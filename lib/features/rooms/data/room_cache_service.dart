// // // import 'dart:convert';

// // // import '../../../core/storage/database/app_database.dart';
// // // import '../../../core/utils/app_logger.dart';
// // // import '../domain/room_entity.dart';
// // // import 'package:sqflite/sqflite.dart';

// // // /// Local SQLite cache for room data.
// // // ///
// // // /// Purpose:
// // // /// - Show last-known room list instantly on app launch (before network load)
// // // /// - Cache chat messages so users see history immediately on rejoin
// // // /// - Store room metadata for offline room info display
// // // ///
// // // /// NOT used for: game state (too volatile), presence (ephemeral by nature)
// // // class RoomCacheService {
// // //   RoomCacheService._();
// // //   static final RoomCacheService _instance = RoomCacheService._();
// // //   static RoomCacheService get instance => _instance;

// // //   // ── Schema ────────────────────────────────────────────────────────────────
// // //   static const _schema = '''
// // //     CREATE TABLE IF NOT EXISTS cached_rooms (
// // //       id           TEXT PRIMARY KEY,
// // //       data         TEXT NOT NULL,
// // //       cached_at    INTEGER NOT NULL
// // //     );

// // //     CREATE TABLE IF NOT EXISTS cached_chat_messages (
// // //       id           TEXT PRIMARY KEY,
// // //       room_id      TEXT NOT NULL,
// // //       data         TEXT NOT NULL,
// // //       created_at   INTEGER NOT NULL
// // //     );

// // //     CREATE INDEX IF NOT EXISTS idx_cached_chat_room
// // //       ON cached_chat_messages (room_id, created_at DESC);
// // //   ''';

// // //   Future<void> initialize() async {
// // //     final db = AppDatabase.instance.db;
// // //     await db.execute(_schema);
// // //   }

// // //   // ── Rooms ─────────────────────────────────────────────────────────────────
// // //   Future<void> cacheRooms(List<RoomEntity> rooms) async {
// // //     final db = AppDatabase.instance.db;
// // //     final now = DateTime.now().millisecondsSinceEpoch;

// // //     final batch = db.batch();
// // //     for (final room in rooms) {
// // //       batch.insert(
// // //         'cached_rooms',
// // //         {'id': room.id, 'data': jsonEncode(_roomToMap(room)), 'cached_at': now},
// // //         // conflictAlgorithm: 5, // REPLACE
// // //         conflictAlgorithm: ConflictAlgorithm.replace,
// // //       );
// // //     }
// // //     await batch.commit(noResult: true);
// // //   }

// // //   Future<List<RoomEntity>> getCachedRooms() async {
// // //     final db = AppDatabase.instance.db;
// // //     // Only show rooms cached within the last 5 minutes
// // //     final cutoff = DateTime.now()
// // //         .subtract(const Duration(minutes: 5))
// // //         .millisecondsSinceEpoch;

// // //     final rows = await db.query(
// // //       'cached_rooms',
// // //       where: 'cached_at > ?',
// // //       whereArgs: [cutoff],
// // //       orderBy: 'cached_at DESC',
// // //       limit: 50,
// // //     );

// // //     return rows.map((r) {
// // //       final map = jsonDecode(r['data'] as String) as Map<String, dynamic>;
// // //       return _mapToRoom(map);
// // //     }).toList();
// // //   }

// // //   // ── Chat messages ─────────────────────────────────────────────────────────
// // //   Future<void> cacheChatMessages(
// // //     String roomId,
// // //     List<ChatMessageEntity> messages,
// // //   ) async {
// // //     final db = AppDatabase.instance.db;
// // //     final batch = db.batch();

// // //     for (final msg in messages) {
// // //       batch.insert(
// // //         'cached_chat_messages',
// // //         {
// // //           'id': msg.id,
// // //           'room_id': roomId,
// // //           'data': jsonEncode(_chatToMap(msg)),
// // //           'created_at': msg.createdAt.millisecondsSinceEpoch,
// // //         },
// // //         // conflictAlgorithm: 5, // REPLACE
// // //         conflictAlgorithm: ConflictAlgorithm.replace,
// // //       );
// // //     }
// // //     await batch.commit(noResult: true);

