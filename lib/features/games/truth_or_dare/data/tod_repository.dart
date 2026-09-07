// // // // // // // // // // // import 'dart:convert';

// // // // // // // // // // // import 'package:sqflite/sqflite.dart';
// // // // // // // // // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // // // // // // // // import 'package:uuid/uuid.dart';

// // // // // // // // // // // import '../../../../core/data/base_repository.dart';
// // // // // // // // // // // import '../../../../core/storage/database/app_database.dart';
// // // // // // // // // // // import '../../../../core/utils/app_logger.dart';
// // // // // // // // // // // import '../domain/tod_models.dart';
// // // // // // // // // // // import '../../engine/base_game_engine.dart';

// // // // // // // // // // // const _uuid = Uuid();

// // // // // // // // // // // /// Truth or Dare DB persistence layer.
// // // // // // // // // // // ///
// // // // // // // // // // // /// Priority order for card loading:
// // // // // // // // // // // ///   1. Local SQLite cache (AppDatabase — offline-first)
// // // // // // // // // // // ///   2. Supabase remote (online fallback)
// // // // // // // // // // // ///
// // // // // // // // // // // /// Session persistence:
// // // // // // // // // // // ///   - Owner creates a game_sessions row at start
// // // // // // // // // // // ///   - Owner saves snapshots every 10s for reconnect recovery
// // // // // // // // // // // ///   - Session marked completed when game ends
// // // // // // // // // // // class TodRepository extends BaseRepository {
// // // // // // // // // // //   TodRepository._();
// // // // // // // // // // //   static final TodRepository _instance = TodRepository._();
// // // // // // // // // // //   static TodRepository get instance => _instance;

// // // // // // // // // // //   final _supabase = Supabase.instance.client;

// // // // // // // // // // //   // ── Card loading ───────────────────────────────────────────────────────────

// // // // // // // // // // //   /// Primary: load from remote Supabase (online).
// // // // // // // // // // //   Future<List<TodCard>> loadCards({
// // // // // // // // // // //     required String packId,
// // // // // // // // // // //     required String language,
// // // // // // // // // // //     bool allowSpicy = false,
// // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // //     operationName: 'loadTodCards',
// // // // // // // // // // //     operation: () async {
// // // // // // // // // // //       var q = _supabase
// // // // // // // // // // //           .from('pack_cards')
// // // // // // // // // // //           .select('id, content, card_type, difficulty')
// // // // // // // // // // //           .eq('pack_id', packId)
// // // // // // // // // // //           .eq('is_active', true);

// // // // // // // // // // //       if (!allowSpicy) q = q.neq('difficulty', 'spicy');

// // // // // // // // // // //       final rows = await q.order('sort_order');

// // // // // // // // // // //       return rows.map((r) {
// // // // // // // // // // //         final contentJson = r['content'] as Map<String, dynamic>? ?? {};
// // // // // // // // // // //         final content =
// // // // // // // // // // //             contentJson[language] as String? ??
// // // // // // // // // // //             contentJson['en'] as String? ??
// // // // // // // // // // //             '';
// // // // // // // // // // //         return TodCard(
// // // // // // // // // // //           id: r['id'] as String,
// // // // // // // // // // //           content: content,
// // // // // // // // // // //           type: TodCardType.values.firstWhere(
// // // // // // // // // // //             (t) => t.name == (r['card_type'] as String? ?? 'truth'),
// // // // // // // // // // //             orElse: () => TodCardType.truth,
// // // // // // // // // // //           ),
// // // // // // // // // // //           difficulty: TodDifficulty.values.firstWhere(
// // // // // // // // // // //             (d) => d.name == (r['difficulty'] as String? ?? 'mild'),
// // // // // // // // // // //             orElse: () => TodDifficulty.mild,
// // // // // // // // // // //           ),
// // // // // // // // // // //           allowSpicy: r['allowSpicy'],
// // // // // // // // // // //           language: r['language'],
// // // // // // // // // // //         );
// // // // // // // // // // //       }).toList();
// // // // // // // // // // //     },
// // // // // // // // // // //   );

// // // // // // // // // // //   /// Fallback: load from local SQLite (downloaded packs cache).
// // // // // // // // // // //   // Future<List<TodCard>> loadCardsFromCache({
// // // // // // // // // // //   //   required String packId,
// // // // // // // // // // //   //   required String language,
// // // // // // // // // // //   //   bool allowSpicy = false,
// // // // // // // // // // //   // }) async {
// // // // // // // // // // //   //   try {
// // // // // // // // // // //   //     final db = AppDatabase.instance.db;

// // // // // // // // // // //   //     var sql = '''
// // // // // // // // // // //   //       SELECT id, content_json, card_type, difficulty
// // // // // // // // // // //   //       FROM pack_cards_cache
// // // // // // // // // // //   //       WHERE pack_id = ?
// // // // // // // // // // //   //         AND is_active = 1
// // // // // // // // // // //   //     ''';
// // // // // // // // // // //   //     final params = <Object>[packId];
// // // // // // // // // // //   //     if (!allowSpicy) {
// // // // // // // // // // //   //       sql += ' AND difficulty != ?';
// // // // // // // // // // //   //       params.add('spicy');
// // // // // // // // // // //   //     }
// // // // // // // // // // //   //     sql += ' ORDER BY sort_order';

// // // // // // // // // // //   //     final rows = await db.rawQuery(sql, params);

// // // // // // // // // // //   //     return rows.map((r) {
// // // // // // // // // // //   //       final contentJson =
// // // // // // // // // // //   //           jsonDecode(r['content_json'] as String? ?? '{}')
// // // // // // // // // // //   //               as Map<String, dynamic>;
// // // // // // // // // // //   //       final content = contentJson[language] as String? ??
// // // // // // // // // // //   //           contentJson['en'] as String? ??
// // // // // // // // // // //   //           '';
// // // // // // // // // // //   //       return TodCard(
// // // // // // // // // // //   //         id:         r['id']        as String,
// // // // // // // // // // //   //         content:    content,
// // // // // // // // // // //   //         type:       TodCardType.values.firstWhere(
// // // // // // // // // // //   //           (t) => t.name == r['card_type'],
// // // // // // // // // // //   //           orElse: () => TodCardType.truth,
// // // // // // // // // // //   //         ),
// // // // // // // // // // //   //         difficulty: TodDifficulty.values.firstWhere(
// // // // // // // // // // //   //           (d) => d.name == r['difficulty'],
// // // // // // // // // // //   //           orElse: () => TodDifficulty.mild,
// // // // // // // // // // //   //         ),
// // // // // // // // // // //   //       );
// // // // // // // // // // //   //     }).toList();
// // // // // // // // // // //   //   } catch (e) {
// // // // // // // // // // //   //     AppLogger.debug('TodRepository: SQLite cache miss for $packId — $e');
// // // // // // // // // // //   //     return [];
// // // // // // // // // // //   //   }
// // // // // // // // // // //   // }

// // // // // // // // // // //   // Future<List<Map<String, dynamic>>> loadCardsFromCache(
// // // // // // // // // // //   //   String packId, {
// // // // // // // // // // //   //   String? language,
// // // // // // // // // // //   //   bool allowSpicy = false,
// // // // // // // // // // //   // }) async {
// // // // // // // // // // //   //   final db = AppDatabase.instance.db;
// // // // // // // // // // //   //   final List<Map<String, dynamic>> rows = await db.rawQuery(
// // // // // // // // // // //   //     '''
// // // // // // // // // // //   //   SELECT id, content_json, card_type, difficulty
// // // // // // // // // // //   //   FROM pack_cards_cache
// // // // // // // // // // //   //   WHERE pack_id = ? AND is_active = 1
// // // // // // // // // // //   //   ORDER BY sort_order
// // // // // // // // // // //   // ''',
// // // // // // // // // // //   //     [packId],
// // // // // // // // // // //   //   );

// // // // // // // // // // //   //   // Parse content_json from string to Map
// // // // // // // // // // //   //   final parsedRows = rows.map((row) {
// // // // // // // // // // //   //     final contentJsonString = row['content_json'] as String;
// // // // // // // // // // //   //     final Map<String, dynamic> contentMap = jsonDecode(contentJsonString);
// // // // // // // // // // //   //     return {
// // // // // // // // // // //   //       ...row,
// // // // // // // // // // //   //       'content_json': contentMap, // replace string with map
// // // // // // // // // // //   //     };
// // // // // // // // // // //   //   }).toList();

// // // // // // // // // // //   //   return parsedRows;
// // // // // // // // // // //   // }

// // // // // // // // // // //   // Future<List<TodCard>> loadCardsFromCache({
// // // // // // // // // // //   //   required String packId,
// // // // // // // // // // //   //   required String language,
// // // // // // // // // // //   //   bool allowSpicy = false,
// // // // // // // // // // //   // }) async {
// // // // // // // // // // //   //   try {
// // // // // // // // // // //   //     final db = AppDatabase.instance.db;

// // // // // // // // // // //   //     var sql = '''
// // // // // // // // // // //   //     SELECT id, content_json, card_type, difficulty
// // // // // // // // // // //   //     FROM pack_cards_cache
// // // // // // // // // // //   //     WHERE pack_id = ?
// // // // // // // // // // //   //       AND is_active = 1
// // // // // // // // // // //   //   ''';
// // // // // // // // // // //   //     final params = <Object>[packId];
// // // // // // // // // // //   //     if (!allowSpicy) {
// // // // // // // // // // //   //       sql += ' AND difficulty != ?';
// // // // // // // // // // //   //       params.add('spicy');
// // // // // // // // // // //   //     }
// // // // // // // // // // //   //     sql += ' ORDER BY sort_order';

// // // // // // // // // // //   //     final rows = await db.rawQuery(sql, params);

// // // // // // // // // // //   //     return rows.map((r) {
// // // // // // // // // // //   //       final contentJson =
// // // // // // // // // // //   //           jsonDecode(r['content_json'] as String? ?? '{}')
// // // // // // // // // // //   //               as Map<String, dynamic>;
// // // // // // // // // // //   //       final content =
// // // // // // // // // // //   //           contentJson[language] as String? ??
// // // // // // // // // // //   //           contentJson['en'] as String? ??
// // // // // // // // // // //   //           '';
// // // // // // // // // // //   //       return TodCard(
// // // // // // // // // // //   //         id: r['id'] as String,
// // // // // // // // // // //   //         content: content,
// // // // // // // // // // //   //         type: TodCardType.values.firstWhere(
// // // // // // // // // // //   //           (t) => t.name == (r['card_type'] as String? ?? 'truth'),
// // // // // // // // // // //   //           orElse: () => TodCardType.truth,
// // // // // // // // // // //   //         ),
// // // // // // // // // // //   //         difficulty: TodDifficulty.values.firstWhere(
// // // // // // // // // // //   //           (d) => d.name == (r['difficulty'] as String? ?? 'mild'),
// // // // // // // // // // //   //           orElse: () => TodDifficulty.mild,
// // // // // // // // // // //   //         ),
// // // // // // // // // // //   //         allowSpicy: r['allowSpicy'] as bool,
// // // // // // // // // // //   //         language: r['language'] as String,
// // // // // // // // // // //   //       );
// // // // // // // // // // //   //     }).toList();
// // // // // // // // // // //   //   } catch (e) {
// // // // // // // // // // //   //     AppLogger.debug('TodRepository: SQLite cache miss for $packId — $e');
// // // // // // // // // // //   //     return [];
// // // // // // // // // // //   //   }
// // // // // // // // // // //   // }

// // // // // // // // // // //   Future<List<TodCard>> loadCardsFromCache({
// // // // // // // // // // //   required String packId,
// // // // // // // // // // //   required String language,
// // // // // // // // // // //   bool allowSpicy = false,
// // // // // // // // // // // }) async {
// // // // // // // // // // //   try {
// // // // // // // // // // //     final db = AppDatabase.instance.db;

// // // // // // // // // // //     var sql = '''
// // // // // // // // // // //       SELECT id, content_json, card_type, difficulty
// // // // // // // // // // //       FROM pack_cards_cache
// // // // // // // // // // //       WHERE pack_id = ?
// // // // // // // // // // //         AND is_active = 1
// // // // // // // // // // //     ''';
// // // // // // // // // // //     final params = <Object>[packId];
// // // // // // // // // // //     if (!allowSpicy) {
// // // // // // // // // // //       sql += ' AND difficulty != ?';
// // // // // // // // // // //       params.add('spicy');
// // // // // // // // // // //     }
// // // // // // // // // // //     sql += ' ORDER BY sort_order';

// // // // // // // // // // //     final rows = await db.rawQuery(sql, params);

