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
      return Theme.of(context).colorScheme.error;
    case 'word':
      return Theme.of(context).colorScheme.primary;
    case 'image':
      return const Color(0xFFF59E0B); // Gold accents can remain
    default:
      return Theme.of(context).colorScheme.onSurfaceVariant;
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
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final borderColor = Theme.of(context).dividerColor.withOpacity(0.08);

    return Container(
      padding: LibrarySpacing.card,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(LibraryRadius.card),
        border: Border.all(color: borderColor),
        boxShadow: LibraryShadows.soft(context),
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
                      padding: LibrarySpacing.badge,
                      decoration: BoxDecoration(
                        color: fileColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(LibraryRadius.badge),
                      ),
                      child: Text(
                        file.fileType,
                        style: LibraryTextStyles.badge(context, fileColor),
                      ),
                    ),
                    Container(
                      padding: LibrarySpacing.badge,
                      decoration: BoxDecoration(
                        color: _statusColor(context, file.status).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(LibraryRadius.badge),
                      ),
                      child: Text(
                        _statusText(file.status),
                        style: LibraryTextStyles.badge(context, _statusColor(context, file.status)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  file.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: LibraryTextStyles.title(context),
                ),
                const SizedBox(height: 4),
                Text(
                  '${file.author} â€¢ ${file.college}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LibraryTextStyles.subtitle(context),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _MetricChip(icon: Icons.thumb_up_alt_outlined, value: file.likes),
                    const SizedBox(width: 18),
                    _MetricChip(icon: Icons.bookmark_border_rounded, value: file.saves),
                    const SizedBox(width: 18),
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
        return Colors.green;
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'rejected':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  static String _statusText(String status) {
    switch (status) {
      case 'approved':
        return 'ظ…ظ†ط´ظˆط±';
      case 'pending':
        return 'ظ‚ظٹط¯ ط§ظ„ظ…ط±ط§ط¬ط¹ط©';
      case 'rejected':
        return 'ظ…ط±ظپظˆط¶';
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
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final borderColor = Theme.of(context).dividerColor.withOpacity(0.08);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(LibraryRadius.card),
        border: Border.all(color: borderColor),
        boxShadow: LibraryShadows.soft(context),
      ),
      child: Padding(
        padding: LibrarySpacing.gridCard,
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
              style: LibraryTextStyles.title(context).copyWith(fontSize: 13, height: 1.2),
            ),
            const SizedBox(height: 4),
            Text(
              '${file.author} â€¢ ${file.college}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: LibraryTextStyles.subtitle(context).copyWith(fontSize: 11),
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
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: mutedColor,
      fontWeight: FontWeight.w500,
      height: 1.0,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: mutedColor),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: textStyle,
        ),
      ],
    );
  }
}

