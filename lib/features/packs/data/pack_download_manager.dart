// // // import 'dart:async';
// // // import 'dart:convert';
// // // import 'dart:io';

// // // import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // import 'package:path/path.dart' as p;
// // // import 'package:path_provider/path_provider.dart';
// // // import 'package:sqflite/sqflite.dart';

// // // import '../../../../core/storage/database/app_database.dart';
// // // import '../../../../core/utils/app_logger.dart';
// // // import '../domain/pack_entity.dart';

// // // /// Manages the full offline pack lifecycle:
// // // ///   download → atomic SQLite write → availability check → cleanup
// // // ///
// // // /// Download flow:
// // // ///   1. Fetch JSON manifest from Wasabi (download_url on pack)
// // // ///   2. Parse cards array from JSON
// // // ///   3. Download card images (if any) in parallel, bounded concurrency
// // // ///   4. Write pack header + all cards in one SQLite transaction (atomic)
// // // ///   5. Update sync_log with server version
// // // ///
// // // /// Idempotency: re-downloading the same version is a no-op.
// // // /// Recovery: failed downloads leave no partial data (transaction rollback).
// // // class PackDownloadManager {
// // //   PackDownloadManager._();
// // //   static final PackDownloadManager _instance = PackDownloadManager._();
// // //   static PackDownloadManager get instance => _instance;

// // //   final _db = AppDatabase.instance;

// // //   // Active downloads: packId → StreamController
// // //   final _active = <String, StreamController<PackDownloadState>>{};

// // //   // Global progress broadcast (for download list UI)
// // //   final _globalCtrl =
// // //       StreamController<MapEntry<String, PackDownloadState>>.broadcast();
// // //   Stream<MapEntry<String, PackDownloadState>> get globalProgress =>
// // //       _globalCtrl.stream;

// // //   /// Stream of download state for a specific pack.
// // //   Stream<PackDownloadState> progressFor(String packId) {
// // //     return _active[packId]?.stream ??
// // //         Stream.value(PackDownloadState.initial(packId));
// // //   }

// // //   // ── Download ───────────────────────────────────────────────────────────────

// // //   /// Download a pack for offline use.
// // //   /// Returns immediately; progress comes via [progressFor].
// // //   /// Safe to call multiple times — duplicate calls for the same pack are ignored.
// // //   Future<void> download(PackEntity pack) async {
// // //     if (_active.containsKey(pack.id)) {
// // //       AppLogger.debug('PackDownloadManager: already downloading ${pack.id}');
// // //       return;
// // //     }

// // //     // Already downloaded at current version?
// // //     if (await _isCurrentVersion(pack.id, pack.version)) {
// // //       AppLogger.debug(
// // //         'PackDownloadManager: pack ${pack.id} already at v${pack.version}',
// // //       );
// // //       return;
// // //     }

// // //     final ctrl = StreamController<PackDownloadState>.broadcast();
// // //     _active[pack.id] = ctrl;

// // //     _doDownload(pack, ctrl).whenComplete(() {
// // //       Future.delayed(const Duration(seconds: 2), () {
// // //         _active.remove(pack.id)?.close();
// // //       });
// // //     });
// // //   }

// // //   Future<void> _doDownload(
// // //     PackEntity pack,
// // //     StreamController<PackDownloadState> ctrl,
// // //   ) async {
// // //     void emit(PackDownloadState s) {
// // //       if (!ctrl.isClosed) ctrl.add(s);
// // //       _globalCtrl.add(MapEntry(pack.id, s));
// // //     }

// // //     emit(
// // //       PackDownloadState(
// // //         packId: pack.id,
// // //         status: DownloadStatus.downloading,
// // //         progress: 0.0,
// // //       ),
// // //     );

// // //     try {
// // //       List<Map<String, dynamic>> cards;

// // //       if (pack.downloadUrl != null) {
// // //         // Fetch manifest from Wasabi
// // //         emit(
// // //           PackDownloadState(
// // //             packId: pack.id,
// // //             status: DownloadStatus.downloading,
// // //             progress: 0.05,
// // //           ),
// // //         );
// // //         final manifest = await _fetchManifest(pack.downloadUrl!);
// // //         cards = (manifest['cards'] as List? ?? []).cast<Map<String, dynamic>>();
// // //       } else {
// // //         // No Wasabi URL — fetch cards directly from Supabase
// // //         emit(
// // //           PackDownloadState(
// // //             packId: pack.id,
// // //             status: DownloadStatus.downloading,
// // //             progress: 0.05,
// // //           ),
// // //         );
// // //         final rows = await Supabase.instance.client
// // //             .from('pack_cards')
// // //             .select('id, content, card_type, difficulty, sort_order')
// // //             .eq('pack_id', pack.id)
// // //             .order('sort_order');
// // //         cards = (rows as List).map((r) {
// // //           final content = r['content'];
// // //           final contentStr = content is String
// // //               ? content
// // //               : content is Map
// // //               ? jsonEncode(content)
// // //               : '{}';
// // //           return {
// // //             'id': r['id'],
// // //             'content': contentStr,
// // //             'card_type': r['card_type'],
// // //             'difficulty': r['difficulty'] ?? 'mild',
// // //             'sort_order': r['sort_order'] ?? 0,
// // //           };
// // //         }).toList();
// // //       }

// // //       // Step 2: Download card images if present (bounded parallelism)
// // //       final imageMap = <String, String>{}; // cardId → local path
// // //       if (cards.any((c) => c['image_url'] != null)) {
// // //         await _downloadImages(pack.id, cards, imageMap, (progress) {
// // //           emit(
// // //             PackDownloadState(
// // //               packId: pack.id,
// // //               status: DownloadStatus.downloading,
// // //               progress: 0.05 + progress * 0.70,
// // //             ),
// // //           );
// // //         });
// // //       }

// // //       // Step 3: Atomic SQLite write
// // //       emit(
// // //         PackDownloadState(
// // //           packId: pack.id,
// // //           status: DownloadStatus.downloading,
// // //           progress: 0.85,
// // //         ),
// // //       );
// // //       await _writeToDatabase(pack, cards, imageMap);

// // //       // Step 4: Update sync_log
// // //       await _updateSyncLog(pack.id, pack.version);

// // //       final finalState = PackDownloadState(
// // //         packId: pack.id,
// // //         status: DownloadStatus.downloaded,
// // //         progress: 1.0,
// // //         downloadedAt: DateTime.now(),
// // //         localVersion: pack.version,
// // //       );
// // //       emit(finalState);
// // //       AppLogger.info(
// // //         'PackDownloadManager: ✅ downloaded ${pack.id} v${pack.version}',
// // //       );
// // //     } catch (e, st) {
// // //       AppLogger.error(
// // //         'PackDownloadManager: ❌ download failed for ${pack.id}',
// // //         error: e,
// // //         stackTrace: st,
// // //       );
// // //       emit(
// // //         PackDownloadState(
// // //           packId: pack.id,
// // //           status: DownloadStatus.failed,
// // //           errorMessage: e.toString(),
// // //         ),
// // //       );
// // //     }
// // //   }

// // //   // ── Manifest fetch ─────────────────────────────────────────────────────────

// // //   Future<Map<String, dynamic>> _fetchManifest(String url) async {
// // //     final client = HttpClient()
// // //       ..connectionTimeout = const Duration(seconds: 30);
// // //     try {
// // //       final req = await client.getUrl(Uri.parse(url));
// // //       final resp = await req.close();
// // //       if (resp.statusCode != 200) {
// // //         throw Exception('Manifest fetch failed: HTTP ${resp.statusCode}');
// // //       }
// // //       final body = await resp.transform(utf8.decoder).join();
// // //       return jsonDecode(body) as Map<String, dynamic>;
// // //     } finally {
// // //       client.close();
// // //     }
// // //   }

// // //   // ── Image download ─────────────────────────────────────────────────────────

// // //   Future<void> _downloadImages(
// // //     String packId,
// // //     List<Map<String, dynamic>> cards,
// // //     Map<String, String> imageMap,
// // //     void Function(double) onProgress,
// // //   ) async {
// // //     final toDownload = cards
// // //         .where((c) => c['image_url'] != null && c['id'] != null)
// // //         .toList();

// // //     if (toDownload.isEmpty) return;

// // //     final dir = await _imageDirectory(packId);
// // //     int done = 0;

// // //     // Max 4 concurrent image downloads
// // //     const concurrency = 4;
// // //     final chunks = _chunked(toDownload, concurrency);

