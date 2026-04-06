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
import '../../features/edu_bot/presentation/widgets/animated_bot_button.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String _selectedFilter = 'For You';
  final List<String> _filters = const ['For You', 'Academic', 'Popular', 'Recent'];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() {});
  }

  void _openProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
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

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';

    return '${date.day}/${date.month}/${date.year}';
  }

  Stream<List<FeedPostModel>> _postsStream() {
    return FeedService.streamPublicFeed(filter: _selectedFilter, searchQuery: '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Clean Premium Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Text(
                        'Edu Mate',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                      const Spacer(),
                      _HeaderAction(icon: Icons.search_rounded, onTap: () {}),
                      const SizedBox(width: 12),
                      _HeaderAction(icon: Icons.notifications_none_rounded, hasBadge: true, onTap: () {}),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _openProfile,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/university_logo.png'), // Using uni logo as placeholder avatar for premium feel
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Composer / Quick Post Area (Social style)
                Container(
                  color: AppColors.darkSurface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: const BoxDecoration(color: Color(0xFF262626), shape: BoxShape.circle),
                            child: const Icon(Icons.person, color: Colors.white54),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Share an academic update...",
                                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ComposerAction(icon: Icons.image_rounded, label: 'Photo', color: Colors.greenAccent),
                          _ComposerAction(icon: Icons.article_rounded, label: 'Document', color: Colors.blueAccent),
                          _ComposerAction(icon: Icons.groups_rounded, label: 'Group', color: AppColors.primary),
                        ],
                      ),
                    ],
                  ),
                ),

                // Sleek Filters
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.04))),
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final label = _filters[index];
                      final active = _selectedFilter == label;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFilter = label),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: active ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: active ? AppColors.primary : Colors.transparent),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                color: active ? AppColors.primary : Colors.white.withOpacity(0.5),
                                fontSize: 13.5,
                                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Main Feed
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
                            itemCount: 3,
                            itemBuilder: (_, __) => const SkeletonPostCard(),
                          );
                        }

                        if (snapshot.hasError || (snapshot.data ?? []).isEmpty) {
                          return ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(top: 60),
                            children: const [
                              Center(
                                child: Text('No posts available yet', style: TextStyle(color: Colors.white54, fontSize: 16)),
                              )
                            ],
                          );
                        }

                        final docs = snapshot.data!;
                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 120),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => Container(height: 8, color: AppColors.background), // social divider
                          itemBuilder: (context, index) {
                            final data = docs[index];
                            final post = {
                              'postId': data.id,
                              'authorId': data.authorId,
                              'authorName': data.authorName,
                              'groupName': data.groupName,
                              'time': _formatTime(data.createdAt),
                              'content': data.contentText,
                              'likes': data.likesCount,
                              'comments': data.commentsCount,
                              'hasImage': data.contentImageUrl.isNotEmpty,
                              'imageUrl': data.contentImageUrl,
                              'groupId': data.groupId,
                            };
                            return PostCard(post: post);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Enhanced Floating Draggable Mascot
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedBotButton(
                  onTap: _openBot,
                  screenWidth: constraints.maxWidth,
                  screenHeight: constraints.maxHeight,
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool hasBadge;

  const _HeaderAction({required this.icon, required this.onTap, this.hasBadge = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          if (hasBadge)
            Positioned(
              right: 2, top: 2,
              child: Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle, border: Border.all(color: AppColors.darkSurface, width: 1.5)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ComposerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ComposerAction({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
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
  int _likesCount = 0;
  bool _isJoined = false;

  late final AnimationController _likeController;
  late final Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post['likes'] as int? ?? 0;
    _checkMembership();
    _checkLikeStatus();
    _likeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _likeScale = Tween<double>(begin: 1.0, end: 1.4).animate(CurvedAnimation(parent: _likeController, curve: Curves.elasticOut));
  }

  Future<void> _checkMembership() async {
    final groupId = widget.post['groupId']?.toString() ?? '';
    if (groupId.isNotEmpty) {
      final state = await GroupService.getUserGroupState(groupId);
      if (mounted) setState(() => _isJoined = state.isMember);
    }
  }

  Future<void> _checkLikeStatus() async {
    final postId = widget.post['postId']?.toString() ?? '';
    if (postId.isNotEmpty) {
      final liked = await FeedReactionsService.hasUserLikedPost(postId);
      if (mounted) setState(() => isLiked = liked);
    }
  }

  Future<void> _toggleLike() async {
    final postId = widget.post['postId']?.toString() ?? '';
    if (postId.isEmpty) return;
    
    final oldIsLiked = isLiked;
    setState(() {
      isLiked = !isLiked;
      _likesCount += isLiked ? 1 : -1;
    });

    _likeController.forward().then((_) => _likeController.reverse());
    try {
      await FeedReactionsService.toggleLike(postId: postId, isCurrentlyLiked: oldIsLiked);
    } catch (_) {
      if (mounted) setState(() { isLiked = oldIsLiked; _likesCount += oldIsLiked ? 1 : -1; });
    }
  }

  @override
  void dispose() { _likeController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final imageUrl = (widget.post['imageUrl'] ?? '').toString();

    return Container(
      color: AppColors.darkSurface, // Flat premium social card feel
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF262626),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (widget.post['groupName']?.toString().isNotEmpty ?? false) ? widget.post['groupName'].toString()[0].toUpperCase() : 'G',
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.post['groupName'] ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!_isJoined)
                            GestureDetector(
                              onTap: () {}, // Future logic
                              child: const Text(' • Follow', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(widget.post['authorName'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w500)),
                          Text(' • ${widget.post['time']}', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                          const SizedBox(width: 4),
                          Icon(Icons.public, color: Colors.white.withOpacity(0.4), size: 12),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_horiz_rounded, color: Colors.white.withOpacity(0.6)),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Post Text Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.post['content'] ?? '',
              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14.5, height: 1.4),
            ),
          ),
          
          // Post Media
          if (widget.post['hasImage'] == true && imageUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              width: double.infinity,
              decoration: const BoxDecoration(color: Colors.black),
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
          ],
          
          // Stats Row
          if (_likesCount > 0 || (widget.post['comments'] > 0)) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_likesCount > 0) ...[
                    const Icon(Icons.favorite, color: AppColors.primary, size: 14),
                    const SizedBox(width: 4),
                    Text('$_likesCount', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  ],
                  const Spacer(),
                  if (widget.post['comments'] != null && widget.post['comments'] > 0)
                    Text('${widget.post['comments']} comments', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ],
              ),
            ),
          ],
          
          // Action Divider
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: Colors.white.withOpacity(0.04)),
          
          // Action Row (LinkedIn/FB style wide buttons)
          Row(
            children: [
              _SocialActionButton(
                icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                label: 'Like',
                color: isLiked ? AppColors.primary : Colors.white.withOpacity(0.6),
                scale: isLiked ? _likeScale : null,
                onTap: _toggleLike,
              ),
              _SocialActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Comment',
                color: Colors.white.withOpacity(0.6),
                onTap: () => _openComments(context),
              ),
              _SocialActionButton(
                icon: Icons.share_rounded,
                label: 'Share',
                color: Colors.white.withOpacity(0.6),
                onTap: () {
                  FeedShareService.sharePost(context, FeedPostModel.fromMap(widget.post, widget.post['postId']));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: PostCommentsSheet(postCardData: widget.post)),
    );
  }
}

class _SocialActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Animation<double>? scale;

  const _SocialActionButton({required this.icon, required this.label, required this.color, required this.onTap, this.scale});

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Icon(icon, color: color, size: 20);
    if (scale != null) {
      iconWidget = ScaleTransition(scale: scale!, child: iconWidget);
    }
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconWidget,
                const SizedBox(width: 8),
                Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SkeletonPostCard extends StatelessWidget {
  const SkeletonPostCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkSurface,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 120, height: 12, color: Colors.white.withOpacity(0.05)),
                const SizedBox(height: 8),
                Container(width: 80, height: 10, color: Colors.white.withOpacity(0.05)),
              ],
            ),
          )
        ],
      ),
    );
  }
}