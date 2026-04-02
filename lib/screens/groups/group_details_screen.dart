import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/group_model.dart';
import '../../core/theme/app_colors.dart';
import 'manage_members_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final GroupModel group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> with SingleTickerProviderStateMixin {
  bool _isLoadingRole = true;
  bool _isMember = false;
  bool _isOwner = false;
  bool _isAdmin = false;
  bool _isEditing = false;
  
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Dark Theme Constants
  static const Color _darkBg = Color(0xFF111111);
  static const Color _darkCard = Color(0xFF1E1E1E);
  static const Color _darkSurface = Color(0xFF2C2C2C);
  static const Color _whiteText = Colors.white;
  static const Color _grayText = Color(0xFFAAAAAA);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _nameController.text = widget.group.name;
    _descController.text = widget.group.description;
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

    if (owner) {
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
        final role = doc.data()?['role'] ?? 'member';
        if (role == 'admin') admin = true;
        if (role == 'owner') owner = true;
      }
    } catch (e) {
      // Gracefully continue
    }

    if (mounted) {
      setState(() {
        _isMember = member;
        _isOwner = owner;
        _isAdmin = admin;
        _isLoadingRole = false;
      });
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
      // In a real app we might update widget.group or rely on stream.
      // Here we just toggle UI.
      widget.group.name = newName;
      widget.group.description = newDesc;
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الحفظ')));
    }
  }

  void _openMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: _darkCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: _darkSurface, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 20),
              
              _buildMenuItem(Icons.info_outline_rounded, "معلومات المجموعة", () => Navigator.pop(context)),
              
              if (_isOwner || _isAdmin) ...[
                _buildMenuItem(Icons.link_rounded, "رابط المجموعة", () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: 'edu_mate://group/${widget.group.id}'));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الرابط')));
                }),
                _buildMenuItem(Icons.people_outline_rounded, "إدارة الأعضاء", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ManageMembersScreen(group: widget.group)));
                }),
                _buildMenuItem(Icons.edit_rounded, "تعديل المجموعة", () {
                  Navigator.pop(context);
                  setState(() => _isEditing = true);
                }),
                _buildMenuItem(Icons.chat_bubble_outline_rounded, "تفعيل/إيقاف دردشة الأعضاء", () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('غير متاح حالياً')));
                }),
              ] else ...[
                _buildMenuItem(Icons.notifications_off_outlined, "كتم الإشعارات", () => Navigator.pop(context)),
              ],
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Divider(color: _darkSurface, height: 1),
              ),
              _buildMenuItem(Icons.exit_to_app_rounded, "مغادرة المجموعة", () => Navigator.pop(context), color: AppColors.error),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {Color color = _whiteText}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 15)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _darkBg,
      ),
      child: Scaffold(
        backgroundColor: _darkBg,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: _grayText,
                    dividerColor: _darkSurface,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    isScrollable: false,
                    tabs: const [
                      Tab(text: "الأعضاء"),
                      Tab(text: "الوسائط"),
                      Tab(text: "الملفات"),
                      Tab(text: "الروابط"),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildMembersTab(),
              _buildMediaTab(),
              _buildFilesTab(),
              _buildLinksTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    if (_isEditing) {
      return _buildEditHeader();
    }

    return SafeArea(
      child: Column(
        children: [
          // Top Actions Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: _whiteText),
                  onPressed: () => Navigator.pop(context),
                ),
                if (_isOwner || _isAdmin)
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: _whiteText),
                    onPressed: () => setState(() => _isEditing = true),
                  )
                else
                  const SizedBox(width: 48), // Balance centering
              ],
            ),
          ),
          
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 54,
              backgroundColor: _darkSurface,
              backgroundImage: widget.group.imageUrl.isNotEmpty ? NetworkImage(widget.group.imageUrl) : null,
              child: widget.group.imageUrl.isEmpty
                  ? Text(
                      widget.group.name.isNotEmpty ? widget.group.name.substring(0, 1).toUpperCase() : 'M',
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          
          // Name and Details
          Text(
            widget.group.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _whiteText),
          ),
          const SizedBox(height: 6),
          if (widget.group.description.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                widget.group.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: _grayText),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          Text(
            "${widget.group.membersCount} عضو",
            style: const TextStyle(fontSize: 13, color: _grayText),
          ),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSquareButton(Icons.volume_off_rounded, "كتم", () {}),
                _buildSquareButton(Icons.search_rounded, "بحث", () {}),
                _buildSquareButton(Icons.exit_to_app_rounded, "مغادرة", () {}, iconColor: AppColors.error),
                _buildSquareButton(Icons.more_horiz_rounded, "المزيد", _openMoreMenu),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEditHeader() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: const Text("إلغاء", style: TextStyle(color: _whiteText, fontSize: 16)),
                ),
                const Text("تعديل المجموعة", style: TextStyle(color: _whiteText, fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: _saveEdits,
                  child: const Text("حفظ", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              CircleAvatar(
                radius: 54,
                backgroundColor: _darkSurface,
                backgroundImage: widget.group.imageUrl.isNotEmpty ? NetworkImage(widget.group.imageUrl) : null,
                child: widget.group.imageUrl.isEmpty
                    ? Text(
                        widget.group.name.isNotEmpty ? widget.group.name.substring(0, 1).toUpperCase() : 'M',
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: _whiteText, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: "اسم المجموعة",
                    labelStyle: const TextStyle(color: _grayText),
                    filled: true,
                    fillColor: _darkCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descController,
                  style: const TextStyle(color: _whiteText, fontSize: 14),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "الوصف",
                    labelStyle: const TextStyle(color: _grayText),
                    filled: true,
                    fillColor: _darkCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSquareButton(IconData icon, String label, VoidCallback onTap, {Color iconColor = AppColors.primary}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _darkCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: _grayText, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('groups').doc(widget.group.id).collection('members').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return const Center(child: Text('خطأ في التحميل', style: TextStyle(color: _grayText)));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState(Icons.group_rounded, "لا يوجد أعضاء");

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final name = data['name'] ?? 'عضو بالمجموعة';
            final role = data['role'] ?? 'member';
            final imageUrl = data['imageUrl'] as String?;

            String roleLabel = "";
            Color roleColor = Colors.transparent;

            if (role == 'owner') {
              roleLabel = "مالك";
              roleColor = AppColors.error;
            } else if (role == 'admin') {
              roleLabel = "مشرف";
              roleColor = AppColors.warning;
            }

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _darkSurface,
                backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                child: imageUrl == null || imageUrl.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'M',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              title: Text(name, style: const TextStyle(color: _whiteText, fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: const Text("عضو بالمجموعة", style: TextStyle(color: _grayText, fontSize: 12)),
              trailing: roleLabel.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        roleLabel,
                        style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildMediaTab() {
    // Placeholder grid
    return _buildEmptyState(Icons.photo_library_rounded, "لا توجد وسائط");
  }

  Widget _buildFilesTab() {
    return _buildEmptyState(Icons.insert_drive_file_rounded, "لا توجد ملفات");
  }

  Widget _buildLinksTab() {
    return _buildEmptyState(Icons.link_rounded, "لا توجد روابط");
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: _darkSurface),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: _grayText, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF111111), // _darkBg
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