// // //     for (final chunk in chunks) {
// // //       await Future.wait(
// // //         chunk.map((card) async {
// // //           final cardId = card['id'] as String;
// // //           final imageUrl = card['image_url'] as String;
// // //           try {
// // //             final localPath = await _downloadImage(imageUrl, dir, cardId);
// // //             if (localPath != null) imageMap[cardId] = localPath;
// // //           } catch (e) {
// // //             AppLogger.warning(
// // //               'PackDownloadManager: image download failed $cardId, $e',
// // //             );
// // //           }
// // //           done++;
// // //           onProgress(done / toDownload.length);
// // //         }),
// // //       );
// // //     }
// // //   }

// // //   Future<String?> _downloadImage(
// // //     String url,
// // //     Directory dir,
// // //     String cardId,
// // //   ) async {
// // //     final ext = url.split('.').last.split('?').first;
// // //     final file = File(p.join(dir.path, '$cardId.$ext'));
// // //     if (await file.exists()) return file.path; // already cached

// // //     final client = HttpClient()
// // //       ..connectionTimeout = const Duration(seconds: 15);
// // //     try {
// // //       final req = await client.getUrl(Uri.parse(url));
// // //       final resp = await req.close();
// // //       if (resp.statusCode != 200) return null;
// // //       await resp.pipe(file.openWrite());
// // //       return file.path;
// // //     } finally {
// // //       client.close();
// // //     }
// // //   }

// // //   Future<Directory> _imageDirectory(String packId) async {
// // //     final appDir = await getApplicationDocumentsDirectory();
// // //     final dir = Directory(p.join(appDir.path, 'pack_images', packId));
// // //     await dir.create(recursive: true);
// // //     return dir;
// // //   }

// // //   // ── SQLite write ───────────────────────────────────────────────────────────

// // //   Future<void> _writeToDatabase(
// // //     PackEntity pack,
// // //     List<Map<String, dynamic>> cards,
// // //     Map<String, String> imageMap,
// // //   ) async {
// // //     final db = _db.db;

// // //     await db.transaction((txn) async {
// // //       // Delete old data for this pack (re-download scenario)
// // //       await txn.delete(
// // //         'pack_cards',
// // //         where: 'pack_id = ?',
// // //         whereArgs: [pack.id],
// // //       );
// // //       await txn.delete('packs', where: 'id = ?', whereArgs: [pack.id]);

// // //       // Write pack header
// // //       await txn.insert('packs', {
// // //         'id': pack.id,
// // //         'name_json': jsonEncode(pack.titleJson),
// // //         'cover_url': pack.coverImageUrl,
// // //         'game_type': pack.gameType,
// // //         'language': pack.language,
// // //         'price': pack.priceMru,
// // //         'server_version': pack.version,
// // //         'downloaded_at': DateTime.now().millisecondsSinceEpoch,
// // //         'expires_at': null,
// // //       }, conflictAlgorithm: ConflictAlgorithm.replace);

// // //       // Write cards in batches of 100
// // //       final batched = txn.batch();
// // //       for (final (i, card) in cards.indexed) {
// // //         final cardId = card['id'] as String;
// // //         final content = card['content'];
// // //         // content may already be a JSON string or a Map — store as JSON string
// // //         final contentJson = content is String
// // //             ? content
// // //             : jsonEncode(content ?? {});
// // //         batched.insert('pack_cards', {
// // //           'id': cardId,
// // //           'pack_id': pack.id,
// // //           'content_json': contentJson,
// // //           'card_type': card['card_type'] as String? ?? 'truth',
// // //           'difficulty': card['difficulty'] as String? ?? 'mild',
// // //           'sort_order': i,
// // //           'image_path': imageMap[cardId],
// // //         }, conflictAlgorithm: ConflictAlgorithm.replace);
// // //       }
// // //       await batched.commit(noResult: true);
// // //     });
// // //   }

// // //   // ── Sync log ───────────────────────────────────────────────────────────────

// // //   Future<void> _updateSyncLog(String packId, int version) async {
// // //     await _db.db.insert('sync_log', {
// // //       'pack_id': packId,
// // //       'server_version': version,
// // //       'local_version': version,
// // //       'synced_at': DateTime.now().millisecondsSinceEpoch,
// // //     }, conflictAlgorithm: ConflictAlgorithm.replace);
// // //   }

// // //   Future<bool> _isCurrentVersion(String packId, int serverVersion) async {
// // //     final row = await _db.db.query(
// // //       'sync_log',
// // //       where: 'pack_id = ? AND local_version >= ?',
// // //       whereArgs: [packId, serverVersion],
// // //     );
// // //     return row.isNotEmpty;
// // //   }

// // //   // ── Queries ────────────────────────────────────────────────────────────────

// // //   Future<PackDownloadState> getDownloadState(String packId) async {
// // //     if (!_db.isOpen) return PackDownloadState.initial(packId);
// // //     final row = await _db.db.query(
// // //       'sync_log',
// // //       where: 'pack_id = ?',
// // //       whereArgs: [packId],
// // //     );
// // //     if (row.isEmpty) return PackDownloadState.initial(packId);
// // //     return PackDownloadState(
// // //       packId: packId,
// // //       status: DownloadStatus.downloaded,
// // //       progress: 1.0,
// // //       downloadedAt: DateTime.fromMillisecondsSinceEpoch(
// // //         row.first['synced_at'] as int,
// // //       ),
// // //       localVersion: row.first['local_version'] as int?,
// // //     );
// // //   }

// // //   Future<bool> isDownloaded(String packId) async {
// // //     if (!_db.isOpen) return false;
// // //     final row = await _db.db.query(
// // //       'packs',
// // //       where: 'id = ?',
// // //       whereArgs: [packId],
// // //       limit: 1,
// // //     );
// // //     return row.isNotEmpty;
// // //   }

// // //   /// Load all downloaded packs as PackEntity from local SQLite.
// // //   /// Used when offline — network lists are empty but local data still exists.
// // //   Future<List<PackEntity>> getDownloadedPacks() async {
// // //     await _db.ready;
// // //     if (!_db.isOpen) return [];
// // //     final rows = await _db.db.query('packs');
// // //     return rows.map((r) {
// // //       Map<String, dynamic> nameJson = {};
// // //       try {
// // //         nameJson =
// // //             jsonDecode(r['name_json'] as String? ?? '{}')
// // //                 as Map<String, dynamic>;
// // //       } catch (_) {}
// // //       return PackEntity(
// // //         id: r['id'] as String,
// // //         creatorId: '',
// // //         titleJson: nameJson,
// // //         gameType: r['game_type'] as String? ?? 'truth_or_dare',
// // //         language: r['language'] as String? ?? 'en',
// // //         priceMru: r['price'] as int? ?? 0,
// // //         cardCount: 0,
// // //         avgRating: 0,
// // //         totalRatings: 0,
// // //         totalPurchases: 0,
// // //         totalPlays: 0,
// // //         coverImageUrl: r['cover_url'] as String?,
// // //         version: r['server_version'] as int? ?? 1,
// // //         status: PackStatus.approved,
// // //       );
// // //     }).toList();
// // //   }

// // //   Future<List<String>> getDownloadedPackIds() async {
// // //     if (!_db.isOpen) return [];
// // //     final rows = await _db.db.query('packs', columns: ['id']);
// // //     return rows.map((r) => r['id'] as String).toList();
// // //   }

// // //   /// Total disk usage for downloaded pack data in bytes.
// // //   Future<int> getTotalStorageBytes() async {
// // //     final db = _db.db;
// // //     final result = await db.rawQuery(
// // //       'SELECT SUM(LENGTH(content_json)) as total FROM pack_cards',
// // //     );
// // //     return result.first['total'] as int? ?? 0;
// // //   }

// // //   // ── Deletion ───────────────────────────────────────────────────────────────

// // //   Future<void> deleteDownload(String packId) async {
// // //     await _db.db.transaction((txn) async {
// // //       await txn.delete('pack_cards', where: 'pack_id = ?', whereArgs: [packId]);
// // //       await txn.delete('packs', where: 'id = ?', whereArgs: [packId]);
// // //       await txn.delete('sync_log', where: 'pack_id = ?', whereArgs: [packId]);
// // //     });

// // //     // Delete cached images
// // //     try {
// // //       final appDir = await getApplicationDocumentsDirectory();
// // //       final imageDir = Directory(p.join(appDir.path, 'pack_images', packId));
// // //       if (await imageDir.exists()) await imageDir.delete(recursive: true);
// // //     } catch (e) {
// // //       AppLogger.warning(
// // //         'PackDownloadManager: failed to delete images for $packId, $e',
// // //       );
// // //     }

