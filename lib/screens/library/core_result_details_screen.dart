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
    final title = resultData['title'] ?? 'ط¨ط¯ظˆظ† ط¹ظ†ظˆط§ظ†';
    final authors = (resultData['authors'] as List<dynamic>?)
        ?.map((author) => author['name'].toString())
        .join(', ') ??
        'ظ…ط¤ظ„ظپ ط؛ظٹط± ظ…ط¹ط±ظˆظپ';
    final abstract = resultData['abstract'] ?? 'ظ„ط§ ظٹظˆط¬ط¯ ظ…ظ„ط®طµ ظ…طھط§ط­.';
    final year = resultData['yearPublished']?.toString() ?? 'ط؛ظٹط± ظ…ط¹ط±ظˆظپ';
    final publisher = resultData['publisher'] ?? 'ط؛ظٹط± ظ…ط¹ط±ظˆظپ';
    final journal = resultData['journals'] is List &&
        (resultData['journals'] as List).isNotEmpty
        ? (resultData['journals'] as List).first.toString()
        : 'ط؛ظٹط± ظ…ط¹ط±ظˆظپ';
    final articleId = resultData['id']?.toString();
    final downloadableLink = resultData['downloadUrl']?.toString();

    final String articleUrl = (articleId != null && articleId.isNotEmpty)
        ? 'https://core.ac.uk/display/$articleId'
        : '';

    return Scaffold(
      backgroundColor: LibraryTheme.bg(context),
      appBar: AppBar(
        title: const Text('طھظپط§طµظٹظ„ ط§ظ„ط¨ط­ط«'),
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
                    label: Text(isSaved ? 'ظ…ط­ظپظˆط¸' : 'ط­ظپط¸'),
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
                                    ? 'طھظ…طھ ط§ظ„ط¥ط²ط§ظ„ط© ظ…ظ† ط§ظ„ط­ظپط¸ ط¯ط§ط®ظ„ ط§ظ„ظˆط§ط¬ظ‡ط©'
                                    : 'طھظ… ط­ظپط¸ ط§ظ„ظ…ط±ط¬ط¹ ظپظٹ ظ…ظƒطھط¨طھظٹ',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('طھط¹ط°ط± ط­ظپط¸ ط§ظ„ظ…ط±ط¬ط¹: $e')),
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
                    label: const Text('ظ…ط´ط§ط±ظƒط©'),
                    onPressed: () async {
                      if (articleUrl.isEmpty) return;
                      await Share.share(
                        'ط§ط·ظ„ط¹ ط¹ظ„ظ‰ ظ‡ط°ظ‡ ط§ظ„ظˆط±ظ‚ط© ط§ظ„ط¨ط­ط«ظٹط©:\n$title\n$articleUrl',
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
                  label: const Text('طھظ†ط²ظٹظ„ PDF'),
                  onPressed: () async {
                    try {
                      await DigitalLibraryFirestoreService.registerDownload(
                        resultData,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('طھط¹ط°ط± طھط³ط¬ظٹظ„ ط§ظ„طھظ†ط²ظٹظ„: $e')),
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
                  label: const Text('ظپطھط­ ط§ظ„ظ…طµط¯ط±'),
                  onPressed: () async {
                    final Uri url = Uri.parse(articleUrl);
                    await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LibraryTheme.primary(context),
                    side: BorderSide(color: LibraryTheme.primary(context)),
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
              'ط§ظ„ظ…ظ„ط®طµ (Abstract)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: LibraryTheme.text(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              abstract.toString().trim().isEmpty
                  ? 'ظ„ط§ ظٹظˆط¬ط¯ ظ…ظ„ط®طµ ظ…طھط§ط­.'
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
            value.isEmpty ? 'ط؛ظٹط± ظ…ط¹ط±ظˆظپ' : value,
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

