import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

import '../../core/theme/app_colors.dart';
import '../../data/academic_structure.dart';
import '../../services/group_service.dart';
import '../../services/upload_screening_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _groupType = 'private'; // safe default while role loads

  String? _selectedCollegeId;
  String? _selectedCollegeName;

  String? _selectedSpecializationId;
  String? _selectedSpecializationName;

  String? _selectedImagePath;

  bool _isLoading = false;

  /// True once the Firestore role check confirms the user is a doctor.
  /// Defaults to false so non-doctors never see the public option prematurely.
  bool _isDoctor = false;

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
  void initState() {
    super.initState();
    _loadUserRole();
  }

  /// Fetches the current user's role from Firestore once and updates the UI.
  Future<void> _loadUserRole() async {
    final isDoctor = await GroupService.isCurrentUserDoctor();
    if (!mounted) return;
    setState(() {
      _isDoctor = isDoctor;
      // Doctors may create public groups; students are locked to private.
      if (!isDoctor) _groupType = 'private';
      if (isDoctor) _groupType = 'public';
    });
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

    // Perform pre-upload screening
    await UploadScreeningService.validate(file, isImage: true);

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _createGroup() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      _showMessage(l10n.groupsCreateEmptyNameMsg);
      return;
    }

    if ((_selectedCollegeId ?? '').isEmpty || (_selectedCollegeName ?? '').isEmpty) {
      _showMessage(l10n.groupsCreateEmptyCollegeMsg);
      return;
    }

    if ((_selectedSpecializationId ?? '').isEmpty ||
        (_selectedSpecializationName ?? '').isEmpty) {
      _showMessage(l10n.groupsCreateEmptyMajorMsg);
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
      if (mounted && e is ScreeningException) {
        UploadScreeningService.showScanError(context, e);
      } else {
        _showMessage(e.toString().replaceFirst('Exception: ', ''));
      }
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
    final l10n = AppLocalizations.of(context)!;
    final previewName = _nameController.text.trim().isEmpty
        ? l10n.groupsNameLabel
        : _nameController.text.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.groupsCreateTitle),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.groupsCreateHeaderTitle,
                  style: const TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.groupsCreateHeaderSub,
                  style: const TextStyle(
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
                        _groupType == 'private' ? l10n.groupsPrivateBadge : l10n.groupsPublicBadge,
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
                _FormLabel(l10n.groupsCreateInfoLabel),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: l10n.groupsNameLabel,
                    prefixIcon: const Icon(Icons.groups_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.groupsCreateDescLabel,
                    alignLabelWithHint: true,
                    prefixIcon: const Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCollegeId,
                  decoration: InputDecoration(
                    labelText: l10n.groupsCreateCollegeLabel,
                    prefixIcon: const Icon(Icons.account_balance_rounded),
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
                  decoration: InputDecoration(
                    labelText: l10n.groupsCreateMajorLabel,
                    prefixIcon: const Icon(Icons.school_rounded),
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
                _FormLabel(l10n.groupsCreateTypeLabel),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Public group creation is restricted to doctors only.
                    if (_isDoctor) ...([
                      Expanded(
                        child: _TypeSelectorCard(
                          title: l10n.groupsCreateTypePublicTitle,
                          subtitle: l10n.groupsCreateTypePublicSub,
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
                    ]),
                    Expanded(
                      child: _TypeSelectorCard(
                        title: l10n.groupsCreateTypePrivateTitle,
                        subtitle: l10n.groupsCreateTypePrivateSub,
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
                      _isLoading ? l10n.groupsCreateBtnLoading : l10n.groupsCreateBtn,
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