// // //     AppLogger.info('PackDownloadManager: deleted $packId');
// // //   }

// // //   Future<void> deleteExpiredDownloads(
// // //     List<PackPurchase> activePurchases,
// // //   ) async {
// // //     final activeIds = activePurchases.map((p) => p.packId).toSet();
// // //     final downloaded = await getDownloadedPackIds();
// // //     for (final id in downloaded) {
// // //       if (!activeIds.contains(id)) {
// // //         await deleteDownload(id);
// // //       }
// // //     }
// // //   }

// // //   // ── Helpers ────────────────────────────────────────────────────────────────

// // //   List<List<T>> _chunked<T>(List<T> list, int size) {
// // //     final chunks = <List<T>>[];
// // //     for (var i = 0; i < list.length; i += size) {
// // //       chunks.add(list.sublist(i, (i + size).clamp(0, list.length)));
// // //     }
// // //     return chunks;
// // //   }
// // // }

// // import 'dart:async';
// // import 'dart:convert';
// // import 'dart:io';

// // import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart';
// // import 'package:path/path.dart' as p;
// // import 'package:path_provider/path_provider.dart';
// // import 'package:sqflite/sqflite.dart';

// // import '../../../../core/storage/database/app_database.dart';
// // import '../../../../core/utils/app_logger.dart';
// // import '../domain/pack_entity.dart';

// // /// Manages the full offline pack lifecycle:
// // ///   download → atomic SQLite write → availability check → cleanup
// // ///
// // /// Download flow:
// // ///   1. Fetch JSON manifest from Wasabi (download_url on pack)
// // ///   2. Parse cards array from JSON
// // ///   3. Download card images (if any) in parallel, bounded concurrency
// // ///   4. Write pack header + all cards in one SQLite transaction (atomic)
// // ///   5. Update sync_log with server version
// // ///
// // /// Idempotency: re-downloading the same version is a no-op.
// // /// Recovery: failed downloads leave no partial data (transaction rollback).
// // class PackDownloadManager {
// //   PackDownloadManager._();
// //   static final PackDownloadManager _instance = PackDownloadManager._();
// //   static PackDownloadManager get instance => _instance;

// //   final _db = AppDatabase.instance;

// //   // Active downloads: packId → StreamController
// //   final _active = <String, StreamController<PackDownloadState>>{};

// //   // Global progress broadcast (for download list UI)
// //   final _globalCtrl =
// //       StreamController<MapEntry<String, PackDownloadState>>.broadcast();
// //   Stream<MapEntry<String, PackDownloadState>> get globalProgress =>
// //       _globalCtrl.stream;

// //   /// Stream of download state for a specific pack.
// //   Stream<PackDownloadState> progressFor(String packId) {
// //     return _active[packId]?.stream ??
// //         Stream.value(PackDownloadState.initial(packId));
// //   }

// //   // ── Download ───────────────────────────────────────────────────────────────

// //   /// Download a pack for offline use.
// //   /// Returns immediately; progress comes via [progressFor].
// //   /// Safe to call multiple times — duplicate calls for the same pack are ignored.
// //   Future<void> download(PackEntity pack) async {
// //     if (_active.containsKey(pack.id)) {
// //       AppLogger.debug('PackDownloadManager: already downloading ${pack.id}');
// //       return;
// //     }

// //     // Already downloaded at current version?
// //     if (await _isCurrentVersion(pack.id, pack.version)) {
// //       AppLogger.debug(
// //         'PackDownloadManager: pack ${pack.id} already at v${pack.version}',
// //       );
// //       return;
// //     }

// //     final ctrl = StreamController<PackDownloadState>.broadcast();
// //     _active[pack.id] = ctrl;

// //     _doDownload(pack, ctrl).whenComplete(() {
// //       Future.delayed(const Duration(seconds: 2), () {
// //         _active.remove(pack.id)?.close();
// //       });
// //     });
// //   }

// //   Future<void> _doDownload(
// //     PackEntity pack,
// //     StreamController<PackDownloadState> ctrl,
// //   ) async {
// //     void emit(PackDownloadState s) {
// //       if (!ctrl.isClosed) ctrl.add(s);
// //       _globalCtrl.add(MapEntry(pack.id, s));
// //     }

// //     emit(
// //       PackDownloadState(
// //         packId: pack.id,
// //         status: DownloadStatus.downloading,
// //         progress: 0.0,
// //       ),
// //     );

// //     try {
// //       List<Map<String, dynamic>> cards;

// //       if (pack.downloadUrl != null) {
// //         // Fetch manifest from Wasabi
// //         emit(
// //           PackDownloadState(
// //             packId: pack.id,
// //             status: DownloadStatus.downloading,
// //             progress: 0.05,
// //           ),
// //         );
// //         final manifest = await _fetchManifest(pack.downloadUrl!);
// //         cards = (manifest['cards'] as List? ?? []).cast<Map<String, dynamic>>();
// //       } else {
// //         // No Wasabi URL — fetch cards directly from Supabase
// //         emit(
// //           PackDownloadState(
// //             packId: pack.id,
// //             status: DownloadStatus.downloading,
// //             progress: 0.05,
// //           ),
// //         );
// //         final rows = await Supabase.instance.client
// //             .from('pack_cards')
// //             .select('id, content, card_type, difficulty, sort_order')
// //             .eq('pack_id', pack.id)
// //             .order('sort_order');
// //         cards = (rows as List).map((r) {
// //           final content = r['content'];
// //           final contentStr = content is String
// //               ? content
// //               : content is Map
// //               ? jsonEncode(content)
// //               : '{}';
// //           return {
// //             'id': r['id'],
// //             'content': contentStr,
// //             'card_type': r['card_type'],
// //             'difficulty': r['difficulty'] ?? 'mild',
// //             'sort_order': r['sort_order'] ?? 0,
// //           };
// //         }).toList();
// //       }

// //       // Step 2: Download card images if present (bounded parallelism)
// //       final imageMap = <String, String>{}; // cardId → local path
// //       if (cards.any((c) => c['image_url'] != null)) {
// //         await _downloadImages(pack.id, cards, imageMap, (progress) {
// //           emit(
// //             PackDownloadState(
// //               packId: pack.id,
// //               status: DownloadStatus.downloading,
// //               progress: 0.05 + progress * 0.70,
// //             ),
// //           );
// //         });
// //       }

// //       // Step 3: Atomic SQLite write
// //       emit(
// //         PackDownloadState(
// //           packId: pack.id,
// //           status: DownloadStatus.downloading,
// //           progress: 0.85,
// //         ),
// //       );
// //       await _writeToDatabase(pack, cards, imageMap);

// //       // Step 4: Update sync_log
// //       await _updateSyncLog(pack.id, pack.version);

// //       final finalState = PackDownloadState(
// //         packId: pack.id,
// //         status: DownloadStatus.downloaded,
// //         progress: 1.0,
// //         downloadedAt: DateTime.now(),
// //         localVersion: pack.version,
// //       );
// //       emit(finalState);
// //       AppLogger.info(
// //         'PackDownloadManager: ✅ downloaded ${pack.id} v${pack.version}',
// //       );
// //     } catch (e, st) {
// //       AppLogger.error(
// //         'PackDownloadManager: ❌ download failed for ${pack.id}',
// //         error: e,
// //         stackTrace: st,
// //       );
// //       emit(
// //         PackDownloadState(
// //           packId: pack.id,
// //           status: DownloadStatus.failed,
// //           errorMessage: e.toString(),
// //         ),
// //       );
// //     }
// //   }

// //   // ── Manifest fetch ─────────────────────────────────────────────────────────

// //   Future<Map<String, dynamic>> _fetchManifest(String url) async {
// //     final client = HttpClient()
// //       ..connectionTimeout = const Duration(seconds: 30);
// //     try {
// //       final req = await client.getUrl(Uri.parse(url));
// //       final resp = await req.close();
// //       if (resp.statusCode != 200) {
// //         throw Exception('Manifest fetch failed: HTTP ${resp.statusCode}');
// //       }
// //       final body = await resp.transform(utf8.decoder).join();
// //       return jsonDecode(body) as Map<String, dynamic>;
// //     } finally {
// //       client.close();
// //     }
// //   }

// //   // ── Image download ─────────────────────────────────────────────────────────

// //   Future<void> _downloadImages(
// //     String packId,
// //     List<Map<String, dynamic>> cards,
// //     Map<String, String> imageMap,
// //     void Function(double) onProgress,
// //   ) async {
// //     final toDownload = cards
// //         .where((c) => c['image_url'] != null && c['id'] != null)
// //         .toList();

// //     if (toDownload.isEmpty) return;