// // //     // Prune to last 200 messages per room
// // //     await db.execute(
// // //       '''
// // //       DELETE FROM cached_chat_messages
// // //       WHERE room_id = ? AND id NOT IN (
// // //         SELECT id FROM cached_chat_messages
// // //         WHERE room_id = ?
// // //         ORDER BY created_at DESC
// // //         LIMIT 200
// // //       )
// // //     ''',
// // //       [roomId, roomId],
// // //     );
// // //   }

// // //   Future<List<ChatMessageEntity>> getCachedChatMessages(
// // //     String roomId, {
// // //     int limit = 50,
// // //   }) async {
// // //     final db = AppDatabase.instance.db;
// // //     final rows = await db.query(
// // //       'cached_chat_messages',
// // //       where: 'room_id = ?',
// // //       whereArgs: [roomId],
// // //       orderBy: 'created_at ASC',
// // //       limit: limit,
// // //     );

// // //     return rows.map((r) {
// // //       final map = jsonDecode(r['data'] as String) as Map<String, dynamic>;
// // //       return _mapToChat(map);
// // //     }).toList();
// // //   }

// // //   Future<void> appendChatMessage(ChatMessageEntity msg) async {
// // //     final db = AppDatabase.instance.db;
// // //     await db.insert(
// // //       'cached_chat_messages',
// // //       {
// // //         'id': msg.id,
// // //         'room_id': msg.roomId,
// // //         'data': jsonEncode(_chatToMap(msg)),
// // //         'created_at': msg.createdAt.millisecondsSinceEpoch,
// // //       },
// // //       // conflictAlgorithm: 5,
// // //       conflictAlgorithm: ConflictAlgorithm.replace,
// // //     );
// // //   }

// // //   Future<void> clearRoomCache(String roomId) async {
// // //     final db = AppDatabase.instance.db;
// // //     await db.delete(
// // //       'cached_chat_messages',
// // //       where: 'room_id = ?',
// // //       whereArgs: [roomId],
// // //     );
// // //     AppLogger.debug('RoomCache: cleared chat for $roomId');
// // //   }

// // //   // ── Serialisation ─────────────────────────────────────────────────────────
// // //   Map<String, dynamic> _roomToMap(RoomEntity r) => {
// // //     'id': r.id,
// // //     'owner_id': r.ownerId,
// // //     'name': r.name,
// // //     'status': r.status.toDbString(),
// // //     'visibility': r.visibility.name,
// // //     'max_players': r.maxPlayers,
// // //     'current_players': r.currentPlayers,
// // //     'invite_code': r.inviteCode,
// // //     'language': r.language,
// // //     'allow_spicy': r.allowSpicy,
// // //     'cover_emoji': r.coverEmoji,
// // //     'last_active_at': r.lastActiveAt?.toIso8601String(),
// // //     'created_at': r.createdAt?.toIso8601String(),
// // //   };

// // //   RoomEntity _mapToRoom(Map<String, dynamic> m) => RoomEntity(
// // //     id: m['id'] as String,
// // //     ownerId: m['owner_id'] as String,
// // //     name: m['name'] as String,
// // //     status: RoomStatus.fromString(m['status'] as String? ?? 'waiting'),
// // //     visibility: RoomVisibility.fromString(
// // //       m['visibility'] as String? ?? 'public',
// // //     ),
// // //     maxPlayers: m['max_players'] as int? ?? 6,
// // //     currentPlayers: m['current_players'] as int? ?? 0,
// // //     inviteCode: m['invite_code'] as String?,
// // //     language: m['language'] as String? ?? 'en',
// // //     allowSpicy: m['allow_spicy'] as bool? ?? false,
// // //     coverEmoji: m['cover_emoji'] as String? ?? '🎮',
// // //   );

// // //   Map<String, dynamic> _chatToMap(ChatMessageEntity m) => {
// // //     'id': m.id,
// // //     'room_id': m.roomId,
// // //     'user_id': m.userId,
// // //     'display_name': m.displayName,
// // //     'avatar_url': m.avatarUrl,
// // //     'content': m.content,
// // //     'created_at': m.createdAt.toIso8601String(),
// // //     'is_deleted': m.isDeleted,
// // //   };

