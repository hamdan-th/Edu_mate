import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../notifications/notifications_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/guest_provider.dart';
import '../../services/feed_service.dart';
import '../../models/feed_post_model.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_bottom_sheet.dart';
import '../../features/edu_bot/presentation/widgets/floating_bot_button.dart';
import '../../services/notifications_service.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: const SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: 96),
          child: FloatingBotButton(sourceScreen: 'feed_screen'),
        ),
      ),
      body: Stack(
        children: [
          // Subtle top gradient accent — mirrors login/signup premium depth
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surface.withValues(alpha: isDark ? 0.55 : 0.25),
                    theme.scaffoldBackgroundColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Brand title + subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.app_name,
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                                fontSize: 26,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.filterForYou,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Action icons (guest login + settings + bell + profile)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (context.watch<GuestProvider>().isGuest)
                            Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(end: 6),
                              child: _GuestLoginPill(
                                onTap: () async {
                                  final nav = Navigator.of(context);
                                  await FirebaseAuth.instance.signOut();
                                  if (!mounted) return;
                                  nav.pushNamedAndRemoveUntil(
                                      '/login', (route) => false);
                                },
                              ),
                            ),
                          FeedTopActionButton(
                            icon: Icons.settings_rounded,
                            onTap: () => SettingsBottomSheet.show(context),
                          ),
                          const SizedBox(width: 6),
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
                          const SizedBox(width: 6),
                          FeedTopActionButton(
                            icon: Icons.person_outline_rounded,
                            onTap: _openProfile,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Search bar ───────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 
                          isDark ? 0.45 : 0.20,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: l10n.feedSearchHint,
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                          size: 20,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 11),
                        filled: false,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Filter chips ──────────────────────────────────────────
                SizedBox(
                  height: 38,
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

                // ── Post feed ─────────────────────────────────────────────
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    color: colorScheme.primary,
                    backgroundColor: colorScheme.surface,
                    child: StreamBuilder<List<FeedPostModel>>(
                      stream: _postsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 110),
                            itemCount: 3,
                            itemBuilder: (_, __) => const SkeletonPostCard(),
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

// ─────────────────────────────────────────────────────────────────────────────
// Guest login pill  (compact, branded)
// ─────────────────────────────────────────────────────────────────────────────
class _GuestLoginPill extends StatelessWidget {
  final VoidCallback onTap;
  const _GuestLoginPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.35 : 0.25),
          ),
        ),
        child: Text(
          'دخول',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top action button  (settings / notifications / profile)
// ─────────────────────────────────────────────────────────────────────────────
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
    final colorScheme = Theme.of(context).colorScheme;
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
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: isDark ? 0.55 : 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: colorScheme.onSurface.withValues(alpha: 0.75),
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
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chip
// ─────────────────────────────────────────────────────────────────────────────
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 0),
      decoration: BoxDecoration(
        color: active
            ? colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.12)
            : colorScheme.surface.withValues(alpha: isDark ? 0.60 : 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? colorScheme.primary.withValues(alpha: isDark ? 0.45 : 0.30)
              : colorScheme.outline.withValues(alpha: isDark ? 0.30 : 0.18),
          width: active ? 1.3 : 1.0,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            size: 13,
            color: active
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.45),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: active
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 
                      isDark ? 0.55 : 0.60,
                    ),
              fontSize: 13,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: active ? 0.1 : 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Staggered post entrance animation
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton post card  (loading placeholder)
// ─────────────────────────────────────────────────────────────────────────────
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final base = isDark
        ? colorScheme.surface
        : const Color(0xFFF1F4FA);
    final highlight = isDark
        ? colorScheme.surface.withValues(alpha: 0.45)
        : const Color(0xFFF8FAFE);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final c = _mix(base, highlight, _controller.value);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: isDark ? 0.45 : 0.18),
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
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outline.withValues(alpha: 0.25),
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

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton box primitive
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// Empty / error state card
// ─────────────────────────────────────────────────────────────────────────────
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: isDark ? 0.40 : 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha: 0.08),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}