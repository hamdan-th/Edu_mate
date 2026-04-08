import 'package:flutter/material.dart';

import 'file_model.dart';
import 'library_theme.dart';

class FileCard extends StatefulWidget {
  final FileModel file;
  final VoidCallback? onTap;

  const FileCard({
    super.key,
    required this.file,
    this.onTap,
  });

  @override
  State<FileCard> createState() => _FileCardState();
}

class _FileCardState extends State<FileCard> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = const Color(0xFFD4AF37);
    final scale = _isPressed ? 0.98 : (_isHovering ? 1.005 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _isPressed = true),
        onPointerUp: (_) => setState(() => _isPressed = false),
        onPointerCancel: (_) => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()..scale(scale, scale),
          margin: const EdgeInsets.only(bottom: 14),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? LibraryTheme.border(context) : Colors.grey.withOpacity(0.14),
                    width: 1,
                  ),
                  gradient: LinearGradient(
                    colors: [
                      LibraryTheme.surface(context),
                      isDark ? LibraryTheme.surface(context) : gold.withOpacity(0.025),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    if (!_isPressed)
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.25 : 0.045),
                        blurRadius: _isHovering ? 16 : 12,
                        offset: Offset(0, _isHovering ? 8 : 4),
                      ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(20),
                    highlightColor: gold.withOpacity(0.05),
                    splashColor: gold.withOpacity(0.10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const _ActionButton(),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.file.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15.8,
                                    fontWeight: FontWeight.w800,
                                    color: LibraryTheme.text(context),
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _buildSubtitle(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.8,
                                    fontWeight: FontWeight.w600,
                                    color: LibraryTheme.muted(context),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _MetricChip(
                                      icon: Icons.favorite_border_rounded,
                                      value: widget.file.likes,
                                    ),
                                    _MetricChip(
                                      icon: Icons.file_download_outlined,
                                      value: widget.file.downloads,
                                    ),
                                    _MetricChip(
                                      icon: Icons.remove_red_eye_outlined,
                                      value: widget.file.views,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildBadge(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: gold.withOpacity(0.85),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final author = widget.file.author.trim();
    final college = widget.file.college.trim();

    if (author.isNotEmpty && college.isNotEmpty) {
      return '$author • $college';
    }
    if (author.isNotEmpty) {
      return author;
    }
    if (college.isNotEmpty) {
      return college;
    }
    return 'غير محدد';
  }

  Widget _buildBadge(BuildContext context) {
    final type = widget.file.fileType.toLowerCase();
    final color = _getFileColor(type);
    final icon = _getFileIcon(type);

    if (widget.file.thumbnailUrl.trim().isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withOpacity(0.14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            widget.file.thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackBadge(color, icon, type),
          ),
        ),
      );
    }

    return _fallbackBadge(color, icon, type);
  }

  Widget _fallbackBadge(Color color, IconData icon, String type) {
    final shortType = type.toUpperCase().length > 4
        ? type.substring(0, 3).toUpperCase()
        : type.toUpperCase();

    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.20),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 1),
          Text(
            shortType.isEmpty ? 'FILE' : shortType,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.3,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Color _getFileColor(String type) {
    switch (type) {
      case 'pdf':
        return const Color(0xFFE57373);
      case 'doc':
      case 'docx':
      case 'word':
        return const Color(0xFF64B5F6);
      case 'image':
      case 'png':
      case 'jpg':
      case 'jpeg':
        return const Color(0xFFBA68C8);
      case 'ppt':
      case 'pptx':
        return const Color(0xFFFFB74D);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _getFileIcon(String type) {
    switch (type) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
      case 'word':
        return Icons.description_rounded;
      case 'image':
      case 'png':
      case 'jpg':
      case 'jpeg':
        return Icons.image_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.analytics_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}

class GridFileCard extends StatefulWidget {
  final FileModel file;
  final VoidCallback? onTap;

  const GridFileCard({
    super.key,
    required this.file,
    this.onTap,
  });

  @override
  State<GridFileCard> createState() => _GridFileCardState();
}

class _GridFileCardState extends State<GridFileCard> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = const Color(0xFFD4AF37);
    final scale = _isPressed ? 0.98 : (_isHovering ? 1.005 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _isPressed = true),
        onPointerUp: (_) => setState(() => _isPressed = false),
        onPointerCancel: (_) => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()..scale(scale, scale),
          margin: const EdgeInsets.only(bottom: 14),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? LibraryTheme.border(context) : Colors.grey.withOpacity(0.14),
                    width: 1,
                  ),
                  gradient: LinearGradient(
                    colors: [
                      LibraryTheme.surface(context),
                      isDark ? LibraryTheme.surface(context) : gold.withOpacity(0.025),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    if (!_isPressed)
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                        blurRadius: _isHovering ? 16 : 12,
                        offset: Offset(0, _isHovering ? 8 : 4),
                      ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(22),
                    highlightColor: gold.withOpacity(0.05),
                    splashColor: gold.withOpacity(0.10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const _ActionButton(compact: true),
                              const Spacer(),
                              _buildBadge(context),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            widget.file.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.8,
                              fontWeight: FontWeight.w800,
                              color: LibraryTheme.text(context),
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.file.author.isNotEmpty
                                ? widget.file.author
                                : 'غير محدد',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.3,
                              fontWeight: FontWeight.w600,
                              color: LibraryTheme.muted(context),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _MetricChip(
                                icon: Icons.file_download_outlined,
                                value: widget.file.downloads,
                              ),
                              _MetricChip(
                                icon: Icons.remove_red_eye_outlined,
                                value: widget.file.views,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: gold.withOpacity(0.85),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      bottomLeft: Radius.circular(22),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context) {
    final type = widget.file.fileType.toLowerCase();
    final color = _getFileColor(type);
    final icon = _getFileIcon(type);

    if (widget.file.thumbnailUrl.trim().isNotEmpty) {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withOpacity(0.14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            widget.file.thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackBadge(color, icon),
          ),
        ),
      );
    }

    return _fallbackBadge(color, icon);
  }

  Widget _fallbackBadge(Color color, IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Center(
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }

  Color _getFileColor(String type) {
    switch (type) {
      case 'pdf':
        return const Color(0xFFE57373);
      case 'doc':
      case 'docx':
      case 'word':
        return const Color(0xFF64B5F6);
      case 'image':
      case 'png':
      case 'jpg':
      case 'jpeg':
        return const Color(0xFFBA68C8);
      case 'ppt':
      case 'pptx':
        return const Color(0xFFFFB74D);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _getFileIcon(String type) {
    switch (type) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
      case 'word':
        return Icons.description_rounded;
      case 'image':
      case 'png':
      case 'jpg':
      case 'jpeg':
        return Icons.image_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.analytics_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}

class _ActionButton extends StatefulWidget {
  final bool compact;

  const _ActionButton({this.compact = false});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.compact ? 12.0 : 14.0;
    final vertical = widget.compact ? 8.0 : 10.0;
    final fontSize = widget.compact ? 12.0 : 13.0;
    final iconSize = widget.compact ? 15.0 : 16.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _isPressed = true),
        onPointerUp: (_) => setState(() => _isPressed = false),
        onPointerCancel: (_) => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : (_isHovering ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontal,
              vertical: vertical,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFF1D570),
                  Color(0xFFD4AF37),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37)
                      .withOpacity(_isHovering ? 0.40 : 0.24),
                  blurRadius: _isHovering ? 14 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'فتح',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: iconSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final int value;

  const _MetricChip({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222A) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? LibraryTheme.border(context) : Colors.grey.withOpacity(0.18),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.5,
            color: LibraryTheme.muted(context),
          ),
          const SizedBox(width: 5),
          Text(
            '$value',
            style: TextStyle(
              color: LibraryTheme.text(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}