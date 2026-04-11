// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_name => 'Edu Mate';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get errEnterEmailPass => 'Please enter your email and password';

  @override
  String get errInvalidEmail => 'Invalid email address';

  @override
  String get errAccountNotFound => 'Account not found';

  @override
  String get errWrongPassword => 'Incorrect password';

  @override
  String get errInvalidCredentials => 'Invalid credentials';

  @override
  String get errAccountDisabled => 'Account disabled';

  @override
  String get errTooManyRequests => 'Too many requests, try again later';

  @override
  String get errUnexpected => 'An unexpected error occurred';

  @override
  String get errEmailAlreadyInUse => 'Email already in use';

  @override
  String get errWeakPassword => 'Password is too weak';

  @override
  String get errEmptyUsername => 'Please enter a username';

  @override
  String get errShortUsername => 'Username is too short';

  @override
  String get errInvalidUsername => 'Only letters, numbers, . and _ allowed';

  @override
  String get errEmptyName => 'Please enter your name';

  @override
  String get errEmptyEmail => 'Please enter your email';

  @override
  String get errEmptyPassword => 'Please enter a password';

  @override
  String get errShortPassword => 'Password must be at least 6 characters';

  @override
  String get errUsernameTaken => 'Username is already taken';

  @override
  String get loginWelcomeBack => 'Welcome back';

  @override
  String get loginTitle => 'Log In';

  @override
  String get loginSubtitle => 'Sign in to access your platform';

  @override
  String get loginEmailHint => 'Email';

  @override
  String get loginPasswordHint => 'Password';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginNoAccount => 'Don\'t have an account?';

  @override
  String get loginSignupAction => 'Sign up';

  @override
  String get resetEnterEmailFirst => 'Please enter your email first';

  @override
  String get resetLinkSent => 'Password reset link sent to your email';

  @override
  String get resetFailedSend => 'Failed to send reset link';

  @override
  String get resetEmailNotRegistered => 'Email not registered';

  @override
  String get signupTitle => 'Create Account';

  @override
  String get signupSubtitle =>
      'Create your identity in Edu Mate and start your journey';

  @override
  String get signupUsernameHint => 'Username';

  @override
  String get signupFullNameHint => 'Full Name';

  @override
  String get signupCollegeHint => 'College';

  @override
  String get signupMajorHint => 'Major';

  @override
  String get signupBioHint => 'Bio';

  @override
  String get signupBtn => 'Create Account';

  @override
  String get signupAlreadyHaveAccount => 'Already have an account? Log in';

  @override
  String get signupSuccess => 'Account created successfully';

  @override
  String get signupFailed => 'Signup failed';

  @override
  String get navHome => 'Home';

  @override
  String get navGroups => 'Groups';

  @override
  String get navLibrary => 'Library';

  @override
  String get feedSearchHint => 'Search feed...';

  @override
  String get filterForYou => 'For You';

  @override
  String get filterRecent => 'Recent';

  @override
  String get filterPopular => 'Popular';

  @override
  String get filterAcademic => 'Academic';

  @override
  String get filterCollege => 'College';

  @override
  String get filterMajor => 'Major';

  @override
  String get filterCourses => 'Courses';

  @override
  String get feedErrLoadPosts => 'Failed to load posts';

  @override
  String get feedErrCheckConnection =>
      'Check your connection or Firestore settings';

  @override
  String get feedEmptyPublicPosts => 'No public posts yet';

  @override
  String get feedEmptyPublicPostsSub =>
      'Only public group posts will appear here';

  @override
  String get feedJoinedGroup => 'Joined group successfully';

  @override
  String get feedErrUpdateLike => 'Failed to update like';

  @override
  String get feedJoinAction => 'Join';

  @override
  String get feedBotName => 'Edu Bot';

  @override
  String get likeAction => 'Like';

  @override
  String get commentAction => 'Comment';

  @override
  String get shareAction => 'Share';

  @override
  String get timeNow => 'now';

  @override
  String get timeMinutesAgo => 'm ago';

  @override
  String get timeHoursAgo => 'h ago';

  @override
  String get timeDaysAgo => 'd ago';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsBody => 'Notifications will be connected later';

  @override
  String get errLoginFailed => 'Login failed';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileNoUser => 'No user logged in';

  @override
  String get profileNoData => 'Profile data not found';

  @override
  String get profileVerifiedDoc => 'Verified Doctor';

  @override
  String get profileUserRole => 'User ';

  @override
  String get profileUsernameLabel => 'Username';

  @override
  String get profileFullNameLabel => 'Full Name';

  @override
  String get profileEmailLabel => 'Email';

  @override
  String get profileBioLabel => 'Bio';

  @override
  String get profileCollegeLabel => 'College';

  @override
  String get profileSpecialtyLabel => 'Major';

  @override
  String get profileReqDocVerification => 'Request Doctor Verification';

  @override
  String get profileLogout => 'Log Out';

  @override
  String get profileDeleteAccount => 'Delete Account';

  @override
  String get profileCancel => 'Cancel';

  @override
  String get profileDelete => 'Delete';

  @override
  String get profileDeleteConfirm =>
      'Are you sure? Your account will be permanently deleted.';

  @override
  String get libFilterSortTitle => 'Filter and Sort';

  @override
  String get libFilterReset => 'Reset';

  @override
  String get libFilterApply => 'Apply';

  @override
  String get libFilterLevel => 'Level';

  @override
  String get libSearchHint => 'Search by subject, doctor, or major...';

  @override
  String get libSortPrefix => 'Sort: ';

  @override
  String get libEmptyTitle => 'No matching files';

  @override
  String get libEmptyDesc =>
      'Try changing search keywords or lightening filters to see more results.';

  @override
  String get libSortLatest => 'Latest';

  @override
  String get libSortMostLiked => 'Most Liked';

  @override
  String get libSortMostViewed => 'Most Viewed';

  @override
  String get profileUpdatePhotoSuccess => 'Profile photo updated';

  @override
  String get profileUpdatePhotoFailed => 'Failed to upload photo';

  @override
  String get profileVerificationPending =>
      'You already have a pending verification request';

  @override
  String get profileVerificationSent =>
      'Verification request sent to dashboard';

  @override
  String get profileVerificationFailed => 'Failed to send request';

  @override
  String get profileLogoutFailed => 'Logout failed';

  @override
  String get profileDeleteRequiresLogin =>
      'To delete account, please login again and retry';

  @override
  String get profileDeleteFailed => 'Failed to delete account';

  @override
  String get profileDeleteError => 'Error occurred while deleting account';

  @override
  String get libErrorPrefix => 'An error occurred: ';

  @override
  String get groupsManageMembersTitle => 'Manage Members';

  @override
  String get groupsSearchHint => 'Search...';

  @override
  String get groupsRoleOwnerTitle => 'Owner';

  @override
  String get groupsRoleAdminsTitle => 'Admins';

  @override
  String get groupsRoleMembersTitle => 'Members';

  @override
  String get groupsDefaultMemberName => 'Group member';

  @override
  String get groupsRoleOwner => 'Owner';

  @override
  String get groupsRoleAdmin => 'Admin';

  @override
  String get groupsRoleMember => 'Member';

  @override
  String get groupsStatusMuted => ' (Muted)';

  @override
  String get groupsStatusBanned => ' (Banned)';

  @override
  String get groupsYouMarker => '(You)';

  @override
  String get groupsActionRemoveAdmin => 'Remove Admin';

  @override
  String get groupsActionMakeAdmin => 'Make Admin';

  @override
  String get groupsActionUnmute => 'Unmute';

  @override
  String get groupsActionMute => 'Mute Member';

  @override
  String get groupsActionKick => 'Kick Member';

  @override
  String get groupsActionReport => 'Report';

  @override
  String get groupsActionTransferOwner => 'Transfer Ownership';

  @override
  String get groupsEmptySearchTitle => 'No results found';

  @override
  String get groupsEmptySearchDesc =>
      'We couldn\'t find any members matching your search.';

  @override
  String get groupsTransferOwnershipSuccess =>
      'Ownership transferred successfully';

  @override
  String get groupsTransferOwnershipError => 'Error transferring ownership';

  @override
  String get groupsSetAdminSuccess => 'Admin appointed';

  @override
  String get groupsRemoveAdminSuccess => 'Admin removed';

  @override
  String get groupsMuteMemberSuccess => 'Member muted';

  @override
  String get groupsUnmuteMemberSuccess => 'Member unmuted';

  @override
  String get groupsReportSent => 'Report sent to app manager';

  @override
  String get groupsKickMemberSuccess => 'Member kicked';

  @override
  String get groupsLoadMembersError => 'Failed to load members';
}
