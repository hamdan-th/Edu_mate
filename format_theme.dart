import 'dart:io';

void main() {
  final files = [
    'lib/screens/groups/group_chat_screen.dart',
    'lib/screens/groups/group_details_screen.dart',
    'lib/screens/groups/manage_members_screen.dart',
    'lib/screens/groups/groups_screen.dart',
    'lib/screens/home/post_comments_screen.dart',
    'lib/screens/home/widgets/post_comments_sheet.dart',
    'lib/screens/library/my_library_screen.dart',
    'lib/screens/library/university_library_screen.dart',
    'lib/screens/library/upload_screen.dart',
    'lib/screens/library/edit_file_screen.dart',
    'lib/screens/library/pdf_viewer_screen.dart',
    'lib/screens/library/file_details_screen.dart',
    'lib/screens/library/digital_library_screen.dart',
    'lib/screens/library/my_files_list_screen.dart',
    'lib/screens/library/pdf_preview_screen.dart'
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;

    String content = file.readAsStringSync();
    
    // Quick check to avoid re-processing or if no Theme.of exists
    if (!content.contains('Theme.of(context)')) continue;
    
    bool changed = false;

    // We'll manually replace known patterns safely
    // 1. Add import if not present
    int depth = path.split('/').length - 2;
    String prefix = '';
    for (int i=0; i<depth; i++) prefix += '../';
    final targetImport = "import '${prefix}core/theme/app_colors.dart';";

    if (!content.contains('app_colors.dart')) {
      final lastImport = content.lastIndexOf(RegExp(r"import\s+[^;]+;"));
      if (lastImport != -1) {
        final endOfLastImport = content.indexOf(';', lastImport) + 1;
        content = content.substring(0, endOfLastImport) + '\n' + targetImport + content.substring(endOfLastImport);
        changed = true;
      }
    }

    // Now replacing patterns
    final map = {
      'Theme.of(context).primaryColor': 'AppColors.primary',
      'Theme.of(context).cardTheme.color': '(Theme.of(context).brightness == Brightness.dark ? AppColors.surface : Colors.white)',
      'Theme.of(context).scaffoldBackgroundColor': '(Theme.of(context).brightness == Brightness.dark ? AppColors.background : const Color(0xFFF8F9FA))',
      'Theme.of(context).textTheme.bodyLarge?.color': '(Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black87)',
      'Theme.of(context).textTheme.bodyMedium?.color': '(Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : Colors.black54)',
      'Theme.of(context).colorScheme.error': 'AppColors.error',
    };
    
    map.forEach((k, v) {
      if (content.contains(k)) {
        content = content.replaceAll(k, v);
        changed = true;
      }
    });
    
    // For divider with opacity
    final dividerReg = RegExp(r"Theme\.of\(context\)\.dividerColor\.withOpacity\((0\.\d+)\)");
    content = content.replaceAllMapped(dividerReg, (Match m) {
      final op = m.group(1);
      changed = true;
      return '(Theme.of(context).brightness == Brightness.dark ? AppColors.border.withOpacity($op) : Colors.black12)';
    });

    if (changed) {
      file.writeAsStringSync(content);
      print("Updated $path");
    }
  }
}
