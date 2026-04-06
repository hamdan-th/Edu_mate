import 'dart:io';

void main() {
  final Map<String, List<int>> errors = {
    'lib/screens/home/widgets/post_comments_sheet.dart': [475, 476, 480, 526, 540, 628, 647, 663, 673, 694, 709, 762, 766, 779, 799, 815, 825, 837],
    'lib/screens/library/file_details_screen.dart': [127, 705],
    'lib/screens/library/pdf_preview_screen.dart': [30],
    'lib/screens/library/upload_screen.dart': [345, 398],
  };

  errors.forEach((path, lines) {
    final file = File(path);
    if (!file.existsSync()) return;
    final contentLines = file.readAsLinesSync();
    
    for (int l in lines) {
      final idx = l - 1;
      if (idx >= 0 && idx < contentLines.length) {
        contentLines[idx] = contentLines[idx]
          .replaceAll('const Text(', 'Text(')
          .replaceAll('const TextStyle(', 'TextStyle(')
          .replaceAll('const Icon(', 'Icon(')
          .replaceAll('const SizedBox(', 'SizedBox(')
          .replaceAll('const PopupMenuItem(', 'PopupMenuItem(');
      }
    }
    file.writeAsStringSync(contentLines.join('\n') + '\n');
    print("Fixed const in $path");
  });
}
