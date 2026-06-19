// // // import 'dart:convert';

// // // import 'package:equatable/equatable.dart';

// // // import '../../games/engine/base_game_engine.dart';

// // // // ── Session mode ──────────────────────────────────────────────────────────────

// // // enum OfflineMode {
// // //   /// Single device, players pass the phone in turns.
// // //   passAndPlay,

// // //   /// Host device + nearby devices on same WiFi/hotspot.
// // //   lan,
// // // }

// // // // ── Player ────────────────────────────────────────────────────────────────────

// // // /// Offline player — name only; no auth required.
// // // class OfflinePlayer extends Equatable {
// // //   const OfflinePlayer({
// // //     required this.id, // uuid assigned at session start
// // //     required this.name,
// // //     this.deviceId, // only set in LAN mode
// // //     this.isConnected = true,
// // //     this.seatOrder = 0,
// // //   });

// // //   final String id;
// // //   final String name;
// // //   final String? deviceId;
// // //   final bool isConnected;
// // //   final int seatOrder;

// // //   OfflinePlayer copyWith({bool? isConnected, int? seatOrder}) => OfflinePlayer(
// // //     id: id,
// // //     name: name,
// // //     deviceId: deviceId,
// // //     isConnected: isConnected ?? this.isConnected,
// // //     seatOrder: seatOrder ?? this.seatOrder,
// // //   );

// // //   Map<String, dynamic> toMap() => {
// // //     'id': id,
// // //     'name': name,
// // //     'device_id': deviceId,
// // //     'is_connected': isConnected,
// // //     'seat_order': seatOrder,
// // //   };

// // //   static OfflinePlayer fromMap(Map<String, dynamic> m) => OfflinePlayer(
// // //     id: m['id'] as String,
// // //     name: m['name'] as String,
// // //     deviceId: m['device_id'] as String?,
// // //     isConnected: m['is_connected'] as bool? ?? true,
// // //     seatOrder: m['seat_order'] as int? ?? 0,
// // //   );

// // //   @override
// // //   List<Object?> get props => [id, name, deviceId];
// // // }

// // // // ── Offline session ───────────────────────────────────────────────────────────

// // // /// Snapshot of a local game session — persisted to SQLite for crash recovery.
// // // class OfflineSession extends Equatable {
// // //   const OfflineSession({
// // //     required this.id,
// // //     required this.mode,
// // //     required this.gameType,
// // //     required this.config,
// // //     required this.players,
// // //     required this.packId,
// // //     required this.packName,
// // //     required this.createdAt,
// // //     this.resumedAt,
// // //     this.stateSnapshot, // serialised GameEngineState JSON
// // //     this.isActive = true,
// // //   });

// // //   final String id;
// // //   final OfflineMode mode;
// // //   final GameType gameType;
// // //   final GameConfig config;
// // //   final List<OfflinePlayer> players;
// // //   final String packId;
// // //   final String packName;
// // //   final DateTime createdAt;
// // //   final DateTime? resumedAt;
// // //   final String? stateSnapshot; // raw JSON
// // //   final bool isActive;

// // //   /// True if a persisted snapshot exists and can be resumed.
// // //   bool get isResumable => stateSnapshot != null && isActive;

// // //   Map<String, dynamic> toMap() => {
// // //     'id': id,
// // //     'mode': mode.name,
// // //     'game_type': gameType.toDbString(),
// // //     'config_json': jsonEncode(config.toMap()),
// // //     'players_json': jsonEncode(players.map((p) => p.toMap()).toList()),
// // //     'pack_id': packId,
// // //     'pack_name': packName,
// // //     'created_at': createdAt.millisecondsSinceEpoch,
// // //     'resumed_at': resumedAt?.millisecondsSinceEpoch,
// // //     'state_snapshot': stateSnapshot,
// // //     'is_active': isActive ? 1 : 0,
// // //   };

// // //   static OfflineSession fromMap(Map<String, dynamic> m) {
// // //     final playersJson =
// // //         jsonDecode(m['players_json'] as String) as List<dynamic>;
// // //     return OfflineSession(
// // //       id: m['id'] as String,
// // //       mode: OfflineMode.values.firstWhere(
// // //         (e) => e.name == m['mode'],
// // //         orElse: () => OfflineMode.passAndPlay,
// // //       ),
// // //       gameType: _parseGameType(m['game_type'] as String),
// // //       config: GameConfig.fromMap(
// // //         jsonDecode(m['config_json'] as String) as Map<String, dynamic>,
// // //       ),
// // //       players: playersJson
// // //           .map((p) => OfflinePlayer.fromMap(p as Map<String, dynamic>))
// // //           .toList(),
// // //       packId: m['pack_id'] as String,
// // //       packName: m['pack_name'] as String,
// // //       createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
// // //       resumedAt: m['resumed_at'] != null
// // //           ? DateTime.fromMillisecondsSinceEpoch(m['resumed_at'] as int)
// // //           : null,
// // //       stateSnapshot: m['state_snapshot'] as String?,
// // //       isActive: (m['is_active'] as int?) == 1,
// // //     );
// // //   }

// // //   OfflineSession copyWith({
// // //     String? stateSnapshot,
// // //     bool? isActive,
// // //     DateTime? resumedAt,
// // //   }) => OfflineSession(
// // //     id: id,
// // //     mode: mode,
// // //     gameType: gameType,
// // //     config: config,
// // //     players: players,
// // //     packId: packId,
// // //     packName: packName,
// // //     createdAt: createdAt,
// // //     resumedAt: resumedAt ?? this.resumedAt,
// // //     stateSnapshot: stateSnapshot ?? this.stateSnapshot,
// // //     isActive: isActive ?? this.isActive,
// // //   );

// // //   OfflineSession copyWithPlayers(List<OfflinePlayer> newPlayers) =>
// // //       OfflineSession(
// // //         id: id,
// // //         mode: mode,
// // //         gameType: gameType,
// // //         config: config,
// // //         players: newPlayers,
// // //         packId: packId,
// // //         packName: packName,
// // //         createdAt: createdAt,
// // //         resumedAt: resumedAt,
// // //         stateSnapshot: stateSnapshot,
// // //         isActive: isActive,
// // //       );

