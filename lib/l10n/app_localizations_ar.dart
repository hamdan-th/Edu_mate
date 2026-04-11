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

  @override
  String get groupsChatImageError =>
      'تعذر اختيار الصورة. تأكد من إعطاء الصلاحيات.';

  @override
  String get groupsChatFileP1Unavailable => 'هذا الملف لم يعد متاحًا';

  @override
  String get groupsChatFileP1Error => 'تعذر فتح الملف الآن';

  @override
  String get groupsChatLeaveOwnerError =>
      'المالك لا يمكنه المغادرة قبل نقل الملكية';

  @override
  String get groupsChatLeaveSuccess => 'لقد غادرت المجموعة';

  @override
  String get groupsChatLeaveError => 'حدث خطأ أثناء مغادرة المجموعة';

  @override
  String get groupsChatMuteSuccess => 'تم كتم الإشعارات';

  @override
  String get groupsChatEnableMembersMsg => 'تم تفعيل دردشة الأعضاء';

  @override
  String get groupsChatDisableMembersMsg => 'تم إيقاف دردشة الأعضاء';

  @override
  String get groupsChatSearchHint => 'ابحث في المحادثة...';

  @override
  String get groupsChatFallbackName => 'الدردشة';

  @override
  String get groupsChatMembersPluralSuffix => 'أعضاء';

  @override
  String get groupsChatDefaultCountName => 'مجموعة';

  @override
  String get groupsChatErrorLoadingMessages => 'تعذر تحميل الرسائل';

  @override
  String get groupsChatNoSearchResults => 'لا توجد نتائج مطابقة';

  @override
  String get groupsChatRequiresJoinTitle => 'يجب الانضمام للمجموعة';

  @override
  String get groupsChatRequiresJoinBody =>
      'هذا المجتمع خاص بأعضائه. افتح معلومات المجموعة أولًا ثم اطلب الانضمام للمشاركة داخل الدردشة.';

  @override
  String get groupsChatDetailsButton => 'عرض معلومات المجموعة';

  @override
  String get groupsChatReplyAction => 'رد';

  @override
  String get groupsChatLibraryFile => 'ملف من المكتبة';

  @override
  String get groupsChatImageAttached => 'صورة مرفقة';

  @override
  String get groupsChatSavedRemoveAction => 'إزالة من المحفوظات';

  @override
  String get groupsChatSaveAction => 'حفظ بنجمة';

  @override
  String get groupsChatSavedRemoveSuccess => 'تمت إزالة الرسالة';

  @override
  String get groupsChatSaveSuccess => 'تم حفظ الرسالة';

  @override
  String get groupsChatSaveError => 'فشلت العملية، يرجى المحاولة لاحقاً';

  @override
  String get groupsChatMemberFallback => 'عضو';

  @override
  String get groupsChatImageDisplayError => 'تعذر عرض الصورة';

  @override
  String get groupsChatOpenFileAction => 'اضغط لفتح الملف';

  @override
  String get groupsChatBannedMsg =>
      'عذرًا، لقد تم حظرك من المشاركة في هذه المجموعة.';

  @override
  String get groupsChatMutedMsg => 'لقد تم كتمك. لا يمكنك الإرسال حاليًا.';

  @override
  String get groupsChatReadOnlyMsg => 'المجموعة للقراءة فقط';

  @override
  String get groupsChatInputHint => 'اكتب رسالة...';

  @override
  String get groupsChatEmptyTitle => 'لا توجد رسائل بعد';

  @override
  String get groupsChatEmptySub =>
      'ابدأ أول محادثة داخل هذا المجتمع وشارك الأفكار والملفات مع الأعضاء.';

  @override
  String get groupsChatTimeAm => 'ص';

  @override
  String get groupsChatTimePm => 'م';

  @override
  String get groupsCreateEmptyNameMsg => 'اكتب اسم المجموعة';

  @override
  String get groupsCreateEmptyCollegeMsg => 'اختر الكلية';

  @override
  String get groupsCreateEmptyMajorMsg => 'اختر التخصص';

  @override
  String get groupsCreateTitle => 'إنشاء مجموعة';

  @override
  String get groupsCreateHeaderTitle => 'مجموعة جديدة';

  @override
  String get groupsCreateHeaderSub => 'أنشئ مساحة دراسية جديدة للنقاش والتعاون';

  @override
  String get groupsCreateInfoLabel => 'معلومات المجموعة';

  @override
  String get groupsCreateDescLabel => 'نبذة عن المجموعة';

  @override
  String get groupsCreateCollegeLabel => 'الكلية';

  @override
  String get groupsCreateMajorLabel => 'التخصص';

  @override
  String get groupsCreateTypeLabel => 'نوع المجموعة';

  @override
  String get groupsCreateTypePublicTitle => 'عامة';

  @override
  String get groupsCreateTypePublicSub => 'يمكن لأي مستخدم الانضمام';

  @override
  String get groupsCreateTypePrivateTitle => 'خاصة';

  @override
  String get groupsCreateTypePrivateSub => 'الانضمام عبر رابط الدعوة';

  @override
  String get groupsCreateBtnLoading => 'جاري الإنشاء...';

  @override
  String get groupsCreateBtn => 'إنشاء المجموعة';

  @override
  String get groupsInviteTitle => 'دعوة مجموعة';

  @override
  String get groupsInviteJoiningLoading => 'جاري الانضمام...';

  @override
  String get groupsInviteNotSpecified => 'غير محدد';

  @override
  String get groupsMakeAdminSuccess => 'تم تعيين المشرف';

  @override
  String get groupsReportMemberSuccess => 'تم إرسال البلاغ لمدير التطبيق';

  @override
  String get groupsActionUnmuteMember => 'إلغاء الكتم';

  @override
  String get groupsActionMuteMember => 'كتم العضو';

  @override
  String get groupsActionKickMember => 'طرد العضو';

  @override
  String get groupsActionTransferOwnership => 'نقل الملكية';

  @override
  String get libraryTabUniversity => 'مكتبة الجامعة';

  @override
  String get libraryTabDigital => 'المكتبة الرقمية';

  @override
  String get libraryTabMyLibrary => 'مكتبتي';

  @override
  String get libraryHeaderSubtitle => 'استكشف وادِر مكتبتك الجامعية بسهولة';

  @override
  String get digitalLibDefaultMessage =>
      'ابحث في ملايين الأوراق البحثية المفتوحة...';

  @override
  String digitalLibNoResults(String query) {
    return 'لم يتم العثور على نتائج لـ \"$query\"';
  }

  @override
  String get digitalLibSearchError =>
      'حدث خطأ أثناء البحث. يرجى التحقق من اتصالك بالإنترنت.';

  @override
  String get digitalLibRemovedFromSaved => 'تمت الإزالة من المحفوظات';

  @override
  String get digitalLibSavedSuccessfully => 'تم الحفظ كمرجع بنجاح';

  @override
  String get digitalLibShareNoLink => 'لا يوجد رابط لمشاركة هذا العنصر';

  @override
  String digitalLibShareText(String title, String url) {
    return 'اطلع على هذه الورقة البحثية:\n$title\n$url';
  }

  @override
  String get digitalLibSearchHint => 'ابحث في CORE (مثال: AI in Medicine)';

  @override
  String get digitalLibNoTitle => 'بدون عنوان';

  @override
  String get digitalLibUnknownAuthor => 'مؤلف غير معروف';

  @override
  String get digitalLibActionSaved => 'تم الحفظ';

  @override
  String get digitalLibActionSave => 'حفظ';

  @override
  String get digitalLibActionShare => 'مشاركة';

  @override
  String get digitalLibActionDetails => 'التفاصيل';

  @override
  String get myLibUploadSuccess =>
      'تم رفع الملف بنجاح، ويمكنك متابعته من مكتبتي';

  @override
  String get myLibStatsTitle => 'مؤشرات مكتبتي';

  @override
  String get myLibStatsSubtitle => 'نظرة سريعة على ملفاتك، محفوظاتك، وتنزيلاتك';

  @override
  String get myLibTotalSavedTitle => 'إجمالي المحفوظات';

  @override
  String get myLibTotalSavedSubtitle => 'المراجع والمصادر الخاصة بك';

  @override
  String get myLibNavReferences => 'المراجع';

  @override
  String get myLibDownloadsTitle => 'تنزيلاتي';

  @override
  String get myLibUploadsTitle => 'ما رفعته';

  @override
  String get myLibSharesTitle => 'مشاركاتي';

  @override
  String get myLibNavShares => 'ما شاركته';

  @override
  String get myLibHeroTitle => 'مكتبتي الشخصية';

  @override
  String get myLibHeroSubtitle => 'إدارة جميع ملفاتك ومصادرك';

  @override
  String get myLibFeatureUpload => 'رفع';

  @override
  String get myLibFeatureSave => 'حفظ';

  @override
  String get myLibFeatureDownload => 'تنزيل';

  @override
  String get myLibBtnUploadNew => 'رفع ملف جديد';

  @override
  String get upErrorFilePick => 'تعذر اختيار الملف';

  @override
  String get upErrorSelectFileFirst => 'اختر ملفًا أولًا';

  @override
  String get upErrorFillRequired => 'أكمل جميع القوائم المطلوبة';

  @override
  String get upErrorLoginRequired => 'يجب تسجيل الدخول أولًا';

  @override
  String get upErrorInvalidCollege => 'اختر الكلية بشكل صحيح';

  @override
  String get upSuccessUploaded => 'تم رفع الملف بنجاح وأصبح ظاهرًا في المكتبة';

  @override
  String get upErrorUploadFailed => 'حدث خطأ أثناء رفع الملف';

  @override
  String get upSectionFileDetailsTitle => 'بيانات الملف';

  @override
  String get upSectionFileDetailsSubtitle =>
      'أدخل المعلومات الأساسية بشكل واضح ومنظم';

  @override
  String get upLabelSubjectName => 'اسم المادة / عنوان الملف';

  @override
  String get upErrorFieldRequired => 'هذا الحقل مطلوب';

  @override
  String get upLabelDoctorName => 'اسم الدكتور';

  @override
  String get upLabelDescription => 'وصف مختصر';

  @override
  String get upSectionAcademicTitle => 'التصنيف الأكاديمي';

  @override
  String get upSectionAcademicSubtitle => 'اختر مكان الملف داخل هيكل الجامعة';

  @override
  String get upLabelCollege => 'الكلية';

  @override
  String get upLabelMajor => 'التخصص';

  @override
  String get upLabelLevel => 'المستوى';

  @override
  String get upLabelTerm => 'الترم';

  @override
  String get upBtnUploadNow => 'رفع الملف الآن';

  @override
  String get upHintDirectUpload =>
      'سيتم رفع الملف مباشرة وإظهاره داخل مكتبة الجامعة.';

  @override
  String get upTitleNewUpload => 'رفع ملف جديد';

  @override
  String get upHeroTitle => 'أضف ملفك للمكتبة';

  @override
  String get upHeroSubtitle =>
      'ارفع الملخصات والمراجع والملفات الدراسية بطريقة منظمة واحترافية.';

  @override
  String get upSectionFileTitle => 'الملف المرفوع';

  @override
  String get upSectionFileSubtitle =>
      'اختر PDF أو Word أو صورة حسب نوع المحتوى';

  @override
  String get upHintFileSelectedSuccess =>
      'تم اختيار الملف بنجاح، ويمكنك الآن إكمال بقية البيانات ثم رفعه.';

  @override
  String get upBtnChangeFile => 'تغيير الملف';

  @override
  String get upBtnSelectFile => 'اضغط لاختيار ملف';

  @override
  String get upHintSupportedTypes =>
      'الأنواع المدعومة: PDF / DOC / DOCX / JPG / PNG';

  @override
  String get upBtnChooseFile => 'اختيار ملف';

  @override
  String get myFilesEmptyDefault => 'لا توجد ملفات';

  @override
  String get myFilesEmptySaved => 'لم تقم بحفظ أي ملفات بعد';

  @override
  String get myFilesEmptyUploads => 'لم تقم برفع أي ملفات بعد';

  @override
  String get myFilesEmptyDownloads => 'لم تقم بتنزيل أي ملفات بعد';

  @override
  String get myFilesEmptyShares => 'لم تقم بمشاركة أي ملفات بعد';

  @override
  String get myFilesNoTitle => 'بدون عنوان';

  @override
  String get myFilesUnknown => 'غير معروف';

  @override
  String get myFilesUnknownAuthor => 'مؤلف غير معروف';

  @override
  String myFilesError(String error) {
    return 'حدث خطأ: $error';
  }

  @override
  String get myFilesNoLink => 'لا يوجد رابط للملف';

  @override
  String get myFilesNoLinkToOpen => 'لا يوجد رابط للفتح';

  @override
  String get myFilesCannotOpen => 'تعذر فتح الملف';

  @override
  String get myFilesSanaUniversity => 'جامعة صنعاء';

  @override
  String get myFilesTrailingOpen => 'فتح';

  @override
  String myFilesFutureList(String title) {
    return 'سيتم عرض قائمة \"$title\" هنا لاحقًا';
  }

  @override
  String get detailsUnspecified => 'غير محدد';

  @override
  String get detailsWordFile => 'ملف Word';

  @override
  String get detailsNoPreview =>
      'هذا النوع لا يُعرض داخل التطبيق حاليًا.\nاختر فتحه خارجيًا أو تنزيله.';

  @override
  String get detailsDownloadBtn => 'تنزيل';

  @override
  String get detailsOpenExternalBtn => 'فتح خارجي';

  @override
  String get detailsNoGroupsJoined => 'أنت غير منضم إلى أي مجموعة بعد';

  @override
  String get detailsShareToGroups => 'مشاركة إلى المجموعات';

  @override
  String get detailsSelectGroup => 'اختر المجموعة التي تريد مشاركة الملف فيها';

  @override
  String detailsShareSuccess(String groupName) {
    return 'تمت مشاركة الملف في مجموعة $groupName';
  }

  @override
  String detailsShareFailure(String error) {
    return 'تعذر مشاركة الملف إلى المجموعة: $error';
  }

  @override
  String get detailsNoShareLink => 'لا يوجد رابط لمشاركة الملف';

  @override
  String get detailsDownloadSuccess => 'تم تنزيل الملف وحفظه داخل التطبيق';

  @override
  String get detailsEditTitle => 'تعديل الملف';

  @override
  String get detailsEditSuccess => 'تم تحديث الملف';

  @override
  String detailsEditFailure(String error) {
    return 'فشل التعديل: $error';
  }

  @override
  String get detailsDeleteTitle => 'حذف الملف';

  @override
  String get detailsDeleteConfirm => 'هل أنت متأكد؟';

  @override
  String get detailsBtnCancel => 'إلغاء';

  @override
  String get detailsBtnDelete => 'حذف';

  @override
  String get detailsDeleteSuccess => 'تم حذف الملف';

  @override
  String detailsDeleteFailure(String error) {
    return 'فشل حذف الملف: $error';
  }

  @override
  String detailsDownloadFailure(String error) {
    return 'فشل التنزيل: $error';
  }

  @override
  String detailsShareGeneralFailure(String error) {
    return 'تعذر تسجيل المشاركة: $error';
  }

  @override
  String get detailsFillRequiredFields => 'أكمل جميع الحقول المطلوبة';

  @override
  String get detailsBtnSaveEdits => 'حفظ التعديلات';

  @override
  String get detailsActionOpenFile => 'فتح الملف';

  @override
  String get detailsSectionDescription => 'الوصف';

  @override
  String get detailsSectionFileInfo => 'معلومات الملف';

  @override
  String get detailsInfoCourse => 'المادة';

  @override
  String get detailsInfoCollege => 'الكلية';

  @override
  String get detailsInfoSpecialization => 'التخصص';

  @override
  String get detailsInfoLevel => 'المستوى';

  @override
  String get detailsInfoType => 'النوع';

  @override
  String get detailsInfoStatus => 'الحالة';

  @override
  String get detailsInfoDate => 'تاريخ الرفع';

  @override
  String get detailsStatusApproved => 'منشور';

  @override
  String get detailsStatusPending => 'قيد المراجعة';

  @override
  String get detailsStatusRejected => 'مرفوض';

  @override
  String get detailsLikeAction => 'إعجاب';

  @override
  String detailsLikeFailure(String error) {
    return 'تعذر تنفيذ الإعجاب: $error';
  }

  @override
  String get detailsSaveAction => 'حفظ';

  @override
  String detailsSaveFailure(String error) {
    return 'تعذر تنفيذ الحفظ: $error';
  }

  @override
  String detailsUploaderPrefix(String uploader) {
    return 'رفعه: $uploader';
  }

  @override
  String get detailsStatViews => 'مشاهدة';

  @override
  String get detailsStatDownloads => 'تنزيل';

  @override
  String get detailsStatShares => 'مشاركة';

  @override
  String detailsPrefixDr(String author) {
    return 'د. $author';
  }

  @override
  String get pdfBrowseFile => 'تصفح الملف';

  @override
  String get digitalLibNoAbstract => 'لا يوجد ملخص متاح.';

  @override
  String get digitalLibResultDetailsTitle => 'تفاصيل البحث';

  @override
  String get digitalLibLabelAuthors => 'المؤلفون:';

  @override
  String get digitalLibLabelPublisher => 'الناشر:';

  @override
  String get digitalLibLabelYear => 'سنة النشر:';

  @override
  String get digitalLibLabelJournal => 'المجلة:';

  @override
  String digitalLibSaveErrorParam(String error) {
    return 'تعذر حفظ المرجع: $error';
  }

  @override
  String get digitalLibActionDownloadPdf => 'تنزيل PDF';

  @override
  String digitalLibDownloadError(String error) {
    return 'تعذر تسجيل التنزيل: $error';
  }

  @override
  String get digitalLibActionOpenSource => 'فتح المصدر';

  @override
  String get digitalLibLabelAbstract => 'الملخص (Abstract)';

  @override
  String get notificationsMarkAllRead => 'تحديد الكل كمقروء';

  @override
  String get notificationsMarkAllReadSuccess =>
      'تم تحديد جميع الإشعارات كمقروءة';

  @override
  String get notificationsSectionToday => 'اليوم';

  @override
  String get notificationsSectionEarlier => 'الأقدم';

  @override
  String get notificationsEmptyTitle => 'لا توجد إشعارات الآن';

  @override
  String get notificationsEmptyDesc =>
      'عندما يكون لديك تفاعل جديد أو تحديث مهم، سيظهر هنا بشكل واضح.';

  @override
  String get notifGroupCreatedTitle => 'تم إنشاء المجموعة';

  @override
  String notifGroupCreatedBody(String name) {
    return 'تم إنشاء مجموعتك $name وأصبحت جاهزة الآن.';
  }

  @override
  String get notifGroupJoinedTitle => 'تم الانضمام للمجموعة';

  @override
  String notifGroupJoinedBody(String name) {
    return 'أصبحت الآن عضواً في $name';
  }

  @override
  String get notifGroupJoinedPrivateTitle => 'تم الانضمام لمجموعة خاصة';

  @override
  String notifGroupJoinedPrivateBody(String name) {
    return 'أصبحت الآن عضواً في $name';
  }

  @override
  String get notifGroupOwnershipTransferredTitle => 'نقل ملكية المجموعة';

  @override
  String notifGroupOwnershipTransferredBody(String name) {
    return 'أصبحت الآن مالكاً لمجموعة $name';
  }

  @override
  String get notifGroupPromotedAdminTitle => 'تمت ترقيتك لمشرف';

  @override
  String notifGroupPromotedAdminBody(String name) {
    return 'أصبحت الآن مشرفاً في مجموعة $name';
  }

  @override
  String get notifGroupDemotedAdminTitle => 'إزالة صلاحيات الإشراف';

  @override
  String notifGroupDemotedAdminBody(String name) {
    return 'لم تعد مشرفاً في مجموعة $name';
  }

  @override
  String get notifGroupMutedTitle => 'تم كتمك في المجموعة';

  @override
  String notifGroupMutedBody(String name) {
    return 'لم يعد بإمكانك إرسال رسائل في $name';
  }

  @override
  String get notifGroupUnmutedTitle => 'تم فك الكتم';

  @override
  String notifGroupUnmutedBody(String name) {
    return 'يمكنك الآن إرسال الرسائل مجدداً في $name';
  }

  @override
  String get notifGroupKickedTitle => 'تمت إزالتك من المجموعة';

  @override
  String notifGroupKickedBody(String name) {
    return 'تمت إزالة عضويتك من مجموعة $name';
  }

  @override
  String get notifNewCommentTitle => 'تعليق جديد';

  @override
  String notifNewCommentBody(String sender) {
    return '$sender علّق على منشورك';
  }

  @override
  String get notifNewReplyTitle => 'رد جديد';

  @override
  String notifNewReplyBody(String sender) {
    return '$sender رد على تعليقك';
  }

  @override
  String get notifLibraryFileApprovedTitle => 'تمت الموافقة على الملف';

  @override
  String notifLibraryFileApprovedBody(String name) {
    return 'تم قبول ملف $name وإتاحته في المكتبة';
  }

  @override
  String get notifLibraryFileUploadedTitle => 'تم الرفع بنجاح';

  @override
  String notifLibraryFileUploadedBody(String name) {
    return 'ملف $name متاح الآن في المكتبة';
  }

  @override
  String get timeYesterday => 'أمس';

  @override
  String timeMinutesAgoParam(int count) {
    return 'منذ $count د';
  }

  @override
  String timeHoursAgoParam(int count) {
    return 'منذ $count س';
  }

  @override
  String timeDaysAgoParam(int count) {
    return 'منذ $count أيام';
  }

  @override
  String get upFileTypePdf => 'بي دي اف';

  @override
  String get upFileTypeWord => 'وورد';

  @override
  String get upFileTypeImage => 'صورة';

  @override
  String get upFileTypeGeneric => 'ملف';
}
