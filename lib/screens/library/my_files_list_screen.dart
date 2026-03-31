import 'package:flutter/material.dart';
import 'library_theme.dart';

class MyFilesListScreen extends StatelessWidget {
  final String title;
  const MyFilesListScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: LibraryTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'سيتم عرض قائمة الملفات هنا',
          style: TextStyle(fontSize: 18, color: LibraryTheme.text),
        ),
      ),
    );
  }
}
