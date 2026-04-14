import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/group_model.dart';
import '../../services/group_service.dart';
import '../../core/providers/guest_provider.dart';
import '../../widgets/guest_action_dialog.dart';
import '../../widgets/feed/post_card_wrapper.dart';
import 'group_chat_screen.dart';
import '../../l10n/app_localizations.dart';

class GroupProfileScreen extends StatefulWidget {
  final GroupModel group;

  const GroupProfileScreen({super.key, required this.group});

  @override
  State<GroupProfileScreen> createState() => _GroupProfileScreenState();
}

class _GroupProfileScreenState extends State<GroupProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = true;
  bool _isMember = false;
  int _membersCount = 0;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _loadGroupState();
  }

  Future<void> _loadGroupState() async {
    final state = await GroupService.getUserGroupState(widget.group.id);
    if (mounted) {
      setState(() {
        _isMember = state.isMember;
        _membersCount = widget.group.membersCounts;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAction() async {
    if (_isMember) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GroupChatScreen(group: widget.group)),
      );
      return;
    }

    if (context.read<GuestProvider>().isGuest) {
      GuestActionDialog.show(context);
      return;
    }

    setState(() => _isJoining = true);
    try {
      await GroupService.joinPublicGroup(widget.group.id);
      if (mounted) {
        setState(() {
          _isMember = true;
          _membersCount++;
          _isJoining = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.groupsJoinSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isJoining = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : const Color(0xFFF8F9FB),
      body: CustomScrollView(
        slivers: [
          // Dynamic Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: isDark ? AppColors.surface : AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Animated Gradient Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                          AppColors.primaryDark,
                        ],
                      ),
                    ),
                  ),
                  // Group Info Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar with Glow
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: Colors.white,
                            backgroundImage: widget.group.imageUrl.isNotEmpty
                                ? NetworkImage(widget.group.imageUrl)
                                : null,
                            child: widget.group.imageUrl.isEmpty
                                ? const Icon(Icons.groups_rounded, size: 40, color: AppColors.primary)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Group Name
                        Text(
                          widget.group.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Stats Row
                        Row(
                          children: [
                            _buildStatChip(
                              Icons.people_alt_rounded,
                              '$_membersCount ${l10n.groupsTabMembers}',
                            ),
                            const SizedBox(width: 12),
                            _buildStatChip(
                                Icons.school_rounded,
                                widget.group.specializationName
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action Bar & Description
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleAction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isMember ? AppColors.surface : AppColors.primary,
                            foregroundColor: _isMember ? AppColors.primary : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: _isMember ? const BorderSide(color: AppColors.primary, width: 1.5) : BorderSide.none,
                            ),
                          ),
                          child: _isJoining
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : Text(
                                  _isMember ? 'فتح الدردشة' : l10n.feedJoinAction,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surface : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppColors.border : Colors.black12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.share_outlined),
                          onPressed: () {
                            // Share logic
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Description
                  Text(
                    l10n.signupBioHint,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary.withOpacity(0.8),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.group.description.isEmpty
                        ? 'لا يوجد وصف لهذه المجموعة'
                        : widget.group.description,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: isDark ? AppColors.textSecondary : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Feed Header
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_mosaic_rounded, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'المنشورات العامة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.textPrimary : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Social Feed
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('posts')
                .where('groupId', isEqualTo: widget.group.id)
                .where('visibility', isEqualTo: 'public')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.campaign_outlined, size: 64, color: AppColors.primary.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد منشورات بعد',
                            style: TextStyle(color: isDark ? AppColors.textSecondary : Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      
                      final post = {
                        'postId': doc.id,
                        'authorId': data['authorId'] ?? '',
                        'authorName': data['authorName'] ?? '',
                        'groupName': data['groupName'] ?? widget.group.name,
                        'groupImageUrl': data['groupImageUrl'] ?? widget.group.imageUrl,
                        'createdAt': data['createdAt'],
                        'contentText': data['contentText'] ?? '',
                        'contentImageUrl': data['contentImageUrl'] ?? '',
                        'likesCount': data['likesCount'] ?? 0,
                        'commentsCount': data['commentsCount'] ?? 0,
                        'groupId': widget.group.id,
                        'tag': 'Public',
                      };

                      return PostCardWrapper(post: post);
                    },
                    childCount: docs.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
