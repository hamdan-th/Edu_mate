import 'dart:io';
import 'dart:convert';

void main() {
  final enFile = File(r'lib\l10n\app_en.arb');
  final arFile = File(r'lib\l10n\app_ar.arb');

  final enData = json.decode(enFile.readAsStringSync()) as Map<String, dynamic>;
  final arData = json.decode(arFile.readAsStringSync()) as Map<String, dynamic>;

  // Additional keys for CoreResultDetailsScreen
  final newKeysAr = {
    "digitalLibNoAbstract": "لا يوجد ملخص متاح.",
    "digitalLibResultDetailsTitle": "تفاصيل البحث",
    "digitalLibLabelAuthors": "المؤلفون:",
    "digitalLibLabelPublisher": "الناشر:",
    "digitalLibLabelYear": "سنة النشر:",
    "digitalLibLabelJournal": "المجلة:",
    "digitalLibSaveErrorParam": "تعذر حفظ المرجع: {error}",
    "digitalLibActionDownloadPdf": "تنزيل PDF",
    "digitalLibDownloadError": "تعذر تسجيل التنزيل: {error}",
    "digitalLibActionOpenSource": "فتح المصدر",
    "digitalLibLabelAbstract": "الملخص (Abstract)"
  };

  final newKeysEn = {
    "digitalLibNoAbstract": "No abstract available.",
    "digitalLibResultDetailsTitle": "Research Details",
    "digitalLibLabelAuthors": "Authors:",
    "digitalLibLabelPublisher": "Publisher:",
    "digitalLibLabelYear": "Publication Year:",
    "digitalLibLabelJournal": "Journal:",
    "digitalLibSaveErrorParam": "Could not save reference: {error}",
    "digitalLibActionDownloadPdf": "Download PDF",
    "digitalLibDownloadError": "Could not register download: {error}",
    "digitalLibActionOpenSource": "Open Source",
    "digitalLibLabelAbstract": "Abstract"
  };

  arData.addAll(newKeysAr);
  enData.addAll(newKeysEn);

  // Add placeholders for param keys
  enData["@digitalLibSaveErrorParam"] = {
    "placeholders": {
      "error": { "type": "String" }
    }
  };
  enData["@digitalLibDownloadError"] = {
    "placeholders": {
      "error": { "type": "String" }
    }
  };

  final encoder = JsonEncoder.withIndent('  ');
  enFile.writeAsStringSync(encoder.convert(enData));
  arFile.writeAsStringSync(encoder.convert(arData));

  print('Done updating ARBs for CoreResultDetailsScreen');
}
