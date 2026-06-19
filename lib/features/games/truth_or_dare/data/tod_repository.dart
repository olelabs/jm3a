// // // // // // // import 'dart:convert';

// // // // // // // import 'package:sqflite/sqflite.dart';
// // // // // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // // // // import 'package:uuid/uuid.dart';

// // // // // // // import '../../../../core/data/base_repository.dart';
// // // // // // // import '../../../../core/storage/database/app_database.dart';
// // // // // // // import '../../../../core/utils/app_logger.dart';
// // // // // // // import '../domain/tod_models.dart';
// // // // // // // import '../../engine/base_game_engine.dart';

// // // // // // // const _uuid = Uuid();

// // // // // // // /// Truth or Dare DB persistence layer.
// // // // // // // ///
// // // // // // // /// Priority order for card loading:
// // // // // // // ///   1. Local SQLite cache (AppDatabase — offline-first)
// // // // // // // ///   2. Supabase remote (online fallback)
// // // // // // // ///
// // // // // // // /// Session persistence:
// // // // // // // ///   - Owner creates a game_sessions row at start
// // // // // // // ///   - Owner saves snapshots every 10s for reconnect recovery
// // // // // // // ///   - Session marked completed when game ends
// // // // // // // class TodRepository extends BaseRepository {
// // // // // // //   TodRepository._();
// // // // // // //   static final TodRepository _instance = TodRepository._();
// // // // // // //   static TodRepository get instance => _instance;

// // // // // // //   final _supabase = Supabase.instance.client;

// // // // // // //   // ── Card loading ───────────────────────────────────────────────────────────

// // // // // // //   /// Primary: load from remote Supabase (online).
// // // // // // //   Future<List<TodCard>> loadCards({
// // // // // // //     required String packId,
// // // // // // //     required String language,
// // // // // // //     bool allowSpicy = false,
// // // // // // //   }) => guardedCall(
// // // // // // //     operationName: 'loadTodCards',
// // // // // // //     operation: () async {
// // // // // // //       var q = _supabase
// // // // // // //           .from('pack_cards')
// // // // // // //           .select('id, content, card_type, difficulty')
// // // // // // //           .eq('pack_id', packId)
// // // // // // //           .eq('is_active', true);

// // // // // // //       if (!allowSpicy) q = q.neq('difficulty', 'spicy');

// // // // // // //       final rows = await q.order('sort_order');

// // // // // // //       return rows.map((r) {
// // // // // // //         final contentJson = r['content'] as Map<String, dynamic>? ?? {};
// // // // // // //         final content =
// // // // // // //             contentJson[language] as String? ??
// // // // // // //             contentJson['en'] as String? ??
// // // // // // //             '';
// // // // // // //         return TodCard(
// // // // // // //           id: r['id'] as String,
// // // // // // //           content: content,
// // // // // // //           type: TodCardType.values.firstWhere(
// // // // // // //             (t) => t.name == (r['card_type'] as String? ?? 'truth'),
// // // // // // //             orElse: () => TodCardType.truth,
// // // // // // //           ),
// // // // // // //           difficulty: TodDifficulty.values.firstWhere(
// // // // // // //             (d) => d.name == (r['difficulty'] as String? ?? 'mild'),
// // // // // // //             orElse: () => TodDifficulty.mild,
// // // // // // //           ),
// // // // // // //           allowSpicy: r['allowSpicy'],
// // // // // // //           language: r['language'],
// // // // // // //         );
// // // // // // //       }).toList();
// // // // // // //     },
// // // // // // //   );

// // // // // // //   /// Fallback: load from local SQLite (downloaded packs cache).
// // // // // // //   // Future<List<TodCard>> loadCardsFromCache({
// // // // // // //   //   required String packId,
// // // // // // //   //   required String language,
// // // // // // //   //   bool allowSpicy = false,
// // // // // // //   // }) async {
// // // // // // //   //   try {
// // // // // // //   //     final db = AppDatabase.instance.db;

// // // // // // //   //     var sql = '''
// // // // // // //   //       SELECT id, content_json, card_type, difficulty
// // // // // // //   //       FROM pack_cards_cache
// // // // // // //   //       WHERE pack_id = ?
// // // // // // //   //         AND is_active = 1
// // // // // // //   //     ''';
// // // // // // //   //     final params = <Object>[packId];
// // // // // // //   //     if (!allowSpicy) {
// // // // // // //   //       sql += ' AND difficulty != ?';
// // // // // // //   //       params.add('spicy');
// // // // // // //   //     }
// // // // // // //   //     sql += ' ORDER BY sort_order';

// // // // // // //   //     final rows = await db.rawQuery(sql, params);

// // // // // // //   //     return rows.map((r) {
// // // // // // //   //       final contentJson =
// // // // // // //   //           jsonDecode(r['content_json'] as String? ?? '{}')
// // // // // // //   //               as Map<String, dynamic>;
// // // // // // //   //       final content = contentJson[language] as String? ??
// // // // // // //   //           contentJson['en'] as String? ??
// // // // // // //   //           '';
// // // // // // //   //       return TodCard(
// // // // // // //   //         id:         r['id']        as String,
// // // // // // //   //         content:    content,
// // // // // // //   //         type:       TodCardType.values.firstWhere(
// // // // // // //   //           (t) => t.name == r['card_type'],
// // // // // // //   //           orElse: () => TodCardType.truth,
// // // // // // //   //         ),
// // // // // // //   //         difficulty: TodDifficulty.values.firstWhere(
// // // // // // //   //           (d) => d.name == r['difficulty'],
// // // // // // //   //           orElse: () => TodDifficulty.mild,
// // // // // // //   //         ),
// // // // // // //   //       );
// // // // // // //   //     }).toList();
// // // // // // //   //   } catch (e) {
// // // // // // //   //     AppLogger.debug('TodRepository: SQLite cache miss for $packId — $e');
// // // // // // //   //     return [];
// // // // // // //   //   }
// // // // // // //   // }

// // // // // // //   // Future<List<Map<String, dynamic>>> loadCardsFromCache(
// // // // // // //   //   String packId, {
// // // // // // //   //   String? language,
// // // // // // //   //   bool allowSpicy = false,
// // // // // // //   // }) async {
// // // // // // //   //   final db = AppDatabase.instance.db;
// // // // // // //   //   final List<Map<String, dynamic>> rows = await db.rawQuery(
// // // // // // //   //     '''
// // // // // // //   //   SELECT id, content_json, card_type, difficulty
// // // // // // //   //   FROM pack_cards_cache
// // // // // // //   //   WHERE pack_id = ? AND is_active = 1
// // // // // // //   //   ORDER BY sort_order
// // // // // // //   // ''',
// // // // // // //   //     [packId],
// // // // // // //   //   );

// // // // // // //   //   // Parse content_json from string to Map
// // // // // // //   //   final parsedRows = rows.map((row) {
// // // // // // //   //     final contentJsonString = row['content_json'] as String;
// // // // // // //   //     final Map<String, dynamic> contentMap = jsonDecode(contentJsonString);
// // // // // // //   //     return {
// // // // // // //   //       ...row,
// // // // // // //   //       'content_json': contentMap, // replace string with map
// // // // // // //   //     };
// // // // // // //   //   }).toList();

// // // // // // //   //   return parsedRows;
// // // // // // //   // }

// // // // // // //   // Future<List<TodCard>> loadCardsFromCache({
// // // // // // //   //   required String packId,
// // // // // // //   //   required String language,
// // // // // // //   //   bool allowSpicy = false,
// // // // // // //   // }) async {
// // // // // // //   //   try {
// // // // // // //   //     final db = AppDatabase.instance.db;

// // // // // // //   //     var sql = '''
// // // // // // //   //     SELECT id, content_json, card_type, difficulty
// // // // // // //   //     FROM pack_cards_cache
// // // // // // //   //     WHERE pack_id = ?
// // // // // // //   //       AND is_active = 1
// // // // // // //   //   ''';
// // // // // // //   //     final params = <Object>[packId];
// // // // // // //   //     if (!allowSpicy) {
// // // // // // //   //       sql += ' AND difficulty != ?';
// // // // // // //   //       params.add('spicy');
// // // // // // //   //     }
// // // // // // //   //     sql += ' ORDER BY sort_order';

// // // // // // //   //     final rows = await db.rawQuery(sql, params);

// // // // // // //   //     return rows.map((r) {
// // // // // // //   //       final contentJson =
// // // // // // //   //           jsonDecode(r['content_json'] as String? ?? '{}')
// // // // // // //   //               as Map<String, dynamic>;
// // // // // // //   //       final content =
// // // // // // //   //           contentJson[language] as String? ??
// // // // // // //   //           contentJson['en'] as String? ??
// // // // // // //   //           '';
// // // // // // //   //       return TodCard(
// // // // // // //   //         id: r['id'] as String,
// // // // // // //   //         content: content,
// // // // // // //   //         type: TodCardType.values.firstWhere(
// // // // // // //   //           (t) => t.name == (r['card_type'] as String? ?? 'truth'),
// // // // // // //   //           orElse: () => TodCardType.truth,
// // // // // // //   //         ),
// // // // // // //   //         difficulty: TodDifficulty.values.firstWhere(
// // // // // // //   //           (d) => d.name == (r['difficulty'] as String? ?? 'mild'),
// // // // // // //   //           orElse: () => TodDifficulty.mild,
// // // // // // //   //         ),
// // // // // // //   //         allowSpicy: r['allowSpicy'] as bool,
// // // // // // //   //         language: r['language'] as String,
// // // // // // //   //       );
// // // // // // //   //     }).toList();
// // // // // // //   //   } catch (e) {
// // // // // // //   //     AppLogger.debug('TodRepository: SQLite cache miss for $packId — $e');
// // // // // // //   //     return [];
// // // // // // //   //   }
// // // // // // //   // }

// // // // // // //   Future<List<TodCard>> loadCardsFromCache({
// // // // // // //   required String packId,
// // // // // // //   required String language,
// // // // // // //   bool allowSpicy = false,
// // // // // // // }) async {
// // // // // // //   try {
// // // // // // //     final db = AppDatabase.instance.db;

// // // // // // //     var sql = '''
// // // // // // //       SELECT id, content_json, card_type, difficulty
// // // // // // //       FROM pack_cards_cache
// // // // // // //       WHERE pack_id = ?
// // // // // // //         AND is_active = 1
// // // // // // //     ''';
// // // // // // //     final params = <Object>[packId];
// // // // // // //     if (!allowSpicy) {
// // // // // // //       sql += ' AND difficulty != ?';
// // // // // // //       params.add('spicy');
// // // // // // //     }
// // // // // // //     sql += ' ORDER BY sort_order';

// // // // // // //     final rows = await db.rawQuery(sql, params);

