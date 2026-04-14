import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../services/notifications_service.dart';
import 'package:provider/provider.dart';
import '../../core/providers/guest_provider.dart';
import '../../widgets/guest_action_dialog.dart';
import '../../models/group_model.dart';
import '../../services/group_service.dart';
import '../library/file_details_screen.dart';
import '../library/file_model.dart';
import 'group_details_screen.dart';
import 'group_profile_screen.dart';
import 'invite_group_screen.dart';
import 'package:flutter/gestures.dart';
import '../../l10n/app_localizations.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../services/upload_screening_service.dart';

class GroupChatScreen extends StatefulWidget {
  final GroupModel group;

  const GroupChatScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  bool _isSending = false;
  bool _canSend = false;
  bool _isLoadingRole = true;
  bool _isMember = false;
  bool _isOwner = false;
  bool _isAdmin = false;
  bool _isBanned = false;
  bool _isMuted = false;
  File? _selectedImage;
  int _membersCount = 0;
  bool _isSearching = false;
  String _searchQuery = '';
  List<int> _searchMatchIndices = [];
  int _currentSearchMatchCursor = -1;
  final TextEditingController _searchController = TextEditingController();

  final Map<String, Map<String, dynamic>> _userCache = {};
  Map<String, dynamic>? _replyMessage;

  // ── Jump-to-original & swipe-reply ─────────────────────────────
  final Map<String, GlobalKey> _itemKeys = {};
  String? _highlightedMessageId;
  // Latest snapshot of message docs; used by _jumpToMessage to locate items.
  List<QueryDocumentSnapshot> _loadedDocs = [];
  late Stream<QuerySnapshot> _messagesStream;

  // ── Typing indicator ──────────────────────────────────────────────
  Timer? _typingTimer;
  bool _isCurrentlyTyping = false;
  String _resolvedDisplayName = '';  // populated from Firestore users collection

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _pageBg => Theme.of(context).scaffoldBackgroundColor;
  Color get _surface => _isDark ? AppColors.surface : Colors.white;
  Color get _surfaceSoft =>
      _isDark ? AppColors.background.withOpacity(0.6) : const Color(0xFFF7F8FB);
  Color get _text =>
      _isDark ? AppColors.textPrimary : Colors.black87;
  Color get _muted =>
      _isDark ? AppColors.textSecondary : Colors.black54;
  Color get _border =>
      _isDark ? AppColors.border : Colors.black12;

  Future<void> _fetchUserIfNeeded(String userId) async {
    if (userId.isEmpty || _userCache.containsKey(userId)) return;
    _userCache[userId] = {};
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        if (mounted) {
          setState(() {
            _userCache[userId] = doc.data()!;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _messagesStream = _firestore
        .collection('groups')
        .doc(widget.group.id)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
    // Mark group as read immediately when the screen opens.
    GroupService.markGroupAsRead(widget.group.id);
    // Pre-fetch the real display name from Firestore so typing indicator
    // shows a meaningful name rather than FirebaseAuth.displayName (often empty).
    _fetchDisplayName();
  }

  Future<void> _fetchDisplayName() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      // Mirror the same lookup GroupService uses for senderName in messages.
      final directSnap =
          await _firestore.collection('users').doc(uid).get();
      final data = directSnap.data() ?? {};
      final name = (data['displayName'] ??
              data['fullName'] ??
              data['username'] ??
              _auth.currentUser?.displayName ??
              _auth.currentUser?.email ??
              '')
          .toString()
          .trim();
      if (name.isNotEmpty) _resolvedDisplayName = name;
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-mark as read if the user returns to this screen from background.
    if (state == AppLifecycleState.resumed) {
      GroupService.markGroupAsRead(widget.group.id);
    }
    // Stop typing indicator if app goes to background/is paused.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _clearTyping();
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _clearTyping(); // best-effort — fire-and-forget
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Typing indicator helpers ──────────────────────────────────────

  /// Called on every keystroke in the message field.
  void _onTypingChanged(String value) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    if (value.trim().isEmpty) {
      _clearTyping();
      return;
    }

    // Cancel the idle-delete timer.
    _typingTimer?.cancel();

    // Write/refresh the typing doc on every keystroke.
    _isCurrentlyTyping = true;
    _writeTyping(uid);

    // Auto-delete after 6 s of no keystroke.
    _typingTimer = Timer(const Duration(seconds: 6), _clearTyping);
  }

  /// Writes the typing marker to Firestore.
  /// Uses Timestamp.now() — NOT serverTimestamp() — so the snapshot
  /// arrives immediately without a null pendingWrite phase.
  void _writeTyping(String uid) {
    final name = _resolvedDisplayName.isNotEmpty
        ? _resolvedDisplayName
        : (_auth.currentUser?.email?.split('@').first ?? 'User');
    _firestore
        .collection('groups')
        .doc(widget.group.id)
        .collection('typing')
        .doc(uid)
        .set({
      'uid': uid,
      'displayName': name,
      'updatedAt': Timestamp.now(),
    }).catchError((_) {});
  }

  /// Deletes the typing doc for the current user.
  /// Deletion is the canonical signal that the user stopped typing.
  void _deleteTypingDoc(String uid) {
    _firestore
        .collection('groups')
        .doc(widget.group.id)
        .collection('typing')
        .doc(uid)
        .delete()
        .catchError((_) {});
  }

  /// Stops typing: cancels the debounce timer and deletes the doc.
  void _clearTyping() {
    _typingTimer?.cancel();
    _typingTimer = null;
    if (!_isCurrentlyTyping) return;
    _isCurrentlyTyping = false;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _deleteTypingDoc(uid);
  }

  Future<void> _checkPermissions() async {
    final state = await GroupService.getUserGroupState(widget.group.id);

    if (mounted) {
      setState(() {
        _isMember = state.isMember;
        _canSend = state.canSend;
        _isOwner = state.isOwner;
        _isAdmin = state.isAdmin;
        _isBanned = state.isBanned;
        _isMuted = state.isMuted;
        _membersCount = widget.group.membersCounts;
        _isLoadingRole = false;
      });
    }
  }

  /// Shared helper to set reply state from any trigger (long-press or swipe).
  void _triggerReply(Map<String, dynamic> data, String messageId, String senderName) {
    final type = (data['type'] ?? 'text').toString();
    final text = (data['text'] ?? '').toString().trim();
    String previewText;
    if (text.isNotEmpty) {
      previewText = text;
    } else if (type == 'image') {
      previewText = '📷 Photo';
    } else if (type == 'library_file_link') {
      previewText = (data['sharedFileTitle'] ?? '📎 File').toString();
    } else {
      previewText = '...';
    }
    setState(() {
      _replyMessage = {
        'id': messageId,
        'text': previewText,
        'senderName': senderName,
        'type': type,
      };
    });
  }

  /// Opens the pinned messages history bottom sheet.
  void _showPinnedHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PinnedHistorySheet(
        groupId: widget.group.id,
        canUnpin: _isOwner || _isAdmin,
        isDark: _isDark,
        surface: _surface,
        border: _border,
        muted: _muted,
        text: _text,
        onJump: (msgId) {
          // Pop the sheet first, then wait for its dismiss animation to
          // complete before reading RenderBox coordinates. Without this
          // delay, localToGlobal returns wrong values from the
          // partially-dismissed frame and produces the shake.
          Navigator.pop(context);
          Future.delayed(const Duration(milliseconds: 280), () {
            if (mounted) _jumpToMessage(msgId);
          });
        },
      ),
    );
  }

