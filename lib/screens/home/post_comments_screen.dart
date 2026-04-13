import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/feed_comment_model.dart';
import '../../services/feed_comments_service.dart';
import 'package:provider/provider.dart';
import '../../core/providers/guest_provider.dart';
import '../../widgets/guest_action_dialog.dart';

class PostCommentsScreen extends StatefulWidget {
  final Map<String, dynamic> postCardData;

  const PostCommentsScreen({
    super.key,
    required this.postCardData,
  });

  @override
  State<PostCommentsScreen> createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends State<PostCommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _unfocus() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    final postId = widget.postCardData['postId']?.toString() ?? '';

    if (text.isEmpty || postId.isEmpty || _isSending) return;

    // 🚫 Guest cannot comment
    if (context.read<GuestProvider>().isGuest) {
      GuestActionDialog.show(
        context,
        title: 'تسجيل الدخول مطلوب',
        subtitle: 'التصفح متاح كضيف، لكن التعليق يحتاج إلى تسجيل الدخول.',
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    _unfocus();

    try {
      await FeedCommentsService.addComment(postId: postId, text: text);
      if (mounted) {
        _commentController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر إضافة التعليق')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';

    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final postId = widget.postCardData['postId']?.toString() ?? '';

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.background : const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        centerTitle: false,
        title: const Text(
          'التعليقات',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _unfocus,
              child: StreamBuilder<List<FeedCommentModel>>(
                stream: FeedCommentsService.streamComments(postId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'تعذر تحميل التعليقات',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondary
                              : Colors.black54,
                        ),
                      ),
                    );
                  }

                  final comments = snapshot.data ?? [];

                  if (comments.isEmpty) {
                    return const _CommentsEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    reverse: true,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];

                      return _CommentCard(
                        comment: comment,
                        timeLabel: _formatTime(comment.createdAt?.toDate()),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.border.withOpacity(0.55)
                : Colors.black12,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.10 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 42,
              height: 42,
              margin: const EdgeInsetsDirectional.only(end: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.background
                      : const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? AppColors.border.withOpacity(0.55)
                        : Colors.black12,
                  ),
                ),
                child: TextField(
                  controller: _commentController,
                  maxLines: 5,
                  minLines: 1,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textPrimary
                        : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'أضف تعليقًا مفيدًا...',
                    hintStyle: TextStyle(
                      color: isDark
                          ? AppColors.textSecondary
                          : Colors.black45,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSending ? null : _sendComment,
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isSending
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final FeedCommentModel comment;
  final String timeLabel;

  const _CommentCard({
    required this.comment,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? AppColors.border.withOpacity(0.50)
                      : Colors.black12,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.10 : 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          comment.authorName,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeLabel,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondary
                              : Colors.black45,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    comment.text,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textPrimary
                          : Colors.black87,
                      fontSize: 13.8,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _MiniActionChip(
                        icon: Icons.reply_rounded,
                        label: 'رد',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _MiniActionChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.background.withOpacity(0.7)
            : const Color(0xFFF6F7FA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark
              ? AppColors.border.withOpacity(0.5)
              : Colors.black12,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? AppColors.textSecondary : Colors.black54,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.textSecondary : Colors.black54,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentsEmptyState extends StatelessWidget {
  const _CommentsEmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.border : Colors.black12,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.14 : 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.primary.withOpacity(0.10),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد تعليقات بعد',
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ابدأ أول تعليق وشارك رأيك أو ملاحظتك بشكل مفيد وواضح.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppColors.textSecondary : Colors.black54,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}