import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../profile/profile_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String _selectedFilter = 'For You';

  final List<String> _filters = const [
    'For You',
    'Academic',
    'Popular',
    'Recent',
  ];

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
        builder: (_) => const PlaceholderNotificationsScreen(),
      ),
    );
  }

  void _openBot() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PlaceholderBotScreen(),
      ),
    );
  }

  String _formatTime(dynamic value) {
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

    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }

  bool _isValidPost(Map<String, dynamic> data) {
    final contentText = (data['contentText'] ?? '').toString().trim();
    final contentImageUrl = (data['contentImageUrl'] ?? '').toString().trim();
    final groupId = (data['groupId'] ?? '').toString().trim();
    final groupName = (data['groupName'] ?? '').toString().trim();
    final visibility = (data['visibility'] ?? '').toString().trim();

    final hasContent = contentText.isNotEmpty || contentImageUrl.isNotEmpty;
    final hasGroup = groupId.isNotEmpty || groupName.isNotEmpty;
    final isPublic = visibility.toLowerCase() == 'public';

    return hasContent && hasGroup && isPublic;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _postsStream() {
    return FirebaseFirestore.instance
        .collection('posts')
        .where('visibility', isEqualTo: 'public')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 74),
        child: FloatingStudyBotButton(
          onTap: _openBot,
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -110,
            right: -60,
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
            top: 140,
            left: -35,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.04),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.97),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.06),
                                blurRadius: 14,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primaryDark,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Edu Mate',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Public groups feed',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FeedTopActionButton(
                        icon: Icons.notifications_none_rounded,
                        hasBadge: true,
                        onTap: _openNotifications,
                      ),
                      const SizedBox(width: 10),
                      FeedTopActionButton(
                        icon: Icons.person_outline_rounded,
                        onTap: _openProfile,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.98),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const TextField(
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search public posts or groups',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final label = _filters[index];
                      final active = _selectedFilter == label;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = label;
                          });
                        },
                        child: ModernChip(label: label, active: active),
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
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _postsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return ListView.builder(
                            padding:
                            const EdgeInsets.fromLTRB(20, 0, 20, 110),
                            itemCount: 3,
                            itemBuilder: (_, __) =>
                            const SkeletonPostCard(),
                          );
                        }

                        if (snapshot.hasError) {
                          return ListView(
                            padding:
                            const EdgeInsets.fromLTRB(20, 30, 20, 110),
                            children: const [
                              EmptyStateCard(
                                icon: Icons.error_outline_rounded,
                                title: 'تعذر تحميل المنشورات',
                                subtitle:
                                'تحقق من الاتصال أو من إعدادات Firestore',
                              ),
                            ],
                          );
                        }

                        final rawDocs = snapshot.data?.docs ?? [];

                        final docs = rawDocs.where((doc) {
                          final data = doc.data();
                          return _isValidPost(data);
                        }).toList();

                        if (docs.isEmpty) {
                          return ListView(
                            padding:
                            const EdgeInsets.fromLTRB(20, 30, 20, 110),
                            children: const [
                              EmptyStateCard(
                                icon: Icons.feed_outlined,
                                title: 'لا يوجد منشورات عامة بعد',
                                subtitle:
                                'ستظهر هنا فقط منشورات المجموعات العامة',
                              ),
                            ],
                          );
                        }

                        return ListView.builder(
                          padding:
                          const EdgeInsets.fromLTRB(20, 0, 20, 110),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data();

                            final post = {
                              'postId': data['postId'] ?? docs[index].id,
                              'authorId': data['authorId'] ?? '',
                              'authorName': data['authorName'] ?? '',
                              'groupName': data['groupName'] ?? '',
                              'groupMeta': 'Public Group',
                              'time': _formatTime(data['createdAt']),
                              'content': data['contentText'] ?? '',
                              'likes': data['likesCount'] ?? 0,
                              'comments': data['commentsCount'] ?? 0,
                              'hasImage':
                              (data['contentImageUrl'] ?? '')
                                  .toString()
                                  .trim()
                                  .isNotEmpty,
                              'imageUrl': data['contentImageUrl'] ?? '',
                              'joined': true,
                              'tag': 'Public',
                            };

                            return AnimatedPostWrapper(
                              delay: Duration(milliseconds: 80 * index),
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

class FloatingStudyBotButton extends StatelessWidget {
  final VoidCallback onTap;

  const FloatingStudyBotButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.97),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Edu Bot',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
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
              color: AppColors.surface.withOpacity(0.98),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
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
              color: AppColors.textPrimary,
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
  final bool active;

  const ModernChip({
    super.key,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: active ? null : Border.all(color: AppColors.border),
        boxShadow: active
            ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.14),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ]
            : [],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textSecondary,
            fontSize: 12.3,
            fontWeight: FontWeight.w700,
          ),
        ),
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

  late final AnimationController _likeController;
  late final Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _likeScale = Tween<double>(begin: 1, end: 1.18).animate(
      CurvedAnimation(parent: _likeController, curve: Curves.easeOut),
    );
  }

  void _toggleLike() {
    setState(() => isLiked = !isLiked);
    _likeController.forward().then((_) => _likeController.reverse());
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primarySoft = Color(0xFFF1F0FF);
    const accentSoft = Color(0xFFFFF4DD);

    final imageUrl = (widget.post['imageUrl'] ?? '').toString();

    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: isPressed ? 0.985 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withOpacity(
                  isPressed ? 0.07 : 0.04,
                ),
                blurRadius: isPressed ? 18 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (widget.post['groupName'] ?? '').toString(),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${widget.post['authorName'] ?? ''} · ${widget.post['time'] ?? ''}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: widget.post['joined'] == true
                          ? primarySoft
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        widget.post['joined'] == true ? 'Public' : 'Join',
                        style: TextStyle(
                          color: widget.post['joined'] == true
                              ? AppColors.primary
                              : Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.post['tag'] ?? 'Public',
                  style: const TextStyle(
                    color: Color(0xFFB7791F),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.post['content'] ?? '',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if ((widget.post['hasImage'] ?? false) == true) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    height: 190,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      color: const Color(0xFFF8FAFF),
                    ),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.textSecondary,
                            size: 34,
                          ),
                        );
                      },
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
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.border,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _toggleLike,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 4,
                      ),
                      child: ScaleTransition(
                        scale: _likeScale,
                        child: Row(
                          children: [
                            Icon(
                              isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 18,
                              color: isLiked
                                  ? Colors.red
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${widget.post['likes'] ?? 0}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  FlatPostAction(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '${widget.post['comments'] ?? 0}',
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 20),
                  const FlatPostAction(
                    icon: Icons.share_outlined,
                    label: '',
                    color: AppColors.textSecondary,
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

class FlatPostAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const FlatPostAction({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            if (label.isNotEmpty) const SizedBox(width: 5),
            if (label.isNotEmpty)
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
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
    const base = Color(0xFFF1F4FA);
    const highlight = Color(0xFFF8FAFE);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final c = _mix(base, highlight, _controller.value);
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
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
                  SkeletonBox(width: 24, height: 18, color: c, radius: 8),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
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
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class PlaceholderNotificationsScreen extends StatelessWidget {
  const PlaceholderNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: const Center(
        child: Text(
          'الإشعارات ستربط لاحقًا',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class PlaceholderBotScreen extends StatelessWidget {
  const PlaceholderBotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edu Bot'),
      ),
      body: const Center(
        child: Text(
          'البوت سيُربط بالذكاء الاصطناعي لاحقًا',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}