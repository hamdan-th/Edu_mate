import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/academic_structure.dart';
import '../../services/group_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _groupType = 'public';

  String? _selectedCollegeId;
  String? _selectedCollegeName;

  String? _selectedSpecializationId;
  String? _selectedSpecializationName;

  String? _selectedImagePath;

  bool _isLoading = false;

  CollegeItem? get _selectedCollege {
    if (_selectedCollegeId == null) return null;
    for (final college in AcademicStructure.colleges) {
      if (college.id == _selectedCollegeId) return college;
    }
    return null;
  }

  List<SpecializationItem> get _availableSpecializations {
    return _selectedCollege?.specializations ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedImagePath = result.files.single.path!;
      });
    }
  }

  Future<String> _uploadImageIfNeeded() async {
    if (_selectedImagePath == null || _selectedImagePath!.isEmpty) {
      return '';
    }

    final file = File(_selectedImagePath!);
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

    final ref = FirebaseStorage.instance
        .ref()
        .child('group_covers')
        .child(fileName);

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      _showMessage('اكتب اسم المجموعة');
      return;
    }

    if ((_selectedCollegeId ?? '').isEmpty || (_selectedCollegeName ?? '').isEmpty) {
      _showMessage('اختر الكلية');
      return;
    }

    if ((_selectedSpecializationId ?? '').isEmpty ||
        (_selectedSpecializationName ?? '').isEmpty) {
      _showMessage('اختر التخصص');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final imageUrl = await _uploadImageIfNeeded();

      await GroupService.createGroup(
        name: name,
        description: description,
        type: _groupType,
        collegeId: _selectedCollegeId!,
        collegeName: _selectedCollegeName!,
        specializationId: _selectedSpecializationId!,
        specializationName: _selectedSpecializationName!,
        imageUrl: imageUrl,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final previewName = _nameController.text.trim().isEmpty
        ? 'اسم المجموعة'
        : _nameController.text.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إنشاء مجموعة'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Group',
                  style: TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'أنشئ مساحة دراسية جديدة للنقاش والتعاون',
                  style: TextStyle(
                    color: Color(0xFFD7E6FF),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(18),
                  child: _selectedImagePath != null
                      ? Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      image: DecorationImage(
                        image: FileImage(File(_selectedImagePath!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                      : Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.blueGlow],
                      ),
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.textOnDark,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        previewName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _groupType == 'private' ? 'مجموعة خاصة' : 'مجموعة عامة',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_selectedCollegeName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _selectedCollegeName!,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          if (_selectedSpecializationName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _selectedSpecializationName!,
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
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
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FormLabel('معلومات المجموعة'),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'اسم المجموعة',
                    prefixIcon: Icon(Icons.groups_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'نبذة عن المجموعة',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCollegeId,
                  decoration: const InputDecoration(
                    labelText: 'الكلية',
                    prefixIcon: Icon(Icons.account_balance_rounded),
                  ),
                  items: AcademicStructure.colleges.map((college) {
                    return DropdownMenuItem<String>(
                      value: college.id,
                      child: Text(college.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCollegeId = value;
                      _selectedSpecializationId = null;
                      _selectedSpecializationName = null;

                      final matched = AcademicStructure.colleges
                          .where((e) => e.id == value)
                          .toList();

                      if (matched.isNotEmpty) {
                        _selectedCollegeName = matched.first.name;
                      } else {
                        _selectedCollegeName = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSpecializationId,
                  decoration: const InputDecoration(
                    labelText: 'التخصص',
                    prefixIcon: Icon(Icons.school_rounded),
                  ),
                  items: _availableSpecializations.map((spec) {
                    return DropdownMenuItem<String>(
                      value: spec.id,
                      child: Text(spec.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSpecializationId = value;

                      final matched = _availableSpecializations
                          .where((e) => e.id == value)
                          .toList();

                      if (matched.isNotEmpty) {
                        _selectedSpecializationName = matched.first.name;
                      } else {
                        _selectedSpecializationName = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 18),
                const _FormLabel('نوع المجموعة'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _TypeSelectorCard(
                        title: 'عامة',
                        subtitle: 'يمكن لأي مستخدم الانضمام',
                        icon: Icons.public_rounded,
                        selected: _groupType == 'public',
                        onTap: () {
                          setState(() {
                            _groupType = 'public';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TypeSelectorCard(
                        title: 'خاصة',
                        subtitle: 'الانضمام عبر رابط الدعوة',
                        icon: Icons.lock_rounded,
                        selected: _groupType == 'private',
                        onTap: () {
                          setState(() {
                            _groupType = 'private';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createGroup,
                    icon: _isLoading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.check_rounded),
                    label: Text(
                      _isLoading ? 'جاري الإنشاء...' : 'إنشاء المجموعة',
                    ),
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

class _FormLabel extends StatelessWidget {
  final String text;

  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _TypeSelectorCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeSelectorCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.inputFill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}