// // //   @override
// // //   List<Object?> get props => [id, gameType, mode, createdAt];
// // // }

// // // // ── LAN room ──────────────────────────────────────────────────────────────────

// // // /// Advertised LAN room descriptor — broadcast by the host for discovery.
// // // class LanRoomDescriptor extends Equatable {
// // //   const LanRoomDescriptor({
// // //     required this.sessionId,
// // //     required this.hostName,
// // //     required this.hostAddress,
// // //     required this.port,
// // //     required this.gameType,
// // //     required this.playerCount,
// // //     required this.maxPlayers,
// // //     required this.packName,
// // //     required this.advertisedAt,
// // //   });

// // //   final String sessionId;
// // //   final String hostName;
// // //   final String hostAddress; // IPv4
// // //   final int port;
// // //   final GameType gameType;
// // //   final int playerCount;
// // //   final int maxPlayers;
// // //   final String packName;
// // //   final DateTime advertisedAt;

// // //   bool get isFull => playerCount >= maxPlayers;
// // //   bool get isStale => DateTime.now().difference(advertisedAt).inSeconds > 10;

// // //   Map<String, dynamic> toJson() => {
// // //     'session_id': sessionId,
// // //     'host_name': hostName,
// // //     'host_address': hostAddress,
// // //     'port': port,
// // //     'game_type': gameType.toDbString(),
// // //     'player_count': playerCount,
// // //     'max_players': maxPlayers,
// // //     'pack_name': packName,
// // //     'ts': advertisedAt.millisecondsSinceEpoch,
// // //   };

// // //   static LanRoomDescriptor fromJson(Map<String, dynamic> j) =>
// // //       LanRoomDescriptor(
// // //         sessionId: j['session_id'] as String,
// // //         hostName: j['host_name'] as String,
// // //         hostAddress: j['host_address'] as String,
// // //         port: j['port'] as int,
// // //         gameType: _parseGameType(j['game_type'] as String),
// // //         playerCount: j['player_count'] as int? ?? 0,
// // //         maxPlayers: j['max_players'] as int? ?? 6,
// // //         packName: j['pack_name'] as String? ?? '',
// // //         advertisedAt: DateTime.now(), // use receive time, not packet ts
// // //       );

// // //   @override
// // //   List<Object?> get props => [sessionId, hostAddress, port];

// // //   LanRoomDescriptor copyWith({String? hostAddress}) => LanRoomDescriptor(
// // //     sessionId: sessionId,
// // //     hostName: hostName,
// // //     hostAddress: hostAddress ?? this.hostAddress,
// // //     port: port,
// // //     gameType: gameType,
// // //     playerCount: playerCount,
// // //     maxPlayers: maxPlayers,
// // //     packName: packName,
// // //     advertisedAt: advertisedAt,
// // //   );
// // // }

// // // // ── LAN message envelope ──────────────────────────────────────────────────────

// // // enum LanMessageType {
// // //   join,
// // //   joinAck,
// // //   leave,
// // //   gameState,
// // //   playerAction,
// // //   ping,
// // //   pong,
// // //   roomInfo,
// // //   startGame,
// // //   lobbyUpdate,
// // //   chat,
// // // }

// // // class LanMessage {
// // //   const LanMessage({
// // //     required this.type,
// // //     required this.senderId,
// // //     required this.payload,
// // //     required this.ts,
// // //   });

// // //   final LanMessageType type;
// // //   final String senderId;
// // //   final Map<String, dynamic> payload;
// // //   final int ts;

// // //   String toJson() => jsonEncode({
// // //     'type': type.name,
// // //     'sender_id': senderId,
// // //     'payload': payload,
// // //     'ts': ts,
// // //   });

// // //   static LanMessage? fromJson(String raw) {
// // //     try {
// // //       final m = jsonDecode(raw) as Map<String, dynamic>;
// // //       return LanMessage(
// // //         type: LanMessageType.values.firstWhere(
// // //           (t) => t.name == m['type'],
// // //           orElse: () => LanMessageType.ping,
// // //         ),
// // //         senderId: m['sender_id'] as String? ?? '',
// // //         // Deep-cast so nested maps are also Map<String, dynamic>, not Map<dynamic, dynamic>
// // //         payload: _deepCast(m['payload']) as Map<String, dynamic>? ?? {},
// // //         ts: m['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch,
// // //       );
// // //     } catch (e) {
// // //       return null;
// // //     }
// // //   }

// // //   /// Recursively cast all maps to Map<String, dynamic>.
// // //   static dynamic _deepCast(dynamic value) {
// // //     if (value is Map) {
// // //       return Map<String, dynamic>.fromEntries(
// // //         value.entries.map(
// // //           (e) => MapEntry(e.key.toString(), _deepCast(e.value)),
// // //         ),
// // //       );
// // //     }
// // //     if (value is List) {
// // //       return value.map(_deepCast).toList();
// // //     }
// // //     return value;
// // //   }
// // // }

// // // // ── Downloaded pack entry ─────────────────────────────────────────────────────

// // // /// Summary of a locally-available pack (stored in SQLite).
// // // class OfflinePack extends Equatable {
// // //   const OfflinePack({
// // //     required this.id,
// // //     required this.name,
// // //     required this.gameType,
// // //     required this.language,
// // //     required this.cardCount,
// // //     this.isFree = false,
// // //     this.expiresAt,
// // //   });

// // //   final String id;
// // //   final String name;
// // //   final GameType gameType;
// // //   final String language;
// // //   final int cardCount;
// // //   final bool isFree;
// // //   final DateTime? expiresAt;

// // //   bool get isExpired =>
// // //       expiresAt != null && expiresAt!.isBefore(DateTime.now());
// // //   bool get isUsable => !isExpired;

// // //   @override
// // //   List<Object?> get props => [id, name, gameType];
// // // }

