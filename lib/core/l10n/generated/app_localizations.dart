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

  /// No description provided for @introSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get introSkip;

  /// No description provided for @introNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get introNext;

  /// No description provided for @introGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get introGetStarted;

  /// No description provided for @introPage1Title.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Jma3a'**
  String get introPage1Title;

  /// No description provided for @introPage1Body.
  ///
  /// In en, this message translates to:
  /// **'Multiplayer party games — play with friends and family, anytime, anywhere.'**
  String get introPage1Body;

  /// No description provided for @introPage2Title.
  ///
  /// In en, this message translates to:
  /// **'Discover Packs'**
  String get introPage2Title;

  /// No description provided for @introPage2Body.
  ///
  /// In en, this message translates to:
  /// **'Community-created packs, premium packs, and physical packs you can order and play with.'**
  String get introPage2Body;

  /// No description provided for @introPage3Title.
  ///
  /// In en, this message translates to:
  /// **'Create or Join Rooms'**
  String get introPage3Title;

  /// No description provided for @introPage3Body.
  ///
  /// In en, this message translates to:
  /// **'Public rooms, private rooms, invite codes — play with friends however you like.'**
  String get introPage3Body;

  /// No description provided for @introPage4Title.
  ///
  /// In en, this message translates to:
  /// **'Premium Features'**
  String get introPage4Title;

  /// No description provided for @introPage4Body.
  ///
  /// In en, this message translates to:
  /// **'Custom themes, backgrounds, exclusive features, and tools built for creators.'**
  String get introPage4Body;

  /// No description provided for @introPage5Title.
  ///
  /// In en, this message translates to:
  /// **'Ready to Play'**
  String get introPage5Title;

  /// No description provided for @introPage5Body.
  ///
  /// In en, this message translates to:
  /// **'Everything\'s set. Let\'s get the party started.'**
  String get introPage5Body;

  /// No description provided for @settingsReplayIntro.
  ///
  /// In en, this message translates to:
  /// **'Replay Introduction'**
  String get settingsReplayIntro;

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

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

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

  /// No description provided for @authOtpLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get authOtpLabel;

  /// No description provided for @authOtpVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get authOtpVerify;

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

  /// No description provided for @authOtpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid code. Please try again.'**
  String get authOtpInvalid;

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

  /// No description provided for @settingsOnlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Online Status'**
  String get settingsOnlineStatus;

  /// No description provided for @settingsOnlineStatusPremiumHint.
  ///
  /// In en, this message translates to:
  /// **'Manual status is a Premium feature'**
  String get settingsOnlineStatusPremiumHint;

  /// No description provided for @presenceModeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get presenceModeAuto;

  /// No description provided for @presenceModeOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get presenceModeOnline;

  /// No description provided for @presenceModeOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get presenceModeOffline;

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

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsSectionAccount;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @settingsVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersionLabel;

  /// No description provided for @settingsSigningOut.
  ///
  /// In en, this message translates to:
  /// **'Signing out…'**
  String get settingsSigningOut;

  /// No description provided for @premiumBackgroundCustomSet.
  ///
  /// In en, this message translates to:
  /// **'Custom background set'**
  String get premiumBackgroundCustomSet;

  /// No description provided for @premiumBackgroundChooseColor.
  ///
  /// In en, this message translates to:
  /// **'Choose a background color'**
  String get premiumBackgroundChooseColor;

  /// No description provided for @premiumBackgroundUpgradeHint.
  ///
  /// In en, this message translates to:
  /// **'Premium feature — tap to upgrade'**
  String get premiumBackgroundUpgradeHint;

  /// No description provided for @premiumBackgroundSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save background color.'**
  String get premiumBackgroundSaveFailed;

  /// No description provided for @premiumBackgroundResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reset background color.'**
  String get premiumBackgroundResetFailed;

  /// No description provided for @roomsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get roomsTitle;

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

  /// No description provided for @qrRoomRevealTitle.
  ///
  /// In en, this message translates to:
  /// **'Room QR Code'**
  String get qrRoomRevealTitle;

  /// No description provided for @qrRoomRevealInstruction.
  ///
  /// In en, this message translates to:
  /// **'Scan to join this room'**
  String get qrRoomRevealInstruction;

  /// No description provided for @qrProfileRevealTitle.
  ///
  /// In en, this message translates to:
  /// **'My QR Code'**
  String get qrProfileRevealTitle;

  /// No description provided for @qrProfileRevealInstruction.
  ///
  /// In en, this message translates to:
  /// **'Scan to view my profile'**
  String get qrProfileRevealInstruction;

  /// No description provided for @qrClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get qrClose;

  /// No description provided for @qrShareLink.
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get qrShareLink;

  /// No description provided for @qrScanButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get qrScanButtonLabel;

  /// No description provided for @qrScanScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get qrScanScreenTitle;

  /// No description provided for @qrScanInstruction.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at a Jma3a QR code'**
  String get qrScanInstruction;

  /// No description provided for @qrScanInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'This isn\'t a valid Jma3a QR code'**
  String get qrScanInvalidCode;

  /// No description provided for @qrScanTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get qrScanTryAgain;

  /// No description provided for @roomsInvitedByName.
  ///
  /// In en, this message translates to:
  /// **'Invited by {name}'**
  String roomsInvitedByName(String name);

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

  /// No description provided for @lobbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Lobby'**
  String get lobbyTitle;

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

  /// No description provided for @lobbyStartGameFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the game — please try again.'**
  String get lobbyStartGameFailed;

  /// No description provided for @lobbyGameStarting.
  ///
  /// In en, this message translates to:
  /// **'Preparing the game…'**
  String get lobbyGameStarting;

  /// No description provided for @lobbyGameStartingBody.
  ///
  /// In en, this message translates to:
  /// **'Please wait while the game is being prepared.'**
  String get lobbyGameStartingBody;

  /// No description provided for @lobbyCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied!'**
  String get lobbyCopied;

  /// No description provided for @lobbyLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave?'**
  String get lobbyLeaveConfirm;

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

  /// No description provided for @gameSettingsMaxRoundsCapHint.
  ///
  /// In en, this message translates to:
  /// **'Maximum {cap} rounds — this pack has {cap} usable cards and every card is used at most once per game.'**
  String gameSettingsMaxRoundsCapHint(int cap);

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

  /// No description provided for @gameConnectionLost.
  ///
  /// In en, this message translates to:
  /// **'Connection lost'**
  String get gameConnectionLost;

  /// No description provided for @gameTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get gameTryAgain;

  /// No description provided for @gameYourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn!'**
  String get gameYourTurn;

  /// No description provided for @gamePlayerTurn.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s turn'**
  String gamePlayerTurn(String name);

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

  /// No description provided for @moderationYouWereKickedBy.
  ///
  /// In en, this message translates to:
  /// **'{name} removed you from the room'**
  String moderationYouWereKickedBy(String name);

  /// No description provided for @moderationYouWereBannedBy.
  ///
  /// In en, this message translates to:
  /// **'{name} banned you from the room'**
  String moderationYouWereBannedBy(String name);

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

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

  /// No description provided for @walletTransactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction history'**
  String get walletTransactionHistory;

  /// No description provided for @walletFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get walletFilterAll;

  /// No description provided for @walletFilterDeposits.
  ///
  /// In en, this message translates to:
  /// **'Deposits'**
  String get walletFilterDeposits;

  /// No description provided for @walletFilterWithdrawals.
  ///
  /// In en, this message translates to:
  /// **'Withdrawals'**
  String get walletFilterWithdrawals;

  /// No description provided for @walletFilterPurchases.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get walletFilterPurchases;

  /// No description provided for @walletFilterEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get walletFilterEarnings;

  /// No description provided for @walletFilterRefunds.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get walletFilterRefunds;

  /// No description provided for @walletFilterPayouts.
  ///
  /// In en, this message translates to:
  /// **'Payouts'**
  String get walletFilterPayouts;

  /// No description provided for @walletFilterBonuses.
  ///
  /// In en, this message translates to:
  /// **'Bonuses'**
  String get walletFilterBonuses;

  /// No description provided for @walletFilterAdjustments.
  ///
  /// In en, this message translates to:
  /// **'Adjustments'**
  String get walletFilterAdjustments;

  /// No description provided for @walletFilterTransfers.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get walletFilterTransfers;

  /// No description provided for @walletTypeDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get walletTypeDeposit;

  /// No description provided for @walletTypeWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get walletTypeWithdrawal;

  /// No description provided for @walletTypePurchase.
  ///
  /// In en, this message translates to:
  /// **'Pack Purchase'**
  String get walletTypePurchase;

  /// No description provided for @walletTypeRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get walletTypeRefund;

  /// No description provided for @walletTypeCommission.
  ///
  /// In en, this message translates to:
  /// **'Creator Earnings'**
  String get walletTypeCommission;

  /// No description provided for @walletTypePayout.
  ///
  /// In en, this message translates to:
  /// **'Payout'**
  String get walletTypePayout;

  /// No description provided for @walletTypeAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get walletTypeAdjustment;

  /// No description provided for @walletTypeBonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get walletTypeBonus;

  /// No description provided for @walletTypeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Balance Transfer'**
  String get walletTypeTransfer;

  /// No description provided for @walletStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get walletStatusPending;

  /// No description provided for @walletStatusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get walletStatusProcessing;

  /// No description provided for @walletStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get walletStatusCompleted;

  /// No description provided for @walletStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get walletStatusFailed;

  /// No description provided for @walletStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get walletStatusCancelled;

  /// No description provided for @walletStatusReversed.
  ///
  /// In en, this message translates to:
  /// **'Reversed'**
  String get walletStatusReversed;

  /// No description provided for @walletDepositStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get walletDepositStatusPending;

  /// No description provided for @walletDepositStatusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get walletDepositStatusUnderReview;

  /// No description provided for @walletDepositStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get walletDepositStatusApproved;

  /// No description provided for @walletDepositStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get walletDepositStatusRejected;

  /// No description provided for @profileGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get profileGames;

  /// No description provided for @usernameProfileResolving.
  ///
  /// In en, this message translates to:
  /// **'Loading profile…'**
  String get usernameProfileResolving;

  /// No description provided for @usernameProfileNotFound.
  ///
  /// In en, this message translates to:
  /// **'This profile couldn\'t be found.'**
  String get usernameProfileNotFound;

  /// No description provided for @profileScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get profileScore;

  /// No description provided for @profileHonestyPoints.
  ///
  /// In en, this message translates to:
  /// **'Honesty Points'**
  String get profileHonestyPoints;

  /// No description provided for @honestyVoteHonest.
  ///
  /// In en, this message translates to:
  /// **'Honest'**
  String get honestyVoteHonest;

  /// No description provided for @honestyVoteNotHonest.
  ///
  /// In en, this message translates to:
  /// **'Not honest'**
  String get honestyVoteNotHonest;

  /// No description provided for @honestyVoteRecorded.
  ///
  /// In en, this message translates to:
  /// **'Your vote was recorded'**
  String get honestyVoteRecorded;

  /// No description provided for @honestyVoteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t submit your vote — try again'**
  String get honestyVoteFailed;

  /// No description provided for @profileStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{count}-day streak'**
  String profileStreakDays(int count);

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

  /// No description provided for @streakAchievementBarrierLabel.
  ///
  /// In en, this message translates to:
  /// **'Streak achievement'**
  String get streakAchievementBarrierLabel;

  /// No description provided for @streakNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Streak!'**
  String get streakNewTitle;

  /// No description provided for @streakNewBody.
  ///
  /// In en, this message translates to:
  /// **'You started a new streak! Keep playing every day to make it bigger.'**
  String get streakNewBody;

  /// No description provided for @streakNewCta.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go!'**
  String get streakNewCta;

  /// No description provided for @streakExtendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Streak extended! {count} days in a row!'**
  String streakExtendedTitle(int count);

  /// No description provided for @streakExtendedBody.
  ///
  /// In en, this message translates to:
  /// **'{count} days in a row! You\'re on fire 🔥'**
  String streakExtendedBody(int count);

  /// No description provided for @streakExtendedCta.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get streakExtendedCta;

  /// No description provided for @profileShareAction.
  ///
  /// In en, this message translates to:
  /// **'Share Profile'**
  String get profileShareAction;

  /// No description provided for @profileShareMessage.
  ///
  /// In en, this message translates to:
  /// **'🎮 Join me on Jma3a! Follow {name}\n\n{link}'**
  String profileShareMessage(String name, String link);

  /// No description provided for @profileShareSubject.
  ///
  /// In en, this message translates to:
  /// **'🎮 {name} on Jma3a'**
  String profileShareSubject(String name);

  /// No description provided for @profileShareCardCta.
  ///
  /// In en, this message translates to:
  /// **'Tap to view my Jma3a profile'**
  String get profileShareCardCta;

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

  /// No description provided for @gameSettingsHonestyVote.
  ///
  /// In en, this message translates to:
  /// **'Honesty vote'**
  String get gameSettingsHonestyVote;

  /// No description provided for @gameSettingsAllowSpectators.
  ///
  /// In en, this message translates to:
  /// **'Allow spectators'**
  String get gameSettingsAllowSpectators;

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

  /// No description provided for @authUseEmailInstead.
  ///
  /// In en, this message translates to:
  /// **'Use email instead'**
  String get authUseEmailInstead;

  /// No description provided for @authUsePhoneInstead.
  ///
  /// In en, this message translates to:
  /// **'Use phone instead'**
  String get authUsePhoneInstead;

  /// No description provided for @authContinueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get authContinueAsGuest;

  /// No description provided for @authTermsPrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our Terms & Privacy Policy'**
  String get authTermsPrivacyNotice;

  /// No description provided for @authOtpAttemptsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} attempt remaining} other{{count} attempts remaining}}'**
  String authOtpAttemptsRemaining(int count);

  /// No description provided for @authTakingLonger.
  ///
  /// In en, this message translates to:
  /// **'Taking longer than usual…'**
  String get authTakingLonger;

  /// No description provided for @authContinueWithoutSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Continue without signing in'**
  String get authContinueWithoutSigningIn;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @onboardingGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get onboardingGenderLabel;

  /// No description provided for @onboardingGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get onboardingGenderMale;

  /// No description provided for @onboardingGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get onboardingGenderFemale;

  /// No description provided for @onboardingGenderRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select your gender'**
  String get onboardingGenderRequired;

  /// No description provided for @onboardingAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get onboardingAgeLabel;

  /// No description provided for @onboardingAgeHint.
  ///
  /// In en, this message translates to:
  /// **'Your age (13+)'**
  String get onboardingAgeHint;

  /// No description provided for @onboardingAgeRequired.
  ///
  /// In en, this message translates to:
  /// **'Age is required'**
  String get onboardingAgeRequired;

  /// No description provided for @onboardingAgeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid age'**
  String get onboardingAgeInvalid;

  /// No description provided for @onboardingAgeTooYoung.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 13 years old'**
  String get onboardingAgeTooYoung;

  /// No description provided for @onboardingDisplayNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 2 characters'**
  String get onboardingDisplayNameTooShort;

  /// No description provided for @onboardingDisplayNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Maximum 50 characters'**
  String get onboardingDisplayNameTooLong;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @chatTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTabLabel;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checking;

  /// No description provided for @defaultPlayerName.
  ///
  /// In en, this message translates to:
  /// **'A player'**
  String get defaultPlayerName;

  /// No description provided for @deny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get deny;

  /// No description provided for @errorConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get errorConnectionFailed;

  /// No description provided for @invited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get invited;

  /// No description provided for @kick.
  ///
  /// In en, this message translates to:
  /// **'Kick'**
  String get kick;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @leaveGame.
  ///
  /// In en, this message translates to:
  /// **'Leave Game'**
  String get leaveGame;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @muted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get muted;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sending;

  /// No description provided for @unban.
  ///
  /// In en, this message translates to:
  /// **'Unban'**
  String get unban;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @moderationYouWereBanned.
  ///
  /// In en, this message translates to:
  /// **'You were banned'**
  String get moderationYouWereBanned;

  /// No description provided for @lobbyAddAsFriend.
  ///
  /// In en, this message translates to:
  /// **'Add {name} as friend'**
  String lobbyAddAsFriend(String name);

  /// No description provided for @lobbyAllRequestsDecided.
  ///
  /// In en, this message translates to:
  /// **'All requests have been decided.'**
  String get lobbyAllRequestsDecided;

  /// No description provided for @lobbyAreFriends.
  ///
  /// In en, this message translates to:
  /// **'You and {name} are friends ✓'**
  String lobbyAreFriends(String name);

  /// No description provided for @lobbyAutoLetInOnceApproved.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be let in automatically once they approve.'**
  String get lobbyAutoLetInOnceApproved;

  /// No description provided for @lobbyBanReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String lobbyBanReason(String reason);

  /// No description provided for @lobbyBannedSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'🚫 Banned'**
  String get lobbyBannedSectionTitle;

  /// No description provided for @lobbyCannotSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Cannot send request to {name}'**
  String lobbyCannotSendRequest(String name);

  /// No description provided for @lobbyCloseRoomBody.
  ///
  /// In en, this message translates to:
  /// **'Closing the room will remove all players.'**
  String get lobbyCloseRoomBody;

  /// No description provided for @lobbyCloseRoomConfirm.
  ///
  /// In en, this message translates to:
  /// **'Close Room'**
  String get lobbyCloseRoomConfirm;

  /// No description provided for @lobbyCloseRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Close Room?'**
  String get lobbyCloseRoomTitle;

  /// No description provided for @lobbyCloseKeepGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Close this room?'**
  String get lobbyCloseKeepGameTitle;

  /// No description provided for @lobbyCloseKeepGameBody.
  ///
  /// In en, this message translates to:
  /// **'The room will disappear from Browse and no new players can join. Anyone already playing keeps playing — the game isn\'t interrupted, and the room isn\'t deleted.'**
  String get lobbyCloseKeepGameBody;

  /// No description provided for @lobbyCloseKeepGameConfirm.
  ///
  /// In en, this message translates to:
  /// **'Close Room'**
  String get lobbyCloseKeepGameConfirm;

  /// No description provided for @lobbyCloseKeepGameCta.
  ///
  /// In en, this message translates to:
  /// **'Close Room'**
  String get lobbyCloseKeepGameCta;

  /// No description provided for @lobbyRoomClosedForNewPlayers.
  ///
  /// In en, this message translates to:
  /// **'The host closed the room to new players.'**
  String get lobbyRoomClosedForNewPlayers;

  /// No description provided for @lobbyReopenTitle.
  ///
  /// In en, this message translates to:
  /// **'Reopen this room?'**
  String get lobbyReopenTitle;

  /// No description provided for @lobbyReopenBody.
  ///
  /// In en, this message translates to:
  /// **'The room will accept new players again and reappear in Browse. Nothing else changes — the room isn\'t recreated and no game is reset.'**
  String get lobbyReopenBody;

  /// No description provided for @lobbyReopenConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reopen Room'**
  String get lobbyReopenConfirm;

  /// No description provided for @lobbyReopenCta.
  ///
  /// In en, this message translates to:
  /// **'Reopen Room'**
  String get lobbyReopenCta;

  /// No description provided for @lobbySelectPackBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'Please select a pack before starting the game.'**
  String get lobbySelectPackBeforeStart;

  /// No description provided for @lobbyRejoinDecisionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String lobbyRejoinDecisionFailed(String error);

  /// No description provided for @premiumErrorInsufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Not enough balance. Please top up your wallet first.'**
  String get premiumErrorInsufficientBalance;

  /// No description provided for @premiumErrorWalletNotFound.
  ///
  /// In en, this message translates to:
  /// **'Wallet not found. Please contact support.'**
  String get premiumErrorWalletNotFound;

  /// No description provided for @premiumErrorWalletFrozen.
  ///
  /// In en, this message translates to:
  /// **'Your wallet is frozen. Please contact support.'**
  String get premiumErrorWalletFrozen;

  /// No description provided for @premiumErrorInvalidPlan.
  ///
  /// In en, this message translates to:
  /// **'Invalid plan selected.'**
  String get premiumErrorInvalidPlan;

  /// No description provided for @premiumErrorDowngradeBlocked.
  ///
  /// In en, this message translates to:
  /// **'You can switch plans once your current subscription expires.'**
  String get premiumErrorDowngradeBlocked;

  /// No description provided for @premiumErrorPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed: {error}'**
  String premiumErrorPurchaseFailed(String error);

  /// No description provided for @lobbyRoomReopened.
  ///
  /// In en, this message translates to:
  /// **'Room reopened — new players can join again.'**
  String get lobbyRoomReopened;

  /// No description provided for @lobbyCouldNotSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Could not send request — try again'**
  String get lobbyCouldNotSendRequest;

  /// No description provided for @lobbyDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get lobbyDeselectAll;

  /// No description provided for @lobbyFriendRequestPending.
  ///
  /// In en, this message translates to:
  /// **'Friend request pending'**
  String get lobbyFriendRequestPending;

  /// No description provided for @lobbyFriendRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent to {name} ✅'**
  String lobbyFriendRequestSent(String name);

  /// No description provided for @lobbyHiddenAnonymousCount.
  ///
  /// In en, this message translates to:
  /// **'+ {count} anonymous (visible to mods only)'**
  String lobbyHiddenAnonymousCount(int count);

  /// No description provided for @lobbyHowToJoin.
  ///
  /// In en, this message translates to:
  /// **'How do you want to join?'**
  String get lobbyHowToJoin;

  /// No description provided for @lobbyInviteCount.
  ///
  /// In en, this message translates to:
  /// **'Invite {count}'**
  String lobbyInviteCount(int count);

  /// No description provided for @lobbyInviteFriendsTitle.
  ///
  /// In en, this message translates to:
  /// **'👥 Invite Friends'**
  String get lobbyInviteFriendsTitle;

  /// No description provided for @lobbyJoinRequestSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Request Sent'**
  String get lobbyJoinRequestSentTitle;

  /// No description provided for @lobbyKickSpectatorBody.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from the room.'**
  String lobbyKickSpectatorBody(String name);

  /// No description provided for @lobbyKickSpectatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Kick spectator?'**
  String get lobbyKickSpectatorTitle;

  /// No description provided for @lobbyLeaveRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Room?'**
  String get lobbyLeaveRoomTitle;

  /// No description provided for @lobbyModerationTitle.
  ///
  /// In en, this message translates to:
  /// **'⚖️ Moderation'**
  String get lobbyModerationTitle;

  /// No description provided for @lobbyMutedSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'🔇 Muted'**
  String get lobbyMutedSectionTitle;

  /// No description provided for @lobbyNoFriendsMatchQuery.
  ///
  /// In en, this message translates to:
  /// **'No friends match \"{query}\"'**
  String lobbyNoFriendsMatchQuery(String query);

  /// No description provided for @lobbyNoFriendsToInvite.
  ///
  /// In en, this message translates to:
  /// **'No friends to invite yet.'**
  String get lobbyNoFriendsToInvite;

  /// No description provided for @lobbyNoMutedOrBanned.
  ///
  /// In en, this message translates to:
  /// **'No muted or banned players.'**
  String get lobbyNoMutedOrBanned;

  /// No description provided for @lobbyNoVisibleSpectators.
  ///
  /// In en, this message translates to:
  /// **'No visible spectators'**
  String get lobbyNoVisibleSpectators;

  /// No description provided for @lobbySpectatorsSection.
  ///
  /// In en, this message translates to:
  /// **'Spectators'**
  String get lobbySpectatorsSection;

  /// No description provided for @lobbyPermissionsFor.
  ///
  /// In en, this message translates to:
  /// **'Permissions for {name}'**
  String lobbyPermissionsFor(String name);

  /// No description provided for @lobbyPermissionsHint.
  ///
  /// In en, this message translates to:
  /// **'Owners can adjust these at any time.'**
  String get lobbyPermissionsHint;

  /// No description provided for @lobbyRejoinRequestsCount.
  ///
  /// In en, this message translates to:
  /// **'Rejoin Requests ({count})'**
  String lobbyRejoinRequestsCount(int count);

  /// No description provided for @lobbyRoomClosedBody.
  ///
  /// In en, this message translates to:
  /// **'The host closed the room.'**
  String get lobbyRoomClosedBody;

  /// No description provided for @lobbyRoomClosedTitle.
  ///
  /// In en, this message translates to:
  /// **'Room Closed'**
  String get lobbyRoomClosedTitle;

  /// No description provided for @lobbySearchFriendsHint.
  ///
  /// In en, this message translates to:
  /// **'Search friends…'**
  String get lobbySearchFriendsHint;

  /// No description provided for @lobbySelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get lobbySelectAll;

  /// No description provided for @lobbySelectPackToStart.
  ///
  /// In en, this message translates to:
  /// **'Select a pack in settings to start'**
  String get lobbySelectPackToStart;

  /// No description provided for @lobbyShareInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Share invite link'**
  String get lobbyShareInviteLink;

  /// No description provided for @roomShareMaxPlayers.
  ///
  /// In en, this message translates to:
  /// **'{count} players max'**
  String roomShareMaxPlayers(int count);

  /// No description provided for @roomShareInvitedBy.
  ///
  /// In en, this message translates to:
  /// **'Invited by'**
  String get roomShareInvitedBy;

  /// No description provided for @roomShareScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get roomShareScoreLabel;

  /// No description provided for @roomShareHonestyLabel.
  ///
  /// In en, this message translates to:
  /// **'Honesty'**
  String get roomShareHonestyLabel;

  /// No description provided for @roomShareJoinCta.
  ///
  /// In en, this message translates to:
  /// **'JOIN ROOM'**
  String get roomShareJoinCta;

  /// No description provided for @lobbyShareInviteMessage.
  ///
  /// In en, this message translates to:
  /// **'🎮 Join my Jma3a room!\n\nCode: {code}\n\n{link}'**
  String lobbyShareInviteMessage(String code, String link);

  /// No description provided for @lobbyShareInviteSubject.
  ///
  /// In en, this message translates to:
  /// **'🎮 Jma3a Code: {code}'**
  String lobbyShareInviteSubject(String code);

  /// No description provided for @lobbySpectateWatchHint.
  ///
  /// In en, this message translates to:
  /// **'These players want to watch the game as spectators.'**
  String get lobbySpectateWatchHint;

  /// No description provided for @lobbySpectatorRequestCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} spectator request} other{{count} spectator requests}}'**
  String lobbySpectatorRequestCount(int count);

  /// No description provided for @lobbySpectatorRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Spectator Requests'**
  String get lobbySpectatorRequestsTitle;

  /// No description provided for @lobbySpectatorsCount.
  ///
  /// In en, this message translates to:
  /// **'Spectators ({count})'**
  String lobbySpectatorsCount(int count);

  /// No description provided for @lobbyWaitingForHostApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the host to approve your request to join.'**
  String get lobbyWaitingForHostApproval;

  /// No description provided for @lobbyWantsToRejoin.
  ///
  /// In en, this message translates to:
  /// **'Wants to rejoin the game'**
  String get lobbyWantsToRejoin;

  /// No description provided for @lobbyWantsToSpectate.
  ///
  /// In en, this message translates to:
  /// **'Wants to spectate'**
  String get lobbyWantsToSpectate;

  /// No description provided for @lobbyYouAreHost.
  ///
  /// In en, this message translates to:
  /// **'You are the host'**
  String get lobbyYouAreHost;

  /// No description provided for @lobbyYouAreNowOwner.
  ///
  /// In en, this message translates to:
  /// **'You\'re now the room owner 👑'**
  String get lobbyYouAreNowOwner;

  /// No description provided for @defaultPackName.
  ///
  /// In en, this message translates to:
  /// **'Pack'**
  String get defaultPackName;

  /// No description provided for @gameNameAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get gameNameAll;

  /// No description provided for @gameNameMeme.
  ///
  /// In en, this message translates to:
  /// **'Meme Game'**
  String get gameNameMeme;

  /// No description provided for @gameNameNeverHaveIEver.
  ///
  /// In en, this message translates to:
  /// **'Never Have I'**
  String get gameNameNeverHaveIEver;

  /// No description provided for @gameNameTruthOrDare.
  ///
  /// In en, this message translates to:
  /// **'Truth or Dare'**
  String get gameNameTruthOrDare;

  /// No description provided for @gameSettingsChooseProofViewers.
  ///
  /// In en, this message translates to:
  /// **'Choose exactly who can see proof'**
  String get gameSettingsChooseProofViewers;

  /// No description provided for @gameSettingsMemberLabelSpectator.
  ///
  /// In en, this message translates to:
  /// **'{name} (spec)'**
  String gameSettingsMemberLabelSpectator(String name);

  /// No description provided for @gameSettingsNoPacksDevMsg.
  ///
  /// In en, this message translates to:
  /// **'No packs available. Run the seed SQL in Supabase.'**
  String get gameSettingsNoPacksDevMsg;

  /// No description provided for @gameSettingsPackPunishments.
  ///
  /// In en, this message translates to:
  /// **'Pack punishments'**
  String get gameSettingsPackPunishments;

  /// No description provided for @gameSettingsPlayersSubmit.
  ///
  /// In en, this message translates to:
  /// **'Players submit'**
  String get gameSettingsPlayersSubmit;

  /// No description provided for @gameSettingsProofCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get gameSettingsProofCustom;

  /// No description provided for @gameSettingsProofEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get gameSettingsProofEveryone;

  /// No description provided for @gameSettingsProofPlayers.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get gameSettingsProofPlayers;

  /// No description provided for @gameSettingsProofSpectators.
  ///
  /// In en, this message translates to:
  /// **'Spectators'**
  String get gameSettingsProofSpectators;

  /// No description provided for @gameSettingsProofVisibility.
  ///
  /// In en, this message translates to:
  /// **'Proof visibility'**
  String get gameSettingsProofVisibility;

  /// No description provided for @gameSettingsPunishmentHintDefault.
  ///
  /// In en, this message translates to:
  /// **'When a player skips, every other player submits a punishment and the skipped player picks one to do.'**
  String get gameSettingsPunishmentHintDefault;

  /// No description provided for @gameSettingsPunishmentHintPackAvailable.
  ///
  /// In en, this message translates to:
  /// **'This pack includes its own punishments. Choose who provides them when a player skips.'**
  String get gameSettingsPunishmentHintPackAvailable;

  /// No description provided for @gameSettingsPunishmentMode.
  ///
  /// In en, this message translates to:
  /// **'Punishment mode'**
  String get gameSettingsPunishmentMode;

  /// No description provided for @gameSettingsSelectPack.
  ///
  /// In en, this message translates to:
  /// **'Select Pack'**
  String get gameSettingsSelectPack;

  /// No description provided for @packSituationFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'What are you looking for?'**
  String get packSituationFilterTitle;

  /// No description provided for @packSituationFilterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional — pick a mood and we\'ll surface the best-fitting packs first.'**
  String get packSituationFilterSubtitle;

  /// No description provided for @packBestMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'BEST MATCH FOR YOU'**
  String get packBestMatchTitle;

  /// No description provided for @packOtherPacksTitle.
  ///
  /// In en, this message translates to:
  /// **'OTHER PACKS'**
  String get packOtherPacksTitle;

  /// No description provided for @packMatchedLabel.
  ///
  /// In en, this message translates to:
  /// **'Matched'**
  String get packMatchedLabel;

  /// No description provided for @packTagRelationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get packTagRelationship;

  /// No description provided for @packTagBreakup.
  ///
  /// In en, this message translates to:
  /// **'Breakup'**
  String get packTagBreakup;

  /// No description provided for @packTagFixingRelationship.
  ///
  /// In en, this message translates to:
  /// **'Fixing relationship'**
  String get packTagFixingRelationship;

  /// No description provided for @packTagDating.
  ///
  /// In en, this message translates to:
  /// **'Dating'**
  String get packTagDating;

  /// No description provided for @packTagCouples.
  ///
  /// In en, this message translates to:
  /// **'Couples'**
  String get packTagCouples;

  /// No description provided for @packTagFriendship.
  ///
  /// In en, this message translates to:
  /// **'Friendship'**
  String get packTagFriendship;

  /// No description provided for @packTagFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get packTagFamily;

  /// No description provided for @packTagParty.
  ///
  /// In en, this message translates to:
  /// **'Party'**
  String get packTagParty;

  /// No description provided for @packTagIcebreaker.
  ///
  /// In en, this message translates to:
  /// **'Icebreaker'**
  String get packTagIcebreaker;

  /// No description provided for @packTagWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get packTagWork;

  /// No description provided for @packTagTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get packTagTravel;

  /// No description provided for @packTagLateNight.
  ///
  /// In en, this message translates to:
  /// **'Late night'**
  String get packTagLateNight;

  /// No description provided for @packCreationTagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Types (optional)'**
  String get packCreationTagsTitle;

  /// No description provided for @packCreationTagsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help players find this pack for the right moment.'**
  String get packCreationTagsSubtitle;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @roleLabelPlayer.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get roleLabelPlayer;

  /// No description provided for @roleLabelSpectator.
  ///
  /// In en, this message translates to:
  /// **'Spectator'**
  String get roleLabelSpectator;

  /// No description provided for @roomsActiveRoomOpenBody.
  ///
  /// In en, this message translates to:
  /// **'Your room \"{name}\" is still open. Return to it, or close it to create a new one.'**
  String roomsActiveRoomOpenBody(String name);

  /// No description provided for @roomsActiveRoomPausedBody.
  ///
  /// In en, this message translates to:
  /// **'Your room \"{name}\" is paused. Return to it, or close it to create a new one.'**
  String roomsActiveRoomPausedBody(String name);

  /// No description provided for @roomsActiveRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'You already have an active room'**
  String get roomsActiveRoomTitle;

  /// No description provided for @roomsAllowSpectators.
  ///
  /// In en, this message translates to:
  /// **'Allow Spectators'**
  String get roomsAllowSpectators;

  /// No description provided for @roomsAllowSpectatorsHint.
  ///
  /// In en, this message translates to:
  /// **'Others can watch without playing'**
  String get roomsAllowSpectatorsHint;

  /// No description provided for @roomsAlreadyInRoomBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re still in \"{name}\". You can\'t be a player or spectator in two rooms at once — return to it, or leave it for good to join this one instead.'**
  String roomsAlreadyInRoomBody(String name);

  /// No description provided for @roomsAlreadyInRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re already in a room'**
  String get roomsAlreadyInRoomTitle;

  /// No description provided for @roomsBanConfirm.
  ///
  /// In en, this message translates to:
  /// **'Ban {name} from this room?'**
  String roomsBanConfirm(String name);

  /// No description provided for @roomsBrowsePacks.
  ///
  /// In en, this message translates to:
  /// **'Browse Packs'**
  String get roomsBrowsePacks;

  /// No description provided for @roomsCloseAndCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Close Existing Room and Create New Room'**
  String get roomsCloseAndCreateNew;

  /// No description provided for @roomsClosedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Room closed'**
  String get roomsClosedSnackbar;

  /// No description provided for @roomsDailyLimitFreeBody.
  ///
  /// In en, this message translates to:
  /// **'Free plan allows {basicLimit} rooms per day. Try again tomorrow, or upgrade to Premium for {premiumLimit} rooms/day.'**
  String roomsDailyLimitFreeBody(int basicLimit, int premiumLimit);

  /// No description provided for @roomsDailyLimitPremiumBody.
  ///
  /// In en, this message translates to:
  /// **'Premium plan allows {premiumLimit} rooms per day. Try again tomorrow.'**
  String roomsDailyLimitPremiumBody(int premiumLimit);

  /// No description provided for @roomsDailyLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily limit reached'**
  String get roomsDailyLimitTitle;

  /// No description provided for @roomsCreationTooSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get roomsCreationTooSoonTitle;

  /// No description provided for @roomsCreationTooSoonBody.
  ///
  /// In en, this message translates to:
  /// **'You can create your next room in {hours}h {minutes}m.'**
  String roomsCreationTooSoonBody(int hours, int minutes);

  /// No description provided for @roomsDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get roomsDuration;

  /// No description provided for @roomsDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String roomsDurationLabel(String duration);

  /// No description provided for @roomsGameLabel.
  ///
  /// In en, this message translates to:
  /// **'Game: {game}'**
  String roomsGameLabel(String game);

  /// No description provided for @roomsIconFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get roomsIconFree;

  /// No description provided for @roomsIconPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium ✦'**
  String get roomsIconPremium;

  /// No description provided for @roomsLeaveForGood.
  ///
  /// In en, this message translates to:
  /// **'Leave for good'**
  String get roomsLeaveForGood;

  /// No description provided for @roomsLeftTheGame.
  ///
  /// In en, this message translates to:
  /// **'Left the game'**
  String get roomsLeftTheGame;

  /// No description provided for @roomsMutedInGame.
  ///
  /// In en, this message translates to:
  /// **'Muted — watching only'**
  String get roomsMutedInGame;

  /// No description provided for @roomsWaitingForGameApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for game approval'**
  String get roomsWaitingForGameApproval;

  /// No description provided for @roomsMaxPlayers.
  ///
  /// In en, this message translates to:
  /// **'Max players'**
  String get roomsMaxPlayers;

  /// No description provided for @roomsMaxPlayersLabel.
  ///
  /// In en, this message translates to:
  /// **'Max players: {count}'**
  String roomsMaxPlayersLabel(String count);

  /// No description provided for @roomsModPermissionsCount.
  ///
  /// In en, this message translates to:
  /// **'MOD · {count}'**
  String roomsModPermissionsCount(int count);

  /// No description provided for @roomsMyClosedRooms.
  ///
  /// In en, this message translates to:
  /// **'My Closed Rooms'**
  String get roomsMyClosedRooms;

  /// No description provided for @roomsNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Friday Night Fun'**
  String get roomsNameHint;

  /// No description provided for @roomsNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Room name'**
  String get roomsNameLabel;

  /// No description provided for @roomsNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Maximum 60 characters'**
  String get roomsNameTooLong;

  /// No description provided for @roomsNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 3 characters'**
  String get roomsNameTooShort;

  /// No description provided for @roomsNoClosedRooms.
  ///
  /// In en, this message translates to:
  /// **'No rooms closed in the last 5 days.'**
  String get roomsNoClosedRooms;

  /// No description provided for @roomsNoGameData.
  ///
  /// In en, this message translates to:
  /// **'No game data available.'**
  String get roomsNoGameData;

  /// No description provided for @roomsNoPacksBody.
  ///
  /// In en, this message translates to:
  /// **'You need at least one pack to create a room — get a free pack or purchase one from the marketplace first.'**
  String get roomsNoPacksBody;

  /// No description provided for @roomsNoPacksTitle.
  ///
  /// In en, this message translates to:
  /// **'No packs available'**
  String get roomsNoPacksTitle;

  /// No description provided for @roomsParticipantsCount.
  ///
  /// In en, this message translates to:
  /// **'Participants ({count})'**
  String roomsParticipantsCount(int count);

  /// No description provided for @roomsPlayedLabel.
  ///
  /// In en, this message translates to:
  /// **'Played: {date}'**
  String roomsPlayedLabel(String date);

  /// No description provided for @roomsPlayedPacksCount.
  ///
  /// In en, this message translates to:
  /// **'Played Packs ({count})'**
  String roomsPlayedPacksCount(int count);

  /// No description provided for @roomsRequestSentBody.
  ///
  /// In en, this message translates to:
  /// **'Your join request has been sent. You\'ll be notified once the host approves it.'**
  String get roomsRequestSentBody;

  /// No description provided for @roomsRequestSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Sent!'**
  String get roomsRequestSentTitle;

  /// No description provided for @roomsRequireJoinApproval.
  ///
  /// In en, this message translates to:
  /// **'Require Join Approval'**
  String get roomsRequireJoinApproval;

  /// No description provided for @roomsRequireJoinApprovalHint.
  ///
  /// In en, this message translates to:
  /// **'You approve each request to join'**
  String get roomsRequireJoinApprovalHint;

  /// No description provided for @roomsRequireSpectatorApproval.
  ///
  /// In en, this message translates to:
  /// **'Require Spectator Approval'**
  String get roomsRequireSpectatorApproval;

  /// No description provided for @roomsRequireSpectatorApprovalHint.
  ///
  /// In en, this message translates to:
  /// **'You approve each request to spectate, separately from player join approval'**
  String get roomsRequireSpectatorApprovalHint;

  /// No description provided for @roomsResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get roomsResults;

  /// No description provided for @roomsReturnToMyRoom.
  ///
  /// In en, this message translates to:
  /// **'Return to My Room'**
  String get roomsReturnToMyRoom;

  /// No description provided for @roomsRoomIcon.
  ///
  /// In en, this message translates to:
  /// **'Room Icon'**
  String get roomsRoomIcon;

  /// No description provided for @roomsRoomInfo.
  ///
  /// In en, this message translates to:
  /// **'Room Info'**
  String get roomsRoomInfo;

  /// No description provided for @roomsStillInRoomBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re still in \"{name}\". Leave it before creating a new room.'**
  String roomsStillInRoomBody(String name);

  /// No description provided for @roomsSupportsUpToPlayers.
  ///
  /// In en, this message translates to:
  /// **'Your room supports up to {count} players'**
  String roomsSupportsUpToPlayers(int count);

  /// No description provided for @roomsTransferOwnership.
  ///
  /// In en, this message translates to:
  /// **'Transfer ownership'**
  String get roomsTransferOwnership;

  /// No description provided for @roomsUpgradeArrow.
  ///
  /// In en, this message translates to:
  /// **'Upgrade →'**
  String get roomsUpgradeArrow;

  /// No description provided for @roomsVisibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get roomsVisibility;

  /// No description provided for @roomsWinnerLabel.
  ///
  /// In en, this message translates to:
  /// **'🏆 Winner: {name}'**
  String roomsWinnerLabel(String name);

  /// No description provided for @gameNameNeverHaveIEverFull.
  ///
  /// In en, this message translates to:
  /// **'Never Have I Ever'**
  String get gameNameNeverHaveIEverFull;

  /// No description provided for @defaultGameName.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get defaultGameName;

  /// No description provided for @chatDisabledForRoom.
  ///
  /// In en, this message translates to:
  /// **'Chat is disabled for this room'**
  String get chatDisabledForRoom;

  /// No description provided for @chatNoMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatNoMessagesYet;

  /// No description provided for @chatSayHint.
  ///
  /// In en, this message translates to:
  /// **'Say something…'**
  String get chatSayHint;

  /// No description provided for @chatSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Message failed to send — tap send to try again'**
  String get chatSendFailed;

  /// No description provided for @chatReplyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String chatReplyingTo(String name);

  /// No description provided for @chatCancelReply.
  ///
  /// In en, this message translates to:
  /// **'Cancel reply'**
  String get chatCancelReply;

  /// No description provided for @chatAudienceEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get chatAudienceEveryone;

  /// No description provided for @chatAudienceOnly.
  ///
  /// In en, this message translates to:
  /// **'Only: {names}'**
  String chatAudienceOnly(String names);

  /// No description provided for @chatAudiencePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Who can see this message?'**
  String get chatAudiencePickerTitle;

  /// No description provided for @chatAudienceSelectPeople.
  ///
  /// In en, this message translates to:
  /// **'Select people'**
  String get chatAudienceSelectPeople;

  /// No description provided for @chatAudienceNoOneAvailable.
  ///
  /// In en, this message translates to:
  /// **'No one else is available to select right now.'**
  String get chatAudienceNoOneAvailable;

  /// No description provided for @chatAudienceApply.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get chatAudienceApply;

  /// No description provided for @chatTargetedIndicatorSender.
  ///
  /// In en, this message translates to:
  /// **'Only visible to {names}'**
  String chatTargetedIndicatorSender(String names);

  /// No description provided for @chatTargetedIndicatorRecipient.
  ///
  /// In en, this message translates to:
  /// **'Sent only to you and select people'**
  String get chatTargetedIndicatorRecipient;

  /// No description provided for @chatAudienceRequiresPremiumPlus.
  ///
  /// In en, this message translates to:
  /// **'Only Premium Plus members can target specific people.'**
  String get chatAudienceRequiresPremiumPlus;

  /// No description provided for @chatAudienceRecipientUnavailable.
  ///
  /// In en, this message translates to:
  /// **'One of the selected people is no longer available.'**
  String get chatAudienceRecipientUnavailable;

  /// No description provided for @chatAudienceNoLongerRoomMember.
  ///
  /// In en, this message translates to:
  /// **'You are no longer part of this room/game.'**
  String get chatAudienceNoLongerRoomMember;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @premiumBadge.
  ///
  /// In en, this message translates to:
  /// **'✨ Premium'**
  String get premiumBadge;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @todActivityAnswering.
  ///
  /// In en, this message translates to:
  /// **'{name} is answering…'**
  String todActivityAnswering(String name);

  /// No description provided for @todActivityChoosing.
  ///
  /// In en, this message translates to:
  /// **'{name} is choosing…'**
  String todActivityChoosing(String name);

  /// No description provided for @todActivityFinishingUp.
  ///
  /// In en, this message translates to:
  /// **'{name} is finishing up…'**
  String todActivityFinishingUp(String name);

  /// No description provided for @todActivityPerforming.
  ///
  /// In en, this message translates to:
  /// **'{name} is performing…'**
  String todActivityPerforming(String name);

  /// No description provided for @todActivityUploadingProof.
  ///
  /// In en, this message translates to:
  /// **'{name} is uploading proof…'**
  String todActivityUploadingProof(String name);

  /// No description provided for @todAddCardToDeck.
  ///
  /// In en, this message translates to:
  /// **'Add Card to Deck'**
  String get todAddCardToDeck;

  /// No description provided for @todAddCustomCardButton.
  ///
  /// In en, this message translates to:
  /// **'Add custom card'**
  String get todAddCustomCardButton;

  /// No description provided for @todAddCustomCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Card'**
  String get todAddCustomCardTitle;

  /// No description provided for @todAddDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a description (optional)…'**
  String get todAddDescriptionOptional;

  /// No description provided for @todAnswerRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'Your answer is required…'**
  String get todAnswerRequiredHint;

  /// No description provided for @todChoosingTruthOrDare.
  ///
  /// In en, this message translates to:
  /// **'{name} is choosing Truth or Dare…'**
  String todChoosingTruthOrDare(String name);

  /// No description provided for @todCompleteTurn.
  ///
  /// In en, this message translates to:
  /// **'Complete Turn'**
  String get todCompleteTurn;

  /// No description provided for @todCompletedTurn.
  ///
  /// In en, this message translates to:
  /// **'completed their turn!'**
  String get todCompletedTurn;

  /// No description provided for @todNoAnswerOrProofYet.
  ///
  /// In en, this message translates to:
  /// **'No response or proof for this turn'**
  String get todNoAnswerOrProofYet;

  /// No description provided for @todSpectatorWatchingLabel.
  ///
  /// In en, this message translates to:
  /// **'Watching — no actions available'**
  String get todSpectatorWatchingLabel;

  /// No description provided for @todCustomCardAdded.
  ///
  /// In en, this message translates to:
  /// **'✅ Custom card added to deck!'**
  String get todCustomCardAdded;

  /// No description provided for @todCustomCardSessionOnly.
  ///
  /// In en, this message translates to:
  /// **'This card will be added to the deck for this session only.'**
  String get todCustomCardSessionOnly;

  /// No description provided for @todDare.
  ///
  /// In en, this message translates to:
  /// **'Dare'**
  String get todDare;

  /// No description provided for @todDefaultPlayerNumbered.
  ///
  /// In en, this message translates to:
  /// **'Player {id}'**
  String todDefaultPlayerNumbered(String id);

  /// No description provided for @todDifficultyLabel.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get todDifficultyLabel;

  /// No description provided for @todDoneButton.
  ///
  /// In en, this message translates to:
  /// **'Respond ✅'**
  String get todDoneButton;

  /// No description provided for @todEndGame.
  ///
  /// In en, this message translates to:
  /// **'End Game'**
  String get todEndGame;

  /// No description provided for @todEndGameBody.
  ///
  /// In en, this message translates to:
  /// **'This will end the game for all players.'**
  String get todEndGameBody;

  /// No description provided for @todEndGameTitle.
  ///
  /// In en, this message translates to:
  /// **'End Game?'**
  String get todEndGameTitle;

  /// No description provided for @todLikedResponseVotes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{👍 Liked this response ({count} vote)} other{👍 Liked this response ({count} votes)}}'**
  String todLikedResponseVotes(int count);

  /// No description provided for @todNextTurn.
  ///
  /// In en, this message translates to:
  /// **'Next Turn →'**
  String get todNextTurn;

  /// No description provided for @todNoCardAvailable.
  ///
  /// In en, this message translates to:
  /// **'No card available — all cards used!'**
  String get todNoCardAvailable;

  /// No description provided for @todPointsAbbrev.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String todPointsAbbrev(int points);

  /// No description provided for @todQuotedResponse.
  ///
  /// In en, this message translates to:
  /// **'\"{response}\"'**
  String todQuotedResponse(String response);

  /// No description provided for @todProofTimerLabel.
  ///
  /// In en, this message translates to:
  /// **'Viewing duration'**
  String get todProofTimerLabel;

  /// No description provided for @todProofTimerNoLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get todProofTimerNoLimit;

  /// No description provided for @todProofVisibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Who can see this?'**
  String get todProofVisibilityLabel;

  /// No description provided for @todProofVisibilityEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get todProofVisibilityEveryone;

  /// No description provided for @todProofVisibilityPlayersOnly.
  ///
  /// In en, this message translates to:
  /// **'Players only'**
  String get todProofVisibilityPlayersOnly;

  /// No description provided for @todProofVisibilitySpectatorsOnly.
  ///
  /// In en, this message translates to:
  /// **'Spectators only'**
  String get todProofVisibilitySpectatorsOnly;

  /// No description provided for @todProofVisibilityPersonalized.
  ///
  /// In en, this message translates to:
  /// **'Personalized'**
  String get todProofVisibilityPersonalized;

  /// No description provided for @todProofVisibilityNoOneElse.
  ///
  /// In en, this message translates to:
  /// **'No one else is in the room yet.'**
  String get todProofVisibilityNoOneElse;

  /// No description provided for @todProofVisibilityPickAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one person.'**
  String get todProofVisibilityPickAtLeastOne;

  /// No description provided for @todProofViewedLabel.
  ///
  /// In en, this message translates to:
  /// **'Proof viewed'**
  String get todProofViewedLabel;

  /// No description provided for @todProofTapToViewLabel.
  ///
  /// In en, this message translates to:
  /// **'🔒 Tap to view proof'**
  String get todProofTapToViewLabel;

  /// No description provided for @todVoiceProofLabel.
  ///
  /// In en, this message translates to:
  /// **'VOICE PROOF'**
  String get todVoiceProofLabel;

  /// No description provided for @todImageProofLabel.
  ///
  /// In en, this message translates to:
  /// **'IMAGE PROOF'**
  String get todImageProofLabel;

  /// No description provided for @todProofReplayCount.
  ///
  /// In en, this message translates to:
  /// **'👁 Replay ({count} left)'**
  String todProofReplayCount(int count);

  /// No description provided for @todProofNoReplaysLeft.
  ///
  /// In en, this message translates to:
  /// **'No replays left for this proof.'**
  String get todProofNoReplaysLeft;

  /// No description provided for @todProofNotAllowedToView.
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to view this proof.'**
  String get todProofNotAllowedToView;

  /// No description provided for @todProofOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open proof — please try again.'**
  String get todProofOpenFailed;

  /// No description provided for @todReactLabel.
  ///
  /// In en, this message translates to:
  /// **'React:'**
  String get todReactLabel;

  /// No description provided for @todReadyForNextTurn.
  ///
  /// In en, this message translates to:
  /// **'I\'m Ready for Next Turn'**
  String get todReadyForNextTurn;

  /// No description provided for @todReadyWaitingHost.
  ///
  /// In en, this message translates to:
  /// **'✓ You\'re ready — waiting for the host to continue…'**
  String get todReadyWaitingHost;

  /// No description provided for @todRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording…'**
  String get todRecording;

  /// No description provided for @todSkipTurnMod.
  ///
  /// In en, this message translates to:
  /// **'Skip turn (mod)'**
  String get todSkipTurnMod;

  /// No description provided for @todSpectatingWaitingHost.
  ///
  /// In en, this message translates to:
  /// **'Spectating — waiting for the host to continue…'**
  String get todSpectatingWaitingHost;

  /// No description provided for @todSpicyBadge.
  ///
  /// In en, this message translates to:
  /// **'🌶 SPICY'**
  String get todSpicyBadge;

  /// No description provided for @todStopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop Recording'**
  String get todStopRecording;

  /// No description provided for @todSubmitCompleteTurn.
  ///
  /// In en, this message translates to:
  /// **'Submit & Complete Turn ✅'**
  String get todSubmitCompleteTurn;

  /// No description provided for @todTruth.
  ///
  /// In en, this message translates to:
  /// **'Truth'**
  String get todTruth;

  /// No description provided for @todChooseYourChallenge.
  ///
  /// In en, this message translates to:
  /// **'Choose your challenge'**
  String get todChooseYourChallenge;

  /// No description provided for @todPlayerIsChoosing.
  ///
  /// In en, this message translates to:
  /// **'{name} is choosing…'**
  String todPlayerIsChoosing(String name);

  /// No description provided for @todWaitingForPlayerGeneric.
  ///
  /// In en, this message translates to:
  /// **'Waiting for player…'**
  String get todWaitingForPlayerGeneric;

  /// No description provided for @todTruthChoiceDescription.
  ///
  /// In en, this message translates to:
  /// **'Answer a personal question honestly.'**
  String get todTruthChoiceDescription;

  /// No description provided for @todDareChoiceDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete a daring challenge.'**
  String get todDareChoiceDescription;

  /// No description provided for @todSkipCardConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip this card?'**
  String get todSkipCardConfirmTitle;

  /// No description provided for @todSkipCardConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Skipping may result in a group punishment vote.'**
  String get todSkipCardConfirmBody;

  /// No description provided for @todStatRounds.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get todStatRounds;

  /// No description provided for @todStatPlayers.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get todStatPlayers;

  /// No description provided for @todStatTotalTurns.
  ///
  /// In en, this message translates to:
  /// **'Total Turns'**
  String get todStatTotalTurns;

  /// No description provided for @todDareBadge.
  ///
  /// In en, this message translates to:
  /// **'DARE'**
  String get todDareBadge;

  /// No description provided for @todTruthBadge.
  ///
  /// In en, this message translates to:
  /// **'TRUTH'**
  String get todTruthBadge;

  /// No description provided for @nhieBadgeAllCaps.
  ///
  /// In en, this message translates to:
  /// **'NEVER HAVE I EVER'**
  String get nhieBadgeAllCaps;

  /// No description provided for @memeBadgeAllCaps.
  ///
  /// In en, this message translates to:
  /// **'MEME PROMPT'**
  String get memeBadgeAllCaps;

  /// No description provided for @memePickStickerFirst.
  ///
  /// In en, this message translates to:
  /// **'Pick a sticker first'**
  String get memePickStickerFirst;

  /// No description provided for @memeSubmitResponseButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Response'**
  String get memeSubmitResponseButton;

  /// No description provided for @gameNotStartedYet.
  ///
  /// In en, this message translates to:
  /// **'Game not started yet'**
  String get gameNotStartedYet;

  /// No description provided for @gameNotReady.
  ///
  /// In en, this message translates to:
  /// **'Game not ready'**
  String get gameNotReady;

  /// No description provided for @todTruthRequiresResponse.
  ///
  /// In en, this message translates to:
  /// **'Truth requires a response'**
  String get todTruthRequiresResponse;

  /// No description provided for @todDareRequiresResponseOrProof.
  ///
  /// In en, this message translates to:
  /// **'Add a description or attach proof before continuing'**
  String get todDareRequiresResponseOrProof;

  /// No description provided for @todProofVoteRequiresVoice.
  ///
  /// In en, this message translates to:
  /// **'The group voted for voice proof — record one to continue'**
  String get todProofVoteRequiresVoice;

  /// No description provided for @todProofVoteRequiresImage.
  ///
  /// In en, this message translates to:
  /// **'The group voted for photo proof — attach one to continue'**
  String get todProofVoteRequiresImage;

  /// No description provided for @todTypeDare.
  ///
  /// In en, this message translates to:
  /// **'🔥 Dare'**
  String get todTypeDare;

  /// No description provided for @todTypeTruth.
  ///
  /// In en, this message translates to:
  /// **'🤔 Truth'**
  String get todTypeTruth;

  /// No description provided for @todVoiceMaxSeconds.
  ///
  /// In en, this message translates to:
  /// **'Voice (max {n}s)'**
  String todVoiceMaxSeconds(int n);

  /// No description provided for @todVoiceProofRecorded.
  ///
  /// In en, this message translates to:
  /// **'Voice proof recorded'**
  String get todVoiceProofRecorded;

  /// No description provided for @todVoiceProofTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Proof'**
  String get todVoiceProofTitle;

  /// No description provided for @todVotedForResponseTotal.
  ///
  /// In en, this message translates to:
  /// **'✓ You voted for this response ({count} total)'**
  String todVotedForResponseTotal(int count);

  /// No description provided for @todWaitingForToFinishReading.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {names} to finish reading…'**
  String todWaitingForToFinishReading(String names);

  /// No description provided for @todWriteCardPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Write your card prompt…'**
  String get todWriteCardPromptHint;

  /// No description provided for @someone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get someone;

  /// No description provided for @todAllPlayersLeftGameBody.
  ///
  /// In en, this message translates to:
  /// **'All players left the game.'**
  String get todAllPlayersLeftGameBody;

  /// No description provided for @todAllPlayersLeftGameEnded.
  ///
  /// In en, this message translates to:
  /// **'All players left — game ended'**
  String get todAllPlayersLeftGameEnded;

  /// No description provided for @todChatTitle.
  ///
  /// In en, this message translates to:
  /// **'💬 Chat'**
  String get todChatTitle;

  /// No description provided for @todGameEnded.
  ///
  /// In en, this message translates to:
  /// **'Game Ended'**
  String get todGameEnded;

  /// No description provided for @todGameOver.
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get todGameOver;

  /// No description provided for @todGamePausedTitle.
  ///
  /// In en, this message translates to:
  /// **'Game Paused'**
  String get todGamePausedTitle;

  /// No description provided for @todGoToLobby.
  ///
  /// In en, this message translates to:
  /// **'Go to Lobby'**
  String get todGoToLobby;

  /// No description provided for @todHistoryRoundsCount.
  ///
  /// In en, this message translates to:
  /// **'History ({count} rounds)'**
  String todHistoryRoundsCount(int count);

  /// No description provided for @todHostEndedGame.
  ///
  /// In en, this message translates to:
  /// **'The host ended the game'**
  String get todHostEndedGame;

  /// No description provided for @todHostEndedGameBody.
  ///
  /// In en, this message translates to:
  /// **'The host ended the game.'**
  String get todHostEndedGameBody;

  /// No description provided for @todHostSteppedAway.
  ///
  /// In en, this message translates to:
  /// **'The host stepped away and will\nreturn shortly.'**
  String get todHostSteppedAway;

  /// No description provided for @todLeaveForNow.
  ///
  /// In en, this message translates to:
  /// **'Leave for Now'**
  String get todLeaveForNow;

  /// No description provided for @todNoRoundsYet.
  ///
  /// In en, this message translates to:
  /// **'No rounds completed yet.'**
  String get todNoRoundsYet;

  /// No description provided for @todPlayerLeftGame.
  ///
  /// In en, this message translates to:
  /// **'👋 {name} left the game'**
  String todPlayerLeftGame(String name);

  /// No description provided for @todForcePunishmentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Force this punishment'**
  String get todForcePunishmentTooltip;

  /// No description provided for @todPunishmentModeOn.
  ///
  /// In en, this message translates to:
  /// **'Punishment mode ON'**
  String get todPunishmentModeOn;

  /// No description provided for @todQuitGame.
  ///
  /// In en, this message translates to:
  /// **'Quit Game'**
  String get todQuitGame;

  /// No description provided for @todQuitGameBody.
  ///
  /// In en, this message translates to:
  /// **'Leave the current game?'**
  String get todQuitGameBody;

  /// No description provided for @todQuitGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Quit Game?'**
  String get todQuitGameTitle;

  /// No description provided for @todRemovedFromGame.
  ///
  /// In en, this message translates to:
  /// **'You were removed from this game'**
  String get todRemovedFromGame;

  /// No description provided for @todRoundTypeContent.
  ///
  /// In en, this message translates to:
  /// **'{type}: {content}'**
  String todRoundTypeContent(String type, String content);

  /// No description provided for @todScreenshotTaken.
  ///
  /// In en, this message translates to:
  /// **'📸 {name} took a screenshot'**
  String todScreenshotTaken(String name);

  /// No description provided for @todSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get todSkipped;

  /// No description provided for @todProofWatchedByCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Proof sent — not watched yet} other{Proof watched by {count}}}'**
  String todProofWatchedByCount(int count);

  /// No description provided for @todReplayCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No replays yet} one{{count} replay} other{{count} replays}}'**
  String todReplayCount(int count);

  /// No description provided for @todVoteCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{👍 {count} vote} other{👍 {count} votes}}'**
  String todVoteCount(int count);

  /// No description provided for @todYouAreNowHost.
  ///
  /// In en, this message translates to:
  /// **'👑 You are now the game host!'**
  String get todYouAreNowHost;

  /// No description provided for @secAbbrev.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get secAbbrev;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @todConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Truth or Dare Setup'**
  String get todConfigTitle;

  /// No description provided for @todConfigSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure this game before it starts — you won\'t be able to change it once it begins.'**
  String get todConfigSubtitle;

  /// No description provided for @todConfigForceDareTitle.
  ///
  /// In en, this message translates to:
  /// **'Force Dare Rules'**
  String get todConfigForceDareTitle;

  /// No description provided for @todConfigForceDareUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get todConfigForceDareUnlimited;

  /// No description provided for @todConfigForceDarePerPlayer.
  ///
  /// In en, this message translates to:
  /// **'Per Player'**
  String get todConfigForceDarePerPlayer;

  /// No description provided for @todConfigForceDarePerTurn.
  ///
  /// In en, this message translates to:
  /// **'Per Turn'**
  String get todConfigForceDarePerTurn;

  /// No description provided for @todConfigMaxTruths.
  ///
  /// In en, this message translates to:
  /// **'Max Truths'**
  String get todConfigMaxTruths;

  /// No description provided for @todConfigCardRepetitionTitle.
  ///
  /// In en, this message translates to:
  /// **'Card Repetition'**
  String get todConfigCardRepetitionTitle;

  /// No description provided for @todConfigCardRepetitionShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle Continuously'**
  String get todConfigCardRepetitionShuffle;

  /// No description provided for @todConfigCardRepetitionUnique.
  ///
  /// In en, this message translates to:
  /// **'Unique Cards'**
  String get todConfigCardRepetitionUnique;

  /// No description provided for @todConfigUniqueCardsCapHint.
  ///
  /// In en, this message translates to:
  /// **'This pack has {count} cards — Max Rounds can\'t exceed what\'s available once each card is used at most once per player\'s turn.'**
  String todConfigUniqueCardsCapHint(int count);

  /// No description provided for @todConfigConfirmStart.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Start'**
  String get todConfigConfirmStart;

  /// No description provided for @gameSettingsPackAlreadyPlayed.
  ///
  /// In en, this message translates to:
  /// **'This pack has already been played in this room. Choose a different pack.'**
  String get gameSettingsPackAlreadyPlayed;

  /// No description provided for @todForcedDareHint.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used up your Truths for now — Dare only.'**
  String get todForcedDareHint;

  /// No description provided for @todEndReasonDefault.
  ///
  /// In en, this message translates to:
  /// **'Game finished'**
  String get todEndReasonDefault;

  /// No description provided for @todEndReasonManual.
  ///
  /// In en, this message translates to:
  /// **'Game ended by host'**
  String get todEndReasonManual;

  /// No description provided for @todEndReasonRoundLimit.
  ///
  /// In en, this message translates to:
  /// **'All rounds completed'**
  String get todEndReasonRoundLimit;

  /// No description provided for @todEndReasonScoreLimit.
  ///
  /// In en, this message translates to:
  /// **'Score limit reached'**
  String get todEndReasonScoreLimit;

  /// No description provided for @todEndReasonCardsExhausted.
  ///
  /// In en, this message translates to:
  /// **'All unique cards have been used'**
  String get todEndReasonCardsExhausted;

  /// No description provided for @todEveryoneElsePickingPunishment.
  ///
  /// In en, this message translates to:
  /// **'Everyone else is picking a punishment for you.'**
  String get todEveryoneElsePickingPunishment;

  /// No description provided for @todGameOverBang.
  ///
  /// In en, this message translates to:
  /// **'Game Over!'**
  String get todGameOverBang;

  /// No description provided for @todLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get todLeaderboard;

  /// No description provided for @todLoadingGame.
  ///
  /// In en, this message translates to:
  /// **'Loading game…'**
  String get todLoadingGame;

  /// No description provided for @todWaitingForPlayers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for other players to join… ({ready}/{total} ready)'**
  String todWaitingForPlayers(int ready, int total);

  /// No description provided for @hostReconnectWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for host to reconnect…'**
  String get hostReconnectWaitingTitle;

  /// No description provided for @hostReconnectWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'The game is paused. It will end automatically in {seconds}s if the host doesn\'t come back.'**
  String hostReconnectWaitingBody(int seconds);

  /// No description provided for @todOnlyPlayerCanPick.
  ///
  /// In en, this message translates to:
  /// **'Only {name} can pick — a moderator can force one if they\'re unresponsive.'**
  String todOnlyPlayerCanPick(String name);

  /// No description provided for @todPhaseChoosing.
  ///
  /// In en, this message translates to:
  /// **'Choosing'**
  String get todPhaseChoosing;

  /// No description provided for @todPhaseCompleting.
  ///
  /// In en, this message translates to:
  /// **'Completing…'**
  String get todPhaseCompleting;

  /// No description provided for @todPhaseInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get todPhaseInProgress;

  /// No description provided for @todPhaseVoting.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Voting'**
  String get todPhaseVoting;

  /// No description provided for @todPlayerSkipped.
  ///
  /// In en, this message translates to:
  /// **'{name} skipped!'**
  String todPlayerSkipped(String name);

  /// No description provided for @todRoundBadge.
  ///
  /// In en, this message translates to:
  /// **'Round {round} / {maxRound}'**
  String todRoundBadge(int round, int maxRound);

  /// No description provided for @todSubmitPunishmentFor.
  ///
  /// In en, this message translates to:
  /// **'Submit one punishment for {name}:'**
  String todSubmitPunishmentFor(String name);

  /// No description provided for @todPunishmentHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. \"Do 10 push-ups\"'**
  String get todPunishmentHint;

  /// No description provided for @todPickYourPunishment.
  ///
  /// In en, this message translates to:
  /// **'⚡ PICK YOUR PUNISHMENT'**
  String get todPickYourPunishment;

  /// No description provided for @todPlayerIsChoosingPunishment.
  ///
  /// In en, this message translates to:
  /// **'⚡ {name} IS CHOOSING…'**
  String todPlayerIsChoosingPunishment(String name);

  /// No description provided for @todEveryoneSubmittedPickOne.
  ///
  /// In en, this message translates to:
  /// **'Everyone submitted one — pick which you\'ll do.'**
  String get todEveryoneSubmittedPickOne;

  /// No description provided for @todWaitingForPlayerToPickOne.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to pick one.'**
  String todWaitingForPlayerToPickOne(String name);

  /// No description provided for @todSubmittedCount.
  ///
  /// In en, this message translates to:
  /// **'{submitted} / {expected} submitted'**
  String todSubmittedCount(int submitted, int expected);

  /// No description provided for @todSubmittedWaitingForOthers.
  ///
  /// In en, this message translates to:
  /// **'Submitted — waiting for everyone else…'**
  String get todSubmittedWaitingForOthers;

  /// No description provided for @todTimeForPunishment.
  ///
  /// In en, this message translates to:
  /// **'Time for a punishment…'**
  String get todTimeForPunishment;

  /// No description provided for @todWaitingChoosingQuestion.
  ///
  /// In en, this message translates to:
  /// **'Truth or Dare?'**
  String get todWaitingChoosingQuestion;

  /// No description provided for @todYourTurnBadge.
  ///
  /// In en, this message translates to:
  /// **'⚡ YOUR TURN'**
  String get todYourTurnBadge;

  /// No description provided for @todTheirTurn.
  ///
  /// In en, this message translates to:
  /// **'It\'s their turn'**
  String get todTheirTurn;

  /// No description provided for @todWinnerWins.
  ///
  /// In en, this message translates to:
  /// **'{name} wins!'**
  String todWinnerWins(String name);

  /// No description provided for @todYouSkipped.
  ///
  /// In en, this message translates to:
  /// **'You skipped…'**
  String get todYouSkipped;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorPrefix(String error);

  /// No description provided for @nhieAddCommentOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a comment (optional)…'**
  String get nhieAddCommentOptional;

  /// No description provided for @nhieAnsweredCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/{total} answered'**
  String nhieAnsweredCount(int count, int total);

  /// No description provided for @nhieCardPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Never have I ever…'**
  String get nhieCardPromptHint;

  /// No description provided for @nhieCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Never Have I Ever…'**
  String get nhieCardTitle;

  /// No description provided for @nhieDrinksScore.
  ///
  /// In en, this message translates to:
  /// **'{count} 🍹'**
  String nhieDrinksScore(int count);

  /// No description provided for @nhieDrinksTotal.
  ///
  /// In en, this message translates to:
  /// **'🍹 {count}'**
  String nhieDrinksTotal(int count);

  /// No description provided for @nhieGameHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Game History'**
  String get nhieGameHistoryTitle;

  /// No description provided for @nhieGoToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get nhieGoToHome;

  /// No description provided for @gameBackToRoom.
  ///
  /// In en, this message translates to:
  /// **'Back to Room'**
  String get gameBackToRoom;

  /// No description provided for @nhieIHave.
  ///
  /// In en, this message translates to:
  /// **'I HAVE'**
  String get nhieIHave;

  /// No description provided for @nhieMostDrinksWins.
  ///
  /// In en, this message translates to:
  /// **'Most 🍹 drinks wins!'**
  String get nhieMostDrinksWins;

  /// No description provided for @nhieNever.
  ///
  /// In en, this message translates to:
  /// **'NEVER'**
  String get nhieNever;

  /// No description provided for @nhieTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up — you didn\'t respond in time'**
  String get nhieTimedOut;

  /// No description provided for @nhieNextCard.
  ///
  /// In en, this message translates to:
  /// **'Next Card →'**
  String get nhieNextCard;

  /// No description provided for @nhiePlayAnotherHandOff.
  ///
  /// In en, this message translates to:
  /// **'Play Another & Hand Off'**
  String get nhiePlayAnotherHandOff;

  /// No description provided for @nhieReadyForNextRound.
  ///
  /// In en, this message translates to:
  /// **'I\'m Ready for Next Round'**
  String get nhieReadyForNextRound;

  /// No description provided for @nhieViewHistoryCount.
  ///
  /// In en, this message translates to:
  /// **'View History ({count} rounds)'**
  String nhieViewHistoryCount(int count);

  /// No description provided for @nhieWaitingCount.
  ///
  /// In en, this message translates to:
  /// **'Waiting… {count}/{total}'**
  String nhieWaitingCount(int count, int total);

  /// No description provided for @nhieWaitingForPlayersReady.
  ///
  /// In en, this message translates to:
  /// **'Waiting for players to be ready…'**
  String get nhieWaitingForPlayersReady;

  /// No description provided for @nhieWhoTakesOver.
  ///
  /// In en, this message translates to:
  /// **'Who takes over?'**
  String get nhieWhoTakesOver;

  /// No description provided for @memeAddCaptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a caption (optional)…'**
  String get memeAddCaptionOptional;

  /// No description provided for @memeCustomPromptSessionOnly.
  ///
  /// In en, this message translates to:
  /// **'This prompt will be added to the deck for this session only.'**
  String get memeCustomPromptSessionOnly;

  /// No description provided for @memeFunniestPlayerWins.
  ///
  /// In en, this message translates to:
  /// **'Funniest player wins!'**
  String get memeFunniestPlayerWins;

  /// No description provided for @memeNextRound.
  ///
  /// In en, this message translates to:
  /// **'Next Round →'**
  String get memeNextRound;

  /// No description provided for @memePassVote.
  ///
  /// In en, this message translates to:
  /// **'Skip — Ready for Next Round'**
  String get memePassVote;

  /// No description provided for @memePickSticker.
  ///
  /// In en, this message translates to:
  /// **'Pick your sticker:'**
  String get memePickSticker;

  /// No description provided for @memePlayersVoted.
  ///
  /// In en, this message translates to:
  /// **'{count}/{total} players voted'**
  String memePlayersVoted(int count, int total);

  /// No description provided for @memeResponseNumber.
  ///
  /// In en, this message translates to:
  /// **'Response #{n}'**
  String memeResponseNumber(int n);

  /// No description provided for @memeResponseSubmittedWaiting.
  ///
  /// In en, this message translates to:
  /// **'Response submitted! Waiting for others…'**
  String get memeResponseSubmittedWaiting;

  /// No description provided for @memeRoundBadgeAllCaps.
  ///
  /// In en, this message translates to:
  /// **'ROUND {round}'**
  String memeRoundBadgeAllCaps(int round);

  /// No description provided for @memeRoundResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Round {round} Results 🏆'**
  String memeRoundResultsTitle(int round);

  /// No description provided for @memeSpectatingWaitingSubmit.
  ///
  /// In en, this message translates to:
  /// **'Spectating — waiting for players to submit…'**
  String get memeSpectatingWaitingSubmit;

  /// No description provided for @memeSubmittedCount.
  ///
  /// In en, this message translates to:
  /// **'{submitted} / {total} submitted'**
  String memeSubmittedCount(int submitted, int total);

  /// No description provided for @memeTapAnywhereToClose.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere to close'**
  String get memeTapAnywhereToClose;

  /// No description provided for @memeTapToExpand.
  ///
  /// In en, this message translates to:
  /// **'Tap to expand'**
  String get memeTapToExpand;

  /// No description provided for @memeTapToSeeReaction.
  ///
  /// In en, this message translates to:
  /// **'Tap to see their reaction'**
  String get memeTapToSeeReaction;

  /// No description provided for @memeTie.
  ///
  /// In en, this message translates to:
  /// **'Tie'**
  String get memeTie;

  /// No description provided for @memeTrophyScore.
  ///
  /// In en, this message translates to:
  /// **'{count} 🏆'**
  String memeTrophyScore(int count);

  /// No description provided for @memeVoteForBest.
  ///
  /// In en, this message translates to:
  /// **'Vote for the best! 😂'**
  String get memeVoteForBest;

  /// No description provided for @memeVoteForThis.
  ///
  /// In en, this message translates to:
  /// **'Vote for this 👍'**
  String get memeVoteForThis;

  /// No description provided for @memeVotedWaiting.
  ///
  /// In en, this message translates to:
  /// **'Voted! Waiting for others…'**
  String get memeVotedWaiting;

  /// No description provided for @memeVotesAbbrev.
  ///
  /// In en, this message translates to:
  /// **'{count} 👍'**
  String memeVotesAbbrev(int count);

  /// No description provided for @memeVotesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} / {total} voted'**
  String memeVotesCount(int count, int total);

  /// No description provided for @memeWinnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Winner: {name}'**
  String memeWinnerLabel(String name);

  /// No description provided for @memeWinsThisRound.
  ///
  /// In en, this message translates to:
  /// **'wins this round!'**
  String get memeWinsThisRound;

  /// No description provided for @memeWritePromptHint.
  ///
  /// In en, this message translates to:
  /// **'Write your meme prompt…'**
  String get memeWritePromptHint;

  /// No description provided for @memeYourResponse.
  ///
  /// In en, this message translates to:
  /// **'Your response'**
  String get memeYourResponse;

  /// No description provided for @memeYourVote.
  ///
  /// In en, this message translates to:
  /// **'✓ Your vote'**
  String get memeYourVote;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @offlineAcceptChallenge.
  ///
  /// In en, this message translates to:
  /// **'Accept the challenge'**
  String get offlineAcceptChallenge;

  /// No description provided for @offlineAddCaptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a caption (optional)…'**
  String get offlineAddCaptionOptional;

  /// No description provided for @offlineAddProofPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add proof photo (view once)'**
  String get offlineAddProofPhoto;

  /// No description provided for @offlineAnswerHonestly.
  ///
  /// In en, this message translates to:
  /// **'Answer honestly'**
  String get offlineAnswerHonestly;

  /// No description provided for @offlineBackToMenu.
  ///
  /// In en, this message translates to:
  /// **'Back to Menu'**
  String get offlineBackToMenu;

  /// No description provided for @offlineChooseYourFate.
  ///
  /// In en, this message translates to:
  /// **'Choose your fate'**
  String get offlineChooseYourFate;

  /// No description provided for @offlineCompleteTurnCheck.
  ///
  /// In en, this message translates to:
  /// **'Complete Turn ✅'**
  String get offlineCompleteTurnCheck;

  /// No description provided for @offlineCompletedName.
  ///
  /// In en, this message translates to:
  /// **'{name} completed!'**
  String offlineCompletedName(String name);

  /// No description provided for @offlineCouldNotPickImage.
  ///
  /// In en, this message translates to:
  /// **'Could not pick image: {error}'**
  String offlineCouldNotPickImage(String error);

  /// No description provided for @offlineDareLabel.
  ///
  /// In en, this message translates to:
  /// **'DARE'**
  String get offlineDareLabel;

  /// No description provided for @offlineDoneCheck.
  ///
  /// In en, this message translates to:
  /// **'✓ Done'**
  String get offlineDoneCheck;

  /// No description provided for @offlineFinalScores.
  ///
  /// In en, this message translates to:
  /// **'Final Scores'**
  String get offlineFinalScores;

  /// No description provided for @offlineGameHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'📖 Game History'**
  String get offlineGameHistoryTitle;

  /// No description provided for @offlineGameOverTrophy.
  ///
  /// In en, this message translates to:
  /// **'Game Over 🏆'**
  String get offlineGameOverTrophy;

  /// No description provided for @offlineGameTypeAndPack.
  ///
  /// In en, this message translates to:
  /// **'{gameType} • {packName}'**
  String offlineGameTypeAndPack(String gameType, String packName);

  /// No description provided for @offlineGoodOneVotes.
  ///
  /// In en, this message translates to:
  /// **'👍 Good one! ({count})'**
  String offlineGoodOneVotes(int count);

  /// No description provided for @offlineHistoryTab.
  ///
  /// In en, this message translates to:
  /// **'📖 History'**
  String get offlineHistoryTab;

  /// No description provided for @offlineIsDeciding.
  ///
  /// In en, this message translates to:
  /// **'{name} is deciding…'**
  String offlineIsDeciding(String name);

  /// No description provided for @offlineKickConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'They will be removed from the lobby.'**
  String get offlineKickConfirmBody;

  /// No description provided for @offlineKickConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Kick {name}?'**
  String offlineKickConfirmTitle(String name);

  /// No description provided for @offlineMemeBadge.
  ///
  /// In en, this message translates to:
  /// **'😂  MEME'**
  String get offlineMemeBadge;

  /// No description provided for @offlineMemeChampion.
  ///
  /// In en, this message translates to:
  /// **'Meme Champion!'**
  String get offlineMemeChampion;

  /// No description provided for @offlineMyVoteCount.
  ///
  /// In en, this message translates to:
  /// **'{voteLabel} ({count}/{total})'**
  String offlineMyVoteCount(String voteLabel, int count, int total);

  /// No description provided for @offlineNeverHaveIEverBadge.
  ///
  /// In en, this message translates to:
  /// **'NEVER HAVE I EVER…'**
  String get offlineNeverHaveIEverBadge;

  /// No description provided for @offlineNextTurnShort.
  ///
  /// In en, this message translates to:
  /// **'Next Turn'**
  String get offlineNextTurnShort;

  /// No description provided for @offlineNoHistoryAvailable.
  ///
  /// In en, this message translates to:
  /// **'No history available'**
  String get offlineNoHistoryAvailable;

  /// No description provided for @offlineNoRoundsCompleted.
  ///
  /// In en, this message translates to:
  /// **'No rounds completed yet'**
  String get offlineNoRoundsCompleted;

  /// No description provided for @offlineNoTurnsCompleted.
  ///
  /// In en, this message translates to:
  /// **'No turns completed yet'**
  String get offlineNoTurnsCompleted;

  /// No description provided for @offlinePackCover.
  ///
  /// In en, this message translates to:
  /// **'Pack cover'**
  String get offlinePackCover;

  /// No description provided for @offlinePickFavourite.
  ///
  /// In en, this message translates to:
  /// **'Pick your favourite:'**
  String get offlinePickFavourite;

  /// No description provided for @offlinePickReaction.
  ///
  /// In en, this message translates to:
  /// **'Pick a reaction:'**
  String get offlinePickReaction;

  /// No description provided for @offlinePickReactionColon.
  ///
  /// In en, this message translates to:
  /// **'Pick your reaction:'**
  String get offlinePickReactionColon;

  /// No description provided for @offlinePlayersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} players'**
  String offlinePlayersCount(int count);

  /// No description provided for @offlinePlayersInLobby.
  ///
  /// In en, this message translates to:
  /// **'PLAYERS IN LOBBY'**
  String get offlinePlayersInLobby;

  /// No description provided for @offlinePreviousCards.
  ///
  /// In en, this message translates to:
  /// **'Previous Cards'**
  String get offlinePreviousCards;

  /// No description provided for @offlineProofViewed.
  ///
  /// In en, this message translates to:
  /// **'📷 Proof viewed'**
  String get offlineProofViewed;

  /// No description provided for @offlineRoundColonCaption.
  ///
  /// In en, this message translates to:
  /// **'Round {round}: {caption}'**
  String offlineRoundColonCaption(int round, String caption);

  /// No description provided for @offlineRoundOf.
  ///
  /// In en, this message translates to:
  /// **'Round {round} of {maxRounds}'**
  String offlineRoundOf(int round, int maxRounds);

  /// No description provided for @offlineSayHiToGroup.
  ///
  /// In en, this message translates to:
  /// **'Say hi to the group!'**
  String get offlineSayHiToGroup;

  /// No description provided for @offlineScoresTab.
  ///
  /// In en, this message translates to:
  /// **'🏆 Scores'**
  String get offlineScoresTab;

  /// No description provided for @offlineSkippedCross.
  ///
  /// In en, this message translates to:
  /// **'✗ Skipped'**
  String get offlineSkippedCross;

  /// No description provided for @offlineSubmissionTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s submission'**
  String offlineSubmissionTitle(String name);

  /// No description provided for @offlineSubmitCount.
  ///
  /// In en, this message translates to:
  /// **'Submit ({count}/{total})'**
  String offlineSubmitCount(int count, int total);

  /// No description provided for @offlineSubmitExclaim.
  ///
  /// In en, this message translates to:
  /// **'Submit!'**
  String get offlineSubmitExclaim;

  /// No description provided for @offlineSubmittedWaitingCheck.
  ///
  /// In en, this message translates to:
  /// **'✅ Submitted! Waiting for others…'**
  String get offlineSubmittedWaitingCheck;

  /// No description provided for @offlineTapAgainToDismiss.
  ///
  /// In en, this message translates to:
  /// **'Tap again to dismiss'**
  String get offlineTapAgainToDismiss;

  /// No description provided for @offlineTapToDismiss.
  ///
  /// In en, this message translates to:
  /// **'Tap to dismiss'**
  String get offlineTapToDismiss;

  /// No description provided for @offlineTapToRevealProof.
  ///
  /// In en, this message translates to:
  /// **'Tap to reveal proof photo'**
  String get offlineTapToRevealProof;

  /// No description provided for @offlineTimerSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String offlineTimerSeconds(int seconds);

  /// No description provided for @offlineTruthLabel.
  ///
  /// In en, this message translates to:
  /// **'TRUTH'**
  String get offlineTruthLabel;

  /// No description provided for @offlineVoteCountBallot.
  ///
  /// In en, this message translates to:
  /// **'{count} 🗳️'**
  String offlineVoteCountBallot(int count);

  /// No description provided for @offlineVoteForBestNoEmoji.
  ///
  /// In en, this message translates to:
  /// **'Vote for the best!'**
  String get offlineVoteForBestNoEmoji;

  /// No description provided for @offlineVotesExclaim.
  ///
  /// In en, this message translates to:
  /// **'{name} votes!'**
  String offlineVotesExclaim(String name);

  /// No description provided for @offlineWaitingForHost.
  ///
  /// In en, this message translates to:
  /// **'Waiting for host…'**
  String get offlineWaitingForHost;

  /// No description provided for @offlineWaitingForHostToStart.
  ///
  /// In en, this message translates to:
  /// **'Waiting for host to start…'**
  String get offlineWaitingForHostToStart;

  /// No description provided for @offlineWaitingForMore.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {count} more…'**
  String offlineWaitingForMore(int count);

  /// No description provided for @offlineWaitingHostAdvance.
  ///
  /// In en, this message translates to:
  /// **'Waiting for host to advance…'**
  String get offlineWaitingHostAdvance;

  /// No description provided for @ptsSuffix.
  ///
  /// In en, this message translates to:
  /// **' pts'**
  String get ptsSuffix;

  /// No description provided for @gameLabel.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get gameLabel;

  /// No description provided for @offlineBulletDownloadedPacks.
  ///
  /// In en, this message translates to:
  /// **'Downloaded packs work fully offline — no internet needed.'**
  String get offlineBulletDownloadedPacks;

  /// No description provided for @offlineBulletLan.
  ///
  /// In en, this message translates to:
  /// **'LAN: each player on their own phone, same WiFi or hotspot.'**
  String get offlineBulletLan;

  /// No description provided for @offlineBulletPassPlay.
  ///
  /// In en, this message translates to:
  /// **'Pass & Play: one phone, pass between players each turn.'**
  String get offlineBulletPassPlay;

  /// No description provided for @offlineChooseMode.
  ///
  /// In en, this message translates to:
  /// **'Choose mode'**
  String get offlineChooseMode;

  /// No description provided for @offlineCreateLanRoomHint.
  ///
  /// In en, this message translates to:
  /// **'Create a LAN room on your device'**
  String get offlineCreateLanRoomHint;

  /// No description provided for @offlineDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get offlineDiscard;

  /// No description provided for @offlineDownloadPackFirst.
  ///
  /// In en, this message translates to:
  /// **'Download a pack first to host'**
  String get offlineDownloadPackFirst;

  /// No description provided for @offlineEnable18Cards.
  ///
  /// In en, this message translates to:
  /// **'Enable 18+ cards'**
  String get offlineEnable18Cards;

  /// No description provided for @offlineEnterNameAboveToJoin.
  ///
  /// In en, this message translates to:
  /// **'Enter your name above to join'**
  String get offlineEnterNameAboveToJoin;

  /// No description provided for @offlineEnterNameToJoin.
  ///
  /// In en, this message translates to:
  /// **'Enter your name to join'**
  String get offlineEnterNameToJoin;

  /// No description provided for @offlineFailedToStart.
  ///
  /// In en, this message translates to:
  /// **'Failed to start'**
  String get offlineFailedToStart;

  /// No description provided for @offlineFindNearbyLanRooms.
  ///
  /// In en, this message translates to:
  /// **'Find nearby LAN rooms to join'**
  String get offlineFindNearbyLanRooms;

  /// No description provided for @offlineGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get offlineGoBack;

  /// No description provided for @offlineHostBadge.
  ///
  /// In en, this message translates to:
  /// **'HOST'**
  String get offlineHostBadge;

  /// No description provided for @offlineHostRoom.
  ///
  /// In en, this message translates to:
  /// **'Host a room'**
  String get offlineHostRoom;

  /// No description provided for @offlineHostsRoom.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Room'**
  String offlineHostsRoom(String name);

  /// No description provided for @offlineHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'ℹ️  How offline works'**
  String get offlineHowItWorks;

  /// No description provided for @offlineJoinLanRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Join LAN Room'**
  String get offlineJoinLanRoomTitle;

  /// No description provided for @offlineJoinRoom.
  ///
  /// In en, this message translates to:
  /// **'Join a room'**
  String get offlineJoinRoom;

  /// No description provided for @offlineJoinRoomButton.
  ///
  /// In en, this message translates to:
  /// **'Join Room'**
  String get offlineJoinRoomButton;

  /// No description provided for @offlineLanMultiplayer.
  ///
  /// In en, this message translates to:
  /// **'LAN Multiplayer'**
  String get offlineLanMultiplayer;

  /// No description provided for @offlineLanRoom.
  ///
  /// In en, this message translates to:
  /// **'LAN Room'**
  String get offlineLanRoom;

  /// No description provided for @offlineLoadingCards.
  ///
  /// In en, this message translates to:
  /// **'Loading cards…'**
  String get offlineLoadingCards;

  /// No description provided for @offlineNearbyRooms.
  ///
  /// In en, this message translates to:
  /// **'Nearby rooms'**
  String get offlineNearbyRooms;

  /// No description provided for @offlineNoPacksDownloaded.
  ///
  /// In en, this message translates to:
  /// **'No {gameType} packs downloaded. Go online to download packs.'**
  String offlineNoPacksDownloaded(String gameType);

  /// No description provided for @offlineOtherPlayersJoinInstructions.
  ///
  /// In en, this message translates to:
  /// **'Other players: open Jma3a → Play → LAN → Join Room'**
  String get offlineOtherPlayersJoinInstructions;

  /// No description provided for @offlinePackExpiry.
  ///
  /// In en, this message translates to:
  /// **'Exp: {day}/{month}'**
  String offlinePackExpiry(int day, int month);

  /// No description provided for @offlinePackMeta.
  ///
  /// In en, this message translates to:
  /// **'{count} cards · {lang} · {status}'**
  String offlinePackMeta(int count, String lang, String status);

  /// No description provided for @offlinePackPlayersCount.
  ///
  /// In en, this message translates to:
  /// **'{packName} · {count} players'**
  String offlinePackPlayersCount(String packName, int count);

  /// No description provided for @offlinePlayTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Play'**
  String get offlinePlayTitle;

  /// No description provided for @offlinePlayersCountDash.
  ///
  /// In en, this message translates to:
  /// **'Players — {count}'**
  String offlinePlayersCountDash(int count);

  /// No description provided for @offlineResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get offlineResume;

  /// No description provided for @offlineResumeGame.
  ///
  /// In en, this message translates to:
  /// **'Resume game'**
  String get offlineResumeGame;

  /// No description provided for @offlineRoomBroadcasting.
  ///
  /// In en, this message translates to:
  /// **'Room is broadcasting'**
  String get offlineRoomBroadcasting;

  /// No description provided for @offlineRoomMeta.
  ///
  /// In en, this message translates to:
  /// **'{gameType} • {packName} • {count}/{max} players'**
  String offlineRoomMeta(String gameType, String packName, int count, int max);

  /// No description provided for @offlineRoundsSlider.
  ///
  /// In en, this message translates to:
  /// **'Rounds: {count}'**
  String offlineRoundsSlider(int count);

  /// No description provided for @offlineSameWifiHint.
  ///
  /// In en, this message translates to:
  /// **'Make sure host device is on the same WiFi.'**
  String get offlineSameWifiHint;

  /// No description provided for @offlineScanningForRooms.
  ///
  /// In en, this message translates to:
  /// **'Scanning for rooms…'**
  String get offlineScanningForRooms;

  /// No description provided for @offlineSetupFailed.
  ///
  /// In en, this message translates to:
  /// **'Setup failed.'**
  String get offlineSetupFailed;

  /// No description provided for @offlineSignInToDownload.
  ///
  /// In en, this message translates to:
  /// **'Sign in to download packs and unlock all games.'**
  String get offlineSignInToDownload;

  /// No description provided for @offlineSpicyContent.
  ///
  /// In en, this message translates to:
  /// **'Spicy content'**
  String get offlineSpicyContent;

  /// No description provided for @offlineTimerSecsLabel.
  ///
  /// In en, this message translates to:
  /// **'Timer: {secs}s'**
  String offlineTimerSecsLabel(int secs);

  /// No description provided for @offlineYourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get offlineYourName;

  /// No description provided for @purchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get purchased;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @accountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @copiedNotice.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get copiedNotice;

  /// No description provided for @labelColonSuffix.
  ///
  /// In en, this message translates to:
  /// **'{label}: '**
  String labelColonSuffix(String label);

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @pendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingLabel;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Phone number must be exactly 8 digits'**
  String get phoneInvalid;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @walletAmountToWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Amount to withdraw'**
  String get walletAmountToWithdraw;

  /// No description provided for @walletAmountValue.
  ///
  /// In en, this message translates to:
  /// **'Amount: {amount} MRU'**
  String walletAmountValue(String amount);

  /// No description provided for @walletAvailableAmount.
  ///
  /// In en, this message translates to:
  /// **'Available: {amount}'**
  String walletAvailableAmount(String amount);

  /// No description provided for @walletAvailableEarnings.
  ///
  /// In en, this message translates to:
  /// **'Available earnings'**
  String get walletAvailableEarnings;

  /// No description provided for @walletAvailableForWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Available for withdrawal'**
  String get walletAvailableForWithdrawal;

  /// No description provided for @walletBackToWallet.
  ///
  /// In en, this message translates to:
  /// **'Back to Wallet'**
  String get walletBackToWallet;

  /// No description provided for @walletBalanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Balance after'**
  String get walletBalanceAfter;

  /// No description provided for @walletBulletCreditedAfterConfirm.
  ///
  /// In en, this message translates to:
  /// **'Earnings are credited after purchase is confirmed.'**
  String get walletBulletCreditedAfterConfirm;

  /// No description provided for @walletBulletEarn85.
  ///
  /// In en, this message translates to:
  /// **'You earn 85% of every pack sale.'**
  String get walletBulletEarn85;

  /// No description provided for @walletBulletMinWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Minimum withdrawal: 500 MRU.'**
  String get walletBulletMinWithdrawal;

  /// No description provided for @walletBulletPlatformFee.
  ///
  /// In en, this message translates to:
  /// **'15% platform fee keeps Jma3a running.'**
  String get walletBulletPlatformFee;

  /// No description provided for @walletChooseHowToAddFunds.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to add funds.'**
  String get walletChooseHowToAddFunds;

  /// No description provided for @walletConfirmWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Confirm Withdrawal'**
  String get walletConfirmWithdrawal;

  /// No description provided for @walletCreateSellPacksHint.
  ///
  /// In en, this message translates to:
  /// **'Create and sell packs to earn commissions.'**
  String get walletCreateSellPacksHint;

  /// No description provided for @walletCreatorEarningsRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Creator earnings rate'**
  String get walletCreatorEarningsRateLabel;

  /// No description provided for @walletCreatorEarningsTitle.
  ///
  /// In en, this message translates to:
  /// **'Creator Earnings'**
  String get walletCreatorEarningsTitle;

  /// No description provided for @walletCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Mauritanian Ouguiya'**
  String get walletCurrencyName;

  /// No description provided for @walletCurrencyShort.
  ///
  /// In en, this message translates to:
  /// **'MRU'**
  String get walletCurrencyShort;

  /// No description provided for @walletAvailableBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get walletAvailableBalanceLabel;

  /// No description provided for @walletFrozenLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet (Frozen)'**
  String get walletFrozenLabel;

  /// No description provided for @walletDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get walletDeposit;

  /// No description provided for @walletDepositAmount.
  ///
  /// In en, this message translates to:
  /// **'Deposit {amount}'**
  String walletDepositAmount(String amount);

  /// No description provided for @walletDepositWarningNotice.
  ///
  /// In en, this message translates to:
  /// **'Only submit after completing the transfer. Deposits are manually reviewed and may take 1–24 hours.'**
  String get walletDepositWarningNotice;

  /// No description provided for @walletEarningsBalance.
  ///
  /// In en, this message translates to:
  /// **'Earnings Balance'**
  String get walletEarningsBalance;

  /// No description provided for @walletEnterReference.
  ///
  /// In en, this message translates to:
  /// **'Enter the reference from your payment'**
  String get walletEnterReference;

  /// No description provided for @walletHowEarningsWork.
  ///
  /// In en, this message translates to:
  /// **'How earnings work'**
  String get walletHowEarningsWork;

  /// No description provided for @walletInsufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance'**
  String get walletInsufficientBalance;

  /// No description provided for @walletMaxDeposit.
  ///
  /// In en, this message translates to:
  /// **'Maximum deposit: 1,000,000 MRU'**
  String get walletMaxDeposit;

  /// No description provided for @walletMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get walletMethodLabel;

  /// No description provided for @walletMinDeposit.
  ///
  /// In en, this message translates to:
  /// **'Minimum deposit: 100 MRU'**
  String get walletMinDeposit;

  /// No description provided for @walletMinWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Minimum withdrawal: {amount} MRU'**
  String walletMinWithdrawal(int amount);

  /// No description provided for @walletNoEarningsYet.
  ///
  /// In en, this message translates to:
  /// **'No earnings yet'**
  String get walletNoEarningsYet;

  /// No description provided for @walletNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get walletNoTransactions;

  /// No description provided for @walletNoTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get walletNoTransactionsYet;

  /// No description provided for @walletOfEveryPackSale.
  ///
  /// In en, this message translates to:
  /// **'of every pack sale ({fee}% platform fee)'**
  String walletOfEveryPackSale(int fee);

  /// No description provided for @walletPaymentReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment reference / transaction ID'**
  String get walletPaymentReferenceLabel;

  /// No description provided for @walletPhoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'8-digit phone number'**
  String get walletPhoneNumberHint;

  /// No description provided for @walletPayoutPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Payout phone number'**
  String get walletPayoutPhoneNumber;

  /// No description provided for @walletPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get walletPhoneLabel;

  /// No description provided for @walletRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get walletRecentTransactions;

  /// No description provided for @walletReferenceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. TXN123456789'**
  String get walletReferenceHint;

  /// No description provided for @walletSelectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select payment method'**
  String get walletSelectPaymentMethod;

  /// No description provided for @walletSelectPayoutMethod.
  ///
  /// In en, this message translates to:
  /// **'Select payout method'**
  String get walletSelectPayoutMethod;

  /// No description provided for @walletStatusPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'{status} • {method}'**
  String walletStatusPaymentMethod(String status, String method);

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get walletTitle;

  /// No description provided for @walletDepositSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit Submitted!'**
  String get walletDepositSubmittedTitle;

  /// No description provided for @walletDepositSubmittedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your deposit of {amount} is under review. Balance will update once approved.'**
  String walletDepositSubmittedSubtitle(String amount);

  /// No description provided for @walletDepositRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Deposit request failed.'**
  String get walletDepositRequestFailed;

  /// No description provided for @walletSubmitDeposit.
  ///
  /// In en, this message translates to:
  /// **'Submit Deposit'**
  String get walletSubmitDeposit;

  /// No description provided for @walletWithdrawalSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal Submitted!'**
  String get walletWithdrawalSubmittedTitle;

  /// No description provided for @walletWithdrawalSubmittedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your withdrawal of {amount} is being processed. Funds will arrive within 1–24 hours.'**
  String walletWithdrawalSubmittedSubtitle(String amount);

  /// No description provided for @walletWithdrawalRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal request failed.'**
  String get walletWithdrawalRequestFailed;

  /// No description provided for @walletContinueArrow.
  ///
  /// In en, this message translates to:
  /// **'Continue →'**
  String get walletContinueArrow;

  /// No description provided for @walletActionDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get walletActionDeposit;

  /// No description provided for @walletActionWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get walletActionWithdraw;

  /// No description provided for @walletActionEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get walletActionEarnings;

  /// No description provided for @walletDetailDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & time'**
  String get walletDetailDateTime;

  /// No description provided for @walletDetailWalletAffected.
  ///
  /// In en, this message translates to:
  /// **'Wallet affected'**
  String get walletDetailWalletAffected;

  /// No description provided for @walletDetailEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get walletDetailEarnings;

  /// No description provided for @walletDetailWalletBalance.
  ///
  /// In en, this message translates to:
  /// **'Wallet Balance'**
  String get walletDetailWalletBalance;

  /// No description provided for @walletDetailBalanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Balance after'**
  String get walletDetailBalanceAfter;

  /// No description provided for @walletDetailPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get walletDetailPaymentMethod;

  /// No description provided for @walletDetailDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get walletDetailDescription;

  /// No description provided for @walletDetailReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get walletDetailReference;

  /// No description provided for @walletDetailTransactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get walletDetailTransactionId;

  /// No description provided for @walletDetailDateAtTime.
  ///
  /// In en, this message translates to:
  /// **'{date} at {time}'**
  String walletDetailDateAtTime(String date, String time);

  /// No description provided for @walletTransferAmount.
  ///
  /// In en, this message translates to:
  /// **'Transfer amount'**
  String get walletTransferAmount;

  /// No description provided for @walletTransferButton.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get walletTransferButton;

  /// No description provided for @walletTransferFailed.
  ///
  /// In en, this message translates to:
  /// **'Transfer failed.'**
  String get walletTransferFailed;

  /// No description provided for @walletTransferSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transferred to wallet balance.'**
  String get walletTransferSuccess;

  /// No description provided for @walletTransferToWallet.
  ///
  /// In en, this message translates to:
  /// **'Transfer to Wallet'**
  String get walletTransferToWallet;

  /// No description provided for @walletTransferToWalletBalance.
  ///
  /// In en, this message translates to:
  /// **'Transfer to Wallet Balance'**
  String get walletTransferToWalletBalance;

  /// No description provided for @walletWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get walletWithdraw;

  /// No description provided for @walletWithdrawalAmount.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal {amount}'**
  String walletWithdrawalAmount(String amount);

  /// No description provided for @walletWithdrawalProcessingNotice.
  ///
  /// In en, this message translates to:
  /// **'Withdrawals are processed manually. Funds arrive in 1–24 hours once approved.'**
  String get walletWithdrawalProcessingNotice;

  /// No description provided for @walletYourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Your phone number'**
  String get walletYourPhoneNumber;

  /// No description provided for @actionLabel.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get actionLabel;

  /// No description provided for @activeLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeLabel;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @getButton.
  ///
  /// In en, this message translates to:
  /// **'Get'**
  String get getButton;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get lightMode;

  /// No description provided for @premiumAppThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get premiumAppThemeTitle;

  /// No description provided for @appThemeNameJma3a.
  ///
  /// In en, this message translates to:
  /// **'Jma3a'**
  String get appThemeNameJma3a;

  /// No description provided for @appThemeNameMidnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get appThemeNameMidnight;

  /// No description provided for @appThemeNameClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get appThemeNameClassic;

  /// No description provided for @appThemeNameCandy.
  ///
  /// In en, this message translates to:
  /// **'Candy'**
  String get appThemeNameCandy;

  /// No description provided for @appThemeNameOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get appThemeNameOcean;

  /// No description provided for @appThemeNameForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get appThemeNameForest;

  /// No description provided for @appThemeNameSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get appThemeNameSunset;

  /// No description provided for @appThemeNameLavender.
  ///
  /// In en, this message translates to:
  /// **'Lavender'**
  String get appThemeNameLavender;

  /// No description provided for @appThemeNameRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get appThemeNameRose;

  /// No description provided for @appThemeNameGalaxy.
  ///
  /// In en, this message translates to:
  /// **'Galaxy'**
  String get appThemeNameGalaxy;

  /// No description provided for @appThemeNameNeon.
  ///
  /// In en, this message translates to:
  /// **'Neon'**
  String get appThemeNameNeon;

  /// No description provided for @appThemeNameGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get appThemeNameGold;

  /// No description provided for @appThemeNameCyber.
  ///
  /// In en, this message translates to:
  /// **'Cyber'**
  String get appThemeNameCyber;

  /// No description provided for @appThemeNameLava.
  ///
  /// In en, this message translates to:
  /// **'Lava'**
  String get appThemeNameLava;

  /// No description provided for @appThemeNameAurora.
  ///
  /// In en, this message translates to:
  /// **'Aurora'**
  String get appThemeNameAurora;

  /// No description provided for @appThemeNameBubblegum.
  ///
  /// In en, this message translates to:
  /// **'Bubblegum'**
  String get appThemeNameBubblegum;

  /// No description provided for @appThemeNameCandyPop.
  ///
  /// In en, this message translates to:
  /// **'Candy Pop'**
  String get appThemeNameCandyPop;

  /// No description provided for @appThemeNameDeepSpace.
  ///
  /// In en, this message translates to:
  /// **'Deep Space'**
  String get appThemeNameDeepSpace;

  /// No description provided for @appThemeNameBlossom.
  ///
  /// In en, this message translates to:
  /// **'Blossom'**
  String get appThemeNameBlossom;

  /// No description provided for @appThemeNameLovestruck.
  ///
  /// In en, this message translates to:
  /// **'Lovestruck'**
  String get appThemeNameLovestruck;

  /// No description provided for @premiumGameCardColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Game Card Color'**
  String get premiumGameCardColorTitle;

  /// No description provided for @premiumGameCardColorHint.
  ///
  /// In en, this message translates to:
  /// **'Applies to the front of your game cards only — the back keeps its own look.'**
  String get premiumGameCardColorHint;

  /// No description provided for @premiumGameCardColorEmoji.
  ///
  /// In en, this message translates to:
  /// **'Game Card Color 🎴'**
  String get premiumGameCardColorEmoji;

  /// No description provided for @premiumChooseGameCardColor.
  ///
  /// In en, this message translates to:
  /// **'Choose a game card color'**
  String get premiumChooseGameCardColor;

  /// No description provided for @gameCardColorClassicPurple.
  ///
  /// In en, this message translates to:
  /// **'Classic Purple'**
  String get gameCardColorClassicPurple;

  /// No description provided for @gameCardColorMidnightBlue.
  ///
  /// In en, this message translates to:
  /// **'Midnight Blue'**
  String get gameCardColorMidnightBlue;

  /// No description provided for @gameCardColorEmberRed.
  ///
  /// In en, this message translates to:
  /// **'Ember Red'**
  String get gameCardColorEmberRed;

  /// No description provided for @gameCardColorForestEmerald.
  ///
  /// In en, this message translates to:
  /// **'Forest Emerald'**
  String get gameCardColorForestEmerald;

  /// No description provided for @gameCardColorSunsetOrange.
  ///
  /// In en, this message translates to:
  /// **'Sunset Orange'**
  String get gameCardColorSunsetOrange;

  /// No description provided for @gameCardColorGoldPrestige.
  ///
  /// In en, this message translates to:
  /// **'Gold Prestige'**
  String get gameCardColorGoldPrestige;

  /// No description provided for @gameCardColorRosePink.
  ///
  /// In en, this message translates to:
  /// **'Rose Pink'**
  String get gameCardColorRosePink;

  /// No description provided for @gameCardColorCyberTeal.
  ///
  /// In en, this message translates to:
  /// **'Cyber Teal'**
  String get gameCardColorCyberTeal;

  /// No description provided for @premiumAutoRenewNotice.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions auto-renew unless cancelled 24h before renewal.'**
  String get premiumAutoRenewNotice;

  /// No description provided for @premiumBackgroundColorEmoji.
  ///
  /// In en, this message translates to:
  /// **'Background Color ✦'**
  String get premiumBackgroundColorEmoji;

  /// No description provided for @premiumBackgroundColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get premiumBackgroundColorTitle;

  /// No description provided for @bgColorWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get bgColorWhite;

  /// No description provided for @bgColorWarmWhite.
  ///
  /// In en, this message translates to:
  /// **'Warm White'**
  String get bgColorWarmWhite;

  /// No description provided for @bgColorLightGrey.
  ///
  /// In en, this message translates to:
  /// **'Light Grey'**
  String get bgColorLightGrey;

  /// No description provided for @bgColorCoolGrey.
  ///
  /// In en, this message translates to:
  /// **'Cool Grey'**
  String get bgColorCoolGrey;

  /// No description provided for @bgColorCharcoal.
  ///
  /// In en, this message translates to:
  /// **'Charcoal'**
  String get bgColorCharcoal;

  /// No description provided for @bgColorSoftBlack.
  ///
  /// In en, this message translates to:
  /// **'Soft Black'**
  String get bgColorSoftBlack;

  /// No description provided for @bgColorCream.
  ///
  /// In en, this message translates to:
  /// **'Cream'**
  String get bgColorCream;

  /// No description provided for @bgColorBeige.
  ///
  /// In en, this message translates to:
  /// **'Beige'**
  String get bgColorBeige;

  /// No description provided for @bgColorSand.
  ///
  /// In en, this message translates to:
  /// **'Sand'**
  String get bgColorSand;

  /// No description provided for @bgColorStone.
  ///
  /// In en, this message translates to:
  /// **'Stone'**
  String get bgColorStone;

  /// No description provided for @bgColorSlate.
  ///
  /// In en, this message translates to:
  /// **'Slate'**
  String get bgColorSlate;

  /// No description provided for @bgColorNavyGrey.
  ///
  /// In en, this message translates to:
  /// **'Navy Grey'**
  String get bgColorNavyGrey;

  /// No description provided for @bgColorDeepBlueGrey.
  ///
  /// In en, this message translates to:
  /// **'Deep Blue Grey'**
  String get bgColorDeepBlueGrey;

  /// No description provided for @bgColorForestMist.
  ///
  /// In en, this message translates to:
  /// **'Forest Mist'**
  String get bgColorForestMist;

  /// No description provided for @bgColorSage.
  ///
  /// In en, this message translates to:
  /// **'Sage'**
  String get bgColorSage;

  /// No description provided for @bgColorPaleBlue.
  ///
  /// In en, this message translates to:
  /// **'Pale Blue'**
  String get bgColorPaleBlue;

  /// No description provided for @bgColorMistBlue.
  ///
  /// In en, this message translates to:
  /// **'Mist Blue'**
  String get bgColorMistBlue;

  /// No description provided for @bgColorLavenderMist.
  ///
  /// In en, this message translates to:
  /// **'Lavender Mist'**
  String get bgColorLavenderMist;

  /// No description provided for @bgColorBlush.
  ///
  /// In en, this message translates to:
  /// **'Blush'**
  String get bgColorBlush;

  /// No description provided for @bgColorSoftMint.
  ///
  /// In en, this message translates to:
  /// **'Soft Mint'**
  String get bgColorSoftMint;

  /// No description provided for @bgColorGraphite.
  ///
  /// In en, this message translates to:
  /// **'Graphite'**
  String get bgColorGraphite;

  /// No description provided for @premiumBlendsIntoTheme.
  ///
  /// In en, this message translates to:
  /// **'Blends into your selected theme — text, cards, and icons adapt automatically.'**
  String get premiumBlendsIntoTheme;

  /// No description provided for @premiumCannotDowngradeBody.
  ///
  /// In en, this message translates to:
  /// **'You have an active Premium Plus subscription. You can switch to a lower plan once it expires on {date}.'**
  String premiumCannotDowngradeBody(String date);

  /// No description provided for @premiumCannotDowngradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot Downgrade Yet'**
  String get premiumCannotDowngradeTitle;

  /// No description provided for @premiumCardTextReadable.
  ///
  /// In en, this message translates to:
  /// **'Card text stays readable'**
  String get premiumCardTextReadable;

  /// No description provided for @premiumChooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose Avatar'**
  String get premiumChooseAvatar;

  /// No description provided for @premiumChooseBackground.
  ///
  /// In en, this message translates to:
  /// **'Choose a background'**
  String get premiumChooseBackground;

  /// No description provided for @premiumConfirmPurchase.
  ///
  /// In en, this message translates to:
  /// **'Confirm Purchase'**
  String get premiumConfirmPurchase;

  /// No description provided for @premiumCurrentTermEnds.
  ///
  /// In en, this message translates to:
  /// **'your current term ends'**
  String get premiumCurrentTermEnds;

  /// No description provided for @premiumFeatureColumnHeader.
  ///
  /// In en, this message translates to:
  /// **'Feature'**
  String get premiumFeatureColumnHeader;

  /// No description provided for @premiumFeatureListDescription.
  ///
  /// In en, this message translates to:
  /// **'Custom themes & avatars, 15 rooms/day, up to 12 players per room, 10 offline packs (1 free), anonymous chat, and more.'**
  String get premiumFeatureListDescription;

  /// No description provided for @premiumLockedUntilExpires.
  ///
  /// In en, this message translates to:
  /// **'Locked until Premium Plus expires'**
  String get premiumLockedUntilExpires;

  /// No description provided for @premiumMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get premiumMonthly;

  /// No description provided for @premiumPageBackground.
  ///
  /// In en, this message translates to:
  /// **'Page background'**
  String get premiumPageBackground;

  /// No description provided for @premiumPlanActivated.
  ///
  /// In en, this message translates to:
  /// **'🎉 {plan} activated!'**
  String premiumPlanActivated(String plan);

  /// No description provided for @premiumPlusLabel.
  ///
  /// In en, this message translates to:
  /// **'Premium Plus'**
  String get premiumPlusLabel;

  /// No description provided for @premiumPlusShort.
  ///
  /// In en, this message translates to:
  /// **'Plus'**
  String get premiumPlusShort;

  /// No description provided for @premiumPremiumAvatars.
  ///
  /// In en, this message translates to:
  /// **'Premium Avatars'**
  String get premiumPremiumAvatars;

  /// No description provided for @premiumPremiumThemes.
  ///
  /// In en, this message translates to:
  /// **'Premium Themes ✦'**
  String get premiumPremiumThemes;

  /// No description provided for @premiumPricePerPeriod.
  ///
  /// In en, this message translates to:
  /// **'{price} / {period}'**
  String premiumPricePerPeriod(String price, String period);

  /// No description provided for @premiumPurchaseConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will deduct {planPrice} from your wallet balance.\n\nPlan: {plan} — {planPrice}/{period}'**
  String premiumPurchaseConfirmBody(
    String plan,
    String planPrice,
    String period,
  );

  /// No description provided for @premiumPurchasePlan.
  ///
  /// In en, this message translates to:
  /// **'Purchase {plan}'**
  String premiumPurchasePlan(String plan);

  /// No description provided for @premiumSave33.
  ///
  /// In en, this message translates to:
  /// **'Save 33%'**
  String get premiumSave33;

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumTitle;

  /// No description provided for @premiumUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Premium'**
  String get premiumUnlockTitle;

  /// No description provided for @premiumUpgradeToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to unlock'**
  String get premiumUpgradeToUnlock;

  /// No description provided for @premiumWhatYouGet.
  ///
  /// In en, this message translates to:
  /// **'What you get'**
  String get premiumWhatYouGet;

  /// No description provided for @premiumYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get premiumYearly;

  /// No description provided for @premiumYourAvatars.
  ///
  /// In en, this message translates to:
  /// **'Your Avatars'**
  String get premiumYourAvatars;

  /// No description provided for @premiumYourThemes.
  ///
  /// In en, this message translates to:
  /// **'Your Themes'**
  String get premiumYourThemes;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to Default'**
  String get resetToDefault;

  /// No description provided for @continueArrow.
  ///
  /// In en, this message translates to:
  /// **'Continue →'**
  String get continueArrow;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @noneLabel.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noneLabel;

  /// No description provided for @packAddFirstCardHint.
  ///
  /// In en, this message translates to:
  /// **'Add your first card above!'**
  String get packAddFirstCardHint;

  /// No description provided for @packAddImages.
  ///
  /// In en, this message translates to:
  /// **'Add Images'**
  String get packAddImages;

  /// No description provided for @packAddMoreMinimum.
  ///
  /// In en, this message translates to:
  /// **'Add {count} more (minimum 10) or remove them all.'**
  String packAddMoreMinimum(int count);

  /// No description provided for @packAdditionalFeeBody.
  ///
  /// In en, this message translates to:
  /// **'This pack has extra cards, which requires an additional fee of {fee} MRU to submit for review.'**
  String packAdditionalFeeBody(int fee);

  /// No description provided for @packAdditionalFeeTitle.
  ///
  /// In en, this message translates to:
  /// **'Additional fee required'**
  String get packAdditionalFeeTitle;

  /// No description provided for @packAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get packAgeLabel;

  /// No description provided for @packAllowedLabel.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get packAllowedLabel;

  /// No description provided for @packAudienceEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get packAudienceEveryone;

  /// No description provided for @packAudienceHint.
  ///
  /// In en, this message translates to:
  /// **'Restrict who this pack is meant for. Not enforced when joining a room yet — saved with the pack for later use.'**
  String get packAudienceHint;

  /// No description provided for @packCardTypePrompt.
  ///
  /// In en, this message translates to:
  /// **'Prompt'**
  String get packCardTypePrompt;

  /// No description provided for @packCardTypeStatement.
  ///
  /// In en, this message translates to:
  /// **'Statement'**
  String get packCardTypeStatement;

  /// No description provided for @packCategoryHintExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Party games'**
  String get packCategoryHintExample;

  /// No description provided for @packCategoryOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Category (optional)'**
  String get packCategoryOptionalLabel;

  /// No description provided for @packCategoryRejectedNoReason.
  ///
  /// In en, this message translates to:
  /// **'Your suggested category \"{name}\" was rejected.'**
  String packCategoryRejectedNoReason(String name);

  /// No description provided for @packCategoryRejectedWithReason.
  ///
  /// In en, this message translates to:
  /// **'Your suggested category \"{name}\" was rejected: {reason}'**
  String packCategoryRejectedWithReason(String name, String reason);

  /// No description provided for @packCategorySubmittedForReview.
  ///
  /// In en, this message translates to:
  /// **'Category submitted for review'**
  String get packCategorySubmittedForReview;

  /// No description provided for @packCoverImageHint.
  ///
  /// In en, this message translates to:
  /// **'This appears on the pack card in the marketplace.'**
  String get packCoverImageHint;

  /// No description provided for @packCoverImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Cover image'**
  String get packCoverImageLabel;

  /// No description provided for @packLivePreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Live game-card preview'**
  String get packLivePreviewLabel;

  /// No description provided for @packLivePreviewHint.
  ///
  /// In en, this message translates to:
  /// **'This is approximately what players will see in the game.'**
  String get packLivePreviewHint;

  /// No description provided for @packCardPreviewSampleText.
  ///
  /// In en, this message translates to:
  /// **'Your card text will appear here'**
  String get packCardPreviewSampleText;

  /// No description provided for @packCardPreviewSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Card preview'**
  String get packCardPreviewSectionLabel;

  /// No description provided for @packCardPreviewCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Card {current} of {total}'**
  String packCardPreviewCountLabel(int current, int total);

  /// No description provided for @packChooseSticker.
  ///
  /// In en, this message translates to:
  /// **'Choose sticker'**
  String get packChooseSticker;

  /// No description provided for @packStickerSelected.
  ///
  /// In en, this message translates to:
  /// **'Sticker selected'**
  String get packStickerSelected;

  /// No description provided for @packRemoveSticker.
  ///
  /// In en, this message translates to:
  /// **'Remove sticker'**
  String get packRemoveSticker;

  /// No description provided for @packNoStickersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No stickers available yet'**
  String get packNoStickersAvailable;

  /// No description provided for @packCardPreviewEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No cards yet'**
  String get packCardPreviewEmptyTitle;

  /// No description provided for @packCardPreviewEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first card below and it will appear here.'**
  String get packCardPreviewEmptyBody;

  /// No description provided for @packCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Pack — {step}'**
  String packCreateTitle(String step);

  /// No description provided for @packDescriptionFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Description ({lang}, optional)'**
  String packDescriptionFieldLabel(String lang);

  /// No description provided for @packDifficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get packDifficultyMedium;

  /// No description provided for @packDifficultyMild.
  ///
  /// In en, this message translates to:
  /// **'Mild'**
  String get packDifficultyMild;

  /// No description provided for @packDifficultySpicy.
  ///
  /// In en, this message translates to:
  /// **'🌶 Spicy'**
  String get packDifficultySpicy;

  /// No description provided for @packEditPunishment.
  ///
  /// In en, this message translates to:
  /// **'Edit punishment'**
  String get packEditPunishment;

  /// No description provided for @packEnableSpicyHint.
  ///
  /// In en, this message translates to:
  /// **'Enable spicy content in pack settings to add spicy cards'**
  String get packEnableSpicyHint;

  /// No description provided for @packFailedSuggestCategory.
  ///
  /// In en, this message translates to:
  /// **'Failed to suggest category: {error}'**
  String packFailedSuggestCategory(String error);

  /// No description provided for @packFailedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String packFailedToSave(String error);

  /// No description provided for @packFailedToSaveCards.
  ///
  /// In en, this message translates to:
  /// **'Failed to save cards: {error}'**
  String packFailedToSaveCards(String error);

  /// No description provided for @packFailedToSaveReactions.
  ///
  /// In en, this message translates to:
  /// **'Failed to save reactions: {error}'**
  String packFailedToSaveReactions(String error);

  /// No description provided for @packFillContentInLanguages.
  ///
  /// In en, this message translates to:
  /// **'Please fill content in: {languages}'**
  String packFillContentInLanguages(String languages);

  /// No description provided for @packFreeLabel.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get packFreeLabel;

  /// No description provided for @packGameTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Game type'**
  String get packGameTypeLabel;

  /// No description provided for @packGameTypeMeme.
  ///
  /// In en, this message translates to:
  /// **'😂 Meme Game'**
  String get packGameTypeMeme;

  /// No description provided for @packGameTypeNhie.
  ///
  /// In en, this message translates to:
  /// **'🍹 Never Have I Ever'**
  String get packGameTypeNhie;

  /// No description provided for @packGameTypeTod.
  ///
  /// In en, this message translates to:
  /// **'🎯 Truth or Dare'**
  String get packGameTypeTod;

  /// No description provided for @packGenderFemaleOnly.
  ///
  /// In en, this message translates to:
  /// **'Female only'**
  String get packGenderFemaleOnly;

  /// No description provided for @packGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get packGenderLabel;

  /// No description provided for @packGenderMaleOnly.
  ///
  /// In en, this message translates to:
  /// **'Male only'**
  String get packGenderMaleOnly;

  /// No description provided for @packImportantRulesBody.
  ///
  /// In en, this message translates to:
  /// **'• Packs cannot be edited after publishing.\n• You must purchase your own pack to use it in games.\n• Moderation review takes 1–3 business days.'**
  String get packImportantRulesBody;

  /// No description provided for @packImportantRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'📋 Important rules:'**
  String get packImportantRulesTitle;

  /// No description provided for @packInformationTitle.
  ///
  /// In en, this message translates to:
  /// **'Pack information'**
  String get packInformationTitle;

  /// No description provided for @packLangArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get packLangArabic;

  /// No description provided for @packLangEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get packLangEnglish;

  /// No description provided for @packLangFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get packLangFrench;

  /// No description provided for @packLangGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get packLangGerman;

  /// No description provided for @packLangPortuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get packLangPortuguese;

  /// No description provided for @packLangRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get packLangRussian;

  /// No description provided for @packLangSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get packLangSpanish;

  /// No description provided for @packLangTurkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get packLangTurkish;

  /// No description provided for @packMaxReactionImagesReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum 30 reaction images reached'**
  String get packMaxReactionImagesReached;

  /// No description provided for @packMinPlayersLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum players: {count}'**
  String packMinPlayersLabel(int count);

  /// No description provided for @packSetMaxPlayersToggle.
  ///
  /// In en, this message translates to:
  /// **'Set a maximum number of players'**
  String get packSetMaxPlayersToggle;

  /// No description provided for @packMaxPlayersLabel.
  ///
  /// In en, this message translates to:
  /// **'Maximum players: {count}'**
  String packMaxPlayersLabel(int count);

  /// No description provided for @packMaxPlayersSliderLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} players'**
  String packMaxPlayersSliderLabel(int count);

  /// No description provided for @packNoMaxPlayersHint.
  ///
  /// In en, this message translates to:
  /// **'No limit — playable with any group above the minimum'**
  String get packNoMaxPlayersHint;

  /// No description provided for @packMinimumReached.
  ///
  /// In en, this message translates to:
  /// **'✅ Minimum reached'**
  String get packMinimumReached;

  /// No description provided for @packMoreNeeded.
  ///
  /// In en, this message translates to:
  /// **'{count} more needed'**
  String packMoreNeeded(int count);

  /// No description provided for @packNameFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Pack name ({lang})*'**
  String packNameFieldLabel(String lang);

  /// No description provided for @packNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Wild Friday Night'**
  String get packNameHint;

  /// No description provided for @packNoReactionImagesYet.
  ///
  /// In en, this message translates to:
  /// **'No reaction images yet'**
  String get packNoReactionImagesYet;

  /// No description provided for @packNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get packNotLoggedIn;

  /// No description provided for @packOneNamePerLanguage.
  ///
  /// In en, this message translates to:
  /// **'One name and description per language you selected.'**
  String get packOneNamePerLanguage;

  /// No description provided for @packPayFeeAndSubmit.
  ///
  /// In en, this message translates to:
  /// **'Pay {fee} MRU & Submit'**
  String packPayFeeAndSubmit(int fee);

  /// No description provided for @packPendingAdminReview.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" is pending admin review'**
  String packPendingAdminReview(String name);

  /// No description provided for @packPickExistingCategory.
  ///
  /// In en, this message translates to:
  /// **'Pick existing category'**
  String get packPickExistingCategory;

  /// No description provided for @roomSettingsCategoryFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get roomSettingsCategoryFilterLabel;

  /// No description provided for @packPlayersSliderLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} players'**
  String packPlayersSliderLabel(int count);

  /// No description provided for @packPriceFreeHint.
  ///
  /// In en, this message translates to:
  /// **'Leave as 0 for a free pack'**
  String get packPriceFreeHint;

  /// No description provided for @packMinPriceError.
  ///
  /// In en, this message translates to:
  /// **'Paid packs must be priced at {min} MRU or more'**
  String packMinPriceError(int min);

  /// No description provided for @packPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get packPriceLabel;

  /// No description provided for @packPriceMru.
  ///
  /// In en, this message translates to:
  /// **'{price} MRU'**
  String packPriceMru(int price);

  /// No description provided for @packPunishmentCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} punishment} other{{count} punishments}}'**
  String packPunishmentCount(int count);

  /// No description provided for @packPunishmentInputHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Do 10 pushups'**
  String get packPunishmentInputHint;

  /// No description provided for @packPunishmentsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Optional — add some, or skip straight to Publish.'**
  String get packPunishmentsEmptyHint;

  /// No description provided for @packPunishmentsHint.
  ///
  /// In en, this message translates to:
  /// **'Shown to a player who skips or refuses a card, if the room owner chooses to use pack punishments instead of live player submissions.'**
  String get packPunishmentsHint;

  /// No description provided for @packPunishmentsOptionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Punishments (optional)'**
  String get packPunishmentsOptionalTitle;

  /// No description provided for @packReactionImageCount.
  ///
  /// In en, this message translates to:
  /// **'{count} / 30 reaction images'**
  String packReactionImageCount(int count);

  /// No description provided for @packReactionSlotsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} slots remaining'**
  String packReactionSlotsRemaining(int count);

  /// No description provided for @packReactionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Players will use these images as reactions during the game. Add up to 30. If none, default stickers are used.'**
  String get packReactionsDescription;

  /// No description provided for @packReactionsOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Optional — skip to use defaults'**
  String get packReactionsOptionalHint;

  /// No description provided for @packReadyToPublish.
  ///
  /// In en, this message translates to:
  /// **'Ready to publish?'**
  String get packReadyToPublish;

  /// No description provided for @packReviewBeforeSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Review your pack before submitting for moderation.'**
  String get packReviewBeforeSubmitting;

  /// No description provided for @packSelectLanguagesHint.
  ///
  /// In en, this message translates to:
  /// **'Choose every language you\'ll write this pack\'s names, descriptions, and cards in.'**
  String get packSelectLanguagesHint;

  /// No description provided for @packSpicyLabel.
  ///
  /// In en, this message translates to:
  /// **'Spicy content'**
  String get packSpicyLabel;

  /// No description provided for @packSpicyContentDisabled.
  ///
  /// In en, this message translates to:
  /// **'Spicy content is not available right now.'**
  String get packSpicyContentDisabled;

  /// No description provided for @packStepAudience.
  ///
  /// In en, this message translates to:
  /// **'Audience'**
  String get packStepAudience;

  /// No description provided for @packStepCards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get packStepCards;

  /// No description provided for @packStepGeneralInfo.
  ///
  /// In en, this message translates to:
  /// **'General Info'**
  String get packStepGeneralInfo;

  /// No description provided for @packStepLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get packStepLanguages;

  /// No description provided for @packStepNamesDescriptions.
  ///
  /// In en, this message translates to:
  /// **'Names & descriptions'**
  String get packStepNamesDescriptions;

  /// No description provided for @packStepPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get packStepPublish;

  /// No description provided for @packStepPunishments.
  ///
  /// In en, this message translates to:
  /// **'Punishments'**
  String get packStepPunishments;

  /// No description provided for @packStepReactions.
  ///
  /// In en, this message translates to:
  /// **'Reactions'**
  String get packStepReactions;

  /// No description provided for @packSubmissionFailed.
  ///
  /// In en, this message translates to:
  /// **'Submission failed: {error}'**
  String packSubmissionFailed(String error);

  /// No description provided for @packSubmitForReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for Review'**
  String get packSubmitForReview;

  /// No description provided for @packEligibilityChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking your submission eligibility…'**
  String get packEligibilityChecking;

  /// No description provided for @packFreeSubmissionAvailable.
  ///
  /// In en, this message translates to:
  /// **'Your free submission is available'**
  String get packFreeSubmissionAvailable;

  /// No description provided for @packFreeSubmissionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Free submission not available yet'**
  String get packFreeSubmissionUnavailable;

  /// No description provided for @packNextFreeSubmissionAt.
  ///
  /// In en, this message translates to:
  /// **'Next free submission: {date}'**
  String packNextFreeSubmissionAt(String date);

  /// No description provided for @packPaidExtraPackHint.
  ///
  /// In en, this message translates to:
  /// **'You can create an extra pack now for {price} MRU.'**
  String packPaidExtraPackHint(int price);

  /// No description provided for @packCreateExtraPackPriced.
  ///
  /// In en, this message translates to:
  /// **'Create Extra Pack — {price} MRU'**
  String packCreateExtraPackPriced(int price);

  /// No description provided for @packCreatorNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Only verified creators can submit packs for review.'**
  String get packCreatorNotVerified;

  /// No description provided for @packAlreadyHasDraft.
  ///
  /// In en, this message translates to:
  /// **'You already have a draft pack. Finish, publish, or delete it before creating another draft.'**
  String get packAlreadyHasDraft;

  /// No description provided for @packDraftLimitReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Draft Limit Reached'**
  String get packDraftLimitReachedTitle;

  /// No description provided for @packDeleteDraft.
  ///
  /// In en, this message translates to:
  /// **'Delete Draft'**
  String get packDeleteDraft;

  /// No description provided for @packDeleteDraftConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this draft?'**
  String get packDeleteDraftConfirmTitle;

  /// No description provided for @packDeleteDraftConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" will be permanently deleted. This can\'t be undone.'**
  String packDeleteDraftConfirmBody(String title);

  /// No description provided for @packDraftDeletedNotice.
  ///
  /// In en, this message translates to:
  /// **'Draft deleted.'**
  String get packDraftDeletedNotice;

  /// No description provided for @packDeleteDraftFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete draft: {error}'**
  String packDeleteDraftFailed(String error);

  /// No description provided for @packSubmittedForReviewNotice.
  ///
  /// In en, this message translates to:
  /// **'Pack submitted for review! You\'ll be notified when approved.'**
  String get packSubmittedForReviewNotice;

  /// No description provided for @packSuggestAgain.
  ///
  /// In en, this message translates to:
  /// **'Suggest again'**
  String get packSuggestAgain;

  /// No description provided for @packSuggestNew.
  ///
  /// In en, this message translates to:
  /// **'Suggest new'**
  String get packSuggestNew;

  /// No description provided for @packSuggestNewCategory.
  ///
  /// In en, this message translates to:
  /// **'Suggest a new category'**
  String get packSuggestNewCategory;

  /// No description provided for @packSummaryCards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get packSummaryCards;

  /// No description provided for @packSummaryCardsValue.
  ///
  /// In en, this message translates to:
  /// **'{count} ({truthCount}T + {dareCount}D)'**
  String packSummaryCardsValue(int count, int truthCount, int dareCount);

  /// No description provided for @packSummaryGameType.
  ///
  /// In en, this message translates to:
  /// **'Game type'**
  String get packSummaryGameType;

  /// No description provided for @packSummaryPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get packSummaryPrice;

  /// No description provided for @packSummarySpicyContent.
  ///
  /// In en, this message translates to:
  /// **'Spicy content'**
  String get packSummarySpicyContent;

  /// No description provided for @packSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get packSummaryTitle;

  /// No description provided for @packTapToAddCover.
  ///
  /// In en, this message translates to:
  /// **'Tap to add cover'**
  String get packTapToAddCover;

  /// No description provided for @packTypeDare.
  ///
  /// In en, this message translates to:
  /// **'Dare 🔥'**
  String get packTypeDare;

  /// No description provided for @packTypePrompt.
  ///
  /// In en, this message translates to:
  /// **'Prompt 😂'**
  String get packTypePrompt;

  /// No description provided for @packTypeStatement.
  ///
  /// In en, this message translates to:
  /// **'Statement 🍹'**
  String get packTypeStatement;

  /// No description provided for @packTypeTruth.
  ///
  /// In en, this message translates to:
  /// **'Truth 🤔'**
  String get packTypeTruth;

  /// No description provided for @packUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String packUploadFailed(String error);

  /// No description provided for @packUploadingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get packUploadingEllipsis;

  /// No description provided for @packWhoCanPlay.
  ///
  /// In en, this message translates to:
  /// **'Who can play with this pack'**
  String get packWhoCanPlay;

  /// No description provided for @packAdditionalDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional details (optional)'**
  String get packAdditionalDetailsOptional;

  /// No description provided for @packAvailableOffline.
  ///
  /// In en, this message translates to:
  /// **'Available offline'**
  String get packAvailableOffline;

  /// No description provided for @packBrowseMarketplaceHint.
  ///
  /// In en, this message translates to:
  /// **'Browse the marketplace to find packs.'**
  String get packBrowseMarketplaceHint;

  /// No description provided for @packConfirmPurchaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Purchase'**
  String get packConfirmPurchaseTitle;

  /// No description provided for @packConfirmPurchaseBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re about to purchase \"{name}\" for {price}.'**
  String packConfirmPurchaseBody(String name, String price);

  /// No description provided for @packConfirmPurchaseAction.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get packConfirmPurchaseAction;

  /// No description provided for @packBuyForPrice.
  ///
  /// In en, this message translates to:
  /// **'Buy for {price} MRU'**
  String packBuyForPrice(int price);

  /// No description provided for @packCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get packCancelled;

  /// No description provided for @packCancelledOn.
  ///
  /// In en, this message translates to:
  /// **'Cancelled on {date}'**
  String packCancelledOn(String date);

  /// No description provided for @packCardCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} card} other{{count} cards}}'**
  String packCardCount(int count);

  /// No description provided for @packCardsAndSales.
  ///
  /// In en, this message translates to:
  /// **'{cards} cards • {sales} sales'**
  String packCardsAndSales(int cards, int sales);

  /// No description provided for @packCardsAvailableOffline.
  ///
  /// In en, this message translates to:
  /// **'{count} cards • Available offline'**
  String packCardsAvailableOffline(int count);

  /// No description provided for @packCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get packCity;

  /// No description provided for @packCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} packs'**
  String packCountLabel(int count);

  /// No description provided for @packCreateFirstHint.
  ///
  /// In en, this message translates to:
  /// **'Create your first pack and share it with the world.'**
  String get packCreateFirstHint;

  /// No description provided for @packCreatePack.
  ///
  /// In en, this message translates to:
  /// **'Create Pack'**
  String get packCreatePack;

  /// No description provided for @packCreator.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get packCreator;

  /// No description provided for @packCreatorLabel.
  ///
  /// In en, this message translates to:
  /// **'Pack creator'**
  String get packCreatorLabel;

  /// No description provided for @packCreatorStudio.
  ///
  /// In en, this message translates to:
  /// **'Creator Studio'**
  String get packCreatorStudio;

  /// No description provided for @packDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get packDownload;

  /// No description provided for @packDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get packDownloadFailed;

  /// No description provided for @packDownloadToPlayOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Download packs to play without internet.'**
  String get packDownloadToPlayOfflineHint;

  /// No description provided for @packDownloadingPercent.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String packDownloadingPercent(int percent);

  /// No description provided for @packExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get packExpired;

  /// No description provided for @packExpiresInDays.
  ///
  /// In en, this message translates to:
  /// **'Expires in {days} days'**
  String packExpiresInDays(int days);

  /// No description provided for @packExpiresInDaysShort.
  ///
  /// In en, this message translates to:
  /// **'Expires in {days}d'**
  String packExpiresInDaysShort(int days);

  /// No description provided for @packFailedToLoadYourPacks.
  ///
  /// In en, this message translates to:
  /// **'Failed to load your packs.'**
  String get packFailedToLoadYourPacks;

  /// No description provided for @packFailedToRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to request: {error}'**
  String packFailedToRequest(String error);

  /// No description provided for @packFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Pack'**
  String get packFallbackTitle;

  /// No description provided for @packFeaturedHeading.
  ///
  /// In en, this message translates to:
  /// **'⭐ Featured'**
  String get packFeaturedHeading;

  /// No description provided for @packFreeOfflineLimitNotice.
  ///
  /// In en, this message translates to:
  /// **'Free plan allows 1 offline pack. Upgrade to Premium for 10.'**
  String get packFreeOfflineLimitNotice;

  /// No description provided for @packFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get packFullName;

  /// No description provided for @packGetFreePack.
  ///
  /// In en, this message translates to:
  /// **'Get Free Pack'**
  String get packGetFreePack;

  /// No description provided for @packInsufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Balance'**
  String get packInsufficientBalance;

  /// No description provided for @packInsufficientBalanceBody.
  ///
  /// In en, this message translates to:
  /// **'You need {price} MRU to purchase this pack. Your current balance is too low.'**
  String packInsufficientBalanceBody(int price);

  /// No description provided for @packLoadingPrice.
  ///
  /// In en, this message translates to:
  /// **'Loading price…'**
  String get packLoadingPrice;

  /// No description provided for @packMinReviewLength.
  ///
  /// In en, this message translates to:
  /// **'Please write at least 10 characters.'**
  String get packMinReviewLength;

  /// No description provided for @packMyPhysicalRequests.
  ///
  /// In en, this message translates to:
  /// **'My Physical Pack Requests'**
  String get packMyPhysicalRequests;

  /// No description provided for @packNewPack.
  ///
  /// In en, this message translates to:
  /// **'New Pack'**
  String get packNewPack;

  /// No description provided for @packNoFeaturedPacksYet.
  ///
  /// In en, this message translates to:
  /// **'No featured packs yet'**
  String get packNoFeaturedPacksYet;

  /// No description provided for @packNoOfflinePacks.
  ///
  /// In en, this message translates to:
  /// **'No offline packs'**
  String get packNoOfflinePacks;

  /// No description provided for @packNoPacksFound.
  ///
  /// In en, this message translates to:
  /// **'No packs found'**
  String get packNoPacksFound;

  /// No description provided for @packNoPacksYet.
  ///
  /// In en, this message translates to:
  /// **'No packs yet'**
  String get packNoPacksYet;

  /// No description provided for @packSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by pack name, creator, or category…'**
  String get packSearchHint;

  /// No description provided for @packSearchForPacks.
  ///
  /// In en, this message translates to:
  /// **'Search for packs'**
  String get packSearchForPacks;

  /// No description provided for @packSearchMinChars.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 2 characters.'**
  String get packSearchMinChars;

  /// No description provided for @packSearchNoResultsHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different name or category.'**
  String get packSearchNoResultsHint;

  /// No description provided for @packNoPurchasedPacks.
  ///
  /// In en, this message translates to:
  /// **'No purchased packs'**
  String get packNoPurchasedPacks;

  /// No description provided for @packNoRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No requests yet.'**
  String get packNoRequestsYet;

  /// No description provided for @packNoReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet. Be the first!'**
  String get packNoReviewsYet;

  /// No description provided for @packNotFound.
  ///
  /// In en, this message translates to:
  /// **'Pack not found.'**
  String get packNotFound;

  /// No description provided for @packNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get packNotesOptional;

  /// No description provided for @packOfflineLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Offline limit reached ({limit} packs). Delete a pack to download another.'**
  String packOfflineLimitReached(int limit);

  /// No description provided for @packOfflineLimitReachedDelete.
  ///
  /// In en, this message translates to:
  /// **'Offline limit reached ({limit} packs). Delete one to download another.'**
  String packOfflineLimitReachedDelete(int limit);

  /// No description provided for @packOwnedBadge.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get packOwnedBadge;

  /// No description provided for @packPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get packPhoneNumber;

  /// No description provided for @packPhysicalCopyRequested.
  ///
  /// In en, this message translates to:
  /// **'Physical copy requested!'**
  String get packPhysicalCopyRequested;

  /// No description provided for @packPhysicalFeeNotice.
  ///
  /// In en, this message translates to:
  /// **'Fee: {total} MRU ({price} × {quantity}), charged to your wallet balance.'**
  String packPhysicalFeeNotice(int total, int price, int quantity);

  /// No description provided for @packPlayer.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get packPlayer;

  /// No description provided for @packProBadge.
  ///
  /// In en, this message translates to:
  /// **'★ PRO'**
  String get packProBadge;

  /// No description provided for @packOfficialBadge.
  ///
  /// In en, this message translates to:
  /// **'Jma3a'**
  String get packOfficialBadge;

  /// No description provided for @packProcessingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get packProcessingEllipsis;

  /// No description provided for @packPromotedBadge.
  ///
  /// In en, this message translates to:
  /// **'PROMOTED'**
  String get packPromotedBadge;

  /// No description provided for @packPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed: {error}'**
  String packPurchaseFailed(String error);

  /// No description provided for @packPurchasedNotice.
  ///
  /// In en, this message translates to:
  /// **'Pack purchased! You can now download it.'**
  String get packPurchasedNotice;

  /// No description provided for @packQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get packQuantity;

  /// No description provided for @packRedownload.
  ///
  /// In en, this message translates to:
  /// **'Re-download'**
  String get packRedownload;

  /// No description provided for @packRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason: {reason}'**
  String packRejectionReason(String reason);

  /// No description provided for @packRemoveDownload.
  ///
  /// In en, this message translates to:
  /// **'Remove download'**
  String get packRemoveDownload;

  /// No description provided for @packRemoveDownloadBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove the offline copy of \"{title}\". You can re-download it later.'**
  String packRemoveDownloadBody(String title);

  /// No description provided for @packRemoveDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove download?'**
  String get packRemoveDownloadTitle;

  /// No description provided for @packReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get packReport;

  /// No description provided for @packReportHint.
  ///
  /// In en, this message translates to:
  /// **'Help us keep the marketplace safe.'**
  String get packReportHint;

  /// No description provided for @packReportPack.
  ///
  /// In en, this message translates to:
  /// **'Report pack'**
  String get packReportPack;

  /// No description provided for @packReportReasonCheating.
  ///
  /// In en, this message translates to:
  /// **'Cheating or gaming the system'**
  String get packReportReasonCheating;

  /// No description provided for @packReportReasonHateSpeech.
  ///
  /// In en, this message translates to:
  /// **'Hate speech'**
  String get packReportReasonHateSpeech;

  /// No description provided for @packReportReasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get packReportReasonInappropriate;

  /// No description provided for @packReportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get packReportReasonOther;

  /// No description provided for @packReportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get packReportReasonSpam;

  /// No description provided for @packReportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted.'**
  String get packReportSubmitted;

  /// No description provided for @packReportAlreadySubmitted.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already reported this pack.'**
  String get packReportAlreadySubmitted;

  /// No description provided for @packReportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t submit your report. Please try again.'**
  String get packReportFailed;

  /// No description provided for @packPromoteYourPack.
  ///
  /// In en, this message translates to:
  /// **'Promote your pack'**
  String get packPromoteYourPack;

  /// No description provided for @packPromotionDuration24h.
  ///
  /// In en, this message translates to:
  /// **'24 Hours'**
  String get packPromotionDuration24h;

  /// No description provided for @packPromotionDuration7d.
  ///
  /// In en, this message translates to:
  /// **'1 Week'**
  String get packPromotionDuration7d;

  /// No description provided for @packPromotionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Feature this pack in the promoted carousel to reach more players.'**
  String get packPromotionSubtitle;

  /// No description provided for @packPromotionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Promote'**
  String get packPromotionSubmit;

  /// No description provided for @packPromotionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Pack promoted successfully!'**
  String get packPromotionSuccess;

  /// No description provided for @packPromotionActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Promotion active'**
  String get packPromotionActiveLabel;

  /// No description provided for @packPromotionEndsAt.
  ///
  /// In en, this message translates to:
  /// **'Ends {date}'**
  String packPromotionEndsAt(String date);

  /// No description provided for @packPromotionAlreadyActive.
  ///
  /// In en, this message translates to:
  /// **'This pack already has an active promotion.'**
  String get packPromotionAlreadyActive;

  /// No description provided for @packRequestPhysicalCopy.
  ///
  /// In en, this message translates to:
  /// **'Request Physical Copy'**
  String get packRequestPhysicalCopy;

  /// No description provided for @packRetryDownload.
  ///
  /// In en, this message translates to:
  /// **'Retry download'**
  String get packRetryDownload;

  /// No description provided for @packReviewSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Review submitted!'**
  String get packReviewSubmitted;

  /// No description provided for @packReviewSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t submit your review. Please try again.'**
  String get packReviewSubmitFailed;

  /// No description provided for @packReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get packReviews;

  /// No description provided for @packShareThoughtsHint.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts about this pack…'**
  String get packShareThoughtsHint;

  /// No description provided for @packStageCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get packStageCompleted;

  /// No description provided for @packStageDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get packStageDelivered;

  /// No description provided for @packStageOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery'**
  String get packStageOutForDelivery;

  /// No description provided for @packStagePackaging.
  ///
  /// In en, this message translates to:
  /// **'Packaging'**
  String get packStagePackaging;

  /// No description provided for @packStagePaymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Payment Confirmed'**
  String get packStagePaymentConfirmed;

  /// No description provided for @packStagePrinting.
  ///
  /// In en, this message translates to:
  /// **'Printing'**
  String get packStagePrinting;

  /// No description provided for @packStageRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Request Submitted'**
  String get packStageRequestSubmitted;

  /// No description provided for @packStageUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get packStageUnderReview;

  /// No description provided for @packStatAvgRating.
  ///
  /// In en, this message translates to:
  /// **'Avg Rating'**
  String get packStatAvgRating;

  /// No description provided for @packStatPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get packStatPublished;

  /// No description provided for @packStatSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get packStatSales;

  /// No description provided for @packStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get packStatusArchived;

  /// No description provided for @packStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get packStatusDraft;

  /// No description provided for @packStatusInReview.
  ///
  /// In en, this message translates to:
  /// **'In Review'**
  String get packStatusInReview;

  /// No description provided for @packStatusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get packStatusPublished;

  /// No description provided for @packStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get packStatusRejected;

  /// No description provided for @packStatusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get packStatusSuspended;

  /// No description provided for @packPlatformManaged.
  ///
  /// In en, this message translates to:
  /// **'Managed by Jma3a'**
  String get packPlatformManaged;

  /// No description provided for @packSubmitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get packSubmitReport;

  /// No description provided for @packSubmitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get packSubmitRequest;

  /// No description provided for @packSubmitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get packSubmitReview;

  /// No description provided for @packTabBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get packTabBrowse;

  /// No description provided for @packTabDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get packTabDownloaded;

  /// No description provided for @packTabFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get packTabFeatured;

  /// No description provided for @packTabMyPacks.
  ///
  /// In en, this message translates to:
  /// **'My Packs'**
  String get packTabMyPacks;

  /// No description provided for @packTabPurchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get packTabPurchased;

  /// No description provided for @packTopUpWallet.
  ///
  /// In en, this message translates to:
  /// **'Top Up Wallet'**
  String get packTopUpWallet;

  /// No description provided for @packWriteReview.
  ///
  /// In en, this message translates to:
  /// **'Write a review'**
  String get packWriteReview;

  /// No description provided for @packWriteReviewShort.
  ///
  /// In en, this message translates to:
  /// **'Write review'**
  String get packWriteReviewShort;

  /// No description provided for @packYouOwnThisPack.
  ///
  /// In en, this message translates to:
  /// **'You own this pack'**
  String get packYouOwnThisPack;

  /// No description provided for @packYouRatedThis.
  ///
  /// In en, this message translates to:
  /// **'You rated this {rating}/5'**
  String packYouRatedThis(int rating);

  /// No description provided for @packRemoveRating.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get packRemoveRating;

  /// No description provided for @packRatingRemoved.
  ///
  /// In en, this message translates to:
  /// **'Your rating has been removed.'**
  String get packRatingRemoved;

  /// No description provided for @packRatingFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your rating. Please try again.'**
  String get packRatingFailed;

  /// No description provided for @packYourPacks.
  ///
  /// In en, this message translates to:
  /// **'Your Packs'**
  String get packYourPacks;

  /// No description provided for @packYourRating.
  ///
  /// In en, this message translates to:
  /// **'Your rating:'**
  String get packYourRating;

  /// No description provided for @packZoneDistrict.
  ///
  /// In en, this message translates to:
  /// **'Zone / District'**
  String get packZoneDistrict;

  /// No description provided for @packZoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Tevragh Zeina'**
  String get packZoneHint;

  /// No description provided for @searchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchLabel;

  /// No description provided for @avatarAlreadyUpdatedNotice.
  ///
  /// In en, this message translates to:
  /// **'You already updated your avatar. Try again in {hours}h {mins}m.'**
  String avatarAlreadyUpdatedNotice(int hours, int mins);

  /// No description provided for @avatarCustomAvatarsHint.
  ///
  /// In en, this message translates to:
  /// **'Create your own Bitmoji-style avatar and show it across the app with Premium.'**
  String get avatarCustomAvatarsHint;

  /// No description provided for @avatarCustomAvatarsTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Avatars'**
  String get avatarCustomAvatarsTitle;

  /// No description provided for @avatarFeelingLucky.
  ///
  /// In en, this message translates to:
  /// **'Feeling lucky?'**
  String get avatarFeelingLucky;

  /// No description provided for @avatarGenerateRandomHint.
  ///
  /// In en, this message translates to:
  /// **'Generate a random avatar instantly.'**
  String get avatarGenerateRandomHint;

  /// No description provided for @avatarOnCooldown.
  ///
  /// In en, this message translates to:
  /// **'On Cooldown'**
  String get avatarOnCooldown;

  /// No description provided for @avatarOptAccessories.
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get avatarOptAccessories;

  /// No description provided for @avatarOptEyebrows.
  ///
  /// In en, this message translates to:
  /// **'Eyebrows'**
  String get avatarOptEyebrows;

  /// No description provided for @avatarOptEyes.
  ///
  /// In en, this message translates to:
  /// **'Eyes'**
  String get avatarOptEyes;

  /// No description provided for @avatarOptFacialHair.
  ///
  /// In en, this message translates to:
  /// **'Facial Hair'**
  String get avatarOptFacialHair;

  /// No description provided for @avatarOptFacialHairColor.
  ///
  /// In en, this message translates to:
  /// **'Facial Hair Color'**
  String get avatarOptFacialHairColor;

  /// No description provided for @avatarOptHairColor.
  ///
  /// In en, this message translates to:
  /// **'Hair Color'**
  String get avatarOptHairColor;

  /// No description provided for @avatarOptHairStyle.
  ///
  /// In en, this message translates to:
  /// **'Hair Style'**
  String get avatarOptHairStyle;

  /// No description provided for @avatarOptMouth.
  ///
  /// In en, this message translates to:
  /// **'Mouth'**
  String get avatarOptMouth;

  /// No description provided for @avatarOptOutfit.
  ///
  /// In en, this message translates to:
  /// **'Outfit'**
  String get avatarOptOutfit;

  /// No description provided for @avatarOptOutfitColor.
  ///
  /// In en, this message translates to:
  /// **'Outfit Color'**
  String get avatarOptOutfitColor;

  /// No description provided for @avatarOptSkinTone.
  ///
  /// In en, this message translates to:
  /// **'Skin Tone'**
  String get avatarOptSkinTone;

  /// No description provided for @avatarRandomizeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Randomize Avatar'**
  String get avatarRandomizeAvatar;

  /// No description provided for @avatarReactionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Your avatar reactions (happy, laugh, cry & more) are available alongside emoji reactions in Truth or Dare and Never Have I Ever.'**
  String get avatarReactionsDescription;

  /// No description provided for @avatarSaveAvatar.
  ///
  /// In en, this message translates to:
  /// **'Save Avatar'**
  String get avatarSaveAvatar;

  /// No description provided for @avatarSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save right now.'**
  String get avatarSaveFailed;

  /// No description provided for @avatarSaved.
  ///
  /// In en, this message translates to:
  /// **'Avatar saved! ✦'**
  String get avatarSaved;

  /// No description provided for @avatarSavingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get avatarSavingEllipsis;

  /// No description provided for @avatarDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete Avatar'**
  String get avatarDeleteAction;

  /// No description provided for @avatarDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your avatar?'**
  String get avatarDeleteDialogTitle;

  /// No description provided for @avatarDeleteDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This removes your custom avatar. You\'ll go back to your uploaded photo or the default look until you create a new one.'**
  String get avatarDeleteDialogMessage;

  /// No description provided for @avatarDeleted.
  ///
  /// In en, this message translates to:
  /// **'Avatar deleted.'**
  String get avatarDeleted;

  /// No description provided for @avatarDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete right now.'**
  String get avatarDeleteFailed;

  /// No description provided for @avatarTabExtras.
  ///
  /// In en, this message translates to:
  /// **'Extras'**
  String get avatarTabExtras;

  /// No description provided for @avatarTabEyes.
  ///
  /// In en, this message translates to:
  /// **'Eyes'**
  String get avatarTabEyes;

  /// No description provided for @avatarTabFace.
  ///
  /// In en, this message translates to:
  /// **'Face'**
  String get avatarTabFace;

  /// No description provided for @avatarTabHair.
  ///
  /// In en, this message translates to:
  /// **'Hair'**
  String get avatarTabHair;

  /// No description provided for @avatarOptTanned.
  ///
  /// In en, this message translates to:
  /// **'Tanned'**
  String get avatarOptTanned;

  /// No description provided for @avatarOptYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get avatarOptYellow;

  /// No description provided for @avatarOptPale.
  ///
  /// In en, this message translates to:
  /// **'Pale'**
  String get avatarOptPale;

  /// No description provided for @avatarOptLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get avatarOptLight;

  /// No description provided for @avatarOptBrown.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get avatarOptBrown;

  /// No description provided for @avatarOptDarkBrown.
  ///
  /// In en, this message translates to:
  /// **'Dark Brown'**
  String get avatarOptDarkBrown;

  /// No description provided for @avatarOptBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get avatarOptBlack;

  /// No description provided for @avatarOptAuburn.
  ///
  /// In en, this message translates to:
  /// **'Auburn'**
  String get avatarOptAuburn;

  /// No description provided for @avatarOptBlonde.
  ///
  /// In en, this message translates to:
  /// **'Blonde'**
  String get avatarOptBlonde;

  /// No description provided for @avatarOptBlondeGolden.
  ///
  /// In en, this message translates to:
  /// **'Golden Blonde'**
  String get avatarOptBlondeGolden;

  /// No description provided for @avatarOptBrownDark.
  ///
  /// In en, this message translates to:
  /// **'Dark Brown'**
  String get avatarOptBrownDark;

  /// No description provided for @avatarOptPastelPink.
  ///
  /// In en, this message translates to:
  /// **'Pastel Pink'**
  String get avatarOptPastelPink;

  /// No description provided for @avatarOptPlatinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get avatarOptPlatinum;

  /// No description provided for @avatarOptRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get avatarOptRed;

  /// No description provided for @avatarOptSilverGray.
  ///
  /// In en, this message translates to:
  /// **'Silver Gray'**
  String get avatarOptSilverGray;

  /// No description provided for @avatarOptNoHair.
  ///
  /// In en, this message translates to:
  /// **'No Hair'**
  String get avatarOptNoHair;

  /// No description provided for @avatarOptEyepatch.
  ///
  /// In en, this message translates to:
  /// **'Eyepatch'**
  String get avatarOptEyepatch;

  /// No description provided for @avatarOptHat.
  ///
  /// In en, this message translates to:
  /// **'Hat'**
  String get avatarOptHat;

  /// No description provided for @avatarOptHijab.
  ///
  /// In en, this message translates to:
  /// **'Hijab'**
  String get avatarOptHijab;

  /// No description provided for @avatarOptTurban.
  ///
  /// In en, this message translates to:
  /// **'Turban'**
  String get avatarOptTurban;

  /// No description provided for @avatarOptWinterHat1.
  ///
  /// In en, this message translates to:
  /// **'Winter Hat 1'**
  String get avatarOptWinterHat1;

  /// No description provided for @avatarOptWinterHat2.
  ///
  /// In en, this message translates to:
  /// **'Winter Hat 2'**
  String get avatarOptWinterHat2;

  /// No description provided for @avatarOptWinterHat3.
  ///
  /// In en, this message translates to:
  /// **'Winter Hat 3'**
  String get avatarOptWinterHat3;

  /// No description provided for @avatarOptWinterHat4.
  ///
  /// In en, this message translates to:
  /// **'Winter Hat 4'**
  String get avatarOptWinterHat4;

  /// No description provided for @avatarOptLongHairBigHair.
  ///
  /// In en, this message translates to:
  /// **'Long Hair — Big Hair'**
  String get avatarOptLongHairBigHair;

  /// No description provided for @avatarOptLongHairBob.
  ///
  /// In en, this message translates to:
  /// **'Long Hair — Bob'**
  String get avatarOptLongHairBob;

  /// No description provided for @avatarOptLongHairBun.
  ///
  /// In en, this message translates to:
  /// **'Long Hair — Bun'**
  String get avatarOptLongHairBun;

  /// No description provided for @avatarOptLongHairCurly.
  ///
  /// In en, this message translates to:
  /// **'Long Hair — Curly'**
  String get avatarOptLongHairCurly;

  /// No description provided for @avatarOptLongHairCurvy.
  ///
  /// In en, this message translates to:
  /// **'Long Hair — Curvy'**
  String get avatarOptLongHairCurvy;

  /// No description provided for @avatarOptLongHairDreads.
  ///
  /// In en, this message translates to:
  /// **'Long Hair — Dreads'**
  String get avatarOptLongHairDreads;

  /// No description provided for @avatarOptLongHairFrida.
  ///
  /// In en, this message translates to:
  /// **'Long Hair — Frida'**
  String get avatarOptLongHairFrida;

  /// No description provided for @avatarOptLongHairFro.
  ///
  /// In en, this message translates to:
  /// **'Long Hair — Fro'**
  String get avatarOptLongHairFro;

  /// No description provided for @avatarOptLongHairFroBand.
  ///
  /// In en, this message translates to:
  /// **'Long Hair — Fro with Band'**
  String get avatarOptLongHairFroBand;

  /// No description provided for @avatarOptLongHairNotTooLong.
  ///
  /// In en, this message translates to:
  /// **'Long Hair — Not Too Long'**
  String get avatarOptLongHairNotTooLong;

  /// No description provided for @avatarOptLongHairShavedSides.
  ///
  /// In en, this message translates to:
  /// **'Long Hair — Shaved Sides'**
  String get avatarOptLongHairShavedSides;

  /// No description provided for @avatarOptLongHairMiaWallace.
  ///
  /// In en, this message translates to:
  /// **'Long Hair — Mia Wallace'**
  String get avatarOptLongHairMiaWallace;

  /// No description provided for @avatarOptLongHairStraight.
  ///
  /// In en, this message translates to:
  /// **'Long Hair — Straight'**
  String get avatarOptLongHairStraight;

  /// No description provided for @avatarOptLongHairStraight2.
  ///
  /// In en, this message translates to:
  /// **'Long Hair — Straight 2'**
  String get avatarOptLongHairStraight2;

  /// No description provided for @avatarOptLongHairStraightStrand.
  ///
  /// In en, this message translates to:
  /// **'Long Hair — Straight Strand'**
  String get avatarOptLongHairStraightStrand;

  /// No description provided for @avatarOptShortHairDreads01.
  ///
  /// In en, this message translates to:
  /// **'Short Hair — Dreads 1'**
  String get avatarOptShortHairDreads01;

  /// No description provided for @avatarOptShortHairDreads02.
  ///
  /// In en, this message translates to:
  /// **'Short Hair — Dreads 2'**
  String get avatarOptShortHairDreads02;

  /// No description provided for @avatarOptShortHairFrizzle.
  ///
  /// In en, this message translates to:
  /// **'Short Hair — Frizzle'**
  String get avatarOptShortHairFrizzle;

  /// No description provided for @avatarOptShortHairShaggyMullet.
  ///
  /// In en, this message translates to:
  /// **'Short Hair — Shaggy Mullet'**
  String get avatarOptShortHairShaggyMullet;

  /// No description provided for @avatarOptShortHairShortCurly.
  ///
  /// In en, this message translates to:
  /// **'Short Hair — Short Curly'**
  String get avatarOptShortHairShortCurly;

  /// No description provided for @avatarOptShortHairShortFlat.
  ///
  /// In en, this message translates to:
  /// **'Short Hair — Short Flat'**
  String get avatarOptShortHairShortFlat;

  /// No description provided for @avatarOptShortHairShortRound.
  ///
  /// In en, this message translates to:
  /// **'Short Hair — Short Round'**
  String get avatarOptShortHairShortRound;

  /// No description provided for @avatarOptShortHairShortWaved.
  ///
  /// In en, this message translates to:
  /// **'Short Hair — Short Waved'**
  String get avatarOptShortHairShortWaved;

  /// No description provided for @avatarOptShortHairSides.
  ///
  /// In en, this message translates to:
  /// **'Short Hair — Sides'**
  String get avatarOptShortHairSides;

  /// No description provided for @avatarOptShortHairTheCaesar.
  ///
  /// In en, this message translates to:
  /// **'Short Hair — Caesar'**
  String get avatarOptShortHairTheCaesar;

  /// No description provided for @avatarOptShortHairTheCaesarSidePart.
  ///
  /// In en, this message translates to:
  /// **'Short Hair — Caesar Side Part'**
  String get avatarOptShortHairTheCaesarSidePart;

  /// No description provided for @avatarOptBlank.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get avatarOptBlank;

  /// No description provided for @avatarOptKurt.
  ///
  /// In en, this message translates to:
  /// **'Kurt Glasses'**
  String get avatarOptKurt;

  /// No description provided for @avatarOptPrescription01.
  ///
  /// In en, this message translates to:
  /// **'Prescription Glasses 1'**
  String get avatarOptPrescription01;

  /// No description provided for @avatarOptPrescription02.
  ///
  /// In en, this message translates to:
  /// **'Prescription Glasses 2'**
  String get avatarOptPrescription02;

  /// No description provided for @avatarOptRound.
  ///
  /// In en, this message translates to:
  /// **'Round Glasses'**
  String get avatarOptRound;

  /// No description provided for @avatarOptSunglasses.
  ///
  /// In en, this message translates to:
  /// **'Sunglasses'**
  String get avatarOptSunglasses;

  /// No description provided for @avatarOptWayfarers.
  ///
  /// In en, this message translates to:
  /// **'Wayfarers'**
  String get avatarOptWayfarers;

  /// No description provided for @avatarOptBeardMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium Beard'**
  String get avatarOptBeardMedium;

  /// No description provided for @avatarOptBeardLight.
  ///
  /// In en, this message translates to:
  /// **'Light Beard'**
  String get avatarOptBeardLight;

  /// No description provided for @avatarOptBeardMagestic.
  ///
  /// In en, this message translates to:
  /// **'Majestic Beard'**
  String get avatarOptBeardMagestic;

  /// No description provided for @avatarOptMoustacheFancy.
  ///
  /// In en, this message translates to:
  /// **'Fancy Moustache'**
  String get avatarOptMoustacheFancy;

  /// No description provided for @avatarOptMoustacheMagnum.
  ///
  /// In en, this message translates to:
  /// **'Magnum Moustache'**
  String get avatarOptMoustacheMagnum;

  /// No description provided for @avatarOptBlazerShirt.
  ///
  /// In en, this message translates to:
  /// **'Blazer & Shirt'**
  String get avatarOptBlazerShirt;

  /// No description provided for @avatarOptBlazerSweater.
  ///
  /// In en, this message translates to:
  /// **'Blazer & Sweater'**
  String get avatarOptBlazerSweater;

  /// No description provided for @avatarOptCollarSweater.
  ///
  /// In en, this message translates to:
  /// **'Collar Sweater'**
  String get avatarOptCollarSweater;

  /// No description provided for @avatarOptGraphicShirt.
  ///
  /// In en, this message translates to:
  /// **'Graphic Shirt'**
  String get avatarOptGraphicShirt;

  /// No description provided for @avatarOptHoodie.
  ///
  /// In en, this message translates to:
  /// **'Hoodie'**
  String get avatarOptHoodie;

  /// No description provided for @avatarOptOverall.
  ///
  /// In en, this message translates to:
  /// **'Overalls'**
  String get avatarOptOverall;

  /// No description provided for @avatarOptShirtCrewNeck.
  ///
  /// In en, this message translates to:
  /// **'Crew Neck Shirt'**
  String get avatarOptShirtCrewNeck;

  /// No description provided for @avatarOptShirtScoopNeck.
  ///
  /// In en, this message translates to:
  /// **'Scoop Neck Shirt'**
  String get avatarOptShirtScoopNeck;

  /// No description provided for @avatarOptShirtVNeck.
  ///
  /// In en, this message translates to:
  /// **'V-Neck Shirt'**
  String get avatarOptShirtVNeck;

  /// No description provided for @avatarOptBlue01.
  ///
  /// In en, this message translates to:
  /// **'Blue 1'**
  String get avatarOptBlue01;

  /// No description provided for @avatarOptBlue02.
  ///
  /// In en, this message translates to:
  /// **'Blue 2'**
  String get avatarOptBlue02;

  /// No description provided for @avatarOptBlue03.
  ///
  /// In en, this message translates to:
  /// **'Blue 3'**
  String get avatarOptBlue03;

  /// No description provided for @avatarOptGray01.
  ///
  /// In en, this message translates to:
  /// **'Gray 1'**
  String get avatarOptGray01;

  /// No description provided for @avatarOptGray02.
  ///
  /// In en, this message translates to:
  /// **'Gray 2'**
  String get avatarOptGray02;

  /// No description provided for @avatarOptHeather.
  ///
  /// In en, this message translates to:
  /// **'Heather'**
  String get avatarOptHeather;

  /// No description provided for @avatarOptPastelBlue.
  ///
  /// In en, this message translates to:
  /// **'Pastel Blue'**
  String get avatarOptPastelBlue;

  /// No description provided for @avatarOptPastelGreen.
  ///
  /// In en, this message translates to:
  /// **'Pastel Green'**
  String get avatarOptPastelGreen;

  /// No description provided for @avatarOptPastelOrange.
  ///
  /// In en, this message translates to:
  /// **'Pastel Orange'**
  String get avatarOptPastelOrange;

  /// No description provided for @avatarOptPastelRed.
  ///
  /// In en, this message translates to:
  /// **'Pastel Red'**
  String get avatarOptPastelRed;

  /// No description provided for @avatarOptPastelYellow.
  ///
  /// In en, this message translates to:
  /// **'Pastel Yellow'**
  String get avatarOptPastelYellow;

  /// No description provided for @avatarOptPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get avatarOptPink;

  /// No description provided for @avatarOptWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get avatarOptWhite;

  /// No description provided for @avatarOptClose.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get avatarOptClose;

  /// No description provided for @avatarOptCry.
  ///
  /// In en, this message translates to:
  /// **'Crying'**
  String get avatarOptCry;

  /// No description provided for @avatarOptDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get avatarOptDefault;

  /// No description provided for @avatarOptDizzy.
  ///
  /// In en, this message translates to:
  /// **'Dizzy'**
  String get avatarOptDizzy;

  /// No description provided for @avatarOptEyeRoll.
  ///
  /// In en, this message translates to:
  /// **'Eye Roll'**
  String get avatarOptEyeRoll;

  /// No description provided for @avatarOptHappy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get avatarOptHappy;

  /// No description provided for @avatarOptHearts.
  ///
  /// In en, this message translates to:
  /// **'Heart Eyes'**
  String get avatarOptHearts;

  /// No description provided for @avatarOptSide.
  ///
  /// In en, this message translates to:
  /// **'Looking Side'**
  String get avatarOptSide;

  /// No description provided for @avatarOptSquint.
  ///
  /// In en, this message translates to:
  /// **'Squinting'**
  String get avatarOptSquint;

  /// No description provided for @avatarOptSurprised.
  ///
  /// In en, this message translates to:
  /// **'Surprised'**
  String get avatarOptSurprised;

  /// No description provided for @avatarOptWink.
  ///
  /// In en, this message translates to:
  /// **'Wink'**
  String get avatarOptWink;

  /// No description provided for @avatarOptWinkWacky.
  ///
  /// In en, this message translates to:
  /// **'Wacky Wink'**
  String get avatarOptWinkWacky;

  /// No description provided for @avatarOptAngry.
  ///
  /// In en, this message translates to:
  /// **'Angry'**
  String get avatarOptAngry;

  /// No description provided for @avatarOptAngryNatural.
  ///
  /// In en, this message translates to:
  /// **'Angry (Natural)'**
  String get avatarOptAngryNatural;

  /// No description provided for @avatarOptDefaultNatural.
  ///
  /// In en, this message translates to:
  /// **'Default (Natural)'**
  String get avatarOptDefaultNatural;

  /// No description provided for @avatarOptFlatNatural.
  ///
  /// In en, this message translates to:
  /// **'Flat (Natural)'**
  String get avatarOptFlatNatural;

  /// No description provided for @avatarOptRaisedExcited.
  ///
  /// In en, this message translates to:
  /// **'Raised Excited'**
  String get avatarOptRaisedExcited;

  /// No description provided for @avatarOptRaisedExcitedNatural.
  ///
  /// In en, this message translates to:
  /// **'Raised Excited (Natural)'**
  String get avatarOptRaisedExcitedNatural;

  /// No description provided for @avatarOptSadConcerned.
  ///
  /// In en, this message translates to:
  /// **'Sad Concerned'**
  String get avatarOptSadConcerned;

  /// No description provided for @avatarOptSadConcernedNatural.
  ///
  /// In en, this message translates to:
  /// **'Sad Concerned (Natural)'**
  String get avatarOptSadConcernedNatural;

  /// No description provided for @avatarOptUnibrowNatural.
  ///
  /// In en, this message translates to:
  /// **'Unibrow (Natural)'**
  String get avatarOptUnibrowNatural;

  /// No description provided for @avatarOptUpDown.
  ///
  /// In en, this message translates to:
  /// **'Up & Down'**
  String get avatarOptUpDown;

  /// No description provided for @avatarOptUpDownNatural.
  ///
  /// In en, this message translates to:
  /// **'Up & Down (Natural)'**
  String get avatarOptUpDownNatural;

  /// No description provided for @avatarOptConcerned.
  ///
  /// In en, this message translates to:
  /// **'Concerned'**
  String get avatarOptConcerned;

  /// No description provided for @avatarOptDisbelief.
  ///
  /// In en, this message translates to:
  /// **'Disbelief'**
  String get avatarOptDisbelief;

  /// No description provided for @avatarOptEating.
  ///
  /// In en, this message translates to:
  /// **'Eating'**
  String get avatarOptEating;

  /// No description provided for @avatarOptGrimace.
  ///
  /// In en, this message translates to:
  /// **'Grimace'**
  String get avatarOptGrimace;

  /// No description provided for @avatarOptSad.
  ///
  /// In en, this message translates to:
  /// **'Sad'**
  String get avatarOptSad;

  /// No description provided for @avatarOptScreamOpen.
  ///
  /// In en, this message translates to:
  /// **'Screaming'**
  String get avatarOptScreamOpen;

  /// No description provided for @avatarOptSerious.
  ///
  /// In en, this message translates to:
  /// **'Serious'**
  String get avatarOptSerious;

  /// No description provided for @avatarOptSmile.
  ///
  /// In en, this message translates to:
  /// **'Smile'**
  String get avatarOptSmile;

  /// No description provided for @avatarOptTongue.
  ///
  /// In en, this message translates to:
  /// **'Tongue Out'**
  String get avatarOptTongue;

  /// No description provided for @avatarOptTwinkle.
  ///
  /// In en, this message translates to:
  /// **'Twinkle'**
  String get avatarOptTwinkle;

  /// No description provided for @avatarOptVomit.
  ///
  /// In en, this message translates to:
  /// **'Vomit'**
  String get avatarOptVomit;

  /// No description provided for @avatarTabMouth.
  ///
  /// In en, this message translates to:
  /// **'Mouth'**
  String get avatarTabMouth;

  /// No description provided for @avatarTabOutfit.
  ///
  /// In en, this message translates to:
  /// **'Outfit'**
  String get avatarTabOutfit;

  /// No description provided for @avatarUpdateCooldownNotice.
  ///
  /// In en, this message translates to:
  /// **'You can update your avatar again in {hours}h {mins}m.'**
  String avatarUpdateCooldownNotice(int hours, int mins);

  /// No description provided for @avatarUpgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium ✦'**
  String get avatarUpgradeToPremium;

  /// No description provided for @profileAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileAbout;

  /// No description provided for @profileAgeOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Age (optional)'**
  String get profileAgeOptionalLabel;

  /// No description provided for @profileBalanceAndTransactions.
  ///
  /// In en, this message translates to:
  /// **'Balance & transactions'**
  String get profileBalanceAndTransactions;

  /// No description provided for @profileBioTooLong.
  ///
  /// In en, this message translates to:
  /// **'Maximum 280 characters'**
  String get profileBioTooLong;

  /// No description provided for @profileChangeUsername.
  ///
  /// In en, this message translates to:
  /// **'Change username'**
  String get profileChangeUsername;

  /// No description provided for @profileChooseColourTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose your colour theme'**
  String get profileChooseColourTheme;

  /// No description provided for @profileChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get profileChooseFromGallery;

  /// No description provided for @profileCooldownActive.
  ///
  /// In en, this message translates to:
  /// **'Cooldown active'**
  String get profileCooldownActive;

  /// No description provided for @profileCooldownBody.
  ///
  /// In en, this message translates to:
  /// **'You can change your username again in {days, plural, one{{days} day} other{{days} days}}.\n\nUsernames can only be changed once every 30 days.'**
  String profileCooldownBody(int days);

  /// No description provided for @profileCountryAlgeria.
  ///
  /// In en, this message translates to:
  /// **'Algeria'**
  String get profileCountryAlgeria;

  /// No description provided for @profileCountryEgypt.
  ///
  /// In en, this message translates to:
  /// **'Egypt'**
  String get profileCountryEgypt;

  /// No description provided for @profileCountryFrance.
  ///
  /// In en, this message translates to:
  /// **'France'**
  String get profileCountryFrance;

  /// No description provided for @profileCountryGermany.
  ///
  /// In en, this message translates to:
  /// **'Germany'**
  String get profileCountryGermany;

  /// No description provided for @profileCountryMauritania.
  ///
  /// In en, this message translates to:
  /// **'Mauritania'**
  String get profileCountryMauritania;

  /// No description provided for @profileCountryMorocco.
  ///
  /// In en, this message translates to:
  /// **'Morocco'**
  String get profileCountryMorocco;

  /// No description provided for @profileCountryOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Country (optional)'**
  String get profileCountryOptionalLabel;

  /// No description provided for @profileCountryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get profileCountryOther;

  /// No description provided for @profileCountrySaudiArabia.
  ///
  /// In en, this message translates to:
  /// **'Saudi Arabia'**
  String get profileCountrySaudiArabia;

  /// No description provided for @profileCountryTunisia.
  ///
  /// In en, this message translates to:
  /// **'Tunisia'**
  String get profileCountryTunisia;

  /// No description provided for @profileCountryUae.
  ///
  /// In en, this message translates to:
  /// **'UAE'**
  String get profileCountryUae;

  /// No description provided for @profileCountryUnitedKingdom.
  ///
  /// In en, this message translates to:
  /// **'United Kingdom'**
  String get profileCountryUnitedKingdom;

  /// No description provided for @profileCountryUnitedStates.
  ///
  /// In en, this message translates to:
  /// **'United States'**
  String get profileCountryUnitedStates;

  /// No description provided for @profileCreateAvatarHint.
  ///
  /// In en, this message translates to:
  /// **'Create your Bitmoji-style avatar'**
  String get profileCreateAvatarHint;

  /// No description provided for @profileCurrentUsername.
  ///
  /// In en, this message translates to:
  /// **'Current username'**
  String get profileCurrentUsername;

  /// No description provided for @profileInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Profile info'**
  String get profileInfoSection;

  /// No description provided for @profileMostPlayedPacks.
  ///
  /// In en, this message translates to:
  /// **'🔥 Most Played Packs'**
  String get profileMostPlayedPacks;

  /// No description provided for @profileMyAvatar.
  ///
  /// In en, this message translates to:
  /// **'My Avatar'**
  String get profileMyAvatar;

  /// No description provided for @profileMyCreatedPacks.
  ///
  /// In en, this message translates to:
  /// **'✏️ My Created Packs'**
  String get profileMyCreatedPacks;

  /// No description provided for @profileNewUsername.
  ///
  /// In en, this message translates to:
  /// **'New username'**
  String get profileNewUsername;

  /// No description provided for @profilePersonalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get profilePersonalDetails;

  /// No description provided for @profilePhoneOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number (optional)'**
  String get profilePhoneOptionalLabel;

  /// No description provided for @profilePreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profilePreferences;

  /// No description provided for @profilePremiumActiveExpires.
  ///
  /// In en, this message translates to:
  /// **'Active · expires {day}/{month}/{year}'**
  String profilePremiumActiveExpires(int day, int month, int year);

  /// No description provided for @profileSaveUsername.
  ///
  /// In en, this message translates to:
  /// **'Save username'**
  String get profileSaveUsername;

  /// No description provided for @profileTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get profileTakePhoto;

  /// No description provided for @profileUnlockPremiumHint.
  ///
  /// In en, this message translates to:
  /// **'Unlock themes, avatars, anonymous chat & more'**
  String get profileUnlockPremiumHint;

  /// No description provided for @profileUploadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo…'**
  String get profileUploadingPhoto;

  /// No description provided for @profileUsernameCooldownNotice.
  ///
  /// In en, this message translates to:
  /// **'Username change available in {days, plural, one{{days} day} other{{days} days}}.\nChanges are limited to once every 30 days.'**
  String profileUsernameCooldownNotice(int days);

  /// No description provided for @profileUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'lowercase_letters_123'**
  String get profileUsernameHint;

  /// No description provided for @profileUsernamePermanentNotice.
  ///
  /// In en, this message translates to:
  /// **'Username changes are permanent for 30 days.'**
  String get profileUsernamePermanentNotice;

  /// No description provided for @profileUsernameRequirements.
  ///
  /// In en, this message translates to:
  /// **'3–30 characters · letters, numbers, underscores'**
  String get profileUsernameRequirements;

  /// No description provided for @profileUsernameTaken.
  ///
  /// In en, this message translates to:
  /// **'This username is already taken.'**
  String get profileUsernameTaken;

  /// No description provided for @profileUsernameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Username updated!'**
  String get profileUsernameUpdated;

  /// No description provided for @profileUsernameValidation.
  ///
  /// In en, this message translates to:
  /// **'3–30 chars, only a–z, 0–9, _'**
  String get profileUsernameValidation;

  /// No description provided for @profileVerifiedCreator.
  ///
  /// In en, this message translates to:
  /// **'Verified Creator'**
  String get profileVerifiedCreator;

  /// No description provided for @notifARoom.
  ///
  /// In en, this message translates to:
  /// **'a room'**
  String get notifARoom;

  /// No description provided for @notifAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up!'**
  String get notifAllCaughtUp;

  /// No description provided for @notifDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get notifDecline;

  /// No description provided for @notifDeclineFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String notifDeclineFailed(String error);

  /// No description provided for @notifInApp.
  ///
  /// In en, this message translates to:
  /// **'In-App'**
  String get notifInApp;

  /// No description provided for @notifInvitedYouToJoin.
  ///
  /// In en, this message translates to:
  /// **'Invited you to join'**
  String get notifInvitedYouToJoin;

  /// No description provided for @notifMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notifMarkAllRead;

  /// No description provided for @notifNoNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notifNoNotifications;

  /// No description provided for @notifPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get notifPreferences;

  /// No description provided for @notifPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get notifPreferencesTitle;

  /// No description provided for @notifPush.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get notifPush;

  /// No description provided for @notifRoomInvitesCount.
  ///
  /// In en, this message translates to:
  /// **'Room Invites ({count})'**
  String notifRoomInvitesCount(int count);

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifTitle;

  /// No description provided for @notifTypeAchievement.
  ///
  /// In en, this message translates to:
  /// **'Achievement'**
  String get notifTypeAchievement;

  /// No description provided for @notifTypeFollow.
  ///
  /// In en, this message translates to:
  /// **'New Follower'**
  String get notifTypeFollow;

  /// No description provided for @notifTypeFriendAccepted.
  ///
  /// In en, this message translates to:
  /// **'Friend Accepted'**
  String get notifTypeFriendAccepted;

  /// No description provided for @notifTypeFriendRequest.
  ///
  /// In en, this message translates to:
  /// **'Friend Request'**
  String get notifTypeFriendRequest;

  /// No description provided for @notifTypeGameStarted.
  ///
  /// In en, this message translates to:
  /// **'Game Started'**
  String get notifTypeGameStarted;

  /// No description provided for @notifTypeModeration.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get notifTypeModeration;

  /// No description provided for @notifTypePackApproved.
  ///
  /// In en, this message translates to:
  /// **'Pack Approved'**
  String get notifTypePackApproved;

  /// No description provided for @notifTypePackExpired.
  ///
  /// In en, this message translates to:
  /// **'Pack Expired'**
  String get notifTypePackExpired;

  /// No description provided for @notifTypePackRejected.
  ///
  /// In en, this message translates to:
  /// **'Pack Rejected'**
  String get notifTypePackRejected;

  /// No description provided for @notifTypePackReview.
  ///
  /// In en, this message translates to:
  /// **'Pack Review'**
  String get notifTypePackReview;

  /// No description provided for @notifTypePackSale.
  ///
  /// In en, this message translates to:
  /// **'Pack Sale'**
  String get notifTypePackSale;

  /// No description provided for @notifTypePhysicalPackStatus.
  ///
  /// In en, this message translates to:
  /// **'Order Update'**
  String get notifTypePhysicalPackStatus;

  /// No description provided for @notifTypeRoomInvite.
  ///
  /// In en, this message translates to:
  /// **'Room Invite'**
  String get notifTypeRoomInvite;

  /// No description provided for @notifTypeRoomJoinRequest.
  ///
  /// In en, this message translates to:
  /// **'Room Join Request'**
  String get notifTypeRoomJoinRequest;

  /// No description provided for @notifTypeRoomJoinRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Join Request Accepted'**
  String get notifTypeRoomJoinRequestAccepted;

  /// No description provided for @notifTypeRoomJoinRequestRejected.
  ///
  /// In en, this message translates to:
  /// **'Join Request Rejected'**
  String get notifTypeRoomJoinRequestRejected;

  /// No description provided for @notifTypeRoomKicked.
  ///
  /// In en, this message translates to:
  /// **'Removed from Room'**
  String get notifTypeRoomKicked;

  /// No description provided for @notifTypeChatMessage.
  ///
  /// In en, this message translates to:
  /// **'Chat Message'**
  String get notifTypeChatMessage;

  /// No description provided for @notifTypeStreakIncreased.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get notifTypeStreakIncreased;

  /// No description provided for @notifTypeCreatorPacksTransferred.
  ///
  /// In en, this message translates to:
  /// **'Packs Jma3a-Managed'**
  String get notifTypeCreatorPacksTransferred;

  /// No description provided for @notifTypeCreatorPrivilegesRemoved.
  ///
  /// In en, this message translates to:
  /// **'Creator Status Removed'**
  String get notifTypeCreatorPrivilegesRemoved;

  /// No description provided for @notifTypeCreatorRecoveryApproved.
  ///
  /// In en, this message translates to:
  /// **'Recovery Request Approved'**
  String get notifTypeCreatorRecoveryApproved;

  /// No description provided for @notifTypeCreatorRecoveryRejected.
  ///
  /// In en, this message translates to:
  /// **'Recovery Request Rejected'**
  String get notifTypeCreatorRecoveryRejected;

  /// No description provided for @notifTypeSubscriptionExpired.
  ///
  /// In en, this message translates to:
  /// **'Subscription Expired'**
  String get notifTypeSubscriptionExpired;

  /// No description provided for @notifTypeSubscriptionExpiring1d.
  ///
  /// In en, this message translates to:
  /// **'Subscription Expiring (1 Day)'**
  String get notifTypeSubscriptionExpiring1d;

  /// No description provided for @notifTypeSubscriptionExpiring2d.
  ///
  /// In en, this message translates to:
  /// **'Subscription Expiring (2 Days)'**
  String get notifTypeSubscriptionExpiring2d;

  /// No description provided for @notifTypeSubscriptionStarted.
  ///
  /// In en, this message translates to:
  /// **'Subscription Started'**
  String get notifTypeSubscriptionStarted;

  /// No description provided for @notifTypeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get notifTypeSystem;

  /// No description provided for @notifTypeWalletCredit.
  ///
  /// In en, this message translates to:
  /// **'Wallet Credit'**
  String get notifTypeWalletCredit;

  /// No description provided for @notifTypeWalletDebit.
  ///
  /// In en, this message translates to:
  /// **'Wallet Debit'**
  String get notifTypeWalletDebit;

  /// No description provided for @viewLabel.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewLabel;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @gameSettingsAllowOneReplay.
  ///
  /// In en, this message translates to:
  /// **'Allow one replay'**
  String get gameSettingsAllowOneReplay;

  /// No description provided for @gameSettingsProofViewDuration.
  ///
  /// In en, this message translates to:
  /// **'Proof view duration (auto-closes after this)'**
  String get gameSettingsProofViewDuration;

  /// No description provided for @gameSettingsProofUnlimitedDuration.
  ///
  /// In en, this message translates to:
  /// **'Unlimited duration (until next round)'**
  String get gameSettingsProofUnlimitedDuration;

  /// No description provided for @gameSettingsProofReplayHint.
  ///
  /// In en, this message translates to:
  /// **'Premium viewers get one extra replay beyond this.'**
  String get gameSettingsProofReplayHint;

  /// No description provided for @gameSettingsProofAutoCloseHint.
  ///
  /// In en, this message translates to:
  /// **'Proof auto-closes after {seconds}s — no replay while a duration is set.'**
  String gameSettingsProofAutoCloseHint(int seconds);

  /// No description provided for @gameSettingsRequireApprovalToSpectate.
  ///
  /// In en, this message translates to:
  /// **'Require approval to spectate'**
  String get gameSettingsRequireApprovalToSpectate;

  /// No description provided for @moderationBanPlayer.
  ///
  /// In en, this message translates to:
  /// **'Ban player'**
  String get moderationBanPlayer;

  /// No description provided for @moderationDuration1Hour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get moderationDuration1Hour;

  /// No description provided for @moderationDuration24Hours.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get moderationDuration24Hours;

  /// No description provided for @moderationDuration30Min.
  ///
  /// In en, this message translates to:
  /// **'30 minutes'**
  String get moderationDuration30Min;

  /// No description provided for @moderationDuration7Days.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get moderationDuration7Days;

  /// No description provided for @moderationDurationPermanent.
  ///
  /// In en, this message translates to:
  /// **'Permanent'**
  String get moderationDurationPermanent;

  /// No description provided for @moderationReasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get moderationReasonOptional;

  /// No description provided for @roomsAnonymousModeOn.
  ///
  /// In en, this message translates to:
  /// **'Anonymous mode on'**
  String get roomsAnonymousModeOn;

  /// No description provided for @roomsAnonymousSender.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get roomsAnonymousSender;

  /// No description provided for @roomsChatDisabled.
  ///
  /// In en, this message translates to:
  /// **'Chat disabled'**
  String get roomsChatDisabled;

  /// No description provided for @roomsChooseYourRole.
  ///
  /// In en, this message translates to:
  /// **'Choose your role in this room.'**
  String get roomsChooseYourRole;

  /// No description provided for @roomsClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get roomsClosed;

  /// No description provided for @roomsAgoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String roomsAgoMinutes(int count);

  /// No description provided for @roomsAgoHours.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String roomsAgoHours(int count);

  /// No description provided for @roomsAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String roomsAgoDays(int count);

  /// No description provided for @roomsClosedAgo.
  ///
  /// In en, this message translates to:
  /// **'Closed {ago}'**
  String roomsClosedAgo(String ago);

  /// No description provided for @roomsClosedRoomFallback.
  ///
  /// In en, this message translates to:
  /// **'Closed Room'**
  String get roomsClosedRoomFallback;

  /// No description provided for @roomsConnConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get roomsConnConnecting;

  /// No description provided for @roomsConnDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get roomsConnDisconnected;

  /// No description provided for @roomsConnLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get roomsConnLive;

  /// No description provided for @roomsConnReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get roomsConnReconnecting;

  /// No description provided for @roomsConnSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get roomsConnSyncing;

  /// No description provided for @roomsFailedToSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to send request: {error}'**
  String roomsFailedToSendRequest(String error);

  /// No description provided for @roomsFallbackRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get roomsFallbackRoom;

  /// No description provided for @roomsGameAlreadyInProgress.
  ///
  /// In en, this message translates to:
  /// **'This game is already in progress.'**
  String get roomsGameAlreadyInProgress;

  /// No description provided for @roomsGameInProgress.
  ///
  /// In en, this message translates to:
  /// **'Game in progress'**
  String get roomsGameInProgress;

  /// No description provided for @roomsHiddenFromPlayersList.
  ///
  /// In en, this message translates to:
  /// **'Hidden from players and spectator list'**
  String get roomsHiddenFromPlayersList;

  /// No description provided for @roomsInvalidCodeOrNotFound.
  ///
  /// In en, this message translates to:
  /// **'Invalid code or room not found'**
  String get roomsInvalidCodeOrNotFound;

  /// No description provided for @roomsInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get roomsInvite;

  /// No description provided for @roomsJoinAsPlayer.
  ///
  /// In en, this message translates to:
  /// **'Join as Player'**
  String get roomsJoinAsPlayer;

  /// No description provided for @roomsMakeModerator.
  ///
  /// In en, this message translates to:
  /// **'Make moderator'**
  String get roomsMakeModerator;

  /// No description provided for @roomsManagePermissionsCount.
  ///
  /// In en, this message translates to:
  /// **'Manage permissions ({count})'**
  String roomsManagePermissionsCount(int count);

  /// No description provided for @roomsMessageAsAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Message as Anonymous…'**
  String get roomsMessageAsAnonymous;

  /// No description provided for @roomsModeration.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get roomsModeration;

  /// No description provided for @roomsObserveWithoutPlaying.
  ///
  /// In en, this message translates to:
  /// **'Observe without playing'**
  String get roomsObserveWithoutPlaying;

  /// No description provided for @roomsPackRequiresMinPlayers.
  ///
  /// In en, this message translates to:
  /// **'This pack requires at least {count} players.'**
  String roomsPackRequiresMinPlayers(int count);

  /// No description provided for @roomsPackRequiresMaxPlayers.
  ///
  /// In en, this message translates to:
  /// **'This pack can only be played by {count} players. Set the extra players as spectators or remove them to start.'**
  String roomsPackRequiresMaxPlayers(int count);

  /// No description provided for @roomsPendingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Pending…'**
  String get roomsPendingEllipsis;

  /// No description provided for @roomsPermAcceptJoins.
  ///
  /// In en, this message translates to:
  /// **'Accept join requests'**
  String get roomsPermAcceptJoins;

  /// No description provided for @roomsPermAcceptRejoins.
  ///
  /// In en, this message translates to:
  /// **'Accept rejoin requests'**
  String get roomsPermAcceptRejoins;

  /// No description provided for @roomsPermAcceptSpectators.
  ///
  /// In en, this message translates to:
  /// **'Accept spectator requests'**
  String get roomsPermAcceptSpectators;

  /// No description provided for @roomsPermAdvanceTurn.
  ///
  /// In en, this message translates to:
  /// **'Start next turn'**
  String get roomsPermAdvanceTurn;

  /// No description provided for @roomsPermEndGame.
  ///
  /// In en, this message translates to:
  /// **'End the game'**
  String get roomsPermEndGame;

  /// No description provided for @roomsPermKickPlayers.
  ///
  /// In en, this message translates to:
  /// **'Remove players'**
  String get roomsPermKickPlayers;

  /// No description provided for @roomsPermManageSettings.
  ///
  /// In en, this message translates to:
  /// **'Manage room settings'**
  String get roomsPermManageSettings;

  /// No description provided for @roomsPermSetSpectator.
  ///
  /// In en, this message translates to:
  /// **'Set players as spectators'**
  String get roomsPermSetSpectator;

  /// No description provided for @roomsPermMuteChat.
  ///
  /// In en, this message translates to:
  /// **'Mute chat'**
  String get roomsPermMuteChat;

  /// No description provided for @roomsPermMutePlayers.
  ///
  /// In en, this message translates to:
  /// **'Mute players in game'**
  String get roomsPermMutePlayers;

  /// No description provided for @roomsPermSkipTurn.
  ///
  /// In en, this message translates to:
  /// **'Skip a turn'**
  String get roomsPermSkipTurn;

  /// No description provided for @roomsPermStartGame.
  ///
  /// In en, this message translates to:
  /// **'Start the game'**
  String get roomsPermStartGame;

  /// No description provided for @roomsRejoin.
  ///
  /// In en, this message translates to:
  /// **'Rejoin'**
  String get roomsRejoin;

  /// No description provided for @roomsRejoinRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Your rejoin request was declined'**
  String get roomsRejoinRequestDeclined;

  /// No description provided for @roomsRequestAgain.
  ///
  /// In en, this message translates to:
  /// **'Request Again'**
  String get roomsRequestAgain;

  /// No description provided for @roomsRequestSentWaiting.
  ///
  /// In en, this message translates to:
  /// **'Request sent — waiting for the host'**
  String get roomsRequestSentWaiting;

  /// No description provided for @roomsRequestToRejoin.
  ///
  /// In en, this message translates to:
  /// **'Request to Rejoin'**
  String get roomsRequestToRejoin;

  /// No description provided for @roomsSendAnonymouslyPremium.
  ///
  /// In en, this message translates to:
  /// **'Send anonymously (Premium)'**
  String get roomsSendAnonymouslyPremium;

  /// No description provided for @roomsStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get roomsStatusClosed;

  /// No description provided for @roomsStatusInGame.
  ///
  /// In en, this message translates to:
  /// **'In Game'**
  String get roomsStatusInGame;

  /// No description provided for @roomsStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get roomsStatusPaused;

  /// No description provided for @roomsStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get roomsStatusWaiting;

  /// No description provided for @roomsTakePartInGame.
  ///
  /// In en, this message translates to:
  /// **'Take part in the game'**
  String get roomsTakePartInGame;

  /// No description provided for @roomsTransferOwnershipConfirm.
  ///
  /// In en, this message translates to:
  /// **'Transfer room ownership to {name}? You will become a regular player.'**
  String roomsTransferOwnershipConfirm(String name);

  /// No description provided for @roomsWaitingForReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for reconnecting player(s)...'**
  String get roomsWaitingForReconnecting;

  /// No description provided for @roomsWatchAnonymously.
  ///
  /// In en, this message translates to:
  /// **'Watch Anonymously ✦'**
  String get roomsWatchAnonymously;

  /// No description provided for @roomsWatchAsSpectator.
  ///
  /// In en, this message translates to:
  /// **'Watch as Spectator'**
  String get roomsWatchAsSpectator;

  /// No description provided for @sharedApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get sharedApprove;

  /// No description provided for @sharedBan.
  ///
  /// In en, this message translates to:
  /// **'Ban'**
  String get sharedBan;

  /// No description provided for @sharedBanPlayerBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to ban this player from this room?'**
  String get sharedBanPlayerBody;

  /// No description provided for @sharedBanPlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Ban Player'**
  String get sharedBanPlayerTitle;

  /// No description provided for @sharedEndGame.
  ///
  /// In en, this message translates to:
  /// **'End Game'**
  String get sharedEndGame;

  /// No description provided for @sharedEveryoneLeftNotice.
  ///
  /// In en, this message translates to:
  /// **'Every other player has left. The game cannot continue — end it when you\'re ready.'**
  String get sharedEveryoneLeftNotice;

  /// No description provided for @sharedGameRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'{gameName} — Rules'**
  String sharedGameRulesTitle(String gameName);

  /// No description provided for @sharedGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get sharedGoHome;

  /// No description provided for @sharedHistoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get sharedHistoryTooltip;

  /// No description provided for @sharedReactionAvatarsTab.
  ///
  /// In en, this message translates to:
  /// **'Avatars'**
  String get sharedReactionAvatarsTab;

  /// No description provided for @sharedReactionIconsTab.
  ///
  /// In en, this message translates to:
  /// **'Icons'**
  String get sharedReactionIconsTab;

  /// No description provided for @sharedReactionPickIconTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a reaction'**
  String get sharedReactionPickIconTitle;

  /// No description provided for @sharedReactionPickAvatarTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick an avatar reaction'**
  String get sharedReactionPickAvatarTitle;

  /// No description provided for @sharedReactionCategoryPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get sharedReactionCategoryPopular;

  /// No description provided for @sharedReactionCategoryLove.
  ///
  /// In en, this message translates to:
  /// **'Love'**
  String get sharedReactionCategoryLove;

  /// No description provided for @sharedReactionCategoryFunny.
  ///
  /// In en, this message translates to:
  /// **'Funny'**
  String get sharedReactionCategoryFunny;

  /// No description provided for @sharedReactionCategoryShock.
  ///
  /// In en, this message translates to:
  /// **'Shock'**
  String get sharedReactionCategoryShock;

  /// No description provided for @sharedReactionCategoryCelebration.
  ///
  /// In en, this message translates to:
  /// **'Celebration'**
  String get sharedReactionCategoryCelebration;

  /// No description provided for @sharedReactionCategorySocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get sharedReactionCategorySocial;

  /// No description provided for @sharedReactionCategoryMoody.
  ///
  /// In en, this message translates to:
  /// **'Moody'**
  String get sharedReactionCategoryMoody;

  /// No description provided for @gameResultSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get gameResultSkipped;

  /// No description provided for @gameResultDidNotRespond.
  ///
  /// In en, this message translates to:
  /// **'Did not respond in time'**
  String get gameResultDidNotRespond;

  /// No description provided for @sharedJoinRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String sharedJoinRequestFailed(String error);

  /// No description provided for @sharedJoinRequestsCount.
  ///
  /// In en, this message translates to:
  /// **'Join Requests ({count})'**
  String sharedJoinRequestsCount(int count);

  /// No description provided for @sharedKick.
  ///
  /// In en, this message translates to:
  /// **'Kick'**
  String get sharedKick;

  /// No description provided for @sharedKickPlayerBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this player from the current game?'**
  String get sharedKickPlayerBody;

  /// No description provided for @sharedKickPlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Kick Player'**
  String get sharedKickPlayerTitle;

  /// No description provided for @sharedMemeRuleObjective.
  ///
  /// In en, this message translates to:
  /// **'Submit the funniest caption or sticker for the round\'s prompt, then vote for your favorite from everyone else\'s.'**
  String get sharedMemeRuleObjective;

  /// No description provided for @sharedMemeRuleScoring.
  ///
  /// In en, this message translates to:
  /// **'Whoever gets the most votes on a round wins that round\'s point. Most points at the end wins the game.'**
  String get sharedMemeRuleScoring;

  /// No description provided for @sharedMemeRuleTurnFlow.
  ///
  /// In en, this message translates to:
  /// **'Submission phase → voting phase → results, every round, until the pack\'s prompts run out or the round limit is hit.'**
  String get sharedMemeRuleTurnFlow;

  /// No description provided for @sharedMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get sharedMute;

  /// No description provided for @sharedNhieRuleObjective.
  ///
  /// In en, this message translates to:
  /// **'Each round shows a \"Never have I ever…\" statement. Everyone answers honestly whether they have or haven\'t.'**
  String get sharedNhieRuleObjective;

  /// No description provided for @sharedNhieRuleScoring.
  ///
  /// In en, this message translates to:
  /// **'Your history of honest answers builds your profile across the game — there\'s no winner/loser, just revealing.'**
  String get sharedNhieRuleScoring;

  /// No description provided for @sharedNhieRuleTurnFlow.
  ///
  /// In en, this message translates to:
  /// **'A new statement appears each round; every player votes, then the round advances once everyone has answered.'**
  String get sharedNhieRuleTurnFlow;

  /// No description provided for @sharedNoPendingJoinRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending join requests'**
  String get sharedNoPendingJoinRequests;

  /// No description provided for @sharedPageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page Not Found'**
  String get sharedPageNotFound;

  /// No description provided for @sharedPageNotFoundHint.
  ///
  /// In en, this message translates to:
  /// **'The page you\'re looking for doesn\'t exist.'**
  String get sharedPageNotFoundHint;

  /// No description provided for @sharedReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get sharedReject;

  /// No description provided for @sharedRemoveSpectator.
  ///
  /// In en, this message translates to:
  /// **'Remove Spectator'**
  String get sharedRemoveSpectator;

  /// No description provided for @sharedSetSpectator.
  ///
  /// In en, this message translates to:
  /// **'Set as Spectator'**
  String get sharedSetSpectator;

  /// No description provided for @sharedSetSpectatorBody.
  ///
  /// In en, this message translates to:
  /// **'This player will stop counting as an active player and won\'t be able to take turns, but can still watch. You can reverse this anytime.'**
  String get sharedSetSpectatorBody;

  /// No description provided for @sharedSetSpectatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Set as Spectator'**
  String get sharedSetSpectatorTitle;

  /// No description provided for @sharedRoomMembers.
  ///
  /// In en, this message translates to:
  /// **'Room members'**
  String get sharedRoomMembers;

  /// No description provided for @sharedRoomMembersCount.
  ///
  /// In en, this message translates to:
  /// **'👥 Room Members ({count})'**
  String sharedRoomMembersCount(int count);

  /// No description provided for @sharedRoomSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'This room\'s settings'**
  String get sharedRoomSettingsTitle;

  /// No description provided for @sharedRuleNoTurnTimer.
  ///
  /// In en, this message translates to:
  /// **'No turn timer'**
  String get sharedRuleNoTurnTimer;

  /// No description provided for @sharedRuleObjective.
  ///
  /// In en, this message translates to:
  /// **'Objective'**
  String get sharedRuleObjective;

  /// No description provided for @sharedRulePolicyEveryone.
  ///
  /// In en, this message translates to:
  /// **'everyone in the game'**
  String get sharedRulePolicyEveryone;

  /// No description provided for @sharedRulePolicyPlayersOnly.
  ///
  /// In en, this message translates to:
  /// **'players only'**
  String get sharedRulePolicyPlayersOnly;

  /// No description provided for @sharedRulePolicySpectatorsOnly.
  ///
  /// In en, this message translates to:
  /// **'spectators only'**
  String get sharedRulePolicySpectatorsOnly;

  /// No description provided for @sharedRuleProofViewOnce.
  ///
  /// In en, this message translates to:
  /// **'Proof can be viewed once (Premium: twice).'**
  String get sharedRuleProofViewOnce;

  /// No description provided for @sharedRuleProofViewTwice.
  ///
  /// In en, this message translates to:
  /// **'Proof can be viewed twice (Premium: three times).'**
  String get sharedRuleProofViewTwice;

  /// No description provided for @sharedRuleProofVisibleTo.
  ///
  /// In en, this message translates to:
  /// **'Proof is visible to: {policy}.'**
  String sharedRuleProofVisibleTo(String policy);

  /// No description provided for @sharedRulePunishmentOff.
  ///
  /// In en, this message translates to:
  /// **'Punishment mode is OFF — skipping isn\'t offered as an option.'**
  String get sharedRulePunishmentOff;

  /// No description provided for @sharedRulePunishmentOn.
  ///
  /// In en, this message translates to:
  /// **'Punishment mode is ON — skipping means every other player submits one punishment and you pick which you\'ll do.'**
  String get sharedRulePunishmentOn;

  /// No description provided for @sharedRuleScoring.
  ///
  /// In en, this message translates to:
  /// **'Scoring'**
  String get sharedRuleScoring;

  /// No description provided for @sharedRuleSpectatorsApprovalRequired.
  ///
  /// In en, this message translates to:
  /// **'Spectators are allowed, subject to host approval.'**
  String get sharedRuleSpectatorsApprovalRequired;

  /// No description provided for @sharedRuleSpectatorsFreelyAllowed.
  ///
  /// In en, this message translates to:
  /// **'Spectators are allowed to watch freely.'**
  String get sharedRuleSpectatorsFreelyAllowed;

  /// No description provided for @sharedRuleSpectatorsNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Spectators are not allowed in this room.'**
  String get sharedRuleSpectatorsNotAllowed;

  /// No description provided for @sharedRuleSpicyEnabled.
  ///
  /// In en, this message translates to:
  /// **'Spicy content is enabled for this room.'**
  String get sharedRuleSpicyEnabled;

  /// No description provided for @sharedRuleTurnFlow.
  ///
  /// In en, this message translates to:
  /// **'Turn flow'**
  String get sharedRuleTurnFlow;

  /// No description provided for @sharedRuleTurnTimer.
  ///
  /// In en, this message translates to:
  /// **'Turn timer: {seconds}s'**
  String sharedRuleTurnTimer(int seconds);

  /// No description provided for @sharedRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get sharedRules;

  /// No description provided for @sharedStatusDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get sharedStatusDisconnected;

  /// No description provided for @sharedStatusMuted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get sharedStatusMuted;

  /// No description provided for @sharedStatusPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get sharedStatusPlaying;

  /// No description provided for @sharedStatusSpectator.
  ///
  /// In en, this message translates to:
  /// **'Spectator'**
  String get sharedStatusSpectator;

  /// No description provided for @sharedTodRuleObjective.
  ///
  /// In en, this message translates to:
  /// **'Take turns choosing Truth or Dare. Answer honestly or complete the dare — there\'s no \"safe\" option once you\'ve picked.'**
  String get sharedTodRuleObjective;

  /// No description provided for @sharedTodRuleScoring.
  ///
  /// In en, this message translates to:
  /// **'Completed truths and dares add to your score. Skips are tracked too — they may trigger a punishment (see below).'**
  String get sharedTodRuleScoring;

  /// No description provided for @sharedTodRuleTurnFlow.
  ///
  /// In en, this message translates to:
  /// **'The current player picks Truth or Dare, gets a card, and either answers/performs it or (if allowed) skips. Then play passes to the next player in order.'**
  String get sharedTodRuleTurnFlow;

  /// No description provided for @sharedUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get sharedUnmute;

  /// No description provided for @sharedWantsToJoinCurrentGame.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to join the current game.'**
  String sharedWantsToJoinCurrentGame(String name);

  /// No description provided for @friendsAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get friendsAccept;

  /// No description provided for @friendsReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get friendsReject;

  /// No description provided for @friendsDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get friendsDecline;

  /// No description provided for @friendsPendingRequestsHeader.
  ///
  /// In en, this message translates to:
  /// **'Pending Friendship Requests'**
  String get friendsPendingRequestsHeader;

  /// No description provided for @friendsYourFriendsHeader.
  ///
  /// In en, this message translates to:
  /// **'Your Friends'**
  String get friendsYourFriendsHeader;

  /// No description provided for @friendsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get friendsAdd;

  /// No description provided for @friendsAddFriend.
  ///
  /// In en, this message translates to:
  /// **'Add friend'**
  String get friendsAddFriend;

  /// No description provided for @friendsBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get friendsBlock;

  /// No description provided for @friendsReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get friendsReport;

  /// No description provided for @friendsReportAndBlock.
  ///
  /// In en, this message translates to:
  /// **'Report & Block'**
  String get friendsReportAndBlock;

  /// No description provided for @friendsReportUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Report User'**
  String get friendsReportUserTitle;

  /// No description provided for @friendsReportHint.
  ///
  /// In en, this message translates to:
  /// **'Help us keep the community safe.'**
  String get friendsReportHint;

  /// No description provided for @friendsReportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get friendsReportReasonHarassment;

  /// No description provided for @friendsReportReasonImpersonation.
  ///
  /// In en, this message translates to:
  /// **'Impersonation'**
  String get friendsReportReasonImpersonation;

  /// No description provided for @friendsReportReasonUnderage.
  ///
  /// In en, this message translates to:
  /// **'Underage user'**
  String get friendsReportReasonUnderage;

  /// No description provided for @friendsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get friendsBlocked;

  /// No description provided for @friendsCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get friendsCancelRequest;

  /// No description provided for @friendsCannotInteract.
  ///
  /// In en, this message translates to:
  /// **'You cannot interact with this user.'**
  String get friendsCannotInteract;

  /// No description provided for @friendsCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Created by {name}'**
  String friendsCreatedBy(String name);

  /// No description provided for @friendsOfficialAccount.
  ///
  /// In en, this message translates to:
  /// **'Official Jma3a Account'**
  String get friendsOfficialAccount;

  /// No description provided for @friendsFollowersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Followers'**
  String friendsFollowersCount(int count);

  /// No description provided for @friendsFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get friendsFollow;

  /// No description provided for @friendsFollowersTitle.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get friendsFollowersTitle;

  /// No description provided for @friendsNoFollowersYet.
  ///
  /// In en, this message translates to:
  /// **'No followers yet.'**
  String get friendsNoFollowersYet;

  /// No description provided for @friendsMostPlayedBy.
  ///
  /// In en, this message translates to:
  /// **'Most Played by {name}'**
  String friendsMostPlayedBy(String name);

  /// No description provided for @friendsNoBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'No blocked users'**
  String get friendsNoBlockedUsers;

  /// No description provided for @friendsNoBlockedUsersHint.
  ///
  /// In en, this message translates to:
  /// **'Users you block will appear here.'**
  String get friendsNoBlockedUsersHint;

  /// No description provided for @friendsNoFriendsHint.
  ///
  /// In en, this message translates to:
  /// **'Explore people and find players to connect with.'**
  String get friendsNoFriendsHint;

  /// No description provided for @friendsNoFriendsYet.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get friendsNoFriendsYet;

  /// No description provided for @friendsNoPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get friendsNoPendingRequests;

  /// No description provided for @friendsNoPendingRequestsHint.
  ///
  /// In en, this message translates to:
  /// **'Friend requests you receive will appear here.'**
  String get friendsNoPendingRequestsHint;

  /// No description provided for @friendsNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get friendsNoResults;

  /// No description provided for @friendsNoResultsHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different name or username.'**
  String get friendsNoResultsHint;

  /// No description provided for @friendsOfflineCount.
  ///
  /// In en, this message translates to:
  /// **'Offline — {count}'**
  String friendsOfflineCount(int count);

  /// No description provided for @friendsOnlineCount.
  ///
  /// In en, this message translates to:
  /// **'Online — {count}'**
  String friendsOnlineCount(int count);

  /// No description provided for @creatorVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Become a Verified Creator'**
  String get creatorVerificationTitle;

  /// No description provided for @creatorVerificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Meet all of these requirements to apply for creator verification.'**
  String get creatorVerificationSubtitle;

  /// No description provided for @creatorReqPremiumPlus.
  ///
  /// In en, this message translates to:
  /// **'Premium Plus subscriber'**
  String get creatorReqPremiumPlus;

  /// No description provided for @creatorReqGamesPlayed.
  ///
  /// In en, this message translates to:
  /// **'Play at least {count} games'**
  String creatorReqGamesPlayed(int count);

  /// No description provided for @creatorReqPacksUsed.
  ///
  /// In en, this message translates to:
  /// **'Use at least {count} packs'**
  String creatorReqPacksUsed(int count);

  /// No description provided for @creatorReqFollowers.
  ///
  /// In en, this message translates to:
  /// **'Have at least {count} followers'**
  String creatorReqFollowers(int count);

  /// No description provided for @creatorReqLoginStreak.
  ///
  /// In en, this message translates to:
  /// **'Enter the app {count} days in a row'**
  String creatorReqLoginStreak(int count);

  /// No description provided for @creatorReqRoomStreak.
  ///
  /// In en, this message translates to:
  /// **'Create a room every day for {count} days in a row'**
  String creatorReqRoomStreak(int count);

  /// No description provided for @creatorReqPackGamesStreak.
  ///
  /// In en, this message translates to:
  /// **'Finish at least {count} pack games every day for {days} days in a row'**
  String creatorReqPackGamesStreak(int count, int days);

  /// No description provided for @creatorReqPlayedWithOthers.
  ///
  /// In en, this message translates to:
  /// **'Play a game with other users'**
  String get creatorReqPlayedWithOthers;

  /// No description provided for @creatorApplyNow.
  ///
  /// In en, this message translates to:
  /// **'Apply Now'**
  String get creatorApplyNow;

  /// No description provided for @creatorKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going — you\'ll be able to apply once every requirement above is met.'**
  String get creatorKeepGoing;

  /// No description provided for @creatorRecoveryBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Your verified creator status was removed'**
  String get creatorRecoveryBannerTitle;

  /// No description provided for @creatorRecoveryBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Your Premium Plus subscription lapsed and your verified creator status/privileges were automatically removed. You can submit a recovery request for admin review.'**
  String get creatorRecoveryBannerBody;

  /// No description provided for @creatorRecoveryBannerAction.
  ///
  /// In en, this message translates to:
  /// **'Submit a Recovery Request'**
  String get creatorRecoveryBannerAction;

  /// No description provided for @creatorRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery Request'**
  String get creatorRecoveryTitle;

  /// No description provided for @creatorRecoveryIntro.
  ///
  /// In en, this message translates to:
  /// **'Tell us what happened. An admin will review your request and, if approved, your verified creator status, privileges, and packs will be fully restored.'**
  String get creatorRecoveryIntro;

  /// No description provided for @creatorRecoveryReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get creatorRecoveryReasonLabel;

  /// No description provided for @creatorRecoveryReasonResubscribedLate.
  ///
  /// In en, this message translates to:
  /// **'I resubscribed but missed the grace period'**
  String get creatorRecoveryReasonResubscribedLate;

  /// No description provided for @creatorRecoveryReasonPaymentIssue.
  ///
  /// In en, this message translates to:
  /// **'A payment/billing issue caused the lapse'**
  String get creatorRecoveryReasonPaymentIssue;

  /// No description provided for @creatorRecoveryReasonUnawareOfExpiry.
  ///
  /// In en, this message translates to:
  /// **'I wasn\'t notified my subscription expired'**
  String get creatorRecoveryReasonUnawareOfExpiry;

  /// No description provided for @creatorRecoveryReasonExtenuatingCircumstances.
  ///
  /// In en, this message translates to:
  /// **'Extenuating circumstances prevented renewal'**
  String get creatorRecoveryReasonExtenuatingCircumstances;

  /// No description provided for @creatorRecoveryReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get creatorRecoveryReasonOther;

  /// No description provided for @creatorRecoveryExplanationLabel.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get creatorRecoveryExplanationLabel;

  /// No description provided for @creatorRecoveryExplanationHint.
  ///
  /// In en, this message translates to:
  /// **'Explain what happened in at least 20 characters'**
  String get creatorRecoveryExplanationHint;

  /// No description provided for @creatorRecoveryExplanationTooShort.
  ///
  /// In en, this message translates to:
  /// **'Please write at least 20 characters explaining what happened.'**
  String get creatorRecoveryExplanationTooShort;

  /// No description provided for @creatorRecoveryEvidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Evidence (optional)'**
  String get creatorRecoveryEvidenceLabel;

  /// No description provided for @creatorRecoveryEvidenceUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload that image. Please try again.'**
  String get creatorRecoveryEvidenceUploadFailed;

  /// No description provided for @creatorRecoverySubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get creatorRecoverySubmit;

  /// No description provided for @creatorRecoverySubmitted.
  ///
  /// In en, this message translates to:
  /// **'Your recovery request has been submitted for review.'**
  String get creatorRecoverySubmitted;

  /// No description provided for @creatorRecoveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t submit your recovery request. Please try again.'**
  String get creatorRecoveryFailed;

  /// No description provided for @creatorRecoveryPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery Request Pending'**
  String get creatorRecoveryPendingTitle;

  /// No description provided for @creatorRecoveryPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Your recovery request is being reviewed by an admin. You\'ll be notified once a decision is made.'**
  String get creatorRecoveryPendingBody;

  /// No description provided for @creatorRecoveryRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your previous recovery request was rejected'**
  String get creatorRecoveryRejectedTitle;

  /// No description provided for @creatorApplyDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply for Verification'**
  String get creatorApplyDialogTitle;

  /// No description provided for @creatorApplyDialogRealName.
  ///
  /// In en, this message translates to:
  /// **'Full legal name'**
  String get creatorApplyDialogRealName;

  /// No description provided for @creatorApplyDialogBio.
  ///
  /// In en, this message translates to:
  /// **'Short bio (optional)'**
  String get creatorApplyDialogBio;

  /// No description provided for @creatorApplySubmitted.
  ///
  /// In en, this message translates to:
  /// **'Application submitted! We\'ll review it soon.'**
  String get creatorApplySubmitted;

  /// No description provided for @creatorApplyFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit application. Please try again.'**
  String get creatorApplyFailed;

  /// No description provided for @profileBecomeCreator.
  ///
  /// In en, this message translates to:
  /// **'Become a Verified Creator'**
  String get profileBecomeCreator;

  /// No description provided for @profileBecomeCreatorHint.
  ///
  /// In en, this message translates to:
  /// **'Unlock creator tools and earnings'**
  String get profileBecomeCreatorHint;

  /// No description provided for @friendsPlayingNow.
  ///
  /// In en, this message translates to:
  /// **'Playing now'**
  String get friendsPlayingNow;

  /// No description provided for @friendsProfileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found.'**
  String get friendsProfileNotFound;

  /// No description provided for @friendsReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get friendsReceived;

  /// No description provided for @friendsRemoveFriend.
  ///
  /// In en, this message translates to:
  /// **'Remove friend'**
  String get friendsRemoveFriend;

  /// No description provided for @friendsRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get friendsRequests;

  /// No description provided for @friendsSearchForFriends.
  ///
  /// In en, this message translates to:
  /// **'Search for friends'**
  String get friendsSearchForFriends;

  /// No description provided for @friendsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by username or name…'**
  String get friendsSearchHint;

  /// No description provided for @friendsSearchMinChars.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 2 characters.'**
  String get friendsSearchMinChars;

  /// No description provided for @friendsSentCount.
  ///
  /// In en, this message translates to:
  /// **'Sent — {count}'**
  String friendsSentCount(int count);

  /// No description provided for @friendsStatusInGame.
  ///
  /// In en, this message translates to:
  /// **'In Game'**
  String get friendsStatusInGame;

  /// No description provided for @friendsStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get friendsStatusOffline;

  /// No description provided for @friendsStatusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get friendsStatusOnline;

  /// No description provided for @presenceUserIsAway.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get presenceUserIsAway;

  /// No description provided for @presenceUserIsAwayFull.
  ///
  /// In en, this message translates to:
  /// **'User is away'**
  String get presenceUserIsAwayFull;

  /// No description provided for @presenceUserAwaySnackbar.
  ///
  /// In en, this message translates to:
  /// **'{name} is away'**
  String presenceUserAwaySnackbar(String name);

  /// No description provided for @friendsStatusInRoomLobby.
  ///
  /// In en, this message translates to:
  /// **'In room lobby'**
  String get friendsStatusInRoomLobby;

  /// No description provided for @friendsStatusPlayingGame.
  ///
  /// In en, this message translates to:
  /// **'Playing {game}'**
  String friendsStatusPlayingGame(String game);

  /// No description provided for @friendsUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get friendsUnblock;

  /// No description provided for @friendsUnblockedNotice.
  ///
  /// In en, this message translates to:
  /// **'{name} unblocked'**
  String friendsUnblockedNotice(String name);

  /// No description provided for @friendsUnfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get friendsUnfollow;

  /// No description provided for @friendsUserFallback.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get friendsUserFallback;

  /// No description provided for @friendsYouHaveBlocked.
  ///
  /// In en, this message translates to:
  /// **'You have blocked this user.'**
  String get friendsYouHaveBlocked;

  /// No description provided for @notifJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notifJustNow;

  /// No description provided for @notifMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count}m ago} other{{count}m ago}}'**
  String notifMinutesAgo(int count);

  /// No description provided for @settingsAboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get settingsAboutUs;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsTermsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get settingsTermsConditions;

  /// No description provided for @settingsRequestAccountDeletion.
  ///
  /// In en, this message translates to:
  /// **'Request Account Deletion'**
  String get settingsRequestAccountDeletion;

  /// No description provided for @settingsRequestAccountDeletionPending.
  ///
  /// In en, this message translates to:
  /// **'Deletion request pending review'**
  String get settingsRequestAccountDeletionPending;

  /// No description provided for @deleteAccountDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountDialogTitle;

  /// No description provided for @deleteAccountDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This submits a request for our team to review — your account is not deleted immediately. Once approved, your profile, packs, wallet balance, and game history are permanently removed and this cannot be undone.'**
  String get deleteAccountDialogMessage;

  /// No description provided for @deleteAccountDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get deleteAccountDialogConfirm;

  /// No description provided for @deleteAccountSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Your deletion request has been submitted for review.'**
  String get deleteAccountSubmitted;

  /// No description provided for @deleteAccountAlreadyPending.
  ///
  /// In en, this message translates to:
  /// **'You already have a pending deletion request.'**
  String get deleteAccountAlreadyPending;

  /// No description provided for @settingsCancelAccountDeletion.
  ///
  /// In en, this message translates to:
  /// **'Cancel Account Deletion'**
  String get settingsCancelAccountDeletion;

  /// No description provided for @settingsCancelAccountDeletionHint.
  ///
  /// In en, this message translates to:
  /// **'Your account will stay active if you cancel before it\'s processed.'**
  String get settingsCancelAccountDeletionHint;

  /// No description provided for @settingsCancelAccountDeletionDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel deletion request?'**
  String get settingsCancelAccountDeletionDialogTitle;

  /// No description provided for @settingsCancelAccountDeletionDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account will remain active and nothing will be deleted.'**
  String get settingsCancelAccountDeletionDialogMessage;

  /// No description provided for @settingsCancelAccountDeletionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get settingsCancelAccountDeletionConfirm;

  /// No description provided for @settingsAccountDeletionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Your account deletion request has been cancelled.'**
  String get settingsAccountDeletionCancelled;

  /// No description provided for @settingsCancelAccountDeletionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t cancel your request. It may already be past cancellation — please try again or contact support.'**
  String get settingsCancelAccountDeletionFailed;

  /// No description provided for @aboutUsTitle.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUsTitle;

  /// No description provided for @aboutUsVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutUsVersionLabel;

  /// No description provided for @aboutUsDescription.
  ///
  /// In en, this message translates to:
  /// **'Jma3a is a social multiplayer party-game platform developed and owned by MOUJ TECH. Play Truth or Dare, Never Have I Ever, and Meme games with friends and family, create and share your own packs, build a profile, and — as a Verified Creator — earn from packs you publish.'**
  String get aboutUsDescription;

  /// No description provided for @aboutUsCompanySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get aboutUsCompanySectionTitle;

  /// No description provided for @aboutUsCompanyInfo.
  ///
  /// In en, this message translates to:
  /// **'Jma3a is developed and owned by MOUJ TECH. MOUJ TECH is responsible for the app\'s development, features, and ongoing operation, including community-created packs, Verified Creator tools, Premium and Premium Plus, and the creator earnings wallet.'**
  String get aboutUsCompanyInfo;

  /// No description provided for @moujTechDevelopedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed by MOUJ TECH'**
  String get moujTechDevelopedBy;

  /// No description provided for @aboutUsContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get aboutUsContactTitle;

  /// No description provided for @aboutUsContactEmail.
  ///
  /// In en, this message translates to:
  /// **'support@jma3a.app'**
  String get aboutUsContactEmail;

  /// No description provided for @aboutUsWebsiteTitle.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get aboutUsWebsiteTitle;

  /// No description provided for @aboutUsWebsite.
  ///
  /// In en, this message translates to:
  /// **'www.jma3a.app'**
  String get aboutUsWebsite;

  /// No description provided for @aboutUsFollowUsTitle.
  ///
  /// In en, this message translates to:
  /// **'Follow us'**
  String get aboutUsFollowUsTitle;

  /// No description provided for @aboutUsSocialTiktok.
  ///
  /// In en, this message translates to:
  /// **'TikTok'**
  String get aboutUsSocialTiktok;

  /// No description provided for @aboutUsSocialSnapchat.
  ///
  /// In en, this message translates to:
  /// **'Snapchat'**
  String get aboutUsSocialSnapchat;

  /// No description provided for @aboutUsSocialFacebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get aboutUsSocialFacebook;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyPolicyIntro.
  ///
  /// In en, this message translates to:
  /// **'This Privacy Policy explains what information the Jma3a app collects, how it is used, and the choices you have. It describes Jma3a\'s actual current features. Some legal details specific to MOUJ TECH as a company (such as its registered address and formal contact channels) are still being finalized and will be added here once available — this does not change what is described below about how the app itself handles your information.'**
  String get privacyPolicyIntro;

  /// No description provided for @privacySectionInfoCollected.
  ///
  /// In en, this message translates to:
  /// **'Information We Collect'**
  String get privacySectionInfoCollected;

  /// No description provided for @privacySectionInfoCollectedBody.
  ///
  /// In en, this message translates to:
  /// **'Account information: the email address you sign up with, and your chosen username, display name, bio, and avatar (either an uploaded photo or a generated avatar). Authentication: your password is handled by our authentication provider and is never visible to us in plain text; sign-in also uses one-time verification codes sent to your email. Activity and social data: the rooms and games you join or host, your in-game actions, scores, and streaks, chat messages you send in game rooms, and your friends, followers, and any accounts you block. Purchases and creator activity: packs you buy or publish, your Verified Creator status, wallet balance and payout history, and — if you request a physical pack — the name, phone number, and delivery area you provide for that order. Reports: if you report a pack, we record the reason and any details you add. Account deletion requests: if you request to delete your account, we record the reason you select and the request\'s status. Device and app information: your app version and build number, and basic platform information (Android or iOS), used to keep the app working correctly and to check for required updates.'**
  String get privacySectionInfoCollectedBody;

  /// No description provided for @privacySectionHowUsed.
  ///
  /// In en, this message translates to:
  /// **'How We Use Your Information'**
  String get privacySectionHowUsed;

  /// No description provided for @privacySectionHowUsedBody.
  ///
  /// In en, this message translates to:
  /// **'We use your information to operate the app\'s core features: creating and securing your account, matching you with rooms and games, showing your profile and stats to other players and friends as intended by each feature, processing pack purchases and creator payouts, delivering physical pack orders you request, reviewing reports and account deletion requests, and sending the notifications described below. We do not use a third-party analytics or advertising-tracking SDK in this app. We do not sell your information.'**
  String get privacySectionHowUsedBody;

  /// No description provided for @privacySectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get privacySectionNotifications;

  /// No description provided for @privacySectionNotificationsBody.
  ///
  /// In en, this message translates to:
  /// **'Jma3a sends notifications for things like game invites, room activity, friend requests, and messages. Push delivery is handled through OneSignal, a third-party notification service; some notifications are also scheduled directly on your device. You can manage notification permissions at any time from your device\'s system settings.'**
  String get privacySectionNotificationsBody;

  /// No description provided for @privacySectionPurchases.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get privacySectionPurchases;

  /// No description provided for @privacySectionPurchasesBody.
  ///
  /// In en, this message translates to:
  /// **'Some packs are paid, and Premium/Premium Plus are paid subscriptions. Verified Creators can publish packs and earn from them through an in-app wallet. Jma3a does not directly collect or store your full payment card details; payments are processed through the payment methods offered at checkout. Purchase and payout records (amounts, pack/subscription identifiers, and status) are kept as part of your account and creator history.'**
  String get privacySectionPurchasesBody;

  /// No description provided for @privacySectionUserContent.
  ///
  /// In en, this message translates to:
  /// **'User-Generated Content'**
  String get privacySectionUserContent;

  /// No description provided for @privacySectionUserContentBody.
  ///
  /// In en, this message translates to:
  /// **'Packs, cards, and other content you create and publish may be visible to other users as intended by the feature you used to create them (for example, a published pack in the marketplace). Chat messages you send in a room are visible to other members of that room. You are responsible for the content you choose to create and share.'**
  String get privacySectionUserContentBody;

  /// No description provided for @privacySectionAccountDeletion.
  ///
  /// In en, this message translates to:
  /// **'Account Deletion'**
  String get privacySectionAccountDeletion;

  /// No description provided for @privacySectionAccountDeletionBody.
  ///
  /// In en, this message translates to:
  /// **'You can request account deletion from Settings. This submits a request for review — your account is not deleted immediately. While a request is pending, you can cancel it from Settings and your account stays active. Once a request has been accepted and processed, deletion cannot be undone, and your profile, packs, wallet balance, and game history are permanently removed.'**
  String get privacySectionAccountDeletionBody;

  /// No description provided for @privacySectionThirdParty.
  ///
  /// In en, this message translates to:
  /// **'Third-Party Services'**
  String get privacySectionThirdParty;

  /// No description provided for @privacySectionThirdPartyBody.
  ///
  /// In en, this message translates to:
  /// **'Jma3a relies on a small number of third-party services to operate: our backend database and authentication provider, cloud object storage for images you upload (such as avatars and pack covers), and OneSignal for push notifications. These providers process data only as needed to provide their service to Jma3a.'**
  String get privacySectionThirdPartyBody;

  /// No description provided for @privacySectionContact.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get privacySectionContact;

  /// No description provided for @privacySectionContactBody.
  ///
  /// In en, this message translates to:
  /// **'If you have questions about this Privacy Policy or your information, contact us at {email}.'**
  String privacySectionContactBody(String email);

  /// No description provided for @termsConditionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditionsTitle;

  /// No description provided for @termsConditionsIntro.
  ///
  /// In en, this message translates to:
  /// **'These Terms & Conditions govern your use of Jma3a, a social multiplayer game app developed and operated by MOUJ TECH. By creating an account or using the app, you agree to these Terms.'**
  String get termsConditionsIntro;

  /// No description provided for @termsSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get termsSectionAccount;

  /// No description provided for @termsSectionAccountBody.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 13 years old to create a Jma3a account. You can sign up using a phone number or email address, which is verified with a one-time code. You are responsible for keeping your account credentials secure and for all activity on your account.'**
  String get termsSectionAccountBody;

  /// No description provided for @termsSectionAcceptableUse.
  ///
  /// In en, this message translates to:
  /// **'Acceptable Use'**
  String get termsSectionAcceptableUse;

  /// No description provided for @termsSectionAcceptableUseBody.
  ///
  /// In en, this message translates to:
  /// **'You agree to use Jma3a respectfully and not to harass, threaten, or abuse other users, impersonate others, or use the app for any unlawful purpose. Violations may result in content removal, feature restrictions, or account suspension.'**
  String get termsSectionAcceptableUseBody;

  /// No description provided for @termsSectionContent.
  ///
  /// In en, this message translates to:
  /// **'Your Content'**
  String get termsSectionContent;

  /// No description provided for @termsSectionContentBody.
  ///
  /// In en, this message translates to:
  /// **'You retain ownership of the content you create, such as your profile and any packs or cards you make. By posting content in Jma3a, you grant us the right to display and distribute it within the app so other users can see and interact with it. You are responsible for the content you create or share.'**
  String get termsSectionContentBody;

  /// No description provided for @termsSectionCreators.
  ///
  /// In en, this message translates to:
  /// **'Creators & Official Accounts'**
  String get termsSectionCreators;

  /// No description provided for @termsSectionCreatorsBody.
  ///
  /// In en, this message translates to:
  /// **'Jma3a offers Verified Creator status to eligible content creators, shown on their profile. Verified status may be granted or removed based on your account\'s standing and compliance with these Terms. An official Jma3a account may also appear in the app to share announcements and responses.'**
  String get termsSectionCreatorsBody;

  /// No description provided for @termsSectionRoomsGames.
  ///
  /// In en, this message translates to:
  /// **'Rooms & Games'**
  String get termsSectionRoomsGames;

  /// No description provided for @termsSectionRoomsGamesBody.
  ///
  /// In en, this message translates to:
  /// **'Jma3a lets you create or join rooms to play multiplayer games with friends and other players, using packs of content provided by Jma3a or created by users. Room hosts and members are expected to follow these Terms while playing.'**
  String get termsSectionRoomsGamesBody;

  /// No description provided for @termsSectionPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium & Premium Plus'**
  String get termsSectionPremium;

  /// No description provided for @termsSectionPremiumBody.
  ///
  /// In en, this message translates to:
  /// **'Jma3a offers optional Premium and Premium Plus subscriptions that unlock additional features and benefits within the app. What each tier includes may change over time; you will be shown what a subscription includes before you purchase it.'**
  String get termsSectionPremiumBody;

  /// No description provided for @termsSectionWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet & Payments'**
  String get termsSectionWallet;

  /// No description provided for @termsSectionWalletBody.
  ///
  /// In en, this message translates to:
  /// **'Jma3a includes an in-app wallet that can be topped up using supported local payment methods. Creators may earn wallet balance from their content and request withdrawals, subject to Jma3a\'s review. Payments are also subject to the terms of the payment method provider you use.'**
  String get termsSectionWalletBody;

  /// No description provided for @termsSectionModeration.
  ///
  /// In en, this message translates to:
  /// **'Reporting & Moderation'**
  String get termsSectionModeration;

  /// No description provided for @termsSectionModerationBody.
  ///
  /// In en, this message translates to:
  /// **'You can report or block other users and content that violates these Terms. Jma3a may review reports and take action, including removing content, restricting features, or suspending or terminating accounts that violate these Terms.'**
  String get termsSectionModerationBody;

  /// No description provided for @termsSectionTermination.
  ///
  /// In en, this message translates to:
  /// **'Suspension & Termination'**
  String get termsSectionTermination;

  /// No description provided for @termsSectionTerminationBody.
  ///
  /// In en, this message translates to:
  /// **'We may suspend or terminate your account if you violate these Terms, misuse the app, or engage in fraudulent or harmful behavior. You may also request deletion of your account and data at any time.'**
  String get termsSectionTerminationBody;

  /// No description provided for @termsSectionAvailability.
  ///
  /// In en, this message translates to:
  /// **'Service Availability'**
  String get termsSectionAvailability;

  /// No description provided for @termsSectionAvailabilityBody.
  ///
  /// In en, this message translates to:
  /// **'Jma3a is provided on an \"as available\" basis. We may modify, suspend, or discontinue parts of the app at any time, and we do not guarantee uninterrupted or error-free service.'**
  String get termsSectionAvailabilityBody;

  /// No description provided for @termsSectionChanges.
  ///
  /// In en, this message translates to:
  /// **'Changes to These Terms'**
  String get termsSectionChanges;

  /// No description provided for @termsSectionChangesBody.
  ///
  /// In en, this message translates to:
  /// **'We may update these Terms from time to time. Continuing to use Jma3a after changes are published means you accept the updated Terms.'**
  String get termsSectionChangesBody;

  /// No description provided for @termsSectionContact.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get termsSectionContact;

  /// No description provided for @termsSectionContactBody.
  ///
  /// In en, this message translates to:
  /// **'If you have questions about these Terms, contact us at {email}.'**
  String termsSectionContactBody(String email);

  /// No description provided for @accountSuspendedDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Suspended'**
  String get accountSuspendedDialogTitle;

  /// No description provided for @accountSuspendedUntil.
  ///
  /// In en, this message translates to:
  /// **'Your account has been suspended until {until}.'**
  String accountSuspendedUntil(String until);

  /// No description provided for @accountBannedPermanently.
  ///
  /// In en, this message translates to:
  /// **'Your account has been suspended from using Jma3a.'**
  String get accountBannedPermanently;

  /// No description provided for @appUpdateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get appUpdateAvailableTitle;

  /// No description provided for @appUpdateDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'A new version is available'**
  String get appUpdateDefaultTitle;

  /// No description provided for @appUpdateDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'Please update the app to continue enjoying the latest features.'**
  String get appUpdateDefaultMessage;

  /// No description provided for @appUpdateNowButton.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get appUpdateNowButton;

  /// No description provided for @appUpdateLaterButton.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get appUpdateLaterButton;

  /// No description provided for @appUpdateBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'A new version of Jma3a is available.'**
  String get appUpdateBannerMessage;

  /// No description provided for @deleteAccountReasonPrompt.
  ///
  /// In en, this message translates to:
  /// **'Why are you leaving?'**
  String get deleteAccountReasonPrompt;

  /// No description provided for @deleteAccountReasonNoLongerUse.
  ///
  /// In en, this message translates to:
  /// **'I no longer use the app'**
  String get deleteAccountReasonNoLongerUse;

  /// No description provided for @deleteAccountReasonPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy concerns'**
  String get deleteAccountReasonPrivacy;

  /// No description provided for @deleteAccountReasonFoundAnother.
  ///
  /// In en, this message translates to:
  /// **'Found another app'**
  String get deleteAccountReasonFoundAnother;

  /// No description provided for @deleteAccountReasonTooManyNotifications.
  ///
  /// In en, this message translates to:
  /// **'Too many notifications'**
  String get deleteAccountReasonTooManyNotifications;

  /// No description provided for @deleteAccountReasonTechnicalProblems.
  ///
  /// In en, this message translates to:
  /// **'Technical problems'**
  String get deleteAccountReasonTechnicalProblems;

  /// No description provided for @deleteAccountReasonTemporaryBreak.
  ///
  /// In en, this message translates to:
  /// **'Temporary break'**
  String get deleteAccountReasonTemporaryBreak;

  /// No description provided for @deleteAccountReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get deleteAccountReasonOther;

  /// No description provided for @deleteAccountReasonOtherHint.
  ///
  /// In en, this message translates to:
  /// **'Please tell us more (required)'**
  String get deleteAccountReasonOtherHint;

  /// No description provided for @deleteAccountReasonValidation.
  ///
  /// In en, this message translates to:
  /// **'Please select a reason'**
  String get deleteAccountReasonValidation;

  /// No description provided for @deleteAccountOtherDescriptionValidation.
  ///
  /// In en, this message translates to:
  /// **'Please describe your reason'**
  String get deleteAccountOtherDescriptionValidation;

  /// No description provided for @deleteAccountContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get deleteAccountContinueButton;

  /// No description provided for @tutHomeNavTitle.
  ///
  /// In en, this message translates to:
  /// **'Get around'**
  String get tutHomeNavTitle;

  /// No description provided for @tutHomeNavBody.
  ///
  /// In en, this message translates to:
  /// **'Switch between Rooms, Friends, the Marketplace and your Profile from here.'**
  String get tutHomeNavBody;

  /// No description provided for @tutBrowserCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a room'**
  String get tutBrowserCreateTitle;

  /// No description provided for @tutBrowserCreateBody.
  ///
  /// In en, this message translates to:
  /// **'Host your own room, pick a game and invite friends to play.'**
  String get tutBrowserCreateBody;

  /// No description provided for @tutBrowserJoinCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Join with a code'**
  String get tutBrowserJoinCodeTitle;

  /// No description provided for @tutBrowserJoinCodeBody.
  ///
  /// In en, this message translates to:
  /// **'Got an invite code? Enter it here to jump into a private room.'**
  String get tutBrowserJoinCodeBody;

  /// No description provided for @tutBrowserFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Find a game'**
  String get tutBrowserFilterTitle;

  /// No description provided for @tutBrowserFilterBody.
  ///
  /// In en, this message translates to:
  /// **'Filter public rooms by game type to find one that\'s open to join.'**
  String get tutBrowserFilterBody;

  /// No description provided for @tutCreateNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Name your room'**
  String get tutCreateNameTitle;

  /// No description provided for @tutCreateNameBody.
  ///
  /// In en, this message translates to:
  /// **'Give your room a name so friends can recognise it.'**
  String get tutCreateNameBody;

  /// No description provided for @tutCreateVisibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Public or private'**
  String get tutCreateVisibilityTitle;

  /// No description provided for @tutCreateVisibilityBody.
  ///
  /// In en, this message translates to:
  /// **'Public rooms show in Browse for everyone. Private rooms are invite-only.'**
  String get tutCreateVisibilityBody;

  /// No description provided for @tutCreateSpectatorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Spectators'**
  String get tutCreateSpectatorsTitle;

  /// No description provided for @tutCreateSpectatorsBody.
  ///
  /// In en, this message translates to:
  /// **'Let people watch without playing. Spectators never affect the game.'**
  String get tutCreateSpectatorsBody;

  /// No description provided for @tutCreateButtonTitle.
  ///
  /// In en, this message translates to:
  /// **'Create & host'**
  String get tutCreateButtonTitle;

  /// No description provided for @tutCreateButtonBody.
  ///
  /// In en, this message translates to:
  /// **'You become the host — you control the room and start the game.'**
  String get tutCreateButtonBody;

  /// No description provided for @tutLobbyManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your room'**
  String get tutLobbyManageTitle;

  /// No description provided for @tutLobbyManageBody.
  ///
  /// In en, this message translates to:
  /// **'As host you can close the room to new players, then reopen it later — without ending the game.'**
  String get tutLobbyManageBody;

  /// No description provided for @tutLobbyStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Start the game'**
  String get tutLobbyStartTitle;

  /// No description provided for @tutLobbyStartBody.
  ///
  /// In en, this message translates to:
  /// **'Only the host starts the game. Make sure everyone is ready first.'**
  String get tutLobbyStartBody;

  /// No description provided for @tutLobbyReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready up'**
  String get tutLobbyReadyTitle;

  /// No description provided for @tutLobbyReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap to tell the host you\'re ready. The game starts once everyone is.'**
  String get tutLobbyReadyBody;

  /// No description provided for @tutMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage players'**
  String get tutMembersTitle;

  /// No description provided for @tutMembersBody.
  ///
  /// In en, this message translates to:
  /// **'As host, tap a player to mute, kick or ban them. Muting stops them acting; kicking removes them; banning blocks their return.'**
  String get tutMembersBody;

  /// No description provided for @tutTodTitle.
  ///
  /// In en, this message translates to:
  /// **'Truth or Dare'**
  String get tutTodTitle;

  /// No description provided for @tutTodBody.
  ///
  /// In en, this message translates to:
  /// **'The current player is shown here. They pick Truth or Dare and complete it, then play passes on.'**
  String get tutTodBody;

  /// No description provided for @tutNhieTitle.
  ///
  /// In en, this message translates to:
  /// **'Your turn to answer'**
  String get tutNhieTitle;

  /// No description provided for @tutNhieBody.
  ///
  /// In en, this message translates to:
  /// **'Read the statement, then cast your answer below. Results show once everyone has answered.'**
  String get tutNhieBody;

  /// No description provided for @tutNhieSpectatorBody.
  ///
  /// In en, this message translates to:
  /// **'Read along and watch how everyone answers — spectators don\'t vote.'**
  String get tutNhieSpectatorBody;

  /// No description provided for @tutMemeTitle.
  ///
  /// In en, this message translates to:
  /// **'React to the meme'**
  String get tutMemeTitle;

  /// No description provided for @tutMemeBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a reaction or sticker for this meme and submit. The funniest picks win the round.'**
  String get tutMemeBody;

  /// No description provided for @tutReplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Replay tutorials'**
  String get tutReplayTitle;

  /// No description provided for @tutReplaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show the in-app guides again'**
  String get tutReplaySubtitle;

  /// No description provided for @tutReplayDone.
  ///
  /// In en, this message translates to:
  /// **'Tutorials reset — you\'ll see them again as you go.'**
  String get tutReplayDone;

  /// No description provided for @lobbyAnonymousSpectator.
  ///
  /// In en, this message translates to:
  /// **'Anonymous spectator'**
  String get lobbyAnonymousSpectator;

  /// No description provided for @packIssuesHeader.
  ///
  /// In en, this message translates to:
  /// **'Fix these before submitting:'**
  String get packIssuesHeader;

  /// No description provided for @packIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a name for every selected language'**
  String get packIssueTitle;

  /// No description provided for @packIssueCards.
  ///
  /// In en, this message translates to:
  /// **'Add at least 20 cards'**
  String get packIssueCards;

  /// No description provided for @packIssueLanguage.
  ///
  /// In en, this message translates to:
  /// **'Every card needs content in all selected languages'**
  String get packIssueLanguage;

  /// No description provided for @packIssuePrice.
  ///
  /// In en, this message translates to:
  /// **'Set a price of at least {min} MRU'**
  String packIssuePrice(int min);

  /// No description provided for @packIssueBalance.
  ///
  /// In en, this message translates to:
  /// **'Truth or Dare packs need an equal number of Truth and Dare cards'**
  String get packIssueBalance;

  /// No description provided for @packIssuePunishments.
  ///
  /// In en, this message translates to:
  /// **'Add at least 10 punishments, or remove them all'**
  String get packIssuePunishments;

  /// No description provided for @packIssueTerms.
  ///
  /// In en, this message translates to:
  /// **'Accept the Pack Creation Terms'**
  String get packIssueTerms;

  /// No description provided for @packIssuePlayerRange.
  ///
  /// In en, this message translates to:
  /// **'Maximum players must be at least the minimum'**
  String get packIssuePlayerRange;

  /// No description provided for @packTermsAgreePrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get packTermsAgreePrefix;

  /// No description provided for @packTermsAgreeLink.
  ///
  /// In en, this message translates to:
  /// **'Pack Creation Terms'**
  String get packTermsAgreeLink;

  /// No description provided for @packTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pack Creation Terms'**
  String get packTermsTitle;

  /// No description provided for @packTermsBody.
  ///
  /// In en, this message translates to:
  /// **'By submitting a pack you confirm that: you own or have the right to share all content; the content does not infringe anyone\'s rights or contain illegal, hateful, or harassing material; you accept Jma3a\'s content review and may have the pack rejected or removed; and paid packs are subject to the platform\'s revenue and refund policies. Packs must meet the minimum price and, for Truth or Dare, contain an equal number of Truth and Dare cards.'**
  String get packTermsBody;

  /// No description provided for @packMinPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum price is {min} MRU'**
  String packMinPriceLabel(int min);

  /// No description provided for @packTruthDareBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'Truth or Dare packs need equal Truth and Dare cards. You have {truth} Truth and {dare} Dare.'**
  String packTruthDareBalanceHint(int truth, int dare);

  /// No description provided for @exploreAddFriend.
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get exploreAddFriend;

  /// No description provided for @exploreEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Check back soon — new people join the discovery pool as the community grows.'**
  String get exploreEmptyHint;

  /// No description provided for @exploreEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No one to discover yet'**
  String get exploreEmptyTitle;

  /// No description provided for @exploreLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load people to discover.'**
  String get exploreLoadFailed;

  /// No description provided for @exploreRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request Sent'**
  String get exploreRequestSent;

  /// No description provided for @exploreSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by username or name…'**
  String get exploreSearchHint;

  /// No description provided for @exploreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover players ranked by reputation'**
  String get exploreSubtitle;

  /// No description provided for @exploreTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get exploreTabLabel;

  /// No description provided for @honestyReasonHint.
  ///
  /// In en, this message translates to:
  /// **'What made this feel dishonest? (minimum 3 characters)'**
  String get honestyReasonHint;

  /// No description provided for @honestyReasonSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Why wasn\'t this honest?'**
  String get honestyReasonSheetTitle;

  /// No description provided for @honestyReasonsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 player marked this dishonest} other{{count} players marked this dishonest}}'**
  String honestyReasonsCount(int count);

  /// No description provided for @profileStreakActive.
  ///
  /// In en, this message translates to:
  /// **'Streak active'**
  String get profileStreakActive;

  /// No description provided for @profileStreakInactive.
  ///
  /// In en, this message translates to:
  /// **'Streak inactive — play today to keep it going'**
  String get profileStreakInactive;

  /// No description provided for @officialResponsesTitle.
  ///
  /// In en, this message translates to:
  /// **'Official Responses'**
  String get officialResponsesTitle;

  /// No description provided for @officialResponsesReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get officialResponsesReviews;

  /// No description provided for @officialResponsesWarnings.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get officialResponsesWarnings;

  /// No description provided for @officialResponsesBansAndSuspensions.
  ///
  /// In en, this message translates to:
  /// **'Bans & Suspensions'**
  String get officialResponsesBansAndSuspensions;

  /// No description provided for @officialResponsesRequestsAndDecisions.
  ///
  /// In en, this message translates to:
  /// **'Requests & Decisions'**
  String get officialResponsesRequestsAndDecisions;

  /// No description provided for @officialResponsesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get officialResponsesEmpty;

  /// No description provided for @officialResponseExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String officialResponseExpiresOn(String date);

  /// No description provided for @walletDepositsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Deposits are temporarily unavailable.'**
  String get walletDepositsUnavailable;

  /// No description provided for @walletWithdrawalsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Withdrawals are temporarily unavailable.'**
  String get walletWithdrawalsUnavailable;

  /// No description provided for @walletFinanceServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Finance service temporarily unavailable'**
  String get walletFinanceServiceUnavailable;

  /// No description provided for @authIdentifierLabel.
  ///
  /// In en, this message translates to:
  /// **'Email or phone number'**
  String get authIdentifierLabel;

  /// No description provided for @authIdentifierHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com or 12345678'**
  String get authIdentifierHint;

  /// No description provided for @authIdentifierRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or phone number'**
  String get authIdentifierRequired;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordHint;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get authPasswordTooShort;

  /// No description provided for @authPasswordTooLong.
  ///
  /// In en, this message translates to:
  /// **'Password must be at most 72 characters'**
  String get authPasswordTooLong;

  /// No description provided for @authPasswordNeedsLetterAndDigit.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one letter and one digit'**
  String get authPasswordNeedsLetterAndDigit;

  /// No description provided for @authPasswordConfirmationLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authPasswordConfirmationLabel;

  /// No description provided for @authPasswordConfirmationHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get authPasswordConfirmationHint;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get authPasswordMismatch;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get authLogIn;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email/phone or password.'**
  String get authInvalidCredentials;

  /// No description provided for @authSetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a password'**
  String get authSetPasswordTitle;

  /// No description provided for @authSetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a password so you can log in without a code next time'**
  String get authSetPasswordSubtitle;

  /// No description provided for @authSetPasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Start playing'**
  String get authSetPasswordSubmit;

  /// No description provided for @authResetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get authResetPasswordTitle;

  /// No description provided for @authResetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password for your account'**
  String get authResetPasswordSubtitle;

  /// No description provided for @authResetPasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authResetPasswordSubmit;

  /// No description provided for @authPasswordSetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password set successfully'**
  String get authPasswordSetSuccess;

  /// No description provided for @authPasswordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully'**
  String get authPasswordResetSuccess;

  /// No description provided for @authForgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get authForgotPasswordTitle;

  /// No description provided for @authForgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or phone number and we\'ll send you a code'**
  String get authForgotPasswordSubtitle;

  /// No description provided for @authForgotPasswordSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get authForgotPasswordSendCode;

  /// No description provided for @authBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get authBackToLogin;

  /// No description provided for @authMethodPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get authMethodPhone;

  /// No description provided for @authMethodPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'+222 ...'**
  String get authMethodPhoneHint;

  /// No description provided for @authMethodEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authMethodEmail;

  /// No description provided for @authMethodEmailHint.
  ///
  /// In en, this message translates to:
  /// **'name@email.com'**
  String get authMethodEmailHint;

  /// No description provided for @authSignupTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Jma3a 🎉'**
  String get authSignupTitle;

  /// No description provided for @authSignupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How would you like to sign up?'**
  String get authSignupSubtitle;

  /// No description provided for @authContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authContinue;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authAlreadyHaveAccount;

  /// No description provided for @authPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter your 8-digit Mauritanian number'**
  String get authPhoneInvalid;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back 👋'**
  String get authWelcomeBack;

  /// No description provided for @authReadyToPlay.
  ///
  /// In en, this message translates to:
  /// **'Ready to play?'**
  String get authReadyToPlay;

  /// No description provided for @authLegacyNoPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'No password yet'**
  String get authLegacyNoPasswordTitle;

  /// No description provided for @authLegacyNoPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'This account doesn\'t have a password yet. Verify with a one-time code to create one.'**
  String get authLegacyNoPasswordBody;

  /// No description provided for @authVerifyWithOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify with OTP'**
  String get authVerifyWithOtp;

  /// No description provided for @authDontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authDontHaveAccount;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @passwordSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Password & Security'**
  String get passwordSettingsTitle;

  /// No description provided for @passwordSettingsUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get passwordSettingsUpdateTitle;

  /// No description provided for @passwordSettingsUpdateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change your password securely.'**
  String get passwordSettingsUpdateSubtitle;

  /// No description provided for @passwordSettingsVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify Current Password'**
  String get passwordSettingsVerifyButton;

  /// No description provided for @passwordSettingsChangeButton.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get passwordSettingsChangeButton;

  /// No description provided for @passwordSettingsOtpNotice.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a verification code to confirm it\'s you before applying this change.'**
  String get passwordSettingsOtpNotice;

  /// No description provided for @passwordSettingsCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get passwordSettingsCurrentLabel;

  /// No description provided for @passwordSettingsNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get passwordSettingsNewLabel;

  /// No description provided for @passwordSettingsConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get passwordSettingsConfirmLabel;

  /// No description provided for @passwordSettingsNoPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordSettingsNoPasswordTitle;

  /// No description provided for @passwordSettingsNoPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t set a password yet.'**
  String get passwordSettingsNoPasswordBody;

  /// No description provided for @passwordSettingsHasPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Your password is set.'**
  String get passwordSettingsHasPasswordBody;

  /// No description provided for @passwordSettingsSetButton.
  ///
  /// In en, this message translates to:
  /// **'Set password with OTP'**
  String get passwordSettingsSetButton;

  /// No description provided for @passwordSettingsChangeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordSettingsChangeSuccess;

  /// No description provided for @settingsPassword.
  ///
  /// In en, this message translates to:
  /// **'Password & Security'**
  String get settingsPassword;

  /// No description provided for @settingsPasswordSubtitleReady.
  ///
  /// In en, this message translates to:
  /// **'Tap to change your password'**
  String get settingsPasswordSubtitleReady;

  /// No description provided for @settingsPasswordSubtitleNotSet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t set a password yet'**
  String get settingsPasswordSubtitleNotSet;

  /// No description provided for @authAccountAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this phone/email already exists. Please log in.'**
  String get authAccountAlreadyExists;
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
