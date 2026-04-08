import 'package:flutter/material.dart';

import 'file_model.dart';
import 'library_theme.dart';

class FileCard extends StatefulWidget {
  final FileModel file;
  final VoidCallback? onTap;

  const FileCard({super.key, required this.file, this.onTap});

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
    final double scale = _isPressed ? 0.97 : (_isHovering ? 1.01 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _isPressed = true),
        onPointerUp: (_) => setState(() => _isPressed = false),
        onPointerCancel: (_) => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCirc,
          transform: Matrix4.identity()..scale(scale, scale),
          margin: const EdgeInsets.only(bottom: 14),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey.withOpacity(isDark ? 0.10 : 0.14),
                    width: 1,
                  ),
                  gradient: LinearGradient(
                    colors: [
                      LibraryTheme.surface(context),
                      gold.withOpacity(isDark ? 0.05 : 0.025),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    if (!_isPressed)
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.05 : 0.045),
                        blurRadius: _isHovering ? 16 : 12,
                        offset: Offset(0, _isHovering ? 8 : 4),
                      ),
                    if (_isPressed)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
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
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const _ActionButton(),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.file.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: LibraryTheme.text(context),
                                    height: 1.35,
                                    letterSpacing: -0.15,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _buildSubtitle(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color:
                                    isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    _MetricChip(
                                      icon: Icons.remove_red_eye_outlined,
                                      value: widget.file.views,
                                    ),
                                    const SizedBox(width: 8),
                                    _MetricChip(
                                      icon: Icons.file_download_outlined,
                                      value: widget.file.downloads,
                                    ),
                                    const SizedBox(width: 8),
                                    _MetricChip(
                                      icon: Icons.favorite_border_rounded,
                                      value: widget.file.likes,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
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
    } else if (author.isNotEmpty) {
      return author;
    } else if (college.isNotEmpty) {
      return college;
    }
    return 'غير محدد';
  }

  Widget _buildBadge(BuildContext context) {
    final String type = widget.file.fileType.toLowerCase();
    final Color badgeColor = _getFileColor(type);
    final IconData badgeIcon = _getFileIcon(type);

    if (widget.file.thumbnailUrl.trim().isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            widget.file.thumbnailUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _fallbackBadge(badgeColor, badgeIcon, type),
          ),
        ),
      );
    }
    return _fallbackBadge(badgeColor, badgeIcon, type);
  }

  Widget _fallbackBadge(Color color, IconData icon, String type) {
    final shortType =
    type.toUpperCase().length > 4 ? type.substring(0, 3).toUpperCase() : type.toUpperCase();

    return Container(
      width: 50,
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.2),
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 2),
          Text(
            shortType.isEmpty ? 'FILE' : shortType,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
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

  const GridFileCard({super.key, required this.file, this.onTap});

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
    final double scale = _isPressed ? 0.97 : (_isHovering ? 1.01 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _isPressed = true),
        onPointerUp: (_) => setState(() => _isPressed = false),
        onPointerCancel: (_) => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCirc,
          transform: Matrix4.identity()..scale(scale, scale),
          margin: const EdgeInsets.only(bottom: 14),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.grey.withOpacity(isDark ? 0.10 : 0.14),
                    width: 1,
                  ),
                  gradient: LinearGradient(
                    colors: [
                      LibraryTheme.surface(context),
                      gold.withOpacity(isDark ? 0.05 : 0.025),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    if (!_isPressed)
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.05 : 0.04),
                        blurRadius: _isHovering ? 16 : 12,
                        offset: Offset(0, _isHovering ? 8 : 4),
                      ),
                    if (_isPressed)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _ActionButton(),
                              _buildBadge(context),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            widget.file.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: LibraryTheme.text(context),
                              height: 1.35,
                              letterSpacing: -0.15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.file.author.isNotEmpty
                                ? widget.file.author
                                : 'غير محدد',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color:
                              isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _MetricChip(
                                icon: Icons.remove_red_eye_outlined,
                                value: widget.file.views,
                              ),
                              const SizedBox(width: 8),
                              _MetricChip(
                                icon: Icons.file_download_outlined,
                                value: widget.file.downloads,
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
    final String type = widget.file.fileType.toLowerCase();
    final Color badgeColor = _getFileColor(type);
    final IconData badgeIcon = _getFileIcon(type);

    if (widget.file.thumbnailUrl.trim().isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            widget.file.thumbnailUrl,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _fallbackBadge(badgeColor, badgeIcon, type),
          ),
        ),
      );
    }
    return _fallbackBadge(badgeColor, badgeIcon, type);
  }

  Widget _fallbackBadge(Color color, IconData icon, String type) {
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.2),
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
      child: Center(
        child: Icon(icon, color: color, size: 18),
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
  const _ActionButton();

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _isPressed = true),
        onPointerUp: (_) => setState(() => _isPressed = false),
        onPointerCancel: (_) => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.94 : (_isHovering ? 1.03 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
                      .withOpacity(_isHovering ? 0.45 : 0.28),
                  blurRadius: _isHovering ? 14 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'فتح',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 16,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.18),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
          const SizedBox(width: 6),
          Text(
            '$value',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[800],
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}