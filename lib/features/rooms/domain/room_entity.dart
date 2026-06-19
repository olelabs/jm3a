// // import 'package:equatable/equatable.dart';
// // import '../../games/engine/base_game_engine.dart';

// // // ── Enums ─────────────────────────────────────────────────────────────────────

// // enum RoomStatus {
// //   waiting,
// //   starting,
// //   inGame,
// //   paused,
// //   ended,
// //   closed;

// //   static RoomStatus fromString(String s) => switch (s) {
// //     'starting' => starting,
// //     'in_game' => inGame,
// //     'paused' => paused,
// //     'ended' => ended,
// //     'closed' => closed,
// //     _ => waiting,
// //   };

// //   String toDbString() => switch (this) {
// //     starting => 'starting',
// //     inGame => 'in_game',
// //     paused => 'paused',
// //     ended => 'ended',
// //     closed => 'closed',
// //     waiting => 'waiting',
// //   };
// // }

// // enum RoomVisibility {
// //   public,
// //   private;

// //   static RoomVisibility fromString(String s) =>
// //       s == 'private' ? private : public;
// // }

// // enum MemberRole { player, moderator, spectator }

// // // ── RoomEntity ────────────────────────────────────────────────────────────────

// // class RoomEntity extends Equatable {
// //   const RoomEntity({
// //     required this.id,
// //     required this.ownerId,
// //     required this.name,
// //     required this.status,
// //     required this.visibility,
// //     required this.maxPlayers,
// //     required this.currentPlayers,
// //     this.inviteCode,
// //     this.gameType,
// //     this.packId,
// //     this.language = 'en',
// //     this.allowSpicy = false,
// //     this.coverEmoji = '🎮',
// //     this.lastActiveAt,
// //     this.createdAt,
// //   });

// //   final String id;
// //   final String ownerId;
// //   final String name;
// //   final RoomStatus status;
// //   final RoomVisibility visibility;
// //   final int maxPlayers;
// //   final int currentPlayers;
// //   final String? inviteCode;
// //   final GameType? gameType;
// //   final String? packId;
// //   final String language;
// //   final bool allowSpicy;
// //   final String coverEmoji;
// //   final DateTime? lastActiveAt;
// //   final DateTime? createdAt;

// //   bool get isFull => currentPlayers >= maxPlayers;
// //   bool get isWaiting => status == RoomStatus.waiting;
// //   bool get isInGame => status == RoomStatus.inGame;
// //   bool get isPaused => status == RoomStatus.paused;
// //   bool get isActive =>
// //       status == RoomStatus.waiting || status == RoomStatus.inGame;
// //   bool get canJoin => !isFull && isActive;
// //   bool get isPrivate => visibility == RoomVisibility.private;

// //   RoomEntity copyWith({
// //     String? ownerId,
// //     String? name,
// //     RoomStatus? status,
// //     int? currentPlayers,
// //     GameType? gameType,
// //     String? packId,
// //     bool? allowSpicy,
// //     DateTime? lastActiveAt,
// //   }) => RoomEntity(
// //     id: id,
// //     ownerId: ownerId ?? this.ownerId,
// //     name: name ?? this.name,
// //     status: status ?? this.status,
// //     visibility: visibility,
// //     maxPlayers: maxPlayers,
// //     currentPlayers: currentPlayers ?? this.currentPlayers,
// //     inviteCode: inviteCode,
// //     gameType: gameType ?? this.gameType,
// //     packId: packId ?? this.packId,
// //     language: language,
// //     allowSpicy: allowSpicy ?? this.allowSpicy,
// //     coverEmoji: coverEmoji,
// //     lastActiveAt: lastActiveAt ?? this.lastActiveAt,
// //     createdAt: createdAt,
// //   );

// //   @override
// //   List<Object?> get props => [
// //     id,
// //     ownerId,
// //     name,
// //     status,
// //     visibility,
// //     maxPlayers,
// //     currentPlayers,
// //     inviteCode,
// //     gameType,
// //     packId,
// //     language,
// //     allowSpicy,
// //   ];
// // }

