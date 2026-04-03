import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class _GroupDetailsScreenState extends State<GroupDetailsScreen> with SingleTickerProviderStateMixin {
  bool _isLoadingRole = true;
  bool _isJoining = false;
  bool _isMember = false;
  bool _isOwner = false;
  bool _isAdmin = false;
  bool _isEditing = false;
  bool _isMuted = false;
  
  late String _groupName;
  late String _groupDescription;
  int _membersCount = 0;
  
  late TabController _tabController;
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
    
    _tabController = TabController(length: 4, vsync: this);
    _nameController.text = _groupName;
    _descController.text = _groupDescription;
    _loadMembershipState();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      }
      
      final membersSnap = await membersCol.get();
      count = membersSnap.docs.length;
      
    } catch (e) {
      // Gracefully continue
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

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isMuted ? 'تم كتم الإشعارات' : 'تم تفعيل الإشعارات')),
    );
  }

  Future<void> _leaveGroup() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المالك لا يمكنه المغادرة، يمكنك فقط نقل الملكية')));
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              
              _buildMenuItem(Icons.report_problem_rounded, "إبلاغ", () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم استلام البلاغ')));
              }),
              _buildMenuItem(Icons.cleaning_services_rounded, "مسح محتوى الدردشة", () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سيتم تفعيل الميزة قريباً')));
              }),
              _buildMenuItem(Icons.link_rounded, "رابط المجموعة", () {
                Navigator.pop(context);
                String link = widget.group.inviteLink.isEmpty ? 'edu_mate://group/${widget.group.id}' : widget.group.inviteLink;
                Clipboard.setData(ClipboardData(text: link));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الرابط')));
              }),
              
              if (_isOwner || _isAdmin) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: AppColors.background, thickness: 8),
                ),
                _buildMenuItem(Icons.people_alt_rounded, "إدارة الأعضاء", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ManageMembersScreen(group: widget.group)));
                }),
                _buildMenuItem(Icons.edit_rounded, "تعديل المجموعة", () {
                  Navigator.pop(context);
                  setState(() => _isEditing = true);
                }),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: AppColors.textPrimary, size: 28),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBEBEB), // Distinct light gray background for Telegram-like contrast
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.3),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: _isEditing ? _buildEditingView() : _buildProfileView(),
    );
  }

  Widget _buildProfileView() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: AppColors.surface, // Pure solid white top container
            width: double.infinity,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 56, bottom: 20),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 64, // Large prominent size
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
                
                // Details
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
                
                // Actions Row Strictly Under Header
                _isLoadingRole
                    ? const CircularProgressIndicator(color: AppColors.primary)
                    : !_isMember
                        ? Padding(
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
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionItem(
                                  _isMuted ? Icons.notifications_off_rounded : Icons.notifications_rounded,
                                  _isMuted ? "تفعيل" : "كتم",
                                  _toggleMute),
                              _buildActionItem(Icons.search_rounded, "بحث", () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("البحث غير متاح قريباً")));
                              }),
                              _buildActionItem(Icons.exit_to_app_rounded, "مغادرة", _leaveGroup, color: AppColors.error),
                              _buildActionItem(Icons.more_horiz_rounded, "المزيد", _openMoreMenu),
                            ],
                          ),
              ],
            ),
          ),
        ),
        
        // Tab Bar Section (Separate Block)
        SliverToBoxAdapter(
          child: const SizedBox(height: 8), // Gap between Header and Tabs
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _SliverAppBarDelegate(
            Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: "الأعضاء"),
                  Tab(text: "الوسائط"),
                  Tab(text: "الروابط"),
                  Tab(text: "المحفوظات"),
                ],
              ),
            ),
          ),
        ),
        
        // View Content
        SliverFillRemaining(
          child: Container(
            color: AppColors.surface,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMembersTab(),
                _buildEmptyState(Icons.photo_library_rounded, "لا توجد وسائط"),
                _buildEmptyState(Icons.link_rounded, "لا توجد روابط"),
                _buildEmptyState(Icons.bookmark_rounded, "لا توجد محفوظات"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditingView() {
    return Container(
      color: AppColors.surface,
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () => setState(() => _isEditing = false), child: const Text("إلغاء", style: TextStyle(color: AppColors.textSecondary, fontSize: 18))),
                  const Text("تعديل", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  TextButton(onPressed: _saveEdits, child: const Text("حفظ", style: TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 32),
            CircleAvatar(
              radius: 64,
              backgroundColor: AppColors.inputFill,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    decoration: InputDecoration(
                      labelText: "اسم المجموعة",
                      filled: true,
                      fillColor: const Color(0xFFF4F5F7),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
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
            ),
          ],
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
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    if (!_isMember) return _buildEmptyState(Icons.lock_rounded, "يجب الانضمام لرؤية الأعضاء");

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('groups').doc(widget.group.id).collection('members').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        if (snapshot.hasError) return _buildEmptyState(Icons.error_outline_rounded, "حدث خطأ");

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState(Icons.group_rounded, "لا يوجد أعضاء");

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 40),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final name = data['name'] ?? data['displayName'] ?? 'عضو';
            final imageUrl = data['imageUrl'] ?? data['photoUrl'];
            final role = data['role'] ?? 'member';
            final status = data['status'] ?? 'active';

            String roleStr = (role == 'owner') ? "مالك" : (role == 'admin' ? "مشرف" : "");
            Color roleCol = role == 'owner' ? AppColors.error : AppColors.warning;
            String statusStr = status == 'muted' ? " (مكتوم)" : (status == 'banned' ? " (محظور)" : "");

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                child: imageUrl == null || imageUrl.isEmpty ? Text(name[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)) : null,
              ),
              title: Text(name + statusStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text(roleStr.isNotEmpty ? roleStr : "عضو", style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              trailing: roleStr.isNotEmpty ? Text(roleStr, style: TextStyle(color: roleCol, fontWeight: FontWeight.w900, fontSize: 12)) : null,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.border),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverAppBarDelegate(this.child);

  @override
  double get minExtent => 50;
  @override
  double get maxExtent => 50;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
