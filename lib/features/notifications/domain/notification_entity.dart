import 'package:equatable/equatable.dart';

// ── Localized text helpers ──────────────────────────────────────────────────
// Shared by NotificationEntity and InAppToast so every consumer (list,
// toast, local push) resolves a notification's title/body the exact same
// way instead of each widget re-implementing its own JSONB fallback logic.

/// Parses a `notifications.title`/`.body` column value into the
/// `{lang: text}` map the UI reads from. The DB column is `jsonb NOT NULL`,
/// but the JSON value stored inside it isn't always an object — a plain
/// string scalar (from an older, pre-localization write path, or any
/// future direct-SQL insert that doesn't use jsonb_build_object) decodes
/// to a raw Dart String, not a Map. Treating that case as an unrecognized
/// single value keyed as "und" (rather than assuming it's English) means
/// [localizedValue] still surfaces it for every locale via its
/// any-available-value fallback, without silently mislabeling it.
Map<String, dynamic> parseLocalizedJson(dynamic raw) {
  if (raw is Map) return raw.cast<String, dynamic>();
  if (raw is String && raw.isNotEmpty) return {'und': raw};
  return const {};
}

/// Resolves the best available string for [lang] out of a parsed
/// localized-text map: the requested language, then English, then
/// whatever non-empty value exists at all (so a notification is never
/// rendered blank just because neither the requested language nor English
/// happens to be present) — never returns null, only ''.
String localizedValue(Map<String, dynamic> json, String lang) {
  final requested = json[lang];
  if (requested is String && requested.isNotEmpty) return requested;
  final en = json['en'];
  if (en is String && en.isNotEmpty) return en;
  for (final v in json.values) {
    if (v is String && v.isNotEmpty) return v;
  }
  return '';
}

// ── Access-level / pack display copy ────────────────────────────────────────
// Pre-release terminology pass. Jma3a Plus (tier `premium`) and Jma3a
// Elite (tier `premium_plus`) are access levels granted by the Jma3a team,
// not paid subscriptions, and packs are things a user gets access to, not
// purchases. Some producers (SQL triggers/RPCs that can't be changed without
// a production migration, and rows already stored in users' inboxes) still
// carry "subscription / renew / repurchase" wording and raw tier ids, so for
// these deterministic templates the app renders its own copy instead. The
// stored row, its type, data payload and deep link are untouched — only
// what is displayed changes. Returns null for every other notification.

typedef NotificationCopy = ({
  Map<String, String> title,
  Map<String, String> body,
});

Map<String, String> _levelName(Object? tier) => tier == 'premium_plus'
    ? const {'en': 'Jma3a Elite', 'ar': 'جماعة إيليت', 'fr': 'Jma3a Elite'}
    : const {'en': 'Jma3a Plus', 'ar': 'جماعة بلس', 'fr': 'Jma3a Plus'};

