// // // // // // // // // import 'package:equatable/equatable.dart';
// // // // // // // // // import '../../games/engine/base_game_engine.dart';

// // // // // // // // // // ── Enums ─────────────────────────────────────────────────────────────────────

// // // // // // // // // enum RoomStatus {
// // // // // // // // //   waiting,
// // // // // // // // //   starting,
// // // // // // // // //   inGame,
// // // // // // // // //   paused,
// // // // // // // // //   ended,
// // // // // // // // //   closed;

// // // // // // // // //   static RoomStatus fromString(String s) => switch (s) {
// // // // // // // // //     'starting' => starting,
// // // // // // // // //     'in_game' => inGame,
// // // // // // // // //     'paused' => paused,
// // // // // // // // //     'ended' => ended,
// // // // // // // // //     'closed' => closed,
// // // // // // // // //     _ => waiting,
// // // // // // // // //   };

// // // // // // // // //   String toDbString() => switch (this) {
// // // // // // // // //     starting => 'starting',
// // // // // // // // //     inGame => 'in_game',
// // // // // // // // //     paused => 'paused',
// // // // // // // // //     ended => 'ended',
// // // // // // // // //     closed => 'closed',
// // // // // // // // //     waiting => 'waiting',
// // // // // // // // //   };
// // // // // // // // // }

// // // // // // // // // enum RoomVisibility {
// // // // // // // // //   public,
// // // // // // // // //   private;

// // // // // // // // //   static RoomVisibility fromString(String s) =>
// // // // // // // // //       s == 'private' ? private : public;
// // // // // // // // // }

// // // // // // // // // enum MemberRole { player, moderator, spectator }

// // // // // // // // // // ── RoomEntity ────────────────────────────────────────────────────────────────

// // // // // // // // // class RoomEntity extends Equatable {
// // // // // // // // //   const RoomEntity({
// // // // // // // // //     required this.id,
// // // // // // // // //     required this.ownerId,
// // // // // // // // //     required this.name,
// // // // // // // // //     required this.status,
// // // // // // // // //     required this.visibility,
// // // // // // // // //     required this.maxPlayers,
// // // // // // // // //     required this.currentPlayers,
// // // // // // // // //     this.inviteCode,
// // // // // // // // //     this.gameType,
// // // // // // // // //     this.packId,
// // // // // // // // //     this.language = 'en',
// // // // // // // // //     this.allowSpicy = false,
// // // // // // // // //     this.coverEmoji = '🎮',
// // // // // // // // //     this.lastActiveAt,
// // // // // // // // //     this.createdAt,
// // // // // // // // //   });

// // // // // // // // //   final String id;
// // // // // // // // //   final String ownerId;
// // // // // // // // //   final String name;
// // // // // // // // //   final RoomStatus status;
// // // // // // // // //   final RoomVisibility visibility;
// // // // // // // // //   final int maxPlayers;
// // // // // // // // //   final int currentPlayers;
// // // // // // // // //   final String? inviteCode;
// // // // // // // // //   final GameType? gameType;
// // // // // // // // //   final String? packId;
// // // // // // // // //   final String language;
// // // // // // // // //   final bool allowSpicy;
// // // // // // // // //   final String coverEmoji;
// // // // // // // // //   final DateTime? lastActiveAt;
// // // // // // // // //   final DateTime? createdAt;

// // // // // // // // //   bool get isFull => currentPlayers >= maxPlayers;
// // // // // // // // //   bool get isWaiting => status == RoomStatus.waiting;
// // // // // // // // //   bool get isInGame => status == RoomStatus.inGame;
// // // // // // // // //   bool get isPaused => status == RoomStatus.paused;
// // // // // // // // //   bool get isActive =>
// // // // // // // // //       status == RoomStatus.waiting || status == RoomStatus.inGame;
// // // // // // // // //   bool get canJoin => !isFull && isActive;
// // // // // // // // //   bool get isPrivate => visibility == RoomVisibility.private;

// // // // // // // // //   RoomEntity copyWith({
// // // // // // // // //     String? ownerId,
// // // // // // // // //     String? name,
// // // // // // // // //     RoomStatus? status,
// // // // // // // // //     int? currentPlayers,
// // // // // // // // //     GameType? gameType,
// // // // // // // // //     String? packId,
// // // // // // // // //     bool? allowSpicy,
// // // // // // // // //     DateTime? lastActiveAt,
// // // // // // // // //   }) => RoomEntity(
// // // // // // // // //     id: id,
// // // // // // // // //     ownerId: ownerId ?? this.ownerId,
// // // // // // // // //     name: name ?? this.name,
// // // // // // // // //     status: status ?? this.status,
// // // // // // // // //     visibility: visibility,
// // // // // // // // //     maxPlayers: maxPlayers,
// // // // // // // // //     currentPlayers: currentPlayers ?? this.currentPlayers,
// // // // // // // // //     inviteCode: inviteCode,
// // // // // // // // //     gameType: gameType ?? this.gameType,
// // // // // // // // //     packId: packId ?? this.packId,
// // // // // // // // //     language: language,
// // // // // // // // //     allowSpicy: allowSpicy ?? this.allowSpicy,
// // // // // // // // //     coverEmoji: coverEmoji,
// // // // // // // // //     lastActiveAt: lastActiveAt ?? this.lastActiveAt,
// // // // // // // // //     createdAt: createdAt,
// // // // // // // // //   );

// // // // // // // // //   @override
// // // // // // // // //   List<Object?> get props => [
// // // // // // // // //     id,
// // // // // // // // //     ownerId,
// // // // // // // // //     name,
// // // // // // // // //     status,
// // // // // // // // //     visibility,
// // // // // // // // //     maxPlayers,
// // // // // // // // //     currentPlayers,
// // // // // // // // //     inviteCode,
// // // // // // // // //     gameType,
// // // // // // // // //     packId,
// // // // // // // // //     language,
// // // // // // // // //     allowSpicy,
// // // // // // // // //   ];
// // // // // // // // // }

// // // // // // // // // // ── RoomMemberEntity ──────────────────────────────────────────────────────────

// // // // // // // // // class RoomMemberEntity extends Equatable {
// // // // // // // // //   const RoomMemberEntity({
// // // // // // // // //     required this.userId,
// // // // // // // // //     required this.displayName,
// // // // // // // // //     this.avatarUrl,
// // // // // // // // //     required this.seatOrder,
// // // // // // // // //     required this.isReady,
// // // // // // // // //     required this.isOwner,
// // // // // // // // //     required this.isModerator,
// // // // // // // // //     this.isMuted = false,
// // // // // // // // //     this.isDisconnected = false,
// // // // // // // // //     this.joinedAt,
// // // // // // // // //   });

// // // // // // // // //   final String userId;
// // // // // // // // //   final String displayName;
// // // // // // // // //   final String? avatarUrl;
// // // // // // // // //   final int seatOrder;
// // // // // // // // //   final bool isReady;
// // // // // // // // //   final bool isOwner;
// // // // // // // // //   final bool isModerator;
// // // // // // // // //   final bool isMuted;
// // // // // // // // //   final bool isDisconnected;
// // // // // // // // //   final DateTime? joinedAt;

// // // // // // // // //   bool get canModerate => isOwner || isModerator;
// // // // // // // // //   bool get isActive => !isDisconnected;

// // // // // // // // //   String get displayRole {
// // // // // // // // //     if (isOwner) return 'Owner';
// // // // // // // // //     if (isModerator) return 'Mod';
// // // // // // // // //     return '';
// // // // // // // // //   }

// // // // // // // // //   RoomMemberEntity copyWith({
// // // // // // // // //     bool? isReady,
// // // // // // // // //     bool? isOwner,
// // // // // // // // //     bool? isModerator,
// // // // // // // // //     bool? isMuted,
// // // // // // // // //     bool? isDisconnected,
// // // // // // // // //   }) => RoomMemberEntity(
// // // // // // // // //     userId: userId,
// // // // // // // // //     displayName: displayName,
// // // // // // // // //     avatarUrl: avatarUrl,
// // // // // // // // //     seatOrder: seatOrder,
// // // // // // // // //     isReady: isReady ?? this.isReady,
// // // // // // // // //     isOwner: isOwner ?? this.isOwner,
// // // // // // // // //     isModerator: isModerator ?? this.isModerator,
// // // // // // // // //     isMuted: isMuted ?? this.isMuted,
// // // // // // // // //     isDisconnected: isDisconnected ?? this.isDisconnected,
// // // // // // // // //     joinedAt: joinedAt,
// // // // // // // // //   );

// // // // // // // // //   @override
// // // // // // // // //   List<Object?> get props => [
// // // // // // // // //     userId,
// // // // // // // // //     displayName,
// // // // // // // // //     seatOrder,
// // // // // // // // //     isReady,
// // // // // // // // //     isOwner,
// // // // // // // // //     isModerator,
// // // // // // // // //     isMuted,
// // // // // // // // //     isDisconnected,
// // // // // // // // //   ];
// // // // // // // // // }

// // // // // // // // // // ── ChatMessageEntity ─────────────────────────────────────────────────────────

// // // // // // // // // enum ChatMessageType { user, system }

// // // // // // // // // class ChatMessageEntity extends Equatable {
// // // // // // // // //   const ChatMessageEntity({
// // // // // // // // //     required this.id,
// // // // // // // // //     required this.roomId,
// // // // // // // // //     required this.userId,
// // // // // // // // //     required this.displayName,
// // // // // // // // //     this.avatarUrl,
// // // // // // // // //     required this.content,
// // // // // // // // //     required this.createdAt,
// // // // // // // // //     this.isDeleted = false,
// // // // // // // // //     this.isOptimistic = false,
// // // // // // // // //     this.type = ChatMessageType.user,
// // // // // // // // //   });

// // // // // // // // //   final String id;
// // // // // // // // //   final String roomId;
// // // // // // // // //   final String userId;
// // // // // // // // //   final String displayName;
// // // // // // // // //   final String? avatarUrl;
// // // // // // // // //   final String content;
// // // // // // // // //   final DateTime createdAt;
// // // // // // // // //   final bool isDeleted;
// // // // // // // // //   final bool isOptimistic; // client-only: not yet confirmed by server
// // // // // // // // //   final ChatMessageType type;

// // // // // // // // //   bool get isSystem => type == ChatMessageType.system;

// // // // // // // // //   @override
// // // // // // // // //   List<Object?> get props => [id, roomId, userId, content, createdAt];
// // // // // // // // // }

// // // // // // // // // // ── RoomSettingsEntity ────────────────────────────────────────────────────────

// // // // // // // // // class RoomSettingsEntity extends Equatable {
// // // // // // // // //   const RoomSettingsEntity({
// // // // // // // // //     this.turnTimerSeconds = 60,
// // // // // // // // //     this.allowSkip = true,
// // // // // // // // //     this.maxRounds = 10,
// // // // // // // // //     this.chatEnabled = true,
// // // // // // // // //     this.allowSpectators = false,
// // // // // // // // //     this.allowSpicy = false,
// // // // // // // // //     this.requiresApproval = false,
// // // // // // // // //   });

// // // // // // // // //   final int turnTimerSeconds;
// // // // // // // // //   final bool allowSkip;
// // // // // // // // //   final int maxRounds;
// // // // // // // // //   final bool chatEnabled;
// // // // // // // // //   final bool allowSpectators;
// // // // // // // // //   final bool allowSpicy;
// // // // // // // // //   final bool requiresApproval;

// // // // // // // // //   RoomSettingsEntity copyWith({
// // // // // // // // //     int? turnTimerSeconds,
// // // // // // // // //     bool? allowSkip,
// // // // // // // // //     int? maxRounds,
// // // // // // // // //     bool? chatEnabled,
// // // // // // // // //     bool? allowSpectators,
// // // // // // // // //     bool? allowSpicy,
// // // // // // // // //     bool? requiresApproval,
// // // // // // // // //   }) => RoomSettingsEntity(
// // // // // // // // //     turnTimerSeconds: turnTimerSeconds ?? this.turnTimerSeconds,
// // // // // // // // //     allowSkip: allowSkip ?? this.allowSkip,
// // // // // // // // //     maxRounds: maxRounds ?? this.maxRounds,
// // // // // // // // //     chatEnabled: chatEnabled ?? this.chatEnabled,
// // // // // // // // //     allowSpectators: allowSpectators ?? this.allowSpectators,
// // // // // // // // //     allowSpicy: allowSpicy ?? this.allowSpicy,
// // // // // // // // //     requiresApproval: requiresApproval ?? this.requiresApproval,
// // // // // // // // //   );

// // // // // // // // //   Map<String, dynamic> toMap() => {
// // // // // // // // //     'turn_timer_secs': turnTimerSeconds,
// // // // // // // // //     'allow_skip': allowSkip,
// // // // // // // // //     'max_rounds': maxRounds,
// // // // // // // // //     'chat_enabled': chatEnabled,
// // // // // // // // //     'allow_spectators': allowSpectators,
// // // // // // // // //     'allow_spicy': allowSpicy,
// // // // // // // // //     'requires_approval': requiresApproval,
// // // // // // // // //   };

// // // // // // // // //   static RoomSettingsEntity fromMap(Map<String, dynamic> m) =>
// // // // // // // // //       RoomSettingsEntity(
// // // // // // // // //         turnTimerSeconds: m['turn_timer_secs'] as int? ?? 60,
// // // // // // // // //         allowSkip: m['allow_skip'] as bool? ?? true,
// // // // // // // // //         maxRounds: m['max_rounds'] as int? ?? 10,
// // // // // // // // //         chatEnabled: m['chat_enabled'] as bool? ?? true,
// // // // // // // // //         allowSpectators: m['allow_spectators'] as bool? ?? false,
// // // // // // // // //         allowSpicy: m['allow_spicy'] as bool? ?? false,
// // // // // // // // //         requiresApproval: m['requires_approval'] as bool? ?? false,
// // // // // // // // //       );

// // // // // // // // //   @override
// // // // // // // // //   List<Object?> get props => [
// // // // // // // // //     turnTimerSeconds,
// // // // // // // // //     allowSkip,
// // // // // // // // //     maxRounds,
// // // // // // // // //     chatEnabled,
// // // // // // // // //     allowSpectators,
// // // // // // // // //     allowSpicy,
// // // // // // // // //     requiresApproval,
// // // // // // // // //   ];
// // // // // // // // // }

// // // // // // // // // // ── ModerationAction ──────────────────────────────────────────────────────────

// // // // // // // // // enum ModerationActionType {
// // // // // // // // //   kick,
// // // // // // // // //   mute,
// // // // // // // // //   unmute,
// // // // // // // // //   ban,
// // // // // // // // //   unban,
// // // // // // // // //   transferOwnership,
// // // // // // // // //   pauseGame,
// // // // // // // // //   resumeGame,
// // // // // // // // // }

// // // // // // // // // class ModerationAction {
// // // // // // // // //   const ModerationAction({
// // // // // // // // //     required this.type,
// // // // // // // // //     required this.actorId,
// // // // // // // // //     this.targetUserId,
// // // // // // // // //     this.reason,
// // // // // // // // //     this.durationSeconds,
// // // // // // // // //     this.metadata = const {},
// // // // // // // // //   });

// // // // // // // // //   final ModerationActionType type;
// // // // // // // // //   final String actorId;
// // // // // // // // //   final String? targetUserId;
// // // // // // // // //   final String? reason;
// // // // // // // // //   final int? durationSeconds;
// // // // // // // // //   final Map<String, dynamic> metadata;

// // // // // // // // //   Map<String, dynamic> toMap() => {
// // // // // // // // //     'type': type.name,
// // // // // // // // //     'actor_id': actorId,
// // // // // // // // //     'target_user_id': targetUserId,
// // // // // // // // //     'reason': reason,
// // // // // // // // //     'duration_seconds': durationSeconds,
// // // // // // // // //     ...metadata,
// // // // // // // // //   };

// // // // // // // // //   static ModerationAction fromMap(Map<String, dynamic> m) => ModerationAction(
// // // // // // // // //     type: ModerationActionType.values.firstWhere(
// // // // // // // // //       (t) => t.name == m['type'],
// // // // // // // // //       orElse: () => ModerationActionType.kick,
// // // // // // // // //     ),
// // // // // // // // //     actorId: m['actor_id'] as String? ?? '',
// // // // // // // // //     targetUserId: m['target_user_id'] as String?,
// // // // // // // // //     reason: m['reason'] as String?,
// // // // // // // // //     durationSeconds: m['duration_seconds'] as int?,
// // // // // // // // //   );
// // // // // // // // // }

// // // // // // // // import 'package:equatable/equatable.dart';
// // // // // // // // import '../../games/engine/base_game_engine.dart';

// // // // // // // // // ── Enums ─────────────────────────────────────────────────────────────────────

// // // // // // // // enum RoomStatus {
// // // // // // // //   waiting,
// // // // // // // //   starting,
// // // // // // // //   inGame,
// // // // // // // //   paused,
// // // // // // // //   ended,
// // // // // // // //   closed;

// // // // // // // //   static RoomStatus fromString(String s) => switch (s) {
// // // // // // // //     'starting' => starting,
// // // // // // // //     'in_game' => inGame,
// // // // // // // //     'paused' => paused,
// // // // // // // //     'ended' => ended,
// // // // // // // //     'closed' => closed,
// // // // // // // //     _ => waiting,
// // // // // // // //   };

// // // // // // // //   String toDbString() => switch (this) {
// // // // // // // //     starting => 'starting',
// // // // // // // //     inGame => 'in_game',
// // // // // // // //     paused => 'paused',
// // // // // // // //     ended => 'ended',
// // // // // // // //     closed => 'closed',
// // // // // // // //     waiting => 'waiting',
// // // // // // // //   };
// // // // // // // // }

// // // // // // // // enum RoomVisibility {
// // // // // // // //   public,
// // // // // // // //   private;

// // // // // // // //   static RoomVisibility fromString(String s) =>
// // // // // // // //       s == 'private' ? private : public;
// // // // // // // // }

// // // // // // // // enum MemberRole { player, moderator, spectator }

// // // // // // // // // ── RoomEntity ────────────────────────────────────────────────────────────────

// // // // // // // // class RoomEntity extends Equatable {
// // // // // // // //   const RoomEntity({
// // // // // // // //     required this.id,
// // // // // // // //     required this.ownerId,
// // // // // // // //     required this.name,
// // // // // // // //     required this.status,
// // // // // // // //     required this.visibility,
// // // // // // // //     required this.maxPlayers,
// // // // // // // //     required this.currentPlayers,
// // // // // // // //     this.inviteCode,
// // // // // // // //     this.gameType,
// // // // // // // //     this.packId,
// // // // // // // //     this.language = 'en',
// // // // // // // //     this.allowSpicy = false,
// // // // // // // //     this.coverEmoji = '🎮',
// // // // // // // //     this.lastActiveAt,
// // // // // // // //     this.createdAt,
// // // // // // // //   });

// // // // // // // //   final String id;
// // // // // // // //   final String ownerId;
// // // // // // // //   final String name;
// // // // // // // //   final RoomStatus status;
// // // // // // // //   final RoomVisibility visibility;
// // // // // // // //   final int maxPlayers;
// // // // // // // //   final int currentPlayers;
// // // // // // // //   final String? inviteCode;
// // // // // // // //   final GameType? gameType;
// // // // // // // //   final String? packId;
// // // // // // // //   final String language;
// // // // // // // //   final bool allowSpicy;
// // // // // // // //   final String coverEmoji;
// // // // // // // //   final DateTime? lastActiveAt;
// // // // // // // //   final DateTime? createdAt;

// // // // // // // //   bool get isFull => currentPlayers >= maxPlayers;
// // // // // // // //   bool get isWaiting => status == RoomStatus.waiting;
// // // // // // // //   bool get isInGame => status == RoomStatus.inGame;
// // // // // // // //   bool get isPaused => status == RoomStatus.paused;
// // // // // // // //   bool get isActive =>
// // // // // // // //       status == RoomStatus.waiting || status == RoomStatus.inGame;
// // // // // // // //   bool get canJoin => !isFull && isActive;
// // // // // // // //   bool get isPrivate => visibility == RoomVisibility.private;

// // // // // // // //   RoomEntity copyWith({
// // // // // // // //     String? ownerId,
// // // // // // // //     String? name,
// // // // // // // //     RoomStatus? status,
// // // // // // // //     int? currentPlayers,
// // // // // // // //     GameType? gameType,
// // // // // // // //     String? packId,
// // // // // // // //     bool? allowSpicy,
// // // // // // // //     DateTime? lastActiveAt,
// // // // // // // //   }) => RoomEntity(
// // // // // // // //     id: id,
// // // // // // // //     ownerId: ownerId ?? this.ownerId,
// // // // // // // //     name: name ?? this.name,
// // // // // // // //     status: status ?? this.status,
// // // // // // // //     visibility: visibility,
// // // // // // // //     maxPlayers: maxPlayers,
// // // // // // // //     currentPlayers: currentPlayers ?? this.currentPlayers,
// // // // // // // //     inviteCode: inviteCode,
// // // // // // // //     gameType: gameType ?? this.gameType,
// // // // // // // //     packId: packId ?? this.packId,
// // // // // // // //     language: language,
// // // // // // // //     allowSpicy: allowSpicy ?? this.allowSpicy,
// // // // // // // //     coverEmoji: coverEmoji,
// // // // // // // //     lastActiveAt: lastActiveAt ?? this.lastActiveAt,
// // // // // // // //     createdAt: createdAt,
// // // // // // // //   );