// // // // // // // // // // //     return rows.map((row) {
// // // // // // // // // // //       // Parse content_json from string (or handle if already map)
// // // // // // // // // // //       final contentJsonRaw = row['content_json'];
// // // // // // // // // // //       Map<String, dynamic> contentMap;
// // // // // // // // // // //       if (contentJsonRaw is String) {
// // // // // // // // // // //         contentMap = jsonDecode(contentJsonRaw) as Map<String, dynamic>;
// // // // // // // // // // //       } else if (contentJsonRaw is Map) {
// // // // // // // // // // //         contentMap = contentJsonRaw as Map<String, dynamic>;
// // // // // // // // // // //       } else {
// // // // // // // // // // //         contentMap = {};
// // // // // // // // // // //       }
// // // // // // // // // // //       final content = contentMap[language] as String? ??
// // // // // // // // // // //           contentMap['en'] as String? ??
// // // // // // // // // // //           '';
// // // // // // // // // // //       return TodCard(
// // // // // // // // // // //         id: row['id'] as String,
// // // // // // // // // // //         content: content,
// // // // // // // // // // //         type: TodCardType.values.firstWhere(
// // // // // // // // // // //           (t) => t.name == (row['card_type'] as String? ?? 'truth'),
// // // // // // // // // // //           orElse: () => TodCardType.truth,
// // // // // // // // // // //         ),
// // // // // // // // // // //         difficulty: TodDifficulty.values.firstWhere(
// // // // // // // // // // //           (d) => d.name == (row['difficulty'] as String? ?? 'mild'),
// // // // // // // // // // //           orElse: () => TodDifficulty.mild,
// // // // // // // // // // //         ),
// // // // // // // // // // //       );
// // // // // // // // // // //     }).toList();
// // // // // // // // // // //   } catch (e) {
// // // // // // // // // // //     AppLogger.debug('TodRepository: SQLite cache miss for $packId — $e');
// // // // // // // // // // //     return [];
// // // // // // // // // // //   }
// // // // // // // // // // // }

// // // // // // // // // // //   // ── Session persistence ────────────────────────────────────────────────────

// // // // // // // // // // //   Future<String> createSession({
// // // // // // // // // // //     required String roomId,
// // // // // // // // // // //     required String packId,
// // // // // // // // // // //     required GameConfig config,
// // // // // // // // // // //     required List<String> playerIds,
// // // // // // // // // // //     required String ownerId,
// // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // //     operationName: 'createTodSession',
// // // // // // // // // // //     operation: () async {
// // // // // // // // // // //       final row = await _supabase
// // // // // // // // // // //           .from('game_sessions')
// // // // // // // // // // //           .insert({
// // // // // // // // // // //             'room_id': roomId,
// // // // // // // // // // //             'pack_id': packId,
// // // // // // // // // // //             'game_type': GameType.truthOrDare.toDbString(),
// // // // // // // // // // //             'owner_id': ownerId,
// // // // // // // // // // //             'player_ids': playerIds,
// // // // // // // // // // //             'state_snapshot': {},
// // // // // // // // // // //             'max_rounds': config.maxRounds,
// // // // // // // // // // //             'turn_timer_secs': config.turnTimerSeconds,
// // // // // // // // // // //             'allow_skip': config.allowSkip,
// // // // // // // // // // //             'allow_spicy': config.allowSpicy,
// // // // // // // // // // //             'status': 'active',
// // // // // // // // // // //           })
// // // // // // // // // // //           .select('id')
// // // // // // // // // // //           .single();
// // // // // // // // // // //       return row['id'] as String;
// // // // // // // // // // //     },
// // // // // // // // // // //   );

// // // // // // // // // // //   /// Called every 10s by owner to persist the current snapshot.
// // // // // // // // // // //   /// Followers use this as a reconnect fallback.
// // // // // // // // // // //   Future<void> saveSnapshot({
// // // // // // // // // // //     required String sessionId,
// // // // // // // // // // //     required Map<String, dynamic> snapshot,
// // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // //     operationName: 'saveTodSnapshot',
// // // // // // // // // // //     operation: () async {
// // // // // // // // // // //       await _supabase
// // // // // // // // // // //           .from('game_sessions')
// // // // // // // // // // //           .update({
// // // // // // // // // // //             'state_snapshot': snapshot,
// // // // // // // // // // //             'snapshot_at': DateTime.now().toIso8601String(),
// // // // // // // // // // //           })
// // // // // // // // // // //           .eq('id', sessionId);
// // // // // // // // // // //     },
// // // // // // // // // // //   );

// // // // // // // // // // //   /// Load the latest snapshot from DB (8s timeout fallback for followers).
// // // // // // // // // // //   Future<Map<String, dynamic>?> loadSnapshot(String sessionId) => guardedCall(
// // // // // // // // // // //     operationName: 'loadTodSnapshot',
// // // // // // // // // // //     operation: () async {
// // // // // // // // // // //       final row = await _supabase
// // // // // // // // // // //           .from('game_sessions')
// // // // // // // // // // //           .select('state_snapshot, status')
// // // // // // // // // // //           .eq('id', sessionId)
// // // // // // // // // // //           .single();

// // // // // // // // // // //       if (row['status'] == 'completed' || row['status'] == 'aborted') {
// // // // // // // // // // //         return null;
// // // // // // // // // // //       }
// // // // // // // // // // //       return row['state_snapshot'] as Map<String, dynamic>?;
// // // // // // // // // // //     },
// // // // // // // // // // //   );

// // // // // // // // // // //   /// Mark session complete and record final scores.
// // // // // // // // // // //   Future<void> completeSession({
// // // // // // // // // // //     required String sessionId,
// // // // // // // // // // //     required Map<String, dynamic> finalSnapshot,
// // // // // // // // // // //     required String endReason,
// // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // //     operationName: 'completeTodSession',
// // // // // // // // // // //     operation: () async {
// // // // // // // // // // //       await _supabase
// // // // // // // // // // //           .from('game_sessions')
// // // // // // // // // // //           .update({
// // // // // // // // // // //             'status': 'completed',
// // // // // // // // // // //             'state_snapshot': finalSnapshot,
// // // // // // // // // // //             'ended_at': DateTime.now().toIso8601String(),
// // // // // // // // // // //           })
// // // // // // // // // // //           .eq('id', sessionId);
// // // // // // // // // // //     },
// // // // // // // // // // //   );
// // // // // // // // // // // }

// // // // // // // // // // import 'dart:convert';

// // // // // // // // // // import 'package:sqflite/sqflite.dart';
// // // // // // // // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // // // // // // // import 'package:uuid/uuid.dart';

// // // // // // // // // // import '../../../../core/data/base_repository.dart';
// // // // // // // // // // import '../../../../core/storage/database/app_database.dart';
// // // // // // // // // // import '../../../../core/utils/app_logger.dart';
// // // // // // // // // // import '../domain/tod_models.dart';
// // // // // // // // // // import '../../engine/base_game_engine.dart';

// // // // // // // // // // const _uuid = Uuid();

// // // // // // // // // // /// Truth or Dare DB persistence layer.
// // // // // // // // // // ///
// // // // // // // // // // /// Priority order for card loading:
// // // // // // // // // // ///   1. Local SQLite cache (AppDatabase — offline-first)
// // // // // // // // // // ///   2. Supabase remote (online fallback)
// // // // // // // // // // ///
// // // // // // // // // // /// Session persistence:
// // // // // // // // // // ///   - Owner creates a game_sessions row at start
// // // // // // // // // // ///   - Owner saves snapshots every 10s for reconnect recovery
// // // // // // // // // // ///   - Session marked completed when game ends
// // // // // // // // // // class TodRepository extends BaseRepository {
// // // // // // // // // //   TodRepository._();
// // // // // // // // // //   static final TodRepository _instance = TodRepository._();
// // // // // // // // // //   static TodRepository get instance => _instance;

// // // // // // // // // //   final _supabase = Supabase.instance.client;

// // // // // // // // // //   // ── Card loading ───────────────────────────────────────────────────────────

// // // // // // // // // //   /// Primary: load from remote Supabase (online).
// // // // // // // // // //   Future<List<TodCard>> loadCards({
// // // // // // // // // //     required String packId,
// // // // // // // // // //     required String language,
// // // // // // // // // //     bool allowSpicy = false,
// // // // // // // // // //   }) => guardedCall(
// // // // // // // // // //     operationName: 'loadTodCards',
// // // // // // // // // //     operation: () async {
// // // // // // // // // //       var q = _supabase
// // // // // // // // // //           .from('pack_cards')
// // // // // // // // // //           .select('id, content, card_type, difficulty')
// // // // // // // // // //           .eq('pack_id', packId)
// // // // // // // // // //           .eq('is_active', true);

// // // // // // // // // //       if (!allowSpicy) q = q.neq('difficulty', 'spicy');

// // // // // // // // // //       final rows = await q.order('sort_order');

// // // // // // // // // //       return rows.map((r) {
// // // // // // // // // //         final contentJson = r['content'] as Map<String, dynamic>? ?? {};
// // // // // // // // // //         final content =
// // // // // // // // // //             contentJson[language] as String? ??
// // // // // // // // // //             contentJson['en'] as String? ??
// // // // // // // // // //             '';
// // // // // // // // // //         return TodCard(
// // // // // // // // // //           id: r['id'] as String,
// // // // // // // // // //           content: content,
// // // // // // // // // //           type: TodCardType.values.firstWhere(
// // // // // // // // // //             (t) => t.name == (r['card_type'] as String? ?? 'truth'),
// // // // // // // // // //             orElse: () => TodCardType.truth,
// // // // // // // // // //           ),
// // // // // // // // // //           difficulty: TodDifficulty.values.firstWhere(
// // // // // // // // // //             (d) => d.name == (r['difficulty'] as String? ?? 'mild'),
// // // // // // // // // //             orElse: () => TodDifficulty.mild,
// // // // // // // // // //           ),
// // // // // // // // // //         );
// // // // // // // // // //       }).toList();
// // // // // // // // // //     },
// // // // // // // // // //   );

// // // // // // // // // //   /// Fallback: load from local SQLite (downloaded packs cache).
// // // // // // // // // //   Future<List<TodCard>> loadCardsFromCache({
// // // // // // // // // //     required String packId,
// // // // // // // // // //     required String language,
// // // // // // // // // //     bool allowSpicy = false,
// // // // // // // // // //   }) async {
// // // // // // // // // //     try {
// // // // // // // // // //       final db = AppDatabase.instance.db;

// // // // // // // // // //       var sql = '''
// // // // // // // // // //         SELECT id, content_json, card_type, difficulty
// // // // // // // // // //         FROM pack_cards_cache
// // // // // // // // // //         WHERE pack_id = ?
// // // // // // // // // //       ''';
// // // // // // // // // //       final params = <Object>[packId];
// // // // // // // // // //       if (!allowSpicy) {
// // // // // // // // // //         sql += ' AND difficulty != ?';
// // // // // // // // // //         params.add('spicy');
// // // // // // // // // //       }
// // // // // // // // // //       sql += ' ORDER BY sort_order';

// // // // // // // // // //       final rows = await db.rawQuery(sql, params);

// // // // // // // // // //       return rows.map((r) {
// // // // // // // // // //         final contentJson =
// // // // // // // // // //             jsonDecode(r['content_json'] as String? ?? '{}')
// // // // // // // // // //                 as Map<String, dynamic>;
// // // // // // // // // //         final content =
// // // // // // // // // //             contentJson[language] as String? ??
// // // // // // // // // //             contentJson['en'] as String? ??
// // // // // // // // // //             '';
// // // // // // // // // //         return TodCard(
// // // // // // // // // //           id: r['id'] as String,
// // // // // // // // // //           content: content,
// // // // // // // // // //           type: TodCardType.values.firstWhere(
// // // // // // // // // //             (t) => t.name == r['card_type'],
// // // // // // // // // //             orElse: () => TodCardType.truth,
// // // // // // // // // //           ),
// // // // // // // // // //           difficulty: TodDifficulty.values.firstWhere(
// // // // // // // // // //             (d) => d.name == r['difficulty'],
// // // // // // // // // //             orElse: () => TodDifficulty.mild,
// // // // // // // // // //           ),
// // // // // // // // // //         );
// // // // // // // // // //       }).toList();
// // // // // // // // // //     } catch (e) {
// // // // // // // // // //       AppLogger.debug('TodRepository: SQLite cache miss for $packId — $e');
// // // // // // // // // //       return [];
// // // // // // // // // //     }
// // // // // // // // // //   }

// // // // // // // // // //   // ── Session persistence ────────────────────────────────────────────────────

