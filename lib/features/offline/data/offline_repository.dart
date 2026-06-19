// // // // import 'dart:convert';

// // // // import 'package:sqflite/sqflite.dart';

// // // // import '../../../core/storage/database/app_database.dart';
// // // // import '../../../core/utils/app_logger.dart';
// // // // import '../../games/engine/base_game_engine.dart';
// // // // import '../domain/offline_session.dart';

// // // // /// Local SQLite repository for offline sessions and pack queries.
// // // // ///
// // // // /// Schema (added to existing AppDatabase via migration v2):
// // // // ///   offline_sessions  — persisted session state for crash-resume
// // // // ///
// // // // /// Pack data lives in the existing `packs` + `pack_cards` tables.
// // // // class OfflineRepository {
// // // //   OfflineRepository._();
// // // //   static final OfflineRepository _instance = OfflineRepository._();
// // // //   static OfflineRepository get instance => _instance;

// // // //   Database get _db => AppDatabase.instance.db;

// // // //   // ── Schema (call from AppDatabase._migration002) ──────────────────────────
// // // //   static const schemaV2 = '''
// // // //     CREATE TABLE IF NOT EXISTS offline_sessions (
// // // //       id             TEXT    PRIMARY KEY,
// // // //       mode           TEXT    NOT NULL DEFAULT 'pass_and_play',
// // // //       game_type      TEXT    NOT NULL,
// // // //       config_json    TEXT    NOT NULL,
// // // //       players_json   TEXT    NOT NULL,
// // // //       pack_id        TEXT    NOT NULL,
// // // //       pack_name      TEXT    NOT NULL,
// // // //       state_snapshot TEXT,
// // // //       is_active      INTEGER NOT NULL DEFAULT 1,
// // // //       created_at     INTEGER NOT NULL,
// // // //       resumed_at     INTEGER
// // // //     );
// // // //     CREATE INDEX IF NOT EXISTS idx_offline_sessions_active
// // // //       ON offline_sessions (is_active, created_at DESC);
// // // //   ''';

// // // //   // ── Sessions ──────────────────────────────────────────────────────────────

// // // //   Future<void> saveSession(OfflineSession session) async {
// // // //     await _db.insert(
// // // //       'offline_sessions',
// // // //       session.toMap(),
// // // //       conflictAlgorithm: ConflictAlgorithm.replace,
// // // //     );
// // // //   }

// // // //   Future<void> updateSnapshot(String sessionId, String snapshotJson) async {
// // // //     await _db.update(
// // // //       'offline_sessions',
// // // //       {
// // // //         'state_snapshot': snapshotJson,
// // // //         'is_active':      1,
// // // //         'resumed_at':     DateTime.now().millisecondsSinceEpoch,
// // // //       },
// // // //       where: 'id = ?',
// // // //       whereArgs: [sessionId],
// // // //     );
// // // //   }

// // // //   Future<void> endSession(String sessionId) async {
// // // //     await _db.update(
// // // //       'offline_sessions',
// // // //       {'is_active': 0},
// // // //       where: 'id = ?',
// // // //       whereArgs: [sessionId],
// // // //     );
// // // //   }

// // // //   /// Returns the most recent resumable session, if any.
// // // //   Future<OfflineSession?> getActiveSession() async {
// // // //     final rows = await _db.query(
// // // //       'offline_sessions',
// // // //       where:   'is_active = 1 AND state_snapshot IS NOT NULL',
// // // //       orderBy: 'resumed_at DESC, created_at DESC',
// // // //       limit:   1,
// // // //     );
// // // //     if (rows.isEmpty) return null;
// // // //     return OfflineSession.fromMap(rows.first);
// // // //   }

// // // //   Future<List<OfflineSession>> getRecentSessions({int limit = 5}) async {
// // // //     final rows = await _db.query(
// // // //       'offline_sessions',
// // // //       orderBy: 'created_at DESC',
// // // //       limit:   limit,
// // // //     );
// // // //     return rows.map(OfflineSession.fromMap).toList();
// // // //   }

// // // //   // ── Packs ──────────────────────────────────────────────────────────────────

// // // //   /// Returns all locally-cached packs available for offline play,
// // // //   /// filtered by game type (card_type column maps to game type).
// // // //   Future<List<OfflinePack>> getAvailablePacks({
// // // //     GameType? gameType,
// // // //     String    language = 'en',
// // // //   }) async {
// // // //     try {
// // // //       // Join packs with purchase records to check expiry
// // // //       String sql = '''
// // // //         SELECT p.id, p.name_json, p.game_type, p.language, p.price,
// // // //                COUNT(pc.id) as card_count,
// // // //                pu.expires_at
// // // //         FROM packs p
// // // //         LEFT JOIN pack_cards pc ON pc.pack_id = p.id
// // // //         LEFT JOIN purchases pu  ON pu.pack_id = p.id
// // // //         WHERE 1=1
// // // //       ''';