// // // ── RoomMemberEntity ──────────────────────────────────────────────────────────

// // class RoomMemberEntity extends Equatable {
// //   const RoomMemberEntity({
// //     required this.userId,
// //     required this.displayName,
// //     this.avatarUrl,
// //     required this.seatOrder,
// //     required this.isReady,
// //     required this.isOwner,
// //     required this.isModerator,
// //     this.isMuted = false,
// //     this.isDisconnected = false,
// //     this.joinedAt,
// //   });

// //   final String userId;
// //   final String displayName;
// //   final String? avatarUrl;
// //   final int seatOrder;
// //   final bool isReady;
// //   final bool isOwner;
// //   final bool isModerator;
// //   final bool isMuted;
// //   final bool isDisconnected;
// //   final DateTime? joinedAt;

// //   bool get canModerate => isOwner || isModerator;
// //   bool get isActive => !isDisconnected;

// //   String get displayRole {
// //     if (isOwner) return 'Owner';
// //     if (isModerator) return 'Mod';
// //     return '';
// //   }

// //   RoomMemberEntity copyWith({
// //     bool? isReady,
// //     bool? isOwner,
// //     bool? isModerator,
// //     bool? isMuted,
// //     bool? isDisconnected,
// //   }) => RoomMemberEntity(
// //     userId: userId,
// //     displayName: displayName,
// //     avatarUrl: avatarUrl,
// //     seatOrder: seatOrder,
// //     isReady: isReady ?? this.isReady,
// //     isOwner: isOwner ?? this.isOwner,
// //     isModerator: isModerator ?? this.isModerator,
// //     isMuted: isMuted ?? this.isMuted,
// //     isDisconnected: isDisconnected ?? this.isDisconnected,
// //     joinedAt: joinedAt,
// //   );

// //   @override
// //   List<Object?> get props => [
// //     userId,
// //     displayName,
// //     seatOrder,
// //     isReady,
// //     isOwner,
// //     isModerator,
// //     isMuted,
// //     isDisconnected,
// //   ];
// // }

// // // ── ChatMessageEntity ─────────────────────────────────────────────────────────

// // enum ChatMessageType { user, system }

// // class ChatMessageEntity extends Equatable {
// //   const ChatMessageEntity({
// //     required this.id,
// //     required this.roomId,
// //     required this.userId,
// //     required this.displayName,
// //     this.avatarUrl,
// //     required this.content,
// //     required this.createdAt,
// //     this.isDeleted = false,
// //     this.isOptimistic = false,
// //     this.type = ChatMessageType.user,
// //   });

// //   final String id;
// //   final String roomId;
// //   final String userId;
// //   final String displayName;
// //   final String? avatarUrl;
// //   final String content;
// //   final DateTime createdAt;
// //   final bool isDeleted;
// //   final bool isOptimistic; // client-only: not yet confirmed by server
// //   final ChatMessageType type;

// //   bool get isSystem => type == ChatMessageType.system;

// //   @override
// //   List<Object?> get props => [id, roomId, userId, content, createdAt];
// // }

// // // ── RoomSettingsEntity ────────────────────────────────────────────────────────

// // class RoomSettingsEntity extends Equatable {
// //   const RoomSettingsEntity({
// //     this.turnTimerSeconds = 60,
// //     this.allowSkip = true,
// //     this.maxRounds = 10,
// //     this.chatEnabled = true,
// //     this.allowSpectators = false,
// //     this.allowSpicy = false,
// //     this.requiresApproval = false,
// //   });

// //   final int turnTimerSeconds;
// //   final bool allowSkip;
// //   final int maxRounds;
// //   final bool chatEnabled;
// //   final bool allowSpectators;
// //   final bool allowSpicy;
// //   final bool requiresApproval;