// // // // // // // // // //   Future<String> createSession({
// // // // // // // // // //     required String roomId,
// // // // // // // // // //     required String packId,
// // // // // // // // // //     required GameConfig config,
// // // // // // // // // //     required List<String> playerIds,
// // // // // // // // // //     required String ownerId,
// // // // // // // // // //   }) => guardedCall(
// // // // // // // // // //     operationName: 'createTodSession',
// // // // // // // // // //     operation: () async {
// // // // // // // // // //       final row = await _supabase
// // // // // // // // // //           .from('game_sessions')
// // // // // // // // // //           .insert({
// // // // // // // // // //             'room_id': roomId,
// // // // // // // // // //             'pack_id': packId,
// // // // // // // // // //             'game_type': GameType.truthOrDare.toDbString(),
// // // // // // // // // //             'owner_id': ownerId,
// // // // // // // // // //             'player_ids': playerIds,
// // // // // // // // // //             'state_snapshot': {},
// // // // // // // // // //             'max_rounds': config.maxRounds,
// // // // // // // // // //             'turn_timer_secs': config.turnTimerSeconds,
// // // // // // // // // //             'allow_skip': config.allowSkip,
// // // // // // // // // //             'allow_spicy': config.allowSpicy,
// // // // // // // // // //             'status': 'active',
// // // // // // // // // //           })
// // // // // // // // // //           .select('id')
// // // // // // // // // //           .single();
// // // // // // // // // //       return row['id'] as String;
// // // // // // // // // //     },
// // // // // // // // // //   );

// // // // // // // // // //   /// Called every 10s by owner to persist the current snapshot.
// // // // // // // // // //   /// Followers use this as a reconnect fallback.
// // // // // // // // // //   Future<void> saveSnapshot({
// // // // // // // // // //     required String sessionId,
// // // // // // // // // //     required Map<String, dynamic> snapshot,
// // // // // // // // // //   }) => guardedCall(
// // // // // // // // // //     operationName: 'saveTodSnapshot',
// // // // // // // // // //     operation: () async {
// // // // // // // // // //       await _supabase
// // // // // // // // // //           .from('game_sessions')
// // // // // // // // // //           .update({
// // // // // // // // // //             'state_snapshot': snapshot,
// // // // // // // // // //             'snapshot_at': DateTime.now().toIso8601String(),
// // // // // // // // // //           })
// // // // // // // // // //           .eq('id', sessionId);
// // // // // // // // // //     },
// // // // // // // // // //   );

// // // // // // // // // //   /// Load the latest snapshot from DB (8s timeout fallback for followers).
// // // // // // // // // //   Future<Map<String, dynamic>?> loadSnapshot(String sessionId) => guardedCall(
// // // // // // // // // //     operationName: 'loadTodSnapshot',
// // // // // // // // // //     operation: () async {
// // // // // // // // // //       final row = await _supabase
// // // // // // // // // //           .from('game_sessions')
// // // // // // // // // //           .select('state_snapshot, status')
// // // // // // // // // //           .eq('id', sessionId)
// // // // // // // // // //           .single();

// // // // // // // // // //       if (row['status'] == 'completed' || row['status'] == 'aborted') {
// // // // // // // // // //         return null;
// // // // // // // // // //       }
// // // // // // // // // //       return row['state_snapshot'] as Map<String, dynamic>?;
// // // // // // // // // //     },
// // // // // // // // // //   );

// // // // // // // // // //   /// Mark session complete and record final scores.
// // // // // // // // // //   Future<void> completeSession({
// // // // // // // // // //     required String sessionId,
// // // // // // // // // //     required Map<String, dynamic> finalSnapshot,
// // // // // // // // // //     required String endReason,
// // // // // // // // // //   }) => guardedCall(
// // // // // // // // // //     operationName: 'completeTodSession',
// // // // // // // // // //     operation: () async {
// // // // // // // // // //       await _supabase
// // // // // // // // // //           .from('game_sessions')
// // // // // // // // // //           .update({
// // // // // // // // // //             'status': 'completed',
// // // // // // // // // //             'state_snapshot': finalSnapshot,
// // // // // // // // // //             'ended_at': DateTime.now().toIso8601String(),
// // // // // // // // // //           })
// // // // // // // // // //           .eq('id', sessionId);
// // // // // // // // // //     },
// // // // // // // // // //   );
// // // // // // // // // // }

// // // // // // // // // import 'dart:convert';

// // // // // // // // // import 'package:sqflite/sqflite.dart';
// // // // // // // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // // // // // // import 'package:uuid/uuid.dart';

// // // // // // // // // import '../../../../core/data/base_repository.dart';
// // // // // // // // // import '../../../../core/storage/database/app_database.dart';
// // // // // // // // // import '../../../../core/utils/app_logger.dart';
// // // // // // // // // import '../domain/tod_models.dart';
// // // // // // // // // import '../../engine/base_game_engine.dart';

// // // // // // // // // const _uuid = Uuid();

// // // // // // // // // /// Truth or Dare DB persistence layer.
// // // // // // // // // ///
// // // // // // // // // /// Priority order for card loading:
// // // // // // // // // ///   1. Local SQLite cache (AppDatabase — offline-first)
// // // // // // // // // ///   2. Supabase remote (online fallback)
// // // // // // // // // ///
// // // // // // // // // /// Session persistence:
// // // // // // // // // ///   - Owner creates a game_sessions row at start
// // // // // // // // // ///   - Owner saves snapshots every 10s for reconnect recovery
// // // // // // // // // ///   - Session marked completed when game ends
// // // // // // // // // class TodRepository extends BaseRepository {
// // // // // // // // //   TodRepository._();
// // // // // // // // //   static final TodRepository _instance = TodRepository._();
// // // // // // // // //   static TodRepository get instance => _instance;

// // // // // // // // //   final _supabase = Supabase.instance.client;

// // // // // // // // //   // ── Card loading ───────────────────────────────────────────────────────────

// // // // // // // // //   /// Primary: load from remote Supabase (online).
// // // // // // // // //   Future<List<TodCard>> loadCards({
// // // // // // // // //     required String packId,
// // // // // // // // //     required String language,
// // // // // // // // //     bool allowSpicy = false,
// // // // // // // // //   }) => guardedCall(
// // // // // // // // //     operationName: 'loadTodCards',
// // // // // // // // //     operation: () async {
// // // // // // // // //       var q = _supabase
// // // // // // // // //           .from('pack_cards')
// // // // // // // // //           .select('id, content, card_type, difficulty')
// // // // // // // // //           .eq('pack_id', packId)
// // // // // // // // //           .eq('is_active', true);

// // // // // // // // //       if (!allowSpicy) q = q.neq('difficulty', 'spicy');

// // // // // // // // //       final rows = await q.order('sort_order');

// // // // // // // // //       return rows.map((r) {
// // // // // // // // //         final contentJson = r['content'] as Map<String, dynamic>? ?? {};
// // // // // // // // //         final content =
// // // // // // // // //             contentJson[language] as String? ??
// // // // // // // // //             contentJson['en'] as String? ??
// // // // // // // // //             '';
// // // // // // // // //         return TodCard(
// // // // // // // // //           id: r['id'] as String,
// // // // // // // // //           content: content,
// // // // // // // // //           type: TodCardType.values.firstWhere(
// // // // // // // // //             (t) => t.name == (r['card_type'] as String? ?? 'truth'),
// // // // // // // // //             orElse: () => TodCardType.truth,
// // // // // // // // //           ),
// // // // // // // // //           difficulty: TodDifficulty.values.firstWhere(
// // // // // // // // //             (d) => d.name == (r['difficulty'] as String? ?? 'mild'),
// // // // // // // // //             orElse: () => TodDifficulty.mild,
// // // // // // // // //           ),
// // // // // // // // //         );
// // // // // // // // //       }).toList();
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   /// Fallback: load from local SQLite (downloaded packs cache).
// // // // // // // // //   Future<List<TodCard>> loadCardsFromCache({
// // // // // // // // //     required String packId,
// // // // // // // // //     required String language,
// // // // // // // // //     bool allowSpicy = false,
// // // // // // // // //   }) async {
// // // // // // // // //     try {
// // // // // // // // //       final db = AppDatabase.instance.db;

// // // // // // // // //       var sql = '''
// // // // // // // // //         SELECT id, content_json, card_type, difficulty
// // // // // // // // //         FROM pack_cards_cache
// // // // // // // // //         WHERE pack_id = ?
// // // // // // // // //       ''';
// // // // // // // // //       final params = <Object>[packId];
// // // // // // // // //       if (!allowSpicy) {
// // // // // // // // //         sql += ' AND difficulty != ?';
// // // // // // // // //         params.add('spicy');
// // // // // // // // //       }
// // // // // // // // //       sql += ' ORDER BY sort_order';

// // // // // // // // //       final rows = await db.rawQuery(sql, params);

// // // // // // // // //       // Debug: log how many cards were found
// // // // // // // // //       AppLogger.debug(
// // // // // // // // //         'TodRepository: found ${rows.length} cards for pack $packId',
// // // // // // // // //       );

// // // // // // // // //       // Also check if pack exists at all
// // // // // // // // //       if (rows.isEmpty) {
// // // // // // // // //         final packCheck = await db.rawQuery(
// // // // // // // // //           'SELECT COUNT(*) as cnt FROM pack_cards WHERE pack_id = ?',
// // // // // // // // //           [packId],
// // // // // // // // //         );
// // // // // // // // //         final cardCount = packCheck.first['cnt'] as int? ?? 0;
// // // // // // // // //         AppLogger.debug(
// // // // // // // // //           'TodRepository: pack_cards direct count = $cardCount for $packId',
// // // // // // // // //         );
// // // // // // // // //         // Try without the view
// // // // // // // // //         if (cardCount > 0) {
// // // // // // // // //           final directRows = await db.rawQuery(
// // // // // // // // //             'SELECT id, content_json, card_type, difficulty, sort_order FROM pack_cards WHERE pack_id = ? ORDER BY sort_order',
// // // // // // // // //             [packId],
// // // // // // // // //           );
// // // // // // // // //           AppLogger.debug(
// // // // // // // // //             'TodRepository: direct query returned ${directRows.length} rows',
// // // // // // // // //           );
// // // // // // // // //           return directRows.map((r) {
// // // // // // // // //             final rawContent = r['content_json'];
// // // // // // // // //             final contentStr = rawContent is String
// // // // // // // // //                 ? rawContent
// // // // // // // // //                 : jsonEncode(rawContent ?? '{}');
// // // // // // // // //             Map<String, dynamic> contentJson;
// // // // // // // // //             try {
// // // // // // // // //               contentJson = jsonDecode(contentStr) as Map<String, dynamic>;
// // // // // // // // //             } catch (_) {
// // // // // // // // //               contentJson = {'en': contentStr};
// // // // // // // // //             }
// // // // // // // // //             final content =
// // // // // // // // //                 contentJson[language] as String? ??
// // // // // // // // //                 contentJson['en'] as String? ??
// // // // // // // // //                 '';
// // // // // // // // //             return TodCard(
// // // // // // // // //               id: r['id'] as String,
// // // // // // // // //               content: content,
// // // // // // // // //               type: TodCardType.values.firstWhere(
// // // // // // // // //                 (t) => t.name == r['card_type'],
// // // // // // // // //                 orElse: () => TodCardType.truth,
// // // // // // // // //               ),
// // // // // // // // //               difficulty: TodDifficulty.values.firstWhere(
// // // // // // // // //                 (d) => d.name == r['difficulty'],
// // // // // // // // //                 orElse: () => TodDifficulty.mild,
// // // // // // // // //               ),
// // // // // // // // //             );
// // // // // // // // //           }).toList();
// // // // // // // // //         }
// // // // // // // // //       }

// // // // // // // // //       return rows.map((r) {
// // // // // // // // //         final contentJson =
// // // // // // // // //             jsonDecode(r['content_json'] as String? ?? '{}')
// // // // // // // // //                 as Map<String, dynamic>;
// // // // // // // // //         final content =
// // // // // // // // //             contentJson[language] as String? ??
// // // // // // // // //             contentJson['en'] as String? ??
// // // // // // // // //             '';
// // // // // // // // //         return TodCard(
// // // // // // // // //           id: r['id'] as String,
// // // // // // // // //           content: content,
// // // // // // // // //           type: TodCardType.values.firstWhere(
// // // // // // // // //             (t) => t.name == r['card_type'],
// // // // // // // // //             orElse: () => TodCardType.truth,
// // // // // // // // //           ),
// // // // // // // // //           difficulty: TodDifficulty.values.firstWhere(
// // // // // // // // //             (d) => d.name == r['difficulty'],
// // // // // // // // //             orElse: () => TodDifficulty.mild,
// // // // // // // // //           ),
// // // // // // // // //         );
// // // // // // // // //       }).toList();
// // // // // // // // //     } catch (e) {
// // // // // // // // //       AppLogger.debug('TodRepository: SQLite cache miss for $packId — $e');
// // // // // // // // //       return [];
// // // // // // // // //     }
// // // // // // // // //   }

