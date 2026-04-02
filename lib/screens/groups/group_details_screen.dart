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
    _groupName = widget.group.name;
    _groupDescription = widget.group.description;
    
    _tabController = TabController(length: 3, vsync: this);
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
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 20),
              
              _buildMenuItem(Icons.info_outline_rounded, "معلومات المجموعة", () => Navigator.pop(context)),
              
              if (_isOwner || _isAdmin) ...[
                _buildMenuItem(Icons.link_rounded, "رابط المجموعة", () {
                  Navigator.pop(context);
                  String inviteLink = '';
                  try {
                    inviteLink = (widget.group as dynamic).inviteLink ?? 'edu_mate://group/${widget.group.id}';
                  } catch (e) {
                    inviteLink = 'edu_mate://group/${widget.group.id}';
                  }
                  Clipboard.setData(ClipboardData(text: inviteLink));
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
                child: Divider(color: AppColors.border, height: 1),
              ),
              _buildMenuItem(Icons.exit_to_app_rounded, "مغادرة المجموعة", () {
                Navigator.pop(context);
              }, color: AppColors.error),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(title, style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 15)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: _buildHeader(),
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
                    dividerColor: AppColors.border,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    isScrollable: false,
                    tabs: const [
                      Tab(text: "الأعضاء"),
                      Tab(text: "الوسائط"),
                      Tab(text: "الروابط"),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: Container(
          color: AppColors.background,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMembersTab(),
              _buildMediaTab(),
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
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            // Top Actions Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  if (_isOwner || _isAdmin)
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: AppColors.textPrimary),
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
                backgroundColor: AppColors.inputFill,
                backgroundImage: widget.group.imageUrl.isNotEmpty ? NetworkImage(widget.group.imageUrl) : null,
                child: widget.group.imageUrl.isEmpty
                    ? Text(
                        _groupName.isNotEmpty ? _groupName.substring(0, 1).toUpperCase() : 'M',
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            
            // Name and Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _groupName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 6),
            
            if (_membersCount > 0)
              Text(
                "$_membersCount عضو",
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              )
            else
              const SizedBox(
                width: 16, height: 16, 
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            
            const SizedBox(height: 12),

            if (_groupDescription.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _groupDescription,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
               const SizedBox(height: 12),
            ],
            
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
          ],
        ),
      ),
    );
  }

  Widget _buildEditHeader() {
    return SafeArea(
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _isEditing = false),
                    child: const Text("إلغاء", style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  ),
                  const Text("تعديل المجموعة", style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
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
                  backgroundColor: AppColors.inputFill,
                  backgroundImage: widget.group.imageUrl.isNotEmpty ? NetworkImage(widget.group.imageUrl) : null,
                  child: widget.group.imageUrl.isEmpty
                      ? Text(
                          _groupName.isNotEmpty ? _groupName.substring(0, 1).toUpperCase() : 'M',
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
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: "اسم المجموعة",
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.inputFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "الوصف",
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.inputFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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

  Widget _buildSquareButton(IconData icon, String label, VoidCallback onTap, {Color iconColor = AppColors.primary}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
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
          return const Center(child: Text('خطأ في التحميل', style: TextStyle(color: AppColors.textSecondary)));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState(Icons.group_rounded, "لا يوجد أعضاء");

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            
            // Safe fallback logic for name
            final String name = data['name'] ?? data['displayName'] ?? data['username'] ?? 'عضو بالمجموعة';
            final String? imageUrl = data['imageUrl'] ?? data['photoUrl'];
            final String role = data['role'] ?? 'member';
            
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
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                child: imageUrl == null || imageUrl.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'M',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              title: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: Text(
                roleLabel.isNotEmpty ? roleLabel : "عضو", 
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)
              ),
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
    return _buildEmptyState(Icons.photo_library_rounded, "لا توجد وسائط");
  }

  Widget _buildLinksTab() {
    return _buildEmptyState(Icons.link_rounded, "لا توجد روابط");
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.inputFill),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// Keep the delegate inside the file for standalone functionality
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverAppBarDelegate(this.child);

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