// // // // // // //     return rows.map((row) {
// // // // // // //       // Parse content_json from string (or handle if already map)
// // // // // // //       final contentJsonRaw = row['content_json'];
// // // // // // //       Map<String, dynamic> contentMap;
// // // // // // //       if (contentJsonRaw is String) {
// // // // // // //         contentMap = jsonDecode(contentJsonRaw) as Map<String, dynamic>;
// // // // // // //       } else if (contentJsonRaw is Map) {
// // // // // // //         contentMap = contentJsonRaw as Map<String, dynamic>;
// // // // // // //       } else {
// // // // // // //         contentMap = {};
// // // // // // //       }
// // // // // // //       final content = contentMap[language] as String? ??
// // // // // // //           contentMap['en'] as String? ??
// // // // // // //           '';
// // // // // // //       return TodCard(
// // // // // // //         id: row['id'] as String,
// // // // // // //         content: content,
// // // // // // //         type: TodCardType.values.firstWhere(
// // // // // // //           (t) => t.name == (row['card_type'] as String? ?? 'truth'),
// // // // // // //           orElse: () => TodCardType.truth,
// // // // // // //         ),
// // // // // // //         difficulty: TodDifficulty.values.firstWhere(
// // // // // // //           (d) => d.name == (row['difficulty'] as String? ?? 'mild'),
// // // // // // //           orElse: () => TodDifficulty.mild,
// // // // // // //         ),
// // // // // // //       );
// // // // // // //     }).toList();
// // // // // // //   } catch (e) {
// // // // // // //     AppLogger.debug('TodRepository: SQLite cache miss for $packId — $e');
// // // // // // //     return [];
// // // // // // //   }
// // // // // // // }

// // // // // // //   // ── Session persistence ────────────────────────────────────────────────────

// // // // // // //   Future<String> createSession({
// // // // // // //     required String roomId,
// // // // // // //     required String packId,
// // // // // // //     required GameConfig config,
// // // // // // //     required List<String> playerIds,
// // // // // // //     required String ownerId,
// // // // // // //   }) => guardedCall(
// // // // // // //     operationName: 'createTodSession',
// // // // // // //     operation: () async {
// // // // // // //       final row = await _supabase
// // // // // // //           .from('game_sessions')
// // // // // // //           .insert({
// // // // // // //             'room_id': roomId,
// // // // // // //             'pack_id': packId,
// // // // // // //             'game_type': GameType.truthOrDare.toDbString(),
// // // // // // //             'owner_id': ownerId,
// // // // // // //             'player_ids': playerIds,
// // // // // // //             'state_snapshot': {},
// // // // // // //             'max_rounds': config.maxRounds,
// // // // // // //             'turn_timer_secs': config.turnTimerSeconds,
// // // // // // //             'allow_skip': config.allowSkip,
// // // // // // //             'allow_spicy': config.allowSpicy,
// // // // // // //             'status': 'active',
// // // // // // //           })
// // // // // // //           .select('id')
// // // // // // //           .single();
// // // // // // //       return row['id'] as String;
// // // // // // //     },
// // // // // // //   );

// // // // // // //   /// Called every 10s by owner to persist the current snapshot.
// // // // // // //   /// Followers use this as a reconnect fallback.
// // // // // // //   Future<void> saveSnapshot({
// // // // // // //     required String sessionId,
// // // // // // //     required Map<String, dynamic> snapshot,
// // // // // // //   }) => guardedCall(
// // // // // // //     operationName: 'saveTodSnapshot',
// // // // // // //     operation: () async {
// // // // // // //       await _supabase
// // // // // // //           .from('game_sessions')
// // // // // // //           .update({
// // // // // // //             'state_snapshot': snapshot,
// // // // // // //             'snapshot_at': DateTime.now().toIso8601String(),
// // // // // // //           })
// // // // // // //           .eq('id', sessionId);
// // // // // // //     },
// // // // // // //   );

// // // // // // //   /// Load the latest snapshot from DB (8s timeout fallback for followers).
// // // // // // //   Future<Map<String, dynamic>?> loadSnapshot(String sessionId) => guardedCall(
// // // // // // //     operationName: 'loadTodSnapshot',
// // // // // // //     operation: () async {
// // // // // // //       final row = await _supabase
// // // // // // //           .from('game_sessions')
// // // // // // //           .select('state_snapshot, status')
// // // // // // //           .eq('id', sessionId)
// // // // // // //           .single();

// // // // // // //       if (row['status'] == 'completed' || row['status'] == 'aborted') {
// // // // // // //         return null;
// // // // // // //       }
// // // // // // //       return row['state_snapshot'] as Map<String, dynamic>?;
// // // // // // //     },
// // // // // // //   );

// // // // // // //   /// Mark session complete and record final scores.
// // // // // // //   Future<void> completeSession({
// // // // // // //     required String sessionId,
// // // // // // //     required Map<String, dynamic> finalSnapshot,
// // // // // // //     required String endReason,
// // // // // // //   }) => guardedCall(
// // // // // // //     operationName: 'completeTodSession',
// // // // // // //     operation: () async {
// // // // // // //       await _supabase
// // // // // // //           .from('game_sessions')
// // // // // // //           .update({
// // // // // // //             'status': 'completed',
// // // // // // //             'state_snapshot': finalSnapshot,
// // // // // // //             'ended_at': DateTime.now().toIso8601String(),
// // // // // // //           })
// // // // // // //           .eq('id', sessionId);
// // // // // // //     },
// // // // // // //   );
// // // // // // // }

// // // // // // import 'dart:convert';

// // // // // // import 'package:sqflite/sqflite.dart';
// // // // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // // // import 'package:uuid/uuid.dart';

// // // // // // import '../../../../core/data/base_repository.dart';
// // // // // // import '../../../../core/storage/database/app_database.dart';
// // // // // // import '../../../../core/utils/app_logger.dart';
// // // // // // import '../domain/tod_models.dart';
// // // // // // import '../../engine/base_game_engine.dart';

// // // // // // const _uuid = Uuid();

// // // // // // /// Truth or Dare DB persistence layer.
// // // // // // ///
// // // // // // /// Priority order for card loading:
// // // // // // ///   1. Local SQLite cache (AppDatabase — offline-first)
// // // // // // ///   2. Supabase remote (online fallback)
// // // // // // ///
// // // // // // /// Session persistence:
// // // // // // ///   - Owner creates a game_sessions row at start
// // // // // // ///   - Owner saves snapshots every 10s for reconnect recovery
// // // // // // ///   - Session marked completed when game ends
// // // // // // class TodRepository extends BaseRepository {
// // // // // //   TodRepository._();
// // // // // //   static final TodRepository _instance = TodRepository._();
// // // // // //   static TodRepository get instance => _instance;

// // // // // //   final _supabase = Supabase.instance.client;

// // // // // //   // ── Card loading ───────────────────────────────────────────────────────────

// // // // // //   /// Primary: load from remote Supabase (online).
// // // // // //   Future<List<TodCard>> loadCards({
// // // // // //     required String packId,
// // // // // //     required String language,
// // // // // //     bool allowSpicy = false,
// // // // // //   }) => guardedCall(
// // // // // //     operationName: 'loadTodCards',
// // // // // //     operation: () async {
// // // // // //       var q = _supabase
// // // // // //           .from('pack_cards')
// // // // // //           .select('id, content, card_type, difficulty')
// // // // // //           .eq('pack_id', packId)
// // // // // //           .eq('is_active', true);

// // // // // //       if (!allowSpicy) q = q.neq('difficulty', 'spicy');

// // // // // //       final rows = await q.order('sort_order');

// // // // // //       return rows.map((r) {
// // // // // //         final contentJson = r['content'] as Map<String, dynamic>? ?? {};
// // // // // //         final content =
// // // // // //             contentJson[language] as String? ??
// // // // // //             contentJson['en'] as String? ??
// // // // // //             '';
// // // // // //         return TodCard(
// // // // // //           id: r['id'] as String,
// // // // // //           content: content,
// // // // // //           type: TodCardType.values.firstWhere(
// // // // // //             (t) => t.name == (r['card_type'] as String? ?? 'truth'),
// // // // // //             orElse: () => TodCardType.truth,
// // // // // //           ),
// // // // // //           difficulty: TodDifficulty.values.firstWhere(
// // // // // //             (d) => d.name == (r['difficulty'] as String? ?? 'mild'),
// // // // // //             orElse: () => TodDifficulty.mild,
// // // // // //           ),
// // // // // //         );
// // // // // //       }).toList();
// // // // // //     },
// // // // // //   );

// // // // // //   /// Fallback: load from local SQLite (downloaded packs cache).
// // // // // //   Future<List<TodCard>> loadCardsFromCache({
// // // // // //     required String packId,
// // // // // //     required String language,
// // // // // //     bool allowSpicy = false,
// // // // // //   }) async {
// // // // // //     try {
// // // // // //       final db = AppDatabase.instance.db;

// // // // // //       var sql = '''
// // // // // //         SELECT id, content_json, card_type, difficulty
// // // // // //         FROM pack_cards_cache
// // // // // //         WHERE pack_id = ?
// // // // // //       ''';
// // // // // //       final params = <Object>[packId];
// // // // // //       if (!allowSpicy) {
// // // // // //         sql += ' AND difficulty != ?';
// // // // // //         params.add('spicy');
// // // // // //       }
// // // // // //       sql += ' ORDER BY sort_order';

// // // // // //       final rows = await db.rawQuery(sql, params);

// // // // // //       return rows.map((r) {
// // // // // //         final contentJson =
// // // // // //             jsonDecode(r['content_json'] as String? ?? '{}')
// // // // // //                 as Map<String, dynamic>;
// // // // // //         final content =
// // // // // //             contentJson[language] as String? ??
// // // // // //             contentJson['en'] as String? ??
// // // // // //             '';
// // // // // //         return TodCard(
// // // // // //           id: r['id'] as String,
// // // // // //           content: content,
// // // // // //           type: TodCardType.values.firstWhere(
// // // // // //             (t) => t.name == r['card_type'],
// // // // // //             orElse: () => TodCardType.truth,
// // // // // //           ),
// // // // // //           difficulty: TodDifficulty.values.firstWhere(
// // // // // //             (d) => d.name == r['difficulty'],
// // // // // //             orElse: () => TodDifficulty.mild,
// // // // // //           ),
// // // // // //         );
// // // // // //       }).toList();
// // // // // //     } catch (e) {
// // // // // //       AppLogger.debug('TodRepository: SQLite cache miss for $packId — $e');
// // // // // //       return [];
// // // // // //     }
// // // // // //   }

// // // // // //   // ── Session persistence ────────────────────────────────────────────────────

// // // // // //   Future<String> createSession({
// // // // // //     required String roomId,
// // // // // //     required String packId,
// // // // // //     required GameConfig config,
// // // // // //     required List<String> playerIds,
// // // // // //     required String ownerId,
// // // // // //   }) => guardedCall(
// // // // // //     operationName: 'createTodSession',
// // // // // //     operation: () async {
// // // // // //       final row = await _supabase
// // // // // //           .from('game_sessions')
// // // // // //           .insert({
// // // // // //             'room_id': roomId,
// // // // // //             'pack_id': packId,
// // // // // //             'game_type': GameType.truthOrDare.toDbString(),
// // // // // //             'owner_id': ownerId,
// // // // // //             'player_ids': playerIds,
// // // // // //             'state_snapshot': {},
// // // // // //             'max_rounds': config.maxRounds,
// // // // // //             'turn_timer_secs': config.turnTimerSeconds,
// // // // // //             'allow_skip': config.allowSkip,
// // // // // //             'allow_spicy': config.allowSpicy,
// // // // // //             'status': 'active',
// // // // // //           })
// // // // // //           .select('id')
// // // // // //           .single();
// // // // // //       return row['id'] as String;
// // // // // //     },
// // // // // //   );

