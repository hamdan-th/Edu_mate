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
    super.key,
    required this.resultData,
    required this.isSaved,
    required this.onToggleSave,
  });

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
      backgroundColor: LibraryTheme.bg(context),
      appBar: AppBar(
        title: const Text('تفاصيل البحث'),
        backgroundColor: LibraryTheme.surface(context),
        foregroundColor: LibraryTheme.text(context),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: LibraryTheme.text(context),
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(context, Icons.people_alt_outlined, 'المؤلفون:', authors),
            const SizedBox(height: 8),
            _buildInfoRow(context, Icons.business_rounded, 'الناشر:', publisher.toString()),
            const SizedBox(height: 8),
            _buildInfoRow(context, Icons.calendar_today_rounded, 'سنة النشر:', year),
            const SizedBox(height: 8),
            _buildInfoRow(context, Icons.menu_book_rounded, 'المجلة:', journal),
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
                            SnackBar(content: Text('تعذر حفظ المرجع: $e')),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('مشاركة'),
                    onPressed: () async {
                      if (articleUrl.isEmpty) return;
                      await Share.share(
                        'اطلع على هذه الورقة البحثية:\n$title\n$articleUrl',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LibraryTheme.primary(context),
                      foregroundColor: LibraryTheme.surface(context),
                    ),
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
                  label: const Text('تنزيل PDF'),
                  onPressed: () async {
                    try {
                      await DigitalLibraryFirestoreService.registerDownload(
                        resultData,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تعذر تسجيل التنزيل: $e')),
                        );
                      }
                    }

                    final Uri? url = Uri.tryParse(downloadableLink);
                    if (url != null) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LibraryTheme.primary(context),
                    foregroundColor: LibraryTheme.surface(context),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

            if (articleUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_browser_rounded),
                  label: const Text('فتح المصدر'),
                  onPressed: () async {
                    final Uri url = Uri.parse(articleUrl);
                    await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LibraryTheme.primary(context),
                    side: const BorderSide(color: LibraryTheme.primary(context)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],

            const Divider(height: 30, thickness: 1),
            Text(
              'الملخص (Abstract)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: LibraryTheme.text(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              abstract.toString().trim().isEmpty
                  ? 'لا يوجد ملخص متاح.'
                  : abstract.toString(),
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: LibraryTheme.text(context).withOpacity(0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: LibraryTheme.primary(context), size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: LibraryTheme.text(context),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value.isEmpty ? 'غير معروف' : value,
            style: TextStyle(
              fontSize: 16,
              color: LibraryTheme.text(context),
            ),
          ),
        ),
      ],
    );
  }
}