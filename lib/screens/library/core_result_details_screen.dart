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
    final year = resultData['yearPublished']?.toString() ?? 'غير معروف';
    final publisher = resultData['publisher'] ?? 'غير معروف';
    final journal = resultData['journals'] is List &&
            (resultData['journals'] as List).isNotEmpty
        ? (resultData['journals'] as List).first.toString()
        : 'غير معروف';
    final articleId = resultData['id']?.toString();
    final downloadableLink = resultData['downloadUrl']?.toString();

    final String articleUrl = (articleId != null && articleId.isNotEmpty)
        ? 'https://core.ac.uk/display/$articleId'
        : '';

    return Scaffold(
      backgroundColor: LibraryTheme.bg,
      appBar: AppBar(
        title: const Text('تفاصيل البحث'),
        backgroundColor: LibraryTheme.surface,
        foregroundColor: LibraryTheme.text,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: LibraryTheme.text,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.people_alt_outlined, 'المؤلفون:', authors),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.business_rounded, 'الناشر:', publisher.toString()),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today_rounded, 'سنة النشر:', year),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.menu_book_rounded, 'المجلة:', journal),
            const Divider(height: 30, thickness: 1),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(
                      isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                    ),
                    label: Text(isSaved ? 'محفوظ' : 'حفظ'),
                    onPressed: () async {
                      try {
                        if (!isSaved) {
                          await DigitalLibraryFirestoreService.saveReference(
                            resultData,
                          );
                        }
                        onToggleSave();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isSaved
                                    ? 'تمت الإزالة من الحفظ داخل الواجهة'
                                    : 'تم حفظ المرجع في مكتبتي',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تعذر الحفظ: $e')),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('مشاركة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LibraryTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      try {
                        await DigitalLibraryFirestoreService.registerShare(
                          resultData,
                        );
                      } catch (_) {}
                      final shareText =
                          'اطلع على هذه الورقة البحثية:\n$title\n$articleUrl';
                      await Share.share(shareText);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (downloadableLink != null && downloadableLink.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('فتح / تنزيل'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LibraryTheme.success,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    try {
                      await DigitalLibraryFirestoreService.registerDownload(
                        resultData,
                      );
                    } catch (_) {}

                    final uri = Uri.parse(downloadableLink);
                    final launched = await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                    if (!launched && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تعذر فتح الرابط')),
                      );
                    }
                  },
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'الملخص',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LibraryTheme.text,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LibraryTheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: LibraryTheme.border),
              ),
              child: Text(
                abstract.toString(),
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.7,
                  color: LibraryTheme.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: LibraryTheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: LibraryTheme.text,
                fontSize: 14,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: '$label ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