// // // // // //   /// Called every 10s by owner to persist the current snapshot.
// // // // // //   /// Followers use this as a reconnect fallback.
// // // // // //   Future<void> saveSnapshot({
// // // // // //     required String sessionId,
// // // // // //     required Map<String, dynamic> snapshot,
// // // // // //   }) => guardedCall(
// // // // // //     operationName: 'saveTodSnapshot',
// // // // // //     operation: () async {
// // // // // //       await _supabase
// // // // // //           .from('game_sessions')
// // // // // //           .update({
// // // // // //             'state_snapshot': snapshot,
// // // // // //             'snapshot_at': DateTime.now().toIso8601String(),
// // // // // //           })
// // // // // //           .eq('id', sessionId);
// // // // // //     },
// // // // // //   );

// // // // // //   /// Load the latest snapshot from DB (8s timeout fallback for followers).
// // // // // //   Future<Map<String, dynamic>?> loadSnapshot(String sessionId) => guardedCall(
// // // // // //     operationName: 'loadTodSnapshot',
// // // // // //     operation: () async {
// // // // // //       final row = await _supabase
// // // // // //           .from('game_sessions')
// // // // // //           .select('state_snapshot, status')
// // // // // //           .eq('id', sessionId)
// // // // // //           .single();

// // // // // //       if (row['status'] == 'completed' || row['status'] == 'aborted') {
// // // // // //         return null;
// // // // // //       }
// // // // // //       return row['state_snapshot'] as Map<String, dynamic>?;
// // // // // //     },
// // // // // //   );

// // // // // //   /// Mark session complete and record final scores.
// // // // // //   Future<void> completeSession({
// // // // // //     required String sessionId,
// // // // // //     required Map<String, dynamic> finalSnapshot,
// // // // // //     required String endReason,
// // // // // //   }) => guardedCall(
// // // // // //     operationName: 'completeTodSession',
// // // // // //     operation: () async {
// // // // // //       await _supabase
// // // // // //           .from('game_sessions')
// // // // // //           .update({
// // // // // //             'status': 'completed',
// // // // // //             'state_snapshot': finalSnapshot,
// // // // // //             'ended_at': DateTime.now().toIso8601String(),
// // // // // //           })
// // // // // //           .eq('id', sessionId);
// // // // // //     },
// // // // // //   );
// // // // // // }

// // // // // import 'dart:convert';

// // // // // import 'package:sqflite/sqflite.dart';
// // // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // // import 'package:uuid/uuid.dart';

// // // // // import '../../../../core/data/base_repository.dart';
// // // // // import '../../../../core/storage/database/app_database.dart';
// // // // // import '../../../../core/utils/app_logger.dart';
// // // // // import '../domain/tod_models.dart';
// // // // // import '../../engine/base_game_engine.dart';

// // // // // const _uuid = Uuid();

// // // // // /// Truth or Dare DB persistence layer.
// // // // // ///
// // // // // /// Priority order for card loading:
// // // // // ///   1. Local SQLite cache (AppDatabase — offline-first)
// // // // // ///   2. Supabase remote (online fallback)
// // // // // ///
// // // // // /// Session persistence:
// // // // // ///   - Owner creates a game_sessions row at start
// // // // // ///   - Owner saves snapshots every 10s for reconnect recovery
// // // // // ///   - Session marked completed when game ends
// // // // // class TodRepository extends BaseRepository {
// // // // //   TodRepository._();
// // // // //   static final TodRepository _instance = TodRepository._();
// // // // //   static TodRepository get instance => _instance;

// // // // //   final _supabase = Supabase.instance.client;

// // // // //   // ── Card loading ───────────────────────────────────────────────────────────

// // // // //   /// Primary: load from remote Supabase (online).
// // // // //   Future<List<TodCard>> loadCards({
// // // // //     required String packId,
// // // // //     required String language,
// // // // //     bool allowSpicy = false,
// // // // //   }) => guardedCall(
// // // // //     operationName: 'loadTodCards',
// // // // //     operation: () async {
// // // // //       var q = _supabase
// // // // //           .from('pack_cards')
// // // // //           .select('id, content, card_type, difficulty')
// // // // //           .eq('pack_id', packId)
// // // // //           .eq('is_active', true);

// // // // //       if (!allowSpicy) q = q.neq('difficulty', 'spicy');

// // // // //       final rows = await q.order('sort_order');

// // // // //       return rows.map((r) {
// // // // //         final contentJson = r['content'] as Map<String, dynamic>? ?? {};
// // // // //         final content =
// // // // //             contentJson[language] as String? ??
// // // // //             contentJson['en'] as String? ??
// // // // //             '';
// // // // //         return TodCard(
// // // // //           id: r['id'] as String,
// // // // //           content: content,
// // // // //           type: TodCardType.values.firstWhere(
// // // // //             (t) => t.name == (r['card_type'] as String? ?? 'truth'),
// // // // //             orElse: () => TodCardType.truth,
// // // // //           ),
// // // // //           difficulty: TodDifficulty.values.firstWhere(
// // // // //             (d) => d.name == (r['difficulty'] as String? ?? 'mild'),
// // // // //             orElse: () => TodDifficulty.mild,
// // // // //           ),
// // // // //         );
// // // // //       }).toList();
// // // // //     },
// // // // //   );

// // // // //   /// Fallback: load from local SQLite (downloaded packs cache).
// // // // //   Future<List<TodCard>> loadCardsFromCache({
// // // // //     required String packId,
// // // // //     required String language,
// // // // //     bool allowSpicy = false,
// // // // //   }) async {
// // // // //     try {
// // // // //       final db = AppDatabase.instance.db;

// // // // //       var sql = '''
// // // // //         SELECT id, content_json, card_type, difficulty
// // // // //         FROM pack_cards_cache
// // // // //         WHERE pack_id = ?
// // // // //       ''';
// // // // //       final params = <Object>[packId];
// // // // //       if (!allowSpicy) {
// // // // //         sql += ' AND difficulty != ?';
// // // // //         params.add('spicy');
// // // // //       }
// // // // //       sql += ' ORDER BY sort_order';

// // // // //       final rows = await db.rawQuery(sql, params);

// // // // //       // Debug: log how many cards were found
// // // // //       AppLogger.debug(
// // // // //         'TodRepository: found ${rows.length} cards for pack $packId',
// // // // //       );

// // // // //       // Also check if pack exists at all
// // // // //       if (rows.isEmpty) {
// // // // //         final packCheck = await db.rawQuery(
// // // // //           'SELECT COUNT(*) as cnt FROM pack_cards WHERE pack_id = ?',
// // // // //           [packId],
// // // // //         );
// // // // //         final cardCount = packCheck.first['cnt'] as int? ?? 0;
// // // // //         AppLogger.debug(
// // // // //           'TodRepository: pack_cards direct count = $cardCount for $packId',
// // // // //         );
// // // // //         // Try without the view
// // // // //         if (cardCount > 0) {
// // // // //           final directRows = await db.rawQuery(
// // // // //             'SELECT id, content_json, card_type, difficulty, sort_order FROM pack_cards WHERE pack_id = ? ORDER BY sort_order',
// // // // //             [packId],
// // // // //           );
// // // // //           AppLogger.debug(
// // // // //             'TodRepository: direct query returned ${directRows.length} rows',
// // // // //           );
// // // // //           return directRows.map((r) {
// // // // //             final rawContent = r['content_json'];
// // // // //             final contentStr = rawContent is String
// // // // //                 ? rawContent
// // // // //                 : jsonEncode(rawContent ?? '{}');
// // // // //             Map<String, dynamic> contentJson;
// // // // //             try {
// // // // //               contentJson = jsonDecode(contentStr) as Map<String, dynamic>;
// // // // //             } catch (_) {
// // // // //               contentJson = {'en': contentStr};
// // // // //             }
// // // // //             final content =
// // // // //                 contentJson[language] as String? ??
// // // // //                 contentJson['en'] as String? ??
// // // // //                 '';
// // // // //             return TodCard(
// // // // //               id: r['id'] as String,
// // // // //               content: content,
// // // // //               type: TodCardType.values.firstWhere(
// // // // //                 (t) => t.name == r['card_type'],
// // // // //                 orElse: () => TodCardType.truth,
// // // // //               ),
// // // // //               difficulty: TodDifficulty.values.firstWhere(
// // // // //                 (d) => d.name == r['difficulty'],
// // // // //                 orElse: () => TodDifficulty.mild,
// // // // //               ),
// // // // //             );
// // // // //           }).toList();
// // // // //         }
// // // // //       }

// // // // //       return rows.map((r) {
// // // // //         final contentJson =
// // // // //             jsonDecode(r['content_json'] as String? ?? '{}')
// // // // //                 as Map<String, dynamic>;
// // // // //         final content =
// // // // //             contentJson[language] as String? ??
// // // // //             contentJson['en'] as String? ??
// // // // //             '';
// // // // //         return TodCard(
// // // // //           id: r['id'] as String,
// // // // //           content: content,
// // // // //           type: TodCardType.values.firstWhere(
// // // // //             (t) => t.name == r['card_type'],
// // // // //             orElse: () => TodCardType.truth,
// // // // //           ),
// // // // //           difficulty: TodDifficulty.values.firstWhere(
// // // // //             (d) => d.name == r['difficulty'],
// // // // //             orElse: () => TodDifficulty.mild,
// // // // //           ),
// // // // //         );
// // // // //       }).toList();
// // // // //     } catch (e) {
// // // // //       AppLogger.debug('TodRepository: SQLite cache miss for $packId — $e');
// // // // //       return [];
// // // // //     }
// // // // //   }

// // // // //   // ── Session persistence ────────────────────────────────────────────────────

// // // // //   Future<String> createSession({
// // // // //     required String roomId,
// // // // //     required String packId,
// // // // //     required GameConfig config,
// // // // //     required List<String> playerIds,
// // // // //     required String ownerId,
// // // // //   }) => guardedCall(
// // // // //     operationName: 'createTodSession',
// // // // //     operation: () async {
// // // // //       final row = await _supabase
// // // // //           .from('game_sessions')
// // // // //           .insert({
// // // // //             'room_id': roomId,
// // // // //             'pack_id': packId,
// // // // //             'game_type': GameType.truthOrDare.toDbString(),
// // // // //             'owner_id': ownerId,
// // // // //             'player_ids': playerIds,
// // // // //             'state_snapshot': {},
// // // // //             'max_rounds': config.maxRounds,
// // // // //             'turn_timer_secs': config.turnTimerSeconds,
// // // // //             'allow_skip': config.allowSkip,
// // // // //             'allow_spicy': config.allowSpicy,
// // // // //             'status': 'active',
// // // // //           })
// // // // //           .select('id')
// // // // //           .single();
// // // // //       return row['id'] as String;
// // // // //     },
// // // // //   );

// // // // //   /// Called every 10s by owner to persist the current snapshot.
// // // // //   /// Followers use this as a reconnect fallback.
// // // // //   Future<void> saveSnapshot({
// // // // //     required String sessionId,
// // // // //     required Map<String, dynamic> snapshot,
// // // // //   }) => guardedCall(
// // // // //     operationName: 'saveTodSnapshot',
// // // // //     operation: () async {
// // // // //       await _supabase
// // // // //           .from('game_sessions')
// // // // //           .update({
// // // // //             'state_snapshot': snapshot,
// // // // //             'snapshot_at': DateTime.now().toIso8601String(),
// // // // //           })
// // // // //           .eq('id', sessionId);
// // // // //     },
// // // // //   );

