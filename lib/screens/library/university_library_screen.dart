import 'package:flutter/material.dart';
import 'library_theme.dart';
import 'file_card.dart';
import 'file_details_screen.dart';
import 'file_model.dart';


class UniversityLibraryScreen extends StatefulWidget {
  const UniversityLibraryScreen({Key? key}) : super(key: key);

  @override
  State<UniversityLibraryScreen> createState() => _UniversityLibraryScreenState();
}

class _UniversityLibraryScreenState extends State<UniversityLibraryScreen> {
  final List<FileModel> _allFiles = dummyFiles;
  List<FileModel> _filteredFiles = [];
  bool _isGridView = false;
  final TextEditingController _searchController = TextEditingController();

  // ✨ 1. متغيرات جديدة لتخزين قيم الفلاتر المختارة
  String? _selectedCollege = 'كلية الهندسة';
  String? _selectedLevel = 'المستوى الأول';
  String _sortOrder = 'الأحدث';

  @override
  void initState() {
    super.initState();
    _filteredFiles = _allFiles;
    _searchController.addListener(_filterFiles);
  }

  void _filterFiles() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFiles = _allFiles.where((file) {
        final titleMatch = file.title.toLowerCase().contains(query); // بدون .info
        final authorMatch = file.author.toLowerCase().contains(query); // بدون .info
        return titleMatch || authorMatch;
      }).toList();
    });
  }



  @override
  void dispose() {
    _searchController.removeListener(_filterFiles);
    _searchController.dispose();
    super.dispose();
  }

  // ✨ 2. دالة جديدة لعرض لوحة الفلاتر
  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: LibraryTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        // نستخدم StatefulWidget هنا للسماح بتغيير القيم داخل اللوحة
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('فلترة النتائج', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // فلتر الكلية
                  DropdownButtonFormField<String>(
                    value: _selectedCollege,
                    decoration: const InputDecoration(labelText: 'الكلية', border: OutlineInputBorder()),
                    items: ['كلية الهندسة', 'كلية الطب', 'كلية العلوم', 'كلية الآداب']
                        .map((college) => DropdownMenuItem(value: college, child: Text(college)))
                        .toList(),
                    onChanged: (value) => setModalState(() => _selectedCollege = value),
                  ),
                  const SizedBox(height: 16),

                  // فلتر المستوى
                  DropdownButtonFormField<String>(
                    value: _selectedLevel,
                    decoration: const InputDecoration(labelText: 'المستوى', border: OutlineInputBorder()),
                    items: ['المستوى الأول', 'المستوى الثاني', 'المستوى الثالث', 'المستوى الرابع']
                        .map((level) => DropdownMenuItem(value: level, child: Text(level)))
                        .toList(),
                    onChanged: (value) => setModalState(() => _selectedLevel = value),
                  ),
                  const SizedBox(height: 20),

                  // فلتر الترتيب
                  const Text('ترتيب حسب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('الأحدث'),
                        selected: _sortOrder == 'الأحدث',
                        onSelected: (selected) => setModalState(() => _sortOrder = 'الأحدث'),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('الأكثر إعجاباً'),
                        selected: _sortOrder == 'الأكثر إعجاباً',
                        onSelected: (selected) => setModalState(() => _sortOrder = 'الأكثر إعجاباً'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // زر تطبيق الفلاتر
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LibraryTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        // مستقبلاً: هنا يتم تطبيق الفلترة الفعلية
                        print('تم اختيار: $_selectedCollege, $_selectedLevel, $_sortOrder');
                        Navigator.pop(context); // إغلاق اللوحة
                      },
                      child: const Text('تطبيق', style: TextStyle(fontSize: 18, color: LibraryTheme.surface)),
                    ),
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
      backgroundColor: LibraryTheme.bg,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // ✨ 3. شريط البحث أصبح داخل Expanded
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ابحث عن مادة أو دكتور...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: LibraryTheme.surface,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // ✨ 4. إضافة زر الفلترة
                IconButton(
                  icon: const Icon(Icons.filter_list_rounded),
                  onPressed: _showFilterPanel,
                  tooltip: 'فلترة',
                  style: IconButton.styleFrom(
                    backgroundColor: LibraryTheme.surface,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(width: 10),
                // زر تبديل العرض
                IconButton(
                  icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
                  onPressed: () => setState(() => _isGridView = !_isGridView),
                  tooltip: 'تغيير طريقة العرض',
                  style: IconButton.styleFrom(
                    backgroundColor: LibraryTheme.surface,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isGridView
                ? GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _filteredFiles.length,
              itemBuilder: (context, index) {
                final file = _filteredFiles[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FileDetailsScreen(file: file)),
                  ),
                  child: GridFileCard(file: file),
                );
              },
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredFiles.length,
              itemBuilder: (context, index) {
                final file = _filteredFiles[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FileDetailsScreen(file: file)),
                    ),
                    child: FileCard(file: file),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
