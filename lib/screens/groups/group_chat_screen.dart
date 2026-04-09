import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/gestures.dart';

import '../../core/theme/app_colors.dart';
import '../../models/group_model.dart';
import '../../services/group_service.dart';
import 'group_details_screen.dart';
import 'invite_group_screen.dart';

class GroupChatScreen extends StatefulWidget {
  final GroupModel group;

  const GroupChatScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
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

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _isDark ? const Color(0xFF0B0D12) : const Color(0xFFF4F5F7);
  Color get _headerBg => _isDark ? const Color(0xFF121722) : Colors.white;
  Color get _surface => _isDark ? const Color(0xFF171C25) : Colors.white;
  Color get _soft => _isDark ? const Color(0xFF10141C) : const Color(0xFFF2F4F7);
  Color get _text => _isDark ? AppColors.textPrimary : Colors.black87;
  Color get _muted => _isDark ? AppColors.textSecondary : Colors.black54;
  Color get _border => _isDark ? Colors.white.withOpacity(0.07) : Colors.black12;

  Future<void> _fetchUserIfNeeded(String userId) async {
    if (userId.isEmpty || _userCache.containsKey(userId)) return;
    _userCache[userId] = {};
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null && mounted) {
        setState(() {
          _userCache[userId] = doc.data()!;
        });
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر اختيار الصورة. تأكد من إعطاء الصلاحيات.')),
        );
      }
    }
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    setState(() => _isSending = true);

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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    int hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    String period = 'ص';

    if (hour >= 12) {
      period = 'م';
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
        const SnackBar(content: Text('المالك لا يمكنه المغادرة قبل نقل الملكية')),
      );
      return;
    }

    try {
      await GroupService.leaveGroup(widget.group.id);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لقد غادرت المجموعة')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء مغادرة المجموعة')),
        );
      }
    }
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'mute':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم كتم الإشعارات')),
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
                        ? 'تم تفعيل دردشة الأعضاء'
                        : 'تم إيقاف دردشة الأعضاء',
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
      backgroundColor: _bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(66),
        child: Container(
          decoration: BoxDecoration(
            color: _headerBg,
            border: Border(
              bottom: BorderSide(color: _border),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isDark ? 0.18 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: AppBar(
              titleSpacing: 0,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: _text,
                ),
                onPressed: () {
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
              title: _isSearching
                  ? TextField(
                controller: _searchController,
                autofocus: true,
                cursorColor: AppColors.primary,
                style: TextStyle(
                  color: _text,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: "ابحث في المحادثة...",
                  hintStyle: TextStyle(
                    color: _muted.withOpacity(0.7),
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: _soft,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: _border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (val) =>
                    setState(() => _searchQuery = val.trim()),
              )
                  : GestureDetector(
                onTap: _openDetails,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 4,
                    bottom: 4,
                    right: 8,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                        AppColors.primary.withOpacity(0.14),
                        backgroundImage: widget.group.imageUrl.isNotEmpty
                            ? NetworkImage(widget.group.imageUrl)
                            : null,
                        child: widget.group.imageUrl.isEmpty
                            ? Text(
                          widget.group.name.isNotEmpty
                              ? widget.group.name.substring(0, 1).toUpperCase()
                              : 'M',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.group.name.isEmpty
                                  ? 'الدردشة'
                                  : widget.group.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16.5,
                                color: _text,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${_membersCount > 0 ? '$_membersCount أعضاء • ' : ''}${widget.group.specializationName}".trim(),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _muted.withOpacity(0.9),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (_isSearching)
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: _text),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  )
                else
                  IconButton(
                    icon: Icon(Icons.search_rounded, color: _muted),
                    onPressed: () => setState(() => _isSearching = true),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoadingRole
          ? const Center(child: CircularProgressIndicator())
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
                      'تعذر تحميل الرسائل',
                      style: TextStyle(color: _muted),
                    ),
                  );
                }

                var docs = snapshot.data?.docs ?? [];

                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  docs = docs.where((doc) {
                    final data =
                    doc.data() as Map<String, dynamic>;
                    final text =
                    (data['text'] ?? '').toString().toLowerCase();
                    return text.contains(query);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return _searchQuery.isNotEmpty
                      ? Center(
                    child: Text(
                      "لا توجد نتائج مطابقة",
                      style: TextStyle(
                        color: _muted,
                        fontSize: 16,
                      ),
                    ),
                  )
                      : const _EmptyChatState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.only(
                    top: 16,
                    bottom: 12,
                    left: 12,
                    right: 12,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data =
                    doc.data() as Map<String, dynamic>;
                    final messageId = doc.id;
                    final myId = _auth.currentUser?.uid;
                    final senderId = data['senderId'] ?? '';
                    final isMe = myId != null && myId == senderId;

                    return _buildMessageBubble(
                      data,
                      messageId,
                      isMe,
                    );
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
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isDark ? 0.16 : 0.05),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Icon(
                Icons.lock_rounded,
                size: 48,
                color: _muted.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'يجب الانضمام للمجموعة',
              style: TextStyle(
                color: _text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'هذا مجتمع خاص بأعضائه، يرجى عرض معلومات المجموعة وطلب الانضمام للمشاركة.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted.withOpacity(0.9),
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 14,
                ),
                elevation: 0,
              ),
              onPressed: _openDetails,
              child: const Text(
                'عرض معلومات المجموعة',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
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
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.reply_rounded, color: _text),
              title: Text(
                'رد',
                style: TextStyle(color: _text, fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyMessage = {
                    'id': messageId,
                    'text': (data['text'] != null &&
                        data['text'].toString().isNotEmpty)
                        ? data['text']
                        : 'صورة مرفقة',
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
                isSaved ? 'إزالة من المحفوظات' : 'حفظ بنجمة',
                style: TextStyle(color: _text, fontSize: 16),
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
                        const SnackBar(content: Text('تمت إزالة الرسالة')),
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
                        const SnackBar(content: Text('تم حفظ الرسالة')),
                      );
                    }
                  }
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(
                        content: Text('فشلت العملية، يرجى المحاولة لاحقاً'),
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
      bool isMe,
      ) {
    final text = data['text'] ?? '';
    final imageUrl = data['imageUrl'] as String?;
    final senderId = data['senderId'] ?? '';

    _fetchUserIfNeeded(senderId);
    final cachedUser = _userCache[senderId];

    String senderName = data['senderName']?.toString() ?? 'عضو';
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
      senderAvatarUrl = (cachedUser['photoUrl']?.toString() ??
          cachedUser['imageUrl']?.toString() ??
          senderAvatarUrl)
          .trim();
    }

    if (senderName.contains('@')) senderName = senderName.split('@').first;

    final timestamp = data['createdAt'] as Timestamp?;
    const primaryColor = Color(0xFFD4AF37);

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

    final String? replyToText = data['replyToText'];
    final String? replyToSender = data['replyToSender'];

    final messageContent = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.82,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? (_isDark
            ? primaryColor.withOpacity(0.10)
            : AppColors.primary)
            : _surface,
        border: Border.all(
          color: _isDark
              ? (isMe
              ? primaryColor.withOpacity(0.22)
              : Colors.white.withOpacity(0.06))
              : Colors.transparent,
        ),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isMe ? 20 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.10 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                senderName,
                style: TextStyle(
                  fontSize: 14,
                  color: senderColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          if (replyToText != null) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.only(
                right: 10,
                left: 10,
                top: 4,
                bottom: 6,
              ),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: senderColor, width: 3.5),
                ),
                color: senderColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    replyToSender ?? "رد",
                    style: TextStyle(
                      color: senderColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    replyToText,
                    style: TextStyle(
                      color: _muted,
                      fontSize: 13,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
          if (imageUrl != null && imageUrl.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                bottom: text.isNotEmpty ? 6.0 : 2.0,
                top: 2,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 150,
                      width: double.infinity,
                      color: _soft,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),
              ),
            ),
          if (text.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                _buildMessageText(text, isMe),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isMe
                          ? (_isDark
                          ? primaryColor.withOpacity(0.72)
                          : Colors.white70)
                          : _muted.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          if (text.isEmpty && imageUrl != null)
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: _muted.withOpacity(0.85),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return GestureDetector(
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
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment:
          isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 17,
                backgroundColor: senderColor.withOpacity(0.15),
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
            Flexible(child: messageContent),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageText(String text, bool isMe) {
    final textColor = isMe
        ? (_isDark ? Colors.white.withOpacity(0.95) : Colors.white)
        : _text;
    final textStyle = TextStyle(
      fontSize: 15.5,
      color: textColor,
      height: 1.4,
      fontWeight: FontWeight.w500,
    );

    if (!text.contains('edumate://invite')) {
      return Text(text, style: textStyle);
    }

    final linkRegExp = RegExp(
      r'(edumate:\/\/invite\?[^\s]+)',
      caseSensitive: false,
    );
    final matches = linkRegExp.allMatches(text);
    if (matches.isEmpty) {
      return Text(text, style: textStyle);
    }

    final List<TextSpan> spans = [];
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
                      builder: (_) => InviteGroupScreen(
                        groupId: groupId,
                        code: code,
                      ),
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
      text: TextSpan(style: textStyle, children: spans),
    );
  }

  Widget _buildInputArea() {
    if (_isBanned) {
      return _buildDisabledState(
        'عذراً، لقد تم حظرك من المشاركة في هذه المجموعة.',
        Icons.block_rounded,
        AppColors.error,
      );
    }
    if (_isMuted) {
      return _buildDisabledState(
        'لقد تم كتمك. لا يمكنك الإرسال حالياً.',
        Icons.mic_off_rounded,
        AppColors.warning,
      );
    }
    if (!_canSend) {
      return _buildDisabledState(
        'المجموعة للقراءة فقط',
        Icons.info_outline_rounded,
        AppColors.textSecondary,
      );
    }

    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.18 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: _soft,
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
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _replyMessage!['text'],
                          style: TextStyle(
                            color: _muted,
                            fontSize: 13,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: _muted),
                    onPressed: () => setState(() => _replyMessage = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          if (_selectedImage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8, left: 42),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _soft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      height: 50,
                      width: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "صورة مرفقة",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
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
              IconButton(
                onPressed: _pickImage,
                icon: Icon(
                  Icons.image_outlined,
                  color: _muted,
                  size: 28,
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  cursorColor: AppColors.primary,
                  style: TextStyle(
                    color: _text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: "اكتب رسالة...",
                    hintStyle: TextStyle(
                      color: _muted.withOpacity(0.75),
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: _soft,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: _border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isSending ? null : _send,
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFD4AF37),
                        Color(0xFFFFD700),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37)
                            .withOpacity(_isDark ? 0.18 : 0.26),
                        blurRadius: _isDark ? 10 : 14,
                        offset: const Offset(0, 4),
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
                fontWeight: FontWeight.w600,
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

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF171C25) : Colors.white;
    final text = isDark ? AppColors.textPrimary : Colors.black87;
    final muted = isDark ? AppColors.textSecondary : Colors.black54;
    final border = isDark ? Colors.white.withOpacity(0.07) : Colors.black12;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.16 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 20,
                color: muted,
              ),
              const SizedBox(width: 10),
              Text(
                'لا توجد رسائل بعد',
                style: TextStyle(
                  color: text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}