// // // // // // // //   @override
// // // // // // // //   List<Object?> get props => [
// // // // // // // //     id,
// // // // // // // //     ownerId,
// // // // // // // //     name,
// // // // // // // //     status,
// // // // // // // //     visibility,
// // // // // // // //     maxPlayers,
// // // // // // // //     currentPlayers,
// // // // // // // //     inviteCode,
// // // // // // // //     gameType,
// // // // // // // //     packId,
// // // // // // // //     language,
// // // // // // // //     allowSpicy,
// // // // // // // //   ];
// // // // // // // // }

// // // // // // // // // ── RoomMemberEntity ──────────────────────────────────────────────────────────

// // // // // // // // class RoomMemberEntity extends Equatable {
// // // // // // // //   const RoomMemberEntity({
// // // // // // // //     required this.userId,
// // // // // // // //     required this.displayName,
// // // // // // // //     this.avatarUrl,
// // // // // // // //     required this.seatOrder,
// // // // // // // //     required this.isReady,
// // // // // // // //     required this.isOwner,
// // // // // // // //     required this.isModerator,
// // // // // // // //     this.isSpectator = false,
// // // // // // // //     this.isMuted = false,
// // // // // // // //     this.isDisconnected = false,
// // // // // // // //     this.joinedAt,
// // // // // // // //   });

// // // // // // // //   final String userId;
// // // // // // // //   final String displayName;
// // // // // // // //   final String? avatarUrl;
// // // // // // // //   final int seatOrder;
// // // // // // // //   final bool isReady;
// // // // // // // //   final bool isOwner;
// // // // // // // //   final bool isModerator;
// // // // // // // //   final bool isSpectator;
// // // // // // // //   final bool isMuted;
// // // // // // // //   final bool isDisconnected;
// // // // // // // //   final DateTime? joinedAt;

// // // // // // // //   bool get canModerate => isOwner || isModerator;
// // // // // // // //   bool get isActive => !isDisconnected;

// // // // // // // //   String get displayRole {
// // // // // // // //     if (isOwner) return 'Owner';
// // // // // // // //     if (isModerator) return 'Mod';
// // // // // // // //     if (isSpectator) return 'Spectator';
// // // // // // // //     return '';
// // // // // // // //   }

// // // // // // // //   RoomMemberEntity copyWith({
// // // // // // // //     bool? isReady,
// // // // // // // //     bool? isOwner,
// // // // // // // //     bool? isModerator,
// // // // // // // //     bool? isSpectator,
// // // // // // // //     bool? isMuted,
// // // // // // // //     bool? isDisconnected,
// // // // // // // //   }) => RoomMemberEntity(
// // // // // // // //     userId: userId,
// // // // // // // //     displayName: displayName,
// // // // // // // //     avatarUrl: avatarUrl,
// // // // // // // //     seatOrder: seatOrder,
// // // // // // // //     isReady: isReady ?? this.isReady,
// // // // // // // //     isOwner: isOwner ?? this.isOwner,
// // // // // // // //     isModerator: isModerator ?? this.isModerator,
// // // // // // // //     isSpectator: isSpectator ?? this.isSpectator,
// // // // // // // //     isMuted: isMuted ?? this.isMuted,
// // // // // // // //     isDisconnected: isDisconnected ?? this.isDisconnected,
// // // // // // // //     joinedAt: joinedAt,
// // // // // // // //   );

// // // // // // // //   @override
// // // // // // // //   List<Object?> get props => [
// // // // // // // //     userId,
// // // // // // // //     displayName,
// // // // // // // //     seatOrder,
// // // // // // // //     isReady,
// // // // // // // //     isOwner,
// // // // // // // //     isModerator,
// // // // // // // //     isSpectator,
// // // // // // // //     isMuted,
// // // // // // // //     isDisconnected,
// // // // // // // //   ];
// // // // // // // // }

// // // // // // // // // ── ChatMessageEntity ─────────────────────────────────────────────────────────

// // // // // // // // enum ChatMessageType { user, system }

// // // // // // // // class ChatMessageEntity extends Equatable {
// // // // // // // //   const ChatMessageEntity({
// // // // // // // //     required this.id,
// // // // // // // //     required this.roomId,
// // // // // // // //     required this.userId,
// // // // // // // //     required this.displayName,
// // // // // // // //     this.avatarUrl,
// // // // // // // //     required this.content,
// // // // // // // //     required this.createdAt,
// // // // // // // //     this.isDeleted = false,
// // // // // // // //     this.isOptimistic = false,
// // // // // // // //     this.type = ChatMessageType.user,
// // // // // // // //   });

// // // // // // // //   final String id;
// // // // // // // //   final String roomId;
// // // // // // // //   final String userId;
// // // // // // // //   final String displayName;
// // // // // // // //   final String? avatarUrl;
// // // // // // // //   final String content;
// // // // // // // //   final DateTime createdAt;
// // // // // // // //   final bool isDeleted;
// // // // // // // //   final bool isOptimistic; // client-only: not yet confirmed by server
// // // // // // // //   final ChatMessageType type;

// // // // // // // //   bool get isSystem => type == ChatMessageType.system;

// // // // // // // //   @override
// // // // // // // //   List<Object?> get props => [id, roomId, userId, content, createdAt];
// // // // // // // // }

// // // // // // // // // ── RoomSettingsEntity ────────────────────────────────────────────────────────

// // // // // // // // class RoomSettingsEntity extends Equatable {
// // // // // // // //   const RoomSettingsEntity({
// // // // // // // //     this.turnTimerSeconds = 60,
// // // // // // // //     this.allowSkip = true,
// // // // // // // //     this.maxRounds = 10,
// // // // // // // //     this.chatEnabled = true,
// // // // // // // //     this.allowSpectators = false,
// // // // // // // //     this.allowSpicy = false,
// // // // // // // //     this.requiresApproval = false,
// // // // // // // //   });

// // // // // // // //   final int turnTimerSeconds;
// // // // // // // //   final bool allowSkip;
// // // // // // // //   final int maxRounds;
// // // // // // // //   final bool chatEnabled;
// // // // // // // //   final bool allowSpectators;
// // // // // // // //   final bool allowSpicy;
// // // // // // // //   final bool requiresApproval;

// // // // // // // //   RoomSettingsEntity copyWith({
// // // // // // // //     int? turnTimerSeconds,
// // // // // // // //     bool? allowSkip,
// // // // // // // //     int? maxRounds,
// // // // // // // //     bool? chatEnabled,
// // // // // // // //     bool? allowSpectators,
// // // // // // // //     bool? allowSpicy,
// // // // // // // //     bool? requiresApproval,
// // // // // // // //   }) => RoomSettingsEntity(
// // // // // // // //     turnTimerSeconds: turnTimerSeconds ?? this.turnTimerSeconds,
// // // // // // // //     allowSkip: allowSkip ?? this.allowSkip,
// // // // // // // //     maxRounds: maxRounds ?? this.maxRounds,
// // // // // // // //     chatEnabled: chatEnabled ?? this.chatEnabled,
// // // // // // // //     allowSpectators: allowSpectators ?? this.allowSpectators,
// // // // // // // //     allowSpicy: allowSpicy ?? this.allowSpicy,
// // // // // // // //     requiresApproval: requiresApproval ?? this.requiresApproval,
// // // // // // // //   );

// // // // // // // //   Map<String, dynamic> toMap() => {
// // // // // // // //     'turn_timer_secs': turnTimerSeconds,
// // // // // // // //     'allow_skip': allowSkip,
// // // // // // // //     'max_rounds': maxRounds,
// // // // // // // //     'chat_enabled': chatEnabled,
// // // // // // // //     'allow_spectators': allowSpectators,
// // // // // // // //     'allow_spicy': allowSpicy,
// // // // // // // //     'requires_approval': requiresApproval,
// // // // // // // //   };

// // // // // // // //   static RoomSettingsEntity fromMap(Map<String, dynamic> m) =>
// // // // // // // //       RoomSettingsEntity(
// // // // // // // //         turnTimerSeconds: m['turn_timer_secs'] as int? ?? 60,
// // // // // // // //         allowSkip: m['allow_skip'] as bool? ?? true,
// // // // // // // //         maxRounds: m['max_rounds'] as int? ?? 10,
// // // // // // // //         chatEnabled: m['chat_enabled'] as bool? ?? true,
// // // // // // // //         allowSpectators: m['allow_spectators'] as bool? ?? false,
// // // // // // // //         allowSpicy: m['allow_spicy'] as bool? ?? false,
// // // // // // // //         requiresApproval: m['requires_approval'] as bool? ?? false,
// // // // // // // //       );

// // // // // // // //   @override
// // // // // // // //   List<Object?> get props => [
// // // // // // // //     turnTimerSeconds,
// // // // // // // //     allowSkip,
// // // // // // // //     maxRounds,
// // // // // // // //     chatEnabled,
// // // // // // // //     allowSpectators,
// // // // // // // //     allowSpicy,
// // // // // // // //     requiresApproval,
// // // // // // // //   ];
// // // // // // // // }

// // // // // // // // // ── ModerationAction ──────────────────────────────────────────────────────────

// // // // // // // // enum ModerationActionType {
// // // // // // // //   kick,
// // // // // // // //   mute,
// // // // // // // //   unmute,
// // // // // // // //   ban,
// // // // // // // //   unban,
// // // // // // // //   transferOwnership,
// // // // // // // //   pauseGame,
// // // // // // // //   resumeGame,
// // // // // // // // }

// // // // // // // // class ModerationAction {
// // // // // // // //   const ModerationAction({
// // // // // // // //     required this.type,
// // // // // // // //     required this.actorId,
// // // // // // // //     this.targetUserId,
// // // // // // // //     this.reason,
// // // // // // // //     this.durationSeconds,
// // // // // // // //     this.metadata = const {},
// // // // // // // //   });

// // // // // // // //   final ModerationActionType type;
// // // // // // // //   final String actorId;
// // // // // // // //   final String? targetUserId;
// // // // // // // //   final String? reason;
// // // // // // // //   final int? durationSeconds;
// // // // // // // //   final Map<String, dynamic> metadata;

// // // // // // // //   Map<String, dynamic> toMap() => {
// // // // // // // //     'type': type.name,
// // // // // // // //     'actor_id': actorId,
// // // // // // // //     'target_user_id': targetUserId,
// // // // // // // //     'reason': reason,
// // // // // // // //     'duration_seconds': durationSeconds,
// // // // // // // //     ...metadata,
// // // // // // // //   };

// // // // // // // //   static ModerationAction fromMap(Map<String, dynamic> m) => ModerationAction(
// // // // // // // //     type: ModerationActionType.values.firstWhere(
// // // // // // // //       (t) => t.name == m['type'],
// // // // // // // //       orElse: () => ModerationActionType.kick,
// // // // // // // //     ),
// // // // // // // //     actorId: m['actor_id'] as String? ?? '',
// // // // // // // //     targetUserId: m['target_user_id'] as String?,
// // // // // // // //     reason: m['reason'] as String?,
// // // // // // // //     durationSeconds: m['duration_seconds'] as int?,
// // // // // // // //   );
// // // // // // // // }

// // // // // // // import 'package:equatable/equatable.dart';
// // // // // // // import '../../games/engine/base_game_engine.dart';

// // // // // // // // ── Enums ─────────────────────────────────────────────────────────────────────

// // // // // // // enum RoomStatus {
// // // // // // //   waiting,
// // // // // // //   starting,
// // // // // // //   inGame,
// // // // // // //   paused,
// // // // // // //   ended,
// // // // // // //   closed;

// // // // // // //   static RoomStatus fromString(String s) => switch (s) {
// // // // // // //     'starting' => starting,
// // // // // // //     'in_game' => inGame,
// // // // // // //     'paused' => paused,
// // // // // // //     'ended' => ended,
// // // // // // //     'closed' => closed,
// // // // // // //     _ => waiting,
// // // // // // //   };

// // // // // // //   String toDbString() => switch (this) {
// // // // // // //     starting => 'starting',
// // // // // // //     inGame => 'in_game',
// // // // // // //     paused => 'paused',
// // // // // // //     ended => 'ended',
// // // // // // //     closed => 'closed',
// // // // // // //     waiting => 'waiting',
// // // // // // //   };
// // // // // // // }

// // // // // // // enum RoomVisibility {
// // // // // // //   public,
// // // // // // //   private;

// // // // // // //   static RoomVisibility fromString(String s) =>
// // // // // // //       s == 'private' ? private : public;
// // // // // // // }

// // // // // // // enum MemberRole { player, moderator, spectator }

// // // // // // // // ── RoomEntity ────────────────────────────────────────────────────────────────

// // // // // // // class RoomEntity extends Equatable {
// // // // // // //   const RoomEntity({
// // // // // // //     required this.id,
// // // // // // //     required this.ownerId,
// // // // // // //     required this.name,
// // // // // // //     required this.status,
// // // // // // //     required this.visibility,
// // // // // // //     required this.maxPlayers,
// // // // // // //     required this.currentPlayers,
// // // // // // //     this.inviteCode,
// // // // // // //     this.gameType,
// // // // // // //     this.packId,
// // // // // // //     this.language = 'en',
// // // // // // //     this.allowSpicy = false,
// // // // // // //     this.coverEmoji = '🎮',
// // // // // // //     this.lastActiveAt,
// // // // // // //     this.createdAt,
// // // // // // //   });

// // // // // // //   final String id;
// // // // // // //   final String ownerId;
// // // // // // //   final String name;
// // // // // // //   final RoomStatus status;
// // // // // // //   final RoomVisibility visibility;
// // // // // // //   final int maxPlayers;
// // // // // // //   final int currentPlayers;
// // // // // // //   final String? inviteCode;
// // // // // // //   final GameType? gameType;
// // // // // // //   final String? packId;
// // // // // // //   final String language;
// // // // // // //   final bool allowSpicy;
// // // // // // //   final String coverEmoji;
// // // // // // //   final DateTime? lastActiveAt;
// // // // // // //   final DateTime? createdAt;

// // // // // // //   bool get isFull => currentPlayers >= maxPlayers;
// // // // // // //   bool get isWaiting => status == RoomStatus.waiting;
// // // // // // //   bool get isInGame => status == RoomStatus.inGame;
// // // // // // //   bool get isPaused => status == RoomStatus.paused;
// // // // // // //   bool get isActive =>
// // // // // // //       status == RoomStatus.waiting || status == RoomStatus.inGame;
// // // // // // //   bool get canJoin => !isFull && isActive;
// // // // // // //   bool get isPrivate => visibility == RoomVisibility.private;

// // // // // // //   RoomEntity copyWith({
// // // // // // //     String? ownerId,
// // // // // // //     String? name,
// // // // // // //     RoomStatus? status,
// // // // // // //     int? currentPlayers,
// // // // // // //     GameType? gameType,
// // // // // // //     String? packId,
// // // // // // //     String? language,
// // // // // // //     bool? allowSpicy,
// // // // // // //     DateTime? lastActiveAt,
// // // // // // //   }) => RoomEntity(
// // // // // // //     id: id,
// // // // // // //     ownerId: ownerId ?? this.ownerId,
// // // // // // //     name: name ?? this.name,
// // // // // // //     status: status ?? this.status,
// // // // // // //     visibility: visibility,
// // // // // // //     maxPlayers: maxPlayers,
// // // // // // //     currentPlayers: currentPlayers ?? this.currentPlayers,
// // // // // // //     inviteCode: inviteCode,
// // // // // // //     gameType: gameType ?? this.gameType,
// // // // // // //     packId: packId ?? this.packId,
// // // // // // //     language: language ?? this.language,
// // // // // // //     allowSpicy: allowSpicy ?? this.allowSpicy,
// // // // // // //     coverEmoji: coverEmoji,
// // // // // // //     lastActiveAt: lastActiveAt ?? this.lastActiveAt,
// // // // // // //     createdAt: createdAt,
// // // // // // //   );

// // // // // // //   @override
// // // // // // //   List<Object?> get props => [
// // // // // // //     id,
// // // // // // //     ownerId,
// // // // // // //     name,
// // // // // // //     status,
// // // // // // //     visibility,
// // // // // // //     maxPlayers,
// // // // // // //     currentPlayers,
// // // // // // //     inviteCode,
// // // // // // //     gameType,
// // // // // // //     packId,
// // // // // // //     language,
// // // // // // //     allowSpicy,
// // // // // // //   ];
// // // // // // // }

// // // // // // // // ── RoomMemberEntity ──────────────────────────────────────────────────────────

// // // // // // // class RoomMemberEntity extends Equatable {
// // // // // // //   const RoomMemberEntity({
// // // // // // //     required this.userId,
// // // // // // //     required this.displayName,
// // // // // // //     this.avatarUrl,
// // // // // // //     required this.seatOrder,
// // // // // // //     required this.isReady,
// // // // // // //     required this.isOwner,
// // // // // // //     required this.isModerator,
// // // // // // //     this.isSpectator = false,
// // // // // // //     this.isMuted = false,
// // // // // // //     this.isDisconnected = false,
// // // // // // //     this.joinedAt,
// // // // // // //   });

// // // // // // //   final String userId;
// // // // // // //   final String displayName;
// // // // // // //   final String? avatarUrl;
// // // // // // //   final int seatOrder;
// // // // // // //   final bool isReady;
// // // // // // //   final bool isOwner;
// // // // // // //   final bool isModerator;
// // // // // // //   final bool isSpectator;
// // // // // // //   final bool isMuted;
// // // // // // //   final bool isDisconnected;
// // // // // // //   final DateTime? joinedAt;

// // // // // // //   bool get canModerate => isOwner || isModerator;
// // // // // // //   bool get isActive => !isDisconnected;

// // // // // // //   String get displayRole {
// // // // // // //     if (isOwner) return 'Owner';
// // // // // // //     if (isModerator) return 'Mod';
// // // // // // //     if (isSpectator) return 'Spectator';
// // // // // // //     return '';
// // // // // // //   }

// // // // // // //   RoomMemberEntity copyWith({
// // // // // // //     bool? isReady,
// // // // // // //     bool? isOwner,
// // // // // // //     bool? isModerator,
// // // // // // //     bool? isSpectator,
// // // // // // //     bool? isMuted,
// // // // // // //     bool? isDisconnected,
// // // // // // //   }) => RoomMemberEntity(
// // // // // // //     userId: userId,
// // // // // // //     displayName: displayName,
// // // // // // //     avatarUrl: avatarUrl,
// // // // // // //     seatOrder: seatOrder,
// // // // // // //     isReady: isReady ?? this.isReady,
// // // // // // //     isOwner: isOwner ?? this.isOwner,
// // // // // // //     isModerator: isModerator ?? this.isModerator,
// // // // // // //     isSpectator: isSpectator ?? this.isSpectator,
// // // // // // //     isMuted: isMuted ?? this.isMuted,
// // // // // // //     isDisconnected: isDisconnected ?? this.isDisconnected,
// // // // // // //     joinedAt: joinedAt,
// // // // // // //   );

// // // // // // //   @override
// // // // // // //   List<Object?> get props => [
// // // // // // //     userId,
// // // // // // //     displayName,
// // // // // // //     seatOrder,
// // // // // // //     isReady,
// // // // // // //     isOwner,
// // // // // // //     isModerator,
// // // // // // //     isSpectator,
// // // // // // //     isMuted,
// // // // // // //     isDisconnected,
// // // // // // //   ];
// // // // // // // }

// // // // // // // // ── ChatMessageEntity ─────────────────────────────────────────────────────────

// // // // // // // enum ChatMessageType { user, system }

// // // // // // // class ChatMessageEntity extends Equatable {
// // // // // // //   const ChatMessageEntity({
// // // // // // //     required this.id,
// // // // // // //     required this.roomId,
// // // // // // //     required this.userId,
// // // // // // //     required this.displayName,
// // // // // // //     this.avatarUrl,
// // // // // // //     required this.content,
// // // // // // //     required this.createdAt,
// // // // // // //     this.isDeleted = false,
// // // // // // //     this.isOptimistic = false,
// // // // // // //     this.type = ChatMessageType.user,
// // // // // // //   });

// // // // // // //   final String id;
// // // // // // //   final String roomId;
// // // // // // //   final String userId;
// // // // // // //   final String displayName;
// // // // // // //   final String? avatarUrl;
// // // // // // //   final String content;
// // // // // // //   final DateTime createdAt;
// // // // // // //   final bool isDeleted;
// // // // // // //   final bool isOptimistic; // client-only: not yet confirmed by server
// // // // // // //   final ChatMessageType type;

// // // // // // //   bool get isSystem => type == ChatMessageType.system;

// // // // // // //   @override
// // // // // // //   List<Object?> get props => [id, roomId, userId, content, createdAt];
// // // // // // // }

// // // // // // // // ── RoomSettingsEntity ────────────────────────────────────────────────────────

