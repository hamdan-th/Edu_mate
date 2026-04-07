import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'file_card.dart';
import 'file_details_screen.dart';
import 'file_model.dart';
import 'library_files_service.dart';
import 'library_theme.dart';
import 'university_academic_data.dart';

class UniversityLibraryScreen extends StatefulWidget {
  const UniversityLibraryScreen({super.key});

  @override
  State<UniversityLibraryScreen> createState() => _UniversityLibraryScreenState();
}

class _UniversityLibraryScreenState extends State<UniversityLibraryScreen> {
  bool _isGridView = false;
  final TextEditingController _searchController = TextEditingController();

  String? _selectedCollege;
  String? _selectedMajor;
  String? _selectedLevel;
  String _sortOrder = 'ط§ظ„ط£ط­ط¯ط«';

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
      case 'ط§ظ„ط£ظƒط«ط± ط¥ط¹ط¬ط§ط¨ط§ظ‹':
        filtered.sort((a, b) => b.likes.compareTo(a.likes));
        break;
      case 'ط§ظ„ط£ظƒط«ط± ظ…ط´ط§ظ‡ط¯ط©':
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
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: SizedBox(width: 42, child: Divider(thickness: 4, color: Theme.of(context).dividerColor)),
                  ),
                  const SizedBox(height: 12),
                  const Text('ظپظ„طھط±ط© ظˆطھط±طھظٹط¨', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  _BottomSheetDropdown(
                    value: _selectedCollege,
                    label: 'ط§ظ„ظƒظ„ظٹط©',
                    items: UniversityAcademicData.colleges,
                    onChanged: (value) => setModalState(() {
                      _selectedCollege = value;
                      _selectedMajor = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  _BottomSheetDropdown(
                    value: _selectedMajor,
                    label: 'ط§ظ„طھط®طµطµ',
                    items: majors,
                    onChanged: (value) => setModalState(() => _selectedMajor = value),
                  ),
                  const SizedBox(height: 12),
                  _BottomSheetDropdown(
                    value: _selectedLevel,
                    label: 'ط§ظ„ظ…ط³طھظˆظ‰',
                    items: UniversityAcademicData.levels,
                    onChanged: (value) => setModalState(() => _selectedLevel = value),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final option in ['ط§ظ„ط£ط­ط¯ط«', 'ط§ظ„ط£ظƒط«ط± ط¥ط¹ط¬ط§ط¨ط§ظ‹', 'ط§ظ„ط£ظƒط«ط± ظ…ط´ط§ظ‡ط¯ط©'])
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
                              _sortOrder = 'ط§ظ„ط£ط­ط¯ط«';
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('ط¥ط¹ط§ط¯ط© ط¶ط¨ط·'),
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
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('طھط·ط¨ظٹظ‚'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(LibraryRadius.card),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.08)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'ط§ط¨ط­ط« ط¨ط§ط³ظ… ط§ظ„ظ…ط§ط¯ط© ط£ظˆ ط§ظ„ط¯ظƒطھظˆط± ط£ظˆ ط§ظ„طھط®طµطµ...',
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.primary),
                      suffixIcon: IconButton(
                        onPressed: _showFilterPanel,
                        icon: const Icon(Icons.tune_rounded),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(LibraryRadius.card), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(LibraryRadius.card),
                          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.08)),
                        ),
                        child: Text(
                          'ط§ظ„طھط±طھظٹط¨: $_sortOrder',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => setState(() => _isGridView = !_isGridView),
                      borderRadius: BorderRadius.circular(LibraryRadius.card),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(LibraryRadius.card),
                          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.08)),
                        ),
                        child: Icon(
                          _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: LibraryFilesService.universityFiles(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('ط­ط¯ط« ط®ط·ط£: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];
                final files = docs.map(FileModel.fromFirestore).toList();
                final filtered = _applyFilters(files);

                if (filtered.isEmpty) {
                  return const _EmptyLibraryState();
                }

                if (_isGridView) {
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.77,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final file = filtered[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => FileDetailsScreen(file: file)),
                        ),
                        child: GridFileCard(file: file),
                      );
                    },
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final file = filtered[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => FileDetailsScreen(file: file)),
                      ),
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

class _EmptyLibraryState extends StatelessWidget {
  const _EmptyLibraryState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(Icons.library_books_rounded, size: 42, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 18),
            const Text(
              'ظ„ط§ طھظˆط¬ط¯ ظ…ظ„ظپط§طھ ظ…ط·ط§ط¨ظ‚ط©',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'ط¬ط±ظ‘ط¨ طھط؛ظٹظٹط± ظƒظ„ظ…ط§طھ ط§ظ„ط¨ط­ط« ط£ظˆ طھط®ظپظٹظپ ط§ظ„ظپظ„ط§طھط± ط­طھظ‰ طھط¸ظ‡ط± ظ„ظƒ ظ†طھط§ط¦ط¬ ط£ظƒط«ط±.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5),
            ),
          ],
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

  const _BottomSheetDropdown({required this.value, required this.label, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(LibraryRadius.card), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(LibraryRadius.card), borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.08))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(LibraryRadius.card), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.4)),
      ),
      items: items.map((e) => DropdownMenuItem<String>(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }
}

