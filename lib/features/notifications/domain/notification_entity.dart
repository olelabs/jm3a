import 'package:equatable/equatable.dart';

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
  achievement;

  static NotificationType fromString(String s) => switch (s) {
    'friend_request'  => friendRequest,
    'friend_accepted' => friendAccepted,
    'room_invite'     => roomInvite,
    'room_started'    => roomStarted,
    'pack_approved'   => packApproved,
    'pack_rejected'   => packRejected,
    'pack_sale'       => packSale,
    'wallet_credit'   => walletCredit,
    'wallet_debit'    => walletDebit,
    'moderation'      => moderation,
    'achievement'     => achievement,
    _                 => system,
  };

  String get dbString => switch (this) {
    friendRequest  => 'friend_request',
    friendAccepted => 'friend_accepted',
    roomInvite     => 'room_invite',
    roomStarted    => 'room_started',
    packApproved   => 'pack_approved',
    packRejected   => 'pack_rejected',
    packSale       => 'pack_sale',
    walletCredit   => 'wallet_credit',
    walletDebit    => 'wallet_debit',
    moderation     => 'moderation',
    achievement    => 'achievement',
    system         => 'system',
  };

  String get emoji => switch (this) {
    friendRequest  => '👤',
    friendAccepted => '✅',
    roomInvite     => '🎮',
    roomStarted    => '▶️',
    packApproved   => '📦',
    packRejected   => '❌',
    packSale       => '💰',
    walletCredit   => '💳',
    walletDebit    => '💸',
    moderation     => '⚠️',
    achievement    => '🏆',
    system         => '📢',
  };

  String get displayLabel => switch (this) {
    friendRequest  => 'Friend Request',
    friendAccepted => 'Friend Accepted',
    roomInvite     => 'Room Invite',
    roomStarted    => 'Game Started',
    packApproved   => 'Pack Approved',
    packRejected   => 'Pack Rejected',
    packSale       => 'Pack Sale',
    walletCredit   => 'Wallet Credit',
    walletDebit    => 'Wallet Debit',
    moderation     => 'Moderation',
    achievement    => 'Achievement',
    system         => 'System',
  };

  /// Which route to navigate to on tap
  String? get defaultRoute => switch (this) {
    friendRequest  => '/friends',
    friendAccepted => '/friends',
    roomInvite     => null,  // needs room_id from data
    packApproved   => '/marketplace',
    packRejected   => '/creator',
    packSale       => '/wallet',
    walletCredit   => '/wallet',
    walletDebit    => '/wallet',
    _              => '/notifications',
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

  final String                id;
  final String                userId;
  final NotificationType      type;
  final Map<String, dynamic>  titleJson;
  final Map<String, dynamic>  bodyJson;
  final Map<String, dynamic>  data;
  final bool                  isRead;
  final DateTime              createdAt;
  final DateTime?             expiresAt;

  String titleFor(String lang) =>
      titleJson[lang] as String? ?? titleJson['en'] as String? ?? '';
  String bodyFor(String lang) =>
      bodyJson[lang] as String? ?? bodyJson['en'] as String? ?? '';

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  NotificationEntity copyWith({bool? isRead}) => NotificationEntity(
    id: id, userId: userId, type: type,
    titleJson: titleJson, bodyJson: bodyJson, data: data,
    isRead:    isRead ?? this.isRead,
    createdAt: createdAt, expiresAt: expiresAt,
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
  final bool             inApp;
  final bool             push;

  NotificationPreference copyWith({bool? inApp, bool? push}) =>
      NotificationPreference(
        type:  type,
        inApp: inApp ?? this.inApp,
        push:  push  ?? this.push,
      );

  @override
  List<Object?> get props => [type, inApp, push];
}

// ── In-app toast ──────────────────────────────────────────────────────────────
/// Ephemeral in-app notification banner shown when a push arrives while
/// the user is actively using the app. Dismissed after 4 seconds or on tap.

class InAppToast extends Equatable {
  const InAppToast({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.createdAt,
  });

  final String               id;
  final NotificationType     type;
  final String               title;
  final String               body;
  final Map<String, dynamic> data;
  final DateTime             createdAt;

  @override
  List<Object?> get props => [id];
}