// //     final dir = await _imageDirectory(packId);
// //     int done = 0;

// //     // Max 4 concurrent image downloads
// //     const concurrency = 4;
// //     final chunks = _chunked(toDownload, concurrency);

// //     for (final chunk in chunks) {
// //       await Future.wait(
// //         chunk.map((card) async {
// //           final cardId = card['id'] as String;
// //           final imageUrl = card['image_url'] as String;
// //           try {
// //             final localPath = await _downloadImage(imageUrl, dir, cardId);
// //             if (localPath != null) imageMap[cardId] = localPath;
// //           } catch (e) {
// //             AppLogger.warning(
// //               'PackDownloadManager: image download failed $cardId, $e',
// //             );
// //           }
// //           done++;
// //           onProgress(done / toDownload.length);
// //         }),
// //       );
// //     }
// //   }

// //   Future<String?> _downloadImage(
// //     String url,
// //     Directory dir,
// //     String cardId,
// //   ) async {
// //     final ext = url.split('.').last.split('?').first;
// //     final file = File(p.join(dir.path, '$cardId.$ext'));
// //     if (await file.exists()) return file.path; // already cached

// //     final client = HttpClient()
// //       ..connectionTimeout = const Duration(seconds: 15);
// //     try {
// //       final req = await client.getUrl(Uri.parse(url));
// //       final resp = await req.close();
// //       if (resp.statusCode != 200) return null;
// //       await resp.pipe(file.openWrite());
// //       return file.path;
// //     } finally {
// //       client.close();
// //     }
// //   }

// //   Future<Directory> _imageDirectory(String packId) async {
// //     final appDir = await getApplicationDocumentsDirectory();
// //     final dir = Directory(p.join(appDir.path, 'pack_images', packId));
// //     await dir.create(recursive: true);
// //     return dir;
// //   }

// //   // ── SQLite write ───────────────────────────────────────────────────────────

// //   Future<void> _writeToDatabase(
// //     PackEntity pack,
// //     List<Map<String, dynamic>> cards,
// //     Map<String, String> imageMap,
// //   ) async {
// //     final db = _db.db;

// //     await db.transaction((txn) async {
// //       // Delete old data for this pack (re-download scenario)
// //       await txn.delete(
// //         'pack_cards',
// //         where: 'pack_id = ?',
// //         whereArgs: [pack.id],
// //       );
// //       await txn.delete('packs', where: 'id = ?', whereArgs: [pack.id]);

// //       // Write pack header
// //       await txn.insert('packs', {
// //         'id': pack.id,
// //         'name_json': jsonEncode(pack.titleJson),
// //         'cover_url': pack.coverImageUrl,
// //         'game_type': pack.gameType,
// //         'language': pack.language,
// //         'price': pack.priceMru,
// //         'server_version': pack.version,
// //         'downloaded_at': DateTime.now().millisecondsSinceEpoch,
// //         'expires_at': null,
// //       }, conflictAlgorithm: ConflictAlgorithm.replace);

// //       // Write cards in batches of 100
// //       final batched = txn.batch();
// //       for (final (i, card) in cards.indexed) {
// //         final cardId = card['id'] as String;
// //         final content = card['content'];
// //         // content may already be a JSON string or a Map — store as JSON string
// //         final contentJson = content is String
// //             ? content
// //             : jsonEncode(content ?? {});
// //         batched.insert('pack_cards', {
// //           'id': cardId,
// //           'pack_id': pack.id,
// //           'content_json': contentJson,
// //           'card_type': card['card_type'] as String? ?? 'truth',
// //           'difficulty': card['difficulty'] as String? ?? 'mild',
// //           'sort_order': i,
// //           'image_path': imageMap[cardId],
// //         }, conflictAlgorithm: ConflictAlgorithm.replace);
// //       }
// //       await batched.commit(noResult: true);
// //     });
// //   }

// //   // ── Sync log ───────────────────────────────────────────────────────────────

// //   Future<void> _updateSyncLog(String packId, int version) async {
// //     await _db.db.insert('sync_log', {
// //       'pack_id': packId,
// //       'server_version': version,
// //       'local_version': version,
// //       'synced_at': DateTime.now().millisecondsSinceEpoch,
// //     }, conflictAlgorithm: ConflictAlgorithm.replace);
// //   }

// //   Future<bool> _isCurrentVersion(String packId, int serverVersion) async {
// //     final row = await _db.db.query(
// //       'sync_log',
// //       where: 'pack_id = ? AND local_version >= ?',
// //       whereArgs: [packId, serverVersion],
// //     );
// //     return row.isNotEmpty;
// //   }

// //   // ── Queries ────────────────────────────────────────────────────────────────

// //   Future<PackDownloadState> getDownloadState(String packId) async {
// //     if (!_db.isOpen) return PackDownloadState.initial(packId);
// //     final row = await _db.db.query(
// //       'sync_log',
// //       where: 'pack_id = ?',
// //       whereArgs: [packId],
// //     );
// //     if (row.isEmpty) return PackDownloadState.initial(packId);
// //     return PackDownloadState(
// //       packId: packId,
// //       status: DownloadStatus.downloaded,
// //       progress: 1.0,
// //       downloadedAt: DateTime.fromMillisecondsSinceEpoch(
// //         row.first['synced_at'] as int,
// //       ),
// //       localVersion: row.first['local_version'] as int?,
// //     );
// //   }

// //   Future<bool> isDownloaded(String packId) async {
// //     if (!_db.isOpen) return false;
// //     final row = await _db.db.query(
// //       'packs',
// //       where: 'id = ?',
// //       whereArgs: [packId],
// //       limit: 1,
// //     );
// //     return row.isNotEmpty;
// //   }

// //   /// Load all downloaded packs as PackEntity from local SQLite.
// //   /// Used when offline — network lists are empty but local data still exists.
// //   Future<List<PackEntity>> getDownloadedPacks() async {
// //     if (!_db.isOpen) return [];
// //     final rows = await _db.db.query('packs');
// //     return rows.map((r) {
// //       Map<String, dynamic> nameJson = {};
// //       try {
// //         nameJson =
// //             jsonDecode(r['name_json'] as String? ?? '{}')
// //                 as Map<String, dynamic>;
// //       } catch (_) {}
// //       return PackEntity(
// //         id: r['id'] as String,
// //         creatorId: '',
// //         titleJson: nameJson,
// //         gameType: r['game_type'] as String? ?? 'truth_or_dare',
// //         language: r['language'] as String? ?? 'en',
// //         priceMru: r['price'] as int? ?? 0,
// //         cardCount: 0,
// //         avgRating: 0,
// //         totalRatings: 0,
// //         totalPurchases: 0,
// //         totalPlays: 0,
// //         coverImageUrl: r['cover_url'] as String?,
// //         version: r['server_version'] as int? ?? 1,
// //         status: PackStatus.approved,
// //       );
// //     }).toList();
// //   }

// //   Future<List<String>> getDownloadedPackIds() async {
// //     if (!_db.isOpen) return [];
// //     final rows = await _db.db.query('packs', columns: ['id']);
// //     return rows.map((r) => r['id'] as String).toList();
// //   }

// //   /// Total disk usage for downloaded pack data in bytes.
// //   Future<int> getTotalStorageBytes() async {
// //     final db = _db.db;
// //     final result = await db.rawQuery(
// //       'SELECT SUM(LENGTH(content_json)) as total FROM pack_cards',
// //     );
// //     return result.first['total'] as int? ?? 0;
// //   }

// //   // ── Deletion ───────────────────────────────────────────────────────────────

// //   Future<void> deleteDownload(String packId) async {
// //     await _db.db.transaction((txn) async {
// //       await txn.delete('pack_cards', where: 'pack_id = ?', whereArgs: [packId]);
// //       await txn.delete('packs', where: 'id = ?', whereArgs: [packId]);
// //       await txn.delete('sync_log', where: 'pack_id = ?', whereArgs: [packId]);
// //     });

// //     // Delete cached images
// //     try {
// //       final appDir = await getApplicationDocumentsDirectory();
// //       final imageDir = Directory(p.join(appDir.path, 'pack_images', packId));
// //       if (await imageDir.exists()) await imageDir.delete(recursive: true);
// //     } catch (e) {
// //       AppLogger.warning(
// //         'PackDownloadManager: failed to delete images for $packId , $e',
// //       );
// //     }

// //     AppLogger.info('PackDownloadManager: deleted $packId');
// //   }

