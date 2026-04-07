import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'core_api_service.dart';
import 'core_result_details_screen.dart';
import 'library_theme.dart';

class DigitalLibraryScreen extends StatefulWidget {
  const DigitalLibraryScreen({Key? key}) : super(key: key);

  @override
  State<DigitalLibraryScreen> createState() => _DigitalLibraryScreenState();
}

class _DigitalLibraryScreenState extends State<DigitalLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  String _message = 'ابحث في ملايين الأوراق البحثية المفتوحة...';
  final Set<String> _savedItems = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _message = '';
      _searchResults = [];
    });

    try {
      final results = await CoreApiService.search(_searchController.text);
      setState(() {
        _searchResults = results;
        if (_searchResults.isEmpty) {
          _message = 'لم يتم العثور على نتائج لـ "${_searchController.text}"';
        }
      });
    } catch (e) {
      setState(() {
        _message = 'حدث خطأ أثناء البحث. يرجى التحقق من اتصالك بالإنترنت.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleSave(Map<String, dynamic> result) {
    final String articleId = result['id']?.toString() ?? '';
    if (articleId.isEmpty) return;

    final bool isSaved = _savedItems.contains(articleId);

    setState(() {
      if (isSaved) {
        _savedItems.remove(articleId);
      } else {
        _savedItems.add(articleId);
      }
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            isSaved ? 'تمت الإزالة من المحفوظات' : 'تم الحفظ كمرجع بنجاح',
          ),
        ),
      );
  }

  Future<void> _shareResult(Map<String, dynamic> result, String title) async {
    final String? articleId = result['id']?.toString();
    if (articleId == null || articleId.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('لا يوجد رابط لمشاركة هذا العنصر')),
        );
      return;
    }

    final String articleUrl = 'https://core.ac.uk/display/$articleId';
    final String shareText = 'اطلع على هذه الورقة البحثية:\n$title\n$articleUrl';
    await Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LibraryTheme.bg,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => _performSearch(),
              decoration: InputDecoration(
                hintText: 'ابحث في CORE (مثال: AI in Medicine)',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded),
                  color: LibraryTheme.primary,
                  onPressed: _performSearch,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: LibraryTheme.surface,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isNotEmpty
                ? ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                final title = result['title'] ?? 'بدون عنوان';
                final authors = (result['authors'] as List<dynamic>?)
                    ?.map((author) => author['name'].toString())
                    .join(', ') ??
                    'مؤلف غير معروف';

                final String articleId = result['id']?.toString() ?? '';
                final bool isSaved = _savedItems.contains(articleId);

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CoreResultDetailsScreen(
                            resultData: result,
                            isSaved: isSaved,
                            onToggleSave: () => _toggleSave(result),
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (authors.isNotEmpty)
                            Text(
                              authors,
                              style: const TextStyle(
                                color: LibraryTheme.muted,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _ActionButton(
                                icon: isSaved
                                    ? Icons.bookmark_added
                                    : Icons.bookmark_add_outlined,
                                label: isSaved ? 'تم الحفظ' : 'حفظ',
                                onPressed: () => _toggleSave(result),
                              ),
                              _ActionButton(
                                icon: Icons.share_outlined,
                                label: 'مشاركة',
                                onPressed: () => _shareResult(result, title),
                              ),
                              _ActionButton(
                                icon: Icons.arrow_forward_ios_rounded,
                                label: 'التفاصيل',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CoreResultDetailsScreen(
                                        resultData: result,
                                        isSaved: isSaved,
                                        onToggleSave: () => _toggleSave(result),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
                : Center(
              child: Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: LibraryTheme.muted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: LibraryTheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: LibraryTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}