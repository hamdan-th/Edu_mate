import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/chat_message.dart';
import '../../../../../screens/library/file_details_screen.dart';
import '../../../../../screens/library/file_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
          alignment: isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isUser) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C0D11),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.primary),
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
                        color: isUser ? null : const Color(0xFF0C0D11),
                        gradient: isUser 
                             ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight) 
                             : null,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isUser ? 20 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 20),
                        ),
                        border: isUser 
                           ? null 
                           : Border.all(color: AppColors.primary.withOpacity(0.15), width: 1),
                        boxShadow: [
                          if (isUser)
                             BoxShadow(
                                color: AppColors.primary.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                             )
                          else
                             BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
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
                          if (message.suggestedFiles != null && message.suggestedFiles!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(Icons.library_books_rounded, size: 14, color: isUser ? Colors.white70 : AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'ملفات مقترحة من المكتبة:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isUser ? Colors.white70 : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...message.suggestedFiles!.map((file) => _buildMiniFileCard(context, file, isUser)),
                          ],
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
                                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      message.errorMessage ?? 'فشل الإرسال',
                                      style: const TextStyle(
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
                          Icon(Icons.copy_rounded, size: 13, color: AppColors.primary.withOpacity(0.7)),
                          const SizedBox(width: 6),
                          Text(
                            'نسخ الرد',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary.withOpacity(0.8),
                              fontWeight: FontWeight.w700,
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

  Widget _buildMiniFileCard(BuildContext context, Map<String, dynamic> fileMap, bool isUser) {
    final title = (fileMap['title'] ?? fileMap['subjectName'] ?? 'بدون عنوان').toString();
    final ext = (fileMap['fileType'] ?? 'pdf').toString().toLowerCase();
    final IconData icon = ext.contains('pdf') ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded;
    final Color iconColor = ext.contains('pdf') ? const Color(0xFFE57373) : const Color(0xFF64B5F6);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          // Construct dummy doc data so FileModel.fromFirestore can parse it if needed
          // Or we can just build FileModel cleanly.
          final fileModel = FileModel(
            id: fileMap['id']?.toString() ?? '',
            title: title,
            author: (fileMap['doctorName'] ?? fileMap['author'] ?? '').toString(),
            course: title,
            university: (fileMap['university'] ?? '').toString(),
            college: (fileMap['college'] ?? '').toString(),
            major: (fileMap['specialization'] ?? fileMap['major'] ?? '').toString(),
            semester: '',
            fileType: ext,
            thumbnailUrl: (fileMap['thumbnailUrl'] ?? '').toString(),
            fileUrl: (fileMap['fileUrl'] ?? '').toString(),
            uploaderName: (fileMap['uploaderName'] ?? '').toString(),
            uploaderUsername: (fileMap['uploaderUsername'] ?? '').toString(),
            description: (fileMap['description'] ?? '').toString(),
            createdAt: fileMap['createdAt'] is int ? DateTime.fromMillisecondsSinceEpoch(fileMap['createdAt']) : DateTime.now(),
            likes: fileMap['likesCount'] ?? 0,
            saves: fileMap['savesCount'] ?? 0,
            downloads: fileMap['downloadsCount'] ?? 0,
            views: fileMap['viewsCount'] ?? 0,
            shares: fileMap['sharesCount'] ?? 0,
            status: 'approved',
            userId: (fileMap['userId'] ?? '').toString(),
            storagePath: (fileMap['storagePath'] ?? '').toString(),
          );

          Navigator.push(context, MaterialPageRoute(
             builder: (_) => FileDetailsScreen(file: fileModel),
          ));
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUser ? Colors.white.withOpacity(0.1) : AppColors.background,
            border: Border.all(color: isUser ? Colors.white24 : AppColors.border.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isUser ? Colors.white24 : iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: isUser ? Colors.white : iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: isUser ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'اضغط للفتح المباشر',
                      style: TextStyle(
                        fontSize: 11,
                        color: isUser ? Colors.white70 : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isUser ? Colors.white54 : AppColors.textSecondary.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
