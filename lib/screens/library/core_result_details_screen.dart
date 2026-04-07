import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'digital_library_firestore_service.dart';
import 'library_theme.dart';

class CoreResultDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;
  final bool isSaved;
  final VoidCallback onToggleSave;

  const CoreResultDetailsScreen({
    Key? key,
    required this.resultData,
    required this.isSaved,
    required this.onToggleSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = resultData['title'] ?? 'بدون عنوان';
    final authors = (resultData['authors'] as List<dynamic>?)
        ?.map((author) => author['name'].toString())
        .join(', ') ??
        'مؤلف غير معروف';
    final abstract = resultData['abstract'] ?? 'لا يوجد ملخص متاح.';
    final publisher = resultData['publisher'] ?? 'غير معروف';
    final year = resultData['yearPublished']?.toString() ?? 'غير معروف';
    final journal = resultData['journals'] != null && (resultData['journals'] as List).isNotEmpty
        ? (resultData['journals'] as List).first.toString()
        : 'غير معروف';

    return Scaffold(
      backgroundColor: LibraryTheme.bg,
      appBar: AppBar(
        title: const Text('تفاصيل الورقة البحثية'),
        backgroundColor: LibraryTheme.surface,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 📄 Card: Basic Info
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.person, 'المؤلفون', authors),
                    const Divider(height: 24),
                    _buildInfoRow(Icons.business, 'الناشر', publisher),
                    const Divider(height: 24),
                    _buildInfoRow(Icons.book, 'المجلة', journal),
                    const Divider(height: 24),
                    _buildInfoRow(Icons.calendar_today, 'سنة النشر', year),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            /// 📝 Card: Abstract
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notes, color: LibraryTheme.primary),
                        SizedBox(width: 8),
                        Text(
                          'الملخص',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      abstract,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            /// 🔘 Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      onToggleSave(); // Update state in parent UI
                      if (!isSaved) {
                        DigitalLibraryFirestoreService.saveReference(resultData);
                      } else {
                        // TODO: Implement removal from Firestore if needed
                      }
                    },
                    icon: Icon(
                      isSaved ? Icons.bookmark_added : Icons.bookmark_add_outlined,
                      color: isSaved ? Colors.white : LibraryTheme.primary,
                    ),
                    label: Text(
                      isSaved ? 'تم الحفظ' : 'حفظ كمرجع',
                      style: TextStyle(
                        color: isSaved ? Colors.white : LibraryTheme.primary,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSaved ? LibraryTheme.primary : Colors.white,
                      side: BorderSide(color: LibraryTheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final url = resultData['downloadUrl'] as String?;
                      final String? articleId = resultData['id']?.toString();
                      final sourceUrl = articleId != null
                          ? 'https://core.ac.uk/display/$articleId'
                          : null;

                      final targetUrl = (url != null && url.isNotEmpty)
                          ? url
                          : sourceUrl;

                      if (targetUrl != null && targetUrl.isNotEmpty) {
                        final uri = Uri.parse(targetUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                          DigitalLibraryFirestoreService.registerDownload(resultData);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('لا يمكن فتح الرابط')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('لا يتوفر رابط لهذه الورقة')),
                        );
                      }
                    },
                    icon: const Icon(Icons.open_in_new, color: Colors.white),
                    label: const Text(
                      'فتح المصدر',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LibraryTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  final String? articleId = resultData['id']?.toString();
                  if (articleId != null) {
                    final String url = 'https://core.ac.uk/display/$articleId';
                    await Share.share('اطلع على هذه الورقة البحثية:\n$title\n$url');
                  }
                },
                icon: const Icon(Icons.share, color: LibraryTheme.primary),
                label: const Text(
                  'مشاركة رابط الورقة',
                  style: TextStyle(color: LibraryTheme.primary, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: LibraryTheme.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: LibraryTheme.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isNotEmpty ? value : 'غير متوفر',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
