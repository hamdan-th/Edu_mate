// lib/file_card.dart

import 'package:flutter/material.dart';
import 'library_theme.dart';
import 'file_model.dart';

// دالة مساعدة لتحديد الأيقونة واللون بناءً على نوع الملف
IconData _getIconForFileType(String fileType) {
  if (fileType.toLowerCase() == 'pdf') {
    return Icons.picture_as_pdf_rounded;
  } else if (fileType.toLowerCase() == 'word') {
    return Icons.description_rounded;
  }
  return Icons.insert_drive_file_rounded;
}

Color _getColorForFileType(String fileType) {
  if (fileType.toLowerCase() == 'pdf') {
    return LibraryTheme.danger;
  } else if (fileType.toLowerCase() == 'word') {
    return LibraryTheme.primary;
  }
  return LibraryTheme.text.withOpacity(0.72);
}


class FileCard extends StatelessWidget {
  final FileModel file;
  const FileCard({Key? key, required this.file}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LibraryTheme.surface,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: LibraryTheme.border),
        boxShadow: [
          BoxShadow(
            color: LibraryTheme.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: NetworkImage(file.thumbnailUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  file.author,
                  style: TextStyle(fontSize: 14, color: LibraryTheme.muted),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.thumb_up_alt_rounded, size: 16, color: LibraryTheme.muted),
                        const SizedBox(width: 4),
                        Text(file.likes.toString()),
                        const SizedBox(width: 16),
                        Icon(Icons.bookmark_rounded, size: 16, color: LibraryTheme.muted),
                        const SizedBox(width: 4),
                        Text(file.saves.toString()),
                      ],
                    ),
                    // أيقونة نوع الملف (تمت استعادتها)
                    Icon(
                      _getIconForFileType(file.fileType),
                      color: _getColorForFileType(file.fileType),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GridFileCard extends StatelessWidget {
  final FileModel file;
  const GridFileCard({Key? key, required this.file}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LibraryTheme.surface,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: LibraryTheme.border),
        boxShadow: [
          BoxShadow(
            color: LibraryTheme.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15.0)),
                image: DecorationImage(
                  image: NetworkImage(file.thumbnailUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  file.author,
                  style: TextStyle(fontSize: 12, color: LibraryTheme.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.thumb_up_alt_rounded, size: 14, color: LibraryTheme.muted),
                        const SizedBox(width: 4),
                        Text(
                          file.likes.toString(),
                          style: TextStyle(fontSize: 12, color: LibraryTheme.muted),
                        ),
                      ],
                    ),
                    // أيقونة نوع الملف (تمت استعادتها)
                    Icon(
                      _getIconForFileType(file.fileType),
                      color: _getColorForFileType(file.fileType),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