// // // // //   /// Load the latest snapshot from DB (8s timeout fallback for followers).
// // // // //   Future<Map<String, dynamic>?> loadSnapshot(String sessionId) => guardedCall(
// // // // //     operationName: 'loadTodSnapshot',
// // // // //     operation: () async {
// // // // //       final row = await _supabase
// // // // //           .from('game_sessions')
// // // // //           .select('state_snapshot, status')
// // // // //           .eq('id', sessionId)
// // // // //           .single();

// // // // //       if (row['status'] == 'completed' || row['status'] == 'aborted') {
// // // // //         return null;
// // // // //       }
// // // // //       return row['state_snapshot'] as Map<String, dynamic>?;
// // // // //     },
// // // // //   );

// // // // //   /// Mark session complete and record final scores.
// // // // //   Future<void> completeSession({
// // // // //     required String sessionId,
// // // // //     required Map<String, dynamic> finalSnapshot,
// // // // //     required String endReason,
// // // // //   }) => guardedCall(
// // // // //     operationName: 'completeTodSession',
// // // // //     operation: () async {
// // // // //       await _supabase
// // // // //           .from('game_sessions')
// // // // //           .update({
// // // // //             'status': 'completed',
// // // // //             'state_snapshot': finalSnapshot,
// // // // //             'ended_at': DateTime.now().toIso8601String(),
// // // // //           })
// // // // //           .eq('id', sessionId);
// // // // //     },
// // // // //   );
// // // // // }

// // // // import 'dart:convert';

// // // // import 'package:sqflite/sqflite.dart';
// // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // import 'package:uuid/uuid.dart';

// // // // import '../../../../core/data/base_repository.dart';
// // // // import '../../../../core/storage/database/app_database.dart';
// // // // import '../../../../core/utils/app_logger.dart';
// // // // import '../domain/tod_models.dart';
// // // // import '../../engine/base_game_engine.dart';

// // // // const _uuid = Uuid();

// // // // /// Truth or Dare DB persistence layer.
// // // // ///
// // // // /// Priority order for card loading:
// // // // ///   1. Local SQLite cache (AppDatabase — offline-first)
// // // // ///   2. Supabase remote (online fallback)
// // // // ///
// // // // /// Session persistence:
// // // // ///   - Owner creates a game_sessions row at start
// // // // ///   - Owner saves snapshots every 10s for reconnect recovery
// // // // ///   - Session marked completed when game ends
// // // // class TodRepository extends BaseRepository {
// // // //   TodRepository._();
// // // //   static final TodRepository _instance = TodRepository._();
// // // //   static TodRepository get instance => _instance;

// // // //   final _supabase = Supabase.instance.client;

// // // //   // ── Card loading ───────────────────────────────────────────────────────────

// // // //   /// Primary: load from remote Supabase (online).
// // // //   Future<List<TodCard>> loadCards({
// // // //     required String packId,
// // // //     required String language,
// // // //     bool allowSpicy = false,
// // // //   }) => guardedCall(
// // // //     operationName: 'loadTodCards',
// // // //     operation: () async {
// // // //       var q = _supabase
// // // //           .from('pack_cards')
// // // //           .select('id, content, card_type, difficulty')
// // // //           .eq('pack_id', packId)
// // // //           .eq('is_active', true);

// // // //       if (!allowSpicy) q = q.neq('difficulty', 'spicy');

// // // //       final rows = await q.order('sort_order');

// // // //       return rows.map((r) {
// // // //         final contentJson = r['content'] as Map<String, dynamic>? ?? {};
// // // //         final content =
// // // //             contentJson[language] as String? ??
// // // //             contentJson['en'] as String? ??
// // // //             '';
// // // //         return TodCard(
// // // //           id: r['id'] as String,
// // // //           content: content,
// // // //           type: TodCardType.values.firstWhere(
// // // //             (t) => t.name == (r['card_type'] as String? ?? 'truth'),
// // // //             orElse: () => TodCardType.truth,
// // // //           ),
// // // //           difficulty: TodDifficulty.values.firstWhere(
// // // //             (d) => d.name == (r['difficulty'] as String? ?? 'mild'),
// // // //             orElse: () => TodDifficulty.mild,
// // // //           ),
// // // //         );
// // // //       }).toList();
// // // //     },
// // // //   );

// // // //   /// Fallback: load from local SQLite (downloaded packs cache).
// // // //   Future<List<TodCard>> loadCardsFromCache({
// // // //     required String packId,
// // // //     required String language,
// // // //     bool allowSpicy = false,
// // // //   }) async {
// // // //     try {
// // // //       final db = AppDatabase.instance.db;

// // // //       var sql = '''
// // // //         SELECT id, content_json, card_type, difficulty
// // // //         FROM pack_cards_cache
// // // //         WHERE pack_id = ?
// // // //       ''';
// // // //       final params = <Object>[packId];
// // // //       if (!allowSpicy) {
// // // //         sql += ' AND difficulty != ?';
// // // //         params.add('spicy');
// // // //       }
// // // //       sql += ' ORDER BY sort_order';

// // // //       final rows = await db.rawQuery(sql, params);

// // // //       // Debug: log how many cards were found
// // // //       AppLogger.debug(
// // // //         'TodRepository: found ${rows.length} cards for pack $packId',
// // // //       );

// // // //       // Also check if pack exists at all
// // // //       if (rows.isEmpty) {
// // // //         final packCheck = await db.rawQuery(
// // // //           'SELECT COUNT(*) as cnt FROM pack_cards WHERE pack_id = ?',
// // // //           [packId],
// // // //         );
// // // //         final cardCount = packCheck.first['cnt'] as int? ?? 0;
// // // //         AppLogger.debug(
// // // //           'TodRepository: pack_cards direct count = $cardCount for $packId',
// // // //         );
// // // //         // Try without the view
// // // //         if (cardCount > 0) {
// // // //           final directRows = await db.rawQuery(
// // // //             'SELECT id, content_json, card_type, difficulty, sort_order FROM pack_cards WHERE pack_id = ? ORDER BY sort_order',
// // // //             [packId],
// // // //           );
// // // //           AppLogger.debug(
// // // //             'TodRepository: direct query returned ${directRows.length} rows',
// // // //           );
// // // //           return directRows.map((r) {
// // // //             final rawContent = r['content_json'];
// // // //             final contentStr = rawContent is String
// // // //                 ? rawContent
// // // //                 : jsonEncode(rawContent ?? '{}');
// // // //             Map<String, dynamic> contentJson;
// // // //             try {
// // // //               contentJson = jsonDecode(contentStr) as Map<String, dynamic>;
// // // //             } catch (_) {
// // // //               contentJson = {'en': contentStr};
// // // //             }
// // // //             final content =
// // // //                 contentJson[language] as String? ??
// // // //                 contentJson['en'] as String? ??
// // // //                 '';
// // // //             return TodCard(
// // // //               id: r['id'] as String,
// // // //               content: content,
// // // //               type: TodCardType.values.firstWhere(
// // // //                 (t) => t.name == r['card_type'],
// // // //                 orElse: () => TodCardType.truth,
// // // //               ),
// // // //               difficulty: TodDifficulty.values.firstWhere(
// // // //                 (d) => d.name == r['difficulty'],
// // // //                 orElse: () => TodDifficulty.mild,
// // // //               ),
// // // //             );
// // // //           }).toList();
// // // //         }
// // // //       }

// // // //       return rows.map((r) {
// // // //         final rawJson = r['content_json'];
// // // //         final contentStr = rawJson is String
// // // //             ? rawJson
// // // //             : jsonEncode(rawJson ?? '{}');
// // // //         dynamic decoded;
// // // //         try {
// // // //           decoded = jsonDecode(contentStr);
// // // //         } catch (_) {
// // // //           decoded = <String, dynamic>{};
// // // //         }
// // // //         if (decoded is String) {
// // // //           try {
// // // //             decoded = jsonDecode(decoded);
// // // //           } catch (_) {
// // // //             decoded = <String, dynamic>{};
// // // //           }
// // // //         }
// // // //         final contentJson = decoded is Map
// // // //             ? Map<String, dynamic>.from(decoded)
// // // //             : <String, dynamic>{};
// // // //         final content =
// // // //             contentJson[language] as String? ??
// // // //             contentJson['en'] as String? ??
// // // //             '';
// // // //         return TodCard(
// // // //           id: r['id'] as String,
// // // //           content: content,
// // // //           type: TodCardType.values.firstWhere(
// // // //             (t) => t.name == r['card_type'],
// // // //             orElse: () => TodCardType.truth,
// // // //           ),
// // // //           difficulty: TodDifficulty.values.firstWhere(
// // // //             (d) => d.name == r['difficulty'],
// // // //             orElse: () => TodDifficulty.mild,
// // // //           ),
// // // //         );
// // // //       }).toList();
// // // //     } catch (e) {
// // // //       AppLogger.debug('TodRepository: SQLite cache miss for $packId — $e');
// // // //       return [];
// // // //     }
// // // //   }

// // // //   // ── Session persistence ────────────────────────────────────────────────────

// // // //   Future<String> createSession({
// // // //     required String roomId,
// // // //     required String packId,
// // // //     required GameConfig config,
// // // //     required List<String> playerIds,
// // // //     required String ownerId,
// // // //   }) => guardedCall(
// // // //     operationName: 'createTodSession',
// // // //     operation: () async {
// // // //       final row = await _supabase
// // // //           .from('game_sessions')
// // // //           .insert({
// // // //             'room_id': roomId,
// // // //             'pack_id': packId,
// // // //             'game_type': GameType.truthOrDare.toDbString(),
// // // //             'owner_id': ownerId,
// // // //             'player_ids': playerIds,
// // // //             'state_snapshot': {},
// // // //             'max_rounds': config.maxRounds,
// // // //             'turn_timer_secs': config.turnTimerSeconds,
// // // //             'allow_skip': config.allowSkip,
// // // //             'allow_spicy': config.allowSpicy,
// // // //             'status': 'active',
// // // //           })
// // // //           .select('id')
// // // //           .single();
// // // //       return row['id'] as String;
// // // //     },
// // // //   );

// // // //   /// Called every 10s by owner to persist the current snapshot.
// // // //   /// Followers use this as a reconnect fallback.
// // // //   Future<void> saveSnapshot({
// // // //     required String sessionId,
// // // //     required Map<String, dynamic> snapshot,
// // // //   }) => guardedCall(
// // // //     operationName: 'saveTodSnapshot',
// // // //     operation: () async {
// // // //       await _supabase
// // // //           .from('game_sessions')
// // // //           .update({
// // // //             'state_snapshot': snapshot,
// // // //             'snapshot_at': DateTime.now().toIso8601String(),
// // // //           })
// // // //           .eq('id', sessionId);
// // // //     },
// // // //   );