// // //   ChatMessageEntity _mapToChat(Map<String, dynamic> m) => ChatMessageEntity(
// // //     id: m['id'] as String,
// // //     roomId: m['room_id'] as String,
// // //     userId: m['user_id'] as String,
// // //     displayName: m['display_name'] as String? ?? 'Player',
// // //     avatarUrl: m['avatar_url'] as String?,
// // //     content: m['content'] as String,
// // //     createdAt: DateTime.parse(m['created_at'] as String),
// // //     isDeleted: m['is_deleted'] as bool? ?? false,
// // //   );
// // // }

// // import 'dart:convert';

// // import 'package:sqflite/sqflite.dart';

// // import '../../../core/storage/database/app_database.dart';
// // import '../../../core/utils/app_logger.dart';
// // import '../domain/room_entity.dart';

// // /// Local SQLite cache for room data.
// // ///
// // /// Purpose:
// // /// - Show last-known room list instantly on app launch (before network load)
// // /// - Cache chat messages so users see history immediately on rejoin
// // /// - Store room metadata for offline room info display
// // ///
// // /// NOT used for: game state (too volatile), presence (ephemeral by nature)
// // class RoomCacheService {
// //   RoomCacheService._();
// //   static final RoomCacheService _instance = RoomCacheService._();
// //   static RoomCacheService get instance => _instance;

// //   // ── Schema ────────────────────────────────────────────────────────────────
// //   static const _schema = '''
// //     CREATE TABLE IF NOT EXISTS cached_rooms (
// //       id           TEXT PRIMARY KEY,
// //       data         TEXT NOT NULL,
// //       cached_at    INTEGER NOT NULL
// //     );

// //     CREATE TABLE IF NOT EXISTS cached_chat_messages (
// //       id           TEXT PRIMARY KEY,
// //       room_id      TEXT NOT NULL,
// //       data         TEXT NOT NULL,
// //       created_at   INTEGER NOT NULL
// //     );

// //     CREATE INDEX IF NOT EXISTS idx_cached_chat_room
// //       ON cached_chat_messages (room_id, created_at DESC);
// //   ''';

// //   Future<void> initialize() async {
// //     final db = AppDatabase.instance.safeDb;
// //     if (db == null) return;
// //     await db.execute(_schema);
// //   }

// //   // ── Rooms ─────────────────────────────────────────────────────────────────
// //   Future<void> cacheRooms(List<RoomEntity> rooms) async {
// //     final db = AppDatabase.instance.safeDb;
// //     if (db == null) return;
// //     final now = DateTime.now().millisecondsSinceEpoch;

// //     final batch = db.batch();
// //     for (final room in rooms) {
// //       batch.insert('cached_rooms', {
// //         'id': room.id,
// //         'data': jsonEncode(_roomToMap(room)),
// //         'cached_at': now,
// //       }, conflictAlgorithm: ConflictAlgorithm.replace);
// //     }
// //     await batch.commit(noResult: true);
// //   }

// //   Future<List<RoomEntity>> getCachedRooms() async {
// //     final db = AppDatabase.instance.safeDb;
// //     if (db == null) return [];
// //     final cutoff = DateTime.now()
// //         .subtract(const Duration(minutes: 5))
// //         .millisecondsSinceEpoch;

// //     final rows = await db.query(
// //       'cached_rooms',
// //       where: 'cached_at > ?',
// //       whereArgs: [cutoff],
// //       orderBy: 'cached_at DESC',
// //       limit: 50,
// //     );

// //     return rows.map((r) {
// //       final map = jsonDecode(r['data'] as String) as Map<String, dynamic>;
// //       return _mapToRoom(map);
// //     }).toList();
// //   }

// //   // ── Chat messages ─────────────────────────────────────────────────────────
// //   Future<void> cacheChatMessages(
// //     String roomId,
// //     List<ChatMessageEntity> messages,
// //   ) async {
// //     final db = AppDatabase.instance.safeDb;
// //     if (db == null) return;
// //     final batch = db.batch();

