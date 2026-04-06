import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
import '../notifications/notifications_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String _selectedFilter = 'For You';
  final List<String> _filters = const ['For You', 'Academic', 'Popular', 'Recent'];

  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
    return FeedService.streamPublicFeed(filter: _selectedFilter, searchQuery: _searchQuery);
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    children: [
                      if (!_isSearching)
                        const Text(
                          'Edu Mate',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      if (_isSearching)
                        Expanded(
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              autofocus: true,
                              decoration: const InputDecoration(
                                hintText: 'Search...',
                                hintStyle: TextStyle(color: Colors.white54),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                      if (!_isSearching) const Spacer(),
                      const SizedBox(width: 12),
                      _HeaderAction(
                        icon: _isSearching ? Icons.close_rounded : Icons.search_rounded, 
                        onTap: () {
                          setState(() {
                            if (_isSearching) _searchController.clear();
                            _isSearching = !_isSearching;
                          });
                        }
                      ),
                      const SizedBox(width: 12),
                      _HeaderAction(
                        icon: Icons.notifications_none_rounded, 
                        hasBadge: true, 
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPlaceholderScreen()));
                        }
                      ),
                      const SizedBox(width: 12),
                      
                      // Authenticated User Avatar
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseAuth.instance.currentUser != null 
                          ? FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots()
                          : const Stream.empty(),
                        builder: (context, snapshot) {
                          final authUser = FirebaseAuth.instance.currentUser;
                          String? finalPhotoUrl = authUser?.photoURL;
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data = snapshot.data!.data() as Map<String, dynamic>?;
                            if (data != null && data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty) {
                              finalPhotoUrl = data['photoUrl'];
                            }
                          }

                          return GestureDetector(
                            onTap: _openProfile,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 1.5),
                                color: AppColors.primary.withOpacity(0.1),
                              ),
                              child: ClipOval(
                                child: (finalPhotoUrl != null && finalPhotoUrl.isNotEmpty)
                                    ? Image.network(
                                        finalPhotoUrl, 
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            authUser?.displayName?.isNotEmpty == true ? authUser!.displayName![0].toUpperCase() : 'U',
                                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          authUser?.displayName?.isNotEmpty == true ? authUser!.displayName![0].toUpperCase() : 'U',
                                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16),
                                        ),
                                      ),
                              ),
                            ),
                          );
                        }
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
                          separatorBuilder: (_, __) => const SizedBox(height: 4), // social divider
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
          _DraggableBotWrapper(onOpenBot: _openBot),
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
            decoration: const BoxDecoration(
              color: AppColors.darkSurface,
              shape: BoxShape.circle,
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
  bool _isJoining = false;
  bool _isLiking = false;

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

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post['likes'] != widget.post['likes']) {
      _likesCount = widget.post['likes'] as int? ?? 0;
    }
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
    if (_isLiking) return;
    final postId = widget.post['postId']?.toString() ?? '';
    if (postId.isEmpty) return;
    
    _isLiking = true;
    final oldIsLiked = isLiked;
    setState(() {
      isLiked = !isLiked;
      _likesCount += isLiked ? 1 : -1;
      if (_likesCount < 0) _likesCount = 0;
    });

    _likeController.forward().then((_) => _likeController.reverse());
    try {
      await FeedReactionsService.toggleLike(postId: postId, isCurrentlyLiked: oldIsLiked);
    } catch (_) {
      if (mounted) {
        setState(() { 
          isLiked = oldIsLiked; 
          _likesCount += oldIsLiked ? 1 : -1; 
          if (_likesCount < 0) _likesCount = 0;
        });
      }
    } finally {
      if (mounted) {
        _isLiking = false;
      }
    }
  }

  Future<void> _joinGroup() async {
    if (_isJoined || _isJoining) return;
    final groupId = widget.post['groupId']?.toString() ?? '';
    if (groupId.isEmpty) return;
    
    setState(() => _isJoining = true);
    try {
      await GroupService.joinPublicGroup(groupId);
      if (mounted) setState(() { _isJoined = true; _isJoining = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isJoining = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to join group')));
      }
    }
  }

  @override
  void dispose() { _likeController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final imageUrl = (widget.post['imageUrl'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkSurface, // Flat premium social card feel
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), spreadRadius: 0, blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.only(top: 20, bottom: 8),
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
                    color: Color(0xFF1E1E22),
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
                      Text(
                        widget.post['groupName'] ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(widget.post['authorName'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(' • ${widget.post['time']}', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                          const SizedBox(width: 4),
                          Icon(Icons.public, color: Colors.white.withOpacity(0.3), size: 11),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _joinGroup,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isJoined ? Colors.white.withOpacity(0.05) : AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _isJoined ? Colors.white.withOpacity(0.1) : AppColors.primary.withOpacity(0.8), width: 1),
                    ),
                    child: _isJoining
                      ? const SizedBox(
                          width: 12, height: 12, 
                          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)
                        )
                      : Text(
                          _isJoined ? 'Joined' : 'Join',
                          style: TextStyle(
                            color: _isJoined ? Colors.white.withOpacity(0.5) : AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          )
                        )
                  )
                ),
                const SizedBox(width: 12),
                if (FirebaseAuth.instance.currentUser?.uid == widget.post['authorId'])
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz_rounded, color: Colors.white.withOpacity(0.6), size: 20),
                    color: AppColors.darkSurface,
                    offset: const Offset(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) {
                      if (value == 'edit') _editPost();
                      if (value == 'delete') _deletePost();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
                    ],
                  )
                else
                  const SizedBox(width: 20),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Post Text Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.post['content'] ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5, letterSpacing: 0.1),
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
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: AppColors.primary, size: 14),
                const SizedBox(width: 4),
                Text('$_likesCount', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                const Spacer(),
                Text('${widget.post['comments'] ?? 0} comments', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
          
          // Action Divider
          const SizedBox(height: 16),
          Divider(height: 1, thickness: 1, color: Colors.white.withOpacity(0.03)),
          
          // Action Row
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

  Future<void> _deletePost() async {
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Post', style: TextStyle(color: Colors.white)),
      content: const Text('Are you sure you want to delete this post?', style: TextStyle(color: Colors.white70)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
      ],
    ));
    if (confirm != true) return;
    try {
      await FirebaseFirestore.instance.collection('posts').doc(widget.post['postId']).delete();
    } catch (_) {}
  }

  Future<void> _editPost() async {
    final TextEditingController ctrl = TextEditingController(text: widget.post['content']);
    final newContent = await showDialog<String>(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Edit Post', style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        maxLines: 5,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
        ),
      ),
      actions: [
         TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
         TextButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
      ],
    ));
    if (newContent != null && newContent.trim().isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('posts').doc(widget.post['postId']).update({'contentText': newContent.trim()});
      } catch (_) {}
    }
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
    Widget iconWidget = Icon(icon, color: color, size: 22);
    if (scale != null) {
      iconWidget = ScaleTransition(scale: scale!, child: iconWidget);
    }
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.primary.withOpacity(0.1),
          highlightColor: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconWidget,
                const SizedBox(width: 10),
                Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
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

class _DraggableBotWrapper extends StatefulWidget {
  final VoidCallback onOpenBot;
  const _DraggableBotWrapper({required this.onOpenBot});
  @override
  State<_DraggableBotWrapper> createState() => _DraggableBotWrapperState();
}

class _DraggableBotWrapperState extends State<_DraggableBotWrapper> {
  double _botX = -1;
  double _botY = -1;

  void _onBotPanUpdate(DragUpdateDetails details) {
    setState(() {
      _botX += details.delta.dx;
      _botY += details.delta.dy;
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      _botX = _botX.clamp(8.0, screenWidth - 76.0);
      _botY = _botY.clamp(100.0, screenHeight - 160.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_botX == -1) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      _botX = screenWidth - 76;
      _botY = screenHeight - 240;
    }
    return Positioned(
      left: _botX,
      top: _botY,
      child: GestureDetector(
        onPanUpdate: _onBotPanUpdate,
        child: AnimatedBotButton(onTap: widget.onOpenBot),
      ),
    );
  }
}