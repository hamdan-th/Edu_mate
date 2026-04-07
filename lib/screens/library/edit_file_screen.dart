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
      case 'ظƒظ„ظٹط© ط§ظ„ظ‡ظ†ط¯ط³ط©':
        return 'ظƒظ„ظٹط© ط§ظ„ظ‡ظ†ط¯ط³ط© ظˆطھظƒظ†ظˆظ„ظˆط¬ظٹط§ ط§ظ„ظ…ط¹ظ„ظˆظ…ط§طھ';
      default:
        return college.trim();
    }
  }

  String? _normalizeSpecialization(String? specialization) {
    if (specialization == null) return null;
    return specialization.trim();
  }

  @override
  void initState() {
    super.initState();

    final data = widget.fileData;

    _subjectNameController = TextEditingController(
      text: (data['subjectName'] ?? data['title'] ?? '').toString(),
    );
    _doctorNameController = TextEditingController(
      text: (data['doctorName'] ?? '').toString(),
    );
    _descriptionController = TextEditingController(
      text: (data['description'] ?? '').toString(),
    );

    _selectedCollege = _normalizeCollege((data['college'] ?? '').toString());
    _selectedSpecialization =
        _normalizeSpecialization((data['specialization'] ?? '').toString());
    _selectedLevel = (data['level'] ?? '').toString().trim().isEmpty
        ? null
        : (data['level'] ?? '').toString().trim();
    _selectedTerm = (data['term'] ?? '').toString().trim().isEmpty
        ? null
        : (data['term'] ?? '').toString().trim();

    final colleges = UniversityAcademicData.colleges.toSet().toList();
    if (_selectedCollege != null && !colleges.contains(_selectedCollege)) {
      _selectedCollege = null;
    }

    final specializations = _selectedCollege == null
        ? <String>[]
        : (UniversityAcademicData.majorsByCollege[_selectedCollege!] ?? <String>[])
        .toSet()
        .toList();

    if (_selectedSpecialization != null &&
        !specializations.contains(_selectedSpecialization)) {
      _selectedSpecialization = null;
    }

    final levels = UniversityAcademicData.levels.toSet().toList();
    if (_selectedLevel != null && !levels.contains(_selectedLevel)) {
      _selectedLevel = null;
    }

    final terms = UniversityAcademicData.terms.toSet().toList();
    if (_selectedTerm != null && !terms.contains(_selectedTerm)) {
      _selectedTerm = null;
    }
  }

  @override
  void dispose() {
    _subjectNameController.dispose();
    _doctorNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCollege == null ||
        _selectedSpecialization == null ||
        _selectedLevel == null ||
        _selectedTerm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ط£ظƒظ…ظ„ ط¬ظ…ظٹط¹ ط§ظ„ظ‚ظˆط§ط¦ظ… ط§ظ„ظ…ط·ظ„ظˆط¨ط©')),
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
        'status': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('طھظ… طھط¹ط¯ظٹظ„ ط§ظ„ظ…ظ„ظپ ط¨ظ†ط¬ط§ط­طŒ ظˆط­ط§ظ„طھظ‡ ط§ظ„ط¢ظ†: ظ‚ظٹط¯ ط§ظ„ظ…ط±ط§ط¬ط¹ط©'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ظپط´ظ„ طھط¹ط¯ظٹظ„ ط§ظ„ظ…ظ„ظپ: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colleges = UniversityAcademicData.colleges.toSet().toList();

    final specializations = _selectedCollege == null
        ? <String>[]
        : (UniversityAcademicData.majorsByCollege[_selectedCollege!] ?? <String>[])
        .toSet()
        .toList();

    final levels = UniversityAcademicData.levels.toSet().toList();
    final terms = UniversityAcademicData.terms.toSet().toList();

    return Scaffold(
      backgroundColor: LibraryTheme.bg(context),
      appBar: AppBar(
        title: const Text('طھط¹ط¯ظٹظ„ ط§ظ„ظ…ظ„ظپ'),
        backgroundColor: LibraryTheme.bg(context),
        elevation: 0,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Field(
              controller: _subjectNameController,
              label: 'ط§ط³ظ… ط§ظ„ظ…ط§ط¯ط© / ط§ظ„ط¹ظ†ظˆط§ظ†',
              validator: true,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _doctorNameController,
              label: 'ط§ط³ظ… ط§ظ„ط¯ظƒطھظˆط±',
              validator: true,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _descriptionController,
              label: 'ط§ظ„ظˆطµظپ',
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            _Dropdown(
              value: _selectedCollege,
              label: 'ط§ظ„ظƒظ„ظٹط©',
              items: colleges,
              onChanged: (value) {
                setState(() {
                  _selectedCollege = value;
                  _selectedSpecialization = null;
                });
              },
            ),
            const SizedBox(height: 12),
            _Dropdown(
              value: _selectedSpecialization,
              label: 'ط§ظ„طھط®طµطµ',
              items: specializations,
              onChanged: (value) {
                setState(() {
                  _selectedSpecialization = value;
                });
              },
            ),
            const SizedBox(height: 12),
            _Dropdown(
              value: _selectedLevel,
              label: 'ط§ظ„ظ…ط³طھظˆظ‰',
              items: levels,
              onChanged: (value) {
                setState(() {
                  _selectedLevel = value;
                });
              },
            ),
            const SizedBox(height: 12),
            _Dropdown(
              value: _selectedTerm,
              label: 'ط§ظ„طھط±ظ…',
              items: terms,
              onChanged: (value) {
                setState(() {
                  _selectedTerm = value;
                });
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LibraryTheme.primary(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('ط­ظپط¸ ط§ظ„طھط¹ط¯ظٹظ„ط§طھ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final bool validator;

  const _Field({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.validator = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator
          ? (value) =>
      (value == null || value.trim().isEmpty) ? 'ظ‡ط°ط§ ط§ظ„ط­ظ‚ظ„ ظ…ط·ظ„ظˆط¨' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: LibraryTheme.bg(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: LibraryTheme.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
          BorderSide(color: LibraryTheme.primary(context), width: 1.4),
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String? value;
  final String label;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _Dropdown({
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final uniqueItems = items.toSet().toList();
    final safeValue =
    (value != null && uniqueItems.contains(value)) ? value : null;

    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: LibraryTheme.bg(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: LibraryTheme.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
          BorderSide(color: LibraryTheme.primary(context), width: 1.4),
        ),
      ),
      items: uniqueItems
          .map(
            (item) => DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        ),
      )
          .toList(),
      onChanged: onChanged,
    );
  }
}

