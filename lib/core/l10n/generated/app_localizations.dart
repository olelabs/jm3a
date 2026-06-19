import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Jma3a'**
  String get appName;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @characters.
  ///
  /// In en, this message translates to:
  /// **'{count} / {max}'**
  String characters(int count, int max);

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get error;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get errorNetwork;

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get errorUnexpected;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get errorNotFound;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do that'**
  String get errorForbidden;

  /// No description provided for @navRooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get navRooms;

  /// No description provided for @navFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get navFriends;

  /// No description provided for @navMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Packs'**
  String get navMarketplace;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @authWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Jma3a'**
  String get authWelcome;

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'Play together, anywhere'**
  String get authTagline;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Your email address'**
  String get authEmailLabel;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEmailHint;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get authEmailInvalid;

  /// No description provided for @authSendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get authSendOtp;

  /// No description provided for @authSendingOtp.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get authSendingOtp;

  /// No description provided for @authOtpSent.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {email}'**
  String authOtpSent(String email);

  /// No description provided for @authOtpLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get authOtpLabel;

  /// No description provided for @authOtpHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit code'**
  String get authOtpHint;

  /// No description provided for @authOtpVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get authOtpVerify;

  /// No description provided for @authOtpVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying…'**
  String get authOtpVerifying;

  /// No description provided for @authOtpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authOtpResend;

  /// No description provided for @authOtpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String authOtpResendIn(int seconds);

  /// No description provided for @authOtpExpired.
  ///
  /// In en, this message translates to:
  /// **'Code expired. Please request a new one.'**
  String get authOtpExpired;

  /// No description provided for @authOtpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid code. Please try again.'**
  String get authOtpInvalid;

  /// No description provided for @authOtpMaxAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please request a new code.'**
  String get authOtpMaxAttempts;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your profile'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a username to get started'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get onboardingUsernameLabel;

  /// No description provided for @onboardingUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'lowercase letters, numbers, underscores'**
  String get onboardingUsernameHint;

  /// No description provided for @onboardingDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get onboardingDisplayNameLabel;

  /// No description provided for @onboardingDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'How others will see you'**
  String get onboardingDisplayNameHint;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingUsernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'3–30 characters, letters, numbers, underscores only'**
  String get onboardingUsernameInvalid;

  /// No description provided for @onboardingUsernameTaken.
  ///
  /// In en, this message translates to:
  /// **'This username is already taken'**
  String get onboardingUsernameTaken;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditTitle;

  /// No description provided for @profileBioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get profileBioLabel;

  /// No description provided for @profileBioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell others a bit about yourself'**
  String get profileBioHint;

  /// No description provided for @profileCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get profileCountryLabel;

  /// No description provided for @profileLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguageLabel;

  /// No description provided for @profileAvatarChange.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get profileAvatarChange;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @settingsSignOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get settingsSignOutConfirm;

  /// No description provided for @roomsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get roomsTitle;

  /// No description provided for @roomsBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse rooms'**
  String get roomsBrowse;

  /// No description provided for @roomsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create room'**
  String get roomsCreate;

  /// No description provided for @roomsJoinCode.
  ///
  /// In en, this message translates to:
  /// **'Join with code'**
  String get roomsJoinCode;

  /// No description provided for @roomsEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter invite code'**
  String get roomsEnterCode;

  /// No description provided for @roomsCodeHint.
  ///
  /// In en, this message translates to:
  /// **'6-character code'**
  String get roomsCodeHint;

  /// No description provided for @roomsJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get roomsJoin;

  /// No description provided for @roomsJoining.
  ///
  /// In en, this message translates to:
  /// **'Joining…'**
  String get roomsJoining;

  /// No description provided for @roomsPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get roomsPublic;

  /// No description provided for @roomsPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get roomsPrivate;

  /// No description provided for @roomsPlayers.
  ///
  /// In en, this message translates to:
  /// **'{current}/{max} players'**
  String roomsPlayers(int current, int max);

  /// No description provided for @roomsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No rooms right now'**
  String get roomsEmpty;

  /// No description provided for @roomsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create one and invite your friends!'**
  String get roomsEmptySubtitle;

  /// No description provided for @roomsFull.
  ///
  /// In en, this message translates to:
  /// **'Room is full'**
  String get roomsFull;

  /// No description provided for @roomsBanned.
  ///
  /// In en, this message translates to:
  /// **'You are banned from this room'**
  String get roomsBanned;

  /// No description provided for @lobbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Lobby'**
  String get lobbyTitle;

  /// No description provided for @lobbyWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for players…'**
  String get lobbyWaiting;

  /// No description provided for @lobbyReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get lobbyReady;

  /// No description provided for @lobbyNotReady.
  ///
  /// In en, this message translates to:
  /// **'Not ready'**
  String get lobbyNotReady;

  /// No description provided for @lobbyStartGame.
  ///
  /// In en, this message translates to:
  /// **'Start game'**
  String get lobbyStartGame;

  /// No description provided for @lobbySelectGame.
  ///
  /// In en, this message translates to:
  /// **'Select game'**
  String get lobbySelectGame;

  /// No description provided for @lobbySelectPack.
  ///
  /// In en, this message translates to:
  /// **'Select pack'**
  String get lobbySelectPack;

  /// No description provided for @lobbyCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied!'**
  String get lobbyCopied;

  /// No description provided for @lobbyLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave room'**
  String get lobbyLeave;

  /// No description provided for @lobbyLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave?'**
  String get lobbyLeaveConfirm;

  /// No description provided for @lobbyOwnerLeft.
  ///
  /// In en, this message translates to:
  /// **'{name} is now the room owner'**
  String lobbyOwnerLeft(String name);

  /// No description provided for @lobbyPlayerJoined.
  ///
  /// In en, this message translates to:
  /// **'{name} joined'**
  String lobbyPlayerJoined(String name);

  /// No description provided for @lobbyPlayerLeft.
  ///
  /// In en, this message translates to:
  /// **'{name} left'**
  String lobbyPlayerLeft(String name);

  /// No description provided for @chatPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Say something…'**
  String get chatPlaceholder;

  /// No description provided for @chatMuted.
  ///
  /// In en, this message translates to:
  /// **'You are muted'**
  String get chatMuted;

  /// No description provided for @chatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// No description provided for @gameSettings.
  ///
  /// In en, this message translates to:
  /// **'Game settings'**
  String get gameSettings;

  /// No description provided for @gameSettingsTurnTimer.
  ///
  /// In en, this message translates to:
  /// **'Turn timer'**
  String get gameSettingsTurnTimer;

  /// No description provided for @gameSettingsAllowSkip.
  ///
  /// In en, this message translates to:
  /// **'Allow skip'**
  String get gameSettingsAllowSkip;

  /// No description provided for @gameSettingsMaxRounds.
  ///
  /// In en, this message translates to:
  /// **'Max rounds'**
  String get gameSettingsMaxRounds;

  /// No description provided for @gameSettingsAllowSpicy.
  ///
  /// In en, this message translates to:
  /// **'Allow spicy content'**
  String get gameSettingsAllowSpicy;

  /// No description provided for @gameSettingsSeconds.
  ///
  /// In en, this message translates to:
  /// **'{n}s'**
  String gameSettingsSeconds(int n);

  /// No description provided for @gameReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get gameReconnecting;

  /// No description provided for @gameRecovering.
  ///
  /// In en, this message translates to:
  /// **'Catching up…'**
  String get gameRecovering;

  /// No description provided for @gameConnectionLost.
  ///
  /// In en, this message translates to:
  /// **'Connection lost'**
  String get gameConnectionLost;

  /// No description provided for @gameConnectionLostBody.
  ///
  /// In en, this message translates to:
  /// **'Unable to reconnect after multiple attempts.'**
  String get gameConnectionLostBody;

  /// No description provided for @gameLeaveRoom.
  ///
  /// In en, this message translates to:
  /// **'Leave room'**
  String get gameLeaveRoom;

  /// No description provided for @gameTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get gameTryAgain;

  /// No description provided for @moderationKick.
  ///
  /// In en, this message translates to:
  /// **'Kick player'**
  String get moderationKick;

  /// No description provided for @moderationMute.
  ///
  /// In en, this message translates to:
  /// **'Mute player'**
  String get moderationMute;

  /// No description provided for @moderationBan.
  ///
  /// In en, this message translates to:
  /// **'Ban from room'**
  String get moderationBan;

  /// No description provided for @moderationKickConfirm.
  ///
  /// In en, this message translates to:
  /// **'Kick {name} from the room?'**
  String moderationKickConfirm(String name);

  /// No description provided for @moderationYouWereKicked.
  ///
  /// In en, this message translates to:
  /// **'You were removed from the room'**
  String get moderationYouWereKicked;

  /// No description provided for @moderationYouWereMuted.
  ///
  /// In en, this message translates to:
  /// **'You have been muted'**
  String get moderationYouWereMuted;

  /// No description provided for @moderationGamePaused.
  ///
  /// In en, this message translates to:
  /// **'Game paused'**
  String get moderationGamePaused;

  /// No description provided for @moderationGameResumed.
  ///
  /// In en, this message translates to:
  /// **'Game resumed'**
  String get moderationGameResumed;

  /// No description provided for @roomsJoinRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Join request sent! Waiting for host approval.'**
  String get roomsJoinRequestSent;

  /// No description provided for @roomsRequiresApproval.
  ///
  /// In en, this message translates to:
  /// **'This room requires approval to join'**
  String get roomsRequiresApproval;

  /// No description provided for @roomsJoinApproved.
  ///
  /// In en, this message translates to:
  /// **'Your join request was approved!'**
  String get roomsJoinApproved;

  /// No description provided for @roomsJoinRejected.
  ///
  /// In en, this message translates to:
  /// **'Your join request was declined.'**
  String get roomsJoinRejected;

  /// No description provided for @roomsSpectators.
  ///
  /// In en, this message translates to:
  /// **'Spectators'**
  String get roomsSpectators;

  /// No description provided for @roomsSpectatorCount.
  ///
  /// In en, this message translates to:
  /// **'{count} watching'**
  String roomsSpectatorCount(int count);

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotifFriendRequests.
  ///
  /// In en, this message translates to:
  /// **'Friend requests'**
  String get settingsNotifFriendRequests;

  /// No description provided for @settingsNotifRoomInvites.
  ///
  /// In en, this message translates to:
  /// **'Room invites'**
  String get settingsNotifRoomInvites;

  /// No description provided for @settingsNotifGameActions.
  ///
  /// In en, this message translates to:
  /// **'Game actions'**
  String get settingsNotifGameActions;

  /// No description provided for @settingsNotifWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet updates'**
  String get settingsNotifWallet;

  /// No description provided for @settingsNotifPackSales.
  ///
  /// In en, this message translates to:
  /// **'Pack sales'**
  String get settingsNotifPackSales;

  /// No description provided for @walletEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get walletEarnings;

  /// No description provided for @walletEarningsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total earned'**
  String get walletEarningsTotal;

  /// No description provided for @walletEarningsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get walletEarningsThisMonth;

  /// No description provided for @walletEarningsTotalSales.
  ///
  /// In en, this message translates to:
  /// **'Total sales'**
  String get walletEarningsTotalSales;

  /// No description provided for @walletEarningsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get walletEarningsAvailable;

  /// No description provided for @walletEarningsCommissionRate.
  ///
  /// In en, this message translates to:
  /// **'Your rate'**
  String get walletEarningsCommissionRate;

  /// No description provided for @walletTransactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction history'**
  String get walletTransactionHistory;

  /// No description provided for @profileGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get profileGames;

  /// No description provided for @profileFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get profileFriends;

  /// No description provided for @profilePacks.
  ///
  /// In en, this message translates to:
  /// **'Packs'**
  String get profilePacks;

  /// No description provided for @profileFollowers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get profileFollowers;

  /// No description provided for @profileFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get profileFollowing;

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get profileNotFound;

  /// No description provided for @profileGamesPlayed.
  ///
  /// In en, this message translates to:
  /// **'{count} games'**
  String profileGamesPlayed(int count);

  /// No description provided for @gameSettingsSpicy.
  ///
  /// In en, this message translates to:
  /// **'Spicy cards'**
  String get gameSettingsSpicy;

  /// No description provided for @gameSettingsRequireApproval.
  ///
  /// In en, this message translates to:
  /// **'Require approval to join'**
  String get gameSettingsRequireApproval;

  /// No description provided for @gameSettingsAllowSpectators.
  ///
  /// In en, this message translates to:
  /// **'Allow spectators'**
  String get gameSettingsAllowSpectators;

  /// No description provided for @lobbyJoinRequests.
  ///
  /// In en, this message translates to:
  /// **'Join requests'**
  String get lobbyJoinRequests;

  /// No description provided for @lobbyApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get lobbyApprove;

  /// No description provided for @lobbyReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get lobbyReject;

  /// No description provided for @packCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get packCategory;

  /// No description provided for @packCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get packCategoryHint;

  /// No description provided for @packCategoryNone.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get packCategoryNone;
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
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

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
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
