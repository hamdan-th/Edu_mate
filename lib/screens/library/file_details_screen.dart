import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import 'library_local_download_service.dart';
import 'file_model.dart';
import 'library_files_service.dart';
import 'library_reactions_service.dart';
import 'library_theme.dart';
import 'pdf_preview_screen.dart';
import 'university_academic_data.dart';
import '../../services/group_service.dart';
import '../../models/group_model.dart';
import '../../l10n/app_localizations.dart';

class FileDetailsScreen extends StatefulWidget {
  final FileModel file;
  const FileDetailsScreen({super.key, required this.file});

  @override
  State<FileDetailsScreen> createState() => _FileDetailsScreenState();
}

class _FileDetailsScreenState extends State<FileDetailsScreen> {
  bool _viewRegistered = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _bg => _isDark ? const Color(0xFF0B0D12) : const Color(0xFFF7F9FC);
  Color get _surface => _isDark ? const Color(0xFF171C25) : Colors.white;
  Color get _surfaceSoft =>
      _isDark ? const Color(0xFF10141C) : const Color(0xFFF8FAFD);
  Color get _text => _isDark ? AppColors.textPrimary : Colors.black87;
  Color get _muted => _isDark ? AppColors.textSecondary : Colors.black54;
  Color get _border =>
      _isDark ? Colors.white.withOpacity(0.07) : Colors.black12;
  Color get _heroPink =>
      _isDark ? const Color(0xFF2A1E24) : const Color(0xFFF8DDE1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_viewRegistered) {
      _viewRegistered = true;
      LibraryReactionsService.registerViewOnce(widget.file.id);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return AppLocalizations.of(context)!.detailsUnspecified;
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
      _snack(AppLocalizations.of(context)!.myFilesNoLink);
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
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: _border,
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
                child: Icon(
                  Icons.description_rounded,
                  color: LibraryTheme.primary(context),
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                AppLocalizations.of(context)!.detailsWordFile,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.detailsNoPreview,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.2,
                  color: _muted,
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
                        side: BorderSide(color: LibraryTheme.primary(context)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text(AppLocalizations.of(context)!.detailsDownloadBtn),
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
                          _snack(AppLocalizations.of(context)!.myFilesCannotOpen);
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
                      label: Text(AppLocalizations.of(context)!.detailsOpenExternalBtn),
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

  Future<void> _shareFileToGroup() async {
    final url = widget.file.fileUrl.trim();
    if (url.isEmpty) {
      _snack(AppLocalizations.of(context)!.detailsNoShareLink);
      return;
    }

    try {
      final groups = await GroupService.streamMyGroups().first;

      if (!mounted) return;

      if (groups.isEmpty) {
        _snack(AppLocalizations.of(context)!.detailsNoGroupsJoined);
        return;
      }

      final GroupModel? selectedGroup = await showModalBottomSheet<GroupModel>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.72,
            ),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.groups_rounded,
                      color: LibraryTheme.primary(context),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.detailsShareToGroups,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    AppLocalizations.of(context)!.detailsSelectGroup,
                    style: TextStyle(
                      fontSize: 13,
                      color: _muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: groups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return InkWell(
                        onTap: () => Navigator.pop(context, group),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _surfaceSoft,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _border),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                LibraryTheme.primary(context).withOpacity(0.1),
                                backgroundImage: group.imageUrl.isNotEmpty
                                    ? NetworkImage(group.imageUrl)
                                    : null,
                                child: group.imageUrl.isEmpty
                                    ? Text(
                                  group.name.isNotEmpty
                                      ? group.name.substring(0, 1).toUpperCase()
                                      : 'G',
                                  style: TextStyle(
                                    color: LibraryTheme.primary(context),
                                    fontWeight: FontWeight.w800,
                                  ),
                                )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: _text,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      group.specializationName.isNotEmpty
                                          ? group.specializationName
                                          : group.collegeName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: _muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: _muted,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (selectedGroup == null) return;

      await GroupService.shareLibraryFileToGroup(
        groupId: selectedGroup.id,
        fileId: widget.file.id,
        fileTitle: widget.file.title,
        fileUrl: widget.file.fileUrl,
        fileType: widget.file.fileType,
        ownerId: widget.file.userId,
      );

      await LibraryReactionsService.registerShare(widget.file.id);

      if (!mounted) return;
      _snack(AppLocalizations.of(context)!.detailsShareSuccess(selectedGroup.name));
    } catch (e) {
      _snack(AppLocalizations.of(context)!.detailsShareFailure(e.toString()));
    }
  }

  Future<void> _shareFileExternally() async {
    final url = widget.file.fileUrl.trim();
    if (url.isEmpty) {
      _snack(AppLocalizations.of(context)!.detailsNoShareLink);
      return;
    }

    try {
      await LibraryReactionsService.registerShare(widget.file.id);
      final l10n = AppLocalizations.of(context)!;
      final text = '''
📘 ${widget.file.title}

${l10n.upLabelDoctorName}: ${widget.file.author}
${AppLocalizations.of(context)!.detailsInfoCourse}: ${widget.file.course}
${AppLocalizations.of(context)!.detailsInfoCollege}: ${widget.file.college}
${AppLocalizations.of(context)!.detailsInfoSpecialization}: ${widget.file.major}
${AppLocalizations.of(context)!.detailsInfoLevel}: ${widget.file.semester}

$url
''';
      await Share.share(text);
    } catch (e) {
      _snack(AppLocalizations.of(context)!.detailsShareGeneralFailure(e.toString()));
    }
  }

  Future<void> _downloadFile(String url) async {
    if (url.trim().isEmpty) {
      _snack(AppLocalizations.of(context)!.myFilesNoLink);
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
        _snack(AppLocalizations.of(context)!.detailsDownloadSuccess);
      }
    } catch (e) {
      _snack(AppLocalizations.of(context)!.detailsDownloadFailure(e.toString()));
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
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.detailsEditTitle,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _text,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ModernField(
                        controller: subjectController,
                        label: AppLocalizations.of(context)!.upLabelSubjectName,
                        icon: Icons.menu_book_rounded,
                        isDark: _isDark,
                        textColor: _text,
                        borderColor: _border,
                        fillColor: _surfaceSoft,
                      ),
                      const SizedBox(height: 12),
                      _ModernField(
                        controller: doctorController,
                        label: AppLocalizations.of(context)!.upLabelDoctorName,
                        icon: Icons.person_rounded,
                        isDark: _isDark,
                        textColor: _text,
                        borderColor: _border,
                        fillColor: _surfaceSoft,
                      ),
                      const SizedBox(height: 12),
                      _ModernField(
                        controller: descriptionController,
                        label: AppLocalizations.of(context)!.detailsSectionDescription,
                        icon: Icons.notes_rounded,
                        maxLines: 4,
                        isDark: _isDark,
                        textColor: _text,
                        borderColor: _border,
                        fillColor: _surfaceSoft,
                      ),
                      const SizedBox(height: 12),
                      _DropdownField(
                        value: selectedCollege,
                        hint: AppLocalizations.of(context)!.upLabelCollege,
                        icon: Icons.account_balance_rounded,
                        items: UniversityAcademicData.colleges,
                        textColor: _text,
                        borderColor: _border,
                        fillColor: _surfaceSoft,
                        onChanged: (value) => setModalState(() {
                          selectedCollege = value;
                          selectedSpecialization = null;
                        }),
                      ),
                      const SizedBox(height: 12),
                      _DropdownField(
                        value: selectedSpecialization,
                        hint: AppLocalizations.of(context)!.upLabelMajor,
                        icon: Icons.auto_awesome_mosaic_rounded,
                        items: majors,
                        textColor: _text,
                        borderColor: _border,
                        fillColor: _surfaceSoft,
                        onChanged: (value) => setModalState(() {
                          selectedSpecialization = value;
                        }),
                      ),
                      const SizedBox(height: 12),
                      _DropdownField(
                        value: selectedLevel,
                        hint: AppLocalizations.of(context)!.upLabelLevel,
                        icon: Icons.layers_rounded,
                        items: UniversityAcademicData.levels,
                        textColor: _text,
                        borderColor: _border,
                        fillColor: _surfaceSoft,
                        onChanged: (value) => setModalState(() {
                          selectedLevel = value;
                        }),
                      ),
                      const SizedBox(height: 12),
                      _DropdownField(
                        value: selectedTerm,
                        hint: AppLocalizations.of(context)!.upLabelTerm,
                        icon: Icons.calendar_month_rounded,
                        items: UniversityAcademicData.terms,
                        textColor: _text,
                        borderColor: _border,
                        fillColor: _surfaceSoft,
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
                              _snack(AppLocalizations.of(context)!.detailsFillRequiredFields);
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
                                specialization: selectedSpecialization!,
                                level: selectedLevel!,
                                term: selectedTerm!,
                              );

                              if (mounted) {
                                Navigator.pop(context);
                                _snack(AppLocalizations.of(context)!.detailsEditSuccess);
                              }
                            } catch (e) {
                              _snack(AppLocalizations.of(context)!.detailsEditFailure(e.toString()));
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
                              : Text(
                            AppLocalizations.of(context)!.detailsBtnSaveEdits,
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
        backgroundColor: _surface,
        title: Text(
          AppLocalizations.of(context)!.detailsDeleteTitle,
          style: TextStyle(color: _text),
        ),
        content: Text(
          AppLocalizations.of(context)!.detailsDeleteConfirm,
          style: TextStyle(color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.detailsBtnCancel,
              style: TextStyle(color: _muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.detailsBtnDelete,
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
        _snack(AppLocalizations.of(context)!.detailsDeleteSuccess);
      }
    } catch (e) {
      _snack(AppLocalizations.of(context)!.detailsDeleteFailure(e.toString()));
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
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
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _border,
          width: 0.6,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: LibraryTheme.primary(context).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 16,
              color: LibraryTheme.primary(context),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.2,
              fontWeight: FontWeight.w800,
              color: _text,
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
                color: _muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(
      IconData icon,
      String label,
      int count, {
        Color? color,
      }) {
    final effectiveColor = color ?? LibraryTheme.primary(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(icon, color: effectiveColor, size: 18),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: _text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.2,
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool filled,
  }) {
    final primary = LibraryTheme.primary(context);

    if (filled) {
      return Expanded(
        child: ElevatedButton.icon(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: Icon(icon, size: 18),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      );
    }

    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) { final l10n = AppLocalizations.of(context)!;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner =
        currentUserId != null && currentUserId == widget.file.userId;
    final fileColor = widget.file.isPdf
        ? LibraryTheme.danger(context)
        : LibraryTheme.primary(context);

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
          backgroundColor: _bg,
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
                    color: fileColor.withOpacity(_isDark ? 0.05 : 0.06),
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
                            backgroundColor: _surface,
                            borderColor: _border,
                            iconColor: _text,
                          ),
                          const Spacer(),
                          if (isOwner) ...[
                            _CircleAction(
                              icon: Icons.edit_rounded,
                              onTap: _showEditSheet,
                              backgroundColor: _surface,
                              borderColor: _border,
                              iconColor: _text,
                            ),
                            const SizedBox(width: 8),
                            _CircleAction(
                              icon: Icons.delete_outline_rounded,
                              color: LibraryTheme.danger(context),
                              onTap: _confirmDelete,
                              backgroundColor: _surface,
                              borderColor: _border,
                              iconColor: LibraryTheme.danger(context),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _heroPink,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _border,
                            width: 0.6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(_isDark ? 0.14 : 0.03),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        fileColor.withOpacity(0.16),
                                        fileColor.withOpacity(0.08),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    updatedFile.isPdf
                                        ? Icons.picture_as_pdf_rounded
                                        : Icons.description_rounded,
                                    color: fileColor,
                                    size: 26,
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
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        updatedFile.title,
                                        style: TextStyle(
                                          fontSize: 20,
                                          height: 1.35,
                                          fontWeight: FontWeight.w900,
                                          color: _text,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              l10n.detailsPrefixDr(updatedFile.author),
                              style: TextStyle(
                                fontSize: 14.5,
                                color: _muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.detailsUploaderPrefix(updatedFile.displayUploader),
                              style: TextStyle(
                                fontSize: 12.8,
                                color: _muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _statItem(
                                    Icons.visibility_outlined,
                                    l10n.detailsStatViews,
                                    updatedFile.views,
                                    color: LibraryTheme.primary(context),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _statItem(
                                    Icons.download_rounded,
                                    l10n.detailsStatDownloads,
                                    updatedFile.downloads,
                                    color: LibraryTheme.success(context),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _statItem(
                                    Icons.share_outlined,
                                    l10n.detailsStatShares,
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
                      SizedBox(
                        width: double.infinity,
                        child: _actionButton(
                          icon: Icons.groups_rounded,
                          label: l10n.detailsShareToGroups,
                          onTap: _shareFileToGroup,
                          filled: false,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                                  label: l10n.detailsLikeAction,
                                  count: updatedFile.likes,
                                  active: liked,
                                  onTap: () async {
                                    try {
                                      await LibraryReactionsService.toggleLike(
                                        fileId: widget.file.id,
                                        isCurrentlyLiked: liked,
                                      );
                                    } catch (e) {
                                      _snack(l10n.detailsLikeFailure(e.toString()));
                                    }
                                  },
                                  isDark: _isDark,
                                  surfaceColor: _surface,
                                  borderColor: _border,
                                  mutedColor: _muted,
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
                                  label: l10n.detailsSaveAction,
                                  count: updatedFile.saves,
                                  active: saved,
                                  onTap: () async {
                                    try {
                                      await LibraryReactionsService.toggleSave(
                                        fileId: widget.file.id,
                                        isCurrentlySaved: saved,
                                      );
                                    } catch (e) {
                                      _snack(l10n.detailsSaveFailure(e.toString()));
                                    }
                                  },
                                  isDark: _isDark,
                                  surfaceColor: _surface,
                                  borderColor: _border,
                                  mutedColor: _muted,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ReactionButton(
                              icon: Icons.share_outlined,
                              label: l10n.detailsStatShares,
                              count: updatedFile.shares,
                              active: false,
                              onTap: _shareFileExternally,
                              isDark: _isDark,
                              surfaceColor: _surface,
                              borderColor: _border,
                              mutedColor: _muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _actionButton(
                            icon: Icons.visibility_rounded,
                            label: l10n.detailsActionOpenFile,
                            onTap: () => _openFile(updatedFile.fileUrl),
                            filled: true,
                          ),
                          const SizedBox(width: 10),
                          _actionButton(
                            icon: Icons.download_rounded,
                            label: l10n.detailsDownloadBtn,
                            onTap: () => _downloadFile(updatedFile.fileUrl),
                            filled: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (updatedFile.description.trim().isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _border,
                              width: 0.6,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.notes_rounded,
                                    color: LibraryTheme.primary(context),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.detailsSectionDescription,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: _text,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                updatedFile.description,
                                style: TextStyle(
                                  fontSize: 14.2,
                                  color: _muted,
                                  height: 1.7,
                                  fontWeight: FontWeight.w500,
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
                          color: _surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _border,
                            width: 0.6,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: _text,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.detailsSectionFileInfo,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: _text,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoTile(
                              icon: Icons.menu_book_rounded,
                              label: l10n.detailsInfoCourse,
                              value: updatedFile.course,
                            ),
                            _buildInfoTile(
                              icon: Icons.account_balance_rounded,
                              label: l10n.detailsInfoCollege,
                              value: updatedFile.college,
                            ),
                            _buildInfoTile(
                              icon: Icons.auto_awesome_mosaic_rounded,
                              label: l10n.detailsInfoSpecialization,
                              value: updatedFile.major,
                            ),
                            _buildInfoTile(
                              icon: Icons.layers_rounded,
                              label: l10n.detailsInfoLevel,
                              value: updatedFile.semester,
                            ),
                            _buildInfoTile(
                              icon: Icons.description_rounded,
                              label: l10n.detailsInfoType,
                              value: updatedFile.fileType,
                            ),
                            _buildInfoTile(
                              icon: Icons.verified_rounded,
                              label: l10n.detailsInfoStatus,
                              value: _statusText(updatedFile.status, l10n),
                            ),
                            _buildInfoTile(
                              icon: Icons.calendar_today_rounded,
                              label: l10n.detailsInfoDate,
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

  static String _statusText(String status, AppLocalizations l10n) {
    switch (status) {
      case 'approved':
        return l10n.detailsStatusApproved;
      case 'pending':
        return l10n.detailsStatusPending;
      case 'rejected':
        return l10n.detailsStatusRejected;
      default:
        return status;
    }
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;

  const _CircleAction({
    required this.icon,
    required this.onTap,
    this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) { final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 0.6,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: color ?? iconColor,
        ),
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
  final bool isDark;
  final Color surfaceColor;
  final Color borderColor;
  final Color mutedColor;

  const _ReactionButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
    required this.isDark,
    required this.surfaceColor,
    required this.borderColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) { final l10n = AppLocalizations.of(context)!;
    final color = active ? LibraryTheme.primary(context) : mutedColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? LibraryTheme.primary(context)
              .withOpacity(isDark ? 0.16 : 0.08)
              : surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active
                ? LibraryTheme.primary(context).withOpacity(0.25)
                : borderColor,
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
              style: TextStyle(
                color: mutedColor,
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
  final bool isDark;
  final Color textColor;
  final Color borderColor;
  final Color fillColor;

  const _ModernField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    required this.isDark,
    required this.textColor,
    required this.borderColor,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) { final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? AppColors.textSecondary : Colors.black54,
        ),
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
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
  final Color textColor;
  final Color borderColor;
  final Color fillColor;

  const _DropdownField({
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
    required this.textColor,
    required this.borderColor,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) { final l10n = AppLocalizations.of(context)!;
    final uniqueItems = items.toSet().toList();
    final safeValue =
    (value != null && uniqueItems.contains(value)) ? value : null;

    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      style: TextStyle(color: textColor),
      dropdownColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF171C25)
          : Colors.white,
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.textSecondary
              : Colors.black54,
        ),
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
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
