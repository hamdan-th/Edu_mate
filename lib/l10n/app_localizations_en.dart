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
  String get loginGuestAction => 'Browse as Guest';

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
  String get signupRoleStudent => 'Student';

  @override
  String get signupRoleDoctor => 'Doctor';

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

  @override
  String get groupsJoinSuccess => 'Joined group successfully';

  @override
  String get groupsNameRequired => 'Group name is required';

  @override
  String get groupsSaveSuccess => 'Saved successfully';

  @override
  String get groupsSaveError => 'Error saving';

  @override
  String get groupsMuteNotificationsSuccess => 'Notifications muted';

  @override
  String get groupsUnmuteNotificationsSuccess => 'Notifications unmuted';

  @override
  String get groupsOwnerLeaveError =>
      'Owner cannot leave without transferring ownership';

  @override
  String get groupsLeaveSuccess => 'Left group successfully';

  @override
  String get groupsLeaveError => 'Error leaving group';

  @override
  String get groupsReportConfirmTitle => 'Confirm Report';

  @override
  String get groupsReportConfirmMsg =>
      'Are you sure you want to report this group? Its content will be reviewed by administration.';

  @override
  String get groupsReportReceived => 'Report received and will be reviewed';

  @override
  String get groupsActionClearChat => 'Clear Chat History';

  @override
  String get groupsClearChatConfirmMsg =>
      'Are you sure you want to clear all chat messages? This action cannot be undone.';

  @override
  String get groupsClearChatSubmit => 'Clear';

  @override
  String get groupsClearChatSuccess => 'Chat history cleared successfully';

  @override
  String get groupsClearChatError => 'Error clearing history';

  @override
  String get groupsActionCopyLink => 'Copy Link';

  @override
  String get groupsCopyLinkSuccess => 'Link copied';

  @override
  String get groupsActionEditGroup => 'Edit Group';

  @override
  String get groupsEditTitle => 'Edit';

  @override
  String get groupsSaveAction => 'Save';

  @override
  String get groupsNameLabel => 'Group Name';

  @override
  String get groupsDescLabel => 'Description';

  @override
  String get groupsMemberCountSuffix => 'member';

  @override
  String get groupsPublicBadge => 'Public Group';

  @override
  String get groupsPrivateBadge => 'Private Group';

  @override
  String get groupsJoinAction => 'Join Group';

  @override
  String get groupsEnableAction => 'Enable';

  @override
  String get groupsMuteAction => 'Mute';

  @override
  String get groupsLeaveAction => 'Leave';

  @override
  String get groupsMoreAction => 'More';

  @override
  String get groupsPublishFeedAction => 'Publish to Public Feed';

  @override
  String get groupsPublishFeedSub =>
      'Share an announcement or update with all students';

  @override
  String get groupsAllowMembersChat => 'Allow members to chat';

  @override
  String get groupsTabMembers => 'Members';

  @override
  String get groupsTabMedia => 'Media';

  @override
  String get groupsTabLinks => 'Links';

  @override
  String get groupsTabSaved => 'Saved';

  @override
  String get groupsReportError => 'Error sending report';

  @override
  String get groupsRequiresJoinToView =>
      'You must join the group to view members';

  @override
  String get groupsErrorLoadingMembers => 'Error loading members';

  @override
  String get groupsEmptyMembersTitle => 'No members in this group';

  @override
  String get groupsErrorLoadingSaved => 'Error loading saved messages';

  @override
  String get groupsEmptySavedTitle => 'No saved messages';

  @override
  String get groupsDefaultMessageLabel => 'Message';

  @override
  String get groupsErrorLoadingMedia => 'Error loading media';

  @override
  String get groupsEmptyMediaTitle => 'No media found';

  @override
  String get groupsErrorLoadingLinks => 'Error loading links';

  @override
  String get groupsEmptyLinksTitle => 'No links found';

  @override
  String get groupsFilterTitle => 'Filter Results';

  @override
  String get groupsFilterPublicOnly => 'Public Groups Only';

  @override
  String get groupsFilterPublicOnlySub =>
      'Show only public communities in results';

  @override
  String get groupsFilterReset => 'Reset Filter';

  @override
  String get groupsFilterApply => 'Apply';

  @override
  String get groupsSearchFieldHint => 'Search for a community...';

  @override
  String get groupsAppBarTitle => 'Communities';

  @override
  String get groupsTabDiscover => 'Discover';

  @override
  String get groupsTabMyGroups => 'My Groups';

  @override
  String get groupsEmptyDiscoverTitle => 'No communities available to discover';

  @override
  String get groupsEmptyDiscoverSub =>
      'We couldn\'t find any communities matching your criteria. Try adjusting the search or create a new community.';

  @override
  String get groupsEmptyMyGroupsTitle =>
      'You are not a member of any community';

  @override
  String get groupsEmptyMyGroupsSub =>
      'Join academic groups to connect with peers or create your own.';

  @override
  String get groupsPillPublic => 'Public';

  @override
  String get groupsPillPrivate => 'Private';

  @override
  String get groupsCardDiscoverSub => 'Academic community ready to join';

  @override
  String get groupsCardMyGroupsSub => 'Enter and interact with group members';

  @override
  String get groupsChatImageError =>
      'Could not select image. Make sure permissions are granted.';

  @override
  String get groupsChatFileP1Unavailable => 'This file is no longer available';

  @override
  String get groupsChatFileP1Error => 'Could not open file now';

  @override
  String get groupsChatLeaveOwnerError =>
      'Owner cannot leave before transferring ownership';

  @override
  String get groupsChatLeaveSuccess => 'You have left the group';

  @override
  String get groupsChatLeaveError => 'Error leaving group';

  @override
  String get groupsChatMuteSuccess => 'Notifications muted';

  @override
  String get groupsChatEnableMembersMsg => 'Members chat enabled';

  @override
  String get groupsChatDisableMembersMsg => 'Members chat disabled';

  @override
  String get groupsChatSearchHint => 'Search in chat...';

  @override
  String get groupsChatFallbackName => 'Chat';

  @override
  String get groupsChatMembersPluralSuffix => 'members';

  @override
  String get groupsChatDefaultCountName => 'Group';

  @override
  String get groupsChatErrorLoadingMessages => 'Could not load messages';

  @override
  String get groupsChatNoSearchResults => 'No matching results found';

  @override
  String get groupsChatRequiresJoinTitle => 'Must join group';

  @override
  String get groupsChatRequiresJoinBody =>
      'This community is private. Open group info first, then request to join to participate in chat.';

  @override
  String get groupsChatDetailsButton => 'View group info';

  @override
  String get groupsChatReplyAction => 'Reply';

  @override
  String get groupsChatLibraryFile => 'Library file';

  @override
  String get groupsChatImageAttached => 'Attached image';

  @override
  String get groupsChatSavedRemoveAction => 'Remove from saved';

  @override
  String get groupsChatSaveAction => 'Save with star';

  @override
  String get groupsChatSavedRemoveSuccess => 'Message removed';

  @override
  String get groupsChatSaveSuccess => 'Message saved';

  @override
  String get groupsChatSaveError => 'Operation failed, try again later';

  @override
  String get groupsChatMemberFallback => 'Member';

  @override
  String get groupsChatImageDisplayError => 'Could not display image';

  @override
  String get groupsChatOpenFileAction => 'Tap to open file';

  @override
  String get groupsChatBannedMsg =>
      'Sorry, you have been banned from participating in this group.';

  @override
  String get groupsChatMutedMsg => 'You are muted. Cannot send currently.';

  @override
  String get groupsChatReadOnlyMsg => 'Group is read-only';

  @override
  String get groupsChatInputHint => 'Type a message...';

  @override
  String get groupsChatEmptyTitle => 'No messages yet';

  @override
  String get groupsChatEmptySub =>
      'Start the first conversation in this community and share ideas and files.';

  @override
  String get groupsChatTimeAm => 'AM';

  @override
  String get groupsChatTimePm => 'PM';

  @override
  String get groupsCreateEmptyNameMsg => 'Enter group name';

  @override
  String get groupsCreateEmptyCollegeMsg => 'Select college';

  @override
  String get groupsCreateEmptyMajorMsg => 'Select major';

  @override
  String get groupsCreateTitle => 'Create Group';

  @override
  String get groupsCreateHeaderTitle => 'New Group';

  @override
  String get groupsCreateHeaderSub =>
      'Create a new study space for discussion and collaboration';

  @override
  String get groupsCreateInfoLabel => 'Group Information';

  @override
  String get groupsCreateDescLabel => 'Group Description';

  @override
  String get groupsCreateCollegeLabel => 'College';

  @override
  String get groupsCreateMajorLabel => 'Major';

  @override
  String get groupsCreateTypeLabel => 'Group Type';

  @override
  String get groupsCreateTypePublicTitle => 'Public';

  @override
  String get groupsCreateTypePublicSub => 'Anyone can join';

  @override
  String get groupsCreateTypePrivateTitle => 'Private';

  @override
  String get groupsCreateTypePrivateSub => 'Join via invite link';

  @override
  String get groupsCreateBtnLoading => 'Creating...';

  @override
  String get groupsCreateBtn => 'Create Group';

  @override
  String get groupsInviteTitle => 'Group Invite';

  @override
  String get groupsInviteJoiningLoading => 'Joining...';

  @override
  String get groupsInviteNotSpecified => 'Not specified';

  @override
  String get groupsMakeAdminSuccess => 'Admin assigned';

  @override
  String get groupsReportMemberSuccess => 'Report sent to admin';

  @override
  String get groupsActionUnmuteMember => 'Unmute';

  @override
  String get groupsActionMuteMember => 'Mute';

  @override
  String get groupsActionKickMember => 'Kick Member';

  @override
  String get groupsActionTransferOwnership => 'Transfer Ownership';

  @override
  String get libraryTabUniversity => 'University Library';

  @override
  String get libraryTabDigital => 'Digital Library';

  @override
  String get libraryTabMyLibrary => 'My Library';

  @override
  String get libraryHeaderSubtitle =>
      'Explore and manage your university library easily';

  @override
  String get digitalLibDefaultMessage =>
      'Search millions of open research papers...';

  @override
  String digitalLibNoResults(String query) {
    return 'No results found for \"$query\"';
  }

  @override
  String get digitalLibSearchError =>
      'An error occurred during the search. Please check your internet connection.';

  @override
  String get digitalLibRemovedFromSaved => 'Removed from saved';

  @override
  String get digitalLibSavedSuccessfully => 'Saved as reference successfully';

  @override
  String get digitalLibShareNoLink => 'No link available to share this item';

  @override
  String digitalLibShareText(String title, String url) {
    return 'Check out this research paper:\n$title\n$url';
  }

  @override
  String get digitalLibSearchHint => 'Search CORE (e.g., AI in Medicine)';

  @override
  String get digitalLibNoTitle => 'Untitled';

  @override
  String get digitalLibUnknownAuthor => 'Unknown author';

  @override
  String get digitalLibActionSaved => 'Saved';

  @override
  String get digitalLibActionSave => 'Save';

  @override
  String get digitalLibActionShare => 'Share';

  @override
  String get digitalLibActionDetails => 'Details';

  @override
  String get myLibUploadSuccess =>
      'File uploaded successfully, you can track it in My Library';

  @override
  String get myLibStatsTitle => 'My Library Stats';

  @override
  String get myLibStatsSubtitle =>
      'A quick look at your files, saves, and downloads';

  @override
  String get myLibTotalSavedTitle => 'Total Saves';

  @override
  String get myLibTotalSavedSubtitle => 'Your references and sources';

  @override
  String get myLibNavReferences => 'References';

  @override
  String get myLibDownloadsTitle => 'My Downloads';

  @override
  String get myLibUploadsTitle => 'My Uploads';

  @override
  String get myLibSharesTitle => 'My Shares';

  @override
  String get myLibNavShares => 'What I Shared';

  @override
  String get myLibHeroTitle => 'Personal Library';

  @override
  String get myLibHeroSubtitle => 'Manage all your files and resources';

  @override
  String get myLibFeatureUpload => 'Upload';

  @override
  String get myLibFeatureSave => 'Save';

  @override
  String get myLibFeatureDownload => 'Download';

  @override
  String get myLibBtnUploadNew => 'Upload New File';

  @override
  String get upErrorFilePick => 'Could not pick file';

  @override
  String get upErrorSelectFileFirst => 'Please select a file first';

  @override
  String get upErrorFillRequired => 'Please fill all required fields';

  @override
  String get upErrorLoginRequired => 'You must be logged in';

  @override
  String get upErrorInvalidCollege => 'Please select a valid college';

  @override
  String get upSuccessUploaded =>
      'File uploaded successfully and is now visible in the library';

  @override
  String get upErrorUploadFailed =>
      'An error occurred while uploading. Please try again.';

  @override
  String get upSectionFileDetailsTitle => 'File Details';

  @override
  String get upSectionFileDetailsSubtitle =>
      'Enter the basic information clearly and organized';

  @override
  String get upLabelSubjectName => 'Subject Name / File Title';

  @override
  String get upErrorFieldRequired => 'This field is required';

  @override
  String get upLabelDoctorName => 'Doctor Name';

  @override
  String get upLabelDescription => 'Brief Description';

  @override
  String get upSectionAcademicTitle => 'Academic Classification';

  @override
  String get upSectionAcademicSubtitle =>
      'Choose where the file belongs in the university structure';

  @override
  String get upLabelCollege => 'College';

  @override
  String get upLabelMajor => 'Major';

  @override
  String get upLabelLevel => 'Level';

  @override
  String get upLabelTerm => 'Term';

  @override
  String get upBtnUploadNow => 'Upload File Now';

  @override
  String get upHintDirectUpload =>
      'The file will be uploaded directly and shown in the university library.';

  @override
  String get upTitleNewUpload => 'Upload New File';

  @override
  String get upHeroTitle => 'Add your file to the library';

  @override
  String get upHeroSubtitle =>
      'Upload summaries, references, and study files in an organized and professional way.';

  @override
  String get upSectionFileTitle => 'Uploaded File';

  @override
  String get upSectionFileSubtitle =>
      'Choose PDF, Word, or image depending on content type';

  @override
  String get upHintFileSelectedSuccess =>
      'File selected successfully. You can now complete the rest of the data and upload it.';

  @override
  String get upBtnChangeFile => 'Change File';

  @override
  String get upBtnSelectFile => 'Tap to select a file';

  @override
  String get upHintSupportedTypes =>
      'Supported Types: PDF / DOC / DOCX / JPG / PNG';

  @override
  String get upBtnChooseFile => 'Choose File';

  @override
  String get myFilesEmptyDefault => 'No files found';

  @override
  String get myFilesEmptySaved => 'You haven\'t saved any files yet';

  @override
  String get myFilesEmptyUploads => 'You haven\'t uploaded any files yet';

  @override
  String get myFilesEmptyDownloads => 'You haven\'t downloaded any files yet';

  @override
  String get myFilesEmptyShares => 'You haven\'t shared any files yet';

  @override
  String get myFilesNoTitle => 'Untitled';

  @override
  String get myFilesUnknown => 'Unknown';

  @override
  String get myFilesUnknownAuthor => 'Unknown Author';

  @override
  String myFilesError(String error) {
    return 'Error: $error';
  }

  @override
  String get myFilesNoLink => 'No link available for this file';

  @override
  String get myFilesNoLinkToOpen => 'No link available to open';

  @override
  String get myFilesCannotOpen => 'Could not open file';

  @override
  String get myFilesSanaUniversity => 'Sana\'a University';

  @override
  String get myFilesTrailingOpen => 'Open';

  @override
  String myFilesFutureList(String title) {
    return 'The \"$title\" list will be displayed here later';
  }

  @override
  String get detailsUnspecified => 'Unspecified';

  @override
  String get detailsWordFile => 'Word File';

  @override
  String get detailsNoPreview =>
      'This type is not currently displayed inside the app.\nChoose to open externally or download it.';

  @override
  String get detailsDownloadBtn => 'Download';

  @override
  String get detailsOpenExternalBtn => 'Open Externally';

  @override
  String get detailsNoGroupsJoined => 'You haven\'t joined any groups yet';

  @override
  String get detailsShareToGroups => 'Share to Groups';

  @override
  String get detailsSelectGroup =>
      'Choose the group you want to share the file with';

  @override
  String detailsShareSuccess(String groupName) {
    return 'File shared in $groupName group';
  }

  @override
  String detailsShareFailure(String error) {
    return 'Could not share file to group: $error';
  }

  @override
  String get detailsNoShareLink => 'No link available to share the file';

  @override
  String get detailsDownloadSuccess =>
      'File downloaded and saved inside the app';

  @override
  String get detailsEditTitle => 'Edit File';

  @override
  String get detailsEditSuccess => 'File updated';

  @override
  String detailsEditFailure(String error) {
    return 'Failed to edit: $error';
  }

  @override
  String get detailsDeleteTitle => 'Delete File';

  @override
  String get detailsDeleteConfirm => 'Are you sure?';

  @override
  String get detailsBtnCancel => 'Cancel';

  @override
  String get detailsBtnDelete => 'Delete';

  @override
  String get detailsDeleteSuccess => 'File deleted';

  @override
  String detailsDeleteFailure(String error) {
    return 'Failed to delete file: $error';
  }

  @override
  String detailsDownloadFailure(String error) {
    return 'Download failed: $error';
  }

  @override
  String detailsShareGeneralFailure(String error) {
    return 'Could not register share: $error';
  }

  @override
  String get detailsFillRequiredFields => 'Complete all required fields';

  @override
  String get detailsBtnSaveEdits => 'Save Changes';

  @override
  String get detailsActionOpenFile => 'Open File';

  @override
  String get detailsSectionDescription => 'Description';

  @override
  String get detailsSectionFileInfo => 'File Information';

  @override
  String get detailsInfoCourse => 'Course';

  @override
  String get detailsInfoCollege => 'College';

  @override
  String get detailsInfoSpecialization => 'Specialization';

  @override
  String get detailsInfoLevel => 'Level';

  @override
  String get detailsInfoType => 'Type';

  @override
  String get detailsInfoStatus => 'Status';

  @override
  String get detailsInfoDate => 'Upload Date';

  @override
  String get detailsStatusApproved => 'Published';

  @override
  String get detailsStatusPending => 'Under Review';

  @override
  String get detailsStatusRejected => 'Rejected';

  @override
  String get detailsLikeAction => 'Like';

  @override
  String detailsLikeFailure(String error) {
    return 'Could not like: $error';
  }

  @override
  String get detailsSaveAction => 'Save';

  @override
  String detailsSaveFailure(String error) {
    return 'Could not save: $error';
  }

  @override
  String detailsUploaderPrefix(String uploader) {
    return 'Uploaded by: $uploader';
  }

  @override
  String get detailsStatViews => 'Views';

  @override
  String get detailsStatDownloads => 'Downloads';

  @override
  String get detailsStatShares => 'Shares';

  @override
  String detailsPrefixDr(String author) {
    return 'Dr. $author';
  }

  @override
  String get pdfBrowseFile => 'Browse File';

  @override
  String get digitalLibNoAbstract => 'No abstract available.';

  @override
  String get digitalLibResultDetailsTitle => 'Research Details';

  @override
  String get digitalLibLabelAuthors => 'Authors:';

  @override
  String get digitalLibLabelPublisher => 'Publisher:';

  @override
  String get digitalLibLabelYear => 'Publication Year:';

  @override
  String get digitalLibLabelJournal => 'Journal:';

  @override
  String digitalLibSaveErrorParam(String error) {
    return 'Could not save reference: $error';
  }

  @override
  String get digitalLibActionDownloadPdf => 'Download PDF';

  @override
  String digitalLibDownloadError(String error) {
    return 'Could not register download: $error';
  }

  @override
  String get digitalLibActionOpenSource => 'Open Source';

  @override
  String get digitalLibLabelAbstract => 'Abstract';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsMarkAllReadSuccess =>
      'All notifications marked as read';

  @override
  String get notificationsSectionToday => 'Today';

  @override
  String get notificationsSectionEarlier => 'Earlier';

  @override
  String get notificationsEmptyTitle => 'No notifications yet';

  @override
  String get notificationsEmptyDesc =>
      'When you have a new interaction or an important update, it will appear here clearly.';

  @override
  String get notifGroupCreatedTitle => 'Group Created';

  @override
  String notifGroupCreatedBody(String name) {
    return 'Your group $name was created and is now ready.';
  }

  @override
  String get notifGroupJoinedTitle => 'Joined Group';

  @override
  String notifGroupJoinedBody(String name) {
    return 'You are now a member of $name';
  }

  @override
  String get notifGroupJoinedPrivateTitle => 'Joined Private Group';

  @override
  String notifGroupJoinedPrivateBody(String name) {
    return 'You are now a member of $name';
  }

  @override
  String get notifGroupOwnershipTransferredTitle => 'Ownership Transferred';

  @override
  String notifGroupOwnershipTransferredBody(String name) {
    return 'You are now the owner of $name';
  }

  @override
  String get notifGroupPromotedAdminTitle => 'Promoted to Admin';

  @override
  String notifGroupPromotedAdminBody(String name) {
    return 'You are now an admin in $name';
  }

  @override
  String get notifGroupDemotedAdminTitle => 'Admin Privileges Removed';

  @override
  String notifGroupDemotedAdminBody(String name) {
    return 'You are no longer an admin in $name';
  }

  @override
  String get notifGroupMutedTitle => 'Muted in Group';

  @override
  String notifGroupMutedBody(String name) {
    return 'You can no longer send messages in $name';
  }

  @override
  String get notifGroupUnmutedTitle => 'Unmuted in Group';

  @override
  String notifGroupUnmutedBody(String name) {
    return 'You can now send messages again in $name';
  }

  @override
  String get notifGroupKickedTitle => 'Removed from Group';

  @override
  String notifGroupKickedBody(String name) {
    return 'Your membership in $name has been removed';
  }

  @override
  String get notifNewCommentTitle => 'New Comment';

  @override
  String notifNewCommentBody(String sender) {
    return '$sender commented on your post';
  }

  @override
  String get notifNewReplyTitle => 'New Reply';

  @override
  String notifNewReplyBody(String sender) {
    return '$sender replied to your comment';
  }

  @override
  String get notifLibraryFileApprovedTitle => 'File Approved';

  @override
  String notifLibraryFileApprovedBody(String name) {
    return 'File $name was accepted and is available in the library';
  }

  @override
  String get notifLibraryFileUploadedTitle => 'Upload Successful';

  @override
  String notifLibraryFileUploadedBody(String name) {
    return 'File $name is now available in the library';
  }

  @override
  String get timeYesterday => 'Yesterday';

  @override
  String timeMinutesAgoParam(int count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgoParam(int count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgoParam(int count) {
    return '${count}d ago';
  }

  @override
  String get upFileTypePdf => 'PDF';

  @override
  String get upFileTypeWord => 'Word';

  @override
  String get upFileTypeImage => 'Image';

  @override
  String get upFileTypeGeneric => 'File';
}
