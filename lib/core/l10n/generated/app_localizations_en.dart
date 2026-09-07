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
  String get introSkip => 'Skip';

  @override
  String get introNext => 'Next';

  @override
  String get introGetStarted => 'Get Started';

  @override
  String get introPage1Title => 'Welcome to Jma3a';

  @override
  String get introPage1Body =>
      'Multiplayer party games — play with friends and family, anytime, anywhere.';

  @override
  String get introPage2Title => 'Discover Packs';

  @override
  String get introPage2Body =>
      'Community-created packs, premium packs, and physical packs you can order and play with.';

  @override
  String get introPage3Title => 'Create or Join Rooms';

  @override
  String get introPage3Body =>
      'Public rooms, private rooms, invite codes — play with friends however you like.';

  @override
  String get introPage4Title => 'Premium Features';

  @override
  String get introPage4Body =>
      'Custom themes, backgrounds, exclusive features, and tools built for creators.';

  @override
  String get introPage5Title => 'Ready to Play';

  @override
  String get introPage5Body =>
      'Everything\'s set. Let\'s get the party started.';

  @override
  String get settingsReplayIntro => 'Replay Introduction';

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
  String get back => 'Back';

  @override
  String get skip => 'Skip';

  @override
  String get remove => 'Remove';

  @override
  String get no => 'No';

  @override
  String get or => 'or';

  @override
  String get optional => 'Optional';

  @override
  String get error => 'Something went wrong';

  @override
  String get errorNetwork => 'Network error. Please check your connection.';

  @override
  String get errorUnexpected =>
      'An unexpected error occurred. Please try again.';

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
  String get authOtpLabel => 'Verification code';

  @override
  String get authOtpVerify => 'Verify';

  @override
  String get authOtpResend => 'Resend code';

  @override
  String authOtpResendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get authOtpInvalid => 'Invalid code. Please try again.';

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
  String get settingsOnlineStatus => 'Online Status';

  @override
  String get settingsOnlineStatusPremiumHint =>
      'Manual status is a Premium feature';

  @override
  String get presenceModeAuto => 'Auto';

  @override
  String get presenceModeOnline => 'Online';

  @override
  String get presenceModeOffline => 'Offline';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsSignOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsVersionLabel => 'Version';

  @override
  String get settingsSigningOut => 'Signing out…';

  @override
  String get premiumBackgroundCustomSet => 'Custom background set';

  @override
  String get premiumBackgroundChooseColor => 'Choose a background color';

  @override
  String get premiumBackgroundUpgradeHint => 'Premium feature — tap to upgrade';

  @override
  String get premiumBackgroundSaveFailed => 'Could not save background color.';

  @override
  String get premiumBackgroundResetFailed =>
      'Could not reset background color.';

  @override
  String get roomsTitle => 'Rooms';

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
  String roomsInvitedByName(String name) {
    return 'Invited by $name';
  }

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
  String get lobbyTitle => 'Lobby';

  @override
  String get lobbyReady => 'Ready';

  @override
  String get lobbyNotReady => 'Not ready';

  @override
  String get lobbyStartGame => 'Start game';

  @override
  String get lobbyStartGameFailed =>
      'Couldn\'t start the game — please try again.';

  @override
  String get lobbyGameStarting => 'Preparing the game…';

  @override
  String get lobbyGameStartingBody =>
      'Please wait while the game is being prepared.';

  @override
  String get lobbyCopied => 'Code copied!';

  @override
  String get lobbyLeaveConfirm => 'Are you sure you want to leave?';

  @override
  String lobbyPlayerLeft(String name) {
    return '$name left';
  }

  @override
  String get chatPlaceholder => 'Say something…';

  @override
  String get chatMuted => 'You are muted';

  @override
  String get gameSettings => 'Game settings';

  @override
  String get gameSettingsTurnTimer => 'Turn timer';

  @override
  String get gameSettingsAllowSkip => 'Allow skip';

  @override
  String get gameSettingsMaxRounds => 'Max rounds';

  @override
  String gameSettingsMaxRoundsCapHint(int cap) {
    return 'Maximum $cap rounds — this pack has $cap usable cards and every card is used at most once per game.';
  }

  @override
  String gameSettingsSeconds(int n) {
    return '${n}s';
  }

  @override
  String get gameReconnecting => 'Reconnecting…';

  @override
  String get gameConnectionLost => 'Connection lost';

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
  String moderationYouWereKickedBy(String name) {
    return '$name removed you from the room';
  }

  @override
  String moderationYouWereBannedBy(String name) {
    return '$name banned you from the room';
  }

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get walletEarningsTotal => 'Total earned';

  @override
  String get walletEarningsThisMonth => 'This month';

  @override
  String get walletEarningsTotalSales => 'Total sales';

  @override
  String get walletTransactionHistory => 'Transaction history';

  @override
  String get walletFilterAll => 'All';

  @override
  String get walletFilterDeposits => 'Deposits';

  @override
  String get walletFilterWithdrawals => 'Withdrawals';

  @override
  String get walletFilterPurchases => 'Purchases';

  @override
  String get walletFilterEarnings => 'Earnings';

  @override
  String get walletFilterRefunds => 'Refunds';

  @override
  String get walletFilterPayouts => 'Payouts';

  @override
  String get walletFilterBonuses => 'Bonuses';

  @override
  String get walletFilterAdjustments => 'Adjustments';

  @override
  String get walletFilterTransfers => 'Transfers';

  @override
  String get walletTypeDeposit => 'Deposit';

  @override
  String get walletTypeWithdrawal => 'Withdrawal';

  @override
  String get walletTypePurchase => 'Pack Purchase';

  @override
  String get walletTypeRefund => 'Refund';

  @override
  String get walletTypeCommission => 'Creator Earnings';

  @override
  String get walletTypePayout => 'Payout';

  @override
  String get walletTypeAdjustment => 'Adjustment';

  @override
  String get walletTypeBonus => 'Bonus';

  @override
  String get walletTypeTransfer => 'Balance Transfer';

  @override
  String get walletStatusPending => 'Pending';

  @override
  String get walletStatusProcessing => 'Processing';

  @override
  String get walletStatusCompleted => 'Completed';

  @override
  String get walletStatusFailed => 'Failed';

  @override
  String get walletStatusCancelled => 'Cancelled';

  @override
  String get walletStatusReversed => 'Reversed';

  @override
  String get walletDepositStatusPending => 'Pending';

  @override
  String get walletDepositStatusUnderReview => 'Under Review';

  @override
  String get walletDepositStatusApproved => 'Approved';

  @override
  String get walletDepositStatusRejected => 'Rejected';

  @override
  String get profileGames => 'Games';

  @override
  String get profileScore => 'Score';

  @override
  String get profileHonestyPoints => 'Honesty Points';

  @override
  String get honestyVoteHonest => 'Honest';

  @override
  String get honestyVoteNotHonest => 'Not honest';

  @override
  String get honestyVoteRecorded => 'Your vote was recorded';

  @override
  String get honestyVoteFailed => 'Couldn\'t submit your vote — try again';

  @override
  String profileStreakDays(int count) {
    return '$count-day streak';
  }

  @override
  String get profileFriends => 'Friends';

  @override
  String get profilePacks => 'Packs';

  @override
  String get profileFollowers => 'Followers';

  @override
  String get streakNewTitle => 'New Streak!';

  @override
  String get streakNewBody =>
      'You started a new streak! Keep playing every day to make it bigger.';

  @override
  String get streakNewCta => 'Let\'s go!';

  @override
  String streakExtendedTitle(int count) {
    return 'Streak extended! $count days in a row!';
  }

  @override
  String streakExtendedBody(int count) {
    return '$count days in a row! You\'re on fire 🔥';
  }

  @override
  String get streakExtendedCta => 'Continue';

  @override
  String get profileShareAction => 'Share Profile';

  @override
  String profileShareMessage(String name, String link) {
    return '🎮 Join me on Jma3a! Follow $name\n\n$link';
  }

  @override
  String profileShareSubject(String name) {
    return '🎮 $name on Jma3a';
  }

  @override
  String get profileShareCardCta => 'Tap to view my Jma3a profile';

  @override
  String get gameSettingsSpicy => 'Spicy cards';

  @override
  String get gameSettingsRequireApproval => 'Require approval to join';

  @override
  String get gameSettingsAllowSpectators => 'Allow spectators';

  @override
  String get lobbyApprove => 'Approve';

  @override
  String get lobbyReject => 'Reject';

  @override
  String get authUseEmailInstead => 'Use email instead';

  @override
  String get authUsePhoneInstead => 'Use phone instead';

  @override
  String get authContinueAsGuest => 'Continue as Guest';

  @override
  String get authTermsPrivacyNotice =>
      'By continuing you agree to our Terms & Privacy Policy';

  @override
  String authOtpAttemptsRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts remaining',
      one: '$count attempt remaining',
    );
    return '$_temp0';
  }

  @override
  String get authTakingLonger => 'Taking longer than usual…';

  @override
  String get authContinueWithoutSigningIn => 'Continue without signing in';

  @override
  String get required => 'Required';

  @override
  String get onboardingGenderLabel => 'Gender';

  @override
  String get onboardingGenderMale => 'Male';

  @override
  String get onboardingGenderFemale => 'Female';

  @override
  String get onboardingGenderRequired => 'Please select your gender';

  @override
  String get onboardingAgeLabel => 'Age';

  @override
  String get onboardingAgeHint => 'Your age (13+)';

  @override
  String get onboardingAgeRequired => 'Age is required';

  @override
  String get onboardingAgeInvalid => 'Enter a valid age';

  @override
  String get onboardingAgeTooYoung => 'You must be at least 13 years old';

  @override
  String get onboardingDisplayNameTooShort => 'At least 2 characters';

  @override
  String get onboardingDisplayNameTooLong => 'Maximum 50 characters';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageFrench => 'Français';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get chatTabLabel => 'Chat';

  @override
  String get checking => 'Checking…';

  @override
  String get defaultPlayerName => 'A player';

  @override
  String get deny => 'Deny';

  @override
  String get errorConnectionFailed => 'Connection failed';

  @override
  String get invited => 'Invited';

  @override
  String get kick => 'Kick';

  @override
  String get leave => 'Leave';

  @override
  String get ok => 'OK';

  @override
  String get muted => 'Muted';

  @override
  String get sending => 'Sending…';

  @override
  String get unban => 'Unban';

  @override
  String get unmute => 'Unmute';

  @override
  String get moderationYouWereBanned => 'You were banned';

  @override
  String lobbyAddAsFriend(String name) {
    return 'Add $name as friend';
  }

  @override
  String get lobbyAllRequestsDecided => 'All requests have been decided.';

  @override
  String lobbyAreFriends(String name) {
    return 'You and $name are friends ✓';
  }

  @override
  String get lobbyAutoLetInOnceApproved =>
      'You\'ll be let in automatically once they approve.';

  @override
  String lobbyBanReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get lobbyBannedSectionTitle => '🚫 Banned';

  @override
  String lobbyCannotSendRequest(String name) {
    return 'Cannot send request to $name';
  }

  @override
  String get lobbyCloseRoomBody => 'Closing the room will remove all players.';

  @override
  String get lobbyCloseRoomConfirm => 'Close Room';

  @override
  String get lobbyCloseRoomTitle => 'Close Room?';

  @override
  String get lobbyCloseKeepGameTitle => 'Close this room?';

  @override
  String get lobbyCloseKeepGameBody =>
      'The room will disappear from Browse and no new players can join. Anyone already playing keeps playing — the game isn\'t interrupted, and the room isn\'t deleted.';

  @override
  String get lobbyCloseKeepGameConfirm => 'Close Room';

  @override
  String get lobbyCloseKeepGameCta => 'Close Room';

  @override
  String get lobbyRoomClosedForNewPlayers =>
      'The host closed the room to new players.';

  @override
  String get lobbyReopenTitle => 'Reopen this room?';

  @override
  String get lobbyReopenBody =>
      'The room will accept new players again and reappear in Browse. Nothing else changes — the room isn\'t recreated and no game is reset.';

  @override
  String get lobbyReopenConfirm => 'Reopen Room';

  @override
  String get lobbyReopenCta => 'Reopen Room';

  @override
  String get lobbySelectPackBeforeStart =>
      'Please select a pack before starting the game.';

  @override
  String lobbyRejoinDecisionFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String get premiumErrorInsufficientBalance =>
      'Not enough balance. Please top up your wallet first.';

  @override
  String get premiumErrorWalletNotFound =>
      'Wallet not found. Please contact support.';

  @override
  String get premiumErrorWalletFrozen =>
      'Your wallet is frozen. Please contact support.';

  @override
  String get premiumErrorInvalidPlan => 'Invalid plan selected.';

  @override
  String get premiumErrorDowngradeBlocked =>
      'You can switch plans once your current subscription expires.';

  @override
  String premiumErrorPurchaseFailed(String error) {
    return 'Purchase failed: $error';
  }

  @override
  String get lobbyRoomReopened => 'Room reopened — new players can join again.';

  @override
  String get lobbyCouldNotSendRequest => 'Could not send request — try again';

  @override
  String get lobbyDeselectAll => 'Deselect all';

  @override
  String get lobbyFriendRequestPending => 'Friend request pending';

  @override
  String lobbyFriendRequestSent(String name) {
    return 'Friend request sent to $name ✅';
  }

  @override
  String lobbyHiddenAnonymousCount(int count) {
    return '+ $count anonymous (visible to mods only)';
  }

  @override
  String get lobbyHowToJoin => 'How do you want to join?';

  @override
  String lobbyInviteCount(int count) {
    return 'Invite $count';
  }

  @override
  String get lobbyInviteFriendsTitle => '👥 Invite Friends';

  @override
  String get lobbyJoinRequestSentTitle => 'Join Request Sent';

  @override
  String lobbyKickSpectatorBody(String name) {
    return 'Remove $name from the room.';
  }

  @override
  String get lobbyKickSpectatorTitle => 'Kick spectator?';

  @override
  String get lobbyLeaveRoomTitle => 'Leave Room?';

  @override
  String get lobbyModerationTitle => '⚖️ Moderation';

  @override
  String get lobbyMutedSectionTitle => '🔇 Muted';

  @override
  String lobbyNoFriendsMatchQuery(String query) {
    return 'No friends match \"$query\"';
  }

  @override
  String get lobbyNoFriendsToInvite => 'No friends to invite yet.';

  @override
  String get lobbyNoMutedOrBanned => 'No muted or banned players.';

  @override
  String get lobbyNoVisibleSpectators => 'No visible spectators';

  @override
  String get lobbySpectatorsSection => 'Spectators';

  @override
  String lobbyPermissionsFor(String name) {
    return 'Permissions for $name';
  }

  @override
  String get lobbyPermissionsHint => 'Owners can adjust these at any time.';

  @override
  String lobbyRejoinRequestsCount(int count) {
    return 'Rejoin Requests ($count)';
  }

  @override
  String get lobbyRoomClosedBody => 'The host closed the room.';

  @override
  String get lobbyRoomClosedTitle => 'Room Closed';

  @override
  String get lobbySearchFriendsHint => 'Search friends…';

  @override
  String get lobbySelectAll => 'Select all';

  @override
  String get lobbySelectPackToStart => 'Select a pack in settings to start';

  @override
  String get lobbyShareInviteLink => 'Share invite link';

  @override
  String lobbyShareInviteMessage(String code, String link) {
    return '🎮 Join my Jma3a room!\n\nCode: $code\n\n$link';
  }

  @override
  String lobbyShareInviteSubject(String code) {
    return '🎮 Jma3a Code: $code';
  }

  @override
  String get lobbySpectateWatchHint =>
      'These players want to watch the game as spectators.';

  @override
  String lobbySpectatorRequestCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spectator requests',
      one: '$count spectator request',
    );
    return '$_temp0';
  }

  @override
  String get lobbySpectatorRequestsTitle => 'Spectator Requests';

  @override
  String lobbySpectatorsCount(int count) {
    return 'Spectators ($count)';
  }

  @override
  String get lobbyWaitingForHostApproval =>
      'Waiting for the host to approve your request to join.';

  @override
  String get lobbyWantsToRejoin => 'Wants to rejoin the game';

  @override
  String get lobbyWantsToSpectate => 'Wants to spectate';

  @override
  String get lobbyYouAreHost => 'You are the host';

  @override
  String get lobbyYouAreNowOwner => 'You\'re now the room owner 👑';

  @override
  String get defaultPackName => 'Pack';

  @override
  String get gameNameAll => 'All';

  @override
  String get gameNameMeme => 'Meme Game';

  @override
  String get gameNameNeverHaveIEver => 'Never Have I';

  @override
  String get gameNameTruthOrDare => 'Truth or Dare';

  @override
  String get gameSettingsChooseProofViewers =>
      'Choose exactly who can see proof';

  @override
  String gameSettingsMemberLabelSpectator(String name) {
    return '$name (spec)';
  }

  @override
  String get gameSettingsNoPacksDevMsg =>
      'No packs available. Run the seed SQL in Supabase.';

  @override
  String get gameSettingsPackPunishments => 'Pack punishments';

  @override
  String get gameSettingsPlayersSubmit => 'Players submit';

  @override
  String get gameSettingsProofCustom => 'Custom';

  @override
  String get gameSettingsProofEveryone => 'Everyone';

  @override
  String get gameSettingsProofPlayers => 'Players';

  @override
  String get gameSettingsProofSpectators => 'Spectators';

  @override
  String get gameSettingsProofVisibility => 'Proof visibility';

  @override
  String get gameSettingsPunishmentHintDefault =>
      'When a player skips, every other player submits a punishment and the skipped player picks one to do.';

  @override
  String get gameSettingsPunishmentHintPackAvailable =>
      'This pack includes its own punishments. Choose who provides them when a player skips.';

  @override
  String get gameSettingsPunishmentMode => 'Punishment mode';

  @override
  String get gameSettingsSelectPack => 'Select Pack';

  @override
  String get packSituationFilterTitle => 'What are you looking for?';

  @override
  String get packSituationFilterSubtitle =>
      'Optional — pick a mood and we\'ll surface the best-fitting packs first.';

  @override
  String get packBestMatchTitle => 'BEST MATCH FOR YOU';

  @override
  String get packOtherPacksTitle => 'OTHER PACKS';

  @override
  String get packMatchedLabel => 'Matched';

  @override
  String get packTagRelationship => 'Relationship';

  @override
  String get packTagBreakup => 'Breakup';

  @override
  String get packTagFixingRelationship => 'Fixing relationship';

  @override
  String get packTagDating => 'Dating';

  @override
  String get packTagCouples => 'Couples';

  @override
  String get packTagFriendship => 'Friendship';

  @override
  String get packTagFamily => 'Family';

  @override
  String get packTagParty => 'Party';

  @override
  String get packTagIcebreaker => 'Icebreaker';

  @override
  String get packTagWork => 'Work';

  @override
  String get packTagTravel => 'Travel';

  @override
  String get packTagLateNight => 'Late night';

  @override
  String get packCreationTagsTitle => 'Types (optional)';

  @override
  String get packCreationTagsSubtitle =>
      'Help players find this pack for the right moment.';

  @override
  String get none => 'None';

  @override
  String get roleLabelPlayer => 'Player';

  @override
  String get roleLabelSpectator => 'Spectator';

  @override
  String roomsActiveRoomOpenBody(String name) {
    return 'Your room \"$name\" is still open. Return to it, or close it to create a new one.';
  }

  @override
  String roomsActiveRoomPausedBody(String name) {
    return 'Your room \"$name\" is paused. Return to it, or close it to create a new one.';
  }

  @override
  String get roomsActiveRoomTitle => 'You already have an active room';

  @override
  String get roomsAllowSpectators => 'Allow Spectators';

  @override
  String get roomsAllowSpectatorsHint => 'Others can watch without playing';

  @override
  String roomsAlreadyInRoomBody(String name) {
    return 'You\'re still in \"$name\". You can\'t be a player or spectator in two rooms at once — return to it, or leave it for good to join this one instead.';
  }

  @override
  String get roomsAlreadyInRoomTitle => 'You\'re already in a room';

  @override
  String roomsBanConfirm(String name) {
    return 'Ban $name from this room?';
  }

  @override
  String get roomsBrowsePacks => 'Browse Packs';

  @override
  String get roomsCloseAndCreateNew =>
      'Close Existing Room and Create New Room';

  @override
  String get roomsClosedSnackbar => 'Room closed';

  @override
  String roomsDailyLimitFreeBody(int basicLimit, int premiumLimit) {
    return 'Free plan allows $basicLimit rooms per day. Try again tomorrow, or upgrade to Premium for $premiumLimit rooms/day.';
  }

  @override
  String roomsDailyLimitPremiumBody(int premiumLimit) {
    return 'Premium plan allows $premiumLimit rooms per day. Try again tomorrow.';
  }

  @override
  String get roomsDailyLimitTitle => 'Daily limit reached';

  @override
  String get roomsCreationTooSoonTitle => 'Not yet';

  @override
  String roomsCreationTooSoonBody(int hours, int minutes) {
    return 'You can create your next room in ${hours}h ${minutes}m.';
  }

  @override
  String get roomsDuration => 'Duration';

  @override
  String roomsDurationLabel(String duration) {
    return 'Duration: $duration';
  }

  @override
  String roomsGameLabel(String game) {
    return 'Game: $game';
  }

  @override
  String get roomsIconFree => 'Free';

  @override
  String get roomsIconPremium => 'Premium ✦';

  @override
  String get roomsLeaveForGood => 'Leave for good';

  @override
  String get roomsLeftTheGame => 'Left the game';

  @override
  String get roomsMutedInGame => 'Muted — watching only';

  @override
  String get roomsWaitingForGameApproval => 'Waiting for game approval';

  @override
  String get roomsMaxPlayers => 'Max players';

  @override
  String roomsMaxPlayersLabel(String count) {
    return 'Max players: $count';
  }

  @override
  String roomsModPermissionsCount(int count) {
    return 'MOD · $count';
  }

  @override
  String get roomsMyClosedRooms => 'My Closed Rooms';

  @override
  String get roomsNameHint => 'e.g. Friday Night Fun';

  @override
  String get roomsNameLabel => 'Room name';

  @override
  String get roomsNameTooLong => 'Maximum 60 characters';

  @override
  String get roomsNameTooShort => 'At least 3 characters';

  @override
  String get roomsNoClosedRooms => 'No rooms closed in the last 5 days.';

  @override
  String get roomsNoGameData => 'No game data available.';

  @override
  String get roomsNoPacksBody =>
      'You need at least one pack to create a room — get a free pack or purchase one from the marketplace first.';

  @override
  String get roomsNoPacksTitle => 'No packs available';

  @override
  String roomsParticipantsCount(int count) {
    return 'Participants ($count)';
  }

  @override
  String roomsPlayedLabel(String date) {
    return 'Played: $date';
  }

  @override
  String roomsPlayedPacksCount(int count) {
    return 'Played Packs ($count)';
  }

  @override
  String get roomsRequestSentBody =>
      'Your join request has been sent. You\'ll be notified once the host approves it.';

  @override
  String get roomsRequestSentTitle => 'Request Sent!';

  @override
  String get roomsRequireJoinApproval => 'Require Join Approval';

  @override
  String get roomsRequireJoinApprovalHint => 'You approve each request to join';

  @override
  String get roomsRequireSpectatorApproval => 'Require Spectator Approval';

  @override
  String get roomsRequireSpectatorApprovalHint =>
      'You approve each request to spectate, separately from player join approval';

  @override
  String get roomsResults => 'Results';

  @override
  String get roomsReturnToMyRoom => 'Return to My Room';

  @override
  String get roomsRoomIcon => 'Room Icon';

  @override
  String get roomsRoomInfo => 'Room Info';

  @override
  String roomsStillInRoomBody(String name) {
    return 'You\'re still in \"$name\". Leave it before creating a new room.';
  }

  @override
  String roomsSupportsUpToPlayers(int count) {
    return 'Your room supports up to $count players';
  }

  @override
  String get roomsTransferOwnership => 'Transfer ownership';

  @override
  String get roomsUpgradeArrow => 'Upgrade →';

  @override
  String get roomsVisibility => 'Visibility';

  @override
  String roomsWinnerLabel(String name) {
    return '🏆 Winner: $name';
  }

  @override
  String get gameNameNeverHaveIEverFull => 'Never Have I Ever';

  @override
  String get defaultGameName => 'Game';

  @override
  String get chatDisabledForRoom => 'Chat is disabled for this room';

  @override
  String get chatNoMessagesYet => 'No messages yet';

  @override
  String get chatSayHint => 'Say something…';

  @override
  String get chatSendFailed => 'Message failed to send — tap send to try again';

  @override
  String chatReplyingTo(String name) {
    return 'Replying to $name';
  }

  @override
  String get chatCancelReply => 'Cancel reply';

  @override
  String get chatAudienceEveryone => 'Everyone';

  @override
  String chatAudienceOnly(String names) {
    return 'Only: $names';
  }

  @override
  String get chatAudiencePickerTitle => 'Who can see this message?';

  @override
  String get chatAudienceSelectPeople => 'Select people';

  @override
  String get chatAudienceNoOneAvailable =>
      'No one else is available to select right now.';

  @override
  String get chatAudienceApply => 'Done';

  @override
  String chatTargetedIndicatorSender(String names) {
    return 'Only visible to $names';
  }

  @override
  String get chatTargetedIndicatorRecipient =>
      'Sent only to you and select people';

  @override
  String get chatAudienceRequiresPremiumPlus =>
      'Only Premium Plus members can target specific people.';

  @override
  String get chatAudienceRecipientUnavailable =>
      'One of the selected people is no longer available.';

  @override
  String get chatAudienceNoLongerRoomMember =>
      'You are no longer part of this room/game.';

  @override
  String get failed => 'Failed';

  @override
  String get photo => 'Photo';

  @override
  String get premiumBadge => '✨ Premium';

  @override
  String get preview => 'Preview';

  @override
  String todActivityAnswering(String name) {
    return '$name is answering…';
  }

  @override
  String todActivityChoosing(String name) {
    return '$name is choosing…';
  }

  @override
  String todActivityFinishingUp(String name) {
    return '$name is finishing up…';
  }

  @override
  String todActivityPerforming(String name) {
    return '$name is performing…';
  }

  @override
  String todActivityUploadingProof(String name) {
    return '$name is uploading proof…';
  }

  @override
  String get todAddCardToDeck => 'Add Card to Deck';

  @override
  String get todAddCustomCardButton => 'Add custom card';

  @override
  String get todAddCustomCardTitle => 'Add Custom Card';

  @override
  String get todAddDescriptionOptional => 'Add a description (optional)…';

  @override
  String get todAnswerRequiredHint => 'Your answer is required…';

  @override
  String todChoosingTruthOrDare(String name) {
    return '$name is choosing Truth or Dare…';
  }

  @override
  String get todCompleteTurn => 'Complete Turn';

  @override
  String get todCompletedTurn => 'completed their turn!';

  @override
  String get todCustomCardAdded => '✅ Custom card added to deck!';

  @override
  String get todCustomCardSessionOnly =>
      'This card will be added to the deck for this session only.';

  @override
  String get todDare => 'Dare';

  @override
  String todDefaultPlayerNumbered(String id) {
    return 'Player $id';
  }

  @override
  String get todDifficultyLabel => 'Difficulty';

  @override
  String get todDoneButton => 'Done! ✅';

  @override
  String get todEndGame => 'End Game';

  @override
  String get todEndGameBody => 'This will end the game for all players.';

  @override
  String get todEndGameTitle => 'End Game?';

  @override
  String todLikedResponseVotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '👍 Liked this response ($count votes)',
      one: '👍 Liked this response ($count vote)',
    );
    return '$_temp0';
  }

  @override
  String get todNextTurn => 'Next Turn →';

  @override
  String get todNoCardAvailable => 'No card available — all cards used!';

  @override
  String todPointsAbbrev(int points) {
    return '$points pts';
  }

  @override
  String todQuotedResponse(String response) {
    return '\"$response\"';
  }

  @override
  String get todProofTimerLabel => 'Viewing duration';

  @override
  String get todProofTimerNoLimit => 'No limit';

  @override
  String get todProofVisibilityLabel => 'Who can see this?';

  @override
  String get todProofVisibilityEveryone => 'Everyone';

  @override
  String get todProofVisibilityPlayersOnly => 'Players only';

  @override
  String get todProofVisibilitySpectatorsOnly => 'Spectators only';

  @override
  String get todProofVisibilityPersonalized => 'Personalized';

  @override
  String get todProofVisibilityNoOneElse => 'No one else is in the room yet.';

  @override
  String get todProofVisibilityPickAtLeastOne => 'Pick at least one person.';

  @override
  String get todReactLabel => 'React:';

  @override
  String get todReadyForNextTurn => 'I\'m Ready for Next Turn';

  @override
  String get todReadyWaitingHost =>
      '✓ You\'re ready — waiting for the host to continue…';

  @override
  String get todRecording => 'Recording…';

  @override
  String get todSkipTurnMod => 'Skip turn (mod)';

  @override
  String get todSpectatingWaitingHost =>
      'Spectating — waiting for the host to continue…';

  @override
  String get todSpicyBadge => '🌶 SPICY';

  @override
  String get todStopRecording => 'Stop Recording';

  @override
  String get todSubmitCompleteTurn => 'Submit & Complete Turn ✅';

  @override
  String get todTruth => 'Truth';

  @override
  String get todChooseYourChallenge => 'Choose your challenge';

  @override
  String todPlayerIsChoosing(String name) {
    return '$name is choosing…';
  }

  @override
  String get todTruthChoiceDescription =>
      'Answer a personal question honestly.';

  @override
  String get todDareChoiceDescription => 'Complete a daring challenge.';

  @override
  String get todSkipCardConfirmTitle => 'Skip this card?';

  @override
  String get todSkipCardConfirmBody =>
      'Skipping may result in a group punishment vote.';

  @override
  String get todStatRounds => 'Rounds';

  @override
  String get todStatPlayers => 'Players';

  @override
  String get todStatTotalTurns => 'Total Turns';

  @override
  String get todDareBadge => 'DARE';

  @override
  String get todTruthBadge => 'TRUTH';

  @override
  String get nhieBadgeAllCaps => 'NEVER HAVE I EVER';

  @override
  String get memeBadgeAllCaps => 'MEME PROMPT';

  @override
  String get memePickStickerFirst => 'Pick a sticker first';

  @override
  String get memeSubmitResponseButton => 'Submit Response';

  @override
  String get gameNotStartedYet => 'Game not started yet';

  @override
  String get gameNotReady => 'Game not ready';

  @override
  String get todTruthRequiresResponse => 'Truth requires a response';

  @override
  String get todDareRequiresResponseOrProof =>
      'Add a description or attach proof before continuing';

  @override
  String get todProofVoteRequiresVoice =>
      'The group voted for voice proof — record one to continue';

  @override
  String get todProofVoteRequiresImage =>
      'The group voted for photo proof — attach one to continue';

  @override
  String get todTypeDare => '🔥 Dare';

  @override
  String get todTypeTruth => '🤔 Truth';

  @override
  String todVoiceMaxSeconds(int n) {
    return 'Voice (max ${n}s)';
  }

  @override
  String get todVoiceProofRecorded => 'Voice proof recorded';

  @override
  String get todVoiceProofTitle => 'Voice Proof';

  @override
  String todVotedForResponseTotal(int count) {
    return '✓ You voted for this response ($count total)';
  }

  @override
  String todWaitingForToFinishReading(String names) {
    return 'Waiting for $names to finish reading…';
  }

  @override
  String get todWriteCardPromptHint => 'Write your card prompt…';

  @override
  String get someone => 'Someone';

  @override
  String get todAllPlayersLeftGameBody => 'All players left the game.';

  @override
  String get todAllPlayersLeftGameEnded => 'All players left — game ended';

  @override
  String get todChatTitle => '💬 Chat';

  @override
  String get todGameEnded => 'Game Ended';

  @override
  String get todGameOver => 'Game Over';

  @override
  String get todGamePausedTitle => 'Game Paused';

  @override
  String get todGoToLobby => 'Go to Lobby';

  @override
  String todHistoryRoundsCount(int count) {
    return 'History ($count rounds)';
  }

  @override
  String get todHostEndedGame => 'The host ended the game';

  @override
  String get todHostEndedGameBody => 'The host ended the game.';

  @override
  String get todHostSteppedAway =>
      'The host stepped away and will\nreturn shortly.';

  @override
  String get todLeaveForNow => 'Leave for Now';

  @override
  String get todNoRoundsYet => 'No rounds completed yet.';

  @override
  String todPlayerLeftGame(String name) {
    return '👋 $name left the game';
  }

  @override
  String get todForcePunishmentTooltip => 'Force this punishment';

  @override
  String get todPunishmentModeOn => 'Punishment mode ON';

  @override
  String get todQuitGame => 'Quit Game';

  @override
  String get todQuitGameBody => 'Leave the current game?';

  @override
  String get todQuitGameTitle => 'Quit Game?';

  @override
  String get todRemovedFromGame => 'You were removed from this game';

  @override
  String todRoundTypeContent(String type, String content) {
    return '$type: $content';
  }

  @override
  String todScreenshotTaken(String name) {
    return '📸 $name took a screenshot';
  }

  @override
  String get todSkipped => 'Skipped';

  @override
  String todProofWatchedByCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Proof watched by $count',
      zero: 'Proof sent — not watched yet',
    );
    return '$_temp0';
  }

  @override
  String todReplayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count replays',
      one: '$count replay',
      zero: 'No replays yet',
    );
    return '$_temp0';
  }

  @override
  String todVoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '👍 $count votes',
      one: '👍 $count vote',
    );
    return '$_temp0';
  }

  @override
  String get todYouAreNowHost => '👑 You are now the game host!';

  @override
  String get secAbbrev => 'sec';

  @override
  String get submit => 'Submit';

  @override
  String get todConfigTitle => 'Truth or Dare Setup';

  @override
  String get todConfigSubtitle =>
      'Configure this game before it starts — you won\'t be able to change it once it begins.';

  @override
  String get todConfigForceDareTitle => 'Force Dare Rules';

  @override
  String get todConfigForceDareUnlimited => 'Unlimited';

  @override
  String get todConfigForceDarePerPlayer => 'Per Player';

  @override
  String get todConfigForceDarePerTurn => 'Per Turn';

  @override
  String get todConfigMaxTruths => 'Max Truths';

  @override
  String get todConfigCardRepetitionTitle => 'Card Repetition';

  @override
  String get todConfigCardRepetitionShuffle => 'Shuffle Continuously';

  @override
  String get todConfigCardRepetitionUnique => 'Unique Cards';

  @override
  String todConfigUniqueCardsCapHint(int count) {
    return 'This pack has $count cards — Max Rounds can\'t exceed what\'s available once each card is used at most once per player\'s turn.';
  }

  @override
  String get todConfigConfirmStart => 'Confirm & Start';

  @override
  String get gameSettingsPackAlreadyPlayed =>
      'This pack has already been played in this room. Choose a different pack.';

  @override
  String get todForcedDareHint =>
      'You\'ve used up your Truths for now — Dare only.';

  @override
  String get todEndReasonDefault => 'Game finished';

  @override
  String get todEndReasonManual => 'Game ended by host';

  @override
  String get todEndReasonRoundLimit => 'All rounds completed';

  @override
  String get todEndReasonScoreLimit => 'Score limit reached';

  @override
  String get todEndReasonCardsExhausted => 'All unique cards have been used';

  @override
  String get todEveryoneElsePickingPunishment =>
      'Everyone else is picking a punishment for you.';

  @override
  String get todGameOverBang => 'Game Over!';

  @override
  String get todLeaderboard => 'Leaderboard';

  @override
  String get todLoadingGame => 'Loading game…';

  @override
  String todWaitingForPlayers(int ready, int total) {
    return 'Waiting for other players to join… ($ready/$total ready)';
  }

  @override
  String get hostReconnectWaitingTitle => 'Waiting for host to reconnect…';

  @override
  String hostReconnectWaitingBody(int seconds) {
    return 'The game is paused. It will end automatically in ${seconds}s if the host doesn\'t come back.';
  }

  @override
  String todOnlyPlayerCanPick(String name) {
    return 'Only $name can pick — a moderator can force one if they\'re unresponsive.';
  }

  @override
  String get todPhaseChoosing => 'Choosing';

  @override
  String get todPhaseCompleting => 'Completing…';

  @override
  String get todPhaseInProgress => 'In Progress';

  @override
  String get todPhaseVoting => '⚠️ Voting';

  @override
  String todPlayerSkipped(String name) {
    return '$name skipped!';
  }

  @override
  String todRoundBadge(int round, int maxRound) {
    return 'Round $round / $maxRound';
  }

  @override
  String todSubmitPunishmentFor(String name) {
    return 'Submit one punishment for $name:';
  }

  @override
  String todSubmittedCount(int submitted, int expected) {
    return '$submitted / $expected submitted';
  }

  @override
  String get todSubmittedWaitingForOthers =>
      'Submitted — waiting for everyone else…';

  @override
  String get todTimeForPunishment => 'Time for a punishment…';

  @override
  String get todWaitingChoosingQuestion => 'Truth or Dare?';

  @override
  String todWinnerWins(String name) {
    return '$name wins!';
  }

  @override
  String get todYouSkipped => 'You skipped…';

  @override
  String errorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get nhieAddCommentOptional => 'Add a comment (optional)…';

  @override
  String nhieAnsweredCount(int count, int total) {
    return '$count/$total answered';
  }

  @override
  String get nhieCardPromptHint => 'Never have I ever…';

  @override
  String get nhieCardTitle => 'Never Have I Ever…';

  @override
  String nhieDrinksScore(int count) {
    return '$count 🍹';
  }

  @override
  String nhieDrinksTotal(int count) {
    return '🍹 $count';
  }

  @override
  String get nhieGameHistoryTitle => 'Game History';

  @override
  String get nhieGoToHome => 'Go to Home';

  @override
  String get gameBackToRoom => 'Back to Room';

  @override
  String get nhieIHave => 'I HAVE';

  @override
  String get nhieMostDrinksWins => 'Most 🍹 drinks wins!';

  @override
  String get nhieNever => 'NEVER';

  @override
  String get nhieTimedOut => 'Time\'s up — you didn\'t respond in time';

  @override
  String get nhieNextCard => 'Next Card →';

  @override
  String get nhiePlayAnotherHandOff => 'Play Another & Hand Off';

  @override
  String get nhieReadyForNextRound => 'I\'m Ready for Next Round';

  @override
  String nhieViewHistoryCount(int count) {
    return 'View History ($count rounds)';
  }

  @override
  String nhieWaitingCount(int count, int total) {
    return 'Waiting… $count/$total';
  }

  @override
  String get nhieWaitingForPlayersReady => 'Waiting for players to be ready…';

  @override
  String get nhieWhoTakesOver => 'Who takes over?';

  @override
  String get memeAddCaptionOptional => 'Add a caption (optional)…';

  @override
  String get memeCustomPromptSessionOnly =>
      'This prompt will be added to the deck for this session only.';

  @override
  String get memeFunniestPlayerWins => 'Funniest player wins!';

  @override
  String get memeNextRound => 'Next Round →';

  @override
  String get memePassVote => 'Skip — Ready for Next Round';

  @override
  String get memePickSticker => 'Pick your sticker:';

  @override
  String memePlayersVoted(int count, int total) {
    return '$count/$total players voted';
  }

  @override
  String memeResponseNumber(int n) {
    return 'Response #$n';
  }

  @override
  String get memeResponseSubmittedWaiting =>
      'Response submitted! Waiting for others…';

  @override
  String memeRoundBadgeAllCaps(int round) {
    return 'ROUND $round';
  }

  @override
  String memeRoundResultsTitle(int round) {
    return 'Round $round Results 🏆';
  }

  @override
  String get memeSpectatingWaitingSubmit =>
      'Spectating — waiting for players to submit…';

  @override
  String memeSubmittedCount(int submitted, int total) {
    return '$submitted / $total submitted';
  }

  @override
  String get memeTapAnywhereToClose => 'Tap anywhere to close';

  @override
  String get memeTapToExpand => 'Tap to expand';

  @override
  String get memeTapToSeeReaction => 'Tap to see their reaction';

  @override
  String get memeTie => 'Tie';

  @override
  String memeTrophyScore(int count) {
    return '$count 🏆';
  }

  @override
  String get memeVoteForBest => 'Vote for the best! 😂';

  @override
  String get memeVoteForThis => 'Vote for this 👍';

  @override
  String get memeVotedWaiting => 'Voted! Waiting for others…';

  @override
  String memeVotesAbbrev(int count) {
    return '$count 👍';
  }

  @override
  String memeVotesCount(int count, int total) {
    return '$count / $total voted';
  }

  @override
  String memeWinnerLabel(String name) {
    return 'Winner: $name';
  }

  @override
  String get memeWinsThisRound => 'wins this round!';

  @override
  String get memeWritePromptHint => 'Write your meme prompt…';

  @override
  String get memeYourResponse => 'Your response';

  @override
  String get memeYourVote => '✓ Your vote';

  @override
  String get exit => 'Exit';

  @override
  String get offlineAcceptChallenge => 'Accept the challenge';

  @override
  String get offlineAddCaptionOptional => 'Add a caption (optional)…';

  @override
  String get offlineAddProofPhoto => 'Add proof photo (view once)';

  @override
  String get offlineAnswerHonestly => 'Answer honestly';

  @override
  String get offlineBackToMenu => 'Back to Menu';

  @override
  String get offlineChooseYourFate => 'Choose your fate';

  @override
  String get offlineCompleteTurnCheck => 'Complete Turn ✅';

  @override
  String offlineCompletedName(String name) {
    return '$name completed!';
  }

  @override
  String offlineCouldNotPickImage(String error) {
    return 'Could not pick image: $error';
  }

  @override
  String get offlineDareLabel => 'DARE';

  @override
  String get offlineDoneCheck => '✓ Done';

  @override
  String get offlineFinalScores => 'Final Scores';

  @override
  String get offlineGameHistoryTitle => '📖 Game History';

  @override
  String get offlineGameOverTrophy => 'Game Over 🏆';

  @override
  String offlineGameTypeAndPack(String gameType, String packName) {
    return '$gameType • $packName';
  }

  @override
  String offlineGoodOneVotes(int count) {
    return '👍 Good one! ($count)';
  }

  @override
  String get offlineHistoryTab => '📖 History';

  @override
  String offlineIsDeciding(String name) {
    return '$name is deciding…';
  }

  @override
  String get offlineKickConfirmBody => 'They will be removed from the lobby.';

  @override
  String offlineKickConfirmTitle(String name) {
    return 'Kick $name?';
  }

  @override
  String get offlineMemeBadge => '😂  MEME';

  @override
  String get offlineMemeChampion => 'Meme Champion!';

  @override
  String offlineMyVoteCount(String voteLabel, int count, int total) {
    return '$voteLabel ($count/$total)';
  }

  @override
  String get offlineNeverHaveIEverBadge => 'NEVER HAVE I EVER…';

  @override
  String get offlineNextTurnShort => 'Next Turn';

  @override
  String get offlineNoHistoryAvailable => 'No history available';

  @override
  String get offlineNoRoundsCompleted => 'No rounds completed yet';

  @override
  String get offlineNoTurnsCompleted => 'No turns completed yet';

  @override
  String get offlinePackCover => 'Pack cover';

  @override
  String get offlinePickFavourite => 'Pick your favourite:';

  @override
  String get offlinePickReaction => 'Pick a reaction:';

  @override
  String get offlinePickReactionColon => 'Pick your reaction:';

  @override
  String offlinePlayersCount(int count) {
    return '$count players';
  }

  @override
  String get offlinePlayersInLobby => 'PLAYERS IN LOBBY';

  @override
  String get offlinePreviousCards => 'Previous Cards';

  @override
  String get offlineProofViewed => '📷 Proof viewed';

  @override
  String offlineRoundColonCaption(int round, String caption) {
    return 'Round $round: $caption';
  }

  @override
  String offlineRoundOf(int round, int maxRounds) {
    return 'Round $round of $maxRounds';
  }

  @override
  String get offlineSayHiToGroup => 'Say hi to the group!';

  @override
  String get offlineScoresTab => '🏆 Scores';

  @override
  String get offlineSkippedCross => '✗ Skipped';

  @override
  String offlineSubmissionTitle(String name) {
    return '$name\'s submission';
  }

  @override
  String offlineSubmitCount(int count, int total) {
    return 'Submit ($count/$total)';
  }

  @override
  String get offlineSubmitExclaim => 'Submit!';

  @override
  String get offlineSubmittedWaitingCheck => '✅ Submitted! Waiting for others…';

  @override
  String get offlineTapAgainToDismiss => 'Tap again to dismiss';

  @override
  String get offlineTapToDismiss => 'Tap to dismiss';

  @override
  String get offlineTapToRevealProof => 'Tap to reveal proof photo';

  @override
  String offlineTimerSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get offlineTruthLabel => 'TRUTH';

  @override
  String offlineVoteCountBallot(int count) {
    return '$count 🗳️';
  }

  @override
  String get offlineVoteForBestNoEmoji => 'Vote for the best!';

  @override
  String offlineVotesExclaim(String name) {
    return '$name votes!';
  }

  @override
  String get offlineWaitingForHost => 'Waiting for host…';

  @override
  String get offlineWaitingForHostToStart => 'Waiting for host to start…';

  @override
  String offlineWaitingForMore(int count) {
    return 'Waiting for $count more…';
  }

  @override
  String get offlineWaitingHostAdvance => 'Waiting for host to advance…';

  @override
  String get ptsSuffix => ' pts';

  @override
  String get gameLabel => 'Game';

  @override
  String get offlineBulletDownloadedPacks =>
      'Downloaded packs work fully offline — no internet needed.';

  @override
  String get offlineBulletLan =>
      'LAN: each player on their own phone, same WiFi or hotspot.';

  @override
  String get offlineBulletPassPlay =>
      'Pass & Play: one phone, pass between players each turn.';

  @override
  String get offlineChooseMode => 'Choose mode';

  @override
  String get offlineCreateLanRoomHint => 'Create a LAN room on your device';

  @override
  String get offlineDiscard => 'Discard';

  @override
  String get offlineDownloadPackFirst => 'Download a pack first to host';

  @override
  String get offlineEnable18Cards => 'Enable 18+ cards';

  @override
  String get offlineEnterNameAboveToJoin => 'Enter your name above to join';

  @override
  String get offlineEnterNameToJoin => 'Enter your name to join';

  @override
  String get offlineFailedToStart => 'Failed to start';

  @override
  String get offlineFindNearbyLanRooms => 'Find nearby LAN rooms to join';

  @override
  String get offlineGoBack => 'Go back';

  @override
  String get offlineHostBadge => 'HOST';

  @override
  String get offlineHostRoom => 'Host a room';

  @override
  String offlineHostsRoom(String name) {
    return '$name\'s Room';
  }

  @override
  String get offlineHowItWorks => 'ℹ️  How offline works';

  @override
  String get offlineJoinLanRoomTitle => 'Join LAN Room';

  @override
  String get offlineJoinRoom => 'Join a room';

  @override
  String get offlineJoinRoomButton => 'Join Room';

  @override
  String get offlineLanMultiplayer => 'LAN Multiplayer';

  @override
  String get offlineLanRoom => 'LAN Room';

  @override
  String get offlineLoadingCards => 'Loading cards…';

  @override
  String get offlineNearbyRooms => 'Nearby rooms';

  @override
  String offlineNoPacksDownloaded(String gameType) {
    return 'No $gameType packs downloaded. Go online to download packs.';
  }

  @override
  String get offlineOtherPlayersJoinInstructions =>
      'Other players: open Jma3a → Play → LAN → Join Room';

  @override
  String offlinePackExpiry(int day, int month) {
    return 'Exp: $day/$month';
  }

  @override
  String offlinePackMeta(int count, String lang, String status) {
    return '$count cards · $lang · $status';
  }

  @override
  String offlinePackPlayersCount(String packName, int count) {
    return '$packName · $count players';
  }

  @override
  String get offlinePlayTitle => 'Offline Play';

  @override
  String offlinePlayersCountDash(int count) {
    return 'Players — $count';
  }

  @override
  String get offlineResume => 'Resume';

  @override
  String get offlineResumeGame => 'Resume game';

  @override
  String get offlineRoomBroadcasting => 'Room is broadcasting';

  @override
  String offlineRoomMeta(String gameType, String packName, int count, int max) {
    return '$gameType • $packName • $count/$max players';
  }

  @override
  String offlineRoundsSlider(int count) {
    return 'Rounds: $count';
  }

  @override
  String get offlineSameWifiHint =>
      'Make sure host device is on the same WiFi.';

  @override
  String get offlineScanningForRooms => 'Scanning for rooms…';

  @override
  String get offlineSetupFailed => 'Setup failed.';

  @override
  String get offlineSignInToDownload =>
      'Sign in to download packs and unlock all games.';

  @override
  String get offlineSpicyContent => 'Spicy content';

  @override
  String offlineTimerSecsLabel(int secs) {
    return 'Timer: ${secs}s';
  }

  @override
  String get offlineYourName => 'Your name';

  @override
  String get purchased => 'Purchased';

  @override
  String get signIn => 'Sign In';

  @override
  String get tryAgain => 'Try again';

  @override
  String get accountLabel => 'Account';

  @override
  String get amountLabel => 'Amount';

  @override
  String get copiedNotice => 'Copied!';

  @override
  String labelColonSuffix(String label) {
    return '$label: ';
  }

  @override
  String get nameLabel => 'Name';

  @override
  String get pendingLabel => 'Pending';

  @override
  String get phoneInvalid => 'Phone number must be exactly 8 digits';

  @override
  String get refresh => 'Refresh';

  @override
  String get seeAll => 'See all';

  @override
  String get walletAmountToWithdraw => 'Amount to withdraw';

  @override
  String walletAmountValue(String amount) {
    return 'Amount: $amount MRU';
  }

  @override
  String walletAvailableAmount(String amount) {
    return 'Available: $amount';
  }

  @override
  String get walletAvailableEarnings => 'Available earnings';

  @override
  String get walletAvailableForWithdrawal => 'Available for withdrawal';

  @override
  String get walletBackToWallet => 'Back to Wallet';

  @override
  String get walletBalanceAfter => 'Balance after';

  @override
  String get walletBulletCreditedAfterConfirm =>
      'Earnings are credited after purchase is confirmed.';

  @override
  String get walletBulletEarn85 => 'You earn 85% of every pack sale.';

  @override
  String get walletBulletMinWithdrawal => 'Minimum withdrawal: 500 MRU.';

  @override
  String get walletBulletPlatformFee => '15% platform fee keeps Jma3a running.';

  @override
  String get walletChooseHowToAddFunds => 'Choose how you want to add funds.';

  @override
  String get walletConfirmWithdrawal => 'Confirm Withdrawal';

  @override
  String get walletCreateSellPacksHint =>
      'Create and sell packs to earn commissions.';

  @override
  String get walletCreatorEarningsRateLabel => 'Creator earnings rate';

  @override
  String get walletCreatorEarningsTitle => 'Creator Earnings';

  @override
  String get walletCurrencyName => 'Mauritanian Ouguiya';

  @override
  String get walletDeposit => 'Deposit';

  @override
  String walletDepositAmount(String amount) {
    return 'Deposit $amount';
  }

  @override
  String get walletDepositWarningNotice =>
      'Only submit after completing the transfer. Deposits are manually reviewed and may take 1–24 hours.';

  @override
  String get walletEarningsBalance => 'Earnings Balance';

  @override
  String get walletEnterReference => 'Enter the reference from your payment';

  @override
  String get walletHowEarningsWork => 'How earnings work';

  @override
  String get walletInsufficientBalance => 'Insufficient balance';

  @override
  String get walletMaxDeposit => 'Maximum deposit: 1,000,000 MRU';

  @override
  String get walletMethodLabel => 'Method';

  @override
  String get walletMinDeposit => 'Minimum deposit: 100 MRU';

  @override
  String walletMinWithdrawal(int amount) {
    return 'Minimum withdrawal: $amount MRU';
  }

  @override
  String get walletNoEarningsYet => 'No earnings yet';

  @override
  String get walletNoTransactions => 'No transactions';

  @override
  String get walletNoTransactionsYet => 'No transactions yet';

  @override
  String walletOfEveryPackSale(int fee) {
    return 'of every pack sale ($fee% platform fee)';
  }

  @override
  String get walletPaymentReferenceLabel =>
      'Payment reference / transaction ID';

  @override
  String get walletPhoneNumberHint => '8-digit phone number';

  @override
  String get walletPayoutPhoneNumber => 'Payout phone number';

  @override
  String get walletPhoneLabel => 'Phone';

  @override
  String get walletRecentTransactions => 'Recent Transactions';

  @override
  String get walletReferenceHint => 'e.g. TXN123456789';

  @override
  String get walletSelectPaymentMethod => 'Select payment method';

  @override
  String get walletSelectPayoutMethod => 'Select payout method';

  @override
  String walletStatusPaymentMethod(String status, String method) {
    return '$status • $method';
  }

  @override
  String get walletTitle => 'Wallet';

  @override
  String get walletDepositSubmittedTitle => 'Deposit Submitted!';

  @override
  String walletDepositSubmittedSubtitle(String amount) {
    return 'Your deposit of $amount is under review. Balance will update once approved.';
  }

  @override
  String get walletDepositRequestFailed => 'Deposit request failed.';

  @override
  String get walletSubmitDeposit => 'Submit Deposit';

  @override
  String get walletWithdrawalSubmittedTitle => 'Withdrawal Submitted!';

  @override
  String walletWithdrawalSubmittedSubtitle(String amount) {
    return 'Your withdrawal of $amount is being processed. Funds will arrive within 1–24 hours.';
  }

  @override
  String get walletWithdrawalRequestFailed => 'Withdrawal request failed.';

  @override
  String get walletContinueArrow => 'Continue →';

  @override
  String get walletActionDeposit => 'Deposit';

  @override
  String get walletActionWithdraw => 'Withdraw';

  @override
  String get walletActionEarnings => 'Earnings';

  @override
  String get walletDetailDateTime => 'Date & time';

  @override
  String get walletDetailWalletAffected => 'Wallet affected';

  @override
  String get walletDetailEarnings => 'Earnings';

  @override
  String get walletDetailWalletBalance => 'Wallet Balance';

  @override
  String get walletDetailBalanceAfter => 'Balance after';

  @override
  String get walletDetailPaymentMethod => 'Payment method';

  @override
  String get walletDetailDescription => 'Description';

  @override
  String get walletDetailReference => 'Reference';

  @override
  String get walletDetailTransactionId => 'Transaction ID';

  @override
  String walletDetailDateAtTime(String date, String time) {
    return '$date at $time';
  }

  @override
  String get walletTransferAmount => 'Transfer amount';

  @override
  String get walletTransferButton => 'Transfer';

  @override
  String get walletTransferFailed => 'Transfer failed.';

  @override
  String get walletTransferSuccess => 'Transferred to wallet balance.';

  @override
  String get walletTransferToWallet => 'Transfer to Wallet';

  @override
  String get walletTransferToWalletBalance => 'Transfer to Wallet Balance';

  @override
  String get walletWithdraw => 'Withdraw';

  @override
  String walletWithdrawalAmount(String amount) {
    return 'Withdrawal $amount';
  }

  @override
  String get walletWithdrawalProcessingNotice =>
      'Withdrawals are processed manually. Funds arrive in 1–24 hours once approved.';

  @override
  String get walletYourPhoneNumber => 'Your phone number';

  @override
  String get actionLabel => 'Action';

  @override
  String get activeLabel => 'Active';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get getButton => 'Get';

  @override
  String get lightMode => 'Light mode';

  @override
  String get premiumAppThemeTitle => 'App Theme';

  @override
  String get premiumAutoRenewNotice =>
      'Subscriptions auto-renew unless cancelled 24h before renewal.';

  @override
  String get premiumBackgroundColorEmoji => 'Background Color ✦';

  @override
  String get premiumBackgroundColorTitle => 'Background Color';

  @override
  String get premiumBlendsIntoTheme =>
      'Blends into your selected theme — text, cards, and icons adapt automatically.';

  @override
  String premiumCannotDowngradeBody(String date) {
    return 'You have an active Premium Plus subscription. You can switch to a lower plan once it expires on $date.';
  }

  @override
  String get premiumCannotDowngradeTitle => 'Cannot Downgrade Yet';

  @override
  String get premiumCardTextReadable => 'Card text stays readable';

  @override
  String get premiumChooseAvatar => 'Choose Avatar';

  @override
  String get premiumChooseBackground => 'Choose a background';

  @override
  String get premiumConfirmPurchase => 'Confirm Purchase';

  @override
  String get premiumCurrentTermEnds => 'your current term ends';

  @override
  String get premiumFeatureColumnHeader => 'Feature';

  @override
  String get premiumFeatureListDescription =>
      'Custom themes & avatars, 15 rooms/day, up to 12 players per room, 10 offline packs (1 free), anonymous chat, and more.';

  @override
  String get premiumLockedUntilExpires => 'Locked until Premium Plus expires';

  @override
  String get premiumMonthly => 'Monthly';

  @override
  String get premiumPageBackground => 'Page background';

  @override
  String premiumPlanActivated(String plan) {
    return '🎉 $plan activated!';
  }

  @override
  String get premiumPlusLabel => 'Premium Plus';

  @override
  String get premiumPlusShort => 'Plus';

  @override
  String get premiumPremiumAvatars => 'Premium Avatars';

  @override
  String get premiumPremiumThemes => 'Premium Themes ✦';

  @override
  String premiumPricePerPeriod(String price, String period) {
    return '$price / $period';
  }

  @override
  String premiumPurchaseConfirmBody(
    String plan,
    String planPrice,
    String period,
  ) {
    return 'This will deduct $planPrice from your wallet balance.\n\nPlan: $plan — $planPrice/$period';
  }

  @override
  String premiumPurchasePlan(String plan) {
    return 'Purchase $plan';
  }

  @override
  String get premiumSave33 => 'Save 33%';

  @override
  String get premiumTitle => 'Premium';

  @override
  String get premiumUnlockTitle => 'Unlock Premium';

  @override
  String get premiumUpgradeToUnlock => 'Upgrade to unlock';

  @override
  String get premiumWhatYouGet => 'What you get';

  @override
  String get premiumYearly => 'Yearly';

  @override
  String get premiumYourAvatars => 'Your Avatars';

  @override
  String get premiumYourThemes => 'Your Themes';

  @override
  String get resetToDefault => 'Reset to Default';

  @override
  String get continueArrow => 'Continue →';

  @override
  String get continueLabel => 'Continue';

  @override
  String get noneLabel => 'None';

  @override
  String get packAddFirstCardHint => 'Add your first card above!';

  @override
  String get packAddImages => 'Add Images';

  @override
  String packAddMoreMinimum(int count) {
    return 'Add $count more (minimum 10) or remove them all.';
  }

  @override
  String packAdditionalFeeBody(int fee) {
    return 'This pack has extra cards, which requires an additional fee of $fee MRU to submit for review.';
  }

  @override
  String get packAdditionalFeeTitle => 'Additional fee required';

  @override
  String get packAgeLabel => 'Age';

  @override
  String get packAllowedLabel => 'Allowed';

  @override
  String get packAudienceEveryone => 'Everyone';

  @override
  String get packAudienceHint =>
      'Restrict who this pack is meant for. Not enforced when joining a room yet — saved with the pack for later use.';

  @override
  String get packCardTypePrompt => 'Prompt';

  @override
  String get packCardTypeStatement => 'Statement';

  @override
  String get packCategoryHintExample => 'e.g. Party games';

  @override
  String get packCategoryOptionalLabel => 'Category (optional)';

  @override
  String packCategoryRejectedNoReason(String name) {
    return 'Your suggested category \"$name\" was rejected.';
  }

  @override
  String packCategoryRejectedWithReason(String name, String reason) {
    return 'Your suggested category \"$name\" was rejected: $reason';
  }

  @override
  String get packCategorySubmittedForReview => 'Category submitted for review';

  @override
  String get packCoverImageHint =>
      'This appears on the pack card in the marketplace.';

  @override
  String get packCoverImageLabel => 'Cover image';

  @override
  String get packLivePreviewLabel => 'Live game-card preview';

  @override
  String get packLivePreviewHint =>
      'This is approximately what players will see in the game.';

  @override
  String get packCardPreviewSampleText => 'Your card text will appear here';

  @override
  String get packCardPreviewSectionLabel => 'Card preview';

  @override
  String packCardPreviewCountLabel(int current, int total) {
    return 'Card $current of $total';
  }

  @override
  String get packChooseSticker => 'Choose sticker';

  @override
  String get packStickerSelected => 'Sticker selected';

  @override
  String get packRemoveSticker => 'Remove sticker';

  @override
  String get packNoStickersAvailable => 'No stickers available yet';

  @override
  String get packCardPreviewEmptyTitle => 'No cards yet';

  @override
  String get packCardPreviewEmptyBody =>
      'Add your first card below and it will appear here.';

  @override
  String packCreateTitle(String step) {
    return 'Create Pack — $step';
  }

  @override
  String packDescriptionFieldLabel(String lang) {
    return 'Description ($lang, optional)';
  }

  @override
  String get packDifficultyMedium => 'Medium';

  @override
  String get packDifficultyMild => 'Mild';

  @override
  String get packDifficultySpicy => '🌶 Spicy';

  @override
  String get packEditPunishment => 'Edit punishment';

  @override
  String get packEnableSpicyHint =>
      'Enable spicy content in pack settings to add spicy cards';

  @override
  String packFailedSuggestCategory(String error) {
    return 'Failed to suggest category: $error';
  }

  @override
  String packFailedToSave(String error) {
    return 'Failed to save: $error';
  }

  @override
  String packFailedToSaveCards(String error) {
    return 'Failed to save cards: $error';
  }

  @override
  String packFailedToSaveReactions(String error) {
    return 'Failed to save reactions: $error';
  }

  @override
  String packFillContentInLanguages(String languages) {
    return 'Please fill content in: $languages';
  }

  @override
  String get packFreeLabel => 'Free';

  @override
  String get packGameTypeLabel => 'Game type';

  @override
  String get packGameTypeMeme => '😂 Meme Game';

  @override
  String get packGameTypeNhie => '🍹 Never Have I Ever';

  @override
  String get packGameTypeTod => '🎯 Truth or Dare';

  @override
  String get packGenderFemaleOnly => 'Female only';

  @override
  String get packGenderLabel => 'Gender';

  @override
  String get packGenderMaleOnly => 'Male only';

  @override
  String get packImportantRulesBody =>
      '• Packs cannot be edited after publishing.\n• You must purchase your own pack to use it in games.\n• Moderation review takes 1–3 business days.';

  @override
  String get packImportantRulesTitle => '📋 Important rules:';

  @override
  String get packInformationTitle => 'Pack information';

  @override
  String get packLangArabic => 'Arabic';

  @override
  String get packLangEnglish => 'English';

  @override
  String get packLangFrench => 'French';

  @override
  String get packLangGerman => 'German';

  @override
  String get packLangPortuguese => 'Portuguese';

  @override
  String get packLangRussian => 'Russian';

  @override
  String get packLangSpanish => 'Spanish';

  @override
  String get packLangTurkish => 'Turkish';

  @override
  String get packMaxReactionImagesReached =>
      'Maximum 30 reaction images reached';

  @override
  String packMinPlayersLabel(int count) {
    return 'Minimum players: $count';
  }

  @override
  String get packMinimumReached => '✅ Minimum reached';

  @override
  String packMoreNeeded(int count) {
    return '$count more needed';
  }

  @override
  String packNameFieldLabel(String lang) {
    return 'Pack name ($lang)*';
  }

  @override
  String get packNameHint => 'e.g. Wild Friday Night';

  @override
  String get packNoReactionImagesYet => 'No reaction images yet';

  @override
  String get packNotLoggedIn => 'Not logged in';

  @override
  String get packOneNamePerLanguage =>
      'One name and description per language you selected.';

  @override
  String packPayFeeAndSubmit(int fee) {
    return 'Pay $fee MRU & Submit';
  }

  @override
  String packPendingAdminReview(String name) {
    return '\"$name\" is pending admin review';
  }

  @override
  String get packPickExistingCategory => 'Pick existing category';

  @override
  String packPlayersSliderLabel(int count) {
    return '$count players';
  }

  @override
  String get packPriceFreeHint => 'Leave as 0 for a free pack';

  @override
  String packMinPriceError(int min) {
    return 'Paid packs must be priced at $min MRU or more';
  }

  @override
  String get packPriceLabel => 'Price';

  @override
  String packPriceMru(int price) {
    return '$price MRU';
  }

  @override
  String packPunishmentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count punishments',
      one: '$count punishment',
    );
    return '$_temp0';
  }

  @override
  String get packPunishmentInputHint => 'e.g. Do 10 pushups';

  @override
  String get packPunishmentsEmptyHint =>
      'Optional — add some, or skip straight to Publish.';

  @override
  String get packPunishmentsHint =>
      'Shown to a player who skips or refuses a card, if the room owner chooses to use pack punishments instead of live player submissions.';

  @override
  String get packPunishmentsOptionalTitle => 'Punishments (optional)';

  @override
  String packReactionImageCount(int count) {
    return '$count / 30 reaction images';
  }

  @override
  String packReactionSlotsRemaining(int count) {
    return '$count slots remaining';
  }

  @override
  String get packReactionsDescription =>
      'Players will use these images as reactions during the game. Add up to 30. If none, default stickers are used.';

  @override
  String get packReactionsOptionalHint => 'Optional — skip to use defaults';

  @override
  String get packReadyToPublish => 'Ready to publish?';

  @override
  String get packReviewBeforeSubmitting =>
      'Review your pack before submitting for moderation.';

  @override
  String get packSelectLanguagesHint =>
      'Choose every language you\'ll write this pack\'s names, descriptions, and cards in.';

  @override
  String get packSpicyLabel => 'Spicy content';

  @override
  String get packSpicyContentDisabled =>
      'Spicy content is not available right now.';

  @override
  String get packStepAudience => 'Audience';

  @override
  String get packStepCards => 'Cards';

  @override
  String get packStepGeneralInfo => 'General Info';

  @override
  String get packStepLanguages => 'Languages';

  @override
  String get packStepNamesDescriptions => 'Names & descriptions';

  @override
  String get packStepPublish => 'Publish';

  @override
  String get packStepPunishments => 'Punishments';

  @override
  String get packStepReactions => 'Reactions';

  @override
  String packSubmissionFailed(String error) {
    return 'Submission failed: $error';
  }

  @override
  String get packSubmitForReview => 'Submit for Review';

  @override
  String get packEligibilityChecking => 'Checking your submission eligibility…';

  @override
  String get packFreeSubmissionAvailable => 'Your free submission is available';

  @override
  String get packFreeSubmissionUnavailable =>
      'Free submission not available yet';

  @override
  String packNextFreeSubmissionAt(String date) {
    return 'Next free submission: $date';
  }

  @override
  String packPaidExtraPackHint(int price) {
    return 'You can create an extra pack now for $price MRU.';
  }

  @override
  String packCreateExtraPackPriced(int price) {
    return 'Create Extra Pack — $price MRU';
  }

  @override
  String get packCreatorNotVerified =>
      'Only verified creators can submit packs for review.';

  @override
  String get packAlreadyHasDraft =>
      'You already have a draft pack. Finish, publish, or delete it before creating another draft.';

  @override
  String get packDraftLimitReachedTitle => 'Draft Limit Reached';

  @override
  String get packDeleteDraft => 'Delete Draft';

  @override
  String get packDeleteDraftConfirmTitle => 'Delete this draft?';

  @override
  String packDeleteDraftConfirmBody(String title) {
    return '\"$title\" will be permanently deleted. This can\'t be undone.';
  }

  @override
  String get packDraftDeletedNotice => 'Draft deleted.';

  @override
  String packDeleteDraftFailed(String error) {
    return 'Failed to delete draft: $error';
  }

  @override
  String get packSubmittedForReviewNotice =>
      'Pack submitted for review! You\'ll be notified when approved.';

  @override
  String get packSuggestAgain => 'Suggest again';

  @override
  String get packSuggestNew => 'Suggest new';

  @override
  String get packSuggestNewCategory => 'Suggest a new category';

  @override
  String get packSummaryCards => 'Cards';

  @override
  String packSummaryCardsValue(int count, int truthCount, int dareCount) {
    return '$count (${truthCount}T + ${dareCount}D)';
  }

  @override
  String get packSummaryGameType => 'Game type';

  @override
  String get packSummaryPrice => 'Price';

  @override
  String get packSummarySpicyContent => 'Spicy content';

  @override
  String get packSummaryTitle => 'Title';

  @override
  String get packTapToAddCover => 'Tap to add cover';

  @override
  String get packTypeDare => 'Dare 🔥';

  @override
  String get packTypePrompt => 'Prompt 😂';

  @override
  String get packTypeStatement => 'Statement 🍹';

  @override
  String get packTypeTruth => 'Truth 🤔';

  @override
  String packUploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get packUploadingEllipsis => 'Uploading...';

  @override
  String get packWhoCanPlay => 'Who can play with this pack';

  @override
  String get packAdditionalDetailsOptional => 'Additional details (optional)';

  @override
  String get packAvailableOffline => 'Available offline';

  @override
  String get packBrowseMarketplaceHint =>
      'Browse the marketplace to find packs.';

  @override
  String packBuyForPrice(int price) {
    return 'Buy for $price MRU';
  }

  @override
  String get packCancelled => 'Cancelled';

  @override
  String packCancelledOn(String date) {
    return 'Cancelled on $date';
  }

  @override
  String packCardCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '$count card',
    );
    return '$_temp0';
  }

  @override
  String packCardsAndSales(int cards, int sales) {
    return '$cards cards • $sales sales';
  }

  @override
  String packCardsAvailableOffline(int count) {
    return '$count cards • Available offline';
  }

  @override
  String get packCity => 'City';

  @override
  String packCountLabel(int count) {
    return '$count packs';
  }

  @override
  String get packCreateFirstHint =>
      'Create your first pack and share it with the world.';

  @override
  String get packCreatePack => 'Create Pack';

  @override
  String get packCreator => 'Creator';

  @override
  String get packCreatorLabel => 'Pack creator';

  @override
  String get packCreatorStudio => 'Creator Studio';

  @override
  String get packDownload => 'Download';

  @override
  String get packDownloadFailed => 'Download failed';

  @override
  String get packDownloadToPlayOfflineHint =>
      'Download packs to play without internet.';

  @override
  String packDownloadingPercent(int percent) {
    return 'Downloading… $percent%';
  }

  @override
  String get packExpired => 'Expired';

  @override
  String packExpiresInDays(int days) {
    return 'Expires in $days days';
  }

  @override
  String packExpiresInDaysShort(int days) {
    return 'Expires in ${days}d';
  }

  @override
  String get packFailedToLoadYourPacks => 'Failed to load your packs.';

  @override
  String packFailedToRequest(String error) {
    return 'Failed to request: $error';
  }

  @override
  String get packFallbackTitle => 'Pack';

  @override
  String get packFeaturedHeading => '⭐ Featured';

  @override
  String get packFreeOfflineLimitNotice =>
      'Free plan allows 1 offline pack. Upgrade to Premium for 10.';

  @override
  String get packFullName => 'Full name';

  @override
  String get packGetFreePack => 'Get Free Pack';

  @override
  String get packInsufficientBalance => 'Insufficient Balance';

  @override
  String packInsufficientBalanceBody(int price) {
    return 'You need $price MRU to purchase this pack. Your current balance is too low.';
  }

  @override
  String get packLoadingPrice => 'Loading price…';

  @override
  String get packMinReviewLength => 'Please write at least 10 characters.';

  @override
  String get packMyPhysicalRequests => 'My Physical Pack Requests';

  @override
  String get packNewPack => 'New Pack';

  @override
  String get packNoFeaturedPacksYet => 'No featured packs yet';

  @override
  String get packNoOfflinePacks => 'No offline packs';

  @override
  String get packNoPacksFound => 'No packs found';

  @override
  String get packNoPacksYet => 'No packs yet';

  @override
  String get packSearchHint => 'Search by pack name, creator, or category…';

  @override
  String get packSearchForPacks => 'Search for packs';

  @override
  String get packSearchMinChars => 'Enter at least 2 characters.';

  @override
  String get packSearchNoResultsHint => 'Try a different name or category.';

  @override
  String get packNoPurchasedPacks => 'No purchased packs';

  @override
  String get packNoRequestsYet => 'No requests yet.';

  @override
  String get packNoReviewsYet => 'No reviews yet. Be the first!';

  @override
  String get packNotFound => 'Pack not found.';

  @override
  String get packNotesOptional => 'Notes (optional)';

  @override
  String packOfflineLimitReached(int limit) {
    return 'Offline limit reached ($limit packs). Delete a pack to download another.';
  }

  @override
  String packOfflineLimitReachedDelete(int limit) {
    return 'Offline limit reached ($limit packs). Delete one to download another.';
  }

  @override
  String get packOwnedBadge => 'Owned';

  @override
  String get packPhoneNumber => 'Phone number';

  @override
  String get packPhysicalCopyRequested => 'Physical copy requested!';

  @override
  String packPhysicalFeeNotice(int total, int price, int quantity) {
    return 'Fee: $total MRU ($price × $quantity), charged to your wallet balance.';
  }

  @override
  String get packPlayer => 'Player';

  @override
  String get packProBadge => '★ PRO';

  @override
  String get packOfficialBadge => 'Jma3a';

  @override
  String get packProcessingEllipsis => 'Processing…';

  @override
  String get packPromotedBadge => 'PROMOTED';

  @override
  String packPurchaseFailed(String error) {
    return 'Purchase failed: $error';
  }

  @override
  String get packPurchasedNotice => 'Pack purchased! You can now download it.';

  @override
  String get packQuantity => 'Quantity';

  @override
  String get packRedownload => 'Re-download';

  @override
  String packRejectionReason(String reason) {
    return 'Rejection reason: $reason';
  }

  @override
  String get packRemoveDownload => 'Remove download';

  @override
  String packRemoveDownloadBody(String title) {
    return 'This will remove the offline copy of \"$title\". You can re-download it later.';
  }

  @override
  String get packRemoveDownloadTitle => 'Remove download?';

  @override
  String get packReport => 'Report';

  @override
  String get packReportHint => 'Help us keep the marketplace safe.';

  @override
  String get packReportPack => 'Report pack';

  @override
  String get packReportReasonCheating => 'Cheating or gaming the system';

  @override
  String get packReportReasonHateSpeech => 'Hate speech';

  @override
  String get packReportReasonInappropriate => 'Inappropriate content';

  @override
  String get packReportReasonOther => 'Other';

  @override
  String get packReportReasonSpam => 'Spam';

  @override
  String get packReportSubmitted => 'Report submitted.';

  @override
  String get packPromoteYourPack => 'Promote your pack';

  @override
  String get packPromotionDuration24h => '24 Hours';

  @override
  String get packPromotionDuration7d => '1 Week';

  @override
  String get packPromotionSubtitle =>
      'Feature this pack in the promoted carousel to reach more players.';

  @override
  String get packPromotionSubmit => 'Promote';

  @override
  String get packPromotionSuccess => 'Pack promoted successfully!';

  @override
  String get packPromotionActiveLabel => 'Promotion active';

  @override
  String packPromotionEndsAt(String date) {
    return 'Ends $date';
  }

  @override
  String get packPromotionAlreadyActive =>
      'This pack already has an active promotion.';

  @override
  String get packRequestPhysicalCopy => 'Request Physical Copy';

  @override
  String get packRetryDownload => 'Retry download';

  @override
  String get packReviewSubmitted => 'Review submitted!';

  @override
  String get packReviewSubmitFailed =>
      'Couldn\'t submit your review. Please try again.';

  @override
  String get packReviews => 'Reviews';

  @override
  String get packShareThoughtsHint => 'Share your thoughts about this pack…';

  @override
  String get packStageCompleted => 'Completed';

  @override
  String get packStageDelivered => 'Delivered';

  @override
  String get packStageOutForDelivery => 'Out for Delivery';

  @override
  String get packStagePackaging => 'Packaging';

  @override
  String get packStagePaymentConfirmed => 'Payment Confirmed';

  @override
  String get packStagePrinting => 'Printing';

  @override
  String get packStageRequestSubmitted => 'Request Submitted';

  @override
  String get packStageUnderReview => 'Under Review';

  @override
  String get packStatAvgRating => 'Avg Rating';

  @override
  String get packStatPublished => 'Published';

  @override
  String get packStatSales => 'Sales';

  @override
  String get packStatusArchived => 'Archived';

  @override
  String get packStatusDraft => 'Draft';

  @override
  String get packStatusInReview => 'In Review';

  @override
  String get packStatusPublished => 'Published';

  @override
  String get packStatusRejected => 'Rejected';

  @override
  String get packStatusSuspended => 'Suspended';

  @override
  String get packPlatformManaged => 'Managed by Jma3a';

  @override
  String get packSubmitReport => 'Submit Report';

  @override
  String get packSubmitRequest => 'Submit Request';

  @override
  String get packSubmitReview => 'Submit Review';

  @override
  String get packTabBrowse => 'Browse';

  @override
  String get packTabDownloaded => 'Downloaded';

  @override
  String get packTabFeatured => 'Featured';

  @override
  String get packTabMyPacks => 'My Packs';

  @override
  String get packTabPurchased => 'Purchased';

  @override
  String get packTopUpWallet => 'Top Up Wallet';

  @override
  String get packWriteReview => 'Write a review';

  @override
  String get packWriteReviewShort => 'Write review';

  @override
  String get packYouOwnThisPack => 'You own this pack';

  @override
  String packYouRatedThis(int rating) {
    return 'You rated this $rating/5';
  }

  @override
  String get packRemoveRating => 'Remove';

  @override
  String get packRatingRemoved => 'Your rating has been removed.';

  @override
  String get packRatingFailed =>
      'Couldn\'t save your rating. Please try again.';

  @override
  String get packYourPacks => 'Your Packs';

  @override
  String get packYourRating => 'Your rating:';

  @override
  String get packZoneDistrict => 'Zone / District';

  @override
  String get packZoneHint => 'e.g. Tevragh Zeina';

  @override
  String get searchLabel => 'Search';

  @override
  String avatarAlreadyUpdatedNotice(int hours, int mins) {
    return 'You already updated your avatar. Try again in ${hours}h ${mins}m.';
  }

  @override
  String get avatarCustomAvatarsHint =>
      'Create your own Bitmoji-style avatar and show it across the app with Premium.';

  @override
  String get avatarCustomAvatarsTitle => 'Custom Avatars';

  @override
  String get avatarFeelingLucky => 'Feeling lucky?';

  @override
  String get avatarGenerateRandomHint => 'Generate a random avatar instantly.';

  @override
  String get avatarOnCooldown => 'On Cooldown';

  @override
  String get avatarOptAccessories => 'Accessories';

  @override
  String get avatarOptEyebrows => 'Eyebrows';

  @override
  String get avatarOptEyes => 'Eyes';

  @override
  String get avatarOptFacialHair => 'Facial Hair';

  @override
  String get avatarOptFacialHairColor => 'Facial Hair Color';

  @override
  String get avatarOptHairColor => 'Hair Color';

  @override
  String get avatarOptHairStyle => 'Hair Style';

  @override
  String get avatarOptMouth => 'Mouth';

  @override
  String get avatarOptOutfit => 'Outfit';

  @override
  String get avatarOptOutfitColor => 'Outfit Color';

  @override
  String get avatarOptSkinTone => 'Skin Tone';

  @override
  String get avatarRandomizeAvatar => 'Randomize Avatar';

  @override
  String get avatarReactionsDescription =>
      'Your avatar reactions (happy, laugh, cry & more) are available alongside emoji reactions in Truth or Dare and Never Have I Ever.';

  @override
  String get avatarSaveAvatar => 'Save Avatar';

  @override
  String get avatarSaveFailed => 'Could not save right now.';

  @override
  String get avatarSaved => 'Avatar saved! ✦';

  @override
  String get avatarSavingEllipsis => 'Saving…';

  @override
  String get avatarDeleteAction => 'Delete Avatar';

  @override
  String get avatarDeleteDialogTitle => 'Delete your avatar?';

  @override
  String get avatarDeleteDialogMessage =>
      'This removes your custom avatar. You\'ll go back to your uploaded photo or the default look until you create a new one.';

  @override
  String get avatarDeleted => 'Avatar deleted.';

  @override
  String get avatarDeleteFailed => 'Could not delete right now.';

  @override
  String get avatarTabExtras => 'Extras';

  @override
  String get avatarTabEyes => 'Eyes';

  @override
  String get avatarTabFace => 'Face';

  @override
  String get avatarTabHair => 'Hair';

  @override
  String get avatarTabMouth => 'Mouth';

  @override
  String get avatarTabOutfit => 'Outfit';

  @override
  String avatarUpdateCooldownNotice(int hours, int mins) {
    return 'You can update your avatar again in ${hours}h ${mins}m.';
  }

  @override
  String get avatarUpgradeToPremium => 'Upgrade to Premium ✦';

  @override
  String get profileAbout => 'About';

  @override
  String get profileAgeOptionalLabel => 'Age (optional)';

  @override
  String get profileBalanceAndTransactions => 'Balance & transactions';

  @override
  String get profileBioTooLong => 'Maximum 280 characters';

  @override
  String get profileChangeUsername => 'Change username';

  @override
  String get profileChooseColourTheme => 'Choose your colour theme';

  @override
  String get profileChooseFromGallery => 'Choose from gallery';

  @override
  String get profileCooldownActive => 'Cooldown active';

  @override
  String profileCooldownBody(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '$days day',
    );
    return 'You can change your username again in $_temp0.\n\nUsernames can only be changed once every 30 days.';
  }

  @override
  String get profileCountryAlgeria => 'Algeria';

  @override
  String get profileCountryEgypt => 'Egypt';

  @override
  String get profileCountryFrance => 'France';

  @override
  String get profileCountryGermany => 'Germany';

  @override
  String get profileCountryMauritania => 'Mauritania';

  @override
  String get profileCountryMorocco => 'Morocco';

  @override
  String get profileCountryOptionalLabel => 'Country (optional)';

  @override
  String get profileCountryOther => 'Other';

  @override
  String get profileCountrySaudiArabia => 'Saudi Arabia';

  @override
  String get profileCountryTunisia => 'Tunisia';

  @override
  String get profileCountryUae => 'UAE';

  @override
  String get profileCountryUnitedKingdom => 'United Kingdom';

  @override
  String get profileCountryUnitedStates => 'United States';

  @override
  String get profileCreateAvatarHint => 'Create your Bitmoji-style avatar';

  @override
  String get profileCurrentUsername => 'Current username';

  @override
  String get profileInfoSection => 'Profile info';

  @override
  String get profileMostPlayedPacks => '🔥 Most Played Packs';

  @override
  String get profileMyAvatar => 'My Avatar';

  @override
  String get profileMyCreatedPacks => '✏️ My Created Packs';

  @override
  String get profileNewUsername => 'New username';

  @override
  String get profilePersonalDetails => 'Personal details';

  @override
  String get profilePhoneOptionalLabel => 'Phone number (optional)';

  @override
  String get profilePreferences => 'Preferences';

  @override
  String profilePremiumActiveExpires(int day, int month, int year) {
    return 'Active · expires $day/$month/$year';
  }

  @override
  String get profileSaveUsername => 'Save username';

  @override
  String get profileTakePhoto => 'Take photo';

  @override
  String get profileUnlockPremiumHint =>
      'Unlock themes, avatars, anonymous chat & more';

  @override
  String get profileUploadingPhoto => 'Uploading photo…';

  @override
  String profileUsernameCooldownNotice(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '$days day',
    );
    return 'Username change available in $_temp0.\nChanges are limited to once every 30 days.';
  }

  @override
  String get profileUsernameHint => 'lowercase_letters_123';

  @override
  String get profileUsernamePermanentNotice =>
      'Username changes are permanent for 30 days.';

  @override
  String get profileUsernameRequirements =>
      '3–30 characters · letters, numbers, underscores';

  @override
  String get profileUsernameTaken => 'This username is already taken.';

  @override
  String get profileUsernameUpdated => 'Username updated!';

  @override
  String get profileUsernameValidation => '3–30 chars, only a–z, 0–9, _';

  @override
  String get profileVerifiedCreator => 'Verified Creator';

  @override
  String get notifARoom => 'a room';

  @override
  String get notifAllCaughtUp => 'You\'re all caught up!';

  @override
  String get notifDecline => 'Decline';

  @override
  String notifDeclineFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String get notifInApp => 'In-App';

  @override
  String get notifInvitedYouToJoin => 'Invited you to join';

  @override
  String get notifMarkAllRead => 'Mark all read';

  @override
  String get notifNoNotifications => 'No notifications';

  @override
  String get notifPreferences => 'Preferences';

  @override
  String get notifPreferencesTitle => 'Notification Preferences';

  @override
  String get notifPush => 'Push';

  @override
  String notifRoomInvitesCount(int count) {
    return 'Room Invites ($count)';
  }

  @override
  String get notifTitle => 'Notifications';

  @override
  String get notifTypeAchievement => 'Achievement';

  @override
  String get notifTypeFollow => 'New Follower';

  @override
  String get notifTypeFriendAccepted => 'Friend Accepted';

  @override
  String get notifTypeFriendRequest => 'Friend Request';

  @override
  String get notifTypeGameStarted => 'Game Started';

  @override
  String get notifTypeModeration => 'Moderation';

  @override
  String get notifTypePackApproved => 'Pack Approved';

  @override
  String get notifTypePackExpired => 'Pack Expired';

  @override
  String get notifTypePackRejected => 'Pack Rejected';

  @override
  String get notifTypePackReview => 'Pack Review';

  @override
  String get notifTypePackSale => 'Pack Sale';

  @override
  String get notifTypePhysicalPackStatus => 'Order Update';

  @override
  String get notifTypeRoomInvite => 'Room Invite';

  @override
  String get notifTypeRoomJoinRequest => 'Room Join Request';

  @override
  String get notifTypeRoomJoinRequestAccepted => 'Join Request Accepted';

  @override
  String get notifTypeRoomJoinRequestRejected => 'Join Request Rejected';

  @override
  String get notifTypeRoomKicked => 'Removed from Room';

  @override
  String get notifTypeChatMessage => 'Chat Message';

  @override
  String get notifTypeStreakIncreased => 'Streak';

  @override
  String get notifTypeCreatorPacksTransferred => 'Packs Jma3a-Managed';

  @override
  String get notifTypeCreatorPrivilegesRemoved => 'Creator Status Removed';

  @override
  String get notifTypeCreatorRecoveryApproved => 'Recovery Request Approved';

  @override
  String get notifTypeCreatorRecoveryRejected => 'Recovery Request Rejected';

  @override
  String get notifTypeSubscriptionExpired => 'Subscription Expired';

  @override
  String get notifTypeSubscriptionExpiring1d => 'Subscription Expiring (1 Day)';

  @override
  String get notifTypeSubscriptionExpiring2d =>
      'Subscription Expiring (2 Days)';

  @override
  String get notifTypeSubscriptionStarted => 'Subscription Started';

  @override
  String get notifTypeSystem => 'System';

  @override
  String get notifTypeWalletCredit => 'Wallet Credit';

  @override
  String get notifTypeWalletDebit => 'Wallet Debit';

  @override
  String get viewLabel => 'View';

  @override
  String get chatTitle => 'Chat';

  @override
  String get gameSettingsAllowOneReplay => 'Allow one replay';

  @override
  String get gameSettingsProofViewDuration =>
      'Proof view duration (auto-closes after this)';

  @override
  String get gameSettingsProofUnlimitedDuration =>
      'Unlimited duration (until next round)';

  @override
  String get gameSettingsProofReplayHint =>
      'Premium viewers get one extra replay beyond this.';

  @override
  String gameSettingsProofAutoCloseHint(int seconds) {
    return 'Proof auto-closes after ${seconds}s — no replay while a duration is set.';
  }

  @override
  String get gameSettingsRequireApprovalToSpectate =>
      'Require approval to spectate';

  @override
  String get moderationBanPlayer => 'Ban player';

  @override
  String get moderationDuration1Hour => '1 hour';

  @override
  String get moderationDuration24Hours => '24 hours';

  @override
  String get moderationDuration30Min => '30 minutes';

  @override
  String get moderationDuration7Days => '7 days';

  @override
  String get moderationDurationPermanent => 'Permanent';

  @override
  String get moderationReasonOptional => 'Reason (optional)';

  @override
  String get roomsAnonymousModeOn => 'Anonymous mode on';

  @override
  String get roomsAnonymousSender => 'Anonymous';

  @override
  String get roomsChatDisabled => 'Chat disabled';

  @override
  String get roomsChooseYourRole => 'Choose your role in this room.';

  @override
  String get roomsClosed => 'Closed';

  @override
  String roomsAgoMinutes(int count) {
    return '${count}m ago';
  }

  @override
  String roomsAgoHours(int count) {
    return '${count}h ago';
  }

  @override
  String roomsAgoDays(int count) {
    return '${count}d ago';
  }

  @override
  String roomsClosedAgo(String ago) {
    return 'Closed $ago';
  }

  @override
  String get roomsClosedRoomFallback => 'Closed Room';

  @override
  String get roomsConnConnecting => 'Connecting…';

  @override
  String get roomsConnDisconnected => 'Disconnected';

  @override
  String get roomsConnLive => 'Live';

  @override
  String get roomsConnReconnecting => 'Reconnecting…';

  @override
  String get roomsConnSyncing => 'Syncing…';

  @override
  String roomsFailedToSendRequest(String error) {
    return 'Failed to send request: $error';
  }

  @override
  String get roomsFallbackRoom => 'Room';

  @override
  String get roomsGameAlreadyInProgress => 'This game is already in progress.';

  @override
  String get roomsGameInProgress => 'Game in progress';

  @override
  String get roomsHiddenFromPlayersList =>
      'Hidden from players and spectator list';

  @override
  String get roomsInvalidCodeOrNotFound => 'Invalid code or room not found';

  @override
  String get roomsInvite => 'Invite';

  @override
  String get roomsJoinAsPlayer => 'Join as Player';

  @override
  String get roomsMakeModerator => 'Make moderator';

  @override
  String roomsManagePermissionsCount(int count) {
    return 'Manage permissions ($count)';
  }

  @override
  String get roomsMessageAsAnonymous => 'Message as Anonymous…';

  @override
  String get roomsModeration => 'Moderation';

  @override
  String get roomsObserveWithoutPlaying => 'Observe without playing';

  @override
  String roomsPackRequiresMinPlayers(int count) {
    return 'This pack requires at least $count players.';
  }

  @override
  String get roomsPendingEllipsis => 'Pending…';

  @override
  String get roomsPermAcceptJoins => 'Accept join requests';

  @override
  String get roomsPermAcceptRejoins => 'Accept rejoin requests';

  @override
  String get roomsPermAcceptSpectators => 'Accept spectator requests';

  @override
  String get roomsPermAdvanceTurn => 'Start next turn';

  @override
  String get roomsPermEndGame => 'End the game';

  @override
  String get roomsPermKickPlayers => 'Remove players';

  @override
  String get roomsPermManageSettings => 'Manage room settings';

  @override
  String get roomsPermMuteChat => 'Mute chat';

  @override
  String get roomsPermMutePlayers => 'Mute players in game';

  @override
  String get roomsPermSkipTurn => 'Skip a turn';

  @override
  String get roomsPermStartGame => 'Start the game';

  @override
  String get roomsRejoin => 'Rejoin';

  @override
  String get roomsRejoinRequestDeclined => 'Your rejoin request was declined';

  @override
  String get roomsRequestAgain => 'Request Again';

  @override
  String get roomsRequestSentWaiting => 'Request sent — waiting for the host';

  @override
  String get roomsRequestToRejoin => 'Request to Rejoin';

  @override
  String get roomsSendAnonymouslyPremium => 'Send anonymously (Premium)';

  @override
  String get roomsStatusClosed => 'Closed';

  @override
  String get roomsStatusInGame => 'In Game';

  @override
  String get roomsStatusPaused => 'Paused';

  @override
  String get roomsStatusWaiting => 'Waiting';

  @override
  String get roomsTakePartInGame => 'Take part in the game';

  @override
  String roomsTransferOwnershipConfirm(String name) {
    return 'Transfer room ownership to $name? You will become a regular player.';
  }

  @override
  String get roomsWaitingForReconnecting =>
      'Waiting for reconnecting player(s)...';

  @override
  String get roomsWatchAnonymously => 'Watch Anonymously ✦';

  @override
  String get roomsWatchAsSpectator => 'Watch as Spectator';

  @override
  String get sharedApprove => 'Approve';

  @override
  String get sharedBan => 'Ban';

  @override
  String get sharedBanPlayerBody =>
      'Are you sure you want to ban this player from this room?';

  @override
  String get sharedBanPlayerTitle => 'Ban Player';

  @override
  String get sharedEndGame => 'End Game';

  @override
  String get sharedEveryoneLeftNotice =>
      'Every other player has left. The game cannot continue — end it when you\'re ready.';

  @override
  String sharedGameRulesTitle(String gameName) {
    return '$gameName — Rules';
  }

  @override
  String get sharedGoHome => 'Go Home';

  @override
  String get sharedHistoryTooltip => 'History';

  @override
  String get sharedReactionAvatarsTab => 'Avatars';

  @override
  String get sharedReactionIconsTab => 'Icons';

  @override
  String sharedJoinRequestFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String sharedJoinRequestsCount(int count) {
    return 'Join Requests ($count)';
  }

  @override
  String get sharedKick => 'Kick';

  @override
  String get sharedKickPlayerBody =>
      'Are you sure you want to remove this player from the current game?';

  @override
  String get sharedKickPlayerTitle => 'Kick Player';

  @override
  String get sharedMemeRuleObjective =>
      'Submit the funniest caption or sticker for the round\'s prompt, then vote for your favorite from everyone else\'s.';

  @override
  String get sharedMemeRuleScoring =>
      'Whoever gets the most votes on a round wins that round\'s point. Most points at the end wins the game.';

  @override
  String get sharedMemeRuleTurnFlow =>
      'Submission phase → voting phase → results, every round, until the pack\'s prompts run out or the round limit is hit.';

  @override
  String get sharedMute => 'Mute';

  @override
  String get sharedNhieRuleObjective =>
      'Each round shows a \"Never have I ever…\" statement. Everyone answers honestly whether they have or haven\'t.';

  @override
  String get sharedNhieRuleScoring =>
      'Your history of honest answers builds your profile across the game — there\'s no winner/loser, just revealing.';

  @override
  String get sharedNhieRuleTurnFlow =>
      'A new statement appears each round; every player votes, then the round advances once everyone has answered.';

  @override
  String get sharedNoPendingJoinRequests => 'No pending join requests';

  @override
  String get sharedPageNotFound => 'Page Not Found';

  @override
  String get sharedPageNotFoundHint =>
      'The page you\'re looking for doesn\'t exist.';

  @override
  String get sharedReject => 'Reject';

  @override
  String get sharedRoomMembers => 'Room members';

  @override
  String sharedRoomMembersCount(int count) {
    return '👥 Room Members ($count)';
  }

  @override
  String get sharedRoomSettingsTitle => 'This room\'s settings';

  @override
  String get sharedRuleNoTurnTimer => 'No turn timer';

  @override
  String get sharedRuleObjective => 'Objective';

  @override
  String get sharedRulePolicyEveryone => 'everyone in the game';

  @override
  String get sharedRulePolicyPlayersOnly => 'players only';

  @override
  String get sharedRulePolicySpectatorsOnly => 'spectators only';

  @override
  String get sharedRuleProofViewOnce =>
      'Proof can be viewed once (Premium: twice).';

  @override
  String get sharedRuleProofViewTwice =>
      'Proof can be viewed twice (Premium: three times).';

  @override
  String sharedRuleProofVisibleTo(String policy) {
    return 'Proof is visible to: $policy.';
  }

  @override
  String get sharedRulePunishmentOff =>
      'Punishment mode is OFF — skipping isn\'t offered as an option.';

  @override
  String get sharedRulePunishmentOn =>
      'Punishment mode is ON — skipping means every other player submits one punishment and you pick which you\'ll do.';

  @override
  String get sharedRuleScoring => 'Scoring';

  @override
  String get sharedRuleSpectatorsApprovalRequired =>
      'Spectators are allowed, subject to host approval.';

  @override
  String get sharedRuleSpectatorsFreelyAllowed =>
      'Spectators are allowed to watch freely.';

  @override
  String get sharedRuleSpectatorsNotAllowed =>
      'Spectators are not allowed in this room.';

  @override
  String get sharedRuleSpicyEnabled =>
      'Spicy content is enabled for this room.';

  @override
  String get sharedRuleTurnFlow => 'Turn flow';

  @override
  String sharedRuleTurnTimer(int seconds) {
    return 'Turn timer: ${seconds}s';
  }

  @override
  String get sharedRules => 'Rules';

  @override
  String get sharedStatusDisconnected => 'Disconnected';

  @override
  String get sharedStatusMuted => 'Muted';

  @override
  String get sharedStatusPlaying => 'Playing';

  @override
  String get sharedStatusSpectator => 'Spectator';

  @override
  String get sharedTodRuleObjective =>
      'Take turns choosing Truth or Dare. Answer honestly or complete the dare — there\'s no \"safe\" option once you\'ve picked.';

  @override
  String get sharedTodRuleScoring =>
      'Completed truths and dares add to your score. Skips are tracked too — they may trigger a punishment (see below).';

  @override
  String get sharedTodRuleTurnFlow =>
      'The current player picks Truth or Dare, gets a card, and either answers/performs it or (if allowed) skips. Then play passes to the next player in order.';

  @override
  String get sharedUnmute => 'Unmute';

  @override
  String sharedWantsToJoinCurrentGame(String name) {
    return '$name wants to join the current game.';
  }

  @override
  String get friendsAccept => 'Accept';

  @override
  String get friendsReject => 'Reject';

  @override
  String get friendsDecline => 'Decline';

  @override
  String get friendsPendingRequestsHeader => 'Pending Friendship Requests';

  @override
  String get friendsYourFriendsHeader => 'Your Friends';

  @override
  String get friendsAdd => 'Add';

  @override
  String get friendsAddFriend => 'Add friend';

  @override
  String get friendsBlock => 'Block';

  @override
  String get friendsBlocked => 'Blocked';

  @override
  String get friendsCancelRequest => 'Cancel request';

  @override
  String get friendsCannotInteract => 'You cannot interact with this user.';

  @override
  String friendsCreatedBy(String name) {
    return 'Created by $name';
  }

  @override
  String get friendsOfficialAccount => 'Official Jma3a Account';

  @override
  String friendsFollowersCount(int count) {
    return '$count Followers';
  }

  @override
  String get friendsFollow => 'Follow';

  @override
  String get friendsFollowersTitle => 'Followers';

  @override
  String get friendsNoFollowersYet => 'No followers yet.';

  @override
  String friendsMostPlayedBy(String name) {
    return 'Most Played by $name';
  }

  @override
  String get friendsNoBlockedUsers => 'No blocked users';

  @override
  String get friendsNoBlockedUsersHint => 'Users you block will appear here.';

  @override
  String get friendsNoFriendsHint =>
      'Explore people and find players to connect with.';

  @override
  String get friendsNoFriendsYet => 'No friends yet';

  @override
  String get friendsNoPendingRequests => 'No pending requests';

  @override
  String get friendsNoPendingRequestsHint =>
      'Friend requests you receive will appear here.';

  @override
  String get friendsNoResults => 'No results';

  @override
  String get friendsNoResultsHint => 'Try a different name or username.';

  @override
  String friendsOfflineCount(int count) {
    return 'Offline — $count';
  }

  @override
  String friendsOnlineCount(int count) {
    return 'Online — $count';
  }

  @override
  String get creatorVerificationTitle => 'Become a Verified Creator';

  @override
  String get creatorVerificationSubtitle =>
      'Meet all of these requirements to apply for creator verification.';

  @override
  String get creatorReqPremiumPlus => 'Premium Plus subscriber';

  @override
  String creatorReqGamesPlayed(int count) {
    return 'Play at least $count games';
  }

  @override
  String creatorReqPacksUsed(int count) {
    return 'Use at least $count packs';
  }

  @override
  String creatorReqFollowers(int count) {
    return 'Have at least $count followers';
  }

  @override
  String creatorReqLoginStreak(int count) {
    return 'Enter the app $count days in a row';
  }

  @override
  String creatorReqRoomStreak(int count) {
    return 'Create a room every day for $count days in a row';
  }

  @override
  String creatorReqPackGamesStreak(int count, int days) {
    return 'Finish at least $count pack games every day for $days days in a row';
  }

  @override
  String get creatorReqPlayedWithOthers => 'Play a game with other users';

  @override
  String get creatorApplyNow => 'Apply Now';

  @override
  String get creatorKeepGoing =>
      'Keep going — you\'ll be able to apply once every requirement above is met.';

  @override
  String get creatorRecoveryBannerTitle =>
      'Your verified creator status was removed';

  @override
  String get creatorRecoveryBannerBody =>
      'Your Premium Plus subscription lapsed and your verified creator status/privileges were automatically removed. You can submit a recovery request for admin review.';

  @override
  String get creatorRecoveryBannerAction => 'Submit a Recovery Request';

  @override
  String get creatorRecoveryTitle => 'Recovery Request';

  @override
  String get creatorRecoveryIntro =>
      'Tell us what happened. An admin will review your request and, if approved, your verified creator status, privileges, and packs will be fully restored.';

  @override
  String get creatorRecoveryReasonLabel => 'Reason';

  @override
  String get creatorRecoveryReasonResubscribedLate =>
      'I resubscribed but missed the grace period';

  @override
  String get creatorRecoveryReasonPaymentIssue =>
      'A payment/billing issue caused the lapse';

  @override
  String get creatorRecoveryReasonUnawareOfExpiry =>
      'I wasn\'t notified my subscription expired';

  @override
  String get creatorRecoveryReasonExtenuatingCircumstances =>
      'Extenuating circumstances prevented renewal';

  @override
  String get creatorRecoveryReasonOther => 'Other';

  @override
  String get creatorRecoveryExplanationLabel => 'Explanation';

  @override
  String get creatorRecoveryExplanationHint =>
      'Explain what happened in at least 20 characters';

  @override
  String get creatorRecoveryExplanationTooShort =>
      'Please write at least 20 characters explaining what happened.';

  @override
  String get creatorRecoveryEvidenceLabel => 'Evidence (optional)';

  @override
  String get creatorRecoveryEvidenceUploadFailed =>
      'Couldn\'t upload that image. Please try again.';

  @override
  String get creatorRecoverySubmit => 'Submit Request';

  @override
  String get creatorRecoverySubmitted =>
      'Your recovery request has been submitted for review.';

  @override
  String get creatorRecoveryFailed =>
      'Couldn\'t submit your recovery request. Please try again.';

  @override
  String get creatorRecoveryPendingTitle => 'Recovery Request Pending';

  @override
  String get creatorRecoveryPendingBody =>
      'Your recovery request is being reviewed by an admin. You\'ll be notified once a decision is made.';

  @override
  String get creatorRecoveryRejectedTitle =>
      'Your previous recovery request was rejected';

  @override
  String get creatorApplyDialogTitle => 'Apply for Verification';

  @override
  String get creatorApplyDialogRealName => 'Full legal name';

  @override
  String get creatorApplyDialogBio => 'Short bio (optional)';

  @override
  String get creatorApplySubmitted =>
      'Application submitted! We\'ll review it soon.';

  @override
  String get creatorApplyFailed =>
      'Failed to submit application. Please try again.';

  @override
  String get profileBecomeCreator => 'Become a Verified Creator';

  @override
  String get profileBecomeCreatorHint => 'Unlock creator tools and earnings';

  @override
  String get friendsPlayingNow => 'Playing now';

  @override
  String get friendsProfileNotFound => 'Profile not found.';

  @override
  String get friendsReceived => 'Received';

  @override
  String get friendsRemoveFriend => 'Remove friend';

  @override
  String get friendsRequests => 'Requests';

  @override
  String get friendsSearchForFriends => 'Search for friends';

  @override
  String get friendsSearchHint => 'Search by username or name…';

  @override
  String get friendsSearchMinChars => 'Enter at least 2 characters.';

  @override
  String friendsSentCount(int count) {
    return 'Sent — $count';
  }

  @override
  String get friendsStatusInGame => 'In Game';

  @override
  String get friendsStatusOffline => 'Offline';

  @override
  String get friendsStatusOnline => 'Online';

  @override
  String get presenceUserIsAway => 'Away';

  @override
  String get presenceUserIsAwayFull => 'User is away';

  @override
  String presenceUserAwaySnackbar(String name) {
    return '$name is away';
  }

  @override
  String get friendsStatusInRoomLobby => 'In room lobby';

  @override
  String friendsStatusPlayingGame(String game) {
    return 'Playing $game';
  }

  @override
  String get friendsUnblock => 'Unblock';

  @override
  String friendsUnblockedNotice(String name) {
    return '$name unblocked';
  }

  @override
  String get friendsUnfollow => 'Unfollow';

  @override
  String get friendsUserFallback => 'User';

  @override
  String get friendsYouHaveBlocked => 'You have blocked this user.';

  @override
  String get notifJustNow => 'Just now';

  @override
  String notifMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}m ago',
      one: '${count}m ago',
    );
    return '$_temp0';
  }

  @override
  String get settingsAboutUs => 'About Us';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsTermsConditions => 'Terms & Conditions';

  @override
  String get settingsRequestAccountDeletion => 'Request Account Deletion';

  @override
  String get settingsRequestAccountDeletionPending =>
      'Deletion request pending review';

  @override
  String get deleteAccountDialogTitle => 'Delete your account?';

  @override
  String get deleteAccountDialogMessage =>
      'This submits a request for our team to review — your account is not deleted immediately. Once approved, your profile, packs, wallet balance, and game history are permanently removed and this cannot be undone.';

  @override
  String get deleteAccountDialogConfirm => 'Submit Request';

  @override
  String get deleteAccountSubmitted =>
      'Your deletion request has been submitted for review.';

  @override
  String get deleteAccountAlreadyPending =>
      'You already have a pending deletion request.';

  @override
  String get aboutUsTitle => 'About Us';

  @override
  String get aboutUsVersionLabel => 'Version';

  @override
  String get aboutUsDescription =>
      'Jma3a is a multiplayer party game app — play Truth or Dare, Never Have I Ever, and meme games with friends and family, anytime, anywhere.';

  @override
  String get aboutUsCompanySectionTitle => 'Company';

  @override
  String get aboutUsCompanyInfo =>
      'Jma3a is developed and operated by the Jma3a team.';

  @override
  String get aboutUsContactTitle => 'Contact';

  @override
  String get aboutUsContactEmail => 'support@jma3a.app';

  @override
  String get aboutUsWebsiteTitle => 'Website';

  @override
  String get aboutUsWebsite => 'www.jma3a.app';

  @override
  String get aboutUsFollowUsTitle => 'Follow us';

  @override
  String get aboutUsSocialTiktok => 'TikTok';

  @override
  String get aboutUsSocialSnapchat => 'Snapchat';

  @override
  String get aboutUsSocialFacebook => 'Facebook';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get privacyPolicyIntro =>
      'This Privacy Policy explains what information Jma3a collects and how it\'s used. This is placeholder content — it will be replaced with the full legal policy.';

  @override
  String get privacySectionInfoCollected => 'Information We Collect';

  @override
  String get privacySectionInfoCollectedBody =>
      'Placeholder — describes account details, usage data, and content you create within the app.';

  @override
  String get privacySectionHowUsed => 'How We Use Your Information';

  @override
  String get privacySectionHowUsedBody =>
      'Placeholder — describes how collected information is used to provide and improve the app.';

  @override
  String get privacySectionNotifications => 'Notifications';

  @override
  String get privacySectionNotificationsBody =>
      'Placeholder — describes push notifications and how to manage your preferences.';

  @override
  String get privacySectionPurchases => 'Purchases';

  @override
  String get privacySectionPurchasesBody =>
      'Placeholder — describes how in-app purchases and subscriptions are handled.';

  @override
  String get privacySectionUserContent => 'User-Generated Content';

  @override
  String get privacySectionUserContentBody =>
      'Placeholder — describes ownership and handling of packs, cards, and other content you create.';

  @override
  String get privacySectionAccountDeletion => 'Account Deletion';

  @override
  String get privacySectionAccountDeletionBody =>
      'Placeholder — describes how to request account deletion and what happens to your data.';

  @override
  String get privacySectionContact => 'Contact Us';

  @override
  String get privacySectionContactBody =>
      'Placeholder — contact details for privacy-related questions.';

  @override
  String get termsConditionsTitle => 'Terms & Conditions';

  @override
  String get termsConditionsIntro =>
      'These Terms & Conditions govern your use of Jma3a, a social multiplayer game app. By creating an account or using the app, you agree to these Terms.';

  @override
  String get termsSectionAccount => 'Accounts';

  @override
  String get termsSectionAccountBody =>
      'You must be at least 13 years old to create a Jma3a account. You can sign up using a phone number or email address, which is verified with a one-time code. You are responsible for keeping your account credentials secure and for all activity on your account.';

  @override
  String get termsSectionAcceptableUse => 'Acceptable Use';

  @override
  String get termsSectionAcceptableUseBody =>
      'You agree to use Jma3a respectfully and not to harass, threaten, or abuse other users, impersonate others, or use the app for any unlawful purpose. Violations may result in content removal, feature restrictions, or account suspension.';

  @override
  String get termsSectionContent => 'Your Content';

  @override
  String get termsSectionContentBody =>
      'You retain ownership of the content you create, such as your profile and any packs or cards you make. By posting content in Jma3a, you grant us the right to display and distribute it within the app so other users can see and interact with it. You are responsible for the content you create or share.';

  @override
  String get termsSectionCreators => 'Creators & Official Accounts';

  @override
  String get termsSectionCreatorsBody =>
      'Jma3a offers Verified Creator status to eligible content creators, shown on their profile. Verified status may be granted or removed based on your account\'s standing and compliance with these Terms. An official Jma3a account may also appear in the app to share announcements and responses.';

  @override
  String get termsSectionRoomsGames => 'Rooms & Games';

  @override
  String get termsSectionRoomsGamesBody =>
      'Jma3a lets you create or join rooms to play multiplayer games with friends and other players, using packs of content provided by Jma3a or created by users. Room hosts and members are expected to follow these Terms while playing.';

  @override
  String get termsSectionPremium => 'Premium & Premium Plus';

  @override
  String get termsSectionPremiumBody =>
      'Jma3a offers optional Premium and Premium Plus subscriptions that unlock additional features and benefits within the app. What each tier includes may change over time; you will be shown what a subscription includes before you purchase it.';

  @override
  String get termsSectionWallet => 'Wallet & Payments';

  @override
  String get termsSectionWalletBody =>
      'Jma3a includes an in-app wallet that can be topped up using supported local payment methods. Creators may earn wallet balance from their content and request withdrawals, subject to Jma3a\'s review. Payments are also subject to the terms of the payment method provider you use.';

  @override
  String get termsSectionModeration => 'Reporting & Moderation';

  @override
  String get termsSectionModerationBody =>
      'You can report or block other users and content that violates these Terms. Jma3a may review reports and take action, including removing content, restricting features, or suspending or terminating accounts that violate these Terms.';

  @override
  String get termsSectionTermination => 'Suspension & Termination';

  @override
  String get termsSectionTerminationBody =>
      'We may suspend or terminate your account if you violate these Terms, misuse the app, or engage in fraudulent or harmful behavior. You may also request deletion of your account and data at any time.';

  @override
  String get termsSectionAvailability => 'Service Availability';

  @override
  String get termsSectionAvailabilityBody =>
      'Jma3a is provided on an \"as available\" basis. We may modify, suspend, or discontinue parts of the app at any time, and we do not guarantee uninterrupted or error-free service.';

  @override
  String get termsSectionChanges => 'Changes to These Terms';

  @override
  String get termsSectionChangesBody =>
      'We may update these Terms from time to time. Continuing to use Jma3a after changes are published means you accept the updated Terms.';

  @override
  String get termsSectionContact => 'Contact Us';

  @override
  String termsSectionContactBody(String email) {
    return 'If you have questions about these Terms, contact us at $email.';
  }

  @override
  String get accountSuspendedDialogTitle => 'Account Suspended';

  @override
  String accountSuspendedUntil(String until) {
    return 'Your account has been suspended until $until.';
  }

  @override
  String get accountBannedPermanently =>
      'Your account has been suspended from using Jma3a.';

  @override
  String get appUpdateAvailableTitle => 'Update Available';

  @override
  String get appUpdateDefaultTitle => 'A new version is available';

  @override
  String get appUpdateDefaultMessage =>
      'Please update the app to continue enjoying the latest features.';

  @override
  String get appUpdateNowButton => 'Update';

  @override
  String get appUpdateLaterButton => 'Later';

  @override
  String get appUpdateBannerMessage => 'A new version of Jma3a is available.';

  @override
  String get deleteAccountReasonPrompt => 'Why are you leaving?';

  @override
  String get deleteAccountReasonNoLongerUse => 'I no longer use the app';

  @override
  String get deleteAccountReasonPrivacy => 'Privacy concerns';

  @override
  String get deleteAccountReasonFoundAnother => 'Found another app';

  @override
  String get deleteAccountReasonTooManyNotifications =>
      'Too many notifications';

  @override
  String get deleteAccountReasonTechnicalProblems => 'Technical problems';

  @override
  String get deleteAccountReasonTemporaryBreak => 'Temporary break';

  @override
  String get deleteAccountReasonOther => 'Other';

  @override
  String get deleteAccountReasonOtherHint => 'Please tell us more (required)';

  @override
  String get deleteAccountReasonValidation => 'Please select a reason';

  @override
  String get deleteAccountOtherDescriptionValidation =>
      'Please describe your reason';

  @override
  String get deleteAccountContinueButton => 'Continue';

  @override
  String get tutHomeNavTitle => 'Get around';

  @override
  String get tutHomeNavBody =>
      'Switch between Rooms, Friends, the Marketplace and your Profile from here.';

  @override
  String get tutBrowserCreateTitle => 'Create a room';

  @override
  String get tutBrowserCreateBody =>
      'Host your own room, pick a game and invite friends to play.';

  @override
  String get tutBrowserJoinCodeTitle => 'Join with a code';

  @override
  String get tutBrowserJoinCodeBody =>
      'Got an invite code? Enter it here to jump into a private room.';

  @override
  String get tutBrowserFilterTitle => 'Find a game';

  @override
  String get tutBrowserFilterBody =>
      'Filter public rooms by game type to find one that\'s open to join.';

  @override
  String get tutCreateNameTitle => 'Name your room';

  @override
  String get tutCreateNameBody =>
      'Give your room a name so friends can recognise it.';

  @override
  String get tutCreateVisibilityTitle => 'Public or private';

  @override
  String get tutCreateVisibilityBody =>
      'Public rooms show in Browse for everyone. Private rooms are invite-only.';

  @override
  String get tutCreateSpectatorsTitle => 'Spectators';

  @override
  String get tutCreateSpectatorsBody =>
      'Let people watch without playing. Spectators never affect the game.';

  @override
  String get tutCreateButtonTitle => 'Create & host';

  @override
  String get tutCreateButtonBody =>
      'You become the host — you control the room and start the game.';

  @override
  String get tutLobbyManageTitle => 'Manage your room';

  @override
  String get tutLobbyManageBody =>
      'As host you can close the room to new players, then reopen it later — without ending the game.';

  @override
  String get tutLobbyStartTitle => 'Start the game';

  @override
  String get tutLobbyStartBody =>
      'Only the host starts the game. Make sure everyone is ready first.';

  @override
  String get tutLobbyReadyTitle => 'Ready up';

  @override
  String get tutLobbyReadyBody =>
      'Tap to tell the host you\'re ready. The game starts once everyone is.';

  @override
  String get tutMembersTitle => 'Manage players';

  @override
  String get tutMembersBody =>
      'As host, tap a player to mute, kick or ban them. Muting stops them acting; kicking removes them; banning blocks their return.';

  @override
  String get tutTodTitle => 'Truth or Dare';

  @override
  String get tutTodBody =>
      'The current player is shown here. They pick Truth or Dare and complete it, then play passes on.';

  @override
  String get tutNhieTitle => 'Your turn to answer';

  @override
  String get tutNhieBody =>
      'Read the statement, then cast your answer below. Results show once everyone has answered.';

  @override
  String get tutNhieSpectatorBody =>
      'Read along and watch how everyone answers — spectators don\'t vote.';

  @override
  String get tutMemeTitle => 'React to the meme';

  @override
  String get tutMemeBody =>
      'Pick a reaction or sticker for this meme and submit. The funniest picks win the round.';

  @override
  String get tutReplayTitle => 'Replay tutorials';

  @override
  String get tutReplaySubtitle => 'Show the in-app guides again';

  @override
  String get tutReplayDone =>
      'Tutorials reset — you\'ll see them again as you go.';

  @override
  String get lobbyAnonymousSpectator => 'Anonymous spectator';

  @override
  String get packIssuesHeader => 'Fix these before submitting:';

  @override
  String get packIssueTitle => 'Add a name for every selected language';

  @override
  String get packIssueCards => 'Add at least 20 cards';

  @override
  String get packIssueLanguage =>
      'Every card needs content in all selected languages';

  @override
  String packIssuePrice(int min) {
    return 'Set a price of at least $min MRU';
  }

  @override
  String get packIssueBalance =>
      'Truth or Dare packs need an equal number of Truth and Dare cards';

  @override
  String get packIssuePunishments =>
      'Add at least 10 punishments, or remove them all';

  @override
  String get packIssueTerms => 'Accept the Pack Creation Terms';

  @override
  String get packTermsAgreePrefix => 'I agree to the ';

  @override
  String get packTermsAgreeLink => 'Pack Creation Terms';

  @override
  String get packTermsTitle => 'Pack Creation Terms';

  @override
  String get packTermsBody =>
      'By submitting a pack you confirm that: you own or have the right to share all content; the content does not infringe anyone\'s rights or contain illegal, hateful, or harassing material; you accept Jma3a\'s content review and may have the pack rejected or removed; and paid packs are subject to the platform\'s revenue and refund policies. Packs must meet the minimum price and, for Truth or Dare, contain an equal number of Truth and Dare cards.';

  @override
  String packMinPriceLabel(int min) {
    return 'Minimum price is $min MRU';
  }

  @override
  String packTruthDareBalanceHint(int truth, int dare) {
    return 'Truth or Dare packs need equal Truth and Dare cards. You have $truth Truth and $dare Dare.';
  }

  @override
  String get exploreAddFriend => 'Add Friend';

  @override
  String get exploreEmptyHint =>
      'Check back soon — new people join the discovery pool as the community grows.';

  @override
  String get exploreEmptyTitle => 'No one to discover yet';

  @override
  String get exploreLoadFailed => 'Couldn\'t load people to discover.';

  @override
  String get exploreRequestSent => 'Request Sent';

  @override
  String get exploreSearchHint => 'Search by username or name…';

  @override
  String get exploreSubtitle => 'Discover players ranked by reputation';

  @override
  String get exploreTabLabel => 'Explore';

  @override
  String get honestyReasonHint =>
      'What made this feel dishonest? (minimum 3 characters)';

  @override
  String get honestyReasonSheetTitle => 'Why wasn\'t this honest?';

  @override
  String honestyReasonsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players marked this dishonest',
      one: '1 player marked this dishonest',
    );
    return '$_temp0';
  }

  @override
  String get profileStreakActive => 'Streak active';

  @override
  String get profileStreakInactive =>
      'Streak inactive — play today to keep it going';

  @override
  String get officialResponsesTitle => 'Official Responses';

  @override
  String get officialResponsesReviews => 'Reviews';

  @override
  String get officialResponsesWarnings => 'Warnings';

  @override
  String get officialResponsesBansAndSuspensions => 'Bans & Suspensions';

  @override
  String get officialResponsesRequestsAndDecisions => 'Requests & Decisions';

  @override
  String get officialResponsesEmpty => 'Nothing here yet';

  @override
  String officialResponseExpiresOn(String date) {
    return 'Expires $date';
  }

  @override
  String get walletDepositsUnavailable =>
      'Deposits are temporarily unavailable.';

  @override
  String get walletWithdrawalsUnavailable =>
      'Withdrawals are temporarily unavailable.';

  @override
  String get walletFinanceServiceUnavailable =>
      'Finance service temporarily unavailable';

  @override
  String get authIdentifierLabel => 'Email or phone number';

  @override
  String get authIdentifierHint => 'you@example.com or 12345678';

  @override
  String get authIdentifierRequired => 'Enter your email or phone number';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordHint => 'Enter your password';

  @override
  String get authPasswordRequired => 'Password is required';

  @override
  String get authPasswordTooShort => 'Password must be at least 8 characters';

  @override
  String get authPasswordTooLong => 'Password must be at most 72 characters';

  @override
  String get authPasswordNeedsLetterAndDigit =>
      'Password must contain at least one letter and one digit';

  @override
  String get authPasswordConfirmationLabel => 'Confirm password';

  @override
  String get authPasswordConfirmationHint => 'Re-enter your password';

  @override
  String get authPasswordMismatch => 'Passwords don\'t match';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authLogIn => 'Log in';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authInvalidCredentials => 'Incorrect email/phone or password.';

  @override
  String get authSetPasswordTitle => 'Set a password';

  @override
  String get authSetPasswordSubtitle =>
      'Create a password so you can log in without a code next time';

  @override
  String get authSetPasswordSubmit => 'Start playing';

  @override
  String get authResetPasswordTitle => 'Reset your password';

  @override
  String get authResetPasswordSubtitle =>
      'Choose a new password for your account';

  @override
  String get authResetPasswordSubmit => 'Reset password';

  @override
  String get authPasswordSetSuccess => 'Password set successfully';

  @override
  String get authPasswordResetSuccess => 'Password reset successfully';

  @override
  String get authForgotPasswordTitle => 'Forgot password';

  @override
  String get authForgotPasswordSubtitle =>
      'Enter your email or phone number and we\'ll send you a code';

  @override
  String get authForgotPasswordSendCode => 'Send code';

  @override
  String get authBackToLogin => 'Back to login';

  @override
  String get authMethodPhone => 'Phone';

  @override
  String get authMethodPhoneHint => '+222 ...';

  @override
  String get authMethodEmail => 'Email';

  @override
  String get authMethodEmailHint => 'name@email.com';

  @override
  String get authSignupTitle => 'Join Jma3a 🎉';

  @override
  String get authSignupSubtitle => 'How would you like to sign up?';

  @override
  String get authContinue => 'Continue';

  @override
  String get authAlreadyHaveAccount => 'Already have an account?';

  @override
  String get authPhoneInvalid => 'Enter your 8-digit Mauritanian number';

  @override
  String get authWelcomeBack => 'Welcome back 👋';

  @override
  String get authReadyToPlay => 'Ready to play?';

  @override
  String get authLegacyNoPasswordTitle => 'No password yet';

  @override
  String get authLegacyNoPasswordBody =>
      'This account doesn\'t have a password yet. Verify with a one-time code to create one.';

  @override
  String get authVerifyWithOtp => 'Verify with OTP';

  @override
  String get authDontHaveAccount => 'Don\'t have an account?';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get passwordSettingsTitle => 'Password & Security';

  @override
  String get passwordSettingsUpdateTitle => 'Update Password';

  @override
  String get passwordSettingsUpdateSubtitle => 'Change your password securely.';

  @override
  String get passwordSettingsVerifyButton => 'Verify Current Password';

  @override
  String get passwordSettingsChangeButton => 'Change Password';

  @override
  String get passwordSettingsOtpNotice =>
      'We\'ll send a verification code to confirm it\'s you before applying this change.';

  @override
  String get passwordSettingsCurrentLabel => 'Current password';

  @override
  String get passwordSettingsNewLabel => 'New password';

  @override
  String get passwordSettingsConfirmLabel => 'Confirm new password';

  @override
  String get passwordSettingsNoPasswordTitle => 'Password';

  @override
  String get passwordSettingsNoPasswordBody =>
      'You haven\'t set a password yet.';

  @override
  String get passwordSettingsHasPasswordBody => 'Your password is set.';

  @override
  String get passwordSettingsSetButton => 'Set password with OTP';

  @override
  String get passwordSettingsChangeSuccess => 'Password changed successfully';

  @override
  String get settingsPassword => 'Password & Security';

  @override
  String get settingsPasswordSubtitleReady => 'Tap to change your password';

  @override
  String get settingsPasswordSubtitleNotSet =>
      'You haven\'t set a password yet';

  @override
  String get authAccountAlreadyExists =>
      'An account with this phone/email already exists. Please log in.';
}
