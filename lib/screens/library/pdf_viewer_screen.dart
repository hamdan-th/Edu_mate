import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfViewerScreen extends StatelessWidget {
  final String filePath;

  const PdfViewerScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طھطµظپط­ ط§ظ„ظ…ظ„ظپ'),
        centerTitle: true,
      ),
      body: PDFView(
        filePath: filePath,
      ),
    );
  }
}

