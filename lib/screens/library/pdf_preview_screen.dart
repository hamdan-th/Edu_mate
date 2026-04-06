import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'library_theme.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
      ),
      body: url.trim().isEmpty
          ? const Center(
              child: Text(
                'لا يوجد رابط للملف',
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
            )
          : SfPdfViewer.network(url),
    );
  }
}