// // // // ── Helpers ───────────────────────────────────────────────────────────────────

// // // GameType _parseGameType(String s) => switch (s) {
// // //   'truth_or_dare' => GameType.truthOrDare,
// // //   'never_have_i_ever' => GameType.neverHaveIEver,
// // //   'meme_game' => GameType.memeGame,
// // //   _ => GameType.truthOrDare,
// // // };

// // import 'dart:convert';

// // import 'package:equatable/equatable.dart';

// // import '../../games/engine/base_game_engine.dart';

// // // ── Session mode ──────────────────────────────────────────────────────────────

// // enum OfflineMode {
// //   /// Single device, players pass the phone in turns.
// //   passAndPlay,

// //   /// Host device + nearby devices on same WiFi/hotspot.
// //   lan,
// // }

// // // ── Player ────────────────────────────────────────────────────────────────────

// // /// Offline player — name only; no auth required.
// // class OfflinePlayer extends Equatable {
// //   const OfflinePlayer({
// //     required this.id, // uuid assigned at session start
// //     required this.name,
// //     this.deviceId, // only set in LAN mode
// //     this.isConnected = true,
// //     this.seatOrder = 0,
// //   });

// //   final String id;
// //   final String name;
// //   final String? deviceId;
// //   final bool isConnected;
// //   final int seatOrder;

// //   OfflinePlayer copyWith({bool? isConnected, int? seatOrder}) => OfflinePlayer(
// //     id: id,
// //     name: name,
// //     deviceId: deviceId,
// //     isConnected: isConnected ?? this.isConnected,
// //     seatOrder: seatOrder ?? this.seatOrder,
// //   );

// //   Map<String, dynamic> toMap() => {
// //     'id': id,
// //     'name': name,
// //     'device_id': deviceId,
// //     'is_connected': isConnected,
// //     'seat_order': seatOrder,
// //   };

// //   static OfflinePlayer fromMap(Map<String, dynamic> m) => OfflinePlayer(
// //     id: m['id'] as String,
// //     name: m['name'] as String,
// //     deviceId: m['device_id'] as String?,
// //     isConnected: m['is_connected'] as bool? ?? true,
// //     seatOrder: m['seat_order'] as int? ?? 0,
// //   );

// //   @override
// //   List<Object?> get props => [id, name, deviceId];
// // }

// // // ── Offline session ───────────────────────────────────────────────────────────

// // /// Snapshot of a local game session — persisted to SQLite for crash recovery.
// // class OfflineSession extends Equatable {
// //   const OfflineSession({
// //     required this.id,
// //     required this.mode,
// //     required this.gameType,
// //     required this.config,
// //     required this.players,
// //     required this.packId,
// //     required this.packName,
// //     required this.createdAt,
// //     this.resumedAt,
// //     this.stateSnapshot, // serialised GameEngineState JSON
// //     this.isActive = true,
// //   });

// //   final String id;
// //   final OfflineMode mode;
// //   final GameType gameType;
// //   final GameConfig config;
// //   final List<OfflinePlayer> players;
// //   final String packId;
// //   final String packName;
// //   final DateTime createdAt;
// //   final DateTime? resumedAt;
// //   final String? stateSnapshot; // raw JSON
// //   final bool isActive;

// //   /// True if a persisted snapshot exists and can be resumed.
// //   bool get isResumable => stateSnapshot != null && isActive;

// //   Map<String, dynamic> toMap() => {
// //     'id': id,
// //     'mode': mode.name,
// //     'game_type': gameType.toDbString(),
// //     'config_json': jsonEncode(config.toMap()),
// //     'players_json': jsonEncode(players.map((p) => p.toMap()).toList()),
// //     'pack_id': packId,
// //     'pack_name': packName,
// //     'created_at': createdAt.millisecondsSinceEpoch,
// //     'resumed_at': resumedAt?.millisecondsSinceEpoch,
// //     'state_snapshot': stateSnapshot,
// //     'is_active': isActive ? 1 : 0,
// //   };

// //   static OfflineSession fromMap(Map<String, dynamic> m) {
// //     final playersJson =
// //         jsonDecode(m['players_json'] as String) as List<dynamic>;
// //     return OfflineSession(
// //       id: m['id'] as String,
// //       mode: OfflineMode.values.firstWhere(
// //         (e) => e.name == m['mode'],
// //         orElse: () => OfflineMode.passAndPlay,
// //       ),
// //       gameType: _parseGameType(m['game_type'] as String),
// //       config: GameConfig.fromMap(
// //         jsonDecode(m['config_json'] as String) as Map<String, dynamic>,
// //       ),
// //       players: playersJson
// //           .map((p) => OfflinePlayer.fromMap(p as Map<String, dynamic>))
// //           .toList(),
// //       packId: m['pack_id'] as String,
// //       packName: m['pack_name'] as String,
// //       createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
// //       resumedAt: m['resumed_at'] != null
// //           ? DateTime.fromMillisecondsSinceEpoch(m['resumed_at'] as int)
// //           : null,
// //       stateSnapshot: m['state_snapshot'] as String?,
// //       isActive: (m['is_active'] as int?) == 1,
// //     );
// //   }

// //   OfflineSession copyWith({
// //     String? stateSnapshot,
// //     bool? isActive,
// //     DateTime? resumedAt,
// //   }) => OfflineSession(
// //     id: id,
// //     mode: mode,
// //     gameType: gameType,
// //     config: config,
// //     players: players,
// //     packId: packId,
// //     packName: packName,
// //     createdAt: createdAt,
// //     resumedAt: resumedAt ?? this.resumedAt,
// //     stateSnapshot: stateSnapshot ?? this.stateSnapshot,
// //     isActive: isActive ?? this.isActive,
// //   );

// //   OfflineSession copyWithPlayers(List<OfflinePlayer> newPlayers) =>
// //       OfflineSession(
// //         id: id,
// //         mode: mode,
// //         gameType: gameType,
// //         config: config,
// //         players: newPlayers,
// //         packId: packId,
// //         packName: packName,
// //         createdAt: createdAt,
// //         resumedAt: resumedAt,
// //         stateSnapshot: stateSnapshot,
// //         isActive: isActive,
// //       );

