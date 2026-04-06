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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  color: Theme.of(context).primaryColor,
                  onPressed: _performSearch,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          final title = result['title'] ?? 'بدون عنوان';
                          final articleId = result['id']?.toString() ?? '';
                          final isSaved = _savedItems.contains(articleId);

                          return Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              title: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  result['yearPublished']?.toString() ?? 'غير معروف',
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'save') {
                                    _toggleSave(result);
                                  } else if (value == 'share') {
                                    await _shareResult(result, title);
                                  } else if (value == 'details') {
                                    if (!mounted) return;
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CoreResultDetailsScreen(
                                          resultData: result,
                                          isSaved: isSaved,
                                          onToggleSave: () => _toggleSave(result),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'save',
                                    child: Text(isSaved ? 'إزالة الحفظ' : 'حفظ'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'share',
                                    child: Text('مشاركة'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'details',
                                    child: Text('التفاصيل'),
                                  ),
                                ],
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CoreResultDetailsScreen(
                                      resultData: result,
                                      isSaved: isSaved,
                                      onToggleSave: () => _toggleSave(result),
                                    ),
                                  ),
                                );
                              },
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