// // // // // // // // //   // ── Session persistence ────────────────────────────────────────────────────

// // // // // // // // //   Future<String> createSession({
// // // // // // // // //     required String roomId,
// // // // // // // // //     required String packId,
// // // // // // // // //     required GameConfig config,
// // // // // // // // //     required List<String> playerIds,
// // // // // // // // //     required String ownerId,
// // // // // // // // //   }) => guardedCall(
// // // // // // // // //     operationName: 'createTodSession',
// // // // // // // // //     operation: () async {
// // // // // // // // //       final row = await _supabase
// // // // // // // // //           .from('game_sessions')
// // // // // // // // //           .insert({
// // // // // // // // //             'room_id': roomId,
// // // // // // // // //             'pack_id': packId,
// // // // // // // // //             'game_type': GameType.truthOrDare.toDbString(),
// // // // // // // // //             'owner_id': ownerId,
// // // // // // // // //             'player_ids': playerIds,
// // // // // // // // //             'state_snapshot': {},
// // // // // // // // //             'max_rounds': config.maxRounds,
// // // // // // // // //             'turn_timer_secs': config.turnTimerSeconds,
// // // // // // // // //             'allow_skip': config.allowSkip,
// // // // // // // // //             'allow_spicy': config.allowSpicy,
// // // // // // // // //             'status': 'active',
// // // // // // // // //           })
// // // // // // // // //           .select('id')
// // // // // // // // //           .single();
// // // // // // // // //       return row['id'] as String;
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   /// Called every 10s by owner to persist the current snapshot.
// // // // // // // // //   /// Followers use this as a reconnect fallback.
// // // // // // // // //   Future<void> saveSnapshot({
// // // // // // // // //     required String sessionId,
// // // // // // // // //     required Map<String, dynamic> snapshot,
// // // // // // // // //   }) => guardedCall(
// // // // // // // // //     operationName: 'saveTodSnapshot',
// // // // // // // // //     operation: () async {
// // // // // // // // //       await _supabase
// // // // // // // // //           .from('game_sessions')
// // // // // // // // //           .update({
// // // // // // // // //             'state_snapshot': snapshot,
// // // // // // // // //             'snapshot_at': DateTime.now().toIso8601String(),
// // // // // // // // //           })
// // // // // // // // //           .eq('id', sessionId);
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   /// Load the latest snapshot from DB (8s timeout fallback for followers).
// // // // // // // // //   Future<Map<String, dynamic>?> loadSnapshot(String sessionId) => guardedCall(
// // // // // // // // //     operationName: 'loadTodSnapshot',
// // // // // // // // //     operation: () async {
// // // // // // // // //       final row = await _supabase
// // // // // // // // //           .from('game_sessions')
// // // // // // // // //           .select('state_snapshot, status')
// // // // // // // // //           .eq('id', sessionId)
// // // // // // // // //           .single();

// // // // // // // // //       if (row['status'] == 'completed' || row['status'] == 'aborted') {
// // // // // // // // //         return null;
// // // // // // // // //       }
// // // // // // // // //       return row['state_snapshot'] as Map<String, dynamic>?;
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   /// Mark session complete and record final scores.
// // // // // // // // //   Future<void> completeSession({
// // // // // // // // //     required String sessionId,
// // // // // // // // //     required Map<String, dynamic> finalSnapshot,
// // // // // // // // //     required String endReason,
// // // // // // // // //   }) => guardedCall(
// // // // // // // // //     operationName: 'completeTodSession',
// // // // // // // // //     operation: () async {
// // // // // // // // //       await _supabase
// // // // // // // // //           .from('game_sessions')
// // // // // // // // //           .update({
// // // // // // // // //             'status': 'completed',
// // // // // // // // //             'state_snapshot': finalSnapshot,
// // // // // // // // //             'ended_at': DateTime.now().toIso8601String(),
// // // // // // // // //           })
// // // // // // // // //           .eq('id', sessionId);
// // // // // // // // //     },
// // // // // // // // //   );
// // // // // // // // // }

// // // // // // // // import 'dart:convert';

// // // // // // // // import 'package:sqflite/sqflite.dart';
// // // // // // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // // // // // import 'package:uuid/uuid.dart';

// // // // // // // // import '../../../../core/data/base_repository.dart';
// // // // // // // // import '../../../../core/storage/database/app_database.dart';
// // // // // // // // import '../../../../core/utils/app_logger.dart';
// // // // // // // // import '../domain/tod_models.dart';
// // // // // // // // import '../../engine/base_game_engine.dart';

// // // // // // // // const _uuid = Uuid();

// // // // // // // // /// Truth or Dare DB persistence layer.
// // // // // // // // ///
// // // // // // // // /// Priority order for card loading:
// // // // // // // // ///   1. Local SQLite cache (AppDatabase — offline-first)
// // // // // // // // ///   2. Supabase remote (online fallback)
// // // // // // // // ///
// // // // // // // // /// Session persistence:
// // // // // // // // ///   - Owner creates a game_sessions row at start
// // // // // // // // ///   - Owner saves snapshots every 10s for reconnect recovery
// // // // // // // // ///   - Session marked completed when game ends
// // // // // // // // class TodRepository extends BaseRepository {
// // // // // // // //   TodRepository._();
// // // // // // // //   static final TodRepository _instance = TodRepository._();
// // // // // // // //   static TodRepository get instance => _instance;

// // // // // // // //   final _supabase = Supabase.instance.client;

// // // // // // // //   // ── Card loading ───────────────────────────────────────────────────────────

// // // // // // // //   /// Primary: load from remote Supabase (online).
// // // // // // // //   Future<List<TodCard>> loadCards({
// // // // // // // //     required String packId,
// // // // // // // //     required String language,
// // // // // // // //     bool allowSpicy = false,
// // // // // // // //   }) => guardedCall(
// // // // // // // //     operationName: 'loadTodCards',
// // // // // // // //     operation: () async {
// // // // // // // //       var q = _supabase
// // // // // // // //           .from('pack_cards')
// // // // // // // //           .select('id, content, card_type, difficulty')
// // // // // // // //           .eq('pack_id', packId)
// // // // // // // //           .eq('is_active', true);

// // // // // // // //       if (!allowSpicy) q = q.neq('difficulty', 'spicy');

// // // // // // // //       final rows = await q.order('sort_order');

// // // // // // // //       return rows.map((r) {
// // // // // // // //         final contentJson = r['content'] as Map<String, dynamic>? ?? {};
// // // // // // // //         final content =
// // // // // // // //             contentJson[language] as String? ??
// // // // // // // //             contentJson['en'] as String? ??
// // // // // // // //             '';
// // // // // // // //         return TodCard(
// // // // // // // //           id: r['id'] as String,
// // // // // // // //           content: content,
// // // // // // // //           type: TodCardType.values.firstWhere(
// // // // // // // //             (t) => t.name == (r['card_type'] as String? ?? 'truth'),
// // // // // // // //             orElse: () => TodCardType.truth,
// // // // // // // //           ),
// // // // // // // //           difficulty: TodDifficulty.values.firstWhere(
// // // // // // // //             (d) => d.name == (r['difficulty'] as String? ?? 'mild'),
// // // // // // // //             orElse: () => TodDifficulty.mild,
// // // // // // // //           ),
// // // // // // // //         );
// // // // // // // //       }).toList();
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   /// Fallback: load from local SQLite (downloaded packs cache).
// // // // // // // //   Future<List<TodCard>> loadCardsFromCache({
// // // // // // // //     required String packId,
// // // // // // // //     required String language,
// // // // // // // //     bool allowSpicy = false,
// // // // // // // //   }) async {
// // // // // // // //     try {
// // // // // // // //       final db = AppDatabase.instance.db;

// // // // // // // //       var sql = '''
// // // // // // // //         SELECT id, content_json, card_type, difficulty
// // // // // // // //         FROM pack_cards_cache
// // // // // // // //         WHERE pack_id = ?
// // // // // // // //       ''';
// // // // // // // //       final params = <Object>[packId];
// // // // // // // //       if (!allowSpicy) {
// // // // // // // //         sql += ' AND difficulty != ?';
// // // // // // // //         params.add('spicy');
// // // // // // // //       }
// // // // // // // //       sql += ' ORDER BY sort_order';

// // // // // // // //       final rows = await db.rawQuery(sql, params);

// // // // // // // //       // Debug: log how many cards were found
// // // // // // // //       AppLogger.debug(
// // // // // // // //         'TodRepository: found ${rows.length} cards for pack $packId',
// // // // // // // //       );

// // // // // // // //       // Also check if pack exists at all
// // // // // // // //       if (rows.isEmpty) {
// // // // // // // //         final packCheck = await db.rawQuery(
// // // // // // // //           'SELECT COUNT(*) as cnt FROM pack_cards WHERE pack_id = ?',
// // // // // // // //           [packId],
// // // // // // // //         );
// // // // // // // //         final cardCount = packCheck.first['cnt'] as int? ?? 0;
// // // // // // // //         AppLogger.debug(
// // // // // // // //           'TodRepository: pack_cards direct count = $cardCount for $packId',
// // // // // // // //         );
// // // // // // // //         // Try without the view
// // // // // // // //         if (cardCount > 0) {
// // // // // // // //           final directRows = await db.rawQuery(
// // // // // // // //             'SELECT id, content_json, card_type, difficulty, sort_order FROM pack_cards WHERE pack_id = ? ORDER BY sort_order',
// // // // // // // //             [packId],
// // // // // // // //           );
// // // // // // // //           AppLogger.debug(
// // // // // // // //             'TodRepository: direct query returned ${directRows.length} rows',
// // // // // // // //           );
// // // // // // // //           return directRows.map((r) {
// // // // // // // //             final rawContent = r['content_json'];
// // // // // // // //             final contentStr = rawContent is String
// // // // // // // //                 ? rawContent
// // // // // // // //                 : jsonEncode(rawContent ?? '{}');
// // // // // // // //             Map<String, dynamic> contentJson;
// // // // // // // //             try {
// // // // // // // //               contentJson = jsonDecode(contentStr) as Map<String, dynamic>;
// // // // // // // //             } catch (_) {
// // // // // // // //               contentJson = {'en': contentStr};
// // // // // // // //             }
// // // // // // // //             final content =
// // // // // // // //                 contentJson[language] as String? ??
// // // // // // // //                 contentJson['en'] as String? ??
// // // // // // // //                 '';
// // // // // // // //             return TodCard(
// // // // // // // //               id: r['id'] as String,
// // // // // // // //               content: content,
// // // // // // // //               type: TodCardType.values.firstWhere(
// // // // // // // //                 (t) => t.name == r['card_type'],
// // // // // // // //                 orElse: () => TodCardType.truth,
// // // // // // // //               ),
// // // // // // // //               difficulty: TodDifficulty.values.firstWhere(
// // // // // // // //                 (d) => d.name == r['difficulty'],
// // // // // // // //                 orElse: () => TodDifficulty.mild,
// // // // // // // //               ),
// // // // // // // //             );
// // // // // // // //           }).toList();
// // // // // // // //         }
// // // // // // // //       }

// // // // // // // //       return rows.map((r) {
// // // // // // // //         final rawJson = r['content_json'];
// // // // // // // //         final contentStr = rawJson is String
// // // // // // // //             ? rawJson
// // // // // // // //             : jsonEncode(rawJson ?? '{}');
// // // // // // // //         dynamic decoded;
// // // // // // // //         try {
// // // // // // // //           decoded = jsonDecode(contentStr);
// // // // // // // //         } catch (_) {
// // // // // // // //           decoded = <String, dynamic>{};
// // // // // // // //         }
// // // // // // // //         if (decoded is String) {
// // // // // // // //           try {
// // // // // // // //             decoded = jsonDecode(decoded);
// // // // // // // //           } catch (_) {
// // // // // // // //             decoded = <String, dynamic>{};
// // // // // // // //           }
// // // // // // // //         }
// // // // // // // //         final contentJson = decoded is Map
// // // // // // // //             ? Map<String, dynamic>.from(decoded)
// // // // // // // //             : <String, dynamic>{};
// // // // // // // //         final content =
// // // // // // // //             contentJson[language] as String? ??
// // // // // // // //             contentJson['en'] as String? ??
// // // // // // // //             '';
// // // // // // // //         return TodCard(
// // // // // // // //           id: r['id'] as String,
// // // // // // // //           content: content,
// // // // // // // //           type: TodCardType.values.firstWhere(
// // // // // // // //             (t) => t.name == r['card_type'],
// // // // // // // //             orElse: () => TodCardType.truth,
// // // // // // // //           ),
// // // // // // // //           difficulty: TodDifficulty.values.firstWhere(
// // // // // // // //             (d) => d.name == r['difficulty'],
// // // // // // // //             orElse: () => TodDifficulty.mild,
// // // // // // // //           ),
// // // // // // // //         );
// // // // // // // //       }).toList();
// // // // // // // //     } catch (e) {
// // // // // // // //       AppLogger.debug('TodRepository: SQLite cache miss for $packId — $e');
// // // // // // // //       return [];
// // // // // // // //     }
// // // // // // // //   }

