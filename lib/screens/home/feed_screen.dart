import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/feed_reactions_service.dart';
import '../../services/feed_service.dart';
import '../../services/feed_share_service.dart';
import '../../models/feed_post_model.dart';
import 'widgets/post_comments_sheet.dart';
import '../../services/group_service.dart';
import '../profile/profile_screen.dart';
import '../../features/edu_bot/presentation/screens/bot_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String _selectedFilter = 'For You';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = const ['For You', 'Academic', 'Popular', 'Recent'];

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
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  void _openNotifications() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaceholderNotificationsScreen()));
  }

  void _openBot() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const BotScreen()));
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

  Stream<List<FeedPostModel>> _postsStream() {
    return FeedService.streamPublicFeed(filter: _selectedFilter, searchQuery: _searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 96),
        child: FloatingStudyBotButton(onTap: _openBot),
      ),
      body: Stack(
        children: [
          // Ambient Glows
          Positioned(
            top: -110,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.04),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 100)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Premium Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.darkSurface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.primary, Color(0xFFC79A22)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: const Icon(Icons.school_rounded, color: AppColors.secondary, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Edu Mate',
                                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Public groups feed',
                                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FeedTopActionButton(icon: Icons.notifications_none_rounded, hasBadge: true, onTap: _openNotifications),
                      const SizedBox(width: 10),
                      FeedTopActionButton(icon: Icons.person_outline_rounded, onTap: _openProfile),
                    ],
                  ),
                ),
                
                // Filters Row
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final label = _filters[index];
                      final active = _selectedFilter == label;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedFilter = label),
                        child: ModernChip(label: label, active: active),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Feed Stream
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    color: AppColors.primary,
                    backgroundColor: AppColors.darkSurface,
                    child: StreamBuilder<List<FeedPostModel>>(
                      stream: _postsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                            itemCount: 3,
                            itemBuilder: (_, __) => const SkeletonPostCard(),
                          );
                        }

                        if (snapshot.hasError) {
                          return ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 30, 20, 120),
                            children: const [
                              EmptyStateCard(icon: Icons.error_outline_rounded, title: 'تعذر تحميل المنشورات', subtitle: 'تحقق من الاتصال أو من إعدادات Firestore'),
                            ],
                          );
                        }

                        final docs = snapshot.data ?? [];

                        if (docs.isEmpty) {
                          return ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 30, 20, 120),
                            children: const [
                              EmptyStateCard(icon: Icons.feed_outlined, title: 'لا يوجد منشورات عامة بعد', subtitle: 'ستظهر هنا فقط منشورات المجموعات العامة'),
                            ],
                          );
                        }

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index];
                            final post = {
                              'postId': data.id,
                              'authorId': data.authorId,
                              'authorName': data.authorName,
                              'groupName': data.groupName,
                              'groupMeta': 'Public Group',
                              'time': _formatTime(data.createdAt),
                              'content': data.contentText,
                              'likes': data.likesCount,
                              'comments': data.commentsCount,
                              'hasImage': data.contentImageUrl.isNotEmpty,
                              'imageUrl': data.contentImageUrl,
                              'groupId': data.groupId,
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

class FloatingStudyBotButton extends StatefulWidget {
  final VoidCallback onTap;
  const FloatingStudyBotButton({super.key, required this.onTap});

  @override
  State<FloatingStudyBotButton> createState() => _FloatingStudyBotButtonState();
}

class _FloatingStudyBotButtonState extends State<FloatingStudyBotButton> {
  bool _isPressed = false;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.secondary, size: 22),
              SizedBox(width: 8),
              Text('Edu Bot', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.secondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class FeedTopActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool hasBadge;
  const FeedTopActionButton({super.key, required this.icon, required this.onTap, this.hasBadge = false});

  @override
  State<FeedTopActionButton> createState() => _FeedTopActionButtonState();
}

class _FeedTopActionButtonState extends State<FeedTopActionButton> {
  bool _isPressed = false;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Icon(widget.icon, color: Colors.white, size: 22),
            ),
            if (widget.hasBadge)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.darkSurface, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ModernChip extends StatelessWidget {
  final String label;
  final bool active;
  const ModernChip({super.key, required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: active ? null : Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: active 
            ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] 
            : [],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.secondary : Colors.white.withOpacity(0.6),
            fontSize: 13,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class AnimatedPostWrapper extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const AnimatedPostWrapper({super.key, required this.child, required this.delay});

  @override
  State<AnimatedPostWrapper> createState() => _AnimatedPostWrapperState();
}

class _AnimatedPostWrapperState extends State<AnimatedPostWrapper> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _offset = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
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
    return FadeTransition(opacity: _opacity, child: SlideTransition(position: _offset, child: widget.child));
  }
}

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
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
    _likeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _likeScale = Tween<double>(begin: 1, end: 1.3).animate(CurvedAnimation(parent: _likeController, curve: Curves.elasticOut));
  }

  Future<void> _checkMembership() async {
    final groupId = widget.post['groupId']?.toString() ?? '';
    if (groupId.isNotEmpty) {
      final state = await GroupService.getUserGroupState(groupId);
      if (mounted) setState(() { _isJoined = state.isMember; _isLoadingJoined = false; });
    } else {
      if (mounted) setState(() => _isLoadingJoined = false);
    }
  }

  Future<void> _checkLikeStatus() async {
    final postId = widget.post['postId']?.toString() ?? '';
    if (postId.isNotEmpty) {
      final liked = await FeedReactionsService.hasUserLikedPost(postId);
      if (mounted) setState(() => isLiked = liked);
    }
  }

  Future<void> _joinGroup() async {
    if (_isLoadingJoined || _isJoined) return;
    final groupId = widget.post['groupId']?.toString() ?? '';
    if (groupId.isEmpty) return;
    
    setState(() => _isLoadingJoined = true);
    try {
      await GroupService.joinPublicGroup(groupId);
      if (mounted) {
        setState(() => _isJoined = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الانضمام للمجموعة')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _isLoadingJoined = false);
    }
  }

  Future<void> _toggleLike() async {
    if (_isLoadingLike) return;
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
      await FeedReactionsService.toggleLike(postId: postId, isCurrentlyLiked: oldIsLiked);
    } catch (e) {
      if (mounted) {
        setState(() { isLiked = oldIsLiked; _likesCount += oldIsLiked ? 1 : -1; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تحديث الإعجاب')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingLike = false);
    }
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = (widget.post['imageUrl'] ?? '').toString();

    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: isPressed ? 0.98 : 1,
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFFC79A22)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Center(
                      child: Text(
                        (widget.post['authorName']?.toString().isNotEmpty ?? false) ? widget.post['authorName'].toString()[0].toUpperCase() : 'U',
                        style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w900, fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (widget.post['groupName'] ?? '').toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              widget.post['authorName'] ?? '',
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              ' • ${widget.post['time'] ?? ''}',
                              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: (_isLoadingJoined || _isJoined) ? null : _joinGroup,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isJoined ? AppColors.primary.withOpacity(0.1) : AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        border: _isJoined ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
                      ),
                      child: Center(
                        child: _isLoadingJoined
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(
                                _isJoined ? 'Joined' : 'Join',
                                style: TextStyle(
                                  color: _isJoined ? AppColors.primary : AppColors.secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              
              // Post Content
              Text(
                widget.post['content'] ?? '',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14.5,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if ((widget.post['hasImage'] ?? false) == true) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported_outlined, color: Colors.white.withOpacity(0.3), size: 34))
                        : Icon(Icons.image_outlined, color: Colors.white.withOpacity(0.3), size: 34),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              
              Divider(height: 1, thickness: 1, color: Colors.white.withOpacity(0.06)),
              const SizedBox(height: 14),
              
              // Action Row
              Row(
                children: [
                  GestureDetector(
                    onTap: _toggleLike,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isLiked ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          ScaleTransition(
                            scale: _likeScale,
                            child: Icon(
                              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              size: 20,
                              color: isLiked ? AppColors.primary : Colors.white.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$_likesCount',
                            style: TextStyle(
                              color: isLiked ? AppColors.primary : Colors.white.withOpacity(0.5),
                              fontSize: 13,
                              fontWeight: isLiked ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FlatPostAction(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '${widget.post['comments'] ?? 0}',
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: PostCommentsSheet(postCardData: widget.post)),
                      );
                    },
                  ),
                  const Spacer(),
                  FlatPostAction(
                    icon: Icons.share_rounded,
                    label: '',
                    onTap: () {
                      final feedPost = FeedPostModel.fromMap(widget.post, widget.post['postId']?.toString() ?? '');
                      FeedShareService.sharePost(context, feedPost);
                    },
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
  final VoidCallback? onTap;

  const FlatPostAction({super.key, required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: Colors.transparent,
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.white.withOpacity(0.5)),
            if (label.isNotEmpty) const SizedBox(width: 8),
            if (label.isNotEmpty)
              Text(
                label,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w600),
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

class _SkeletonPostCardState extends State<SkeletonPostCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t) ?? a;

  @override
  Widget build(BuildContext context) {
    final base = AppColors.darkSurface.withOpacity(0.5);
    final highlight = AppColors.darkSurface.withOpacity(0.9);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final c = _mix(base, highlight, _controller.value);
        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.04))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonBox(width: 48, height: 48, color: c, radius: 24),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SkeletonBox(width: 120, height: 14, color: c, radius: 6), const SizedBox(height: 8), SkeletonBox(width: 80, height: 10, color: c, radius: 4)])),
                ],
              ),
              const SizedBox(height: 20),
              SkeletonBox(width: double.infinity, height: 12, color: c, radius: 6),
              const SizedBox(height: 8),
              SkeletonBox(width: double.infinity, height: 12, color: c, radius: 6),
              const SizedBox(height: 8),
              SkeletonBox(width: 150, height: 12, color: c, radius: 6),
              const SizedBox(height: 20),
              SkeletonBox(width: double.infinity, height: 180, color: c, radius: 16),
            ],
          ),
        );
      },
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double width, height, radius;
  final Color color;
  const SkeletonBox({super.key, required this.width, required this.height, required this.color, required this.radius});
  @override
  Widget build(BuildContext context) {
    return Container(width: width, height: height, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)));
  }
}

class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const EmptyStateCard({super.key, required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 48),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class PlaceholderNotificationsScreen extends StatelessWidget {
  const PlaceholderNotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.background, appBar: AppBar(backgroundColor: AppColors.background, title: const Text('Notifications')), body: const Center(child: Text('الإشعارات ستربط لاحقًا', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))));
  }
}

class PlaceholderBotScreen extends StatelessWidget {
  const PlaceholderBotScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.background, appBar: AppBar(backgroundColor: AppColors.background, title: const Text('Edu Bot')), body: const Center(child: Text('البوت سيُربط بالذكاء الاصطناعي لاحقًا', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))));
  }
}