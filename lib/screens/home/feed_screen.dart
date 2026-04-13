import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../notifications/notifications_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/guest_provider.dart';
import '../../widgets/guest_action_dialog.dart';
import '../../services/feed_reactions_service.dart';
import '../../services/feed_service.dart';
import '../../services/feed_share_service.dart';
import '../../models/feed_post_model.dart';
import 'widgets/post_comments_sheet.dart';
import '../../services/group_service.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_bottom_sheet.dart';
import '../../features/edu_bot/presentation/screens/bot_screen.dart';
import '../../features/edu_bot/presentation/widgets/floating_bot_button.dart';
import '../../services/notifications_service.dart';
import '../../models/group_model.dart';
import '../groups/group_chat_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String _selectedFilter = 'For You';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = const [
    'For You',
    'Recent',
    'Popular',
    'Academic',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() {});
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  void _openBot() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BotScreen(sourceScreen: 'feed_screen'),
      ),
    );
  }

  String _formatTime(dynamic value, AppLocalizations l10n) {
    if (value == null) return '';

    DateTime? date;
    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) return '';

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return l10n.timeNow;
    if (diff.inMinutes < 60) return '${diff.inMinutes}${l10n.timeMinutesAgo}';
    if (diff.inHours < 24) return '${diff.inHours}${l10n.timeHoursAgo}';
    if (diff.inDays < 7) return '${diff.inDays}${l10n.timeDaysAgo}';

    return '${date.day}/${date.month}/${date.year}';
  }

  Stream<List<FeedPostModel>> _postsStream() {
    return FeedService.streamPublicFeed(
      filter: _selectedFilter,
      searchQuery: _searchQuery,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: const SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: 96),
          child: FloatingBotButton(sourceScreen: 'feed_screen'),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -70,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryDark.withOpacity(0.04),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.app_name,
                              style: TextStyle(
                                color:
                                isDark ? AppColors.textPrimary : Colors.black87,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.filterForYou,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textSecondary
                                    : Colors.black54,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          if (context.watch<GuestProvider>().isGuest)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 8),
                              child: ElevatedButton(
                                onPressed: () async {
                                  await FirebaseAuth.instance.signOut();
                                  if (!mounted) return;
                                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(
                                  'دخول',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                                ),
                              ),
                            ),
                          FeedTopActionButton(
                            icon: Icons.settings_rounded,
                            onTap: () => SettingsBottomSheet.show(context),
                          ),
                          const SizedBox(width: 8),
                          StreamBuilder<int>(
                            stream: NotificationsService.streamUnreadCount(),
                            builder: (context, snapshot) {
                              final unreadCount = snapshot.data ?? 0;

                              return FeedTopActionButton(
                                icon: Icons.notifications_none_rounded,
                                hasBadge: unreadCount > 0,
                                onTap: _openNotifications,
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          FeedTopActionButton(
                            icon: Icons.person_outline_rounded,
                            onTap: _openProfile,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surface.withOpacity(0.92)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.border.withOpacity(0.45)
                            : Colors.black12,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.10 : 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimary : Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: l10n.feedSearchHint,
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.textSecondary
                              : Colors.black45,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final label = _filters[index];
                      final active = _selectedFilter == label;

                      String displayLabel = label;
                      if (label == 'For You') {
                        displayLabel = l10n.filterForYou;
                      } else if (label == 'Recent') {
                        displayLabel = l10n.filterRecent;
                      } else if (label == 'Popular') {
                        displayLabel = l10n.filterPopular;
                      } else if (label == 'Academic') {
                        displayLabel = l10n.filterAcademic;
                      }

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = label;
                          });
                        },
                        child: ModernChip(
                          label: displayLabel,
                          originalValue: label,
                          active: active,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    child: StreamBuilder<List<FeedPostModel>>(
                      stream: _postsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return ListView.builder(
                            padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 110),
                            itemCount: 3,
                            itemBuilder: (_, __) =>
                            const SkeletonPostCard(),
                          );
                        }

                        if (snapshot.hasError) {
                          return ListView(
                            padding:
                            const EdgeInsets.fromLTRB(20, 30, 20, 110),
                            children: [
                              EmptyStateCard(
                                icon: Icons.error_outline_rounded,
                                title: l10n.feedErrLoadPosts,
                                subtitle: l10n.feedErrCheckConnection,
                              ),
                            ],
                          );
                        }

                        final docs = snapshot.data ?? [];

                        if (docs.isEmpty) {
                          return ListView(
                            padding:
                            const EdgeInsets.fromLTRB(20, 30, 20, 110),
                            children: [
                              EmptyStateCard(
                                icon: Icons.feed_outlined,
                                title: l10n.feedEmptyPublicPosts,
                                subtitle: l10n.feedEmptyPublicPostsSub,
                              ),
                            ],
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 110),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index];

                            final post = {
                              'postId': data.id,
                              'authorId': data.authorId,
                              'authorName': data.authorName,
                              'groupName': data.groupName,
                              'groupImageUrl': data.groupImageUrl,
                              'groupMeta': 'Public Group',
                              'time': _formatTime(data.createdAt, l10n),
                              'content': data.contentText,
                              'likes': data.likesCount,
                              'comments': data.commentsCount,
                              'hasImage': data.contentImageUrl.isNotEmpty,
                              'imageUrl': data.contentImageUrl,
                              'groupId': data.groupId,
                              'tag': 'Public',
                            };

                            return AnimatedPostWrapper(
                              delay: Duration(milliseconds: 70 * index),
                              child: PostCard(post: post),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

  class FeedTopActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool hasBadge;

  const FeedTopActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.hasBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface.withOpacity(0.98) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.border : Colors.black12,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isDark ? AppColors.textPrimary : Colors.black87,
              size: 21,
            ),
          ),
        ),
        if (hasBadge)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class ModernChip extends StatelessWidget {
  final String label;
  final String? originalValue;
  final bool active;

  const ModernChip({
    super.key,
    required this.label,
    this.originalValue,
    this.active = false,
  });

  IconData _getIcon() {
    final checkLabel = originalValue ?? label;
    if (checkLabel.contains('For You')) return Icons.auto_awesome_rounded;
    if (checkLabel.contains('Recent')) return Icons.access_time_rounded;
    if (checkLabel.contains('Popular')) {
      return Icons.local_fire_department_rounded;
    }
    if (checkLabel.contains('Academic')) return Icons.account_balance_rounded;
    return Icons.filter_list_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary.withOpacity(0.12)
            : (isDark
            ? AppColors.surface.withOpacity(0.4)
            : Colors.white.withOpacity(0.75)),
        borderRadius: BorderRadius.circular(22),
        border: active
            ? Border.all(color: AppColors.primary.withOpacity(0.30))
            : Border.all(
          color: isDark
              ? AppColors.border.withOpacity(0.35)
              : Colors.black12,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            size: 14,
            color: active
                ? AppColors.primary
                : AppColors.textSecondary.withOpacity(0.85),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: active
                  ? AppColors.primary
                  : (isDark ? AppColors.textSecondary : Colors.black54),
              fontSize: 13,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedPostWrapper extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const AnimatedPostWrapper({
    super.key,
    required this.child,
    required this.delay,
  });

  @override
  State<AnimatedPostWrapper> createState() => _AnimatedPostWrapperState();
}

class _AnimatedPostWrapperState extends State<AnimatedPostWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostCard({
    super.key,
    required this.post,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  bool isLiked = false;
  bool isPressed = false;
  bool _isJoined = false;
  bool _isLoadingJoined = true;
  bool _isLoadingLike = false;
  int _likesCount = 0;

  late final AnimationController _likeController;
  late final Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post['likes'] as int? ?? 0;
    _checkMembership();
    _checkLikeStatus();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _likeScale = Tween<double>(begin: 1, end: 1.18).animate(
      CurvedAnimation(parent: _likeController, curve: Curves.easeOut),
    );
  }

  Future<void> _checkMembership() async {
    final groupId = widget.post['groupId']?.toString() ?? '';
    if (groupId.isNotEmpty) {
      final state = await GroupService.getUserGroupState(groupId);
      if (mounted) {
        setState(() {
          _isJoined = state.isMember;
          _isLoadingJoined = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoadingJoined = false);
    }
  }

  Future<void> _checkLikeStatus() async {
    final postId = widget.post['postId']?.toString() ?? '';
    if (postId.isNotEmpty) {
      final liked = await FeedReactionsService.hasUserLikedPost(postId);
      if (mounted) {
        setState(() {
          isLiked = liked;
        });
      }
    }
  }

  Future<void> _joinGroup() async {
    if (_isLoadingJoined || _isJoined) return;

    // 🚫 Guest cannot join
    if (context.read<GuestProvider>().isGuest) {
      GuestActionDialog.show(
        context,
        title: 'تسجيل الدخول مطلوب',
        subtitle: 'يمكنك مشاهدة المجموعات كضيف، وللانضمام يجب تسجيل الدخول.',
      );
      return;
    }

    final groupId = widget.post['groupId']?.toString() ?? '';
    if (groupId.isEmpty) return;

    setState(() {
      _isLoadingJoined = true;
    });

    try {
      await GroupService.joinPublicGroup(groupId);
      if (mounted) {
        setState(() {
          _isJoined = true;
        });
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.feedJoinedGroup)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingJoined = false;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_isLoadingLike) return;

    // 🚫 Guest cannot like
    if (context.read<GuestProvider>().isGuest) {
      GuestActionDialog.show(
        context,
        title: 'تسجيل الدخول مطلوب',
        subtitle: 'أنت الآن في وضع الضيف. سجّل دخولك لتتمكن من الإعجاب بالمنشورات.',
      );
      return;
    }

    final postId = widget.post['postId']?.toString() ?? '';
    if (postId.isEmpty) return;

    final oldIsLiked = isLiked;

    setState(() {
      _isLoadingLike = true;
      isLiked = !isLiked;
      _likesCount += isLiked ? 1 : -1;
    });

    _likeController.forward().then((_) => _likeController.reverse());

    try {
      await FeedReactionsService.toggleLike(
        postId: postId,
        isCurrentlyLiked: oldIsLiked,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          isLiked = oldIsLiked;
          _likesCount += oldIsLiked ? 1 : -1;
        });
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.feedErrUpdateLike)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLike = false;
        });
      }
    }
  }

  void _showPostMenu(BuildContext context) {
    final postId  = widget.post['postId']?.toString() ?? '';
    final authorId = widget.post['authorId']?.toString() ?? '';
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isOwner = currentUid == authorId;
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetColor = isDark ? AppColors.surface : Colors.white;

        return Container(
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag handle
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (isOwner) ...[
                _MenuTile(
                  icon: Icons.edit_outlined,
                  label: 'تعديل المنشور',
                  onTap: () {
                    Navigator.pop(context);
                    _showEditSheet(context, postId);
                  },
                ),
                _MenuTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'حذف المنشور',
                  color: AppColors.error,
                  onTap: () async {
                    Navigator.pop(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('حذف المنشور'),
                        content: const Text('هل أنت متأكد أنك تريد حذف هذا المنشور؟'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('إلغاء'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('حذف', style: TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && postId.isNotEmpty) {
                      try {
                        await FeedService.deletePost(postId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم حذف المنشور')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
              if (!isOwner)
                _MenuTile(
                  icon: Icons.flag_outlined,
                  label: 'إبلاغ عن المنشور',
                  color: AppColors.error,
                  onTap: () async {
                    Navigator.pop(context);
                    
                    // 🚫 Guest cannot report
                    if (context.read<GuestProvider>().isGuest) {
                      GuestActionDialog.show(context);
                      return;
                    }

                    if (postId.isEmpty) return;
                    try {
                      await FeedService.reportPost(
                        postId: postId,
                        reason: 'user_report',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم إرسال البلاغ، شكرًا لك')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                        );
                      }
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showEditSheet(BuildContext context, String postId) {
    final currentText = widget.post['content']?.toString() ?? '';
    final controller = TextEditingController(text: currentText);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetColor = isDark ? AppColors.surface : Colors.white;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: sheetColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'تعديل المنشور',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textPrimary : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.background.withOpacity(0.6)
                            : const Color(0xFFF7F8FB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.border.withOpacity(0.5)
                              : Colors.black12,
                        ),
                      ),
                      child: TextField(
                        controller: controller,
                        maxLines: null,
                        minLines: 4,
                        style: TextStyle(
                          fontSize: 15.5,
                          height: 1.55,
                          color: isDark ? AppColors.textPrimary : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          hintText: 'اكتب المنشور...',
                          hintStyle: TextStyle(
                            color: isDark
                                ? AppColors.textSecondary
                                : Colors.black38,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                final newText = controller.text.trim();
                                if (newText.isEmpty || newText == currentText) {
                                  Navigator.pop(sheetCtx);
                                  return;
                                }
                                setSheetState(() => isSaving = true);
                                try {
                                  await FeedService.updatePost(
                                    postId: postId,
                                    newText: newText,
                                  );
                                  if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('تم تعديل المنشور بنجاح')),
                                    );
                                  }
                                } catch (e) {
                                  setSheetState(() => isSaving = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                                    );
                                  }
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'حفظ التعديل',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() => controller.dispose());
  }

  void _handleGroupTap() async {
    final groupId = widget.post['groupId']?.toString() ?? '';
    if (groupId.isEmpty) return;

    if (_isJoined) {
      // 1) Logic for Members: Direct Navigation
      try {
        final group = await GroupService.getGroupById(groupId);
        if (group != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupChatScreen(group: group),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر فتح المجموعة حالياً')),
          );
        }
      }
    } else {
      // 2) Logic for Non-members: Show Preview only
      _showGroupPreview(groupId);
    }
  }

  void _showGroupPreview(String groupId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return FutureBuilder<GroupModel?>(
          future: GroupService.getGroupById(groupId),
          builder: (context, snapshot) {
            final group = snapshot.data;
            final isLoading = snapshot.connectionState == ConnectionState.waiting;

            return Container(
              height: 310,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151A22) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Drag Handle
                  Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  if (isLoading)
                    const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3)))
                  else if (group == null)
                    const Expanded(child: Center(child: Text('المجموعة غير موجودة')))
                  else ...[
                    const SizedBox(height: 24),
                    // Header: Image + Identity
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Container(
                            width: 68, height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary.withOpacity(0.12), width: 2.5),
                            ),
                            child: ClipOval(
                              child: group.imageUrl.isNotEmpty
                                  ? Image.network(group.imageUrl, fit: BoxFit.cover)
                                  : Container(
                                      color: AppColors.primary.withOpacity(0.08),
                                      child: const Icon(Icons.groups_rounded, size: 32, color: AppColors.primary),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? AppColors.textPrimary : const Color(0xFF181A20),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.people_alt_rounded, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${group.membersCounts} عضو نشط',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Body: Compact Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8F9FB),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          group.description.isNotEmpty ? group.description : 'لا يوجد وصف متاح لهذه المجموعة.',
                          textAlign: TextAlign.start,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.5,
                            color: isDark ? AppColors.textSecondary : const Color(0xFF6A6E7D),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ]
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = (widget.post['imageUrl'] ?? '').toString();

    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: isPressed ? 0.988 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? AppColors.border.withOpacity(0.50)
                  : Colors.black12,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  isPressed
                      ? (isDark ? 0.18 : 0.05)
                      : (isDark ? 0.10 : 0.03),
                ),
                blurRadius: isPressed ? 10 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _handleGroupTap,
                    child: () {
                      final groupImg = (widget.post['groupImageUrl'] ?? '').toString();
                      if (groupImg.isNotEmpty) {
                        return CircleAvatar(
                          radius: 23,
                          backgroundColor: AppColors.primary.withOpacity(0.12),
                          backgroundImage: NetworkImage(groupImg),
                        );
                      }
                      return Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      );
                    }(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.post['authorName'] ?? ''}',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textPrimary
                                : Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Flexible(
                              child: GestureDetector(
                                onTap: _handleGroupTap,
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.groups_rounded,
                                      size: 15,
                                      color: AppColors.primary.withOpacity(0.9),
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        (widget.post['groupName'] ?? '').toString(),
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppColors.primary.withOpacity(0.95),
                                          fontSize: 12.8,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.circle,
                              size: 4,
                              color:
                              AppColors.textSecondary.withOpacity(0.65),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.post['time'] ?? ''}',
                              style: TextStyle(
                                color:
                                AppColors.textSecondary.withOpacity(0.82),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!_isJoined)
                    InkWell(
                      onTap: _isLoadingJoined ? null : _joinGroup,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.22),
                          ),
                        ),
                        child: Center(
                          child: _isLoadingJoined
                              ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                              : Text(
                            l10n.feedJoinAction,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12.8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showPostMenu(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.background.withOpacity(0.7)
                            : const Color(0xFFF7F8FB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.more_horiz,
                        color: isDark
                            ? AppColors.textSecondary
                            : Colors.black45,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                widget.post['content'] ?? '',
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : Colors.black87,
                  fontSize: 15.3,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if ((widget.post['hasImage'] ?? false) == true) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    height: 230,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.border.withOpacity(0.25),
                      ),
                      color: AppColors.surface,
                    ),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.textSecondary,
                          size: 34,
                        ),
                      ),
                    )
                        : const Center(
                      child: Icon(
                        Icons.image_outlined,
                        color: AppColors.textSecondary,
                        size: 34,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  _PostMetaItem(
                    icon: Icons.favorite_rounded,
                    value: '$_likesCount',
                    color: Colors.red,
                  ),
                  const SizedBox(width: 14),
                  _PostMetaItem(
                    icon: Icons.chat_bubble_rounded,
                    value: '${widget.post['comments'] ?? 0}',
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.border.withOpacity(0.28),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: l10n.likeAction,
                      active: isLiked,
                      activeColor: Colors.red,
                      onTap: _toggleLike,
                    ),
                  ),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: l10n.commentAction,
                      active: false,
                      activeColor: AppColors.primary,
                      onTap: () {
                        // 🚫 Guest cannot comment
                        if (context.read<GuestProvider>().isGuest) {
                          GuestActionDialog.show(context);
                          return;
                        }
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child:
                            PostCommentsSheet(postCardData: widget.post),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.share_outlined,
                      label: l10n.shareAction,
                      active: false,
                      activeColor: AppColors.primary,
                      onTap: () {
                        // 🚫 Guest cannot share
                        if (context.read<GuestProvider>().isGuest) {
                          GuestActionDialog.show(
                            context,
                            title: 'تسجيل الدخول مطلوب',
                            subtitle: 'أنت الآن تتصفح كضيف. لتتمكن من مشاركة المنشورات، يرجى تسجيل الدخول.',
                          );
                          return;
                        }
                        final feedPost = FeedPostModel.fromMap(
                          widget.post,
                          widget.post['postId']?.toString() ?? '',
                        );
                        FeedShareService.sharePost(context, feedPost);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostMetaItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _PostMetaItem({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.9),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 19,
              color: active
                  ? activeColor
                  : (isDark ? AppColors.textSecondary : Colors.black54),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active
                    ? activeColor
                    : (isDark ? AppColors.textSecondary : Colors.black54),
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FlatPostAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const FlatPostAction({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            if (label.isNotEmpty) const SizedBox(width: 6),
            if (label.isNotEmpty)
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = color ??
        (isDark ? AppColors.textPrimary : Colors.black87);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
        child: Row(
          children: [
            Icon(icon, size: 22, color: effectiveColor),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonPostCard extends StatefulWidget {
  const SkeletonPostCard({super.key});

  @override
  State<SkeletonPostCard> createState() => _SkeletonPostCardState();
}

class _SkeletonPostCardState extends State<SkeletonPostCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t) ?? a;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const baseLight = Color(0xFFF1F4FA);
    const highlightLight = Color(0xFFF8FAFE);
    const baseDark = AppColors.surface;
    final highlightDark = AppColors.surface.withOpacity(0.5);

    final base = isDark ? baseDark : baseLight;
    final highlight = isDark ? highlightDark : highlightLight;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final c = _mix(base, highlight, _controller.value);
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.border : Colors.black12,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonBox(width: 46, height: 46, color: c, radius: 15),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        SkeletonBox(
                          width: double.infinity,
                          height: 12,
                          color: c,
                          radius: 6,
                        ),
                        const SizedBox(height: 8),
                        SkeletonBox(
                          width: 120,
                          height: 10,
                          color: c,
                          radius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SkeletonBox(width: 64, height: 34, color: c, radius: 10),
                ],
              ),
              const SizedBox(height: 14),
              SkeletonBox(width: 80, height: 24, color: c, radius: 10),
              const SizedBox(height: 12),
              SkeletonBox(
                width: double.infinity,
                height: 12,
                color: c,
                radius: 6,
              ),
              const SizedBox(height: 8),
              SkeletonBox(
                width: double.infinity,
                height: 12,
                color: c,
                radius: 6,
              ),
              const SizedBox(height: 8),
              SkeletonBox(width: 180, height: 12, color: c, radius: 6),
              const SizedBox(height: 14),
              SkeletonBox(
                width: double.infinity,
                height: 170,
                color: c,
                radius: 18,
              ),
              const SizedBox(height: 14),
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.border,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SkeletonBox(width: 54, height: 18, color: c, radius: 8),
                  const SizedBox(width: 20),
                  SkeletonBox(width: 54, height: 18, color: c, radius: 8),
                  const SizedBox(width: 20),
                  SkeletonBox(width: 54, height: 18, color: c, radius: 8),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final Color color;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    required this.color,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      constraints: width == double.infinity
          ? const BoxConstraints(minWidth: double.infinity)
          : null,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.border : Colors.black12,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withOpacity(0.08),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: isDark ? AppColors.textPrimary : Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? AppColors.textSecondary : Colors.black54,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}