NotificationCopy? accessLevelNotificationCopy(
  NotificationType type,
  Map<String, dynamic> data,
) {
  final l = _levelName(data['tier']);
  switch (type) {
    case NotificationType.subscriptionStarted:
      return (
        title: {
          'en': "✦ You've been granted ${l['en']} access!",
          'ar': '✦ تم منحك وصول ${l['ar']}!',
          'fr': '✦ Accès ${l['fr']} accordé !',
        },
        body: {
          'en': 'The Jma3a team has granted you ${l['en']}. Enjoy your new features!',
          'ar': 'منحك فريق جماعة ${l['ar']}. استمتع بمزاياك الجديدة!',
          'fr': "L'équipe Jma3a vous a accordé ${l['fr']}. Profitez de vos nouvelles fonctionnalités !",
        },
      );
    case NotificationType.subscriptionExpiring2d:
      return (
        title: {
          'en': 'Your ${l['en']} access ends soon',
          'ar': 'وصولك إلى ${l['ar']} ينتهي قريباً',
          'fr': 'Votre accès ${l['fr']} prend bientôt fin',
        },
        body: {
          'en': 'Your ${l['en']} access ends in 2 days.',
          'ar': 'ينتهي وصولك إلى ${l['ar']} خلال يومين.',
          'fr': 'Votre accès ${l['fr']} prend fin dans 2 jours.',
        },
      );
    case NotificationType.subscriptionExpiring1d:
      return (
        title: {
          'en': 'Your ${l['en']} access ends tomorrow',
          'ar': 'وصولك إلى ${l['ar']} ينتهي غداً',
          'fr': 'Votre accès ${l['fr']} prend fin demain',
        },
        body: {
          'en': 'Your ${l['en']} access ends tomorrow.',
          'ar': 'ينتهي وصولك إلى ${l['ar']} غداً.',
          'fr': 'Votre accès ${l['fr']} prend fin demain.',
        },
      );
    case NotificationType.subscriptionExpired:
      return (
        title: {
          'en': '${l['en']} access ended',
          'ar': 'انتهى وصول ${l['ar']}',
          'fr': 'Fin de l\'accès ${l['fr']}',
        },
        body: {
          'en': 'Your ${l['en']} access has ended, and your Jma3a privileges have been updated.',
          'ar': 'انتهى وصولك إلى ${l['ar']}، وتم تحديث امتيازاتك في جماعة.',
          'fr': 'Votre accès ${l['fr']} a pris fin et vos privilèges Jma3a ont été mis à jour.',
        },
      );
    case NotificationType.creatorPacksTransferred:
      return (
        title: const {
          'en': 'Your Packs Are Now Jma3a-Managed',
          'ar': 'أصبحت حزمك الآن تحت إدارة جماعة',
          'fr': 'Vos packs sont maintenant gérés par Jma3a',
        },
        body: const {
          'en': "Your Jma3a Elite access ended, so Jma3a is now managing your packs. If your Elite access is restored within 2 days, you'll keep full creator privileges.",
          'ar': 'انتهى وصولك إلى جماعة إيليت، لذا أصبحت جماعة تدير حزمك الآن. إذا تمت استعادة وصول إيليت خلال يومين، ستحتفظ بامتيازات المنشئ كاملة.',
          'fr': "Votre accès Jma3a Elite a pris fin, Jma3a gère donc désormais vos packs. Si votre accès Elite est rétabli sous 2 jours, vous conserverez tous vos privilèges de créateur.",
        },
      );
    case NotificationType.creatorPrivilegesRemoved:
      return (
        title: const {
          'en': 'Verified Creator Status Removed',
          'ar': 'تمت إزالة حالة المنشئ الموثق',
          'fr': 'Statut de créateur vérifié retiré',
        },
        body: const {
          'en': 'Your verified creator status and privileges were removed after your Jma3a Elite access ended. You can submit a recovery request from your profile.',
          'ar': 'تمت إزالة حالة المنشئ الموثق وامتيازاتك بعد انتهاء وصولك إلى جماعة إيليت. يمكنك تقديم طلب استعادة من ملفك الشخصي.',
          'fr': "Votre statut de créateur vérifié et vos privilèges ont été retirés après la fin de votre accès Jma3a Elite. Vous pouvez soumettre une demande de récupération depuis votre profil.",
        },
      );
    case NotificationType.system when data['reason'] == 'packs_restored_grace':
      return (
        title: const {'en': 'Jma3a', 'ar': 'جماعة', 'fr': 'Jma3a'},
        body: const {
          'en': 'Your Jma3a Elite access was restored in time — full control of your packs is back.',
          'ar': 'تمت استعادة وصولك إلى جماعة إيليت في الوقت المناسب — عاد إليك التحكم الكامل في حزمك.',
          'fr': 'Votre accès Jma3a Elite a été rétabli à temps — vous avez retrouvé le contrôle total de vos packs.',
        },
      );
    case NotificationType.packExpired:
      final name = (data['pack_name'] as String?)?.trim();
      final hasName = name != null && name.isNotEmpty;
      return (
        title: const {
          'en': 'Pack Access Ended',
          'ar': 'انتهى الوصول إلى الحزمة',
          'fr': "Fin de l'accès au pack",
        },
        body: {
          'en': hasName ? 'Your access to "$name" has ended.' : 'Your access to a pack has ended.',
          'ar': hasName ? 'انتهى وصولك إلى "$name".' : 'انتهى وصولك إلى إحدى الحزم.',
          'fr': hasName ? "Votre accès à « $name » a pris fin." : "Votre accès à un pack a pris fin.",
        },
      );
    default:
      return null;
  }
}

