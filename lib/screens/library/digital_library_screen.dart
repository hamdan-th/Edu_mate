import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'core_api_service.dart';
import 'core_result_details_screen.dart';
import 'library_theme.dart';

class DigitalLibraryScreen extends StatefulWidget {
  const DigitalLibraryScreen({super.key});

  @override
  State<DigitalLibraryScreen> createState() => _DigitalLibraryScreenState();
}

class _DigitalLibraryScreenState extends State<DigitalLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  String _message = 'ط§ط¨ط­ط« ظپظٹ ظ…ظ„ط§ظٹظٹظ† ط§ظ„ط£ظˆط±ط§ظ‚ ط§ظ„ط¨ط­ط«ظٹط© ط§ظ„ظ…ظپطھظˆط­ط©...';
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
          _message = 'ظ„ظ… ظٹطھظ… ط§ظ„ط¹ط«ظˆط± ط¹ظ„ظ‰ ظ†طھط§ط¦ط¬ ظ„ظ€ "${_searchController.text}"';
        }
      });
    } catch (e) {
      setState(() {
        _message = 'ط­ط¯ط« ط®ط·ط£ ط£ط«ظ†ط§ط، ط§ظ„ط¨ط­ط«. ظٹط±ط¬ظ‰ ط§ظ„طھط­ظ‚ظ‚ ظ…ظ† ط§طھطµط§ظ„ظƒ ط¨ط§ظ„ط¥ظ†طھط±ظ†طھ.';
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
            isSaved ? 'طھظ…طھ ط§ظ„ط¥ط²ط§ظ„ط© ظ…ظ† ط§ظ„ظ…ط­ظپظˆط¸ط§طھ' : 'طھظ… ط§ظ„ط­ظپط¸ ظƒظ…ط±ط¬ط¹ ط¨ظ†ط¬ط§ط­',
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
          const SnackBar(content: Text('ظ„ط§ ظٹظˆط¬ط¯ ط±ط§ط¨ط· ظ„ظ…ط´ط§ط±ظƒط© ظ‡ط°ط§ ط§ظ„ط¹ظ†طµط±')),
        );
      return;
    }

    final String articleUrl = 'https://core.ac.uk/display/$articleId';
    final String shareText = 'ط§ط·ظ„ط¹ ط¹ظ„ظ‰ ظ‡ط°ظ‡ ط§ظ„ظˆط±ظ‚ط© ط§ظ„ط¨ط­ط«ظٹط©:\n$title\n$articleUrl';
    await Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LibraryTheme.bg(context),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => _performSearch(),
              decoration: InputDecoration(
                hintText: 'ط§ط¨ط­ط« ظپظٹ CORE (ظ…ط«ط§ظ„: AI in Medicine)',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded),
                  color: LibraryTheme.primary(context),
                  onPressed: _performSearch,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: LibraryTheme.surface(context),
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
                final title = result['title'] ?? 'ط¨ط¯ظˆظ† ط¹ظ†ظˆط§ظ†';
                final authors = (result['authors'] as List<dynamic>?)
                    ?.map((author) => author['name'].toString())
                    .join(', ') ??
                    'ظ…ط¤ظ„ظپ ط؛ظٹط± ظ…ط¹ط±ظˆظپ';

                final String articleId = result['id']?.toString() ?? '';
                final bool isSaved = _savedItems.contains(articleId);

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (authors.isNotEmpty)
                            Text(
                              authors,
                              style: TextStyle(
                                color: LibraryTheme.muted(context),
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _ActionButton(
                                icon: isSaved
                                    ? Icons.bookmark_added
                                    : Icons.bookmark_add_outlined,
                                label: isSaved ? 'طھظ… ط§ظ„ط­ظپط¸' : 'ط­ظپط¸',
                                onPressed: () => _toggleSave(result),
                              ),
                              _ActionButton(
                                icon: Icons.share_outlined,
                                label: 'ظ…ط´ط§ط±ظƒط©',
                                onPressed: () => _shareResult(result, title),
                              ),
                              _ActionButton(
                                icon: Icons.arrow_forward_ios_rounded,
                                label: 'ط§ظ„طھظپط§طµظٹظ„',
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
                style: TextStyle(
                  fontSize: 16,
                  color: LibraryTheme.muted(context),
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
            Icon(icon, color: LibraryTheme.primary(context), size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: LibraryTheme.primary(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

