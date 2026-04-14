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
import '../../models/feed_post_model.dart';
import '../groups/group_chat_screen.dart';
import '../../widgets/feed/post_card_wrapper.dart';
import '../../widgets/common/premium_transitions.dart';

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
      PremiumPageRoute(page: const ProfileScreen()),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      PremiumPageRoute(page: const NotificationsScreen()),
    );
  }

  void _openBot() {
    Navigator.push(
      context,
      PremiumPageRoute(
        page: const BotScreen(sourceScreen: 'feed_screen'),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (context.watch<GuestProvider>().isGuest)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 4),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text(
                                  'دخول',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                                ),
                              ),
                            ),
                          FeedTopActionButton(
                            icon: Icons.settings_rounded,
                            onTap: () => SettingsBottomSheet.show(context),
                          ),
                          const SizedBox(width: 4),
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
                    height: 42,
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
                          blurRadius: 8,
                          offset: const Offset(0, 3),
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
                        const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
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
                              'contentText': data.contentText,
                              'likesCount': data.likesCount,
                              'commentsCount': data.commentsCount,
                              'contentImageUrl': data.contentImageUrl,
                              'groupId': data.groupId,
                              'tag': 'Public',
                            };

                            return AnimatedPostWrapper(
                              delay: Duration(milliseconds: 70 * index),
                              child: PostCardWrapper(post: post),
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
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface.withOpacity(0.98) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.border : Colors.black12,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isDark ? AppColors.textPrimary : Colors.black87,
              size: 20,
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary.withOpacity(0.12)
            : (isDark
            ? AppColors.surface.withOpacity(0.4)
            : Colors.white.withOpacity(0.75)),
        borderRadius: BorderRadius.circular(14),
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
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface : Colors.white,
            borderRadius: BorderRadius.circular(16),
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
                height: 190,
                color: c,
                radius: 14,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.border : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.14 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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