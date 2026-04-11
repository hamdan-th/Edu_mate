import 'dart:io';
import 'dart:convert';

void main() {
  final enFile = File(r'lib\l10n\app_en.arb');
  final arFile = File(r'lib\l10n\app_ar.arb');

  final enData = json.decode(enFile.readAsStringSync()) as Map<String, dynamic>;
  final arData = json.decode(arFile.readAsStringSync()) as Map<String, dynamic>;

  enData['pdfBrowseFile'] = 'Browse File';
  arData['pdfBrowseFile'] = 'تصفح الملف';

  final encoder = JsonEncoder.withIndent('  ');
  enFile.writeAsStringSync(encoder.convert(enData));
  arFile.writeAsStringSync(encoder.convert(arData));

  print('Done PDF arbs');
}