// // // //       final args = <Object>[];

// // // //       if (gameType != null) {
// // // //         sql += ' AND p.game_type = ?';
// // // //         args.add(gameType.toDbString());
// // // //       }

// // // //       // Only packs that are either free (price=0) or not expired
// // // //       sql += ''' AND (
// // // //           p.price = 0
// // // //           OR (pu.expires_at IS NOT NULL AND pu.expires_at > ?)
// // // //         )''';
// // // //       args.add(DateTime.now().millisecondsSinceEpoch);

// // // //       sql += ' GROUP BY p.id HAVING card_count > 0';
// // // //       sql += ' ORDER BY p.name_json ASC';

// // // //       final rows = await _db.rawQuery(sql, args);

// // // //       return rows.map((r) {
// // // //         final nameJson = jsonDecode(r['name_json'] as String) as Map<String, dynamic>;
// // // //         final name = nameJson[language] as String? ??
// // // //             nameJson['en']             as String? ?? 'Pack';
// // // //         final expiresMs = r['expires_at'] as int?;

// // // //         return OfflinePack(
// // // //           id:        r['id']        as String,
// // // //           name:      name,
// // // //           gameType:  _parseGameType(r['game_type'] as String? ?? ''),
// // // //           language:  r['language']  as String? ?? 'en',
// // // //           cardCount: r['card_count'] as int,
// // // //           isFree:    (r['price'] as int?) == 0,
// // // //           expiresAt: expiresMs != null
// // // //               ? DateTime.fromMillisecondsSinceEpoch(expiresMs) : null,
// // // //         );
// // // //       }).toList();
// // // //     } catch (e) {
// // // //       AppLogger.error('OfflineRepository: getAvailablePacks failed', error: e);
// // // //       return [];
// // // //     }
// // // //   }

// // // //   /// Check whether a specific pack is available offline.
// // // //   Future<bool> isPackAvailable(String packId) async {
// // // //     final rows = await _db.rawQuery(
// // // //       '''
// // // //       SELECT p.id FROM packs p
// // // //       LEFT JOIN purchases pu ON pu.pack_id = p.id
// // // //       WHERE p.id = ?
// // // //         AND (p.price = 0 OR (pu.expires_at IS NOT NULL AND pu.expires_at > ?))
// // // //       LIMIT 1
// // // //       ''',
// // // //       [packId, DateTime.now().millisecondsSinceEpoch],
// // // //     );
// // // //     return rows.isNotEmpty;
// // // //   }

// // // //   /// Total count of offline-usable packs (for the offline home badge).
// // // //   Future<int> getAvailablePackCount() async {
// // // //     final result = await _db.rawQuery(
// // // //       '''
// // // //       SELECT COUNT(DISTINCT p.id) as cnt FROM packs p
// // // //       LEFT JOIN purchases pu ON pu.pack_id = p.id
// // // //       WHERE p.price = 0
// // // //          OR (pu.expires_at IS NOT NULL AND pu.expires_at > ?)
// // // //       ''',
// // // //       [DateTime.now().millisecondsSinceEpoch],
// // // //     );
// // // //     return result.first['cnt'] as int? ?? 0;
// // // //   }

// // // //   /// Clean up sessions older than 7 days.
// // // //   Future<void> pruneOldSessions() async {
// // // //     final cutoff = DateTime.now()
// // // //         .subtract(const Duration(days: 7))
// // // //         .millisecondsSinceEpoch;
// // // //     await _db.delete(
// // // //       'offline_sessions',
// // // //       where:     'created_at < ? AND is_active = 0',
// // // //       whereArgs: [cutoff],
// // // //     );
// // // //   }
// // // // }

// // // // GameType _parseGameType(String s) => switch (s) {
// // // //   'truth_or_dare'     => GameType.truthOrDare,
// // // //   'never_have_i_ever' => GameType.neverHaveIEver,
// // // //   'meme_game'         => GameType.memeGame,
// // // //   _                   => GameType.truthOrDare,
// // // // };

// // // import 'dart:convert';

// // // import 'package:sqflite/sqflite.dart';