// // // // // // // class RoomSettingsEntity extends Equatable {
// // // // // // //   const RoomSettingsEntity({
// // // // // // //     this.turnTimerSeconds = 60,
// // // // // // //     this.allowSkip = true,
// // // // // // //     this.maxRounds = 10,
// // // // // // //     this.chatEnabled = true,
// // // // // // //     this.allowSpectators = false,
// // // // // // //     this.allowSpicy = false,
// // // // // // //     this.requiresApproval = false,
// // // // // // //   });

// // // // // // //   final int turnTimerSeconds;
// // // // // // //   final bool allowSkip;
// // // // // // //   final int maxRounds;
// // // // // // //   final bool chatEnabled;
// // // // // // //   final bool allowSpectators;
// // // // // // //   final bool allowSpicy;
// // // // // // //   final bool requiresApproval;

// // // // // // //   RoomSettingsEntity copyWith({
// // // // // // //     int? turnTimerSeconds,
// // // // // // //     bool? allowSkip,
// // // // // // //     int? maxRounds,
// // // // // // //     bool? chatEnabled,
// // // // // // //     bool? allowSpectators,
// // // // // // //     bool? allowSpicy,
// // // // // // //     bool? requiresApproval,
// // // // // // //   }) => RoomSettingsEntity(
// // // // // // //     turnTimerSeconds: turnTimerSeconds ?? this.turnTimerSeconds,
// // // // // // //     allowSkip: allowSkip ?? this.allowSkip,
// // // // // // //     maxRounds: maxRounds ?? this.maxRounds,
// // // // // // //     chatEnabled: chatEnabled ?? this.chatEnabled,
// // // // // // //     allowSpectators: allowSpectators ?? this.allowSpectators,
// // // // // // //     allowSpicy: allowSpicy ?? this.allowSpicy,
// // // // // // //     requiresApproval: requiresApproval ?? this.requiresApproval,
// // // // // // //   );

// // // // // // //   Map<String, dynamic> toMap() => {
// // // // // // //     'turn_timer_secs': turnTimerSeconds,
// // // // // // //     'allow_skip': allowSkip,
// // // // // // //     'max_rounds': maxRounds,
// // // // // // //     'chat_enabled': chatEnabled,
// // // // // // //     'allow_spectators': allowSpectators,
// // // // // // //     'allow_spicy': allowSpicy,
// // // // // // //     'requires_approval': requiresApproval,
// // // // // // //   };

// // // // // // //   static RoomSettingsEntity fromMap(Map<String, dynamic> m) =>
// // // // // // //       RoomSettingsEntity(
// // // // // // //         turnTimerSeconds: m['turn_timer_secs'] as int? ?? 60,
// // // // // // //         allowSkip: m['allow_skip'] as bool? ?? true,
// // // // // // //         maxRounds: m['max_rounds'] as int? ?? 10,
// // // // // // //         chatEnabled: m['chat_enabled'] as bool? ?? true,
// // // // // // //         allowSpectators: m['allow_spectators'] as bool? ?? false,
// // // // // // //         allowSpicy: m['allow_spicy'] as bool? ?? false,
// // // // // // //         requiresApproval: m['requires_approval'] as bool? ?? false,
// // // // // // //       );

// // // // // // //   @override
// // // // // // //   List<Object?> get props => [
// // // // // // //     turnTimerSeconds,
// // // // // // //     allowSkip,
// // // // // // //     maxRounds,
// // // // // // //     chatEnabled,
// // // // // // //     allowSpectators,
// // // // // // //     allowSpicy,
// // // // // // //     requiresApproval,
// // // // // // //   ];
// // // // // // // }

// // // // // // // // ── ModerationAction ──────────────────────────────────────────────────────────

// // // // // // // enum ModerationActionType {
// // // // // // //   kick,
// // // // // // //   mute,
// // // // // // //   unmute,
// // // // // // //   ban,
// // // // // // //   unban,
// // // // // // //   transferOwnership,
// // // // // // //   pauseGame,
// // // // // // //   resumeGame,
// // // // // // // }

// // // // // // // class ModerationAction {
// // // // // // //   const ModerationAction({
// // // // // // //     required this.type,
// // // // // // //     required this.actorId,
// // // // // // //     this.targetUserId,
// // // // // // //     this.reason,
// // // // // // //     this.durationSeconds,
// // // // // // //     this.metadata = const {},
// // // // // // //   });

// // // // // // //   final ModerationActionType type;
// // // // // // //   final String actorId;
// // // // // // //   final String? targetUserId;
// // // // // // //   final String? reason;
// // // // // // //   final int? durationSeconds;
// // // // // // //   final Map<String, dynamic> metadata;

// // // // // // //   Map<String, dynamic> toMap() => {
// // // // // // //     'type': type.name,
// // // // // // //     'actor_id': actorId,
// // // // // // //     'target_user_id': targetUserId,
// // // // // // //     'reason': reason,
// // // // // // //     'duration_seconds': durationSeconds,
// // // // // // //     ...metadata,
// // // // // // //   };

// // // // // // //   static ModerationAction fromMap(Map<String, dynamic> m) => ModerationAction(
// // // // // // //     type: ModerationActionType.values.firstWhere(
// // // // // // //       (t) => t.name == m['type'],
// // // // // // //       orElse: () => ModerationActionType.kick,
// // // // // // //     ),
// // // // // // //     actorId: m['actor_id'] as String? ?? '',
// // // // // // //     targetUserId: m['target_user_id'] as String?,
// // // // // // //     reason: m['reason'] as String?,
// // // // // // //     durationSeconds: m['duration_seconds'] as int?,
// // // // // // //   );
// // // // // // // }

// // // // // // // // import 'package:equatable/equatable.dart';
// // // // // // // // import '../../games/engine/base_game_engine.dart';

// // // // // // // // // ── Enums ─────────────────────────────────────────────────────────────────────

// // // // // // // // enum RoomStatus {
// // // // // // // //   waiting,
// // // // // // // //   starting,
// // // // // // // //   inGame,
// // // // // // // //   paused,
// // // // // // // //   ended,
// // // // // // // //   closed;

// // // // // // // //   static RoomStatus fromString(String s) => switch (s) {
// // // // // // // //     'starting' => starting,
// // // // // // // //     'in_game' => inGame,
// // // // // // // //     'paused' => paused,
// // // // // // // //     'ended' => ended,
// // // // // // // //     'closed' => closed,
// // // // // // // //     _ => waiting,
// // // // // // // //   };

// // // // // // // //   String toDbString() => switch (this) {
// // // // // // // //     starting => 'starting',
// // // // // // // //     inGame => 'in_game',
// // // // // // // //     paused => 'paused',
// // // // // // // //     ended => 'ended',
// // // // // // // //     closed => 'closed',
// // // // // // // //     waiting => 'waiting',
// // // // // // // //   };
// // // // // // // // }

// // // // // // // // enum RoomVisibility {
// // // // // // // //   public,
// // // // // // // //   private;

// // // // // // // //   static RoomVisibility fromString(String s) =>
// // // // // // // //       s == 'private' ? private : public;
// // // // // // // // }

// // // // // // // // enum MemberRole { player, moderator, spectator }

// // // // // // // // // ── RoomEntity ────────────────────────────────────────────────────────────────

// // // // // // // // class RoomEntity extends Equatable {
// // // // // // // //   const RoomEntity({
// // // // // // // //     required this.id,
// // // // // // // //     required this.ownerId,
// // // // // // // //     required this.name,
// // // // // // // //     required this.status,
// // // // // // // //     required this.visibility,
// // // // // // // //     required this.maxPlayers,
// // // // // // // //     required this.currentPlayers,
// // // // // // // //     this.inviteCode,
// // // // // // // //     this.gameType,
// // // // // // // //     this.packId,
// // // // // // // //     this.language = 'en',
// // // // // // // //     this.allowSpicy = false,
// // // // // // // //     this.coverEmoji = '🎮',
// // // // // // // //     this.lastActiveAt,
// // // // // // // //     this.createdAt,
// // // // // // // //   });

// // // // // // // //   final String id;
// // // // // // // //   final String ownerId;
// // // // // // // //   final String name;
// // // // // // // //   final RoomStatus status;
// // // // // // // //   final RoomVisibility visibility;
// // // // // // // //   final int maxPlayers;
// // // // // // // //   final int currentPlayers;
// // // // // // // //   final String? inviteCode;
// // // // // // // //   final GameType? gameType;
// // // // // // // //   final String? packId;
// // // // // // // //   final String language;
// // // // // // // //   final bool allowSpicy;
// // // // // // // //   final String coverEmoji;
// // // // // // // //   final DateTime? lastActiveAt;
// // // // // // // //   final DateTime? createdAt;

// // // // // // // //   bool get isFull => currentPlayers >= maxPlayers;
// // // // // // // //   bool get isWaiting => status == RoomStatus.waiting;
// // // // // // // //   bool get isInGame => status == RoomStatus.inGame;
// // // // // // // //   bool get isPaused => status == RoomStatus.paused;
// // // // // // // //   bool get isActive =>
// // // // // // // //       status == RoomStatus.waiting || status == RoomStatus.inGame;
// // // // // // // //   bool get canJoin => !isFull && isActive;
// // // // // // // //   bool get isPrivate => visibility == RoomVisibility.private;

// // // // // // // //   RoomEntity copyWith({
// // // // // // // //     String? ownerId,
// // // // // // // //     String? name,
// // // // // // // //     RoomStatus? status,
// // // // // // // //     int? currentPlayers,
// // // // // // // //     GameType? gameType,
// // // // // // // //     String? packId,
// // // // // // // //     bool? allowSpicy,
// // // // // // // //     DateTime? lastActiveAt,
// // // // // // // //   }) => RoomEntity(
// // // // // // // //     id: id,
// // // // // // // //     ownerId: ownerId ?? this.ownerId,
// // // // // // // //     name: name ?? this.name,
// // // // // // // //     status: status ?? this.status,
// // // // // // // //     visibility: visibility,
// // // // // // // //     maxPlayers: maxPlayers,
// // // // // // // //     currentPlayers: currentPlayers ?? this.currentPlayers,
// // // // // // // //     inviteCode: inviteCode,
// // // // // // // //     gameType: gameType ?? this.gameType,
// // // // // // // //     packId: packId ?? this.packId,
// // // // // // // //     language: language,
// // // // // // // //     allowSpicy: allowSpicy ?? this.allowSpicy,
// // // // // // // //     coverEmoji: coverEmoji,
// // // // // // // //     lastActiveAt: lastActiveAt ?? this.lastActiveAt,
// // // // // // // //     createdAt: createdAt,
// // // // // // // //   );

// // // // // // // //   @override
// // // // // // // //   List<Object?> get props => [
// // // // // // // //     id,
// // // // // // // //     ownerId,
// // // // // // // //     name,
// // // // // // // //     status,
// // // // // // // //     visibility,
// // // // // // // //     maxPlayers,
// // // // // // // //     currentPlayers,
// // // // // // // //     inviteCode,
// // // // // // // //     gameType,
// // // // // // // //     packId,
// // // // // // // //     language,
// // // // // // // //     allowSpicy,
// // // // // // // //   ];
// // // // // // // // }

// // // // // // // // // ── RoomMemberEntity ──────────────────────────────────────────────────────────

// // // // // // // // class RoomMemberEntity extends Equatable {
// // // // // // // //   const RoomMemberEntity({
// // // // // // // //     required this.userId,
// // // // // // // //     required this.displayName,
// // // // // // // //     this.avatarUrl,
// // // // // // // //     required this.seatOrder,
// // // // // // // //     required this.isReady,
// // // // // // // //     required this.isOwner,
// // // // // // // //     required this.isModerator,
// // // // // // // //     this.isMuted = false,
// // // // // // // //     this.isDisconnected = false,
// // // // // // // //     this.joinedAt,
// // // // // // // //   });

// // // // // // // //   final String userId;
// // // // // // // //   final String displayName;
// // // // // // // //   final String? avatarUrl;
// // // // // // // //   final int seatOrder;
// // // // // // // //   final bool isReady;
// // // // // // // //   final bool isOwner;
// // // // // // // //   final bool isModerator;
// // // // // // // //   final bool isMuted;
// // // // // // // //   final bool isDisconnected;
// // // // // // // //   final DateTime? joinedAt;

// // // // // // // //   bool get canModerate => isOwner || isModerator;
// // // // // // // //   bool get isActive => !isDisconnected;

// // // // // // // //   String get displayRole {
// // // // // // // //     if (isOwner) return 'Owner';
// // // // // // // //     if (isModerator) return 'Mod';
// // // // // // // //     return '';
// // // // // // // //   }

// // // // // // // //   RoomMemberEntity copyWith({
// // // // // // // //     bool? isReady,
// // // // // // // //     bool? isOwner,
// // // // // // // //     bool? isModerator,
// // // // // // // //     bool? isMuted,
// // // // // // // //     bool? isDisconnected,
// // // // // // // //   }) => RoomMemberEntity(
// // // // // // // //     userId: userId,
// // // // // // // //     displayName: displayName,
// // // // // // // //     avatarUrl: avatarUrl,
// // // // // // // //     seatOrder: seatOrder,
// // // // // // // //     isReady: isReady ?? this.isReady,
// // // // // // // //     isOwner: isOwner ?? this.isOwner,
// // // // // // // //     isModerator: isModerator ?? this.isModerator,
// // // // // // // //     isMuted: isMuted ?? this.isMuted,
// // // // // // // //     isDisconnected: isDisconnected ?? this.isDisconnected,
// // // // // // // //     joinedAt: joinedAt,
// // // // // // // //   );

// // // // // // // //   @override
// // // // // // // //   List<Object?> get props => [
// // // // // // // //     userId,
// // // // // // // //     displayName,
// // // // // // // //     seatOrder,
// // // // // // // //     isReady,
// // // // // // // //     isOwner,
// // // // // // // //     isModerator,
// // // // // // // //     isMuted,
// // // // // // // //     isDisconnected,
// // // // // // // //   ];
// // // // // // // // }

// // // // // // // // // ── ChatMessageEntity ─────────────────────────────────────────────────────────

// // // // // // // // enum ChatMessageType { user, system }

// // // // // // // // class ChatMessageEntity extends Equatable {
// // // // // // // //   const ChatMessageEntity({
// // // // // // // //     required this.id,
// // // // // // // //     required this.roomId,
// // // // // // // //     required this.userId,
// // // // // // // //     required this.displayName,
// // // // // // // //     this.avatarUrl,
// // // // // // // //     required this.content,
// // // // // // // //     required this.createdAt,
// // // // // // // //     this.isDeleted = false,
// // // // // // // //     this.isOptimistic = false,
// // // // // // // //     this.type = ChatMessageType.user,
// // // // // // // //   });

// // // // // // // //   final String id;
// // // // // // // //   final String roomId;
// // // // // // // //   final String userId;
// // // // // // // //   final String displayName;
// // // // // // // //   final String? avatarUrl;
// // // // // // // //   final String content;
// // // // // // // //   final DateTime createdAt;
// // // // // // // //   final bool isDeleted;
// // // // // // // //   final bool isOptimistic; // client-only: not yet confirmed by server
// // // // // // // //   final ChatMessageType type;

// // // // // // // //   bool get isSystem => type == ChatMessageType.system;

// // // // // // // //   @override
// // // // // // // //   List<Object?> get props => [id, roomId, userId, content, createdAt];
// // // // // // // // }

// // // // // // // // // ── RoomSettingsEntity ────────────────────────────────────────────────────────

// // // // // // // // class RoomSettingsEntity extends Equatable {
// // // // // // // //   const RoomSettingsEntity({
// // // // // // // //     this.turnTimerSeconds = 60,
// // // // // // // //     this.allowSkip = true,
// // // // // // // //     this.maxRounds = 10,
// // // // // // // //     this.chatEnabled = true,
// // // // // // // //     this.allowSpectators = false,
// // // // // // // //     this.allowSpicy = false,
// // // // // // // //     this.requiresApproval = false,
// // // // // // // //   });

// // // // // // // //   final int turnTimerSeconds;
// // // // // // // //   final bool allowSkip;
// // // // // // // //   final int maxRounds;
// // // // // // // //   final bool chatEnabled;
// // // // // // // //   final bool allowSpectators;
// // // // // // // //   final bool allowSpicy;
// // // // // // // //   final bool requiresApproval;

// // // // // // // //   RoomSettingsEntity copyWith({
// // // // // // // //     int? turnTimerSeconds,
// // // // // // // //     bool? allowSkip,
// // // // // // // //     int? maxRounds,
// // // // // // // //     bool? chatEnabled,
// // // // // // // //     bool? allowSpectators,
// // // // // // // //     bool? allowSpicy,
// // // // // // // //     bool? requiresApproval,
// // // // // // // //   }) => RoomSettingsEntity(
// // // // // // // //     turnTimerSeconds: turnTimerSeconds ?? this.turnTimerSeconds,
// // // // // // // //     allowSkip: allowSkip ?? this.allowSkip,
// // // // // // // //     maxRounds: maxRounds ?? this.maxRounds,
// // // // // // // //     chatEnabled: chatEnabled ?? this.chatEnabled,
// // // // // // // //     allowSpectators: allowSpectators ?? this.allowSpectators,
// // // // // // // //     allowSpicy: allowSpicy ?? this.allowSpicy,
// // // // // // // //     requiresApproval: requiresApproval ?? this.requiresApproval,
// // // // // // // //   );

// // // // // // // //   Map<String, dynamic> toMap() => {
// // // // // // // //     'turn_timer_secs': turnTimerSeconds,
// // // // // // // //     'allow_skip': allowSkip,
// // // // // // // //     'max_rounds': maxRounds,
// // // // // // // //     'chat_enabled': chatEnabled,
// // // // // // // //     'allow_spectators': allowSpectators,
// // // // // // // //     'allow_spicy': allowSpicy,
// // // // // // // //     'requires_approval': requiresApproval,
// // // // // // // //   };

// // // // // // // //   static RoomSettingsEntity fromMap(Map<String, dynamic> m) =>
// // // // // // // //       RoomSettingsEntity(
// // // // // // // //         turnTimerSeconds: m['turn_timer_secs'] as int? ?? 60,
// // // // // // // //         allowSkip: m['allow_skip'] as bool? ?? true,
// // // // // // // //         maxRounds: m['max_rounds'] as int? ?? 10,
// // // // // // // //         chatEnabled: m['chat_enabled'] as bool? ?? true,
// // // // // // // //         allowSpectators: m['allow_spectators'] as bool? ?? false,
// // // // // // // //         allowSpicy: m['allow_spicy'] as bool? ?? false,
// // // // // // // //         requiresApproval: m['requires_approval'] as bool? ?? false,
// // // // // // // //       );

// // // // // // // //   @override
// // // // // // // //   List<Object?> get props => [
// // // // // // // //     turnTimerSeconds,
// // // // // // // //     allowSkip,
// // // // // // // //     maxRounds,
// // // // // // // //     chatEnabled,
// // // // // // // //     allowSpectators,
// // // // // // // //     allowSpicy,
// // // // // // // //     requiresApproval,
// // // // // // // //   ];
// // // // // // // // }

// // // // // // // // // ── ModerationAction ──────────────────────────────────────────────────────────

// // // // // // // // enum ModerationActionType {
// // // // // // // //   kick,
// // // // // // // //   mute,
// // // // // // // //   unmute,
// // // // // // // //   ban,
// // // // // // // //   unban,
// // // // // // // //   transferOwnership,
// // // // // // // //   pauseGame,
// // // // // // // //   resumeGame,
// // // // // // // // }

// // // // // // // // class ModerationAction {
// // // // // // // //   const ModerationAction({
// // // // // // // //     required this.type,
// // // // // // // //     required this.actorId,
// // // // // // // //     this.targetUserId,
// // // // // // // //     this.reason,
// // // // // // // //     this.durationSeconds,
// // // // // // // //     this.metadata = const {},
// // // // // // // //   });

// // // // // // // //   final ModerationActionType type;
// // // // // // // //   final String actorId;
// // // // // // // //   final String? targetUserId;
// // // // // // // //   final String? reason;
// // // // // // // //   final int? durationSeconds;
// // // // // // // //   final Map<String, dynamic> metadata;

// // // // // // // //   Map<String, dynamic> toMap() => {
// // // // // // // //     'type': type.name,
// // // // // // // //     'actor_id': actorId,
// // // // // // // //     'target_user_id': targetUserId,
// // // // // // // //     'reason': reason,
// // // // // // // //     'duration_seconds': durationSeconds,
// // // // // // // //     ...metadata,
// // // // // // // //   };

// // // // // // // //   static ModerationAction fromMap(Map<String, dynamic> m) => ModerationAction(
// // // // // // // //     type: ModerationActionType.values.firstWhere(
// // // // // // // //       (t) => t.name == m['type'],
// // // // // // // //       orElse: () => ModerationActionType.kick,
// // // // // // // //     ),
// // // // // // // //     actorId: m['actor_id'] as String? ?? '',
// // // // // // // //     targetUserId: m['target_user_id'] as String?,
// // // // // // // //     reason: m['reason'] as String?,
// // // // // // // //     durationSeconds: m['duration_seconds'] as int?,
// // // // // // // //   );
// // // // // // // // }

// // // // // // // import 'package:equatable/equatable.dart';
// // // // // // // import '../../games/engine/base_game_engine.dart';