// ── Notification type ─────────────────────────────────────────────────────────

enum NotificationType {
  friendRequest,
  friendAccepted,
  roomInvite,
  roomStarted,
  packApproved,
  packRejected,
  packSale,
  packGranted,
  walletCredit,
  walletDebit,
  moderation,
  system,
  achievement,
  follow,
  packReview,
  packExpired,
  physicalPackStatus,
  subscriptionStarted,
  subscriptionExpiring2d,
  subscriptionExpiring1d,
  subscriptionExpired,
  roomJoinRequest,
  roomJoinRequestAccepted,
  roomJoinRequestRejected,
  roomKicked,
  creatorPacksTransferred,
  creatorPrivilegesRemoved,
  creatorRecoveryApproved,
  creatorRecoveryRejected,
  chatMessage,
  streakIncreased;

  static NotificationType fromString(String s) => switch (s) {
    'friend_request' => friendRequest,
    'friend_accepted' => friendAccepted,
    'room_invite' => roomInvite,
    'room_started' => roomStarted,
    'pack_approved' => packApproved,
    'pack_rejected' => packRejected,
    'pack_sale' => packSale,
    'pack_granted' => packGranted,
    'wallet_credit' => walletCredit,
    'wallet_debit' => walletDebit,
    'moderation' => moderation,
    'achievement' => achievement,
    'follow' => follow,
    'pack_review' => packReview,
    'pack_expired' => packExpired,
    'physical_pack_status' => physicalPackStatus,
    'subscription_started' => subscriptionStarted,
    'subscription_expiring_2d' => subscriptionExpiring2d,
    'subscription_expiring_1d' => subscriptionExpiring1d,
    'subscription_expired' => subscriptionExpired,
    'room_join_request' => roomJoinRequest,
    'room_join_request_accepted' => roomJoinRequestAccepted,
    'room_join_request_rejected' => roomJoinRequestRejected,
    'room_kicked' => roomKicked,
    'creator_packs_transferred' => creatorPacksTransferred,
    'creator_privileges_removed' => creatorPrivilegesRemoved,
    'creator_recovery_approved' => creatorRecoveryApproved,
    'creator_recovery_rejected' => creatorRecoveryRejected,
    'room_chat_message' => chatMessage,
    'streak_increased' => streakIncreased,
    _ => system,
  };

  String get dbString => switch (this) {
    friendRequest => 'friend_request',
    friendAccepted => 'friend_accepted',
    roomInvite => 'room_invite',
    roomStarted => 'room_started',
    packApproved => 'pack_approved',
    packRejected => 'pack_rejected',
    packSale => 'pack_sale',
    packGranted => 'pack_granted',
    walletCredit => 'wallet_credit',
    walletDebit => 'wallet_debit',
    moderation => 'moderation',
    achievement => 'achievement',
    system => 'system',
    follow => 'follow',
    packReview => 'pack_review',
    packExpired => 'pack_expired',
    physicalPackStatus => 'physical_pack_status',
    subscriptionStarted => 'subscription_started',
    subscriptionExpiring2d => 'subscription_expiring_2d',
    subscriptionExpiring1d => 'subscription_expiring_1d',
    subscriptionExpired => 'subscription_expired',
    roomJoinRequest => 'room_join_request',
    roomJoinRequestAccepted => 'room_join_request_accepted',
    roomJoinRequestRejected => 'room_join_request_rejected',
    roomKicked => 'room_kicked',
    creatorPacksTransferred => 'creator_packs_transferred',
    creatorPrivilegesRemoved => 'creator_privileges_removed',
    creatorRecoveryApproved => 'creator_recovery_approved',
    creatorRecoveryRejected => 'creator_recovery_rejected',
    chatMessage => 'room_chat_message',
    streakIncreased => 'streak_increased',
  };

