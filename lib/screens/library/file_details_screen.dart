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
import 'university_academic_data.dart';

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

  String _formatDate(DateTime? date) {
    if (date == null) return 'غير محدد';
    return '${date.year}/${date.month}/${date.day}';
  }

  String? _normalizeCollege(String? college) {
    if (college == null) return null;
    switch (college.trim()) {
      case 'كلية الهندسة':
        return 'كلية الهندسة وتكنولوجيا المعلومات';
      default:
        return college.trim().isEmpty ? null : college.trim();
    }
  }

  String? _normalizeSpecialization(String? specialization) {
    if (specialization == null) return null;
    final value = specialization.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _openFile(String url) async {
    if (url.trim().isEmpty) {
      _snack('لا يوجد رابط للملف');
      return;
    }

    if (widget.file.isPdf) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            url: url,
            title: widget.file.title,
          ),
        ),
      );
      return;
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: LibraryTheme.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: LibraryTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: LibraryTheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'ملف Word',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: LibraryTheme.text,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'هذا النوع لا يُعرض داخل التطبيق حاليًا.\nاختر فتحه خارجيًا أو تنزيله.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.2,
                  color: LibraryTheme.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _downloadFile(url);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: LibraryTheme.primary,
                        side: const BorderSide(color: LibraryTheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('تنزيل'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        final uri = Uri.parse(url);
                        final launched = await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                        if (!launched && mounted) {
                          _snack('تعذر فتح الملف');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LibraryTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('فتح خارجي'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareFileExternally() async {
    final url = widget.file.fileUrl.trim();
    if (url.isEmpty) {
      _snack('لا يوجد رابط لمشاركة الملف');
      return;
    }

    try {
      await LibraryReactionsService.registerShare(widget.file.id);
      final text = '''
📘 ${widget.file.title}

الدكتور: ${widget.file.author}
المادة: ${widget.file.course}
الكلية: ${widget.file.college}
التخصص: ${widget.file.major}
المستوى: ${widget.file.semester}

$url
''';
      await Share.share(text);
    } catch (e) {
      _snack('تعذر تسجيل المشاركة: $e');
    }
  }

  Future<void> _downloadFile(String url) async {
    if (url.trim().isEmpty) {
      _snack('لا يوجد رابط للتنزيل');
      return;
    }

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
        _snack('تم تنزيل الملف وحفظه داخل التطبيق');
      }
    } catch (e) {
      _snack('فشل التنزيل: $e');
    }
  }

  Future<void> _showEditSheet() async {
    final fileDoc = await FirebaseFirestore.instance
        .collection('library_files')
        .doc(widget.file.id)
        .get();
    final data = fileDoc.data() ?? {};

    final subjectController = TextEditingController(
      text: (data['subjectName'] ?? widget.file.title).toString(),
    );
    final doctorController = TextEditingController(
      text: (data['doctorName'] ?? widget.file.author).toString(),
    );
    final descriptionController = TextEditingController(
      text: (data['description'] ?? widget.file.description).toString(),
    );

    String? selectedCollege = _normalizeCollege(
      (data['college'] ?? widget.file.college).toString(),
    );
    String? selectedSpecialization = _normalizeSpecialization(
      (data['specialization'] ?? widget.file.major).toString(),
    );
    String? selectedLevel = (data['level'] ?? '').toString().trim().isEmpty
        ? null
        : (data['level'] ?? '').toString().trim();
    String? selectedTerm = (data['term'] ?? '').toString().trim().isEmpty
        ? null
        : (data['term'] ?? '').toString().trim();

    final safeColleges = UniversityAcademicData.colleges.toSet().toList();
    if (selectedCollege != null && !safeColleges.contains(selectedCollege)) {
      selectedCollege = null;
    }

    final initialMajors = selectedCollege == null
        ? <String>[]
        : (UniversityAcademicData.majorsByCollege[selectedCollege] ?? <String>[])
            .toSet()
            .toList();

    if (selectedSpecialization != null &&
        !initialMajors.contains(selectedSpecialization)) {
      selectedSpecialization = null;
    }

    final safeLevels = UniversityAcademicData.levels.toSet().toList();
    if (selectedLevel != null && !safeLevels.contains(selectedLevel)) {
      selectedLevel = null;
    }

    final safeTerms = UniversityAcademicData.terms.toSet().toList();
    if (selectedTerm != null && !safeTerms.contains(selectedTerm)) {
      selectedTerm = null;
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final majors = selectedCollege == null
                ? <String>[]
                : (UniversityAcademicData.majorsByCollege[selectedCollege] ??
                        <String>[])
                    .toSet()
                    .toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
                decoration: const BoxDecoration(
                  color: Color(0xFFFDFEFF),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: LibraryTheme.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Text(
                            'تعديل الملف',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ModernField(
                        controller: subjectController,
                        label: 'اسم المادة / العنوان',
                        icon: Icons.menu_book_rounded,
                      ),
                      const SizedBox(height: 12),
                      _ModernField(
                        controller: doctorController,
                        label: 'اسم الدكتور',
                        icon: Icons.person_rounded,
                      ),
                      const SizedBox(height: 12),
                      _ModernField(
                        controller: descriptionController,
                        label: 'الوصف',
                        icon: Icons.notes_rounded,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      _DropdownField(
                        value: selectedCollege,
                        hint: 'الكلية',
                        icon: Icons.account_balance_rounded,
                        items: UniversityAcademicData.colleges,
                        onChanged: (value) => setModalState(() {
                          selectedCollege = value;
                          selectedSpecialization = null;
                        }),
                      ),
                      const SizedBox(height: 12),
                      _DropdownField(
                        value: selectedSpecialization,
                        hint: 'التخصص',
                        icon: Icons.auto_awesome_mosaic_rounded,
                        items: majors,
                        onChanged: (value) => setModalState(() {
                          selectedSpecialization = value;
                        }),
                      ),
                      const SizedBox(height: 12),
                      _DropdownField(
                        value: selectedLevel,
                        hint: 'المستوى',
                        icon: Icons.layers_rounded,
                        items: UniversityAcademicData.levels,
                        onChanged: (value) => setModalState(() {
                          selectedLevel = value;
                        }),
                      ),
                      const SizedBox(height: 12),
                      _DropdownField(
                        value: selectedTerm,
                        hint: 'الترم',
                        icon: Icons.calendar_month_rounded,
                        items: UniversityAcademicData.terms,
                        onChanged: (value) => setModalState(() {
                          selectedTerm = value;
                        }),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (subjectController.text.trim().isEmpty ||
                                      doctorController.text.trim().isEmpty ||
                                      selectedCollege == null ||
                                      selectedSpecialization == null ||
                                      selectedLevel == null ||
                                      selectedTerm == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('أكمل جميع الحقول المطلوبة'),
                                      ),
                                    );
                                    return;
                                  }

                                  setModalState(() => isSaving = true);
                                  try {
                                    await LibraryFilesService.updateLibraryFile(
                                      fileId: widget.file.id,
                                      subjectName: subjectController.text.trim(),
                                      doctorName: doctorController.text.trim(),
                                      description: descriptionController.text.trim(),
                                      college: selectedCollege!,
                                      specialization: selectedSpecialization!,
                                      level: selectedLevel!,
                                      term: selectedTerm!,
                                    );

                                    if (!mounted) return;
                                    Navigator.pop(context);
                                    _snack('تم تعديل الملف بنجاح');
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('فشل التعديل: $e')),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setModalState(() => isSaving = false);
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LibraryTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.3,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'حفظ التعديلات',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteFile() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('حذف الملف'),
            content: const Text('هل أنت متأكد أنك تريد حذف هذا الملف نهائيًا؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'حذف',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await LibraryFilesService.deleteLibraryFile(fileId: widget.file.id);
      if (!mounted) return;
      Navigator.pop(context);
      _snack('تم حذف الملف');
    } catch (e) {
      _snack('فشل الحذف: $e');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.file;
    final isOwner = FirebaseAuth.instance.currentUser?.uid == file.userId;

    return Scaffold(
      backgroundColor: LibraryTheme.bg,
      appBar: AppBar(
        title: const Text('تفاصيل الملف'),
        backgroundColor: LibraryTheme.surface,
        foregroundColor: LibraryTheme.text,
        elevation: 0,
        actions: [
          if (isOwner)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  await _showEditSheet();
                } else if (value == 'delete') {
                  await _deleteFile();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('تعديل'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('حذف'),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: LibraryTheme.surface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: LibraryTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: LibraryTheme.primary.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF5B8CFF),
                          Color(0xFF7B61FF),
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(26),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            file.isPdf
                                ? Icons.picture_as_pdf_rounded
                                : Icons.description_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                file.author,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.school_rounded,
                          label: 'الكلية',
                          value: file.college,
                        ),
                        _InfoRow(
                          icon: Icons.account_tree_rounded,
                          label: 'التخصص',
                          value: file.major,
                        ),
                        _InfoRow(
                          icon: Icons.layers_rounded,
                          label: 'المستوى / الترم',
                          value: file.semester,
                        ),
                        _InfoRow(
                          icon: Icons.person_outline_rounded,
                          label: 'الرافع',
                          value: file.displayUploader,
                        ),
                        _InfoRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'تاريخ الإضافة',
                          value: _formatDate(file.createdAt),
                        ),
                        _InfoRow(
                          icon: Icons.info_outline_rounded,
                          label: 'الحالة',
                          value: file.status,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LibraryTheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: LibraryTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الوصف',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: LibraryTheme.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    file.description.trim().isEmpty
                        ? 'لا يوجد وصف متاح لهذا الملف.'
                        : file.description,
                    style: const TextStyle(
                      fontSize: 14.2,
                      color: LibraryTheme.text,
                      height: 1.65,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<bool>(
              stream: LibraryReactionsService.isLikedStream(file.id),
              builder: (context, likedSnapshot) {
                final isLiked = likedSnapshot.data ?? false;
                return StreamBuilder<bool>(
                  stream: LibraryReactionsService.isSavedStream(file.id),
                  builder: (context, savedSnapshot) {
                    final isSaved = savedSnapshot.data ?? false;

                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _ActionButton(
                          icon: isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          label: isLiked ? 'تم الإعجاب' : 'إعجاب',
                          color: const Color(0xFFE11D48),
                          onTap: () async {
                            try {
                              await LibraryReactionsService.toggleLike(
                                fileId: file.id,
                                isCurrentlyLiked: isLiked,
                              );
                            } catch (e) {
                              _snack('تعذر تسجيل الإعجاب');
                            }
                          },
                        ),
                        _ActionButton(
                          icon: isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          label: isSaved ? 'تم الحفظ' : 'حفظ',
                          color: LibraryTheme.primary,
                          onTap: () async {
                            try {
                              await LibraryReactionsService.toggleSave(
                                fileId: file.id,
                                isCurrentlySaved: isSaved,
                              );
                            } catch (e) {
                              _snack('تعذر حفظ الملف');
                            }
                          },
                        ),
                        _ActionButton(
                          icon: Icons.share_rounded,
                          label: 'مشاركة',
                          color: LibraryTheme.accent,
                          onTap: _shareFileExternally,
                        ),
                        _ActionButton(
                          icon: Icons.download_rounded,
                          label: 'تنزيل',
                          color: LibraryTheme.success,
                          onTap: () => _downloadFile(file.fileUrl),
                        ),
                        _ActionButton(
                          icon: Icons.open_in_new_rounded,
                          label: 'فتح',
                          color: LibraryTheme.secondary,
                          onTap: () => _openFile(file.fileUrl),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _MetricCard(
                  icon: Icons.favorite_rounded,
                  label: 'الإعجابات',
                  value: file.likes.toString(),
                  color: const Color(0xFFE11D48),
                ),
                const SizedBox(width: 10),
                _MetricCard(
                  icon: Icons.visibility_rounded,
                  label: 'المشاهدات',
                  value: file.views.toString(),
                  color: LibraryTheme.primary,
                ),
                const SizedBox(width: 10),
                _MetricCard(
                  icon: Icons.download_rounded,
                  label: 'التنزيلات',
                  value: file.downloads.toString(),
                  color: LibraryTheme.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: LibraryTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: LibraryTheme.text,
                  fontSize: 14,
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: LibraryTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: LibraryTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: LibraryTheme.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: LibraryTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;

  const _ModernField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: LibraryTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: LibraryTheme.primary),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String? value;
  final String hint;
  final IconData icon;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeItems = items.toSet().toList();
    final safeValue = safeItems.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      value: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon, size: 19),
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: LibraryTheme.border),
        ),
      ),
      items: safeItems
          .map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