// // // //   /// Load the latest snapshot from DB (8s timeout fallback for followers).
// // // //   Future<Map<String, dynamic>?> loadSnapshot(String sessionId) => guardedCall(
// // // //     operationName: 'loadTodSnapshot',
// // // //     operation: () async {
// // // //       final row = await _supabase
// // // //           .from('game_sessions')
// // // //           .select('state_snapshot, status')
// // // //           .eq('id', sessionId)
// // // //           .single();

// // // //       if (row['status'] == 'completed' || row['status'] == 'aborted') {
// // // //         return null;
// // // //       }
// // // //       return row['state_snapshot'] as Map<String, dynamic>?;
// // // //     },
// // // //   );

// // // //   /// Mark session complete and record final scores.
// // // //   Future<void> completeSession({
// // // //     required String sessionId,
// // // //     required Map<String, dynamic> finalSnapshot,
// // // //     required String endReason,
// // // //   }) => guardedCall(
// // // //     operationName: 'completeTodSession',
// // // //     operation: () async {
// // // //       await _supabase
// // // //           .from('game_sessions')
// // // //           .update({
// // // //             'status': 'completed',
// // // //             'state_snapshot': finalSnapshot,
// // // //             'ended_at': DateTime.now().toIso8601String(),
// // // //           })
// // // //           .eq('id', sessionId);
// // // //     },
// // // //   );
// // // // }

// // // import 'dart:convert';

// // // import 'package:sqflite/sqflite.dart';
// // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // import 'package:uuid/uuid.dart';

// // // import '../../../../core/data/base_repository.dart';
// // // import '../../../../core/storage/database/app_database.dart';
// // // import '../../../../core/utils/app_logger.dart';
// // // import '../domain/tod_models.dart';
// // // import '../../engine/base_game_engine.dart';

// // // const _uuid = Uuid();

// // // /// Truth or Dare DB persistence layer.
// // // ///
// // // /// Priority order for card loading:
// // // ///   1. Local SQLite cache (AppDatabase — offline-first)
// // // ///   2. Supabase remote (online fallback)
// // // ///
// // // /// Session persistence:
// // // ///   - Owner creates a game_sessions row at start
// // // ///   - Owner saves snapshots every 10s for reconnect recovery
// // // ///   - Session marked completed when game ends
// // // class TodRepository extends BaseRepository {
// // //   TodRepository._();
// // //   static final TodRepository _instance = TodRepository._();
// // //   static TodRepository get instance => _instance;

// // //   final _supabase = Supabase.instance.client;

// // //   // ── Card loading ───────────────────────────────────────────────────────────

// // //   /// Primary: load from remote Supabase (online).
// // //   Future<List<TodCard>> loadCards({
// // //     required String packId,
// // //     required String language,
// // //     bool allowSpicy = false,
// // //   }) => guardedCall(
// // //     operationName: 'loadTodCards',
// // //     operation: () async {
// // //       var q = _supabase
// // //           .from('pack_cards')
// // //           .select('id, content, card_type, difficulty')
// // //           .eq('pack_id', packId)
// // //           .eq('is_active', true);

// // //       if (!allowSpicy) q = q.neq('difficulty', 'spicy');

// // //       final rows = await q.order('sort_order');

// // //       return rows.map((r) {
// // //         final contentJson = r['content'] as Map<String, dynamic>? ?? {};
// // //         final content =
// // //             contentJson[language] as String? ??
// // //             contentJson['en'] as String? ??
// // //             '';
// // //         return TodCard(
// // //           id: r['id'] as String,
// // //           content: content,
// // //           type: TodCardType.values.firstWhere(
// // //             (t) => t.name == (r['card_type'] as String? ?? 'truth'),
// // //             orElse: () => TodCardType.truth,
// // //           ),
// // //           difficulty: TodDifficulty.values.firstWhere(
// // //             (d) => d.name == (r['difficulty'] as String? ?? 'mild'),
// // //             orElse: () => TodDifficulty.mild,
// // //           ),
// // //         );
// // //       }).toList();
// // //     },
// // //   );

// // //   /// Fallback: load from local SQLite (downloaded packs cache).
// // //   Future<List<TodCard>> loadCardsFromCache({
// // //     required String packId,
// // //     required String language,
// // //     bool allowSpicy = false,
// // //   }) async {
// // //     try {
// // //       final db = AppDatabase.instance.db;

// // //       var sql = '''
// // //         SELECT id, content_json, card_type, difficulty
// // //         FROM pack_cards_cache
// // //         WHERE pack_id = ?
// // //       ''';
// // //       final params = <Object>[packId];
// // //       if (!allowSpicy) {
// // //         sql += ' AND difficulty != ?';
// // //         params.add('spicy');
// // //       }
// // //       sql += ' ORDER BY sort_order';

// // //       final rows = await db.rawQuery(sql, params);

// // //       // Debug: log how many cards were found
// // //       AppLogger.debug(
// // //         'TodRepository: found ${rows.length} cards for pack $packId',
// // //       );

// // //       // Also check if pack exists at all
// // //       if (rows.isEmpty) {
// // //         final packCheck = await db.rawQuery(
// // //           'SELECT COUNT(*) as cnt FROM pack_cards WHERE pack_id = ?',
// // //           [packId],
// // //         );
// // //         final cardCount = packCheck.first['cnt'] as int? ?? 0;
// // //         AppLogger.debug(
// // //           'TodRepository: pack_cards direct count = $cardCount for $packId',
// // //         );
// // //         // Try without the view
// // //         if (cardCount > 0) {
// // //           final directRows = await db.rawQuery(
// // //             'SELECT id, content_json, card_type, difficulty, sort_order FROM pack_cards WHERE pack_id = ? ORDER BY sort_order',
// // //             [packId],
// // //           );
// // //           AppLogger.debug(
// // //             'TodRepository: direct query returned ${directRows.length} rows',
// // //           );
// // //           return directRows.map((r) {
// // //             final rawContent = r['content_json'];
// // //             final contentStr = rawContent is String
// // //                 ? rawContent
// // //                 : jsonEncode(rawContent ?? '{}');
// // //             Map<String, dynamic> contentJson;
// // //             try {
// // //               contentJson = jsonDecode(contentStr) as Map<String, dynamic>;
// // //             } catch (_) {
// // //               contentJson = {'en': contentStr};
// // //             }
// // //             final content =
// // //                 contentJson[language] as String? ??
// // //                 contentJson['en'] as String? ??
// // //                 '';
// // //             return TodCard(
// // //               id: r['id'] as String,
// // //               content: content,
// // //               type: TodCardType.values.firstWhere(
// // //                 (t) => t.name == r['card_type'],
// // //                 orElse: () => TodCardType.truth,
// // //               ),
// // //               difficulty: TodDifficulty.values.firstWhere(
// // //                 (d) => d.name == r['difficulty'],
// // //                 orElse: () => TodDifficulty.mild,
// // //               ),
// // //             );
// // //           }).toList();
// // //         }
// // //       }

// // //       return rows.map((r) {
// // //         final rawJson = r['content_json'];
// // //         final contentStr = rawJson is String
// // //             ? rawJson
// // //             : jsonEncode(rawJson ?? '{}');
// // //         dynamic decoded;
// // //         try {
// // //           decoded = jsonDecode(contentStr);
// // //         } catch (_) {
// // //           decoded = <String, dynamic>{};
// // //         }
// // //         if (decoded is String) {
// // //           try {
// // //             decoded = jsonDecode(decoded);
// // //           } catch (_) {
// // //             decoded = <String, dynamic>{};
// // //           }
// // //         }
// // //         final contentJson = decoded is Map
// // //             ? Map<String, dynamic>.from(decoded)
// // //             : <String, dynamic>{};
// // //         final content =
// // //             contentJson[language] as String? ??
// // //             contentJson['en'] as String? ??
// // //             '';
// // //         return TodCard(
// // //           id: r['id'] as String,
// // //           content: content,
// // //           type: TodCardType.values.firstWhere(
// // //             (t) => t.name == r['card_type'],
// // //             orElse: () => TodCardType.truth,
// // //           ),
// // //           difficulty: TodDifficulty.values.firstWhere(
// // //             (d) => d.name == r['difficulty'],
// // //             orElse: () => TodDifficulty.mild,
// // //           ),
// // //         );
// // //       }).toList();
// // //     } catch (e) {
// // //       AppLogger.debug('TodRepository: SQLite cache miss for $packId — $e');
// // //     }

// // //     // Fallback: fetch directly from Supabase (pack not downloaded yet)
// // //     AppLogger.info('TodRepository: fetching cards from Supabase for $packId');
// // //     try {
// // //       final query = _supabase
// // //           .from('pack_cards')
// // //           .select('id, content, card_type, difficulty, sort_order')
// // //           .eq('pack_id', packId)
// // //           .order('sort_order');

// // //       final rows = await query as List;
// // //       return rows.map((r) {
// // //         final rawContent = r['content'];
// // //         Map<String, dynamic> contentJson;
// // //         try {
// // //           if (rawContent is Map) {
// // //             contentJson = Map<String, dynamic>.from(rawContent);
// // //           } else if (rawContent is String) {
// // //             final decoded = jsonDecode(rawContent);
// // //             contentJson = decoded is Map
// // //                 ? Map<String, dynamic>.from(decoded)
// // //                 : {'en': rawContent};
// // //           } else {
// // //             contentJson = {};
// // //           }
// // //         } catch (_) {
// // //           contentJson = {};
// // //         }
// // //         final content =
// // //             contentJson[language] as String? ??
// // //             contentJson['en'] as String? ??
// // //             '';
// // //         return TodCard(
// // //           id: r['id'] as String,
// // //           content: content,
// // //           type: TodCardType.values.firstWhere(
// // //             (t) => t.name == (r['card_type'] as String? ?? ''),
// // //             orElse: () => TodCardType.truth,
// // //           ),
// // //           difficulty: TodDifficulty.values.firstWhere(
// // //             (d) => d.name == (r['difficulty'] as String? ?? ''),
// // //             orElse: () => TodDifficulty.mild,
// // //           ),
// // //         );
// // //       }).toList();
// // //     } catch (e) {
// // //       AppLogger.error(
// // //         'TodRepository: Supabase fallback failed for $packId',
// // //         error: e,
// // //       );
// // //       return [];
// // //     }
// // //   }

// // //   // ── Session persistence ────────────────────────────────────────────────────

// // //   Future<String> createSession({
// // //     required String roomId,
// // //     required String packId,
// // //     required GameConfig config,
// // //     required List<String> playerIds,
// // //     required String ownerId,
// // //   }) => guardedCall(
// // //     operationName: 'createTodSession',
// // //     operation: () async {
// // //       final row = await _supabase
// // //           .from('game_sessions')
// // //           .insert({
// // //             'room_id': roomId,
// // //             'pack_id': packId,
// // //             'game_type': GameType.truthOrDare.toDbString(),
// // //             'owner_id': ownerId,
// // //             'player_ids': playerIds,
// // //             'state_snapshot': {},
// // //             'max_rounds': config.maxRounds,
// // //             'turn_timer_secs': config.turnTimerSeconds,
// // //             'allow_skip': config.allowSkip,
// // //             'allow_spicy': config.allowSpicy,
// // //             'status': 'active',
// // //           })
// // //           .select('id')
// // //           .single();
// // //       return row['id'] as String;
// // //     },
// // //   );

