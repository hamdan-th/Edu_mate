import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'library_theme.dart';
import 'library_upload_service.dart';
import 'university_academic_data.dart';
import '../../l10n/app_localizations.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectNameController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedFile;
  bool _isUploading = false;

  String? _selectedCollege;
  String? _selectedSpecialization;
  String? _selectedLevel;
  String? _selectedTerm;

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

  @override
  void dispose() {
    _subjectNameController.dispose();
    _doctorNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _selectedFile = File(result.files.single.path!));
      }
    } catch (e) {
      if (mounted) _showSnackBar(AppLocalizations.of(context)!.upErrorFilePick);
    }
  }

  Future<void> _submitForm() async {
    if (_isUploading) return;

    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedFile == null) {
      _showSnackBar(l10n.upErrorSelectFileFirst);
      return;
    }

    if (_selectedCollege == null ||
        _selectedSpecialization == null ||
        _selectedLevel == null ||
        _selectedTerm == null) {
      _showSnackBar(l10n.upErrorFillRequired);
      return;
    }

    if (FirebaseAuth.instance.currentUser == null) {
      _showSnackBar(l10n.upErrorLoginRequired);
      return;
    }

    final normalizedCollege = _normalizeCollege(_selectedCollege);

    if (normalizedCollege == null) {
      _showSnackBar(l10n.upErrorInvalidCollege);
      return;
    }

    try {
      setState(() => _isUploading = true);

      await LibraryUploadService.uploadLibraryFile(
        file: _selectedFile!,
        subjectName: _subjectNameController.text.trim(),
        doctorName: _doctorNameController.text.trim(),
        description: _descriptionController.text.trim(),
        college: normalizedCollege,
        specialization: _selectedSpecialization!,
        level: _selectedLevel!,
        term: _selectedTerm!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.upSuccessUploaded),
          ),
        );

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _showSnackBar(l10n.upErrorUploadFailed);
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  String _fileName(File file) {
    final path = file.path.replaceAll('\\', '/');
    return path.split('/').last;
  }

  String _fileTypeLabel(File file, AppLocalizations l10n) {
    final name = _fileName(file).toLowerCase();
    if (name.endsWith('.pdf')) return l10n.upFileTypePdf;
    if (name.endsWith('.doc') || name.endsWith('.docx')) return l10n.upFileTypeWord;
    if (name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg')) {
      return l10n.upFileTypeImage;
    }
    return l10n.upFileTypeGeneric;
  }

  IconData _fileTypeIcon(File file) {
    final name = _fileName(file).toLowerCase();
    if (name.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (name.endsWith('.doc') || name.endsWith('.docx')) {
      return Icons.description_rounded;
    }
    if (name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg')) {
      return Icons.image_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final normalizedCollege = _normalizeCollege(_selectedCollege);
    final normalizedSpecialization =
    _normalizeSpecialization(_selectedSpecialization);

    final specializations = normalizedCollege == null
        ? <String>[]
        : (UniversityAcademicData.majorsByCollege[normalizedCollege] ??
        <String>[])
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LibraryTheme.primary(context).withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            top: 140,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LibraryTheme.secondary(context).withOpacity(0.05),
              ),
            ),
          ),
          SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopBar(
                      onBack: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 14),
                    const _HeroUploadCard(),
                    const SizedBox(height: 18),
                    _FilePickerCard(
                      selectedFile: _selectedFile,
                      onTap: _pickFile,
                      fileNameBuilder: _fileName,
                      fileTypeLabelBuilder: _fileTypeLabel,
                      fileTypeIconBuilder: _fileTypeIcon,
                    ),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: l10n.upSectionFileDetailsTitle,
                      subtitle: l10n.upSectionFileDetailsSubtitle,
                      child: Column(
                        children: [
                          _ModernTextField(
                            controller: _subjectNameController,
                            label: l10n.upLabelSubjectName,
                            icon: Icons.menu_book_rounded,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return l10n.upErrorFieldRequired;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _ModernTextField(
                            controller: _doctorNameController,
                            label: l10n.upLabelDoctorName,
                            icon: Icons.person_rounded,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return l10n.upErrorFieldRequired;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _ModernTextField(
                            controller: _descriptionController,
                            label: l10n.upLabelDescription,
                            icon: Icons.notes_rounded,
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: l10n.upSectionAcademicTitle,
                      subtitle: l10n.upSectionAcademicSubtitle,
                      child: Column(
                        children: [
                          _ModernDropdown(
                            value: normalizedCollege,
                            label: l10n.upLabelCollege,
                            icon: Icons.account_balance_rounded,
                            items: UniversityAcademicData.colleges,
                            onChanged: (value) => setState(() {
                              _selectedCollege = value;
                              _selectedSpecialization = null;
                            }),
                          ),
                          const SizedBox(height: 12),
                          _ModernDropdown(
                            value: normalizedSpecialization,
                            label: l10n.upLabelMajor,
                            icon: Icons.auto_awesome_mosaic_rounded,
                            items: specializations,
                            onChanged: (value) =>
                                setState(() => _selectedSpecialization = value),
                          ),
                          const SizedBox(height: 12),
                          _ModernDropdown(
                            value: _selectedLevel,
                            label: l10n.upLabelLevel,
                            icon: Icons.layers_rounded,
                            items: UniversityAcademicData.levels,
                            onChanged: (value) =>
                                setState(() => _selectedLevel = value),
                          ),
                          const SizedBox(height: 12),
                          _ModernDropdown(
                            value: _selectedTerm,
                            label: l10n.upLabelTerm,
                            icon: Icons.calendar_month_rounded,
                            items: UniversityAcademicData.terms,
                            onChanged: (value) =>
                                setState(() => _selectedTerm = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LibraryTheme.primary(context),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                          LibraryTheme.primary(context).withOpacity(0.55),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _isUploading
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_upload_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              l10n.upBtnUploadNow,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        l10n.upHintDirectUpload,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: LibraryTheme.muted(context),
                          fontSize: 12.8,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: LibraryTheme.border(context).withOpacity(0.3),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        const Spacer(),
        Text(
          AppLocalizations.of(context)!.upTitleNewUpload,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: LibraryTheme.text(context),
          ),
        ),
      ],
    );
  }
}

class _HeroUploadCard extends StatelessWidget {
  const _HeroUploadCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF5B8CFF),
            Color(0xFF7B61FF),
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B61FF).withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeroIconBox(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.upHeroTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.upHeroSubtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.4,
                    height: 1.5,
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

class _HeroIconBox extends StatelessWidget {
  const _HeroIconBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: const Icon(
        Icons.upload_file_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

class _FilePickerCard extends StatelessWidget {
  final File? selectedFile;
  final VoidCallback onTap;
  final String Function(File file) fileNameBuilder;
  final String Function(File file, AppLocalizations l10n) fileTypeLabelBuilder;
  final IconData Function(File file) fileTypeIconBuilder;

  const _FilePickerCard({
    required this.selectedFile,
    required this.onTap,
    required this.fileNameBuilder,
    required this.fileTypeLabelBuilder,
    required this.fileTypeIconBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasFile = selectedFile != null;

    return _SectionCard(
      title: l10n.upSectionFileTitle,
      subtitle: l10n.upSectionFileSubtitle,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: DottedBorder(
          borderType: BorderType.RRect,
          radius: const Radius.circular(22),
          dashPattern: const [8, 5],
          color: hasFile
              ? LibraryTheme.primary(context).withOpacity(0.45)
              : LibraryTheme.border(context),
          strokeWidth: 1.5,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: LibraryTheme.bg(context),
              borderRadius: BorderRadius.circular(22),
            ),
            child: hasFile
                ? Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        LibraryTheme.primary(context).withOpacity(0.16),
                        LibraryTheme.secondary(context).withOpacity(0.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    fileTypeIconBuilder(selectedFile!),
                    color: LibraryTheme.primary(context),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                    LibraryTheme.primary(context).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    fileTypeLabelBuilder(selectedFile!, l10n),
                    style: TextStyle(
                      color: LibraryTheme.primary(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  fileNameBuilder(selectedFile!),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.6,
                    fontWeight: FontWeight.w800,
                    color: LibraryTheme.text(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.upHintFileSelectedSuccess,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: LibraryTheme.muted(context),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                      LibraryTheme.border(context).withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    l10n.upBtnChangeFile,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: LibraryTheme.primary(context),
                    ),
                  ),
                ),
              ],
            )
                : Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.withOpacity(0.08),
                        Colors.grey.withOpacity(0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.attach_file_rounded,
                    color: LibraryTheme.muted(context),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.upBtnSelectFile,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.6,
                    fontWeight: FontWeight.w700,
                    color: LibraryTheme.text(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.upHintSupportedTypes,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: LibraryTheme.muted(context),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                      LibraryTheme.border(context).withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    l10n.upBtnChooseFile,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: LibraryTheme.primary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: LibraryTheme.border(context).withOpacity(0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17.5,
              fontWeight: FontWeight.w800,
              color: LibraryTheme.text(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12.8,
              color: LibraryTheme.muted(context),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final String? Function(String?)? validator;

  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        fontSize: 14.5,
        color: LibraryTheme.text(context),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: LibraryTheme.border(context),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: LibraryTheme.primary(context),
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _ModernDropdown extends StatelessWidget {
  final String? value;
  final String label;
  final IconData icon;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _ModernDropdown({
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final uniqueItems = items.toSet().toList();
    final safeValue =
    value != null && uniqueItems.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      style: TextStyle(
        fontSize: 14.5,
        color: LibraryTheme.text(context),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: LibraryTheme.border(context),
            width: 1,
          ),
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
            (item) => DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      )
          .toList(),
      onChanged: onChanged,
    );
  }
}