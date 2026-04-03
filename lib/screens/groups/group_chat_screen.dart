import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../core/theme/app_colors.dart';
import '../../models/group_model.dart';
import '../../services/group_service.dart';
import 'group_details_screen.dart';
import 'manage_members_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingRole = false);
      return;
    }

    bool canSend = widget.group.membersCanChat;
    bool owner = widget.group.ownerId == user.uid;
    bool admin = false;
    bool banned = false;
    bool muted = false;
    bool member = false;

    // Fetch freshest group data to ensure membersCanChat is strictly accurate real-time
    try {
      final grpDoc = await _firestore.collection('groups').doc(widget.group.id).get();
      if (grpDoc.exists) {
         canSend = grpDoc.data()?['membersCanChat'] ?? canSend;
      }
    } catch (_) {}

    if (owner) {
      canSend = true;
      member = true;
    }

    try {
      final doc = await _firestore
          .collection('groups')
          .doc(widget.group.id)
          .collection('members')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        member = true;
        final role = doc.data()?['role'];
        final status = doc.data()?['status'];

        if (status == 'banned') {
          banned = true;
          canSend = false;
        } else if (status == 'muted') {
          muted = true;
          canSend = false;
        }

        if (role == 'admin' || role == 'owner') {
          if (!banned) canSend = true;
          if (role == 'admin') admin = true;
          if (role == 'owner') owner = true;
        } else {
          // Double verification on real-time canSend vs banned/muted limitations
          if (!canSend && !banned && !muted) {
            canSend = false; // it is already false if chat is locked and not admin
          } else if (banned || muted) {
            canSend = false;
          }
        }
      }
    } catch (e) {
      // Ignore gracefully
    }

    if (mounted) {
      setState(() {
        _isMember = member;
        _canSend = canSend;
        _isOwner = owner;
        _isAdmin = admin;
        _isBanned = banned;
        _isMuted = muted;
        _isLoadingRole = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
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

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      String senderName = 'عضو';
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data() != null && userDoc.data()!.containsKey('name')) {
          senderName = userDoc.data()!['name'];
        }
      } catch (_) {}

      String? imageUrl;
      if (_selectedImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('groups_chat')
            .child(widget.group.id)
            .child('${DateTime.now().millisecondsSinceEpoch}_${user.uid}.jpg');
        final uploadTask = await ref.putFile(_selectedImage!);
        imageUrl = await uploadTask.ref.getDownloadURL();
      }

      await _firestore
          .collection('groups')
          .doc(widget.group.id)
          .collection('messages')
          .add({
        'text': text,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'senderId': user.uid,
        'senderName': senderName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
      setState(() {
        _selectedImage = null;
      });

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
        const SnackBar(content: Text('حدث خطأ أثناء الإرسال')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    int hour = date.hour;
    String minute = date.minute.toString().padLeft(2, '0');
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المالك لا يمكنه المغادرة قبل نقل الملكية')));
      return;
    }

    try {
      await GroupService.leaveGroup(widget.group.id);
          
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لقد غادرت المجموعة')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء مغادرة المجموعة')));
      }
    }
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'info':
        _openDetails();
        break;
      case 'mute':
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم كتم الإشعارات')));
        break;
      case 'members':
        Navigator.push(context, MaterialPageRoute(builder: (_) => ManageMembersScreen(group: widget.group)));
        break;
      case 'link':
        String link = widget.group.inviteLink;
        if (link.isEmpty) {
          link = 'edu_mate://group/${widget.group.id}';
        }
        Clipboard.setData(ClipboardData(text: link));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ رابط الدعوة الخاص')));
        break;
      case 'settings':
        _openDetails();
        break;
      case 'toggle_chat':
        try {
          final doc = await _firestore.collection('groups').doc(widget.group.id).get();
          if (doc.exists) {
            final current = doc.data()?['membersCanChat'] ?? true;
            await doc.reference.update({'membersCanChat': !current});
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(!current ? 'تم تفعيل دردشة الأعضاء' : 'تم إيقاف دردشة الأعضاء')));
            // Force re-check to update text box input area immediately without hot reloading
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
      backgroundColor: const Color(0xFFF4F5F7), // Authentic Telegram-like soft background
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GestureDetector(
          onTap: _openDetails,
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.inputFill,
                backgroundImage: widget.group.imageUrl.isNotEmpty ? NetworkImage(widget.group.imageUrl) : null,
                child: widget.group.imageUrl.isEmpty
                    ? Text(
                        widget.group.name.isNotEmpty ? widget.group.name.substring(0, 1).toUpperCase() : 'M',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.group.name.isEmpty ? 'الدردشة' : widget.group.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary, height: 1.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.group.specializationName,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: _handleMenuAction,
            itemBuilder: (context) {
              return [
                const PopupMenuItem(value: 'info', child: Text("معلومات المجموعة")),
                if (_isMember && !_isOwner && !_isAdmin) ...[
                  const PopupMenuItem(value: 'mute', child: Text("كتم الإشعارات")),
                ],
                if (_isOwner || _isAdmin) ...[
                  const PopupMenuItem(value: 'members', child: Text("إدارة الأعضاء")),
                  const PopupMenuItem(value: 'link', child: Text("رابط المجموعة")),
                  const PopupMenuItem(value: 'settings', child: Text("تعديل المجموعة")),
                  const PopupMenuItem(value: 'toggle_chat', child: Text("تفعيل/إيقاف دردشة الأعضاء")),
                ],
                if (_isMember) ...[
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'leave', child: Text("مغادرة المجموعة", style: TextStyle(color: AppColors.error))),
                ],
              ];
            },
          ),
        ],
      ),
      body: _isLoadingRole
          ? const Center(child: CircularProgressIndicator())
          : !_isMember
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_rounded, size: 54, color: AppColors.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'يجب الانضمام أولاً',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'لا يمكنك مشاهدة الرسائل أو التفاعل بدون عضوية في المجتمع.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          elevation: 0,
                        ),
                        onPressed: _openDetails,
                        child: const Text('عرض معلومات المجموعة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('تعذر تحميل الرسائل', style: TextStyle(color: AppColors.textSecondary)));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const _EmptyChatState();
                }

                return ListView.separated(
                  controller: _scrollController,
                  reverse: true, // Auto scrolls and shows latest at bottom
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final myId = _auth.currentUser?.uid;
                    final senderId = data['senderId'] ?? '';
                    final isMe = myId != null && myId == senderId;
                    
                    return _buildMessageBubble(data, isMe);
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

  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe) {
    final text = data['text'] ?? '';
    final imageUrl = data['imageUrl'] as String?;
    final senderName = data['senderName'] ?? 'عضو';
    final timestamp = data['createdAt'] as Timestamp?;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 6),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFE3F2FD) : Colors.white, // Clean soft blue for me, crisp white for others
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 2), // Sharper edge corresponding to Telegram
            bottomRight: Radius.circular(isMe ? 2 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 2,
              offset: const Offset(0, 1),
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
                child: Text(senderName, style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            if (imageUrl != null && imageUrl.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: text.isNotEmpty ? 6.0 : 0.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 150, width: double.infinity,
                        color: AppColors.inputFill,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                  ),
                ),
              ),
            if (text.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(text, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.3)),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(_formatTimestamp(timestamp), style: TextStyle(fontSize: 10, color: AppColors.textSecondary.withOpacity(0.8))),
                  ),
                ],
              ),
            if (text.isEmpty && imageUrl != null)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_formatTimestamp(timestamp), style: TextStyle(fontSize: 10, color: AppColors.textSecondary.withOpacity(0.8))),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    if (_isBanned) {
      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.block_rounded, color: AppColors.error, size: 20),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'عذراً، لقد تم حظرك من المشاركة في هذه المجموعة.',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isMuted) {
      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.mic_off_rounded, color: AppColors.warning, size: 20),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'لقد تم كتمك. لا يمكنك الإرسال حالياً.',
                  style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_canSend) {
      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.campaign_rounded, color: AppColors.textSecondary, size: 20),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'المجموعة للإعلانات فقط، المشرفون هم من يمكنهم الإرسال.',
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedImage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_selectedImage!, height: 40, width: 40, fit: BoxFit.cover)),
                    const SizedBox(width: 12),
                    const Expanded(child: Text("صورة مرفقة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.error), onPressed: () => setState(() => _selectedImage = null)),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.attach_file_rounded, color: AppColors.textSecondary, size: 28), // Telegram attachment placement
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.background, // Contrast against clean white bottom bar
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'رسالة',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        isDense: true,
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
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 54,
                color: AppColors.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لا توجد رسائل بعد',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'كن أول من يبدأ النقاش في هذا المجتمع، وشارك أفكارك مع الأعضاء.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}