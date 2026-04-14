import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_colors.dart';
import '../../models/group_model.dart';
import '../../services/group_service.dart';
import '../../l10n/app_localizations.dart';

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
      await GroupService.transferOwnership(widget.group.id, newOwnerId);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.groupsTransferOwnershipSuccess)));
        setState(() {
          _currentUserRole = 'admin'; // update local role to reflect loss of ownership
        });
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    }
  }

  void _handleMemberAction(String action, Map<String, dynamic> memberData, String memberId) async {
    if (memberId == _auth.currentUser?.uid) return;

    try {
      final l10n = AppLocalizations.of(context)!;
      switch (action) {
        case 'make_admin':
          await GroupService.promoteToAdmin(widget.group.id, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.groupsSetAdminSuccess)));
          break;
        case 'remove_admin':
          await GroupService.removeAdmin(widget.group.id, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.groupsRemoveAdminSuccess)));
          break;
        case 'mute':
          await GroupService.muteMember(widget.group.id, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.groupsMuteMemberSuccess)));
          break;
        case 'unmute':
          await GroupService.unmuteMember(widget.group.id, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.groupsUnmuteMemberSuccess)));
          break;
        case 'report':
          await GroupService.reportMember(widget.group.id, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.groupsReportSent)));
          break;
        case 'kick':
          await GroupService.kickMember(widget.group.id, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.groupsKickMemberSuccess)));
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.groupsManageMembersTitle,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingRole
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: _firestore
                        .collection('groups')
                        .doc(widget.group.id)
                        .snapshots(),
                    builder: (context, groupDocSnap) {
                      final liveOwnerId = (groupDocSnap.data?.data() as Map<String, dynamic>?)?['ownerId'] ?? widget.group.ownerId;

                      return StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('groups')
                            .doc(widget.group.id)
                            .collection('members')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting && !groupDocSnap.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(child: Text(l10n.groupsLoadMembersError));
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
                              String searchableName = (data['username']?.toString() ?? data['fullName']?.toString() ?? data['displayName']?.toString() ?? data['name']?.toString() ?? l10n.groupsDefaultMemberName).trim();
                              if (searchableName.contains('@')) searchableName = searchableName.split('@').first;
                              if (!searchableName.toLowerCase().contains(_searchQuery)) continue;
                            }

                            final role = data['role'] ?? 'member';
                            final isTrueOwner = doc.id == liveOwnerId;
                            
                            if (isTrueOwner) {
                              owners.add(doc);
                            } else if (role == 'admin' || role == 'owner') {
                              // if they have 'owner' but aren't the group ownerId, treat as admin
                              admins.add(doc);
                            } else {
                              members.add(doc);
                            }
                          }

                          final itemsList = <Widget>[];

                          if (owners.isNotEmpty) {
                            itemsList.add(_buildSectionTitle(l10n.groupsRoleOwnerTitle));
                            itemsList.addAll(owners.map((doc) => _buildMemberItem(doc, liveOwnerId)));
                          }
                          if (admins.isNotEmpty) {
                            itemsList.add(_buildSectionTitle(l10n.groupsRoleAdminsTitle));
                            itemsList.addAll(admins.map((doc) => _buildMemberItem(doc, liveOwnerId)));
                          }
                          if (members.isNotEmpty) {
                            itemsList.add(_buildSectionTitle(l10n.groupsRoleMembersTitle));
                            itemsList.addAll(members.map((doc) => _buildMemberItem(doc, liveOwnerId)));
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
                      );
                    }
                  ),
                ),

              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Theme.of(context).canvasColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.12),
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.groupsSearchHint,
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
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark 
              ? AppColors.primary 
              : const Color(0xFFC79A22), // Deepened gold for better contrast on light surfaces
        ),
      ),
    );
  }

  Widget _buildMemberItem(DocumentSnapshot doc, String liveOwnerId) {
    final l10n = AppLocalizations.of(context)!;
    final data = doc.data() as Map<String, dynamic>;
    final memberId = doc.id;
    String name = (data['username']?.toString() ?? data['fullName']?.toString() ?? data['displayName']?.toString() ?? data['name']?.toString() ?? l10n.groupsDefaultMemberName).trim();
    if (name.contains('@')) name = name.split('@').first;
    final role = data['role'] ?? 'member';
    final imageUrl = data['imageUrl'] as String?;

    final bool isMe = memberId == _auth.currentUser?.uid;
    final bool isTargetOwner = memberId == liveOwnerId;
    final bool isTargetAdmin = role == 'admin' || (role == 'owner' && !isTargetOwner);

    String roleLabel = l10n.groupsRoleMember;
    Color roleColor = AppColors.textSecondary;
    Widget roleIcon = const SizedBox.shrink();

    if (isTargetOwner) {
      roleLabel = l10n.groupsRoleOwner;
      roleColor = AppColors.error;
      roleIcon = const Icon(Icons.workspace_premium, color: Colors.purple, size: 18);
    } else if (isTargetAdmin) {
      roleLabel = l10n.groupsRoleAdmin;
      roleColor = AppColors.warning;
      roleIcon = const Icon(Icons.headset_mic, color: Colors.orange, size: 18);
    } else {
      roleLabel = l10n.groupsRoleMember;
      roleColor = Theme.of(context).brightness == Brightness.dark 
          ? AppColors.primary 
          : const Color(0xFFC79A22);
    }

    // Small badge for muted/banned
    String statusNote = "";
    if (data['status'] == 'muted') statusNote = l10n.groupsStatusMuted;
    if (data['status'] == 'banned') statusNote = l10n.groupsStatusBanned;

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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textPrimary
                                : const Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      roleIcon,
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Text(
                          l10n.groupsYouMarker,
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
              _buildPopupMenu(memberId, data, isTargetOwner, isTargetAdmin),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupMenu(String memberId, Map<String, dynamic> data, bool isTargetOwner, bool isTargetAdmin) {
    final status = data['status'] ?? 'active';
    final l10n = AppLocalizations.of(context)!;
    
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
              items.add(PopupMenuItem(value: 'remove_admin', child: Text(l10n.groupsActionRemoveAdmin, style: const TextStyle(fontWeight: FontWeight.bold))));
            } else {
              items.add(PopupMenuItem(value: 'make_admin', child: Text(l10n.groupsActionMakeAdmin, style: const TextStyle(fontWeight: FontWeight.bold))));
            }
          }

          if (status == 'muted') {
            items.add(PopupMenuItem(value: 'unmute', child: Text(l10n.groupsActionUnmute, style: const TextStyle(fontWeight: FontWeight.bold))));
          } else {
            items.add(PopupMenuItem(value: 'mute', child: Text(l10n.groupsActionMute, style: const TextStyle(fontWeight: FontWeight.bold))));
          }

          // We removed 'ban' and just use 'kick'
          items.add(const PopupMenuDivider());
          items.add(PopupMenuItem(value: 'kick', child: Text(l10n.groupsActionKick, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))));
        }

        if (items.isNotEmpty) items.add(const PopupMenuDivider());
        items.add(PopupMenuItem(value: 'report', child: Text(l10n.groupsActionReport, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))));

        if (_currentUserRole == 'owner' && !isTargetOwner) {
          items.add(const PopupMenuDivider());
          items.add(PopupMenuItem(value: 'transfer_owner', child: Text(l10n.groupsActionTransferOwner, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w900))));
        }

        return items;
      },
    );
  }


  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
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
            Text(
              l10n.groupsEmptySearchTitle,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textPrimary
                    : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.groupsEmptySearchDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
