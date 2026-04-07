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
      LibraryReactionsService.registerViewOnce(widget.file.id);    }}

  String _formatDate(DateTime? date) {
    if (date == null) return 'ط؛ظٹط± ظ…ط­ط¯ط¯';
    return '${date.year}/${date.month}/${date.day}';
  }

  String? _normalizeCollege(String? college) {
    if (college == null) return null;
    switch (college.trim()) {
      case 'ظƒظ„ظٹط© ط§ظ„ظ‡ظ†ط¯ط³ط©':
        return 'ظƒظ„ظٹط© ط§ظ„ظ‡ظ†ط¯ط³ط© ظˆطھظƒظ†ظˆظ„ظˆط¬ظٹط§ ط§ظ„ظ…ط¹ظ„ظˆظ…ط§طھ';
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
      _snack('ظ„ط§ ظٹظˆط¬ط¯ ط±ط§ط¨ط· ظ„ظ„ظ…ظ„ظپ');
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
                  color: LibraryTheme.border(context),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: LibraryTheme.primary(context).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: LibraryTheme.primary(context),
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'ظ…ظ„ظپ Word',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: LibraryTheme.text(context),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ظ‡ط°ط§ ط§ظ„ظ†ظˆط¹ ظ„ط§ ظٹظڈط¹ط±ط¶ ط¯ط§ط®ظ„ ط§ظ„طھط·ط¨ظٹظ‚ ط­ط§ظ„ظٹظ‹ط§.\nط§ط®طھط± ظپطھط­ظ‡ ط®ط§ط±ط¬ظٹظ‹ط§ ط£ظˆ طھظ†ط²ظٹظ„ظ‡.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.2,
                  color: LibraryTheme.muted(context),
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
                        foregroundColor: LibraryTheme.primary(context),
                        side: const BorderSide(color: LibraryTheme.primary(context)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('طھظ†ط²ظٹظ„'),
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
                          _snack('طھط¹ط°ط± ظپطھط­ ط§ظ„ظ…ظ„ظپ');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LibraryTheme.primary(context),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('ظپطھط­ ط®ط§ط±ط¬ظٹ'),
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
      _snack('ظ„ط§ ظٹظˆط¬ط¯ ط±ط§ط¨ط· ظ„ظ…ط´ط§ط±ظƒط© ط§ظ„ظ…ظ„ظپ');
      return;
    }

    try {
      await LibraryReactionsService.registerShare(widget.file.id);
      final text = '''
ًں“ک ${widget.file.title}

ط§ظ„ط¯ظƒطھظˆط±: ${widget.file.author}
ط§ظ„ظ…ط§ط¯ط©: ${widget.file.course}
ط§ظ„ظƒظ„ظٹط©: ${widget.file.college}
ط§ظ„طھط®طµطµ: ${widget.file.major}
ط§ظ„ظ…ط³طھظˆظ‰: ${widget.file.semester}

$url
''';
      await Share.share(text);
    } catch (e) {
      _snack('طھط¹ط°ط± طھط³ط¬ظٹظ„ ط§ظ„ظ…ط´ط§ط±ظƒط©: $e');
    }
  }

  Future<void> _downloadFile(String url) async {
    if (url.trim().isEmpty) {
      _snack('ظ„ط§ ظٹظˆط¬ط¯ ط±ط§ط¨ط· ظ„ظ„طھظ†ط²ظٹظ„');
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
        _snack('طھظ… طھظ†ط²ظٹظ„ ط§ظ„ظ…ظ„ظپ ظˆط­ظپط¸ظ‡ ط¯ط§ط®ظ„ ط§ظ„طھط·ط¨ظٹظ‚');
      }
    } catch (e) {
      _snack('ظپط´ظ„ ط§ظ„طھظ†ط²ظٹظ„: $e');
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
                          color: LibraryTheme.border(context),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Text(
                            'طھط¹ط¯ظٹظ„ ط§ظ„ظ…ظ„ظپ',
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
                        label: 'ط§ط³ظ… ط§ظ„ظ…ط§ط¯ط© / ط§ظ„ط¹ظ†ظˆط§ظ†',
                        icon: Icons.menu_book_rounded,
                      ),
                      const SizedBox(height: 12),
                      _ModernField(
                        controller: doctorController,
                        label: 'ط§ط³ظ… ط§ظ„ط¯ظƒطھظˆط±',
                        icon: Icons.person_rounded,
                      ),
                      const SizedBox(height: 12),
                      _ModernField(
                        controller: descriptionController,
                        label: 'ط§ظ„ظˆطµظپ',
                        icon: Icons.notes_rounded,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      _DropdownField(
                        value: selectedCollege,
                        hint: 'ط§ظ„ظƒظ„ظٹط©',
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
                        hint: 'ط§ظ„طھط®طµطµ',
                        icon: Icons.auto_awesome_mosaic_rounded,
                        items: majors,
                        onChanged: (value) => setModalState(() {
                          selectedSpecialization = value;
                        }),
                      ),
                      const SizedBox(height: 12),
                      _DropdownField(
                        value: selectedLevel,
                        hint: 'ط§ظ„ظ…ط³طھظˆظ‰',
                        icon: Icons.layers_rounded,
                        items: UniversityAcademicData.levels,
                        onChanged: (value) => setModalState(() {
                          selectedLevel = value;
                        }),
                      ),
                      const SizedBox(height: 12),
                      _DropdownField(
                        value: selectedTerm,
                        hint: 'ط§ظ„طھط±ظ…',
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
                              _snack('ط£ظƒظ…ظ„ ط¬ظ…ظٹط¹ ط§ظ„ط­ظ‚ظˆظ„ ط§ظ„ظ…ط·ظ„ظˆط¨ط©');
                              return;
                            }

                            setModalState(() => isSaving = true);

                            try {
                              await LibraryFilesService.updateLibraryFile(
                                fileId: widget.file.id,
                                subjectName: subjectController.text.trim(),
                                doctorName: doctorController.text.trim(),
                                description:
                                descriptionController.text.trim(),
                                college: selectedCollege!,
                                specialization:
                                selectedSpecialization!,
                                level: selectedLevel!,
                                term: selectedTerm!,
                              );

                              if (mounted) {
                                Navigator.pop(context);
                                _snack('طھظ… طھط­ط¯ظٹط« ط§ظ„ظ…ظ„ظپ');
                              }
                            } catch (e) {
                              _snack('ظپط´ظ„ ط§ظ„طھط¹ط¯ظٹظ„: $e');
                            } finally {
                              if (mounted) {
                                setModalState(() => isSaving = false);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LibraryTheme.primary(context),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: isSaving
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            'ط­ظپط¸ ط§ظ„طھط¹ط¯ظٹظ„ط§طھ',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
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

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ط­ط°ظپ ط§ظ„ظ…ظ„ظپ'),
        content: const Text('ظ‡ظ„ ط£ظ†طھ ظ…طھط£ظƒط¯طں'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ط¥ظ„ط؛ط§ط،'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ط­ط°ظپ',
              style: TextStyle(color: LibraryTheme.danger(context)),
            ),
          ),
        ],
      ),
    ) ??
        false;

    if (!shouldDelete) return;

    try {
      await LibraryFilesService.deleteLibraryFile(
        fileId: widget.file.id,
        storagePath: widget.file.storagePath ?? '',
      );
      if (mounted) {
        Navigator.pop(context);
        _snack('طھظ… ط­ط°ظپ ط§ظ„ظ…ظ„ظپ');
      }
    } catch (e) {
      _snack('ظپط´ظ„ ط­ط°ظپ ط§ظ„ظ…ظ„ظپ: $e');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LibraryTheme.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: LibraryTheme.primary(context).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 16, color: LibraryTheme.primary(context)),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.2,
              fontWeight: FontWeight.w700,
              color: LibraryTheme.text(context),
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.left,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(
                fontSize: 13.2,
                color: LibraryTheme.text(context).withOpacity(0.78),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label, int count, {Color? color}) {
    final effectiveColor = color ?? LibraryTheme.primary(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: effectiveColor, size: 16),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: LibraryTheme.muted(context),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUserId != null && currentUserId == widget.file.userId;
    final fileColor =
    widget.file.isPdf ? LibraryTheme.danger(context) : LibraryTheme.primary(context);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('library_files')
          .doc(widget.file.id)
          .snapshots(),
      builder: (context, snapshot) {
        final liveData = snapshot.data?.data() ?? <String, dynamic>{};

        int readCounter(String key, int fallback) {
          final value = liveData[key];
          if (value is int) return value;
          if (value is num) return value.toInt();
          return int.tryParse('${liveData[key] ?? fallback}') ?? fallback;
        }

        final updatedFile = widget.file.copyWith(
          likes: readCounter('likesCount', widget.file.likes),
          saves: readCounter('savesCount', widget.file.saves),
          downloads: readCounter('downloadsCount', widget.file.downloads),
          views: readCounter('viewsCount', widget.file.views),
          shares: readCounter('sharesCount', widget.file.shares),
          status: (liveData['status'] ?? widget.file.status).toString(),
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          body: Stack(
            children: [
              Positioned(
                top: -70,
                right: -50,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fileColor.withOpacity(0.06),
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _CircleAction(
                            icon: Icons.arrow_back_rounded,
                            onTap: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          if (isOwner) ...[
                            _CircleAction(
                              icon: Icons.edit_rounded,
                              onTap: _showEditSheet,
                            ),
                            const SizedBox(width: 8),
                            _CircleAction(
                              icon: Icons.delete_outline_rounded,
                              color: LibraryTheme.danger(context),
                              onTap: _confirmDelete,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              fileColor.withOpacity(0.05),
                            ],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: LibraryTheme.border(context)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        fileColor.withOpacity(0.16),
                                        fileColor.withOpacity(0.08),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    updatedFile.isPdf
                                        ? Icons.picture_as_pdf_rounded
                                        : Icons.description_rounded,
                                    color: fileColor,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: fileColor.withOpacity(0.08),
                                          borderRadius:
                                          BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          updatedFile.fileType,
                                          style: TextStyle(
                                            color: fileColor,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        updatedFile.title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          height: 1.3,
                                          fontWeight: FontWeight.w800,
                                          color: LibraryTheme.text(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'ط¯. ${updatedFile.author}',
                              style: const TextStyle(
                                fontSize: 14.5,
                                color: LibraryTheme.muted(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ط±ظپط¹ظ‡: ${updatedFile.displayUploader}',
                              style: const TextStyle(
                                fontSize: 12.8,
                                color: LibraryTheme.muted(context),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _statItem(
                                    Icons.visibility_outlined,
                                    'ظ…ط´ط§ظ‡ط¯ط©',
                                    updatedFile.views,
                                    color: LibraryTheme.primary(context),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _statItem(
                                    Icons.download_rounded,
                                    'طھظ†ط²ظٹظ„',
                                    updatedFile.downloads,
                                    color: LibraryTheme.success(context),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _statItem(
                                    Icons.share_outlined,
                                    'ظ…ط´ط§ط±ظƒط©',
                                    updatedFile.shares,
                                    color: LibraryTheme.accent(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          StreamBuilder<bool>(
                            stream: LibraryReactionsService.isLikedStream(
                              widget.file.id,
                            ),
                            builder: (context, likeSnapshot) {
                              final liked = likeSnapshot.data ?? false;
                              return Expanded(
                                child: _ReactionButton(
                                  icon: liked
                                      ? Icons.thumb_up_alt_rounded
                                      : Icons.thumb_up_alt_outlined,
                                  label: 'ط¥ط¹ط¬ط§ط¨',
                                  count: updatedFile.likes,
                                  active: liked,
                                  onTap: () async {
                                    try {
                                      await LibraryReactionsService.toggleLike(
                                        fileId: widget.file.id,
                                        isCurrentlyLiked: liked,
                                      );
                                    } catch (e) {
                                      _snack('طھط¹ط°ط± طھظ†ظپظٹط° ط§ظ„ط¥ط¹ط¬ط§ط¨: $e');
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          StreamBuilder<bool>(
                            stream: LibraryReactionsService.isSavedStream(
                              widget.file.id,
                            ),
                            builder: (context, saveSnapshot) {
                              final saved = saveSnapshot.data ?? false;
                              return Expanded(
                                child: _ReactionButton(
                                  icon: saved
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  label: 'ط­ظپط¸',
                                  count: updatedFile.saves,
                                  active: saved,
                                  onTap: () async {
                                    try {
                                      await LibraryReactionsService.toggleSave(
                                        fileId: widget.file.id,
                                        isCurrentlySaved: saved,
                                      );
                                    } catch (e) {
                                      _snack('طھط¹ط°ط± طھظ†ظپظٹط° ط§ظ„ط­ظپط¸: $e');
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ReactionButton(
                              icon: Icons.share_outlined,
                              label: 'ظ…ط´ط§ط±ظƒط©',
                              count: updatedFile.shares,
                              active: false,
                              onTap: _shareFileExternally,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openFile(updatedFile.fileUrl),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: LibraryTheme.primary(context),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: const Icon(Icons.visibility_rounded, size: 18),
                              label: const Text('ظپطھط­ ط§ظ„ظ…ظ„ظپ'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _downloadFile(updatedFile.fileUrl),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: LibraryTheme.primary(context),
                                side: const BorderSide(color: LibraryTheme.primary(context)),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: const Icon(Icons.download_rounded, size: 18),
                              label: const Text('طھظ†ط²ظٹظ„'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (updatedFile.description.trim().isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: LibraryTheme.border(context)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ط§ظ„ظˆطµظپ',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                updatedFile.description,
                                style: TextStyle(
                                  fontSize: 14.2,
                                  color: LibraryTheme.text(context).withOpacity(0.82),
                                  height: 1.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: LibraryTheme.border(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ظ…ط¹ظ„ظˆظ…ط§طھ ط§ظ„ظ…ظ„ظپ',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoTile(
                              icon: Icons.menu_book_rounded,
                              label: 'ط§ظ„ظ…ط§ط¯ط©',
                              value: updatedFile.course,
                            ),
                            _buildInfoTile(
                              icon: Icons.account_balance_rounded,
                              label: 'ط§ظ„ظƒظ„ظٹط©',
                              value: updatedFile.college,
                            ),
                            _buildInfoTile(
                              icon: Icons.auto_awesome_mosaic_rounded,
                              label: 'ط§ظ„طھط®طµطµ',
                              value: updatedFile.major,
                            ),
                            _buildInfoTile(
                              icon: Icons.layers_rounded,
                              label: 'ط§ظ„ظ…ط³طھظˆظ‰',
                              value: updatedFile.semester,
                            ),
                            _buildInfoTile(
                              icon: Icons.description_rounded,
                              label: 'ط§ظ„ظ†ظˆط¹',
                              value: updatedFile.fileType,
                            ),
                            _buildInfoTile(
                              icon: Icons.verified_rounded,
                              label: 'ط§ظ„ط­ط§ظ„ط©',
                              value: _statusText(updatedFile.status),
                            ),
                            _buildInfoTile(
                              icon: Icons.calendar_today_rounded,
                              label: 'طھط§ط±ظٹط® ط§ظ„ط±ظپط¹',
                              value: _formatDate(updatedFile.createdAt),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _CircleAction({
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: LibraryTheme.border(context)),
        ),
        child: Icon(icon, size: 20, color: color ?? LibraryTheme.text(context)),
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? LibraryTheme.primary(context) : LibraryTheme.muted(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? LibraryTheme.primary(context).withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active
                ? LibraryTheme.primary(context).withOpacity(0.18)
                : LibraryTheme.border(context),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '$count',
              style: const TextStyle(
                color: LibraryTheme.muted(context),
                fontSize: 11.5,
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
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: LibraryTheme.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: LibraryTheme.primary(context),
            width: 1.4,
          ),
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
    final uniqueItems = items.toSet().toList();
    final safeValue =
    (value != null && uniqueItems.contains(value)) ? value : null;

    return DropdownButtonFormField<String>(
      value: safeValue,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: LibraryTheme.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: LibraryTheme.primary(context),
            width: 1.4,
          ),
        ),
      ),
      items: uniqueItems
          .map(
            (e) => DropdownMenuItem<String>(
          value: e,
          child: Text(
            e,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      )
          .toList(),
      onChanged: onChanged,
    );
  }
}