// // // // // // // // ── Enums ─────────────────────────────────────────────────────────────────────

// // // // // // // enum RoomStatus {
// // // // // // //   waiting,
// // // // // // //   starting,
// // // // // // //   inGame,
// // // // // // //   paused,
// // // // // // //   ended,
// // // // // // //   closed;

// // // // // // //   static RoomStatus fromString(String s) => switch (s) {
// // // // // // //     'starting' => starting,
// // // // // // //     'in_game' => inGame,
// // // // // // //     'paused' => paused,
// // // // // // //     'ended' => ended,
// // // // // // //     'closed' => closed,
// // // // // // //     _ => waiting,
// // // // // // //   };

// // // // // // //   String toDbString() => switch (this) {
// // // // // // //     starting => 'starting',
// // // // // // //     inGame => 'in_game',
// // // // // // //     paused => 'paused',
// // // // // // //     ended => 'ended',
// // // // // // //     closed => 'closed',
// // // // // // //     waiting => 'waiting',
// // // // // // //   };
// // // // // // // }

// // // // // // // enum RoomVisibility {
// // // // // // //   public,
// // // // // // //   private;

// // // // // // //   static RoomVisibility fromString(String s) =>
// // // // // // //       s == 'private' ? private : public;
// // // // // // // }

// // // // // // // enum MemberRole { player, moderator, spectator }

// // // // // // // // ── RoomEntity ────────────────────────────────────────────────────────────────

// // // // // // // class RoomEntity extends Equatable {
// // // // // // //   const RoomEntity({
// // // // // // //     required this.id,
// // // // // // //     required this.ownerId,
// // // // // // //     required this.name,
// // // // // // //     required this.status,
// // // // // // //     required this.visibility,
// // // // // // //     required this.maxPlayers,
// // // // // // //     required this.currentPlayers,
// // // // // // //     this.inviteCode,
// // // // // // //     this.gameType,
// // // // // // //     this.packId,
// // // // // // //     this.language = 'en',
// // // // // // //     this.allowSpicy = false,
// // // // // // //     this.coverEmoji = '🎮',
// // // // // // //     this.lastActiveAt,
// // // // // // //     this.createdAt,
// // // // // // //   });

// // // // // // //   final String id;
// // // // // // //   final String ownerId;
// // // // // // //   final String name;
// // // // // // //   final RoomStatus status;
// // // // // // //   final RoomVisibility visibility;
// // // // // // //   final int maxPlayers;
// // // // // // //   final int currentPlayers;
// // // // // // //   final String? inviteCode;
// // // // // // //   final GameType? gameType;
// // // // // // //   final String? packId;
// // // // // // //   final String language;
// // // // // // //   final bool allowSpicy;
// // // // // // //   final String coverEmoji;
// // // // // // //   final DateTime? lastActiveAt;
// // // // // // //   final DateTime? createdAt;

// // // // // // //   bool get isFull => currentPlayers >= maxPlayers;
// // // // // // //   bool get isWaiting => status == RoomStatus.waiting;
// // // // // // //   bool get isInGame => status == RoomStatus.inGame;
// // // // // // //   bool get isPaused => status == RoomStatus.paused;
// // // // // // //   bool get isActive =>
// // // // // // //       status == RoomStatus.waiting || status == RoomStatus.inGame;
// // // // // // //   bool get canJoin => !isFull && isActive;
// // // // // // //   bool get isPrivate => visibility == RoomVisibility.private;

// // // // // // //   RoomEntity copyWith({
// // // // // // //     String? ownerId,
// // // // // // //     String? name,
// // // // // // //     RoomStatus? status,
// // // // // // //     int? currentPlayers,
// // // // // // //     GameType? gameType,
// // // // // // //     String? packId,
// // // // // // //     bool? allowSpicy,
// // // // // // //     DateTime? lastActiveAt,
// // // // // // //   }) => RoomEntity(
// // // // // // //     id: id,
// // // // // // //     ownerId: ownerId ?? this.ownerId,
// // // // // // //     name: name ?? this.name,
// // // // // // //     status: status ?? this.status,
// // // // // // //     visibility: visibility,
// // // // // // //     maxPlayers: maxPlayers,
// // // // // // //     currentPlayers: currentPlayers ?? this.currentPlayers,
// // // // // // //     inviteCode: inviteCode,
// // // // // // //     gameType: gameType ?? this.gameType,
// // // // // // //     packId: packId ?? this.packId,
// // // // // // //     language: language,
// // // // // // //     allowSpicy: allowSpicy ?? this.allowSpicy,
// // // // // // //     coverEmoji: coverEmoji,
// // // // // // //     lastActiveAt: lastActiveAt ?? this.lastActiveAt,
// // // // // // //     createdAt: createdAt,
// // // // // // //   );

// // // // // // //   @override
// // // // // // //   List<Object?> get props => [
// // // // // // //     id,
// // // // // // //     ownerId,
// // // // // // //     name,
// // // // // // //     status,
// // // // // // //     visibility,
// // // // // // //     maxPlayers,
// // // // // // //     currentPlayers,
// // // // // // //     inviteCode,
// // // // // // //     gameType,
// // // // // // //     packId,
// // // // // // //     language,
// // // // // // //     allowSpicy,
// // // // // // //   ];
// // // // // // // }

// // // // // // // // ── RoomMemberEntity ──────────────────────────────────────────────────────────

// // // // // // // class RoomMemberEntity extends Equatable {
// // // // // // //   const RoomMemberEntity({
// // // // // // //     required this.userId,
// // // // // // //     required this.displayName,
// // // // // // //     this.avatarUrl,
// // // // // // //     required this.seatOrder,
// // // // // // //     required this.isReady,
// // // // // // //     required this.isOwner,
// // // // // // //     required this.isModerator,
// // // // // // //     this.isSpectator = false,
// // // // // // //     this.isMuted = false,
// // // // // // //     this.isDisconnected = false,
// // // // // // //     this.joinedAt,
// // // // // // //   });

// // // // // // //   final String userId;
// // // // // // //   final String displayName;
// // // // // // //   final String? avatarUrl;
// // // // // // //   final int seatOrder;
// // // // // // //   final bool isReady;
// // // // // // //   final bool isOwner;
// // // // // // //   final bool isModerator;
// // // // // // //   final bool isSpectator;
// // // // // // //   final bool isMuted;
// // // // // // //   final bool isDisconnected;
// // // // // // //   final DateTime? joinedAt;

// // // // // // //   bool get canModerate => isOwner || isModerator;
// // // // // // //   bool get isActive => !isDisconnected;

// // // // // // //   String get displayRole {
// // // // // // //     if (isOwner) return 'Owner';
// // // // // // //     if (isModerator) return 'Mod';
// // // // // // //     if (isSpectator) return 'Spectator';
// // // // // // //     return '';
// // // // // // //   }

// // // // // // //   RoomMemberEntity copyWith({
// // // // // // //     bool? isReady,
// // // // // // //     bool? isOwner,
// // // // // // //     bool? isModerator,
// // // // // // //     bool? isSpectator,
// // // // // // //     bool? isMuted,
// // // // // // //     bool? isDisconnected,
// // // // // // //   }) => RoomMemberEntity(
// // // // // // //     userId: userId,
// // // // // // //     displayName: displayName,
// // // // // // //     avatarUrl: avatarUrl,
// // // // // // //     seatOrder: seatOrder,
// // // // // // //     isReady: isReady ?? this.isReady,
// // // // // // //     isOwner: isOwner ?? this.isOwner,
// // // // // // //     isModerator: isModerator ?? this.isModerator,
// // // // // // //     isSpectator: isSpectator ?? this.isSpectator,
// // // // // // //     isMuted: isMuted ?? this.isMuted,
// // // // // // //     isDisconnected: isDisconnected ?? this.isDisconnected,
// // // // // // //     joinedAt: joinedAt,
// // // // // // //   );

// // // // // // //   @override
// // // // // // //   List<Object?> get props => [
// // // // // // //     userId,
// // // // // // //     displayName,
// // // // // // //     seatOrder,
// // // // // // //     isReady,
// // // // // // //     isOwner,
// // // // // // //     isModerator,
// // // // // // //     isSpectator,
// // // // // // //     isMuted,
// // // // // // //     isDisconnected,
// // // // // // //   ];
// // // // // // // }

// // // // // // // // ── ChatMessageEntity ─────────────────────────────────────────────────────────

// // // // // // // enum ChatMessageType { user, system }

// // // // // // // class ChatMessageEntity extends Equatable {
// // // // // // //   const ChatMessageEntity({
// // // // // // //     required this.id,
// // // // // // //     required this.roomId,
// // // // // // //     required this.userId,
// // // // // // //     required this.displayName,
// // // // // // //     this.avatarUrl,
// // // // // // //     required this.content,
// // // // // // //     required this.createdAt,
// // // // // // //     this.isDeleted = false,
// // // // // // //     this.isOptimistic = false,
// // // // // // //     this.type = ChatMessageType.user,
// // // // // // //   });

// // // // // // //   final String id;
// // // // // // //   final String roomId;
// // // // // // //   final String userId;
// // // // // // //   final String displayName;
// // // // // // //   final String? avatarUrl;
// // // // // // //   final String content;
// // // // // // //   final DateTime createdAt;
// // // // // // //   final bool isDeleted;
// // // // // // //   final bool isOptimistic; // client-only: not yet confirmed by server
// // // // // // //   final ChatMessageType type;

// // // // // // //   bool get isSystem => type == ChatMessageType.system;

// // // // // // //   @override
// // // // // // //   List<Object?> get props => [id, roomId, userId, content, createdAt];
// // // // // // // }

// // // // // // // // ── RoomSettingsEntity ────────────────────────────────────────────────────────

// // // // // // // class RoomSettingsEntity extends Equatable {
// // // // // // //   const RoomSettingsEntity({
// // // // // // //     this.turnTimerSeconds = 60,
// // // // // // //     this.allowSkip = true,
// // // // // // //     this.maxRounds = 10,
// // // // // // //     this.chatEnabled = true,
// // // // // // //     this.allowSpectators = false,
// // // // // // //     this.allowSpicy = false,
// // // // // // //     this.requiresApproval = false,
// // // // // // //   });

// // // // // // //   final int turnTimerSeconds;
// // // // // // //   final bool allowSkip;
// // // // // // //   final int maxRounds;
// // // // // // //   final bool chatEnabled;
// // // // // // //   final bool allowSpectators;
// // // // // // //   final bool allowSpicy;
// // // // // // //   final bool requiresApproval;

// // // // // // //   RoomSettingsEntity copyWith({
// // // // // // //     int? turnTimerSeconds,
// // // // // // //     bool? allowSkip,
// // // // // // //     int? maxRounds,
// // // // // // //     bool? chatEnabled,
// // // // // // //     bool? allowSpectators,
// // // // // // //     bool? allowSpicy,
// // // // // // //     bool? requiresApproval,
// // // // // // //   }) => RoomSettingsEntity(
// // // // // // //     turnTimerSeconds: turnTimerSeconds ?? this.turnTimerSeconds,
// // // // // // //     allowSkip: allowSkip ?? this.allowSkip,
// // // // // // //     maxRounds: maxRounds ?? this.maxRounds,
// // // // // // //     chatEnabled: chatEnabled ?? this.chatEnabled,
// // // // // // //     allowSpectators: allowSpectators ?? this.allowSpectators,
// // // // // // //     allowSpicy: allowSpicy ?? this.allowSpicy,
// // // // // // //     requiresApproval: requiresApproval ?? this.requiresApproval,
// // // // // // //   );

// // // // // // //   Map<String, dynamic> toMap() => {
// // // // // // //     'turn_timer_secs': turnTimerSeconds,
// // // // // // //     'allow_skip': allowSkip,
// // // // // // //     'max_rounds': maxRounds,
// // // // // // //     'chat_enabled': chatEnabled,
// // // // // // //     'allow_spectators': allowSpectators,
// // // // // // //     'allow_spicy': allowSpicy,
// // // // // // //     'requires_approval': requiresApproval,
// // // // // // //   };

// // // // // // //   static RoomSettingsEntity fromMap(Map<String, dynamic> m) =>
// // // // // // //       RoomSettingsEntity(
// // // // // // //         turnTimerSeconds: m['turn_timer_secs'] as int? ?? 60,
// // // // // // //         allowSkip: m['allow_skip'] as bool? ?? true,
// // // // // // //         maxRounds: m['max_rounds'] as int? ?? 10,
// // // // // // //         chatEnabled: m['chat_enabled'] as bool? ?? true,
// // // // // // //         allowSpectators: m['allow_spectators'] as bool? ?? false,
// // // // // // //         allowSpicy: m['allow_spicy'] as bool? ?? false,
// // // // // // //         requiresApproval: m['requires_approval'] as bool? ?? false,
// // // // // // //       );

// // // // // // //   @override
// // // // // // //   List<Object?> get props => [
// // // // // // //     turnTimerSeconds,
// // // // // // //     allowSkip,
// // // // // // //     maxRounds,
// // // // // // //     chatEnabled,
// // // // // // //     allowSpectators,
// // // // // // //     allowSpicy,
// // // // // // //     requiresApproval,
// // // // // // //   ];
// // // // // // // }

// // // // // // // // ── ModerationAction ──────────────────────────────────────────────────────────

// // // // // // // enum ModerationActionType {
// // // // // // //   kick,
// // // // // // //   mute,
// // // // // // //   unmute,
// // // // // // //   ban,
// // // // // // //   unban,
// // // // // // //   transferOwnership,
// // // // // // //   pauseGame,
// // // // // // //   resumeGame,
// // // // // // // }

// // // // // // // class ModerationAction {
// // // // // // //   const ModerationAction({
// // // // // // //     required this.type,
// // // // // // //     required this.actorId,
// // // // // // //     this.targetUserId,
// // // // // // //     this.reason,
// // // // // // //     this.durationSeconds,
// // // // // // //     this.metadata = const {},
// // // // // // //   });

// // // // // // //   final ModerationActionType type;
// // // // // // //   final String actorId;
// // // // // // //   final String? targetUserId;
// // // // // // //   final String? reason;
// // // // // // //   final int? durationSeconds;
// // // // // // //   final Map<String, dynamic> metadata;

// // // // // // //   Map<String, dynamic> toMap() => {
// // // // // // //     'type': type.name,
// // // // // // //     'actor_id': actorId,
// // // // // // //     'target_user_id': targetUserId,
// // // // // // //     'reason': reason,
// // // // // // //     'duration_seconds': durationSeconds,
// // // // // // //     ...metadata,
// // // // // // //   };

// // // // // // //   static ModerationAction fromMap(Map<String, dynamic> m) => ModerationAction(
// // // // // // //     type: ModerationActionType.values.firstWhere(
// // // // // // //       (t) => t.name == m['type'],
// // // // // // //       orElse: () => ModerationActionType.kick,
// // // // // // //     ),
// // // // // // //     actorId: m['actor_id'] as String? ?? '',
// // // // // // //     targetUserId: m['target_user_id'] as String?,
// // // // // // //     reason: m['reason'] as String?,
// // // // // // //     durationSeconds: m['duration_seconds'] as int?,
// // // // // // //   );
// // // // // // // }

// // // // // // import 'package:equatable/equatable.dart';
// // // // // // import '../../games/engine/base_game_engine.dart';

// // // // // // // ── Enums ─────────────────────────────────────────────────────────────────────

// // // // // // enum RoomStatus {
// // // // // //   waiting,
// // // // // //   starting,
// // // // // //   inGame,
// // // // // //   paused,
// // // // // //   ended,
// // // // // //   closed;

// // // // // //   static RoomStatus fromString(String s) => switch (s) {
// // // // // //     'starting' => starting,
// // // // // //     'in_game' => inGame,
// // // // // //     'paused' => paused,
// // // // // //     'ended' => ended,
// // // // // //     'closed' => closed,
// // // // // //     _ => waiting,
// // // // // //   };

// // // // // //   String toDbString() => switch (this) {
// // // // // //     starting => 'starting',
// // // // // //     inGame => 'in_game',
// // // // // //     paused => 'paused',
// // // // // //     ended => 'ended',
// // // // // //     closed => 'closed',
// // // // // //     waiting => 'waiting',
// // // // // //   };
// // // // // // }

// // // // // // enum RoomVisibility {
// // // // // //   public,
// // // // // //   private;

// // // // // //   static RoomVisibility fromString(String s) =>
// // // // // //       s == 'private' ? private : public;
// // // // // // }

// // // // // // enum MemberRole { player, moderator, spectator }

// // // // // // // ── RoomEntity ────────────────────────────────────────────────────────────────

// // // // // // class RoomEntity extends Equatable {
// // // // // //   const RoomEntity({
// // // // // //     required this.id,
// // // // // //     required this.ownerId,
// // // // // //     required this.name,
// // // // // //     required this.status,
// // // // // //     required this.visibility,
// // // // // //     required this.maxPlayers,
// // // // // //     required this.currentPlayers,
// // // // // //     this.inviteCode,
// // // // // //     this.gameType,
// // // // // //     this.packId,
// // // // // //     this.language = 'en',
// // // // // //     this.allowSpicy = false,
// // // // // //     this.coverEmoji = '🎮',
// // // // // //     this.lastActiveAt,
// // // // // //     this.createdAt,
// // // // // //   });

// // // // // //   final String id;
// // // // // //   final String ownerId;
// // // // // //   final String name;
// // // // // //   final RoomStatus status;
// // // // // //   final RoomVisibility visibility;
// // // // // //   final int maxPlayers;
// // // // // //   final int currentPlayers;
// // // // // //   final String? inviteCode;
// // // // // //   final GameType? gameType;
// // // // // //   final String? packId;
// // // // // //   final String language;
// // // // // //   final bool allowSpicy;
// // // // // //   final String coverEmoji;
// // // // // //   final DateTime? lastActiveAt;
// // // // // //   final DateTime? createdAt;

// // // // // //   bool get isFull => currentPlayers >= maxPlayers;
// // // // // //   bool get isWaiting => status == RoomStatus.waiting;
// // // // // //   bool get isInGame => status == RoomStatus.inGame;
// // // // // //   bool get isPaused => status == RoomStatus.paused;
// // // // // //   bool get isActive =>
// // // // // //       status == RoomStatus.waiting || status == RoomStatus.inGame;
// // // // // //   bool get canJoin => !isFull && isActive;
// // // // // //   bool get isPrivate => visibility == RoomVisibility.private;

// // // // // //   RoomEntity copyWith({
// // // // // //     String? ownerId,
// // // // // //     String? name,
// // // // // //     RoomStatus? status,
// // // // // //     int? currentPlayers,
// // // // // //     GameType? gameType,
// // // // // //     String? packId,
// // // // // //     String? language,
// // // // // //     bool? allowSpicy,
// // // // // //     DateTime? lastActiveAt,
// // // // // //   }) => RoomEntity(
// // // // // //     id: id,
// // // // // //     ownerId: ownerId ?? this.ownerId,
// // // // // //     name: name ?? this.name,
// // // // // //     status: status ?? this.status,
// // // // // //     visibility: visibility,
// // // // // //     maxPlayers: maxPlayers,
// // // // // //     currentPlayers: currentPlayers ?? this.currentPlayers,
// // // // // //     inviteCode: inviteCode,
// // // // // //     gameType: gameType ?? this.gameType,
// // // // // //     packId: packId ?? this.packId,
// // // // // //     language: language ?? this.language,
// // // // // //     allowSpicy: allowSpicy ?? this.allowSpicy,
// // // // // //     coverEmoji: coverEmoji,
// // // // // //     lastActiveAt: lastActiveAt ?? this.lastActiveAt,
// // // // // //     createdAt: createdAt,
// // // // // //   );

// // // // // //   @override
// // // // // //   List<Object?> get props => [
// // // // // //     id,
// // // // // //     ownerId,
// // // // // //     name,
// // // // // //     status,
// // // // // //     visibility,
// // // // // //     maxPlayers,
// // // // // //     currentPlayers,
// // // // // //     inviteCode,
// // // // // //     gameType,
// // // // // //     packId,
// // // // // //     language,
// // // // // //     allowSpicy,
// // // // // //   ];
// // // // // // }

// // // // // // // ── RoomMemberEntity ──────────────────────────────────────────────────────────

// // // // // // class RoomMemberEntity extends Equatable {
// // // // // //   const RoomMemberEntity({
// // // // // //     required this.userId,
// // // // // //     required this.displayName,
// // // // // //     this.avatarUrl,
// // // // // //     required this.seatOrder,
// // // // // //     required this.isReady,
// // // // // //     required this.isOwner,
// // // // // //     required this.isModerator,
// // // // // //     this.isSpectator = false,
// // // // // //     this.isMuted = false,
// // // // // //     this.isDisconnected = false,
// // // // // //     this.isAway = false,
// // // // // //     this.leftDefinitively = false,
// // // // // //     this.joinedAt,
// // // // // //   });