// //   RoomSettingsEntity copyWith({
// //     int? turnTimerSeconds,
// //     bool? allowSkip,
// //     int? maxRounds,
// //     bool? chatEnabled,
// //     bool? allowSpectators,
// //     bool? allowSpicy,
// //     bool? requiresApproval,
// //   }) => RoomSettingsEntity(
// //     turnTimerSeconds: turnTimerSeconds ?? this.turnTimerSeconds,
// //     allowSkip: allowSkip ?? this.allowSkip,
// //     maxRounds: maxRounds ?? this.maxRounds,
// //     chatEnabled: chatEnabled ?? this.chatEnabled,
// //     allowSpectators: allowSpectators ?? this.allowSpectators,
// //     allowSpicy: allowSpicy ?? this.allowSpicy,
// //     requiresApproval: requiresApproval ?? this.requiresApproval,
// //   );

// //   Map<String, dynamic> toMap() => {
// //     'turn_timer_secs': turnTimerSeconds,
// //     'allow_skip': allowSkip,
// //     'max_rounds': maxRounds,
// //     'chat_enabled': chatEnabled,
// //     'allow_spectators': allowSpectators,
// //     'allow_spicy': allowSpicy,
// //     'requires_approval': requiresApproval,
// //   };

// //   static RoomSettingsEntity fromMap(Map<String, dynamic> m) =>
// //       RoomSettingsEntity(
// //         turnTimerSeconds: m['turn_timer_secs'] as int? ?? 60,
// //         allowSkip: m['allow_skip'] as bool? ?? true,
// //         maxRounds: m['max_rounds'] as int? ?? 10,
// //         chatEnabled: m['chat_enabled'] as bool? ?? true,
// //         allowSpectators: m['allow_spectators'] as bool? ?? false,
// //         allowSpicy: m['allow_spicy'] as bool? ?? false,
// //         requiresApproval: m['requires_approval'] as bool? ?? false,
// //       );

// //   @override
// //   List<Object?> get props => [
// //     turnTimerSeconds,
// //     allowSkip,
// //     maxRounds,
// //     chatEnabled,
// //     allowSpectators,
// //     allowSpicy,
// //     requiresApproval,
// //   ];
// // }

// // // ── ModerationAction ──────────────────────────────────────────────────────────

// // enum ModerationActionType {
// //   kick,
// //   mute,
// //   unmute,
// //   ban,
// //   unban,
// //   transferOwnership,
// //   pauseGame,
// //   resumeGame,
// // }

// // class ModerationAction {
// //   const ModerationAction({
// //     required this.type,
// //     required this.actorId,
// //     this.targetUserId,
// //     this.reason,
// //     this.durationSeconds,
// //     this.metadata = const {},
// //   });

// //   final ModerationActionType type;
// //   final String actorId;
// //   final String? targetUserId;
// //   final String? reason;
// //   final int? durationSeconds;
// //   final Map<String, dynamic> metadata;

// //   Map<String, dynamic> toMap() => {
// //     'type': type.name,
// //     'actor_id': actorId,
// //     'target_user_id': targetUserId,
// //     'reason': reason,
// //     'duration_seconds': durationSeconds,
// //     ...metadata,
// //   };

// //   static ModerationAction fromMap(Map<String, dynamic> m) => ModerationAction(
// //     type: ModerationActionType.values.firstWhere(
// //       (t) => t.name == m['type'],
// //       orElse: () => ModerationActionType.kick,
// //     ),
// //     actorId: m['actor_id'] as String? ?? '',
// //     targetUserId: m['target_user_id'] as String?,
// //     reason: m['reason'] as String?,
// //     durationSeconds: m['duration_seconds'] as int?,
// //   );
// // }

// import 'package:equatable/equatable.dart';
// import '../../games/engine/base_game_engine.dart';

// // ── Enums ─────────────────────────────────────────────────────────────────────

// enum RoomStatus {
//   waiting,
//   starting,
//   inGame,
//   paused,
//   ended,
//   closed;