// // // import '../../../core/storage/database/app_database.dart';
// // // import '../../../core/utils/app_logger.dart';
// // // import '../../games/engine/base_game_engine.dart';
// // // import '../domain/offline_session.dart';

// // // /// Local SQLite repository for offline sessions and pack queries.
// // // ///
// // // /// Schema (added to existing AppDatabase via migration v2):
// // // ///   offline_sessions  — persisted session state for crash-resume
// // // ///
// // // /// Pack data lives in the existing `packs` + `pack_cards` tables.
// // // class OfflineRepository {
// // //   OfflineRepository._();
// // //   static final OfflineRepository _instance = OfflineRepository._();
// // //   static OfflineRepository get instance => _instance;

// // //   Database get _db => AppDatabase.instance.db;

// // //   // ── Schema (call from AppDatabase._migration002) ──────────────────────────
// // //   static const schemaV2 = '''
// // //     CREATE TABLE IF NOT EXISTS offline_sessions (
// // //       id             TEXT    PRIMARY KEY,
// // //       mode           TEXT    NOT NULL DEFAULT 'pass_and_play',
// // //       game_type      TEXT    NOT NULL,
// // //       config_json    TEXT    NOT NULL,
// // //       players_json   TEXT    NOT NULL,
// // //       pack_id        TEXT    NOT NULL,
// // //       pack_name      TEXT    NOT NULL,
// // //       state_snapshot TEXT,
// // //       is_active      INTEGER NOT NULL DEFAULT 1,
// // //       created_at     INTEGER NOT NULL,
// // //       resumed_at     INTEGER
// // //     );
// // //     CREATE INDEX IF NOT EXISTS idx_offline_sessions_active
// // //       ON offline_sessions (is_active, created_at DESC);
// // //   ''';

// // //   // ── Sessions ──────────────────────────────────────────────────────────────

// // //   Future<void> saveSession(OfflineSession session) async {
// // //     await _db.insert(
// // //       'offline_sessions',
// // //       session.toMap(),
// // //       conflictAlgorithm: ConflictAlgorithm.replace,
// // //     );
// // //   }

// // //   Future<void> updateSnapshot(String sessionId, String snapshotJson) async {
// // //     await _db.update(
// // //       'offline_sessions',
// // //       {
// // //         'state_snapshot': snapshotJson,
// // //         'is_active': 1,
// // //         'resumed_at': DateTime.now().millisecondsSinceEpoch,
// // //       },
// // //       where: 'id = ?',
// // //       whereArgs: [sessionId],
// // //     );
// // //   }

// // //   Future<void> endSession(String sessionId) async {
// // //     await _db.update(
// // //       'offline_sessions',
// // //       {'is_active': 0},
// // //       where: 'id = ?',
// // //       whereArgs: [sessionId],
// // //     );
// // //   }

// // //   /// Returns the most recent resumable session, if any.
// // //   Future<OfflineSession?> getActiveSession() async {
// // //     final rows = await _db.query(
// // //       'offline_sessions',
// // //       where: 'is_active = 1 AND state_snapshot IS NOT NULL',
// // //       orderBy: 'resumed_at DESC, created_at DESC',
// // //       limit: 1,
// // //     );
// // //     if (rows.isEmpty) return null;
// // //     return OfflineSession.fromMap(rows.first);
// // //   }

// // //   Future<List<OfflineSession>> getRecentSessions({int limit = 5}) async {
// // //     final rows = await _db.query(
// // //       'offline_sessions',
// // //       orderBy: 'created_at DESC',
// // //       limit: limit,
// // //     );
// // //     return rows.map(OfflineSession.fromMap).toList();
// // //   }

// // //   // ── Packs ──────────────────────────────────────────────────────────────────

// // //   /// Returns all locally-cached packs available for offline play,
// // //   /// filtered by game type (card_type column maps to game type).
// // //   Future<List<OfflinePack>> getAvailablePacks({
// // //     GameType? gameType,
// // //     String language = 'en',
// // //   }) async {
// // //     try {
// // //       // Join packs with purchase records to check expiry
// // //       String sql = '''
// // //         SELECT p.id, p.name_json, p.game_type, p.language, p.price,
// // //                COUNT(pc.id) as card_count,
// // //                pu.expires_at
// // //         FROM packs p
// // //         LEFT JOIN pack_cards pc ON pc.pack_id = p.id
// // //         LEFT JOIN purchases pu  ON pu.pack_id = p.id
// // //         WHERE 1=1
// // //       ''';

// // //       final args = <Object>[];