// //   Future<void> deleteExpiredDownloads(
// //     List<PackPurchase> activePurchases,
// //   ) async {
// //     final activeIds = activePurchases.map((p) => p.packId).toSet();
// //     final downloaded = await getDownloadedPackIds();
// //     for (final id in downloaded) {
// //       if (!activeIds.contains(id)) {
// //         await deleteDownload(id);
// //       }
// //     }
// //   }

// //   // ── Helpers ────────────────────────────────────────────────────────────────

// //   List<List<T>> _chunked<T>(List<T> list, int size) {
// //     final chunks = <List<T>>[];
// //     for (var i = 0; i < list.length; i += size) {
// //       chunks.add(list.sublist(i, (i + size).clamp(0, list.length)));
// //     }
// //     return chunks;
// //   }
// // }

// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';

// import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:path/path.dart' as p;
// import 'package:path_provider/path_provider.dart';
// import 'package:sqflite/sqflite.dart';

// import '../../../../core/storage/database/app_database.dart';
// import '../../../../core/utils/app_logger.dart';
// import '../domain/pack_entity.dart';

// /// Manages the full offline pack lifecycle:
// ///   download → atomic SQLite write → availability check → cleanup
// ///
// /// Download flow:
// ///   1. Fetch JSON manifest from Wasabi (download_url on pack)
// ///   2. Parse cards array from JSON
// ///   3. Download card images (if any) in parallel, bounded concurrency
// ///   4. Write pack header + all cards in one SQLite transaction (atomic)
// ///   5. Update sync_log with server version
// ///
// /// Idempotency: re-downloading the same version is a no-op.
// /// Recovery: failed downloads leave no partial data (transaction rollback).
// class PackDownloadManager {
//   PackDownloadManager._();
//   static final PackDownloadManager _instance = PackDownloadManager._();
//   static PackDownloadManager get instance => _instance;

//   final _db = AppDatabase.instance;

//   // Active downloads: packId → StreamController
//   final _active = <String, StreamController<PackDownloadState>>{};

//   // Global progress broadcast (for download list UI)
//   final _globalCtrl =
//       StreamController<MapEntry<String, PackDownloadState>>.broadcast();
//   Stream<MapEntry<String, PackDownloadState>> get globalProgress =>
//       _globalCtrl.stream;

//   /// Stream of download state for a specific pack.
//   Stream<PackDownloadState> progressFor(String packId) {
//     return _active[packId]?.stream ??
//         Stream.value(PackDownloadState.initial(packId));
//   }

//   // ── Download ───────────────────────────────────────────────────────────────

//   /// Download a pack for offline use.
//   /// Returns immediately; progress comes via [progressFor].
//   /// Safe to call multiple times — duplicate calls for the same pack are ignored.
//   Future<void> download(PackEntity pack) async {
//     if (_active.containsKey(pack.id)) {
//       AppLogger.debug('PackDownloadManager: already downloading ${pack.id}');
//       return;
//     }

//     // Already downloaded at current version?
//     if (await _isCurrentVersion(pack.id, pack.version)) {
//       AppLogger.debug(
//         'PackDownloadManager: pack ${pack.id} already at v${pack.version}',
//       );
//       return;
//     }

//     final ctrl = StreamController<PackDownloadState>.broadcast();
//     _active[pack.id] = ctrl;

//     _doDownload(pack, ctrl).whenComplete(() {
//       Future.delayed(const Duration(seconds: 2), () {
//         _active.remove(pack.id)?.close();
//       });
//     });
//   }

//   Future<void> _doDownload(
//     PackEntity pack,
//     StreamController<PackDownloadState> ctrl,
//   ) async {
//     void emit(PackDownloadState s) {
//       if (!ctrl.isClosed) ctrl.add(s);
//       _globalCtrl.add(MapEntry(pack.id, s));
//     }

//     emit(
//       PackDownloadState(
//         packId: pack.id,
//         status: DownloadStatus.downloading,
//         progress: 0.0,
//       ),
//     );

//     try {
//       List<Map<String, dynamic>> cards;

//       if (pack.downloadUrl != null) {
//         // Fetch manifest from Wasabi
//         emit(
//           PackDownloadState(
//             packId: pack.id,
//             status: DownloadStatus.downloading,
//             progress: 0.05,
//           ),
//         );
//         final manifest = await _fetchManifest(pack.downloadUrl!);
//         cards = (manifest['cards'] as List? ?? []).cast<Map<String, dynamic>>();
//       } else {
//         // No Wasabi URL — fetch cards directly from Supabase
//         emit(
//           PackDownloadState(
//             packId: pack.id,
//             status: DownloadStatus.downloading,
//             progress: 0.05,
//           ),
//         );
//         final rows = await Supabase.instance.client
//             .from('pack_cards')
//             .select('id, content, card_type, difficulty, sort_order')
//             .eq('pack_id', pack.id)
//             .order('sort_order');
//         cards = (rows as List).map((r) {
//           final content = r['content'];
//           final contentStr = content is String
//               ? content
//               : content is Map
//               ? jsonEncode(content)
//               : '{}';
//           return {
//             'id': r['id'],
//             'content': contentStr,
//             'card_type': r['card_type'],
//             'difficulty': r['difficulty'] ?? 'mild',
//             'sort_order': r['sort_order'] ?? 0,
//           };
//         }).toList();
//       }

//       // Step 2: Download card images if present (bounded parallelism)
//       final imageMap = <String, String>{}; // cardId → local path
//       if (cards.any((c) => c['image_url'] != null)) {
//         await _downloadImages(pack.id, cards, imageMap, (progress) {
//           emit(
//             PackDownloadState(
//               packId: pack.id,
//               status: DownloadStatus.downloading,
//               progress: 0.05 + progress * 0.70,
//             ),
//           );
//         });
//       }

//       // Step 2b: Download cover image locally
//       String? localCoverPath;
//       if (pack.coverImageUrl != null && pack.coverImageUrl!.isNotEmpty) {
//         try {
//           emit(
//             PackDownloadState(
//               packId: pack.id,
//               status: DownloadStatus.downloading,
//               progress: 0.78,
//             ),
//           );
//           final dir = await _imageDirectory(pack.id);
//           localCoverPath = await _downloadImage(
//             pack.coverImageUrl!,
//             dir,
//             'cover',
//           );
//           AppLogger.info(
//             'PackDownloadManager: cover downloaded → $localCoverPath',
//           );
//         } catch (e) {
//           AppLogger.warning('PackDownloadManager: cover download failed, $e');
//         }
//       }

//       // Step 2c: Download sticker/reaction images if pack has them
//       final stickerPaths = <String>[];
//       if (pack.reactionImageUrls.isNotEmpty) {
//         try {
//           emit(
//             PackDownloadState(
//               packId: pack.id,
//               status: DownloadStatus.downloading,
//               progress: 0.82,
//             ),
//           );
//           final dir = await _imageDirectory(pack.id);
//           for (int i = 0; i < pack.reactionImageUrls.length; i++) {
//             final url = pack.reactionImageUrls[i];
//             final path = await _downloadImage(url, dir, 'sticker_$i');
//             if (path != null) stickerPaths.add(path);
//           }
//           AppLogger.info(
//             'PackDownloadManager: ${stickerPaths.length} stickers downloaded',
//           );
//         } catch (e) {
//           AppLogger.warning('PackDownloadManager: sticker download failed, $e');
//         }
//       }

//       // Step 3: Atomic SQLite write
//       emit(
//         PackDownloadState(
//           packId: pack.id,
//           status: DownloadStatus.downloading,
//           progress: 0.85,
//         ),
//       );
//       await _writeToDatabase(
//         pack,
//         cards,
//         imageMap,
//         localCoverPath: localCoverPath,
//         localStickerPaths: stickerPaths,
//       );

//       // Step 4: Update sync_log
//       await _updateSyncLog(pack.id, pack.version);

//       final finalState = PackDownloadState(
//         packId: pack.id,
//         status: DownloadStatus.downloaded,
//         progress: 1.0,
//         downloadedAt: DateTime.now(),
//         localVersion: pack.version,
//       );
//       emit(finalState);
//       AppLogger.info(
//         'PackDownloadManager: ✅ downloaded ${pack.id} v${pack.version}',
//       );
//     } catch (e, st) {
//       AppLogger.error(
//         'PackDownloadManager: ❌ download failed for ${pack.id}',
//         error: e,
//         stackTrace: st,
//       );
//       emit(
//         PackDownloadState(
//           packId: pack.id,
//           status: DownloadStatus.failed,
//           errorMessage: e.toString(),
//         ),
//       );
//     }
//   }

//   // ── Manifest fetch ─────────────────────────────────────────────────────────