// // // // // //   final String userId;
// // // // // //   final String displayName;
// // // // // //   final String? avatarUrl;
// // // // // //   final int seatOrder;
// // // // // //   final bool isReady;
// // // // // //   final bool isOwner;
// // // // // //   final bool isModerator;
// // // // // //   final bool isSpectator;
// // // // // //   final bool isMuted;
// // // // // //   final bool isDisconnected;
// // // // // //   // True if this member picked "I'll Return" — seat preserved, should see a
// // // // // //   // "continue playing" popup next time they open this room.
// // // // // //   final bool isAway;
// // // // // //   // True if this member picked "Leave for Good" — never show rejoin popup.
// // // // // //   final bool leftDefinitively;
// // // // // //   final DateTime? joinedAt;

// // // // // //   bool get canModerate => isOwner || isModerator;
// // // // // //   bool get isActive => !isDisconnected;

// // // // // //   // Should this member see a "continue playing" popup when entering the room?
// // // // // //   bool get shouldOfferRejoin => isAway && !leftDefinitively;

// // // // // //   String get displayRole {
// // // // // //     if (isOwner) return 'Owner';
// // // // // //     if (isModerator) return 'Mod';
// // // // // //     if (isSpectator) return 'Spectator';
// // // // // //     return '';
// // // // // //   }

// // // // // //   RoomMemberEntity copyWith({
// // // // // //     bool? isReady,
// // // // // //     bool? isOwner,
// // // // // //     bool? isModerator,
// // // // // //     bool? isSpectator,
// // // // // //     bool? isMuted,
// // // // // //     bool? isDisconnected,
// // // // // //     bool? isAway,
// // // // // //     bool? leftDefinitively,
// // // // // //   }) => RoomMemberEntity(
// // // // // //     userId: userId,
// // // // // //     displayName: displayName,
// // // // // //     avatarUrl: avatarUrl,
// // // // // //     seatOrder: seatOrder,
// // // // // //     isReady: isReady ?? this.isReady,
// // // // // //     isOwner: isOwner ?? this.isOwner,
// // // // // //     isModerator: isModerator ?? this.isModerator,
// // // // // //     isSpectator: isSpectator ?? this.isSpectator,
// // // // // //     isMuted: isMuted ?? this.isMuted,
// // // // // //     isDisconnected: isDisconnected ?? this.isDisconnected,
// // // // // //     isAway: isAway ?? this.isAway,
// // // // // //     leftDefinitively: leftDefinitively ?? this.leftDefinitively,
// // // // // //     joinedAt: joinedAt,
// // // // // //   );

// // // // // //   @override
// // // // // //   List<Object?> get props => [
// // // // // //     userId,
// // // // // //     displayName,
// // // // // //     seatOrder,
// // // // // //     isReady,
// // // // // //     isOwner,
// // // // // //     isModerator,
// // // // // //     isSpectator,
// // // // // //     isMuted,
// // // // // //     isDisconnected,
// // // // // //     isAway,
// // // // // //     leftDefinitively,
// // // // // //   ];
// // // // // // }

// // // // // // // ── ChatMessageEntity ─────────────────────────────────────────────────────────

// // // // // // enum ChatMessageType { user, system }

// // // // // // class ChatMessageEntity extends Equatable {
// // // // // //   const ChatMessageEntity({
// // // // // //     required this.id,
// // // // // //     required this.roomId,
// // // // // //     required this.userId,
// // // // // //     required this.displayName,
// // // // // //     this.avatarUrl,
// // // // // //     required this.content,
// // // // // //     required this.createdAt,
// // // // // //     this.isDeleted = false,
// // // // // //     this.isOptimistic = false,
// // // // // //     this.type = ChatMessageType.user,
// // // // // //   });

// // // // // //   final String id;
// // // // // //   final String roomId;
// // // // // //   final String userId;
// // // // // //   final String displayName;
// // // // // //   final String? avatarUrl;
// // // // // //   final String content;
// // // // // //   final DateTime createdAt;
// // // // // //   final bool isDeleted;
// // // // // //   final bool isOptimistic; // client-only: not yet confirmed by server
// // // // // //   final ChatMessageType type;

// // // // // //   bool get isSystem => type == ChatMessageType.system;

// // // // // //   @override
// // // // // //   List<Object?> get props => [id, roomId, userId, content, createdAt];
// // // // // // }

// // // // // // // ── RoomSettingsEntity ────────────────────────────────────────────────────────

// // // // // // class RoomSettingsEntity extends Equatable {
// // // // // //   const RoomSettingsEntity({
// // // // // //     this.turnTimerSeconds = 60,
// // // // // //     this.allowSkip = true,
// // // // // //     this.maxRounds = 10,
// // // // // //     this.chatEnabled = true,
// // // // // //     this.allowSpectators = false,
// // // // // //     this.allowSpicy = false,
// // // // // //     this.requiresApproval = false,
// // // // // //   });

// // // // // //   final int turnTimerSeconds;
// // // // // //   final bool allowSkip;
// // // // // //   final int maxRounds;
// // // // // //   final bool chatEnabled;
// // // // // //   final bool allowSpectators;
// // // // // //   final bool allowSpicy;
// // // // // //   final bool requiresApproval;

// // // // // //   RoomSettingsEntity copyWith({
// // // // // //     int? turnTimerSeconds,
// // // // // //     bool? allowSkip,
// // // // // //     int? maxRounds,
// // // // // //     bool? chatEnabled,
// // // // // //     bool? allowSpectators,
// // // // // //     bool? allowSpicy,
// // // // // //     bool? requiresApproval,
// // // // // //   }) => RoomSettingsEntity(
// // // // // //     turnTimerSeconds: turnTimerSeconds ?? this.turnTimerSeconds,
// // // // // //     allowSkip: allowSkip ?? this.allowSkip,
// // // // // //     maxRounds: maxRounds ?? this.maxRounds,
// // // // // //     chatEnabled: chatEnabled ?? this.chatEnabled,
// // // // // //     allowSpectators: allowSpectators ?? this.allowSpectators,
// // // // // //     allowSpicy: allowSpicy ?? this.allowSpicy,
// // // // // //     requiresApproval: requiresApproval ?? this.requiresApproval,
// // // // // //   );

// // // // // //   Map<String, dynamic> toMap() => {
// // // // // //     'turn_timer_secs': turnTimerSeconds,
// // // // // //     'allow_skip': allowSkip,
// // // // // //     'max_rounds': maxRounds,
// // // // // //     'chat_enabled': chatEnabled,
// // // // // //     'allow_spectators': allowSpectators,
// // // // // //     'allow_spicy': allowSpicy,
// // // // // //     'requires_approval': requiresApproval,
// // // // // //   };

// // // // // //   static RoomSettingsEntity fromMap(Map<String, dynamic> m) =>
// // // // // //       RoomSettingsEntity(
// // // // // //         turnTimerSeconds: m['turn_timer_secs'] as int? ?? 60,
// // // // // //         allowSkip: m['allow_skip'] as bool? ?? true,
// // // // // //         maxRounds: m['max_rounds'] as int? ?? 10,
// // // // // //         chatEnabled: m['chat_enabled'] as bool? ?? true,
// // // // // //         allowSpectators: m['allow_spectators'] as bool? ?? false,
// // // // // //         allowSpicy: m['allow_spicy'] as bool? ?? false,
// // // // // //         requiresApproval: m['requires_approval'] as bool? ?? false,
// // // // // //       );

// // // // // //   @override
// // // // // //   List<Object?> get props => [
// // // // // //     turnTimerSeconds,
// // // // // //     allowSkip,
// // // // // //     maxRounds,
// // // // // //     chatEnabled,
// // // // // //     allowSpectators,
// // // // // //     allowSpicy,
// // // // // //     requiresApproval,
// // // // // //   ];
// // // // // // }

// // // // // // // ── ModerationAction ──────────────────────────────────────────────────────────

// // // // // // enum ModerationActionType {
// // // // // //   kick,
// // // // // //   mute,
// // // // // //   unmute,
// // // // // //   ban,
// // // // // //   unban,
// // // // // //   transferOwnership,
// // // // // //   pauseGame,
// // // // // //   resumeGame,
// // // // // // }

// // // // // // class ModerationAction {
// // // // // //   const ModerationAction({
// // // // // //     required this.type,
// // // // // //     required this.actorId,
// // // // // //     this.targetUserId,
// // // // // //     this.reason,
// // // // // //     this.durationSeconds,
// // // // // //     this.metadata = const {},
// // // // // //   });

// // // // // //   final ModerationActionType type;
// // // // // //   final String actorId;
// // // // // //   final String? targetUserId;
// // // // // //   final String? reason;
// // // // // //   final int? durationSeconds;
// // // // // //   final Map<String, dynamic> metadata;

// // // // // //   Map<String, dynamic> toMap() => {
// // // // // //     'type': type.name,
// // // // // //     'actor_id': actorId,
// // // // // //     'target_user_id': targetUserId,
// // // // // //     'reason': reason,
// // // // // //     'duration_seconds': durationSeconds,
// // // // // //     ...metadata,
// // // // // //   };

// // // // // //   static ModerationAction fromMap(Map<String, dynamic> m) => ModerationAction(
// // // // // //     type: ModerationActionType.values.firstWhere(
// // // // // //       (t) => t.name == m['type'],
// // // // // //       orElse: () => ModerationActionType.kick,
// // // // // //     ),
// // // // // //     actorId: m['actor_id'] as String? ?? '',
// // // // // //     targetUserId: m['target_user_id'] as String?,
// // // // // //     reason: m['reason'] as String?,
// // // // // //     durationSeconds: m['duration_seconds'] as int?,
// // // // // //   );
// // // // // // }

// // // // // import 'package:equatable/equatable.dart';
// // // // // import '../../games/engine/base_game_engine.dart';

// // // // // // ── Enums ─────────────────────────────────────────────────────────────────────

// // // // // enum RoomStatus {
// // // // //   waiting,
// // // // //   starting,
// // // // //   inGame,
// // // // //   paused,
// // // // //   ended,
// // // // //   closed;

// // // // //   static RoomStatus fromString(String s) => switch (s) {
// // // // //     'starting' => starting,
// // // // //     'in_game' => inGame,
// // // // //     'paused' => paused,
// // // // //     'ended' => ended,
// // // // //     'closed' => closed,
// // // // //     _ => waiting,
// // // // //   };

// // // // //   String toDbString() => switch (this) {
// // // // //     starting => 'starting',
// // // // //     inGame => 'in_game',
// // // // //     paused => 'paused',
// // // // //     ended => 'ended',
// // // // //     closed => 'closed',
// // // // //     waiting => 'waiting',
// // // // //   };
// // // // // }

// // // // // enum RoomVisibility {
// // // // //   public,
// // // // //   private;

// // // // //   static RoomVisibility fromString(String s) =>
// // // // //       s == 'private' ? private : public;
// // // // // }

// // // // // enum MemberRole { player, moderator, spectator }

// // // // // // ── RoomEntity ────────────────────────────────────────────────────────────────

// // // // // class RoomEntity extends Equatable {
// // // // //   const RoomEntity({
// // // // //     required this.id,
// // // // //     required this.ownerId,
// // // // //     required this.name,
// // // // //     required this.status,
// // // // //     required this.visibility,
// // // // //     required this.maxPlayers,
// // // // //     required this.currentPlayers,
// // // // //     this.inviteCode,
// // // // //     this.gameType,
// // // // //     this.packId,
// // // // //     this.language = 'en',
// // // // //     this.allowSpicy = false,
// // // // //     this.coverEmoji = '🎮',
// // // // //     this.lastActiveAt,
// // // // //     this.createdAt,
// // // // //   });

// // // // //   final String id;
// // // // //   final String ownerId;
// // // // //   final String name;
// // // // //   final RoomStatus status;
// // // // //   final RoomVisibility visibility;
// // // // //   final int maxPlayers;
// // // // //   final int currentPlayers;
// // // // //   final String? inviteCode;
// // // // //   final GameType? gameType;
// // // // //   final String? packId;
// // // // //   final String language;
// // // // //   final bool allowSpicy;
// // // // //   final String coverEmoji;
// // // // //   final DateTime? lastActiveAt;
// // // // //   final DateTime? createdAt;

// // // // //   bool get isFull => currentPlayers >= maxPlayers;
// // // // //   bool get isWaiting => status == RoomStatus.waiting;
// // // // //   bool get isInGame => status == RoomStatus.inGame;
// // // // //   bool get isPaused => status == RoomStatus.paused;
// // // // //   bool get isActive =>
// // // // //       status == RoomStatus.waiting || status == RoomStatus.inGame;
// // // // //   bool get canJoin => !isFull && isActive;
// // // // //   bool get isPrivate => visibility == RoomVisibility.private;

// // // // //   RoomEntity copyWith({
// // // // //     String? ownerId,
// // // // //     String? name,
// // // // //     RoomStatus? status,
// // // // //     int? currentPlayers,
// // // // //     GameType? gameType,
// // // // //     String? packId,
// // // // //     String? language,
// // // // //     bool? allowSpicy,
// // // // //     DateTime? lastActiveAt,
// // // // //   }) => RoomEntity(
// // // // //     id: id,
// // // // //     ownerId: ownerId ?? this.ownerId,
// // // // //     name: name ?? this.name,
// // // // //     status: status ?? this.status,
// // // // //     visibility: visibility,
// // // // //     maxPlayers: maxPlayers,
// // // // //     currentPlayers: currentPlayers ?? this.currentPlayers,
// // // // //     inviteCode: inviteCode,
// // // // //     gameType: gameType ?? this.gameType,
// // // // //     packId: packId ?? this.packId,
// // // // //     language: language ?? this.language,
// // // // //     allowSpicy: allowSpicy ?? this.allowSpicy,
// // // // //     coverEmoji: coverEmoji,
// // // // //     lastActiveAt: lastActiveAt ?? this.lastActiveAt,
// // // // //     createdAt: createdAt,
// // // // //   );

// // // // //   @override
// // // // //   List<Object?> get props => [
// // // // //     id,
// // // // //     ownerId,
// // // // //     name,
// // // // //     status,
// // // // //     visibility,
// // // // //     maxPlayers,
// // // // //     currentPlayers,
// // // // //     inviteCode,
// // // // //     gameType,
// // // // //     packId,
// // // // //     language,
// // // // //     allowSpicy,
// // // // //   ];
// // // // // }

// // // // // // ── RoomMemberEntity ──────────────────────────────────────────────────────────

// // // // // class RoomMemberEntity extends Equatable {
// // // // //   const RoomMemberEntity({
// // // // //     required this.userId,
// // // // //     required this.displayName,
// // // // //     this.avatarUrl,
// // // // //     required this.seatOrder,
// // // // //     required this.isReady,
// // // // //     required this.isOwner,
// // // // //     required this.isModerator,
// // // // //     this.isSpectator = false,
// // // // //     this.isMuted = false,
// // // // //     this.isDisconnected = false,
// // // // //     this.isAway = false,
// // // // //     this.leftDefinitively = false,
// // // // //     this.joinedAt,
// // // // //   });

// // // // //   final String userId;
// // // // //   final String displayName;
// // // // //   final String? avatarUrl;
// // // // //   final int seatOrder;
// // // // //   final bool isReady;
// // // // //   final bool isOwner;
// // // // //   final bool isModerator;
// // // // //   final bool isSpectator;
// // // // //   final bool isMuted;
// // // // //   final bool isDisconnected;
// // // // //   // True if this member picked "I'll Return" — seat preserved, should see a
// // // // //   // "continue playing" popup next time they open this room.
// // // // //   final bool isAway;
// // // // //   // True if this member picked "Leave for Good" — never show rejoin popup.
// // // // //   final bool leftDefinitively;
// // // // //   final DateTime? joinedAt;

// // // // //   bool get canModerate => isOwner || isModerator;
// // // // //   bool get isActive => !isDisconnected;

// // // // //   // Should this member see a "continue playing" popup when entering the room?
// // // // //   bool get shouldOfferRejoin => isAway && !leftDefinitively;

// // // // //   String get displayRole {
// // // // //     if (isOwner) return 'Owner';
// // // // //     if (isModerator) return 'Mod';
// // // // //     if (isSpectator) return 'Spectator';
// // // // //     return '';
// // // // //   }

// // // // //   RoomMemberEntity copyWith({
// // // // //     bool? isReady,
// // // // //     bool? isOwner,
// // // // //     bool? isModerator,
// // // // //     bool? isSpectator,
// // // // //     bool? isMuted,
// // // // //     bool? isDisconnected,
// // // // //     bool? isAway,
// // // // //     bool? leftDefinitively,
// // // // //   }) => RoomMemberEntity(
// // // // //     userId: userId,
// // // // //     displayName: displayName,
// // // // //     avatarUrl: avatarUrl,
// // // // //     seatOrder: seatOrder,
// // // // //     isReady: isReady ?? this.isReady,
// // // // //     isOwner: isOwner ?? this.isOwner,
// // // // //     isModerator: isModerator ?? this.isModerator,
// // // // //     isSpectator: isSpectator ?? this.isSpectator,
// // // // //     isMuted: isMuted ?? this.isMuted,
// // // // //     isDisconnected: isDisconnected ?? this.isDisconnected,
// // // // //     isAway: isAway ?? this.isAway,
// // // // //     leftDefinitively: leftDefinitively ?? this.leftDefinitively,
// // // // //     joinedAt: joinedAt,
// // // // //   );

// // // // //   @override
// // // // //   List<Object?> get props => [
// // // // //     userId,
// // // // //     displayName,
// // // // //     seatOrder,
// // // // //     isReady,
// // // // //     isOwner,
// // // // //     isModerator,
// // // // //     isSpectator,
// // // // //     isMuted,
// // // // //     isDisconnected,
// // // // //     isAway,
// // // // //     leftDefinitively,
// // // // //   ];
// // // // // }

// // // // // // ── ChatMessageEntity ─────────────────────────────────────────────────────────

// // // // // enum ChatMessageType { user, system }

// // // // // class ChatMessageEntity extends Equatable {
// // // // //   const ChatMessageEntity({
// // // // //     required this.id,
// // // // //     required this.roomId,
// // // // //     required this.userId,
// // // // //     required this.displayName,
// // // // //     this.avatarUrl,
// // // // //     required this.content,
// // // // //     required this.createdAt,
// // // // //     this.isDeleted = false,
// // // // //     this.isOptimistic = false,
// // // // //     this.type = ChatMessageType.user,
// // // // //   });

// // // // //   final String id;
// // // // //   final String roomId;
// // // // //   final String userId;
// // // // //   final String displayName;
// // // // //   final String? avatarUrl;
// // // // //   final String content;
// // // // //   final DateTime createdAt;
// // // // //   final bool isDeleted;
// // // // //   final bool isOptimistic; // client-only: not yet confirmed by server
// // // // //   final ChatMessageType type;

// // // // //   bool get isSystem => type == ChatMessageType.system;

// // // // //   @override
// // // // //   List<Object?> get props => [id, roomId, userId, content, createdAt];
// // // // // }

// // // // // // ── RoomSettingsEntity ────────────────────────────────────────────────────────

// // // // // class RoomSettingsEntity extends Equatable {
// // // // //   const RoomSettingsEntity({
// // // // //     this.turnTimerSeconds = 60,
// // // // //     this.allowSkip = true,
// // // // //     this.maxRounds = 10,
// // // // //     this.chatEnabled = true,
// // // // //     this.allowSpectators = false,
// // // // //     this.allowSpicy = false,
// // // // //     this.requiresApproval = false,
// // // // //   });

// // // // //   final int turnTimerSeconds;
// // // // //   final bool allowSkip;
// // // // //   final int maxRounds;
// // // // //   final bool chatEnabled;
// // // // //   final bool allowSpectators;
// // // // //   final bool allowSpicy;
// // // // //   final bool requiresApproval;

// // // // //   RoomSettingsEntity copyWith({
// // // // //     int? turnTimerSeconds,
// // // // //     bool? allowSkip,
// // // // //     int? maxRounds,
// // // // //     bool? chatEnabled,
// // // // //     bool? allowSpectators,
// // // // //     bool? allowSpicy,
// // // // //     bool? requiresApproval,
// // // // //   }) => RoomSettingsEntity(
// // // // //     turnTimerSeconds: turnTimerSeconds ?? this.turnTimerSeconds,
// // // // //     allowSkip: allowSkip ?? this.allowSkip,
// // // // //     maxRounds: maxRounds ?? this.maxRounds,
// // // // //     chatEnabled: chatEnabled ?? this.chatEnabled,
// // // // //     allowSpectators: allowSpectators ?? this.allowSpectators,
// // // // //     allowSpicy: allowSpicy ?? this.allowSpicy,
// // // // //     requiresApproval: requiresApproval ?? this.requiresApproval,
// // // // //   );

// // // // //   Map<String, dynamic> toMap() => {
// // // // //     'turn_timer_secs': turnTimerSeconds,
// // // // //     'allow_skip': allowSkip,
// // // // //     'max_rounds': maxRounds,
// // // // //     'chat_enabled': chatEnabled,
// // // // //     'allow_spectators': allowSpectators,
// // // // //     'allow_spicy': allowSpicy,
// // // // //     'requires_approval': requiresApproval,
// // // // //   };

