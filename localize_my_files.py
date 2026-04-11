import sys
import re

file_path = r'c:\Users\hamda\StudioProjects\Edu_mate\lib\screens\library\my_files_list_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. buildMyUploads
text = re.sub(
    r'Widget _buildMyUploads\(BuildContext context\) \{',
    r'Widget _buildMyUploads(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;',
    text
)
text = re.sub(
    r"'حدث خطأ: \$\{snapshot\.error\}'",
    r'l10n.myFilesError(snapshot.error.toString())',
    text
)

# 2. buildSavedReferences
text = re.sub(
    r'Widget _buildSavedReferences\(BuildContext context\) \{',
    r'Widget _buildSavedReferences(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;',
    text
)
text = re.sub(
    r"'يجب تسجيل الدخول أولاً'",
    r'l10n.upErrorLoginRequired',
    text
)
text = re.sub(
    r"'حدث خطأ: \$\{saveSnapshot\.error\}'",
    r'l10n.myFilesError(saveSnapshot.error.toString())',
    text
)
text = re.sub(
    r"'حدث خطأ: \$\{filesSnapshot\.error\}'",
    r'l10n.myFilesError(filesSnapshot.error.toString())',
    text
)

# 3. buildDownloads
text = re.sub(
    r'Widget _buildDownloads\(BuildContext context\) \{',
    r'Widget _buildDownloads(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;',
    text
)
text = re.sub(
    r"'حدث خطأ: \$\{downloadSnapshot\.error\}'",
    r'l10n.myFilesError(downloadSnapshot.error.toString())',
    text
)

# 4. buildShares
text = re.sub(
    r'Widget _buildShares\(BuildContext context\) \{',
    r'Widget _buildShares(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;',
    text
)
text = re.sub(
    r"'حدث خطأ: \$\{shareSnapshot\.error\}'",
    r'l10n.myFilesError(shareSnapshot.error.toString())',
    text
)

# 5. buildDigitalSavedReferences
text = re.sub(
    r'Widget _buildDigitalSavedReferences\(BuildContext context\) \{',
    r'Widget _buildDigitalSavedReferences(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;',
    text
)
text = re.sub(
    r"\(\w+\['title'\] \?\? 'بدون عنوان'\)",
    r"(data['title'] ?? l10n.myFilesNoTitle)",
    text
)
text = re.sub(
    r"\(\w+\['authors'\] \?\? 'مؤلف غير معروف'\)",
    r"(data['authors'] ?? l10n.myFilesUnknownAuthor)",
    text
)

# 6. buildDigitalDownloads
text = re.sub(
    r'Widget _buildDigitalDownloads\(BuildContext context\) \{',
    r'Widget _buildDigitalDownloads(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;',
    text
)
text = text.replace(
    "const SnackBar(content: Text('لا يوجد رابط للفتح'))",
    "SnackBar(content: Text(l10n.myFilesNoLinkToOpen))"
)
text = text.replace(
    "const SnackBar(content: Text('تعذر فتح الملف'))",
    "SnackBar(content: Text(l10n.myFilesCannotOpen))"
)
text = re.sub(
    r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(content: Text\(l10n\.myFilesNoLinkToOpen\)\),\s*\);",
    r"if (context.mounted) {\n                    ScaffoldMessenger.of(context).showSnackBar(\n                      SnackBar(content: Text(l10n.myFilesNoLinkToOpen)),\n                    );\n                  }",
    text
)
text = re.sub(
    r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(content: Text\(l10n\.myFilesCannotOpen\)\),\s*\);",
    r"if (context.mounted) {\n                  ScaffoldMessenger.of(context).showSnackBar(\n                    SnackBar(content: Text(l10n.myFilesCannotOpen)),\n                  );\n                }",
    text
)
text = text.replace("'فتح'", "l10n.myFilesTrailingOpen")

# 7. build screen method
text = re.sub(
    r"  @override\s*Widget build\(BuildContext context\) \{\s*final bool isMyUploads = title == 'ما رفعته';\s*final bool isReferences = title == 'المراجع';\s*final bool isDownloads = title == 'تنزيلاتي';\s*final bool isShares = title == 'ما شاركته';",
    r"  @override\n  Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;\n    final bool isMyUploads = title == l10n.myLibUploadsTitle;\n    final bool isReferences = title == l10n.myLibNavReferences;\n    final bool isDownloads = title == l10n.myLibDownloadsTitle;\n    final bool isShares = title == l10n.myLibSharesTitle;",
    text
)
text = re.sub(
    r"'سيتم عرض قائمة \"\$title\" هنا لاحقًا'",
    r"l10n.myFilesFutureList(title)",
    text
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(text)

print('Done')