// // //       if (gameType != null) {
// // //         sql += ' AND p.game_type = ?';
// // //         args.add(gameType.toDbString());
// // //       }

// // //       // Only packs that are either free (price=0) or not expired
// // //       sql += ''' AND (
// // //           p.price = 0
// // //           OR (pu.expires_at IS NOT NULL AND pu.expires_at > ?)
// // //         )''';
// // //       args.add(DateTime.now().millisecondsSinceEpoch);

// // //       sql += ' GROUP BY p.id HAVING card_count > 0';
// // //       sql += ' ORDER BY p.name_json ASC';

// // //       final rows = await _db.rawQuery(sql, args);

// // //       return rows.map((r) {
// // //         final nameJson =
// // //             jsonDecode(r['name_json'] as String) as Map<String, dynamic>;
// // //         final name =
// // //             nameJson[language] as String? ??
// // //             nameJson['en'] as String? ??
// // //             'Pack';
// // //         final expiresMs = r['expires_at'] as int?;

// // //         return OfflinePack(
// // //           id: r['id'] as String,
// // //           name: name,
// // //           gameType: _parseGameType(r['game_type'] as String? ?? ''),
// // //           language: r['language'] as String? ?? 'en',
// // //           cardCount: r['card_count'] as int,
// // //           isFree: (r['price'] as int?) == 0,
// // //           expiresAt: expiresMs != null
// // //               ? DateTime.fromMillisecondsSinceEpoch(expiresMs)
// // //               : null,
// // //         );
// // //       }).toList();
// // //     } catch (e) {
// // //       AppLogger.error('OfflineRepository: getAvailablePacks failed', error: e);
// // //       return [];
// // //     }
// // //   }

// // //   /// Check whether a specific pack is available offline.
// // //   Future<bool> isPackAvailable(String packId) async {
// // //     final rows = await _db.rawQuery(
// // //       '''
// // //       SELECT p.id FROM packs p
// // //       LEFT JOIN purchases pu ON pu.pack_id = p.id
// // //       WHERE p.id = ?
// // //         AND (p.price = 0 OR (pu.expires_at IS NOT NULL AND pu.expires_at > ?))
// // //       LIMIT 1
// // //       ''',
// // //       [packId, DateTime.now().millisecondsSinceEpoch],
// // //     );
// // //     return rows.isNotEmpty;
// // //   }

// // //   /// Total count of offline-usable packs (for the offline home badge).
// // //   Future<int> getAvailablePackCount() async {
// // //     if (!AppDatabase.instance.isOpen) return 0;
// // //     final result = await _db.rawQuery(
// // //       '''
// // //       SELECT COUNT(DISTINCT p.id) as cnt FROM packs p
// // //       LEFT JOIN purchases pu ON pu.pack_id = p.id
// // //       WHERE p.price = 0
// // //          OR (pu.expires_at IS NOT NULL AND pu.expires_at > ?)
// // //       ''',
// // //       [DateTime.now().millisecondsSinceEpoch],
// // //     );
// // //     return result.first['cnt'] as int? ?? 0;
// // //   }

// // //   /// Clean up sessions older than 7 days.
// // //   Future<void> pruneOldSessions() async {
// // //     final cutoff = DateTime.now()
// // //         .subtract(const Duration(days: 7))
// // //         .millisecondsSinceEpoch;
// // //     await _db.delete(
// // //       'offline_sessions',
// // //       where: 'created_at < ? AND is_active = 0',
// // //       whereArgs: [cutoff],
// // //     );
// // //   }
// // // }

// // // GameType _parseGameType(String s) => switch (s) {
// // //   'truth_or_dare' => GameType.truthOrDare,
// // //   'never_have_i_ever' => GameType.neverHaveIEver,
// // //   'meme_game' => GameType.memeGame,
// // //   _ => GameType.truthOrDare,
// // // };

// // import 'dart:convert';

// // import 'package:sqflite/sqflite.dart';

// // import '../../../core/storage/database/app_database.dart';
// // import '../../../core/utils/app_logger.dart';
// // import '../../games/engine/base_game_engine.dart';
// // import '../domain/offline_session.dart';

// // /// Local SQLite repository for offline sessions and pack queries.
// // ///
// // /// Schema (added to existing AppDatabase via migration v2):
// // ///   offline_sessions  — persisted session state for crash-resume
// // ///
// // /// Pack data lives in the existing `packs` + `pack_cards` tables.
// // class OfflineRepository {
// //   OfflineRepository._();
// //   static final OfflineRepository _instance = OfflineRepository._();
// //   static OfflineRepository get instance => _instance;

