import 'dart:io';

void main() {
  final dir = Directory('c:\\Users\\hamda\\StudioProjects\\Edu_mate\\lib\\screens\\library');
  final pattern = RegExp(r'LibraryTheme\.(primary|secondary|bg|surface|text|muted|border|danger|success|accent|primaryGradient|aquaGradient|amberGradient|mintGradient)\b(?!\()');

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart') && !entity.path.endsWith('library_theme.dart')) {
      final content = entity.readAsStringSync();
      if (pattern.hasMatch(content)) {
        final newContent = content.replaceAllMapped(pattern, (match) => 'LibraryTheme.${match.group(1)}(context)');
        entity.writeAsStringSync(newContent);
        print('Updated ${entity.path}');
      }
    }
  }
}
