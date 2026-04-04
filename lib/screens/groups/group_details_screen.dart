import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/group_message_model.dart';
import '../../models/group_model.dart';
import '../../core/theme/app_colors.dart';
import '../../services/group_service.dart';
import 'manage_members_screen.dart';
import 'group_chat_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final GroupModel group;
  final bool startEditing;

  const GroupDetailsScreen({super.key, required this.group, this.startEditing = false});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  bool _isLoadingRole = true;
  bool _isJoining = false;
  bool _isMember = false;
  bool _isOwner = false;
  bool _isAdmin = false;
  bool _isEditing = false;
  bool _isNotificationMuted = false;
  
  late String _groupName;
  late String _groupDescription;
  int _membersCount = 0;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.startEditing;
    _groupName = widget.group.name;
    _groupDescription = widget.group.description;
    
    _nameController.text = _groupName;
    _descController.text = _groupDescription;
    _loadMembershipState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadMembershipState() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingRole = false);
      return;
    }

    bool member = false;
    bool owner = widget.group.ownerId == user.uid;
    bool admin = false;
    int count = 0;

    if (owner) {
      member = true;
    }

    try {
      final membersCol = _firestore.collection('groups').doc(widget.group.id).collection('members');
      final doc = await membersCol.doc(user.uid).get();

      if (doc.exists) {
        member = true;
        final role = doc.data()?['role'] ?? 'member';
        if (role == 'admin') admin = true;
        if (role == 'owner') owner = true;
        
        final notificationsMuted = doc.data()?['notificationsMuted'];
        if (notificationsMuted == true) {
          _isNotificationMuted = true;
        }
      }
      
      final membersSnap = await membersCol.get();
      count = membersSnap.docs.length;
      
    } catch (e) {
      // safe fallback
    }

    if (mounted) {
      setState(() {
        _isMember = member;
        _isOwner = owner;
        _isAdmin = admin;
        _membersCount = count;
        _isLoadingRole = false;
      });
    }
  }

  Future<void> _joinPublicGroup() async {
    setState(() => _isJoining = true);
    try {
      await GroupService.joinPublicGroup(widget.group.id);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GroupChatScreen(group: widget.group)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
        setState(() => _isJoining = false);
      }
    }
  }

  Future<void> _saveEdits() async {
    final newName = _nameController.text.trim();
    final newDesc = _descController.text.trim();
    
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اسم المجموعة مطلوب')));
      return;
    }

    try {
      await _firestore.collection('groups').doc(widget.group.id).update({
        'name': newName,
        'description': newDesc,
      });

      if (mounted) {
        setState(() {
          _groupName = newName;
          _groupDescription = newDesc;
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الحفظ')));
      }
    }
  }

  void _toggleMute() async {
    setState(() {
      _isNotificationMuted = !_isNotificationMuted;
    });
    
    if (!_isMember) return;
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('groups').doc(widget.group.id).collection('members').doc(user.uid).update({
          'notificationsMuted': _isNotificationMuted
        });
      }
    } catch (e) {}

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isNotificationMuted ? 'تم كتم الإشعارات' : 'تم تفعيل الإشعارات')),
    );
  }

  Future<void> _leaveGroup() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المالك لا يمكنه المغادرة، قم بنقل الملكية أولاً')));
      return;
    }

    try {
      await GroupService.leaveGroup(widget.group.id);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت المغادرة بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء مغادرة المجموعة')));
      }
    }
  }

  void _openMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 48, height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 16),
              
              ListTile(
                leading: const Icon(Icons.report_problem_rounded, color: AppColors.textPrimary),
                title: const Text("إبلاغ", style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم استلام البلاغ')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.cleaning_services_rounded, color: AppColors.textPrimary),
                title: const Text("مسح سجل الدردشة", style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قريباً')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_rounded, color: AppColors.textPrimary),
                title: const Text("نسخ الرابط", style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  String link = widget.group.inviteLink.isEmpty ? 'edu_mate://group/${widget.group.id}' : widget.group.inviteLink;
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الرابط')));
                },
              ),
              
              if (_isOwner || _isAdmin) ...[
                const Divider(color: AppColors.background, thickness: 8),
                ListTile(
                  leading: const Icon(Icons.people_alt_rounded, color: AppColors.textPrimary),
                  title: const Text("إدارة الأعضاء", style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ManageMembersScreen(group: widget.group)));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: AppColors.textPrimary),
                  title: const Text("تعديل المجموعة", style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _isEditing = true);
                  },
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
            onPressed: () => setState(() => _isEditing = false),
          ),
          title: const Text("تعديل", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          actions: [
            TextButton(
              onPressed: _saveEdits,
              child: const Text("حفظ", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 64,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: widget.group.imageUrl.isNotEmpty ? NetworkImage(widget.group.imageUrl) : null,
                child: const Align(
                  alignment: Alignment.bottomRight,
                  child: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 20,
                    child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "اسم المجموعة",
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "الوصف",
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
    ));
    }

    if (_isLoadingRole) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (!_isMember) {
      return _buildPreviewView();
    }

    return _buildMemberView();
  }

  Widget _buildPreviewView() {
    return Scaffold(
      backgroundColor: const Color(0xFFEBEBEB),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.3),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          color: AppColors.surface,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 56, bottom: 40),
          child: Column(
            children: [
              CircleAvatar(
                radius: 64,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: widget.group.imageUrl.isNotEmpty ? NetworkImage(widget.group.imageUrl) : null,
                child: widget.group.imageUrl.isEmpty
                    ? Text(
                        _groupName.isNotEmpty ? _groupName[0].toUpperCase() : 'M',
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primary),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _groupName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "$_membersCount عضو",
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    "${widget.group.collegeName} • ${widget.group.specializationName}",
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.group.isPublic ? AppColors.success.withOpacity(0.12) : AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.group.isPublic ? Icons.public_rounded : Icons.lock_rounded, size: 14, color: widget.group.isPublic ? AppColors.success : AppColors.warning),
                    const SizedBox(width: 6),
                    Text(
                      widget.group.isPublic ? "مجموعة عامة" : "مجموعة خاصة",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: widget.group.isPublic ? AppColors.success : AppColors.warning),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_groupDescription.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _groupDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 32),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isJoining ? null : _joinPublicGroup,
                    child: _isJoining
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("انضمام للمجموعة", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberView() {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFEBEBEB),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.3),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 48, bottom: 20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage: widget.group.imageUrl.isNotEmpty ? NetworkImage(widget.group.imageUrl) : null,
                        child: widget.group.imageUrl.isEmpty
                            ? Text(
                                _groupName.isNotEmpty ? _groupName[0].toUpperCase() : 'M',
                                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _groupName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "$_membersCount عضو",
                        style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                      if (_groupDescription.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            _groupDescription,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionItem(_isNotificationMuted ? Icons.notifications_off_rounded : Icons.notifications_rounded, _isNotificationMuted ? "تفعيل" : "كتم", _toggleMute),
                          _buildActionItem(Icons.search_rounded, "بحث", () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("هذه الميزة غير متوفرة بعد")));
                          }),
                          _buildActionItem(Icons.exit_to_app_rounded, "مغادرة", _leaveGroup, color: AppColors.error),
                          _buildActionItem(Icons.more_horiz_rounded, "المزيد", _openMoreMenu),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 8)),
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  Container(
                    color: AppColors.surface,
                    child: const TabBar(
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      tabs: [
                        Tab(text: "الأعضاء"),
                        Tab(text: "الوسائط"),
                        Tab(text: "الروابط"),
                        Tab(text: "المحفوظات"),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: Container(
            color: AppColors.surface,
            child: TabBarView(
              children: [
                _buildMembersTab(),
                _buildMediaTab(),
                _buildLinksTab(),
                _buildSavedMessagesTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap, {Color color = AppColors.primary}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    if (!_isMember) {
      return _buildEmptyState(Icons.lock_rounded, "يجب الانضمام للمجموعة لرؤية الأعضاء");
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('groups').doc(widget.group.id).collection('members').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildEmptyState(Icons.error_outline_rounded, "حدث خطأ أثناء تحميل الأعضاء");
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyState(Icons.group_rounded, "لا يوجد أعضاء في هذه المجموعة");
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 40),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            String name = (data['username']?.toString() ?? data['fullName']?.toString() ?? data['displayName']?.toString() ?? data['name']?.toString() ?? 'عضو').trim();
            if (name.contains('@')) name = name.split('@').first;
            final imageUrl = data['imageUrl'] ?? data['photoUrl'];
            final role = data['role'] ?? 'member';
            final status = data['status'] ?? 'active';

            String roleStr = "عضو";
            Color roleCol = AppColors.primary;
            Widget roleIcon = const SizedBox.shrink();

            if (role == 'owner') {
              roleStr = "مالك";
              roleCol = AppColors.error;
              roleIcon = const Icon(Icons.workspace_premium, color: Colors.purple, size: 18);
            } else if (role == 'admin') {
              roleStr = "مشرف";
              roleCol = AppColors.warning;
              roleIcon = const Icon(Icons.headset_mic, color: Colors.orange, size: 18);
            }

            String statusStr = status == 'muted' ? " (مكتوم)" : (status == 'banned' ? " (محظور)" : "");

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                child: imageUrl == null || imageUrl.isEmpty
                    ? Text(name.isNotEmpty ? name[0] : 'M', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))
                    : null,
              ),
              title: Row(
                children: [
                  Flexible(child: Text(name + statusStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  const SizedBox(width: 6),
                  roleIcon,
                ],
              ),
              subtitle: Text(roleStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              trailing: role != 'member' ? Text(roleStr, style: TextStyle(color: roleCol, fontWeight: FontWeight.w900, fontSize: 12)) : null,
            );
          },
        );
      },
    );
  }

  Widget _buildSavedMessagesTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: GroupService.streamSavedMessages(widget.group.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return const Center(child: Text("حدث خطأ في تحميل المحفوظات", style: TextStyle(color: AppColors.textSecondary)));
        }
        
        final msgs = snapshot.data ?? [];
        if (msgs.isEmpty) {
          return _buildEmptyState(Icons.bookmark_rounded, "لا توجد رسائل محفوظة");
        }

        return ListView.separated(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: msgs.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFEBEBEB)),
          itemBuilder: (context, index) {
            final msg = msgs[index];
            final timestamp = msg['createdAt'] as Timestamp?;
            final dateStr = timestamp != null ? "${timestamp.toDate().day}/${timestamp.toDate().month} - ${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}" : "";
            
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.12), shape: BoxShape.circle),
                child: const Icon(Icons.star_rounded, color: AppColors.warning, size: 22),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(msg['senderName'] ?? 'عضو', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                  if (dateStr.isNotEmpty)
                    Text(dateStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(msg['text'] ?? 'رسالة', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.4)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.border),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMediaTab() {
    return StreamBuilder<List<GroupMessageModel>>(
      stream: GroupService.streamMessages(widget.group.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        if (snapshot.hasError) return const Center(child: Text("خطأ في تحميل الوسائط", style: TextStyle(color: AppColors.textSecondary)));

        final msgs = snapshot.data ?? [];
        final mediaMsgs = msgs.where((m) => m.imageUrl != null && m.imageUrl!.isNotEmpty).toList();

        if (mediaMsgs.isEmpty) return _buildEmptyState(Icons.photo_library_rounded, "لا توجد وسائط");

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: mediaMsgs.length,
          itemBuilder: (context, index) {
            final url = mediaMsgs[index].imageUrl!;
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null ? child : Container(color: Colors.white10),
                errorBuilder: (context, error, stack) => Container(color: AppColors.surface, child: const Icon(Icons.broken_image, color: AppColors.textSecondary)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLinksTab() {
    return StreamBuilder<List<GroupMessageModel>>(
      stream: GroupService.streamMessages(widget.group.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        if (snapshot.hasError) return const Center(child: Text("خطأ في تحميل الروابط", style: TextStyle(color: AppColors.textSecondary)));

        final RegExp urlRegExp = RegExp(r'(https?:\/\/[^\s]+)', caseSensitive: false);
        final msgs = snapshot.data ?? [];
        
        // Filter messages that contain a link
        final linkMsgs = msgs.where((m) => urlRegExp.hasMatch(m.text)).toList();

        if (linkMsgs.isEmpty) return _buildEmptyState(Icons.link_rounded, "لا توجد روابط");

        return ListView.separated(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: linkMsgs.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFEBEBEB)),
          itemBuilder: (context, index) {
            final msg = linkMsgs[index];
            final match = urlRegExp.firstMatch(msg.text);
            final url = match?.group(0) ?? '';
            
            final timestamp = msg.createdAt;
            final dateStr = timestamp != null ? "${timestamp.day}/${timestamp.month} - ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}" : "";
            
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), shape: BoxShape.circle),
                child: const Icon(Icons.link_rounded, color: AppColors.primary, size: 22),
              ),
              title: Text(msg.senderName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textSecondary)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              trailing: dateStr.isNotEmpty ? Text(dateStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)) : null,
              onTap: () {
                // Future enhancement: launchUrl(Uri.parse(url))
              },
            );
          },
        );
      },
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTabBarDelegate(this.child);

  @override
  double get minExtent => 48.0;

  @override
  double get maxExtent => 48.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}
