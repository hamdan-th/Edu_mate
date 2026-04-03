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
              
              _buildMenuItem(Icons.report_problem_outlined, "إبلاغ", () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال البلاغ بنجاح')));
              }),
              _buildMenuItem(Icons.cleaning_services_rounded, "مسح محتوى الدردشة", () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ميزة مسح الحساب قيد التطوير')));
              }),
              _buildMenuItem(Icons.link_rounded, "رابط المجموعة", () {
                Navigator.pop(context);
                String inviteLink = widget.group.inviteLink;
                if (inviteLink.isEmpty) {
                  inviteLink = 'edu_mate://group/${widget.group.id}';
                }
                Clipboard.setData(ClipboardData(text: inviteLink));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ رابط الدعوة')));
              }),
              
              if (_isOwner || _isAdmin) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Divider(color: AppColors.border, height: 1),
                ),
                _buildMenuItem(Icons.people_outline_rounded, "إدارة الأعضاء", () {
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

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: c, size: 22),
      ),
      title: Text(title, style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 16)),
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
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                      )
                    ]
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: UnderlineTabIndicator(
                      borderSide: const BorderSide(width: 3.0, color: AppColors.primary),
                      borderRadius: BorderRadius.circular(3),
                      insets: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    tabAlignment: TabAlignment.fill,
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
              _buildSavedTab(),
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              // Top Actions Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 48), // Balance centering
                  ],
                ),
              ),
              
              // Avatar
              Center(
                child: Hero(
                  tag: 'group_avatar_${widget.group.id}',
                  child: CircleAvatar(
                    radius: 48, // Slightly smaller and cleaner like telegram
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: widget.group.imageUrl.isNotEmpty ? NetworkImage(widget.group.imageUrl) : null,
                    child: widget.group.imageUrl.isEmpty
                        ? Text(
                            _groupName.isNotEmpty ? _groupName.substring(0, 1).toUpperCase() : 'M',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Name and Details
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _groupName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.2),
                ),
              ),
              const SizedBox(height: 4),
              
              Text(
                "$_membersCount عضو",
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              
              const SizedBox(height: 16),

              if (_groupDescription.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _groupDescription,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                 const SizedBox(height: 12),
              ],
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _isLoadingRole 
                  ? const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
                  : _isMember 
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSquareButton(
                            _isMuted ? Icons.notifications_off_rounded : Icons.notifications_none_rounded, 
                            "كتم", 
                            _toggleMute
                          ),
                          _buildSquareButton(Icons.search_rounded, "بحث", () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("هذه الميزة غير متوفرة بعد")));
                          }),
                          _buildSquareButton(Icons.exit_to_app_rounded, "مغادرة", _leaveGroup),
                          _buildSquareButton(Icons.more_horiz_rounded, "المزيد", _openMoreMenu),
                        ],
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: _isJoining ? null : _joinPublicGroup,
                          child: _isJoining 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("انضم للمجتمع الآن", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditHeader() {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
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
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text("إلغاء", style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    const Text("تعديل المجموعة", style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                    TextButton(
                      onPressed: _saveEdits,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text("حفظ", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 56,
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
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 3),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6),
                        ]
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: "اسم المجموعة",
                        labelStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: AppColors.inputFill,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: "الوصف",
                        alignLabelWithHint: true,
                        labelStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: AppColors.inputFill,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSquareButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    if (!_isMember) {
      return _buildEmptyState(Icons.lock_rounded, "يجب الانضمام لرؤية الأعضاء");
    }

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
          padding: const EdgeInsets.only(top: 8, bottom: 40),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            
            final String name = data['name'] ?? data['displayName'] ?? data['username'] ?? 'عضو بالمجموعة';
            final String? imageUrl = data['imageUrl'] ?? data['photoUrl'];
            final String role = data['role'] ?? 'member';
            final String status = data['status'] ?? 'active';
            
            String roleLabel = "";
            Color roleColor = Colors.transparent;

            if (role == 'owner') {
              roleLabel = "مالك";
              roleColor = AppColors.error;
            } else if (role == 'admin') {
              roleLabel = "مشرف";
              roleColor = AppColors.warning;
            }

            String statusNote = "";
            if (status == 'muted') statusNote = " (مكتوم)";
            if (status == 'banned') statusNote = " (محظور)";

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                child: imageUrl == null || imageUrl.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'M',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                      )
                    : null,
              ),
              title: Text(name + statusNote, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: Text(roleLabel.isNotEmpty ? roleLabel : "عضو", style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
              trailing: roleLabel.isNotEmpty
                  ? Text(roleLabel, style: TextStyle(color: roleColor, fontSize: 12, fontWeight: FontWeight.bold))
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildMediaTab() {
    return _buildEmptyState(Icons.photo_library_outlined, "لا توجد وسائط");
  }

  Widget _buildLinksTab() {
    return _buildEmptyState(Icons.link_rounded, "لا توجد روابط");
  }

  Widget _buildSavedTab() {
    return _buildEmptyState(Icons.bookmark_outline_rounded, "لا توجد محفوظات");
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverAppBarDelegate(this.child);

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
