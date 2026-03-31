import 'package:flutter/material.dart';
import 'library_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'core_api_service.dart';
import 'core_result_details_screen.dart';
import 'upload_screen.dart';
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

  // ذاكرة مؤقتة لتخزين معرفات العناصر المحفوظة
  final Set<String> _savedItems = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) {
      return;
    }

    // إخفاء لوحة المفاتيح
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LibraryTheme.bg,

      // 🔥 زر إضافة ملخص (احترافي)
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70), // 🔥 يرفعه فوق البار السفلي
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LibraryTheme.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: LibraryTheme.primary.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton(
            backgroundColor: Colors.transparent,
            elevation: 0,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UploadScreen(),
                ),
              );
            },
            child: const Icon(Icons.add, size: 24),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      body: Column(
        children: [
          // --- شريط البحث ---
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

          // --- النتائج ---
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
                final authors =
                    (result['authors'] as List<dynamic>?)
                        ?.map((author) => author['name'].toString())
                        .join(', ') ??
                        'مؤلف غير معروف';

                return _buildResultCard(result, title, authors);
              },
            )
                : Center(
              child: Text(
                _message,
                textAlign: TextAlign.center,
                style: TextStyle(
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

  // --- ويدجت بطاقة النتيجة ---
  Widget _buildResultCard(Map<String, dynamic> result, String title, String authors) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CoreResultDetailsScreen(resultData: result),
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (authors.isNotEmpty)
                Text(
                  authors,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSaveButton(result),
                  _buildShareButton(result, title),
                  _buildDownloadButton(result),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ويدجت زر الحفظ ---
  Widget _buildSaveButton(Map<String, dynamic> result) {
    final String articleId = result['id']?.toString() ?? '';
    final bool isSaved = _savedItems.contains(articleId);

    return _buildActionButton(
      icon: isSaved ? Icons.bookmark_added : Icons.bookmark_add_outlined,
      label: isSaved ? 'تم الحفظ' : 'حفظ',
      onPressed: () {
        if (articleId.isEmpty) return;
        setState(() {
          if (isSaved) {
            _savedItems.remove(articleId);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(content: Text('تمت الإزالة من المحفوظات')));
          } else {
            _savedItems.add(articleId);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(content: Text('تم الحفظ كمرجع بنجاح!')));
          }
        });
      },
    );
  }

  // --- ويدجت زر المشاركة ---
  Widget _buildShareButton(Map<String, dynamic> result, String title) {
    return _buildActionButton(
      icon: Icons.share_outlined,
      label: 'مشاركة',
      onPressed: () async {
        final String? articleId = result['id']?.toString();
        if (articleId != null) {
          final String articleUrl = 'https://core.ac.uk/display/$articleId';
          final String shareText = 'اطلع على هذه الورقة البحثية: "$title"\n$articleUrl';
          await Share.share(shareText );
        } else {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('لا يوجد رابط لمشاركة هذا العنصر')));
        }
      },
    );
  }

  // --- ويدجت زر التنزيل ---
  Widget _buildDownloadButton(Map<String, dynamic> result) {
    return _buildActionButton(
      icon: Icons.download_for_offline_outlined,
      label: 'تنزيل',
      onPressed: () {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('سيتم برمجة التنزيل قريباً')));
      },
    );
  }

  // --- ويدجت بناء الأيقونة العام ---
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
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
