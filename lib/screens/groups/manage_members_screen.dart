import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_colors.dart';
import '../../models/group_model.dart';

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
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoadingRole = false);
      return;
    }

    if (widget.group.ownerId == user.uid) {
      setState(() {
        _currentUserRole = 'owner';
        _isLoadingRole = false;
      });
      return;
    }

    try {
      final doc = await _firestore
          .collection('groups')
          .doc(widget.group.id)
          .collection('members')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _currentUserRole = doc.data()?['role'] ?? 'member';
        });
      }
    } catch (e) {
      // Ignored
    } finally {
      if (mounted) setState(() => _isLoadingRole = false);
    }
  }

  Future<void> _updateMemberRole(String memberId, String newRole) async {
    try {
      await _firestore
          .collection('groups')
          .doc(widget.group.id)
          .collection('members')
          .doc(memberId)
          .update({'role': newRole});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث صلاحيات العضو')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء التحديث')));
      }
    }
  }

  Future<void> _updateMemberStatus(String memberId, String status) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      final memberRef = _firestore
          .collection('groups')
          .doc(widget.group.id)
          .collection('members')
          .doc(memberId);
      
      final groupRef = _firestore.collection('groups').doc(widget.group.id);

      batch.update(memberRef, {
        'status': status,
      });

      if (status == 'banned') {
         batch.update(groupRef, {
           'bannedUserIds': FieldValue.arrayUnion([memberId])
         });
      } else {
         batch.update(groupRef, {
           'bannedUserIds': FieldValue.arrayRemove([memberId])
         });
      }

      await batch.commit();

      if (mounted) {
        String msg = 'تم تحديث حالة العضو';
        if (status == 'muted') msg = 'تم كتم العضو';
        if (status == 'active') msg = 'تم إلغاء الكتم عن العضو';
        if (status == 'banned') msg = 'تم حظر العضو';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء التحديث')));
      }
    }
  }

  Future<void> _removeMember(String memberId) async {
    try {
      WriteBatch batch = _firestore.batch();
      final groupRef = _firestore.collection('groups').doc(widget.group.id);
      
      batch.delete(groupRef.collection('members').doc(memberId));
      batch.delete(_firestore.collection('users').doc(memberId).collection('joined_groups').doc(widget.group.id));
      
      batch.update(groupRef, {
        'membersCounts': FieldValue.increment(-1),
      });

      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إزالة العضو من المجموعة')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء إزالة العضو')));
      }
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

  void _handleMemberAction(String action, Map<String, dynamic> memberData, String memberId) {
    if (memberId == _auth.currentUser?.uid) return;

    switch (action) {
      case 'make_admin':
        _updateMemberRole(memberId, 'admin');
        break;
      case 'remove_admin':
        _updateMemberRole(memberId, 'member');
        break;
      case 'mute':
        _updateMemberStatus(memberId, 'muted');
        break;
      case 'unmute':
        _updateMemberStatus(memberId, 'active');
        break;
      case 'ban':
        _updateMemberStatus(memberId, 'banned');
        break;
      case 'kick':
        _removeMember(memberId);
        break;
      case 'transfer_owner':
        _transferOwnership(memberId);
        break;
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

                      if (owners.isEmpty && admins.isEmpty && members.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: owners.length + admins.length + members.length + 3,
                        separatorBuilder: (context, index) {
                           // Try not to draw separators directly after section headers
                           return const Divider(height: 1, indent: 64);
                        },
                        itemBuilder: (context, index) {
                          final List<Widget> items = [];
                          
                          if (owners.isNotEmpty) {
                            items.add(_buildSectionTitle("المالك"));
                            items.addAll(owners.map((doc) => _buildMemberItem(doc)));
                          }
                          if (admins.isNotEmpty) {
                            items.add(_buildSectionTitle("المشرفون"));
                            items.addAll(admins.map((doc) => _buildMemberItem(doc)));
                          }
                          if (members.isNotEmpty) {
                            items.add(_buildSectionTitle("الأعضاء"));
                            items.addAll(members.map((doc) => _buildMemberItem(doc)));
                          }
                          
                          if (index < items.length) return items[index];
                          return const SizedBox.shrink();
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
    Widget? roleIcon;

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
                      if (roleIcon != null) ...[
                        const SizedBox(width: 6),
                        roleIcon,
                      ],
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
            if (!isMe && _currentUserRole != 'member' && !_isTargetOwner)
              _buildPopupMenu(memberId, data, _isTargetAdmin),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupMenu(String memberId, Map<String, dynamic> data, bool isTargetAdmin) {
    final status = data['status'] ?? 'active';
    
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (action) => _handleMemberAction(action, data, memberId),
      itemBuilder: (context) {
        List<PopupMenuEntry<String>> items = [];

        if (_currentUserRole == 'owner') {
          if (isTargetAdmin) {
            items.add(const PopupMenuItem(value: 'remove_admin', child: Text("إزالة من الإشراف", style: TextStyle(fontWeight: FontWeight.bold))));
          } else {
            items.add(const PopupMenuItem(value: 'make_admin', child: Text("تعيين كمشرف", style: TextStyle(fontWeight: FontWeight.bold))));
          }
        }

        // Mute / Unmute
        if (status == 'muted') {
          items.add(const PopupMenuItem(value: 'unmute', child: Text("إلغاء الكتم", style: TextStyle(fontWeight: FontWeight.bold))));
        } else {
          items.add(const PopupMenuItem(value: 'mute', child: Text("كتم العضو", style: TextStyle(fontWeight: FontWeight.bold))));
        }

        // Ban
        if (status != 'banned') {
          items.add(const PopupMenuDivider());
          items.add(const PopupMenuItem(value: 'ban', child: Text("حظر العضو", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))));
        }

        // Kick
        if (status == 'banned' && items.isEmpty) items.add(const PopupMenuDivider());
        items.add(const PopupMenuItem(value: 'kick', child: Text("طرد العضو", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))));
        
        if (_currentUserRole == 'owner') {
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