//   static RoomStatus fromString(String s) => switch (s) {
//     'starting' => starting,
//     'in_game' => inGame,
//     'paused' => paused,
//     'ended' => ended,
//     'closed' => closed,
//     _ => waiting,
//   };

//   String toDbString() => switch (this) {
//     starting => 'starting',
//     inGame => 'in_game',
//     paused => 'paused',
//     ended => 'ended',
//     closed => 'closed',
//     waiting => 'waiting',
//   };
// }

// enum RoomVisibility {
//   public,
//   private;

//   static RoomVisibility fromString(String s) =>
//       s == 'private' ? private : public;
// }

// enum MemberRole { player, moderator, spectator }

// // ── RoomEntity ────────────────────────────────────────────────────────────────

// class RoomEntity extends Equatable {
//   const RoomEntity({
//     required this.id,
//     required this.ownerId,
//     required this.name,
//     required this.status,
//     required this.visibility,
//     required this.maxPlayers,
//     required this.currentPlayers,
//     this.inviteCode,
//     this.gameType,
//     this.packId,
//     this.language = 'en',
//     this.allowSpicy = false,
//     this.coverEmoji = '🎮',
//     this.lastActiveAt,
//     this.createdAt,
//   });

//   final String id;
//   final String ownerId;
//   final String name;
//   final RoomStatus status;
//   final RoomVisibility visibility;
//   final int maxPlayers;
//   final int currentPlayers;
//   final String? inviteCode;
//   final GameType? gameType;
//   final String? packId;
//   final String language;
//   final bool allowSpicy;
//   final String coverEmoji;
//   final DateTime? lastActiveAt;
//   final DateTime? createdAt;

//   bool get isFull => currentPlayers >= maxPlayers;
//   bool get isWaiting => status == RoomStatus.waiting;
//   bool get isInGame => status == RoomStatus.inGame;
//   bool get isPaused => status == RoomStatus.paused;
//   bool get isActive =>
//       status == RoomStatus.waiting || status == RoomStatus.inGame;
//   bool get canJoin => !isFull && isActive;
//   bool get isPrivate => visibility == RoomVisibility.private;

//   RoomEntity copyWith({
//     String? ownerId,
//     String? name,
//     RoomStatus? status,
//     int? currentPlayers,
//     GameType? gameType,
//     String? packId,
//     bool? allowSpicy,
//     DateTime? lastActiveAt,
//   }) => RoomEntity(
//     id: id,
//     ownerId: ownerId ?? this.ownerId,
//     name: name ?? this.name,
//     status: status ?? this.status,
//     visibility: visibility,
//     maxPlayers: maxPlayers,
//     currentPlayers: currentPlayers ?? this.currentPlayers,
//     inviteCode: inviteCode,
//     gameType: gameType ?? this.gameType,
//     packId: packId ?? this.packId,
//     language: language,
//     allowSpicy: allowSpicy ?? this.allowSpicy,
//     coverEmoji: coverEmoji,
//     lastActiveAt: lastActiveAt ?? this.lastActiveAt,
//     createdAt: createdAt,
//   );

//   @override
//   List<Object?> get props => [
//     id,
//     ownerId,
//     name,
//     status,
//     visibility,
//     maxPlayers,
//     currentPlayers,
//     inviteCode,
//     gameType,
//     packId,
//     language,
//     allowSpicy,
//   ];
// }

// // ── RoomMemberEntity ──────────────────────────────────────────────────────────

// class RoomMemberEntity extends Equatable {
//   const RoomMemberEntity({
//     required this.userId,
//     required this.displayName,
//     this.avatarUrl,
//     required this.seatOrder,
//     required this.isReady,
//     required this.isOwner,
//     required this.isModerator,
//     this.isSpectator = false,
//     this.isMuted = false,
//     this.isDisconnected = false,
//     this.joinedAt,
//   });

