import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../models/group_model.dart';
import '../../services/group_service.dart';
import '../library/file_details_screen.dart';
import '../library/file_model.dart';
import 'group_details_screen.dart';
import 'invite_group_screen.dart';
import 'package:flutter/gestures.dart';
import '../../l10n/app_localizations.dart';

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
  final ScrollController _scrollController = ScrollController();
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
  final TextEditingController _searchController = TextEditingController();

  final Map<String, Map<String, dynamic>> _userCache = {};
  Map<String, dynamic>? _replyMessage;

  // ── Typing indicator ──────────────────────────────────────────────
  Timer? _typingTimer;
  bool _isCurrentlyTyping = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _pageBg =>
      _isDark ? const Color(0xFF0B0D12) : const Color(0xFFF3F5F7);
  Color get _surface => _isDark ? const Color(0xFF151A22) : Colors.white;
  Color get _surfaceSoft =>
      _isDark ? const Color(0xFF0F131A) : const Color(0xFFF8FAFD);
  Color get _text =>
      _isDark ? AppColors.textPrimary : const Color(0xFF181A20);
  Color get _muted =>
      _isDark ? AppColors.textSecondary : const Color(0xFF7B808A);
  Color get _border =>
      _isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06);

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
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
    // Mark group as read immediately when the screen opens.
    GroupService.markGroupAsRead(widget.group.id);
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
    _scrollController.dispose();
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

    // Cancel previous debounce timer.
    _typingTimer?.cancel();

    // Write typing=true if not already set.
    if (!_isCurrentlyTyping) {
      _isCurrentlyTyping = true;
      _setTyping(uid, isTyping: true);
    } else {
      // Refresh the timestamp so it doesn't go stale.
      _setTyping(uid, isTyping: true);
    }

    // Auto-clear after 5 s of no keystroke.
    _typingTimer = Timer(const Duration(seconds: 5), () {
      _clearTyping();
    });
  }

  /// Writes the typing marker to Firestore (fire-and-forget).
  void _setTyping(String uid, {required bool isTyping}) {
    final displayName = _auth.currentUser?.displayName ??
        _auth.currentUser?.email ??
        'User';
    _firestore
        .collection('groups')
        .doc(widget.group.id)
        .collection('typing')
        .doc(uid)
        .set({
      'uid': uid,
      'displayName': displayName,
      'isTyping': isTyping,
      'updatedAt': FieldValue.serverTimestamp(),
    }).catchError((_) {});
  }

  /// Clears the typing marker for the current user.
  void _clearTyping() {
    _typingTimer?.cancel();
    _typingTimer = null;
    if (!_isCurrentlyTyping) return;
    _isCurrentlyTyping = false;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _setTyping(uid, isTyping: false);
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.groupsChatImageError),
          ),
        );
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

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
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
                            setState(() => _searchQuery = val.trim()),
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
                  if (!_isSearching)
                    _TopIconButton(
                      icon: Icons.search_rounded,
                      onTap: () => setState(() => _isSearching = true),
                    ),
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('groups')
                  .doc(widget.group.id)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
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

                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final text =
                    (data['text'] ?? '').toString().toLowerCase();
                    final sharedTitle = (data['sharedFileTitle'] ?? '')
                        .toString()
                        .toLowerCase();
                    return text.contains(query) ||
                        sharedTitle.contains(query);
                  }).toList();
                }

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

                return ListView.builder(
                  controller: _scrollController,
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
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: _isDark
                    ? Colors.black.withOpacity(0.22)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
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
      ) {
    final parentContext = context;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.only(top: 10, bottom: 20),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(26),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                setState(() {
                  _replyMessage = {
                    'id': messageId,
                    'text': (data['text'] != null &&
                        data['text'].toString().isNotEmpty)
                        ? data['text']
                        : (data['type'] == 'library_file_link'
                        ? (data['sharedFileTitle'] ?? AppLocalizations.of(context)!.groupsChatLibraryFile)
                        : AppLocalizations.of(context)!.groupsChatImageAttached),
                    'senderName': resolvedSenderName,
                  };
                });
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
          ],
        ),
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
    final primaryColor = const Color(0xFFD4AF37);

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
        final isSaved = await GroupService.isMessageSaved(
          groupId: widget.group.id,
          messageId: messageId,
        );
        if (!mounted) return;
        _showMessageOptions(data, messageId, senderName, isSaved);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
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
                  maxWidth: MediaQuery.of(context).size.width * 0.80,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: bubbleBg,
                  border: Border.all(color: bubbleBorder),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(22),
                    topRight: const Radius.circular(22),
                    bottomLeft: Radius.circular(isMe ? 22 : 8),
                    bottomRight: Radius.circular(isMe ? 8 : 22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isDark
                          ? Colors.black.withOpacity(0.16)
                          : Colors.black.withOpacity(0.035),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
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
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: senderColor, width: 3.2),
                          ),
                          color: senderColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              replyToSender ?? AppLocalizations.of(context)!.groupsChatReplyAction,
                              style: TextStyle(
                                color: senderColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              replyToText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white.withOpacity(0.78)
                                    : _muted,
                                fontSize: 12.6,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                height: 165,
                                width: double.infinity,
                                color: _surfaceSoft,
                                alignment: Alignment.center,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              height: 120,
                              color: _surfaceSoft,
                              alignment: Alignment.center,
                              child: Text(
                                AppLocalizations.of(context)!.groupsChatImageDisplayError,
                                style: TextStyle(
                                  color: _muted,
                                  fontWeight: FontWeight.w600,
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
                            child: Text(
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
                              color: _muted.withOpacity(0.82),
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

    // Seen-by indicator — only on the current user's latest outgoing message.
    if (!isLatestOwn) return bubble;

    final createdAt = data['createdAt'] as Timestamp?;
    if (createdAt == null) return bubble;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        bubble,
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
        ? (_isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.16))
        : _surfaceSoft;

    final borderColor = isMe
        ? (_isDark ? Colors.white.withOpacity(0.10) : Colors.white.withOpacity(0.25))
        : _border;

    final titleColor = isMe
        ? (_isDark ? Colors.white : Colors.white)
        : _text;

    final subtitleColor = isMe
        ? (_isDark ? Colors.white70 : Colors.white.withOpacity(0.88))
        : _muted;

    return InkWell(
      onTap: () => _openSharedLibraryFile(data),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: thumbnailUrl.isNotEmpty
                  ? Image.network(
                thumbnailUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildSharedFileIconBox(
                  fileType: fileType,
                ),
              )
                  : _buildSharedFileIconBox(fileType: fileType),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 14.2,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fileType.isNotEmpty ? fileType.toUpperCase() : AppLocalizations.of(context)!.groupsChatLibraryFile,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 12.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (sharedFileUrl.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 13.5,
                          color: subtitleColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.groupsChatOpenFileAction,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 11.8,
                              fontWeight: FontWeight.w700,
                            ),
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
    IconData icon = Icons.insert_drive_file_rounded;

    if (normalized.contains('pdf')) {
      icon = Icons.picture_as_pdf_rounded;
    } else if (normalized.contains('word') ||
        normalized.contains('doc') ||
        normalized.contains('docx')) {
      icon = Icons.description_rounded;
    } else if (normalized.contains('ppt') ||
        normalized.contains('presentation')) {
      icon = Icons.slideshow_rounded;
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: const Color(0xFFD4AF37),
        size: 29,
      ),
    );
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

    if (!text.contains('edumate://invite')) {
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _surfaceSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.reply_rounded,
                    color: Color(0xFF64B5F6),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _replyMessage!['senderName'],
                          style: const TextStyle(
                            color: Color(0xFF64B5F6),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _replyMessage!['text'],
                          style: TextStyle(
                            color: _muted,
                            fontSize: 13,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: _muted,
                    ),
                    onPressed: () => setState(() => _replyMessage = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
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
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFFE53935),
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
                    borderRadius: BorderRadius.circular(24),
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
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (!_isSending)
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withOpacity(0.32),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
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
                    size: 23,
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
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.22)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
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

/// Streams live typing state from `groups/{groupId}/typing` and renders
/// an animated indicator above the composer.
class _TypingIndicator extends StatelessWidget {
  final String groupId;
  final String currentUid;
  final Color muted;

  const _TypingIndicator({
    required this.groupId,
    required this.currentUid,
    required this.muted,
  });

  Stream<List<String>> _typingStream() {
    return FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('typing')
        .where('isTyping', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final staleThreshold = DateTime.now().subtract(const Duration(seconds: 8));
      final names = <String>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final uid = (data['uid'] ?? '').toString();
        if (uid == currentUid) continue; // never show self
        final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
        if (updatedAt == null || updatedAt.isBefore(staleThreshold)) continue;
        final name = (data['displayName'] ?? '').toString().trim();
        if (name.isNotEmpty) names.add(name.split(' ').first); // first name only
      }
      return names;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: _typingStream(),
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
              _BouncingDots(color: muted),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: muted,
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
