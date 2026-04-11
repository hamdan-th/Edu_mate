import 'dart:io';

void main() {
  final file = File(r'c:\Users\hamda\StudioProjects\Edu_mate\lib\screens\library\file_details_screen.dart');
  var text = file.readAsStringSync();

  // 1. imports
  if (!text.contains("import '../../l10n/app_localizations.dart';")) {
    text = text.replaceFirst(
        "import '../../models/group_model.dart';",
        "import '../../models/group_model.dart';\nimport '../../l10n/app_localizations.dart';");
  }

  // 2. format date
  text = text.replaceAll(
      "return 'غير محدد';",
      "return AppLocalizations.of(context)!.detailsUnspecified;");

  // 3. open_file snackbars
  text = text.replaceAll("_snack('لا يوجد رابط للملف')", "_snack(AppLocalizations.of(context)!.myFilesNoLink)");
  text = text.replaceAll("Text('ملف Word')", "Text(AppLocalizations.of(context)!.detailsWordFile)");
  text = text.replaceAll("Text(\n                'هذا النوع لا يُعرض داخل التطبيق حاليًا.\\nاختر فتحه خارجيًا أو تنزيله.',", "Text(\n                AppLocalizations.of(context)!.detailsNoPreview,");
  text = text.replaceAll("label: const Text('تنزيل')", "label: Text(AppLocalizations.of(context)!.detailsDownloadBtn)");
  text = text.replaceAll("_snack('تعذر فتح الملف')", "_snack(AppLocalizations.of(context)!.myFilesCannotOpen)");
  text = text.replaceAll("label: const Text('فتح خارجي')", "label: Text(AppLocalizations.of(context)!.detailsOpenExternalBtn)");

  // 4. shareFileToGroup
  text = text.replaceAll("_snack('لا يوجد رابط لمشاركة الملف')", "_snack(AppLocalizations.of(context)!.detailsNoShareLink)");
  text = text.replaceAll("_snack('أنت غير منضم إلى أي مجموعة بعد')", "_snack(AppLocalizations.of(context)!.detailsNoGroupsJoined)");
  text = text.replaceAll("Text('مشاركة إلى المجموعات',", "Text(AppLocalizations.of(context)!.detailsShareToGroups,");
  text = text.replaceAll("Text(\n                    'اختر المجموعة التي تريد مشاركة الملف فيها',", "Text(\n                    AppLocalizations.of(context)!.detailsSelectGroup,");
  text = text.replaceAll("_snack('تمت مشاركة الملف في مجموعة \${selectedGroup.name}')", "_snack(AppLocalizations.of(context)!.detailsShareSuccess(selectedGroup.name))");
  text = text.replaceAll("_snack('تعذر مشاركة الملف إلى المجموعة: \$e')", "_snack(AppLocalizations.of(context)!.detailsShareFailure(e.toString()))");

  // 5. shareFileExternally
  text = text.replaceAll("_snack('تعذر تسجيل المشاركة: \$e')", "_snack(AppLocalizations.of(context)!.detailsShareGeneralFailure(e.toString()))");
  text = text.replaceFirst(
      "      final text = '''\n📘 \${widget.file.title}\n\nالدكتور: \${widget.file.author}\nالمادة: \${widget.file.course}\nالكلية: \${widget.file.college}\nالتخصص: \${widget.file.major}\nالمستوى: \${widget.file.semester}\n\n\$url\n''';",
      "      final l10n = AppLocalizations.of(context)!;\n      final text = '''\n📘 \${widget.file.title}\n\n\${l10n.upLabelDoctorName}: \${widget.file.author}\n\${l10n.detailsInfoCourse}: \${widget.file.course}\n\${l10n.detailsInfoCollege}: \${widget.file.college}\n\${l10n.detailsInfoSpecialization}: \${widget.file.major}\n\${l10n.detailsInfoLevel}: \${widget.file.semester}\n\n\$url\n''';"
  );

  // 6. downloadFile
  text = text.replaceAll("_snack('لا يوجد رابط للتنزيل')", "_snack(AppLocalizations.of(context)!.myFilesNoLink)");
  text = text.replaceAll("_snack('تم تنزيل الملف وحفظه داخل التطبيق')", "_snack(AppLocalizations.of(context)!.detailsDownloadSuccess)");
  text = text.replaceAll("_snack('فشل التنزيل: \$e')", "_snack(AppLocalizations.of(context)!.detailsDownloadFailure(e.toString()))");

  // 7. _showEditSheet
  text = text.replaceFirst(
    "Text(\n                            'تعديل الملف',",
    "Text(\n                            AppLocalizations.of(context)!.detailsEditTitle,"
  );
  text = text.replaceAll("label: 'اسم المادة / العنوان'", "label: AppLocalizations.of(context)!.upLabelSubjectName");
  text = text.replaceAll("label: 'اسم الدكتور'", "label: AppLocalizations.of(context)!.upLabelDoctorName");
  text = text.replaceAll("label: 'الوصف'", "label: AppLocalizations.of(context)!.detailsSectionDescription");
  text = text.replaceAll("hint: 'الكلية'", "hint: AppLocalizations.of(context)!.upLabelCollege");
  text = text.replaceAll("hint: 'التخصص'", "hint: AppLocalizations.of(context)!.upLabelSpecialization");
  text = text.replaceAll("hint: 'المستوى'", "hint: AppLocalizations.of(context)!.upLabelLevel");
  text = text.replaceAll("hint: 'الترم'", "hint: AppLocalizations.of(context)!.upLabelTerm");
  text = text.replaceAll("_snack('أكمل جميع الحقول المطلوبة')", "_snack(AppLocalizations.of(context)!.detailsFillRequiredFields)");
  text = text.replaceAll("_snack('تم تحديث الملف')", "_snack(AppLocalizations.of(context)!.detailsEditSuccess)");
  text = text.replaceAll("_snack('فشل التعديل: \$e')", "_snack(AppLocalizations.of(context)!.detailsEditFailure(e.toString()))");
  text = text.replaceFirst(
    "Text(\n                            'حفظ التعديلات',",
    "Text(\n                            AppLocalizations.of(context)!.detailsBtnSaveEdits,"
  );

  // 8. confirmDelete
  text = text.replaceFirst(
    "Text(\n          'حذف الملف',",
    "Text(\n          AppLocalizations.of(context)!.detailsDeleteTitle,"
  );
  text = text.replaceFirst(
    "Text(\n          'هل أنت متأكد؟',",
    "Text(\n          AppLocalizations.of(context)!.detailsDeleteConfirm,"
  );
  text = text.replaceFirst(
    "Text(\n              'إلغاء',",
    "Text(\n              AppLocalizations.of(context)!.detailsBtnCancel,"
  );
  text = text.replaceFirst(
    "Text(\n              'حذف',",
    "Text(\n              AppLocalizations.of(context)!.detailsBtnDelete,"
  );
  text = text.replaceAll("_snack('تم حذف الملف')", "_snack(AppLocalizations.of(context)!.detailsDeleteSuccess)");
  text = text.replaceAll("_snack('فشل حذف الملف: \$e')", "_snack(AppLocalizations.of(context)!.detailsDeleteFailure(e.toString()))");

  // 9. build map bindings
  text = text.replaceFirst(
    "Widget build(BuildContext context) {\n    final currentUserId = FirebaseAuth.instance.currentUser?.uid;",
    "Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;\n    final currentUserId = FirebaseAuth.instance.currentUser?.uid;"
  );
  text = text.replaceAll("'د. \${updatedFile.author}'", "l10n.detailsPrefixDr(updatedFile.author)");
  text = text.replaceAll("'رفعه: \${updatedFile.displayUploader}'", "l10n.detailsUploaderPrefix(updatedFile.displayUploader)");
  text = text.replaceFirst("'مشاهدة'", "l10n.detailsStatViews");
  text = text.replaceFirst("'تنزيل'", "l10n.detailsStatDownloads");
  text = text.replaceFirst("'مشاركة'", "l10n.detailsStatShares");
  text = text.replaceFirst("label: 'مشاركة إلى المجموعات'", "label: l10n.detailsShareToGroups");
  text = text.replaceFirst("label: 'إعجاب'", "label: l10n.detailsLikeAction");
  text = text.replaceAll("_snack('تعذر تنفيذ الإعجاب: \$e')", "_snack(l10n.detailsLikeFailure(e.toString()))");
  text = text.replaceFirst("label: 'حفظ'", "label: l10n.detailsSaveAction");
  text = text.replaceAll("_snack('تعذر تنفيذ الحفظ: \$e')", "_snack(l10n.detailsSaveFailure(e.toString()))");
  text = text.replaceFirst("label: 'مشاركة'", "label: l10n.detailsStatShares");
  text = text.replaceFirst("label: 'فتح الملف'", "label: l10n.detailsActionOpenFile");
  text = text.replaceFirst("label: 'تنزيل'", "label: l10n.detailsDownloadBtn");
  
  text = text.replaceFirst(
    "Text(\n                                    'الوصف',",
    "Text(\n                                    l10n.detailsSectionDescription,"
  );
  text = text.replaceFirst(
    "Text(\n                                  'معلومات الملف',",
    "Text(\n                                  l10n.detailsSectionFileInfo,"
  );
  text = text.replaceFirst("label: 'المادة'", "label: l10n.detailsInfoCourse");
  text = text.replaceFirst("label: 'الكلية'", "label: l10n.detailsInfoCollege");
  text = text.replaceFirst("label: 'التخصص'", "label: l10n.detailsInfoSpecialization");
  text = text.replaceFirst("label: 'المستوى'", "label: l10n.detailsInfoLevel");
  text = text.replaceFirst("label: 'النوع'", "label: l10n.detailsInfoType");
  text = text.replaceAll("value: _statusText(updatedFile.status)", "value: _statusText(updatedFile.status, l10n)");
  text = text.replaceFirst("label: 'الحالة'", "label: l10n.detailsInfoStatus");
  text = text.replaceFirst("label: 'تاريخ الرفع'", "label: l10n.detailsInfoDate");

  // 10. static status text
  text = text.replaceFirst(
    "static String _statusText(String status) {",
    "static String _statusText(String status, AppLocalizations l10n) {"
  );
  text = text.replaceAll("return 'منشور';", "return l10n.detailsStatusApproved;");
  text = text.replaceAll("return 'قيد المراجعة';", "return l10n.detailsStatusPending;");
  text = text.replaceAll("return 'مرفوض';", "return l10n.detailsStatusRejected;");

  file.writeAsStringSync(text);
  print('Done details');
}