// //     for (final msg in messages) {
// //       batch.insert('cached_chat_messages', {
// //         'id': msg.id,
// //         'room_id': roomId,
// //         'data': jsonEncode(_chatToMap(msg)),
// //         'created_at': msg.createdAt.millisecondsSinceEpoch,
// //       }, conflictAlgorithm: ConflictAlgorithm.replace);
// //     }
// //     await batch.commit(noResult: true);

// //     await db.execute(
// //       '''
// //       DELETE FROM cached_chat_messages
// //       WHERE room_id = ? AND id NOT IN (
// //         SELECT id FROM cached_chat_messages
// //         WHERE room_id = ?
// //         ORDER BY created_at DESC
// //         LIMIT 200
// //       )
// //     ''',
// //       [roomId, roomId],
// //     );
// //   }

// //   Future<List<ChatMessageEntity>> getCachedChatMessages(
// //     String roomId, {
// //     int limit = 50,
// //   }) async {
// //     final db = AppDatabase.instance.safeDb;
// //     if (db == null) return [];
// //     final rows = await db.query(
// //       'cached_chat_messages',
// //       where: 'room_id = ?',
// //       whereArgs: [roomId],
// //       orderBy: 'created_at ASC',
// //       limit: limit,
// //     );

// //     return rows.map((r) {
// //       final map = jsonDecode(r['data'] as String) as Map<String, dynamic>;
// //       return _mapToChat(map);
// //     }).toList();
// //   }

// //   Future<void> appendChatMessage(ChatMessageEntity msg) async {
// //     final db = AppDatabase.instance.safeDb;
// //     if (db == null) return;
// //     await db.insert('cached_chat_messages', {
// //       'id': msg.id,
// //       'room_id': msg.roomId,
// //       'data': jsonEncode(_chatToMap(msg)),
// //       'created_at': msg.createdAt.millisecondsSinceEpoch,
// //     }, conflictAlgorithm: ConflictAlgorithm.replace);
// //   }

// //   Future<void> clearRoomCache(String roomId) async {
// //     final db = AppDatabase.instance.safeDb;
// //     if (db == null) return;
// //     await db.delete(
// //       'cached_chat_messages',
// //       where: 'room_id = ?',
// //       whereArgs: [roomId],
// //     );
// //     AppLogger.debug('RoomCache: cleared chat for $roomId');
// //   }

// //   // ── Serialisation ─────────────────────────────────────────────────────────
// //   Map<String, dynamic> _roomToMap(RoomEntity r) => {
// //     'id': r.id,
// //     'owner_id': r.ownerId,
// //     'name': r.name,
// //     'status': r.status.toDbString(),
// //     'visibility': r.visibility.name,
// //     'max_players': r.maxPlayers,
// //     'current_players': r.currentPlayers,
// //     'invite_code': r.inviteCode,
// //     'language': r.language,
// //     'allow_spicy': r.allowSpicy,
// //     'cover_emoji': r.coverEmoji,
// //     'last_active_at': r.lastActiveAt?.toIso8601String(),
// //     'created_at': r.createdAt?.toIso8601String(),
// //   };

// //   RoomEntity _mapToRoom(Map<String, dynamic> m) => RoomEntity(
// //     id: m['id'] as String,
// //     ownerId: m['owner_id'] as String,
// //     name: m['name'] as String,
// //     status: RoomStatus.fromString(m['status'] as String? ?? 'waiting'),
// //     visibility: RoomVisibility.fromString(
// //       m['visibility'] as String? ?? 'public',
// //     ),
// //     maxPlayers: m['max_players'] as int? ?? 6,
// //     currentPlayers: m['current_players'] as int? ?? 0,
// //     inviteCode: m['invite_code'] as String?,
// //     language: m['language'] as String? ?? 'en',
// //     allowSpicy: m['allow_spicy'] as bool? ?? false,
// //     coverEmoji: m['cover_emoji'] as String? ?? '🎮',
// //   );

// //   Map<String, dynamic> _chatToMap(ChatMessageEntity m) => {
// //     'id': m.id,
// //     'room_id': m.roomId,
// //     'user_id': m.userId,
// //     'display_name': m.displayName,
// //     'avatar_url': m.avatarUrl,
// //     'content': m.content,
// //     'created_at': m.createdAt.toIso8601String(),
// //     'is_deleted': m.isDeleted,
// //   };