//   Future<Map<String, dynamic>> _fetchManifest(String url) async {
//     final client = HttpClient()
//       ..connectionTimeout = const Duration(seconds: 30);
//     try {
//       final req = await client.getUrl(Uri.parse(url));
//       final resp = await req.close();
//       if (resp.statusCode != 200) {
//         throw Exception('Manifest fetch failed: HTTP ${resp.statusCode}');
//       }
//       final body = await resp.transform(utf8.decoder).join();
//       return jsonDecode(body) as Map<String, dynamic>;
//     } finally {
//       client.close();
//     }
//   }

//   // ── Image download ─────────────────────────────────────────────────────────

//   Future<void> _downloadImages(
//     String packId,
//     List<Map<String, dynamic>> cards,
//     Map<String, String> imageMap,
//     void Function(double) onProgress,
//   ) async {
//     final toDownload = cards
//         .where((c) => c['image_url'] != null && c['id'] != null)
//         .toList();

//     if (toDownload.isEmpty) return;

//     final dir = await _imageDirectory(packId);
//     int done = 0;

//     // Max 4 concurrent image downloads
//     const concurrency = 4;
//     final chunks = _chunked(toDownload, concurrency);

//     for (final chunk in chunks) {
//       await Future.wait(
//         chunk.map((card) async {
//           final cardId = card['id'] as String;
//           final imageUrl = card['image_url'] as String;
//           try {
//             final localPath = await _downloadImage(imageUrl, dir, cardId);
//             if (localPath != null) imageMap[cardId] = localPath;
//           } catch (e) {
//             AppLogger.warning(
//               'PackDownloadManager: image download failed $cardId, $e',
//             );
//           }
//           done++;
//           onProgress(done / toDownload.length);
//         }),
//       );
//     }
//   }

//   Future<String?> _downloadImage(
//     String url,
//     Directory dir,
//     String cardId,
//   ) async {
//     final ext = url.split('.').last.split('?').first;
//     final file = File(p.join(dir.path, '$cardId.$ext'));
//     if (await file.exists()) return file.path; // already cached

//     final client = HttpClient()
//       ..connectionTimeout = const Duration(seconds: 15);
//     try {
//       final req = await client.getUrl(Uri.parse(url));
//       final resp = await req.close();
//       if (resp.statusCode != 200) return null;
//       await resp.pipe(file.openWrite());
//       return file.path;
//     } finally {
//       client.close();
//     }
//   }

//   Future<Directory> _imageDirectory(String packId) async {
//     final appDir = await getApplicationDocumentsDirectory();
//     final dir = Directory(p.join(appDir.path, 'pack_images', packId));
//     await dir.create(recursive: true);
//     return dir;
//   }

//   // ── SQLite write ───────────────────────────────────────────────────────────

//   Future<void> _writeToDatabase(
//     PackEntity pack,
//     List<Map<String, dynamic>> cards,
//     Map<String, String> imageMap, {
//     String? localCoverPath,
//     List<String> localStickerPaths = const [],
//   }) async {
//     final db = _db.db;

//     await db.transaction((txn) async {
//       // Delete old data for this pack (re-download scenario)
//       await txn.delete(
//         'pack_cards',
//         where: 'pack_id = ?',
//         whereArgs: [pack.id],
//       );
//       await txn.delete('packs', where: 'id = ?', whereArgs: [pack.id]);

//       // Write pack header
//       await txn.insert('packs', {
//         'id': pack.id,
//         'name_json': jsonEncode(pack.titleJson),
//         'cover_url': pack.coverImageUrl,
//         'local_cover_path': localCoverPath,
//         'local_sticker_paths': localStickerPaths.isNotEmpty
//             ? jsonEncode(localStickerPaths)
//             : null,
//         'game_type': pack.gameType,
//         'language': pack.language,
//         'price': pack.priceMru,
//         'server_version': pack.version,
//         'downloaded_at': DateTime.now().millisecondsSinceEpoch,
//         'expires_at': null,
//       }, conflictAlgorithm: ConflictAlgorithm.replace);

//       // Write cards in batches of 100
//       final batched = txn.batch();
//       for (final (i, card) in cards.indexed) {
//         final cardId = card['id'] as String;
//         final content = card['content'];
//         // content may already be a JSON string or a Map — store as JSON string
//         final contentJson = content is String
//             ? content
//             : jsonEncode(content ?? {});
//         batched.insert('pack_cards', {
//           'id': cardId,
//           'pack_id': pack.id,
//           'content_json': contentJson,
//           'card_type': card['card_type'] as String? ?? 'truth',
//           'difficulty': card['difficulty'] as String? ?? 'mild',
//           'sort_order': i,
//           'image_path': imageMap[cardId],
//         }, conflictAlgorithm: ConflictAlgorithm.replace);
//       }
//       await batched.commit(noResult: true);
//     });
//   }

//   // ── Sync log ───────────────────────────────────────────────────────────────

//   Future<void> _updateSyncLog(String packId, int version) async {
//     await _db.db.insert('sync_log', {
//       'pack_id': packId,
//       'server_version': version,
//       'local_version': version,
//       'synced_at': DateTime.now().millisecondsSinceEpoch,
//     }, conflictAlgorithm: ConflictAlgorithm.replace);
//   }

//   Future<bool> _isCurrentVersion(String packId, int serverVersion) async {
//     final row = await _db.db.query(
//       'sync_log',
//       where: 'pack_id = ? AND local_version >= ?',
//       whereArgs: [packId, serverVersion],
//     );
//     return row.isNotEmpty;
//   }

//   // ── Queries ────────────────────────────────────────────────────────────────

//   Future<PackDownloadState> getDownloadState(String packId) async {
//     if (!_db.isOpen) return PackDownloadState.initial(packId);
//     final row = await _db.db.query(
//       'sync_log',
//       where: 'pack_id = ?',
//       whereArgs: [packId],
//     );
//     if (row.isEmpty) return PackDownloadState.initial(packId);
//     return PackDownloadState(
//       packId: packId,
//       status: DownloadStatus.downloaded,
//       progress: 1.0,
//       downloadedAt: DateTime.fromMillisecondsSinceEpoch(
//         row.first['synced_at'] as int,
//       ),
//       localVersion: row.first['local_version'] as int?,
//     );
//   }

//   Future<bool> isDownloaded(String packId) async {
//     if (!_db.isOpen) return false;
//     final row = await _db.db.query(
//       'packs',
//       where: 'id = ?',
//       whereArgs: [packId],
//       limit: 1,
//     );
//     return row.isNotEmpty;
//   }

//   /// Load all downloaded packs as PackEntity from local SQLite.
//   /// Used when offline — network lists are empty but local data still exists.
//   Future<List<PackEntity>> getDownloadedPacks() async {
//     if (!_db.isOpen) return [];
//     final rows = await _db.db.query('packs');
//     return rows.map((r) {
//       Map<String, dynamic> nameJson = {};
//       try {
//         nameJson =
//             jsonDecode(r['name_json'] as String? ?? '{}')
//                 as Map<String, dynamic>;
//       } catch (_) {}
//       return PackEntity(
//         id: r['id'] as String,
//         creatorId: '',
//         titleJson: nameJson,
//         gameType: r['game_type'] as String? ?? 'truth_or_dare',
//         language: r['language'] as String? ?? 'en',
//         priceMru: r['price'] as int? ?? 0,
//         cardCount: 0,
//         avgRating: 0,
//         totalRatings: 0,
//         totalPurchases: 0,
//         totalPlays: 0,
//         coverImageUrl: r['cover_url'] as String?,
//         version: r['server_version'] as int? ?? 1,
//         status: PackStatus.approved,
//       );
//     }).toList();
//   }

//   Future<List<String>> getDownloadedPackIds() async {
//     if (!_db.isOpen) return [];
//     final rows = await _db.db.query('packs', columns: ['id']);
//     return rows.map((r) => r['id'] as String).toList();
//   }

//   /// Total disk usage for downloaded pack data in bytes.
//   Future<int> getTotalStorageBytes() async {
//     final db = _db.db;
//     final result = await db.rawQuery(
//       'SELECT SUM(LENGTH(content_json)) as total FROM pack_cards',
//     );
//     return result.first['total'] as int? ?? 0;
//   }

//   // ── Deletion ───────────────────────────────────────────────────────────────

//   Future<void> deleteDownload(String packId) async {
//     await _db.db.transaction((txn) async {
//       await txn.delete('pack_cards', where: 'pack_id = ?', whereArgs: [packId]);
//       await txn.delete('packs', where: 'id = ?', whereArgs: [packId]);
//       await txn.delete('sync_log', where: 'pack_id = ?', whereArgs: [packId]);
//     });