// //   @override
// //   List<Object?> get props => [id, gameType, mode, createdAt];
// // }

// // // ── LAN room ──────────────────────────────────────────────────────────────────

// // /// Advertised LAN room descriptor — broadcast by the host for discovery.
// // class LanRoomDescriptor extends Equatable {
// //   const LanRoomDescriptor({
// //     required this.sessionId,
// //     required this.hostName,
// //     required this.hostAddress,
// //     required this.port,
// //     required this.gameType,
// //     required this.playerCount,
// //     required this.maxPlayers,
// //     required this.packName,
// //     required this.advertisedAt,
// //     this.maxRounds = 10,
// //     this.turnTimerSeconds = 0,
// //     this.allowSpicy = false,
// //     this.allowSkip = true,
// //   });

// //   final String sessionId;
// //   final String hostName;
// //   final String hostAddress;
// //   final int port;
// //   final GameType gameType;
// //   final int playerCount;
// //   final int maxPlayers;
// //   final String packName;
// //   final DateTime advertisedAt;
// //   final int maxRounds;
// //   final int turnTimerSeconds;
// //   final bool allowSpicy;
// //   final bool allowSkip;

// //   bool get isFull => playerCount >= maxPlayers;
// //   bool get isStale => DateTime.now().difference(advertisedAt).inSeconds > 10;

// //   Map<String, dynamic> toJson() => {
// //     'session_id': sessionId,
// //     'host_name': hostName,
// //     'host_address': hostAddress,
// //     'port': port,
// //     'game_type': gameType.toDbString(),
// //     'player_count': playerCount,
// //     'max_players': maxPlayers,
// //     'pack_name': packName,
// //     'ts': advertisedAt.millisecondsSinceEpoch,
// //     'max_rounds': maxRounds,
// //     'turn_timer_secs': turnTimerSeconds,
// //     'allow_spicy': allowSpicy,
// //     'allow_skip': allowSkip,
// //   };

// //   static LanRoomDescriptor fromJson(Map<String, dynamic> j) =>
// //       LanRoomDescriptor(
// //         sessionId: j['session_id'] as String,
// //         hostName: j['host_name'] as String,
// //         hostAddress: j['host_address'] as String,
// //         port: j['port'] as int,
// //         gameType: _parseGameType(j['game_type'] as String),
// //         playerCount: j['player_count'] as int? ?? 0,
// //         maxPlayers: j['max_players'] as int? ?? 6,
// //         packName: j['pack_name'] as String? ?? '',
// //         advertisedAt: DateTime.now(),
// //         maxRounds: j['max_rounds'] as int? ?? 10,
// //         turnTimerSeconds: j['turn_timer_secs'] as int? ?? 0,
// //         allowSpicy: j['allow_spicy'] as bool? ?? false,
// //         allowSkip: j['allow_skip'] as bool? ?? true,
// //       );

// //   @override
// //   List<Object?> get props => [sessionId, hostAddress, port];

// //   LanRoomDescriptor copyWith({String? hostAddress}) => LanRoomDescriptor(
// //     sessionId: sessionId,
// //     hostName: hostName,
// //     hostAddress: hostAddress ?? this.hostAddress,
// //     port: port,
// //     gameType: gameType,
// //     playerCount: playerCount,
// //     maxPlayers: maxPlayers,
// //     packName: packName,
// //     advertisedAt: advertisedAt,
// //     maxRounds: maxRounds,
// //     turnTimerSeconds: turnTimerSeconds,
// //     allowSpicy: allowSpicy,
// //     allowSkip: allowSkip,
// //     // port: port,
// //     // gameType: gameType,
// //     // playerCount: playerCount,
// //     // maxPlayers: maxPlayers,
// //     // packName: packName,
// //     // advertisedAt: advertisedAt,
// //   );
// // }

// // // ── LAN message envelope ──────────────────────────────────────────────────────

// // enum LanMessageType {
// //   join,
// //   joinAck,
// //   leave,
// //   gameState,
// //   playerAction,
// //   ping,
// //   pong,
// //   roomInfo,
// //   startGame,
// //   lobbyUpdate,
// //   chat,
// // }

// // class LanMessage {
// //   const LanMessage({
// //     required this.type,
// //     required this.senderId,
// //     required this.payload,
// //     required this.ts,
// //   });

// //   final LanMessageType type;
// //   final String senderId;
// //   final Map<String, dynamic> payload;
// //   final int ts;

// //   String toJson() => jsonEncode({
// //     'type': type.name,
// //     'sender_id': senderId,
// //     'payload': payload,
// //     'ts': ts,
// //   });

// //   static LanMessage? fromJson(String raw) {
// //     try {
// //       final m = jsonDecode(raw) as Map<String, dynamic>;
// //       return LanMessage(
// //         type: LanMessageType.values.firstWhere(
// //           (t) => t.name == m['type'],
// //           orElse: () => LanMessageType.ping,
// //         ),
// //         senderId: m['sender_id'] as String? ?? '',
// //         // Deep-cast so nested maps are also Map<String, dynamic>, not Map<dynamic, dynamic>
// //         payload: _deepCast(m['payload']) as Map<String, dynamic>? ?? {},
// //         ts: m['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch,
// //       );
// //     } catch (e) {
// //       return null;
// //     }
// //   }

// //   /// Recursively cast all maps to Map<String, dynamic>.
// //   static dynamic _deepCast(dynamic value) {
// //     if (value is Map) {
// //       return Map<String, dynamic>.fromEntries(
// //         value.entries.map(
// //           (e) => MapEntry(e.key.toString(), _deepCast(e.value)),
// //         ),
// //       );
// //     }
// //     if (value is List) {
// //       return value.map(_deepCast).toList();
// //     }
// //     return value;
// //   }
// // }

// // // ── Downloaded pack entry ─────────────────────────────────────────────────────

