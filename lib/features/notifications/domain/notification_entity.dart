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

// ── Notification type ─────────────────────────────────────────────────────────

enum NotificationType {
  friendRequest,
  friendAccepted,
  roomInvite,
  roomStarted,
  packApproved,
  packRejected,
  packSale,
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

  String titleFor(String lang) => localizedValue(titleJson, lang);
  String bodyFor(String lang) => localizedValue(bodyJson, lang);

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

  String titleFor(String lang) => localizedValue(titleJson, lang);
  String bodyFor(String lang) => localizedValue(bodyJson, lang);

  @override
  List<Object?> get props => [id];
}
