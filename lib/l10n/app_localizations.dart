import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @app_name.
  ///
  /// In en, this message translates to:
  /// **'Edu Mate'**
  String get app_name;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @errEnterEmailPass.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email and password'**
  String get errEnterEmailPass;

  /// No description provided for @errInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get errInvalidEmail;

  /// No description provided for @errAccountNotFound.
  ///
  /// In en, this message translates to:
  /// **'Account not found'**
  String get errAccountNotFound;

  /// No description provided for @errWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get errWrongPassword;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials'**
  String get errInvalidCredentials;

  /// No description provided for @errAccountDisabled.
  ///
  /// In en, this message translates to:
  /// **'Account disabled'**
  String get errAccountDisabled;

  /// No description provided for @errTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests, try again later'**
  String get errTooManyRequests;

  /// No description provided for @errUnexpected.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get errUnexpected;

  /// No description provided for @errEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'Email already in use'**
  String get errEmailAlreadyInUse;

  /// No description provided for @errWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak'**
  String get errWeakPassword;

  /// No description provided for @errEmptyUsername.
  ///
  /// In en, this message translates to:
  /// **'Please enter a username'**
  String get errEmptyUsername;

  /// No description provided for @errShortUsername.
  ///
  /// In en, this message translates to:
  /// **'Username is too short'**
  String get errShortUsername;

  /// No description provided for @errInvalidUsername.
  ///
  /// In en, this message translates to:
  /// **'Only letters, numbers, . and _ allowed'**
  String get errInvalidUsername;

  /// No description provided for @errEmptyName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get errEmptyName;

  /// No description provided for @errEmptyEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get errEmptyEmail;

  /// No description provided for @errEmptyPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get errEmptyPassword;

  /// No description provided for @errShortPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get errShortPassword;

  /// No description provided for @errUsernameTaken.
  ///
  /// In en, this message translates to:
  /// **'Username is already taken'**
  String get errUsernameTaken;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginWelcomeBack;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your platform'**
  String get loginSubtitle;

  /// No description provided for @loginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmailHint;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordHint;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get loginNoAccount;

  /// No description provided for @loginSignupAction.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get loginSignupAction;

  /// No description provided for @resetEnterEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email first'**
  String get resetEnterEmailFirst;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to your email'**
  String get resetLinkSent;

  /// No description provided for @resetFailedSend.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset link'**
  String get resetFailedSend;

  /// No description provided for @resetEmailNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'Email not registered'**
  String get resetEmailNotRegistered;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signupTitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your identity in Edu Mate and start your journey'**
  String get signupSubtitle;

  /// No description provided for @signupUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get signupUsernameHint;

  /// No description provided for @signupFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get signupFullNameHint;

  /// No description provided for @signupCollegeHint.
  ///
  /// In en, this message translates to:
  /// **'College'**
  String get signupCollegeHint;

  /// No description provided for @signupMajorHint.
  ///
  /// In en, this message translates to:
  /// **'Major'**
  String get signupMajorHint;

  /// No description provided for @signupBioHint.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get signupBioHint;

  /// No description provided for @signupBtn.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signupBtn;

  /// No description provided for @signupAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get signupAlreadyHaveAccount;

  /// No description provided for @signupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully'**
  String get signupSuccess;

  /// No description provided for @signupFailed.
  ///
  /// In en, this message translates to:
  /// **'Signup failed'**
  String get signupFailed;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get navGroups;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @feedSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search feed...'**
  String get feedSearchHint;

  /// No description provided for @filterCollege.
  ///
  /// In en, this message translates to:
  /// **'College'**
  String get filterCollege;

  /// No description provided for @filterMajor.
  ///
  /// In en, this message translates to:
  /// **'Major'**
  String get filterMajor;

  /// No description provided for @filterCourses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get filterCourses;

  /// No description provided for @feedErrLoadPosts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load posts'**
  String get feedErrLoadPosts;

  /// No description provided for @feedErrCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your connection or Firestore settings'**
  String get feedErrCheckConnection;

  /// No description provided for @feedEmptyPublicPosts.
  ///
  /// In en, this message translates to:
  /// **'No public posts yet'**
  String get feedEmptyPublicPosts;

  /// No description provided for @feedEmptyPublicPostsSub.
  ///
  /// In en, this message translates to:
  /// **'Only public group posts will appear here'**
  String get feedEmptyPublicPostsSub;

  /// No description provided for @feedJoinedGroup.
  ///
  /// In en, this message translates to:
  /// **'Joined group successfully'**
  String get feedJoinedGroup;

  /// No description provided for @feedErrUpdateLike.
  ///
  /// In en, this message translates to:
  /// **'Failed to update like'**
  String get feedErrUpdateLike;

  /// No description provided for @feedJoinAction.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get feedJoinAction;

  /// No description provided for @feedBotName.
  ///
  /// In en, this message translates to:
  /// **'Edu Bot'**
  String get feedBotName;

  /// No description provided for @likeAction.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get likeAction;

  /// No description provided for @commentAction.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get commentAction;

  /// No description provided for @shareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareAction;

  /// No description provided for @timeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get timeNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'m ago'**
  String get timeMinutesAgo;

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'h ago'**
  String get timeHoursAgo;

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'d ago'**
  String get timeDaysAgo;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsBody.
  ///
  /// In en, this message translates to:
  /// **'Notifications will be connected later'**
  String get notificationsBody;

  /// No description provided for @errLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get errLoginFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