// // /// Summary of a locally-available pack (stored in SQLite).
// // class OfflinePack extends Equatable {
// //   const OfflinePack({
// //     required this.id,
// //     required this.name,
// //     required this.gameType,
// //     required this.language,
// //     required this.cardCount,
// //     this.isFree = false,
// //     this.expiresAt,
// //   });

// //   final String id;
// //   final String name;
// //   final GameType gameType;
// //   final String language;
// //   final int cardCount;
// //   final bool isFree;
// //   final DateTime? expiresAt;

// //   bool get isExpired =>
// //       expiresAt != null && expiresAt!.isBefore(DateTime.now());
// //   bool get isUsable => !isExpired;

// //   @override
// //   List<Object?> get props => [id, name, gameType];
// // }

// // // ── Helpers ───────────────────────────────────────────────────────────────────

// // GameType _parseGameType(String s) => switch (s) {
// //   'truth_or_dare' => GameType.truthOrDare,
// //   'never_have_i_ever' => GameType.neverHaveIEver,
// //   'meme_game' => GameType.memeGame,
// //   _ => GameType.truthOrDare,
// // };

// import 'dart:convert';

// import 'package:equatable/equatable.dart';

// import '../../games/engine/base_game_engine.dart';

// // ── Session mode ──────────────────────────────────────────────────────────────

// enum OfflineMode {
//   /// Single device, players pass the phone in turns.
//   passAndPlay,

//   /// Host device + nearby devices on same WiFi/hotspot.
//   lan,
// }

// // ── Player ────────────────────────────────────────────────────────────────────

// /// Offline player — name only; no auth required.
// class OfflinePlayer extends Equatable {
//   const OfflinePlayer({
//     required this.id, // uuid assigned at session start
//     required this.name,
//     this.deviceId, // only set in LAN mode
//     this.isConnected = true,
//     this.seatOrder = 0,
//   });

//   final String id;
//   final String name;
//   final String? deviceId;
//   final bool isConnected;
//   final int seatOrder;

//   OfflinePlayer copyWith({bool? isConnected, int? seatOrder}) => OfflinePlayer(
//     id: id,
//     name: name,
//     deviceId: deviceId,
//     isConnected: isConnected ?? this.isConnected,
//     seatOrder: seatOrder ?? this.seatOrder,
//   );

//   Map<String, dynamic> toMap() => {
//     'id': id,
//     'name': name,
//     'device_id': deviceId,
//     'is_connected': isConnected,
//     'seat_order': seatOrder,
//   };

//   static OfflinePlayer fromMap(Map<String, dynamic> m) => OfflinePlayer(
//     id: m['id'] as String,
//     name: m['name'] as String,
//     deviceId: m['device_id'] as String?,
//     isConnected: m['is_connected'] as bool? ?? true,
//     seatOrder: m['seat_order'] as int? ?? 0,
//   );

//   @override
//   List<Object?> get props => [id, name, deviceId];
// }

// // ── Offline session ───────────────────────────────────────────────────────────

// /// Snapshot of a local game session — persisted to SQLite for crash recovery.
// class OfflineSession extends Equatable {
//   const OfflineSession({
//     required this.id,
//     required this.mode,
//     required this.gameType,
//     required this.config,
//     required this.players,
//     required this.packId,
//     required this.packName,
//     this.packCoverUrl,
//     required this.createdAt,
//     this.resumedAt,
//     this.stateSnapshot, // serialised GameEngineState JSON
//     this.isActive = true,
//   });

//   final String id;
//   final OfflineMode mode;
//   final GameType gameType;
//   final GameConfig config;
//   final List<OfflinePlayer> players;
//   final String packId;
//   final String packName;
//   final String? packCoverUrl;
//   final DateTime createdAt;
//   final DateTime? resumedAt;
//   final String? stateSnapshot; // raw JSON
//   final bool isActive;

//   /// True if a persisted snapshot exists and can be resumed.
//   bool get isResumable => stateSnapshot != null && isActive;

//   Map<String, dynamic> toMap() => {
//     'id': id,
//     'mode': mode.name,
//     'game_type': gameType.toDbString(),
//     'config_json': jsonEncode(config.toMap()),
//     'players_json': jsonEncode(players.map((p) => p.toMap()).toList()),
//     'pack_id': packId,
//     'pack_name': packName,
//     'pack_cover_url': packCoverUrl,
//     'created_at': createdAt.millisecondsSinceEpoch,
//     'resumed_at': resumedAt?.millisecondsSinceEpoch,
//     'state_snapshot': stateSnapshot,
//     'is_active': isActive ? 1 : 0,
//   };

//   static OfflineSession fromMap(Map<String, dynamic> m) {
//     final playersJson =
//         jsonDecode(m['players_json'] as String) as List<dynamic>;
//     return OfflineSession(
//       id: m['id'] as String,
//       mode: OfflineMode.values.firstWhere(
//         (e) => e.name == m['mode'],
//         orElse: () => OfflineMode.passAndPlay,
//       ),
//       gameType: _parseGameType(m['game_type'] as String),
//       config: GameConfig.fromMap(
//         jsonDecode(m['config_json'] as String) as Map<String, dynamic>,
//       ),
//       players: playersJson
//           .map((p) => OfflinePlayer.fromMap(p as Map<String, dynamic>))
//           .toList(),
//       packId: m['pack_id'] as String,
//       packName: m['pack_name'] as String,
//       packCoverUrl: m['pack_cover_url'] as String?,
//       createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
//       resumedAt: m['resumed_at'] != null
//           ? DateTime.fromMillisecondsSinceEpoch(m['resumed_at'] as int)
//           : null,
//       stateSnapshot: m['state_snapshot'] as String?,
//       isActive: (m['is_active'] as int?) == 1,
//     );
//   }

