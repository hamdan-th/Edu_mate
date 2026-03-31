import 'package:flutter/material.dart';
import 'library_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class CoreResultDetailsScreen extends StatelessWidget {
  // هذه الشاشة ستستقبل بيانات النتيجة من الشاشة السابقة
  final Map<String, dynamic> resultData;

  const CoreResultDetailsScreen({Key? key, required this.resultData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // استخراج البيانات لتسهيل استخدامها
    final title = resultData['title'] ?? 'بدون عنوان';
    final authors = (resultData['authors'] as List<dynamic>?)
        ?.map((author) => author['name'].toString())
        .join(', ') ?? 'مؤلف غير معروف';
    final abstract = resultData['abstract'] ?? 'لا يوجد ملخص متاح.';
    final year = resultData['yearPublished']?.toString() ?? 'غير معروف';
    final publisher = resultData['publisher'] ?? 'غير معروف';
    final articleId = resultData['id']?.toString();
    final downloadableLink = resultData['downloadUrl']; // الرابط المباشر للتنزيل

    return Scaffold(
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
            // --- العنوان ---
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // --- المؤلفون ---
            _buildInfoRow(Icons.people_alt_outlined, 'المؤلفون:', authors),
            const SizedBox(height: 8),

            // --- الناشر وسنة النشر ---
            _buildInfoRow(Icons.business_rounded, 'الناشر:', '$publisher - $year'),
            const Divider(height: 30, thickness: 1),

            // --- الملخص ---
            const Text(
              'الملخص (Abstract)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              abstract,
              style: TextStyle(
                fontSize: 16,
                height: 1.5, // لسهولة القراءة
                color: LibraryTheme.text.withOpacity(0.72),
              ),
            ),
            const Divider(height: 30, thickness: 1),

            // --- أزرار الإجراءات ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // زر التنزيل (يظهر فقط إذا كان هناك رابط)
                if (downloadableLink != null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('تنزيل PDF'),
                    onPressed: () async {
                      final Uri? url = Uri.tryParse(downloadableLink);
                      if (url != null) {
                        // TODO: سنقوم ببرمجة منطق التنزيل الفعلي هنا لاحقاً
                        // حالياً سيفتح الرابط في المتصفح
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LibraryTheme.primary,
                      foregroundColor: LibraryTheme.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),

                // زر الفتح في المتصفح
                if (articleId != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.open_in_browser_rounded),
                    label: const Text('فتح المصدر'),
                    onPressed: () async {
                      final Uri url = Uri.parse('https://core.ac.uk/display/$articleId' );
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // دالة مساعدة لعرض معلومات بشكل منظم
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: LibraryTheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
          ),
        ),
      ],
    );
  }
}