// // // // //   static RoomSettingsEntity fromMap(Map<String, dynamic> m) =>
// // // // //       RoomSettingsEntity(
// // // // //         turnTimerSeconds: m['turn_timer_secs'] as int? ?? 60,
// // // // //         allowSkip: m['allow_skip'] as bool? ?? true,
// // // // //         maxRounds: m['max_rounds'] as int? ?? 10,
// // // // //         chatEnabled: m['chat_enabled'] as bool? ?? true,
// // // // //         allowSpectators: m['allow_spectators'] as bool? ?? false,
// // // // //         allowSpicy: m['allow_spicy'] as bool? ?? false,
// // // // //         requiresApproval: m['requires_approval'] as bool? ?? false,
// // // // //       );

// // // // //   @override
// // // // //   List<Object?> get props => [
// // // // //     turnTimerSeconds,
// // // // //     allowSkip,
// // // // //     maxRounds,
// // // // //     chatEnabled,
// // // // //     allowSpectators,
// // // // //     allowSpicy,
// // // // //     requiresApproval,
// // // // //   ];
// // // // // }

// // // // // // ── ModerationAction ──────────────────────────────────────────────────────────

// // // // // enum ModerationActionType {
// // // // //   kick,
// // // // //   mute,
// // // // //   unmute,
// // // // //   ban,
// // // // //   unban,
// // // // //   transferOwnership,
// // // // //   pauseGame,
// // // // //   resumeGame,
// // // // // }

// // // // // class ModerationAction {
// // // // //   const ModerationAction({
// // // // //     required this.type,
// // // // //     required this.actorId,
// // // // //     this.targetUserId,
// // // // //     this.reason,
// // // // //     this.durationSeconds,
// // // // //     this.metadata = const {},
// // // // //   });

// // // // //   final ModerationActionType type;
// // // // //   final String actorId;
// // // // //   final String? targetUserId;
// // // // //   final String? reason;
// // // // //   final int? durationSeconds;
// // // // //   final Map<String, dynamic> metadata;

// // // // //   Map<String, dynamic> toMap() => {
// // // // //     'type': type.name,
// // // // //     'actor_id': actorId,
// // // // //     'target_user_id': targetUserId,
// // // // //     'reason': reason,
// // // // //     'duration_seconds': durationSeconds,
// // // // //     ...metadata,
// // // // //   };

// // // // //   static ModerationAction fromMap(Map<String, dynamic> m) => ModerationAction(
// // // // //     type: ModerationActionType.values.firstWhere(
// // // // //       (t) => t.name == m['type'],
// // // // //       orElse: () => ModerationActionType.kick,
// // // // //     ),
// // // // //     actorId: m['actor_id'] as String? ?? '',
// // // // //     targetUserId: m['target_user_id'] as String?,
// // // // //     reason: m['reason'] as String?,
// // // // //     durationSeconds: m['duration_seconds'] as int?,
// // // // //   );
// // // // // }

// // // // import 'package:equatable/equatable.dart';
// // // // import '../../games/engine/base_game_engine.dart';

// // // // // ── Enums ─────────────────────────────────────────────────────────────────────

// // // // enum RoomStatus {
// // // //   waiting,
// // // //   starting,
// // // //   inGame,
// // // //   paused,
// // // //   ended,
// // // //   closed;

// // // //   static RoomStatus fromString(String s) => switch (s) {
// // // //     'starting' => starting,
// // // //     'in_game' => inGame,
// // // //     'paused' => paused,
// // // //     'ended' => ended,
// // // //     'closed' => closed,
// // // //     _ => waiting,
// // // //   };

// // // //   String toDbString() => switch (this) {
// // // //     starting => 'starting',
// // // //     inGame => 'in_game',
// // // //     paused => 'paused',
// // // //     ended => 'ended',
// // // //     closed => 'closed',
// // // //     waiting => 'waiting',
// // // //   };
// // // // }

// // // // enum RoomVisibility {
// // // //   public,
// // // //   private;

// // // //   static RoomVisibility fromString(String s) =>
// // // //       s == 'private' ? private : public;
// // // // }

// // // // enum MemberRole { player, moderator, spectator }

// // // // // ── RoomEntity ────────────────────────────────────────────────────────────────

// // // // class RoomEntity extends Equatable {
// // // //   const RoomEntity({
// // // //     required this.id,
// // // //     required this.ownerId,
// // // //     required this.name,
// // // //     required this.status,
// // // //     required this.visibility,
// // // //     required this.maxPlayers,
// // // //     required this.currentPlayers,
// // // //     this.inviteCode,
// // // //     this.gameType,
// // // //     this.packId,
// // // //     this.language = 'en',
// // // //     this.allowSpicy = false,
// // // //     this.coverEmoji = '🎮',
// // // //     this.lastActiveAt,
// // // //     this.createdAt,
// // // //   });

// // // //   final String id;
// // // //   final String ownerId;
// // // //   final String name;
// // // //   final RoomStatus status;
// // // //   final RoomVisibility visibility;
// // // //   final int maxPlayers;
// // // //   final int currentPlayers;
// // // //   final String? inviteCode;
// // // //   final GameType? gameType;
// // // //   final String? packId;
// // // //   final String language;
// // // //   final bool allowSpicy;
// // // //   final String coverEmoji;
// // // //   final DateTime? lastActiveAt;
// // // //   final DateTime? createdAt;

// // // //   bool get isFull => currentPlayers >= maxPlayers;
// // // //   bool get isWaiting => status == RoomStatus.waiting;
// // // //   bool get isInGame => status == RoomStatus.inGame;
// // // //   bool get isPaused => status == RoomStatus.paused;
// // // //   bool get isActive =>
// // // //       status == RoomStatus.waiting || status == RoomStatus.inGame;
// // // //   bool get canJoin => !isFull && isActive;
// // // //   bool get isPrivate => visibility == RoomVisibility.private;

// // // //   RoomEntity copyWith({
// // // //     String? ownerId,
// // // //     String? name,
// // // //     RoomStatus? status,
// // // //     int? currentPlayers,
// // // //     GameType? gameType,
// // // //     String? packId,
// // // //     String? language,
// // // //     bool? allowSpicy,
// // // //     DateTime? lastActiveAt,
// // // //   }) => RoomEntity(
// // // //     id: id,
// // // //     ownerId: ownerId ?? this.ownerId,
// // // //     name: name ?? this.name,
// // // //     status: status ?? this.status,
// // // //     visibility: visibility,
// // // //     maxPlayers: maxPlayers,
// // // //     currentPlayers: currentPlayers ?? this.currentPlayers,
// // // //     inviteCode: inviteCode,
// // // //     gameType: gameType ?? this.gameType,
// // // //     packId: packId ?? this.packId,
// // // //     language: language ?? this.language,
// // // //     allowSpicy: allowSpicy ?? this.allowSpicy,
// // // //     coverEmoji: coverEmoji,
// // // //     lastActiveAt: lastActiveAt ?? this.lastActiveAt,
// // // //     createdAt: createdAt,
// // // //   );

// // // //   @override
// // // //   List<Object?> get props => [
// // // //     id,
// // // //     ownerId,
// // // //     name,
// // // //     status,
// // // //     visibility,
// // // //     maxPlayers,
// // // //     currentPlayers,
// // // //     inviteCode,
// // // //     gameType,
// // // //     packId,
// // // //     language,
// // // //     allowSpicy,
// // // //   ];
// // // // }

// // // // // ── RoomMemberEntity ──────────────────────────────────────────────────────────

// // // // class RoomMemberEntity extends Equatable {
// // // //   const RoomMemberEntity({
// // // //     required this.userId,
// // // //     required this.displayName,
// // // //     this.avatarUrl,
// // // //     required this.seatOrder,
// // // //     required this.isReady,
// // // //     required this.isOwner,
// // // //     required this.isModerator,
// // // //     this.isSpectator = false,
// // // //     this.isMuted = false,
// // // //     this.isDisconnected = false,
// // // //     this.isAway = false,
// // // //     this.leftDefinitively = false,
// // // //     this.joinedAt,
// // // //   });

// // // //   final String userId;
// // // //   final String displayName;
// // // //   final String? avatarUrl;
// // // //   final int seatOrder;
// // // //   final bool isReady;
// // // //   final bool isOwner;
// // // //   final bool isModerator;
// // // //   final bool isSpectator;
// // // //   final bool isMuted;
// // // //   final bool isDisconnected;
// // // //   // True if this member picked "I'll Return" — seat preserved, should see a
// // // //   // "continue playing" popup next time they open this room.
// // // //   final bool isAway;
// // // //   // True if this member picked "Leave for Good" — never show rejoin popup.
// // // //   final bool leftDefinitively;
// // // //   final DateTime? joinedAt;

// // // //   bool get canModerate => isOwner || isModerator;
// // // //   bool get isActive => !isDisconnected;

// // // //   // Should this member see a "continue playing" popup when entering the room?
// // // //   bool get shouldOfferRejoin => isAway && !leftDefinitively;

// // // //   String get displayRole {
// // // //     if (isOwner) return 'Owner';
// // // //     if (isModerator) return 'Mod';
// // // //     if (isSpectator) return 'Spectator';
// // // //     return '';
// // // //   }

// // // //   RoomMemberEntity copyWith({
// // // //     bool? isReady,
// // // //     bool? isOwner,
// // // //     bool? isModerator,
// // // //     bool? isSpectator,
// // // //     bool? isMuted,
// // // //     bool? isDisconnected,
// // // //     bool? isAway,
// // // //     bool? leftDefinitively,
// // // //   }) => RoomMemberEntity(
// // // //     userId: userId,
// // // //     displayName: displayName,
// // // //     avatarUrl: avatarUrl,
// // // //     seatOrder: seatOrder,
// // // //     isReady: isReady ?? this.isReady,
// // // //     isOwner: isOwner ?? this.isOwner,
// // // //     isModerator: isModerator ?? this.isModerator,
// // // //     isSpectator: isSpectator ?? this.isSpectator,
// // // //     isMuted: isMuted ?? this.isMuted,
// // // //     isDisconnected: isDisconnected ?? this.isDisconnected,
// // // //     isAway: isAway ?? this.isAway,
// // // //     leftDefinitively: leftDefinitively ?? this.leftDefinitively,
// // // //     joinedAt: joinedAt,
// // // //   );

// // // //   @override
// // // //   List<Object?> get props => [
// // // //     userId,
// // // //     displayName,
// // // //     seatOrder,
// // // //     isReady,
// // // //     isOwner,
// // // //     isModerator,
// // // //     isSpectator,
// // // //     isMuted,
// // // //     isDisconnected,
// // // //     isAway,
// // // //     leftDefinitively,
// // // //   ];
// // // // }

// // // // // ── ChatMessageEntity ─────────────────────────────────────────────────────────

// // // // enum ChatMessageType { user, system }

// // // // class ChatMessageEntity extends Equatable {
// // // //   const ChatMessageEntity({
// // // //     required this.id,
// // // //     required this.roomId,
// // // //     required this.userId,
// // // //     required this.displayName,
// // // //     this.avatarUrl,
// // // //     required this.content,
// // // //     required this.createdAt,
// // // //     this.isDeleted = false,
// // // //     this.isOptimistic = false,
// // // //     this.type = ChatMessageType.user,
// // // //     this.replyToId,
// // // //     this.replyToContent,
// // // //     this.replyToDisplayName,
// // // //   });

// // // //   final String id;
// // // //   final String roomId;
// // // //   final String userId;
// // // //   final String displayName;
// // // //   final String? avatarUrl;
// // // //   final String content;
// // // //   final DateTime createdAt;
// // // //   final bool isDeleted;
// // // //   final bool isOptimistic; // client-only: not yet confirmed by server
// // // //   final ChatMessageType type;
// // // //   // WhatsApp-style reply — denormalized snippet of the original message so
// // // //   // it can render without a join, and still shows something if the
// // // //   // original is later deleted.
// // // //   final String? replyToId;
// // // //   final String? replyToContent;
// // // //   final String? replyToDisplayName;

// // // //   bool get isSystem => type == ChatMessageType.system;
// // // //   bool get isReply => replyToId != null;

// // // //   @override
// // // //   List<Object?> get props => [id, roomId, userId, content, createdAt];
// // // // }

// // // // // ── RoomSettingsEntity ────────────────────────────────────────────────────────

// // // // class RoomSettingsEntity extends Equatable {
// // // //   const RoomSettingsEntity({
// // // //     this.turnTimerSeconds = 60,
// // // //     this.allowSkip = true,
// // // //     this.maxRounds = 10,
// // // //     this.chatEnabled = true,
// // // //     this.allowSpectators = false,
// // // //     this.allowSpicy = false,
// // // //     this.requiresApproval = false,
// // // //   });

// // // //   final int turnTimerSeconds;
// // // //   final bool allowSkip;
// // // //   final int maxRounds;
// // // //   final bool chatEnabled;
// // // //   final bool allowSpectators;
// // // //   final bool allowSpicy;
// // // //   final bool requiresApproval;

// // // //   RoomSettingsEntity copyWith({
// // // //     int? turnTimerSeconds,
// // // //     bool? allowSkip,
// // // //     int? maxRounds,
// // // //     bool? chatEnabled,
// // // //     bool? allowSpectators,
// // // //     bool? allowSpicy,
// // // //     bool? requiresApproval,
// // // //   }) => RoomSettingsEntity(
// // // //     turnTimerSeconds: turnTimerSeconds ?? this.turnTimerSeconds,
// // // //     allowSkip: allowSkip ?? this.allowSkip,
// // // //     maxRounds: maxRounds ?? this.maxRounds,
// // // //     chatEnabled: chatEnabled ?? this.chatEnabled,
// // // //     allowSpectators: allowSpectators ?? this.allowSpectators,
// // // //     allowSpicy: allowSpicy ?? this.allowSpicy,
// // // //     requiresApproval: requiresApproval ?? this.requiresApproval,
// // // //   );

// // // //   Map<String, dynamic> toMap() => {
// // // //     'turn_timer_secs': turnTimerSeconds,
// // // //     'allow_skip': allowSkip,
// // // //     'max_rounds': maxRounds,
// // // //     'chat_enabled': chatEnabled,
// // // //     'allow_spectators': allowSpectators,
// // // //     'allow_spicy': allowSpicy,
// // // //     'requires_approval': requiresApproval,
// // // //   };

// // // //   static RoomSettingsEntity fromMap(Map<String, dynamic> m) =>
// // // //       RoomSettingsEntity(
// // // //         turnTimerSeconds: m['turn_timer_secs'] as int? ?? 60,
// // // //         allowSkip: m['allow_skip'] as bool? ?? true,
// // // //         maxRounds: m['max_rounds'] as int? ?? 10,
// // // //         chatEnabled: m['chat_enabled'] as bool? ?? true,
// // // //         allowSpectators: m['allow_spectators'] as bool? ?? false,
// // // //         allowSpicy: m['allow_spicy'] as bool? ?? false,
// // // //         requiresApproval: m['requires_approval'] as bool? ?? false,
// // // //       );

// // // //   @override
// // // //   List<Object?> get props => [
// // // //     turnTimerSeconds,
// // // //     allowSkip,
// // // //     maxRounds,
// // // //     chatEnabled,
// // // //     allowSpectators,
// // // //     allowSpicy,
// // // //     requiresApproval,
// // // //   ];
// // // // }

// // // // // ── ModerationAction ──────────────────────────────────────────────────────────

// // // // enum ModerationActionType {
// // // //   kick,
// // // //   mute,
// // // //   unmute,
// // // //   ban,
// // // //   unban,
// // // //   transferOwnership,
// // // //   pauseGame,
// // // //   resumeGame,
// // // // }

// // // // class ModerationAction {
// // // //   const ModerationAction({
// // // //     required this.type,
// // // //     required this.actorId,
// // // //     this.targetUserId,
// // // //     this.reason,
// // // //     this.durationSeconds,
// // // //     this.metadata = const {},
// // // //   });

// // // //   final ModerationActionType type;
// // // //   final String actorId;
// // // //   final String? targetUserId;
// // // //   final String? reason;
// // // //   final int? durationSeconds;
// // // //   final Map<String, dynamic> metadata;

// // // //   Map<String, dynamic> toMap() => {
// // // //     'type': type.name,
// // // //     'actor_id': actorId,
// // // //     'target_user_id': targetUserId,
// // // //     'reason': reason,
// // // //     'duration_seconds': durationSeconds,
// // // //     ...metadata,
// // // //   };

// // // //   static ModerationAction fromMap(Map<String, dynamic> m) => ModerationAction(
// // // //     type: ModerationActionType.values.firstWhere(
// // // //       (t) => t.name == m['type'],
// // // //       orElse: () => ModerationActionType.kick,
// // // //     ),
// // // //     actorId: m['actor_id'] as String? ?? '',
// // // //     targetUserId: m['target_user_id'] as String?,
// // // //     reason: m['reason'] as String?,
// // // //     durationSeconds: m['duration_seconds'] as int?,
// // // //   );
// // // // }

// // // import 'package:equatable/equatable.dart';
// // // import '../../games/engine/base_game_engine.dart';

// // // // ── Enums ─────────────────────────────────────────────────────────────────────

// // // enum RoomStatus {
// // //   waiting,
// // //   starting,
// // //   inGame,
// // //   paused,
// // //   ended,
// // //   closed;

// // //   static RoomStatus fromString(String s) => switch (s) {
// // //     'starting' => starting,
// // //     'in_game' => inGame,
// // //     'paused' => paused,
// // //     'ended' => ended,
// // //     'closed' => closed,
// // //     _ => waiting,
// // //   };

// // //   String toDbString() => switch (this) {
// // //     starting => 'starting',
// // //     inGame => 'in_game',
// // //     paused => 'paused',
// // //     ended => 'ended',
// // //     closed => 'closed',
// // //     waiting => 'waiting',
// // //   };
// // // }

// // // enum RoomVisibility {
// // //   public,
// // //   private;

// // //   static RoomVisibility fromString(String s) =>
// // //       s == 'private' ? private : public;
// // // }

// // // enum MemberRole { player, moderator, spectator }

// // // // ── RoomEntity ────────────────────────────────────────────────────────────────

// // // class RoomEntity extends Equatable {
// // //   const RoomEntity({
// // //     required this.id,
// // //     required this.ownerId,
// // //     required this.name,
// // //     required this.status,
// // //     required this.visibility,
// // //     required this.maxPlayers,
// // //     required this.currentPlayers,
// // //     this.inviteCode,
// // //     this.gameType,
// // //     this.packId,
// // //     this.language = 'en',
// // //     this.allowSpicy = false,
// // //     this.coverEmoji = '🎮',
// // //     this.lastActiveAt,
// // //     this.createdAt,
// // //   });

// // //   final String id;
// // //   final String ownerId;
// // //   final String name;
// // //   final RoomStatus status;
// // //   final RoomVisibility visibility;
// // //   final int maxPlayers;
// // //   final int currentPlayers;
// // //   final String? inviteCode;
// // //   final GameType? gameType;
// // //   final String? packId;
// // //   final String language;
// // //   final bool allowSpicy;
// // //   final String coverEmoji;
// // //   final DateTime? lastActiveAt;
// // //   final DateTime? createdAt;

// // //   bool get isFull => currentPlayers >= maxPlayers;
// // //   bool get isWaiting => status == RoomStatus.waiting;
// // //   bool get isInGame => status == RoomStatus.inGame;
// // //   bool get isPaused => status == RoomStatus.paused;
// // //   bool get isActive =>
// // //       status == RoomStatus.waiting || status == RoomStatus.inGame;
// // //   bool get canJoin => !isFull && isActive;
// // //   bool get isPrivate => visibility == RoomVisibility.private;

// // //   RoomEntity copyWith({
// // //     String? ownerId,
// // //     String? name,
// // //     RoomStatus? status,
// // //     int? currentPlayers,
// // //     GameType? gameType,
// // //     String? packId,
// // //     String? language,
// // //     bool? allowSpicy,
// // //     DateTime? lastActiveAt,
// // //   }) => RoomEntity(
// // //     id: id,
// // //     ownerId: ownerId ?? this.ownerId,
// // //     name: name ?? this.name,
// // //     status: status ?? this.status,
// // //     visibility: visibility,
// // //     maxPlayers: maxPlayers,
// // //     currentPlayers: currentPlayers ?? this.currentPlayers,
// // //     inviteCode: inviteCode,
// // //     gameType: gameType ?? this.gameType,
// // //     packId: packId ?? this.packId,
// // //     language: language ?? this.language,
// // //     allowSpicy: allowSpicy ?? this.allowSpicy,
// // //     coverEmoji: coverEmoji,
// // //     lastActiveAt: lastActiveAt ?? this.lastActiveAt,
// // //     createdAt: createdAt,
// // //   );

// // //   @override
// // //   List<Object?> get props => [
// // //     id,
// // //     ownerId,
// // //     name,
// // //     status,
// // //     visibility,
// // //     maxPlayers,
// // //     currentPlayers,
// // //     inviteCode,
// // //     gameType,
// // //     packId,
// // //     language,
// // //     allowSpicy,
// // //   ];
// // // }

// // // // ── RoomMemberEntity ──────────────────────────────────────────────────────────

// // // class RoomMemberEntity extends Equatable {
// // //   const RoomMemberEntity({
// // //     required this.userId,
// // //     required this.displayName,
// // //     this.avatarUrl,
// // //     required this.seatOrder,
// // //     required this.isReady,
// // //     required this.isOwner,
// // //     required this.isModerator,
// // //     this.isSpectator = false,
// // //     this.isMuted = false,
// // //     this.isDisconnected = false,
// // //     this.isAway = false,
// // //     this.leftDefinitively = false,
// // //     this.joinedAt,
// // //   });