// //   Database get _db => AppDatabase.instance.db;

// //   // ── Schema (call from AppDatabase._migration002) ──────────────────────────
// //   static const schemaV2 = '''
// //     CREATE TABLE IF NOT EXISTS offline_sessions (
// //       id             TEXT    PRIMARY KEY,
// //       mode           TEXT    NOT NULL DEFAULT 'pass_and_play',
// //       game_type      TEXT    NOT NULL,
// //       config_json    TEXT    NOT NULL,
// //       players_json   TEXT    NOT NULL,
// //       pack_id        TEXT    NOT NULL,
// //       pack_name      TEXT    NOT NULL,
// //       state_snapshot TEXT,
// //       is_active      INTEGER NOT NULL DEFAULT 1,
// //       created_at     INTEGER NOT NULL,
// //       resumed_at     INTEGER
// //     );
// //     CREATE INDEX IF NOT EXISTS idx_offline_sessions_active
// //       ON offline_sessions (is_active, created_at DESC);
// //   ''';

// //   // ── Sessions ──────────────────────────────────────────────────────────────

// //   Future<void> saveSession(OfflineSession session) async {
// //     await _db.insert(
// //       'offline_sessions',
// //       session.toMap(),
// //       conflictAlgorithm: ConflictAlgorithm.replace,
// //     );
// //   }

// //   Future<void> updateSnapshot(String sessionId, String snapshotJson) async {
// //     await _db.update(
// //       'offline_sessions',
// //       {
// //         'state_snapshot': snapshotJson,
// //         'is_active': 1,
// //         'resumed_at': DateTime.now().millisecondsSinceEpoch,
// //       },
// //       where: 'id = ?',
// //       whereArgs: [sessionId],
// //     );
// //   }

// //   Future<void> endSession(String sessionId) async {
// //     await _db.update(
// //       'offline_sessions',
// //       {'is_active': 0},
// //       where: 'id = ?',
// //       whereArgs: [sessionId],
// //     );
// //   }

// //   /// Returns the most recent resumable session, if any.
// //   Future<OfflineSession?> getActiveSession() async {
// //     final rows = await _db.query(
// //       'offline_sessions',
// //       where: 'is_active = 1 AND state_snapshot IS NOT NULL',
// //       orderBy: 'resumed_at DESC, created_at DESC',
// //       limit: 1,
// //     );
// //     if (rows.isEmpty) return null;
// //     return OfflineSession.fromMap(rows.first);
// //   }

// //   Future<List<OfflineSession>> getRecentSessions({int limit = 5}) async {
// //     final rows = await _db.query(
// //       'offline_sessions',
// //       orderBy: 'created_at DESC',
// //       limit: limit,
// //     );
// //     return rows.map(OfflineSession.fromMap).toList();
// //   }

// //   // ── Packs ──────────────────────────────────────────────────────────────────

// //   /// Returns all locally-cached packs available for offline play,
// //   /// filtered by game type (card_type column maps to game type).
// //   Future<List<OfflinePack>> getAvailablePacks({
// //     GameType? gameType,
// //     String language = 'en',
// //   }) async {
// //     try {
// //       // All downloaded packs are available — download itself is the access gate
// //       String sql = '''
// //         SELECT p.id, p.name_json, p.game_type, p.language, p.price,
// //                COUNT(pc.id) as card_count
// //         FROM packs p
// //         LEFT JOIN pack_cards pc ON pc.pack_id = p.id
// //         WHERE 1=1
// //       ''';

// //       final args = <Object>[];

// //       if (gameType != null) {
// //         sql += ' AND p.game_type = ?';
// //         args.add(gameType.toDbString());
// //       }

// //       sql += ' GROUP BY p.id HAVING card_count > 0';
// //       sql += ' ORDER BY p.name_json ASC';

// //       final rows = await _db.rawQuery(sql, args);

// //       return rows.map((r) {
// //         final nameJson =
// //             jsonDecode(r['name_json'] as String) as Map<String, dynamic>;
// //         final name =
// //             nameJson[language] as String? ??
// //             nameJson['en'] as String? ??
// //             'Pack';

// //         return OfflinePack(
// //           id: r['id'] as String,
// //           name: name,
// //           gameType: _parseGameType(r['game_type'] as String? ?? ''),
// //           language: r['language'] as String? ?? 'en',
// //           cardCount: r['card_count'] as int,
// //           isFree: (r['price'] as int?) == 0,
// //           expiresAt: null,
// //         );
// //       }).toList();
// //     } catch (e) {
// //       AppLogger.error('OfflineRepository: getAvailablePacks failed', error: e);
// //       return [];
// //     }
// //   }