// // // // // // // //   // ── Session persistence ────────────────────────────────────────────────────

// // // // // // // //   Future<String> createSession({
// // // // // // // //     required String roomId,
// // // // // // // //     required String packId,
// // // // // // // //     required GameConfig config,
// // // // // // // //     required List<String> playerIds,
// // // // // // // //     required String ownerId,
// // // // // // // //   }) => guardedCall(
// // // // // // // //     operationName: 'createTodSession',
// // // // // // // //     operation: () async {
// // // // // // // //       final row = await _supabase
// // // // // // // //           .from('game_sessions')
// // // // // // // //           .insert({
// // // // // // // //             'room_id': roomId,
// // // // // // // //             'pack_id': packId,
// // // // // // // //             'game_type': GameType.truthOrDare.toDbString(),
// // // // // // // //             'owner_id': ownerId,
// // // // // // // //             'player_ids': playerIds,
// // // // // // // //             'state_snapshot': {},
// // // // // // // //             'max_rounds': config.maxRounds,
// // // // // // // //             'turn_timer_secs': config.turnTimerSeconds,
// // // // // // // //             'allow_skip': config.allowSkip,
// // // // // // // //             'allow_spicy': config.allowSpicy,
// // // // // // // //             'status': 'active',
// // // // // // // //           })
// // // // // // // //           .select('id')
// // // // // // // //           .single();
// // // // // // // //       return row['id'] as String;
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   /// Called every 10s by owner to persist the current snapshot.
// // // // // // // //   /// Followers use this as a reconnect fallback.
// // // // // // // //   Future<void> saveSnapshot({
// // // // // // // //     required String sessionId,
// // // // // // // //     required Map<String, dynamic> snapshot,
// // // // // // // //   }) => guardedCall(
// // // // // // // //     operationName: 'saveTodSnapshot',
// // // // // // // //     operation: () async {
// // // // // // // //       await _supabase
// // // // // // // //           .from('game_sessions')
// // // // // // // //           .update({
// // // // // // // //             'state_snapshot': snapshot,
// // // // // // // //             'snapshot_at': DateTime.now().toIso8601String(),
// // // // // // // //           })
// // // // // // // //           .eq('id', sessionId);
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   /// Load the latest snapshot from DB (8s timeout fallback for followers).
// // // // // // // //   Future<Map<String, dynamic>?> loadSnapshot(String sessionId) => guardedCall(
// // // // // // // //     operationName: 'loadTodSnapshot',
// // // // // // // //     operation: () async {
// // // // // // // //       final row = await _supabase
// // // // // // // //           .from('game_sessions')
// // // // // // // //           .select('state_snapshot, status')
// // // // // // // //           .eq('id', sessionId)
// // // // // // // //           .single();

// // // // // // // //       if (row['status'] == 'completed' || row['status'] == 'aborted') {
// // // // // // // //         return null;
// // // // // // // //       }
// // // // // // // //       return row['state_snapshot'] as Map<String, dynamic>?;
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   /// Mark session complete and record final scores.
// // // // // // // //   Future<void> completeSession({
// // // // // // // //     required String sessionId,
// // // // // // // //     required Map<String, dynamic> finalSnapshot,
// // // // // // // //     required String endReason,
// // // // // // // //   }) => guardedCall(
// // // // // // // //     operationName: 'completeTodSession',
// // // // // // // //     operation: () async {
// // // // // // // //       await _supabase
// // // // // // // //           .from('game_sessions')
// // // // // // // //           .update({
// // // // // // // //             'status': 'completed',
// // // // // // // //             'state_snapshot': finalSnapshot,
// // // // // // // //             'ended_at': DateTime.now().toIso8601String(),
// // // // // // // //           })
// // // // // // // //           .eq('id', sessionId);
// // // // // // // //     },
// // // // // // // //   );
// // // // // // // // }

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
// // // // // // //         );
// // // // // // //       }).toList();
// // // // // // //     },
// // // // // // //   );

// // // // // // //   /// Fallback: load from local SQLite (downloaded packs cache).
// // // // // // //   Future<List<TodCard>> loadCardsFromCache({
// // // // // // //     required String packId,
// // // // // // //     required String language,
// // // // // // //     bool allowSpicy = false,
// // // // // // //   }) async {
// // // // // // //     try {
// // // // // // //       final db = AppDatabase.instance.db;

// // // // // // //       var sql = '''
// // // // // // //         SELECT id, content_json, card_type, difficulty
// // // // // // //         FROM pack_cards_cache
// // // // // // //         WHERE pack_id = ?
// // // // // // //       ''';
// // // // // // //       final params = <Object>[packId];
// // // // // // //       if (!allowSpicy) {
// // // // // // //         sql += ' AND difficulty != ?';
// // // // // // //         params.add('spicy');
// // // // // // //       }
// // // // // // //       sql += ' ORDER BY sort_order';

// // // // // // //       final rows = await db.rawQuery(sql, params);

// // // // // // //       // Debug: log how many cards were found
// // // // // // //       AppLogger.debug(
// // // // // // //         'TodRepository: found ${rows.length} cards for pack $packId',
// // // // // // //       );

// // // // // // //       // Also check if pack exists at all
// // // // // // //       if (rows.isEmpty) {
// // // // // // //         final packCheck = await db.rawQuery(
// // // // // // //           'SELECT COUNT(*) as cnt FROM pack_cards WHERE pack_id = ?',
// // // // // // //           [packId],
// // // // // // //         );
// // // // // // //         final cardCount = packCheck.first['cnt'] as int? ?? 0;
// // // // // // //         AppLogger.debug(
// // // // // // //           'TodRepository: pack_cards direct count = $cardCount for $packId',
// // // // // // //         );
// // // // // // //         // Try without the view
// // // // // // //         if (cardCount > 0) {
// // // // // // //           final directRows = await db.rawQuery(
// // // // // // //             'SELECT id, content_json, card_type, difficulty, sort_order FROM pack_cards WHERE pack_id = ? ORDER BY sort_order',
// // // // // // //             [packId],
// // // // // // //           );
// // // // // // //           AppLogger.debug(
// // // // // // //             'TodRepository: direct query returned ${directRows.length} rows',
// // // // // // //           );
// // // // // // //           return directRows.map((r) {
// // // // // // //             final rawContent = r['content_json'];
// // // // // // //             final contentStr = rawContent is String
// // // // // // //                 ? rawContent
// // // // // // //                 : jsonEncode(rawContent ?? '{}');
// // // // // // //             Map<String, dynamic> contentJson;
// // // // // // //             try {
// // // // // // //               contentJson = jsonDecode(contentStr) as Map<String, dynamic>;
// // // // // // //             } catch (_) {
// // // // // // //               contentJson = {'en': contentStr};
// // // // // // //             }
// // // // // // //             final content =
// // // // // // //                 contentJson[language] as String? ??
// // // // // // //                 contentJson['en'] as String? ??
// // // // // // //                 '';
// // // // // // //             return TodCard(
// // // // // // //               id: r['id'] as String,
// // // // // // //               content: content,
// // // // // // //               type: TodCardType.values.firstWhere(
// // // // // // //                 (t) => t.name == r['card_type'],
// // // // // // //                 orElse: () => TodCardType.truth,
// // // // // // //               ),
// // // // // // //               difficulty: TodDifficulty.values.firstWhere(
// // // // // // //                 (d) => d.name == r['difficulty'],
// // // // // // //                 orElse: () => TodDifficulty.mild,
// // // // // // //               ),
// // // // // // //             );
// // // // // // //           }).toList();
// // // // // // //         }
// // // // // // //       }

// // // // // // //       return rows.map((r) {
// // // // // // //         final rawJson = r['content_json'];
// // // // // // //         final contentStr = rawJson is String
// // // // // // //             ? rawJson
// // // // // // //             : jsonEncode(rawJson ?? '{}');
// // // // // // //         dynamic decoded;
// // // // // // //         try {
// // // // // // //           decoded = jsonDecode(contentStr);
// // // // // // //         } catch (_) {
// // // // // // //           decoded = <String, dynamic>{};
// // // // // // //         }
// // // // // // //         if (decoded is String) {
// // // // // // //           try {
// // // // // // //             decoded = jsonDecode(decoded);
// // // // // // //           } catch (_) {
// // // // // // //             decoded = <String, dynamic>{};
// // // // // // //           }
// // // // // // //         }
// // // // // // //         final contentJson = decoded is Map
// // // // // // //             ? Map<String, dynamic>.from(decoded)
// // // // // // //             : <String, dynamic>{};
// // // // // // //         final content =
// // // // // // //             contentJson[language] as String? ??
// // // // // // //             contentJson['en'] as String? ??
// // // // // // //             '';
// // // // // // //         return TodCard(
// // // // // // //           id: r['id'] as String,
// // // // // // //           content: content,
// // // // // // //           type: TodCardType.values.firstWhere(
// // // // // // //             (t) => t.name == r['card_type'],
// // // // // // //             orElse: () => TodCardType.truth,
// // // // // // //           ),
// // // // // // //           difficulty: TodDifficulty.values.firstWhere(
// // // // // // //             (d) => d.name == r['difficulty'],
// // // // // // //             orElse: () => TodDifficulty.mild,
// // // // // // //           ),
// // // // // // //         );
// // // // // // //       }).toList();
// // // // // // //     } catch (e) {
// // // // // // //       AppLogger.debug('TodRepository: SQLite cache miss for $packId — $e');
// // // // // // //     }

// // // // // // //     // Fallback: fetch directly from Supabase (pack not downloaded yet)
// // // // // // //     AppLogger.info('TodRepository: fetching cards from Supabase for $packId');
// // // // // // //     try {
// // // // // // //       final query = _supabase
// // // // // // //           .from('pack_cards')
// // // // // // //           .select('id, content, card_type, difficulty, sort_order')
// // // // // // //           .eq('pack_id', packId)
// // // // // // //           .order('sort_order');

// // // // // // //       final rows = await query as List;
// // // // // // //       return rows.map((r) {
// // // // // // //         final rawContent = r['content'];
// // // // // // //         Map<String, dynamic> contentJson;
// // // // // // //         try {
// // // // // // //           if (rawContent is Map) {
// // // // // // //             contentJson = Map<String, dynamic>.from(rawContent);
// // // // // // //           } else if (rawContent is String) {
// // // // // // //             final decoded = jsonDecode(rawContent);
// // // // // // //             contentJson = decoded is Map
// // // // // // //                 ? Map<String, dynamic>.from(decoded)
// // // // // // //                 : {'en': rawContent};
// // // // // // //           } else {
// // // // // // //             contentJson = {};
// // // // // // //           }
// // // // // // //         } catch (_) {
// // // // // // //           contentJson = {};
// // // // // // //         }
// // // // // // //         final content =
// // // // // // //             contentJson[language] as String? ??
// // // // // // //             contentJson['en'] as String? ??
// // // // // // //             '';
// // // // // // //         return TodCard(
// // // // // // //           id: r['id'] as String,
// // // // // // //           content: content,
// // // // // // //           type: TodCardType.values.firstWhere(
// // // // // // //             (t) => t.name == (r['card_type'] as String? ?? ''),
// // // // // // //             orElse: () => TodCardType.truth,
// // // // // // //           ),
// // // // // // //           difficulty: TodDifficulty.values.firstWhere(
// // // // // // //             (d) => d.name == (r['difficulty'] as String? ?? ''),
// // // // // // //             orElse: () => TodDifficulty.mild,
// // // // // // //           ),
// // // // // // //         );
// // // // // // //       }).toList();
// // // // // // //     } catch (e) {
// // // // // // //       AppLogger.error(
// // // // // // //         'TodRepository: Supabase fallback failed for $packId',
// // // // // // //         error: e,
// // // // // // //       );
// // // // // // //       return [];
// // // // // // //     }
// // // // // // //   }

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