  String get emoji => switch (this) {
    friendRequest => '👤',
    friendAccepted => '✅',
    roomInvite => '🎮',
    roomStarted => '▶️',
    packApproved => '📦',
    packRejected => '❌',
    packSale => '💰',
    packGranted => '🎉',
    walletCredit => '💳',
    walletDebit => '💸',
    moderation => '⚠️',
    achievement => '🏆',
    system => '📢',
    follow => '👤',
    packReview => '⭐',
    packExpired => '📦',
    physicalPackStatus => '📦',
    subscriptionStarted => '✦',
    subscriptionExpiring2d => '⏳',
    subscriptionExpiring1d => '⏳',
    subscriptionExpired => '✦',
    roomJoinRequest => '🎮',
    roomJoinRequestAccepted => '✅',
    roomJoinRequestRejected => '❌',
    roomKicked => '🚪',
    creatorPacksTransferred => '📦',
    creatorPrivilegesRemoved => '⚠️',
    creatorRecoveryApproved => '✅',
    creatorRecoveryRejected => '❌',
    chatMessage => '💬',
    streakIncreased => '🔥',
  };
}

// ── Notification entity ───────────────────────────────────────────────────────

class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.titleJson,
    required this.bodyJson,
    required this.data,
    required this.isRead,
    required this.createdAt,
    this.expiresAt,
  });

  final String id;
  final String userId;
  final NotificationType type;
  final Map<String, dynamic> titleJson;
  final Map<String, dynamic> bodyJson;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? expiresAt;

  String titleFor(String lang) => localizedValue(
    accessLevelNotificationCopy(type, data)?.title ?? titleJson,
    lang,
  );
  String bodyFor(String lang) => localizedValue(
    accessLevelNotificationCopy(type, data)?.body ?? bodyJson,
    lang,
  );

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  NotificationEntity copyWith({bool? isRead}) => NotificationEntity(
    id: id,
    userId: userId,
    type: type,
    titleJson: titleJson,
    bodyJson: bodyJson,
    data: data,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
    expiresAt: expiresAt,
  );

  @override
  List<Object?> get props => [id, userId, type, isRead, createdAt];
}

// ── Notification preference ───────────────────────────────────────────────────

class NotificationPreference extends Equatable {
  const NotificationPreference({
    required this.type,
    required this.inApp,
    required this.push,
  });

  final NotificationType type;
  final bool inApp;
  final bool push;

  NotificationPreference copyWith({bool? inApp, bool? push}) =>
      NotificationPreference(
        type: type,
        inApp: inApp ?? this.inApp,
        push: push ?? this.push,
      );

  @override
  List<Object?> get props => [type, inApp, push];
}

// ── In-app toast ──────────────────────────────────────────────────────────────
/// Ephemeral in-app notification banner shown when a push arrives while
/// the user is actively using the app. Auto-dismissed a few seconds after
/// being shown (timing owned by the banner widget itself) or dismissed
/// earlier by a tap/swipe.

class InAppToast extends Equatable {
  const InAppToast({
    required this.id,
    required this.type,
    required this.titleJson,
    required this.bodyJson,
    required this.data,
    required this.createdAt,
    this.avatarUrl,
  });

  final String id;
  final NotificationType type;
  final Map<String, dynamic> titleJson;
  final Map<String, dynamic> bodyJson;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  /// Sender/actor avatar (e.g. the requester on a friend_request), when the
  /// backend payload includes one. Falls back to a type icon when absent.
  final String? avatarUrl;

  String titleFor(String lang) => localizedValue(
    accessLevelNotificationCopy(type, data)?.title ?? titleJson,
    lang,
  );
  String bodyFor(String lang) => localizedValue(
    accessLevelNotificationCopy(type, data)?.body ?? bodyJson,
    lang,
  );

  @override
  List<Object?> get props => [id];
}
