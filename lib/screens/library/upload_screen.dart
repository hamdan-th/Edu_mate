import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'library_theme.dart';
import 'library_upload_service.dart';
import 'university_academic_data.dart';

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
      _showSnackBar('تعذر اختيار الملف');
    }
  }

  Future<void> _submitForm() async {
    if (_isUploading) return;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedFile == null) {
      _showSnackBar('اختر ملفًا أولاً');
      return;
    }

    if (_selectedCollege == null ||
        _selectedSpecialization == null ||
        _selectedLevel == null ||
        _selectedTerm == null) {
      _showSnackBar('أكمل جميع القوائم المطلوبة');
      return;
    }

    if (FirebaseAuth.instance.currentUser == null) {
      _showSnackBar('يجب تسجيل الدخول أولاً');
      return;
    }

    final normalizedCollege = _normalizeCollege(_selectedCollege);

    if (normalizedCollege == null) {
      _showSnackBar('اختر الكلية بشكل صحيح');
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
          const SnackBar(
            content: Text('تم رفع الملف بنجاح، وحالته الآن: قيد المراجعة'),
          ),
        );

      Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء رفع الملف');
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

  @override
  Widget build(BuildContext context) {
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
                    ),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: 'بيانات الملف',
                      subtitle: 'أدخل المعلومات الأساسية بشكل واضح ومنظم',
                      child: Column(
                        children: [
                          _ModernTextField(
                            controller: _subjectNameController,
                            label: 'اسم المادة / عنوان الملف',
                            icon: Icons.menu_book_rounded,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'هذا الحقل مطلوب';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _ModernTextField(
                            controller: _doctorNameController,
                            label: 'اسم الدكتور',
                            icon: Icons.person_rounded,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'هذا الحقل مطلوب';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _ModernTextField(
                            controller: _descriptionController,
                            label: 'وصف مختصر',
                            icon: Icons.notes_rounded,
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: 'التصنيف الأكاديمي',
                      subtitle: 'اختر مكان الملف داخل هيكل الجامعة',
                      child: Column(
                        children: [
                          _ModernDropdown(
                            value: normalizedCollege,
                            label: 'الكلية',
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
                            label: 'التخصص',
                            icon: Icons.auto_awesome_mosaic_rounded,
                            items: specializations,
                            onChanged: (value) =>
                                setState(() => _selectedSpecialization = value),
                          ),
                          const SizedBox(height: 12),
                          _ModernDropdown(
                            value: _selectedLevel,
                            label: 'المستوى',
                            icon: Icons.layers_rounded,
                            items: UniversityAcademicData.levels,
                            onChanged: (value) =>
                                setState(() => _selectedLevel = value),
                          ),
                          const SizedBox(height: 12),
                          _ModernDropdown(
                            value: _selectedTerm,
                            label: 'الترم',
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
                            : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'رفع الملف الآن',
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
                        'سيتم رفع الملف ثم مراجعته قبل ظهوره داخل مكتبة الجامعة',
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
              border: Border.all(color: LibraryTheme.border(context).withOpacity(0.3), width: 0.5),
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
          'رفع ملف جديد',
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
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroIconBox(),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أضف ملفك للمكتبة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'ارفع الملخصات والمراجع والملفات الدراسية بطريقة منظمة واحترافية.',
                  style: TextStyle(
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

  const _FilePickerCard({
    required this.selectedFile,
    required this.onTap,
    required this.fileNameBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = selectedFile != null;

    return _SectionCard(
      title: 'الملف المرفوع',
      subtitle: 'اختر PDF أو Word أو صورة حسب نوع المحتوى',
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
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: hasFile
                          ? [
                        LibraryTheme.primary(context).withOpacity(0.16),
                        LibraryTheme.secondary(context).withOpacity(0.12),
                      ]
                          : [
                        Colors.grey.withOpacity(0.08),
                        Colors.grey.withOpacity(0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    hasFile
                        ? Icons.check_circle_rounded
                        : Icons.attach_file_rounded,
                    color: hasFile ? LibraryTheme.primary(context) : LibraryTheme.muted(context),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  hasFile ? fileNameBuilder(selectedFile!) : 'اضغط لاختيار ملف',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.6,
                    fontWeight: FontWeight.w700,
                    color: LibraryTheme.text(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasFile
                      ? 'تم اختيار الملف بنجاح، ويمكنك الآن إكمال بقية البيانات'
                      : 'الأنواع المدعومة: PDF / DOC / DOCX / JPG / PNG',
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
                    border: Border.all(color: LibraryTheme.border(context).withOpacity(0.3), width: 0.5),
                  ),
                  child: Text(
                    hasFile ? 'تغيير الملف' : 'اختيار ملف',
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
        border: Border.all(color: LibraryTheme.border(context).withOpacity(0.3), width: 0.5),
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