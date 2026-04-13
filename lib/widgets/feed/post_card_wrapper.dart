import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'post_card.dart';
import '../../models/feed_post_model.dart';
import '../../services/feed_service.dart';
import '../../services/feed_reactions_service.dart';
import '../../services/feed_share_service.dart';
import '../../services/group_service.dart';
import '../../core/providers/guest_provider.dart';
import '../../widgets/guest_action_dialog.dart';
import '../../screens/home/widgets/post_comments_sheet.dart';
import '../../screens/groups/group_chat_screen.dart';
import '../../screens/groups/group_details_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../models/group_model.dart';

class PostCardWrapper extends StatefulWidget {
  final Map<String, dynamic> post;
  
  const PostCardWrapper({
    super.key,
    required this.post,
  });

  @override
  State<PostCardWrapper> createState() => _PostCardWrapperState();
}

class _PostCardWrapperState extends State<PostCardWrapper> {
  bool _isLiked = false;
  bool _isJoined = false;
  bool _isLoadingJoined = true;
  bool _isLoadingLike = false;
  late int _likesCount;
  late int _commentsCount;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post['likes'] as int? ?? widget.post['likesCount'] as int? ?? 0;
    _commentsCount = widget.post['comments'] as int? ?? widget.post['commentsCount'] as int? ?? 0;
    _checkMembership();
    _checkLikeStatus();
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
          _isLiked = liked;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_isLoadingLike) return;

    if (context.read<GuestProvider>().isGuest) {
      GuestActionDialog.show(context);
      return;
    }

    final postId = widget.post['postId']?.toString() ?? '';
    if (postId.isEmpty) return;

    final oldIsLiked = _isLiked;

    setState(() {
      _isLoadingLike = true;
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    try {
      await FeedReactionsService.toggleLike(
        postId: postId,
        isCurrentlyLiked: oldIsLiked,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = oldIsLiked;
          _likesCount += oldIsLiked ? 1 : -1;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLike = false;
        });
      }
    }
  }

  Future<void> _joinGroup() async {
    if (_isLoadingJoined || _isJoined) return;

    if (context.read<GuestProvider>().isGuest) {
      GuestActionDialog.show(context);
      return;
    }

    final groupId = widget.post['groupId']?.toString() ?? '';
    if (groupId.isEmpty) return;

    setState(() => _isLoadingJoined = true);

    try {
      await GroupService.joinPublicGroup(groupId);
      if (mounted) {
        setState(() => _isJoined = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.feedJoinedGroup)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingJoined = false);
    }
  }

  void _handleComment() {
    if (context.read<GuestProvider>().isGuest) {
      GuestActionDialog.show(context);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: PostCommentsSheet(postCardData: widget.post),
      ),
    );
  }

  void _handleShare() {
    if (context.read<GuestProvider>().isGuest) {
      GuestActionDialog.show(context);
      return;
    }
    final feedPost = FeedPostModel.fromMap(
      widget.post,
      widget.post['postId']?.toString() ?? '',
    );
    FeedShareService.sharePost(context, feedPost);
  }

  void _handleGroupTap() async {
    final groupId = widget.post['groupId']?.toString() ?? '';
    if (groupId.isEmpty) return;

    // We can directly open the group profile now as per requirements
    // Wait, let's keep the logic consistent with what's expected for "restructuring"
    // Requirement says clicking group leads to profile
    try {
      final group = await GroupService.getGroupById(groupId);
      if (group != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupDetailsScreen(group: group),
          ),
        );
      }
    } catch (e) {}
  }

  void _handleMoreMenu() {
    final postId = widget.post['postId']?.toString() ?? '';
    final authorId = widget.post['authorId']?.toString() ?? '';
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isOwner = currentUid == authorId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            if (isOwner) ...[
              _buildMenuTile(Icons.edit_outlined, 'تعديل المنشور', () {
                Navigator.pop(context);
                // logic for edit
              }),
              _buildMenuTile(Icons.delete_outline_rounded, 'حذف المنشور', () async {
                Navigator.pop(context);
                // logic for delete
              }, color: AppColors.error),
            ] else
              _buildMenuTile(Icons.flag_outlined, 'إبلاغ عن المنشور', () async {
                Navigator.pop(context);
                // logic for report
              }, color: AppColors.error),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? (Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black87)),
      title: Text(label, style: TextStyle(color: color ?? (Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black87), fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PostCard(
      post: widget.post,
      isLiked: _isLiked,
      isJoined: _isJoined,
      isLoadingJoined: _isLoadingJoined,
      likesCount: _likesCount,
      commentsCount: _commentsCount,
      onLike: _toggleLike,
      onComment: _handleComment,
      onShare: _handleShare,
      onJoinGroup: _joinGroup,
      onGroupTap: _handleGroupTap,
      onAuthorTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())), // Simplified
      onMoreMenu: _handleMoreMenu,
    );
  }
}
