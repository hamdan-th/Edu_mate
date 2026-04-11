import 'dart:io';

void main() {
  // 1. file_details_screen.dart
  final fileDetailsPath = r'lib\screens\library\file_details_screen.dart';
  var content = File(fileDetailsPath).readAsStringSync();
  
  // Fix const Text
  content = content.replaceFirst(
    'const Text(\n                            AppLocalizations.of(context)!.detailsBtnSaveEdits,',
    'Text(\n                            AppLocalizations.of(context)!.detailsBtnSaveEdits,'
  );
  // Alternative if no newline
  content = content.replaceFirst(
    'const Text(AppLocalizations.of(context)!.detailsBtnSaveEdits,',
    'Text(AppLocalizations.of(context)!.detailsBtnSaveEdits,'
  );

  // Fix upLabelSpecialization (already partially done but let's be sure)
  content = content.replaceAll('upLabelSpecialization', 'upLabelMajor');

  // Add l10n in build
  if (!content.contains('final l10n = AppLocalizations.of(context)!;')) {
    content = content.replaceFirst(
      'Widget build(BuildContext context) {',
      'Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;'
    );
  }

  File(fileDetailsPath).writeAsStringSync(content);
  print('Fixed file_details_screen.dart');

  // 2. my_files_list_screen.dart
  final myFilesListPath = r'lib\screens\library\my_files_list_screen.dart';
  content = File(myFilesListPath).readAsStringSync();
  if (!content.contains('final l10n = AppLocalizations.of(context)!;') || 
      content.split('final l10n = AppLocalizations.of(context)!;').length <= 2) {
    // We want it specifically in build
    content = content.replaceFirst(
      'Widget build(BuildContext context) {',
      'Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;'
    );
  }
  File(myFilesListPath).writeAsStringSync(content);
  print('Fixed my_files_list_screen.dart');

  // 3. core_result_details_screen.dart
  final coreDetailsPath = r'lib\screens\library\core_result_details_screen.dart';
  content = File(coreDetailsPath).readAsStringSync();
  // Add l10n in _buildInfoRow
  if (!content.contains('Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {\n    final l10n = AppLocalizations.of(context)!;')) {
    content = content.replaceFirst(
      'Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {',
      'Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {\n    final l10n = AppLocalizations.of(context)!;'
    );
  }
  File(coreDetailsPath).writeAsStringSync(content);
  print('Fixed core_result_details_screen.dart');
}