// // // // // //       // Debug: log how many cards were found
// // // // // //       AppLogger.debug(
// // // // // //         'TodRepository: found ${rows.length} cards for pack $packId',
// // // // // //       );

// // // // // //       // Also check if pack exists at all
// // // // // //       if (rows.isEmpty) {
// // // // // //         final packCheck = await db.rawQuery(
// // // // // //           'SELECT COUNT(*) as cnt FROM pack_cards WHERE pack_id = ?',
// // // // // //           [packId],
// // // // // //         );
// // // // // //         final cardCount = packCheck.first['cnt'] as int? ?? 0;
// // // // // //         AppLogger.debug(
// // // // // //           'TodRepository: pack_cards direct count = $cardCount for $packId',
// // // // // //         );
// // // // // //         // Try without the view
// // // // // //         if (cardCount > 0) {
// // // // // //           final directRows = await db.rawQuery(
// // // // // //             'SELECT id, content_json, card_type, difficulty, sort_order FROM pack_cards WHERE pack_id = ? ORDER BY sort_order',
// // // // // //             [packId],
// // // // // //           );
// // // // // //           AppLogger.debug(
// // // // // //             'TodRepository: direct query returned ${directRows.length} rows',
// // // // // //           );
// // // // // //           return directRows.map((r) {
// // // // // //             final rawContent = r['content_json'];
// // // // // //             final contentStr = rawContent is String
// // // // // //                 ? rawContent
// // // // // //                 : jsonEncode(rawContent ?? '{}');
// // // // // //             Map<String, dynamic> contentJson;
// // // // // //             try {
// // // // // //               contentJson = jsonDecode(contentStr) as Map<String, dynamic>;
// // // // // //             } catch (_) {
// // // // // //               contentJson = {'en': contentStr};
// // // // // //             }
// // // // // //             final content =
// // // // // //                 contentJson[language] as String? ??
// // // // // //                 contentJson['en'] as String? ??
// // // // // //                 '';
// // // // // //             return TodCard(
// // // // // //               id: r['id'] as String,
// // // // // //               content: content,
// // // // // //               type: TodCardType.values.firstWhere(
// // // // // //                 (t) => t.name == r['card_type'],
// // // // // //                 orElse: () => TodCardType.truth,
// // // // // //               ),
// // // // // //               difficulty: TodDifficulty.values.firstWhere(
// // // // // //                 (d) => d.name == r['difficulty'],
// // // // // //                 orElse: () => TodDifficulty.mild,
// // // // // //               ),
// // // // // //             );
// // // // // //           }).toList();
// // // // // //         }
// // // // // //       }

// // // // // //       return rows.map((r) {
// // // // // //         final rawJson = r['content_json'];
// // // // // //         final contentStr = rawJson is String
// // // // // //             ? rawJson
// // // // // //             : jsonEncode(rawJson ?? '{}');
// // // // // //         dynamic decoded;
// // // // // //         try {
// // // // // //           decoded = jsonDecode(contentStr);
// // // // // //         } catch (_) {
// // // // // //           decoded = <String, dynamic>{};
// // // // // //         }
// // // // // //         if (decoded is String) {
// // // // // //           try {
// // // // // //             decoded = jsonDecode(decoded);
// // // // // //           } catch (_) {
// // // // // //             decoded = <String, dynamic>{};
// // // // // //           }
// // // // // //         }
// // // // // //         final contentJson = decoded is Map
// // // // // //             ? Map<String, dynamic>.from(decoded)
// // // // // //             : <String, dynamic>{};
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
// // // // // //     }

// // // // // //     // Fallback: fetch directly from Supabase (pack not downloaded yet)
// // // // // //     AppLogger.info('TodRepository: fetching cards from Supabase for $packId');
// // // // // //     try {
// // // // // //       final query = _supabase
// // // // // //           .from('pack_cards')
// // // // // //           .select('id, content, card_type, difficulty, sort_order')
// // // // // //           .eq('pack_id', packId)
// // // // // //           .order('sort_order');

// // // // // //       final rows = await query as List;
// // // // // //       // ignore: avoid_print
// // // // // //       print(
// // // // // //         '=== Supabase cards: ${rows.length}, first content: ${rows.isNotEmpty ? rows.first['content'] : 'none'}',
// // // // // //       );
// // // // // //       return rows.map((r) {
// // // // // //         final rawContent = r['content'];
// // // // // //         Map<String, dynamic> contentJson;
// // // // // //         try {
// // // // // //           if (rawContent is Map) {
// // // // // //             contentJson = Map<String, dynamic>.from(rawContent);
// // // // // //           } else if (rawContent is String) {
// // // // // //             final decoded = jsonDecode(rawContent);
// // // // // //             contentJson = decoded is Map
// // // // // //                 ? Map<String, dynamic>.from(decoded)
// // // // // //                 : {'en': rawContent};
// // // // // //           } else {
// // // // // //             contentJson = {};
// // // // // //           }
// // // // // //         } catch (_) {
// // // // // //           contentJson = {};
// // // // // //         }
// // // // // //         final content =
// // // // // //             contentJson[language] as String? ??
// // // // // //             contentJson['en'] as String? ??
// // // // // //             '';
// // // // // //         return TodCard(
// // // // // //           id: r['id'] as String,
// // // // // //           content: content,
// // // // // //           type: TodCardType.values.firstWhere(
// // // // // //             (t) => t.name == (r['card_type'] as String? ?? ''),
// // // // // //             orElse: () => TodCardType.truth,
// // // // // //           ),
// // // // // //           difficulty: TodDifficulty.values.firstWhere(
// // // // // //             (d) => d.name == (r['difficulty'] as String? ?? ''),
// // // // // //             orElse: () => TodDifficulty.mild,
// // // // // //           ),
// // // // // //         );
// // // // // //       }).toList();
// // // // // //     } catch (e) {
// // // // // //       AppLogger.error(
// // // // // //         'TodRepository: Supabase fallback failed for $packId',
// // // // // //         error: e,
// // // // // //       );
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
// // // // //         'TodRepository: found ${rows.length} cards for pack $packId, language=$language',
// // // // //       );
// // // // //       if (rows.isNotEmpty) {
// // // // //         // ignore: avoid_print
// // // // //         print(
// // // // //           '=== RAW first row content_json: ${rows.first["content_json"]?.runtimeType} = ${rows.first["content_json"]}',
// // // // //         );
// // // // //       }

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
// // // // //         final rawJson = r['content_json'];
// // // // //         final contentStr = rawJson is String
// // // // //             ? rawJson
// // // // //             : jsonEncode(rawJson ?? '{}');
// // // // //         dynamic decoded;
// // // // //         try {
// // // // //           decoded = jsonDecode(contentStr);
// // // // //         } catch (_) {
// // // // //           decoded = <String, dynamic>{};
// // // // //         }
// // // // //         if (decoded is String) {
// // // // //           try {
// // // // //             decoded = jsonDecode(decoded);
// // // // //           } catch (_) {
// // // // //             decoded = <String, dynamic>{};
// // // // //           }
// // // // //         }
// // // // //         final contentJson = decoded is Map
// // // // //             ? Map<String, dynamic>.from(decoded)
// // // // //             : <String, dynamic>{};
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
// // // // //     }

// // // // //     // Fallback: fetch directly from Supabase (pack not downloaded yet)
// // // // //     AppLogger.info('TodRepository: fetching cards from Supabase for $packId');
// // // // //     try {
// // // // //       final query = _supabase
// // // // //           .from('pack_cards')
// // // // //           .select('id, content, card_type, difficulty, sort_order')
// // // // //           .eq('pack_id', packId)
// // // // //           .order('sort_order');

// // // // //       final rows = await query as List;
// // // // //       // ignore: avoid_print
// // // // //       print(
// // // // //         '=== Supabase cards: ${rows.length}, first content: ${rows.isNotEmpty ? rows.first['content'] : 'none'}',
// // // // //       );
// // // // //       return rows.map((r) {
// // // // //         final rawContent = r['content'];
// // // // //         Map<String, dynamic> contentJson;
// // // // //         try {
// // // // //           if (rawContent is Map) {
// // // // //             contentJson = Map<String, dynamic>.from(rawContent);
// // // // //           } else if (rawContent is String) {
// // // // //             final decoded = jsonDecode(rawContent);
// // // // //             contentJson = decoded is Map
// // // // //                 ? Map<String, dynamic>.from(decoded)
// // // // //                 : {'en': rawContent};
// // // // //           } else {
// // // // //             contentJson = {};
// // // // //           }
// // // // //         } catch (_) {
// // // // //           contentJson = {};
// // // // //         }
// // // // //         final content =
// // // // //             contentJson[language] as String? ??
// // // // //             contentJson['en'] as String? ??
// // // // //             '';
// // // // //         return TodCard(
// // // // //           id: r['id'] as String,
// // // // //           content: content,
// // // // //           type: TodCardType.values.firstWhere(
// // // // //             (t) => t.name == (r['card_type'] as String? ?? ''),
// // // // //             orElse: () => TodCardType.truth,
// // // // //           ),
// // // // //           difficulty: TodDifficulty.values.firstWhere(
// // // // //             (d) => d.name == (r['difficulty'] as String? ?? ''),
// // // // //             orElse: () => TodDifficulty.mild,
// // // // //           ),
// // // // //         );
// // // // //       }).toList();
// // // // //     } catch (e) {
// // // // //       AppLogger.error(
// // // // //         'TodRepository: Supabase fallback failed for $packId',
// // // // //         error: e,
// // // // //       );
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
// // // //         'TodRepository: found ${rows.length} cards for pack $packId, language=$language',
// // // //       );
// // // //       if (rows.isNotEmpty) {
// // // //         // ignore: avoid_print
// // // //         print(
// // // //           '=== RAW first row content_json: ${rows.first["content_json"]?.runtimeType} = ${rows.first["content_json"]}',
// // // //         );
// // // //       }

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
// // // //     }

// // // //     // Fallback: fetch directly from Supabase (pack not downloaded yet)
// // // //     AppLogger.info('TodRepository: fetching cards from Supabase for $packId');
// // // //     try {
// // // //       final rows = await _supabase
// // // //           .from('pack_cards')
// // // //           .select('id, content, card_type, difficulty, sort_order')
// // // //           .eq('pack_id', packId)
// // // //           .order('sort_order');

// // // //       // ignore: avoid_print
// // // //       print(
// // // //         '=== Supabase fallback: ${rows.length} rows, first content: ${rows.isNotEmpty ? rows.first['content'] : 'none'}',
// // // //       );

// // // //       if (rows.isEmpty) return [];

// // // //       return rows.map((r) {
// // // //         final rawContent = r['content'];
// // // //         Map<String, dynamic> contentJson;
// // // //         try {
// // // //           if (rawContent is Map) {
// // // //             contentJson = Map<String, dynamic>.from(rawContent);
// // // //           } else if (rawContent is String) {
// // // //             final decoded = jsonDecode(rawContent);
// // // //             contentJson = decoded is Map
// // // //                 ? Map<String, dynamic>.from(decoded)
// // // //                 : {'en': rawContent};
// // // //           } else {
// // // //             contentJson = {};
// // // //           }
// // // //         } catch (_) {
// // // //           contentJson = {};
// // // //         }
// // // //         final content =
// // // //             contentJson[language] as String? ??
// // // //             contentJson['en'] as String? ??
// // // //             '';
// // // //         // ignore: avoid_print
// // // //         print('=== card content: $content');
// // // //         return TodCard(
// // // //           id: r['id'] as String,
// // // //           content: content,
// // // //           type: TodCardType.values.firstWhere(
// // // //             (t) => t.name == (r['card_type'] as String? ?? ''),
// // // //             orElse: () => TodCardType.truth,
// // // //           ),
// // // //           difficulty: TodDifficulty.values.firstWhere(
// // // //             (d) => d.name == (r['difficulty'] as String? ?? ''),
// // // //             orElse: () => TodDifficulty.mild,
// // // //           ),
// // // //         );
// // // //       }).toList();
// // // //     } catch (e) {
// // // //       AppLogger.error('TodRepository: Supabase fallback failed', error: e);
// // // //       // ignore: avoid_print
// // // //       print('=== Supabase fallback ERROR: $e');
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
// // //         'TodRepository: found ${rows.length} cards for pack $packId, language=$language',
// // //       );
// // //       if (rows.isNotEmpty) {
// // //         // ignore: avoid_print
// // //         print(
// // //           '=== RAW first row content_json: ${rows.first["content_json"]?.runtimeType} = ${rows.first["content_json"]}',
// // //         );
// // //       }

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
// // //       final rows = await _supabase
// // //           .from('pack_cards')
// // //           .select('id, content, card_type, difficulty, sort_order')
// // //           .eq('pack_id', packId)
// // //           .order('sort_order');