//   OfflineSession copyWith({
//     String? stateSnapshot,
//     bool? isActive,
//     DateTime? resumedAt,
//   }) => OfflineSession(
//     id: id,
//     mode: mode,
//     gameType: gameType,
//     config: config,
//     players: players,
//     packId: packId,
//     packName: packName,
//     packCoverUrl: packCoverUrl,
//     createdAt: createdAt,
//     resumedAt: resumedAt ?? this.resumedAt,
//     stateSnapshot: stateSnapshot ?? this.stateSnapshot,
//     isActive: isActive ?? this.isActive,
//   );

//   OfflineSession copyWithPlayers(List<OfflinePlayer> newPlayers) =>
//       OfflineSession(
//         id: id,
//         mode: mode,
//         gameType: gameType,
//         config: config,
//         players: newPlayers,
//         packId: packId,
//         packName: packName,
//         packCoverUrl: packCoverUrl,
//         createdAt: createdAt,
//         resumedAt: resumedAt,
//         stateSnapshot: stateSnapshot,
//         isActive: isActive,
//       );

//   @override
//   List<Object?> get props => [id, gameType, mode, createdAt];
// }

// // ── LAN room ──────────────────────────────────────────────────────────────────

// /// Advertised LAN room descriptor — broadcast by the host for discovery.
// class LanRoomDescriptor extends Equatable {
//   const LanRoomDescriptor({
//     required this.sessionId,
//     required this.hostName,
//     required this.hostAddress,
//     required this.port,
//     required this.gameType,
//     required this.playerCount,
//     required this.maxPlayers,
//     required this.packName,
//     required this.advertisedAt,
//     this.maxRounds = 10,
//     this.turnTimerSeconds = 0,
//     this.allowSpicy = false,
//     this.allowSkip = true,
//   });

//   final String sessionId;
//   final String hostName;
//   final String hostAddress;
//   final int port;
//   final GameType gameType;
//   final int playerCount;
//   final int maxPlayers;
//   final String packName;
//   final DateTime advertisedAt;
//   final int maxRounds;
//   final int turnTimerSeconds;
//   final bool allowSpicy;
//   final bool allowSkip;

//   bool get isFull => playerCount >= maxPlayers;
//   bool get isStale => DateTime.now().difference(advertisedAt).inSeconds > 10;

//   Map<String, dynamic> toJson() => {
//     'session_id': sessionId,
//     'host_name': hostName,
//     'host_address': hostAddress,
//     'port': port,
//     'game_type': gameType.toDbString(),
//     'player_count': playerCount,
//     'max_players': maxPlayers,
//     'pack_name': packName,
//     'ts': advertisedAt.millisecondsSinceEpoch,
//     'max_rounds': maxRounds,
//     'turn_timer_secs': turnTimerSeconds,
//     'allow_spicy': allowSpicy,
//     'allow_skip': allowSkip,
//   };

//   static LanRoomDescriptor fromJson(Map<String, dynamic> j) =>
//       LanRoomDescriptor(
//         sessionId: j['session_id'] as String,
//         hostName: j['host_name'] as String,
//         hostAddress: j['host_address'] as String,
//         port: j['port'] as int,
//         gameType: _parseGameType(j['game_type'] as String),
//         playerCount: j['player_count'] as int? ?? 0,
//         maxPlayers: j['max_players'] as int? ?? 6,
//         packName: j['pack_name'] as String? ?? '',
//         advertisedAt: DateTime.now(),
//         maxRounds: j['max_rounds'] as int? ?? 10,
//         turnTimerSeconds: j['turn_timer_secs'] as int? ?? 0,
//         allowSpicy: j['allow_spicy'] as bool? ?? false,
//         allowSkip: j['allow_skip'] as bool? ?? true,
//       );

//   @override
//   List<Object?> get props => [sessionId, hostAddress, port];

//   LanRoomDescriptor copyWith({String? hostAddress}) => LanRoomDescriptor(
//     sessionId: sessionId,
//     hostName: hostName,
//     hostAddress: hostAddress ?? this.hostAddress,
//     port: port,
//     gameType: gameType,
//     playerCount: playerCount,
//     maxPlayers: maxPlayers,
//     packName: packName,
//     advertisedAt: advertisedAt,
//     maxRounds: maxRounds,
//     turnTimerSeconds: turnTimerSeconds,
//     allowSpicy: allowSpicy,
//     allowSkip: allowSkip,
//     // port:        port,
//     // gameType:    gameType,
//     // playerCount: playerCount,
//     // maxPlayers:  maxPlayers,
//     // packName:    packName,
//     // advertisedAt: advertisedAt,
//   );
// }

// // ── LAN message envelope ──────────────────────────────────────────────────────

// enum LanMessageType {
//   join,
//   joinAck,
//   leave,
//   gameState,
//   playerAction,
//   ping,
//   pong,
//   roomInfo,
//   startGame,
//   lobbyUpdate,
//   chat,
// }

// class LanMessage {
//   const LanMessage({
//     required this.type,
//     required this.senderId,
//     required this.payload,
//     required this.ts,
//   });

//   final LanMessageType type;
//   final String senderId;
//   final Map<String, dynamic> payload;
//   final int ts;

//   String toJson() => jsonEncode({
//     'type': type.name,
//     'sender_id': senderId,
//     'payload': payload,
//     'ts': ts,
//   });

//   static LanMessage? fromJson(String raw) {
//     try {
//       final m = jsonDecode(raw) as Map<String, dynamic>;
//       return LanMessage(
//         type: LanMessageType.values.firstWhere(
//           (t) => t.name == m['type'],
//           orElse: () => LanMessageType.ping,
//         ),
//         senderId: m['sender_id'] as String? ?? '',
//         // Deep-cast so nested maps are also Map<String, dynamic>, not Map<dynamic, dynamic>
//         payload: _deepCast(m['payload']) as Map<String, dynamic>? ?? {},
//         ts: m['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch,
//       );
//     } catch (e) {
//       return null;
//     }
//   }

//   /// Recursively cast all maps to Map<String, dynamic>.
//   static dynamic _deepCast(dynamic value) {
//     if (value is Map) {
//       return Map<String, dynamic>.fromEntries(
//         value.entries.map(
//           (e) => MapEntry(e.key.toString(), _deepCast(e.value)),
//         ),
//       );
//     }
//     if (value is List) {
//       return value.map(_deepCast).toList();
//     }
//     return value;
//   }
// }

