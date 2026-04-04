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
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Map<String, Map<String, dynamic>> _userCache = {};
  Map<String, dynamic>? _replyMessage;

  Future<void> _fetchUserIfNeeded(String userId) async {
    if (userId.isEmpty || _userCache.containsKey(userId)) return;
    _userCache[userId] = {}; // Optimistic lock to prevent infinite re-fetches
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
        if (_replyMessage != null) 'replyToId': _replyMessage!['id'],
        if (_replyMessage != null) 'replyToText': _replyMessage!['text'],
        if (_replyMessage != null) 'replyToSender': _replyMessage!['senderName'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
      setState(() {
        _selectedImage = null;
        _replyMessage = null;
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
      backgroundColor: const Color(0xFF0E1621), // Deep dark background fallback
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF17212B), // Telegram Header
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 1))],
          ),
          child: AppBar(
            titleSpacing: 0,
            backgroundColor: Colors.transparent,
            elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
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
                cursorColor: Colors.white,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'البحث في الرسائل...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              )
            : GestureDetector(
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
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Color(0xFF7F8B98)),
              onPressed: () => setState(() => _isSearching = true),
            )
        ],
      ),
      ),
      ),
      body: _isLoadingRole
          ? const Center(child: CircularProgressIndicator())
          : !_isMember
              ? _buildNonMemberState()
              : Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage('https://i.imgur.com/IGjZep0.jpg'), // Iconic dark Telegram chat wallpaper
                      fit: BoxFit.cover,
                      opacity: 0.15, // Subtle texture
                    ),
                  ),
                  child: Column(
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
                               return const Center(child: CircularProgressIndicator(color: Color(0xFF3390EC)));
                            }
  
                            if (snapshot.hasError) {
                               return const Center(child: Text('تعذر تحميل الرسائل', style: TextStyle(color: Color(0xFF7F8B98))));
                            }
  
                            // Apply Search Filter locally if active
                            var docs = snapshot.data?.docs ?? [];
                            
                            if (_searchQuery.isNotEmpty) {
                              final query = _searchQuery.toLowerCase();
                              docs = docs.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final text = (data['text'] ?? '').toString().toLowerCase();
                                return text.contains(query);
                              }).toList();
                            }
                            
                            if (docs.isEmpty) {
                               return _searchQuery.isNotEmpty
                                   ? const Center(child: Text("لا توجد نتائج مطابقة", style: TextStyle(color: Color(0xFF7F8B98), fontSize: 16)))
                                   : const _EmptyChatState();
                            }
  
                            return ListView.builder(
                              controller: _scrollController,
                              reverse: true,
                              padding: const EdgeInsets.only(top: 16, bottom: 12, left: 12, right: 12),
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final doc = docs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final messageId = doc.id;
                                final myId = _auth.currentUser?.uid;
                                final senderId = data['senderId'] ?? '';
                                final isMe = myId != null && myId == senderId;
                                
                                return _buildMessageBubble(data, messageId, isMe);
                              },
                            );
                          },
                        ),
                      ),
                      _buildInputArea(),
                    ],
                  ),
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
            decoration: BoxDecoration(color: const Color(0xFF17212B), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16)]),
            child: Icon(Icons.lock_rounded, size: 48, color: const Color(0xFF7F8B98).withOpacity(0.8)),
          ),
          const SizedBox(height: 24),
          const Text(
            'يجب الانضمام للمجموعة',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'هذا مجتمع خاص بأعضائه، يرجى عرض معلومات المجموعة وطلب الانضمام للمشاركة.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF7F8B98), fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3390EC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
              elevation: 0,
            ),
            onPressed: _openDetails,
            child: const Text('عرض معلومات المجموعة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(Map<String, dynamic> data, String messageId, String resolvedSenderName, bool isSaved) {
    final parentContext = context;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF17212B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.reply_rounded, color: Colors.white),
              title: const Text('رد', style: TextStyle(color: Colors.white, fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyMessage = {
                    'id': messageId,
                    'text': (data['text'] != null && data['text'].toString().isNotEmpty) ? data['text'] : 'صورة مرفقة',
                    'senderName': resolvedSenderName,
                  };
                });
              },
            ),
            ListTile(
              leading: Icon(isSaved ? Icons.star_border_rounded : Icons.star_rounded, color: Colors.amber),
              title: Text(isSaved ? 'إزالة من المحفوظات' : 'حفظ بنجمة', style: const TextStyle(color: Colors.white, fontSize: 16)),
              onTap: () async {
                Navigator.pop(context);
                try {
                  if (isSaved) {
                    await GroupService.unsaveMessage(groupId: widget.group.id, messageId: messageId);
                    if (mounted) ScaffoldMessenger.of(parentContext).showSnackBar(const SnackBar(content: Text('تمت إزالة الرسالة')));
                  } else {
                    await GroupService.saveMessage(groupId: widget.group.id, messageId: messageId, data: data);
                    if (mounted) ScaffoldMessenger.of(parentContext).showSnackBar(const SnackBar(content: Text('تم حفظ الرسالة')));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(parentContext).showSnackBar(const SnackBar(content: Text('فشلت العملية، يرجى المحاولة لاحقاً')));
                }
              },
            ),
          ],
        ),
      )
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> data, String messageId, bool isMe) {
    final text = data['text'] ?? '';
    final imageUrl = data['imageUrl'] as String?;
    final senderId = data['senderId'] ?? '';
    
    _fetchUserIfNeeded(senderId);
    final cachedUser = _userCache[senderId];
    
    String senderName = data['senderName']?.toString() ?? 'عضو';
    String senderAvatarUrl = data['senderAvatar'] as String? ?? data['senderImageUrl'] as String? ?? data['photoUrl'] as String? ?? '';

    if (cachedUser != null && cachedUser.isNotEmpty) {
      senderName = (cachedUser['username']?.toString() ?? cachedUser['fullName']?.toString() ?? cachedUser['displayName']?.toString() ?? cachedUser['name']?.toString() ?? senderName).trim();
      senderAvatarUrl = (cachedUser['photoUrl']?.toString() ?? cachedUser['imageUrl']?.toString() ?? senderAvatarUrl).trim();
    }
    
    if (senderName.contains('@')) senderName = senderName.split('@').first;
    
    final timestamp = data['createdAt'] as Timestamp?;

    final List<Color> _nameColors = [
      const Color(0xFFE53935), const Color(0xFFD81B60), const Color(0xFF8E24AA), 
      const Color(0xFF3949AB), const Color(0xFF039BE5), const Color(0xFF00897B), 
      const Color(0xFF7CB342), const Color(0xFFF4511E)
    ];
    final senderColor = _nameColors[senderName.length % _nameColors.length];
    
    final String? replyToText = data['replyToText'];
    final String? replyToSender = data['replyToSender'];

    final messageContent = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF2B5278) : const Color(0xFF182533),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 6),
          bottomRight: Radius.circular(isMe ? 6 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
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
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(senderName, style: TextStyle(fontSize: 14, color: senderColor, fontWeight: FontWeight.w800)),
            ),
          
          if (replyToText != null) ...[
            Container(
               width: double.infinity,
               margin: const EdgeInsets.only(bottom: 6),
               padding: const EdgeInsets.only(right: 10, left: 10, top: 4, bottom: 6),
               decoration: BoxDecoration(
                 border: Border(right: BorderSide(color: senderColor, width: 3.5)),
                 color: senderColor.withOpacity(0.12),
                 borderRadius: BorderRadius.circular(6),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(replyToSender ?? "رد", style: TextStyle(color: senderColor, fontSize: 13, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 2),
                   Text(replyToText, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.2), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                Text(text, style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4)),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 1, top: 4),
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

    return GestureDetector(
      onLongPress: () async {
        final isSaved = await GroupService.isMessageSaved(groupId: widget.group.id, messageId: messageId);
        if (!mounted) return;
        _showMessageOptions(data, messageId, senderName, isSaved);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 17,
                backgroundColor: senderColor.withOpacity(0.15),
                backgroundImage: senderAvatarUrl.isNotEmpty ? NetworkImage(senderAvatarUrl) : null,
                child: senderAvatarUrl.isEmpty
                    ? Text(senderName.isNotEmpty ? senderName[0] : 'M', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: senderColor))
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
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF17212B), // Dark input area Telegram style
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, -1))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFF242F3D), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4)]),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded, color: Color(0xFF64B5F6), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_replyMessage!['senderName'], style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 13, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(_replyMessage!['text'], style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFF7F8B98)), onPressed: () => setState(() => _replyMessage = null), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                ],
              ),
            ),
          if (_selectedImage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8, left: 42),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF242F3D), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)]),
              child: Row(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_selectedImage!, height: 50, width: 50, fit: BoxFit.cover)),
                  const SizedBox(width: 12),
                  const Expanded(child: Text("صورة مرفقة", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white))),
                  IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFFE53935)), onPressed: () => setState(() => _selectedImage = null)),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: _pickImage,
                icon: const Icon(Icons.image_outlined, color: Color(0xFF7F8B98), size: 28),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242F3D),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    cursorColor: const Color(0xFF3390EC),
                    style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.normal),
                    decoration: const InputDecoration(
                      hintText: 'رسالة',
                      hintStyle: TextStyle(color: Color(0xFF7F8B98), fontSize: 16),
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
                  decoration: const BoxDecoration(
                    color: Color(0xFF3390EC),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF182533).withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'لا توجد رسائل بعد',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}