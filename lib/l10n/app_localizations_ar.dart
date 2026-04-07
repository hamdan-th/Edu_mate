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
}
