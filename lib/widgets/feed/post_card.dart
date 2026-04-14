import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/premium_feedback.dart';
import '../../l10n/app_localizations.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool isLiked;
  final bool isJoined;
  final bool isLoadingJoined;
  final int likesCount;
  final int commentsCount;
  
  // Callbacks
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onJoinGroup;
  final VoidCallback onGroupTap;
  final VoidCallback onAuthorTap;
  final VoidCallback onMoreMenu;

  const PostCard({
    super.key,
    required this.post,
    required this.isLiked,
    required this.isJoined,
    this.isLoadingJoined = false,
    required this.likesCount,
    required this.commentsCount,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onJoinGroup,
    required this.onGroupTap,
    required this.onAuthorTap,
    required this.onMoreMenu,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late final AnimationController _likeController;
  late final Animation<double> _likeScale;
  bool _isPressed = false;

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

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked && !oldWidget.isLiked) {
      _likeController.forward().then((_) => _likeController.reverse());
    }
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
    final imageUrl = (widget.post['contentImageUrl'] ?? widget.post['imageUrl'] ?? '').toString();

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _isPressed ? 0.988 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.border.withOpacity(0.50) : AppColors.border.withOpacity(0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  _isPressed ? (isDark ? 0.20 : 0.08) : (isDark ? 0.12 : 0.05),
                ),
                blurRadius: _isPressed ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context, isDark, l10n),
              const SizedBox(height: 12),
              
              // Content Text
              if ((widget.post['contentText'] ?? widget.post['content'] ?? '').toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    (widget.post['contentText'] ?? widget.post['content'] ?? '').toString(),
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: isDark ? AppColors.textPrimary : const Color(0xFF1F2937),
                    ),
                  ),
                ),

              // Content Image
              if (imageUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) => progress == null
                          ? child
                          : Container(
                              height: 200,
                              color: isDark ? AppColors.border.withOpacity(0.1) : Colors.black12,
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                    ),
                  ),
                ),

              const Divider(height: 24, thickness: 0.5),

              // Actions
              _buildActions(context, isDark, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, AppLocalizations l10n) {
    final groupImg = (widget.post['groupImageUrl'] ?? '').toString();
    final authorName = (widget.post['authorName'] ?? '').toString();
    final groupName = (widget.post['groupName'] ?? '').toString();
    
    // Format timestamp
    String timeStr = '';
    final ts = widget.post['createdAt'];
    if (ts is Timestamp) {
      final date = ts.toDate();
      timeStr = '${date.day}/${date.month}';
    } else {
      timeStr = widget.post['time'] ?? '';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: widget.onGroupTap,
          child: groupImg.isNotEmpty
              ? CircleAvatar(
                  radius: 23,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  backgroundImage: NetworkImage(groupImg),
                )
              : Container(
                  width: 46, height: 46,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: widget.onAuthorTap,
                child: Text(
                  authorName,
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimary : AppColors.textOnLight,
                    fontSize: 14.5,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: GestureDetector(
                      onTap: widget.onGroupTap,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.groups_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              groupName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.circle, size: 3, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                  const SizedBox(width: 6),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: isDark 
                          ? AppColors.textSecondary.withOpacity(0.7)
                          : AppColors.lightTextSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!widget.isJoined)
          TextButton(
            onPressed: widget.isLoadingJoined ? null : widget.onJoinGroup,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              minimumSize: const Size(0, 32),
            ),
            child: widget.isLoadingJoined
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : Text(l10n.feedJoinAction, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        IconButton(
          onPressed: widget.onMoreMenu,
          icon: Icon(Icons.more_horiz, color: isDark ? AppColors.textSecondary : Colors.black45, size: 20),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, bool isDark, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _ActionItem(
          icon: widget.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          label: widget.likesCount.toString(),
          color: widget.isLiked ? AppColors.error : (isDark ? AppColors.textSecondary : Colors.black87),
          onTap: widget.onLike,
          scale: widget.isLiked ? _likeScale : null,
        ),
        _ActionItem(
          icon: Icons.chat_bubble_outline_rounded,
          label: widget.commentsCount.toString(),
          color: isDark ? AppColors.textSecondary : Colors.black87,
          onTap: widget.onComment,
        ),
        _ActionItem(
          icon: Icons.share_rounded,
          label: l10n.shareAction,
          color: isDark ? AppColors.textSecondary : Colors.black87,
          onTap: widget.onShare,
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Animation<double>? scale;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.scale,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Icon(icon, color: color, size: 22);
    if (scale != null) {
      iconWidget = ScaleTransition(scale: scale!, child: iconWidget);
    }

    return ScaleOnPress(
      onTap: onTap,
      scale: 0.95,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            iconWidget,
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
