// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get app_name => 'Edu Mate';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'المظهر';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get save => 'حفظ';

  @override
  String get close => 'إغلاق';

  @override
  String get errEnterEmailPass => 'الرجاء إدخال البريد الإلكتروني وكلمة المرور';

  @override
  String get errInvalidEmail => 'البريد الإلكتروني غير صالح';

  @override
  String get errAccountNotFound => 'الحساب غير موجود';

  @override
  String get errWrongPassword => 'كلمة المرور غير صحيحة';

  @override
  String get errInvalidCredentials => 'بيانات الدخول غير صحيحة';

  @override
  String get errAccountDisabled => 'تم تعطيل الحساب';

  @override
  String get errTooManyRequests => 'محاولات كثيرة جداً، حاول لاحقاً';

  @override
  String get errUnexpected => 'حدث خطأ غير متوقع';

  @override
  String get errEmailAlreadyInUse => 'هذا البريد مستخدم بالفعل';

  @override
  String get errWeakPassword => 'كلمة المرور ضعيفة جداً';

  @override
  String get errEmptyUsername => 'أدخل اسم المستخدم';

  @override
  String get errShortUsername => 'اسم المستخدم قصير جدًا';

  @override
  String get errInvalidUsername => 'يسمح فقط بالحروف والأرقام و . و _';

  @override
  String get errEmptyName => 'أدخل الاسم';

  @override
  String get errEmptyEmail => 'أدخل البريد الإلكتروني';

  @override
  String get errEmptyPassword => 'أدخل كلمة المرور';

  @override
  String get errShortPassword => 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';

  @override
  String get errUsernameTaken => 'اسم المستخدم مستخدم بالفعل';

  @override
  String get loginWelcomeBack => 'مرحباً بعودتك';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get loginSubtitle => 'قم بتسجيل الدخول للوصول إلى منصتك';

  @override
  String get loginEmailHint => 'البريد الإلكتروني';

  @override
  String get loginPasswordHint => 'كلمة المرور';

  @override
  String get loginForgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get loginNoAccount => 'ليس لديك حساب؟';

  @override
  String get loginSignupAction => 'إنشاء حساب';

  @override
  String get resetEnterEmailFirst => 'من فضلك أدخل بريدك الإلكتروني أولاً';

  @override
  String get resetLinkSent => 'تم إرسال رابط إعادة تعيين كلمة المرور لبريدك';

  @override
  String get resetFailedSend => 'فشل في إرسال رابط إعادة التعيين';

  @override
  String get resetEmailNotRegistered => 'البريد الإلكتروني غير مسجل';

  @override
  String get signupTitle => 'إنشاء حساب';

  @override
  String get signupSubtitle => 'أنشئ هويتك داخل Edu Mate وابدأ رحلتك';

  @override
  String get signupUsernameHint => 'اسم المستخدم';

  @override
  String get signupFullNameHint => 'الاسم الكامل';

  @override
  String get signupCollegeHint => 'الكلية';

  @override
  String get signupMajorHint => 'التخصص';

  @override
  String get signupBioHint => 'نبذة تعريفية';

  @override
  String get signupBtn => 'إنشاء حساب';

  @override
  String get signupAlreadyHaveAccount => 'لديك حساب بالفعل؟ تسجيل الدخول';

  @override
  String get signupSuccess => 'تم إنشاء الحساب بنجاح';

  @override
  String get signupFailed => 'فشل إنشاء الحساب';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navGroups => 'المجموعات';

  @override
  String get navLibrary => 'المكتبة';

  @override
  String get feedSearchHint => 'البحث...';

  @override
  String get filterForYou => 'لك';

  @override
  String get filterRecent => 'الأحدث';

  @override
  String get filterPopular => 'الرائجة';

  @override
  String get filterAcademic => 'أكاديمي';

  @override
  String get filterCollege => 'الكلية';

  @override
  String get filterMajor => 'التخصص';

  @override
  String get filterCourses => 'المقررات';

  @override
  String get feedErrLoadPosts => 'تعذر تحميل المنشورات';

  @override
  String get feedErrCheckConnection =>
      'تحقق من الاتصال أو من إعدادات Firestore';

  @override
  String get feedEmptyPublicPosts => 'لا يوجد منشورات عامة بعد';

  @override
  String get feedEmptyPublicPostsSub =>
      'ستظهر هنا فقط منشورات المجموعات العامة';

  @override
  String get feedJoinedGroup => 'تم الانضمام للمجموعة';

  @override
  String get feedErrUpdateLike => 'تعذر تحديث الإعجاب';

  @override
  String get feedJoinAction => 'انضمام';

  @override
  String get feedBotName => 'Edu Bot';

  @override
  String get likeAction => 'إعجاب';

  @override
  String get commentAction => 'تعليق';

  @override
  String get shareAction => 'مشاركة';

  @override
  String get timeNow => 'الآن';

  @override
  String get timeMinutesAgo => 'د ق';

  @override
  String get timeHoursAgo => 'س ق';

  @override
  String get timeDaysAgo => 'ي ق';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsBody => 'الإشعارات ستربط لاحقًا';

  @override
  String get errLoginFailed => 'فشل تسجيل الدخول';

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get profileNoUser => 'لا يوجد مستخدم مسجل دخول';

  @override
  String get profileNoData => 'لم يتم العثور على بيانات الملف الشخصي';

  @override
  String get profileVerifiedDoc => 'دكتور موثق';

  @override
  String get profileUserRole => 'مستخدم ';

  @override
  String get profileUsernameLabel => 'اسم المستخدم';

  @override
  String get profileFullNameLabel => 'الاسم الكامل';

  @override
  String get profileEmailLabel => 'البريد الإلكتروني';

  @override
  String get profileBioLabel => 'النبذة';

  @override
  String get profileCollegeLabel => 'الكلية';

  @override
  String get profileSpecialtyLabel => 'التخصص';

  @override
  String get profileReqDocVerification => 'طلب توثيق دكتور';

  @override
  String get profileLogout => 'تسجيل الخروج';

  @override
  String get profileDeleteAccount => 'حذف الحساب';

  @override
  String get profileCancel => 'إلغاء';

  @override
  String get profileDelete => 'حذف';

  @override
  String get profileDeleteConfirm =>
      'هل أنت متأكد؟ سيتم حذف الحساب كاملًا من التطبيق.';

  @override
  String get libFilterSortTitle => 'فلترة وترتيب';

  @override
  String get libFilterReset => 'إعادة ضبط';

  @override
  String get libFilterApply => 'تطبيق';

  @override
  String get libFilterLevel => 'المستوى';

  @override
  String get libSearchHint => 'ابحث باسم المادة أو الدكتور أو التخصص...';

  @override
  String get libSortPrefix => 'الترتيب: ';

  @override
  String get libEmptyTitle => 'لا توجد ملفات مطابقة';

  @override
  String get libEmptyDesc =>
      'جرّب تغيير كلمات البحث أو تخفيف الفلاتر حتى تظهر لك نتائج أكثر.';

  @override
  String get libSortLatest => 'الأحدث';

  @override
  String get libSortMostLiked => 'الأكثر إعجاباً';

  @override
  String get libSortMostViewed => 'الأكثر مشاهدة';

  @override
  String get profileUpdatePhotoSuccess => 'تم تحديث صورة الملف الشخصي';

  @override
  String get profileUpdatePhotoFailed => 'فشل رفع الصورة';

  @override
  String get profileVerificationPending => 'لديك طلب توثيق قيد المراجعة بالفعل';

  @override
  String get profileVerificationSent => 'تم إرسال طلب التوثيق إلى الداشبورد';

  @override
  String get profileVerificationFailed => 'فشل إرسال طلب التوثيق';

  @override
  String get profileLogoutFailed => 'فشل تسجيل الخروج';

  @override
  String get profileDeleteRequiresLogin =>
      'لحذف الحساب يجب تسجيل الدخول من جديد ثم إعادة المحاولة';

  @override
  String get profileDeleteFailed => 'فشل حذف الحساب';

  @override
  String get profileDeleteError => 'حدث خطأ أثناء حذف الحساب';

  @override
  String get libErrorPrefix => 'حدث خطأ: ';

  @override
  String get groupsManageMembersTitle => 'إدارة الأعضاء';

  @override
  String get groupsSearchHint => 'بحث...';

  @override
  String get groupsRoleOwnerTitle => 'المالك';

  @override
  String get groupsRoleAdminsTitle => 'المشرفون';

  @override
  String get groupsRoleMembersTitle => 'الأعضاء';

  @override
  String get groupsDefaultMemberName => 'عضو بالمجموعة';

  @override
  String get groupsRoleOwner => 'مالك';

  @override
  String get groupsRoleAdmin => 'مشرف';

  @override
  String get groupsRoleMember => 'عضو';

  @override
  String get groupsStatusMuted => ' (مكتوم)';

  @override
  String get groupsStatusBanned => ' (محظور)';

  @override
  String get groupsYouMarker => '(أنت)';

  @override
  String get groupsActionRemoveAdmin => 'إزالة من الإشراف';

  @override
  String get groupsActionMakeAdmin => 'تعيين كمشرف';

  @override
  String get groupsActionUnmute => 'إلغاء الكتم';

  @override
  String get groupsActionMute => 'كتم العضو';

  @override
  String get groupsActionKick => 'طرد العضو';

  @override
  String get groupsActionReport => 'إبلاغ';

  @override
  String get groupsActionTransferOwner => 'نقل الملكية';

  @override
  String get groupsEmptySearchTitle => 'لا توجد نتائج';

  @override
  String get groupsEmptySearchDesc =>
      'لم نتمكن من العثور على أعضاء يطابقون بحثك.';

  @override
  String get groupsTransferOwnershipSuccess => 'تم نقل الملكية بنجاح';

  @override
  String get groupsTransferOwnershipError => 'حدث خطأ أثناء نقل الملكية';

  @override
  String get groupsSetAdminSuccess => 'تم تعيين المشرف';

  @override
  String get groupsRemoveAdminSuccess => 'تم إزالة المشرف';

  @override
  String get groupsMuteMemberSuccess => 'تم كتم العضو';

  @override
  String get groupsUnmuteMemberSuccess => 'تم إلغاء كتم العضو';

  @override
  String get groupsReportSent => 'تم إرسال البلاغ لمدير التطبيق';

  @override
  String get groupsKickMemberSuccess => 'تم طرد العضو';

  @override
  String get groupsLoadMembersError => 'تعذر تحميل الأعضاء';

  @override
  String get groupsJoinSuccess => 'تم الانضمام للمجموعة بنجاح';

  @override
  String get groupsNameRequired => 'اسم المجموعة مطلوب';

  @override
  String get groupsSaveSuccess => 'تم الحفظ بنجاح';

  @override
  String get groupsSaveError => 'حدث خطأ أثناء الحفظ';

  @override
  String get groupsMuteNotificationsSuccess => 'تم كتم الإشعارات';

  @override
  String get groupsUnmuteNotificationsSuccess => 'تم تفعيل الإشعارات';

  @override
  String get groupsOwnerLeaveError =>
      'المالك لا يمكنه المغادرة، قم بنقل الملكية أولاً';

  @override
  String get groupsLeaveSuccess => 'تمت المغادرة بنجاح';

  @override
  String get groupsLeaveError => 'حدث خطأ أثناء مغادرة المجموعة';

  @override
  String get groupsReportConfirmTitle => 'تأكيد البلاغ';

  @override
  String get groupsReportConfirmMsg =>
      'هل أنت متأكد من رغبتك في الإبلاغ عن هذه المجموعة؟ سيتم مراجعة محتواها من قبل الإدارة.';

  @override
  String get groupsReportReceived => 'تم استلام البلاغ وسيتم مراجعته';

  @override
  String get groupsActionClearChat => 'مسح سجل الدردشة';

  @override
  String get groupsClearChatConfirmMsg =>
      'هل أنت متأكد من مسح جميع رسائل الدردشة؟ هذا الإجراء لا يمكن التراجع عنه.';

  @override
  String get groupsClearChatSubmit => 'مسح';

  @override
  String get groupsClearChatSuccess => 'تم مسح سجل الدردشة بنجاح';

  @override
  String get groupsClearChatError => 'حدث خطأ أثناء مسح السجل';

  @override
  String get groupsActionCopyLink => 'نسخ الرابط';

  @override
  String get groupsCopyLinkSuccess => 'تم نسخ الرابط';

  @override
  String get groupsActionEditGroup => 'تعديل المجموعة';

  @override
  String get groupsEditTitle => 'تعديل';

  @override
  String get groupsSaveAction => 'حفظ';

  @override
  String get groupsNameLabel => 'اسم المجموعة';

  @override
  String get groupsDescLabel => 'الوصف';

  @override
  String get groupsMemberCountSuffix => 'عضو';

  @override
  String get groupsPublicBadge => 'مجموعة عامة';

  @override
  String get groupsPrivateBadge => 'مجموعة خاصة';

  @override
  String get groupsJoinAction => 'انضمام للمجموعة';

  @override
  String get groupsEnableAction => 'تفعيل';

  @override
  String get groupsMuteAction => 'كتم';

  @override
  String get groupsLeaveAction => 'مغادرة';

  @override
  String get groupsMoreAction => 'المزيد';

  @override
  String get groupsPublishFeedAction => 'نشر في الفيد العام';

  @override
  String get groupsPublishFeedSub => 'مشاركة إعلان أو تحديث لجميع الطلاب';

  @override
  String get groupsAllowMembersChat => 'السماح للأعضاء بالمشاركة في الدردشة';

  @override
  String get groupsTabMembers => 'الأعضاء';

  @override
  String get groupsTabMedia => 'الوسائط';

  @override
  String get groupsTabLinks => 'الروابط';

  @override
  String get groupsTabSaved => 'المحفوظات';

  @override
  String get groupsReportError => 'حدث خطأ أثناء إرسال البلاغ';

  @override
  String get groupsRequiresJoinToView => 'يجب الانضمام للمجموعة لرؤية الأعضاء';

  @override
  String get groupsErrorLoadingMembers => 'حدث خطأ أثناء تحميل الأعضاء';

  @override
  String get groupsEmptyMembersTitle => 'لا يوجد أعضاء في هذه المجموعة';

  @override
  String get groupsErrorLoadingSaved => 'حدث خطأ في تحميل المحفوظات';

  @override
  String get groupsEmptySavedTitle => 'لا توجد رسائل محفوظة';

  @override
  String get groupsDefaultMessageLabel => 'رسالة';

  @override
  String get groupsErrorLoadingMedia => 'خطأ في تحميل الوسائط';

  @override
  String get groupsEmptyMediaTitle => 'لا توجد وسائط';

  @override
  String get groupsErrorLoadingLinks => 'خطأ في تحميل الروابط';

  @override
  String get groupsEmptyLinksTitle => 'لا توجد روابط';

  @override
  String get groupsFilterTitle => 'تصفية النتائج';

  @override
  String get groupsFilterPublicOnly => 'المجموعات العامة فقط';

  @override
  String get groupsFilterPublicOnlySub =>
      'إظهار المجتمعات العامة فقط في النتائج';

  @override
  String get groupsFilterReset => 'إلغاء التصفية';

  @override
  String get groupsFilterApply => 'تطبيق';

  @override
  String get groupsSearchFieldHint => 'ابحث عن مجتمع...';

  @override
  String get groupsAppBarTitle => 'المجتمعات';

  @override
  String get groupsTabDiscover => 'اكتشف';

  @override
  String get groupsTabMyGroups => 'مجموعاتي';

  @override
  String get groupsEmptyDiscoverTitle => 'لا توجد مجتمعات متاحة للاكتشاف';

  @override
  String get groupsEmptyDiscoverSub =>
      'لم نعثر على مجتمعات تطابق معاييرك حاليًا. يمكنك تعديل البحث أو إنشاء مجتمع جديد.';

  @override
  String get groupsEmptyMyGroupsTitle => 'لست عضوًا في أي مجتمع';

  @override
  String get groupsEmptyMyGroupsSub =>
      'انضم إلى المجموعات الأكاديمية للتواصل مع زملائك أو أنشئ مجتمعك الخاص.';

  @override
  String get groupsPillPublic => 'عامة';

  @override
  String get groupsPillPrivate => 'خاصة';

  @override
  String get groupsCardDiscoverSub => 'مجتمع أكاديمي جاهز للانضمام';

  @override
  String get groupsCardMyGroupsSub => 'ادخل وابدأ التفاعل مع أعضاء المجموعة';
}