//   final String userId;
//   final String displayName;
//   final String? avatarUrl;
//   final int seatOrder;
//   final bool isReady;
//   final bool isOwner;
//   final bool isModerator;
//   final bool isSpectator;
//   final bool isMuted;
//   final bool isDisconnected;
//   final DateTime? joinedAt;

//   bool get canModerate => isOwner || isModerator;
//   bool get isActive => !isDisconnected;

//   String get displayRole {
//     if (isOwner) return 'Owner';
//     if (isModerator) return 'Mod';
//     if (isSpectator) return 'Spectator';
//     return '';
//   }

//   RoomMemberEntity copyWith({
//     bool? isReady,
//     bool? isOwner,
//     bool? isModerator,
//     bool? isSpectator,
//     bool? isMuted,
//     bool? isDisconnected,
//   }) => RoomMemberEntity(
//     userId: userId,
//     displayName: displayName,
//     avatarUrl: avatarUrl,
//     seatOrder: seatOrder,
//     isReady: isReady ?? this.isReady,
//     isOwner: isOwner ?? this.isOwner,
//     isModerator: isModerator ?? this.isModerator,
//     isSpectator: isSpectator ?? this.isSpectator,
//     isMuted: isMuted ?? this.isMuted,
//     isDisconnected: isDisconnected ?? this.isDisconnected,
//     joinedAt: joinedAt,
//   );

//   @override
//   List<Object?> get props => [
//     userId,
//     displayName,
//     seatOrder,
//     isReady,
//     isOwner,
//     isModerator,
//     isSpectator,
//     isMuted,
//     isDisconnected,
//   ];
// }

// // ── ChatMessageEntity ─────────────────────────────────────────────────────────

// enum ChatMessageType { user, system }

// class ChatMessageEntity extends Equatable {
//   const ChatMessageEntity({
//     required this.id,
//     required this.roomId,
//     required this.userId,
//     required this.displayName,
//     this.avatarUrl,
//     required this.content,
//     required this.createdAt,
//     this.isDeleted = false,
//     this.isOptimistic = false,
//     this.type = ChatMessageType.user,
//   });

//   final String id;
//   final String roomId;
//   final String userId;
//   final String displayName;
//   final String? avatarUrl;
//   final String content;
//   final DateTime createdAt;
//   final bool isDeleted;
//   final bool isOptimistic; // client-only: not yet confirmed by server
//   final ChatMessageType type;

//   bool get isSystem => type == ChatMessageType.system;

//   @override
//   List<Object?> get props => [id, roomId, userId, content, createdAt];
// }

// // ── RoomSettingsEntity ────────────────────────────────────────────────────────

// class RoomSettingsEntity extends Equatable {
//   const RoomSettingsEntity({
//     this.turnTimerSeconds = 60,
//     this.allowSkip = true,
//     this.maxRounds = 10,
//     this.chatEnabled = true,
//     this.allowSpectators = false,
//     this.allowSpicy = false,
//     this.requiresApproval = false,
//   });

//   final int turnTimerSeconds;
//   final bool allowSkip;
//   final int maxRounds;
//   final bool chatEnabled;
//   final bool allowSpectators;
//   final bool allowSpicy;
//   final bool requiresApproval;

//   RoomSettingsEntity copyWith({
//     int? turnTimerSeconds,
//     bool? allowSkip,
//     int? maxRounds,
//     bool? chatEnabled,
//     bool? allowSpectators,
//     bool? allowSpicy,
//     bool? requiresApproval,
//   }) => RoomSettingsEntity(
//     turnTimerSeconds: turnTimerSeconds ?? this.turnTimerSeconds,
//     allowSkip: allowSkip ?? this.allowSkip,
//     maxRounds: maxRounds ?? this.maxRounds,
//     chatEnabled: chatEnabled ?? this.chatEnabled,
//     allowSpectators: allowSpectators ?? this.allowSpectators,
//     allowSpicy: allowSpicy ?? this.allowSpicy,
//     requiresApproval: requiresApproval ?? this.requiresApproval,
//   );

