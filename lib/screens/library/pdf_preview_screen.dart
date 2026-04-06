import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'library_theme.dart';
import '../../core/theme/app_colors.dart';

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
      backgroundColor: (Theme.of(context).brightness == Brightness.dark ? AppColors.background : const Color(0xFFF8F9FA)),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: (Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black87),
        elevation: 0,
      ),
      body: url.trim().isEmpty
          ? Center(
              child: Text(
                'لا يوجد رابط للملف',
                style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black87)),
              ),
            )
          : SfPdfViewer.network(url),
    );
  }
}
