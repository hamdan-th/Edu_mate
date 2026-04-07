import 'dart:io';

void main() {
  final dir = Directory('c:\\Users\\hamda\\StudioProjects\\Edu_mate\\lib\\screens\\library');

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      
      String newContent = content;
      newContent = newContent.replaceAll(
        'border: Border.all(color: LibraryTheme.border(context))', 
        'border: Border.all(color: LibraryTheme.border(context).withOpacity(0.3), width: 0.5)'
      );
      
      newContent = newContent.replaceAll('Alignment.topRight', 'AlignmentDirectional.topStart');
      newContent = newContent.replaceAll('Alignment.topLeft', 'AlignmentDirectional.topStart');
      newContent = newContent.replaceAll('Alignment.bottomLeft', 'AlignmentDirectional.bottomEnd');
      newContent = newContent.replaceAll('Alignment.bottomRight', 'AlignmentDirectional.bottomEnd');

      if (content != newContent) {
        entity.writeAsStringSync(newContent);
        print('Polished borders and alignments in ${entity.path}');
      }
    }
  }
}