// // //       // ignore: avoid_print
// // //       print(
// // //         '=== Supabase fallback: ${rows.length} rows, first content: ${rows.isNotEmpty ? rows.first['content'] : 'none'}',
// // //       );

// // //       if (rows.isEmpty) return [];

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
// // //         // ignore: avoid_print
// // //         print('=== card content: $content');
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
// // //       AppLogger.error('TodRepository: Supabase fallback failed', error: e);
// // //       // ignore: avoid_print
// // //       print('=== Supabase fallback ERROR: $e');
// // //       return [];
// // //     }
// // //   }

// // //   // ── Session persistence ────────────────────────────────────────────────────

// // //   /// Find the most recent active (not completed/aborted) session for a room.
// // //   /// Used on (re)entry to decide whether to resume an existing game instead
// // //   /// of starting a brand-new one — this is what makes "Resume Game" actually
// // //   /// restore where the players left off (state + history) rather than
// // //   /// silently creating a fresh session every time the owner re-enters.
// // //   Future<Map<String, dynamic>?> findActiveSession(String roomId) => guardedCall(
// // //     operationName: 'findActiveTodSession',
// // //     operation: () async {
// // //       final row = await _supabase
// // //           .from('game_sessions')
// // //           .select('id, state_snapshot, status')
// // //           .eq('room_id', roomId)
// // //           .eq('status', 'active')
// // //           .order('started_at', ascending: false)
// // //           .limit(1)
// // //           .maybeSingle();
// // //       return row;
// // //     },
// // //   );

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
// //         'TodRepository: found ${rows.length} cards for pack $packId, language=$language',
// //       );
// //       if (rows.isNotEmpty) {
// //         // ignore: avoid_print
// //         print(
// //           '=== RAW first row content_json: ${rows.first["content_json"]?.runtimeType} = ${rows.first["content_json"]}',
// //         );
// //       }

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
// //       final rows = await _supabase
// //           .from('pack_cards')
// //           .select('id, content, card_type, difficulty, sort_order')
// //           .eq('pack_id', packId)
// //           .order('sort_order');

// //       // ignore: avoid_print
// //       print(
// //         '=== Supabase fallback: ${rows.length} rows, first content: ${rows.isNotEmpty ? rows.first['content'] : 'none'}',
// //       );

// //       if (rows.isEmpty) return [];

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
// //         // ignore: avoid_print
// //         print('=== card content: $content');
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
// //       AppLogger.error('TodRepository: Supabase fallback failed', error: e);
// //       // ignore: avoid_print
// //       print('=== Supabase fallback ERROR: $e');
// //       return [];
// //     }
// //   }

// //   // ── Session custom cards (premium) ────────────────────────────────────────

// //   /// Saves a custom card created by a premium player for this session only.
// //   /// Cards are stored in session_custom_cards, never in the shared packs.
// //   Future<TodCard> addCustomCard({
// //     required String sessionId,
// //     required String roomId,
// //     required String addedBy,
// //     required TodCardType type,
// //     required String content,
// //     required TodDifficulty difficulty,
// //   }) => guardedCall(
// //     operationName: 'addCustomCard',
// //     operation: () async {
// //       final row = await _supabase
// //           .from('session_custom_cards')
// //           .insert({
// //             'session_id': sessionId,
// //             'room_id': roomId,
// //             'added_by': addedBy,
// //             'card_type': type.name,
// //             'content': content,
// //             'difficulty': difficulty.name,
// //           })
// //           .select()
// //           .single();
// //       return TodCard(
// //         id: row['id'] as String,
// //         content: row['content'] as String,
// //         type: type,
// //         difficulty: difficulty,
// //       );
// //     },
// //   );

// //   /// Loads all custom cards for a session — merged into the normal deck
// //   /// by TodGameProvider so they appear alongside the pack cards during play.
// //   Future<List<TodCard>> loadCustomCards(String sessionId) => guardedCall(
// //     operationName: 'loadCustomCards',
// //     operation: () async {
// //       final rows = await _supabase
// //           .from('session_custom_cards')
// //           .select('id, content, card_type, difficulty')
// //           .eq('session_id', sessionId)
// //           .order('created_at');
// //       return rows
// //           .map(
// //             (r) => TodCard(
// //               id: r['id'] as String,
// //               content: r['content'] as String,
// //               type: TodCardType.values.firstWhere(
// //                 (t) => t.name == r['card_type'],
// //                 orElse: () => TodCardType.truth,
// //               ),
// //               difficulty: TodDifficulty.values.firstWhere(
// //                 (d) => d.name == r['difficulty'],
// //                 orElse: () => TodDifficulty.mild,
// //               ),
// //             ),
// //           )
// //           .toList();
// //     },
// //   );

// //   Future<void> deleteCustomCard(String cardId) => guardedCall(
// //     operationName: 'deleteCustomCard',
// //     operation: () async {
// //       await _supabase.from('session_custom_cards').delete().eq('id', cardId);
// //     },
// //   );

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
//       final rows = await _supabase
//           .from('pack_cards')
//           .select('id, content, card_type, difficulty, sort_order')
//           .eq('pack_id', packId)
//           .order('sort_order');

//       // ignore: avoid_print
//       print(
//         '=== Supabase fallback: ${rows.length} rows, first content: ${rows.isNotEmpty ? rows.first['content'] : 'none'}',
//       );

//       if (rows.isEmpty) return [];

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
//         // ignore: avoid_print
//         print('=== card content: $content');
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
//       AppLogger.error('TodRepository: Supabase fallback failed', error: e);
//       // ignore: avoid_print
//       print('=== Supabase fallback ERROR: $e');
//       return [];
//     }
//   }

//   // ── Session custom cards (premium) ────────────────────────────────────────

//   /// Saves a custom card created by a premium player for this session only.
//   /// Cards are stored in session_custom_cards, never in the shared packs.
//   Future<TodCard> addCustomCard({
//     required String sessionId,
//     required String roomId,
//     required String addedBy,
//     required TodCardType type,
//     required String content,
//     required TodDifficulty difficulty,
//   }) => guardedCall(
//     operationName: 'addCustomCard',
//     operation: () async {
//       final row = await _supabase
//           .from('session_custom_cards')
//           .insert({
//             'session_id': sessionId,
//             'room_id': roomId,
//             'added_by': addedBy,
//             'card_type': type.name,
//             'content': content,
//             'difficulty': difficulty.name,
//           })
//           .select()
//           .single();
//       return TodCard(
//         id: row['id'] as String,
//         content: row['content'] as String,
//         type: type,
//         difficulty: difficulty,
//       );
//     },
//   );

//   /// Loads all custom cards for a session — merged into the normal deck
//   /// by TodGameProvider so they appear alongside the pack cards during play.
//   Future<List<TodCard>> loadCustomCards(String sessionId) => guardedCall(
//     operationName: 'loadCustomCards',
//     operation: () async {
//       final rows = await _supabase
//           .from('session_custom_cards')
//           .select('id, content, card_type, difficulty')
//           .eq('session_id', sessionId)
//           .order('created_at');
//       return rows
//           .map(
//             (r) => TodCard(
//               id: r['id'] as String,
//               content: r['content'] as String,
//               type: TodCardType.values.firstWhere(
//                 (t) => t.name == r['card_type'],
//                 orElse: () => TodCardType.truth,
//               ),
//               difficulty: TodDifficulty.values.firstWhere(
//                 (d) => d.name == r['difficulty'],
//                 orElse: () => TodDifficulty.mild,
//               ),
//             ),
//           )
//           .toList();
//     },
//   );

//   Future<void> deleteCustomCard(String cardId) => guardedCall(
//     operationName: 'deleteCustomCard',
//     operation: () async {
//       await _supabase.from('session_custom_cards').delete().eq('id', cardId);
//     },
//   );

//   // ── Session persistence ────────────────────────────────────────────────────

//   /// Find the most recent active (not completed/aborted) session for a room.
//   /// Used on (re)entry to decide whether to resume an existing game instead
//   /// of starting a brand-new one — this is what makes "Resume Game" actually
//   /// restore where the players left off rather than silently creating a fresh
//   /// session every time the owner re-enters.
//   Future<Map<String, dynamic>?> findActiveSession(String roomId) => guardedCall(
//     operationName: 'findActiveTodSession',
//     operation: () async {
//       final row = await _supabase
//           .from('game_sessions')
//           .select('id, state_snapshot, status')
//           .eq('room_id', roomId)
//           .eq('status', 'active')
//           .order('started_at', ascending: false)
//           .limit(1)
//           .maybeSingle();
//       return row;
//     },
//   );

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
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/database/app_database.dart';
import '../../../../core/utils/app_logger.dart';
import '../domain/tod_models.dart';
import '../../engine/base_game_engine.dart';

const _uuid = Uuid();

