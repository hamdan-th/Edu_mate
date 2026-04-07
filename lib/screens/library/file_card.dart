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

    if (file.thumbnailUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          file.thumbnailUrl,
          width: 86,
          height: 110,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackThumbnail(icon, color),
        ),
      );
    }
    return _buildFallbackThumbnail(icon, color);
  }

  Widget _buildFallbackThumbnail(IconData icon, Color color) {
    return Container(
      width: 86,
      height: 110,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Center(
        child: Icon(icon, color: color, size: 36),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LibraryTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: LibraryTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThumbnail(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  file.title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: LibraryTheme.text,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                _InfoRow(icon: Icons.person_outline_rounded, text: file.author),
                const SizedBox(height: 4),
                _InfoRow(icon: Icons.account_balance_rounded, text: file.college),
                const SizedBox(height: 4),
                _InfoRow(icon: Icons.auto_awesome_mosaic_rounded, text: file.major),
                const SizedBox(height: 4),
                _InfoRow(icon: Icons.access_time_rounded, text: file.semester),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StatBadge(icon: Icons.favorite_rounded, count: file.likes, color: LibraryTheme.danger),
                    const SizedBox(width: 10),
                    _StatBadge(icon: Icons.bookmark_rounded, count: file.saves, color: LibraryTheme.primary),
                    const SizedBox(width: 10),
                    _StatBadge(icon: Icons.file_download_rounded, count: file.downloads, color: LibraryTheme.success),
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

  Widget _buildThumbnail() {
    final icon = _getIconForFileType(file.fileType);
    final color = _getColorForFileType(file.fileType);

    if (file.thumbnailUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          file.thumbnailUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackThumbnail(icon, color),
        ),
      );
    }
    return _buildFallbackThumbnail(icon, color);
  }

  Widget _buildFallbackThumbnail(IconData icon, Color color) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(icon, color: color, size: 40),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: LibraryTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: LibraryTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: _buildThumbnail(),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  file.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: LibraryTheme.text,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  file.major,
                  style: const TextStyle(
                    fontSize: 11,
                    color: LibraryTheme.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatBadge(icon: Icons.favorite_rounded, count: file.likes, color: LibraryTheme.danger),
                    _StatBadge(icon: Icons.bookmark_rounded, count: file.saves, color: LibraryTheme.primary),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: LibraryTheme.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: LibraryTheme.muted, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