// //   ChatMessageEntity _mapToChat(Map<String, dynamic> m) => ChatMessageEntity(
// //     id: m['id'] as String,
// //     roomId: m['room_id'] as String,
// //     userId: m['user_id'] as String,
// //     displayName: m['display_name'] as String? ?? 'Player',
// //     avatarUrl: m['avatar_url'] as String?,
// //     content: m['content'] as String,
// //     createdAt: DateTime.parse(m['created_at'] as String),
// //     isDeleted: m['is_deleted'] as bool? ?? false,
// //   );
// // }

// import 'dart:convert';

// import 'package:sqflite/sqflite.dart';

// import '../../../core/storage/database/app_database.dart';
// import '../../../core/utils/app_logger.dart';
// import '../domain/room_entity.dart';

// /// Local SQLite cache for room data.
// ///
// /// Purpose:
// /// - Show last-known room list instantly on app launch (before network load)
// /// - Cache chat messages so users see history immediately on rejoin
// /// - Store room metadata for offline room info display
// ///
// /// NOT used for: game state (too volatile), presence (ephemeral by nature)
// class RoomCacheService {
//   RoomCacheService._();
//   static final RoomCacheService _instance = RoomCacheService._();
//   static RoomCacheService get instance => _instance;

//   // ── Schema ────────────────────────────────────────────────────────────────
//   static const _schema = '''
//     CREATE TABLE IF NOT EXISTS cached_rooms (
//       id           TEXT PRIMARY KEY,
//       data         TEXT NOT NULL,
//       cached_at    INTEGER NOT NULL
//     );

//     CREATE TABLE IF NOT EXISTS cached_chat_messages (
//       id           TEXT PRIMARY KEY,
//       room_id      TEXT NOT NULL,
//       data         TEXT NOT NULL,
//       created_at   INTEGER NOT NULL
//     );

//     CREATE INDEX IF NOT EXISTS idx_cached_chat_room
//       ON cached_chat_messages (room_id, created_at DESC);
//   ''';

//   Future<void> initialize() async {
//     if (!AppDatabase.instance.isOpen) return;
//     final db = AppDatabase.instance.db;
//     await db.execute(_schema);
//   }

//   // ── Rooms ─────────────────────────────────────────────────────────────────
//   Future<void> cacheRooms(List<RoomEntity> rooms) async {
//     if (!AppDatabase.instance.isOpen) return;
//     final db = AppDatabase.instance.db;
//     final now = DateTime.now().millisecondsSinceEpoch;

//     final batch = db.batch();
//     for (final room in rooms) {
//       batch.insert('cached_rooms', {
//         'id': room.id,
//         'data': jsonEncode(_roomToMap(room)),
//         'cached_at': now,
//       }, conflictAlgorithm: ConflictAlgorithm.replace);
//     }
//     await batch.commit(noResult: true);
//   }

//   Future<List<RoomEntity>> getCachedRooms() async {
//     if (!AppDatabase.instance.isOpen) return [];
//     final db = AppDatabase.instance.db;
//     final cutoff = DateTime.now()
//         .subtract(const Duration(minutes: 5))
//         .millisecondsSinceEpoch;

//     final rows = await db.query(
//       'cached_rooms',
//       where: 'cached_at > ?',
//       whereArgs: [cutoff],
//       orderBy: 'cached_at DESC',
//       limit: 50,
//     );

//     return rows.map((r) {
//       final map = jsonDecode(r['data'] as String) as Map<String, dynamic>;
//       return _mapToRoom(map);
//     }).toList();
//   }

//   // ── Chat messages ─────────────────────────────────────────────────────────
//   Future<void> cacheChatMessages(
//     String roomId,
//     List<ChatMessageEntity> messages,
//   ) async {
//     if (!AppDatabase.instance.isOpen) return;
//     final db = AppDatabase.instance.db;
//     final batch = db.batch();

//     for (final msg in messages) {
//       batch.insert('cached_chat_messages', {
//         'id': msg.id,
//         'room_id': roomId,
//         'data': jsonEncode(_chatToMap(msg)),
//         'created_at': msg.createdAt.millisecondsSinceEpoch,
//       }, conflictAlgorithm: ConflictAlgorithm.replace);
//     }
//     await batch.commit(noResult: true);