// // //   final String userId;
// // //   final String displayName;
// // //   final String? avatarUrl;
// // //   final int seatOrder;
// // //   final bool isReady;
// // //   final bool isOwner;
// // //   final bool isModerator;
// // //   final bool isSpectator;
// // //   final bool isMuted;
// // //   final bool isDisconnected;
// // //   // True if this member picked "I'll Return" — seat preserved, should see a
// // //   // "continue playing" popup next time they open this room.
// // //   final bool isAway;
// // //   // True if this member picked "Leave for Good" — never show rejoin popup.
// // //   final bool leftDefinitively;
// // //   final DateTime? joinedAt;

// // //   bool get canModerate => isOwner || isModerator;
// // //   bool get isActive => !isDisconnected;

// // //   // Should this member see a "continue playing" popup when entering the room?
// // //   bool get shouldOfferRejoin => isAway && !leftDefinitively;

// // //   String get displayRole {
// // //     if (isOwner) return 'Owner';
// // //     if (isModerator) return 'Mod';
// // //     if (isSpectator) return 'Spectator';
// // //     return '';
// // //   }

// // //   RoomMemberEntity copyWith({
// // //     bool? isReady,
// // //     bool? isOwner,
// // //     bool? isModerator,
// // //     bool? isSpectator,
// // //     bool? isMuted,
// // //     bool? isDisconnected,
// // //     bool? isAway,
// // //     bool? leftDefinitively,
// // //   }) => RoomMemberEntity(
// // //     userId: userId,
// // //     displayName: displayName,
// // //     avatarUrl: avatarUrl,
// // //     seatOrder: seatOrder,
// // //     isReady: isReady ?? this.isReady,
// // //     isOwner: isOwner ?? this.isOwner,
// // //     isModerator: isModerator ?? this.isModerator,
// // //     isSpectator: isSpectator ?? this.isSpectator,
// // //     isMuted: isMuted ?? this.isMuted,
// // //     isDisconnected: isDisconnected ?? this.isDisconnected,
// // //     isAway: isAway ?? this.isAway,
// // //     leftDefinitively: leftDefinitively ?? this.leftDefinitively,
// // //     joinedAt: joinedAt,
// // //   );

// // //   @override
// // //   List<Object?> get props => [
// // //     userId,
// // //     displayName,
// // //     seatOrder,
// // //     isReady,
// // //     isOwner,
// // //     isModerator,
// // //     isSpectator,
// // //     isMuted,
// // //     isDisconnected,
// // //     isAway,
// // //     leftDefinitively,
// // //   ];
// // // }

// // // // ── ChatMessageEntity ─────────────────────────────────────────────────────────

// // // enum ChatMessageType { user, system }

// // // class ChatMessageEntity extends Equatable {
// // //   const ChatMessageEntity({
// // //     required this.id,
// // //     required this.roomId,
// // //     required this.userId,
// // //     required this.displayName,
// // //     this.avatarUrl,
// // //     required this.content,
// // //     required this.createdAt,
// // //     this.isDeleted = false,
// // //     this.isOptimistic = false,
// // //     this.type = ChatMessageType.user,
// // //     this.replyToId,
// // //     this.replyToContent,
// // //     this.replyToDisplayName,
// // //   });

// // //   final String id;
// // //   final String roomId;
// // //   final String userId;
// // //   final String displayName;
// // //   final String? avatarUrl;
// // //   final String content;
// // //   final DateTime createdAt;
// // //   final bool isDeleted;
// // //   final bool isOptimistic; // client-only: not yet confirmed by server
// // //   final ChatMessageType type;
// // //   // WhatsApp-style reply — denormalized snippet of the original message so
// // //   // it can render without a join, and still shows something if the
// // //   // original is later deleted.
// // //   final String? replyToId;
// // //   final String? replyToContent;
// // //   final String? replyToDisplayName;

// // //   bool get isSystem => type == ChatMessageType.system;
// // //   bool get isReply => replyToId != null;

// // //   @override
// // //   List<Object?> get props => [id, roomId, userId, content, createdAt];
// // // }

// // // // ── RoomSettingsEntity ────────────────────────────────────────────────────────

// // // class RoomSettingsEntity extends Equatable {
// // //   const RoomSettingsEntity({
// // //     this.turnTimerSeconds = 60,
// // //     this.allowSkip = true,
// // //     this.maxRounds = 10,
// // //     this.chatEnabled = true,
// // //     this.allowSpectators = false,
// // //     this.spectatorApprovalRequired = false,
// // //     this.allowSpicy = false,
// // //     this.requiresApproval = false,
// // //   });

// // //   final int turnTimerSeconds;
// // //   final bool allowSkip;
// // //   final int maxRounds;
// // //   final bool chatEnabled;
// // //   final bool allowSpectators;
// // //   // When true: spectators trying to join a game already in progress are
// // //   // queued in spectator_requests and must wait for admin/mod approval
// // //   // before they can see the game. Ignored when allowSpectators is false.
// // //   final bool spectatorApprovalRequired;
// // //   final bool allowSpicy;
// // //   final bool requiresApproval;

// // //   RoomSettingsEntity copyWith({
// // //     int? turnTimerSeconds,
// // //     bool? allowSkip,
// // //     int? maxRounds,
// // //     bool? chatEnabled,
// // //     bool? allowSpectators,
// // //     bool? spectatorApprovalRequired,
// // //     bool? allowSpicy,
// // //     bool? requiresApproval,
// // //   }) => RoomSettingsEntity(
// // //     turnTimerSeconds: turnTimerSeconds ?? this.turnTimerSeconds,
// // //     allowSkip: allowSkip ?? this.allowSkip,
// // //     maxRounds: maxRounds ?? this.maxRounds,
// // //     chatEnabled: chatEnabled ?? this.chatEnabled,
// // //     allowSpectators: allowSpectators ?? this.allowSpectators,
// // //     spectatorApprovalRequired:
// // //         spectatorApprovalRequired ?? this.spectatorApprovalRequired,
// // //     allowSpicy: allowSpicy ?? this.allowSpicy,
// // //     requiresApproval: requiresApproval ?? this.requiresApproval,
// // //   );

// // //   Map<String, dynamic> toMap() => {
// // //     'turn_timer_secs': turnTimerSeconds,
// // //     'allow_skip': allowSkip,
// // //     'max_rounds': maxRounds,
// // //     'chat_enabled': chatEnabled,
// // //     'allow_spectators': allowSpectators,
// // //     'spectator_approval_required': spectatorApprovalRequired,
// // //     'allow_spicy': allowSpicy,
// // //     'requires_approval': requiresApproval,
// // //   };

// // //   static RoomSettingsEntity fromMap(Map<String, dynamic> m) =>
// // //       RoomSettingsEntity(
// // //         turnTimerSeconds: m['turn_timer_secs'] as int? ?? 60,
// // //         allowSkip: m['allow_skip'] as bool? ?? true,
// // //         maxRounds: m['max_rounds'] as int? ?? 10,
// // //         chatEnabled: m['chat_enabled'] as bool? ?? true,
// // //         allowSpectators: m['allow_spectators'] as bool? ?? false,
// // //         spectatorApprovalRequired:
// // //             m['spectator_approval_required'] as bool? ?? false,
// // //         allowSpicy: m['allow_spicy'] as bool? ?? false,
// // //         requiresApproval: m['requires_approval'] as bool? ?? false,
// // //       );

// // //   @override
// // //   List<Object?> get props => [
// // //     turnTimerSeconds,
// // //     allowSkip,
// // //     maxRounds,
// // //     chatEnabled,
// // //     allowSpectators,
// // //     spectatorApprovalRequired,
// // //     allowSpicy,
// // //     requiresApproval,
// // //   ];
// // // }

// // // // ── ModerationAction ──────────────────────────────────────────────────────────

// // // enum ModerationActionType {
// // //   kick,
// // //   mute,
// // //   unmute,
// // //   ban,
// // //   unban,
// // //   transferOwnership,
// // //   pauseGame,
// // //   resumeGame,
// // // }

// // // class ModerationAction {
// // //   const ModerationAction({
// // //     required this.type,
// // //     required this.actorId,
// // //     this.targetUserId,
// // //     this.reason,
// // //     this.durationSeconds,
// // //     this.metadata = const {},
// // //   });

// // //   final ModerationActionType type;
// // //   final String actorId;
// // //   final String? targetUserId;
// // //   final String? reason;
// // //   final int? durationSeconds;
// // //   final Map<String, dynamic> metadata;

// // //   Map<String, dynamic> toMap() => {
// // //     'type': type.name,
// // //     'actor_id': actorId,
// // //     'target_user_id': targetUserId,
// // //     'reason': reason,
// // //     'duration_seconds': durationSeconds,
// // //     ...metadata,
// // //   };

// // //   static ModerationAction fromMap(Map<String, dynamic> m) => ModerationAction(
// // //     type: ModerationActionType.values.firstWhere(
// // //       (t) => t.name == m['type'],
// // //       orElse: () => ModerationActionType.kick,
// // //     ),
// // //     actorId: m['actor_id'] as String? ?? '',
// // //     targetUserId: m['target_user_id'] as String?,
// // //     reason: m['reason'] as String?,
// // //     durationSeconds: m['duration_seconds'] as int?,
// // //   );
// // // }

// // import 'package:equatable/equatable.dart';
// // import '../../games/engine/base_game_engine.dart';

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
// //     String? language,
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
// //     language: language ?? this.language,
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

// // class RoomMemberEntity extends Equatable {
// //   const RoomMemberEntity({
// //     required this.userId,
// //     required this.displayName,
// //     this.avatarUrl,
// //     required this.seatOrder,
// //     required this.isReady,
// //     required this.isOwner,
// //     required this.isModerator,
// //     this.isSpectator = false,
// //     this.isHiddenSpectator = false,
// //     this.isMuted = false,
// //     this.isDisconnected = false,
// //     this.isAway = false,
// //     this.leftDefinitively = false,
// //     this.isPremium = false,
// //     this.premiumTier,
// //     this.joinedAt,
// //   });

// //   final String userId;
// //   final String displayName;
// //   final String? avatarUrl;
// //   final int seatOrder;
// //   final bool isReady;
// //   final bool isOwner;
// //   final bool isModerator;
// //   final bool isSpectator;
// //   final bool isHiddenSpectator;
// //   final bool isMuted;
// //   final bool isDisconnected;
// //   final bool isAway;
// //   final bool leftDefinitively;
// //   final bool isPremium;
// //   final String? premiumTier;
// //   final DateTime? joinedAt;

// //   bool get canModerate => isOwner || isModerator;
// //   bool get isActive => !isDisconnected;
// //   bool get shouldOfferRejoin => isAway && !leftDefinitively;

// //   String get displayRole {
// //     if (isOwner) return 'Owner';
// //     if (isModerator) return 'Mod';
// //     if (isSpectator) return isHiddenSpectator ? 'Hidden' : 'Spectator';
// //     return '';
// //   }

// //   RoomMemberEntity copyWith({
// //     bool? isReady,
// //     bool? isOwner,
// //     bool? isModerator,
// //     bool? isSpectator,
// //     bool? isHiddenSpectator,
// //     bool? isMuted,
// //     bool? isDisconnected,
// //     bool? isAway,
// //     bool? leftDefinitively,
// //     bool? isPremium,
// //     String? premiumTier,
// //   }) => RoomMemberEntity(
// //     userId: userId,
// //     displayName: displayName,
// //     avatarUrl: avatarUrl,
// //     seatOrder: seatOrder,
// //     isReady: isReady ?? this.isReady,
// //     isOwner: isOwner ?? this.isOwner,
// //     isModerator: isModerator ?? this.isModerator,
// //     isSpectator: isSpectator ?? this.isSpectator,
// //     isHiddenSpectator: isHiddenSpectator ?? this.isHiddenSpectator,
// //     isMuted: isMuted ?? this.isMuted,
// //     isDisconnected: isDisconnected ?? this.isDisconnected,
// //     isAway: isAway ?? this.isAway,
// //     leftDefinitively: leftDefinitively ?? this.leftDefinitively,
// //     isPremium: isPremium ?? this.isPremium,
// //     premiumTier: premiumTier ?? this.premiumTier,
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
// //     isSpectator,
// //     isHiddenSpectator,
// //     isMuted,
// //     isDisconnected,
// //     isAway,
// //     leftDefinitively,
// //     isPremium,
// //   ];
// // }

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
// //     this.replyToId,
// //     this.replyToContent,
// //     this.replyToDisplayName,
// //     this.isAnonymous = false,
// //     this.realSenderId,
// //     this.senderIsPremium = false,
// //     this.senderPremiumTier,
// //   });

// //   final String id;
// //   final String roomId;
// //   final String userId;
// //   final String displayName;
// //   final String? avatarUrl;
// //   final String content;
// //   final DateTime createdAt;
// //   final bool isDeleted;
// //   final bool isOptimistic;
// //   final ChatMessageType type;
// //   final String? replyToId;
// //   final String? replyToContent;
// //   final String? replyToDisplayName;
// //   final bool isAnonymous;
// //   final String? realSenderId;
// //   final bool senderIsPremium;
// //   final String? senderPremiumTier;

// //   bool get isSystem => type == ChatMessageType.system;
// //   bool get isReply => replyToId != null;

// //   ChatMessageEntity copyWithConfirmed() => ChatMessageEntity(
// //     id: id,
// //     roomId: roomId,
// //     userId: userId,
// //     displayName: displayName,
// //     avatarUrl: avatarUrl,
// //     content: content,
// //     createdAt: createdAt,
// //     isDeleted: isDeleted,
// //     isOptimistic: false,
// //     type: type,
// //     replyToId: replyToId,
// //     replyToContent: replyToContent,
// //     replyToDisplayName: replyToDisplayName,
// //     isAnonymous: isAnonymous,
// //     realSenderId: realSenderId,
// //     senderIsPremium: senderIsPremium,
// //     senderPremiumTier: senderPremiumTier,
// //   );

// //   @override
// //   List<Object?> get props => [
// //     id,
// //     roomId,
// //     userId,
// //     content,
// //     createdAt,
// //     isAnonymous,
// //   ];
// // }

// // class RoomSettingsEntity extends Equatable {
// //   const RoomSettingsEntity({
// //     this.turnTimerSeconds = 60,
// //     this.allowSkip = true,
// //     this.maxRounds = 10,
// //     this.chatEnabled = true,
// //     this.allowSpectators = false,
// //     this.spectatorApprovalRequired = false,
// //     this.allowSpicy = false,
// //     this.requiresApproval = false,
// //   });

// //   final int turnTimerSeconds;
// //   final bool allowSkip;
// //   final int maxRounds;
// //   final bool chatEnabled;
// //   final bool allowSpectators;
// //   final bool spectatorApprovalRequired;
// //   final bool allowSpicy;
// //   final bool requiresApproval;

// //   RoomSettingsEntity copyWith({
// //     int? turnTimerSeconds,
// //     bool? allowSkip,
// //     int? maxRounds,
// //     bool? chatEnabled,
// //     bool? allowSpectators,
// //     bool? spectatorApprovalRequired,
// //     bool? allowSpicy,
// //     bool? requiresApproval,
// //   }) => RoomSettingsEntity(
// //     turnTimerSeconds: turnTimerSeconds ?? this.turnTimerSeconds,
// //     allowSkip: allowSkip ?? this.allowSkip,
// //     maxRounds: maxRounds ?? this.maxRounds,
// //     chatEnabled: chatEnabled ?? this.chatEnabled,
// //     allowSpectators: allowSpectators ?? this.allowSpectators,
// //     spectatorApprovalRequired:
// //         spectatorApprovalRequired ?? this.spectatorApprovalRequired,
// //     allowSpicy: allowSpicy ?? this.allowSpicy,
// //     requiresApproval: requiresApproval ?? this.requiresApproval,
// //   );

// //   Map<String, dynamic> toMap() => {
// //     'turn_timer_secs': turnTimerSeconds,
// //     'allow_skip': allowSkip,
// //     'max_rounds': maxRounds,
// //     'chat_enabled': chatEnabled,
// //     'allow_spectators': allowSpectators,
// //     'spectator_approval_required': spectatorApprovalRequired,
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
// //         spectatorApprovalRequired:
// //             m['spectator_approval_required'] as bool? ?? false,
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
// //     spectatorApprovalRequired,
// //     allowSpicy,
// //     requiresApproval,
// //   ];
// // }

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
//     String? language,
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
//     language: language ?? this.language,
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

// class RoomMemberEntity extends Equatable {
//   const RoomMemberEntity({
//     required this.userId,
//     required this.displayName,
//     this.avatarUrl,
//     this.avatarConfig,
//     required this.seatOrder,
//     required this.isReady,
//     required this.isOwner,
//     required this.isModerator,
//     this.isSpectator = false,
//     this.isHiddenSpectator = false,
//     this.isMuted = false,
//     this.isDisconnected = false,
//     this.isAway = false,
//     this.leftDefinitively = false,
//     this.isPremium = false,
//     this.premiumTier,
//     this.joinedAt,
//   });

//   final String userId;
//   final String displayName;
//   final String? avatarUrl;
//   final Map<String, dynamic>? avatarConfig;
//   final int seatOrder;
//   final bool isReady;
//   final bool isOwner;
//   final bool isModerator;
//   final bool isSpectator;
//   final bool isHiddenSpectator;
//   final bool isMuted;
//   final bool isDisconnected;
//   final bool isAway;
//   final bool leftDefinitively;
//   final bool isPremium;
//   final String? premiumTier;
//   final DateTime? joinedAt;

//   bool get canModerate => isOwner || isModerator;
//   bool get isActive => !isDisconnected;
//   bool get shouldOfferRejoin => isAway && !leftDefinitively;

//   String get displayRole {
//     if (isOwner) return 'Owner';
//     if (isModerator) return 'Mod';
//     if (isSpectator) return isHiddenSpectator ? 'Hidden' : 'Spectator';
//     return '';
//   }

//   RoomMemberEntity copyWith({
//     bool? isReady,
//     bool? isOwner,
//     bool? isModerator,
//     bool? isSpectator,
//     bool? isHiddenSpectator,
//     bool? isMuted,
//     bool? isDisconnected,
//     bool? isAway,
//     bool? leftDefinitively,
//     bool? isPremium,
//     String? premiumTier,
//   }) => RoomMemberEntity(
//     userId: userId,
//     displayName: displayName,
//     avatarUrl: avatarUrl,
//     avatarConfig: avatarConfig,
//     seatOrder: seatOrder,
//     isReady: isReady ?? this.isReady,
//     isOwner: isOwner ?? this.isOwner,
//     isModerator: isModerator ?? this.isModerator,
//     isSpectator: isSpectator ?? this.isSpectator,
//     isHiddenSpectator: isHiddenSpectator ?? this.isHiddenSpectator,
//     isMuted: isMuted ?? this.isMuted,
//     isDisconnected: isDisconnected ?? this.isDisconnected,
//     isAway: isAway ?? this.isAway,
//     leftDefinitively: leftDefinitively ?? this.leftDefinitively,
//     isPremium: isPremium ?? this.isPremium,
//     premiumTier: premiumTier ?? this.premiumTier,
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
//     isHiddenSpectator,
//     isMuted,
//     isDisconnected,
//     isAway,
//     leftDefinitively,
//     isPremium,
//   ];
// }

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
//     this.replyToId,
//     this.replyToContent,
//     this.replyToDisplayName,
//     this.isAnonymous = false,
//     this.realSenderId,
//     this.senderIsPremium = false,
//     this.senderPremiumTier,
//   });

//   final String id;
//   final String roomId;
//   final String userId;
//   final String displayName;
//   final String? avatarUrl;
//   final String content;
//   final DateTime createdAt;
//   final bool isDeleted;
//   final bool isOptimistic;
//   final ChatMessageType type;
//   final String? replyToId;
//   final String? replyToContent;
//   final String? replyToDisplayName;
//   final bool isAnonymous;
//   final String? realSenderId;
//   final bool senderIsPremium;
//   final String? senderPremiumTier;

//   bool get isSystem => type == ChatMessageType.system;
//   bool get isReply => replyToId != null;

//   ChatMessageEntity copyWithConfirmed() => ChatMessageEntity(
//     id: id,
//     roomId: roomId,
//     userId: userId,
//     displayName: displayName,
//     avatarUrl: avatarUrl,
//     content: content,
//     createdAt: createdAt,
//     isDeleted: isDeleted,
//     isOptimistic: false,
//     type: type,
//     replyToId: replyToId,
//     replyToContent: replyToContent,
//     replyToDisplayName: replyToDisplayName,
//     isAnonymous: isAnonymous,
//     realSenderId: realSenderId,
//     senderIsPremium: senderIsPremium,
//     senderPremiumTier: senderPremiumTier,
//   );

//   @override
//   List<Object?> get props => [
//     id,
//     roomId,
//     userId,
//     content,
//     createdAt,
//     isAnonymous,
//   ];
// }