//     // Delete cached images
//     try {
//       final appDir = await getApplicationDocumentsDirectory();
//       final imageDir = Directory(p.join(appDir.path, 'pack_images', packId));
//       if (await imageDir.exists()) await imageDir.delete(recursive: true);
//     } catch (e) {
//       AppLogger.warning(
//         'PackDownloadManager: failed to delete images for $packId, $e',
//       );
//     }

//     AppLogger.info('PackDownloadManager: deleted $packId');
//   }

//   Future<void> deleteExpiredDownloads(
//     List<PackPurchase> activePurchases,
//   ) async {
//     final activeIds = activePurchases.map((p) => p.packId).toSet();
//     final downloaded = await getDownloadedPackIds();
//     for (final id in downloaded) {
//       if (!activeIds.contains(id)) {
//         await deleteDownload(id);
//       }
//     }
//   }

//   // ── Helpers ────────────────────────────────────────────────────────────────

//   List<List<T>> _chunked<T>(List<T> list, int size) {
//     final chunks = <List<T>>[];
//     for (var i = 0; i < list.length; i += size) {
//       chunks.add(list.sublist(i, (i + size).clamp(0, list.length)));
//     }
//     return chunks;
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/storage/database/app_database.dart';
import '../../../../core/utils/app_logger.dart';
import '../domain/pack_entity.dart';

/// Manages the full offline pack lifecycle:
///   download → atomic SQLite write → availability check → cleanup
///
/// Download flow:
///   1. Fetch JSON manifest from Wasabi (download_url on pack)
///   2. Parse cards array from JSON
///   3. Download card images (if any) in parallel, bounded concurrency
///   4. Write pack header + all cards in one SQLite transaction (atomic)
///   5. Update sync_log with server version
///
/// Idempotency: re-downloading the same version is a no-op.
/// Recovery: failed downloads leave no partial data (transaction rollback).
class PackDownloadManager {
  PackDownloadManager._();
  static final PackDownloadManager _instance = PackDownloadManager._();
  static PackDownloadManager get instance => _instance;

  final _db = AppDatabase.instance;

  // Active downloads: packId → StreamController
  final _active = <String, StreamController<PackDownloadState>>{};

  // Global progress broadcast (for download list UI)
  final _globalCtrl =
      StreamController<MapEntry<String, PackDownloadState>>.broadcast();
  Stream<MapEntry<String, PackDownloadState>> get globalProgress =>
      _globalCtrl.stream;

  /// Stream of download state for a specific pack.
  Stream<PackDownloadState> progressFor(String packId) {
    return _active[packId]?.stream ??
        Stream.value(PackDownloadState.initial(packId));
  }

  // ── Download ───────────────────────────────────────────────────────────────

  /// Download a pack for offline use.
  /// Returns immediately; progress comes via [progressFor].
  /// Safe to call multiple times — duplicate calls for the same pack are ignored.
  Future<void> download(PackEntity pack) async {
    if (_active.containsKey(pack.id)) {
      AppLogger.debug('PackDownloadManager: already downloading ${pack.id}');
      return;
    }

    // Already downloaded at current version?
    if (await _isCurrentVersion(pack.id, pack.version)) {
      AppLogger.debug(
        'PackDownloadManager: pack ${pack.id} already at v${pack.version}',
      );
      return;
    }

    final ctrl = StreamController<PackDownloadState>.broadcast();
    _active[pack.id] = ctrl;

    _doDownload(pack, ctrl).whenComplete(() {
      Future.delayed(const Duration(seconds: 2), () {
        _active.remove(pack.id)?.close();
      });
    });
  }

