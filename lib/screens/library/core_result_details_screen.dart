import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'digital_library_firestore_service.dart';
import 'library_theme.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../core/providers/guest_provider.dart';
import '../../widgets/guest_action_dialog.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final title = resultData['title'] ?? l10n.digitalLibNoTitle;
    final authors = (resultData['authors'] as List<dynamic>?)
        ?.map((author) => author['name'].toString())
        .join(', ') ??
        l10n.digitalLibUnknownAuthor;
    final abstract = resultData['abstract'] ?? l10n.digitalLibNoAbstract;
    final year = resultData['yearPublished']?.toString() ?? l10n.myFilesUnknown;
    final publisher = resultData['publisher'] ?? l10n.myFilesUnknown;
    final journal = resultData['journals'] is List &&
        (resultData['journals'] as List).isNotEmpty
        ? (resultData['journals'] as List).first.toString()
        : l10n.myFilesUnknown;
    final articleId = resultData['id']?.toString();
    final downloadableLink = resultData['downloadUrl']?.toString();

    final String articleUrl = (articleId != null && articleId.isNotEmpty)
        ? 'https://core.ac.uk/display/$articleId'
        : '';

    return Scaffold(
      backgroundColor: LibraryTheme.bg(context),
      appBar: AppBar(
        title: Text(l10n.digitalLibResultDetailsTitle),
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
            _buildInfoRow(context, Icons.people_alt_outlined, l10n.digitalLibLabelAuthors, authors),
            const SizedBox(height: 8),
            _buildInfoRow(context, Icons.business_rounded, l10n.digitalLibLabelPublisher, publisher.toString()),
            const SizedBox(height: 8),
            _buildInfoRow(context, Icons.calendar_today_rounded, l10n.digitalLibLabelYear, year),
            const SizedBox(height: 8),
            _buildInfoRow(context, Icons.menu_book_rounded, l10n.digitalLibLabelJournal, journal),
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
                    label: Text(isSaved ? l10n.digitalLibActionSaved : l10n.digitalLibActionSave),
                    onPressed: () async {
                      // 🚫 Guest cannot save
                      if (context.read<GuestProvider>().isGuest) {
                        GuestActionDialog.show(
                          context,
                          title: 'تسجيل الدخول مطلوب',
                          subtitle: 'لحفظ الملفات في مكتبتك، سجّل دخولك أولًا.',
                        );
                        return;
                      }

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
                                    ? l10n.digitalLibRemovedFromSaved
                                    : l10n.digitalLibSavedSuccessfully,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.digitalLibSaveErrorParam(e.toString()))),
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
                    label: Text(l10n.digitalLibActionShare),
                    onPressed: () async {
                      if (articleUrl.isEmpty) return;
                      await Share.share(
                        l10n.digitalLibShareText(title, articleUrl),
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
                  label: Text(l10n.digitalLibActionDownloadPdf),
                  onPressed: () async {
                    // 🚫 Guest cannot download
                    if (context.read<GuestProvider>().isGuest) {
                      GuestActionDialog.show(
                        context,
                        title: 'تسجيل الدخول مطلوب',
                        subtitle: 'تصفح الملفات متاح كضيف، لكن التحميل متاح للمستخدمين المسجلين فقط.',
                      );
                      return;
                    }

                    try {
                      await DigitalLibraryFirestoreService.registerDownload(
                        resultData,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.digitalLibDownloadError(e.toString()))),
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
                  label: Text(l10n.digitalLibActionOpenSource),
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
              l10n.digitalLibLabelAbstract,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: LibraryTheme.text(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              abstract.toString().trim().isEmpty
                  ? l10n.digitalLibNoAbstract
                  : abstract.toString(),
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: LibraryTheme.text(context).withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final l10n = AppLocalizations.of(context)!;
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
            value.isEmpty ? l10n.myFilesUnknown : value,
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