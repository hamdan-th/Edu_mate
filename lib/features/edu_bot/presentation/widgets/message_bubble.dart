import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;

  const MessageBubble({
    super.key,
    required this.message,
    this.onRetry,
  });

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('تم نسخ الرد بنجاح', style: TextStyle(fontFamily: 'Cairo')),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    final isFailed = message.status == MessageStatus.failed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
             offset: Offset(0, 10 * (1 - value)),
             child: Opacity(opacity: value, child: child),
          );
        },
        child: Align(
          alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isUser) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.blueGlow],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isUser ? 4 : 20),
                          bottomRight: Radius.circular(isUser ? 20 : 4),
                        ),
                        border: isUser 
                           ? null 
                           : Border.all(color: AppColors.border.withOpacity(0.4)),
                        boxShadow: [
                          if (isUser)
                             BoxShadow(
                                color: AppColors.primary.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                             )
                          else
                             BoxShadow(
                                color: AppColors.textPrimary.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                             ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SelectableText(
                            message.text,
                            style: TextStyle(
                              color: isUser ? Colors.white : AppColors.textPrimary,
                              height: 1.6,
                              fontSize: 15,
                              fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
                            ),
                          ),
                          if (isFailed) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.error.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      message.errorMessage ?? 'فشل الإرسال',
                                      style: TextStyle(
                                        color: AppColors.error,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (onRetry != null && isUser) ...[
                                    const SizedBox(width: 14),
                                    InkWell(
                                      onTap: onRetry,
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'إعادة',
                                          style: TextStyle(
                                            color: AppColors.error,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          if (message.status == MessageStatus.sending) ...[
                             const SizedBox(height: 10),
                             const Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                                  ),
                                  SizedBox(width: 8),
                                  Text("جاري الإرسال...", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                               ]
                             )
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (!isUser && !isFailed) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(right: 56),
                  child: InkWell(
                    onTap: () => _copyToClipboard(context, message.text),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy_rounded, size: 13, color: AppColors.textSecondary.withOpacity(0.6)),
                          const SizedBox(width: 6),
                          Text(
                            'نسخ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