  Future<void> _doDownload(
    PackEntity pack,
    StreamController<PackDownloadState> ctrl,
  ) async {
    void emit(PackDownloadState s) {
      if (!ctrl.isClosed) ctrl.add(s);
      _globalCtrl.add(MapEntry(pack.id, s));
    }

    emit(
      PackDownloadState(
        packId: pack.id,
        status: DownloadStatus.downloading,
        progress: 0.0,
      ),
    );

    try {
      List<Map<String, dynamic>> cards;

      if (pack.downloadUrl != null) {
        // Fetch manifest from Wasabi
        emit(
          PackDownloadState(
            packId: pack.id,
            status: DownloadStatus.downloading,
            progress: 0.05,
          ),
        );
        final manifest = await _fetchManifest(pack.downloadUrl!);
        cards = (manifest['cards'] as List? ?? []).cast<Map<String, dynamic>>();
      } else {
        // No Wasabi URL — fetch cards directly from Supabase
        emit(
          PackDownloadState(
            packId: pack.id,
            status: DownloadStatus.downloading,
            progress: 0.05,
          ),
        );
        final rows = await Supabase.instance.client
            .from('pack_cards')
            .select('id, content, card_type, difficulty, sort_order')
            .eq('pack_id', pack.id)
            .order('sort_order');
        cards = (rows as List).map((r) {
          final content = r['content'];
          final contentStr = content is String
              ? content
              : content is Map
              ? jsonEncode(content)
              : '{}';
          return {
            'id': r['id'],
            'content': contentStr,
            'card_type': r['card_type'],
            'difficulty': r['difficulty'] ?? 'mild',
            'sort_order': r['sort_order'] ?? 0,
          };
        }).toList();
      }

      // Step 2: Download card images if present (bounded parallelism)
      final imageMap = <String, String>{}; // cardId → local path
      if (cards.any((c) => c['image_url'] != null)) {
        await _downloadImages(pack.id, cards, imageMap, (progress) {
          emit(
            PackDownloadState(
              packId: pack.id,
              status: DownloadStatus.downloading,
              progress: 0.05 + progress * 0.70,
            ),
          );
        });
      }

      // Step 2b: Download cover image locally
      String? localCoverPath;
      if (pack.coverImageUrl != null && pack.coverImageUrl!.isNotEmpty) {
        try {
          emit(
            PackDownloadState(
              packId: pack.id,
              status: DownloadStatus.downloading,
              progress: 0.78,
            ),
          );
          final dir = await _imageDirectory(pack.id);
          localCoverPath = await _downloadImage(
            pack.coverImageUrl!,
            dir,
            'cover',
          );
          AppLogger.info(
            'PackDownloadManager: cover downloaded → $localCoverPath',
          );
        } catch (e) {
          AppLogger.warning('PackDownloadManager: cover download failed, $e');
        }
      }

      // Step 2c: Download sticker/reaction images if pack has them
      final stickerPaths = <String>[];
      if (pack.reactionImageUrls.isNotEmpty) {
        try {
          emit(
            PackDownloadState(
              packId: pack.id,
              status: DownloadStatus.downloading,
              progress: 0.82,
            ),
          );
          final dir = await _imageDirectory(pack.id);
          for (int i = 0; i < pack.reactionImageUrls.length; i++) {
            final url = pack.reactionImageUrls[i];
            final path = await _downloadImage(url, dir, 'sticker_$i');
            if (path != null) stickerPaths.add(path);
          }
          AppLogger.info(
            'PackDownloadManager: ${stickerPaths.length} stickers downloaded',
          );
        } catch (e) {
          AppLogger.warning('PackDownloadManager: sticker download failed, $e');
        }
      }

      // Step 3: Atomic SQLite write
      emit(
        PackDownloadState(
          packId: pack.id,
          status: DownloadStatus.downloading,
          progress: 0.85,
        ),
      );
      await _writeToDatabase(
        pack,
        cards,
        imageMap,
        localCoverPath: localCoverPath,
        localStickerPaths: stickerPaths,
      );

      // Step 4: Update sync_log
      await _updateSyncLog(pack.id, pack.version);

      final finalState = PackDownloadState(
        packId: pack.id,
        status: DownloadStatus.downloaded,
        progress: 1.0,
        downloadedAt: DateTime.now(),
        localVersion: pack.version,
      );
      emit(finalState);
      AppLogger.info(
        'PackDownloadManager: ✅ downloaded ${pack.id} v${pack.version}',
      );
    } catch (e, st) {
      AppLogger.error(
        'PackDownloadManager: ❌ download failed for ${pack.id}',
        error: e,
        stackTrace: st,
      );
      emit(
        PackDownloadState(
          packId: pack.id,
          status: DownloadStatus.failed,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  // ── Manifest fetch ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _fetchManifest(String url) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30);
    try {
      final req = await client.getUrl(Uri.parse(url));
      final resp = await req.close();
      if (resp.statusCode != 200) {
        throw Exception('Manifest fetch failed: HTTP ${resp.statusCode}');
      }
      final body = await resp.transform(utf8.decoder).join();
      return jsonDecode(body) as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }

  // ── Image download ─────────────────────────────────────────────────────────

  Future<void> _downloadImages(
    String packId,
    List<Map<String, dynamic>> cards,
    Map<String, String> imageMap,
    void Function(double) onProgress,
  ) async {
    final toDownload = cards
        .where((c) => c['image_url'] != null && c['id'] != null)
        .toList();

    if (toDownload.isEmpty) return;

    final dir = await _imageDirectory(packId);
    int done = 0;

    // Max 4 concurrent image downloads
    const concurrency = 4;
    final chunks = _chunked(toDownload, concurrency);

    for (final chunk in chunks) {
      await Future.wait(
        chunk.map((card) async {
          final cardId = card['id'] as String;
          final imageUrl = card['image_url'] as String;
          try {
            final localPath = await _downloadImage(imageUrl, dir, cardId);
            if (localPath != null) imageMap[cardId] = localPath;
          } catch (e) {
            AppLogger.warning(
              'PackDownloadManager: image download failed $cardId, $e',
            );
          }
          done++;
          onProgress(done / toDownload.length);
        }),
      );
    }
  }

  Future<String?> _downloadImage(
    String url,
    Directory dir,
    String cardId,
  ) async {
    // Safely derive extension: take path segment after last dot, only if ≤5 chars
    // e.g. "photo.jpg?v=1" → "jpg", "photo-abc" → "jpg" (fallback)
    String ext = 'jpg';
    try {
      final uri = Uri.parse(url);
      final lastSeg = uri.pathSegments.last; // e.g. "photo-xyz.jpg"
      final dotIdx = lastSeg.lastIndexOf('.');
      final candidate = dotIdx >= 0 ? lastSeg.substring(dotIdx + 1) : '';
      if (candidate.isNotEmpty &&
          candidate.length <= 5 &&
          !candidate.contains('/') &&
          !candidate.contains('-')) {
        ext = candidate;
      }
    } catch (_) {}
    final file = File(p.join(dir.path, '$cardId.$ext'));
    if (await file.exists()) return file.path; // already cached

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.getUrl(Uri.parse(url));
      final resp = await req.close();
      if (resp.statusCode != 200) return null;
      await resp.pipe(file.openWrite());
      return file.path;
    } finally {
      client.close();
    }
  }

  Future<Directory> _imageDirectory(String packId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'pack_images', packId));
    await dir.create(recursive: true);
    return dir;
  }

  // ── SQLite write ───────────────────────────────────────────────────────────

  Future<void> _writeToDatabase(
    PackEntity pack,
    List<Map<String, dynamic>> cards,
    Map<String, String> imageMap, {
    String? localCoverPath,
    List<String> localStickerPaths = const [],
  }) async {
    final db = _db.db;

    await db.transaction((txn) async {
      // Delete old data for this pack (re-download scenario)
      await txn.delete(
        'pack_cards',
        where: 'pack_id = ?',
        whereArgs: [pack.id],
      );
      await txn.delete('packs', where: 'id = ?', whereArgs: [pack.id]);

      // Write pack header
      await txn.insert('packs', {
        'id': pack.id,
        'name_json': jsonEncode(pack.titleJson),
        'cover_url': pack.coverImageUrl,
        'local_cover_path': localCoverPath,
        'local_sticker_paths': localStickerPaths.isNotEmpty
            ? jsonEncode(localStickerPaths)
            : null,
        'game_type': pack.gameType,
        'language': pack.language,
        'price': pack.priceMru,
        'server_version': pack.version,
        'downloaded_at': DateTime.now().millisecondsSinceEpoch,
        'expires_at': null,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Write cards in batches of 100
      final batched = txn.batch();
      for (final (i, card) in cards.indexed) {
        final cardId = card['id'] as String;
        final content = card['content'];
        // content may already be a JSON string or a Map — store as JSON string
        final contentJson = content is String
            ? content
            : jsonEncode(content ?? {});
        batched.insert('pack_cards', {
          'id': cardId,
          'pack_id': pack.id,
          'content_json': contentJson,
          'card_type': card['card_type'] as String? ?? 'truth',
          'difficulty': card['difficulty'] as String? ?? 'mild',
          'sort_order': i,
          'image_path': imageMap[cardId],
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batched.commit(noResult: true);
    });
  }

  // ── Sync log ───────────────────────────────────────────────────────────────

  Future<void> _updateSyncLog(String packId, int version) async {
    await _db.db.insert('sync_log', {
      'pack_id': packId,
      'server_version': version,
      'local_version': version,
      'synced_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> _isCurrentVersion(String packId, int serverVersion) async {
    final row = await _db.db.query(
      'sync_log',
      where: 'pack_id = ? AND local_version >= ?',
      whereArgs: [packId, serverVersion],
    );
    return row.isNotEmpty;
  }

  // ── Queries ────────────────────────────────────────────────────────────────

  Future<PackDownloadState> getDownloadState(String packId) async {
    if (!_db.isOpen) return PackDownloadState.initial(packId);
    final row = await _db.db.query(
      'sync_log',
      where: 'pack_id = ?',
      whereArgs: [packId],
    );
    if (row.isEmpty) return PackDownloadState.initial(packId);
    return PackDownloadState(
      packId: packId,
      status: DownloadStatus.downloaded,
      progress: 1.0,
      downloadedAt: DateTime.fromMillisecondsSinceEpoch(
        row.first['synced_at'] as int,
      ),
      localVersion: row.first['local_version'] as int?,
    );
  }

  Future<bool> isDownloaded(String packId) async {
    if (!_db.isOpen) return false;
    final row = await _db.db.query(
      'packs',
      where: 'id = ?',
      whereArgs: [packId],
      limit: 1,
    );
    return row.isNotEmpty;
  }

  /// Load all downloaded packs as PackEntity from local SQLite.
  /// Used when offline — network lists are empty but local data still exists.
  Future<List<PackEntity>> getDownloadedPacks() async {
    if (!_db.isOpen) return [];
    final rows = await _db.db.query('packs');
    return rows.map((r) {
      Map<String, dynamic> nameJson = {};
      try {
        nameJson =
            jsonDecode(r['name_json'] as String? ?? '{}')
                as Map<String, dynamic>;
      } catch (_) {}
      return PackEntity(
        id: r['id'] as String,
        creatorId: '',
        titleJson: nameJson,
        gameType: r['game_type'] as String? ?? 'truth_or_dare',
        language: r['language'] as String? ?? 'en',
        priceMru: r['price'] as int? ?? 0,
        cardCount: 0,
        avgRating: 0,
        totalRatings: 0,
        totalPurchases: 0,
        totalPlays: 0,
        coverImageUrl: r['cover_url'] as String?,
        version: r['server_version'] as int? ?? 1,
        status: PackStatus.approved,
      );
    }).toList();
  }

  Future<List<String>> getDownloadedPackIds() async {
    if (!_db.isOpen) return [];
    final rows = await _db.db.query('packs', columns: ['id']);
    return rows.map((r) => r['id'] as String).toList();
  }

  /// Total disk usage for downloaded pack data in bytes.
  Future<int> getTotalStorageBytes() async {
    final db = _db.db;
    final result = await db.rawQuery(
      'SELECT SUM(LENGTH(content_json)) as total FROM pack_cards',
    );
    return result.first['total'] as int? ?? 0;
  }

  // ── Deletion ───────────────────────────────────────────────────────────────

  Future<void> deleteDownload(String packId) async {
    await _db.db.transaction((txn) async {
      await txn.delete('pack_cards', where: 'pack_id = ?', whereArgs: [packId]);
      await txn.delete('packs', where: 'id = ?', whereArgs: [packId]);
      await txn.delete('sync_log', where: 'pack_id = ?', whereArgs: [packId]);
    });

    // Delete cached images
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory(p.join(appDir.path, 'pack_images', packId));
      if (await imageDir.exists()) await imageDir.delete(recursive: true);
    } catch (e) {
      AppLogger.warning(
        'PackDownloadManager: failed to delete images for $packId, $e',
      );
    }

    AppLogger.info('PackDownloadManager: deleted $packId');
  }

  Future<void> deleteExpiredDownloads(
    List<PackPurchase> activePurchases,
  ) async {
    final activeIds = activePurchases.map((p) => p.packId).toSet();
    final downloaded = await getDownloadedPackIds();
    for (final id in downloaded) {
      if (!activeIds.contains(id)) {
        await deleteDownload(id);
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<List<T>> _chunked<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, (i + size).clamp(0, list.length)));
    }
    return chunks;
  }
}
