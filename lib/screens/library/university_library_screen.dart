import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'file_card.dart';
import 'file_details_screen.dart';
import 'file_model.dart';
import 'library_files_service.dart';
import 'library_theme.dart';
import 'university_academic_data.dart';

class UniversityLibraryScreen extends StatefulWidget {
  const UniversityLibraryScreen({Key? key}) : super(key: key);

  @override
  State<UniversityLibraryScreen> createState() => _UniversityLibraryScreenState();
}

class _UniversityLibraryScreenState extends State<UniversityLibraryScreen> {
  bool _isGridView = false;
  final TextEditingController _searchController = TextEditingController();

  String? _selectedCollege;
  String? _selectedMajor;
  String? _selectedLevel;
  String _sortOrder = 'الأحدث';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FileModel> _applyFilters(List<FileModel> files) {
    final query = _searchController.text.trim().toLowerCase();

    List<FileModel> filtered = files.where((file) {
      final searchable = [
        file.title,
        file.author,
        file.course,
        file.college,
        file.major,
        file.description,
      ].join(' ').toLowerCase();

      final collegeMatch = _selectedCollege == null || file.college == _selectedCollege;
      final majorMatch = _selectedMajor == null || file.major == _selectedMajor;
      final levelMatch = _selectedLevel == null || file.semester.contains(_selectedLevel!);

      return searchable.contains(query) && collegeMatch && majorMatch && levelMatch;
    }).toList();

    switch (_sortOrder) {
      case 'الأكثر إعجاباً':
        filtered.sort((a, b) => b.likes.compareTo(a.likes));
        break;
      case 'الأكثر مشاهدة':
        filtered.sort((a, b) => b.views.compareTo(a.views));
        break;
      default:
        filtered.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    }

    return filtered;
  }

  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final majors = _selectedCollege == null
                ? <String>[]
                : UniversityAcademicData.majorsByCollege[_selectedCollege] ?? <String>[];

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).bottomSheetTheme.backgroundColor ?? Theme.of(context).cardTheme.color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: SizedBox(width: 42, child: Divider(thickness: 4, color: Theme.of(context).dividerColor.withOpacity(0.1))),
                  ),
                  const SizedBox(height: 12),
                  const Text('فلترة وترتيب', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  _BottomSheetDropdown(
                    value: _selectedCollege,
                    label: 'الكلية',
                    items: UniversityAcademicData.colleges,
                    onChanged: (value) => setModalState(() {
                      _selectedCollege = value;
                      _selectedMajor = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  _BottomSheetDropdown(
                    value: _selectedMajor,
                    label: 'التخصص',
                    items: majors,
                    onChanged: (value) => setModalState(() => _selectedMajor = value),
                  ),
                  const SizedBox(height: 12),
                  _BottomSheetDropdown(
                    value: _selectedLevel,
                    label: 'المستوى',
                    items: UniversityAcademicData.levels,
                    onChanged: (value) => setModalState(() => _selectedLevel = value),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final option in ['الأحدث', 'الأكثر إعجاباً', 'الأكثر مشاهدة'])
                        ChoiceChip(
                          label: Text(option),
                          selected: _sortOrder == option,
                          onSelected: (_) => setModalState(() => _sortOrder = option),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCollege = null;
                              _selectedMajor = null;
                              _selectedLevel = null;
                              _sortOrder = 'الأحدث';
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('إعادة ضبط'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {});
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('تطبيق'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchAndActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ابحث عن مادة أو دكتور أو تخصص...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _ActionIconButton(
            icon: Icons.tune_rounded,
            onTap: _showFilterPanel,
          ),
          const SizedBox(width: 8),
          _ActionIconButton(
            icon: _isGridView ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
            onTap: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildSearchAndActions(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: LibraryFilesService.universityFiles(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                final files = docs.map((doc) => FileModel.fromFirestore(doc)).toList();
                final filteredFiles = _applyFilters(files);

                if (filteredFiles.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد ملفات مطابقة حالياً',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                if (_isGridView) {
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredFiles.length,
                    itemBuilder: (context, index) {
                      final file = filteredFiles[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FileDetailsScreen(file: file),
                            ),
                          );
                        },
                        child: FileCard(file: file),
                      );
                    },
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: filteredFiles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final file = filteredFiles[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FileDetailsScreen(file: file),
                          ),
                        );
                      },
                      child: FileCard(file: file),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
          ),
          child: Icon(icon, color: Theme.of(context).iconTheme.color),
        ),
      ),
    );
  }
}

class _BottomSheetDropdown extends StatelessWidget {
  final String? value;
  final String label;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _BottomSheetDropdown({
    required this.value,
    required this.label,
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
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3)),
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
