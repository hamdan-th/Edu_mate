import 'package:copy_with_extension/copy_with_extension.dart'; // Ignore unused warning, keeping typical imports
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/feed_post_model.dart';
import 'package:flutter/material.dart';

class FeedShareService {
  /// Generates a clean text payload and triggers the native share sheet
  static Future<void> sharePost(BuildContext context, FeedPostModel post) async {
    try {
      final buffer = StringBuffer();
      
      buffer.writeln('منشور جديد في مجموعة "${post.groupName}" شاركه ${post.authorName}:');
      buffer.writeln();
      
      if (post.contentText.trim().isNotEmpty) {
        buffer.writeln('"${post.contentText.trim()}"');
      }
      
      if (post.contentImageUrl.trim().isNotEmpty) {
        buffer.writeln('\n[يحتوي على صورة]');
      }
      
      buffer.writeln();
      buffer.writeln('تطبيق Edu Mate - تواصل، تعلم، شارك');

      final sharePayload = buffer.toString();

      // Trigger the native OS share dialog
      await Share.share(sharePayload, subject: 'مشاركة من Edu Mate');
    } catch (e) {
      // Safe Fallback if share_plus fails on an unsupported platform
      try {
        final buffer = StringBuffer();
        buffer.writeln('منشور جديد في مجموعة "${post.groupName}":');
        if (post.contentText.trim().isNotEmpty) {
          buffer.writeln('"${post.contentText.trim()}"');
        }
        await Clipboard.setData(ClipboardData(text: buffer.toString()));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم نسخ النص إلى الحافظة!')),
          );
        }
      } catch (_) {}
    }
  }
}