//   Map<String, dynamic> toMap() => {
//     'turn_timer_secs': turnTimerSeconds,
//     'allow_skip': allowSkip,
//     'max_rounds': maxRounds,
//     'chat_enabled': chatEnabled,
//     'allow_spectators': allowSpectators,
//     'allow_spicy': allowSpicy,
//     'requires_approval': requiresApproval,
//   };

//   static RoomSettingsEntity fromMap(Map<String, dynamic> m) =>
//       RoomSettingsEntity(
//         turnTimerSeconds: m['turn_timer_secs'] as int? ?? 60,
//         allowSkip: m['allow_skip'] as bool? ?? true,
//         maxRounds: m['max_rounds'] as int? ?? 10,
//         chatEnabled: m['chat_enabled'] as bool? ?? true,
//         allowSpectators: m['allow_spectators'] as bool? ?? false,
//         allowSpicy: m['allow_spicy'] as bool? ?? false,
//         requiresApproval: m['requires_approval'] as bool? ?? false,
//       );

//   @override
//   List<Object?> get props => [
//     turnTimerSeconds,
//     allowSkip,
//     maxRounds,
//     chatEnabled,
//     allowSpectators,
//     allowSpicy,
//     requiresApproval,
//   ];
// }

// // ── ModerationAction ──────────────────────────────────────────────────────────

// enum ModerationActionType {
//   kick,
//   mute,
//   unmute,
//   ban,
//   unban,
//   transferOwnership,
//   pauseGame,
//   resumeGame,
// }

// class ModerationAction {
//   const ModerationAction({
//     required this.type,
//     required this.actorId,
//     this.targetUserId,
//     this.reason,
//     this.durationSeconds,
//     this.metadata = const {},
//   });

//   final ModerationActionType type;
//   final String actorId;
//   final String? targetUserId;
//   final String? reason;
//   final int? durationSeconds;
//   final Map<String, dynamic> metadata;

//   Map<String, dynamic> toMap() => {
//     'type': type.name,
//     'actor_id': actorId,
//     'target_user_id': targetUserId,
//     'reason': reason,
//     'duration_seconds': durationSeconds,
//     ...metadata,
//   };

//   static ModerationAction fromMap(Map<String, dynamic> m) => ModerationAction(
//     type: ModerationActionType.values.firstWhere(
//       (t) => t.name == m['type'],
//       orElse: () => ModerationActionType.kick,
//     ),
//     actorId: m['actor_id'] as String? ?? '',
//     targetUserId: m['target_user_id'] as String?,
//     reason: m['reason'] as String?,
//     durationSeconds: m['duration_seconds'] as int?,
//   );
// }

import 'package:equatable/equatable.dart';
import '../../games/engine/base_game_engine.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum RoomStatus {
  waiting,
  starting,
  inGame,
  paused,
  ended,
  closed;

  static RoomStatus fromString(String s) => switch (s) {
    'starting' => starting,
    'in_game' => inGame,
    'paused' => paused,
    'ended' => ended,
    'closed' => closed,
    _ => waiting,
  };

  String toDbString() => switch (this) {
    starting => 'starting',
    inGame => 'in_game',
    paused => 'paused',
    ended => 'ended',
    closed => 'closed',
    waiting => 'waiting',
  };
}

enum RoomVisibility {
  public,
  private;

  static RoomVisibility fromString(String s) =>
      s == 'private' ? private : public;
}

enum MemberRole { player, moderator, spectator }

// ── RoomEntity ────────────────────────────────────────────────────────────────

class RoomEntity extends Equatable {
  const RoomEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.status,
    required this.visibility,
    required this.maxPlayers,
    required this.currentPlayers,
    this.inviteCode,
    this.gameType,
    this.packId,
    this.language = 'en',
    this.allowSpicy = false,
    this.coverEmoji = '🎮',
    this.lastActiveAt,
    this.createdAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final RoomStatus status;
  final RoomVisibility visibility;
  final int maxPlayers;
  final int currentPlayers;
  final String? inviteCode;
  final GameType? gameType;
  final String? packId;
  final String language;
  final bool allowSpicy;
  final String coverEmoji;
  final DateTime? lastActiveAt;
  final DateTime? createdAt;

