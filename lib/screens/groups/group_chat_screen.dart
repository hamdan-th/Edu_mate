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
import '../../models/group_membership_state.dart';
import 'group_details_screen.dart';
import 'invite_group_screen.dart';
import 'package:flutter/gestures.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).cardTheme.color,
            boxShadow: [BoxShadow(color: Theme.of(context).dividerColor.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 1))],
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: "ابحث في المحادثة...",
                  hintStyle: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Theme.of(context).textTheme.titleLarge?.color, letterSpacing: -0.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        "${_membersCount > 0 ? '$_membersCount أعضاء • ' : ''}${widget.group.specializationName}".trim(),
                        style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7), height: 1.1),
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
            decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Theme.of(context).dividerColor.withOpacity(0.05), blurRadius: 16)]),
            child: Icon(Icons.lock_rounded, size: 48, color: Theme.of(context).iconTheme.color?.withOpacity(0.8)),
          ),
          const SizedBox(height: 24),
          Text(
            'يجب الانضمام للمجموعة',
            style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontSize: 20, fontWeight: FontWeight.w800),
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
              backgroundColor: Theme.of(context).primaryColor,
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
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor ?? Theme.of(context).cardTheme.color,
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
        color: isMe ? Theme.of(context).primaryColor : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 6),
          bottomRight: Radius.circular(isMe ? 6 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).dividerColor.withOpacity(0.05),
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
                _buildMessageText(text),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 1, top: 4),
                  child: Text(_formatTimestamp(timestamp), style: TextStyle(fontSize: 11, color: isMe ? Colors.white70 : Theme.of(context).textTheme.bodySmall?.color, letterSpacing: 0.1)),
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

  Widget _buildMessageText(String text) {
    if (!text.contains('edumate://invite')) {
      return Text(text, style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4));
    }
    
    final RegExp linkRegExp = RegExp(r'(edumate:\/\/invite\?[^\s]+)', caseSensitive: false);
    final matches = linkRegExp.allMatches(text);
    if (matches.isEmpty) {
      return Text(text, style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4));
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
          style: const TextStyle(color: Color(0xFF64B5F6), decoration: TextDecoration.underline),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              final uri = Uri.tryParse(url);
              if (uri != null) {
                final groupId = uri.queryParameters['groupId'];
                final code = uri.queryParameters['code'];
                if (groupId != null && code != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => InviteGroupScreen(groupId: groupId, code: code)));
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
        style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4),
        children: spans,
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
       return _buildDisabledState('المجموعة للقراءة فقط', Icons.info_outline_rounded, AppColors.textSecondary);
    }

    return Container(
      padding: EdgeInsets.only(
        left: 8, right: 8, top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).bottomSheetTheme.backgroundColor ?? Theme.of(context).cardTheme.color,
        boxShadow: [BoxShadow(color: Theme.of(context).dividerColor.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -1))],
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
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  cursorColor: Colors.white,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: "اكتب رسالة...",
                    hintStyle: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    color: Theme.of(context).primaryColor,
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
        color: Theme.of(context).cardTheme.color,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
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
                color: Theme.of(context).cardTheme.color?.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'لا توجد رسائل بعد',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
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