  void _doMatchSearchLocally() {
    final query = _searchQuery.toLowerCase();
    final matches = <int>[];
    if (query.isNotEmpty) {
      for (int i = 0; i < _loadedDocs.length; i++) {
        final data = _loadedDocs[i].data() as Map<String, dynamic>;
        final text = (data['text'] ?? '').toString().toLowerCase();
        final shared = (data['sharedFileTitle'] ?? '').toString().toLowerCase();
        if (text.contains(query) || shared.contains(query)) {
          matches.add(i);
        }
      }
    }
    _searchMatchIndices = matches;
    if (matches.isEmpty) {
      _currentSearchMatchCursor = -1;
    } else {
      _currentSearchMatchCursor = 0;
      _jumpToSearchMatch(); 
    }
  }

  void _jumpToSearchMatch() {
    if (_searchMatchIndices.isEmpty || _currentSearchMatchCursor < 0) return;
    final idx = _searchMatchIndices[_currentSearchMatchCursor];
    final doc = _loadedDocs[idx];
    _jumpToMessage(doc.id);
  }

  void _nextSearchMatch() {
    if (_searchMatchIndices.isEmpty) return;
    setState(() {
      _currentSearchMatchCursor = (_currentSearchMatchCursor + 1) % _searchMatchIndices.length;
    });
    _jumpToSearchMatch();
  }

  void _prevSearchMatch() {
    if (_searchMatchIndices.isEmpty) return;
    setState(() {
      _currentSearchMatchCursor = (_currentSearchMatchCursor - 1 + _searchMatchIndices.length) % _searchMatchIndices.length;
    });
    _jumpToSearchMatch();
  }

  /// True index-based navigation strategy.
  /// Locates the real index of the message in the loaded chat history
  /// and natively scrolls the list to perfectly mount it.
  Future<void> _jumpToMessage(String targetId) async {
    final idx = _loadedDocs.indexWhere((d) => d.id == targetId);
    if (idx == -1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message not in current chat window'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (_itemScrollController.isAttached) {
      await _itemScrollController.scrollTo(
        index: idx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: 0.15,
      );
      // Defer highlight to the next frame so the scroll layout is fully
      // settled before setState is called — prevents RenderTransform mutation.
      WidgetsBinding.instance.addPostFrameCallback((_) => _flashHighlight(targetId));
    }
  }

  /// Briefly highlights the message bubble with [targetId].
  void _flashHighlight(String targetId) {
    if (!mounted) return;
    setState(() => _highlightedMessageId = targetId);
    // Longer flash so the landing is clearly visible after a scroll.
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _highlightedMessageId = null);
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        final file = File(image.path);
        
        // Immediate pre-selection screening for fast feedback
        await UploadScreeningService.validate(file, isImage: true);

