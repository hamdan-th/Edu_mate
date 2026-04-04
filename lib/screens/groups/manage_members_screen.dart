import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_colors.dart';
import '../../models/group_model.dart';
import '../../services/group_service.dart';
import '../../models/group_membership_state.dart';

class ManageMembersScreen extends StatefulWidget {
  final GroupModel group;

  const ManageMembersScreen({
    super.key,
    required this.group,
  });

  @override
  State<ManageMembersScreen> createState() => _ManageMembersScreenState();
}

class _ManageMembersScreenState extends State<ManageMembersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _searchQuery = '';
  String _currentUserRole = 'member';
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _loadCurrentUserRole();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserRole() async {
    final state = await GroupService.getUserGroupState(widget.group.id);
    if (mounted) {
      setState(() {
        _currentUserRole = state.role;
        _isLoadingRole = false;
      });
    }
  }

  Future<void> _transferOwnership(String newOwnerId) async {
    final oldOwnerId = _auth.currentUser?.uid;
    if (oldOwnerId == null) return;

    try {
      WriteBatch batch = _firestore.batch();

      final groupRef = _firestore.collection('groups').doc(widget.group.id);
      batch.update(groupRef, {'ownerId': newOwnerId});

      final oldOwnerRef = groupRef.collection('members').doc(oldOwnerId);
      batch.update(oldOwnerRef, {'role': 'admin'});

      final newOwnerRef = groupRef.collection('members').doc(newOwnerId);
      batch.update(newOwnerRef, {'role': 'owner'});

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نقل الملكية بنجاح')));
        setState(() {
          _currentUserRole = 'admin'; // update local role to reflect loss of ownership
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء نقل الملكية')));
      }
    }
  }

  void _handleMemberAction(String action, Map<String, dynamic> memberData, String memberId) async {
    if (memberId == _auth.currentUser?.uid) return;

    try {
      switch (action) {
        case 'make_admin':
          await GroupService.promoteToAdmin(widget.group.id, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تعيين المشرف')));
          break;
        case 'remove_admin':
          await GroupService.removeAdmin(widget.group.id, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إزالة المشرف')));
          break;
        case 'mute':
          await GroupService.muteMember(widget.group.id, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم كتم العضو')));
          break;
        case 'unmute':
          await GroupService.unmuteMember(widget.group.id, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء كتم العضو')));
          break;
        case 'report':
          await GroupService.reportMember(widget.group.id, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال البلاغ لمدير التطبيق')));
          break;
        case 'kick':
          await GroupService.kickMember(widget.group.id, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم طرد العضو')));
          break;
        case 'transfer_owner':
          await _transferOwnership(memberId);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "إدارة الأعضاء",
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingRole
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('groups')
                        .doc(widget.group.id)
                        .collection('members')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return const Center(child: Text('تعذر تحميل الأعضاء'));
                      }

                      final docs = snapshot.data?.docs ?? [];
                      
                      // Categorize members
                      final List<DocumentSnapshot> owners = [];
                      final List<DocumentSnapshot> admins = [];
                      final List<DocumentSnapshot> members = [];

                      for (var doc in docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        
                        // Local search filter
                        if (_searchQuery.isNotEmpty) {
                          String searchableName = (data['username']?.toString() ?? data['fullName']?.toString() ?? data['displayName']?.toString() ?? data['name']?.toString() ?? 'عضو بالمجموعة').trim();
                          if (searchableName.contains('@')) searchableName = searchableName.split('@').first;
                          if (!searchableName.toLowerCase().contains(_searchQuery)) continue;
                        }

                        final role = data['role'] ?? 'member';
                        if (role == 'owner' || doc.id == widget.group.ownerId) {
                          owners.add(doc);
                        } else if (role == 'admin') {
                          admins.add(doc);
                        } else {
                          members.add(doc);
                        }
                      }

                      final itemsList = <Widget>[];

                      if (owners.isNotEmpty) {
                        itemsList.add(_buildSectionTitle("المالك"));
                        itemsList.addAll(owners.map((doc) => _buildMemberItem(doc)));
                      }
                      if (admins.isNotEmpty) {
                        itemsList.add(_buildSectionTitle("المشرفون"));
                        itemsList.addAll(admins.map((doc) => _buildMemberItem(doc)));
                      }
                      if (members.isNotEmpty) {
                        itemsList.add(_buildSectionTitle("الأعضاء"));
                        itemsList.addAll(members.map((doc) => _buildMemberItem(doc)));
                      }

                      if (itemsList.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: itemsList.length,
                        separatorBuilder: (context, index) {
                           return const Divider(height: 1, indent: 64);
                        },
                        itemBuilder: (context, index) {
                          return itemsList[index];
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'بحث...',
            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.cancel_rounded, color: AppColors.textSecondary, size: 18),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildMemberItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final memberId = doc.id;
    String name = (data['username']?.toString() ?? data['fullName']?.toString() ?? data['displayName']?.toString() ?? data['name']?.toString() ?? 'عضو بالمجموعة').trim();
    if (name.contains('@')) name = name.split('@').first;
    final role = data['role'] ?? 'member';
    final imageUrl = data['imageUrl'] as String?;

    final bool isMe = memberId == _auth.currentUser?.uid;
    final bool _isTargetOwner = role == 'owner' || memberId == widget.group.ownerId;
    final bool _isTargetAdmin = role == 'admin';

    String roleLabel = "عضو";
    Color roleColor = AppColors.textSecondary;
    Widget roleIcon = const SizedBox.shrink();

    if (_isTargetOwner) {
      roleLabel = "مالك";
      roleColor = AppColors.error;
      roleIcon = const Icon(Icons.workspace_premium, color: Colors.purple, size: 18);
    } else if (_isTargetAdmin) {
      roleLabel = "مشرف";
      roleColor = AppColors.warning;
      roleIcon = const Icon(Icons.headset_mic, color: Colors.orange, size: 18);
    } else {
      roleLabel = "عضو";
      roleColor = AppColors.primary;
    }

    // Small badge for muted/banned
    String statusNote = "";
    if (data['status'] == 'muted') statusNote = " (مكتوم)";
    if (data['status'] == 'banned') statusNote = " (محظور)";

    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
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
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name + statusNote,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      roleIcon,
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Text(
                          "(أنت)",
                          style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 13),
                        )
                      ]
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    roleLabel,
                    style: TextStyle(color: roleColor, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (!isMe)
              _buildPopupMenu(memberId, data, _isTargetOwner, _isTargetAdmin),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupMenu(String memberId, Map<String, dynamic> data, bool isTargetOwner, bool isTargetAdmin) {
    final status = data['status'] ?? 'active';
    
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (action) => _handleMemberAction(action, data, memberId),
      itemBuilder: (context) {
        List<PopupMenuEntry<String>> items = [];

        bool canManage = false;
        if (_currentUserRole == 'owner' && !isTargetOwner) canManage = true;
        if (_currentUserRole == 'admin' && !isTargetOwner && !isTargetAdmin) canManage = true;

        if (canManage) {
          if (_currentUserRole == 'owner' && !isTargetOwner) {
            if (isTargetAdmin) {
              items.add(const PopupMenuItem(value: 'remove_admin', child: Text("إزالة من الإشراف", style: TextStyle(fontWeight: FontWeight.bold))));
            } else {
              items.add(const PopupMenuItem(value: 'make_admin', child: Text("تعيين كمشرف", style: TextStyle(fontWeight: FontWeight.bold))));
            }
          }

          if (status == 'muted') {
            items.add(const PopupMenuItem(value: 'unmute', child: Text("إلغاء الكتم", style: TextStyle(fontWeight: FontWeight.bold))));
          } else {
            items.add(const PopupMenuItem(value: 'mute', child: Text("كتم العضو", style: TextStyle(fontWeight: FontWeight.bold))));
          }

          // We removed 'ban' and just use 'kick'
          items.add(const PopupMenuDivider());
          items.add(const PopupMenuItem(value: 'kick', child: Text("طرد العضو", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))));
        }

        if (items.isNotEmpty) items.add(const PopupMenuDivider());
        items.add(const PopupMenuItem(value: 'report', child: Text("إبلاغ", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))));

        if (_currentUserRole == 'owner' && !isTargetOwner) {
          items.add(const PopupMenuDivider());
          items.add(const PopupMenuItem(value: 'transfer_owner', child: Text("نقل الملكية", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w900))));
        }

        return items;
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_search_rounded, size: 54, color: AppColors.primary.withOpacity(0.6)),
            ),
            const SizedBox(height: 20),
            const Text(
              "لا توجد نتائج",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              "لم نتمكن من العثور على أعضاء يطابقون بحثك.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