// //   /// Check whether a specific pack is available offline.
// //   Future<bool> isPackAvailable(String packId) async {
// //     final rows = await _db.rawQuery(
// //       'SELECT id FROM packs WHERE id = ? LIMIT 1',
// //       [packId],
// //     );
// //     return rows.isNotEmpty;
// //   }

// //   /// Total count of offline-usable packs (for the offline home badge).
// //   Future<int> getAvailablePackCount() async {
// //     if (!AppDatabase.instance.isOpen) return 0;
// //     final result = await _db.rawQuery('SELECT COUNT(*) as cnt FROM packs');
// //     return result.first['cnt'] as int? ?? 0;
// //   }

// //   /// Clean up sessions older than 7 days.
// //   Future<void> pruneOldSessions() async {
// //     final cutoff = DateTime.now()
// //         .subtract(const Duration(days: 7))
// //         .millisecondsSinceEpoch;
// //     await _db.delete(
// //       'offline_sessions',
// //       where: 'created_at < ? AND is_active = 0',
// //       whereArgs: [cutoff],
// //     );
// //   }
// // }

// // GameType _parseGameType(String s) => switch (s) {
// //   'truth_or_dare' => GameType.truthOrDare,
// //   'never_have_i_ever' => GameType.neverHaveIEver,
// //   'meme_game' => GameType.memeGame,
// //   _ => GameType.truthOrDare,
// // };

// import 'dart:convert';

// import 'package:sqflite/sqflite.dart';

// import '../../../core/storage/database/app_database.dart';
// import '../../../core/utils/app_logger.dart';
// import '../../games/engine/base_game_engine.dart';
// import '../domain/offline_session.dart';

// /// Local SQLite repository for offline sessions and pack queries.
// ///
// /// Schema (added to existing AppDatabase via migration v2):
// ///   offline_sessions  — persisted session state for crash-resume
// ///
// /// Pack data lives in the existing `packs` + `pack_cards` tables.
// class OfflineRepository {
//   OfflineRepository._();
//   static final OfflineRepository _instance = OfflineRepository._();
//   static OfflineRepository get instance => _instance;

//   Database get _db => AppDatabase.instance.db;

//   // ── Schema (call from AppDatabase._migration002) ──────────────────────────
//   static const schemaV2 = '''
//     CREATE TABLE IF NOT EXISTS offline_sessions (
//       id             TEXT    PRIMARY KEY,
//       mode           TEXT    NOT NULL DEFAULT 'pass_and_play',
//       game_type      TEXT    NOT NULL,
//       config_json    TEXT    NOT NULL,
//       players_json   TEXT    NOT NULL,
//       pack_id        TEXT    NOT NULL,
//       pack_name      TEXT    NOT NULL,
//       pack_cover_url TEXT,
//       state_snapshot TEXT,
//       is_active      INTEGER NOT NULL DEFAULT 1,
//       created_at     INTEGER NOT NULL,
//       resumed_at     INTEGER
//     );
//     CREATE INDEX IF NOT EXISTS idx_offline_sessions_active
//       ON offline_sessions (is_active, created_at DESC);
//   ''';

//   // ── Sessions ──────────────────────────────────────────────────────────────

//   Future<void> saveSession(OfflineSession session) async {
//     await _db.insert(
//       'offline_sessions',
//       session.toMap(),
//       conflictAlgorithm: ConflictAlgorithm.replace,
//     );
//   }

//   Future<void> updateSnapshot(String sessionId, String snapshotJson) async {
//     await _db.update(
//       'offline_sessions',
//       {
//         'state_snapshot': snapshotJson,
//         'is_active': 1,
//         'resumed_at': DateTime.now().millisecondsSinceEpoch,
//       },
//       where: 'id = ?',
//       whereArgs: [sessionId],
//     );
//   }

//   Future<void> endSession(String sessionId) async {
//     await _db.update(
//       'offline_sessions',
//       {'is_active': 0},
//       where: 'id = ?',
//       whereArgs: [sessionId],
//     );
//   }

//   /// Returns the most recent resumable session, if any.
//   Future<OfflineSession?> getActiveSession() async {
//     final rows = await _db.query(
//       'offline_sessions',
//       where: 'is_active = 1 AND state_snapshot IS NOT NULL',
//       orderBy: 'resumed_at DESC, created_at DESC',
//       limit: 1,
//     );
//     if (rows.isEmpty) return null;
//     return OfflineSession.fromMap(rows.first);
//   }