//     await db.execute(
//       '''
//       DELETE FROM cached_chat_messages
//       WHERE room_id = ? AND id NOT IN (
//         SELECT id FROM cached_chat_messages
//         WHERE room_id = ?
//         ORDER BY created_at DESC
//         LIMIT 200
//       )
//     ''',
//       [roomId, roomId],
//     );
//   }

//   // Future<List<ChatMessageEntity>> getCachedChatMessages(
//   //   String roomId, {
//   //   int limit = 50,
//   // }) async {
//   //   if (!AppDatabase.instance.isOpen) return [];
//   //   final db = AppDatabase.instance.db;
//   //   final rows = await db.query(
//   //     'cached_chat_messages',
//   //     where: 'room_id = ?',
//   //     whereArgs: [roomId],
//   //     orderBy: 'created_at ASC',
//   //     limit: limit,
//   //   );

//   //   return rows.map((r) {
//   //     final map = jsonDecode(r['data'] as String) as Map<String, dynamic>;
//   //     return _mapToChat(map);
//   //   }).toList();
//   // }

//   Future<List<ChatMessageEntity>> getCachedChatMessages(String roomId) async {
//     if (!AppDatabase.instance.isOpen) {
//       AppLogger.debug('Database not open – returning empty chat cache');
//       return [];
//     }
//     try {
//       final db = AppDatabase.instance.db;
//       final result = await db.query(
//         'cached_chat_messages',
//         where: 'room_id = ?',
//         whereArgs: [roomId],
//         orderBy: 'created_at ASC',
//         limit: 50,
//       );
//       return result.map((row) => ChatMessageEntity.fromMap(row)).toList();
//     } catch (e) {
//       AppLogger.error('Failed to get cached chat messages', error: e);
//       return [];
//     }
//   }

//   Future<void> appendChatMessage(ChatMessageEntity msg) async {
//     if (!AppDatabase.instance.isOpen) return;
//     final db = AppDatabase.instance.db;
//     await db.insert('cached_chat_messages', {
//       'id': msg.id,
//       'room_id': msg.roomId,
//       'data': jsonEncode(_chatToMap(msg)),
//       'created_at': msg.createdAt.millisecondsSinceEpoch,
//     }, conflictAlgorithm: ConflictAlgorithm.replace);
//   }

//   Future<void> clearRoomCache(String roomId) async {
//     if (!AppDatabase.instance.isOpen) return;
//     final db = AppDatabase.instance.db;
//     await db.delete(
//       'cached_chat_messages',
//       where: 'room_id = ?',
//       whereArgs: [roomId],
//     );
//     AppLogger.debug('RoomCache: cleared chat for $roomId');
//   }

//   // ── Serialisation ─────────────────────────────────────────────────────────
//   Map<String, dynamic> _roomToMap(RoomEntity r) => {
//     'id': r.id,
//     'owner_id': r.ownerId,
//     'name': r.name,
//     'status': r.status.toDbString(),
//     'visibility': r.visibility.name,
//     'max_players': r.maxPlayers,
//     'current_players': r.currentPlayers,
//     'invite_code': r.inviteCode,
//     'language': r.language,
//     'allow_spicy': r.allowSpicy,
//     'cover_emoji': r.coverEmoji,
//     'last_active_at': r.lastActiveAt?.toIso8601String(),
//     'created_at': r.createdAt?.toIso8601String(),
//   };

//   RoomEntity _mapToRoom(Map<String, dynamic> m) => RoomEntity(
//     id: m['id'] as String,
//     ownerId: m['owner_id'] as String,
//     name: m['name'] as String,
//     status: RoomStatus.fromString(m['status'] as String? ?? 'waiting'),
//     visibility: RoomVisibility.fromString(
//       m['visibility'] as String? ?? 'public',
//     ),
//     maxPlayers: m['max_players'] as int? ?? 6,
//     currentPlayers: m['current_players'] as int? ?? 0,
//     inviteCode: m['invite_code'] as String?,
//     language: m['language'] as String? ?? 'en',
//     allowSpicy: m['allow_spicy'] as bool? ?? false,
//     coverEmoji: m['cover_emoji'] as String? ?? '🎮',
//   );