/// Resolves a card's/pack's localized text for [lang]: the requested
/// language first, then 'en' (legacy default), then — critically — the
/// first non-empty value present under ANY key. Packs authored in a
/// single non-en/ar/fr language (e.g. 'hs' Hassaniya, or any future
/// language code from pack_languages) only ever populate ONE key in this
/// map, which is neither [lang] nor 'en' whenever the room/viewer isn't
/// using that exact language — without this last resort, such packs
/// render every card blank instead of showing the content that actually
/// exists. Never returns a raw id; callers substitute a localized "no
/// content" string when this returns ''.
String _pickLocalized(Map<String, dynamic> json, String lang) {
  String? nonEmpty(String? key) {
    if (key == null) return null;
    final v = json[key];
    return (v is String && v.trim().isNotEmpty) ? v : null;
  }

  final direct = nonEmpty(lang) ?? nonEmpty('en');
  if (direct != null) return direct;
  for (final v in json.values) {
    if (v is String && v.trim().isNotEmpty) return v;
  }
  return '';
}

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
        final content = _pickLocalized(contentJson, language);
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

      AppLogger.debug(
        'TodRepository: found ${rows.length} cards for pack $packId, language=$language',
      );

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
            final content = _pickLocalized(contentJson, language);
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
        final content = _pickLocalized(contentJson, language);
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
        final content = _pickLocalized(contentJson, language);
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
      return [];
    }
  }

  // ── Session custom cards (premium) ────────────────────────────────────────

  /// Saves a custom card created by a premium player for this session only.
  /// Cards are stored in session_custom_cards, never in the shared packs.
  Future<TodCard> addCustomCard({
    required String sessionId,
    required String roomId,
    required String addedBy,
    required TodCardType type,
    required String content,
    required TodDifficulty difficulty,
  }) => guardedCall(
    operationName: 'addCustomCard',
    operation: () async {
      final row = await _supabase
          .from('session_custom_cards')
          .insert({
            'session_id': sessionId,
            'room_id': roomId,
            'added_by': addedBy,
            'card_type': type.name,
            'content': content,
            'difficulty': difficulty.name,
          })
          .select()
          .single();
      return TodCard(
        id: row['id'] as String,
        content: row['content'] as String,
        type: type,
        difficulty: difficulty,
      );
    },
  );

  /// Loads all custom cards for a session — merged into the normal deck
  /// by TodGameProvider so they appear alongside the pack cards during play.
  Future<List<TodCard>> loadCustomCards(String sessionId) => guardedCall(
    operationName: 'loadCustomCards',
    operation: () async {
      final rows = await _supabase
          .from('session_custom_cards')
          .select('id, content, card_type, difficulty')
          .eq('session_id', sessionId)
          .order('created_at');
      return rows
          .map(
            (r) => TodCard(
              id: r['id'] as String,
              content: r['content'] as String,
              type: TodCardType.values.firstWhere(
                (t) => t.name == r['card_type'],
                orElse: () => TodCardType.truth,
              ),
              difficulty: TodDifficulty.values.firstWhere(
                (d) => d.name == r['difficulty'],
                orElse: () => TodDifficulty.mild,
              ),
            ),
          )
          .toList();
    },
  );

  Future<void> deleteCustomCard(String cardId) => guardedCall(
    operationName: 'deleteCustomCard',
    operation: () async {
      await _supabase.from('session_custom_cards').delete().eq('id', cardId);
    },
  );

  // ── Session persistence ────────────────────────────────────────────────────

  /// Find the most recent active (not completed/aborted) session for a room.
  /// Used on (re)entry to decide whether to resume an existing game instead
  /// of starting a brand-new one — this is what makes "Resume Game" actually
  /// restore where the players left off rather than silently creating a fresh
  /// session every time the owner re-enters.
  Future<Map<String, dynamic>?> findActiveSession(String roomId) => guardedCall(
    operationName: 'findActiveTodSession',
    operation: () async {
      // Scoped to game_type='truth_or_dare' — never treat a stale
      // active/paused session from a different game type in the same
      // room as ToD's own existing session. Same class of bug as
      // NHIE/Meme's equivalent lookup (fixed identically there) — a
      // room-only filter here could latch onto an NHIE/Meme session
      // that hasn't yet transitioned out of 'active'.
      final row = await _supabase
          .from('game_sessions')
          .select('id, state_snapshot, status, config, lifecycle_state')
          .eq('room_id', roomId)
          .eq('game_type', 'truth_or_dare')
          .eq('status', 'active')
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return row;
    },
  );

  /// Records "I loaded this exact game session" durably (survives a
  /// reconnect that missed the ephemeral broadcast) — the owner
  /// activates the session once every player_id has confirmed or its own
  /// timeout elapses; see TodGameProvider._confirmReadyAndMaybeActivate.
  Future<void> confirmSessionReady(String sessionId) => guardedCall(
    operationName: 'confirmTodSessionReady',
    operation: () async {
      await _supabase.rpc(
        'confirm_game_session_ready',
        params: {'p_session_id': sessionId},
      );
    },
  );

  /// Owner-only: transitions the session from 'starting' to 'active',
  /// unblocking gameplay actions for every client (see
  /// TodGameProvider._handleAction/onPlayerAction's lifecycle gate).
  Future<void> activateSession(String sessionId) => guardedCall(
    operationName: 'activateTodSession',
    operation: () async {
      await _supabase.rpc(
        'activate_game_session',
        params: {'p_session_id': sessionId},
      );
    },
  );

  /// Weak-connection fallback for a follower stuck on 'starting' with no
  /// session_active broadcast having arrived yet — polls the DB directly
  /// instead of waiting indefinitely.
  Future<String?> getSessionLifecycleState(String sessionId) => guardedCall(
    operationName: 'getTodSessionLifecycleState',
    operation: () async {
      final row = await _supabase
          .from('game_sessions')
          .select('lifecycle_state')
          .eq('id', sessionId)
          .maybeSingle();
      return row?['lifecycle_state'] as String?;
    },
  );

  /// The single source of truth for "who is actually in this room right
  /// now" at the exact moment a NEW session is about to be created —
  /// deliberately a fresh query, not RoomProvider.members. The Start Game
  /// button's own flow has several awaits between the tap (a pack lookup,
  /// the server-side pack-already-played check, Truth or Dare's pre-game
  /// config sheet, which is a full modal the owner can sit on indefinitely)
  /// before actually reaching createSession — a player leaving at any
  /// point in that window left the session created with a stale
  /// player_ids entry for someone no longer there, which the ready
  /// barrier (waiting on every one of them to confirm) or the engine's
  /// own turn order would then wait on forever. See
  /// TodGameProvider.initAsOwner, which calls this instead of trusting
  /// its own playerIds parameter for a genuinely new game.
  Future<List<String>> fetchActiveMemberIds(String roomId) => guardedCall(
    operationName: 'fetchActiveMemberIds',
    operation: () async {
      final rows = await _supabase
          .from('room_members')
          .select('user_id')
          .eq('room_id', roomId)
          .isFilter('left_at', null)
          .neq('role', 'spectator');
      return rows.map((r) => r['user_id'] as String).toList();
    },
  );

  Future<String> createSession({
    required String roomId,
    required String packId,
    required GameConfig config,
    required List<String> playerIds,
    required String ownerId,
    required Map<String, dynamic> stateSnapshot,
  }) => guardedCall(
    operationName: 'createTodSession',
    operation: () async {
      // game_sessions has no permissive INSERT policy — creation only ever
      // happens through this SECURITY DEFINER RPC, which also enforces that
      // the caller is the room owner or an explicitly-permitted moderator.
      // This is now the SAME canonical 9-param signature NHIE/Meme already
      // call — the old 10-param overload (p_config, ToD-only, not
      // race-safe) is retired; see
      // migration_2026_starting_state_and_tod_canonical_rpc.sql.
      try {
        final id =
            await _supabase.rpc(
                  'create_game_session',
                  params: {
                    'p_room_id': roomId,
                    'p_pack_id': packId,
                    'p_game_type': GameType.truthOrDare.toDbString(),
                    'p_player_ids': playerIds,
                    'p_max_rounds': config.maxRounds,
                    'p_turn_timer_secs': config.turnTimerSeconds,
                    'p_allow_skip': config.allowSkip,
                    'p_allow_spicy': config.allowSpicy,
                    'p_state_snapshot': stateSnapshot,
                    // Items 2/3/8 — ToD's own 'unique' cardRepetitionMode
                    // (see TruthOrDareEngine._draw) is what the server
                    // needs to know to enforce Max Rounds <= actual card
                    // supply; 'shuffle' (the default) has no ceiling,
                    // matching this same false default.
                    'p_unique_cards': config.cardRepetitionMode == 'unique',
                  },
                )
                as String;
        // The canonical RPC has no p_config parameter of its own to
        // populate this in the same INSERT — game_sessions.config is a
        // real, existing column (see findActiveSession/findLatestSession,
        // which already read it back), just no longer written inline by
        // create_game_session itself. Written here as a plain follow-up
        // update instead, identically to how saveSnapshot/completeSession
        // already write state_snapshot post-creation — so a resumed game
        // still never silently reconstructs a different config than the
        // one it actually started with.
        await _supabase
            .from('game_sessions')
            .update({'config': config.toMap()})
            .eq('id', id);
        return id;
      } on PostgrestException catch (e) {
        if (e.message.contains('permission_denied')) {
          throw const ForbiddenFailure(
            message: 'Only the room owner or an authorized moderator can start the game.',
          );
        }
        rethrow;
      }
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
  /// Returns the snapshot regardless of session status — a finished session's
  /// snapshot already has `is_over: true` embedded, so callers can render the
  /// results screen instead of treating a completed game as unrecoverable.
  /// Also returns lifecycle_state alongside the snapshot — a caller that
  /// only checked the snapshot content (ignoring whether the session had
  /// actually reached 'active') was a real gap: it let a weak-connection
  /// client's 8s no-broadcast-received fallback silently unlock the full
  /// interactive game UI for a session still stuck in 'starting', since
  /// this was the one snapshot-loading path that predated (and knew
  /// nothing about) the ready barrier.
  Future<(Map<String, dynamic>?, String?, String?)> loadSnapshot(
    String sessionId,
  ) => guardedCall(
    operationName: 'loadTodSnapshot',
    operation: () async {
      final row = await _supabase
          .from('game_sessions')
          .select('state_snapshot, lifecycle_state, status')
          .eq('id', sessionId)
          .single();
      return (
        row['state_snapshot'] as Map<String, dynamic>?,
        row['lifecycle_state'] as String?,
        row['status'] as String?,
      );
    },
  );

  /// Real server-side enforcement of who can view proof and how many
  /// times — previously view/replay counting only ever lived in the shared
  /// broadcast game state (owner-authoritative, no backend validation at
  /// all). Throws (via guardedCall's PostgrestException handling) with a
  /// message containing 'not_permitted' or 'view_limit_exceeded' when the
  /// caller isn't allowed to view or has already used up their allotment —
  /// callers must not reveal the proof content unless this succeeds.
  Future<Map<String, dynamic>> recordProofView({
    required String sessionId,
    required int turnStartedAt,
  }) => guardedCall(
    operationName: 'recordProofView',
    operation: () async {
      final result = await _supabase.rpc(
        'record_proof_view',
        params: {
          'p_session_id': sessionId,
          'p_turn_started_at': turnStartedAt,
        },
      );
      return Map<String, dynamic>.from(result as Map);
    },
  );

  /// Durable, synchronous record of one turn's proof visibility + viewing
  /// rules — see TodGameProvider.saveProofMetadata's doc comment for why
  /// this exists separately from the periodic (every-10s) state snapshot.
  /// record_proof_view reads this row (falling back to the room's own
  /// proof_visibility_policy settings when absent — an older client, or a
  /// session predating this) to authorize/gate each view server-side.
  Future<void> saveTurnProofMetadata({
    required String sessionId,
    required int turnStartedAt,
    required TodProofVisibilitySettings visibility,
    required TodProofViewMode viewMode,
    required int viewSeconds,
  }) => guardedCall(
    operationName: 'saveTurnProofMetadata',
    operation: () async {
      // Snake_case wire vocabulary, matching room_settings.
      // proof_visibility_policy's existing values — NOT
      // TodProofVisibility.name (camelCase, used only for the client-side
      // broadcast/state round-trip) — so record_proof_view's existing
      // room-settings comparisons can be reused verbatim for this new
      // per-turn source too.
      final wirePolicy = switch (visibility.visibility) {
        TodProofVisibility.playersOnly => 'players_only',
        TodProofVisibility.spectatorsOnly => 'spectators_only',
        TodProofVisibility.selectedPlayers => 'selected',
        TodProofVisibility.everyone => 'everyone',
      };
      await _supabase.rpc(
        'save_tod_proof_metadata',
        params: {
          'p_session_id': sessionId,
          'p_turn_started_at': turnStartedAt,
          'p_visibility': wirePolicy,
          'p_visible_to_ids': visibility.visibleToIds,
          'p_view_mode': viewMode == TodProofViewMode.timed
              ? 'timed'
              : viewMode == TodProofViewMode.replayOnce
                  ? 'replay_once'
                  : 'once',
          'p_view_seconds': viewSeconds,
        },
      );
    },
  );

  /// Server-authoritative "watched by N" (distinct viewers) + "replays"
  /// (extra opens beyond each viewer's first) counts for a batch of
  /// rounds, keyed by turnStartedAt — for the in-game history panel.
  /// Backed entirely by the existing tod_proof_views rows record_proof_view
  /// already writes; get_tod_proof_view_stats only aggregates them
  /// (RLS on the table itself only allows a client to see their own view
  /// rows, so the cross-player aggregate must go through this RPC).
  /// Returns turnStartedAt → (distinctViewers, totalViews); a turn with no
  /// rows in tod_proof_views (nobody watched, or a round predating this
  /// field) is simply absent from the map.
  Future<Map<int, ({int distinctViewers, int totalViews})>> getProofViewStats({
    required String sessionId,
    required List<int> turnStartedAts,
  }) => guardedCall(
    operationName: 'getProofViewStats',
    operation: () async {
      if (turnStartedAts.isEmpty) return {};
      final rows = await _supabase.rpc(
        'get_tod_proof_view_stats',
        params: {
          'p_session_id': sessionId,
          'p_turn_started_ats': turnStartedAts,
        },
      ) as List<dynamic>;
      return {
        for (final r in rows.cast<Map<String, dynamic>>())
          (r['turn_started_at'] as num).toInt(): (
            distinctViewers: (r['distinct_viewers'] as num).toInt(),
            totalViews: (r['total_views'] as num).toInt(),
          ),
      };
    },
  );

  /// Find the most recent session for a room regardless of status — used as
  /// a fallback when [findActiveSession] finds nothing, so a reconnecting
  /// owner whose game already ended lands on the results snapshot instead of
  /// silently starting a brand-new session.
  Future<Map<String, dynamic>?> findLatestSession(String roomId) =>
      guardedCall(
        operationName: 'findLatestTodSession',
        operation: () async {
          // Same game_type scoping as findActiveSession above — a
          // completed/aborted session from a DIFFERENT game must never be
          // picked up as ToD's own "latest session" fallback.
          final row = await _supabase
              .from('game_sessions')
              .select('id, state_snapshot, status, config, lifecycle_state')
              .eq('room_id', roomId)
              .eq('game_type', 'truth_or_dare')
              .order('started_at', ascending: false)
              .limit(1)
              .maybeSingle();
          return row;
        },
      );

  /// Mark session complete and record final scores.
  Future<void> completeSession({
    required String sessionId,
    required Map<String, dynamic> finalSnapshot,
    required String endReason,
    Map<String, dynamic>? finalScores,
  }) => guardedCall(
    operationName: 'completeTodSession',
    operation: () async {
      await _supabase
          .from('game_sessions')
          .update({
            'status': 'completed',
            'state_snapshot': finalSnapshot,
            'ended_at': DateTime.now().toIso8601String(),
            if (finalScores != null) 'final_scores': finalScores,
          })
          .eq('id', sessionId);
    },
  );
}
