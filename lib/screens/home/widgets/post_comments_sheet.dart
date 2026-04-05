import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/feed_comment_model.dart';
import '../../../models/feed_comment_reply_model.dart';
import '../../../services/feed_comments_service.dart';
import '../../../services/feed_comment_reactions_service.dart';

class PostCommentsSheet extends StatefulWidget {
  final Map<String, dynamic> postCardData;

  const PostCommentsSheet({
    super.key,
    required this.postCardData,
  });

  @override
  State<PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<PostCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;
  FeedCommentModel? _replyingTo;

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

    setState(() {
      _isSending = true;
    });

    _unfocus();

    try {
      if (_replyingTo != null) {
        await FeedCommentsService.addReply(
          postId: postId,
          commentId: _replyingTo!.commentId,
          text: text,
        );
      } else {
        await FeedCommentsService.addComment(postId: postId, text: text);
      }
      
      if (mounted) {
        _commentController.clear();
        setState(() {
          _replyingTo = null;
        });
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

  @override
  Widget build(BuildContext context) {
    final postId = widget.postCardData['postId']?.toString() ?? '';
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag handle and header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'التعليقات',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: GestureDetector(
              onTap: _unfocus,
              child: StreamBuilder<List<FeedCommentModel>>(
                stream: FeedCommentsService.streamComments(postId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'تعذر تحميل التعليقات',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  final comments = snapshot.data ?? [];

                  if (comments.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 48, color: AppColors.border),
                          SizedBox(height: 16),
                          Text(
                            'لا توجد تعليقات بعد\nكُن أول من يعلق!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    reverse: true, // Show newest at bottom naturally like social apps
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return _CommentItem(
                        postId: postId,
                        comment: comment,
                        onReplyTap: () {
                          setState(() {
                            _replyingTo = comment;
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // Input field area
          Container(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + keyboardHeight),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(
                top: BorderSide(color: AppColors.border),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_replyingTo != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الرد على ${_replyingTo!.authorName}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _replyingTo = null;
                            });
                          },
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: TextField(
                            controller: _commentController,
                            maxLines: 5,
                            minLines: 1,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: _replyingTo != null
                                  ? 'اكتب ردك هنا...'
                                  : 'إضافة تعليق...',
                              hintStyle: const TextStyle(
                                  color: AppColors.textSecondary),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _isSending ? null : _sendComment,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
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
                                    size: 18,
                                  ),
                          ),
                        ),
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

class _CommentItem extends StatefulWidget {
  final String postId;
  final FeedCommentModel comment;
  final VoidCallback? onReplyTap;

  const _CommentItem({
    required this.postId,
    required this.comment,
    this.onReplyTap,
  });

  @override
  State<_CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<_CommentItem> {
  bool _isLiked = false;
  int _likesCount = 0;
  bool _isLoadingLike = false;
  bool _isSelf = false;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.comment.likesCount;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _isSelf = currentUserId == widget.comment.authorId;
    _checkLikeStatus();
  }

  Future<void> _checkLikeStatus() async {
    final liked = await FeedCommentReactionsService.hasUserLikedComment(
      postId: widget.postId,
      commentId: widget.comment.commentId,
    );
    if (mounted) {
      setState(() {
        _isLiked = liked;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_isLoadingLike) return;

    final oldLiked = _isLiked;
    setState(() {
      _isLoadingLike = true;
      _isLiked = !oldLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    try {
      await FeedCommentReactionsService.toggleCommentLike(
        postId: widget.postId,
        commentId: widget.comment.commentId,
        isCurrentlyLiked: oldLiked,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = oldLiked;
          _likesCount += oldLiked ? 1 : -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تحديث الإعجاب')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLike = false);
      }
    }
  }

  void _showReportDialog() {
    bool isReporting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('الإبلاغ عن تعليق', style: TextStyle(color: AppColors.textPrimary)),
              content: const Text(
                'هل أنت متأكد من رغبتك في الإبلاغ عن هذا التعليق كمرجع للمراجعة؟',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: isReporting ? null : () => Navigator.pop(ctx),
                  child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
                ),
                TextButton(
                  onPressed: isReporting
                      ? null
                      : () async {
                          setDialogState(() => isReporting = true);
                          try {
                            await FeedCommentReactionsService.reportComment(
                              postId: widget.postId,
                              commentId: widget.comment.commentId,
                              reportedCommentAuthorId: widget.comment.authorId,
                              commentText: widget.comment.text,
                            );
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال البلاغ بنجاح')));
                            }
                          } catch (e) {
                            if (mounted) {
                              setDialogState(() => isReporting = false);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الإرسال')));
                            }
                          }
                        },
                  child: isReporting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('إرسال', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.comment.authorName,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _formatTime(widget.comment.createdAt?.toDate()),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!_isSelf) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTapDown: (details) {
                            showMenu(
                              context: context,
                              color: AppColors.surface,
                              position: RelativeRect.fromLTRB(
                                details.globalPosition.dx,
                                details.globalPosition.dy,
                                details.globalPosition.dx,
                                details.globalPosition.dy,
                              ),
                              items: [
                                const PopupMenuItem(
                                  value: 'report',
                                  child: Text('إبلاغ', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ).then((value) {
                              if (value == 'report') {
                                _showReportDialog();
                              }
                            });
                          },
                          child: const Icon(Icons.more_horiz_rounded, size: 16, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.comment.text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: _toggleLike,
                    child: Row(
                      children: [
                        Icon(
                          _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 16,
                          color: _isLiked ? Colors.red : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_likesCount',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: widget.onReplyTap,
                    child: const Text(
                      'رد',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Replies StreamBuilder
        Padding(
          padding: const EdgeInsets.only(right: 24.0, bottom: 12.0),
          child: StreamBuilder<List<FeedCommentReplyModel>>(
            stream: FeedCommentsService.streamReplies(
              postId: widget.postId,
              commentId: widget.comment.commentId,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final replies = snapshot.data!;
              if (replies.isEmpty) return const SizedBox.shrink();

              return Column(
                children: replies.map((reply) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              reply.authorName,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatTime(reply.createdAt?.toDate()),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reply.text,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