//   Map<String, dynamic> _chatToMap(ChatMessageEntity m) => {
//     'id': m.id,
//     'room_id': m.roomId,
//     'user_id': m.userId,
//     'display_name': m.displayName,
//     'avatar_url': m.avatarUrl,
//     'content': m.content,
//     'created_at': m.createdAt.toIso8601String(),
//     'is_deleted': m.isDeleted,
//   };

//   ChatMessageEntity _mapToChat(Map<String, dynamic> m) => ChatMessageEntity(
//     id: m['id'] as String,
//     roomId: m['room_id'] as String,
//     userId: m['user_id'] as String,
//     displayName: m['display_name'] as String? ?? 'Player',
//     avatarUrl: m['avatar_url'] as String?,
//     content: m['content'] as String,
//     createdAt: DateTime.parse(m['created_at'] as String),
//     isDeleted: m['is_deleted'] as bool? ?? false,
//   );
// }

import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/storage/database/app_database.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/room_entity.dart';

/// Local SQLite cache for room data.
///
/// Purpose:
/// - Show last-known room list instantly on app launch (before network load)
/// - Cache chat messages so users see history immediately on rejoin
/// - Store room metadata for offline room info display
///
/// NOT used for: game state (too volatile), presence (ephemeral by nature)
class RoomCacheService {
  RoomCacheService._();
  static final RoomCacheService _instance = RoomCacheService._();
  static RoomCacheService get instance => _instance;

  // ── Schema ────────────────────────────────────────────────────────────────
  static const _schema = '''
    CREATE TABLE IF NOT EXISTS cached_rooms (
      id           TEXT PRIMARY KEY,
      data         TEXT NOT NULL,
      cached_at    INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS cached_chat_messages (
      id           TEXT PRIMARY KEY,
      room_id      TEXT NOT NULL,
      data         TEXT NOT NULL,
      created_at   INTEGER NOT NULL
    );

    CREATE INDEX IF NOT EXISTS idx_cached_chat_room
      ON cached_chat_messages (room_id, created_at DESC);
  ''';

  Future<void> initialize() async {
    if (!AppDatabase.instance.isOpen) return;
    await _ensureTables();
  }

