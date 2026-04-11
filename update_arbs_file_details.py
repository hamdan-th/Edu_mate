import json

en_arb_path = r'lib\l10n\app_en.arb'
ar_arb_path = r'lib\l10n\app_ar.arb'

new_en = {
  "detailsUnspecified": "Unspecified",
  "detailsWordFile": "Word File",
  "detailsNoPreview": "This type is not currently displayed inside the app.\nChoose to open externally or download it.",
  "detailsDownloadBtn": "Download",
  "detailsOpenExternalBtn": "Open Externally",
  "detailsNoGroupsJoined": "You haven't joined any groups yet",
  "detailsShareToGroups": "Share to Groups",
  "detailsSelectGroup": "Choose the group you want to share the file with",
  "detailsShareSuccess": "File shared in {groupName} group",
  "@detailsShareSuccess": {
    "placeholders": {
      "groupName": {
        "type": "String"
      }
    }
  },
  "detailsShareFailure": "Could not share file to group: {error}",
  "@detailsShareFailure": {
    "placeholders": {
      "error": {
        "type": "String"
      }
    }
  },
  "detailsNoShareLink": "No link available to share the file",
  "detailsDownloadSuccess": "File downloaded and saved inside the app",
  "detailsEditTitle": "Edit File",
  "detailsEditSuccess": "File updated",
  "detailsEditFailure": "Failed to edit: {error}",
  "@detailsEditFailure": {
    "placeholders": {
      "error": {
        "type": "String"
      }
    }
  },
  "detailsDeleteTitle": "Delete File",
  "detailsDeleteConfirm": "Are you sure?",
  "detailsBtnCancel": "Cancel",
  "detailsBtnDelete": "Delete",
  "detailsDeleteSuccess": "File deleted",
  "detailsDeleteFailure": "Failed to delete file: {error}",
  "@detailsDeleteFailure": {
    "placeholders": {
      "error": {
        "type": "String"
      }
    }
  },
  "detailsDownloadFailure": "Download failed: {error}",
  "@detailsDownloadFailure": {
    "placeholders": {
      "error": {
        "type": "String"
      }
    }
  },
  "detailsShareGeneralFailure": "Could not register share: {error}",
  "@detailsShareGeneralFailure": {
    "placeholders": {
      "error": {
        "type": "String"
      }
    }
  },
  "detailsFillRequiredFields": "Complete all required fields",
  "detailsBtnSaveEdits": "Save Changes",
  "detailsActionOpenFile": "Open File",
  "detailsSectionDescription": "Description",
  "detailsSectionFileInfo": "File Information",
  "detailsInfoCourse": "Course",
  "detailsInfoCollege": "College",
  "detailsInfoSpecialization": "Specialization",
  "detailsInfoLevel": "Level",
  "detailsInfoType": "Type",
  "detailsInfoStatus": "Status",
  "detailsInfoDate": "Upload Date",
  "detailsStatusApproved": "Published",
  "detailsStatusPending": "Under Review",
  "detailsStatusRejected": "Rejected",
  "detailsLikeAction": "Like",
  "detailsLikeFailure": "Could not like: {error}",
  "@detailsLikeFailure": {
    "placeholders": {
      "error": {
        "type": "String"
      }
    }
  },
  "detailsSaveAction": "Save",
  "detailsSaveFailure": "Could not save: {error}",
  "@detailsSaveFailure": {
    "placeholders": {
      "error": {
        "type": "String"
      }
    }
  },
  "detailsUploaderPrefix": "Uploaded by: {uploader}",
  "@detailsUploaderPrefix": {
    "placeholders": {
      "uploader": {
        "type": "String"
      }
    }
  },
  "detailsStatViews": "Views",
  "detailsStatDownloads": "Downloads",
  "detailsStatShares": "Shares",
  "detailsPrefixDr": "Dr. {author}",
  "@detailsPrefixDr": {
    "placeholders": {
      "author": {
        "type": "String"
      }
    }
  }
}

new_ar = {
  "detailsUnspecified": "غير محدد",
  "detailsWordFile": "ملف Word",
  "detailsNoPreview": "هذا النوع لا يُعرض داخل التطبيق حاليًا.\nاختر فتحه خارجيًا أو تنزيله.",
  "detailsDownloadBtn": "تنزيل",
  "detailsOpenExternalBtn": "فتح خارجي",
  "detailsNoGroupsJoined": "أنت غير منضم إلى أي مجموعة بعد",
  "detailsShareToGroups": "مشاركة إلى المجموعات",
  "detailsSelectGroup": "اختر المجموعة التي تريد مشاركة الملف فيها",
  "detailsShareSuccess": "تمت مشاركة الملف في مجموعة {groupName}",
  "detailsShareFailure": "تعذر مشاركة الملف إلى المجموعة: {error}",
  "detailsNoShareLink": "لا يوجد رابط لمشاركة الملف",
  "detailsDownloadSuccess": "تم تنزيل الملف وحفظه داخل التطبيق",
  "detailsEditTitle": "تعديل الملف",
  "detailsEditSuccess": "تم تحديث الملف",
  "detailsEditFailure": "فشل التعديل: {error}",
  "detailsDeleteTitle": "حذف الملف",
  "detailsDeleteConfirm": "هل أنت متأكد؟",
  "detailsBtnCancel": "إلغاء",
  "detailsBtnDelete": "حذف",
  "detailsDeleteSuccess": "تم حذف الملف",
  "detailsDeleteFailure": "فشل حذف الملف: {error}",
  "detailsDownloadFailure": "فشل التنزيل: {error}",
  "detailsShareGeneralFailure": "تعذر تسجيل المشاركة: {error}",
  "detailsFillRequiredFields": "أكمل جميع الحقول المطلوبة",
  "detailsBtnSaveEdits": "حفظ التعديلات",
  "detailsActionOpenFile": "فتح الملف",
  "detailsSectionDescription": "الوصف",
  "detailsSectionFileInfo": "معلومات الملف",
  "detailsInfoCourse": "المادة",
  "detailsInfoCollege": "الكلية",
  "detailsInfoSpecialization": "التخصص",
  "detailsInfoLevel": "المستوى",
  "detailsInfoType": "النوع",
  "detailsInfoStatus": "الحالة",
  "detailsInfoDate": "تاريخ الرفع",
  "detailsStatusApproved": "منشور",
  "detailsStatusPending": "قيد المراجعة",
  "detailsStatusRejected": "مرفوض",
  "detailsLikeAction": "إعجاب",
  "detailsLikeFailure": "تعذر تنفيذ الإعجاب: {error}",
  "detailsSaveAction": "حفظ",
  "detailsSaveFailure": "تعذر تنفيذ الحفظ: {error}",
  "detailsUploaderPrefix": "رفعه: {uploader}",
  "detailsStatViews": "مشاهدة",
  "detailsStatDownloads": "تنزيل",
  "detailsStatShares": "مشاركة",
  "detailsPrefixDr": "د. {author}"
}

with open(en_arb_path, 'r', encoding='utf-8') as f:
    en_data = json.load(f)

with open(ar_arb_path, 'r', encoding='utf-8') as f:
    ar_data = json.load(f)

en_data.update(new_en)
ar_data.update(new_ar)

with open(en_arb_path, 'w', encoding='utf-8', newline='\n') as f:
    json.dump(en_data, f, ensure_ascii=False, indent=2)

with open(ar_arb_path, 'w', encoding='utf-8', newline='\n') as f:
    json.dump(ar_data, f, ensure_ascii=False, indent=2)

print('ARB Update Complete.')
