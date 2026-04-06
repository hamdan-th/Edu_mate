import 'package:flutter/material.dart';

import 'file_model.dart';
import 'library_theme.dart';

IconData _getIconForFileType(String fileType) {
  switch (fileType.toLowerCase()) {
    case 'pdf':
      return Icons.picture_as_pdf_rounded;
    case 'word':
      return Icons.description_rounded;
    case 'image':
      return Icons.image_rounded;
    default:
      return Icons.insert_drive_file_rounded;
  }
}

Color _getColorForFileType(String fileType) {
  switch (fileType.toLowerCase()) {
    case 'pdf':
      return LibraryTheme.danger;
    case 'word':
      return LibraryTheme.primary;
    case 'image':
      return LibraryTheme.accent;
    default:
      return LibraryTheme.text.withOpacity(0.72);
  }
}

class FileCard extends StatelessWidget {
  final FileModel file;
  const FileCard({Key? key, required this.file}) : super(key: key);

  Widget _buildThumbnail() {
    final icon = _getIconForFileType(file.fileType);
    final color = _getColorForFileType(file.fileType);

    if (file.thumbnailUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          file.thumbnailUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(icon, color),
        ),
      );
    }

    return _fallback(icon, color);
  }

  Widget _fallback(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(icon, size: 36, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileColor = _getColorForFileType(file.fileType);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LibraryTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: LibraryTheme.border),
        boxShadow: [
          BoxShadow(
            color: LibraryTheme.primary.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 86, height: 86, child: _buildThumbnail()),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: fileColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        file.fileType,
                        style: TextStyle(
                          color: fileColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (file.status.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusColor(file.status).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _statusText(file.status),
                          style: TextStyle(
                            color: _statusColor(file.status),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  file.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: LibraryTheme.text,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  file.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LibraryTheme.muted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _MetaItem(
                      icon: Icons.favorite_rounded,
                      value: file.likes.toString(),
                      color: const Color(0xFFE11D48),
                    ),
                    _MetaItem(
                      icon: Icons.visibility_rounded,
                      value: file.views.toString(),
                      color: LibraryTheme.primary,
                    ),
                    _MetaItem(
                      icon: Icons.download_rounded,
                      value: file.downloads.toString(),
                      color: LibraryTheme.success,
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

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return LibraryTheme.success;
      case 'pending':
        return LibraryTheme.accent;
      case 'rejected':
        return LibraryTheme.danger;
      default:
        return LibraryTheme.muted;
    }
  }

  static String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'معتمد';
      case 'pending':
        return 'قيد المراجعة';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _MetaItem({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: LibraryTheme.muted,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