//   Future<List<OfflineSession>> getRecentSessions({int limit = 5}) async {
//     final rows = await _db.query(
//       'offline_sessions',
//       orderBy: 'created_at DESC',
//       limit: limit,
//     );
//     return rows.map(OfflineSession.fromMap).toList();
//   }

//   // ── Packs ──────────────────────────────────────────────────────────────────

//   /// Returns all locally-cached packs available for offline play,
//   /// filtered by game type (card_type column maps to game type).
//   Future<List<OfflinePack>> getAvailablePacks({
//     GameType? gameType,
//     String language = 'en',
//   }) async {
//     try {
//       // All downloaded packs are available — download itself is the access gate
//       String sql = '''
//         SELECT p.id, p.name_json, p.game_type, p.language, p.price,
//                COUNT(pc.id) as card_count
//         FROM packs p
//         LEFT JOIN pack_cards pc ON pc.pack_id = p.id
//         WHERE 1=1
//       ''';

//       final args = <Object>[];

//       if (gameType != null) {
//         sql += ' AND p.game_type = ?';
//         args.add(gameType.toDbString());
//       }

//       sql += ' GROUP BY p.id HAVING card_count > 0';
//       sql += ' ORDER BY p.name_json ASC';

//       final rows = await _db.rawQuery(sql, args);

//       return rows.map((r) {
//         final nameJson =
//             jsonDecode(r['name_json'] as String) as Map<String, dynamic>;
//         final name =
//             nameJson[language] as String? ??
//             nameJson['en'] as String? ??
//             'Pack';

//         return OfflinePack(
//           id: r['id'] as String,
//           name: name,
//           gameType: _parseGameType(r['game_type'] as String? ?? ''),
//           language: r['language'] as String? ?? 'en',
//           cardCount: r['card_count'] as int,
//           isFree: (r['price'] as int?) == 0,
//           coverImageUrl: r['cover_image_url'] as String?,
//           expiresAt: null,
//         );
//       }).toList();
//     } catch (e) {
//       AppLogger.error('OfflineRepository: getAvailablePacks failed', error: e);
//       return [];
//     }
//   }

//   /// Check whether a specific pack is available offline.
//   Future<bool> isPackAvailable(String packId) async {
//     final rows = await _db.rawQuery(
//       'SELECT id FROM packs WHERE id = ? LIMIT 1',
//       [packId],
//     );
//     return rows.isNotEmpty;
//   }

//   /// Total count of offline-usable packs (for the offline home badge).
//   Future<int> getAvailablePackCount() async {
//     if (!AppDatabase.instance.isOpen) return 0;
//     final result = await _db.rawQuery('SELECT COUNT(*) as cnt FROM packs');
//     return result.first['cnt'] as int? ?? 0;
//   }

//   /// Clean up sessions older than 7 days.
//   Future<void> pruneOldSessions() async {
//     final cutoff = DateTime.now()
//         .subtract(const Duration(days: 7))
//         .millisecondsSinceEpoch;
//     await _db.delete(
//       'offline_sessions',
//       where: 'created_at < ? AND is_active = 0',
//       whereArgs: [cutoff],
//     );
//   }
// }

// GameType _parseGameType(String s) => switch (s) {
//   'truth_or_dare' => GameType.truthOrDare,
//   'never_have_i_ever' => GameType.neverHaveIEver,
//   'meme_game' => GameType.memeGame,
//   _ => GameType.truthOrDare,
// };

import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/storage/database/app_database.dart';
import '../../../core/utils/app_logger.dart';
import '../../games/engine/base_game_engine.dart';
import '../domain/offline_session.dart';

/// Local SQLite repository for offline sessions and pack queries.
///
/// Schema (added to existing AppDatabase via migration v2):
///   offline_sessions  — persisted session state for crash-resume
///
/// Pack data lives in the existing `packs` + `pack_cards` tables.
class OfflineRepository {
  OfflineRepository._();
  static final OfflineRepository _instance = OfflineRepository._();
  static OfflineRepository get instance => _instance;

  Database get _db => AppDatabase.instance.db;

