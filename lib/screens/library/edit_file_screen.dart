import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'library_theme.dart';
import 'university_academic_data.dart';

class EditFileScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> fileData;

  const EditFileScreen({
    super.key,
    required this.docId,
    required this.fileData,
  });

  @override
  State<EditFileScreen> createState() => _EditFileScreenState();
}

class _EditFileScreenState extends State<EditFileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _subjectNameController;
  late final TextEditingController _doctorNameController;
  late final TextEditingController _descriptionController;

  String? _selectedCollege;
  String? _selectedSpecialization;
  String? _selectedLevel;
  String? _selectedTerm;

  bool _isSaving = false;

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
  void initState() {
    super.initState();
    final d = widget.fileData;

    _subjectNameController =
        TextEditingController(text: d['subjectName'] ?? d['title'] ?? '');
    _doctorNameController =
        TextEditingController(text: d['doctorName'] ?? d['author'] ?? '');
    _descriptionController =
        TextEditingController(text: d['description'] ?? '');

    _selectedCollege = _normalizeCollege(d['college']?.toString());
    _selectedSpecialization = _normalizeSpecialization(d['specialization']?.toString() ?? d['major']?.toString());
    _selectedLevel = d['level']?.toString();
    _selectedTerm = d['term']?.toString();
  }

  @override
  void dispose() {
    _subjectNameController.dispose();
    _doctorNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCollege == null ||
        _selectedSpecialization == null ||
        _selectedLevel == null ||
        _selectedTerm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى استكمال اختيار جميع التصنيفات')),
      );
      return;
    }

    try {
      setState(() => _isSaving = true);

      await FirebaseFirestore.instance
          .collection('library_files')
          .doc(widget.docId)
          .update({
        'subjectName': _subjectNameController.text.trim(),
        'doctorName': _doctorNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'college': _selectedCollege,
        'specialization': _selectedSpecialization,
        'level': _selectedLevel,
        'term': _selectedTerm,
        'visibility': 'public',
        'status': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التعديلات بنجاح')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء حفظ التعديلات')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
      appBar: AppBar(
        title: const Text('تعديل وعرض عام'),
        backgroundColor: LibraryTheme.surface,
        foregroundColor: LibraryTheme.text,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionCard(
                title: 'بيانات الملف',
                subtitle: 'أدخل المعلومات الأساسية للبحث',
                child: Column(
                  children: [
                    _ModernTextField(
                      controller: _subjectNameController,
                      label: 'اسم المادة / عنوان الملف',
                      icon: Icons.menu_book_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'مطلوب';
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
                          return 'مطلوب';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _ModernTextField(
                      controller: _descriptionController,
                      label: 'وصف',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'التصنيف الأكاديمي',
                subtitle: 'أين يجب ظهور هذا الملف؟',
                child: Column(
                  children: [
                    _ModernDropdown(
                      value: normalizedCollege,
                      label: 'الكلية',
                      icon: Icons.account_balance_rounded,
                      items: UniversityAcademicData.colleges,
                      onChanged: (val) => setState(() {
                        _selectedCollege = val;
                        _selectedSpecialization = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                    _ModernDropdown(
                      value: normalizedSpecialization,
                      label: 'التخصص',
                      icon: Icons.auto_awesome_mosaic_rounded,
                      items: specializations,
                      onChanged: (val) =>
                          setState(() => _selectedSpecialization = val),
                    ),
                    const SizedBox(height: 12),
                    _ModernDropdown(
                      value: _selectedLevel,
                      label: 'المستوى',
                      icon: Icons.layers_rounded,
                      items: UniversityAcademicData.levels,
                      onChanged: (val) => setState(() => _selectedLevel = val),
                    ),
                    const SizedBox(height: 12),
                    _ModernDropdown(
                      value: _selectedTerm,
                      label: 'الترم',
                      icon: Icons.calendar_month_rounded,
                      items: UniversityAcademicData.terms,
                      onChanged: (val) => setState(() => _selectedTerm = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LibraryTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'تعديل ونشر للعام',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: LibraryTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: LibraryTheme.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12.5,
              color: LibraryTheme.muted,
            ),
          ),
          const SizedBox(height: 16),
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LibraryTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LibraryTheme.primary, width: 1.4),
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
      value: safeValue,
      isExpanded: true,
      icon: const Icon(Icons.expand_more_rounded),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LibraryTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LibraryTheme.primary, width: 1.4),
        ),
      ),
      items: uniqueItems
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