// // ── Downloaded pack entry ─────────────────────────────────────────────────────

// /// Summary of a locally-available pack (stored in SQLite).
// class OfflinePack extends Equatable {
//   const OfflinePack({
//     required this.id,
//     required this.name,
//     required this.gameType,
//     required this.language,
//     required this.cardCount,
//     this.isFree = false,
//     this.coverImageUrl,
//     this.expiresAt,
//   });

//   final String id;
//   final String name;
//   final GameType gameType;
//   final String language;
//   final int cardCount;
//   final bool isFree;
//   final String? coverImageUrl;
//   final DateTime? expiresAt;

//   bool get isExpired =>
//       expiresAt != null && expiresAt!.isBefore(DateTime.now());
//   bool get isUsable => !isExpired;

//   @override
//   List<Object?> get props => [id, name, gameType];
// }

// // ── Helpers ───────────────────────────────────────────────────────────────────

// GameType _parseGameType(String s) => switch (s) {
//   'truth_or_dare' => GameType.truthOrDare,
//   'never_have_i_ever' => GameType.neverHaveIEver,
//   'meme_game' => GameType.memeGame,
//   _ => GameType.truthOrDare,
// };

import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../../games/engine/base_game_engine.dart';

// ── Session mode ──────────────────────────────────────────────────────────────

enum OfflineMode {
  /// Single device, players pass the phone in turns.
  passAndPlay,

  /// Host device + nearby devices on same WiFi/hotspot.
  lan,
}

// ── Player ────────────────────────────────────────────────────────────────────

/// Offline player — name only; no auth required.
class OfflinePlayer extends Equatable {
  const OfflinePlayer({
    required this.id, // uuid assigned at session start
    required this.name,
    this.deviceId, // only set in LAN mode
    this.isConnected = true,
    this.seatOrder = 0,
  });

  final String id;
  final String name;
  final String? deviceId;
  final bool isConnected;
  final int seatOrder;

  OfflinePlayer copyWith({bool? isConnected, int? seatOrder}) => OfflinePlayer(
    id: id,
    name: name,
    deviceId: deviceId,
    isConnected: isConnected ?? this.isConnected,
    seatOrder: seatOrder ?? this.seatOrder,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'device_id': deviceId,
    'is_connected': isConnected,
    'seat_order': seatOrder,
  };

  static OfflinePlayer fromMap(Map<String, dynamic> m) => OfflinePlayer(
    id: m['id'] as String,
    name: m['name'] as String,
    deviceId: m['device_id'] as String?,
    isConnected: m['is_connected'] as bool? ?? true,
    seatOrder: m['seat_order'] as int? ?? 0,
  );

  @override
  List<Object?> get props => [id, name, deviceId];
}

// ── Offline session ───────────────────────────────────────────────────────────

/// Snapshot of a local game session — persisted to SQLite for crash recovery.
class OfflineSession extends Equatable {
  const OfflineSession({
    required this.id,
    required this.mode,
    required this.gameType,
    required this.config,
    required this.players,
    required this.packId,
    required this.packName,
    this.packCoverUrl,
    required this.createdAt,
    this.resumedAt,
    this.stateSnapshot, // serialised GameEngineState JSON
    this.isActive = true,
  });

  final String id;
  final OfflineMode mode;
  final GameType gameType;
  final GameConfig config;
  final List<OfflinePlayer> players;
  final String packId;
  final String packName;
  final String? packCoverUrl;
  final DateTime createdAt;
  final DateTime? resumedAt;
  final String? stateSnapshot; // raw JSON
  final bool isActive;

  /// True if a persisted snapshot exists and can be resumed.
  bool get isResumable => stateSnapshot != null && isActive;

  Map<String, dynamic> toMap() => {
    'id': id,
    'mode': mode.name,
    'game_type': gameType.toDbString(),
    'config_json': jsonEncode(config.toMap()),
    'players_json': jsonEncode(players.map((p) => p.toMap()).toList()),
    'pack_id': packId,
    'pack_name': packName,
    'created_at': createdAt.millisecondsSinceEpoch,
    'resumed_at': resumedAt?.millisecondsSinceEpoch,
    'state_snapshot': stateSnapshot,
    'is_active': isActive ? 1 : 0,
  };

