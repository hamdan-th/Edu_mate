import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({
    super.key,
    required this.message,
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
      padding: const EdgeInsets.only(bottom: 20),
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
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isUser ? 4 : 20),
                        bottomRight: Radius.circular(isUser ? 20 : 4),
                      ),
                      border: isUser ? null : Border.all(
                        color: isFailed ? AppColors.error.withOpacity(0.5) : AppColors.border.withOpacity(0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isUser ? AppColors.primary : AppColors.textPrimary).withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
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
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isFailed) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline_rounded, color: isUser ? Colors.white70 : AppColors.error, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'فشل الإرسال: ${message.errorMessage ?? "خطأ غير معروف"}',
                                style: TextStyle(
                                  color: isUser ? Colors.white70 : AppColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (message.status == MessageStatus.sending) ...[
                           const SizedBox(height: 8),
                           const SizedBox(
                             width: 12,
                             height: 12,
                             child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                           ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (!isUser) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(right: 48),
                child: InkWell(
                  onTap: () => _copyToClipboard(context, message.text),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded, size: 14, color: AppColors.textSecondary.withOpacity(0.7)),
                        const SizedBox(width: 6),
                        Text(
                          'نسخ التوضيح',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
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
    );
  }
}
