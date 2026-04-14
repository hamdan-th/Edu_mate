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
import 'group_details_screen.dart';
import '../../l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../../widgets/common/premium_feedback.dart';
import '../../widgets/common/premium_transitions.dart';

class GroupProfileScreen extends StatefulWidget {
  final GroupModel group;

  const GroupProfileScreen({super.key, required this.group});

  @override
  State<GroupProfileScreen> createState() => _GroupProfileScreenState();
}

class _GroupProfileScreenState extends State<GroupProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = true;
  bool _isMember = false;
  bool _isOwner = false;
  bool _isAdmin = false;
  bool _isNotificationMuted = false;
  int _membersCount = 0;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
    ));

    _loadGroupState();
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupState() async {
    final state = await GroupService.getUserGroupState(widget.group.id);
    if (mounted) {
      setState(() {
        _isMember = state.isMember;
        _isOwner = state.isOwner;
        _isAdmin = state.isAdmin;
        _isNotificationMuted = state.notificationsMuted;
        _membersCount = widget.group.membersCounts;
        _isLoading = false;
      });
    }
  }

  void _shareGroup() {
    final inviteLink = GroupService.buildInviteLink(groupId: widget.group.id, inviteCode: widget.group.inviteCode);
    final shareText = 'انضم إلى مجموعة ${widget.group.name} على Edu Mate!\n\n'
        '${widget.group.description}\n\n'
        'رابط الانضمام: $inviteLink';
    
    Share.share(shareText);
  }

  void _showMoreMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final guest = context.read<GuestProvider>().isGuest;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              
              // Role-based actions
              _buildMenuItem(
                icon: Icons.link_rounded,
                title: 'نسخ الرابط',
                onTap: () {
                  final link = GroupService.buildInviteLink(groupId: widget.group.id, inviteCode: widget.group.inviteCode);
                  Clipboard.setData(ClipboardData(text: link));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الرابط'), behavior: SnackBarBehavior.floating));
                },
              ),
              if (!guest && _isMember) ...[
                _buildMenuItem(
                  icon: _isNotificationMuted ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                  title: _isNotificationMuted ? 'تفعيل التنبيهات' : 'كتم التنبيهات',
                  onTap: () async {
                    Navigator.pop(context);
                    setState(() => _isNotificationMuted = !_isNotificationMuted);
                    await _firestore.collection('groups').doc(widget.group.id).collection('members').doc(_auth.currentUser?.uid).update({
                      'notificationsMuted': _isNotificationMuted
                    });
                  },
                ),
                if (!_isOwner)
                  _buildMenuItem(
                    icon: Icons.exit_to_app_rounded,
                    title: 'مغادرة المجموعة',
                    color: AppColors.error,
                    onTap: () {
                      Navigator.pop(context);
                      _confirmLeave();
                    },
                  ),
              ],
              if (!guest && (_isOwner || _isAdmin)) ...[
                _buildMenuItem(
                  icon: Icons.edit_rounded,
                  title: 'تعديل المجموعة',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, PremiumPageRoute(page: GroupDetailsScreen(group: widget.group, startEditing: true)));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.people_rounded,
                  title: 'إدارة الأعضاء',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, PremiumPageRoute(page: GroupDetailsScreen(group: widget.group)));
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _confirmLeave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مغادرة المجموعة', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من رغبتك في مغادرة هذه المجموعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('مغادرة', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await GroupService.leaveGroup(widget.group.id);
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Widget _buildMenuItem({required IconData icon, required String title, required VoidCallback onTap, Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary, size: 22),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: color)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 32),
      onTap: onTap,
    );
  }

  Future<void> _handleAction() async {
    if (_isMember) {
      Navigator.push(
        context,
        PremiumPageRoute(page: GroupChatScreen(group: widget.group)),
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
            expandedHeight: 260,
            pinned: true,
            stretch: true,
            backgroundColor: isDark ? AppColors.surface : AppColors.primary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.white, size: 22),
                onPressed: _shareGroup,
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 22),
                onPressed: _showMoreMenu,
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Minimal Gradient Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDark 
                            ? [AppColors.primary, AppColors.primaryDark.withOpacity(0.9)]
                            : [AppColors.primary, AppColors.primary.withOpacity(0.85)],
                      ),
                    ),
                  ),
                  // Subtle Overlay for readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          isDark ? Colors.black.withOpacity(0.4) : AppColors.primaryDark.withOpacity(0.15),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Clean Avatar
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.7) : Colors.white, 
                              width: 2.0
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            backgroundImage: widget.group.imageUrl.isNotEmpty
                                ? NetworkImage(widget.group.imageUrl)
                                : null,
                            child: widget.group.imageUrl.isEmpty
                                ? const Icon(Icons.groups_rounded, size: 36, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Group Name
                        Text(
                          widget.group.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Refined Meta Row
                        Row(
                          children: [
                            _buildStatChip(
                              Icons.people_alt_rounded,
                              '$_membersCount ${l10n.groupsTabMembers}',
                            ),
                            const SizedBox(width: 8),
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
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Action Button
                  ScaleOnPress(
                    onTap: _isLoading ? null : _handleAction,
                    child: Semantics(
                      button: true,
                      label: _isMember ? 'فتح الدردشة' : l10n.feedJoinAction,
                      enabled: !_isLoading,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDark 
                              ? (_isMember ? Colors.transparent : AppColors.primary)
                              : AppColors.lightPrimary,
                          borderRadius: BorderRadius.circular(14),
                          border: (isDark && _isMember) ? Border.all(color: AppColors.primary, width: 2) : null,
                          boxShadow: isDark ? null : [
                            BoxShadow(
                              color: AppColors.lightShadow.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: _isJoining
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                            : Text(
                                _isMember ? 'فتح الدردشة' : l10n.feedJoinAction,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900, 
                                  fontSize: 16, 
                                  letterSpacing: 0.2,
                                  color: (isDark && _isMember) ? AppColors.primary : Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  // About Section
                  Text(
                    'حول المجموعة',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary.withOpacity(0.9),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.group.description.isEmpty
                        ? 'لا يوجد وصف لهذه المجموعة حالياً'
                        : widget.group.description,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Feed Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome_mosaic_rounded, size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'آخر المنشورات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.textPrimary : AppColors.textOnLight,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      // Optional: Filter or More actions
                    ],
                  ),
                  const SizedBox(height: 4),
                  Divider(color: isDark ? AppColors.border : Colors.black.withOpacity(0.05)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.12) : AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isDark ? Colors.white.withOpacity(0.9) : AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white.withOpacity(0.95) : AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
