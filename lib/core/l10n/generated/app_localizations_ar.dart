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
  String get next => 'التالي';

  @override
  String get back => 'رجوع';

  @override
  String get skip => 'تخطي';

  @override
  String get edit => 'تعديل';

  @override
  String get delete => 'حذف';

  @override
  String get remove => 'إزالة';

  @override
  String get close => 'إغلاق';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get or => 'أو';

  @override
  String get optional => 'اختياري';

  @override
  String characters(int count, int max) {
    return '$count / $max';
  }

  @override
  String get error => 'حدث خطأ ما';

  @override
  String get errorNetwork => 'خطأ في الشبكة. يرجى التحقق من الاتصال.';

  @override
  String get errorUnexpected => 'حدث خطأ غير متوقع. يرجى المحاولة مجدداً.';

  @override
  String get errorNotFound => 'غير موجود';

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
  String get authSendingOtp => 'جارٍ الإرسال…';

  @override
  String authOtpSent(String email) {
    return 'تم إرسال الرمز إلى $email';
  }

  @override
  String get authOtpLabel => 'رمز التحقق';

  @override
  String get authOtpHint => 'أدخل الرمز المكوّن من 6 أرقام';

  @override
  String get authOtpVerify => 'تحقق';

  @override
  String get authOtpVerifying => 'جارٍ التحقق…';

  @override
  String get authOtpResend => 'إعادة إرسال الرمز';

  @override
  String authOtpResendIn(int seconds) {
    return 'إعادة الإرسال خلال $secondsث';
  }

  @override
  String get authOtpExpired => 'انتهت صلاحية الرمز. يرجى طلب رمز جديد.';

  @override
  String get authOtpInvalid => 'رمز غير صحيح. يرجى المحاولة مجدداً.';

  @override
  String get authOtpMaxAttempts => 'محاولات كثيرة جداً. يرجى طلب رمز جديد.';

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
  String get profileTitle => 'الملف الشخصي';

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
  String get settingsSignOut => 'تسجيل الخروج';

  @override
  String get settingsSignOutConfirm => 'هل أنت متأكد من تسجيل الخروج؟';

  @override
  String get roomsTitle => 'الغرف';

  @override
  String get roomsBrowse => 'تصفح الغرف';

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
  String get roomsJoining => 'جارٍ الانضمام…';

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
  String get roomsBanned => 'أنت محظور من هذه الغرفة';

  @override
  String get lobbyTitle => 'غرفة الانتظار';

  @override
  String get lobbyWaiting => 'في انتظار اللاعبين…';

  @override
  String get lobbyReady => 'جاهز';

  @override
  String get lobbyNotReady => 'غير جاهز';

  @override
  String get lobbyStartGame => 'بدء اللعبة';

  @override
  String get lobbySelectGame => 'اختر اللعبة';

  @override
  String get lobbySelectPack => 'اختر الباقة';

  @override
  String get lobbyCopied => 'تم نسخ الرمز!';

  @override
  String get lobbyLeave => 'مغادرة الغرفة';

  @override
  String get lobbyLeaveConfirm => 'هل أنت متأكد من المغادرة؟';

  @override
  String lobbyOwnerLeft(String name) {
    return '$name هو مالك الغرفة الآن';
  }

  @override
  String lobbyPlayerJoined(String name) {
    return 'انضم $name';
  }

  @override
  String lobbyPlayerLeft(String name) {
    return 'غادر $name';
  }

  @override
  String get chatPlaceholder => 'قل شيئاً…';

  @override
  String get chatMuted => 'تم كتم صوتك';

  @override
  String get chatSend => 'إرسال';

  @override
  String get gameSettings => 'إعدادات اللعبة';

  @override
  String get gameSettingsTurnTimer => 'وقت الدور';

  @override
  String get gameSettingsAllowSkip => 'السماح بالتخطي';

  @override
  String get gameSettingsMaxRounds => 'أقصى عدد جولات';

  @override
  String get gameSettingsAllowSpicy => 'السماح بالمحتوى الساخن';

  @override
  String gameSettingsSeconds(int n) {
    return '$nث';
  }

  @override
  String get gameReconnecting => 'جارٍ إعادة الاتصال…';

  @override
  String get gameRecovering => 'جارٍ المزامنة…';

  @override
  String get gameConnectionLost => 'انقطع الاتصال';

  @override
  String get gameConnectionLostBody => 'تعذّر إعادة الاتصال بعد عدة محاولات.';

  @override
  String get gameLeaveRoom => 'مغادرة الغرفة';

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
  String get moderationYouWereMuted => 'تم كتم صوتك';

  @override
  String get moderationGamePaused => 'تم إيقاف اللعبة';

  @override
  String get moderationGameResumed => 'استُؤنفت اللعبة';

  @override
  String get roomsJoinRequestSent =>
      'تم إرسال طلب الانضمام! في انتظار موافقة المضيف.';

  @override
  String get roomsRequiresApproval => 'هذه الغرفة تتطلب موافقة للانضمام';

  @override
  String get roomsJoinApproved => 'تمت الموافقة على طلب انضمامك!';

  @override
  String get roomsJoinRejected => 'تم رفض طلب انضمامك.';

  @override
  String get roomsSpectators => 'المتفرجون';

  @override
  String roomsSpectatorCount(int count) {
    return '$count يشاهد';
  }

  @override
  String get settingsNotifications => 'الإشعارات';

  @override
  String get settingsNotifFriendRequests => 'طلبات الصداقة';

  @override
  String get settingsNotifRoomInvites => 'دعوات الغرف';

  @override
  String get settingsNotifGameActions => 'أحداث اللعبة';

  @override
  String get settingsNotifWallet => 'تحديثات المحفظة';

  @override
  String get settingsNotifPackSales => 'مبيعات الباقات';

  @override
  String get walletEarnings => 'الأرباح';

  @override
  String get walletEarningsTotal => 'إجمالي الأرباح';

  @override
  String get walletEarningsThisMonth => 'هذا الشهر';

  @override
  String get walletEarningsTotalSales => 'إجمالي المبيعات';

  @override
  String get walletEarningsAvailable => 'المتاح';

  @override
  String get walletEarningsCommissionRate => 'نسبتك';

  @override
  String get walletTransactionHistory => 'سجل المعاملات';

  @override
  String get profileGames => 'الألعاب';

  @override
  String get profileFriends => 'الأصدقاء';

  @override
  String get profilePacks => 'الباقات';

  @override
  String get profileFollowers => 'المتابعون';

  @override
  String get profileFollowing => 'متابَعون';

  @override
  String get profileNotFound => 'الملف الشخصي غير موجود';

  @override
  String profileGamesPlayed(int count) {
    return '$count لعبة';
  }

  @override
  String get gameSettingsSpicy => 'بطاقات حارة';

  @override
  String get gameSettingsRequireApproval => 'يتطلب موافقة للانضمام';

  @override
  String get gameSettingsAllowSpectators => 'السماح بالمتفرجين';

  @override
  String get lobbyJoinRequests => 'طلبات الانضمام';

  @override
  String get lobbyApprove => 'قبول';

  @override
  String get lobbyReject => 'رفض';

  @override
  String get packCategory => 'الفئة';

  @override
  String get packCategoryHint => 'اختر فئة';

  @override
  String get packCategoryNone => 'بدون فئة';
}