  bool get isFull => currentPlayers >= maxPlayers;
  bool get isWaiting => status == RoomStatus.waiting;
  bool get isInGame => status == RoomStatus.inGame;
  bool get isPaused => status == RoomStatus.paused;
  bool get isActive =>
      status == RoomStatus.waiting || status == RoomStatus.inGame;
  bool get canJoin => !isFull && isActive;
  bool get isPrivate => visibility == RoomVisibility.private;

  RoomEntity copyWith({
    String? ownerId,
    String? name,
    RoomStatus? status,
    int? currentPlayers,
    GameType? gameType,
    String? packId,
    String? language,
    bool? allowSpicy,
    DateTime? lastActiveAt,
  }) => RoomEntity(
    id: id,
    ownerId: ownerId ?? this.ownerId,
    name: name ?? this.name,
    status: status ?? this.status,
    visibility: visibility,
    maxPlayers: maxPlayers,
    currentPlayers: currentPlayers ?? this.currentPlayers,
    inviteCode: inviteCode,
    gameType: gameType ?? this.gameType,
    packId: packId ?? this.packId,
    language: language ?? this.language,
    allowSpicy: allowSpicy ?? this.allowSpicy,
    coverEmoji: coverEmoji,
    lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [
    id,
    ownerId,
    name,
    status,
    visibility,
    maxPlayers,
    currentPlayers,
    inviteCode,
    gameType,
    packId,
    language,
    allowSpicy,
  ];
}

// ── RoomMemberEntity ──────────────────────────────────────────────────────────

class RoomMemberEntity extends Equatable {
  const RoomMemberEntity({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.seatOrder,
    required this.isReady,
    required this.isOwner,
    required this.isModerator,
    this.isSpectator = false,
    this.isMuted = false,
    this.isDisconnected = false,
    this.joinedAt,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int seatOrder;
  final bool isReady;
  final bool isOwner;
  final bool isModerator;
  final bool isSpectator;
  final bool isMuted;
  final bool isDisconnected;
  final DateTime? joinedAt;

  bool get canModerate => isOwner || isModerator;
  bool get isActive => !isDisconnected;

  String get displayRole {
    if (isOwner) return 'Owner';
    if (isModerator) return 'Mod';
    if (isSpectator) return 'Spectator';
    return '';
  }

  RoomMemberEntity copyWith({
    bool? isReady,
    bool? isOwner,
    bool? isModerator,
    bool? isSpectator,
    bool? isMuted,
    bool? isDisconnected,
  }) => RoomMemberEntity(
    userId: userId,
    displayName: displayName,
    avatarUrl: avatarUrl,
    seatOrder: seatOrder,
    isReady: isReady ?? this.isReady,
    isOwner: isOwner ?? this.isOwner,
    isModerator: isModerator ?? this.isModerator,
    isSpectator: isSpectator ?? this.isSpectator,
    isMuted: isMuted ?? this.isMuted,
    isDisconnected: isDisconnected ?? this.isDisconnected,
    joinedAt: joinedAt,
  );

  @override
  List<Object?> get props => [
    userId,
    displayName,
    seatOrder,
    isReady,
    isOwner,
    isModerator,
    isSpectator,
    isMuted,
    isDisconnected,
  ];
}

// ── ChatMessageEntity ─────────────────────────────────────────────────────────

enum ChatMessageType { user, system }

class ChatMessageEntity extends Equatable {
  const ChatMessageEntity({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.content,
    required this.createdAt,
    this.isDeleted = false,
    this.isOptimistic = false,
    this.type = ChatMessageType.user,
  });

  final String id;
  final String roomId;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String content;
  final DateTime createdAt;
  final bool isDeleted;
  final bool isOptimistic; // client-only: not yet confirmed by server
  final ChatMessageType type;

  bool get isSystem => type == ChatMessageType.system;

  @override
  List<Object?> get props => [id, roomId, userId, content, createdAt];
}

// ── RoomSettingsEntity ────────────────────────────────────────────────────────

class RoomSettingsEntity extends Equatable {
  const RoomSettingsEntity({
    this.turnTimerSeconds = 60,
    this.allowSkip = true,
    this.maxRounds = 10,
    this.chatEnabled = true,
    this.allowSpectators = false,
    this.allowSpicy = false,
    this.requiresApproval = false,
  });

  final int turnTimerSeconds;
  final bool allowSkip;
  final int maxRounds;
  final bool chatEnabled;
  final bool allowSpectators;
  final bool allowSpicy;
  final bool requiresApproval;

  RoomSettingsEntity copyWith({
    int? turnTimerSeconds,
    bool? allowSkip,
    int? maxRounds,
    bool? chatEnabled,
    bool? allowSpectators,
    bool? allowSpicy,
    bool? requiresApproval,
  }) => RoomSettingsEntity(
    turnTimerSeconds: turnTimerSeconds ?? this.turnTimerSeconds,
    allowSkip: allowSkip ?? this.allowSkip,
    maxRounds: maxRounds ?? this.maxRounds,
    chatEnabled: chatEnabled ?? this.chatEnabled,
    allowSpectators: allowSpectators ?? this.allowSpectators,
    allowSpicy: allowSpicy ?? this.allowSpicy,
    requiresApproval: requiresApproval ?? this.requiresApproval,
  );

  Map<String, dynamic> toMap() => {
    'turn_timer_secs': turnTimerSeconds,
    'allow_skip': allowSkip,
    'max_rounds': maxRounds,
    'chat_enabled': chatEnabled,
    'allow_spectators': allowSpectators,
    'allow_spicy': allowSpicy,
    'requires_approval': requiresApproval,
  };

  static RoomSettingsEntity fromMap(Map<String, dynamic> m) =>
      RoomSettingsEntity(
        turnTimerSeconds: m['turn_timer_secs'] as int? ?? 60,
        allowSkip: m['allow_skip'] as bool? ?? true,
        maxRounds: m['max_rounds'] as int? ?? 10,
        chatEnabled: m['chat_enabled'] as bool? ?? true,
        allowSpectators: m['allow_spectators'] as bool? ?? false,
        allowSpicy: m['allow_spicy'] as bool? ?? false,
        requiresApproval: m['requires_approval'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
    turnTimerSeconds,
    allowSkip,
    maxRounds,
    chatEnabled,
    allowSpectators,
    allowSpicy,
    requiresApproval,
  ];
}

// ── ModerationAction ──────────────────────────────────────────────────────────

enum ModerationActionType {
  kick,
  mute,
  unmute,
  ban,
  unban,
  transferOwnership,
  pauseGame,
  resumeGame,
}

class ModerationAction {
  const ModerationAction({
    required this.type,
    required this.actorId,
    this.targetUserId,
    this.reason,
    this.durationSeconds,
    this.metadata = const {},
  });

  final ModerationActionType type;
  final String actorId;
  final String? targetUserId;
  final String? reason;
  final int? durationSeconds;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'actor_id': actorId,
    'target_user_id': targetUserId,
    'reason': reason,
    'duration_seconds': durationSeconds,
    ...metadata,
  };

  static ModerationAction fromMap(Map<String, dynamic> m) => ModerationAction(
    type: ModerationActionType.values.firstWhere(
      (t) => t.name == m['type'],
      orElse: () => ModerationActionType.kick,
    ),
    actorId: m['actor_id'] as String? ?? '',
    targetUserId: m['target_user_id'] as String?,
    reason: m['reason'] as String?,
    durationSeconds: m['duration_seconds'] as int?,
  );
}