// class RoomSettingsEntity extends Equatable {
//   const RoomSettingsEntity({
//     this.turnTimerSeconds = 60,
//     this.allowSkip = true,
//     this.maxRounds = 10,
//     this.chatEnabled = true,
//     this.allowSpectators = false,
//     this.spectatorApprovalRequired = false,
//     this.allowSpicy = false,
//     this.requiresApproval = false,
//   });

//   final int turnTimerSeconds;
//   final bool allowSkip;
//   final int maxRounds;
//   final bool chatEnabled;
//   final bool allowSpectators;
//   final bool spectatorApprovalRequired;
//   final bool allowSpicy;
//   final bool requiresApproval;

//   RoomSettingsEntity copyWith({
//     int? turnTimerSeconds,
//     bool? allowSkip,
//     int? maxRounds,
//     bool? chatEnabled,
//     bool? allowSpectators,
//     bool? spectatorApprovalRequired,
//     bool? allowSpicy,
//     bool? requiresApproval,
//   }) => RoomSettingsEntity(
//     turnTimerSeconds: turnTimerSeconds ?? this.turnTimerSeconds,
//     allowSkip: allowSkip ?? this.allowSkip,
//     maxRounds: maxRounds ?? this.maxRounds,
//     chatEnabled: chatEnabled ?? this.chatEnabled,
//     allowSpectators: allowSpectators ?? this.allowSpectators,
//     spectatorApprovalRequired:
//         spectatorApprovalRequired ?? this.spectatorApprovalRequired,
//     allowSpicy: allowSpicy ?? this.allowSpicy,
//     requiresApproval: requiresApproval ?? this.requiresApproval,
//   );

//   Map<String, dynamic> toMap() => {
//     'turn_timer_secs': turnTimerSeconds,
//     'allow_skip': allowSkip,
//     'max_rounds': maxRounds,
//     'chat_enabled': chatEnabled,
//     'allow_spectators': allowSpectators,
//     'spectator_approval_required': spectatorApprovalRequired,
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
//         spectatorApprovalRequired:
//             m['spectator_approval_required'] as bool? ?? false,
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
//     spectatorApprovalRequired,
//     allowSpicy,
//     requiresApproval,
//   ];
// }

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
    this.ownerTransferredAt,
    this.closedAt,
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

  /// When ownership was last transferred — null if it never has been.
  /// Owners may only transfer ownership once every 24h.
  final DateTime? ownerTransferredAt;

  /// Batch D keep-game close marker (rooms.closed_at). When set, the room is
  /// closed to NEW entrants and hidden from Browse, but the live game keeps
  /// running (status stays in_game/paused). This is ENTIRELY DISTINCT from
  /// the terminal [RoomStatus.closed] teardown — do not conflate the two.
  final DateTime? closedAt;

  bool get isFull => currentPlayers >= maxPlayers;
  bool get isWaiting => status == RoomStatus.waiting;
  bool get isInGame => status == RoomStatus.inGame;
  bool get isPaused => status == RoomStatus.paused;
  bool get isActive =>
      status == RoomStatus.waiting || status == RoomStatus.inGame;

  /// Keep-game closed (closed_at set) — NOT the same as
  /// `status == RoomStatus.closed` (terminal teardown). A room can be
  /// `isInGame && isClosed` at the same time.
  bool get isClosed => closedAt != null;
  bool get canJoin => !isFull && isActive && !isClosed;
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
    DateTime? ownerTransferredAt,
    DateTime? closedAt,
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
    ownerTransferredAt: ownerTransferredAt ?? this.ownerTransferredAt,
    closedAt: closedAt ?? this.closedAt,
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
    closedAt,
  ];
}

/// Granular moderator permission keys — must match the exact strings the
/// backend RPCs check via `has_room_permission()` (schema.sql). Adding a
/// new permission needs an entry here, a check at whatever action it
/// gates, and a row in the UI permission picker — no other structural
/// change, so the permission system stays extensible.
abstract final class ModeratorPermission {
  static const acceptJoins = 'accept_joins';
  static const acceptSpectators = 'accept_spectators';
  static const acceptRejoins = 'accept_rejoins';
  static const advanceTurn = 'advance_turn';
  static const skipTurn = 'skip_turn';
  static const kickPlayers = 'kick_players';
  static const muteChat = 'mute_chat';
  // Distinct from muteChat — this gates the ability to mute a player
  // OUT OF GAME ACTIONS (can't answer/submit/take a turn) while they can
  // still watch, not text chat. Deliberately a separate permission key so
  // the two can be granted independently.
  static const mutePlayers = 'mute_players';
  static const manageSettings = 'manage_settings';
  static const endGame = 'end_game';
  static const startGame = 'start_game';

  // Item 5 — lets a delegated moderator (not just the room owner, who
  // always passes has_room_permission unconditionally) toggle a member
  // between player and spectator via set_room_member_spectator. Distinct
  // from acceptSpectators, which only gates approving a member's OWN
  // request to become a spectator, not an admin proactively reassigning
  // someone else.
  static const setSpectator = 'set_spectator';

  // start_game/end_game are intentionally excluded — both are hard
  // owner-only now (see create_game_session and the ToD end-game path),
  // never delegable to a moderator. The string constants above stay
  // defined in case anything else still references them defensively.
  static const all = [
    acceptJoins,
    acceptSpectators,
    acceptRejoins,
    advanceTurn,
    skipTurn,
    kickPlayers,
    muteChat,
    mutePlayers,
    manageSettings,
    setSpectator,
  ];
}

/// Single, named moderation-state concept for game-action gating and
/// permission checks to read, instead of scattered raw booleans. `kicked`
/// is intentionally not a value here: a kicked member is removed from the
/// room entirely (see kick_room_member/RoomProvider._removeMember), so
/// it's represented by absence from RoomProvider.members, not a state on
/// a still-present entity.
enum MemberModerationState { active, muted, spectator }

class RoomMemberEntity extends Equatable {
  const RoomMemberEntity({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.avatarConfig,
    required this.seatOrder,
    required this.isReady,
    required this.isOwner,
    required this.isModerator,
    this.isSpectator = false,
    this.isHiddenSpectator = false,
    this.isMuted = false,
    this.isGameMuted = false,
    this.isDisconnected = false,
    this.isAway = false,
    this.leftDefinitively = false,
    this.isPremium = false,
    this.premiumTier,
    this.joinedAt,
    this.moderatorPermissions = const {},
    this.honestyPoints = 0,
    this.generalScore = 0,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final Map<String, dynamic>? avatarConfig;
  final int seatOrder;
  final bool isReady;
  final bool isOwner;
  final bool isModerator;
  final bool isSpectator;
  final bool isHiddenSpectator;
  final bool isMuted;

  /// Moderator-imposed game mute — cannot act (answer/submit/take a turn)
  /// but can still watch. Distinct from [isMuted], which only silences
  /// text chat — do not conflate the two.
  final bool isGameMuted;
  final bool isDisconnected;
  final bool isAway;
  final bool leftDefinitively;
  final bool isPremium;
  final String? premiumTier;
  final DateTime? joinedAt;

  /// Granular permission keys this moderator was explicitly granted (empty
  /// for non-moderators/plain players). The owner implicitly has every
  /// permission regardless of this set — see [RoomProvider.hasPermission].
  final Set<String> moderatorPermissions;

  /// Live server-authoritative reputation stats — see
  /// core/services/player_stats and RoomProvider's profiles-CDC extension
  /// for how this stays fresh without polling/rejoining the room.
  /// Separate ledgers (see profiles.honesty_points/general_score); never
  /// mixed. honestyPoints can be negative.
  final int honestyPoints;
  final int generalScore;

  bool get canModerate => isOwner || isModerator;
  bool hasPermission(String key) =>
      isOwner || moderatorPermissions.contains(key);
  bool get isActive => !isDisconnected;
  bool get shouldOfferRejoin => isAway && !leftDefinitively;

  /// See [MemberModerationState].
  MemberModerationState get moderationState {
    if (isSpectator) return MemberModerationState.spectator;
    if (isGameMuted) return MemberModerationState.muted;
    return MemberModerationState.active;
  }

  RoomMemberEntity copyWith({
    bool? isReady,
    bool? isOwner,
    bool? isModerator,
    bool? isSpectator,
    bool? isHiddenSpectator,
    bool? isMuted,
    bool? isGameMuted,
    bool? isDisconnected,
    bool? isAway,
    bool? leftDefinitively,
    bool? isPremium,
    String? premiumTier,
    Set<String>? moderatorPermissions,
    int? honestyPoints,
    int? generalScore,
  }) => RoomMemberEntity(
    userId: userId,
    displayName: displayName,
    avatarUrl: avatarUrl,
    avatarConfig: avatarConfig,
    seatOrder: seatOrder,
    isReady: isReady ?? this.isReady,
    isOwner: isOwner ?? this.isOwner,
    isModerator: isModerator ?? this.isModerator,
    isSpectator: isSpectator ?? this.isSpectator,
    isHiddenSpectator: isHiddenSpectator ?? this.isHiddenSpectator,
    isMuted: isMuted ?? this.isMuted,
    isGameMuted: isGameMuted ?? this.isGameMuted,
    isDisconnected: isDisconnected ?? this.isDisconnected,
    isAway: isAway ?? this.isAway,
    leftDefinitively: leftDefinitively ?? this.leftDefinitively,
    isPremium: isPremium ?? this.isPremium,
    premiumTier: premiumTier ?? this.premiumTier,
    joinedAt: joinedAt,
    moderatorPermissions: moderatorPermissions ?? this.moderatorPermissions,
    honestyPoints: honestyPoints ?? this.honestyPoints,
    generalScore: generalScore ?? this.generalScore,
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
    isHiddenSpectator,
    isMuted,
    isGameMuted,
    isDisconnected,
    isAway,
    leftDefinitively,
    isPremium,
    moderatorPermissions,
    honestyPoints,
    generalScore,
  ];
}

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
    this.replyToId,
    this.replyToContent,
    this.replyToDisplayName,
    this.isAnonymous = false,
    this.realSenderId,
    this.senderIsPremium = false,
    this.senderPremiumTier,
    this.audienceType = 'everyone',
    this.gameSessionId,
    this.recipientNames = const [],
  });

  final String id;
  final String roomId;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String content;
  final DateTime createdAt;
  final bool isDeleted;
  final bool isOptimistic;
  final ChatMessageType type;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToDisplayName;
  final bool isAnonymous;
  final String? realSenderId;
  final bool senderIsPremium;
  final String? senderPremiumTier;

  /// 'everyone' (default — every existing message) or 'selected' (item 2 —
  /// Premium Plus targeted chat). Only the DB/RPC ever sets 'selected';
  /// a plain client insert is server-rejected from setting it.
  final String audienceType;

  /// Null = a lobby-context message (every existing row). Non-null ties
  /// this message to a specific game_sessions row — set only for targeted
  /// in-game messages (see item 2's design: normal/"everyone" game chat
  /// stays broadcast-only and unpersisted, exactly as before).
  final String? gameSessionId;

  /// Display names of the selected recipients, for the SENDER's own "Only:
  /// Ahmed, Sara +1" indicator (item 2's UI requirement) — populated
  /// locally at send time from the audience picker's own selection, never
  /// fetched for a message this user didn't send (see product decision:
  /// a recipient sees the message normally, not the full audience list).
  final List<String> recipientNames;

  bool get isSystem => type == ChatMessageType.system;
  bool get isReply => replyToId != null;
  bool get isTargeted => audienceType == 'selected';

  ChatMessageEntity copyWithConfirmed() => ChatMessageEntity(
    id: id,
    roomId: roomId,
    userId: userId,
    displayName: displayName,
    avatarUrl: avatarUrl,
    content: content,
    createdAt: createdAt,
    isDeleted: isDeleted,
    isOptimistic: false,
    type: type,
    replyToId: replyToId,
    replyToContent: replyToContent,
    replyToDisplayName: replyToDisplayName,
    isAnonymous: isAnonymous,
    realSenderId: realSenderId,
    senderIsPremium: senderIsPremium,
    senderPremiumTier: senderPremiumTier,
    audienceType: audienceType,
    gameSessionId: gameSessionId,
    recipientNames: recipientNames,
  );

  @override
  List<Object?> get props => [
    id,
    roomId,
    userId,
    content,
    createdAt,
    isAnonymous,
  ];
}

class RoomSettingsEntity extends Equatable {
  const RoomSettingsEntity({
    this.turnTimerSeconds = 60,
    this.allowSkip = true,
    this.maxRounds = 10,
    this.chatEnabled = true,
    this.allowSpectators = false,
    this.spectatorApprovalRequired = false,
    this.allowSpicy = false,
    this.requiresApproval = false,
    this.allowAnonymousSpectators = true,
    this.enablePunishments = false,
    this.punishmentSource = 'players',
    this.proofVisibilityPolicy = 'everyone',
    this.proofViewSeconds = 5,
    this.proofReplayMode = 'once',
    this.proofVisibilitySelectedUserIds = const [],
    this.forceDareMode = 'unlimited',
    this.maxTruths = 2,
    this.honestyVoteEnabled = true,
  });

  final int turnTimerSeconds;
  final bool allowSkip;
  final int maxRounds;
  final bool chatEnabled;
  final bool allowSpectators;
  final bool spectatorApprovalRequired;
  final bool allowSpicy;
  final bool requiresApproval;
  final bool allowAnonymousSpectators;
  final bool enablePunishments;

  /// 'players' (default, existing peer-vote flow) or 'pack' (resolves
  /// directly from the selected pack's suggested_punishments).
  final String punishmentSource;
  final String proofVisibilityPolicy;
  final int proofViewSeconds;
  final String proofReplayMode;
  final List<String> proofVisibilitySelectedUserIds;

  /// Item 18.2 — ToD's "Force Dare after N Truths" choice from
  /// tod_pre_game_config_sheet.dart, persisted here (durable for the
  /// lifetime of the current game) so _syncGameRoute's GameConfig
  /// reconstruction — the only path that ever navigates a client, owner
  /// included, into the game screen — can read it back on every
  /// navigation instead of only the one-shot broadcast that started the
  /// game. 'unlimited' | 'per_player' | 'per_turn'.
  final String forceDareMode;
  final int maxTruths;

  /// Whether the honesty-vote mechanic (CompactHonestyVoteButtons/
  /// _HonestyVoteRow — the shared cast_honesty_vote flow used
  /// identically by ToD, NHIE, and Meme Game) is active in this room.
  /// Defaults to true: honesty voting was previously ALWAYS on with no
  /// way to disable it, so a true default preserves existing behavior
  /// for every room that already exists (no migration should silently
  /// turn this off for rooms created before it existed).
  final bool honestyVoteEnabled;

  RoomSettingsEntity copyWith({
    int? turnTimerSeconds,
    bool? allowSkip,
    int? maxRounds,
    bool? chatEnabled,
    bool? allowSpectators,
    bool? spectatorApprovalRequired,
    bool? allowSpicy,
    bool? requiresApproval,
    bool? allowAnonymousSpectators,
    bool? enablePunishments,
    String? punishmentSource,
    String? proofVisibilityPolicy,
    int? proofViewSeconds,
    String? proofReplayMode,
    List<String>? proofVisibilitySelectedUserIds,
    String? forceDareMode,
    int? maxTruths,
    bool? honestyVoteEnabled,
  }) => RoomSettingsEntity(
    turnTimerSeconds: turnTimerSeconds ?? this.turnTimerSeconds,
    allowSkip: allowSkip ?? this.allowSkip,
    maxRounds: maxRounds ?? this.maxRounds,
    chatEnabled: chatEnabled ?? this.chatEnabled,
    allowSpectators: allowSpectators ?? this.allowSpectators,
    spectatorApprovalRequired:
        spectatorApprovalRequired ?? this.spectatorApprovalRequired,
    allowSpicy: allowSpicy ?? this.allowSpicy,
    requiresApproval: requiresApproval ?? this.requiresApproval,
    allowAnonymousSpectators:
        allowAnonymousSpectators ?? this.allowAnonymousSpectators,
    enablePunishments: enablePunishments ?? this.enablePunishments,
    punishmentSource: punishmentSource ?? this.punishmentSource,
    proofVisibilityPolicy: proofVisibilityPolicy ?? this.proofVisibilityPolicy,
    proofViewSeconds: proofViewSeconds ?? this.proofViewSeconds,
    proofReplayMode: proofReplayMode ?? this.proofReplayMode,
    proofVisibilitySelectedUserIds:
        proofVisibilitySelectedUserIds ?? this.proofVisibilitySelectedUserIds,
    forceDareMode: forceDareMode ?? this.forceDareMode,
    maxTruths: maxTruths ?? this.maxTruths,
    honestyVoteEnabled: honestyVoteEnabled ?? this.honestyVoteEnabled,
  );

  Map<String, dynamic> toMap() => {
    'turn_timer_secs': turnTimerSeconds,
    'allow_skip': allowSkip,
    'max_rounds': maxRounds,
    'chat_enabled': chatEnabled,
    'allow_spectators': allowSpectators,
    'spectator_approval_required': spectatorApprovalRequired,
    'allow_spicy': allowSpicy,
    'requires_approval': requiresApproval,
    'allow_anonymous_spectators': allowAnonymousSpectators,
    'enable_punishments': enablePunishments,
    'punishment_source': punishmentSource,
    'proof_visibility_policy': proofVisibilityPolicy,
    'proof_view_seconds': proofViewSeconds,
    'proof_replay_mode': proofReplayMode,
    'proof_visibility_selected_user_ids': proofVisibilitySelectedUserIds,
    'force_dare_mode': forceDareMode,
    'max_truths': maxTruths,
    'honesty_vote_enabled': honestyVoteEnabled,
  };

  static RoomSettingsEntity fromMap(
    Map<String, dynamic> m,
  ) => RoomSettingsEntity(
    turnTimerSeconds: m['turn_timer_secs'] as int? ?? 60,
    allowSkip: m['allow_skip'] as bool? ?? true,
    maxRounds: m['max_rounds'] as int? ?? 10,
    chatEnabled: m['chat_enabled'] as bool? ?? true,
    allowSpectators: m['allow_spectators'] as bool? ?? false,
    spectatorApprovalRequired:
        m['spectator_approval_required'] as bool? ?? false,
    allowSpicy: m['allow_spicy'] as bool? ?? false,
    requiresApproval: m['requires_approval'] as bool? ?? false,
    enablePunishments: m['enable_punishments'] as bool? ?? false,
    punishmentSource: m['punishment_source'] as String? ?? 'players',
    proofVisibilityPolicy:
        m['proof_visibility_policy'] as String? ?? 'everyone',
    proofViewSeconds: m['proof_view_seconds'] as int? ?? 5,
    proofReplayMode: m['proof_replay_mode'] as String? ?? 'once',
    proofVisibilitySelectedUserIds:
        (m['proof_visibility_selected_user_ids'] as List?)?.cast<String>() ??
        const [],
    allowAnonymousSpectators: m['allow_anonymous_spectators'] as bool? ?? true,
    forceDareMode: m['force_dare_mode'] as String? ?? 'unlimited',
    maxTruths: (m['max_truths'] as num?)?.toInt() ?? 2,
    honestyVoteEnabled: m['honesty_vote_enabled'] as bool? ?? true,
  );

  @override
  List<Object?> get props => [
    turnTimerSeconds,
    allowSkip,
    maxRounds,
    chatEnabled,
    allowSpectators,
    spectatorApprovalRequired,
    allowSpicy,
    allowAnonymousSpectators,
    requiresApproval,
    enablePunishments,
    punishmentSource,
    proofVisibilityPolicy,
    proofViewSeconds,
    proofReplayMode,
    proofVisibilitySelectedUserIds,
    forceDareMode,
    maxTruths,
    honestyVoteEnabled,
  ];
}

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

/// One-round-trip snapshot from get_room_creation_status() — item 7's
/// pre-flight room-creation eligibility check (daily limit + minimum-hours
/// gate + the global enable/disable switch), all read server-side in one
/// call instead of the UI parsing create_room()'s exception codes.
class RoomCreationStatus {
  const RoomCreationStatus({
    required this.roomsToday,
    required this.dailyLimit,
    required this.restrictionsEnabled,
    this.nextAllowedAt,
  });

  final int roomsToday;
  final int dailyLimit;
  final bool restrictionsEnabled;

  /// Null when there's no active minimum-hours gate (either restrictions
  /// are off, the tier's minimum-hours value is 0, or this is the user's
  /// first-ever room).
  final DateTime? nextAllowedAt;

  bool get hasHitDailyLimit => restrictionsEnabled && roomsToday >= dailyLimit;

  bool get isTooSoon =>
      restrictionsEnabled &&
      nextAllowedAt != null &&
      nextAllowedAt!.isAfter(DateTime.now());

  static RoomCreationStatus fromMap(Map<String, dynamic> m) =>
      RoomCreationStatus(
        roomsToday: (m['rooms_today'] as num?)?.toInt() ?? 0,
        dailyLimit: (m['daily_limit'] as num?)?.toInt() ?? 0,
        restrictionsEnabled: m['restrictions_enabled'] as bool? ?? true,
        nextAllowedAt: m['next_allowed_at'] != null
            ? DateTime.tryParse(m['next_allowed_at'] as String)
            : null,
      );
}
