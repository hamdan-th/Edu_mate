import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'core_api_service.dart';
import '../../l10n/app_localizations.dart';
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
  String _message = '';
  final Set<String> _savedItems = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) return;

    FocusScope.of(context).unfocus();
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = true;
      _message = '';
      _searchResults = [];
    });

    try {
      final results = await CoreApiService.search(_searchController.text);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        if (_searchResults.isEmpty) {
          _message = l10n.digitalLibNoResults(_searchController.text);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = l10n.digitalLibSearchError;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
            isSaved ? AppLocalizations.of(context)!.digitalLibRemovedFromSaved : AppLocalizations.of(context)!.digitalLibSavedSuccessfully,
          ),
        ),
      );
  }

  Future<void> _shareResult(Map<String, dynamic> result, String title) async {
    final String? articleId = result['id']?.toString();
    final l10n = AppLocalizations.of(context)!;
    if (articleId == null || articleId.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.digitalLibShareNoLink)),
        );
      return;
    }

    final String articleUrl = 'https://core.ac.uk/display/$articleId';
    final String shareText = l10n.digitalLibShareText(title, articleUrl);
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
                hintText: AppLocalizations.of(context)!.digitalLibSearchHint,
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
                final l10n = AppLocalizations.of(context)!;
                final title = result['title'] ?? l10n.digitalLibNoTitle;
                final authors = (result['authors'] as List<dynamic>?)
                    ?.map((author) => author['name'].toString())
                    .join(', ') ??
                    l10n.digitalLibUnknownAuthor;

                final String articleId = result['id']?.toString() ?? '';
                final bool isSaved = _savedItems.contains(articleId);

                return Card(
                  color: LibraryTheme.surface(context),
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? LibraryTheme.border(context) : Colors.transparent),
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
                                label: isSaved ? l10n.digitalLibActionSaved : l10n.digitalLibActionSave,
                                onPressed: () => _toggleSave(result),
                              ),
                              _ActionButton(
                                icon: Icons.share_outlined,
                                label: l10n.digitalLibActionShare,
                                onPressed: () => _shareResult(result, title),
                              ),
                              _ActionButton(
                                icon: Icons.arrow_forward_ios_rounded,
                                label: l10n.digitalLibActionDetails,
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
                _message.isEmpty ? AppLocalizations.of(context)!.digitalLibDefaultMessage : _message,
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