// // //   /// Called every 10s by owner to persist the current snapshot.
// // //   /// Followers use this as a reconnect fallback.
// // //   Future<void> saveSnapshot({
// // //     required String sessionId,
// // //     required Map<String, dynamic> snapshot,
// // //   }) => guardedCall(
// // //     operationName: 'saveTodSnapshot',
// // //     operation: () async {
// // //       await _supabase
// // //           .from('game_sessions')
// // //           .update({
// // //             'state_snapshot': snapshot,
// // //             'snapshot_at': DateTime.now().toIso8601String(),
// // //           })
// // //           .eq('id', sessionId);
// // //     },
// // //   );

// // //   /// Load the latest snapshot from DB (8s timeout fallback for followers).
// // //   Future<Map<String, dynamic>?> loadSnapshot(String sessionId) => guardedCall(
// // //     operationName: 'loadTodSnapshot',
// // //     operation: () async {
// // //       final row = await _supabase
// // //           .from('game_sessions')
// // //           .select('state_snapshot, status')
// // //           .eq('id', sessionId)
// // //           .single();

// // //       if (row['status'] == 'completed' || row['status'] == 'aborted') {
// // //         return null;
// // //       }
// // //       return row['state_snapshot'] as Map<String, dynamic>?;
// // //     },
// // //   );

// // //   /// Mark session complete and record final scores.
// // //   Future<void> completeSession({
// // //     required String sessionId,
// // //     required Map<String, dynamic> finalSnapshot,
// // //     required String endReason,
// // //   }) => guardedCall(
// // //     operationName: 'completeTodSession',
// // //     operation: () async {
// // //       await _supabase
// // //           .from('game_sessions')
// // //           .update({
// // //             'status': 'completed',
// // //             'state_snapshot': finalSnapshot,
// // //             'ended_at': DateTime.now().toIso8601String(),
// // //           })
// // //           .eq('id', sessionId);
// // //     },
// // //   );
// // // }

// // import 'dart:convert';

// // import 'package:sqflite/sqflite.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart';
// // import 'package:uuid/uuid.dart';

// // import '../../../../core/data/base_repository.dart';
// // import '../../../../core/storage/database/app_database.dart';
// // import '../../../../core/utils/app_logger.dart';
// // import '../domain/tod_models.dart';
// // import '../../engine/base_game_engine.dart';

// // const _uuid = Uuid();

// // /// Truth or Dare DB persistence layer.
// // ///
// // /// Priority order for card loading:
// // ///   1. Local SQLite cache (AppDatabase — offline-first)
// // ///   2. Supabase remote (online fallback)
// // ///
// // /// Session persistence:
// // ///   - Owner creates a game_sessions row at start
// // ///   - Owner saves snapshots every 10s for reconnect recovery
// // ///   - Session marked completed when game ends
// // class TodRepository extends BaseRepository {
// //   TodRepository._();
// //   static final TodRepository _instance = TodRepository._();
// //   static TodRepository get instance => _instance;

// //   final _supabase = Supabase.instance.client;

// //   // ── Card loading ───────────────────────────────────────────────────────────

// //   /// Primary: load from remote Supabase (online).
// //   Future<List<TodCard>> loadCards({
// //     required String packId,
// //     required String language,
// //     bool allowSpicy = false,
// //   }) => guardedCall(
// //     operationName: 'loadTodCards',
// //     operation: () async {
// //       var q = _supabase
// //           .from('pack_cards')
// //           .select('id, content, card_type, difficulty')
// //           .eq('pack_id', packId)
// //           .eq('is_active', true);

// //       if (!allowSpicy) q = q.neq('difficulty', 'spicy');

// //       final rows = await q.order('sort_order');

// //       return rows.map((r) {
// //         final contentJson = r['content'] as Map<String, dynamic>? ?? {};
// //         final content =
// //             contentJson[language] as String? ??
// //             contentJson['en'] as String? ??
// //             '';
// //         return TodCard(
// //           id: r['id'] as String,
// //           content: content,
// //           type: TodCardType.values.firstWhere(
// //             (t) => t.name == (r['card_type'] as String? ?? 'truth'),
// //             orElse: () => TodCardType.truth,
// //           ),
// //           difficulty: TodDifficulty.values.firstWhere(
// //             (d) => d.name == (r['difficulty'] as String? ?? 'mild'),
// //             orElse: () => TodDifficulty.mild,
// //           ),
// //         );
// //       }).toList();
// //     },
// //   );

// //   /// Fallback: load from local SQLite (downloaded packs cache).
// //   Future<List<TodCard>> loadCardsFromCache({
// //     required String packId,
// //     required String language,
// //     bool allowSpicy = false,
// //   }) async {
// //     try {
// //       final db = AppDatabase.instance.db;

// //       var sql = '''
// //         SELECT id, content_json, card_type, difficulty
// //         FROM pack_cards_cache
// //         WHERE pack_id = ?
// //       ''';
// //       final params = <Object>[packId];
// //       if (!allowSpicy) {
// //         sql += ' AND difficulty != ?';
// //         params.add('spicy');
// //       }
// //       sql += ' ORDER BY sort_order';

// //       final rows = await db.rawQuery(sql, params);

// //       // Debug: log how many cards were found
// //       AppLogger.debug(
// //         'TodRepository: found ${rows.length} cards for pack $packId',
// //       );

// //       // Also check if pack exists at all
// //       if (rows.isEmpty) {
// //         final packCheck = await db.rawQuery(
// //           'SELECT COUNT(*) as cnt FROM pack_cards WHERE pack_id = ?',
// //           [packId],
// //         );
// //         final cardCount = packCheck.first['cnt'] as int? ?? 0;
// //         AppLogger.debug(
// //           'TodRepository: pack_cards direct count = $cardCount for $packId',
// //         );
// //         // Try without the view
// //         if (cardCount > 0) {
// //           final directRows = await db.rawQuery(
// //             'SELECT id, content_json, card_type, difficulty, sort_order FROM pack_cards WHERE pack_id = ? ORDER BY sort_order',
// //             [packId],
// //           );
// //           AppLogger.debug(
// //             'TodRepository: direct query returned ${directRows.length} rows',
// //           );
// //           return directRows.map((r) {
// //             final rawContent = r['content_json'];
// //             final contentStr = rawContent is String
// //                 ? rawContent
// //                 : jsonEncode(rawContent ?? '{}');
// //             Map<String, dynamic> contentJson;
// //             try {
// //               contentJson = jsonDecode(contentStr) as Map<String, dynamic>;
// //             } catch (_) {
// //               contentJson = {'en': contentStr};
// //             }
// //             final content =
// //                 contentJson[language] as String? ??
// //                 contentJson['en'] as String? ??
// //                 '';
// //             return TodCard(
// //               id: r['id'] as String,
// //               content: content,
// //               type: TodCardType.values.firstWhere(
// //                 (t) => t.name == r['card_type'],
// //                 orElse: () => TodCardType.truth,
// //               ),
// //               difficulty: TodDifficulty.values.firstWhere(
// //                 (d) => d.name == r['difficulty'],
// //                 orElse: () => TodDifficulty.mild,
// //               ),
// //             );
// //           }).toList();
// //         }
// //       }

// //       return rows.map((r) {
// //         final rawJson = r['content_json'];
// //         final contentStr = rawJson is String
// //             ? rawJson
// //             : jsonEncode(rawJson ?? '{}');
// //         dynamic decoded;
// //         try {
// //           decoded = jsonDecode(contentStr);
// //         } catch (_) {
// //           decoded = <String, dynamic>{};
// //         }
// //         if (decoded is String) {
// //           try {
// //             decoded = jsonDecode(decoded);
// //           } catch (_) {
// //             decoded = <String, dynamic>{};
// //           }
// //         }
// //         final contentJson = decoded is Map
// //             ? Map<String, dynamic>.from(decoded)
// //             : <String, dynamic>{};
// //         final content =
// //             contentJson[language] as String? ??
// //             contentJson['en'] as String? ??
// //             '';
// //         return TodCard(
// //           id: r['id'] as String,
// //           content: content,
// //           type: TodCardType.values.firstWhere(
// //             (t) => t.name == r['card_type'],
// //             orElse: () => TodCardType.truth,
// //           ),
// //           difficulty: TodDifficulty.values.firstWhere(
// //             (d) => d.name == r['difficulty'],
// //             orElse: () => TodDifficulty.mild,
// //           ),
// //         );
// //       }).toList();
// //     } catch (e) {
// //       AppLogger.debug('TodRepository: SQLite cache miss for $packId — $e');
// //     }

// //     // Fallback: fetch directly from Supabase (pack not downloaded yet)
// //     AppLogger.info('TodRepository: fetching cards from Supabase for $packId');
// //     try {
// //       final query = _supabase
// //           .from('pack_cards')
// //           .select('id, content, card_type, difficulty, sort_order')
// //           .eq('pack_id', packId)
// //           .order('sort_order');

// //       final rows = await query as List;
// //       // ignore: avoid_print
// //       print(
// //         '=== Supabase cards: ${rows.length}, first content: ${rows.isNotEmpty ? rows.first['content'] : 'none'}',
// //       );
// //       return rows.map((r) {
// //         final rawContent = r['content'];
// //         Map<String, dynamic> contentJson;
// //         try {
// //           if (rawContent is Map) {
// //             contentJson = Map<String, dynamic>.from(rawContent);
// //           } else if (rawContent is String) {
// //             final decoded = jsonDecode(rawContent);
// //             contentJson = decoded is Map
// //                 ? Map<String, dynamic>.from(decoded)
// //                 : {'en': rawContent};
// //           } else {
// //             contentJson = {};
// //           }
// //         } catch (_) {
// //           contentJson = {};
// //         }
// //         final content =
// //             contentJson[language] as String? ??
// //             contentJson['en'] as String? ??
// //             '';
// //         return TodCard(
// //           id: r['id'] as String,
// //           content: content,
// //           type: TodCardType.values.firstWhere(
// //             (t) => t.name == (r['card_type'] as String? ?? ''),
// //             orElse: () => TodCardType.truth,
// //           ),
// //           difficulty: TodDifficulty.values.firstWhere(
// //             (d) => d.name == (r['difficulty'] as String? ?? ''),
// //             orElse: () => TodDifficulty.mild,
// //           ),
// //         );
// //       }).toList();
// //     } catch (e) {
// //       AppLogger.error(
// //         'TodRepository: Supabase fallback failed for $packId',
// //         error: e,
// //       );
// //       return [];
// //     }
// //   }

// //   // ── Session persistence ────────────────────────────────────────────────────

// //   Future<String> createSession({
// //     required String roomId,
// //     required String packId,
// //     required GameConfig config,
// //     required List<String> playerIds,
// //     required String ownerId,
// //   }) => guardedCall(
// //     operationName: 'createTodSession',
// //     operation: () async {
// //       final row = await _supabase
// //           .from('game_sessions')
// //           .insert({
// //             'room_id': roomId,
// //             'pack_id': packId,
// //             'game_type': GameType.truthOrDare.toDbString(),
// //             'owner_id': ownerId,
// //             'player_ids': playerIds,
// //             'state_snapshot': {},
// //             'max_rounds': config.maxRounds,
// //             'turn_timer_secs': config.turnTimerSeconds,
// //             'allow_skip': config.allowSkip,
// //             'allow_spicy': config.allowSpicy,
// //             'status': 'active',
// //           })
// //           .select('id')
// //           .single();
// //       return row['id'] as String;
// //     },
// //   );

