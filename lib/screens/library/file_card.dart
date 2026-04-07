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

Color _getColorForFileType(BuildContext context, String fileType) {
  switch (fileType.toLowerCase()) {
    case 'pdf':
      return LibraryTheme.danger(context);
    case 'word':
      return LibraryTheme.primary(context);
    case 'image':
      return LibraryTheme.accent(context);
    default:
      return LibraryTheme.text(context).withOpacity(0.72);
  }
}

class FileCard extends StatelessWidget {
  final FileModel file;
  const FileCard({super.key, required this.file});

  Widget _buildThumbnail(BuildContext context) {
    final icon = _getIconForFileType(file.fileType);
    final color = _getColorForFileType(context, file.fileType);

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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(icon, size: 28, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileColor = _getColorForFileType(context, file.fileType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: LibraryTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LibraryTheme.border(context).withOpacity(0.3), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: LibraryTheme.primary(context).withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 58, height: 58, child: _buildThumbnail(context)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: fileColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        file.fileType,
                        style: TextStyle(
                          color: fileColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(context, file.status).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _statusText(file.status),
                        style: TextStyle(
                          color: _statusColor(context, file.status),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  file.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: LibraryTheme.text(context),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        file.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: LibraryTheme.muted(context),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text('•', style: TextStyle(color: LibraryTheme.muted(context).withOpacity(0.4), fontSize: 10)),
                    ),
                    Flexible(
                      child: Text(
                        file.college,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: LibraryTheme.muted(context),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 16,
                  children: [
                    _MetricChip(icon: Icons.thumb_up_alt_outlined, value: file.likes),
                    _MetricChip(icon: Icons.bookmark_border_rounded, value: file.saves),
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

  static Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'approved':
        return LibraryTheme.success(context);
      case 'pending':
        return LibraryTheme.accent(context);
      case 'rejected':
        return LibraryTheme.danger(context);
      default:
        return LibraryTheme.muted(context);
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
  const GridFileCard({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final color = _getColorForFileType(context, file.fileType);

    return Container(
      decoration: BoxDecoration(
        color: LibraryTheme.surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: LibraryTheme.border(context).withOpacity(0.3), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: LibraryTheme.primary(context).withOpacity(0.05),
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
            const SizedBox(height: 8),
            Text(
              file.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: LibraryTheme.text(context),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Flexible(
                  child: Text(
                    file.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: LibraryTheme.muted(context), height: 1.3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('•', style: TextStyle(color: LibraryTheme.muted(context).withOpacity(0.4), fontSize: 9)),
                ),
                Flexible(
                  child: Text(
                    file.college,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: LibraryTheme.muted(context), height: 1.3),
                  ),
                ),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 13, color: LibraryTheme.muted(context).withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: TextStyle(
            color: LibraryTheme.muted(context).withOpacity(0.9),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