  static OfflineSession fromMap(Map<String, dynamic> m) {
    final playersJson =
        jsonDecode(m['players_json'] as String) as List<dynamic>;
    return OfflineSession(
      id: m['id'] as String,
      mode: OfflineMode.values.firstWhere(
        (e) => e.name == m['mode'],
        orElse: () => OfflineMode.passAndPlay,
      ),
      gameType: _parseGameType(m['game_type'] as String),
      config: GameConfig.fromMap(
        jsonDecode(m['config_json'] as String) as Map<String, dynamic>,
      ),
      players: playersJson
          .map((p) => OfflinePlayer.fromMap(p as Map<String, dynamic>))
          .toList(),
      packId: m['pack_id'] as String,
      packName: m['pack_name'] as String,
      packCoverUrl: m['pack_cover_url'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      resumedAt: m['resumed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(m['resumed_at'] as int)
          : null,
      stateSnapshot: m['state_snapshot'] as String?,
      isActive: (m['is_active'] as int?) == 1,
    );
  }

  OfflineSession copyWith({
    String? stateSnapshot,
    bool? isActive,
    DateTime? resumedAt,
  }) => OfflineSession(
    id: id,
    mode: mode,
    gameType: gameType,
    config: config,
    players: players,
    packId: packId,
    packName: packName,
    packCoverUrl: packCoverUrl,
    createdAt: createdAt,
    resumedAt: resumedAt ?? this.resumedAt,
    stateSnapshot: stateSnapshot ?? this.stateSnapshot,
    isActive: isActive ?? this.isActive,
  );

  OfflineSession copyWithPlayers(List<OfflinePlayer> newPlayers) =>
      OfflineSession(
        id: id,
        mode: mode,
        gameType: gameType,
        config: config,
        players: newPlayers,
        packId: packId,
        packName: packName,
        packCoverUrl: packCoverUrl,
        createdAt: createdAt,
        resumedAt: resumedAt,
        stateSnapshot: stateSnapshot,
        isActive: isActive,
      );

  @override
  List<Object?> get props => [id, gameType, mode, createdAt];
}

// ── LAN room ──────────────────────────────────────────────────────────────────

/// Advertised LAN room descriptor — broadcast by the host for discovery.
class LanRoomDescriptor extends Equatable {
  const LanRoomDescriptor({
    required this.sessionId,
    required this.hostName,
    required this.hostAddress,
    required this.port,
    required this.gameType,
    required this.playerCount,
    required this.maxPlayers,
    required this.packName,
    required this.advertisedAt,
    this.maxRounds = 10,
    this.turnTimerSeconds = 0,
    this.allowSpicy = false,
    this.allowSkip = true,
  });

  final String sessionId;
  final String hostName;
  final String hostAddress;
  final int port;
  final GameType gameType;
  final int playerCount;
  final int maxPlayers;
  final String packName;
  final DateTime advertisedAt;
  final int maxRounds;
  final int turnTimerSeconds;
  final bool allowSpicy;
  final bool allowSkip;

  bool get isFull => playerCount >= maxPlayers;
  bool get isStale => DateTime.now().difference(advertisedAt).inSeconds > 10;

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'host_name': hostName,
    'host_address': hostAddress,
    'port': port,
    'game_type': gameType.toDbString(),
    'player_count': playerCount,
    'max_players': maxPlayers,
    'pack_name': packName,
    'ts': advertisedAt.millisecondsSinceEpoch,
    'max_rounds': maxRounds,
    'turn_timer_secs': turnTimerSeconds,
    'allow_spicy': allowSpicy,
    'allow_skip': allowSkip,
  };

  static LanRoomDescriptor fromJson(Map<String, dynamic> j) =>
      LanRoomDescriptor(
        sessionId: j['session_id'] as String,
        hostName: j['host_name'] as String,
        hostAddress: j['host_address'] as String,
        port: j['port'] as int,
        gameType: _parseGameType(j['game_type'] as String),
        playerCount: j['player_count'] as int? ?? 0,
        maxPlayers: j['max_players'] as int? ?? 6,
        packName: j['pack_name'] as String? ?? '',
        advertisedAt: DateTime.now(),
        maxRounds: j['max_rounds'] as int? ?? 10,
        turnTimerSeconds: j['turn_timer_secs'] as int? ?? 0,
        allowSpicy: j['allow_spicy'] as bool? ?? false,
        allowSkip: j['allow_skip'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [sessionId, hostAddress, port];

  LanRoomDescriptor copyWith({String? hostAddress}) => LanRoomDescriptor(
    sessionId: sessionId,
    hostName: hostName,
    hostAddress: hostAddress ?? this.hostAddress,
    port: port,
    gameType: gameType,
    playerCount: playerCount,
    maxPlayers: maxPlayers,
    packName: packName,
    advertisedAt: advertisedAt,
    maxRounds: maxRounds,
    turnTimerSeconds: turnTimerSeconds,
    allowSpicy: allowSpicy,
    allowSkip: allowSkip,
    // port:        port,
    // gameType:    gameType,
    // playerCount: playerCount,
    // maxPlayers:  maxPlayers,
    // packName:    packName,
    // advertisedAt: advertisedAt,
  );
}

// ── LAN message envelope ──────────────────────────────────────────────────────

enum LanMessageType {
  join,
  joinAck,
  leave,
  gameState,
  playerAction,
  ping,
  pong,
  roomInfo,
  startGame,
  lobbyUpdate,
  chat,
}

class LanMessage {
  const LanMessage({
    required this.type,
    required this.senderId,
    required this.payload,
    required this.ts,
  });

  final LanMessageType type;
  final String senderId;
  final Map<String, dynamic> payload;
  final int ts;

  String toJson() => jsonEncode({
    'type': type.name,
    'sender_id': senderId,
    'payload': payload,
    'ts': ts,
  });

  static LanMessage? fromJson(String raw) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return LanMessage(
        type: LanMessageType.values.firstWhere(
          (t) => t.name == m['type'],
          orElse: () => LanMessageType.ping,
        ),
        senderId: m['sender_id'] as String? ?? '',
        // Deep-cast so nested maps are also Map<String, dynamic>, not Map<dynamic, dynamic>
        payload: _deepCast(m['payload']) as Map<String, dynamic>? ?? {},
        ts: m['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      return null;
    }
  }

  /// Recursively cast all maps to Map<String, dynamic>.
  static dynamic _deepCast(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map(
          (e) => MapEntry(e.key.toString(), _deepCast(e.value)),
        ),
      );
    }
    if (value is List) {
      return value.map(_deepCast).toList();
    }
    return value;
  }
}

// ── Downloaded pack entry ─────────────────────────────────────────────────────

/// Summary of a locally-available pack (stored in SQLite).
class OfflinePack extends Equatable {
  const OfflinePack({
    required this.id,
    required this.name,
    required this.gameType,
    required this.language,
    required this.cardCount,
    this.isFree = false,
    this.coverImageUrl,
    this.expiresAt,
  });

  final String id;
  final String name;
  final GameType gameType;
  final String language;
  final int cardCount;
  final bool isFree;
  final String? coverImageUrl;
  final DateTime? expiresAt;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isUsable => !isExpired;

  @override
  List<Object?> get props => [id, name, gameType];
}

// ── Helpers ───────────────────────────────────────────────────────────────────

GameType _parseGameType(String s) => switch (s) {
  'truth_or_dare' => GameType.truthOrDare,
  'never_have_i_ever' => GameType.neverHaveIEver,
  'meme_game' => GameType.memeGame,
  _ => GameType.truthOrDare,
};
