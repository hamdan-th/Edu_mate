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

  /// No description provided for @filterForYou.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get filterForYou;

  /// No description provided for @filterRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get filterRecent;

  /// No description provided for @filterPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get filterPopular;

  /// No description provided for @filterAcademic.
  ///
  /// In en, this message translates to:
  /// **'Academic'**
  String get filterAcademic;

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

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileNoUser.
  ///
  /// In en, this message translates to:
  /// **'No user logged in'**
  String get profileNoUser;

  /// No description provided for @profileNoData.
  ///
  /// In en, this message translates to:
  /// **'Profile data not found'**
  String get profileNoData;

  /// No description provided for @profileVerifiedDoc.
  ///
  /// In en, this message translates to:
  /// **'Verified Doctor'**
  String get profileVerifiedDoc;

  /// No description provided for @profileUserRole.
  ///
  /// In en, this message translates to:
  /// **'User '**
  String get profileUserRole;

  /// No description provided for @profileUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get profileUsernameLabel;

  /// No description provided for @profileFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get profileFullNameLabel;

  /// No description provided for @profileEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmailLabel;

  /// No description provided for @profileBioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get profileBioLabel;

  /// No description provided for @profileCollegeLabel.
  ///
  /// In en, this message translates to:
  /// **'College'**
  String get profileCollegeLabel;

  /// No description provided for @profileSpecialtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Major'**
  String get profileSpecialtyLabel;

  /// No description provided for @profileReqDocVerification.
  ///
  /// In en, this message translates to:
  /// **'Request Doctor Verification'**
  String get profileReqDocVerification;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get profileLogout;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get profileDeleteAccount;

  /// No description provided for @profileCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileCancel;

  /// No description provided for @profileDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get profileDelete;

  /// No description provided for @profileDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? Your account will be permanently deleted.'**
  String get profileDeleteConfirm;

  /// No description provided for @libFilterSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter and Sort'**
  String get libFilterSortTitle;

  /// No description provided for @libFilterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get libFilterReset;

  /// No description provided for @libFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get libFilterApply;

  /// No description provided for @libFilterLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get libFilterLevel;

  /// No description provided for @libSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by subject, doctor, or major...'**
  String get libSearchHint;

  /// No description provided for @libSortPrefix.
  ///
  /// In en, this message translates to:
  /// **'Sort: '**
  String get libSortPrefix;

  /// No description provided for @libEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching files'**
  String get libEmptyTitle;

  /// No description provided for @libEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Try changing search keywords or lightening filters to see more results.'**
  String get libEmptyDesc;

  /// No description provided for @libSortLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get libSortLatest;

  /// No description provided for @libSortMostLiked.
  ///
  /// In en, this message translates to:
  /// **'Most Liked'**
  String get libSortMostLiked;

  /// No description provided for @libSortMostViewed.
  ///
  /// In en, this message translates to:
  /// **'Most Viewed'**
  String get libSortMostViewed;

  /// No description provided for @profileUpdatePhotoSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get profileUpdatePhotoSuccess;

  /// No description provided for @profileUpdatePhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo'**
  String get profileUpdatePhotoFailed;

  /// No description provided for @profileVerificationPending.
  ///
  /// In en, this message translates to:
  /// **'You already have a pending verification request'**
  String get profileVerificationPending;

  /// No description provided for @profileVerificationSent.
  ///
  /// In en, this message translates to:
  /// **'Verification request sent to dashboard'**
  String get profileVerificationSent;

  /// No description provided for @profileVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send request'**
  String get profileVerificationFailed;

  /// No description provided for @profileLogoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Logout failed'**
  String get profileLogoutFailed;

  /// No description provided for @profileDeleteRequiresLogin.
  ///
  /// In en, this message translates to:
  /// **'To delete account, please login again and retry'**
  String get profileDeleteRequiresLogin;

  /// No description provided for @profileDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account'**
  String get profileDeleteFailed;

  /// No description provided for @profileDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while deleting account'**
  String get profileDeleteError;

  /// No description provided for @libErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: '**
  String get libErrorPrefix;

  /// No description provided for @groupsManageMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Members'**
  String get groupsManageMembersTitle;

  /// No description provided for @groupsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get groupsSearchHint;

  /// No description provided for @groupsRoleOwnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get groupsRoleOwnerTitle;

  /// No description provided for @groupsRoleAdminsTitle.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get groupsRoleAdminsTitle;

  /// No description provided for @groupsRoleMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get groupsRoleMembersTitle;

  /// No description provided for @groupsDefaultMemberName.
  ///
  /// In en, this message translates to:
  /// **'Group member'**
  String get groupsDefaultMemberName;

  /// No description provided for @groupsRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get groupsRoleOwner;

  /// No description provided for @groupsRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get groupsRoleAdmin;

  /// No description provided for @groupsRoleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get groupsRoleMember;

  /// No description provided for @groupsStatusMuted.
  ///
  /// In en, this message translates to:
  /// **' (Muted)'**
  String get groupsStatusMuted;

  /// No description provided for @groupsStatusBanned.
  ///
  /// In en, this message translates to:
  /// **' (Banned)'**
  String get groupsStatusBanned;

  /// No description provided for @groupsYouMarker.
  ///
  /// In en, this message translates to:
  /// **'(You)'**
  String get groupsYouMarker;

  /// No description provided for @groupsActionRemoveAdmin.
  ///
  /// In en, this message translates to:
  /// **'Remove Admin'**
  String get groupsActionRemoveAdmin;

  /// No description provided for @groupsActionMakeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Make Admin'**
  String get groupsActionMakeAdmin;

  /// No description provided for @groupsActionUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get groupsActionUnmute;

  /// No description provided for @groupsActionMute.
  ///
  /// In en, this message translates to:
  /// **'Mute Member'**
  String get groupsActionMute;

  /// No description provided for @groupsActionKick.
  ///
  /// In en, this message translates to:
  /// **'Kick Member'**
  String get groupsActionKick;

  /// No description provided for @groupsActionReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get groupsActionReport;

  /// No description provided for @groupsActionTransferOwner.
  ///
  /// In en, this message translates to:
  /// **'Transfer Ownership'**
  String get groupsActionTransferOwner;

  /// No description provided for @groupsEmptySearchTitle.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get groupsEmptySearchTitle;

  /// No description provided for @groupsEmptySearchDesc.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any members matching your search.'**
  String get groupsEmptySearchDesc;

  /// No description provided for @groupsTransferOwnershipSuccess.
  ///
  /// In en, this message translates to:
  /// **'Ownership transferred successfully'**
  String get groupsTransferOwnershipSuccess;

  /// No description provided for @groupsTransferOwnershipError.
  ///
  /// In en, this message translates to:
  /// **'Error transferring ownership'**
  String get groupsTransferOwnershipError;

  /// No description provided for @groupsSetAdminSuccess.
  ///
  /// In en, this message translates to:
  /// **'Admin appointed'**
  String get groupsSetAdminSuccess;

  /// No description provided for @groupsRemoveAdminSuccess.
  ///
  /// In en, this message translates to:
  /// **'Admin removed'**
  String get groupsRemoveAdminSuccess;

  /// No description provided for @groupsMuteMemberSuccess.
  ///
  /// In en, this message translates to:
  /// **'Member muted'**
  String get groupsMuteMemberSuccess;

  /// No description provided for @groupsUnmuteMemberSuccess.
  ///
  /// In en, this message translates to:
  /// **'Member unmuted'**
  String get groupsUnmuteMemberSuccess;

  /// No description provided for @groupsReportSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent to app manager'**
  String get groupsReportSent;

  /// No description provided for @groupsKickMemberSuccess.
  ///
  /// In en, this message translates to:
  /// **'Member kicked'**
  String get groupsKickMemberSuccess;

  /// No description provided for @groupsLoadMembersError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load members'**
  String get groupsLoadMembersError;

  /// No description provided for @groupsJoinSuccess.
  ///
  /// In en, this message translates to:
  /// **'Joined group successfully'**
  String get groupsJoinSuccess;

  /// No description provided for @groupsNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Group name is required'**
  String get groupsNameRequired;

  /// No description provided for @groupsSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get groupsSaveSuccess;

  /// No description provided for @groupsSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving'**
  String get groupsSaveError;

  /// No description provided for @groupsMuteNotificationsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Notifications muted'**
  String get groupsMuteNotificationsSuccess;

  /// No description provided for @groupsUnmuteNotificationsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Notifications unmuted'**
  String get groupsUnmuteNotificationsSuccess;

  /// No description provided for @groupsOwnerLeaveError.
  ///
  /// In en, this message translates to:
  /// **'Owner cannot leave without transferring ownership'**
  String get groupsOwnerLeaveError;

  /// No description provided for @groupsLeaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Left group successfully'**
  String get groupsLeaveSuccess;

  /// No description provided for @groupsLeaveError.
  ///
  /// In en, this message translates to:
  /// **'Error leaving group'**
  String get groupsLeaveError;

  /// No description provided for @groupsReportConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Report'**
  String get groupsReportConfirmTitle;

  /// No description provided for @groupsReportConfirmMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to report this group? Its content will be reviewed by administration.'**
  String get groupsReportConfirmMsg;

  /// No description provided for @groupsReportReceived.
  ///
  /// In en, this message translates to:
  /// **'Report received and will be reviewed'**
  String get groupsReportReceived;

  /// No description provided for @groupsActionClearChat.
  ///
  /// In en, this message translates to:
  /// **'Clear Chat History'**
  String get groupsActionClearChat;

  /// No description provided for @groupsClearChatConfirmMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all chat messages? This action cannot be undone.'**
  String get groupsClearChatConfirmMsg;

  /// No description provided for @groupsClearChatSubmit.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get groupsClearChatSubmit;

  /// No description provided for @groupsClearChatSuccess.
  ///
  /// In en, this message translates to:
  /// **'Chat history cleared successfully'**
  String get groupsClearChatSuccess;

  /// No description provided for @groupsClearChatError.
  ///
  /// In en, this message translates to:
  /// **'Error clearing history'**
  String get groupsClearChatError;

  /// No description provided for @groupsActionCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get groupsActionCopyLink;

  /// No description provided for @groupsCopyLinkSuccess.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get groupsCopyLinkSuccess;

  /// No description provided for @groupsActionEditGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit Group'**
  String get groupsActionEditGroup;

  /// No description provided for @groupsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get groupsEditTitle;

  /// No description provided for @groupsSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get groupsSaveAction;

  /// No description provided for @groupsNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupsNameLabel;

  /// No description provided for @groupsDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get groupsDescLabel;

  /// No description provided for @groupsMemberCountSuffix.
  ///
  /// In en, this message translates to:
  /// **'member'**
  String get groupsMemberCountSuffix;

  /// No description provided for @groupsPublicBadge.
  ///
  /// In en, this message translates to:
  /// **'Public Group'**
  String get groupsPublicBadge;

  /// No description provided for @groupsPrivateBadge.
  ///
  /// In en, this message translates to:
  /// **'Private Group'**
  String get groupsPrivateBadge;

  /// No description provided for @groupsJoinAction.
  ///
  /// In en, this message translates to:
  /// **'Join Group'**
  String get groupsJoinAction;

  /// No description provided for @groupsEnableAction.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get groupsEnableAction;

  /// No description provided for @groupsMuteAction.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get groupsMuteAction;

  /// No description provided for @groupsLeaveAction.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get groupsLeaveAction;

  /// No description provided for @groupsMoreAction.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get groupsMoreAction;

  /// No description provided for @groupsPublishFeedAction.
  ///
  /// In en, this message translates to:
  /// **'Publish to Public Feed'**
  String get groupsPublishFeedAction;

  /// No description provided for @groupsPublishFeedSub.
  ///
  /// In en, this message translates to:
  /// **'Share an announcement or update with all students'**
  String get groupsPublishFeedSub;

  /// No description provided for @groupsAllowMembersChat.
  ///
  /// In en, this message translates to:
  /// **'Allow members to chat'**
  String get groupsAllowMembersChat;

  /// No description provided for @groupsTabMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get groupsTabMembers;

  /// No description provided for @groupsTabMedia.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get groupsTabMedia;

  /// No description provided for @groupsTabLinks.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get groupsTabLinks;

  /// No description provided for @groupsTabSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get groupsTabSaved;

  /// No description provided for @groupsReportError.
  ///
  /// In en, this message translates to:
  /// **'Error sending report'**
  String get groupsReportError;

  /// No description provided for @groupsRequiresJoinToView.
  ///
  /// In en, this message translates to:
  /// **'You must join the group to view members'**
  String get groupsRequiresJoinToView;

  /// No description provided for @groupsErrorLoadingMembers.
  ///
  /// In en, this message translates to:
  /// **'Error loading members'**
  String get groupsErrorLoadingMembers;

  /// No description provided for @groupsEmptyMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'No members in this group'**
  String get groupsEmptyMembersTitle;

  /// No description provided for @groupsErrorLoadingSaved.
  ///
  /// In en, this message translates to:
  /// **'Error loading saved messages'**
  String get groupsErrorLoadingSaved;

  /// No description provided for @groupsEmptySavedTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved messages'**
  String get groupsEmptySavedTitle;

  /// No description provided for @groupsDefaultMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get groupsDefaultMessageLabel;

  /// No description provided for @groupsErrorLoadingMedia.
  ///
  /// In en, this message translates to:
  /// **'Error loading media'**
  String get groupsErrorLoadingMedia;

  /// No description provided for @groupsEmptyMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'No media found'**
  String get groupsEmptyMediaTitle;

  /// No description provided for @groupsErrorLoadingLinks.
  ///
  /// In en, this message translates to:
  /// **'Error loading links'**
  String get groupsErrorLoadingLinks;

  /// No description provided for @groupsEmptyLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'No links found'**
  String get groupsEmptyLinksTitle;

  /// No description provided for @groupsFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter Results'**
  String get groupsFilterTitle;

  /// No description provided for @groupsFilterPublicOnly.
  ///
  /// In en, this message translates to:
  /// **'Public Groups Only'**
  String get groupsFilterPublicOnly;

  /// No description provided for @groupsFilterPublicOnlySub.
  ///
  /// In en, this message translates to:
  /// **'Show only public communities in results'**
  String get groupsFilterPublicOnlySub;

  /// No description provided for @groupsFilterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset Filter'**
  String get groupsFilterReset;

  /// No description provided for @groupsFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get groupsFilterApply;

  /// No description provided for @groupsSearchFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a community...'**
  String get groupsSearchFieldHint;

  /// No description provided for @groupsAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Communities'**
  String get groupsAppBarTitle;

  /// No description provided for @groupsTabDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get groupsTabDiscover;

  /// No description provided for @groupsTabMyGroups.
  ///
  /// In en, this message translates to:
  /// **'My Groups'**
  String get groupsTabMyGroups;

  /// No description provided for @groupsEmptyDiscoverTitle.
  ///
  /// In en, this message translates to:
  /// **'No communities available to discover'**
  String get groupsEmptyDiscoverTitle;

  /// No description provided for @groupsEmptyDiscoverSub.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any communities matching your criteria. Try adjusting the search or create a new community.'**
  String get groupsEmptyDiscoverSub;

  /// No description provided for @groupsEmptyMyGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'You are not a member of any community'**
  String get groupsEmptyMyGroupsTitle;

  /// No description provided for @groupsEmptyMyGroupsSub.
  ///
  /// In en, this message translates to:
  /// **'Join academic groups to connect with peers or create your own.'**
  String get groupsEmptyMyGroupsSub;

  /// No description provided for @groupsPillPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get groupsPillPublic;

  /// No description provided for @groupsPillPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get groupsPillPrivate;

  /// No description provided for @groupsCardDiscoverSub.
  ///
  /// In en, this message translates to:
  /// **'Academic community ready to join'**
  String get groupsCardDiscoverSub;

  /// No description provided for @groupsCardMyGroupsSub.
  ///
  /// In en, this message translates to:
  /// **'Enter and interact with group members'**
  String get groupsCardMyGroupsSub;

  /// No description provided for @groupsChatImageError.
  ///
  /// In en, this message translates to:
  /// **'Could not select image. Make sure permissions are granted.'**
  String get groupsChatImageError;

  /// No description provided for @groupsChatFileP1Unavailable.
  ///
  /// In en, this message translates to:
  /// **'This file is no longer available'**
  String get groupsChatFileP1Unavailable;

  /// No description provided for @groupsChatFileP1Error.
  ///
  /// In en, this message translates to:
  /// **'Could not open file now'**
  String get groupsChatFileP1Error;

  /// No description provided for @groupsChatLeaveOwnerError.
  ///
  /// In en, this message translates to:
  /// **'Owner cannot leave before transferring ownership'**
  String get groupsChatLeaveOwnerError;

  /// No description provided for @groupsChatLeaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'You have left the group'**
  String get groupsChatLeaveSuccess;

  /// No description provided for @groupsChatLeaveError.
  ///
  /// In en, this message translates to:
  /// **'Error leaving group'**
  String get groupsChatLeaveError;

  /// No description provided for @groupsChatMuteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Notifications muted'**
  String get groupsChatMuteSuccess;

  /// No description provided for @groupsChatEnableMembersMsg.
  ///
  /// In en, this message translates to:
  /// **'Members chat enabled'**
  String get groupsChatEnableMembersMsg;

  /// No description provided for @groupsChatDisableMembersMsg.
  ///
  /// In en, this message translates to:
  /// **'Members chat disabled'**
  String get groupsChatDisableMembersMsg;

  /// No description provided for @groupsChatSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search in chat...'**
  String get groupsChatSearchHint;

  /// No description provided for @groupsChatFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get groupsChatFallbackName;

  /// No description provided for @groupsChatMembersPluralSuffix.
  ///
  /// In en, this message translates to:
  /// **'members'**
  String get groupsChatMembersPluralSuffix;

  /// No description provided for @groupsChatDefaultCountName.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get groupsChatDefaultCountName;

  /// No description provided for @groupsChatErrorLoadingMessages.
  ///
  /// In en, this message translates to:
  /// **'Could not load messages'**
  String get groupsChatErrorLoadingMessages;

  /// No description provided for @groupsChatNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No matching results found'**
  String get groupsChatNoSearchResults;

  /// No description provided for @groupsChatRequiresJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Must join group'**
  String get groupsChatRequiresJoinTitle;

  /// No description provided for @groupsChatRequiresJoinBody.
  ///
  /// In en, this message translates to:
  /// **'This community is private. Open group info first, then request to join to participate in chat.'**
  String get groupsChatRequiresJoinBody;

  /// No description provided for @groupsChatDetailsButton.
  ///
  /// In en, this message translates to:
  /// **'View group info'**
  String get groupsChatDetailsButton;

  /// No description provided for @groupsChatReplyAction.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get groupsChatReplyAction;

  /// No description provided for @groupsChatLibraryFile.
  ///
  /// In en, this message translates to:
  /// **'Library file'**
  String get groupsChatLibraryFile;

  /// No description provided for @groupsChatImageAttached.
  ///
  /// In en, this message translates to:
  /// **'Attached image'**
  String get groupsChatImageAttached;

  /// No description provided for @groupsChatSavedRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get groupsChatSavedRemoveAction;

  /// No description provided for @groupsChatSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save with star'**
  String get groupsChatSaveAction;

  /// No description provided for @groupsChatSavedRemoveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Message removed'**
  String get groupsChatSavedRemoveSuccess;

  /// No description provided for @groupsChatSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Message saved'**
  String get groupsChatSaveSuccess;

  /// No description provided for @groupsChatSaveError.
  ///
  /// In en, this message translates to:
  /// **'Operation failed, try again later'**
  String get groupsChatSaveError;

  /// No description provided for @groupsChatMemberFallback.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get groupsChatMemberFallback;

  /// No description provided for @groupsChatImageDisplayError.
  ///
  /// In en, this message translates to:
  /// **'Could not display image'**
  String get groupsChatImageDisplayError;

  /// No description provided for @groupsChatOpenFileAction.
  ///
  /// In en, this message translates to:
  /// **'Tap to open file'**
  String get groupsChatOpenFileAction;

  /// No description provided for @groupsChatBannedMsg.
  ///
  /// In en, this message translates to:
  /// **'Sorry, you have been banned from participating in this group.'**
  String get groupsChatBannedMsg;

  /// No description provided for @groupsChatMutedMsg.
  ///
  /// In en, this message translates to:
  /// **'You are muted. Cannot send currently.'**
  String get groupsChatMutedMsg;

  /// No description provided for @groupsChatReadOnlyMsg.
  ///
  /// In en, this message translates to:
  /// **'Group is read-only'**
  String get groupsChatReadOnlyMsg;

  /// No description provided for @groupsChatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get groupsChatInputHint;

  /// No description provided for @groupsChatEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get groupsChatEmptyTitle;

  /// No description provided for @groupsChatEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Start the first conversation in this community and share ideas and files.'**
  String get groupsChatEmptySub;

  /// No description provided for @groupsChatTimeAm.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get groupsChatTimeAm;

  /// No description provided for @groupsChatTimePm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get groupsChatTimePm;

  /// No description provided for @groupsCreateEmptyNameMsg.
  ///
  /// In en, this message translates to:
  /// **'Enter group name'**
  String get groupsCreateEmptyNameMsg;

  /// No description provided for @groupsCreateEmptyCollegeMsg.
  ///
  /// In en, this message translates to:
  /// **'Select college'**
  String get groupsCreateEmptyCollegeMsg;

  /// No description provided for @groupsCreateEmptyMajorMsg.
  ///
  /// In en, this message translates to:
  /// **'Select major'**
  String get groupsCreateEmptyMajorMsg;

  /// No description provided for @groupsCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get groupsCreateTitle;

  /// No description provided for @groupsCreateHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'New Group'**
  String get groupsCreateHeaderTitle;

  /// No description provided for @groupsCreateHeaderSub.
  ///
  /// In en, this message translates to:
  /// **'Create a new study space for discussion and collaboration'**
  String get groupsCreateHeaderSub;

  /// No description provided for @groupsCreateInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Group Information'**
  String get groupsCreateInfoLabel;

  /// No description provided for @groupsCreateDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Group Description'**
  String get groupsCreateDescLabel;

  /// No description provided for @groupsCreateCollegeLabel.
  ///
  /// In en, this message translates to:
  /// **'College'**
  String get groupsCreateCollegeLabel;

  /// No description provided for @groupsCreateMajorLabel.
  ///
  /// In en, this message translates to:
  /// **'Major'**
  String get groupsCreateMajorLabel;

  /// No description provided for @groupsCreateTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Group Type'**
  String get groupsCreateTypeLabel;

  /// No description provided for @groupsCreateTypePublicTitle.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get groupsCreateTypePublicTitle;

  /// No description provided for @groupsCreateTypePublicSub.
  ///
  /// In en, this message translates to:
  /// **'Anyone can join'**
  String get groupsCreateTypePublicSub;

  /// No description provided for @groupsCreateTypePrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get groupsCreateTypePrivateTitle;

  /// No description provided for @groupsCreateTypePrivateSub.
  ///
  /// In en, this message translates to:
  /// **'Join via invite link'**
  String get groupsCreateTypePrivateSub;

  /// No description provided for @groupsCreateBtnLoading.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get groupsCreateBtnLoading;

  /// No description provided for @groupsCreateBtn.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get groupsCreateBtn;

  /// No description provided for @groupsInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Invite'**
  String get groupsInviteTitle;

  /// No description provided for @groupsInviteJoiningLoading.
  ///
  /// In en, this message translates to:
  /// **'Joining...'**
  String get groupsInviteJoiningLoading;

  /// No description provided for @groupsInviteNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get groupsInviteNotSpecified;

  /// No description provided for @groupsMakeAdminSuccess.
  ///
  /// In en, this message translates to:
  /// **'Admin assigned'**
  String get groupsMakeAdminSuccess;

  /// No description provided for @groupsReportMemberSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report sent to admin'**
  String get groupsReportMemberSuccess;

  /// No description provided for @groupsActionUnmuteMember.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get groupsActionUnmuteMember;

  /// No description provided for @groupsActionMuteMember.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get groupsActionMuteMember;

  /// No description provided for @groupsActionKickMember.
  ///
  /// In en, this message translates to:
  /// **'Kick Member'**
  String get groupsActionKickMember;

  /// No description provided for @groupsActionTransferOwnership.
  ///
  /// In en, this message translates to:
  /// **'Transfer Ownership'**
  String get groupsActionTransferOwnership;

  /// No description provided for @libraryTabUniversity.
  ///
  /// In en, this message translates to:
  /// **'University Library'**
  String get libraryTabUniversity;

  /// No description provided for @libraryTabDigital.
  ///
  /// In en, this message translates to:
  /// **'Digital Library'**
  String get libraryTabDigital;

  /// No description provided for @libraryTabMyLibrary.
  ///
  /// In en, this message translates to:
  /// **'My Library'**
  String get libraryTabMyLibrary;

  /// No description provided for @libraryHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore and manage your university library easily'**
  String get libraryHeaderSubtitle;

  /// No description provided for @digitalLibDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'Search millions of open research papers...'**
  String get digitalLibDefaultMessage;

  /// No description provided for @digitalLibNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found for \"{query}\"'**
  String digitalLibNoResults(String query);

  /// No description provided for @digitalLibSearchError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during the search. Please check your internet connection.'**
  String get digitalLibSearchError;

  /// No description provided for @digitalLibRemovedFromSaved.
  ///
  /// In en, this message translates to:
  /// **'Removed from saved'**
  String get digitalLibRemovedFromSaved;

  /// No description provided for @digitalLibSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Saved as reference successfully'**
  String get digitalLibSavedSuccessfully;

  /// No description provided for @digitalLibShareNoLink.
  ///
  /// In en, this message translates to:
  /// **'No link available to share this item'**
  String get digitalLibShareNoLink;

  /// No description provided for @digitalLibShareText.
  ///
  /// In en, this message translates to:
  /// **'Check out this research paper:\n{title}\n{url}'**
  String digitalLibShareText(String title, String url);

  /// No description provided for @digitalLibSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search CORE (e.g., AI in Medicine)'**
  String get digitalLibSearchHint;

  /// No description provided for @digitalLibNoTitle.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get digitalLibNoTitle;

  /// No description provided for @digitalLibUnknownAuthor.
  ///
  /// In en, this message translates to:
  /// **'Unknown author'**
  String get digitalLibUnknownAuthor;

  /// No description provided for @digitalLibActionSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get digitalLibActionSaved;

  /// No description provided for @digitalLibActionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get digitalLibActionSave;

  /// No description provided for @digitalLibActionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get digitalLibActionShare;

  /// No description provided for @digitalLibActionDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get digitalLibActionDetails;

  /// No description provided for @myLibUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'File uploaded successfully, you can track it in My Library'**
  String get myLibUploadSuccess;

  /// No description provided for @myLibStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Library Stats'**
  String get myLibStatsTitle;

  /// No description provided for @myLibStatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A quick look at your files, saves, and downloads'**
  String get myLibStatsSubtitle;

  /// No description provided for @myLibTotalSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Total Saves'**
  String get myLibTotalSavedTitle;

  /// No description provided for @myLibTotalSavedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your references and sources'**
  String get myLibTotalSavedSubtitle;

  /// No description provided for @myLibNavReferences.
  ///
  /// In en, this message translates to:
  /// **'References'**
  String get myLibNavReferences;

  /// No description provided for @myLibDownloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Downloads'**
  String get myLibDownloadsTitle;

  /// No description provided for @myLibUploadsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Uploads'**
  String get myLibUploadsTitle;

  /// No description provided for @myLibSharesTitle.
  ///
  /// In en, this message translates to:
  /// **'My Shares'**
  String get myLibSharesTitle;

  /// No description provided for @myLibNavShares.
  ///
  /// In en, this message translates to:
  /// **'What I Shared'**
  String get myLibNavShares;

  /// No description provided for @myLibHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal Library'**
  String get myLibHeroTitle;

  /// No description provided for @myLibHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage all your files and resources'**
  String get myLibHeroSubtitle;

  /// No description provided for @myLibFeatureUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get myLibFeatureUpload;

  /// No description provided for @myLibFeatureSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get myLibFeatureSave;

  /// No description provided for @myLibFeatureDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get myLibFeatureDownload;

  /// No description provided for @myLibBtnUploadNew.
  ///
  /// In en, this message translates to:
  /// **'Upload New File'**
  String get myLibBtnUploadNew;

  /// No description provided for @upErrorFilePick.
  ///
  /// In en, this message translates to:
  /// **'Could not pick file'**
  String get upErrorFilePick;

  /// No description provided for @upErrorSelectFileFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a file first'**
  String get upErrorSelectFileFirst;

  /// No description provided for @upErrorFillRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get upErrorFillRequired;

  /// No description provided for @upErrorLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in'**
  String get upErrorLoginRequired;

  /// No description provided for @upErrorInvalidCollege.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid college'**
  String get upErrorInvalidCollege;

  /// No description provided for @upSuccessUploaded.
  ///
  /// In en, this message translates to:
  /// **'File uploaded successfully and is now visible in the library'**
  String get upSuccessUploaded;

  /// No description provided for @upErrorUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while uploading. Please try again.'**
  String get upErrorUploadFailed;

  /// No description provided for @upSectionFileDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'File Details'**
  String get upSectionFileDetailsTitle;

  /// No description provided for @upSectionFileDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the basic information clearly and organized'**
  String get upSectionFileDetailsSubtitle;

  /// No description provided for @upLabelSubjectName.
  ///
  /// In en, this message translates to:
  /// **'Subject Name / File Title'**
  String get upLabelSubjectName;

  /// No description provided for @upErrorFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get upErrorFieldRequired;

  /// No description provided for @upLabelDoctorName.
  ///
  /// In en, this message translates to:
  /// **'Doctor Name'**
  String get upLabelDoctorName;

  /// No description provided for @upLabelDescription.
  ///
  /// In en, this message translates to:
  /// **'Brief Description'**
  String get upLabelDescription;

  /// No description provided for @upSectionAcademicTitle.
  ///
  /// In en, this message translates to:
  /// **'Academic Classification'**
  String get upSectionAcademicTitle;

  /// No description provided for @upSectionAcademicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose where the file belongs in the university structure'**
  String get upSectionAcademicSubtitle;

  /// No description provided for @upLabelCollege.
  ///
  /// In en, this message translates to:
  /// **'College'**
  String get upLabelCollege;

  /// No description provided for @upLabelMajor.
  ///
  /// In en, this message translates to:
  /// **'Major'**
  String get upLabelMajor;

  /// No description provided for @upLabelLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get upLabelLevel;

  /// No description provided for @upLabelTerm.
  ///
  /// In en, this message translates to:
  /// **'Term'**
  String get upLabelTerm;

  /// No description provided for @upBtnUploadNow.
  ///
  /// In en, this message translates to:
  /// **'Upload File Now'**
  String get upBtnUploadNow;

  /// No description provided for @upHintDirectUpload.
  ///
  /// In en, this message translates to:
  /// **'The file will be uploaded directly and shown in the university library.'**
  String get upHintDirectUpload;

  /// No description provided for @upTitleNewUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload New File'**
  String get upTitleNewUpload;

  /// No description provided for @upHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your file to the library'**
  String get upHeroTitle;

  /// No description provided for @upHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload summaries, references, and study files in an organized and professional way.'**
  String get upHeroSubtitle;

  /// No description provided for @upSectionFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Uploaded File'**
  String get upSectionFileTitle;

  /// No description provided for @upSectionFileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose PDF, Word, or image depending on content type'**
  String get upSectionFileSubtitle;

  /// No description provided for @upHintFileSelectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'File selected successfully. You can now complete the rest of the data and upload it.'**
  String get upHintFileSelectedSuccess;

  /// No description provided for @upBtnChangeFile.
  ///
  /// In en, this message translates to:
  /// **'Change File'**
  String get upBtnChangeFile;

  /// No description provided for @upBtnSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Tap to select a file'**
  String get upBtnSelectFile;

  /// No description provided for @upHintSupportedTypes.
  ///
  /// In en, this message translates to:
  /// **'Supported Types: PDF / DOC / DOCX / JPG / PNG'**
  String get upHintSupportedTypes;

  /// No description provided for @upBtnChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get upBtnChooseFile;

  /// No description provided for @myFilesEmptyDefault.
  ///
  /// In en, this message translates to:
  /// **'No files found'**
  String get myFilesEmptyDefault;

  /// No description provided for @myFilesEmptySaved.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t saved any files yet'**
  String get myFilesEmptySaved;

  /// No description provided for @myFilesEmptyUploads.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t uploaded any files yet'**
  String get myFilesEmptyUploads;

  /// No description provided for @myFilesEmptyDownloads.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t downloaded any files yet'**
  String get myFilesEmptyDownloads;

  /// No description provided for @myFilesEmptyShares.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t shared any files yet'**
  String get myFilesEmptyShares;

  /// No description provided for @myFilesNoTitle.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get myFilesNoTitle;

  /// No description provided for @myFilesUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get myFilesUnknown;

  /// No description provided for @myFilesUnknownAuthor.
  ///
  /// In en, this message translates to:
  /// **'Unknown Author'**
  String get myFilesUnknownAuthor;

  /// No description provided for @myFilesError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String myFilesError(String error);

  /// No description provided for @myFilesNoLink.
  ///
  /// In en, this message translates to:
  /// **'No link available for this file'**
  String get myFilesNoLink;

  /// No description provided for @myFilesNoLinkToOpen.
  ///
  /// In en, this message translates to:
  /// **'No link available to open'**
  String get myFilesNoLinkToOpen;

  /// No description provided for @myFilesCannotOpen.
  ///
  /// In en, this message translates to:
  /// **'Could not open file'**
  String get myFilesCannotOpen;

  /// No description provided for @myFilesSanaUniversity.
  ///
  /// In en, this message translates to:
  /// **'Sana\'a University'**
  String get myFilesSanaUniversity;

  /// No description provided for @myFilesTrailingOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get myFilesTrailingOpen;

  /// No description provided for @myFilesFutureList.
  ///
  /// In en, this message translates to:
  /// **'The \"{title}\" list will be displayed here later'**
  String myFilesFutureList(String title);

  /// No description provided for @detailsUnspecified.
  ///
  /// In en, this message translates to:
  /// **'Unspecified'**
  String get detailsUnspecified;

  /// No description provided for @detailsWordFile.
  ///
  /// In en, this message translates to:
  /// **'Word File'**
  String get detailsWordFile;

  /// No description provided for @detailsNoPreview.
  ///
  /// In en, this message translates to:
  /// **'This type is not currently displayed inside the app.\nChoose to open externally or download it.'**
  String get detailsNoPreview;

  /// No description provided for @detailsDownloadBtn.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get detailsDownloadBtn;

  /// No description provided for @detailsOpenExternalBtn.
  ///
  /// In en, this message translates to:
  /// **'Open Externally'**
  String get detailsOpenExternalBtn;

  /// No description provided for @detailsNoGroupsJoined.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t joined any groups yet'**
  String get detailsNoGroupsJoined;

  /// No description provided for @detailsShareToGroups.
  ///
  /// In en, this message translates to:
  /// **'Share to Groups'**
  String get detailsShareToGroups;

  /// No description provided for @detailsSelectGroup.
  ///
  /// In en, this message translates to:
  /// **'Choose the group you want to share the file with'**
  String get detailsSelectGroup;

  /// No description provided for @detailsShareSuccess.
  ///
  /// In en, this message translates to:
  /// **'File shared in {groupName} group'**
  String detailsShareSuccess(String groupName);

  /// No description provided for @detailsShareFailure.
  ///
  /// In en, this message translates to:
  /// **'Could not share file to group: {error}'**
  String detailsShareFailure(String error);

  /// No description provided for @detailsNoShareLink.
  ///
  /// In en, this message translates to:
  /// **'No link available to share the file'**
  String get detailsNoShareLink;

  /// No description provided for @detailsDownloadSuccess.
  ///
  /// In en, this message translates to:
  /// **'File downloaded and saved inside the app'**
  String get detailsDownloadSuccess;

  /// No description provided for @detailsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit File'**
  String get detailsEditTitle;

  /// No description provided for @detailsEditSuccess.
  ///
  /// In en, this message translates to:
  /// **'File updated'**
  String get detailsEditSuccess;

  /// No description provided for @detailsEditFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to edit: {error}'**
  String detailsEditFailure(String error);

  /// No description provided for @detailsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete File'**
  String get detailsDeleteTitle;

  /// No description provided for @detailsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get detailsDeleteConfirm;

  /// No description provided for @detailsBtnCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get detailsBtnCancel;

  /// No description provided for @detailsBtnDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get detailsBtnDelete;

  /// No description provided for @detailsDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'File deleted'**
  String get detailsDeleteSuccess;

  /// No description provided for @detailsDeleteFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete file: {error}'**
  String detailsDeleteFailure(String error);

  /// No description provided for @detailsDownloadFailure.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String detailsDownloadFailure(String error);

  /// No description provided for @detailsShareGeneralFailure.
  ///
  /// In en, this message translates to:
  /// **'Could not register share: {error}'**
  String detailsShareGeneralFailure(String error);

  /// No description provided for @detailsFillRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Complete all required fields'**
  String get detailsFillRequiredFields;

  /// No description provided for @detailsBtnSaveEdits.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get detailsBtnSaveEdits;

  /// No description provided for @detailsActionOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Open File'**
  String get detailsActionOpenFile;

  /// No description provided for @detailsSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get detailsSectionDescription;

  /// No description provided for @detailsSectionFileInfo.
  ///
  /// In en, this message translates to:
  /// **'File Information'**
  String get detailsSectionFileInfo;

  /// No description provided for @detailsInfoCourse.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get detailsInfoCourse;

  /// No description provided for @detailsInfoCollege.
  ///
  /// In en, this message translates to:
  /// **'College'**
  String get detailsInfoCollege;

  /// No description provided for @detailsInfoSpecialization.
  ///
  /// In en, this message translates to:
  /// **'Specialization'**
  String get detailsInfoSpecialization;

  /// No description provided for @detailsInfoLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get detailsInfoLevel;

  /// No description provided for @detailsInfoType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get detailsInfoType;

  /// No description provided for @detailsInfoStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get detailsInfoStatus;

  /// No description provided for @detailsInfoDate.
  ///
  /// In en, this message translates to:
  /// **'Upload Date'**
  String get detailsInfoDate;

  /// No description provided for @detailsStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get detailsStatusApproved;

  /// No description provided for @detailsStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get detailsStatusPending;

  /// No description provided for @detailsStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get detailsStatusRejected;

  /// No description provided for @detailsLikeAction.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get detailsLikeAction;

  /// No description provided for @detailsLikeFailure.
  ///
  /// In en, this message translates to:
  /// **'Could not like: {error}'**
  String detailsLikeFailure(String error);

  /// No description provided for @detailsSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get detailsSaveAction;

  /// No description provided for @detailsSaveFailure.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String detailsSaveFailure(String error);

  /// No description provided for @detailsUploaderPrefix.
  ///
  /// In en, this message translates to:
  /// **'Uploaded by: {uploader}'**
  String detailsUploaderPrefix(String uploader);

  /// No description provided for @detailsStatViews.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get detailsStatViews;

  /// No description provided for @detailsStatDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get detailsStatDownloads;

  /// No description provided for @detailsStatShares.
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get detailsStatShares;

  /// No description provided for @detailsPrefixDr.
  ///
  /// In en, this message translates to:
  /// **'Dr. {author}'**
  String detailsPrefixDr(String author);

  /// No description provided for @pdfBrowseFile.
  ///
  /// In en, this message translates to:
  /// **'Browse File'**
  String get pdfBrowseFile;

  /// No description provided for @digitalLibNoAbstract.
  ///
  /// In en, this message translates to:
  /// **'No abstract available.'**
  String get digitalLibNoAbstract;

  /// No description provided for @digitalLibResultDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Research Details'**
  String get digitalLibResultDetailsTitle;

  /// No description provided for @digitalLibLabelAuthors.
  ///
  /// In en, this message translates to:
  /// **'Authors:'**
  String get digitalLibLabelAuthors;

  /// No description provided for @digitalLibLabelPublisher.
  ///
  /// In en, this message translates to:
  /// **'Publisher:'**
  String get digitalLibLabelPublisher;

  /// No description provided for @digitalLibLabelYear.
  ///
  /// In en, this message translates to:
  /// **'Publication Year:'**
  String get digitalLibLabelYear;

  /// No description provided for @digitalLibLabelJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal:'**
  String get digitalLibLabelJournal;

  /// No description provided for @digitalLibSaveErrorParam.
  ///
  /// In en, this message translates to:
  /// **'Could not save reference: {error}'**
  String digitalLibSaveErrorParam(String error);

  /// No description provided for @digitalLibActionDownloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get digitalLibActionDownloadPdf;

  /// No description provided for @digitalLibDownloadError.
  ///
  /// In en, this message translates to:
  /// **'Could not register download: {error}'**
  String digitalLibDownloadError(String error);

  /// No description provided for @digitalLibActionOpenSource.
  ///
  /// In en, this message translates to:
  /// **'Open Source'**
  String get digitalLibActionOpenSource;

  /// No description provided for @digitalLibLabelAbstract.
  ///
  /// In en, this message translates to:
  /// **'Abstract'**
  String get digitalLibLabelAbstract;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsMarkAllReadSuccess.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get notificationsMarkAllReadSuccess;

  /// No description provided for @notificationsSectionToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get notificationsSectionToday;

  /// No description provided for @notificationsSectionEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get notificationsSectionEarlier;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'When you have a new interaction or an important update, it will appear here clearly.'**
  String get notificationsEmptyDesc;

  /// No description provided for @timeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get timeYesterday;

  /// No description provided for @timeMinutesAgoParam.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeMinutesAgoParam(int count);

  /// No description provided for @timeHoursAgoParam.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeHoursAgoParam(int count);

  /// No description provided for @timeDaysAgoParam.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeDaysAgoParam(int count);

  /// No description provided for @upFileTypePdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get upFileTypePdf;

  /// No description provided for @upFileTypeWord.
  ///
  /// In en, this message translates to:
  /// **'Word'**
  String get upFileTypeWord;

  /// No description provided for @upFileTypeImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get upFileTypeImage;

  /// No description provided for @upFileTypeGeneric.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get upFileTypeGeneric;
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
