import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'library_theme.dart';
import '../../l10n/app_localizations.dart';

class PdfPreviewScreen extends StatelessWidget {
  final String url;
  final String title;

  const PdfPreviewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LibraryTheme.bg(context),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: LibraryTheme.surface(context),
        foregroundColor: LibraryTheme.text(context),
        elevation: 0,
      ),
      body: url.trim().isEmpty
          ? Center(
        child: Text(
          AppLocalizations.of(context)!.myFilesNoLink,
          style: TextStyle(color: LibraryTheme.text(context)),
        ),
      )
          : SfPdfViewer.network(url),
    );
  }
}