        setState(() {
          _selectedImage = file;
        });
      }
    } catch (e) {
      if (mounted) {
        if (e is ScreeningException) {
          UploadScreeningService.showScanError(context, e);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.groupsChatImageError),
            ),
          );
        }
      }
    }
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    // Clear typing indicator immediately on send.
    _clearTyping();

    if (mounted) {
      setState(() {
        _isSending = true;
      });
    }

    try {
      await GroupService.sendMessage(
        groupId: widget.group.id,
        text: text,
        imageFile: _selectedImage,
        replyToMessageId: _replyMessage?['id'],
        replyToText: _replyMessage?['text'],
        replyToSenderName: _replyMessage?['senderName'],
      );

      _messageController.clear();
      if (mounted) {
        setState(() {
          _selectedImage = null;
          _replyMessage = null;
        });
      }

      if (_itemScrollController.isAttached) {
        _itemScrollController.scrollTo(
          index: 0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _openSharedLibraryFile(Map<String, dynamic> data) async {
    final sharedFileId = (data['sharedFileId'] ?? '').toString().trim();
    final sharedFileUrl = (data['sharedFileUrl'] ?? '').toString().trim();

    try {
      if (sharedFileId.isNotEmpty) {
        final doc =
        await _firestore.collection('library_files').doc(sharedFileId).get();

        if (doc.exists && doc.data() != null) {
          final file = FileModel.fromFirestore(doc);
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FileDetailsScreen(file: file),
            ),
          );
          return;
        }
      }

      if (sharedFileUrl.isNotEmpty) {
        final uri = Uri.tryParse(sharedFileUrl);
        if (uri != null) {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.groupsChatFileP1Unavailable)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.groupsChatFileP1Error)),
      );
    }
  }

  String _formatTimestamp(Timestamp? timestamp, AppLocalizations l10n) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    int hour = date.hour;
    String minute = date.minute.toString().padLeft(2, '0');
    String period = l10n.groupsChatTimeAm;

    if (hour >= 12) {
      period = l10n.groupsChatTimePm;
      if (hour > 12) hour -= 12;
    }
    if (hour == 0) hour = 12;

    return '$hour:$minute $period';
  }

  void _openDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailsScreen(group: widget.group),
      ),
    );
  }

  Future<void> _leaveGroup() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.groupsChatLeaveOwnerError),
        ),
      );
      return;
    }

    try {
      await GroupService.leaveGroup(widget.group.id);

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.groupsChatLeaveSuccess)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.groupsChatLeaveError)),
        );
      }
    }
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'mute':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.groupsChatMuteSuccess)),
        );
        break;

      case 'toggle_chat':
        try {
          final doc =
          await _firestore.collection('groups').doc(widget.group.id).get();
          if (doc.exists) {
            final current = doc.data()?['membersCanChat'] ?? true;
            await doc.reference.update({'membersCanChat': !current});
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    !current
                        ? AppLocalizations.of(context)!.groupsChatEnableMembersMsg
                        : AppLocalizations.of(context)!.groupsChatDisableMembersMsg,
                  ),
                ),
              );
            }
            _checkPermissions();
          }
        } catch (_) {}
        break;
      case 'leave':
        _leaveGroup();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(88),
        child: Container(
          decoration: BoxDecoration(
            color: _surface,
            border: Border(
              bottom: BorderSide(color: _border),
            ),
            boxShadow: [
              BoxShadow(
                color: _isDark
                    ? Colors.black.withOpacity(0.18)
                    : Colors.black.withOpacity(0.03),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  _TopIconButton(
                    icon: _isSearching
                        ? Icons.close_rounded
                        : Icons.arrow_back_rounded,
                    onTap: () {
                      if (_isSearching) {
                        setState(() {
                          _isSearching = false;
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _isSearching
                        ? Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _surfaceSoft,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              cursorColor: AppColors.primary,
                              style: TextStyle(
                                color: _text,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!.groupsChatSearchHint,
                                hintStyle: TextStyle(
                                  color: _muted.withOpacity(0.75),
                                ),
                                border: InputBorder.none,
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: _muted,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (val) =>
                                  setState(() {
                                     _searchQuery = val.trim();
                                     _doMatchSearchLocally();
                                  }),
                            ),
                          ),
                          if (_searchMatchIndices.isNotEmpty) ...[
                            Text(
                              '${_currentSearchMatchCursor + 1}/${_searchMatchIndices.length}',
                              style: TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_up_rounded),
                              color: AppColors.primary,
                              iconSize: 22,
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              onPressed: _nextSearchMatch,
                            ),
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down_rounded),
                              color: AppColors.primary,
                              iconSize: 22,
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.only(right: 8, left: 4),
                              onPressed: _prevSearchMatch,
                            ),
                          ],
                        ]
                      ),
                    )
                        : InkWell(
                      onTap: _openDetails,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 4,
                        ),
                        child: Row(
                          children: [
                            _GroupHeaderAvatar(group: widget.group),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.group.name.isEmpty
                                        ? AppLocalizations.of(context)!.groupsChatFallbackName
                                        : widget.group.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      color: _text,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_membersCount > 0 ? '$_membersCount ${AppLocalizations.of(context)!.groupsChatMembersPluralSuffix}' : AppLocalizations.of(context)!.groupsChatDefaultCountName} • ${widget.group.specializationName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.8,
                                      fontWeight: FontWeight.w600,
                                      color: _muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (!_isSearching) ...[
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => GroupProfileScreen(group: widget.group)),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        foregroundColor: AppColors.primary,
                      ),
                      child: const Text(
                        'معلومات المجموعة',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _TopIconButton(
                      icon: Icons.search_rounded,
                      onTap: () => setState(() => _isSearching = true),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoadingRole
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      )
          : !_isMember
          ? _buildNonMemberState()
          : Column(
        children: [
          // ── Pinned message banner — directly below AppBar, above messages ─
          _PinnedBanner(
            groupId: widget.group.id,
            canUnpin: _isOwner || _isAdmin,
            isDark: _isDark,
            surface: _surface,
            border: _border,
            muted: _muted,
            text: _text,
            onJump: _jumpToMessage,
            onViewAll: () => _showPinnedHistory(),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)!.groupsChatErrorLoadingMessages,
                      style: TextStyle(color: _muted),
                    ),
                  );
                }

                var docs = snapshot.data?.docs ?? [];

                // Cache the latest docs list so _jumpToMessage can locate
                // items by index even before their widget is built.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _loadedDocs = List.unmodifiable(docs);
                });

                // Search no longer destructively filters the chat list.
                // It highlights matches in-place instead.

                if (docs.isEmpty) {
                  return _searchQuery.isNotEmpty
                      ? Center(
                    child: Text(
                      AppLocalizations.of(context)!.groupsChatNoSearchResults,
                      style: TextStyle(
                        color: _muted,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                      : const _EmptyChatState();
                }

                return ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  reverse: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final messageId = doc.id;
                    final myId = _auth.currentUser?.uid;
                    final senderId = data['senderId'] ?? '';
                    final isMe = myId != null && myId == senderId;

                    // The latest own message is the first isMe entry in the
                    // reversed list (lowest index) — show seen-by only there.
                    final isLatestOwn = isMe &&
                        !docs
                            .sublist(0, index)
                            .any((d) =>
                                (d.data() as Map<String, dynamic>)['senderId'] ==
                                myId);

                    return _buildMessageBubble(
                        data, messageId, isMe, isLatestOwn);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildNonMemberState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: _isDark
                    ? Colors.black.withOpacity(0.18)
                    : Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_rounded,
                  size: 38,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                AppLocalizations.of(context)!.groupsChatRequiresJoinTitle,
                style: TextStyle(
                  color: _text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context)!.groupsChatRequiresJoinBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  fontSize: 13.8,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  elevation: 0,
                ),
                onPressed: _openDetails,
                child: Text(
                  AppLocalizations.of(context)!.groupsChatDetailsButton,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(
      Map<String, dynamic> data,
      String messageId,
      String resolvedSenderName,
      bool isSaved,
      bool isPinned,
      String? currentUserReaction,
      ) {
    // 🚫 Guest cannot interact with messages
    if (context.read<GuestProvider>().isGuest) {
      GuestActionDialog.show(
        context,
        title: 'تسجيل الدخول مطلوب',
        subtitle: 'أنت الآن في وضع الضيف. التفاعل مع الرسائل يتطلب تسجيل الدخول.',
      );
      return;
    }

    final parentContext = context;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(26),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            // ── Quick emoji reactions ─────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final emoji in const [
                    '👍', '❤️', '😂', '😮', '😢', '🔥'
                  ])
                    Builder(builder: (ctx) {
                      final isActive = emoji == currentUserReaction;
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          GroupService.toggleReaction(
                            groupId: widget.group.id,
                            messageId: messageId,
                            emoji: emoji,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary.withOpacity(
                                    _isDark ? 0.28 : 0.14)
                                : (_isDark
                                    ? Colors.white.withOpacity(0.06)
                                    : Colors.black.withOpacity(0.04)),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isActive
                                  ? AppColors.primary.withOpacity(0.65)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(emoji,
                                style: TextStyle(
                                    fontSize: isActive ? 26 : 23)),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
            Divider(height: 1, color: _border),
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.reply_rounded, color: AppColors.primary),
              title: Text(
                AppLocalizations.of(context)!.groupsChatReplyAction,
                style: TextStyle(
                  color: _text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _triggerReply(data, messageId, resolvedSenderName);
              },
            ),
            ListTile(
              leading: Icon(
                isSaved ? Icons.star_border_rounded : Icons.star_rounded,
                color: Colors.amber,
              ),
              title: Text(
                isSaved ? AppLocalizations.of(context)!.groupsChatSavedRemoveAction : AppLocalizations.of(context)!.groupsChatSaveAction,
                style: TextStyle(
                  color: _text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                try {
                  if (isSaved) {
                    await GroupService.unsaveMessage(
                      groupId: widget.group.id,
                      messageId: messageId,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.groupsChatSavedRemoveSuccess)),
                      );
                    }
                  } else {
                    await GroupService.saveMessage(
                      groupId: widget.group.id,
                      messageId: messageId,
                      data: data,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.groupsChatSaveSuccess)),
                      );
                    }
                  }
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.groupsChatSaveError),
                      ),
                    );
                  }
                }
              },
            ),
            if (_isOwner || _isAdmin)
              ListTile(
                leading: Icon(
                  isPinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  color: isPinned
                      ? AppColors.primary
                      : AppColors.primary,
                ),
                title: Text(
                  isPinned ? 'Unpin Message' : 'Pin Message',
                  style: TextStyle(
                    color: _text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    if (isPinned) {
                      await GroupService.unpinMessage(
                        groupId: widget.group.id,
                        messageId: messageId,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(content: Text('Message unpinned')),
                        );
                      }
                    } else {
                      await GroupService.pinMessage(
                        groupId: widget.group.id,
                        messageId: messageId,
                        data: data,
                        pinnedByName: _resolvedDisplayName.isNotEmpty
                            ? _resolvedDisplayName
                            : (_auth.currentUser?.email
                                    ?.split('@')
                                    .first ??
                                ''),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(content: Text('Message pinned')),
                        );
                      }
                    }
                  } catch (_) {
                    if (mounted) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        const SnackBar(
                            content: Text('Failed. Please try again.')),
                      );
                    }
                  }
                },
              ),
            if ((_auth.currentUser?.uid ?? '') == (data['senderId'] ?? '') && data['type'] == 'text')
              ListTile(
                leading: Icon(Icons.edit_rounded, color: AppColors.primary),
                title: Text(
                  'Edit Message',
                  style: TextStyle(
                    color: _text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showEditMessageDialog(messageId, data['text']?.toString() ?? '');
                },
              ),
            if ((_auth.currentUser?.uid ?? '') == (data['senderId'] ?? ''))
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: Colors.red),
                title: const Text(
                  'Delete Message',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteMessageDialog(messageId);
                },
              ),
          ],
        ),
      ),
    ),
  ));
}

  void _showEditMessageDialog(String messageId, String currentText) {
    final editCtrl = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: Text('Edit Message', style: TextStyle(color: _text)),
        content: TextField(
          controller: editCtrl,
          style: TextStyle(color: _text),
          decoration: InputDecoration(
             enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _border)),
             focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
          ),
          maxLines: null,
          minLines: 1,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
               Navigator.pop(ctx);
               if (editCtrl.text.trim().isNotEmpty && editCtrl.text.trim() != currentText.trim()) {
                 await GroupService.editMessage(
                   groupId: widget.group.id,
                   messageId: messageId,
                   newText: editCtrl.text.trim(),
                 );
               }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteMessageDialog(String messageId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: Text('Delete Message', style: TextStyle(color: _text)),
        content: Text('Are you sure you want to delete this message?', style: TextStyle(color: _text)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
               Navigator.pop(ctx);
               await GroupService.deleteMessage(
                 groupId: widget.group.id,
                 messageId: messageId,
               );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      Map<String, dynamic> data,
      String messageId,
      bool isMe, [
      bool isLatestOwn = false,
      ]) {
    final text = data['text'] ?? '';
    final imageUrl = data['imageUrl'] as String?;
    final senderId = data['senderId'] ?? '';
    final type = data['type']?.toString() ?? 'text';
    final isLibraryFileLink = type == 'library_file_link';

    _fetchUserIfNeeded(senderId);
    final cachedUser = _userCache[senderId];

    String senderName = data['senderName']?.toString() ?? AppLocalizations.of(context)!.groupsChatMemberFallback;
    String senderAvatarUrl = data['senderAvatar'] as String? ??
        data['senderImageUrl'] as String? ??
        data['photoUrl'] as String? ??
        '';

    if (cachedUser != null && cachedUser.isNotEmpty) {
      senderName = (cachedUser['username']?.toString() ??
          cachedUser['fullName']?.toString() ??
          cachedUser['displayName']?.toString() ??
          cachedUser['name']?.toString() ??
          senderName)
          .trim();
      senderAvatarUrl =
          (cachedUser['photoUrl']?.toString() ??
              cachedUser['imageUrl']?.toString() ??
              senderAvatarUrl)
              .trim();
    }

    if (senderName.contains('@')) senderName = senderName.split('@').first;

    final timestamp = data['createdAt'] as Timestamp?;
    const primaryColor = AppColors.primary;

    final List<Color> nameColors = [
      const Color(0xFFE53935),
      const Color(0xFFD81B60),
      const Color(0xFF8E24AA),
      const Color(0xFF3949AB),
      const Color(0xFF039BE5),
      const Color(0xFF00897B),
      const Color(0xFF7CB342),
      const Color(0xFFF4511E),
    ];
    final senderColor = nameColors[senderName.length % nameColors.length];

    final String? replyToText = data['replyToText']?.toString();
    final String? replyToSender =
        data['replyToSenderName']?.toString() ?? data['replyToSender']?.toString();

    final bubbleBg = isMe
        ? (_isDark ? primaryColor.withOpacity(0.13) : AppColors.primary)
        : _surface;
    final bubbleBorder = isMe
        ? (_isDark ? primaryColor.withOpacity(0.22) : Colors.transparent)
        : _border;
    final bubbleTextColor = isMe
        ? (_isDark ? Colors.white.withOpacity(0.95) : Colors.white)
        : _text;

    final bubble = GestureDetector(
      onLongPress: () async {
        final results = await Future.wait([
          GroupService.isMessageSaved(
            groupId: widget.group.id,
            messageId: messageId,
          ),
          GroupService.isPinned(
            groupId: widget.group.id,
            messageId: messageId,
          ),
        ]);
        // Also fetch current user's reaction for the picker highlight.
        final currentUid = _auth.currentUser?.uid ?? '';
        String? currentUserReaction;
        if (currentUid.isNotEmpty) {
          try {
            final reactionSnap = await _firestore
                .collection('groups')
                .doc(widget.group.id)
                .collection('messages')
                .doc(messageId)
                .collection('reactions')
                .doc(currentUid)
                .get();
            if (reactionSnap.exists) {
              currentUserReaction =
                  reactionSnap.data()?['emoji']?.toString();
            }
          } catch (_) {}
        }
        if (!mounted) return;
        _showMessageOptions(
            data, messageId, senderName, results[0], results[1],
            currentUserReaction);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment:
          isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 18,
                backgroundColor: senderColor.withOpacity(0.12),
                backgroundImage: senderAvatarUrl.isNotEmpty
                    ? NetworkImage(senderAvatarUrl)
                    : null,
                child: senderAvatarUrl.isEmpty
                    ? Text(
                  senderName.isNotEmpty ? senderName[0] : 'M',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: senderColor,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.74,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: bubbleBg,
                  border: Border.all(color: bubbleBorder),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isDark
                          ? Colors.black.withOpacity(0.12)
                          : Colors.black.withOpacity(0.025),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          senderName,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: senderColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    if (replyToText != null) ...[
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          final replyId = data['replyToMessageId']?.toString();
                          if (replyId != null) _jumpToMessage(replyId);
                        },
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: senderColor,
                                width: 3.5,
                              ),
                            ),
                            color: senderColor.withOpacity(0.09),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _replyTypeIcon(data['replyToType']?.toString()),
                                    size: 11,
                                    color: senderColor.withOpacity(0.85),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      replyToSender ?? AppLocalizations.of(context)!.groupsChatReplyAction,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: senderColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                replyToText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isMe
                                      ? Colors.white.withOpacity(0.75)
                                      : _muted,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (isLibraryFileLink)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: text.toString().trim().isNotEmpty ? 8 : 2,
                        ),
                        child: _buildSharedLibraryCard(
                          data: data,
                          isMe: isMe,
                        ),
                      ),
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: text.toString().isNotEmpty ? 8 : 4,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            // Fullscreen image preview.
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                opaque: false,
                                barrierDismissible: true,
                                barrierColor: Colors.black87,
                                pageBuilder: (_, __, ___) =>
                                    _FullscreenImageViewer(
                                        imageUrl: imageUrl,
                                        heroTag: 'img_$messageId'),
                              ),
                            );
                          },
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width *
                                          0.65,
                                  minHeight: 60,
                                  maxHeight: 230,
                                ),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  loadingBuilder:
                                      (context, child, progress) {
                                    if (progress == null) return child;
                                    final pct = progress
                                                .expectedTotalBytes !=
                                            null
                                        ? progress
                                                .cumulativeBytesLoaded /
                                            progress.expectedTotalBytes!
                                        : null;
                                    return Container(
                                      height: 220,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: _isDark
                                            ? Colors.white
                                                .withOpacity(0.05)
                                            : Colors.black
                                                .withOpacity(0.04),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 32,
                                            height: 32,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: AppColors.primary,
                                              value: pct,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Icon(
                                            Icons.image_rounded,
                                            color: _muted.withOpacity(0.4),
                                            size: 22,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 110,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: _isDark
                                          ? Colors.white.withOpacity(0.04)
                                          : Colors.black.withOpacity(0.04),
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image_rounded,
                                          color: _muted.withOpacity(0.55),
                                          size: 32,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          AppLocalizations.of(context)!
                                              .groupsChatImageDisplayError,
                                          style: TextStyle(
                                            color: _muted,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (text.toString().isNotEmpty)
                      Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          DefaultTextStyle(
                            style: TextStyle(
                              fontSize: 15.3,
                              color: bubbleTextColor,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                            ),
                            child: _buildMessageText(
                              text.toString(),
                              isMe,
                              _isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (data['isEdited'] == true) ...[
                                  Text(
                                    'edited',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FontStyle.italic,
                                      color: isMe
                                          ? (_isDark ? Colors.white54 : Colors.white60)
                                          : _muted.withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  _formatTimestamp(timestamp, AppLocalizations.of(context)!),
                                  style: TextStyle(
                                    fontSize: 10.6,
                                    fontWeight: FontWeight.w700,
                                    color: isMe
                                        ? (_isDark
                                        ? primaryColor.withOpacity(0.85)
                                        : Colors.white70)
                                        : _muted.withOpacity(0.82),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    if (text.toString().isEmpty &&
                        ((imageUrl != null && imageUrl.isNotEmpty) ||
                            isLibraryFileLink))
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _formatTimestamp(timestamp, AppLocalizations.of(context)!),
                            style: TextStyle(
                              fontSize: 10.8,
                              fontWeight: FontWeight.w700,
                              // Honour isMe colour: gold on dark purple,
                              // white-70 on solid primary, muted on others' bubbles.
                              color: isMe
                                  ? (_isDark
                                      ? primaryColor.withOpacity(0.85)
                                      : Colors.white70)
                                  : _muted.withOpacity(0.82),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Build the combined widget: swipe wrapper + optional seen-by.
    final isHighlighted = _highlightedMessageId == messageId;

    Widget content = _SwipeToReplyWrapper(
      isMe: isMe,
      onSwipe: () => _triggerReply(data, messageId, senderName),
      child: AnimatedContainer(
        key: ValueKey(messageId),
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isHighlighted
              ? AppColors.primary.withOpacity(0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: bubble,
      ),
    );

    if (!isLatestOwn) {
      return Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          content,
          _ReactionsBar(
            groupId: widget.group.id,
            messageId: messageId,
            currentUid: _auth.currentUser?.uid ?? '',
            isMe: isMe,
            isDark: _isDark,
            muted: _muted,
          ),
        ],
      );
    }

    final createdAt = data['createdAt'] as Timestamp?;
    if (createdAt == null) {
      return Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          content,
          _ReactionsBar(
            groupId: widget.group.id,
            messageId: messageId,
            currentUid: _auth.currentUser?.uid ?? '',
            isMe: isMe,
            isDark: _isDark,
            muted: _muted,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        content,
        _ReactionsBar(
          groupId: widget.group.id,
          messageId: messageId,
          currentUid: _auth.currentUser?.uid ?? '',
          isMe: isMe,
          isDark: _isDark,
          muted: _muted,
        ),
        _SeenByWidget(
          groupId: widget.group.id,
          currentUid: _auth.currentUser?.uid ?? '',
          messageCreatedAt: createdAt,
          muted: _muted,
        ),
      ],
    );
  }

  Widget _buildSharedLibraryCard({
    required Map<String, dynamic> data,
    required bool isMe,
  }) {
    final title = (data['sharedFileTitle'] ?? AppLocalizations.of(context)!.groupsChatLibraryFile).toString();
    final fileType = (data['sharedFileType'] ?? 'FILE').toString();
    final thumbnailUrl = (data['sharedFileThumbnailUrl'] ?? '').toString();
    final sharedFileUrl = (data['sharedFileUrl'] ?? '').toString();

    final cardColor = isMe
        ? (_isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.12))
        : _surfaceSoft;
    final borderColor = isMe
        ? (_isDark ? Colors.white.withOpacity(0.10) : Colors.white.withOpacity(0.22))
        : _border;
    final titleColor = isMe ? Colors.white : _text;
    final openColor = isMe ? Colors.white : AppColors.primary;

    return InkWell(
      onTap: () => _openSharedLibraryFile(data),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: _isDark
                  ? Colors.black.withOpacity(0.10)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon / thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: thumbnailUrl.isNotEmpty
                  ? Image.network(
                      thumbnailUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return _buildSharedFileIconBox(fileType: fileType);
                      },
                      errorBuilder: (_, __, ___) =>
                          _buildSharedFileIconBox(fileType: fileType),
                    )
                  : _buildSharedFileIconBox(fileType: fileType),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File type badge pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      fileType.isNotEmpty
                          ? fileType.toUpperCase()
                          : AppLocalizations.of(context)!.groupsChatLibraryFile,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Title
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.8,
                      height: 1.3,
                    ),
                  ),
                  if (sharedFileUrl.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 13,
                          color: openColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)!.groupsChatOpenFileAction,
                          style: TextStyle(
                            color: openColor,
                            fontSize: 11.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedFileIconBox({
    required String fileType,
  }) {
    final normalized = fileType.toLowerCase();
    IconData icon;
    Color iconColor;

    if (normalized.contains('pdf')) {
      icon = Icons.picture_as_pdf_rounded;
      iconColor = const Color(0xFFE53935);
    } else if (normalized.contains('word') ||
        normalized.contains('doc') ||
        normalized.contains('docx')) {
      icon = Icons.description_rounded;
      iconColor = const Color(0xFF1565C0);
    } else if (normalized.contains('ppt') ||
        normalized.contains('presentation')) {
      icon = Icons.slideshow_rounded;
      iconColor = const Color(0xFFE65100);
    } else if (normalized.contains('xls') ||
        normalized.contains('sheet') ||
        normalized.contains('csv')) {
      icon = Icons.table_chart_rounded;
      iconColor = const Color(0xFF2E7D32);
    } else if (normalized.contains('zip') ||
        normalized.contains('rar') ||
        normalized.contains('7z')) {
      icon = Icons.folder_zip_rounded;
      iconColor = const Color(0xFF6A1B9A);
    } else if (normalized.contains('image') ||
        normalized.contains('jpg') ||
        normalized.contains('png') ||
        normalized.contains('jpeg')) {
      icon = Icons.image_rounded;
      iconColor = const Color(0xFF00838F);
    } else {
      icon = Icons.insert_drive_file_rounded;
      iconColor = AppColors.primary;
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            iconColor.withOpacity(_isDark ? 0.22 : 0.12),
            iconColor.withOpacity(_isDark ? 0.10 : 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withOpacity(0.18),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 27,
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query, TextStyle textStyle) {
    if (query.isEmpty) return Text(text, style: textStyle);
    
    final lowerText = text.toLowerCase();
    int start = 0;
    List<TextSpan> spans = [];
    
    while (true) {
      final idx = lowerText.indexOf(query, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start), style: textStyle));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: textStyle));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: textStyle.copyWith(backgroundColor: AppColors.primary.withOpacity(0.4)),
      ));
      start = idx + query.length;
    }
    
    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildMessageText(String text, bool isMe, bool isDark) {
    final textColor = isDark
        ? Colors.white.withOpacity(0.95)
        : (isMe ? Colors.white : Colors.black87);
    final textStyle = TextStyle(
      fontSize: 15.3,
      color: textColor,
      height: 1.45,
      fontWeight: FontWeight.w600,
    );

    final query = _searchQuery.toLowerCase();

    if (!text.contains('edumate://invite')) {
      if (query.isNotEmpty) {
        return _buildHighlightedText(text, query, textStyle);
      }
      return Text(text, style: textStyle);
    }

    final RegExp linkRegExp = RegExp(
      r'(edumate:\/\/invite\?[^\s]+)',
      caseSensitive: false,
    );
    final matches = linkRegExp.allMatches(text);
    if (matches.isEmpty) {
      return Text(text, style: textStyle);
    }

    List<TextSpan> spans = [];
    int currentPos = 0;

    for (final match in matches) {
      if (match.start > currentPos) {
        spans.add(TextSpan(text: text.substring(currentPos, match.start)));
      }
      final url = match.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: const TextStyle(
            color: Color(0xFF64B5F6),
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.bold,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              final uri = Uri.tryParse(url);
              if (uri != null) {
                final groupId = uri.queryParameters['groupId'];
                final code = uri.queryParameters['code'];
                if (groupId != null && code != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          InviteGroupScreen(groupId: groupId, code: code),
                    ),
                  );
                }
              }
            },
        ),
      );
      currentPos = match.end;
    }

    if (currentPos < text.length) {
      spans.add(TextSpan(text: text.substring(currentPos)));
    }

    return RichText(
      text: TextSpan(
        style: textStyle,
        children: spans,
      ),
    );
  }

  Widget _buildInputArea() {
    if (_isBanned) {
      return _buildDisabledState(
        AppLocalizations.of(context)!.groupsChatBannedMsg,
        Icons.block_rounded,
        AppColors.error,
      );
    }
    if (_isMuted) {
      return _buildDisabledState(
        AppLocalizations.of(context)!.groupsChatMutedMsg,
        Icons.mic_off_rounded,
        AppColors.warning,
      );
    }
    if (!_canSend) {
      return _buildDisabledState(
        AppLocalizations.of(context)!.groupsChatReadOnlyMsg,
        Icons.info_outline_rounded,
        _muted,
      );
    }

    return Container(
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _border)),
        boxShadow: [
          BoxShadow(
            color: _isDark
                ? Colors.black.withOpacity(0.22)
                : Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Live typing indicator — shown above reply/image previews.
          _TypingIndicator(
            groupId: widget.group.id,
            currentUid: _auth.currentUser?.uid ?? '',
            muted: _muted,
          ),
          if (_replyMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: _surfaceSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // Left accent bar
                      Container(width: 4, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Icon(
                        _replyTypeIcon(_replyMessage!['type']?.toString()),
                        color: AppColors.primary,
                        size: 17,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                (_replyMessage!['senderName'] ?? '').toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                (_replyMessage!['text'] ?? '').toString(),
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 12.5,
                                  height: 1.2,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _replyMessage = null),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(Icons.close_rounded, color: _muted, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_selectedImage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _surfaceSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _selectedImage!,
                      height: 54,
                      width: 54,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.groupsChatImageAttached,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: _text,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.error,
                    ),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _BottomMiniButton(
                icon: Icons.image_outlined,
                onTap: _pickImage,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _surfaceSoft,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _border),
                  ),
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    cursorColor: AppColors.primary,
                    onChanged: _onTypingChanged,
                    style: TextStyle(
                      color: _text,
                      fontSize: 15.6,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.groupsChatInputHint,
                      hintStyle: TextStyle(
                        color: _muted.withOpacity(0.75),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isSending ? null : _send,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (!_isSending)
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                  child: _isSending
                      ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                      : const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledState(String msg, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              msg,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}


/// Compact banner below AppBar showing the latest pinned message.
///
/// Tapping the body opens the full pinned-messages history sheet.
/// The ✕ button (owner/admin only) quick-unpins the latest pin.
/// Shows "1 pinned" / "N pinned" counter + chevron affordance.
class _PinnedBanner extends StatefulWidget {
  final String groupId;
  final bool canUnpin;
  final bool isDark;
  final Color surface;
  final Color border;
  final Color muted;
  final Color text;
  final void Function(String messageId) onJump;
  final VoidCallback onViewAll;

  const _PinnedBanner({
    required this.groupId,
    required this.canUnpin,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.muted,
    required this.text,
    required this.onJump,
    required this.onViewAll,
  });

  @override
  State<_PinnedBanner> createState() => _PinnedBannerState();
}

class _PinnedBannerState extends State<_PinnedBanner> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _allStream;

  @override
  void initState() {
    super.initState();
    _allStream = GroupService.streamAllPins(widget.groupId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _allStream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        final latestData = docs.first.data();
        final latestId   =
            (latestData['messageId'] ?? docs.first.id).toString();
        final preview    = (latestData['previewText'] ?? '').toString();
        final sender     = (latestData['senderName'] ?? '').toString();
        final totalPins  = docs.length;

        // Header label: "Pinned" (1 pin) or "Pinned · 3" (multi-pin).
        final headerLabel = totalPins > 1
            ? 'Pinned · $totalPins'
            : 'Pinned';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            // Full banner tap → open history sheet.
            onTap: widget.onViewAll,
            child: Container(
              decoration: BoxDecoration(
                color: widget.surface,
                border: Border(
                  bottom: BorderSide(color: widget.border),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left gold accent bar.
                  Container(
                    width: 3,
                    height: 40,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.push_pin_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  // Text content.
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header row: label + count.
                          Text(
                            headerLabel,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Sender name on its own line (bolder).
                          if (sender.isNotEmpty)
                            Text(
                              sender,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: widget.text,
                              ),
                            ),
                          // Preview text on second line (lighter).
                          if (preview.isNotEmpty)
                            Text(
                              preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: widget.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Chevron: affordance that tapping opens history list.
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: widget.muted.withOpacity(0.6),
                  ),
                  // Unpin button (owner/admin only).
                  if (widget.canUnpin)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => GroupService.unpinMessage(
                        groupId: widget.groupId,
                        messageId: latestId,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
                        child: Icon(
                          Icons.close_rounded,
                          size: 17,
                          color: widget.muted.withOpacity(0.7),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pinned Messages History Sheet
// ─────────────────────────────────────────────────────────────────────────────

/// Bottom sheet listing all pinned messages for the group (newest first).
///
/// * Any member can view and jump to a message.
/// * Owners / admins get a trash icon to unpin per item.
class _PinnedHistorySheet extends StatefulWidget {
  final String groupId;
  final bool canUnpin;
  final bool isDark;
  final Color surface;
  final Color border;
  final Color muted;
  final Color text;
  final void Function(String messageId) onJump;

  const _PinnedHistorySheet({
    required this.groupId,
    required this.canUnpin,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.muted,
    required this.text,
    required this.onJump,
  });

  @override
  State<_PinnedHistorySheet> createState() => _PinnedHistorySheetState();
}

class _PinnedHistorySheetState extends State<_PinnedHistorySheet> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = GroupService.streamAllPins(widget.groupId);
  }

  String _relativeTime(Timestamp? ts) {
    if (ts == null) return '';
    final now = DateTime.now();
    final diff = now.difference(ts.toDate());
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final d = ts.toDate();
    return '${d.day}/${d.month}/${d.year}';
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'image':
        return Icons.image_rounded;
      case 'library_file_link':
        return Icons.attach_file_rounded;
      default:
        return Icons.chat_bubble_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: widget.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.35 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: widget.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          // ── Header ────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.push_pin_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Pinned Messages',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: widget.text,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: widget.border),
          // ── List ─────────────────────────────────────────────────
          Flexible(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Padding(
                    padding:
                        EdgeInsets.fromLTRB(24, 32, 24, bottomPad + 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.push_pin_outlined,
                          size: 48,
                          color: widget.muted.withOpacity(0.35),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No pinned messages yet',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: widget.muted,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.only(
                      top: 4, bottom: bottomPad + 16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data    = docs[i].data();
                    final msgId   = (data['messageId'] ?? docs[i].id).toString();
                    final preview = (data['previewText'] ?? '').toString();
                    final sender  = (data['senderName'] ?? '').toString();
                    final pinnedBy = (data['pinnedByName'] ?? '').toString();
                    final pinnedAt  = data['pinnedAt'] as Timestamp?;
                    final msgType  = (data['messageType'] ?? 'text').toString();

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (i > 0)
                          Divider(height: 1, color: widget.border),
                        InkWell(
                          onTap: () => widget.onJump(msgId),
                          splashColor: AppColors.primary.withOpacity(0.08),
                          highlightColor: AppColors.primary.withOpacity(0.05),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Type icon badge.
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(
                                        widget.isDark ? 0.14 : 0.08),
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.22),
                                    ),
                                  ),
                                  child: Icon(
                                    _typeIcon(msgType),
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Sender + time row.
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              sender.isNotEmpty ? sender : 'Unknown',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: widget.text,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _relativeTime(pinnedAt),
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: widget.muted.withOpacity(0.65),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      // Preview.
                                      Text(
                                        preview.isNotEmpty ? preview : '…',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: widget.muted,
                                          height: 1.35,
                                        ),
                                      ),
                                      // "Pinned by" attribution.
                                      if (pinnedBy.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          'Pinned by $pinnedBy',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: widget.muted.withOpacity(0.48),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // Unpin button — clear remove action.
                                if (widget.canUnpin)
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => GroupService.unpinMessage(
                                      groupId: widget.groupId,
                                      messageId: msgId,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: Icon(
                                        Icons.remove_circle_outline_rounded,
                                        size: 20,
                                        color: widget.muted.withOpacity(0.50),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


/// Full-screen image viewer opened when a chat image is tapped.
///
/// Uses [Hero] for a smooth expand animation from the bubble.
/// [InteractiveViewer] allows pinch-to-zoom / pan.
class _FullscreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const _FullscreenImageViewer({
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5.0,
                child: Image.network(
                  imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2.5,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white54,
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.06);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF10141C) : const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 22,
        ),
      ),
    );
  }
}

class _GroupHeaderAvatar extends StatelessWidget {
  final GroupModel group;

  const _GroupHeaderAvatar({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: group.imageUrl.isNotEmpty
            ? Image.network(
          group.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _HeaderFallback(name: group.name),
        )
            : _HeaderFallback(name: group.name),
      ),
    );
  }
}

class _HeaderFallback extends StatelessWidget {
  final String name;

  const _HeaderFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'G',
        style: const TextStyle(
          color: AppColors.secondary,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ),
    );
  }
}

class _BottomMiniButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _BottomMiniButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.06);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF10141C) : const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF7F8B98),
          size: 24,
        ),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF151A22) : Colors.white;
    final text =
    isDark ? AppColors.textPrimary : const Color(0xFF181A20);
    final muted =
    isDark ? AppColors.textSecondary : const Color(0xFF7B808A);
    final border =
    isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.18)
                    : Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                AppLocalizations.of(context)!.groupsChatEmptyTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: text,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.groupsChatEmptySub,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: muted,
                  fontSize: 13.6,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Returns the appropriate icon for a given reply/message type.
IconData _replyTypeIcon(String? type) {
  switch (type) {
    case 'image':
      return Icons.image_rounded;
    case 'library_file_link':
      return Icons.attach_file_rounded;
    default:
      return Icons.reply_rounded;
  }
}

/// Streams live reactions for a single message and renders compact emoji chips.
///
/// Doc-presence model: each doc is one user's reaction with {uid, emoji}.
/// Groups by emoji → shows count + highlights current user's own reaction.
class _ReactionsBar extends StatefulWidget {
  final String groupId;
  final String messageId;
  final String currentUid;
  final bool isMe;
  final bool isDark;
  final Color muted;

  const _ReactionsBar({
    required this.groupId,
    required this.messageId,
    required this.currentUid,
    required this.isMe,
    required this.isDark,
    required this.muted,
  });

  @override
  State<_ReactionsBar> createState() => _ReactionsBarState();
}

class _ReactionsBarState extends State<_ReactionsBar> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    // Stream created ONCE — immune to parent rebuilds.
    _stream = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .doc(widget.messageId)
        .collection('reactions')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        // Group by emoji → {emoji: count}, sorted by count desc.
        final Map<String, int> counts = {};
        String? myEmoji;
        for (final doc in docs) {
          final data = doc.data();
          final emoji = (data['emoji'] ?? '').toString();
          if (emoji.isEmpty) continue;
          counts[emoji] = (counts[emoji] ?? 0) + 1;
          if ((data['uid'] ?? '') == widget.currentUid) myEmoji = emoji;
        }
        if (counts.isEmpty) return const SizedBox.shrink();

        // Sort highest count first so most-popular emoji leads.
        final sorted = counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Padding(
          padding: EdgeInsets.only(
            // Align below bubble: avatar=36+8px on others' side.
            left: widget.isMe ? 0 : 44,
            right: widget.isMe ? 8 : 0,
            top: 4,
            bottom: 6,
          ),
          child: Wrap(
            alignment:
                widget.isMe ? WrapAlignment.end : WrapAlignment.start,
            spacing: 6,
            runSpacing: 5,
            children: sorted.map((entry) {
              final emoji = entry.key;
              final count = entry.value;
              final isMine = emoji == myEmoji;

              // Colours.
              final chipBg = isMine
                  ? AppColors.primary.withOpacity(widget.isDark ? 0.28 : 0.16)
                  : (widget.isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.055));
              final chipBorder = isMine
                  ? AppColors.primary.withOpacity(widget.isDark ? 0.70 : 0.50)
                  : (widget.isDark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.black.withOpacity(0.10));
              final countColor = isMine
                  ? (widget.isDark ? AppColors.primary : AppColors.primary)
                  : (widget.isDark
                      ? Colors.white.withOpacity(0.70)
                      : Colors.black.withOpacity(0.55));

              return GestureDetector(
                onTap: () {
                  // 🚫 Guest cannot interact
                  if (context.read<GuestProvider>().isGuest) {
                    GuestActionDialog.show(
                      context,
                      title: 'تسجيل الدخول مطلوب',
                      subtitle: 'أنت الآن تتصفح كضيف. للتفاعل مع الرسائل سجل دخولك أولاً.',
                    );
                    return;
                  }
                  GroupService.toggleReaction(
                    groupId: widget.groupId,
                    messageId: widget.messageId,
                    emoji: emoji,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: chipBorder, width: 1.4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji,
                          style: const TextStyle(fontSize: 16,
                              // Let system render emoji at native quality.
                              fontFamilyFallback: ['Apple Color Emoji',
                                'Noto Color Emoji'])),
                      const SizedBox(width: 5),
                      Text(
                        // Always show count — even 1 is meaningful.
                        '$count',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isMine
                              ? FontWeight.w900
                              : FontWeight.w700,
                          color: countColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

/// Wraps a message bubble with a horizontal swipe gesture that triggers reply.
///
/// - Right-swipe triggers reply (works for both own and others' messages).
/// - A reply icon fades in as the user drags.
/// - Releases with a spring-back animation after triggering.
/// - Vertical dominance check prevents fighting with ListView scroll.
class _SwipeToReplyWrapper extends StatefulWidget {
  final Widget child;
  final bool isMe;
  final VoidCallback onSwipe;

  const _SwipeToReplyWrapper({
    required this.child,
    required this.isMe,
    required this.onSwipe,
  });

  @override
  State<_SwipeToReplyWrapper> createState() => _SwipeToReplyWrapperState();
}

class _SwipeToReplyWrapperState extends State<_SwipeToReplyWrapper>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _offsetNode = ValueNotifier<double>(0.0);
  bool _triggered = false;
  late final AnimationController _spring;
  late Animation<double> _springAnim;
  bool _trackingAxis = false;
  bool _isHorizontalDrag = false;

  static const double _triggerThreshold = 62;

  @override
  void initState() {
    super.initState();
    _spring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(() {
        _offsetNode.value = _springAnim.value;
      });
  }

  @override
  void dispose() {
    _spring.dispose();
    _offsetNode.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (!_trackingAxis) {
      _trackingAxis = true;
      _isHorizontalDrag =
          d.delta.dx.abs() > d.delta.dy.abs();
    }
    if (!_isHorizontalDrag) return;

    final dx = d.delta.dx;
    // Allow right swipe only (positive dx).
    if (dx < 0 && _offsetNode.value <= 0) return;

    _offsetNode.value = (_offsetNode.value + dx).clamp(-8.0, _triggerThreshold + 12);

    if (_offsetNode.value >= _triggerThreshold && !_triggered) {
      _triggered = true;
      widget.onSwipe();
    }
  }

  void _onDragEnd(DragEndDetails _) {
    _trackingAxis = false;
    _isHorizontalDrag = false;
    _triggered = false;
    // Spring back to 0.
    _springAnim = Tween<double>(begin: _offsetNode.value, end: 0).animate(
      CurvedAnimation(parent: _spring, curve: Curves.elasticOut),
    );
    _spring.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Reply icon revealed when swiping.
          ValueListenableBuilder<double>(
            valueListenable: _offsetNode,
            builder: (context, val, child) {
              final revealProgress = (val / _triggerThreshold).clamp(0.0, 1.0);
              return Positioned(
                left: widget.isMe ? null : 0,
                right: widget.isMe ? 0 : null,
                top: 0,
                bottom: 0,
                child: Opacity(
                  opacity: revealProgress,
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * revealProgress,
                    child: const Icon(
                      Icons.reply_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                ),
              );
            },
          ),
          ValueListenableBuilder<double>(
            valueListenable: _offsetNode,
            builder: (context, val, child) {
              return Transform.translate(
                offset: Offset(val, 0),
                child: widget.child,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Streams live typing state from `groups/{groupId}/typing` and renders
/// an animated indicator above the composer.
///
/// MUST be a StatefulWidget so the Firestore stream is created ONCE in
/// initState and survives parent rebuilds. A StatelessWidget would create
/// a new stream on every parent setState(), which resets the StreamBuilder
/// back to its loading state and kills the live indicator.
class _TypingIndicator extends StatefulWidget {

  final String groupId;
  final String currentUid;
  final Color muted;

  const _TypingIndicator({
    required this.groupId,
    required this.currentUid,
    required this.muted,
  });

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> {
  late final Stream<List<String>> _stream;

  @override
  void initState() {
    super.initState();
    // Stream created ONCE — immune to parent rebuilds.
    // Doc-presence model: a doc existing = user is typing.
    // No isTyping filter needed. A 12-second stale guard is a safety net
    // only (e.g. if the app crashes before deleting the doc).
    _stream = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('typing')
        .snapshots()
        .map((snap) {
      final staleThreshold =
          DateTime.now().subtract(const Duration(seconds: 12));
      final names = <String>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final uid = (data['uid'] ?? '').toString();
        if (uid == widget.currentUid) continue; // never show self
        final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
        // updatedAt is Timestamp.now() so it arrives immediately.
        // Only skip if demonstrably old (crash/disconnect stale guard).
        if (updatedAt != null && updatedAt.isBefore(staleThreshold)) continue;
        final name = (data['displayName'] ?? '').toString().trim();
        if (name.isNotEmpty) names.add(name.split(' ').first);
      }
      return names;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: _stream,
      builder: (context, snapshot) {
        final typers = snapshot.data ?? [];
        if (typers.isEmpty) return const SizedBox.shrink();

        final String label;
        if (typers.length == 1) {
          label = '${typers.first} is typing...';
        } else {
          label = '${typers.length} people are typing...';
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4),
          child: Row(
            children: [
              _BouncingDots(color: widget.muted),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: widget.muted,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


/// Three-dot animated typing animation.
class _BouncingDots extends StatefulWidget {
  final Color color;
  const _BouncingDots({required this.color});

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _anims = List.generate(3, (i) {
      final start = i * 0.2;
      return Tween<double>(begin: 0, end: -4).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, start + 0.4, curve: Curves.easeInOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Transform.translate(
              offset: Offset(0, _anims[i].value),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Streams how many group members have read past a given message, and
/// shows a compact "Seen by N" label below the sender's latest bubble.
class _SeenByWidget extends StatelessWidget {
  final String groupId;
  final String currentUid;
  final Timestamp messageCreatedAt;
  final Color muted;

  const _SeenByWidget({
    required this.groupId,
    required this.currentUid,
    required this.messageCreatedAt,
    required this.muted,
  });

  Stream<int> _seenCountStream() {
    return FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .snapshots()
        .map((snap) {
      int count = 0;
      for (final doc in snap.docs) {
        final uid = doc.id;
        if (uid == currentUid) continue; // exclude self
        final lastReadAt = (doc.data()['lastReadAt'] as Timestamp?);
        if (lastReadAt == null) continue;
        // Member has read past this message if their marker is >= its timestamp.
        if (!lastReadAt.toDate().isBefore(messageCreatedAt.toDate())) {
          count++;
        }
      }
      return count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _seenCountStream(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        if (count == 0) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 3, right: 4, bottom: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.done_all_rounded,
                size: 13,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Seen by $count',
                style: TextStyle(
                  fontSize: 11,
                  color: muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
