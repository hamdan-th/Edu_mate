import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'library_local_download_service.dart';
import 'file_model.dart';
import 'library_files_service.dart';
import 'library_reactions_service.dart';
import 'library_theme.dart';
import 'pdf_preview_screen.dart';

class FileDetailsScreen extends StatefulWidget {
  final FileModel file;
  const FileDetailsScreen({Key? key, required this.file}) : super(key: key);

  @override
  State<FileDetailsScreen> createState() => _FileDetailsScreenState();
}

class _FileDetailsScreenState extends State<FileDetailsScreen> {
  bool _viewRegistered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_viewRegistered) {
      _viewRegistered = true;
      LibraryReactionsService.registerViewOnce(widget.file.id);
    }
  }

  void _shareFile(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
      );
      return;
    }

    try {
      final text = '''
📚 تم مشاركة ملف من مكتبة الجامعة
✨ المادة: ${widget.file.title}
👨‍🏫 الدكتور: ${widget.file.author}

رابط التحميل:
${widget.file.fileUrl}
''';
      await Share.share(text);
      await LibraryReactionsService.registerShare(widget.file.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء المشاركة: $e')),
        );
      }
    }
  }

  Future<void> _openPdf(BuildContext context) async {
    if (widget.file.fileUrl.trim().isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          url: widget.file.fileUrl,
          title: widget.file.title,
        ),
      ),
    );
  }

  Future<void> _deleteFile(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الملف نهائيًا؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await LibraryFilesService.deleteLibraryFile(
        fileId: widget.file.id,
        storagePath: widget.file.storagePath ?? '',
      );
      if (context.mounted) {
        Navigator.pop(context); // pop loading
        Navigator.pop(context); // pop screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الملف بنجاح')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('عذرًا، حدث خطأ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LibraryTheme.surface,
      body: CustomScrollView(
        slivers: [
          _SliverHeader(file: widget.file, onShare: () => _shareFile(context)),
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Container(
                  color: LibraryTheme.primary.withOpacity(0.04),
                  height: 100,
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: LibraryTheme.surface,
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _TopActionsAndMetrics(
                            file: widget.file, onShare: () => _shareFile(context)),
                        const SizedBox(height: 28),
                        const Divider(height: 1, color: LibraryTheme.border),
                        const SizedBox(height: 24),
                        _FileDetailsGrid(file: widget.file),
                        const SizedBox(height: 24),
                        const Divider(height: 1, color: LibraryTheme.border),
                        const SizedBox(height: 24),
                        _UploaderInfo(file: widget.file),
                        if (widget.file.userId == LibraryFilesService.currentUserId) ...[
                          const SizedBox(height: 24),
                          const Divider(height: 1, color: LibraryTheme.border),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () => _deleteFile(context),
                                  icon: const Icon(Icons.delete_rounded,
                                      color: Colors.red),
                                  label: const Text('حذف الملف',
                                      style: TextStyle(color: Colors.red)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    backgroundColor:
                                    Colors.red.withOpacity(0.1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _MainActionButtons(
        file: widget.file,
        onPreviewPdf: () => _openPdf(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _SliverHeader extends StatelessWidget {
  final FileModel file;
  final VoidCallback onShare;

  const _SliverHeader({required this.file, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      elevation: 0,
      backgroundColor: LibraryTheme.surface,
      surfaceTintColor: LibraryTheme.surface,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: LibraryTheme.surface.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: LibraryTheme.text),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: onShare,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: LibraryTheme.surface.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.share_rounded,
                  color: LibraryTheme.primary, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (file.thumbnailUrl.isNotEmpty) ...[
              Image.network(file.thumbnailUrl, fit: BoxFit.cover),
              Container(color: Colors.black.withOpacity(0.4)),
            ] else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      LibraryTheme.primary.withOpacity(0.05),
                      LibraryTheme.secondary.withOpacity(0.15),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: file.isPdf
                          ? LibraryTheme.danger.withOpacity(0.15)
                          : file.isWord
                          ? LibraryTheme.primary.withOpacity(0.15)
                          : LibraryTheme.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: file.isPdf
                            ? LibraryTheme.danger.withOpacity(0.3)
                            : file.isWord
                            ? LibraryTheme.primary.withOpacity(0.3)
                            : LibraryTheme.accent.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      file.fileType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: file.isPdf
                            ? LibraryTheme.danger
                            : file.isWord
                            ? LibraryTheme.primary
                            : LibraryTheme.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    file.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: LibraryTheme.text,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 16, color: LibraryTheme.muted),
                      const SizedBox(width: 6),
                      Text(
                        file.author,
                        style: const TextStyle(
                            fontSize: 14, color: LibraryTheme.muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopActionsAndMetrics extends StatelessWidget {
  final FileModel file;
  final VoidCallback onShare;

  const _TopActionsAndMetrics({required this.file, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('library_files')
          .doc(file.id)
          .snapshots(),
      builder: (context, snapshot) {
        int likesCount = file.likes;
        int savesCount = file.saves;
        int downloadsCount = file.downloads;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data()!;
          likesCount = (data['likesCount'] as num?)?.toInt() ?? 0;
          savesCount = (data['savesCount'] as num?)?.toInt() ?? 0;
          downloadsCount = (data['downloadsCount'] as num?)?.toInt() ?? 0;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: LibraryTheme.bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: LibraryTheme.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _InteractionButton(
                fileId: file.id,
                iconData: Icons.favorite_rounded,
                outlineIconData: Icons.favorite_outline_rounded,
                label: 'إعجاب',
                count: likesCount,
                actionType: _ActionType.like,
                activeColor: LibraryTheme.danger,
              ),
              _InteractionButton(
                fileId: file.id,
                iconData: Icons.bookmark_rounded,
                outlineIconData: Icons.bookmark_outline_rounded,
                label: 'حفظ',
                count: savesCount,
                actionType: _ActionType.save,
                activeColor: LibraryTheme.primary,
              ),
              _StatOnlyItem(
                iconData: Icons.file_download_rounded,
                label: 'تحميل',
                count: downloadsCount,
                color: LibraryTheme.success,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatOnlyItem extends StatelessWidget {
  final IconData iconData;
  final String label;
  final int count;
  final Color color;

  const _StatOnlyItem({
    required this.iconData,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          '$count',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Text(
          label,
          style: const TextStyle(color: LibraryTheme.muted, fontSize: 11),
        ),
      ],
    );
  }
}

enum _ActionType { like, save }

class _InteractionButton extends StatelessWidget {
  final String fileId;
  final IconData iconData;
  final IconData outlineIconData;
  final String label;
  final int count;
  final _ActionType actionType;
  final Color activeColor;

  const _InteractionButton({
    required this.fileId,
    required this.iconData,
    required this.outlineIconData,
    required this.label,
    required this.count,
    required this.actionType,
    required this.activeColor,
  });

  Stream<bool> _getStream() {
    if (actionType == _ActionType.like) {
      return LibraryReactionsService.isLikedStream(fileId);
    } else {
      return LibraryReactionsService.isSavedStream(fileId);
    }
  }

  Future<void> _toggleAction(BuildContext context, bool isActive) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
      );
      return;
    }

    try {
      if (actionType == _ActionType.like) {
        await LibraryReactionsService.toggleLike(
            fileId: fileId, isCurrentlyLiked: isActive);
      } else {
        await LibraryReactionsService.toggleSave(
            fileId: fileId, isCurrentlySaved: isActive);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _getStream(),
      builder: (context, snapshot) {
        final isActive = snapshot.data ?? false;
        final currentColor = isActive ? activeColor : LibraryTheme.muted;

        return InkWell(
          onTap: () => _toggleAction(context, isActive),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive
                      ? activeColor.withOpacity(0.12)
                      : LibraryTheme.border.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isActive ? iconData : outlineIconData,
                  color: currentColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: currentColor,
                ),
              ),
              Text(
                label,
                style: TextStyle(color: currentColor, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FileDetailsGrid extends StatelessWidget {
  final FileModel file;

  const _FileDetailsGrid({required this.file});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'التصنيف الأكاديمي',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: LibraryTheme.bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: LibraryTheme.border),
          ),
          child: Column(
            children: [
              _InfoGridRow(
                icon: Icons.account_balance_rounded,
                label: 'الكلية',
                value: file.college.isNotEmpty ? file.college : 'غير محدد',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: LibraryTheme.border),
              ),
              _InfoGridRow(
                icon: Icons.auto_awesome_mosaic_rounded,
                label: 'التخصص',
                value: file.major.isNotEmpty ? file.major : 'غير محدد',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: LibraryTheme.border),
              ),
              _InfoGridRow(
                icon: Icons.layers_rounded,
                label: 'المستوى والترم',
                value: file.semester.isNotEmpty ? file.semester : 'غير محدد',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoGridRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoGridRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: LibraryTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: LibraryTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: LibraryTheme.muted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UploaderInfo extends StatelessWidget {
  final FileModel file;

  const _UploaderInfo({required this.file});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LibraryTheme.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LibraryTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: LibraryTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded,
                color: LibraryTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تم الرفع بواسطة',
                  style: TextStyle(fontSize: 11, color: LibraryTheme.muted),
                ),
                Text(
                  file.uploaderName.isNotEmpty
                      ? file.uploaderName
                      : 'مستخدم غير معروف',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (file.uploaderUsername.isNotEmpty)
                  Text(
                    '@${file.uploaderUsername}',
                    style: const TextStyle(
                        color: LibraryTheme.primary, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MainActionButtons extends StatefulWidget {
  final FileModel file;
  final VoidCallback onPreviewPdf;

  const _MainActionButtons({required this.file, required this.onPreviewPdf});

  @override
  State<_MainActionButtons> createState() => _MainActionButtonsState();
}

class _MainActionButtonsState extends State<_MainActionButtons> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isDownloadedLocally = false;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _checkLocalState();
  }

  void _checkLocalState() {
    final localPath = LibraryLocalDownloadService.getLocalPath(widget.file.id);
    setState(() {
      _localPath = localPath;
      _isDownloadedLocally = localPath != null;
    });
  }

  Future<void> _handleLocalDownload() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
      );
      return;
    }

    if (widget.file.fileUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رابط الملف غير متاح للتحميل')),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      await LibraryLocalDownloadService.downloadAndSaveFile(
        fileId: widget.file.id,
        title: widget.file.title,
        fileUrl: widget.file.fileUrl,
        fileType: widget.file.fileType,
        course: widget.file.course,
        author: widget.file.author,
      );

      await LibraryReactionsService.registerDownload(widget.file.id);

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 1.0;
        });
        _checkLocalState();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم تنزيل الملف بنجاح، تجده في تنزيلاتي')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء التنزيل: $e')),
        );
      }
    }
  }

  Future<void> _openExternal() async {
    if (widget.file.fileUrl.trim().isEmpty) return;
    final uri = Uri.parse(widget.file.fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن فتح الرابط')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (widget.file.isPdf) ...[
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: widget.onPreviewPdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LibraryTheme.surface,
                  foregroundColor: LibraryTheme.danger,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                        color: LibraryTheme.danger.withOpacity(0.3)),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.remove_red_eye_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'تصفح',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isDownloading
                        ? null
                        : (_isDownloadedLocally
                        ? _openExternal
                        : _handleLocalDownload),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LibraryTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: LibraryTheme.primary.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isDownloading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                        else ...[
                          Icon(
                            _isDownloadedLocally
                                ? Icons.open_in_new_rounded
                                : Icons.file_download_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isDownloading
                                ? 'جاري التنزيل...'
                                : _isDownloadedLocally
                                ? 'فتح الملف'
                                : 'تنزيل الجهاز',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_isDownloading)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: _downloadProgress > 0 ? _downloadProgress : null,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white),
                      minHeight: 3,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
