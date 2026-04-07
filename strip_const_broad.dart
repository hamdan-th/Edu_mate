import 'dart:io';

void main() {
  final dir = Directory('c:\\Users\\hamda\\StudioProjects\\Edu_mate\\lib\\screens\\library');

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart') && !entity.path.endsWith('library_theme.dart')) {
      final content = entity.readAsStringSync();
      
      String newContent = content;
      newContent = newContent.replaceAll('const BorderSide', 'BorderSide');
      newContent = newContent.replaceAll('const TextStyle', 'TextStyle');
      newContent = newContent.replaceAll('const OutlineInputBorder', 'OutlineInputBorder');
      newContent = newContent.replaceAll('const Row', 'Row');
      newContent = newContent.replaceAll('const Column', 'Column');
      newContent = newContent.replaceAll('const Container', 'Container');
      newContent = newContent.replaceAll('const Padding', 'Padding');
      newContent = newContent.replaceAll('const Center', 'Center');
      newContent = newContent.replaceAll('const Divider', 'Divider');
      newContent = newContent.replaceAll('const Text', 'Text');
      newContent = newContent.replaceAll('const Icon', 'Icon');
      newContent = newContent.replaceAll('const SizedBox', 'SizedBox');
      
      if (content != newContent) {
        entity.writeAsStringSync(newContent);
        print('Stripped const literals in ${entity.path}');
      }
    }
  }
}
