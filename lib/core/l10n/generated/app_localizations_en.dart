// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Jma3a';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get loading => 'Loading…';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get skip => 'Skip';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get remove => 'Remove';

  @override
  String get close => 'Close';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get or => 'or';

  @override
  String get optional => 'Optional';

  @override
  String characters(int count, int max) {
    return '$count / $max';
  }

  @override
  String get error => 'Something went wrong';

  @override
  String get errorNetwork => 'Network error. Please check your connection.';

  @override
  String get errorUnexpected =>
      'An unexpected error occurred. Please try again.';

  @override
  String get errorNotFound => 'Not found';

  @override
  String get errorForbidden => 'You don\'t have permission to do that';

  @override
  String get navRooms => 'Rooms';

  @override
  String get navFriends => 'Friends';

  @override
  String get navMarketplace => 'Packs';

  @override
  String get navProfile => 'Profile';

  @override
  String get authWelcome => 'Welcome to Jma3a';

  @override
  String get authTagline => 'Play together, anywhere';

  @override
  String get authEmailLabel => 'Your email address';

  @override
  String get authEmailHint => 'Enter your email';

  @override
  String get authEmailInvalid => 'Please enter a valid email address';

  @override
  String get authSendOtp => 'Send code';

  @override
  String get authSendingOtp => 'Sending…';

  @override
  String authOtpSent(String email) {
    return 'Code sent to $email';
  }

  @override
  String get authOtpLabel => 'Verification code';

  @override
  String get authOtpHint => 'Enter 6-digit code';

  @override
  String get authOtpVerify => 'Verify';

  @override
  String get authOtpVerifying => 'Verifying…';

  @override
  String get authOtpResend => 'Resend code';

  @override
  String authOtpResendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get authOtpExpired => 'Code expired. Please request a new one.';

  @override
  String get authOtpInvalid => 'Invalid code. Please try again.';

  @override
  String get authOtpMaxAttempts =>
      'Too many attempts. Please request a new code.';

  @override
  String get onboardingTitle => 'Set up your profile';

  @override
  String get onboardingSubtitle => 'Choose a username to get started';

  @override
  String get onboardingUsernameLabel => 'Username';

  @override
  String get onboardingUsernameHint =>
      'lowercase letters, numbers, underscores';

  @override
  String get onboardingDisplayNameLabel => 'Display name';

  @override
  String get onboardingDisplayNameHint => 'How others will see you';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingUsernameInvalid =>
      '3–30 characters, letters, numbers, underscores only';

  @override
  String get onboardingUsernameTaken => 'This username is already taken';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileEditTitle => 'Edit profile';

  @override
  String get profileBioLabel => 'Bio';

  @override
  String get profileBioHint => 'Tell others a bit about yourself';

  @override
  String get profileCountryLabel => 'Country';

  @override
  String get profileLanguageLabel => 'Language';

  @override
  String get profileAvatarChange => 'Change photo';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsSignOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get roomsTitle => 'Rooms';

  @override
  String get roomsBrowse => 'Browse rooms';

  @override
  String get roomsCreate => 'Create room';

  @override
  String get roomsJoinCode => 'Join with code';

  @override
  String get roomsEnterCode => 'Enter invite code';

  @override
  String get roomsCodeHint => '6-character code';

  @override
  String get roomsJoin => 'Join';

  @override
  String get roomsJoining => 'Joining…';

  @override
  String get roomsPublic => 'Public';

  @override
  String get roomsPrivate => 'Private';

  @override
  String roomsPlayers(int current, int max) {
    return '$current/$max players';
  }

  @override
  String get roomsEmpty => 'No rooms right now';

  @override
  String get roomsEmptySubtitle => 'Create one and invite your friends!';

  @override
  String get roomsFull => 'Room is full';

  @override
  String get roomsBanned => 'You are banned from this room';

  @override
  String get lobbyTitle => 'Lobby';

  @override
  String get lobbyWaiting => 'Waiting for players…';

  @override
  String get lobbyReady => 'Ready';

  @override
  String get lobbyNotReady => 'Not ready';

  @override
  String get lobbyStartGame => 'Start game';

  @override
  String get lobbySelectGame => 'Select game';

  @override
  String get lobbySelectPack => 'Select pack';

  @override
  String get lobbyCopied => 'Code copied!';

  @override
  String get lobbyLeave => 'Leave room';

  @override
  String get lobbyLeaveConfirm => 'Are you sure you want to leave?';

  @override
  String lobbyOwnerLeft(String name) {
    return '$name is now the room owner';
  }

  @override
  String lobbyPlayerJoined(String name) {
    return '$name joined';
  }

  @override
  String lobbyPlayerLeft(String name) {
    return '$name left';
  }

  @override
  String get chatPlaceholder => 'Say something…';

  @override
  String get chatMuted => 'You are muted';

  @override
  String get chatSend => 'Send';

  @override
  String get gameSettings => 'Game settings';

  @override
  String get gameSettingsTurnTimer => 'Turn timer';

  @override
  String get gameSettingsAllowSkip => 'Allow skip';

  @override
  String get gameSettingsMaxRounds => 'Max rounds';

  @override
  String get gameSettingsAllowSpicy => 'Allow spicy content';

  @override
  String gameSettingsSeconds(int n) {
    return '${n}s';
  }

  @override
  String get gameReconnecting => 'Reconnecting…';

  @override
  String get gameRecovering => 'Catching up…';

  @override
  String get gameConnectionLost => 'Connection lost';

  @override
  String get gameConnectionLostBody =>
      'Unable to reconnect after multiple attempts.';

  @override
  String get gameLeaveRoom => 'Leave room';

  @override
  String get gameTryAgain => 'Try again';

  @override
  String get moderationKick => 'Kick player';

  @override
  String get moderationMute => 'Mute player';

  @override
  String get moderationBan => 'Ban from room';

  @override
  String moderationKickConfirm(String name) {
    return 'Kick $name from the room?';
  }

  @override
  String get moderationYouWereKicked => 'You were removed from the room';

  @override
  String get moderationYouWereMuted => 'You have been muted';

  @override
  String get moderationGamePaused => 'Game paused';

  @override
  String get moderationGameResumed => 'Game resumed';

  @override
  String get roomsJoinRequestSent =>
      'Join request sent! Waiting for host approval.';

  @override
  String get roomsRequiresApproval => 'This room requires approval to join';

  @override
  String get roomsJoinApproved => 'Your join request was approved!';

  @override
  String get roomsJoinRejected => 'Your join request was declined.';

  @override
  String get roomsSpectators => 'Spectators';

  @override
  String roomsSpectatorCount(int count) {
    return '$count watching';
  }

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotifFriendRequests => 'Friend requests';

  @override
  String get settingsNotifRoomInvites => 'Room invites';

  @override
  String get settingsNotifGameActions => 'Game actions';

  @override
  String get settingsNotifWallet => 'Wallet updates';

  @override
  String get settingsNotifPackSales => 'Pack sales';

  @override
  String get walletEarnings => 'Earnings';

  @override
  String get walletEarningsTotal => 'Total earned';

  @override
  String get walletEarningsThisMonth => 'This month';

  @override
  String get walletEarningsTotalSales => 'Total sales';

  @override
  String get walletEarningsAvailable => 'Available';

  @override
  String get walletEarningsCommissionRate => 'Your rate';

  @override
  String get walletTransactionHistory => 'Transaction history';

  @override
  String get profileGames => 'Games';

  @override
  String get profileFriends => 'Friends';

  @override
  String get profilePacks => 'Packs';

  @override
  String get profileFollowers => 'Followers';

  @override
  String get profileFollowing => 'Following';

  @override
  String get profileNotFound => 'Profile not found';

  @override
  String profileGamesPlayed(int count) {
    return '$count games';
  }

  @override
  String get gameSettingsSpicy => 'Spicy cards';

  @override
  String get gameSettingsRequireApproval => 'Require approval to join';

  @override
  String get gameSettingsAllowSpectators => 'Allow spectators';

  @override
  String get lobbyJoinRequests => 'Join requests';

  @override
  String get lobbyApprove => 'Approve';

  @override
  String get lobbyReject => 'Reject';

  @override
  String get packCategory => 'Category';

  @override
  String get packCategoryHint => 'Select a category';

  @override
  String get packCategoryNone => 'No category';
}
