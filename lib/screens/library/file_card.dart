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
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${file.author} • ${file.college}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LibraryTheme.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _MetricChip(icon: Icons.thumb_up_alt_outlined, value: file.likes),
                    const SizedBox(width: 8),
                    _MetricChip(icon: Icons.bookmark_border_rounded, value: file.saves),
                    const SizedBox(width: 8),
                    _MetricChip(icon: Icons.visibility_outlined, value: file.views),
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
    switch (status) {
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
    switch (status) {
      case 'approved':
        return 'منشور';
      case 'pending':
        return 'قيد المراجعة';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }
}

class GridFileCard extends StatelessWidget {
  final FileModel file;
  const GridFileCard({Key? key, required this.file}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = _getColorForFileType(file.fileType);

    return Container(
      decoration: BoxDecoration(
        color: LibraryTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: LibraryTheme.border),
        boxShadow: [
          BoxShadow(
            color: LibraryTheme.primary.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  _getIconForFileType(file.fileType),
                  size: 42,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              file.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: LibraryTheme.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              file.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: LibraryTheme.muted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${file.likes} إعجاب',
                    style: const TextStyle(fontSize: 12, color: LibraryTheme.muted),
                  ),
                ),
                Icon(_getIconForFileType(file.fileType), size: 16, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final int value;
  const _MetricChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: LibraryTheme.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: LibraryTheme.muted),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: const TextStyle(
              color: LibraryTheme.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