// //   /// Called every 10s by owner to persist the current snapshot.
// //   /// Followers use this as a reconnect fallback.
// //   Future<void> saveSnapshot({
// //     required String sessionId,
// //     required Map<String, dynamic> snapshot,
// //   }) => guardedCall(
// //     operationName: 'saveTodSnapshot',
// //     operation: () async {
// //       await _supabase
// //           .from('game_sessions')
// //           .update({
// //             'state_snapshot': snapshot,
// //             'snapshot_at': DateTime.now().toIso8601String(),
// //           })
// //           .eq('id', sessionId);
// //     },
// //   );

// //   /// Load the latest snapshot from DB (8s timeout fallback for followers).
// //   Future<Map<String, dynamic>?> loadSnapshot(String sessionId) => guardedCall(
// //     operationName: 'loadTodSnapshot',
// //     operation: () async {
// //       final row = await _supabase
// //           .from('game_sessions')
// //           .select('state_snapshot, status')
// //           .eq('id', sessionId)
// //           .single();

// //       if (row['status'] == 'completed' || row['status'] == 'aborted') {
// //         return null;
// //       }
// //       return row['state_snapshot'] as Map<String, dynamic>?;
// //     },
// //   );

// //   /// Mark session complete and record final scores.
// //   Future<void> completeSession({
// //     required String sessionId,
// //     required Map<String, dynamic> finalSnapshot,
// //     required String endReason,
// //   }) => guardedCall(
// //     operationName: 'completeTodSession',
// //     operation: () async {
// //       await _supabase
// //           .from('game_sessions')
// //           .update({
// //             'status': 'completed',
// //             'state_snapshot': finalSnapshot,
// //             'ended_at': DateTime.now().toIso8601String(),
// //           })
// //           .eq('id', sessionId);
// //     },
// //   );
// // }

// import 'dart:convert';

// import 'package:sqflite/sqflite.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:uuid/uuid.dart';

// import '../../../../core/data/base_repository.dart';
// import '../../../../core/storage/database/app_database.dart';
// import '../../../../core/utils/app_logger.dart';
// import '../domain/tod_models.dart';
// import '../../engine/base_game_engine.dart';

// const _uuid = Uuid();

// /// Truth or Dare DB persistence layer.
// ///
// /// Priority order for card loading:
// ///   1. Local SQLite cache (AppDatabase — offline-first)
// ///   2. Supabase remote (online fallback)
// ///
// /// Session persistence:
// ///   - Owner creates a game_sessions row at start
// ///   - Owner saves snapshots every 10s for reconnect recovery
// ///   - Session marked completed when game ends
// class TodRepository extends BaseRepository {
//   TodRepository._();
//   static final TodRepository _instance = TodRepository._();
//   static TodRepository get instance => _instance;

//   final _supabase = Supabase.instance.client;

//   // ── Card loading ───────────────────────────────────────────────────────────

//   /// Primary: load from remote Supabase (online).
//   Future<List<TodCard>> loadCards({
//     required String packId,
//     required String language,
//     bool allowSpicy = false,
//   }) => guardedCall(
//     operationName: 'loadTodCards',
//     operation: () async {
//       var q = _supabase
//           .from('pack_cards')
//           .select('id, content, card_type, difficulty')
//           .eq('pack_id', packId)
//           .eq('is_active', true);

//       if (!allowSpicy) q = q.neq('difficulty', 'spicy');

//       final rows = await q.order('sort_order');

//       return rows.map((r) {
//         final contentJson = r['content'] as Map<String, dynamic>? ?? {};
//         final content =
//             contentJson[language] as String? ??
//             contentJson['en'] as String? ??
//             '';
//         return TodCard(
//           id: r['id'] as String,
//           content: content,
//           type: TodCardType.values.firstWhere(
//             (t) => t.name == (r['card_type'] as String? ?? 'truth'),
//             orElse: () => TodCardType.truth,
//           ),
//           difficulty: TodDifficulty.values.firstWhere(
//             (d) => d.name == (r['difficulty'] as String? ?? 'mild'),
//             orElse: () => TodDifficulty.mild,
//           ),
//         );
//       }).toList();
//     },
//   );

//   /// Fallback: load from local SQLite (downloaded packs cache).
//   Future<List<TodCard>> loadCardsFromCache({
//     required String packId,
//     required String language,
//     bool allowSpicy = false,
//   }) async {
//     try {
//       final db = AppDatabase.instance.db;

//       var sql = '''
//         SELECT id, content_json, card_type, difficulty
//         FROM pack_cards_cache
//         WHERE pack_id = ?
//       ''';
//       final params = <Object>[packId];
//       if (!allowSpicy) {
//         sql += ' AND difficulty != ?';
//         params.add('spicy');
//       }
//       sql += ' ORDER BY sort_order';

//       final rows = await db.rawQuery(sql, params);

//       // Debug: log how many cards were found
//       AppLogger.debug(
//         'TodRepository: found ${rows.length} cards for pack $packId, language=$language',
//       );
//       if (rows.isNotEmpty) {
//         // ignore: avoid_print
//         print(
//           '=== RAW first row content_json: ${rows.first["content_json"]?.runtimeType} = ${rows.first["content_json"]}',
//         );
//       }

//       // Also check if pack exists at all
//       if (rows.isEmpty) {
//         final packCheck = await db.rawQuery(
//           'SELECT COUNT(*) as cnt FROM pack_cards WHERE pack_id = ?',
//           [packId],
//         );
//         final cardCount = packCheck.first['cnt'] as int? ?? 0;
//         AppLogger.debug(
//           'TodRepository: pack_cards direct count = $cardCount for $packId',
//         );
//         // Try without the view
//         if (cardCount > 0) {
//           final directRows = await db.rawQuery(
//             'SELECT id, content_json, card_type, difficulty, sort_order FROM pack_cards WHERE pack_id = ? ORDER BY sort_order',
//             [packId],
//           );
//           AppLogger.debug(
//             'TodRepository: direct query returned ${directRows.length} rows',
//           );
//           return directRows.map((r) {
//             final rawContent = r['content_json'];
//             final contentStr = rawContent is String
//                 ? rawContent
//                 : jsonEncode(rawContent ?? '{}');
//             Map<String, dynamic> contentJson;
//             try {
//               contentJson = jsonDecode(contentStr) as Map<String, dynamic>;
//             } catch (_) {
//               contentJson = {'en': contentStr};
//             }
//             final content =
//                 contentJson[language] as String? ??
//                 contentJson['en'] as String? ??
//                 '';
//             return TodCard(
//               id: r['id'] as String,
//               content: content,
//               type: TodCardType.values.firstWhere(
//                 (t) => t.name == r['card_type'],
//                 orElse: () => TodCardType.truth,
//               ),
//               difficulty: TodDifficulty.values.firstWhere(
//                 (d) => d.name == r['difficulty'],
//                 orElse: () => TodDifficulty.mild,
//               ),
//             );
//           }).toList();
//         }
//       }

//       return rows.map((r) {
//         final rawJson = r['content_json'];
//         final contentStr = rawJson is String
//             ? rawJson
//             : jsonEncode(rawJson ?? '{}');
//         dynamic decoded;
//         try {
//           decoded = jsonDecode(contentStr);
//         } catch (_) {
//           decoded = <String, dynamic>{};
//         }
//         if (decoded is String) {
//           try {
//             decoded = jsonDecode(decoded);
//           } catch (_) {
//             decoded = <String, dynamic>{};
//           }
//         }
//         final contentJson = decoded is Map
//             ? Map<String, dynamic>.from(decoded)
//             : <String, dynamic>{};
//         final content =
//             contentJson[language] as String? ??
//             contentJson['en'] as String? ??
//             '';
//         return TodCard(
//           id: r['id'] as String,
//           content: content,
//           type: TodCardType.values.firstWhere(
//             (t) => t.name == r['card_type'],
//             orElse: () => TodCardType.truth,
//           ),
//           difficulty: TodDifficulty.values.firstWhere(
//             (d) => d.name == r['difficulty'],
//             orElse: () => TodDifficulty.mild,
//           ),
//         );
//       }).toList();
//     } catch (e) {
//       AppLogger.debug('TodRepository: SQLite cache miss for $packId — $e');
//     }

//     // Fallback: fetch directly from Supabase (pack not downloaded yet)
//     AppLogger.info('TodRepository: fetching cards from Supabase for $packId');
//     try {
//       final query = _supabase
//           .from('pack_cards')
//           .select('id, content, card_type, difficulty, sort_order')
//           .eq('pack_id', packId)
//           .order('sort_order');

//       final rows = await query as List;
//       // ignore: avoid_print
//       print(
//         '=== Supabase cards: ${rows.length}, first content: ${rows.isNotEmpty ? rows.first['content'] : 'none'}',
//       );
//       return rows.map((r) {
//         final rawContent = r['content'];
//         Map<String, dynamic> contentJson;
//         try {
//           if (rawContent is Map) {
//             contentJson = Map<String, dynamic>.from(rawContent);
//           } else if (rawContent is String) {
//             final decoded = jsonDecode(rawContent);
//             contentJson = decoded is Map
//                 ? Map<String, dynamic>.from(decoded)
//                 : {'en': rawContent};
//           } else {
//             contentJson = {};
//           }
//         } catch (_) {
//           contentJson = {};
//         }
//         final content =
//             contentJson[language] as String? ??
//             contentJson['en'] as String? ??
//             '';
//         return TodCard(
//           id: r['id'] as String,
//           content: content,
//           type: TodCardType.values.firstWhere(
//             (t) => t.name == (r['card_type'] as String? ?? ''),
//             orElse: () => TodCardType.truth,
//           ),
//           difficulty: TodDifficulty.values.firstWhere(
//             (d) => d.name == (r['difficulty'] as String? ?? ''),
//             orElse: () => TodDifficulty.mild,
//           ),
//         );
//       }).toList();
//     } catch (e) {
//       AppLogger.error(
//         'TodRepository: Supabase fallback failed for $packId',
//         error: e,
//       );
//       return [];
//     }
//   }

//   // ── Session persistence ────────────────────────────────────────────────────

//   Future<String> createSession({
//     required String roomId,
//     required String packId,
//     required GameConfig config,
//     required List<String> playerIds,
//     required String ownerId,
//   }) => guardedCall(
//     operationName: 'createTodSession',
//     operation: () async {
//       final row = await _supabase
//           .from('game_sessions')
//           .insert({
//             'room_id': roomId,
//             'pack_id': packId,
//             'game_type': GameType.truthOrDare.toDbString(),
//             'owner_id': ownerId,
//             'player_ids': playerIds,
//             'state_snapshot': {},
//             'max_rounds': config.maxRounds,
//             'turn_timer_secs': config.turnTimerSeconds,
//             'allow_skip': config.allowSkip,
//             'allow_spicy': config.allowSpicy,
//             'status': 'active',
//           })
//           .select('id')
//           .single();
//       return row['id'] as String;
//     },
//   );

