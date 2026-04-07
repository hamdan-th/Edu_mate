import 'dart:io';

void main() {
  final dir = Directory('c:\\Users\\hamda\\StudioProjects\\Edu_mate\\lib\\screens\\library');

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart') && !entity.path.endsWith('library_theme.dart')) {
      final content = entity.readAsStringSync();
      
      String newContent = content;
      newContent = newContent.replaceAllMapped(
          RegExp(r'const\s+((BoxDecoration|TextStyle|Icon|Row|Column|Container|Padding|Center|Divider|SingleChildScrollView|ClipRRect|LinearGradient|Widget|Text|SizedBox|ChoiceChip)\b)'), 
          (match) => match.group(1)!
      );
      newContent = newContent.replaceAll(RegExp(r'const\s+\['), '[');
      newContent = newContent.replaceAll(RegExp(r'const\s+\{'), '{');
      
      if (content != newContent) {
        entity.writeAsStringSync(newContent);
        print('Stripped const in ${entity.path}');
      }
    }
  }
}
