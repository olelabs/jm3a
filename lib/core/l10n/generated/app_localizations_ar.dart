// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'جماعة';

  @override
  String get introSkip => 'تخطي';

  @override
  String get introNext => 'التالي';

  @override
  String get introGetStarted => 'ابدأ الآن';

  @override
  String get introPage1Title => 'مرحبًا بك في جماعة';

  @override
  String get introPage1Body =>
      'ألعاب جماعية متعددة اللاعبين — العب مع الأصدقاء والعائلة، في أي وقت وأي مكان.';

  @override
  String get introPage2Title => 'اكتشف الحزم';

  @override
  String get introPage2Body =>
      'حزم من إبداع المجتمع، حزم بريميوم، وحزم مطبوعة يمكنك طلبها واللعب بها.';

  @override
  String get introPage3Title => 'أنشئ غرفة أو انضم إليها';

  @override
  String get introPage3Body =>
      'غرف عامة، غرف خاصة، رموز دعوة — العب مع أصدقائك بالطريقة التي تفضلها.';

  @override
  String get introPage4Title => 'مزايا بريميوم';

  @override
  String get introPage4Body =>
      'سمات مخصصة، خلفيات، مزايا حصرية، وأدوات مخصصة للمبدعين.';

  @override
  String get introPage5Title => 'جاهز للعب';

  @override
  String get introPage5Body => 'كل شيء جاهز. لنبدأ الحفلة.';

  @override
  String get settingsReplayIntro => 'إعادة عرض المقدمة';

  @override
  String get noInternetConnection => 'لا يوجد اتصال بالإنترنت';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get save => 'حفظ';

  @override
  String get done => 'تم';

  @override
  String get back => 'رجوع';

  @override
  String get skip => 'تخطي';

  @override
  String get remove => 'إزالة';

  @override
  String get no => 'لا';

  @override
  String get or => 'أو';

  @override
  String get optional => 'اختياري';

  @override
  String get error => 'حدث خطأ ما';

  @override
  String get errorNetwork => 'خطأ في الشبكة. يرجى التحقق من الاتصال.';

  @override
  String get errorUnexpected => 'حدث خطأ غير متوقع. يرجى المحاولة مجدداً.';

  @override
  String get errorForbidden => 'ليس لديك صلاحية للقيام بذلك';

  @override
  String get navRooms => 'الغرف';

  @override
  String get navFriends => 'الأصدقاء';

  @override
  String get navMarketplace => 'الباقات';

  @override
  String get navProfile => 'الملف الشخصي';

  @override
  String get authWelcome => 'مرحباً بك في جماعة';

  @override
  String get authTagline => 'العب مع أصدقائك، في أي مكان';

  @override
  String get authEmailLabel => 'بريدك الإلكتروني';

  @override
  String get authEmailHint => 'أدخل بريدك الإلكتروني';

  @override
  String get authEmailInvalid => 'يرجى إدخال بريد إلكتروني صحيح';

  @override
  String get authSendOtp => 'إرسال الرمز';

  @override
  String get authOtpLabel => 'رمز التحقق';

  @override
  String get authOtpVerify => 'تحقق';

  @override
  String get authOtpResend => 'إعادة إرسال الرمز';

  @override
  String authOtpResendIn(int seconds) {
    return 'إعادة الإرسال خلال $secondsث';
  }

  @override
  String get authOtpInvalid => 'رمز غير صحيح. يرجى المحاولة مجدداً.';

  @override
  String get onboardingTitle => 'إعداد ملفك الشخصي';

  @override
  String get onboardingSubtitle => 'اختر اسم مستخدم للبدء';

  @override
  String get onboardingUsernameLabel => 'اسم المستخدم';

  @override
  String get onboardingUsernameHint => 'أحرف وأرقام وشرطة سفلية فقط';

  @override
  String get onboardingDisplayNameLabel => 'الاسم المعروض';

  @override
  String get onboardingDisplayNameHint => 'كيف سيراك الآخرون';

  @override
  String get onboardingContinue => 'متابعة';

  @override
  String get onboardingUsernameInvalid =>
      'من 3 إلى 30 حرفاً، أحرف وأرقام وشرطة سفلية فقط';

  @override
  String get onboardingUsernameTaken => 'اسم المستخدم هذا مأخوذ بالفعل';

  @override
  String get profileEditTitle => 'تعديل الملف';

  @override
  String get profileBioLabel => 'نبذة';

  @override
  String get profileBioHint => 'أخبر الآخرين عن نفسك';

  @override
  String get profileCountryLabel => 'البلد';

  @override
  String get profileLanguageLabel => 'اللغة';

  @override
  String get profileAvatarChange => 'تغيير الصورة';

  @override
  String get profileSaved => 'تم حفظ الملف';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsTheme => 'المظهر';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeDark => 'داكن';

  @override
  String get settingsThemeSystem => 'تلقائي';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsOnlineStatus => 'حالة الاتصال';

  @override
  String get settingsOnlineStatusPremiumHint => 'الحالة اليدوية ميزة بريميوم';

  @override
  String get presenceModeAuto => 'تلقائي';

  @override
  String get presenceModeOnline => 'متصل';

  @override
  String get presenceModeOffline => 'غير متصل';

  @override
  String get settingsSignOut => 'تسجيل الخروج';

  @override
  String get settingsSignOutConfirm => 'هل أنت متأكد من تسجيل الخروج؟';

  @override
  String get settingsSectionAppearance => 'المظهر';

  @override
  String get settingsSectionAccount => 'الحساب';

  @override
  String get settingsSectionAbout => 'حول';

  @override
  String get settingsVersionLabel => 'الإصدار';

  @override
  String get settingsSigningOut => 'جارٍ تسجيل الخروج…';

  @override
  String get premiumBackgroundCustomSet => 'تم تعيين خلفية مخصصة';

  @override
  String get premiumBackgroundChooseColor => 'اختر لون الخلفية';

  @override
  String get premiumBackgroundUpgradeHint => 'ميزة بريميوم — اضغط للترقية';

  @override
  String get premiumBackgroundSaveFailed => 'تعذر حفظ لون الخلفية.';

  @override
  String get premiumBackgroundResetFailed => 'تعذرت إعادة تعيين لون الخلفية.';

  @override
  String get roomsTitle => 'الغرف';

  @override
  String get roomsCreate => 'إنشاء غرفة';

  @override
  String get roomsJoinCode => 'الانضمام برمز';

  @override
  String get roomsEnterCode => 'أدخل رمز الدعوة';

  @override
  String get roomsCodeHint => 'رمز من 6 أحرف';

  @override
  String get roomsJoin => 'انضمام';

  @override
  String roomsInvitedByName(String name) {
    return 'دعوة من $name';
  }

  @override
  String get roomsPublic => 'عامة';

  @override
  String get roomsPrivate => 'خاصة';

  @override
  String roomsPlayers(int current, int max) {
    return '$current/$max لاعبين';
  }

  @override
  String get roomsEmpty => 'لا توجد غرف الآن';

  @override
  String get roomsEmptySubtitle => 'أنشئ غرفة وادعُ أصدقاءك!';

  @override
  String get roomsFull => 'الغرفة ممتلئة';

  @override
  String get lobbyTitle => 'غرفة الانتظار';

  @override
  String get lobbyReady => 'جاهز';

  @override
  String get lobbyNotReady => 'غير جاهز';

  @override
  String get lobbyStartGame => 'بدء اللعبة';

  @override
  String get lobbyStartGameFailed => 'تعذّر بدء اللعبة — حاول مرة أخرى.';

  @override
  String get lobbyGameStarting => 'جارٍ تحضير اللعبة…';

  @override
  String get lobbyGameStartingBody => 'يرجى الانتظار أثناء تحضير اللعبة.';

  @override
  String get lobbyCopied => 'تم نسخ الرمز!';

  @override
  String get lobbyLeaveConfirm => 'هل أنت متأكد من المغادرة؟';

  @override
  String lobbyPlayerLeft(String name) {
    return 'غادر $name';
  }

  @override
  String get chatPlaceholder => 'قل شيئاً…';

  @override
  String get chatMuted => 'تم كتم صوتك';

  @override
  String get gameSettings => 'إعدادات اللعبة';

  @override
  String get gameSettingsTurnTimer => 'وقت الدور';

  @override
  String get gameSettingsAllowSkip => 'السماح بالتخطي';

  @override
  String get gameSettingsMaxRounds => 'أقصى عدد جولات';

  @override
  String gameSettingsMaxRoundsCapHint(int cap) {
    return 'الحد الأقصى $cap جولة — تحتوي هذه الحزمة على $cap بطاقة قابلة للاستخدام، وتُستخدم كل بطاقة مرة واحدة على الأكثر في كل لعبة.';
  }

  @override
  String gameSettingsSeconds(int n) {
    return '$nث';
  }

  @override
  String get gameReconnecting => 'جارٍ إعادة الاتصال…';

  @override
  String get gameConnectionLost => 'انقطع الاتصال';

  @override
  String get gameTryAgain => 'حاول مجدداً';

  @override
  String get moderationKick => 'طرد اللاعب';

  @override
  String get moderationMute => 'كتم اللاعب';

  @override
  String get moderationBan => 'حظر من الغرفة';

  @override
  String moderationKickConfirm(String name) {
    return 'هل تريد طرد $name؟';
  }

  @override
  String get moderationYouWereKicked => 'تم إخراجك من الغرفة';

  @override
  String moderationYouWereKickedBy(String name) {
    return '$name أخرجك من الغرفة';
  }

  @override
  String moderationYouWereBannedBy(String name) {
    return '$name حظرك من الغرفة';
  }

  @override
  String get settingsNotifications => 'الإشعارات';

  @override
  String get walletEarningsTotal => 'إجمالي الأرباح';

  @override
  String get walletEarningsThisMonth => 'هذا الشهر';

  @override
  String get walletEarningsTotalSales => 'إجمالي المبيعات';

  @override
  String get walletTransactionHistory => 'سجل المعاملات';

  @override
  String get walletFilterAll => 'الكل';

  @override
  String get walletFilterDeposits => 'الإيداعات';

  @override
  String get walletFilterWithdrawals => 'السحوبات';

  @override
  String get walletFilterPurchases => 'المشتريات';

  @override
  String get walletFilterEarnings => 'الأرباح';

  @override
  String get walletFilterRefunds => 'المبالغ المستردة';

  @override
  String get walletFilterPayouts => 'المستحقات';

  @override
  String get walletFilterBonuses => 'المكافآت';

  @override
  String get walletFilterAdjustments => 'التعديلات';

  @override
  String get walletFilterTransfers => 'التحويلات';

  @override
  String get walletTypeDeposit => 'إيداع';

  @override
  String get walletTypeWithdrawal => 'سحب';

  @override
  String get walletTypePurchase => 'شراء حزمة';

  @override
  String get walletTypeRefund => 'استرداد';

  @override
  String get walletTypeCommission => 'أرباح المبدع';

  @override
  String get walletTypePayout => 'دفعة مستحقات';

  @override
  String get walletTypeAdjustment => 'تعديل';

  @override
  String get walletTypeBonus => 'مكافأة';

  @override
  String get walletTypeTransfer => 'تحويل رصيد';

  @override
  String get walletStatusPending => 'قيد الانتظار';

  @override
  String get walletStatusProcessing => 'قيد المعالجة';

  @override
  String get walletStatusCompleted => 'مكتمل';

  @override
  String get walletStatusFailed => 'فشل';

  @override
  String get walletStatusCancelled => 'ملغى';

  @override
  String get walletStatusReversed => 'معكوس';

  @override
  String get walletDepositStatusPending => 'قيد الانتظار';

  @override
  String get walletDepositStatusUnderReview => 'قيد المراجعة';

  @override
  String get walletDepositStatusApproved => 'معتمد';

  @override
  String get walletDepositStatusRejected => 'مرفوض';

  @override
  String get profileGames => 'الألعاب';

  @override
  String get profileScore => 'النقاط';

  @override
  String get profileHonestyPoints => 'نقاط الصدق';

  @override
  String get honestyVoteHonest => 'صادق';

  @override
  String get honestyVoteNotHonest => 'غير صادق';

  @override
  String get honestyVoteRecorded => 'تم تسجيل تصويتك';

  @override
  String get honestyVoteFailed => 'تعذّر إرسال تصويتك — حاول مرة أخرى';

  @override
  String profileStreakDays(int count) {
    return 'سلسلة $count يوم';
  }

  @override
  String get profileFriends => 'الأصدقاء';

  @override
  String get profilePacks => 'الباقات';

  @override
  String get profileFollowers => 'المتابعون';

  @override
  String get streakNewTitle => 'سلسلة جديدة!';

  @override
  String get streakNewBody =>
      'لقد بدأت سلسلة جديدة! واصل اللعب كل يوم لتكبيرها.';

  @override
  String get streakNewCta => 'هيا بنا!';

  @override
  String streakExtendedTitle(int count) {
    return 'امتدت السلسلة! $count يوم متتالٍ!';
  }

  @override
  String streakExtendedBody(int count) {
    return '$count يوم متتالٍ! أنت مشتعل 🔥';
  }

  @override
  String get streakExtendedCta => 'متابعة';

  @override
  String get profileShareAction => 'مشاركة الملف الشخصي';

  @override
  String profileShareMessage(String name, String link) {
    return '🎮 انضم إليّ في Jma3a! تابع $name\n\n$link';
  }

  @override
  String profileShareSubject(String name) {
    return '🎮 $name على Jma3a';
  }

  @override
  String get profileShareCardCta => 'اضغط لعرض ملفي الشخصي على Jma3a';

  @override
  String get gameSettingsSpicy => 'بطاقات حارة';

  @override
  String get gameSettingsRequireApproval => 'يتطلب موافقة للانضمام';

  @override
  String get gameSettingsAllowSpectators => 'السماح بالمتفرجين';

  @override
  String get lobbyApprove => 'قبول';

  @override
  String get lobbyReject => 'رفض';

  @override
  String get authUseEmailInstead => 'استخدم البريد الإلكتروني بدلاً من ذلك';

  @override
  String get authUsePhoneInstead => 'استخدم رقم الهاتف بدلاً من ذلك';

  @override
  String get authContinueAsGuest => 'المتابعة كضيف';

  @override
  String get authTermsPrivacyNotice =>
      'بالمتابعة، أنت توافق على الشروط وسياسة الخصوصية';

  @override
  String authOtpAttemptsRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count محاولة متبقية',
      many: '$count محاولة متبقية',
      few: '$count محاولات متبقية',
      two: 'محاولتان متبقيتان',
      one: 'محاولة واحدة متبقية',
      zero: 'لا محاولات متبقية',
    );
    return '$_temp0';
  }

  @override
  String get authTakingLonger => 'يستغرق الأمر وقتاً أطول من المعتاد…';

  @override
  String get authContinueWithoutSigningIn => 'المتابعة دون تسجيل الدخول';

  @override
  String get required => 'مطلوب';

  @override
  String get onboardingGenderLabel => 'الجنس';

  @override
  String get onboardingGenderMale => 'ذكر';

  @override
  String get onboardingGenderFemale => 'أنثى';

  @override
  String get onboardingGenderRequired => 'يرجى تحديد الجنس';

  @override
  String get onboardingAgeLabel => 'العمر';

  @override
  String get onboardingAgeHint => 'عمرك (13 سنة فأكثر)';

  @override
  String get onboardingAgeRequired => 'العمر مطلوب';

  @override
  String get onboardingAgeInvalid => 'أدخل عمراً صحيحاً';

  @override
  String get onboardingAgeTooYoung => 'يجب أن يكون عمرك 13 سنة على الأقل';

  @override
  String get onboardingDisplayNameTooShort => 'حرفان على الأقل';

  @override
  String get onboardingDisplayNameTooLong => '50 حرفاً كحد أقصى';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageFrench => 'Français';

  @override
  String get backToHome => 'العودة إلى الرئيسية';

  @override
  String get chatTabLabel => 'الدردشة';

  @override
  String get checking => 'جارٍ التحقق…';

  @override
  String get defaultPlayerName => 'لاعب';

  @override
  String get deny => 'رفض';

  @override
  String get errorConnectionFailed => 'فشل الاتصال';

  @override
  String get invited => 'تمت الدعوة';

  @override
  String get kick => 'طرد';

  @override
  String get leave => 'مغادرة';

  @override
  String get ok => 'حسناً';

  @override
  String get muted => 'مكتوم';

  @override
  String get sending => 'جارٍ الإرسال…';

  @override
  String get unban => 'رفع الحظر';

  @override
  String get unmute => 'إلغاء الكتم';

  @override
  String get moderationYouWereBanned => 'تم حظرك';

  @override
  String lobbyAddAsFriend(String name) {
    return 'إضافة $name كصديق';
  }

  @override
  String get lobbyAllRequestsDecided => 'تم البت في جميع الطلبات.';

  @override
  String lobbyAreFriends(String name) {
    return 'أنت و$name أصدقاء ✓';
  }

  @override
  String get lobbyAutoLetInOnceApproved =>
      'سيتم إدخالك تلقائياً بمجرد الموافقة.';

  @override
  String lobbyBanReason(String reason) {
    return 'السبب: $reason';
  }

  @override
  String get lobbyBannedSectionTitle => '🚫 محظورون';

  @override
  String lobbyCannotSendRequest(String name) {
    return 'لا يمكن إرسال طلب إلى $name';
  }

  @override
  String get lobbyCloseRoomBody =>
      'سيؤدي إغلاق الغرفة إلى إزالة جميع اللاعبين.';

  @override
  String get lobbyCloseRoomConfirm => 'إغلاق الغرفة';

  @override
  String get lobbyCloseRoomTitle => 'إغلاق الغرفة؟';

  @override
  String get lobbyCloseKeepGameTitle => 'إغلاق هذه الغرفة؟';

  @override
  String get lobbyCloseKeepGameBody =>
      'ستختفي الغرفة من التصفح ولن يتمكن لاعبون جدد من الدخول. من يلعب الآن يكمل اللعب — لن تتوقف اللعبة ولن تُحذف الغرفة.';

  @override
  String get lobbyCloseKeepGameConfirm => 'إغلاق الغرفة';

  @override
  String get lobbyCloseKeepGameCta => 'إغلاق الغرفة';

  @override
  String get lobbyRoomClosedForNewPlayers =>
      'أغلق المضيف الغرفة أمام اللاعبين الجدد.';

  @override
  String get lobbyReopenTitle => 'إعادة فتح هذه الغرفة؟';

  @override
  String get lobbyReopenBody =>
      'ستقبل الغرفة لاعبين جدد مرة أخرى وستظهر في التصفح. لا شيء آخر يتغيّر — لا يُعاد إنشاء الغرفة ولا تُعاد أي لعبة.';

  @override
  String get lobbyReopenConfirm => 'إعادة فتح الغرفة';

  @override
  String get lobbyReopenCta => 'إعادة فتح الغرفة';

  @override
  String get lobbySelectPackBeforeStart => 'يرجى اختيار باقة قبل بدء اللعبة.';

  @override
  String lobbyRejoinDecisionFailed(String error) {
    return 'فشل: $error';
  }

  @override
  String get premiumErrorInsufficientBalance =>
      'الرصيد غير كافٍ. يرجى شحن محفظتك أولاً.';

  @override
  String get premiumErrorWalletNotFound =>
      'لم يتم العثور على المحفظة. يرجى التواصل مع الدعم.';

  @override
  String get premiumErrorWalletFrozen => 'محفظتك مجمدة. يرجى التواصل مع الدعم.';

  @override
  String get premiumErrorInvalidPlan => 'الخطة المختارة غير صالحة.';

  @override
  String get premiumErrorDowngradeBlocked =>
      'يمكنك تغيير الخطة بعد انتهاء اشتراكك الحالي.';

  @override
  String premiumErrorPurchaseFailed(String error) {
    return 'فشل الشراء: $error';
  }

  @override
  String get lobbyRoomReopened =>
      'أُعيد فتح الغرفة — يمكن للاعبين الجدد الانضمام مجددًا.';

  @override
  String get lobbyCouldNotSendRequest => 'تعذر إرسال الطلب — حاول مجدداً';

  @override
  String get lobbyDeselectAll => 'إلغاء تحديد الكل';

  @override
  String get lobbyFriendRequestPending => 'طلب الصداقة قيد الانتظار';

  @override
  String lobbyFriendRequestSent(String name) {
    return 'تم إرسال طلب صداقة إلى $name ✅';
  }

  @override
  String lobbyHiddenAnonymousCount(int count) {
    return '+ $count مجهولين (مرئي للمشرفين فقط)';
  }

  @override
  String get lobbyHowToJoin => 'كيف تريد الانضمام؟';

  @override
  String lobbyInviteCount(int count) {
    return 'دعوة $count';
  }

  @override
  String get lobbyInviteFriendsTitle => '👥 دعوة الأصدقاء';

  @override
  String get lobbyJoinRequestSentTitle => 'تم إرسال طلب الانضمام';

  @override
  String lobbyKickSpectatorBody(String name) {
    return 'إزالة $name من الغرفة.';
  }

  @override
  String get lobbyKickSpectatorTitle => 'طرد المتفرج؟';

  @override
  String get lobbyLeaveRoomTitle => 'مغادرة الغرفة؟';

  @override
  String get lobbyModerationTitle => '⚖️ الإشراف';

  @override
  String get lobbyMutedSectionTitle => '🔇 مكتومون';

  @override
  String lobbyNoFriendsMatchQuery(String query) {
    return 'لا يوجد أصدقاء يطابقون \"$query\"';
  }

  @override
  String get lobbyNoFriendsToInvite => 'لا يوجد أصدقاء لدعوتهم بعد.';

  @override
  String get lobbyNoMutedOrBanned => 'لا يوجد لاعبون مكتومون أو محظورون.';

  @override
  String get lobbyNoVisibleSpectators => 'لا يوجد متفرجون ظاهرون';

  @override
  String get lobbySpectatorsSection => 'المتفرجون';

  @override
  String lobbyPermissionsFor(String name) {
    return 'صلاحيات $name';
  }

  @override
  String get lobbyPermissionsHint => 'يمكن للمالكين تعديل هذه في أي وقت.';

  @override
  String lobbyRejoinRequestsCount(int count) {
    return 'طلبات إعادة الانضمام ($count)';
  }

  @override
  String get lobbyRoomClosedBody => 'أغلق المضيف الغرفة.';

  @override
  String get lobbyRoomClosedTitle => 'تم إغلاق الغرفة';

  @override
  String get lobbySearchFriendsHint => 'ابحث عن أصدقاء…';

  @override
  String get lobbySelectAll => 'تحديد الكل';

  @override
  String get lobbySelectPackToStart => 'اختر حزمة في الإعدادات للبدء';

  @override
  String get lobbyShareInviteLink => 'مشاركة رابط الدعوة';

  @override
  String lobbyShareInviteMessage(String code, String link) {
    return '🎮 انضم إلى غرفتي في جماعة!\n\nالرمز: $code\n\n$link';
  }

  @override
  String lobbyShareInviteSubject(String code) {
    return '🎮 رمز جماعة: $code';
  }

  @override
  String get lobbySpectateWatchHint =>
      'يريد هؤلاء اللاعبون مشاهدة اللعبة كمتفرجين.';

  @override
  String lobbySpectatorRequestCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلب مشاهدة',
      many: '$count طلب مشاهدة',
      few: '$count طلبات مشاهدة',
      two: 'طلبا مشاهدة',
      one: 'طلب مشاهدة واحد',
      zero: 'لا طلبات مشاهدة',
    );
    return '$_temp0';
  }

  @override
  String get lobbySpectatorRequestsTitle => 'طلبات المشاهدة';

  @override
  String lobbySpectatorsCount(int count) {
    return 'المتفرجون ($count)';
  }

  @override
  String get lobbyWaitingForHostApproval =>
      'بانتظار موافقة المضيف على طلب انضمامك.';

  @override
  String get lobbyWantsToRejoin => 'يريد إعادة الانضمام إلى اللعبة';

  @override
  String get lobbyWantsToSpectate => 'يريد المشاهدة';

  @override
  String get lobbyYouAreHost => 'أنت المضيف';

  @override
  String get lobbyYouAreNowOwner => 'أنت الآن مالك الغرفة 👑';

  @override
  String get defaultPackName => 'حزمة';

  @override
  String get gameNameAll => 'الكل';

  @override
  String get gameNameMeme => 'لعبة الميم';

  @override
  String get gameNameNeverHaveIEver => 'لم أفعل من قبل';

  @override
  String get gameNameTruthOrDare => 'الحقيقة أم الجرأة';

  @override
  String get gameSettingsChooseProofViewers =>
      'اختر بالضبط من يمكنه رؤية الإثبات';

  @override
  String gameSettingsMemberLabelSpectator(String name) {
    return '$name (متفرج)';
  }

  @override
  String get gameSettingsNoPacksDevMsg =>
      'لا توجد حزم متاحة. شغّل SQL التمهيدي في Supabase.';

  @override
  String get gameSettingsPackPunishments => 'عقوبات الحزمة';

  @override
  String get gameSettingsPlayersSubmit => 'يقترحها اللاعبون';

  @override
  String get gameSettingsProofCustom => 'مخصص';

  @override
  String get gameSettingsProofEveryone => 'الجميع';

  @override
  String get gameSettingsProofPlayers => 'اللاعبون';

  @override
  String get gameSettingsProofSpectators => 'المتفرجون';

  @override
  String get gameSettingsProofVisibility => 'ظهور الإثبات';

  @override
  String get gameSettingsPunishmentHintDefault =>
      'عندما يتخطى لاعب دوره، يقترح بقية اللاعبين عقوبة ويختار اللاعب المتخطي واحدة لتنفيذها.';

  @override
  String get gameSettingsPunishmentHintPackAvailable =>
      'تحتوي هذه الحزمة على عقوباتها الخاصة. اختر من يقدمها عندما يتخطى لاعب دوره.';

  @override
  String get gameSettingsPunishmentMode => 'وضع العقوبة';

  @override
  String get gameSettingsSelectPack => 'اختر حزمة';

  @override
  String get packSituationFilterTitle => 'عمّ تبحث؟';

  @override
  String get packSituationFilterSubtitle =>
      'اختياري — اختر أجواءً وسنعرض لك الحزم الأنسب أولاً.';

  @override
  String get packBestMatchTitle => 'الأنسب لك';

  @override
  String get packOtherPacksTitle => 'حزم أخرى';

  @override
  String get packMatchedLabel => 'مطابقة';

  @override
  String get packTagRelationship => 'علاقة';

  @override
  String get packTagBreakup => 'انفصال';

  @override
  String get packTagFixingRelationship => 'إصلاح العلاقة';

  @override
  String get packTagDating => 'مواعدة';

  @override
  String get packTagCouples => 'أزواج';

  @override
  String get packTagFriendship => 'صداقة';

  @override
  String get packTagFamily => 'عائلة';

  @override
  String get packTagParty => 'حفلة';

  @override
  String get packTagIcebreaker => 'كسر الجليد';

  @override
  String get packTagWork => 'عمل';

  @override
  String get packTagTravel => 'سفر';

  @override
  String get packTagLateNight => 'سهرة ليلية';

  @override
  String get packCreationTagsTitle => 'الأنواع (اختياري)';

  @override
  String get packCreationTagsSubtitle =>
      'ساعد اللاعبين على إيجاد هذه الحزمة في الوقت المناسب.';

  @override
  String get none => 'لا شيء';

  @override
  String get roleLabelPlayer => 'لاعب';

  @override
  String get roleLabelSpectator => 'متفرج';

  @override
  String roomsActiveRoomOpenBody(String name) {
    return 'غرفتك \"$name\" لا تزال مفتوحة. عد إليها، أو أغلقها لإنشاء غرفة جديدة.';
  }

  @override
  String roomsActiveRoomPausedBody(String name) {
    return 'غرفتك \"$name\" متوقفة مؤقتاً. عد إليها، أو أغلقها لإنشاء غرفة جديدة.';
  }

  @override
  String get roomsActiveRoomTitle => 'لديك بالفعل غرفة نشطة';

  @override
  String get roomsAllowSpectators => 'السماح بالمتفرجين';

  @override
  String get roomsAllowSpectatorsHint => 'يمكن للآخرين المشاهدة دون اللعب';

  @override
  String roomsAlreadyInRoomBody(String name) {
    return 'أنت لا تزال في \"$name\". لا يمكنك أن تكون لاعباً أو متفرجاً في غرفتين في آن واحد — عد إليها، أو غادرها نهائياً للانضمام إلى هذه الغرفة بدلاً منها.';
  }

  @override
  String get roomsAlreadyInRoomTitle => 'أنت بالفعل في غرفة';

  @override
  String roomsBanConfirm(String name) {
    return 'حظر $name من هذه الغرفة؟';
  }

  @override
  String get roomsBrowsePacks => 'تصفح الحزم';

  @override
  String get roomsCloseAndCreateNew => 'إغلاق الغرفة الحالية وإنشاء غرفة جديدة';

  @override
  String get roomsClosedSnackbar => 'تم إغلاق الغرفة';

  @override
  String roomsDailyLimitFreeBody(int basicLimit, int premiumLimit) {
    return 'تسمح الخطة المجانية بـ $basicLimit غرف يومياً. حاول مجدداً غداً، أو قم بالترقية إلى المميزة لـ $premiumLimit غرفة/يوم.';
  }

  @override
  String roomsDailyLimitPremiumBody(int premiumLimit) {
    return 'تسمح الخطة المميزة بـ $premiumLimit غرفة يومياً. حاول مجدداً غداً.';
  }

  @override
  String get roomsDailyLimitTitle => 'تم بلوغ الحد اليومي';

  @override
  String get roomsCreationTooSoonTitle => 'ليس بعد';

  @override
  String roomsCreationTooSoonBody(int hours, int minutes) {
    return 'يمكنك إنشاء غرفتك التالية خلال $hours س $minutes د.';
  }

  @override
  String get roomsDuration => 'المدة';

  @override
  String roomsDurationLabel(String duration) {
    return 'المدة: $duration';
  }

  @override
  String roomsGameLabel(String game) {
    return 'اللعبة: $game';
  }

  @override
  String get roomsIconFree => 'مجاني';

  @override
  String get roomsIconPremium => 'مميز ✦';

  @override
  String get roomsLeaveForGood => 'المغادرة نهائياً';

  @override
  String get roomsLeftTheGame => 'غادر اللعبة';

  @override
  String get roomsMutedInGame => 'مكتوم — مشاهدة فقط';

  @override
  String get roomsWaitingForGameApproval => 'بانتظار موافقة العودة للعبة';

  @override
  String get roomsMaxPlayers => 'الحد الأقصى للاعبين';

  @override
  String roomsMaxPlayersLabel(String count) {
    return 'الحد الأقصى للاعبين: $count';
  }

  @override
  String roomsModPermissionsCount(int count) {
    return 'مشرف · $count';
  }

  @override
  String get roomsMyClosedRooms => 'غرفي المغلقة';

  @override
  String get roomsNameHint => 'مثال: سهرة الجمعة';

  @override
  String get roomsNameLabel => 'اسم الغرفة';

  @override
  String get roomsNameTooLong => '60 حرفاً كحد أقصى';

  @override
  String get roomsNameTooShort => '3 أحرف على الأقل';

  @override
  String get roomsNoClosedRooms => 'لا توجد غرف مغلقة في آخر 5 أيام.';

  @override
  String get roomsNoGameData => 'لا توجد بيانات لعبة متاحة.';

  @override
  String get roomsNoPacksBody =>
      'تحتاج إلى حزمة واحدة على الأقل لإنشاء غرفة — احصل على حزمة مجانية أو اشترِ واحدة من المتجر أولاً.';

  @override
  String get roomsNoPacksTitle => 'لا توجد حزم متاحة';

  @override
  String roomsParticipantsCount(int count) {
    return 'المشاركون ($count)';
  }

  @override
  String roomsPlayedLabel(String date) {
    return 'لُعبت: $date';
  }

  @override
  String roomsPlayedPacksCount(int count) {
    return 'الحزم الملعوبة ($count)';
  }

  @override
  String get roomsRequestSentBody =>
      'تم إرسال طلب انضمامك. سيتم إعلامك بمجرد موافقة المضيف.';

  @override
  String get roomsRequestSentTitle => 'تم إرسال الطلب!';

  @override
  String get roomsRequireJoinApproval => 'طلب الموافقة على الانضمام';

  @override
  String get roomsRequireJoinApprovalHint => 'توافق على كل طلب انضمام';

  @override
  String get roomsRequireSpectatorApproval => 'طلب الموافقة على المشاهدة';

  @override
  String get roomsRequireSpectatorApprovalHint =>
      'توافق على كل طلب مشاهدة، منفصلاً عن موافقة انضمام اللاعبين';

  @override
  String get roomsResults => 'النتائج';

  @override
  String get roomsReturnToMyRoom => 'العودة إلى غرفتي';

  @override
  String get roomsRoomIcon => 'أيقونة الغرفة';

  @override
  String get roomsRoomInfo => 'معلومات الغرفة';

  @override
  String roomsStillInRoomBody(String name) {
    return 'أنت لا تزال في \"$name\". غادرها قبل إنشاء غرفة جديدة.';
  }

  @override
  String roomsSupportsUpToPlayers(int count) {
    return 'تدعم غرفتك حتى $count لاعبين';
  }

  @override
  String get roomsTransferOwnership => 'نقل الملكية';

  @override
  String get roomsUpgradeArrow => 'الترقية ←';

  @override
  String get roomsVisibility => 'الظهور';

  @override
  String roomsWinnerLabel(String name) {
    return '🏆 الفائز: $name';
  }

  @override
  String get gameNameNeverHaveIEverFull => 'لم أفعل من قبل أبداً';

  @override
  String get defaultGameName => 'لعبة';

  @override
  String get chatDisabledForRoom => 'الدردشة معطلة في هذه الغرفة';

  @override
  String get chatNoMessagesYet => 'لا توجد رسائل بعد';

  @override
  String get chatSayHint => 'اكتب شيئًا…';

  @override
  String get chatSendFailed =>
      'فشل إرسال الرسالة — اضغط على إرسال للمحاولة مرة أخرى';

  @override
  String chatReplyingTo(String name) {
    return 'الرد على $name';
  }

  @override
  String get chatCancelReply => 'إلغاء الرد';

  @override
  String get chatAudienceEveryone => 'الجميع';

  @override
  String chatAudienceOnly(String names) {
    return 'فقط: $names';
  }

  @override
  String get chatAudiencePickerTitle => 'من يمكنه رؤية هذه الرسالة؟';

  @override
  String get chatAudienceSelectPeople => 'اختيار أشخاص';

  @override
  String get chatAudienceNoOneAvailable =>
      'لا يوجد أشخاص آخرون متاحون للاختيار الآن.';

  @override
  String get chatAudienceApply => 'تم';

  @override
  String chatTargetedIndicatorSender(String names) {
    return 'مرئية فقط لـ $names';
  }

  @override
  String get chatTargetedIndicatorRecipient =>
      'أُرسلت إليك وإلى أشخاص محددين فقط';

  @override
  String get chatAudienceRequiresPremiumPlus =>
      'يمكن لأعضاء بريميوم بلس فقط استهداف أشخاص محددين.';

  @override
  String get chatAudienceRecipientUnavailable =>
      'أحد الأشخاص المختارين لم يعد متاحًا.';

  @override
  String get chatAudienceNoLongerRoomMember =>
      'لم تعد جزءًا من هذه الغرفة/اللعبة.';

  @override
  String get failed => 'فشل';

  @override
  String get photo => 'صورة';

  @override
  String get premiumBadge => '✨ مميز';

  @override
  String get preview => 'معاينة';

  @override
  String todActivityAnswering(String name) {
    return '$name يجيب…';
  }

  @override
  String todActivityChoosing(String name) {
    return '$name يختار…';
  }

  @override
  String todActivityFinishingUp(String name) {
    return '$name على وشك الانتهاء…';
  }

  @override
  String todActivityPerforming(String name) {
    return '$name ينفذ…';
  }

  @override
  String todActivityUploadingProof(String name) {
    return '$name يرفع إثباتاً…';
  }

  @override
  String get todAddCardToDeck => 'إضافة البطاقة إلى المجموعة';

  @override
  String get todAddCustomCardButton => 'إضافة بطاقة مخصصة';

  @override
  String get todAddCustomCardTitle => 'إضافة بطاقة مخصصة';

  @override
  String get todAddDescriptionOptional => 'أضف وصفاً (اختياري)…';

  @override
  String get todAnswerRequiredHint => 'إجابتك مطلوبة…';

  @override
  String todChoosingTruthOrDare(String name) {
    return '$name يختار الحقيقة أم الجرأة…';
  }

  @override
  String get todCompleteTurn => 'إنهاء الدور';

  @override
  String get todCompletedTurn => 'أنهى دوره!';

  @override
  String get todCustomCardAdded => '✅ تمت إضافة البطاقة المخصصة إلى المجموعة!';

  @override
  String get todCustomCardSessionOnly =>
      'ستُضاف هذه البطاقة إلى المجموعة لهذه الجلسة فقط.';

  @override
  String get todDare => 'جرأة';

  @override
  String todDefaultPlayerNumbered(String id) {
    return 'اللاعب $id';
  }

  @override
  String get todDifficultyLabel => 'الصعوبة';

  @override
  String get todDoneButton => 'تم! ✅';

  @override
  String get todEndGame => 'إنهاء اللعبة';

  @override
  String get todEndGameBody => 'سينهي هذا اللعبة لجميع اللاعبين.';

  @override
  String get todEndGameTitle => 'إنهاء اللعبة؟';

  @override
  String todLikedResponseVotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '👍 أعجبتني هذه الإجابة ($count صوت)',
      many: '👍 أعجبتني هذه الإجابة ($count صوتاً)',
      few: '👍 أعجبتني هذه الإجابة ($count أصوات)',
      two: '👍 أعجبتني هذه الإجابة (صوتان)',
      one: '👍 أعجبتني هذه الإجابة (صوت واحد)',
      zero: '👍 أعجبتني هذه الإجابة (لا أصوات)',
    );
    return '$_temp0';
  }

  @override
  String get todNextTurn => 'الدور التالي ←';

  @override
  String get todNoCardAvailable =>
      'لا توجد بطاقة متاحة — تم استخدام جميع البطاقات!';

  @override
  String todPointsAbbrev(int points) {
    return '$points نقطة';
  }

  @override
  String todQuotedResponse(String response) {
    return '«$response»';
  }

  @override
  String get todProofTimerLabel => 'مدة العرض';

  @override
  String get todProofTimerNoLimit => 'بدون حد';

  @override
  String get todProofVisibilityLabel => 'من يمكنه رؤية هذا؟';

  @override
  String get todProofVisibilityEveryone => 'الجميع';

  @override
  String get todProofVisibilityPlayersOnly => 'اللاعبون فقط';

  @override
  String get todProofVisibilitySpectatorsOnly => 'المتفرجون فقط';

  @override
  String get todProofVisibilityPersonalized => 'مخصص';

  @override
  String get todProofVisibilityNoOneElse => 'لا يوجد أحد آخر في الغرفة بعد.';

  @override
  String get todProofVisibilityPickAtLeastOne => 'اختر شخصًا واحدًا على الأقل.';

  @override
  String get todReactLabel => 'التفاعل:';

  @override
  String get todReadyForNextTurn => 'أنا جاهز للدور التالي';

  @override
  String get todReadyWaitingHost => '✓ أنت جاهز — بانتظار متابعة المضيف…';

  @override
  String get todRecording => 'جارٍ التسجيل…';

  @override
  String get todSkipTurnMod => 'تخطي الدور (مشرف)';

  @override
  String get todSpectatingWaitingHost => 'تشاهد — بانتظار متابعة المضيف…';

  @override
  String get todSpicyBadge => '🌶 حارّ';

  @override
  String get todStopRecording => 'إيقاف التسجيل';

  @override
  String get todSubmitCompleteTurn => 'إرسال وإنهاء الدور ✅';

  @override
  String get todTruth => 'حقيقة';

  @override
  String get todChooseYourChallenge => 'اختر تحديك';

  @override
  String todPlayerIsChoosing(String name) {
    return '$name يختار…';
  }

  @override
  String get todTruthChoiceDescription => 'أجب عن سؤال شخصي بصدق.';

  @override
  String get todDareChoiceDescription => 'أكمل تحديًا جريئًا.';

  @override
  String get todSkipCardConfirmTitle => 'تخطي هذه البطاقة؟';

  @override
  String get todSkipCardConfirmBody =>
      'قد يؤدي التخطي إلى تصويت جماعي على عقوبة.';

  @override
  String get todStatRounds => 'الجولات';

  @override
  String get todStatPlayers => 'اللاعبون';

  @override
  String get todStatTotalTurns => 'إجمالي الأدوار';

  @override
  String get todDareBadge => 'تحدي';

  @override
  String get todTruthBadge => 'حقيقة';

  @override
  String get nhieBadgeAllCaps => 'لم أفعل هذا قط';

  @override
  String get memeBadgeAllCaps => 'مطالبة ميم';

  @override
  String get memePickStickerFirst => 'اختر ملصقًا أولاً';

  @override
  String get memeSubmitResponseButton => 'إرسال الرد';

  @override
  String get gameNotStartedYet => 'لم تبدأ اللعبة بعد';

  @override
  String get gameNotReady => 'اللعبة غير جاهزة';

  @override
  String get todTruthRequiresResponse => 'الحقيقة تتطلب إجابة';

  @override
  String get todDareRequiresResponseOrProof =>
      'أضف وصفاً أو أرفق إثباتاً قبل المتابعة';

  @override
  String get todProofVoteRequiresVoice =>
      'صوّتت المجموعة لإثبات صوتي — سجّل واحداً للمتابعة';

  @override
  String get todProofVoteRequiresImage =>
      'صوّتت المجموعة لإثبات بالصورة — أرفق صورة للمتابعة';

  @override
  String get todTypeDare => '🔥 جرأة';

  @override
  String get todTypeTruth => '🤔 حقيقة';

  @override
  String todVoiceMaxSeconds(int n) {
    return 'صوت (بحد أقصى $n ثانية)';
  }

  @override
  String get todVoiceProofRecorded => 'تم تسجيل الإثبات الصوتي';

  @override
  String get todVoiceProofTitle => 'الإثبات الصوتي';

  @override
  String todVotedForResponseTotal(int count) {
    return '✓ صوّتّ لهذه الإجابة ($count إجمالاً)';
  }

  @override
  String todWaitingForToFinishReading(String names) {
    return 'بانتظار $names لإنهاء القراءة…';
  }

  @override
  String get todWriteCardPromptHint => 'اكتب نص بطاقتك…';

  @override
  String get someone => 'شخص ما';

  @override
  String get todAllPlayersLeftGameBody => 'غادر جميع اللاعبين اللعبة.';

  @override
  String get todAllPlayersLeftGameEnded => 'غادر جميع اللاعبين — انتهت اللعبة';

  @override
  String get todChatTitle => '💬 الدردشة';

  @override
  String get todGameEnded => 'انتهت اللعبة';

  @override
  String get todGameOver => 'انتهت اللعبة';

  @override
  String get todGamePausedTitle => 'اللعبة متوقفة مؤقتاً';

  @override
  String get todGoToLobby => 'الذهاب إلى غرفة الانتظار';

  @override
  String todHistoryRoundsCount(int count) {
    return 'السجل ($count جولة)';
  }

  @override
  String get todHostEndedGame => 'أنهى المضيف اللعبة';

  @override
  String get todHostEndedGameBody => 'أنهى المضيف اللعبة.';

  @override
  String get todHostSteppedAway => 'ابتعد المضيف مؤقتاً وسيعود قريباً.';

  @override
  String get todLeaveForNow => 'المغادرة الآن';

  @override
  String get todNoRoundsYet => 'لم تكتمل أي جولة بعد.';

  @override
  String todPlayerLeftGame(String name) {
    return '👋 غادر $name اللعبة';
  }

  @override
  String get todForcePunishmentTooltip => 'فرض هذه العقوبة';

  @override
  String get todPunishmentModeOn => 'وضع العقوبة مفعّل';

  @override
  String get todQuitGame => 'الخروج من اللعبة';

  @override
  String get todQuitGameBody => 'مغادرة اللعبة الحالية؟';

  @override
  String get todQuitGameTitle => 'الخروج من اللعبة؟';

  @override
  String get todRemovedFromGame => 'تمت إزالتك من هذه اللعبة';

  @override
  String todRoundTypeContent(String type, String content) {
    return '$type: $content';
  }

  @override
  String todScreenshotTaken(String name) {
    return '📸 التقط $name لقطة شاشة';
  }

  @override
  String get todSkipped => 'تم التخطي';

  @override
  String todProofWatchedByCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'شوهد الإثبات من قبل $count',
      zero: 'تم إرسال الإثبات — لم يُشاهد بعد',
    );
    return '$_temp0';
  }

  @override
  String todReplayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إعادة مشاهدة',
      many: '$count إعادة مشاهدة',
      few: '$count إعادات مشاهدة',
      two: 'إعادتا مشاهدة',
      one: 'إعادة مشاهدة واحدة',
      zero: 'لا إعادة مشاهدة بعد',
    );
    return '$_temp0';
  }

  @override
  String todVoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '👍 $count صوت',
      many: '👍 $count صوتاً',
      few: '👍 $count أصوات',
      two: '👍 صوتان',
      one: '👍 صوت واحد',
      zero: '👍 لا أصوات',
    );
    return '$_temp0';
  }

  @override
  String get todYouAreNowHost => '👑 أنت الآن مضيف اللعبة!';

  @override
  String get secAbbrev => 'ث';

  @override
  String get submit => 'إرسال';

  @override
  String get todConfigTitle => 'إعداد الحقيقة أم الجرأة';

  @override
  String get todConfigSubtitle =>
      'قم بتهيئة هذه اللعبة قبل بدئها — لن تتمكن من تغييرها بعد البدء.';

  @override
  String get todConfigForceDareTitle => 'قواعد إجبار الجرأة';

  @override
  String get todConfigForceDareUnlimited => 'غير محدود';

  @override
  String get todConfigForceDarePerPlayer => 'لكل لاعب';

  @override
  String get todConfigForceDarePerTurn => 'لكل دور';

  @override
  String get todConfigMaxTruths => 'الحد الأقصى للحقائق';

  @override
  String get todConfigCardRepetitionTitle => 'تكرار البطاقات';

  @override
  String get todConfigCardRepetitionShuffle => 'خلط مستمر';

  @override
  String get todConfigCardRepetitionUnique => 'بطاقات فريدة';

  @override
  String todConfigUniqueCardsCapHint(int count) {
    return 'تحتوي هذه الحزمة على $count بطاقة — لا يمكن أن يتجاوز الحد الأقصى للجولات ما هو متاح بمجرد استخدام كل بطاقة مرة واحدة على الأكثر لكل دور لاعب.';
  }

  @override
  String get todConfigConfirmStart => 'تأكيد وبدء اللعبة';

  @override
  String get gameSettingsPackAlreadyPlayed =>
      'تم لعب هذه الحزمة بالفعل في هذه الغرفة. اختر حزمة أخرى.';

  @override
  String get todForcedDareHint => 'لقد استنفدت حقائقك الآن — الجرأة فقط.';

  @override
  String get todEndReasonDefault => 'انتهت اللعبة';

  @override
  String get todEndReasonManual => 'أنهى المضيف اللعبة';

  @override
  String get todEndReasonRoundLimit => 'اكتملت جميع الجولات';

  @override
  String get todEndReasonScoreLimit => 'تم بلوغ حد النقاط';

  @override
  String get todEndReasonCardsExhausted => 'تم استخدام جميع البطاقات الفريدة';

  @override
  String get todEveryoneElsePickingPunishment =>
      'بقية اللاعبين يختارون عقوبة لك.';

  @override
  String get todGameOverBang => 'انتهت اللعبة!';

  @override
  String get todLeaderboard => 'لوحة المتصدرين';

  @override
  String get todLoadingGame => 'جارٍ تحميل اللعبة…';

  @override
  String todWaitingForPlayers(int ready, int total) {
    return 'بانتظار انضمام اللاعبين الآخرين… (جاهز $ready/$total)';
  }

  @override
  String get hostReconnectWaitingTitle => 'في انتظار عودة المضيف…';

  @override
  String hostReconnectWaitingBody(int seconds) {
    return 'اللعبة متوقفة مؤقتًا. ستنتهي تلقائيًا خلال $seconds ثانية إذا لم يعد المضيف.';
  }

  @override
  String todOnlyPlayerCanPick(String name) {
    return '$name فقط يمكنه الاختيار — يمكن للمشرف الإجبار إذا لم يستجب.';
  }

  @override
  String get todPhaseChoosing => 'يختار';

  @override
  String get todPhaseCompleting => 'جارٍ الإنهاء…';

  @override
  String get todPhaseInProgress => 'قيد التنفيذ';

  @override
  String get todPhaseVoting => '⚠️ تصويت';

  @override
  String todPlayerSkipped(String name) {
    return 'تخطى $name!';
  }

  @override
  String todRoundBadge(int round, int maxRound) {
    return 'الجولة $round / $maxRound';
  }

  @override
  String todSubmitPunishmentFor(String name) {
    return 'اقترح عقوبة واحدة لـ $name:';
  }

  @override
  String todSubmittedCount(int submitted, int expected) {
    return '$submitted / $expected تم الإرسال';
  }

  @override
  String get todSubmittedWaitingForOthers => 'تم الإرسال — بانتظار البقية…';

  @override
  String get todTimeForPunishment => 'حان وقت العقوبة…';

  @override
  String get todWaitingChoosingQuestion => 'الحقيقة أم الجرأة؟';

  @override
  String todWinnerWins(String name) {
    return '$name يفوز!';
  }

  @override
  String get todYouSkipped => 'لقد تخطيت…';

  @override
  String errorPrefix(String error) {
    return 'خطأ: $error';
  }

  @override
  String get nhieAddCommentOptional => 'أضف تعليقاً (اختياري)…';

  @override
  String nhieAnsweredCount(int count, int total) {
    return '$count/$total أجابوا';
  }

  @override
  String get nhieCardPromptHint => 'لم أفعل من قبل…';

  @override
  String get nhieCardTitle => 'لم أفعل من قبل أبداً…';

  @override
  String nhieDrinksScore(int count) {
    return '$count 🍹';
  }

  @override
  String nhieDrinksTotal(int count) {
    return '🍹 $count';
  }

  @override
  String get nhieGameHistoryTitle => 'سجل اللعبة';

  @override
  String get nhieGoToHome => 'الذهاب إلى الرئيسية';

  @override
  String get gameBackToRoom => 'العودة إلى الغرفة';

  @override
  String get nhieIHave => 'فعلتها';

  @override
  String get nhieMostDrinksWins => 'صاحب أكثر 🍹 يفوز!';

  @override
  String get nhieNever => 'أبداً';

  @override
  String get nhieTimedOut => 'انتهى الوقت — لم تستجب في الوقت المحدد';

  @override
  String get nhieNextCard => 'البطاقة التالية ←';

  @override
  String get nhiePlayAnotherHandOff => 'لعب بطاقة أخرى وتسليم الدور';

  @override
  String get nhieReadyForNextRound => 'أنا جاهز للجولة التالية';

  @override
  String nhieViewHistoryCount(int count) {
    return 'عرض السجل ($count جولة)';
  }

  @override
  String nhieWaitingCount(int count, int total) {
    return 'الانتظار… $count/$total';
  }

  @override
  String get nhieWaitingForPlayersReady => 'بانتظار استعداد اللاعبين…';

  @override
  String get nhieWhoTakesOver => 'من سيتولى؟';

  @override
  String get memeAddCaptionOptional => 'أضف تعليقاً (اختياري)…';

  @override
  String get memeCustomPromptSessionOnly =>
      'سيُضاف هذا الموجه إلى المجموعة لهذه الجلسة فقط.';

  @override
  String get memeFunniestPlayerWins => 'الأكثر إضحاكاً يفوز!';

  @override
  String get memeNextRound => 'الجولة التالية ←';

  @override
  String get memePassVote => 'تخطي — جاهز للجولة التالية';

  @override
  String get memePickSticker => 'اختر ملصقك:';

  @override
  String memePlayersVoted(int count, int total) {
    return '$count/$total صوّتوا';
  }

  @override
  String memeResponseNumber(int n) {
    return 'الإجابة رقم $n';
  }

  @override
  String get memeResponseSubmittedWaiting =>
      'تم إرسال الإجابة! بانتظار البقية…';

  @override
  String memeRoundBadgeAllCaps(int round) {
    return 'الجولة $round';
  }

  @override
  String memeRoundResultsTitle(int round) {
    return 'نتائج الجولة $round 🏆';
  }

  @override
  String get memeSpectatingWaitingSubmit => 'تشاهد — بانتظار إرسال اللاعبين…';

  @override
  String memeSubmittedCount(int submitted, int total) {
    return '$submitted / $total تم الإرسال';
  }

  @override
  String get memeTapAnywhereToClose => 'اضغط في أي مكان للإغلاق';

  @override
  String get memeTapToExpand => 'اضغط للتوسيع';

  @override
  String get memeTapToSeeReaction => 'اضغط لرؤية ردة فعلهم';

  @override
  String get memeTie => 'تعادل';

  @override
  String memeTrophyScore(int count) {
    return '$count 🏆';
  }

  @override
  String get memeVoteForBest => 'صوّت للأفضل! 😂';

  @override
  String get memeVoteForThis => 'صوّت لهذا 👍';

  @override
  String get memeVotedWaiting => 'تم التصويت! بانتظار البقية…';

  @override
  String memeVotesAbbrev(int count) {
    return '$count 👍';
  }

  @override
  String memeVotesCount(int count, int total) {
    return '$count / $total صوّتوا';
  }

  @override
  String memeWinnerLabel(String name) {
    return 'الفائز: $name';
  }

  @override
  String get memeWinsThisRound => 'يفوز بهذه الجولة!';

  @override
  String get memeWritePromptHint => 'اكتب موجه الميم الخاص بك…';

  @override
  String get memeYourResponse => 'إجابتك';

  @override
  String get memeYourVote => '✓ تصويتك';

  @override
  String get exit => 'خروج';

  @override
  String get offlineAcceptChallenge => 'اقبل التحدي';

  @override
  String get offlineAddCaptionOptional => 'أضف تعليقاً (اختياري)…';

  @override
  String get offlineAddProofPhoto => 'أضف صورة إثبات (مشاهدة واحدة)';

  @override
  String get offlineAnswerHonestly => 'أجب بصدق';

  @override
  String get offlineBackToMenu => 'العودة إلى القائمة';

  @override
  String get offlineChooseYourFate => 'اختر مصيرك';

  @override
  String get offlineCompleteTurnCheck => 'إنهاء الدور ✅';

  @override
  String offlineCompletedName(String name) {
    return 'أنهى $name!';
  }

  @override
  String offlineCouldNotPickImage(String error) {
    return 'تعذر اختيار الصورة: $error';
  }

  @override
  String get offlineDareLabel => 'جرأة';

  @override
  String get offlineDoneCheck => '✓ تم';

  @override
  String get offlineFinalScores => 'النتائج النهائية';

  @override
  String get offlineGameHistoryTitle => '📖 سجل اللعبة';

  @override
  String get offlineGameOverTrophy => 'انتهت اللعبة 🏆';

  @override
  String offlineGameTypeAndPack(String gameType, String packName) {
    return '$gameType • $packName';
  }

  @override
  String offlineGoodOneVotes(int count) {
    return '👍 جيدة! ($count)';
  }

  @override
  String get offlineHistoryTab => '📖 السجل';

  @override
  String offlineIsDeciding(String name) {
    return '$name يقرر…';
  }

  @override
  String get offlineKickConfirmBody => 'سيتم إزالته من غرفة الانتظار.';

  @override
  String offlineKickConfirmTitle(String name) {
    return 'طرد $name؟';
  }

  @override
  String get offlineMemeBadge => '😂  ميم';

  @override
  String get offlineMemeChampion => 'بطل الميم!';

  @override
  String offlineMyVoteCount(String voteLabel, int count, int total) {
    return '$voteLabel ($count/$total)';
  }

  @override
  String get offlineNeverHaveIEverBadge => 'لم أفعل من قبل…';

  @override
  String get offlineNextTurnShort => 'الدور التالي';

  @override
  String get offlineNoHistoryAvailable => 'لا يوجد سجل متاح';

  @override
  String get offlineNoRoundsCompleted => 'لم تكتمل أي جولة بعد';

  @override
  String get offlineNoTurnsCompleted => 'لم يكتمل أي دور بعد';

  @override
  String get offlinePackCover => 'غلاف الحزمة';

  @override
  String get offlinePickFavourite => 'اختر المفضل لديك:';

  @override
  String get offlinePickReaction => 'اختر ردة فعل:';

  @override
  String get offlinePickReactionColon => 'اختر ردة فعلك:';

  @override
  String offlinePlayersCount(int count) {
    return '$count لاعبين';
  }

  @override
  String get offlinePlayersInLobby => 'اللاعبون في غرفة الانتظار';

  @override
  String get offlinePreviousCards => 'البطاقات السابقة';

  @override
  String get offlineProofViewed => '📷 تمت مشاهدة الإثبات';

  @override
  String offlineRoundColonCaption(int round, String caption) {
    return 'الجولة $round: $caption';
  }

  @override
  String offlineRoundOf(int round, int maxRounds) {
    return 'الجولة $round من $maxRounds';
  }

  @override
  String get offlineSayHiToGroup => 'قل مرحباً للمجموعة!';

  @override
  String get offlineScoresTab => '🏆 النتائج';

  @override
  String get offlineSkippedCross => '✗ تم التخطي';

  @override
  String offlineSubmissionTitle(String name) {
    return 'إجابة $name';
  }

  @override
  String offlineSubmitCount(int count, int total) {
    return 'إرسال ($count/$total)';
  }

  @override
  String get offlineSubmitExclaim => 'إرسال!';

  @override
  String get offlineSubmittedWaitingCheck => '✅ تم الإرسال! بانتظار البقية…';

  @override
  String get offlineTapAgainToDismiss => 'اضغط مجدداً للإغلاق';

  @override
  String get offlineTapToDismiss => 'اضغط للإغلاق';

  @override
  String get offlineTapToRevealProof => 'اضغط لكشف صورة الإثبات';

  @override
  String offlineTimerSeconds(int seconds) {
    return '$seconds ث';
  }

  @override
  String get offlineTruthLabel => 'حقيقة';

  @override
  String offlineVoteCountBallot(int count) {
    return '$count 🗳️';
  }

  @override
  String get offlineVoteForBestNoEmoji => 'صوّت للأفضل!';

  @override
  String offlineVotesExclaim(String name) {
    return '$name يصوّت!';
  }

  @override
  String get offlineWaitingForHost => 'بانتظار المضيف…';

  @override
  String get offlineWaitingForHostToStart => 'بانتظار بدء المضيف…';

  @override
  String offlineWaitingForMore(int count) {
    return 'بانتظار $count آخرين…';
  }

  @override
  String get offlineWaitingHostAdvance => 'بانتظار متابعة المضيف…';

  @override
  String get ptsSuffix => ' نقطة';

  @override
  String get gameLabel => 'اللعبة';

  @override
  String get offlineBulletDownloadedPacks =>
      'الحزم التي تم تنزيلها تعمل دون اتصال بالكامل — لا حاجة للإنترنت.';

  @override
  String get offlineBulletLan =>
      'الشبكة المحلية: كل لاعب على هاتفه، بنفس الواي فاي أو نقطة الاتصال.';

  @override
  String get offlineBulletPassPlay =>
      'التمرير واللعب: هاتف واحد، يُمرَّر بين اللاعبين كل دور.';

  @override
  String get offlineChooseMode => 'اختر الوضع';

  @override
  String get offlineCreateLanRoomHint => 'أنشئ غرفة شبكة محلية على جهازك';

  @override
  String get offlineDiscard => 'تجاهل';

  @override
  String get offlineDownloadPackFirst => 'نزّل حزمة أولاً للاستضافة';

  @override
  String get offlineEnable18Cards => 'تفعيل بطاقات +18';

  @override
  String get offlineEnterNameAboveToJoin => 'أدخل اسمك أعلاه للانضمام';

  @override
  String get offlineEnterNameToJoin => 'أدخل اسمك للانضمام';

  @override
  String get offlineFailedToStart => 'فشل البدء';

  @override
  String get offlineFindNearbyLanRooms =>
      'ابحث عن غرف شبكة محلية قريبة للانضمام';

  @override
  String get offlineGoBack => 'العودة';

  @override
  String get offlineHostBadge => 'مضيف';

  @override
  String get offlineHostRoom => 'استضافة غرفة';

  @override
  String offlineHostsRoom(String name) {
    return 'غرفة $name';
  }

  @override
  String get offlineHowItWorks => 'ℹ️  كيف يعمل الوضع دون اتصال';

  @override
  String get offlineJoinLanRoomTitle => 'الانضمام لغرفة شبكة محلية';

  @override
  String get offlineJoinRoom => 'الانضمام لغرفة';

  @override
  String get offlineJoinRoomButton => 'الانضمام للغرفة';

  @override
  String get offlineLanMultiplayer => 'متعدد اللاعبين عبر الشبكة المحلية';

  @override
  String get offlineLanRoom => 'غرفة الشبكة المحلية';

  @override
  String get offlineLoadingCards => 'جارٍ تحميل البطاقات…';

  @override
  String get offlineNearbyRooms => 'الغرف القريبة';

  @override
  String offlineNoPacksDownloaded(String gameType) {
    return 'لا توجد حزم $gameType تم تنزيلها. اتصل بالإنترنت لتنزيل الحزم.';
  }

  @override
  String get offlineOtherPlayersJoinInstructions =>
      'اللاعبون الآخرون: افتح جماعة ← العب ← شبكة محلية ← الانضمام لغرفة';

  @override
  String offlinePackExpiry(int day, int month) {
    return 'الانتهاء: $day/$month';
  }

  @override
  String offlinePackMeta(int count, String lang, String status) {
    return '$count بطاقة · $lang · $status';
  }

  @override
  String offlinePackPlayersCount(String packName, int count) {
    return '$packName · $count لاعبين';
  }

  @override
  String get offlinePlayTitle => 'اللعب دون اتصال';

  @override
  String offlinePlayersCountDash(int count) {
    return 'اللاعبون — $count';
  }

  @override
  String get offlineResume => 'استئناف';

  @override
  String get offlineResumeGame => 'استئناف اللعبة';

  @override
  String get offlineRoomBroadcasting => 'الغرفة تبث الآن';

  @override
  String offlineRoomMeta(String gameType, String packName, int count, int max) {
    return '$gameType • $packName • $count/$max لاعبين';
  }

  @override
  String offlineRoundsSlider(int count) {
    return 'الجولات: $count';
  }

  @override
  String get offlineSameWifiHint =>
      'تأكد أن جهاز المضيف على نفس شبكة الواي فاي.';

  @override
  String get offlineScanningForRooms => 'جارٍ البحث عن غرف…';

  @override
  String get offlineSetupFailed => 'فشل الإعداد.';

  @override
  String get offlineSignInToDownload =>
      'سجّل الدخول لتنزيل الحزم وفتح جميع الألعاب.';

  @override
  String get offlineSpicyContent => 'محتوى حار';

  @override
  String offlineTimerSecsLabel(int secs) {
    return 'المؤقت: $secs ث';
  }

  @override
  String get offlineYourName => 'اسمك';

  @override
  String get purchased => 'تم الشراء';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get tryAgain => 'حاول مجدداً';

  @override
  String get accountLabel => 'الحساب';

  @override
  String get amountLabel => 'المبلغ';

  @override
  String get copiedNotice => 'تم النسخ!';

  @override
  String labelColonSuffix(String label) {
    return '$label: ';
  }

  @override
  String get nameLabel => 'الاسم';

  @override
  String get pendingLabel => 'قيد الانتظار';

  @override
  String get phoneInvalid => 'يجب أن يتكون رقم الهاتف من 8 أرقام بالضبط';

  @override
  String get refresh => 'تحديث';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get walletAmountToWithdraw => 'المبلغ المراد سحبه';

  @override
  String walletAmountValue(String amount) {
    return 'المبلغ: $amount أوقية';
  }

  @override
  String walletAvailableAmount(String amount) {
    return 'المتاح: $amount';
  }

  @override
  String get walletAvailableEarnings => 'الأرباح المتاحة';

  @override
  String get walletAvailableForWithdrawal => 'متاح للسحب';

  @override
  String get walletBackToWallet => 'العودة إلى المحفظة';

  @override
  String get walletBalanceAfter => 'الرصيد بعد العملية';

  @override
  String get walletBulletCreditedAfterConfirm =>
      'تُضاف الأرباح بعد تأكيد الشراء.';

  @override
  String get walletBulletEarn85 => 'تكسب 85% من كل عملية بيع حزمة.';

  @override
  String get walletBulletMinWithdrawal => 'الحد الأدنى للسحب: 500 أوقية.';

  @override
  String get walletBulletPlatformFee => 'رسوم المنصة 15% تُبقي جماعة تعمل.';

  @override
  String get walletChooseHowToAddFunds => 'اختر كيف تريد إضافة الأموال.';

  @override
  String get walletConfirmWithdrawal => 'تأكيد السحب';

  @override
  String get walletCreateSellPacksHint => 'أنشئ وبِع حزماً لتكسب عمولات.';

  @override
  String get walletCreatorEarningsRateLabel => 'معدل أرباح المنشئ';

  @override
  String get walletCreatorEarningsTitle => 'أرباح المنشئ';

  @override
  String get walletCurrencyName => 'الأوقية الموريتانية';

  @override
  String get walletDeposit => 'إيداع';

  @override
  String walletDepositAmount(String amount) {
    return 'إيداع $amount';
  }

  @override
  String get walletDepositWarningNotice =>
      'أرسل الطلب فقط بعد إتمام التحويل. تتم مراجعة الإيداعات يدوياً وقد تستغرق من 1 إلى 24 ساعة.';

  @override
  String get walletEarningsBalance => 'رصيد الأرباح';

  @override
  String get walletEnterReference => 'أدخل مرجع عملية الدفع';

  @override
  String get walletHowEarningsWork => 'كيف تعمل الأرباح';

  @override
  String get walletInsufficientBalance => 'الرصيد غير كافٍ';

  @override
  String get walletMaxDeposit => 'الحد الأقصى للإيداع: 1,000,000 أوقية';

  @override
  String get walletMethodLabel => 'الطريقة';

  @override
  String get walletMinDeposit => 'الحد الأدنى للإيداع: 100 أوقية';

  @override
  String walletMinWithdrawal(int amount) {
    return 'الحد الأدنى للسحب: $amount أوقية';
  }

  @override
  String get walletNoEarningsYet => 'لا توجد أرباح بعد';

  @override
  String get walletNoTransactions => 'لا توجد معاملات';

  @override
  String get walletNoTransactionsYet => 'لا توجد معاملات بعد';

  @override
  String walletOfEveryPackSale(int fee) {
    return 'من كل عملية بيع حزمة (رسوم منصة $fee%)';
  }

  @override
  String get walletPaymentReferenceLabel => 'مرجع الدفع / رقم المعاملة';

  @override
  String get walletPhoneNumberHint => 'رقم هاتف مكوّن من 8 أرقام';

  @override
  String get walletPayoutPhoneNumber => 'رقم هاتف الاستلام';

  @override
  String get walletPhoneLabel => 'الهاتف';

  @override
  String get walletRecentTransactions => 'المعاملات الأخيرة';

  @override
  String get walletReferenceHint => 'مثال: TXN123456789';

  @override
  String get walletSelectPaymentMethod => 'اختر طريقة الدفع';

  @override
  String get walletSelectPayoutMethod => 'اختر طريقة الاستلام';

  @override
  String walletStatusPaymentMethod(String status, String method) {
    return '$status • $method';
  }

  @override
  String get walletTitle => 'المحفظة';

  @override
  String get walletDepositSubmittedTitle => 'تم إرسال الإيداع!';

  @override
  String walletDepositSubmittedSubtitle(String amount) {
    return 'إيداعك بقيمة $amount قيد المراجعة. سيتم تحديث الرصيد بعد الموافقة.';
  }

  @override
  String get walletDepositRequestFailed => 'فشل طلب الإيداع.';

  @override
  String get walletSubmitDeposit => 'إرسال الإيداع';

  @override
  String get walletWithdrawalSubmittedTitle => 'تم إرسال السحب!';

  @override
  String walletWithdrawalSubmittedSubtitle(String amount) {
    return 'سحبك بقيمة $amount قيد المعالجة. ستصل الأموال خلال 1 إلى 24 ساعة.';
  }

  @override
  String get walletWithdrawalRequestFailed => 'فشل طلب السحب.';

  @override
  String get walletContinueArrow => 'متابعة ←';

  @override
  String get walletActionDeposit => 'إيداع';

  @override
  String get walletActionWithdraw => 'سحب';

  @override
  String get walletActionEarnings => 'الأرباح';

  @override
  String get walletDetailDateTime => 'التاريخ والوقت';

  @override
  String get walletDetailWalletAffected => 'المحفظة المتأثرة';

  @override
  String get walletDetailEarnings => 'الأرباح';

  @override
  String get walletDetailWalletBalance => 'رصيد المحفظة';

  @override
  String get walletDetailBalanceAfter => 'الرصيد بعد العملية';

  @override
  String get walletDetailPaymentMethod => 'طريقة الدفع';

  @override
  String get walletDetailDescription => 'الوصف';

  @override
  String get walletDetailReference => 'المرجع';

  @override
  String get walletDetailTransactionId => 'معرّف المعاملة';

  @override
  String walletDetailDateAtTime(String date, String time) {
    return '$date في $time';
  }

  @override
  String get walletTransferAmount => 'مبلغ التحويل';

  @override
  String get walletTransferButton => 'تحويل';

  @override
  String get walletTransferFailed => 'فشل التحويل.';

  @override
  String get walletTransferSuccess => 'تم التحويل إلى رصيد المحفظة.';

  @override
  String get walletTransferToWallet => 'تحويل إلى المحفظة';

  @override
  String get walletTransferToWalletBalance => 'تحويل إلى رصيد المحفظة';

  @override
  String get walletWithdraw => 'سحب';

  @override
  String walletWithdrawalAmount(String amount) {
    return 'سحب $amount';
  }

  @override
  String get walletWithdrawalProcessingNotice =>
      'تتم معالجة عمليات السحب يدوياً. تصل الأموال خلال 1-24 ساعة بعد الموافقة.';

  @override
  String get walletYourPhoneNumber => 'رقم هاتفك';

  @override
  String get actionLabel => 'إجراء';

  @override
  String get activeLabel => 'نشط';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get getButton => 'احصل عليه';

  @override
  String get lightMode => 'الوضع الفاتح';

  @override
  String get premiumAppThemeTitle => 'مظهر التطبيق';

  @override
  String get premiumAutoRenewNotice =>
      'تُجدَّد الاشتراكات تلقائياً ما لم يتم إلغاؤها قبل 24 ساعة من التجديد.';

  @override
  String get premiumBackgroundColorEmoji => 'لون الخلفية ✦';

  @override
  String get premiumBackgroundColorTitle => 'لون الخلفية';

  @override
  String get premiumBlendsIntoTheme =>
      'يندمج مع المظهر المختار — يتكيف النص والبطاقات والأيقونات تلقائياً.';

  @override
  String premiumCannotDowngradeBody(String date) {
    return 'لديك اشتراك مميز بلس نشط. يمكنك التبديل إلى خطة أقل بعد انتهائه في $date.';
  }

  @override
  String get premiumCannotDowngradeTitle => 'لا يمكن التخفيض بعد';

  @override
  String get premiumCardTextReadable => 'يبقى نص البطاقة مقروءاً';

  @override
  String get premiumChooseAvatar => 'اختر الصورة الرمزية';

  @override
  String get premiumChooseBackground => 'اختر خلفية';

  @override
  String get premiumConfirmPurchase => 'تأكيد الشراء';

  @override
  String get premiumCurrentTermEnds => 'انتهاء مدتك الحالية';

  @override
  String get premiumFeatureColumnHeader => 'الميزة';

  @override
  String get premiumFeatureListDescription =>
      'مظاهر وصور رمزية مخصصة، 15 غرفة يومياً، حتى 12 لاعباً لكل غرفة، 10 حزم دون اتصال (1 مجانية)، دردشة مجهولة، والمزيد.';

  @override
  String get premiumLockedUntilExpires => 'مقفل حتى تنتهي صلاحية مميز بلس';

  @override
  String get premiumMonthly => 'شهري';

  @override
  String get premiumPageBackground => 'خلفية الصفحة';

  @override
  String premiumPlanActivated(String plan) {
    return '🎉 تم تفعيل $plan!';
  }

  @override
  String get premiumPlusLabel => 'مميز بلس';

  @override
  String get premiumPlusShort => 'بلس';

  @override
  String get premiumPremiumAvatars => 'صور رمزية مميزة';

  @override
  String get premiumPremiumThemes => 'مظاهر مميزة ✦';

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
    return 'سيتم خصم $planPrice من رصيد محفظتك.\n\nالخطة: $plan — $planPrice/$period';
  }

  @override
  String premiumPurchasePlan(String plan) {
    return 'شراء $plan';
  }

  @override
  String get premiumSave33 => 'وفّر 33%';

  @override
  String get premiumTitle => 'مميز';

  @override
  String get premiumUnlockTitle => 'افتح المميز';

  @override
  String get premiumUpgradeToUnlock => 'قم بالترقية للفتح';

  @override
  String get premiumWhatYouGet => 'ما الذي تحصل عليه';

  @override
  String get premiumYearly => 'سنوي';

  @override
  String get premiumYourAvatars => 'صورك الرمزية';

  @override
  String get premiumYourThemes => 'مظاهرك';

  @override
  String get resetToDefault => 'إعادة التعيين للافتراضي';

  @override
  String get continueArrow => 'متابعة ←';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get noneLabel => 'بلا';

  @override
  String get packAddFirstCardHint => 'أضف بطاقتك الأولى أعلاه!';

  @override
  String get packAddImages => 'إضافة صور';

  @override
  String packAddMoreMinimum(int count) {
    return 'أضف $count أخرى (10 كحد أدنى) أو احذفها جميعاً.';
  }

  @override
  String packAdditionalFeeBody(int fee) {
    return 'تحتوي هذه الحزمة على بطاقات إضافية، مما يتطلب رسوماً إضافية قدرها $fee أوقية لتقديمها للمراجعة.';
  }

  @override
  String get packAdditionalFeeTitle => 'رسوم إضافية مطلوبة';

  @override
  String get packAgeLabel => 'العمر';

  @override
  String get packAllowedLabel => 'مسموح';

  @override
  String get packAudienceEveryone => 'الجميع';

  @override
  String get packAudienceHint =>
      'قيّد الفئة المستهدفة لهذه الحزمة. لا يُطبَّق هذا عند الانضمام إلى غرفة بعد — يُحفظ مع الحزمة لاستخدامه لاحقاً.';

  @override
  String get packCardTypePrompt => 'موجّه';

  @override
  String get packCardTypeStatement => 'عبارة';

  @override
  String get packCategoryHintExample => 'مثال: ألعاب الحفلات';

  @override
  String get packCategoryOptionalLabel => 'الفئة (اختياري)';

  @override
  String packCategoryRejectedNoReason(String name) {
    return 'تم رفض الفئة المقترحة \"$name\".';
  }

  @override
  String packCategoryRejectedWithReason(String name, String reason) {
    return 'تم رفض الفئة المقترحة \"$name\": $reason';
  }

  @override
  String get packCategorySubmittedForReview => 'تم إرسال الفئة للمراجعة';

  @override
  String get packCoverImageHint =>
      'تظهر هذه الصورة على بطاقة الحزمة في المتجر.';

  @override
  String get packCoverImageLabel => 'صورة الغلاف';

  @override
  String get packLivePreviewLabel => 'معاينة مباشرة لبطاقة اللعبة';

  @override
  String get packLivePreviewHint => 'هذا تقريبًا ما سيراه اللاعبون في اللعبة.';

  @override
  String get packCardPreviewSampleText => 'سيظهر نص البطاقة هنا';

  @override
  String get packCardPreviewSectionLabel => 'معاينة البطاقة';

  @override
  String packCardPreviewCountLabel(int current, int total) {
    return 'البطاقة $current من $total';
  }

  @override
  String get packChooseSticker => 'اختر ملصقًا';

  @override
  String get packStickerSelected => 'تم اختيار الملصق';

  @override
  String get packRemoveSticker => 'إزالة الملصق';

  @override
  String get packNoStickersAvailable => 'لا توجد ملصقات متاحة بعد';

  @override
  String get packCardPreviewEmptyTitle => 'لا توجد بطاقات بعد';

  @override
  String get packCardPreviewEmptyBody => 'أضف بطاقتك الأولى أدناه وستظهر هنا.';

  @override
  String packCreateTitle(String step) {
    return 'إنشاء حزمة — $step';
  }

  @override
  String packDescriptionFieldLabel(String lang) {
    return 'الوصف ($lang، اختياري)';
  }

  @override
  String get packDifficultyMedium => 'متوسط';

  @override
  String get packDifficultyMild => 'خفيف';

  @override
  String get packDifficultySpicy => '🌶 حار';

  @override
  String get packEditPunishment => 'تعديل العقوبة';

  @override
  String get packEnableSpicyHint =>
      'فعّل المحتوى الحار في إعدادات الحزمة لإضافة بطاقات حارة';

  @override
  String packFailedSuggestCategory(String error) {
    return 'فشل اقتراح الفئة: $error';
  }

  @override
  String packFailedToSave(String error) {
    return 'فشل الحفظ: $error';
  }

  @override
  String packFailedToSaveCards(String error) {
    return 'فشل حفظ البطاقات: $error';
  }

  @override
  String packFailedToSaveReactions(String error) {
    return 'فشل حفظ التفاعلات: $error';
  }

  @override
  String packFillContentInLanguages(String languages) {
    return 'يرجى ملء المحتوى في: $languages';
  }

  @override
  String get packFreeLabel => 'مجاني';

  @override
  String get packGameTypeLabel => 'نوع اللعبة';

  @override
  String get packGameTypeMeme => '😂 لعبة الميم';

  @override
  String get packGameTypeNhie => '🍹 لم يسبق لي أبداً';

  @override
  String get packGameTypeTod => '🎯 الحقيقة أم الجرأة';

  @override
  String get packGenderFemaleOnly => 'إناث فقط';

  @override
  String get packGenderLabel => 'الجنس';

  @override
  String get packGenderMaleOnly => 'ذكور فقط';

  @override
  String get packImportantRulesBody =>
      '• لا يمكن تعديل الحزم بعد نشرها.\n• يجب عليك شراء حزمتك الخاصة لاستخدامها في الألعاب.\n• تستغرق مراجعة الإشراف من 1 إلى 3 أيام عمل.';

  @override
  String get packImportantRulesTitle => '📋 قواعد مهمة:';

  @override
  String get packInformationTitle => 'معلومات الحزمة';

  @override
  String get packLangArabic => 'العربية';

  @override
  String get packLangEnglish => 'الإنجليزية';

  @override
  String get packLangFrench => 'الفرنسية';

  @override
  String get packLangGerman => 'الألمانية';

  @override
  String get packLangPortuguese => 'البرتغالية';

  @override
  String get packLangRussian => 'الروسية';

  @override
  String get packLangSpanish => 'الإسبانية';

  @override
  String get packLangTurkish => 'التركية';

  @override
  String get packMaxReactionImagesReached =>
      'تم الوصول إلى الحد الأقصى 30 صورة تفاعل';

  @override
  String packMinPlayersLabel(int count) {
    return 'الحد الأدنى للاعبين: $count';
  }

  @override
  String get packMinimumReached => '✅ تم بلوغ الحد الأدنى';

  @override
  String packMoreNeeded(int count) {
    return 'يلزم $count أخرى';
  }

  @override
  String packNameFieldLabel(String lang) {
    return 'اسم الحزمة ($lang)*';
  }

  @override
  String get packNameHint => 'مثال: ليلة جمعة جامحة';

  @override
  String get packNoReactionImagesYet => 'لا توجد صور تفاعل بعد';

  @override
  String get packNotLoggedIn => 'لم يتم تسجيل الدخول';

  @override
  String get packOneNamePerLanguage => 'اسم ووصف واحد لكل لغة اخترتها.';

  @override
  String packPayFeeAndSubmit(int fee) {
    return 'دفع $fee أوقية وإرسال';
  }

  @override
  String packPendingAdminReview(String name) {
    return '\"$name\" في انتظار مراجعة الإدارة';
  }

  @override
  String get packPickExistingCategory => 'اختر فئة موجودة';

  @override
  String packPlayersSliderLabel(int count) {
    return '$count لاعبين';
  }

  @override
  String get packPriceFreeHint => 'اترك 0 لجعل الحزمة مجانية';

  @override
  String packMinPriceError(int min) {
    return 'يجب أن يكون سعر الحزم المدفوعة $min أوقية أو أكثر';
  }

  @override
  String get packPriceLabel => 'السعر';

  @override
  String packPriceMru(int price) {
    return '$price أوقية';
  }

  @override
  String packPunishmentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عقوبة',
      many: '$count عقوبة',
      few: '$count عقوبات',
      two: 'عقوبتان',
      one: 'عقوبة واحدة',
      zero: 'لا عقوبات',
    );
    return '$_temp0';
  }

  @override
  String get packPunishmentInputHint => 'مثال: قم بـ10 تمارين ضغط';

  @override
  String get packPunishmentsEmptyHint =>
      'اختياري — أضف بعضها، أو تخطَّ مباشرة إلى النشر.';

  @override
  String get packPunishmentsHint =>
      'تُعرض للاعب الذي يتخطى بطاقة أو يرفضها، إذا اختار مالك الغرفة استخدام عقوبات الحزمة بدلاً من مساهمات اللاعبين المباشرة.';

  @override
  String get packPunishmentsOptionalTitle => 'العقوبات (اختياري)';

  @override
  String packReactionImageCount(int count) {
    return '$count / 30 صورة تفاعل';
  }

  @override
  String packReactionSlotsRemaining(int count) {
    return '$count مكان متبقٍ';
  }

  @override
  String get packReactionsDescription =>
      'سيستخدم اللاعبون هذه الصور كتفاعلات أثناء اللعبة. أضف حتى 30 صورة. إذا لم تُضف أي صورة، تُستخدم الملصقات الافتراضية.';

  @override
  String get packReactionsOptionalHint => 'اختياري — تخطَّ لاستخدام الافتراضي';

  @override
  String get packReadyToPublish => 'جاهز للنشر؟';

  @override
  String get packReviewBeforeSubmitting => 'راجع حزمتك قبل إرسالها للمراجعة.';

  @override
  String get packSelectLanguagesHint =>
      'اختر كل لغة ستكتب بها أسماء هذه الحزمة وأوصافها وبطاقاتها.';

  @override
  String get packSpicyLabel => 'محتوى حار';

  @override
  String get packSpicyContentDisabled => 'المحتوى الحار غير متاح حاليًا.';

  @override
  String get packStepAudience => 'الجمهور';

  @override
  String get packStepCards => 'البطاقات';

  @override
  String get packStepGeneralInfo => 'معلومات عامة';

  @override
  String get packStepLanguages => 'اللغات';

  @override
  String get packStepNamesDescriptions => 'الأسماء والأوصاف';

  @override
  String get packStepPublish => 'نشر';

  @override
  String get packStepPunishments => 'العقوبات';

  @override
  String get packStepReactions => 'التفاعلات';

  @override
  String packSubmissionFailed(String error) {
    return 'فشل الإرسال: $error';
  }

  @override
  String get packSubmitForReview => 'إرسال للمراجعة';

  @override
  String get packEligibilityChecking => 'جارٍ التحقق من أهليتك للإرسال…';

  @override
  String get packFreeSubmissionAvailable => 'إرسالك المجاني متاح الآن';

  @override
  String get packFreeSubmissionUnavailable => 'الإرسال المجاني غير متاح بعد';

  @override
  String packNextFreeSubmissionAt(String date) {
    return 'الإرسال المجاني القادم: $date';
  }

  @override
  String packPaidExtraPackHint(int price) {
    return 'يمكنك إنشاء باقة إضافية الآن مقابل $price أوقية.';
  }

  @override
  String packCreateExtraPackPriced(int price) {
    return 'إنشاء باقة إضافية — $price أوقية';
  }

  @override
  String get packCreatorNotVerified =>
      'يمكن للمنشئين الموثقين فقط إرسال الباقات للمراجعة.';

  @override
  String get packAlreadyHasDraft =>
      'لديك بالفعل باقة مسودة. أكملها أو انشرها أو احذفها قبل إنشاء مسودة جديدة.';

  @override
  String get packDraftLimitReachedTitle => 'تم الوصول إلى حد المسودات';

  @override
  String get packDeleteDraft => 'حذف المسودة';

  @override
  String get packDeleteDraftConfirmTitle => 'هل تريد حذف هذه المسودة؟';

  @override
  String packDeleteDraftConfirmBody(String title) {
    return 'سيتم حذف \"$title\" نهائيًا. لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get packDraftDeletedNotice => 'تم حذف المسودة.';

  @override
  String packDeleteDraftFailed(String error) {
    return 'فشل حذف المسودة: $error';
  }

  @override
  String get packSubmittedForReviewNotice =>
      'تم إرسال الحزمة للمراجعة! سيتم إعلامك عند الموافقة عليها.';

  @override
  String get packSuggestAgain => 'اقترح مجدداً';

  @override
  String get packSuggestNew => 'اقترح فئة جديدة';

  @override
  String get packSuggestNewCategory => 'اقترح فئة جديدة';

  @override
  String get packSummaryCards => 'البطاقات';

  @override
  String packSummaryCardsValue(int count, int truthCount, int dareCount) {
    return '$count ($truthCount حقيقة + $dareCount جرأة)';
  }

  @override
  String get packSummaryGameType => 'نوع اللعبة';

  @override
  String get packSummaryPrice => 'السعر';

  @override
  String get packSummarySpicyContent => 'محتوى حار';

  @override
  String get packSummaryTitle => 'العنوان';

  @override
  String get packTapToAddCover => 'اضغط لإضافة صورة الغلاف';

  @override
  String get packTypeDare => 'جرأة 🔥';

  @override
  String get packTypePrompt => 'موجّه 😂';

  @override
  String get packTypeStatement => 'عبارة 🍹';

  @override
  String get packTypeTruth => 'حقيقة 🤔';

  @override
  String packUploadFailed(String error) {
    return 'فشل الرفع: $error';
  }

  @override
  String get packUploadingEllipsis => 'جارٍ الرفع...';

  @override
  String get packWhoCanPlay => 'من يمكنه اللعب بهذه الحزمة';

  @override
  String get packAdditionalDetailsOptional => 'تفاصيل إضافية (اختياري)';

  @override
  String get packAvailableOffline => 'متاح دون اتصال';

  @override
  String get packBrowseMarketplaceHint => 'تصفح المتجر للعثور على حزم.';

  @override
  String packBuyForPrice(int price) {
    return 'شراء مقابل $price أوقية';
  }

  @override
  String get packCancelled => 'ملغى';

  @override
  String packCancelledOn(String date) {
    return 'أُلغي في $date';
  }

  @override
  String packCardCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بطاقة',
      many: '$count بطاقة',
      few: '$count بطاقات',
      two: 'بطاقتان',
      one: 'بطاقة واحدة',
      zero: 'لا بطاقات',
    );
    return '$_temp0';
  }

  @override
  String packCardsAndSales(int cards, int sales) {
    return '$cards بطاقات • $sales مبيعات';
  }

  @override
  String packCardsAvailableOffline(int count) {
    return '$count بطاقات • متاح دون اتصال';
  }

  @override
  String get packCity => 'المدينة';

  @override
  String packCountLabel(int count) {
    return '$count حزمة';
  }

  @override
  String get packCreateFirstHint => 'أنشئ حزمتك الأولى وشاركها مع العالم.';

  @override
  String get packCreatePack => 'إنشاء حزمة';

  @override
  String get packCreator => 'المنشئ';

  @override
  String get packCreatorLabel => 'منشئ الحزمة';

  @override
  String get packCreatorStudio => 'استوديو المنشئ';

  @override
  String get packDownload => 'تنزيل';

  @override
  String get packDownloadFailed => 'فشل التنزيل';

  @override
  String get packDownloadToPlayOfflineHint =>
      'نزّل الحزم للعب دون اتصال بالإنترنت.';

  @override
  String packDownloadingPercent(int percent) {
    return 'جارٍ التنزيل… $percent٪';
  }

  @override
  String get packExpired => 'منتهي الصلاحية';

  @override
  String packExpiresInDays(int days) {
    return 'تنتهي الصلاحية خلال $days يوماً';
  }

  @override
  String packExpiresInDaysShort(int days) {
    return 'تنتهي خلال $days يوم';
  }

  @override
  String get packFailedToLoadYourPacks => 'فشل تحميل حزمك.';

  @override
  String packFailedToRequest(String error) {
    return 'فشل الطلب: $error';
  }

  @override
  String get packFallbackTitle => 'حزمة';

  @override
  String get packFeaturedHeading => '⭐ مميز';

  @override
  String get packFreeOfflineLimitNotice =>
      'تسمح الخطة المجانية بحزمة واحدة دون اتصال. قم بالترقية إلى بريميوم للحصول على 10.';

  @override
  String get packFullName => 'الاسم الكامل';

  @override
  String get packGetFreePack => 'احصل على الحزمة مجاناً';

  @override
  String get packInsufficientBalance => 'الرصيد غير كافٍ';

  @override
  String packInsufficientBalanceBody(int price) {
    return 'تحتاج إلى $price أوقية لشراء هذه الحزمة. رصيدك الحالي منخفض جداً.';
  }

  @override
  String get packLoadingPrice => 'جارٍ تحميل السعر…';

  @override
  String get packMinReviewLength => 'يرجى كتابة 10 أحرف على الأقل.';

  @override
  String get packMyPhysicalRequests => 'طلبات النسخ المطبوعة الخاصة بي';

  @override
  String get packNewPack => 'حزمة جديدة';

  @override
  String get packNoFeaturedPacksYet => 'لا توجد حزم مميزة بعد';

  @override
  String get packNoOfflinePacks => 'لا توجد حزم دون اتصال';

  @override
  String get packNoPacksFound => 'لم يتم العثور على حزم';

  @override
  String get packNoPacksYet => 'لا توجد حزم بعد';

  @override
  String get packSearchHint => 'ابحث باسم الحزمة أو المنشئ أو الفئة…';

  @override
  String get packSearchForPacks => 'ابحث عن حزم';

  @override
  String get packSearchMinChars => 'أدخل حرفين على الأقل.';

  @override
  String get packSearchNoResultsHint => 'جرّب اسمًا أو فئة مختلفة.';

  @override
  String get packNoPurchasedPacks => 'لا توجد حزم مشتراة';

  @override
  String get packNoRequestsYet => 'لا توجد طلبات بعد.';

  @override
  String get packNoReviewsYet => 'لا توجد مراجعات بعد. كن أول من يراجع!';

  @override
  String get packNotFound => 'لم يتم العثور على الحزمة.';

  @override
  String get packNotesOptional => 'ملاحظات (اختياري)';

  @override
  String packOfflineLimitReached(int limit) {
    return 'تم الوصول إلى الحد الأقصى دون اتصال ($limit حزمة). احذف حزمة لتنزيل أخرى.';
  }

  @override
  String packOfflineLimitReachedDelete(int limit) {
    return 'تم الوصول إلى الحد الأقصى دون اتصال ($limit حزمة). احذف واحدة لتنزيل أخرى.';
  }

  @override
  String get packOwnedBadge => 'مملوك';

  @override
  String get packPhoneNumber => 'رقم الهاتف';

  @override
  String get packPhysicalCopyRequested => 'تم طلب النسخة المطبوعة!';

  @override
  String packPhysicalFeeNotice(int total, int price, int quantity) {
    return 'الرسوم: $total أوقية ($price × $quantity)، تُخصم من رصيد محفظتك.';
  }

  @override
  String get packPlayer => 'لاعب';

  @override
  String get packProBadge => '★ برو';

  @override
  String get packOfficialBadge => 'جمعة';

  @override
  String get packProcessingEllipsis => 'جارٍ المعالجة…';

  @override
  String get packPromotedBadge => 'مروَّج';

  @override
  String packPurchaseFailed(String error) {
    return 'فشل الشراء: $error';
  }

  @override
  String get packPurchasedNotice => 'تم شراء الحزمة! يمكنك الآن تنزيلها.';

  @override
  String get packQuantity => 'الكمية';

  @override
  String get packRedownload => 'إعادة التنزيل';

  @override
  String packRejectionReason(String reason) {
    return 'سبب الرفض: $reason';
  }

  @override
  String get packRemoveDownload => 'إزالة التنزيل';

  @override
  String packRemoveDownloadBody(String title) {
    return 'سيؤدي هذا إلى إزالة النسخة غير المتصلة من \"$title\". يمكنك إعادة تنزيلها لاحقاً.';
  }

  @override
  String get packRemoveDownloadTitle => 'إزالة التنزيل؟';

  @override
  String get packReport => 'إبلاغ';

  @override
  String get packReportHint => 'ساعدنا في الحفاظ على أمان المتجر.';

  @override
  String get packReportPack => 'الإبلاغ عن الحزمة';

  @override
  String get packReportReasonCheating => 'الغش أو التلاعب بالنظام';

  @override
  String get packReportReasonHateSpeech => 'خطاب كراهية';

  @override
  String get packReportReasonInappropriate => 'محتوى غير لائق';

  @override
  String get packReportReasonOther => 'أخرى';

  @override
  String get packReportReasonSpam => 'بريد مزعج';

  @override
  String get packReportSubmitted => 'تم إرسال البلاغ.';

  @override
  String get packPromoteYourPack => 'روّج لحزمتك';

  @override
  String get packPromotionDuration24h => '24 ساعة';

  @override
  String get packPromotionDuration7d => 'أسبوع واحد';

  @override
  String get packPromotionSubtitle =>
      'أبرز هذه الحزمة في شريط الحزم المروَّجة للوصول إلى مزيد من اللاعبين.';

  @override
  String get packPromotionSubmit => 'روّج';

  @override
  String get packPromotionSuccess => 'تم ترويج الحزمة بنجاح!';

  @override
  String get packPromotionActiveLabel => 'الترويج نشط';

  @override
  String packPromotionEndsAt(String date) {
    return 'ينتهي $date';
  }

  @override
  String get packPromotionAlreadyActive => 'هذه الحزمة لديها بالفعل ترويج نشط.';

  @override
  String get packRequestPhysicalCopy => 'طلب نسخة مطبوعة';

  @override
  String get packRetryDownload => 'إعادة محاولة التنزيل';

  @override
  String get packReviewSubmitted => 'تم إرسال المراجعة!';

  @override
  String get packReviewSubmitFailed => 'تعذر إرسال مراجعتك. حاول مرة أخرى.';

  @override
  String get packReviews => 'المراجعات';

  @override
  String get packShareThoughtsHint => 'شارك رأيك حول هذه الحزمة…';

  @override
  String get packStageCompleted => 'مكتمل';

  @override
  String get packStageDelivered => 'تم التسليم';

  @override
  String get packStageOutForDelivery => 'قيد التوصيل';

  @override
  String get packStagePackaging => 'التغليف';

  @override
  String get packStagePaymentConfirmed => 'تم تأكيد الدفع';

  @override
  String get packStagePrinting => 'الطباعة';

  @override
  String get packStageRequestSubmitted => 'تم إرسال الطلب';

  @override
  String get packStageUnderReview => 'قيد المراجعة';

  @override
  String get packStatAvgRating => 'متوسط التقييم';

  @override
  String get packStatPublished => 'منشور';

  @override
  String get packStatSales => 'المبيعات';

  @override
  String get packStatusArchived => 'مؤرشف';

  @override
  String get packStatusDraft => 'مسودة';

  @override
  String get packStatusInReview => 'قيد المراجعة';

  @override
  String get packStatusPublished => 'منشور';

  @override
  String get packStatusRejected => 'مرفوض';

  @override
  String get packStatusSuspended => 'معلَّق';

  @override
  String get packPlatformManaged => 'تديرها جمعة';

  @override
  String get packSubmitReport => 'إرسال البلاغ';

  @override
  String get packSubmitRequest => 'إرسال الطلب';

  @override
  String get packSubmitReview => 'إرسال المراجعة';

  @override
  String get packTabBrowse => 'تصفح';

  @override
  String get packTabDownloaded => 'تم تنزيله';

  @override
  String get packTabFeatured => 'مميز';

  @override
  String get packTabMyPacks => 'حزمي';

  @override
  String get packTabPurchased => 'مشترى';

  @override
  String get packTopUpWallet => 'شحن المحفظة';

  @override
  String get packWriteReview => 'اكتب مراجعة';

  @override
  String get packWriteReviewShort => 'كتابة مراجعة';

  @override
  String get packYouOwnThisPack => 'أنت تمتلك هذه الحزمة';

  @override
  String packYouRatedThis(int rating) {
    return 'قيّمت هذه بـ $rating/5';
  }

  @override
  String get packRemoveRating => 'إزالة';

  @override
  String get packRatingRemoved => 'تمت إزالة تقييمك.';

  @override
  String get packRatingFailed => 'تعذر حفظ تقييمك. حاول مرة أخرى.';

  @override
  String get packYourPacks => 'حزمك';

  @override
  String get packYourRating => 'تقييمك:';

  @override
  String get packZoneDistrict => 'المنطقة / الحي';

  @override
  String get packZoneHint => 'مثال: تفرغ زينة';

  @override
  String get searchLabel => 'بحث';

  @override
  String avatarAlreadyUpdatedNotice(int hours, int mins) {
    return 'لقد حدّثت الصورة الرمزية بالفعل. حاول مرة أخرى خلال $hours س $mins د.';
  }

  @override
  String get avatarCustomAvatarsHint =>
      'أنشئ صورتك الرمزية الخاصة على طراز Bitmoji واعرضها في التطبيق بأكمله مع بريميوم.';

  @override
  String get avatarCustomAvatarsTitle => 'صور رمزية مخصصة';

  @override
  String get avatarFeelingLucky => 'تشعر بالحظ؟';

  @override
  String get avatarGenerateRandomHint => 'أنشئ صورة رمزية عشوائية فوراً.';

  @override
  String get avatarOnCooldown => 'قيد الانتظار';

  @override
  String get avatarOptAccessories => 'الإكسسوارات';

  @override
  String get avatarOptEyebrows => 'الحواجب';

  @override
  String get avatarOptEyes => 'العينان';

  @override
  String get avatarOptFacialHair => 'شعر الوجه';

  @override
  String get avatarOptFacialHairColor => 'لون شعر الوجه';

  @override
  String get avatarOptHairColor => 'لون الشعر';

  @override
  String get avatarOptHairStyle => 'تسريحة الشعر';

  @override
  String get avatarOptMouth => 'الفم';

  @override
  String get avatarOptOutfit => 'الزي';

  @override
  String get avatarOptOutfitColor => 'لون الزي';

  @override
  String get avatarOptSkinTone => 'لون البشرة';

  @override
  String get avatarRandomizeAvatar => 'صورة رمزية عشوائية';

  @override
  String get avatarReactionsDescription =>
      'تفاعلات صورتك الرمزية (سعيد، ضحك، بكاء والمزيد) متاحة إلى جانب تفاعلات الإيموجي في الحقيقة أم الجرأة ولم يسبق لي أبداً.';

  @override
  String get avatarSaveAvatar => 'حفظ الصورة الرمزية';

  @override
  String get avatarSaveFailed => 'تعذر الحفظ الآن.';

  @override
  String get avatarSaved => 'تم حفظ الصورة الرمزية! ✦';

  @override
  String get avatarSavingEllipsis => 'جارٍ الحفظ…';

  @override
  String get avatarDeleteAction => 'حذف الصورة الرمزية';

  @override
  String get avatarDeleteDialogTitle => 'حذف صورتك الرمزية؟';

  @override
  String get avatarDeleteDialogMessage =>
      'سيؤدي هذا إلى إزالة صورتك الرمزية المخصصة. ستعود إلى صورتك المرفوعة أو المظهر الافتراضي حتى تنشئ صورة جديدة.';

  @override
  String get avatarDeleted => 'تم حذف الصورة الرمزية.';

  @override
  String get avatarDeleteFailed => 'تعذر الحذف الآن.';

  @override
  String get avatarTabExtras => 'إضافات';

  @override
  String get avatarTabEyes => 'العينان';

  @override
  String get avatarTabFace => 'الوجه';

  @override
  String get avatarTabHair => 'الشعر';

  @override
  String get avatarTabMouth => 'الفم';

  @override
  String get avatarTabOutfit => 'الزي';

  @override
  String avatarUpdateCooldownNotice(int hours, int mins) {
    return 'يمكنك تحديث صورتك الرمزية مرة أخرى خلال $hours س $mins د.';
  }

  @override
  String get avatarUpgradeToPremium => 'الترقية إلى بريميوم ✦';

  @override
  String get profileAbout => 'نبذة';

  @override
  String get profileAgeOptionalLabel => 'العمر (اختياري)';

  @override
  String get profileBalanceAndTransactions => 'الرصيد والمعاملات';

  @override
  String get profileBioTooLong => '280 حرفاً كحد أقصى';

  @override
  String get profileChangeUsername => 'تغيير اسم المستخدم';

  @override
  String get profileChooseColourTheme => 'اختر نمط الألوان الخاص بك';

  @override
  String get profileChooseFromGallery => 'اختر من المعرض';

  @override
  String get profileCooldownActive => 'فترة الانتظار نشطة';

  @override
  String profileCooldownBody(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم',
      many: '$days يوماً',
      few: '$days أيام',
      two: 'يومين',
      one: 'يوم واحد',
      zero: 'لا أيام',
    );
    return 'يمكنك تغيير اسم المستخدم مرة أخرى خلال $_temp0.\n\nيمكن تغيير أسماء المستخدمين مرة واحدة فقط كل 30 يوماً.';
  }

  @override
  String get profileCountryAlgeria => 'الجزائر';

  @override
  String get profileCountryEgypt => 'مصر';

  @override
  String get profileCountryFrance => 'فرنسا';

  @override
  String get profileCountryGermany => 'ألمانيا';

  @override
  String get profileCountryMauritania => 'موريتانيا';

  @override
  String get profileCountryMorocco => 'المغرب';

  @override
  String get profileCountryOptionalLabel => 'الدولة (اختياري)';

  @override
  String get profileCountryOther => 'أخرى';

  @override
  String get profileCountrySaudiArabia => 'المملكة العربية السعودية';

  @override
  String get profileCountryTunisia => 'تونس';

  @override
  String get profileCountryUae => 'الإمارات العربية المتحدة';

  @override
  String get profileCountryUnitedKingdom => 'المملكة المتحدة';

  @override
  String get profileCountryUnitedStates => 'الولايات المتحدة';

  @override
  String get profileCreateAvatarHint => 'أنشئ صورتك الرمزية على طراز Bitmoji';

  @override
  String get profileCurrentUsername => 'اسم المستخدم الحالي';

  @override
  String get profileInfoSection => 'معلومات الملف الشخصي';

  @override
  String get profileMostPlayedPacks => '🔥 الحزم الأكثر لعباً';

  @override
  String get profileMyAvatar => 'صورتي الرمزية';

  @override
  String get profileMyCreatedPacks => '✏️ حزمي المُنشأة';

  @override
  String get profileNewUsername => 'اسم المستخدم الجديد';

  @override
  String get profilePersonalDetails => 'التفاصيل الشخصية';

  @override
  String get profilePhoneOptionalLabel => 'رقم الهاتف (اختياري)';

  @override
  String get profilePreferences => 'التفضيلات';

  @override
  String profilePremiumActiveExpires(int day, int month, int year) {
    return 'نشط · تنتهي الصلاحية في $day/$month/$year';
  }

  @override
  String get profileSaveUsername => 'حفظ اسم المستخدم';

  @override
  String get profileTakePhoto => 'التقاط صورة';

  @override
  String get profileUnlockPremiumHint =>
      'افتح السمات والصور الرمزية والدردشة المجهولة والمزيد';

  @override
  String get profileUploadingPhoto => 'جارٍ رفع الصورة…';

  @override
  String profileUsernameCooldownNotice(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم',
      many: '$days يوماً',
      few: '$days أيام',
      two: 'يومين',
      one: 'يوم واحد',
      zero: 'لا أيام',
    );
    return 'تغيير اسم المستخدم متاح خلال $_temp0.\nالتغييرات محدودة بمرة واحدة كل 30 يوماً.';
  }

  @override
  String get profileUsernameHint => 'lowercase_letters_123';

  @override
  String get profileUsernamePermanentNotice =>
      'تغييرات اسم المستخدم دائمة لمدة 30 يوماً.';

  @override
  String get profileUsernameRequirements =>
      '3-30 حرفاً · أحرف وأرقام وشرطات سفلية';

  @override
  String get profileUsernameTaken => 'اسم المستخدم هذا مُستخدم بالفعل.';

  @override
  String get profileUsernameUpdated => 'تم تحديث اسم المستخدم!';

  @override
  String get profileUsernameValidation => '3-30 حرفاً، فقط a-z و0-9 و_';

  @override
  String get profileVerifiedCreator => 'منشئ موثّق';

  @override
  String get notifARoom => 'غرفة';

  @override
  String get notifAllCaughtUp => 'لقد اطلعت على كل شيء!';

  @override
  String get notifDecline => 'رفض';

  @override
  String notifDeclineFailed(String error) {
    return 'فشل: $error';
  }

  @override
  String get notifInApp => 'داخل التطبيق';

  @override
  String get notifInvitedYouToJoin => 'دعاك للانضمام';

  @override
  String get notifMarkAllRead => 'تعليم الكل كمقروء';

  @override
  String get notifNoNotifications => 'لا توجد إشعارات';

  @override
  String get notifPreferences => 'التفضيلات';

  @override
  String get notifPreferencesTitle => 'تفضيلات الإشعارات';

  @override
  String get notifPush => 'دفع';

  @override
  String notifRoomInvitesCount(int count) {
    return 'دعوات الغرف ($count)';
  }

  @override
  String get notifTitle => 'الإشعارات';

  @override
  String get notifTypeAchievement => 'إنجاز';

  @override
  String get notifTypeFollow => 'متابع جديد';

  @override
  String get notifTypeFriendAccepted => 'تم قبول الصداقة';

  @override
  String get notifTypeFriendRequest => 'طلب صداقة';

  @override
  String get notifTypeGameStarted => 'بدأت اللعبة';

  @override
  String get notifTypeModeration => 'الإشراف';

  @override
  String get notifTypePackApproved => 'تمت الموافقة على الحزمة';

  @override
  String get notifTypePackExpired => 'انتهت صلاحية الحزمة';

  @override
  String get notifTypePackRejected => 'تم رفض الحزمة';

  @override
  String get notifTypePackReview => 'مراجعة الحزمة';

  @override
  String get notifTypePackSale => 'بيع حزمة';

  @override
  String get notifTypePhysicalPackStatus => 'تحديث الطلب';

  @override
  String get notifTypeRoomInvite => 'دعوة غرفة';

  @override
  String get notifTypeRoomJoinRequest => 'طلب انضمام للغرفة';

  @override
  String get notifTypeRoomJoinRequestAccepted => 'تم قبول طلب الانضمام';

  @override
  String get notifTypeRoomJoinRequestRejected => 'تم رفض طلب الانضمام';

  @override
  String get notifTypeRoomKicked => 'إزالة من الغرفة';

  @override
  String get notifTypeChatMessage => 'رسالة دردشة';

  @override
  String get notifTypeStreakIncreased => 'سلسلة الأيام';

  @override
  String get notifTypeCreatorPacksTransferred => 'حزم تحت إدارة جمعة';

  @override
  String get notifTypeCreatorPrivilegesRemoved => 'إزالة حالة المنشئ';

  @override
  String get notifTypeCreatorRecoveryApproved => 'تمت الموافقة على الاستعادة';

  @override
  String get notifTypeCreatorRecoveryRejected => 'تم رفض طلب الاستعادة';

  @override
  String get notifTypeSubscriptionExpired => 'انتهى الاشتراك';

  @override
  String get notifTypeSubscriptionExpiring1d => 'الاشتراك ينتهي خلال يوم';

  @override
  String get notifTypeSubscriptionExpiring2d => 'الاشتراك ينتهي خلال يومين';

  @override
  String get notifTypeSubscriptionStarted => 'بدأ الاشتراك';

  @override
  String get notifTypeSystem => 'النظام';

  @override
  String get notifTypeWalletCredit => 'إيداع في المحفظة';

  @override
  String get notifTypeWalletDebit => 'خصم من المحفظة';

  @override
  String get viewLabel => 'عرض';

  @override
  String get chatTitle => 'الدردشة';

  @override
  String get gameSettingsAllowOneReplay => 'السماح بإعادة واحدة';

  @override
  String get gameSettingsProofViewDuration =>
      'مدة عرض الإثبات (يُغلق تلقائياً بعدها)';

  @override
  String get gameSettingsProofUnlimitedDuration =>
      'مدة غير محدودة (حتى الجولة التالية)';

  @override
  String get gameSettingsProofReplayHint =>
      'يحصل المشتركون المميزون على إعادة إضافية بعد ذلك.';

  @override
  String gameSettingsProofAutoCloseHint(int seconds) {
    return 'يُغلق الإثبات تلقائياً بعد $seconds ثانية — لا إعادة أثناء تحديد مدة.';
  }

  @override
  String get gameSettingsRequireApprovalToSpectate => 'طلب الموافقة للمشاهدة';

  @override
  String get moderationBanPlayer => 'حظر اللاعب';

  @override
  String get moderationDuration1Hour => 'ساعة واحدة';

  @override
  String get moderationDuration24Hours => '24 ساعة';

  @override
  String get moderationDuration30Min => '30 دقيقة';

  @override
  String get moderationDuration7Days => '7 أيام';

  @override
  String get moderationDurationPermanent => 'دائم';

  @override
  String get moderationReasonOptional => 'السبب (اختياري)';

  @override
  String get roomsAnonymousModeOn => 'الوضع المجهول مُفعّل';

  @override
  String get roomsAnonymousSender => 'مجهول';

  @override
  String get roomsChatDisabled => 'الدردشة معطّلة';

  @override
  String get roomsChooseYourRole => 'اختر دورك في هذه الغرفة.';

  @override
  String get roomsClosed => 'مُغلقة';

  @override
  String roomsAgoMinutes(int count) {
    return 'منذ $count د';
  }

  @override
  String roomsAgoHours(int count) {
    return 'منذ $count س';
  }

  @override
  String roomsAgoDays(int count) {
    return 'منذ $count ي';
  }

  @override
  String roomsClosedAgo(String ago) {
    return 'أُغلقت $ago';
  }

  @override
  String get roomsClosedRoomFallback => 'غرفة مُغلقة';

  @override
  String get roomsConnConnecting => 'جارٍ الاتصال…';

  @override
  String get roomsConnDisconnected => 'غير متصل';

  @override
  String get roomsConnLive => 'مباشر';

  @override
  String get roomsConnReconnecting => 'جارٍ إعادة الاتصال…';

  @override
  String get roomsConnSyncing => 'جارٍ المزامنة…';

  @override
  String roomsFailedToSendRequest(String error) {
    return 'فشل إرسال الطلب: $error';
  }

  @override
  String get roomsFallbackRoom => 'غرفة';

  @override
  String get roomsGameAlreadyInProgress => 'هذه اللعبة قيد التنفيذ بالفعل.';

  @override
  String get roomsGameInProgress => 'اللعبة قيد التنفيذ';

  @override
  String get roomsHiddenFromPlayersList => 'مخفي عن اللاعبين وقائمة المتفرجين';

  @override
  String get roomsInvalidCodeOrNotFound => 'رمز غير صالح أو الغرفة غير موجودة';

  @override
  String get roomsInvite => 'دعوة';

  @override
  String get roomsJoinAsPlayer => 'الانضمام كلاعب';

  @override
  String get roomsMakeModerator => 'تعيين كمشرف';

  @override
  String roomsManagePermissionsCount(int count) {
    return 'إدارة الصلاحيات ($count)';
  }

  @override
  String get roomsMessageAsAnonymous => 'راسل كمجهول…';

  @override
  String get roomsModeration => 'الإشراف';

  @override
  String get roomsObserveWithoutPlaying => 'المراقبة دون اللعب';

  @override
  String roomsPackRequiresMinPlayers(int count) {
    return 'تتطلب هذه الحزمة $count لاعبين على الأقل.';
  }

  @override
  String get roomsPendingEllipsis => 'قيد الانتظار…';

  @override
  String get roomsPermAcceptJoins => 'قبول طلبات الانضمام';

  @override
  String get roomsPermAcceptRejoins => 'قبول طلبات إعادة الانضمام';

  @override
  String get roomsPermAcceptSpectators => 'قبول طلبات المشاهدة';

  @override
  String get roomsPermAdvanceTurn => 'بدء الدور التالي';

  @override
  String get roomsPermEndGame => 'إنهاء اللعبة';

  @override
  String get roomsPermKickPlayers => 'إزالة اللاعبين';

  @override
  String get roomsPermManageSettings => 'إدارة إعدادات الغرفة';

  @override
  String get roomsPermMuteChat => 'كتم الدردشة';

  @override
  String get roomsPermMutePlayers => 'كتم اللاعبين في اللعبة';

  @override
  String get roomsPermSkipTurn => 'تخطي دور';

  @override
  String get roomsPermStartGame => 'بدء اللعبة';

  @override
  String get roomsRejoin => 'إعادة الانضمام';

  @override
  String get roomsRejoinRequestDeclined => 'تم رفض طلب إعادة انضمامك';

  @override
  String get roomsRequestAgain => 'طلب مجدداً';

  @override
  String get roomsRequestSentWaiting => 'تم إرسال الطلب — بانتظار المضيف';

  @override
  String get roomsRequestToRejoin => 'طلب إعادة الانضمام';

  @override
  String get roomsSendAnonymouslyPremium => 'الإرسال بشكل مجهول (بريميوم)';

  @override
  String get roomsStatusClosed => 'مُغلقة';

  @override
  String get roomsStatusInGame => 'في اللعبة';

  @override
  String get roomsStatusPaused => 'متوقفة مؤقتاً';

  @override
  String get roomsStatusWaiting => 'بالانتظار';

  @override
  String get roomsTakePartInGame => 'المشاركة في اللعبة';

  @override
  String roomsTransferOwnershipConfirm(String name) {
    return 'نقل ملكية الغرفة إلى $name؟ ستصبح لاعباً عادياً.';
  }

  @override
  String get roomsWaitingForReconnecting =>
      'بانتظار اللاعب (اللاعبين) الذين يعيدون الاتصال...';

  @override
  String get roomsWatchAnonymously => 'المشاهدة بشكل مجهول ✦';

  @override
  String get roomsWatchAsSpectator => 'المشاهدة كمتفرج';

  @override
  String get sharedApprove => 'قبول';

  @override
  String get sharedBan => 'حظر';

  @override
  String get sharedBanPlayerBody =>
      'هل أنت متأكد أنك تريد حظر هذا اللاعب من هذه الغرفة؟';

  @override
  String get sharedBanPlayerTitle => 'حظر اللاعب';

  @override
  String get sharedEndGame => 'إنهاء اللعبة';

  @override
  String get sharedEveryoneLeftNotice =>
      'غادر جميع اللاعبين الآخرين. لا يمكن أن تستمر اللعبة — أنهها عندما تكون مستعداً.';

  @override
  String sharedGameRulesTitle(String gameName) {
    return '$gameName — القواعد';
  }

  @override
  String get sharedGoHome => 'الذهاب للرئيسية';

  @override
  String get sharedHistoryTooltip => 'السجل';

  @override
  String get sharedReactionAvatarsTab => 'الصور الرمزية';

  @override
  String get sharedReactionIconsTab => 'أيقونات';

  @override
  String sharedJoinRequestFailed(String error) {
    return 'فشل: $error';
  }

  @override
  String sharedJoinRequestsCount(int count) {
    return 'طلبات الانضمام ($count)';
  }

  @override
  String get sharedKick => 'طرد';

  @override
  String get sharedKickPlayerBody =>
      'هل أنت متأكد أنك تريد إزالة هذا اللاعب من اللعبة الحالية؟';

  @override
  String get sharedKickPlayerTitle => 'طرد اللاعب';

  @override
  String get sharedMemeRuleObjective =>
      'أرسل أطرف تعليق أو ملصق لموجّه الجولة، ثم صوّت لمفضلك من بين تعليقات الآخرين.';

  @override
  String get sharedMemeRuleScoring =>
      'من يحصل على أكبر عدد من الأصوات في جولة يفوز بنقطة تلك الجولة. صاحب أكبر عدد نقاط في النهاية يفوز باللعبة.';

  @override
  String get sharedMemeRuleTurnFlow =>
      'مرحلة الإرسال ← مرحلة التصويت ← النتائج، في كل جولة، حتى تنفد موجّهات الحزمة أو يصل عدد الجولات إلى الحد الأقصى.';

  @override
  String get sharedMute => 'كتم';

  @override
  String get sharedNhieRuleObjective =>
      'تعرض كل جولة عبارة \"لم يسبق لي أبداً…\". يجيب الجميع بصدق سواء فعلوا ذلك أم لا.';

  @override
  String get sharedNhieRuleScoring =>
      'يبني سجل إجاباتك الصادقة ملفك الشخصي عبر اللعبة — لا يوجد فائز/خاسر، فقط كشف.';

  @override
  String get sharedNhieRuleTurnFlow =>
      'تظهر عبارة جديدة في كل جولة؛ يصوّت كل لاعب، ثم تتقدم الجولة بمجرد أن يجيب الجميع.';

  @override
  String get sharedNoPendingJoinRequests => 'لا توجد طلبات انضمام معلقة';

  @override
  String get sharedPageNotFound => 'الصفحة غير موجودة';

  @override
  String get sharedPageNotFoundHint => 'الصفحة التي تبحث عنها غير موجودة.';

  @override
  String get sharedReject => 'رفض';

  @override
  String get sharedRoomMembers => 'أعضاء الغرفة';

  @override
  String sharedRoomMembersCount(int count) {
    return '👥 أعضاء الغرفة ($count)';
  }

  @override
  String get sharedRoomSettingsTitle => 'إعدادات هذه الغرفة';

  @override
  String get sharedRuleNoTurnTimer => 'لا يوجد مؤقت للدور';

  @override
  String get sharedRuleObjective => 'الهدف';

  @override
  String get sharedRulePolicyEveryone => 'الجميع في اللعبة';

  @override
  String get sharedRulePolicyPlayersOnly => 'اللاعبون فقط';

  @override
  String get sharedRulePolicySpectatorsOnly => 'المتفرجون فقط';

  @override
  String get sharedRuleProofViewOnce =>
      'يمكن مشاهدة الإثبات مرة واحدة (بريميوم: مرتين).';

  @override
  String get sharedRuleProofViewTwice =>
      'يمكن مشاهدة الإثبات مرتين (بريميوم: ثلاث مرات).';

  @override
  String sharedRuleProofVisibleTo(String policy) {
    return 'الإثبات مرئي لـ: $policy.';
  }

  @override
  String get sharedRulePunishmentOff =>
      'وضع العقوبة معطّل — لا يُقدَّم التخطي كخيار.';

  @override
  String get sharedRulePunishmentOn =>
      'وضع العقوبة مُفعّل — التخطي يعني أن كل لاعب آخر يقترح عقوبة واحدة وتختار أنت أيها ستنفذ.';

  @override
  String get sharedRuleScoring => 'التسجيل';

  @override
  String get sharedRuleSpectatorsApprovalRequired =>
      'يُسمح بالمتفرجين، بشرط موافقة المضيف.';

  @override
  String get sharedRuleSpectatorsFreelyAllowed =>
      'يُسمح للمتفرجين بالمشاهدة بحرية.';

  @override
  String get sharedRuleSpectatorsNotAllowed =>
      'لا يُسمح بالمتفرجين في هذه الغرفة.';

  @override
  String get sharedRuleSpicyEnabled => 'المحتوى الحار مُفعّل لهذه الغرفة.';

  @override
  String get sharedRuleTurnFlow => 'سير الدور';

  @override
  String sharedRuleTurnTimer(int seconds) {
    return 'مؤقت الدور: $seconds ثانية';
  }

  @override
  String get sharedRules => 'القواعد';

  @override
  String get sharedStatusDisconnected => 'غير متصل';

  @override
  String get sharedStatusMuted => 'مكتوم';

  @override
  String get sharedStatusPlaying => 'يلعب';

  @override
  String get sharedStatusSpectator => 'متفرج';

  @override
  String get sharedTodRuleObjective =>
      'تناوبوا على اختيار الحقيقة أم الجرأة. أجب بصدق أو أكمل الجرأة — لا يوجد خيار \"آمن\" بمجرد أن تختار.';

  @override
  String get sharedTodRuleScoring =>
      'تضيف الحقائق والجرأات المكتملة إلى نقاطك. يتم تتبع التخطي أيضاً — قد يؤدي إلى عقوبة (انظر أدناه).';

  @override
  String get sharedTodRuleTurnFlow =>
      'يختار اللاعب الحالي الحقيقة أم الجرأة، ويحصل على بطاقة، ثم يجيب/ينفذها أو (إذا سُمح) يتخطاها. ثم ينتقل الدور إلى اللاعب التالي بالترتيب.';

  @override
  String get sharedUnmute => 'إلغاء الكتم';

  @override
  String sharedWantsToJoinCurrentGame(String name) {
    return '$name يريد الانضمام إلى اللعبة الحالية.';
  }

  @override
  String get friendsAccept => 'قبول';

  @override
  String get friendsReject => 'رفض';

  @override
  String get friendsDecline => 'رفض';

  @override
  String get friendsPendingRequestsHeader => 'طلبات الصداقة المعلّقة';

  @override
  String get friendsYourFriendsHeader => 'أصدقاؤك';

  @override
  String get friendsAdd => 'إضافة';

  @override
  String get friendsAddFriend => 'إضافة صديق';

  @override
  String get friendsBlock => 'حظر';

  @override
  String get friendsBlocked => 'محظور';

  @override
  String get friendsCancelRequest => 'إلغاء الطلب';

  @override
  String get friendsCannotInteract => 'لا يمكنك التفاعل مع هذا المستخدم.';

  @override
  String friendsCreatedBy(String name) {
    return 'أنشأها $name';
  }

  @override
  String get friendsOfficialAccount => 'الحساب الرسمي لجمعة';

  @override
  String friendsFollowersCount(int count) {
    return '$count متابع';
  }

  @override
  String get friendsFollow => 'متابعة';

  @override
  String get friendsFollowersTitle => 'المتابعون';

  @override
  String get friendsNoFollowersYet => 'لا يوجد متابعون بعد.';

  @override
  String friendsMostPlayedBy(String name) {
    return 'الأكثر لعباً من $name';
  }

  @override
  String get friendsNoBlockedUsers => 'لا يوجد مستخدمون محظورون';

  @override
  String get friendsNoBlockedUsersHint => 'سيظهر هنا كل من تحظرهم.';

  @override
  String get friendsNoFriendsHint => 'استكشف أشخاصاً وتواصل مع لاعبين.';

  @override
  String get friendsNoFriendsYet => 'لا يوجد أصدقاء بعد';

  @override
  String get friendsNoPendingRequests => 'لا توجد طلبات معلقة';

  @override
  String get friendsNoPendingRequestsHint =>
      'ستظهر هنا طلبات الصداقة التي تتلقاها.';

  @override
  String get friendsNoResults => 'لا توجد نتائج';

  @override
  String get friendsNoResultsHint => 'جرّب اسماً أو اسم مستخدم مختلفاً.';

  @override
  String friendsOfflineCount(int count) {
    return 'غير متصل — $count';
  }

  @override
  String friendsOnlineCount(int count) {
    return 'متصل — $count';
  }

  @override
  String get creatorVerificationTitle => 'كن منشئ محتوى موثقًا';

  @override
  String get creatorVerificationSubtitle =>
      'استوفِ كل هذه المتطلبات للتقدم بطلب توثيق المنشئ.';

  @override
  String get creatorReqPremiumPlus => 'مشترك في بريميوم بلس';

  @override
  String creatorReqGamesPlayed(int count) {
    return 'العب $count لعبة على الأقل';
  }

  @override
  String creatorReqPacksUsed(int count) {
    return 'استخدم $count حزمة على الأقل';
  }

  @override
  String creatorReqFollowers(int count) {
    return 'احصل على $count متابع على الأقل';
  }

  @override
  String creatorReqLoginStreak(int count) {
    return 'ادخل التطبيق لمدة $count أيام متتالية';
  }

  @override
  String creatorReqRoomStreak(int count) {
    return 'أنشئ غرفة كل يوم لمدة $count أيام متتالية';
  }

  @override
  String creatorReqPackGamesStreak(int count, int days) {
    return 'أنهِ $count ألعاب حزم على الأقل كل يوم لمدة $days أيام متتالية';
  }

  @override
  String get creatorReqPlayedWithOthers => 'العب لعبة مع مستخدمين آخرين';

  @override
  String get creatorApplyNow => 'تقدم الآن';

  @override
  String get creatorKeepGoing =>
      'استمر — ستتمكن من التقديم بمجرد استيفاء جميع المتطلبات أعلاه.';

  @override
  String get creatorRecoveryBannerTitle =>
      'تمت إزالة حالة المنشئ الموثق الخاصة بك';

  @override
  String get creatorRecoveryBannerBody =>
      'انتهت صلاحية اشتراكك في بريميوم بلس وتمت إزالة حالة المنشئ الموثق وامتيازاتك تلقائيًا. يمكنك تقديم طلب استعادة لمراجعة الإدارة.';

  @override
  String get creatorRecoveryBannerAction => 'تقديم طلب استعادة';

  @override
  String get creatorRecoveryTitle => 'طلب الاستعادة';

  @override
  String get creatorRecoveryIntro =>
      'أخبرنا بما حدث. سيراجع أحد المسؤولين طلبك، وفي حال الموافقة، ستتم استعادة حالة المنشئ الموثق وامتيازاتك وحزمك بالكامل.';

  @override
  String get creatorRecoveryReasonLabel => 'السبب';

  @override
  String get creatorRecoveryReasonResubscribedLate =>
      'جددت اشتراكي لكن بعد فوات فترة السماح';

  @override
  String get creatorRecoveryReasonPaymentIssue =>
      'مشكلة في الدفع/الفوترة تسببت في انتهاء الاشتراك';

  @override
  String get creatorRecoveryReasonUnawareOfExpiry =>
      'لم يتم إشعاري بانتهاء اشتراكي';

  @override
  String get creatorRecoveryReasonExtenuatingCircumstances =>
      'ظروف قاهرة منعت التجديد';

  @override
  String get creatorRecoveryReasonOther => 'أخرى';

  @override
  String get creatorRecoveryExplanationLabel => 'التوضيح';

  @override
  String get creatorRecoveryExplanationHint =>
      'اشرح ما حدث في 20 حرفًا على الأقل';

  @override
  String get creatorRecoveryExplanationTooShort =>
      'يرجى كتابة 20 حرفًا على الأقل لتوضيح ما حدث.';

  @override
  String get creatorRecoveryEvidenceLabel => 'دليل (اختياري)';

  @override
  String get creatorRecoveryEvidenceUploadFailed =>
      'تعذر رفع هذه الصورة. حاول مرة أخرى.';

  @override
  String get creatorRecoverySubmit => 'إرسال الطلب';

  @override
  String get creatorRecoverySubmitted =>
      'تم إرسال طلب الاستعادة الخاص بك للمراجعة.';

  @override
  String get creatorRecoveryFailed =>
      'تعذر إرسال طلب الاستعادة. حاول مرة أخرى.';

  @override
  String get creatorRecoveryPendingTitle => 'طلب الاستعادة قيد المراجعة';

  @override
  String get creatorRecoveryPendingBody =>
      'يقوم أحد المسؤولين بمراجعة طلب الاستعادة الخاص بك. سيتم إشعارك فور اتخاذ القرار.';

  @override
  String get creatorRecoveryRejectedTitle =>
      'تم رفض طلب الاستعادة السابق الخاص بك';

  @override
  String get creatorApplyDialogTitle => 'طلب التوثيق';

  @override
  String get creatorApplyDialogRealName => 'الاسم القانوني الكامل';

  @override
  String get creatorApplyDialogBio => 'نبذة قصيرة (اختياري)';

  @override
  String get creatorApplySubmitted => 'تم إرسال الطلب! سنراجعه قريبًا.';

  @override
  String get creatorApplyFailed => 'فشل إرسال الطلب. حاول مرة أخرى.';

  @override
  String get profileBecomeCreator => 'كن منشئ محتوى موثقًا';

  @override
  String get profileBecomeCreatorHint => 'افتح أدوات المنشئين والأرباح';

  @override
  String get friendsPlayingNow => 'يلعب الآن';

  @override
  String get friendsProfileNotFound => 'الملف الشخصي غير موجود.';

  @override
  String get friendsReceived => 'المستلمة';

  @override
  String get friendsRemoveFriend => 'إزالة صديق';

  @override
  String get friendsRequests => 'الطلبات';

  @override
  String get friendsSearchForFriends => 'ابحث عن أصدقاء';

  @override
  String get friendsSearchHint => 'ابحث بالاسم أو اسم المستخدم…';

  @override
  String get friendsSearchMinChars => 'أدخل حرفين على الأقل.';

  @override
  String friendsSentCount(int count) {
    return 'مُرسلة — $count';
  }

  @override
  String get friendsStatusInGame => 'في اللعبة';

  @override
  String get friendsStatusOffline => 'غير متصل';

  @override
  String get friendsStatusOnline => 'متصل';

  @override
  String get presenceUserIsAway => 'غائب';

  @override
  String get presenceUserIsAwayFull => 'المستخدم غائب';

  @override
  String presenceUserAwaySnackbar(String name) {
    return '$name غائب';
  }

  @override
  String get friendsStatusInRoomLobby => 'في غرفة الانتظار';

  @override
  String friendsStatusPlayingGame(String game) {
    return 'يلعب $game';
  }

  @override
  String get friendsUnblock => 'إلغاء الحظر';

  @override
  String friendsUnblockedNotice(String name) {
    return 'تم إلغاء حظر $name';
  }

  @override
  String get friendsUnfollow => 'إلغاء المتابعة';

  @override
  String get friendsUserFallback => 'مستخدم';

  @override
  String get friendsYouHaveBlocked => 'لقد حظرت هذا المستخدم.';

  @override
  String get notifJustNow => 'الآن';

  @override
  String notifMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count دقيقة',
      many: 'منذ $count دقيقة',
      few: 'منذ $count دقائق',
      two: 'منذ دقيقتين',
      one: 'منذ دقيقة',
      zero: 'الآن',
    );
    return '$_temp0';
  }

  @override
  String get settingsAboutUs => 'معلومات عنا';

  @override
  String get settingsPrivacyPolicy => 'سياسة الخصوصية';

  @override
  String get settingsTermsConditions => 'الشروط والأحكام';

  @override
  String get settingsRequestAccountDeletion => 'طلب حذف الحساب';

  @override
  String get settingsRequestAccountDeletionPending => 'طلب الحذف قيد المراجعة';

  @override
  String get deleteAccountDialogTitle => 'حذف حسابك؟';

  @override
  String get deleteAccountDialogMessage =>
      'سيتم إرسال هذا الطلب لمراجعته من قبل فريقنا — لن يُحذف حسابك فورًا. بعد الموافقة، سيتم حذف ملفك الشخصي وحزمك ورصيد محفظتك وسجل ألعابك نهائيًا، ولا يمكن التراجع عن ذلك.';

  @override
  String get deleteAccountDialogConfirm => 'إرسال الطلب';

  @override
  String get deleteAccountSubmitted => 'تم إرسال طلب حذف حسابك للمراجعة.';

  @override
  String get deleteAccountAlreadyPending => 'لديك بالفعل طلب حذف قيد المراجعة.';

  @override
  String get aboutUsTitle => 'معلومات عنا';

  @override
  String get aboutUsVersionLabel => 'الإصدار';

  @override
  String get aboutUsDescription =>
      'جمعة هو تطبيق ألعاب جماعية للحفلات — العب الحقيقة أم الجرأة، لم يسبق لي، وألعاب الميمز مع الأصدقاء والعائلة في أي وقت وأي مكان.';

  @override
  String get aboutUsCompanySectionTitle => 'الشركة';

  @override
  String get aboutUsCompanyInfo => 'يتم تطوير وتشغيل جمعة بواسطة فريق جمعة.';

  @override
  String get aboutUsContactTitle => 'تواصل معنا';

  @override
  String get aboutUsContactEmail => 'support@jma3a.app';

  @override
  String get aboutUsWebsiteTitle => 'الموقع الإلكتروني';

  @override
  String get aboutUsWebsite => 'www.jma3a.app';

  @override
  String get aboutUsFollowUsTitle => 'تابعنا';

  @override
  String get aboutUsSocialTiktok => 'TikTok';

  @override
  String get aboutUsSocialSnapchat => 'Snapchat';

  @override
  String get aboutUsSocialFacebook => 'Facebook';

  @override
  String get privacyPolicyTitle => 'سياسة الخصوصية';

  @override
  String get privacyPolicyIntro =>
      'توضح سياسة الخصوصية هذه المعلومات التي يجمعها تطبيق جمعة وكيفية استخدامها. هذا محتوى مؤقت — سيتم استبداله بالسياسة القانونية الكاملة.';

  @override
  String get privacySectionInfoCollected => 'المعلومات التي نجمعها';

  @override
  String get privacySectionInfoCollectedBody =>
      'محتوى مؤقت — يصف تفاصيل الحساب وبيانات الاستخدام والمحتوى الذي تنشئه داخل التطبيق.';

  @override
  String get privacySectionHowUsed => 'كيفية استخدام معلوماتك';

  @override
  String get privacySectionHowUsedBody =>
      'محتوى مؤقت — يصف كيفية استخدام المعلومات المجمعة لتقديم التطبيق وتحسينه.';

  @override
  String get privacySectionNotifications => 'الإشعارات';

  @override
  String get privacySectionNotificationsBody =>
      'محتوى مؤقت — يصف الإشعارات الفورية وكيفية إدارة تفضيلاتك.';

  @override
  String get privacySectionPurchases => 'المشتريات';

  @override
  String get privacySectionPurchasesBody =>
      'محتوى مؤقت — يصف كيفية التعامل مع المشتريات داخل التطبيق والاشتراكات.';

  @override
  String get privacySectionUserContent => 'المحتوى الذي ينشئه المستخدم';

  @override
  String get privacySectionUserContentBody =>
      'محتوى مؤقت — يصف ملكية الحزم والبطاقات والمحتوى الآخر الذي تنشئه والتعامل معها.';

  @override
  String get privacySectionAccountDeletion => 'حذف الحساب';

  @override
  String get privacySectionAccountDeletionBody =>
      'محتوى مؤقت — يصف كيفية طلب حذف الحساب وما يحدث لبياناتك.';

  @override
  String get privacySectionContact => 'تواصل معنا';

  @override
  String get privacySectionContactBody =>
      'محتوى مؤقت — تفاصيل التواصل للأسئلة المتعلقة بالخصوصية.';

  @override
  String get termsConditionsTitle => 'الشروط والأحكام';

  @override
  String get termsConditionsIntro =>
      'تحكم هذه الشروط والأحكام استخدامك لتطبيق Jma3a، وهو تطبيق ألعاب اجتماعية متعددة اللاعبين. بإنشاء حساب أو استخدام التطبيق، فإنك توافق على هذه الشروط.';

  @override
  String get termsSectionAccount => 'الحسابات';

  @override
  String get termsSectionAccountBody =>
      'يجب أن يكون عمرك 13 عامًا على الأقل لإنشاء حساب في Jma3a. يمكنك التسجيل باستخدام رقم هاتف أو بريد إلكتروني، ويتم التحقق منه برمز لمرة واحدة. أنت مسؤول عن الحفاظ على أمان بيانات حسابك وعن جميع الأنشطة التي تتم عليه.';

  @override
  String get termsSectionAcceptableUse => 'الاستخدام المقبول';

  @override
  String get termsSectionAcceptableUseBody =>
      'توافق على استخدام Jma3a باحترام وعدم مضايقة أو تهديد أو إساءة معاملة المستخدمين الآخرين، أو انتحال شخصية الآخرين، أو استخدام التطبيق لأي غرض غير قانوني. قد يؤدي انتهاك ذلك إلى إزالة المحتوى أو تقييد الميزات أو تعليق الحساب.';

  @override
  String get termsSectionContent => 'محتواك';

  @override
  String get termsSectionContentBody =>
      'تحتفظ بملكية المحتوى الذي تنشئه، مثل ملفك الشخصي أو أي حزم أو بطاقات تصنعها. عند نشر محتوى على Jma3a، فإنك تمنحنا الحق في عرضه وتوزيعه داخل التطبيق حتى يتمكن المستخدمون الآخرون من مشاهدته والتفاعل معه. أنت مسؤول عن المحتوى الذي تنشئه أو تشاركه.';

  @override
  String get termsSectionCreators => 'المنشئون والحسابات الرسمية';

  @override
  String get termsSectionCreatorsBody =>
      'يقدم Jma3a صفة \"منشئ موثّق\" للمنشئين المؤهلين، وتظهر على ملفهم الشخصي. قد تُمنح هذه الصفة أو تُسحب بناءً على سلوك حسابك والتزامك بهذه الشروط. قد يظهر أيضًا حساب Jma3a الرسمي داخل التطبيق لمشاركة الإعلانات والردود.';

  @override
  String get termsSectionRoomsGames => 'الغرف والألعاب';

  @override
  String get termsSectionRoomsGamesBody =>
      'يتيح لك Jma3a إنشاء أو الانضمام إلى غرف للعب ألعاب متعددة اللاعبين مع الأصدقاء والمستخدمين الآخرين، باستخدام حزم محتوى مقدمة من Jma3a أو من إنشاء المستخدمين. يُتوقع من مضيفي وأعضاء الغرفة الالتزام بهذه الشروط أثناء اللعب.';

  @override
  String get termsSectionPremium => 'Premium و Premium Plus';

  @override
  String get termsSectionPremiumBody =>
      'يقدم Jma3a اشتراكات اختيارية Premium وPremium Plus تفتح ميزات ومزايا إضافية داخل التطبيق. قد يتغير محتوى كل فئة بمرور الوقت، وسيتم إعلامك بما يتضمنه الاشتراك قبل الشراء.';

  @override
  String get termsSectionWallet => 'المحفظة والمدفوعات';

  @override
  String get termsSectionWalletBody =>
      'يتضمن Jma3a محفظة داخل التطبيق يمكن شحنها باستخدام وسائل الدفع المحلية المدعومة. يمكن للمنشئين كسب رصيد من محتواهم وطلب سحبه، وذلك وفقًا لمراجعة Jma3a. تخضع المدفوعات أيضًا لشروط مزود وسيلة الدفع التي تستخدمها.';

  @override
  String get termsSectionModeration => 'الإبلاغ والإشراف';

  @override
  String get termsSectionModerationBody =>
      'يمكنك الإبلاغ عن المستخدمين أو المحتوى المخالف لهذه الشروط أو حظرهم. قد يراجع Jma3a البلاغات ويتخذ إجراءات، بما في ذلك إزالة المحتوى أو تقييد الميزات أو تعليق أو إنهاء الحسابات المخالفة لهذه الشروط.';

  @override
  String get termsSectionTermination => 'التعليق والإنهاء';

  @override
  String get termsSectionTerminationBody =>
      'يجوز لنا تعليق حسابك أو إنهاءه إذا خالفت هذه الشروط، أو أسأت استخدام التطبيق، أو قمت بسلوك احتيالي أو ضار. يمكنك أيضًا طلب حذف حسابك وبياناتك في أي وقت.';

  @override
  String get termsSectionAvailability => 'توفر الخدمة';

  @override
  String get termsSectionAvailabilityBody =>
      'يُقدَّم Jma3a \"كما هو متاح\". يجوز لنا تعديل أو تعليق أو إيقاف أجزاء من التطبيق في أي وقت، ولا نضمن خدمة متواصلة أو خالية من الأخطاء.';

  @override
  String get termsSectionChanges => 'التغييرات على هذه الشروط';

  @override
  String get termsSectionChangesBody =>
      'قد نقوم بتحديث هذه الشروط من وقت لآخر. استمرارك في استخدام Jma3a بعد نشر التغييرات يعني موافقتك على الشروط المحدّثة.';

  @override
  String get termsSectionContact => 'تواصل معنا';

  @override
  String termsSectionContactBody(String email) {
    return 'إذا كانت لديك أسئلة حول هذه الشروط، تواصل معنا عبر $email.';
  }

  @override
  String get accountSuspendedDialogTitle => 'الحساب موقوف';

  @override
  String accountSuspendedUntil(String until) {
    return 'تم إيقاف حسابك حتى $until.';
  }

  @override
  String get accountBannedPermanently =>
      'تم حظر حسابك نهائيًا من استخدام جمعة.';

  @override
  String get appUpdateAvailableTitle => 'يتوفر تحديث';

  @override
  String get appUpdateDefaultTitle => 'يتوفر إصدار جديد';

  @override
  String get appUpdateDefaultMessage =>
      'يرجى تحديث التطبيق للاستمرار في الاستمتاع بأحدث الميزات.';

  @override
  String get appUpdateNowButton => 'تحديث';

  @override
  String get appUpdateLaterButton => 'لاحقًا';

  @override
  String get appUpdateBannerMessage => 'يتوفر إصدار جديد من تطبيق جمعة.';

  @override
  String get deleteAccountReasonPrompt => 'لماذا تغادر؟';

  @override
  String get deleteAccountReasonNoLongerUse => 'لم أعد أستخدم التطبيق';

  @override
  String get deleteAccountReasonPrivacy => 'مخاوف تتعلق بالخصوصية';

  @override
  String get deleteAccountReasonFoundAnother => 'وجدت تطبيقًا آخر';

  @override
  String get deleteAccountReasonTooManyNotifications => 'إشعارات كثيرة جدًا';

  @override
  String get deleteAccountReasonTechnicalProblems => 'مشاكل تقنية';

  @override
  String get deleteAccountReasonTemporaryBreak => 'استراحة مؤقتة';

  @override
  String get deleteAccountReasonOther => 'أخرى';

  @override
  String get deleteAccountReasonOtherHint => 'يرجى إخبارنا بالمزيد (مطلوب)';

  @override
  String get deleteAccountReasonValidation => 'يرجى اختيار سبب';

  @override
  String get deleteAccountOtherDescriptionValidation => 'يرجى وصف سببك';

  @override
  String get deleteAccountContinueButton => 'متابعة';

  @override
  String get tutHomeNavTitle => 'التنقّل';

  @override
  String get tutHomeNavBody =>
      'تنقّل من هنا بين الغرف والأصدقاء والمتجر وملفك الشخصي.';

  @override
  String get tutBrowserCreateTitle => 'أنشئ غرفة';

  @override
  String get tutBrowserCreateBody =>
      'استضِف غرفتك الخاصة، اختر لعبة وادعُ أصدقاءك للعب.';

  @override
  String get tutBrowserJoinCodeTitle => 'انضم برمز';

  @override
  String get tutBrowserJoinCodeBody =>
      'لديك رمز دعوة؟ أدخله هنا للانضمام إلى غرفة خاصة.';

  @override
  String get tutBrowserFilterTitle => 'ابحث عن لعبة';

  @override
  String get tutBrowserFilterBody =>
      'صفِّ الغرف العامة حسب نوع اللعبة لتجد غرفة مفتوحة للانضمام.';

  @override
  String get tutCreateNameTitle => 'سمِّ غرفتك';

  @override
  String get tutCreateNameBody => 'أعطِ غرفتك اسمًا حتى يتعرّف عليها أصدقاؤك.';

  @override
  String get tutCreateVisibilityTitle => 'عامة أو خاصة';

  @override
  String get tutCreateVisibilityBody =>
      'الغرف العامة تظهر في التصفّح للجميع. الغرف الخاصة بالدعوة فقط.';

  @override
  String get tutCreateSpectatorsTitle => 'المتفرّجون';

  @override
  String get tutCreateSpectatorsBody =>
      'اسمح للآخرين بالمشاهدة دون اللعب. المتفرّجون لا يؤثّرون في اللعبة أبدًا.';

  @override
  String get tutCreateButtonTitle => 'أنشئ واستضف';

  @override
  String get tutCreateButtonBody =>
      'ستصبح المضيف — أنت تتحكّم بالغرفة وتبدأ اللعبة.';

  @override
  String get tutLobbyManageTitle => 'أدِر غرفتك';

  @override
  String get tutLobbyManageBody =>
      'بصفتك المضيف يمكنك إغلاق الغرفة أمام اللاعبين الجدد ثم إعادة فتحها لاحقًا — دون إنهاء اللعبة.';

  @override
  String get tutLobbyStartTitle => 'ابدأ اللعبة';

  @override
  String get tutLobbyStartBody =>
      'المضيف وحده من يبدأ اللعبة. تأكّد أن الجميع جاهز أولًا.';

  @override
  String get tutLobbyReadyTitle => 'استعد';

  @override
  String get tutLobbyReadyBody =>
      'اضغط لإخبار المضيف بأنك جاهز. تبدأ اللعبة حين يجهز الجميع.';

  @override
  String get tutMembersTitle => 'إدارة اللاعبين';

  @override
  String get tutMembersBody =>
      'بصفتك المضيف، اضغط على لاعب لكتمه أو طرده أو حظره. الكتم يمنعه من التصرّف، والطرد يزيله، والحظر يمنع عودته.';

  @override
  String get tutTodTitle => 'صراحة أو تحدٍّ';

  @override
  String get tutTodBody =>
      'يظهر اللاعب الحالي هنا. يختار صراحة أو تحدّيًا ويُنجزه، ثم ينتقل الدور.';

  @override
  String get tutNhieTitle => 'دورك للإجابة';

  @override
  String get tutNhieBody =>
      'اقرأ العبارة ثم أدلِ بإجابتك بالأسفل. تظهر النتائج بعد أن يجيب الجميع.';

  @override
  String get tutNhieSpectatorBody =>
      'تابِع وشاهد كيف يجيب الجميع — المتفرّجون لا يصوّتون.';

  @override
  String get tutMemeTitle => 'تفاعل مع الميم';

  @override
  String get tutMemeBody =>
      'اختر تفاعلًا أو ملصقًا لهذا الميم وأرسِله. أطرف الاختيارات تفوز بالجولة.';

  @override
  String get tutReplayTitle => 'إعادة عرض الشروحات';

  @override
  String get tutReplaySubtitle => 'عرض الأدلة داخل التطبيق مرة أخرى';

  @override
  String get tutReplayDone =>
      'تمت إعادة تعيين الشروحات — ستظهر لك مجددًا أثناء تقدّمك.';

  @override
  String get lobbyAnonymousSpectator => 'متفرّج مجهول';

  @override
  String get packIssuesHeader => 'صحّح ما يلي قبل الإرسال:';

  @override
  String get packIssueTitle => 'أضِف اسمًا لكل لغة مختارة';

  @override
  String get packIssueCards => 'أضِف 20 بطاقة على الأقل';

  @override
  String get packIssueLanguage =>
      'يجب أن تحتوي كل بطاقة على محتوى بجميع اللغات المختارة';

  @override
  String packIssuePrice(int min) {
    return 'حدّد سعرًا لا يقل عن $min أوقية';
  }

  @override
  String get packIssueBalance =>
      'حِزم صراحة أو تحدٍّ تتطلّب عددًا متساويًا من بطاقات الصراحة والتحدّي';

  @override
  String get packIssuePunishments => 'أضِف 10 عقوبات على الأقل، أو احذفها كلها';

  @override
  String get packIssueTerms => 'وافِق على شروط إنشاء الحزمة';

  @override
  String get packTermsAgreePrefix => 'أوافق على ';

  @override
  String get packTermsAgreeLink => 'شروط إنشاء الحزمة';

  @override
  String get packTermsTitle => 'شروط إنشاء الحزمة';

  @override
  String get packTermsBody =>
      'بإرسالك حزمة فإنك تؤكّد أنّك: تملك كل المحتوى أو لديك الحق في مشاركته؛ وأن المحتوى لا ينتهك حقوق أحد ولا يحتوي على مواد غير قانونية أو تحريضية أو مضايقة؛ وأنك تقبل مراجعة محتوى Jma3a وقد تُرفض الحزمة أو تُزال؛ وأن الحِزم المدفوعة تخضع لسياسات الأرباح والاسترداد للمنصّة. يجب أن تستوفي الحِزم الحد الأدنى للسعر، وبالنسبة لصراحة أو تحدٍّ أن تحتوي على عدد متساوٍ من بطاقات الصراحة والتحدّي.';

  @override
  String packMinPriceLabel(int min) {
    return 'الحد الأدنى للسعر هو $min أوقية';
  }

  @override
  String packTruthDareBalanceHint(int truth, int dare) {
    return 'حِزم صراحة أو تحدٍّ تتطلّب عددًا متساويًا من بطاقات الصراحة والتحدّي. لديك $truth صراحة و$dare تحدٍّ.';
  }

  @override
  String get exploreAddFriend => 'إضافة صديق';

  @override
  String get exploreEmptyHint =>
      'تحقق مرة أخرى قريبًا — ينضم أشخاص جدد إلى مجموعة الاكتشاف مع نمو المجتمع.';

  @override
  String get exploreEmptyTitle => 'لا يوجد أحد لاكتشافه بعد';

  @override
  String get exploreLoadFailed => 'تعذّر تحميل الأشخاص المقترحين.';

  @override
  String get exploreRequestSent => 'تم إرسال الطلب';

  @override
  String get exploreSearchHint => 'ابحث بالاسم أو اسم المستخدم…';

  @override
  String get exploreSubtitle => 'اكتشف لاعبين مرتبين حسب السمعة';

  @override
  String get exploreTabLabel => 'استكشاف';

  @override
  String get honestyReasonHint =>
      'ما الذي جعل هذا يبدو غير صادق؟ (3 أحرف على الأقل)';

  @override
  String get honestyReasonSheetTitle => 'لماذا لم يكن هذا صادقًا؟';

  @override
  String honestyReasonsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أشار $count لاعب إلى أن هذا غير صادق',
      many: 'أشار $count لاعبًا إلى أن هذا غير صادق',
      few: 'أشار $count لاعبين إلى أن هذا غير صادق',
      two: 'أشار لاعبان إلى أن هذا غير صادق',
      one: 'أشار لاعب واحد إلى أن هذا غير صادق',
      zero: 'لم يُشِر أحد إلى أن هذا غير صادق',
    );
    return '$_temp0';
  }

  @override
  String get profileStreakActive => 'السلسلة نشطة';

  @override
  String get profileStreakInactive =>
      'السلسلة غير نشطة — العب اليوم للحفاظ عليها';

  @override
  String get officialResponsesTitle => 'ردود جِمَعَة الرسمية';

  @override
  String get officialResponsesReviews => 'المراجعات';

  @override
  String get officialResponsesWarnings => 'التحذيرات';

  @override
  String get officialResponsesBansAndSuspensions => 'الحظر والإيقاف';

  @override
  String get officialResponsesRequestsAndDecisions => 'الطلبات والقرارات';

  @override
  String get officialResponsesEmpty => 'لا يوجد شيء هنا بعد';

  @override
  String officialResponseExpiresOn(String date) {
    return 'تنتهي في $date';
  }

  @override
  String get walletDepositsUnavailable => 'الإيداع غير متاح مؤقتًا.';

  @override
  String get walletWithdrawalsUnavailable => 'السحب غير متاح مؤقتًا.';

  @override
  String get walletFinanceServiceUnavailable =>
      'الخدمة المالية غير متاحة مؤقتًا';

  @override
  String get authIdentifierLabel => 'البريد الإلكتروني أو رقم الهاتف';

  @override
  String get authIdentifierHint => 'you@example.com أو 12345678';

  @override
  String get authIdentifierRequired => 'أدخل بريدك الإلكتروني أو رقم هاتفك';

  @override
  String get authPasswordLabel => 'كلمة المرور';

  @override
  String get authPasswordHint => 'أدخل كلمة المرور';

  @override
  String get authPasswordRequired => 'كلمة المرور مطلوبة';

  @override
  String get authPasswordTooShort =>
      'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل';

  @override
  String get authPasswordTooLong => 'يجب ألا تتجاوز كلمة المرور 72 حرفًا';

  @override
  String get authPasswordNeedsLetterAndDigit =>
      'يجب أن تحتوي كلمة المرور على حرف ورقم واحد على الأقل';

  @override
  String get authPasswordConfirmationLabel => 'تأكيد كلمة المرور';

  @override
  String get authPasswordConfirmationHint => 'أعد إدخال كلمة المرور';

  @override
  String get authPasswordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get authShowPassword => 'إظهار كلمة المرور';

  @override
  String get authHidePassword => 'إخفاء كلمة المرور';

  @override
  String get authLogIn => 'تسجيل الدخول';

  @override
  String get authForgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get authInvalidCredentials =>
      'البريد الإلكتروني/الهاتف أو كلمة المرور غير صحيحة.';

  @override
  String get authSetPasswordTitle => 'تعيين كلمة مرور';

  @override
  String get authSetPasswordSubtitle =>
      'أنشئ كلمة مرور لتسجيل الدخول بدون رمز في المرة القادمة';

  @override
  String get authSetPasswordSubmit => 'ابدأ اللعب';

  @override
  String get authResetPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get authResetPasswordSubtitle => 'اختر كلمة مرور جديدة لحسابك';

  @override
  String get authResetPasswordSubmit => 'إعادة تعيين كلمة المرور';

  @override
  String get authPasswordSetSuccess => 'تم تعيين كلمة المرور بنجاح';

  @override
  String get authPasswordResetSuccess => 'تمت إعادة تعيين كلمة المرور بنجاح';

  @override
  String get authForgotPasswordTitle => 'نسيت كلمة المرور';

  @override
  String get authForgotPasswordSubtitle =>
      'أدخل بريدك الإلكتروني أو رقم هاتفك وسنرسل لك رمزًا';

  @override
  String get authForgotPasswordSendCode => 'إرسال الرمز';

  @override
  String get authBackToLogin => 'العودة لتسجيل الدخول';

  @override
  String get authMethodPhone => 'الهاتف';

  @override
  String get authMethodPhoneHint => '+222 ...';

  @override
  String get authMethodEmail => 'البريد الإلكتروني';

  @override
  String get authMethodEmailHint => 'name@email.com';

  @override
  String get authSignupTitle => 'انضم إلى جمعة 🎉';

  @override
  String get authSignupSubtitle => 'كيف تود التسجيل؟';

  @override
  String get authContinue => 'متابعة';

  @override
  String get authAlreadyHaveAccount => 'هل لديك حساب بالفعل؟';

  @override
  String get authPhoneInvalid => 'أدخل رقمك الموريتاني المكون من 8 أرقام';

  @override
  String get authWelcomeBack => 'مرحبًا بعودتك 👋';

  @override
  String get authReadyToPlay => 'جاهز للعب؟';

  @override
  String get authLegacyNoPasswordTitle => 'لا توجد كلمة مرور بعد';

  @override
  String get authLegacyNoPasswordBody =>
      'هذا الحساب ليس لديه كلمة مرور بعد. تحقق برمز لمرة واحدة لإنشاء واحدة.';

  @override
  String get authVerifyWithOtp => 'التحقق برمز';

  @override
  String get authDontHaveAccount => 'ليس لديك حساب؟';

  @override
  String get authCreateAccount => 'إنشاء حساب';

  @override
  String get passwordSettingsTitle => 'كلمة المرور والأمان';

  @override
  String get passwordSettingsUpdateTitle => 'تحديث كلمة المرور';

  @override
  String get passwordSettingsUpdateSubtitle => 'غيّر كلمة مرورك بأمان.';

  @override
  String get passwordSettingsVerifyButton => 'تحقق من كلمة المرور الحالية';

  @override
  String get passwordSettingsChangeButton => 'تغيير كلمة المرور';

  @override
  String get passwordSettingsOtpNotice =>
      'سنرسل لك رمز تحقق لتأكيد هويتك قبل تطبيق هذا التغيير.';

  @override
  String get passwordSettingsCurrentLabel => 'كلمة المرور الحالية';

  @override
  String get passwordSettingsNewLabel => 'كلمة المرور الجديدة';

  @override
  String get passwordSettingsConfirmLabel => 'تأكيد كلمة المرور الجديدة';

  @override
  String get passwordSettingsNoPasswordTitle => 'كلمة المرور';

  @override
  String get passwordSettingsNoPasswordBody => 'لم تقم بتعيين كلمة مرور بعد.';

  @override
  String get passwordSettingsHasPasswordBody => 'كلمة المرور الخاصة بك معينة.';

  @override
  String get passwordSettingsSetButton => 'تعيين كلمة مرور برمز';

  @override
  String get passwordSettingsChangeSuccess => 'تم تغيير كلمة المرور بنجاح';

  @override
  String get settingsPassword => 'كلمة المرور والأمان';

  @override
  String get settingsPasswordSubtitleReady => 'اضغط لتغيير كلمة المرور';

  @override
  String get settingsPasswordSubtitleNotSet => 'لم تقم بتعيين كلمة مرور بعد';

  @override
  String get authAccountAlreadyExists =>
      'يوجد حساب بهذا الرقم/البريد الإلكتروني بالفعل. يرجى تسجيل الدخول.';
}