  Future<void> _ensureTables() async {
    final db = AppDatabase.instance.db;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_rooms (
        id        TEXT PRIMARY KEY,
        data      TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_chat_messages (
        id         TEXT PRIMARY KEY,
        room_id    TEXT NOT NULL,
        data       TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_chat_room ON cached_chat_messages(room_id, created_at)',
    );
  }

  // ── Rooms ─────────────────────────────────────────────────────────────────
  Future<void> cacheRooms(List<RoomEntity> rooms) async {
    if (!AppDatabase.instance.isOpen) return;
    await _ensureTables();
    final db = AppDatabase.instance.db;
    final now = DateTime.now().millisecondsSinceEpoch;

    final batch = db.batch();
    for (final room in rooms) {
      batch.insert('cached_rooms', {
        'id': room.id,
        'data': jsonEncode(_roomToMap(room)),
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<RoomEntity>> getCachedRooms() async {
    if (!AppDatabase.instance.isOpen) return [];
    await _ensureTables();
    final db = AppDatabase.instance.db;
    final cutoff = DateTime.now()
        .subtract(const Duration(minutes: 5))
        .millisecondsSinceEpoch;

    final rows = await db.query(
      'cached_rooms',
      where: 'cached_at > ?',
      whereArgs: [cutoff],
      orderBy: 'cached_at DESC',
      limit: 50,
    );

    return rows.map((r) {
      final map = jsonDecode(r['data'] as String) as Map<String, dynamic>;
      return _mapToRoom(map);
    }).toList();
  }

  // ── Chat messages ─────────────────────────────────────────────────────────
  Future<void> cacheChatMessages(
    String roomId,
    List<ChatMessageEntity> messages,
  ) async {
    if (!AppDatabase.instance.isOpen) return;
    final db = AppDatabase.instance.db;
    final batch = db.batch();

    for (final msg in messages) {
      batch.insert('cached_chat_messages', {
        'id': msg.id,
        'room_id': roomId,
        'data': jsonEncode(_chatToMap(msg)),
        'created_at': msg.createdAt.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);

    await db.execute(
      '''
      DELETE FROM cached_chat_messages
      WHERE room_id = ? AND id NOT IN (
        SELECT id FROM cached_chat_messages
        WHERE room_id = ?
        ORDER BY created_at DESC
        LIMIT 200
      )
    ''',
      [roomId, roomId],
    );
  }

  Future<List<ChatMessageEntity>> getCachedChatMessages(
    String roomId, {
    int limit = 50,
  }) async {
    if (!AppDatabase.instance.isOpen) return [];
    await _ensureTables();
    final db = AppDatabase.instance.db;
    final rows = await db.query(
      'cached_chat_messages',
      where: 'room_id = ?',
      whereArgs: [roomId],
      orderBy: 'created_at ASC',
      limit: limit,
    );

    return rows.map((r) {
      final map = jsonDecode(r['data'] as String) as Map<String, dynamic>;
      return _mapToChat(map);
    }).toList();
  }

  Future<void> appendChatMessage(ChatMessageEntity msg) async {
    if (!AppDatabase.instance.isOpen) return;
    final db = AppDatabase.instance.db;
    await db.insert('cached_chat_messages', {
      'id': msg.id,
      'room_id': msg.roomId,
      'data': jsonEncode(_chatToMap(msg)),
      'created_at': msg.createdAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearRoomCache(String roomId) async {
    if (!AppDatabase.instance.isOpen) return;
    final db = AppDatabase.instance.db;
    await db.delete(
      'cached_chat_messages',
      where: 'room_id = ?',
      whereArgs: [roomId],
    );
    AppLogger.debug('RoomCache: cleared chat for $roomId');
  }

  // ── Serialisation ─────────────────────────────────────────────────────────
  Map<String, dynamic> _roomToMap(RoomEntity r) => {
    'id': r.id,
    'owner_id': r.ownerId,
    'name': r.name,
    'status': r.status.toDbString(),
    'visibility': r.visibility.name,
    'max_players': r.maxPlayers,
    'current_players': r.currentPlayers,
    'invite_code': r.inviteCode,
    'language': r.language,
    'allow_spicy': r.allowSpicy,
    'cover_emoji': r.coverEmoji,
    'last_active_at': r.lastActiveAt?.toIso8601String(),
    'created_at': r.createdAt?.toIso8601String(),
  };

  RoomEntity _mapToRoom(Map<String, dynamic> m) => RoomEntity(
    id: m['id'] as String,
    ownerId: m['owner_id'] as String,
    name: m['name'] as String,
    status: RoomStatus.fromString(m['status'] as String? ?? 'waiting'),
    visibility: RoomVisibility.fromString(
      m['visibility'] as String? ?? 'public',
    ),
    maxPlayers: m['max_players'] as int? ?? 6,
    currentPlayers: m['current_players'] as int? ?? 0,
    inviteCode: m['invite_code'] as String?,
    language: m['language'] as String? ?? 'en',
    allowSpicy: m['allow_spicy'] as bool? ?? false,
    coverEmoji: m['cover_emoji'] as String? ?? '🎮',
  );

  Map<String, dynamic> _chatToMap(ChatMessageEntity m) => {
    'id': m.id,
    'room_id': m.roomId,
    'user_id': m.userId,
    'display_name': m.displayName,
    'avatar_url': m.avatarUrl,
    'content': m.content,
    'created_at': m.createdAt.toIso8601String(),
    'is_deleted': m.isDeleted,
  };

  ChatMessageEntity _mapToChat(Map<String, dynamic> m) => ChatMessageEntity(
    id: m['id'] as String,
    roomId: m['room_id'] as String,
    userId: m['user_id'] as String,
    displayName: m['display_name'] as String? ?? 'Player',
    avatarUrl: m['avatar_url'] as String?,
    content: m['content'] as String,
    createdAt: DateTime.parse(m['created_at'] as String),
    isDeleted: m['is_deleted'] as bool? ?? false,
  );
}
