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
    int count = 0;

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
      final membersCol = _firestore.collection('groups').doc(widget.group.id).collection('members');
      final membersSnap = await membersCol.get();
      count = membersSnap.docs.length;

      final doc = await membersCol.doc(user.uid).get();

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
        _membersCount = count;
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
      case 'mute':
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم كتم الإشعارات')));
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
      backgroundColor: const Color(0xFF0E1621), // Authentic Telegram Dark Theme
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: const Color(0xFF17212B),
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.3),
        leadingWidth: 44,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GestureDetector(
          onTap: _openDetails,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4, right: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  backgroundImage: widget.group.imageUrl.isNotEmpty ? NetworkImage(widget.group.imageUrl) : null,
                  child: widget.group.imageUrl.isEmpty
                      ? Text(
                          widget.group.name.isNotEmpty ? widget.group.name.substring(0, 1).toUpperCase() : 'M',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
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
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.white, letterSpacing: -0.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        "${_membersCount > 0 ? '$_membersCount أعضاء • ' : ''}${widget.group.specializationName}".trim(),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF7F8B98), height: 1.1),
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
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Color(0xFF7F8B98)),
            onPressed: () {},
          )
        ],
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

                          return ListView.builder(
                            controller: _scrollController,
                            reverse: true, // Auto scrolls and shows latest at bottom
                            padding: const EdgeInsets.only(top: 16, bottom: 10, left: 16, right: 16),
                            itemCount: docs.length,
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

  Widget _buildNonMemberState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF17212B), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)]),
            child: Icon(Icons.lock_rounded, size: 48, color: const Color(0xFF7F8B98).withOpacity(0.6)),
          ),
          const SizedBox(height: 20),
          const Text(
            'يجب الانضمام للمجموعة',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'هذا مجتمع خاص بأعضائه، يرجى عرض معلومات المجموعة وطلب الانضمام للمشاركة.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF7F8B98), fontSize: 14, height: 1.4),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3390EC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              elevation: 0,
            ),
            onPressed: _openDetails,
            child: const Text('عرض معلومات المجموعة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe) {
    final text = data['text'] ?? '';
    final imageUrl = data['imageUrl'] as String?;
    String senderName = (data['username']?.toString() ?? data['fullName']?.toString() ?? data['displayName']?.toString() ?? data['name']?.toString() ?? data['senderName']?.toString() ?? 'عضو').trim();
    if (senderName.contains('@')) senderName = senderName.split('@').first;
    final timestamp = data['createdAt'] as Timestamp?;
    final senderAvatarUrl = data['senderAvatar'] as String? ?? data['senderImageUrl'] as String? ?? data['photoUrl'] as String?;

    final String? replyToData = data['replyTo']; // Placeholder for future reply support

    final messageContent = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF2B5278) : const Color(0xFF182533),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 1.5,
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
              padding: const EdgeInsets.only(bottom: 4, right: 2),
              child: Text(senderName, style: const TextStyle(fontSize: 14, color: Color(0xFF64B5F6), fontWeight: FontWeight.w700)),
            ),
          
          if (replyToData != null) ...[
            Container(
               width: double.infinity,
               margin: const EdgeInsets.only(bottom: 6),
               padding: const EdgeInsets.only(right: 8, left: 6, top: 2, bottom: 2),
               decoration: BoxDecoration(
                 border: const Border(right: BorderSide(color: Color(0xFF64B5F6), width: 3)),
                 color: const Color(0xFF64B5F6).withOpacity(0.1),
                 borderRadius: BorderRadius.circular(4),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text("رد على", style: TextStyle(color: Color(0xFF64B5F6), fontSize: 12, fontWeight: FontWeight.bold)),
                   Text(replyToData, style: const TextStyle(color: Colors.white70, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                 ],
               ),
            ),
          ],

          if (imageUrl != null && imageUrl.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: text.isNotEmpty ? 6.0 : 2.0, top: 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 150, width: double.infinity,
                      color: Colors.white.withOpacity(0.05),
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF64B5F6)),
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
                Text(text, style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.35)),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2, top: 4),
                  child: Text(_formatTimestamp(timestamp), style: TextStyle(fontSize: 11, color: const Color(0xFF7F8B98).withOpacity(0.9), letterSpacing: 0.1)),
                ),
              ],
            ),
          if (text.isEmpty && imageUrl != null)
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(_formatTimestamp(timestamp), style: const TextStyle(fontSize: 11, color: Color(0xFF7F8B98))),
              ),
            ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: senderAvatarUrl != null && senderAvatarUrl.isNotEmpty ? NetworkImage(senderAvatarUrl) : null,
              child: senderAvatarUrl == null || senderAvatarUrl.isEmpty
                  ? Text(senderName.isNotEmpty ? senderName[0] : 'M', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary))
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          messageContent,
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    if (_isBanned) {
      return _buildDisabledState('عذراً، لقد تم حظرك من المشاركة في هذه المجموعة.', Icons.block_rounded, AppColors.error);
    }
    if (_isMuted) {
       return _buildDisabledState('لقد تم كتمك. لا يمكنك الإرسال حالياً.', Icons.mic_off_rounded, AppColors.warning);
    }
    if (!_canSend) {
       return _buildDisabledState('المجموعة للإعلانات فقط، المشرفون هم من يمكنهم الإرسال.', Icons.campaign_rounded, AppColors.textSecondary);
    }

    return Container(
      padding: EdgeInsets.only(
        left: 8, right: 8, top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF17212B), // Dark input area
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.2))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedImage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFF242F3D), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]),
              child: Row(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_selectedImage!, height: 44, width: 44, fit: BoxFit.cover)),
                  const SizedBox(width: 12),
                  const Expanded(child: Text("صورة مرفقة", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white))),
                  IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.error), onPressed: () => setState(() => _selectedImage = null)),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: _pickImage,
                icon: const Icon(Icons.attach_file_rounded, color: Color(0xFF7F8B98), size: 28),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242F3D), // Dark input field
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'رسالة',
                      hintStyle: TextStyle(color: Color(0xFF7F8B98)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isSending ? null : _send,
                child: Container(
                  height: 44,
                  width: 44,
                  margin: const EdgeInsets.only(bottom: 0),
                  decoration: const BoxDecoration(
                    color: Color(0xFF3390EC), // Telegram blue
                    shape: BoxShape.circle,
                  ),
                  child: _isSending
                      ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              )
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
        top: 16, bottom: MediaQuery.of(context).padding.bottom + 16,
        left: 20, right: 20,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF17212B),
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              msg,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF17212B),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Icon(
                Icons.chat_rounded,
                size: 54,
                color: Color(0xFF3390EC),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لا توجد رسائل بعد',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'كن أول من يبدأ النقاش في هذا المجتمع، وشارك أفكارك مع الأعضاء.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF7F8B98),
                height: 1.5,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}