  // ── Schema (call from AppDatabase._migration002) ──────────────────────────
  static const schemaV2 = '''
    CREATE TABLE IF NOT EXISTS offline_sessions (
      id             TEXT    PRIMARY KEY,
      mode           TEXT    NOT NULL DEFAULT 'pass_and_play',
      game_type      TEXT    NOT NULL,
      config_json    TEXT    NOT NULL,
      players_json   TEXT    NOT NULL,
      pack_id        TEXT    NOT NULL,
      pack_name      TEXT    NOT NULL,
      pack_cover_url TEXT,
      state_snapshot TEXT,
      is_active      INTEGER NOT NULL DEFAULT 1,
      created_at     INTEGER NOT NULL,
      resumed_at     INTEGER
    );
    CREATE INDEX IF NOT EXISTS idx_offline_sessions_active
      ON offline_sessions (is_active, created_at DESC);
  ''';

  // ── Sessions ──────────────────────────────────────────────────────────────

  Future<void> saveSession(OfflineSession session) async {
    await _db.insert(
      'offline_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSnapshot(String sessionId, String snapshotJson) async {
    await _db.update(
      'offline_sessions',
      {
        'state_snapshot': snapshotJson,
        'is_active': 1,
        'resumed_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> endSession(String sessionId) async {
    await _db.update(
      'offline_sessions',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Returns the most recent resumable session, if any.
  Future<OfflineSession?> getActiveSession() async {
    final rows = await _db.query(
      'offline_sessions',
      where: 'is_active = 1 AND state_snapshot IS NOT NULL',
      orderBy: 'resumed_at DESC, created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return OfflineSession.fromMap(rows.first);
  }

  Future<List<OfflineSession>> getRecentSessions({int limit = 5}) async {
    final rows = await _db.query(
      'offline_sessions',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(OfflineSession.fromMap).toList();
  }

  // ── Packs ──────────────────────────────────────────────────────────────────

  /// Returns all locally-cached packs available for offline play,
  /// filtered by game type (card_type column maps to game type).
  Future<List<OfflinePack>> getAvailablePacks({
    GameType? gameType,
    String language = 'en',
  }) async {
    try {
      // All downloaded packs are available — download itself is the access gate
      String sql = '''
        SELECT p.id, p.name_json, p.game_type, p.language, p.price,
               COUNT(pc.id) as card_count
        FROM packs p
        LEFT JOIN pack_cards pc ON pc.pack_id = p.id
        WHERE 1=1
      ''';

      final args = <Object>[];

      if (gameType != null) {
        sql += ' AND p.game_type = ?';
        args.add(gameType.toDbString());
      }

      sql += ' GROUP BY p.id HAVING card_count > 0';
      sql += ' ORDER BY p.name_json ASC';

      final rows = await _db.rawQuery(sql, args);

      return rows.map((r) {
        final nameJson =
            jsonDecode(r['name_json'] as String) as Map<String, dynamic>;
        final name =
            nameJson[language] as String? ??
            nameJson['en'] as String? ??
            'Pack';

        return OfflinePack(
          id: r['id'] as String,
          name: name,
          gameType: _parseGameType(r['game_type'] as String? ?? ''),
          language: r['language'] as String? ?? 'en',
          cardCount: r['card_count'] as int,
          isFree: (r['price'] as int?) == 0,
          coverImageUrl: (r['local_cover_path'] as String?)?.isNotEmpty == true
              ? r['local_cover_path'] as String
              : r['cover_url'] as String? ?? r['cover_image_url'] as String?,
          expiresAt: null,
        );
      }).toList();
    } catch (e) {
      AppLogger.error('OfflineRepository: getAvailablePacks failed', error: e);
      return [];
    }
  }

  /// Check whether a specific pack is available offline.
  Future<bool> isPackAvailable(String packId) async {
    final rows = await _db.rawQuery(
      'SELECT id FROM packs WHERE id = ? LIMIT 1',
      [packId],
    );
    return rows.isNotEmpty;
  }

  /// Total count of offline-usable packs (for the offline home badge).
  Future<int> getAvailablePackCount() async {
    if (!AppDatabase.instance.isOpen) return 0;
    final result = await _db.rawQuery('SELECT COUNT(*) as cnt FROM packs');
    return result.first['cnt'] as int? ?? 0;
  }

  /// Clean up sessions older than 7 days.
  Future<void> pruneOldSessions() async {
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    await _db.delete(
      'offline_sessions',
      where: 'created_at < ? AND is_active = 0',
      whereArgs: [cutoff],
    );
  }
}

GameType _parseGameType(String s) => switch (s) {
  'truth_or_dare' => GameType.truthOrDare,
  'never_have_i_ever' => GameType.neverHaveIEver,
  'meme_game' => GameType.memeGame,
  _ => GameType.truthOrDare,
};