//   /// Called every 10s by owner to persist the current snapshot.
//   /// Followers use this as a reconnect fallback.
//   Future<void> saveSnapshot({
//     required String sessionId,
//     required Map<String, dynamic> snapshot,
//   }) => guardedCall(
//     operationName: 'saveTodSnapshot',
//     operation: () async {
//       await _supabase
//           .from('game_sessions')
//           .update({
//             'state_snapshot': snapshot,
//             'snapshot_at': DateTime.now().toIso8601String(),
//           })
//           .eq('id', sessionId);
//     },
//   );

//   /// Load the latest snapshot from DB (8s timeout fallback for followers).
//   Future<Map<String, dynamic>?> loadSnapshot(String sessionId) => guardedCall(
//     operationName: 'loadTodSnapshot',
//     operation: () async {
//       final row = await _supabase
//           .from('game_sessions')
//           .select('state_snapshot, status')
//           .eq('id', sessionId)
//           .single();

//       if (row['status'] == 'completed' || row['status'] == 'aborted') {
//         return null;
//       }
//       return row['state_snapshot'] as Map<String, dynamic>?;
//     },
//   );

//   /// Mark session complete and record final scores.
//   Future<void> completeSession({
//     required String sessionId,
//     required Map<String, dynamic> finalSnapshot,
//     required String endReason,
//   }) => guardedCall(
//     operationName: 'completeTodSession',
//     operation: () async {
//       await _supabase
//           .from('game_sessions')
//           .update({
//             'status': 'completed',
//             'state_snapshot': finalSnapshot,
//             'ended_at': DateTime.now().toIso8601String(),
//           })
//           .eq('id', sessionId);
//     },
//   );
// }

import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/data/base_repository.dart';
import '../../../../core/storage/database/app_database.dart';
import '../../../../core/utils/app_logger.dart';
import '../domain/tod_models.dart';
import '../../engine/base_game_engine.dart';

const _uuid = Uuid();

/// Truth or Dare DB persistence layer.
///
/// Priority order for card loading:
///   1. Local SQLite cache (AppDatabase — offline-first)
///   2. Supabase remote (online fallback)
///
/// Session persistence:
///   - Owner creates a game_sessions row at start
///   - Owner saves snapshots every 10s for reconnect recovery
///   - Session marked completed when game ends
class TodRepository extends BaseRepository {
  TodRepository._();
  static final TodRepository _instance = TodRepository._();
  static TodRepository get instance => _instance;

  final _supabase = Supabase.instance.client;

  // ── Card loading ───────────────────────────────────────────────────────────

  /// Primary: load from remote Supabase (online).
  Future<List<TodCard>> loadCards({
    required String packId,
    required String language,
    bool allowSpicy = false,
  }) => guardedCall(
    operationName: 'loadTodCards',
    operation: () async {
      var q = _supabase
          .from('pack_cards')
          .select('id, content, card_type, difficulty')
          .eq('pack_id', packId)
          .eq('is_active', true);

      if (!allowSpicy) q = q.neq('difficulty', 'spicy');

      final rows = await q.order('sort_order');

      return rows.map((r) {
        final contentJson = r['content'] as Map<String, dynamic>? ?? {};
        final content =
            contentJson[language] as String? ??
            contentJson['en'] as String? ??
            '';
        return TodCard(
          id: r['id'] as String,
          content: content,
          type: TodCardType.values.firstWhere(
            (t) => t.name == (r['card_type'] as String? ?? 'truth'),
            orElse: () => TodCardType.truth,
          ),
          difficulty: TodDifficulty.values.firstWhere(
            (d) => d.name == (r['difficulty'] as String? ?? 'mild'),
            orElse: () => TodDifficulty.mild,
          ),
        );
      }).toList();
    },
  );

  /// Fallback: load from local SQLite (downloaded packs cache).
  Future<List<TodCard>> loadCardsFromCache({
    required String packId,
    required String language,
    bool allowSpicy = false,
  }) async {
    try {
      final db = AppDatabase.instance.db;

      var sql = '''
        SELECT id, content_json, card_type, difficulty
        FROM pack_cards_cache
        WHERE pack_id = ?
      ''';
      final params = <Object>[packId];
      if (!allowSpicy) {
        sql += ' AND difficulty != ?';
        params.add('spicy');
      }
      sql += ' ORDER BY sort_order';

      final rows = await db.rawQuery(sql, params);

      // Debug: log how many cards were found
      AppLogger.debug(
        'TodRepository: found ${rows.length} cards for pack $packId, language=$language',
      );
      if (rows.isNotEmpty) {
        // ignore: avoid_print
        print(
          '=== RAW first row content_json: ${rows.first["content_json"]?.runtimeType} = ${rows.first["content_json"]}',
        );
      }

      // Also check if pack exists at all
      if (rows.isEmpty) {
        final packCheck = await db.rawQuery(
          'SELECT COUNT(*) as cnt FROM pack_cards WHERE pack_id = ?',
          [packId],
        );
        final cardCount = packCheck.first['cnt'] as int? ?? 0;
        AppLogger.debug(
          'TodRepository: pack_cards direct count = $cardCount for $packId',
        );
        // Try without the view
        if (cardCount > 0) {
          final directRows = await db.rawQuery(
            'SELECT id, content_json, card_type, difficulty, sort_order FROM pack_cards WHERE pack_id = ? ORDER BY sort_order',
            [packId],
          );
          AppLogger.debug(
            'TodRepository: direct query returned ${directRows.length} rows',
          );
          return directRows.map((r) {
            final rawContent = r['content_json'];
            final contentStr = rawContent is String
                ? rawContent
                : jsonEncode(rawContent ?? '{}');
            Map<String, dynamic> contentJson;
            try {
              contentJson = jsonDecode(contentStr) as Map<String, dynamic>;
            } catch (_) {
              contentJson = {'en': contentStr};
            }
            final content =
                contentJson[language] as String? ??
                contentJson['en'] as String? ??
                '';
            return TodCard(
              id: r['id'] as String,
              content: content,
              type: TodCardType.values.firstWhere(
                (t) => t.name == r['card_type'],
                orElse: () => TodCardType.truth,
              ),
              difficulty: TodDifficulty.values.firstWhere(
                (d) => d.name == r['difficulty'],
                orElse: () => TodDifficulty.mild,
              ),
            );
          }).toList();
        }
      }

      return rows.map((r) {
        final rawJson = r['content_json'];
        final contentStr = rawJson is String
            ? rawJson
            : jsonEncode(rawJson ?? '{}');
        dynamic decoded;
        try {
          decoded = jsonDecode(contentStr);
        } catch (_) {
          decoded = <String, dynamic>{};
        }
        if (decoded is String) {
          try {
            decoded = jsonDecode(decoded);
          } catch (_) {
            decoded = <String, dynamic>{};
          }
        }
        final contentJson = decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : <String, dynamic>{};
        final content =
            contentJson[language] as String? ??
            contentJson['en'] as String? ??
            '';
        return TodCard(
          id: r['id'] as String,
          content: content,
          type: TodCardType.values.firstWhere(
            (t) => t.name == r['card_type'],
            orElse: () => TodCardType.truth,
          ),
          difficulty: TodDifficulty.values.firstWhere(
            (d) => d.name == r['difficulty'],
            orElse: () => TodDifficulty.mild,
          ),
        );
      }).toList();
    } catch (e) {
      AppLogger.debug('TodRepository: SQLite cache miss for $packId — $e');
    }

    // Fallback: fetch directly from Supabase (pack not downloaded yet)
    AppLogger.info('TodRepository: fetching cards from Supabase for $packId');
    try {
      final rows = await _supabase
          .from('pack_cards')
          .select('id, content, card_type, difficulty, sort_order')
          .eq('pack_id', packId)
          .order('sort_order');

      // ignore: avoid_print
      print(
        '=== Supabase fallback: ${rows.length} rows, first content: ${rows.isNotEmpty ? rows.first['content'] : 'none'}',
      );

      if (rows.isEmpty) return [];

      return rows.map((r) {
        final rawContent = r['content'];
        Map<String, dynamic> contentJson;
        try {
          if (rawContent is Map) {
            contentJson = Map<String, dynamic>.from(rawContent);
          } else if (rawContent is String) {
            final decoded = jsonDecode(rawContent);
            contentJson = decoded is Map
                ? Map<String, dynamic>.from(decoded)
                : {'en': rawContent};
          } else {
            contentJson = {};
          }
        } catch (_) {
          contentJson = {};
        }
        final content =
            contentJson[language] as String? ??
            contentJson['en'] as String? ??
            '';
        // ignore: avoid_print
        print('=== card content: $content');
        return TodCard(
          id: r['id'] as String,
          content: content,
          type: TodCardType.values.firstWhere(
            (t) => t.name == (r['card_type'] as String? ?? ''),
            orElse: () => TodCardType.truth,
          ),
          difficulty: TodDifficulty.values.firstWhere(
            (d) => d.name == (r['difficulty'] as String? ?? ''),
            orElse: () => TodDifficulty.mild,
          ),
        );
      }).toList();
    } catch (e) {
      AppLogger.error('TodRepository: Supabase fallback failed', error: e);
      // ignore: avoid_print
      print('=== Supabase fallback ERROR: $e');
      return [];
    }
  }

  // ── Session persistence ────────────────────────────────────────────────────

  Future<String> createSession({
    required String roomId,
    required String packId,
    required GameConfig config,
    required List<String> playerIds,
    required String ownerId,
  }) => guardedCall(
    operationName: 'createTodSession',
    operation: () async {
      final row = await _supabase
          .from('game_sessions')
          .insert({
            'room_id': roomId,
            'pack_id': packId,
            'game_type': GameType.truthOrDare.toDbString(),
            'owner_id': ownerId,
            'player_ids': playerIds,
            'state_snapshot': {},
            'max_rounds': config.maxRounds,
            'turn_timer_secs': config.turnTimerSeconds,
            'allow_skip': config.allowSkip,
            'allow_spicy': config.allowSpicy,
            'status': 'active',
          })
          .select('id')
          .single();
      return row['id'] as String;
    },
  );

  /// Called every 10s by owner to persist the current snapshot.
  /// Followers use this as a reconnect fallback.
  Future<void> saveSnapshot({
    required String sessionId,
    required Map<String, dynamic> snapshot,
  }) => guardedCall(
    operationName: 'saveTodSnapshot',
    operation: () async {
      await _supabase
          .from('game_sessions')
          .update({
            'state_snapshot': snapshot,
            'snapshot_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);
    },
  );

  /// Load the latest snapshot from DB (8s timeout fallback for followers).
  Future<Map<String, dynamic>?> loadSnapshot(String sessionId) => guardedCall(
    operationName: 'loadTodSnapshot',
    operation: () async {
      final row = await _supabase
          .from('game_sessions')
          .select('state_snapshot, status')
          .eq('id', sessionId)
          .single();

      if (row['status'] == 'completed' || row['status'] == 'aborted') {
        return null;
      }
      return row['state_snapshot'] as Map<String, dynamic>?;
    },
  );

  /// Mark session complete and record final scores.
  Future<void> completeSession({
    required String sessionId,
    required Map<String, dynamic> finalSnapshot,
    required String endReason,
  }) => guardedCall(
    operationName: 'completeTodSession',
    operation: () async {
      await _supabase
          .from('game_sessions')
          .update({
            'status': 'completed',
            'state_snapshot': finalSnapshot,
            'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);
    },
  );
}
