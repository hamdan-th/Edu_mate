import 'dart:io';

void main() {
  final file = File(r'c:\Users\hamda\StudioProjects\Edu_mate\lib\screens\library\my_files_list_screen.dart');
  var text = file.readAsStringSync();

  // 1. buildMyUploads
  text = text.replaceFirst(
      'Widget _buildMyUploads(BuildContext context) {',
      'Widget _buildMyUploads(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;');
  text = text.replaceAll(
      "'حدث خطأ: \${snapshot.error}'",
      'l10n.myFilesError(snapshot.error.toString())');

  // 2. buildSavedReferences
  text = text.replaceFirst(
      'Widget _buildSavedReferences(BuildContext context) {',
      'Widget _buildSavedReferences(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;');
  text = text.replaceAll(
      "'يجب تسجيل الدخول أولاً'",
      'l10n.upErrorLoginRequired');
  text = text.replaceAll(
      "'حدث خطأ: \${saveSnapshot.error}'",
      'l10n.myFilesError(saveSnapshot.error.toString())');
  text = text.replaceAll(
      "'حدث خطأ: \${filesSnapshot.error}'",
      'l10n.myFilesError(filesSnapshot.error.toString())');

  // 3. buildDownloads
  text = text.replaceFirst(
      'Widget _buildDownloads(BuildContext context) {',
      'Widget _buildDownloads(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;');
  text = text.replaceAll(
      "'حدث خطأ: \${downloadSnapshot.error}'",
      'l10n.myFilesError(downloadSnapshot.error.toString())');

  // 4. buildShares
  text = text.replaceFirst(
      'Widget _buildShares(BuildContext context) {',
      'Widget _buildShares(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;');
  text = text.replaceAll(
      "'حدث خطأ: \${shareSnapshot.error}'",
      'l10n.myFilesError(shareSnapshot.error.toString())');

  // 5. buildDigitalSavedReferences
  text = text.replaceFirst(
      'Widget _buildDigitalSavedReferences(BuildContext context) {',
      'Widget _buildDigitalSavedReferences(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;');
  text = text.replaceAll(
      "data['title'] ?? 'بدون عنوان'",
      "data['title'] ?? l10n.myFilesNoTitle");
  text = text.replaceAll(
      "data['authors'] ?? 'مؤلف غير معروف'",
      "data['authors'] ?? l10n.myFilesUnknownAuthor");

  // 6. buildDigitalDownloads
  text = text.replaceFirst(
      'Widget _buildDigitalDownloads(BuildContext context) {',
      'Widget _buildDigitalDownloads(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;');
  text = text.replaceAll(
      "const SnackBar(content: Text('لا يوجد رابط للفتح'))",
      "SnackBar(content: Text(l10n.myFilesNoLinkToOpen))");
  text = text.replaceAll(
      "const SnackBar(content: Text('تعذر فتح الملف'))",
      "SnackBar(content: Text(l10n.myFilesCannotOpen))");
  text = text.replaceAll(
      "ScaffoldMessenger.of(context).showSnackBar(\n                    SnackBar(content: Text(l10n.myFilesNoLinkToOpen)),\n                  );",
      "if (context.mounted) {\n                    ScaffoldMessenger.of(context).showSnackBar(\n                      SnackBar(content: Text(l10n.myFilesNoLinkToOpen)),\n                    );\n                  }");
  text = text.replaceAll(
      "ScaffoldMessenger.of(context).showSnackBar(\n                    SnackBar(content: Text(l10n.myFilesCannotOpen)),\n                  );",
      "if (context.mounted) {\n                  ScaffoldMessenger.of(context).showSnackBar(\n                    SnackBar(content: Text(l10n.myFilesCannotOpen)),\n                  );\n                }");
  text = text.replaceAll("'فتح'", "l10n.myFilesTrailingOpen");

  // 7. build screen method
  text = text.replaceFirst(
      "  @override\n  Widget build(BuildContext context) {\n    final bool isMyUploads = title == 'ما رفعته';\n    final bool isReferences = title == 'المراجع';\n    final bool isDownloads = title == 'تنزيلاتي';\n    final bool isShares = title == 'ما شاركته';",
      "  @override\n  Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;\n    final bool isMyUploads = title == l10n.myLibUploadsTitle;\n    final bool isReferences = title == l10n.myLibNavReferences;\n    final bool isDownloads = title == l10n.myLibDownloadsTitle;\n    final bool isShares = title == l10n.myLibSharesTitle;");
  text = text.replaceAll(
      "\'سيتم عرض قائمة \"\$title\" هنا لاحقًا\'",
      "l10n.myFilesFutureList(title)");

  file.writeAsStringSync(text);
  print('Done');
}
