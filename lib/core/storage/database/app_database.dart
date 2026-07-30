// // // // // // // // // import 'package:sqflite/sqflite.dart';
// // // // // // // // // import 'package:path/path.dart' as p;

// // // // // // // // // import '../../utils/app_logger.dart';
// // // // // // // // // import '../../../features/offline/data/offline_repository.dart' show OfflineRepository;

// // // // // // // // // /// Offline sessions schema — referenced by AppDatabase migration v2.
// // // // // // // // // abstract class OfflineSessionsMigration {
// // // // // // // // //   static const schema = OfflineRepository.schemaV2;
// // // // // // // // // }

// // // // // // // // // /// SQLite database singleton with versioned migrations.
// // // // // // // // // ///
// // // // // // // // // /// Stores: downloaded pack cards, purchase metadata, offline sync log.
// // // // // // // // // /// All game and social data lives in Supabase — SQLite is offline-only.
// // // // // // // // // class AppDatabase {
// // // // // // // // //   AppDatabase._();
// // // // // // // // //   static final AppDatabase instance = AppDatabase._();

// // // // // // // // //   static const _dbName    = 'jma3a.db';
// // // // // // // // //   static const _dbVersion = 2;

// // // // // // // // //   Database? _db;
// // // // // // // // //   Database get db {
// // // // // // // // //     assert(_db != null, 'AppDatabase not opened. Call open() first.');
// // // // // // // // //     return _db!;
// // // // // // // // //   }

// // // // // // // // //   bool get isOpen => _db?.isOpen ?? false;

// // // // // // // // //   Future<void> open() async {
// // // // // // // // //     if (isOpen) return;

// // // // // // // // //     final dbPath = p.join(await getDatabasesPath(), _dbName);

// // // // // // // // //     _db = await openDatabase(
// // // // // // // // //       dbPath,
// // // // // // // // //       version: _dbVersion,
// // // // // // // // //       onCreate: _onCreate,
// // // // // // // // //       onUpgrade: _onUpgrade,
// // // // // // // // //       onConfigure: (db) async {
// // // // // // // // //         // Enable foreign key enforcement
// // // // // // // // //         await db.execute('PRAGMA foreign_keys = ON');
// // // // // // // // //         // Write-ahead logging for better concurrent read performance
// // // // // // // // //         await db.execute('PRAGMA journal_mode = WAL');
// // // // // // // // //       },
// // // // // // // // //     );

// // // // // // // // //     AppLogger.info('SQLite database opened: $dbPath (v$_dbVersion)');
// // // // // // // // //   }

// // // // // // // // //   // ── Schema creation ────────────────────────────────────────────────────
// // // // // // // // //   Future<void> _onCreate(Database db, int version) async {
// // // // // // // // //     AppLogger.info('Creating SQLite schema v$version');
// // // // // // // // //     await _runMigration(db, version);
// // // // // // // // //   }

// // // // // // // // //   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
// // // // // // // // //     AppLogger.info('Upgrading SQLite $oldVersion → $newVersion');
// // // // // // // // //     for (var v = oldVersion + 1; v <= newVersion; v++) {
// // // // // // // // //       await _runMigration(db, v);
// // // // // // // // //     }
// // // // // // // // //   }

// // // // // // // // //   Future<void> _runMigration(Database db, int version) async {
// // // // // // // // //     switch (version) {
// // // // // // // // //       case 1:
// // // // // // // // //         await _migration001(db);
// // // // // // // // //       case 2:
// // // // // // // // //         await _migration002(db);
// // // // // // // // //     }
// // // // // // // // //   }

// // // // // // // // //   Future<void> _migration002(Database db) async {
// // // // // // // // //     await db.execute(OfflineSessionsMigration.schema);
// // // // // // // // //     AppLogger.info('Migration 002: offline_sessions applied');
// // // // // // // // //   }

// // // // // // // // //   // ── Migration 001: Initial schema ──────────────────────────────────────
// // // // // // // // //   Future<void> _migration001(Database db) async {
// // // // // // // // //     final batch = db.batch();

// // // // // // // // //     // Downloaded packs (header only — cards in pack_cards table)
// // // // // // // // //     batch.execute('''
// // // // // // // // //       CREATE TABLE IF NOT EXISTS packs (
// // // // // // // // //         id            TEXT PRIMARY KEY,
// // // // // // // // //         name_json     TEXT NOT NULL,
// // // // // // // // //         cover_url     TEXT,
// // // // // // // // //         game_type     TEXT NOT NULL,
// // // // // // // // //         language      TEXT NOT NULL DEFAULT 'en',
// // // // // // // // //         price         INTEGER NOT NULL DEFAULT 0,
// // // // // // // // //         server_version INTEGER NOT NULL DEFAULT 1,
// // // // // // // // //         downloaded_at INTEGER NOT NULL,
// // // // // // // // //         expires_at    INTEGER
// // // // // // // // //       )
// // // // // // // // //     ''');

// // // // // // // // //     // Individual cards for each downloaded pack
// // // // // // // // //     batch.execute('''
// // // // // // // // //       CREATE TABLE IF NOT EXISTS pack_cards (
// // // // // // // // //         id           TEXT PRIMARY KEY,
// // // // // // // // //         pack_id      TEXT NOT NULL REFERENCES packs(id) ON DELETE CASCADE,
// // // // // // // // //         content_json TEXT NOT NULL,
// // // // // // // // //         card_type    TEXT NOT NULL,
// // // // // // // // //         difficulty   TEXT NOT NULL DEFAULT 'mild',
// // // // // // // // //         sort_order   INTEGER NOT NULL DEFAULT 0,
// // // // // // // // //         image_path   TEXT
// // // // // // // // //       )
// // // // // // // // //     ''');

// // // // // // // // //     // Alias view for TodRepository compatibility
// // // // // // // // //     batch.execute('''
// // // // // // // // //       CREATE VIEW IF NOT EXISTS pack_cards_cache AS
// // // // // // // // //       SELECT id, pack_id, content_json, card_type, difficulty, sort_order, image_path
// // // // // // // // //       FROM pack_cards
// // // // // // // // //     ''');

// // // // // // // // //     batch.execute(
// // // // // // // // //       'CREATE INDEX IF NOT EXISTS idx_cards_pack ON pack_cards(pack_id, sort_order)',
// // // // // // // // //     );

// // // // // // // // //     // Local mirror of server purchase records (for expiry checking offline)
// // // // // // // // //     batch.execute('''
// // // // // // // // //       CREATE TABLE IF NOT EXISTS purchases (
// // // // // // // // //         pack_id      TEXT PRIMARY KEY REFERENCES packs(id) ON DELETE CASCADE,
// // // // // // // // //         purchased_at INTEGER NOT NULL,
// // // // // // // // //         expires_at   INTEGER NOT NULL
// // // // // // // // //       )
// // // // // // // // //     ''');

// // // // // // // // //     // Sync log: tracks which packs need re-download
// // // // // // // // //     batch.execute('''
// // // // // // // // //       CREATE TABLE IF NOT EXISTS sync_log (
// // // // // // // // //         pack_id        TEXT PRIMARY KEY,
// // // // // // // // //         server_version INTEGER NOT NULL,
// // // // // // // // //         local_version  INTEGER NOT NULL,
// // // // // // // // //         synced_at      INTEGER NOT NULL
// // // // // // // // //       )
// // // // // // // // //     ''');

// // // // // // // // //     await batch.commit(noResult: true);
// // // // // // // // //     AppLogger.info('Migration 001 applied');
// // // // // // // // //   }

// // // // // // // // //   Future<void> close() async {
// // // // // // // // //     await _db?.close();
// // // // // // // // //     _db = null;
// // // // // // // // //   }
// // // // // // // // // }

// // // // // // // // import 'dart:io';

// // // // // // // // import 'package:sqflite/sqflite.dart';
// // // // // // // // import 'package:path/path.dart' as p;

// // // // // // // // import '../../utils/app_logger.dart';
// // // // // // // // import '../../../features/offline/data/offline_repository.dart'
// // // // // // // //     show OfflineRepository;

// // // // // // // // /// Offline sessions schema — referenced by AppDatabase migration v2.
// // // // // // // // abstract class OfflineSessionsMigration {
// // // // // // // //   static const schema = OfflineRepository.schemaV2;
// // // // // // // // }

// // // // // // // // /// SQLite database singleton with versioned migrations.
// // // // // // // // ///
// // // // // // // // /// Stores: downloaded pack cards, purchase metadata, offline sync log.
// // // // // // // // /// All game and social data lives in Supabase — SQLite is offline-only.
// // // // // // // // class AppDatabase {
// // // // // // // //   AppDatabase._();
// // // // // // // //   static final AppDatabase instance = AppDatabase._();

// // // // // // // //   static const _dbName = 'jma3a.db';
// // // // // // // //   static const _dbVersion = 2;

// // // // // // // //   Database? _db;

// // // // // // // //   Database get db {
// // // // // // // //     if (_db == null) {
// // // // // // // //       throw StateError('AppDatabase not opened. Call open() first.');
// // // // // // // //     }
// // // // // // // //     return _db!;
// // // // // // // //   }

// // // // // // // //   bool get isOpen => _db?.isOpen ?? false;

// // // // // // // //   // Future<void> open() async {
// // // // // // // //   //   if (isOpen) return;

// // // // // // // //   //   try {
// // // // // // // //   //     final dbPath = p.join(await getDatabasesPath(), _dbName);

// // // // // // // //   //     _db = await openDatabase(
// // // // // // // //   //       dbPath,
// // // // // // // //   //       version: _dbVersion,
// // // // // // // //   //       onCreate: _onCreate,
// // // // // // // //   //       onUpgrade: _onUpgrade,
// // // // // // // //   //       onConfigure: (db) async {
// // // // // // // //   //         await db.execute('PRAGMA foreign_keys = ON');
// // // // // // // //   //         await db.execute('PRAGMA journal_mode = WAL');
// // // // // // // //   //       },
// // // // // // // //   //     );

// // // // // // // //   //     AppLogger.info('SQLite database opened: $dbPath (v$_dbVersion)');
// // // // // // // //   //   } catch (e) {
// // // // // // // //   //     AppLogger.error('Failed to open database: $e');
// // // // // // // //   //     rethrow;
// // // // // // // //   //   }
// // // // // // // //   // }

// // // // // // // //   Future<void> open() async {
// // // // // // // //     if (isOpen) return;

// // // // // // // //     final dbPath = p.join(await getDatabasesPath(), _dbName);
// // // // // // // //     final directory = p.dirname(dbPath);
// // // // // // // //     await Directory(directory).create(recursive: true);

// // // // // // // //     // Delete corrupted database if needed (uncomment once)
// // // // // // // //     // final file = File(dbPath);
// // // // // // // //     // if (await file.exists()) await file.delete();

// // // // // // // //     _db = await openDatabase(
// // // // // // // //       dbPath,
// // // // // // // //       version: _dbVersion,
// // // // // // // //       onCreate: _onCreate,
// // // // // // // //       onUpgrade: _onUpgrade,
// // // // // // // //       // Do not use onConfigure or onOpen
// // // // // // // //     );

// // // // // // // //     // ✅ Success – no PRAGMA statements
// // // // // // // //     AppLogger.info('SQLite database opened: $dbPath (v$_dbVersion)');
// // // // // // // //   }

// // // // // // // //   // Helper method to safely execute database operations
// // // // // // // //   Future<T?> safeDbOperation<T>(
// // // // // // // //     Future<T> Function(Database db) operation,
// // // // // // // //   ) async {
// // // // // // // //     if (!isOpen) {
// // // // // // // //       AppLogger.warning('Database not open, skipping operation');
// // // // // // // //       return null;
// // // // // // // //     }
// // // // // // // //     try {
// // // // // // // //       return await operation(_db!);
// // // // // // // //     } catch (e) {
// // // // // // // //       AppLogger.error('Database operation failed: $e');
// // // // // // // //       return null;
// // // // // // // //     }
// // // // // // // //   }

// // // // // // // //   // ── Schema creation ────────────────────────────────────────────────────
// // // // // // // //   Future<void> _onCreate(Database db, int version) async {
// // // // // // // //     AppLogger.info('Creating SQLite schema v$version');
// // // // // // // //     await _runMigration(db, version);
// // // // // // // //   }

// // // // // // // //   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
// // // // // // // //     AppLogger.info('Upgrading SQLite $oldVersion → $newVersion');
// // // // // // // //     for (var v = oldVersion + 1; v <= newVersion; v++) {
// // // // // // // //       await _runMigration(db, v);
// // // // // // // //     }
// // // // // // // //   }

// // // // // // // //   Future<void> _runMigration(Database db, int version) async {
// // // // // // // //     switch (version) {
// // // // // // // //       case 1:
// // // // // // // //         await _migration001(db);
// // // // // // // //       case 2:
// // // // // // // //         await _migration002(db);
// // // // // // // //     }
// // // // // // // //   }

// // // // // // // //   Future<void> _migration002(Database db) async {
// // // // // // // //     await db.execute(OfflineSessionsMigration.schema);
// // // // // // // //     AppLogger.info('Migration 002: offline_sessions applied');
// // // // // // // //   }

// // // // // // // //   // ── Migration 001: Initial schema ──────────────────────────────────────
// // // // // // // //   Future<void> _migration001(Database db) async {
// // // // // // // //     final batch = db.batch();

// // // // // // // //     batch.execute('''
// // // // // // // //       CREATE TABLE IF NOT EXISTS packs (
// // // // // // // //         id            TEXT PRIMARY KEY,
// // // // // // // //         name_json     TEXT NOT NULL,
// // // // // // // //         cover_url     TEXT,
// // // // // // // //         game_type     TEXT NOT NULL,
// // // // // // // //         language      TEXT NOT NULL DEFAULT 'en',
// // // // // // // //         price         INTEGER NOT NULL DEFAULT 0,
// // // // // // // //         server_version INTEGER NOT NULL DEFAULT 1,
// // // // // // // //         downloaded_at INTEGER NOT NULL,
// // // // // // // //         expires_at    INTEGER
// // // // // // // //       )
// // // // // // // //     ''');

// // // // // // // //     batch.execute('''
// // // // // // // //       CREATE TABLE IF NOT EXISTS pack_cards (
// // // // // // // //         id           TEXT PRIMARY KEY,
// // // // // // // //         pack_id      TEXT NOT NULL REFERENCES packs(id) ON DELETE CASCADE,
// // // // // // // //         content_json TEXT NOT NULL,
// // // // // // // //         card_type    TEXT NOT NULL,
// // // // // // // //         difficulty   TEXT NOT NULL DEFAULT 'mild',
// // // // // // // //         sort_order   INTEGER NOT NULL DEFAULT 0,
// // // // // // // //         image_path   TEXT
// // // // // // // //       )
// // // // // // // //     ''');

// // // // // // // //     batch.execute('''
// // // // // // // //       CREATE VIEW IF NOT EXISTS pack_cards_cache AS
// // // // // // // //       SELECT id, pack_id, content_json, card_type, difficulty, sort_order, image_path
// // // // // // // //       FROM pack_cards
// // // // // // // //     ''');

// // // // // // // //     batch.execute(
// // // // // // // //       'CREATE INDEX IF NOT EXISTS idx_cards_pack ON pack_cards(pack_id, sort_order)',
// // // // // // // //     );

// // // // // // // //     batch.execute('''
// // // // // // // //       CREATE TABLE IF NOT EXISTS purchases (
// // // // // // // //         pack_id      TEXT PRIMARY KEY REFERENCES packs(id) ON DELETE CASCADE,
// // // // // // // //         purchased_at INTEGER NOT NULL,
// // // // // // // //         expires_at   INTEGER NOT NULL
// // // // // // // //       )
// // // // // // // //     ''');

// // // // // // // //     batch.execute('''
// // // // // // // //       CREATE TABLE IF NOT EXISTS sync_log (
// // // // // // // //         pack_id        TEXT PRIMARY KEY,
// // // // // // // //         server_version INTEGER NOT NULL,
// // // // // // // //         local_version  INTEGER NOT NULL,
// // // // // // // //         synced_at      INTEGER NOT NULL
// // // // // // // //       )
// // // // // // // //     ''');

// // // // // // // //     await batch.commit(noResult: true);
// // // // // // // //     AppLogger.info('Migration 001 applied');
// // // // // // // //   }

// // // // // // // //   Future<void> close() async {
// // // // // // // //     await _db?.close();
// // // // // // // //     _db = null;
// // // // // // // //   }
// // // // // // // // }

// // // // // // // import 'dart:io';
// // // // // // // import 'package:sqflite/sqflite.dart';
// // // // // // // import 'package:path/path.dart' as p;
// // // // // // // import '../../utils/app_logger.dart';
// // // // // // // import '../../../features/offline/data/offline_repository.dart'
// // // // // // //     show OfflineRepository;

// // // // // // // abstract class OfflineSessionsMigration {
// // // // // // //   static const schema = OfflineRepository.schemaV2;
// // // // // // // }

// // // // // // // class AppDatabase {
// // // // // // //   AppDatabase._();
// // // // // // //   static final AppDatabase instance = AppDatabase._();

// // // // // // //   static const _dbName = 'jma3a.db';
// // // // // // //   static const _dbVersion = 2;

// // // // // // //   Database? _db;
// // // // // // //   Database get db {
// // // // // // //     assert(_db != null, 'AppDatabase not opened. Call open() first.');
// // // // // // //     return _db!;
// // // // // // //   }

// // // // // // //   bool get isOpen => _db?.isOpen ?? false;

// // // // // // //   // Future<void> open() async {
// // // // // // //   //   if (isOpen) return;

// // // // // // //   //   final dbPath = p.join(await getDatabasesPath(), _dbName);
// // // // // // //   //   final directory = p.dirname(dbPath);
// // // // // // //   //   await Directory(directory).create(recursive: true);

// // // // // // //   //   // Check if database exists and is valid
// // // // // // //   //   final file = File(dbPath);
// // // // // // //   //   bool needsRecreation = false;

// // // // // // //   //   if (await file.exists()) {
// // // // // // //   //     // Try to open and verify a table exists
// // // // // // //   //     try {
// // // // // // //   //       final testDb = await openDatabase(dbPath, readOnly: true);
// // // // // // //   //       final result = await testDb.rawQuery(
// // // // // // //   //         "SELECT name FROM sqlite_master WHERE type='table' AND name='packs'",
// // // // // // //   //       );
// // // // // // //   //       await testDb.close();
// // // // // // //   //       if (result.isEmpty) {
// // // // // // //   //         needsRecreation = true;
// // // // // // //   //         AppLogger.warning(
// // // // // // //   //           'Database exists but missing packs table – will recreate',
// // // // // // //   //         );
// // // // // // //   //       }
// // // // // // //   //     } catch (e) {
// // // // // // //   //       needsRecreation = true;
// // // // // // //   //       AppLogger.warning('Database file corrupted – will recreate', error: e);
// // // // // // //   //     }
// // // // // // //   //   }

// // // // // // //   //   if (needsRecreation) {
// // // // // // //   //     await file.delete();
// // // // // // //   //     AppLogger.info('Deleted invalid database file');
// // // // // // //   //   }

// // // // // // //   //   _db = await openDatabase(
// // // // // // //   //     dbPath,
// // // // // // //   //     version: _dbVersion,
// // // // // // //   //     onCreate: _onCreate,
// // // // // // //   //     onUpgrade: _onUpgrade,
// // // // // // //   //   );

// // // // // // //   //   AppLogger.info('SQLite database opened: $dbPath (v$_dbVersion)');
// // // // // // //   // }
// // // // // // //   Future<void> open() async {
// // // // // // //     if (isOpen) return;

// // // // // // //     final dbPath = p.join(await getDatabasesPath(), _dbName);
// // // // // // //     final directory = p.dirname(dbPath);
// // // // // // //     await Directory(directory).create(recursive: true);

// // // // // // //     final file = File(dbPath);
// // // // // // //     if (await file.exists()) {
// // // // // // //       AppLogger.warning('Deleting existing database file (force recreation)');
// // // // // // //       // await file.delete();
// // // // // // //       await deleteDatabase(dbPath);
// // // // // // //     }

// // // // // // //     // _db = await openDatabase(
// // // // // // //     //   dbPath,
// // // // // // //     //   version: _dbVersion,
// // // // // // //     //   onCreate: (db, version) async {
// // // // // // //     //     AppLogger.info('onCreate called with version $version');
// // // // // // //     //     await _runMigration(db, version);
// // // // // // //     //     // Verify table creation
// // // // // // //     //     final count = await db.rawQuery(
// // // // // // //     //       "SELECT name FROM sqlite_master WHERE type='table' AND name='packs'",
// // // // // // //     //     );
// // // // // // //     //     AppLogger.info(
// // // // // // //     //       'After migration, packs table exists: ${count.isNotEmpty}',
// // // // // // //     //     );
// // // // // // //     //   },
// // // // // // //     //   onUpgrade: (db, oldVersion, newVersion) async {
// // // // // // //     //     AppLogger.info('onUpgrade from $oldVersion to $newVersion');
// // // // // // //     //     for (var v = oldVersion + 1; v <= newVersion; v++) {
// // // // // // //     //       await _runMigration(db, v);
// // // // // // //     //     }
// // // // // // //     //   },
// // // // // // //     // );
// // // // // // //     _db = await openDatabase(
// // // // // // //       dbPath,
// // // // // // //       version: _dbVersion,
// // // // // // //       onCreate: _onCreate,
// // // // // // //       onUpgrade: _onUpgrade,
// // // // // // //     );

// // // // // // //     // Final verification
// // // // // // //     final check = await _db!.rawQuery(
// // // // // // //       "SELECT name FROM sqlite_master WHERE type='table' AND name='packs'",
// // // // // // //     );
// // // // // // //     if (check.isEmpty) {
// // // // // // //       throw Exception('Failed to create packs table – schema missing');
// // // // // // //     }

// // // // // // //     AppLogger.info('SQLite database opened successfully: $dbPath');
// // // // // // //   }

// // // // // // //   // Future<void> _onCreate(Database db, int version) async {
// // // // // // //   //   for (var v = 1; v <= version; v++) {
// // // // // // //   //     await _runMigration(db, v);
// // // // // // //   //   }
// // // // // // //   // }
// // // // // // //   Future<void> _onCreate(Database db, int version) async {
// // // // // // //     await _migration001(db);
// // // // // // //     await _migration002(db);
// // // // // // //   }

// // // // // // //   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
// // // // // // //     for (var v = oldVersion + 1; v <= newVersion; v++) {
// // // // // // //       await _runMigration(db, v);
// // // // // // //     }
// // // // // // //   }

// // // // // // //   Future<void> _runMigration(Database db, int version) async {
// // // // // // //     AppLogger.info('Running migration for version $version');
// // // // // // //     switch (version) {
// // // // // // //       case 1:
// // // // // // //         await _migration001(db);
// // // // // // //         break;
// // // // // // //       case 2:
// // // // // // //         await _migration002(db);
// // // // // // //         break;
// // // // // // //       default:
// // // // // // //         AppLogger.warning('Unknown migration version $version');
// // // // // // //     }
// // // // // // //   }

// // // // // // //   // Future<void> _onCreate(Database db, int version) async {
// // // // // // //   //   AppLogger.info('Creating SQLite schema v$version');
// // // // // // //   //   await _runMigration(db, version);
// // // // // // //   // }

// // // // // // //   // Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
// // // // // // //   //   AppLogger.info('Upgrading SQLite $oldVersion → $newVersion');
// // // // // // //   //   for (var v = oldVersion + 1; v <= newVersion; v++) {
// // // // // // //   //     await _runMigration(db, v);
// // // // // // //   //   }
// // // // // // //   // }

// // // // // // //   // Future<void> _runMigration(Database db, int version) async {
// // // // // // //   //   switch (version) {
// // // // // // //   //     case 1:
// // // // // // //   //       await _migration001(db);
// // // // // // //   //     case 2:
// // // // // // //   //       await _migration002(db);
// // // // // // //   //   }
// // // // // // //   // }

// // // // // // //   Future<void> _migration002(Database db) async {
// // // // // // //     await db.execute(OfflineSessionsMigration.schema);
// // // // // // //     AppLogger.info('Migration 002: offline_sessions applied');
// // // // // // //   }

// // // // // // //   Future<void> _migration001(Database db) async {
// // // // // // //     try {
// // // // // // //       final batch = db.batch();

// // // // // // //       // Downloaded packs
// // // // // // //       batch.execute('''
// // // // // // //       CREATE TABLE IF NOT EXISTS packs (
// // // // // // //         id            TEXT PRIMARY KEY,
// // // // // // //         name_json     TEXT NOT NULL,
// // // // // // //         cover_url     TEXT,
// // // // // // //         game_type     TEXT NOT NULL,
// // // // // // //         language      TEXT NOT NULL DEFAULT 'en',
// // // // // // //         price         INTEGER NOT NULL DEFAULT 0,
// // // // // // //         server_version INTEGER NOT NULL DEFAULT 1,
// // // // // // //         downloaded_at INTEGER NOT NULL,
// // // // // // //         expires_at    INTEGER
// // // // // // //       )
// // // // // // //     ''');

// // // // // // //       // Pack cards
// // // // // // //       batch.execute('''
// // // // // // //       CREATE TABLE IF NOT EXISTS pack_cards (
// // // // // // //         id           TEXT PRIMARY KEY,
// // // // // // //         pack_id      TEXT NOT NULL REFERENCES packs(id) ON DELETE CASCADE,
// // // // // // //         content_json TEXT NOT NULL,
// // // // // // //         card_type    TEXT NOT NULL,
// // // // // // //         difficulty   TEXT NOT NULL DEFAULT 'mild',
// // // // // // //         sort_order   INTEGER NOT NULL DEFAULT 0,
// // // // // // //         image_path   TEXT
// // // // // // //       )
// // // // // // //     ''');

// // // // // // //       // View for compatibility
// // // // // // //       batch.execute('''
// // // // // // //       CREATE VIEW IF NOT EXISTS pack_cards_cache AS
// // // // // // //       SELECT id, pack_id, content_json, card_type, difficulty, sort_order, image_path
// // // // // // //       FROM pack_cards
// // // // // // //     ''');

// // // // // // //       batch.execute(
// // // // // // //         'CREATE INDEX IF NOT EXISTS idx_cards_pack ON pack_cards(pack_id, sort_order)',
// // // // // // //       );

// // // // // // //       // Purchases table
// // // // // // //       batch.execute('''
// // // // // // //       CREATE TABLE IF NOT EXISTS purchases (
// // // // // // //         pack_id      TEXT PRIMARY KEY REFERENCES packs(id) ON DELETE CASCADE,
// // // // // // //         purchased_at INTEGER NOT NULL,
// // // // // // //         expires_at   INTEGER NOT NULL
// // // // // // //       )
// // // // // // //     ''');

// // // // // // //       // Sync log
// // // // // // //       batch.execute('''
// // // // // // //       CREATE TABLE IF NOT EXISTS sync_log (
// // // // // // //         pack_id        TEXT PRIMARY KEY,
// // // // // // //         server_version INTEGER NOT NULL,
// // // // // // //         local_version  INTEGER NOT NULL,
// // // // // // //         synced_at      INTEGER NOT NULL
// // // // // // //       )
// // // // // // //     ''');

// // // // // // //       await batch.commit(noResult: true);
// // // // // // //       AppLogger.info('Migration 001 applied');
// // // // // // //     } catch (e, st) {
// // // // // // //       AppLogger.error('Migration 001 failed', error: e, stackTrace: st);
// // // // // // //       rethrow;
// // // // // // //     }
// // // // // // //   }

// // // // // // //   Future<void> close() async {
// // // // // // //     await _db?.close();
// // // // // // //     _db = null;
// // // // // // //   }
// // // // // // // }

// // // // // // // import 'package:sqflite/sqflite.dart';
// // // // // // // import 'package:path/path.dart' as p;

// // // // // // // import '../../utils/app_logger.dart';
// // // // // // // import '../../../features/offline/data/offline_repository.dart'
// // // // // // //     show OfflineRepository;

// // // // // // // /// Offline sessions schema — referenced by AppDatabase migration v2.
// // // // // // // abstract class OfflineSessionsMigration {
// // // // // // //   static const schema = OfflineRepository.schemaV2;
// // // // // // // }

// // // // // // // /// SQLite database singleton with versioned migrations.
// // // // // // // ///
// // // // // // // /// Stores: downloaded pack cards, purchase metadata, offline sync log.
// // // // // // // /// All game and social data lives in Supabase — SQLite is offline-only.
// // // // // // // class AppDatabase {
// // // // // // //   AppDatabase._();
// // // // // // //   static final AppDatabase instance = AppDatabase._();

// // // // // // //   static const _dbName = 'jma3a.db';
// // // // // // //   static const _dbVersion = 2;

// // // // // // //   Database? _db;
// // // // // // //   Database get db {
// // // // // // //     assert(_db != null, 'AppDatabase not opened. Call open() first.');
// // // // // // //     return _db!;
// // // // // // //   }

// // // // // // //   /// Returns the database if open, null otherwise. Use in code that
// // // // // // //   /// runs before initialization is guaranteed (e.g. screen initState).
// // // // // // //   Database? get safeDb => (_db?.isOpen ?? false) ? _db : null;

// // // // // // //   bool get isOpen => _db?.isOpen ?? false;

// // // // // // //   Future<void> open() async {
// // // // // // //     if (isOpen) return;

// // // // // // //     final dbPath = p.join(await getDatabasesPath(), _dbName);

// // // // // // //     _db = await openDatabase(
// // // // // // //       dbPath,
// // // // // // //       version: _dbVersion,
// // // // // // //       onCreate: _onCreate,
// // // // // // //       onUpgrade: _onUpgrade,
// // // // // // //       onConfigure: (db) async {
// // // // // // //         await db.rawQuery('PRAGMA foreign_keys = ON');
// // // // // // //         await db.rawQuery('PRAGMA journal_mode = WAL');
// // // // // // //       },
// // // // // // //     );

// // // // // // //     AppLogger.info('SQLite database opened: $dbPath (v$_dbVersion)');
// // // // // // //   }

// // // // // // //   // ── Schema creation ────────────────────────────────────────────────────
// // // // // // //   Future<void> _onCreate(Database db, int version) async {
// // // // // // //     AppLogger.info('Creating SQLite schema v$version');
// // // // // // //     await _runMigration(db, version);
// // // // // // //   }

// // // // // // //   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
// // // // // // //     AppLogger.info('Upgrading SQLite $oldVersion → $newVersion');
// // // // // // //     for (var v = oldVersion + 1; v <= newVersion; v++) {
// // // // // // //       await _runMigration(db, v);
// // // // // // //     }
// // // // // // //   }

// // // // // // //   Future<void> _runMigration(Database db, int version) async {
// // // // // // //     switch (version) {
// // // // // // //       case 1:
// // // // // // //         await _migration001(db);
// // // // // // //       case 2:
// // // // // // //         await _migration002(db);
// // // // // // //     }
// // // // // // //   }

// // // // // // //   Future<void> _migration002(Database db) async {
// // // // // // //     await db.execute(OfflineSessionsMigration.schema);
// // // // // // //     AppLogger.info('Migration 002: offline_sessions applied');
// // // // // // //   }

// // // // // // //   // ── Migration 001: Initial schema ──────────────────────────────────────
// // // // // // //   Future<void> _migration001(Database db) async {
// // // // // // //     final batch = db.batch();

// // // // // // //     // Downloaded packs (header only — cards in pack_cards table)
// // // // // // //     batch.execute('''
// // // // // // //       CREATE TABLE IF NOT EXISTS packs (
// // // // // // //         id            TEXT PRIMARY KEY,
// // // // // // //         name_json     TEXT NOT NULL,
// // // // // // //         cover_url     TEXT,
// // // // // // //         game_type     TEXT NOT NULL,
// // // // // // //         language      TEXT NOT NULL DEFAULT 'en',
// // // // // // //         price         INTEGER NOT NULL DEFAULT 0,
// // // // // // //         server_version INTEGER NOT NULL DEFAULT 1,
// // // // // // //         downloaded_at INTEGER NOT NULL,
// // // // // // //         expires_at    INTEGER
// // // // // // //       )
// // // // // // //     ''');

// // // // // // //     // Individual cards for each downloaded pack
// // // // // // //     batch.execute('''
// // // // // // //       CREATE TABLE IF NOT EXISTS pack_cards (
// // // // // // //         id           TEXT PRIMARY KEY,
// // // // // // //         pack_id      TEXT NOT NULL REFERENCES packs(id) ON DELETE CASCADE,
// // // // // // //         content_json TEXT NOT NULL,
// // // // // // //         card_type    TEXT NOT NULL,
// // // // // // //         difficulty   TEXT NOT NULL DEFAULT 'mild',
// // // // // // //         sort_order   INTEGER NOT NULL DEFAULT 0,
// // // // // // //         image_path   TEXT
// // // // // // //       )
// // // // // // //     ''');

// // // // // // //     // Alias view for TodRepository compatibility
// // // // // // //     batch.execute('''
// // // // // // //       CREATE VIEW IF NOT EXISTS pack_cards_cache AS
// // // // // // //       SELECT id, pack_id, content_json, card_type, difficulty, sort_order, image_path
// // // // // // //       FROM pack_cards
// // // // // // //     ''');

// // // // // // //     batch.execute(
// // // // // // //       'CREATE INDEX IF NOT EXISTS idx_cards_pack ON pack_cards(pack_id, sort_order)',
// // // // // // //     );

// // // // // // //     // Local mirror of server purchase records (for expiry checking offline)
// // // // // // //     batch.execute('''
// // // // // // //       CREATE TABLE IF NOT EXISTS purchases (
// // // // // // //         pack_id      TEXT PRIMARY KEY REFERENCES packs(id) ON DELETE CASCADE,
// // // // // // //         purchased_at INTEGER NOT NULL,
// // // // // // //         expires_at   INTEGER NOT NULL
// // // // // // //       )
// // // // // // //     ''');

// // // // // // //     // Sync log: tracks which packs need re-download
// // // // // // //     batch.execute('''
// // // // // // //       CREATE TABLE IF NOT EXISTS sync_log (
// // // // // // //         pack_id        TEXT PRIMARY KEY,
// // // // // // //         server_version INTEGER NOT NULL,
// // // // // // //         local_version  INTEGER NOT NULL,
// // // // // // //         synced_at      INTEGER NOT NULL
// // // // // // //       )
// // // // // // //     ''');

// // // // // // //     // Room cache — used by RoomCacheService
// // // // // // //     batch.execute('''
// // // // // // //       CREATE TABLE IF NOT EXISTS cached_rooms (
// // // // // // //         id        TEXT PRIMARY KEY,
// // // // // // //         data      TEXT NOT NULL,
// // // // // // //         cached_at INTEGER NOT NULL
// // // // // // //       )
// // // // // // //     ''');

// // // // // // //     batch.execute('''
// // // // // // //       CREATE TABLE IF NOT EXISTS cached_chat_messages (
// // // // // // //         id         TEXT PRIMARY KEY,
// // // // // // //         room_id    TEXT NOT NULL,
// // // // // // //         data       TEXT NOT NULL,
// // // // // // //         created_at INTEGER NOT NULL
// // // // // // //       )
// // // // // // //     ''');

// // // // // // //     batch.execute(
// // // // // // //       'CREATE INDEX IF NOT EXISTS idx_chat_room ON cached_chat_messages(room_id, created_at)',
// // // // // // //     );

// // // // // // //     await batch.commit(noResult: true);
// // // // // // //     AppLogger.info('Migration 001 applied');
// // // // // // //   }

// // // // // // //   Future<void> close() async {
// // // // // // //     await _db?.close();
// // // // // // //     _db = null;
// // // // // // //   }
// // // // // // // }

// // // // // // import 'package:sqflite/sqflite.dart';
// // // // // // import 'package:path/path.dart' as p;

// // // // // // import '../../utils/app_logger.dart';
// // // // // // import '../../../features/offline/data/offline_repository.dart'
// // // // // //     show OfflineRepository;

// // // // // // /// Offline sessions schema — referenced by AppDatabase migration v2.
// // // // // // abstract class OfflineSessionsMigration {
// // // // // //   static const schema = OfflineRepository.schemaV2;
// // // // // // }

// // // // // // /// SQLite database singleton with versioned migrations.
// // // // // // ///
// // // // // // /// Stores: downloaded pack cards, purchase metadata, offline sync log.
// // // // // // /// All game and social data lives in Supabase — SQLite is offline-only.
// // // // // // class AppDatabase {
// // // // // //   AppDatabase._();
// // // // // //   static final AppDatabase instance = AppDatabase._();

// // // // // //   static const _dbName = 'jma3a.db';
// // // // // //   static const _dbVersion = 3; // ✅ increased to 3

// // // // // //   Database? _db;
// // // // // //   Database get db {
// // // // // //     assert(_db != null, 'AppDatabase not opened. Call open() first.');
// // // // // //     return _db!;
// // // // // //   }

// // // // // //   /// Returns the database if open, null otherwise. Use in code that
// // // // // //   /// runs before initialization is guaranteed (e.g. screen initState).
// // // // // //   Database? get safeDb => (_db?.isOpen ?? false) ? _db : null;

// // // // // //   bool get isOpen => _db?.isOpen ?? false;

// // // // // //   Future<void> open() async {
// // // // // //     if (isOpen) return;

// // // // // //     final dbPath = p.join(await getDatabasesPath(), _dbName);

// // // // // //     _db = await openDatabase(
// // // // // //       dbPath,
// // // // // //       version: _dbVersion,
// // // // // //       onCreate: _onCreate,
// // // // // //       onUpgrade: _onUpgrade,
// // // // // //       onConfigure: (db) async {
// // // // // //         await db.rawQuery('PRAGMA foreign_keys = ON');
// // // // // //         await db.rawQuery('PRAGMA journal_mode = WAL');
// // // // // //       },
// // // // // //     );

// // // // // //     AppLogger.info('SQLite database opened: $dbPath (v$_dbVersion)');
// // // // // //   }

// // // // // //   // ── Schema creation ────────────────────────────────────────────────────
// // // // // //   Future<void> _onCreate(Database db, int version) async {
// // // // // //     AppLogger.info('Creating SQLite schema v$version');
// // // // // //     await _runMigration(db, version);
// // // // // //   }

// // // // // //   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
// // // // // //     AppLogger.info('Upgrading SQLite $oldVersion → $newVersion');
// // // // // //     for (var v = oldVersion + 1; v <= newVersion; v++) {
// // // // // //       await _runMigration(db, v);
// // // // // //     }
// // // // // //   }

// // // // // //   Future<void> _runMigration(Database db, int version) async {
// // // // // //     switch (version) {
// // // // // //       case 1:
// // // // // //         await _migration001(db);
// // // // // //       case 2:
// // // // // //         await _migration002(db);
// // // // // //       case 3:
// // // // // //         await _migration003(db);
// // // // // //     }
// // // // // //   }

// // // // // //   Future<void> _migration002(Database db) async {
// // // // // //     await db.execute(OfflineSessionsMigration.schema);
// // // // // //     AppLogger.info('Migration 002: offline_sessions applied');
// // // // // //   }

// // // // // //   Future<void> _migration003(Database db) async {
// // // // // //     // Add is_active column to pack_cards (default 1 = active)
// // // // // //     try {
// // // // // //       await db.execute(
// // // // // //         'ALTER TABLE pack_cards ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1',
// // // // // //       );
// // // // // //       AppLogger.info('Migration 003: added is_active column to pack_cards');
// // // // // //     } catch (e) {
// // // // // //       // Column might already exist (if migration ran partially)
// // // // // //       AppLogger.warning(
// // // // // //         'Migration 003: is_active column may already exist – $e',
// // // // // //       );
// // // // // //     }

// // // // // //     // Recreate the view to include the new column
// // // // // //     await db.execute('DROP VIEW IF EXISTS pack_cards_cache');
// // // // // //     await db.execute('''
// // // // // //       CREATE VIEW pack_cards_cache AS
// // // // // //       SELECT id, pack_id, content_json, card_type, difficulty, sort_order, image_path, is_active
// // // // // //       FROM pack_cards
// // // // // //     ''');
// // // // // //     AppLogger.info(
// // // // // //       'Migration 003: recreated pack_cards_cache view with is_active',
// // // // // //     );
// // // // // //   }

// // // // // //   // ── Migration 001: Initial schema ──────────────────────────────────────
// // // // // //   Future<void> _migration001(Database db) async {
// // // // // //     final batch = db.batch();

// // // // // //     // Downloaded packs (header only — cards in pack_cards table)
// // // // // //     batch.execute('''
// // // // // //       CREATE TABLE IF NOT EXISTS packs (
// // // // // //         id            TEXT PRIMARY KEY,
// // // // // //         name_json     TEXT NOT NULL,
// // // // // //         cover_url     TEXT,
// // // // // //         game_type     TEXT NOT NULL,
// // // // // //         language      TEXT NOT NULL DEFAULT 'en',
// // // // // //         price         INTEGER NOT NULL DEFAULT 0,
// // // // // //         server_version INTEGER NOT NULL DEFAULT 1,
// // // // // //         downloaded_at INTEGER NOT NULL,
// // // // // //         expires_at    INTEGER
// // // // // //       )
// // // // // //     ''');

// // // // // //     // Individual cards for each downloaded pack (now includes is_active)
// // // // // //     batch.execute('''
// // // // // //       CREATE TABLE IF NOT EXISTS pack_cards (
// // // // // //         id           TEXT PRIMARY KEY,
// // // // // //         pack_id      TEXT NOT NULL REFERENCES packs(id) ON DELETE CASCADE,
// // // // // //         content_json TEXT NOT NULL,
// // // // // //         card_type    TEXT NOT NULL,
// // // // // //         difficulty   TEXT NOT NULL DEFAULT 'mild',
// // // // // //         sort_order   INTEGER NOT NULL DEFAULT 0,
// // // // // //         image_path   TEXT,
// // // // // //         is_active    INTEGER NOT NULL DEFAULT 1
// // // // // //       )
// // // // // //     ''');

// // // // // //     // Alias view for TodRepository compatibility (includes is_active)
// // // // // //     batch.execute('''
// // // // // //       CREATE VIEW IF NOT EXISTS pack_cards_cache AS
// // // // // //       SELECT id, pack_id, content_json, card_type, difficulty, sort_order, image_path, is_active
// // // // // //       FROM pack_cards
// // // // // //     ''');

// // // // // //     batch.execute(
// // // // // //       'CREATE INDEX IF NOT EXISTS idx_cards_pack ON pack_cards(pack_id, sort_order)',
// // // // // //     );

// // // // // //     // Local mirror of server purchase records (for expiry checking offline)
// // // // // //     batch.execute('''
// // // // // //       CREATE TABLE IF NOT EXISTS purchases (
// // // // // //         pack_id      TEXT PRIMARY KEY REFERENCES packs(id) ON DELETE CASCADE,
// // // // // //         purchased_at INTEGER NOT NULL,
// // // // // //         expires_at   INTEGER NOT NULL
// // // // // //       )
// // // // // //     ''');

// // // // // //     // Sync log: tracks which packs need re-download
// // // // // //     batch.execute('''
// // // // // //       CREATE TABLE IF NOT EXISTS sync_log (
// // // // // //         pack_id        TEXT PRIMARY KEY,
// // // // // //         server_version INTEGER NOT NULL,
// // // // // //         local_version  INTEGER NOT NULL,
// // // // // //         synced_at      INTEGER NOT NULL
// // // // // //       )
// // // // // //     ''');

// // // // // //     // Room cache — used by RoomCacheService
// // // // // //     batch.execute('''
// // // // // //       CREATE TABLE IF NOT EXISTS cached_rooms (
// // // // // //         id        TEXT PRIMARY KEY,
// // // // // //         data      TEXT NOT NULL,
// // // // // //         cached_at INTEGER NOT NULL
// // // // // //       )
// // // // // //     ''');

// // // // // //     batch.execute('''
// // // // // //       CREATE TABLE IF NOT EXISTS cached_chat_messages (
// // // // // //         id         TEXT PRIMARY KEY,
// // // // // //         room_id    TEXT NOT NULL,
// // // // // //         data       TEXT NOT NULL,
// // // // // //         created_at INTEGER NOT NULL
// // // // // //       )
// // // // // //     ''');

// // // // // //     batch.execute(
// // // // // //       'CREATE INDEX IF NOT EXISTS idx_chat_room ON cached_chat_messages(room_id, created_at)',
// // // // // //     );

// // // // // //     await batch.commit(noResult: true);
// // // // // //     AppLogger.info('Migration 001 applied');
// // // // // //   }

// // // // // //   Future<void> close() async {
// // // // // //     await _db?.close();
// // // // // //     _db = null;
// // // // // //   }
// // // // // // }

// // // // // import 'package:sqflite/sqflite.dart';
// // // // // import 'package:path/path.dart' as p;

// // // // // import '../../utils/app_logger.dart';
// // // // // import '../../../features/offline/data/offline_repository.dart'
// // // // //     show OfflineRepository;

// // // // // /// Offline sessions schema — referenced by AppDatabase migration v2.
// // // // // abstract class OfflineSessionsMigration {
// // // // //   static const schema = OfflineRepository.schemaV2;
// // // // // }

// // // // // /// SQLite database singleton with versioned migrations.
// // // // // ///
// // // // // /// Stores: downloaded pack cards, purchase metadata, offline sync log.
// // // // // /// All game and social data lives in Supabase — SQLite is offline-only.
// // // // // class AppDatabase {
// // // // //   AppDatabase._();
// // // // //   static final AppDatabase instance = AppDatabase._();

// // // // //   static const _dbName = 'jma3a.db';
// // // // //   static const _dbVersion = 2;

// // // // //   Database? _db;
// // // // //   Database get db {
// // // // //     assert(_db != null, 'AppDatabase not opened. Call open() first.');
// // // // //     return _db!;
// // // // //   }

// // // // //   /// Returns the database if open, null otherwise. Use in code that
// // // // //   /// runs before initialization is guaranteed (e.g. screen initState).
// // // // //   Database? get safeDb => (_db?.isOpen ?? false) ? _db : null;

// // // // //   bool get isOpen => _db?.isOpen ?? false;

// // // // //   Future<void> open() async {
// // // // //     if (isOpen) return;

// // // // //     final dbPath = p.join(await getDatabasesPath(), _dbName);

// // // // //     _db = await openDatabase(
// // // // //       dbPath,
// // // // //       version: _dbVersion,
// // // // //       onCreate: _onCreate,
// // // // //       onUpgrade: _onUpgrade,
// // // // //       onConfigure: (db) async {
// // // // //         await db.rawQuery('PRAGMA foreign_keys = ON');
// // // // //         await db.rawQuery('PRAGMA journal_mode = WAL');
// // // // //       },
// // // // //     );

// // // // //     AppLogger.info('SQLite database opened: $dbPath (v$_dbVersion)');
// // // // //   }

// // // // //   // ── Schema creation ────────────────────────────────────────────────────
// // // // //   Future<void> _onCreate(Database db, int version) async {
// // // // //     AppLogger.info('Creating SQLite schema v$version (fresh install)');
// // // // //     // Run all migrations in order from 1 to current version
// // // // //     for (var v = 1; v <= version; v++) {
// // // // //       await _runMigration(db, v);
// // // // //     }
// // // // //   }

// // // // //   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
// // // // //     AppLogger.info('Upgrading SQLite $oldVersion → $newVersion');
// // // // //     for (var v = oldVersion + 1; v <= newVersion; v++) {
// // // // //       await _runMigration(db, v);
// // // // //     }
// // // // //   }

// // // // //   Future<void> _runMigration(Database db, int version) async {
// // // // //     switch (version) {
// // // // //       case 1:
// // // // //         await _migration001(db);
// // // // //       case 2:
// // // // //         await _migration002(db);
// // // // //     }
// // // // //   }

// // // // //   Future<void> _migration002(Database db) async {
// // // // //     await db.execute(OfflineSessionsMigration.schema);
// // // // //     AppLogger.info('Migration 002: offline_sessions applied');
// // // // //   }

// // // // //   // ── Migration 001: Initial schema ──────────────────────────────────────
// // // // //   Future<void> _migration001(Database db) async {
// // // // //     final batch = db.batch();

// // // // //     // Downloaded packs (header only — cards in pack_cards table)
// // // // //     batch.execute('''
// // // // //       CREATE TABLE IF NOT EXISTS packs (
// // // // //         id            TEXT PRIMARY KEY,
// // // // //         name_json     TEXT NOT NULL,
// // // // //         cover_url     TEXT,
// // // // //         game_type     TEXT NOT NULL,
// // // // //         language      TEXT NOT NULL DEFAULT 'en',
// // // // //         price         INTEGER NOT NULL DEFAULT 0,
// // // // //         server_version INTEGER NOT NULL DEFAULT 1,
// // // // //         downloaded_at INTEGER NOT NULL,
// // // // //         expires_at    INTEGER
// // // // //       )
// // // // //     ''');

// // // // //     // Individual cards for each downloaded pack
// // // // //     batch.execute('''
// // // // //       CREATE TABLE IF NOT EXISTS pack_cards (
// // // // //         id           TEXT PRIMARY KEY,
// // // // //         pack_id      TEXT NOT NULL REFERENCES packs(id) ON DELETE CASCADE,
// // // // //         content_json TEXT NOT NULL,
// // // // //         card_type    TEXT NOT NULL,
// // // // //         difficulty   TEXT NOT NULL DEFAULT 'mild',
// // // // //         sort_order   INTEGER NOT NULL DEFAULT 0,
// // // // //         image_path   TEXT
// // // // //       )
// // // // //     ''');

// // // // //     // Alias view for TodRepository compatibility
// // // // //     batch.execute('''
// // // // //       CREATE VIEW IF NOT EXISTS pack_cards_cache AS
// // // // //       SELECT id, pack_id, content_json, card_type, difficulty, sort_order, image_path
// // // // //       FROM pack_cards
// // // // //     ''');

// // // // //     batch.execute(
// // // // //       'CREATE INDEX IF NOT EXISTS idx_cards_pack ON pack_cards(pack_id, sort_order)',
// // // // //     );

// // // // //     // Local mirror of server purchase records (for expiry checking offline)
// // // // //     batch.execute('''
// // // // //       CREATE TABLE IF NOT EXISTS purchases (
// // // // //         pack_id      TEXT PRIMARY KEY REFERENCES packs(id) ON DELETE CASCADE,
// // // // //         purchased_at INTEGER NOT NULL,
// // // // //         expires_at   INTEGER NOT NULL
// // // // //       )
// // // // //     ''');

// // // // //     // Sync log: tracks which packs need re-download
// // // // //     batch.execute('''
// // // // //       CREATE TABLE IF NOT EXISTS sync_log (
// // // // //         pack_id        TEXT PRIMARY KEY,
// // // // //         server_version INTEGER NOT NULL,
// // // // //         local_version  INTEGER NOT NULL,
// // // // //         synced_at      INTEGER NOT NULL
// // // // //       )
// // // // //     ''');

// // // // //     // Room cache — used by RoomCacheService
// // // // //     batch.execute('''
// // // // //       CREATE TABLE IF NOT EXISTS cached_rooms (
// // // // //         id        TEXT PRIMARY KEY,
// // // // //         data      TEXT NOT NULL,
// // // // //         cached_at INTEGER NOT NULL
// // // // //       )
// // // // //     ''');

// // // // //     batch.execute('''
// // // // //       CREATE TABLE IF NOT EXISTS cached_chat_messages (
// // // // //         id         TEXT PRIMARY KEY,
// // // // //         room_id    TEXT NOT NULL,
// // // // //         data       TEXT NOT NULL,
// // // // //         created_at INTEGER NOT NULL
// // // // //       )
// // // // //     ''');

// // // // //     batch.execute(
// // // // //       'CREATE INDEX IF NOT EXISTS idx_chat_room ON cached_chat_messages(room_id, created_at)',
// // // // //     );

// // // // //     await batch.commit(noResult: true);
// // // // //     AppLogger.info('Migration 001 applied');
// // // // //   }

// // // // //   Future<void> close() async {
// // // // //     await _db?.close();
// // // // //     _db = null;
// // // // //   }
// // // // // }

// // // // import 'package:sqflite/sqflite.dart';
// // // // import 'package:path/path.dart' as p;

// // // // import '../../utils/app_logger.dart';
// // // // import '../../../features/offline/data/offline_repository.dart'
// // // //     show OfflineRepository;

// // // // /// Offline sessions schema — referenced by AppDatabase migration v2.
// // // // abstract class OfflineSessionsMigration {
// // // //   static const schema = OfflineRepository.schemaV2;
// // // // }

// // // // /// SQLite database singleton with versioned migrations.
// // // // ///
// // // // /// Stores: downloaded pack cards, purchase metadata, offline sync log.
// // // // /// All game and social data lives in Supabase — SQLite is offline-only.
// // // // class AppDatabase {
// // // //   AppDatabase._();
// // // //   static final AppDatabase instance = AppDatabase._();

// // // //   static const _dbName = 'jma3a.db';
// // // //   static const _dbVersion = 3;

// // // //   Database? _db;
// // // //   Database get db {
// // // //     assert(_db != null, 'AppDatabase not opened. Call open() first.');
// // // //     return _db!;
// // // //   }

// // // //   /// Returns the database if open, null otherwise. Use in code that
// // // //   /// runs before initialization is guaranteed (e.g. screen initState).
// // // //   Database? get safeDb => (_db?.isOpen ?? false) ? _db : null;

// // // //   bool get isOpen => _db?.isOpen ?? false;

// // // //   Future<void> open() async {
// // // //     if (isOpen) return;

// // // //     final dbPath = p.join(await getDatabasesPath(), _dbName);

// // // //     _db = await openDatabase(
// // // //       dbPath,
// // // //       version: _dbVersion,
// // // //       onCreate: _onCreate,
// // // //       onUpgrade: _onUpgrade,
// // // //       onConfigure: (db) async {
// // // //         await db.rawQuery('PRAGMA foreign_keys = ON');
// // // //         await db.rawQuery('PRAGMA journal_mode = WAL');
// // // //       },
// // // //     );

// // // //     AppLogger.info('SQLite database opened: $dbPath (v$_dbVersion)');
// // // //   }

// // // //   // ── Schema creation ────────────────────────────────────────────────────
// // // //   Future<void> _onCreate(Database db, int version) async {
// // // //     AppLogger.info('Creating SQLite schema v$version (fresh install)');
// // // //     // Run all migrations in order from 1 to current version
// // // //     for (var v = 1; v <= version; v++) {
// // // //       await _runMigration(db, v);
// // // //     }
// // // //   }

// // // //   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
// // // //     AppLogger.info('Upgrading SQLite $oldVersion → $newVersion');
// // // //     for (var v = oldVersion + 1; v <= newVersion; v++) {
// // // //       await _runMigration(db, v);
// // // //     }
// // // //   }

// // // //   Future<void> _runMigration(Database db, int version) async {
// // // //     switch (version) {
// // // //       case 1:
// // // //         await _migration001(db);
// // // //       case 2:
// // // //         await _migration002(db);
// // // //       case 3:
// // // //         await _migration003(db);
// // // //     }
// // // //   }

// // // //   /// Migration 003: ensure all v1 tables exist (fixes devices that got v2
// // // //   /// without v1 running due to the onCreate bug — all CREATE TABLE statements
// // // //   /// use IF NOT EXISTS so this is safe to re-run).
// // // //   Future<void> _migration003(Database db) async {
// // // //     await _migration001(db);
// // // //     AppLogger.info('Migration 003: ensured all base tables exist');
// // // //   }

// // // //   Future<void> _migration002(Database db) async {
// // // //     await db.execute(OfflineSessionsMigration.schema);
// // // //     AppLogger.info('Migration 002: offline_sessions applied');
// // // //   }

// // // //   // ── Migration 001: Initial schema ──────────────────────────────────────
// // // //   Future<void> _migration001(Database db) async {
// // // //     final batch = db.batch();

// // // //     // Downloaded packs (header only — cards in pack_cards table)
// // // //     batch.execute('''
// // // //       CREATE TABLE IF NOT EXISTS packs (
// // // //         id            TEXT PRIMARY KEY,
// // // //         name_json     TEXT NOT NULL,
// // // //         cover_url     TEXT,
// // // //         game_type     TEXT NOT NULL,
// // // //         language      TEXT NOT NULL DEFAULT 'en',
// // // //         price         INTEGER NOT NULL DEFAULT 0,
// // // //         server_version INTEGER NOT NULL DEFAULT 1,
// // // //         downloaded_at INTEGER NOT NULL,
// // // //         expires_at    INTEGER
// // // //       )
// // // //     ''');

// // // //     // Individual cards for each downloaded pack
// // // //     batch.execute('''
// // // //       CREATE TABLE IF NOT EXISTS pack_cards (
// // // //         id           TEXT PRIMARY KEY,
// // // //         pack_id      TEXT NOT NULL REFERENCES packs(id) ON DELETE CASCADE,
// // // //         content_json TEXT NOT NULL,
// // // //         card_type    TEXT NOT NULL,
// // // //         difficulty   TEXT NOT NULL DEFAULT 'mild',
// // // //         sort_order   INTEGER NOT NULL DEFAULT 0,
// // // //         image_path   TEXT
// // // //       )
// // // //     ''');

// // // //     // Alias view for TodRepository compatibility
// // // //     batch.execute('''
// // // //       CREATE VIEW IF NOT EXISTS pack_cards_cache AS
// // // //       SELECT id, pack_id, content_json, card_type, difficulty, sort_order, image_path
// // // //       FROM pack_cards
// // // //     ''');

// // // //     batch.execute(
// // // //       'CREATE INDEX IF NOT EXISTS idx_cards_pack ON pack_cards(pack_id, sort_order)',
// // // //     );

// // // //     // Local mirror of server purchase records (for expiry checking offline)
// // // //     batch.execute('''
// // // //       CREATE TABLE IF NOT EXISTS purchases (
// // // //         pack_id      TEXT PRIMARY KEY REFERENCES packs(id) ON DELETE CASCADE,
// // // //         purchased_at INTEGER NOT NULL,
// // // //         expires_at   INTEGER NOT NULL
// // // //       )
// // // //     ''');

// // // //     // Sync log: tracks which packs need re-download
// // // //     batch.execute('''
// // // //       CREATE TABLE IF NOT EXISTS sync_log (
// // // //         pack_id        TEXT PRIMARY KEY,
// // // //         server_version INTEGER NOT NULL,
// // // //         local_version  INTEGER NOT NULL,
// // // //         synced_at      INTEGER NOT NULL
// // // //       )
// // // //     ''');

// // // //     // Room cache — used by RoomCacheService
// // // //     batch.execute('''
// // // //       CREATE TABLE IF NOT EXISTS cached_rooms (
// // // //         id        TEXT PRIMARY KEY,
// // // //         data      TEXT NOT NULL,
// // // //         cached_at INTEGER NOT NULL
// // // //       )
// // // //     ''');

// // // //     batch.execute('''
// // // //       CREATE TABLE IF NOT EXISTS cached_chat_messages (
// // // //         id         TEXT PRIMARY KEY,
// // // //         room_id    TEXT NOT NULL,
// // // //         data       TEXT NOT NULL,
// // // //         created_at INTEGER NOT NULL
// // // //       )
// // // //     ''');

// // // //     batch.execute(
// // // //       'CREATE INDEX IF NOT EXISTS idx_chat_room ON cached_chat_messages(room_id, created_at)',
// // // //     );

// // // //     await batch.commit(noResult: true);
// // // //     AppLogger.info('Migration 001 applied');
// // // //   }

// // // //   Future<void> close() async {
// // // //     await _db?.close();
// // // //     _db = null;
// // // //   }
// // // // }

// // // import 'dart:async';

// // // import 'package:sqflite/sqflite.dart';
// // // import 'package:path/path.dart' as p;

// // // import '../../utils/app_logger.dart';
// // // import '../../../features/offline/data/offline_repository.dart'
// // //     show OfflineRepository;

// // // /// Offline sessions schema — referenced by AppDatabase migration v2.
// // // abstract class OfflineSessionsMigration {
// // //   static const schema = OfflineRepository.schemaV2;
// // // }

// // // /// SQLite database singleton with versioned migrations.
// // // class AppDatabase {
// // //   AppDatabase._();
// // //   static final AppDatabase instance = AppDatabase._();

// // //   static const _dbName = 'jma3a.db';
// // //   static const _dbVersion = 4; // ✅ increased to 4

// // //   Database? _db;
// // //   final _readyCompleter = Completer<void>();

// // //   /// Returns the database if open, null otherwise.
// // //   Database? get safeDb => (_db?.isOpen ?? false) ? _db : null;

// // //   bool get isOpen => _db?.isOpen ?? false;

// // //   /// Future that completes when the database is fully opened and ready.
// // //   Future<void> get ready => _readyCompleter.future;

// // //   Database get db {
// // //     assert(_db != null, 'AppDatabase not opened. Call open() first.');
// // //     return _db!;
// // //   }

// // //   Future<void> open() async {
// // //     if (isOpen) {
// // //       _readyCompleter.complete();
// // //       return;
// // //     }

// // //     final dbPath = p.join(await getDatabasesPath(), _dbName);

// // //     _db = await openDatabase(
// // //       dbPath,
// // //       version: _dbVersion,
// // //       onCreate: _onCreate,
// // //       onUpgrade: _onUpgrade,
// // //       onConfigure: (db) async {
// // //         await db.rawQuery('PRAGMA foreign_keys = ON');
// // //         await db.rawQuery('PRAGMA journal_mode = WAL');
// // //       },
// // //     );

// // //     AppLogger.info('SQLite database opened: $dbPath (v$_dbVersion)');
// // //     _readyCompleter.complete();
// // //   }

// // //   // ── Schema creation ────────────────────────────────────────────────────
// // //   Future<void> _onCreate(Database db, int version) async {
// // //     AppLogger.info('Creating SQLite schema v$version (fresh install)');
// // //     for (var v = 1; v <= version; v++) {
// // //       await _runMigration(db, v);
// // //     }
// // //   }

// // //   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
// // //     AppLogger.info('Upgrading SQLite $oldVersion → $newVersion');
// // //     for (var v = oldVersion + 1; v <= newVersion; v++) {
// // //       await _runMigration(db, v);
// // //     }
// // //   }

// // //   Future<void> _runMigration(Database db, int version) async {
// // //     switch (version) {
// // //       case 1:
// // //         await _migration001(db);
// // //       case 2:
// // //         await _migration002(db);
// // //       case 3:
// // //         await _migration003(db);
// // //       case 4:
// // //         await _migration004(db);
// // //     }
// // //   }

// // //   /// Migration 002: adds offline_sessions table.
// // //   Future<void> _migration002(Database db) async {
// // //     await db.execute(OfflineSessionsMigration.schema);
// // //     AppLogger.info('Migration 002: offline_sessions applied');
// // //   }

// // //   /// Migration 003: ensures all v1 tables exist (fixes devices that got v2
// // //   /// without v1 running due to the onCreate bug).
// // //   Future<void> _migration003(Database db) async {
// // //     await _migration001(db);
// // //     AppLogger.info('Migration 003: ensured all base tables exist');
// // //   }

// // //   /// Migration 004: re‑runs base schema creation to guarantee sync_log,
// // //   /// purchases, pack_cards, etc. exist (idempotent).
// // //   Future<void> _migration004(Database db) async {
// // //     await _migration001(db);
// // //     AppLogger.info('Migration 004: re‑enforced base schema');
// // //   }

// // //   // ── Migration 001: Initial schema (all CREATE IF NOT EXISTS) ───────────
// // //   Future<void> _migration001(Database db) async {
// // //     final batch = db.batch();

// // //     // Downloaded packs
// // //     batch.execute('''
// // //       CREATE TABLE IF NOT EXISTS packs (
// // //         id            TEXT PRIMARY KEY,
// // //         name_json     TEXT NOT NULL,
// // //         cover_url     TEXT,
// // //         game_type     TEXT NOT NULL,
// // //         language      TEXT NOT NULL DEFAULT 'en',
// // //         price         INTEGER NOT NULL DEFAULT 0,
// // //         server_version INTEGER NOT NULL DEFAULT 1,
// // //         downloaded_at INTEGER NOT NULL,
// // //         expires_at    INTEGER
// // //       )
// // //     ''');

// // //     // Individual cards
// // //     batch.execute('''
// // //       CREATE TABLE IF NOT EXISTS pack_cards (
// // //         id           TEXT PRIMARY KEY,
// // //         pack_id      TEXT NOT NULL REFERENCES packs(id) ON DELETE CASCADE,
// // //         content_json TEXT NOT NULL,
// // //         card_type    TEXT NOT NULL,
// // //         difficulty   TEXT NOT NULL DEFAULT 'mild',
// // //         sort_order   INTEGER NOT NULL DEFAULT 0,
// // //         image_path   TEXT
// // //       )
// // //     ''');

// // //     // View for TodRepository compatibility
// // //     batch.execute('''
// // //       CREATE VIEW IF NOT EXISTS pack_cards_cache AS
// // //       SELECT id, pack_id, content_json, card_type, difficulty, sort_order, image_path
// // //       FROM pack_cards
// // //     ''');

// // //     batch.execute(
// // //       'CREATE INDEX IF NOT EXISTS idx_cards_pack ON pack_cards(pack_id, sort_order)',
// // //     );

// // //     // Purchases table
// // //     batch.execute('''
// // //       CREATE TABLE IF NOT EXISTS purchases (
// // //         pack_id      TEXT PRIMARY KEY REFERENCES packs(id) ON DELETE CASCADE,
// // //         purchased_at INTEGER NOT NULL,
// // //         expires_at   INTEGER NOT NULL
// // //       )
// // //     ''');

// // //     // Sync log – the missing table that caused the error
// // //     batch.execute('''
// // //       CREATE TABLE IF NOT EXISTS sync_log (
// // //         pack_id        TEXT PRIMARY KEY,
// // //         server_version INTEGER NOT NULL,
// // //         local_version  INTEGER NOT NULL,
// // //         synced_at      INTEGER NOT NULL
// // //       )
// // //     ''');

// // //     // Room cache tables
// // //     batch.execute('''
// // //       CREATE TABLE IF NOT EXISTS cached_rooms (
// // //         id        TEXT PRIMARY KEY,
// // //         data      TEXT NOT NULL,
// // //         cached_at INTEGER NOT NULL
// // //       )
// // //     ''');

// // //     batch.execute('''
// // //       CREATE TABLE IF NOT EXISTS cached_chat_messages (
// // //         id         TEXT PRIMARY KEY,
// // //         room_id    TEXT NOT NULL,
// // //         data       TEXT NOT NULL,
// // //         created_at INTEGER NOT NULL
// // //       )
// // //     ''');

// // //     batch.execute(
// // //       'CREATE INDEX IF NOT EXISTS idx_chat_room ON cached_chat_messages(room_id, created_at)',
// // //     );

// // //     await batch.commit(noResult: true);
// // //     AppLogger.info('Migration 001 applied');
// // //   }

// // //   Future<void> close() async {
// // //     await _db?.close();
// // //     _db = null;
// // //   }
// // // }

// // import 'package:sqflite/sqflite.dart';
// // import 'package:path/path.dart' as p;

// // import '../../utils/app_logger.dart';
// // import '../../../features/offline/data/offline_repository.dart'
// //     show OfflineRepository;

// // /// Offline sessions schema — referenced by AppDatabase migration v2.
// // abstract class OfflineSessionsMigration {
// //   static const schema = OfflineRepository.schemaV2;
// // }

// // /// SQLite database singleton with versioned migrations.
// // ///
// // /// Stores: downloaded pack cards, purchase metadata, offline sync log.
// // /// All game and social data lives in Supabase — SQLite is offline-only.
// // class AppDatabase {
// //   AppDatabase._();
// //   static final AppDatabase instance = AppDatabase._();

// //   static const _dbName = 'jma3a.db';
// //   static const _dbVersion = 4;

// //   Database? _db;
// //   Database get db {
// //     assert(_db != null, 'AppDatabase not opened. Call open() first.');
// //     return _db!;
// //   }

// //   /// Returns the database if open, null otherwise. Use in code that
// //   /// runs before initialization is guaranteed (e.g. screen initState).
// //   Database? get safeDb => (_db?.isOpen ?? false) ? _db : null;

// //   bool get isOpen => _db?.isOpen ?? false;

// //   Future<void> open() async {
// //     if (isOpen) return;

// //     final dbPath = p.join(await getDatabasesPath(), _dbName);

// //     _db = await openDatabase(
// //       dbPath,
// //       version: _dbVersion,
// //       onCreate: _onCreate,
// //       onUpgrade: _onUpgrade,
// //       onConfigure: (db) async {
// //         await db.rawQuery('PRAGMA foreign_keys = ON');
// //         await db.rawQuery('PRAGMA journal_mode = WAL');
// //       },
// //     );

// //     AppLogger.info('SQLite database opened: $dbPath (v$_dbVersion)');
// //   }

// //   // ── Schema creation ────────────────────────────────────────────────────
// //   Future<void> _onCreate(Database db, int version) async {
// //     AppLogger.info('Creating SQLite schema v$version (fresh install)');
// //     // Run all migrations in order from 1 to current version
// //     for (var v = 1; v <= version; v++) {
// //       await _runMigration(db, v);
// //     }
// //   }

// //   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
// //     AppLogger.info('Upgrading SQLite $oldVersion → $newVersion');
// //     for (var v = oldVersion + 1; v <= newVersion; v++) {
// //       await _runMigration(db, v);
// //     }
// //   }

// //   Future<void> _runMigration(Database db, int version) async {
// //     switch (version) {
// //       case 1:
// //         await _migration001(db);
// //       case 2:
// //         await _migration002(db);
// //       case 3:
// //         await _migration003(db);
// //       case 4:
// //         await _migration004(db);
// //     }
// //   }

// //   /// Migration 003: ensure all v1 tables exist (fixes devices that got v2
// //   /// without v1 running due to the onCreate bug — all CREATE TABLE statements
// //   /// use IF NOT EXISTS so this is safe to re-run).
// //   Future<void> _migration003(Database db) async {
// //     await _migration001(db);
// //     AppLogger.info('Migration 003: ensured all base tables exist');
// //   }

// //   Future<void> _migration002(Database db) async {
// //     await db.execute(OfflineSessionsMigration.schema);
// //     AppLogger.info('Migration 002: offline_sessions applied');
// //   }

// //   // ── Migration 001: Initial schema ──────────────────────────────────────
// //   Future<void> _migration001(Database db) async {
// //     final batch = db.batch();

// //     // Downloaded packs (header only — cards in pack_cards table)
// //     batch.execute('''
// //       CREATE TABLE IF NOT EXISTS packs (
// //         id            TEXT PRIMARY KEY,
// //         name_json     TEXT NOT NULL,
// //         cover_url     TEXT,
// //         game_type     TEXT NOT NULL,
// //         language      TEXT NOT NULL DEFAULT 'en',
// //         price         INTEGER NOT NULL DEFAULT 0,
// //         server_version INTEGER NOT NULL DEFAULT 1,
// //         downloaded_at INTEGER NOT NULL,
// //         expires_at    INTEGER
// //       )
// //     ''');

// //     // Individual cards for each downloaded pack
// //     batch.execute('''
// //       CREATE TABLE IF NOT EXISTS pack_cards (
// //         id           TEXT PRIMARY KEY,
// //         pack_id      TEXT NOT NULL REFERENCES packs(id) ON DELETE CASCADE,
// //         content_json TEXT NOT NULL,
// //         card_type    TEXT NOT NULL,
// //         difficulty   TEXT NOT NULL DEFAULT 'mild',
// //         sort_order   INTEGER NOT NULL DEFAULT 0,
// //         image_path   TEXT
// //       )
// //     ''');

// //     // Alias view for TodRepository compatibility
// //     batch.execute('''
// //       CREATE VIEW IF NOT EXISTS pack_cards_cache AS
// //       SELECT id, pack_id, content_json, card_type, difficulty, sort_order, image_path
// //       FROM pack_cards
// //     ''');

// //     batch.execute(
// //       'CREATE INDEX IF NOT EXISTS idx_cards_pack ON pack_cards(pack_id, sort_order)',
// //     );

// //     // Local mirror of server purchase records (for expiry checking offline)
// //     batch.execute('''
// //       CREATE TABLE IF NOT EXISTS purchases (
// //         pack_id      TEXT PRIMARY KEY REFERENCES packs(id) ON DELETE CASCADE,
// //         purchased_at INTEGER NOT NULL,
// //         expires_at   INTEGER NOT NULL
// //       )
// //     ''');

// //     // Sync log: tracks which packs need re-download
// //     batch.execute('''
// //       CREATE TABLE IF NOT EXISTS sync_log (
// //         pack_id        TEXT PRIMARY KEY,
// //         server_version INTEGER NOT NULL,
// //         local_version  INTEGER NOT NULL,
// //         synced_at      INTEGER NOT NULL
// //       )
// //     ''');

// //     // Room cache — used by RoomCacheService
// //     batch.execute('''
// //       CREATE TABLE IF NOT EXISTS cached_rooms (
// //         id        TEXT PRIMARY KEY,
// //         data      TEXT NOT NULL,
// //         cached_at INTEGER NOT NULL
// //       )
// //     ''');

// //     batch.execute('''
// //       CREATE TABLE IF NOT EXISTS cached_chat_messages (
// //         id         TEXT PRIMARY KEY,
// //         room_id    TEXT NOT NULL,
// //         data       TEXT NOT NULL,
// //         created_at INTEGER NOT NULL
// //       )
// //     ''');

// //     batch.execute(
// //       'CREATE INDEX IF NOT EXISTS idx_chat_room ON cached_chat_messages(room_id, created_at)',
// //     );

// //     await batch.commit(noResult: true);
// //     AppLogger.info('Migration 001 applied');
// //   }

// //   /// Migration 004: add pack_cover_url to offline_sessions
// //   Future<void> _migration004(Database db) async {
// //     // ALTER TABLE only adds if column doesn't exist (SQLite doesn't support IF NOT EXISTS
// //     // for ADD COLUMN, so we catch the error if it already exists)
// //     try {
// //       await db.execute(
// //         'ALTER TABLE offline_sessions ADD COLUMN pack_cover_url TEXT',
// //       );
// //       AppLogger.info('Migration 004: added pack_cover_url to offline_sessions');
// //     } catch (_) {
// //       // Column may already exist on fresh installs — safe to ignore
// //       AppLogger.info('Migration 004: pack_cover_url already exists, skipped');
// //     }
// //   }

// //   Future<void> close() async {
// //     await _db?.close();
// //     _db = null;
// //   }
// // }

// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart' as p;

// import '../../utils/app_logger.dart';
// import '../../../features/offline/data/offline_repository.dart'
//     show OfflineRepository;

// /// Offline sessions schema — referenced by AppDatabase migration v2.
// abstract class OfflineSessionsMigration {
//   static const schema = OfflineRepository.schemaV2;
// }

// /// SQLite database singleton with versioned migrations.
// ///
// /// Stores: downloaded pack cards, purchase metadata, offline sync log.
// /// All game and social data lives in Supabase — SQLite is offline-only.
// class AppDatabase {
//   AppDatabase._();
//   static final AppDatabase instance = AppDatabase._();

//   static const _dbName = 'jma3a.db';
//   static const _dbVersion = 5;

//   Database? _db;
//   Database get db {
//     assert(_db != null, 'AppDatabase not opened. Call open() first.');
//     return _db!;
//   }

//   /// Returns the database if open, null otherwise. Use in code that
//   /// runs before initialization is guaranteed (e.g. screen initState).
//   Database? get safeDb => (_db?.isOpen ?? false) ? _db : null;

//   bool get isOpen => _db?.isOpen ?? false;

//   Future<void> open() async {
//     if (isOpen) return;

//     final dbPath = p.join(await getDatabasesPath(), _dbName);

//     _db = await openDatabase(
//       dbPath,
//       version: _dbVersion,
//       onCreate: _onCreate,
//       onUpgrade: _onUpgrade,
//       onConfigure: (db) async {
//         await db.rawQuery('PRAGMA foreign_keys = ON');
//         await db.rawQuery('PRAGMA journal_mode = WAL');
//       },
//     );

//     AppLogger.info('SQLite database opened: $dbPath (v$_dbVersion)');
//   }

//   // ── Schema creation ────────────────────────────────────────────────────
//   Future<void> _onCreate(Database db, int version) async {
//     AppLogger.info('Creating SQLite schema v$version (fresh install)');
//     // Run all migrations in order from 1 to current version
//     for (var v = 1; v <= version; v++) {
//       await _runMigration(db, v);
//     }
//   }

//   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
//     AppLogger.info('Upgrading SQLite $oldVersion → $newVersion');
//     for (var v = oldVersion + 1; v <= newVersion; v++) {
//       await _runMigration(db, v);
//     }
//   }

//   Future<void> _runMigration(Database db, int version) async {
//     switch (version) {
//       case 1:
//         await _migration001(db);
//       case 2:
//         await _migration002(db);
//       case 3:
//         await _migration003(db);
//       case 4:
//         await _migration004(db);
//       case 5:
//         await _migration005(db);
//     }
//   }

//   /// Migration 003: ensure all v1 tables exist (fixes devices that got v2
//   /// without v1 running due to the onCreate bug — all CREATE TABLE statements
//   /// use IF NOT EXISTS so this is safe to re-run).
//   Future<void> _migration003(Database db) async {
//     await _migration001(db);
//     AppLogger.info('Migration 003: ensured all base tables exist');
//   }

//   Future<void> _migration002(Database db) async {
//     await db.execute(OfflineSessionsMigration.schema);
//     AppLogger.info('Migration 002: offline_sessions applied');
//   }

//   // ── Migration 001: Initial schema ──────────────────────────────────────
//   Future<void> _migration001(Database db) async {
//     final batch = db.batch();

//     // Downloaded packs (header only — cards in pack_cards table)
//     batch.execute('''
//       CREATE TABLE IF NOT EXISTS packs (
//         id            TEXT PRIMARY KEY,
//         name_json     TEXT NOT NULL,
//         cover_url     TEXT,
//         game_type     TEXT NOT NULL,
//         language      TEXT NOT NULL DEFAULT 'en',
//         price         INTEGER NOT NULL DEFAULT 0,
//         server_version INTEGER NOT NULL DEFAULT 1,
//         downloaded_at INTEGER NOT NULL,
//         expires_at    INTEGER
//       )
//     ''');

//     // Individual cards for each downloaded pack
//     batch.execute('''
//       CREATE TABLE IF NOT EXISTS pack_cards (
//         id           TEXT PRIMARY KEY,
//         pack_id      TEXT NOT NULL REFERENCES packs(id) ON DELETE CASCADE,
//         content_json TEXT NOT NULL,
//         card_type    TEXT NOT NULL,
//         difficulty   TEXT NOT NULL DEFAULT 'mild',
//         sort_order   INTEGER NOT NULL DEFAULT 0,
//         image_path   TEXT
//       )
//     ''');

//     // Alias view for TodRepository compatibility
//     batch.execute('''
//       CREATE VIEW IF NOT EXISTS pack_cards_cache AS
//       SELECT id, pack_id, content_json, card_type, difficulty, sort_order, image_path
//       FROM pack_cards
//     ''');

//     batch.execute(
//       'CREATE INDEX IF NOT EXISTS idx_cards_pack ON pack_cards(pack_id, sort_order)',
//     );

//     // Local mirror of server purchase records (for expiry checking offline)
//     batch.execute('''
//       CREATE TABLE IF NOT EXISTS purchases (
//         pack_id      TEXT PRIMARY KEY REFERENCES packs(id) ON DELETE CASCADE,
//         purchased_at INTEGER NOT NULL,
//         expires_at   INTEGER NOT NULL
//       )
//     ''');

//     // Sync log: tracks which packs need re-download
//     batch.execute('''
//       CREATE TABLE IF NOT EXISTS sync_log (
//         pack_id        TEXT PRIMARY KEY,
//         server_version INTEGER NOT NULL,
//         local_version  INTEGER NOT NULL,
//         synced_at      INTEGER NOT NULL
//       )
//     ''');

//     // Room cache — used by RoomCacheService
//     batch.execute('''
//       CREATE TABLE IF NOT EXISTS cached_rooms (
//         id        TEXT PRIMARY KEY,
//         data      TEXT NOT NULL,
//         cached_at INTEGER NOT NULL
//       )
//     ''');

//     batch.execute('''
//       CREATE TABLE IF NOT EXISTS cached_chat_messages (
//         id         TEXT PRIMARY KEY,
//         room_id    TEXT NOT NULL,
//         data       TEXT NOT NULL,
//         created_at INTEGER NOT NULL
//       )
//     ''');

//     batch.execute(
//       'CREATE INDEX IF NOT EXISTS idx_chat_room ON cached_chat_messages(room_id, created_at)',
//     );

//     await batch.commit(noResult: true);
//     AppLogger.info('Migration 001 applied');
//   }

//   /// Migration 004: add pack_cover_url to offline_sessions
//   Future<void> _migration004(Database db) async {
//     // ALTER TABLE only adds if column doesn't exist (SQLite doesn't support IF NOT EXISTS
//     // for ADD COLUMN, so we catch the error if it already exists)
//     try {
//       await db.execute(
//         'ALTER TABLE offline_sessions ADD COLUMN pack_cover_url TEXT',
//       );
//       AppLogger.info('Migration 004: added pack_cover_url to offline_sessions');
//     } catch (_) {
//       // Column may already exist on fresh installs — safe to ignore
//       AppLogger.info('Migration 004: pack_cover_url already exists, skipped');
//     }
//   }

//   Future<void> _migration005(Database db) async {
//     // Add local image cache columns to packs table
//     for (final col in ['local_cover_path TEXT', 'local_sticker_paths TEXT']) {
//       try {
//         final colName = col.split(' ').first;
//         await db.execute('ALTER TABLE packs ADD COLUMN $col');
//         AppLogger.info('Migration 005: added $colName to packs');
//       } catch (_) {
//         // Column may already exist (fresh installs from migration001) — safe to ignore
//       }
//     }
//   }

//   Future<void> close() async {
//     await _db?.close();
//     _db = null;
//   }
// }

// // // // // // // // import 'package:sqflite/sqflite.dart';
// // // // // // // // import 'package:path/path.dart' as p;

// // // // // // // // import '../../utils/app_logger.dart';
// // // // // // // // import '../../../features/offline/data/offline_repository.dart' show OfflineRepository;

// // // // // // // // /// Offline sessions schema — referenced by AppDatabase migration v2.
// // // // // // // // abstract class OfflineSessionsMigration {
// // // // // // // //   static const schema = OfflineRepository.schemaV2;
// // // // // // // // }

// // // // // // // // /// SQLite database singleton with versioned migrations.
// // // // // // // // ///
// // // // // // // // /// Stores: downloaded pack cards, purchase metadata, offline sync log.
// // // // // // // // /// All game and social data lives in Supabase — SQLite is offline-only.
// // // // // // // // class AppDatabase {
// // // // // // // //   AppDatabase._();
// // // // // // // //   static final AppDatabase instance = AppDatabase._();

// // // // // // // //   static const _dbName    = 'jma3a.db';
// // // // // // // //   static const _dbVersion = 2;

// // // // // // // //   Database? _db;
// // // // // // // //   Database get db {
// // // // // // // //     assert(_db != null, 'AppDatabase not opened. Call open() first.');
// // // // // // // //     return _db!;
// // // // // // // //   }

// // // // // // // //   bool get isOpen => _db?.isOpen ?? false;

// // // // // // // //   Future<void> open() async {
// // // // // // // //     if (isOpen) return;

// // // // // // // //     final dbPath = p.join(await getDatabasesPath(), _dbName);

// // // // // // // //     _db = await openDatabase(
// // // // // // // //       dbPath,
// // // // // // // //       version: _dbVersion,
// // // // // // // //       onCreate: _onCreate,
// // // // // // // //       onUpgrade: _onUpgrade,
// // // // // // // //       onConfigure: (db) async {
// // // // // // // //         // Enable foreign key enforcement
// // // // // // // //         await db.execute('PRAGMA foreign_keys = ON');
// // // // // // // //         // Write-ahead logging for better concurrent read performance
// // // // // // // //         await db.execute('PRAGMA journal_mode = WAL');
// // // // // // // //       },
// // // // // // // //     );

// // // // // // // //     AppLogger.info('SQLite database opened: $dbPath (v$_dbVersion)');
// // // // // // // //   }

// // // // // // // //   // ── Schema creation ────────────────────────────────────────────────────
// // // // // // // //   Future<void> _onCreate(Database db, int version) async {
// // // // // // // //     AppLogger.info('Creating SQLite schema v$version');
// // // // // // // //     await _runMigration(db, version);
// // // // // // // //   }

// // // // // // // //   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
// // // // // // // //     AppLogger.info('Upgrading SQLite $oldVersion → $newVersion');
// // // // // // // //     for (var v = oldVersion + 1; v <= newVersion; v++) {
// // // // // // // //       await _runMigration(db, v);
// // // // // // // //     }
// // // // // // // //   }

// // // // // // // //   Future<void> _runMigration(Database db, int version) async {
// // // // // // // //     switch (version) {
// // // // // // // //       case 1:
// // // // // // // //         await _migration001(db);
// // // // // // // //       case 2:
// // // // // // // //         await _migration002(db);
// // // // // // // //     }
// // // // // // // //   }

// // // // // // // //   Future<void> _migration002(Database db) async {
// // // // // // // //     await db.execute(OfflineSessionsMigration.schema);
// // // // // // // //     AppLogger.info('Migration 002: offline_sessions applied');
// // // // // // // //   }

// // // // // // // //   // ── Migration 001: Initial schema ──────────────────────────────────────
// // // // // // // //   Future<void> _migration001(Database db) async {
// // // // // // // //     final batch = db.batch();

// // // // // // // //     // Downloaded packs (header only — cards in pack_cards table)
// // // // // // // //     batch.execute('''
// // // // // // // //       CREATE TABLE IF NOT EXISTS packs (
// // // // // // // //         id            TEXT PRIMARY KEY,
// // // // // // // //         name_json     TEXT NOT NULL,
// // // // // // // //         cover_url     TEXT,
// // // // // // // //         game_type     TEXT NOT NULL,
// // // // // // // //         language      TEXT NOT NULL DEFAULT 'en',
// // // // // // // //         price         INTEGER NOT NULL DEFAULT 0,
// // // // // // // //         server_version INTEGER NOT NULL DEFAULT 1,
// // // // // // // //         downloaded_at INTEGER NOT NULL,
// // // // // // // //         expires_at    INTEGER
// // // // // // // //       )
// // // // // // // //     ''');

// // // // // // // //     // Individual cards for each downloaded pack
// // // // // // // //     batch.execute('''
// // // // // // // //       CREATE TABLE IF NOT EXISTS pack_cards (
// // // // // // // //         id           TEXT PRIMARY KEY,
// // // // // // // //         pack_id      TEXT NOT NULL REFERENCES packs(id) ON DELETE CASCADE,
// // // // // // // //         content_json TEXT NOT NULL,
// // // // // // // //         card_type    TEXT NOT NULL,
// // // // // // // //         difficulty   TEXT NOT NULL DEFAULT 'mild',
// // // // // // // //         sort_order   INTEGER NOT NULL DEFAULT 0,
// // // // // // // //         image_path   TEXT
// // // // // // // //       )
// // // // // // // //     ''');

// // // // // // // //     // Alias view for TodRepository compatibility
// // // // // // // //     batch.execute('''
// // // // // // // //       CREATE VIEW IF NOT EXISTS pack_cards_cache AS
// // // // // // // //       SELECT id, pack_id, content_json, card_type, difficulty, sort_order, image_path
// // // // // // // //       FROM pack_cards
// // // // // // // //     ''');

// // // // // // // //     batch.execute(
// // // // // // // //       'CREATE INDEX IF NOT EXISTS idx_cards_pack ON pack_cards(pack_id, sort_order)',
// // // // // // // //     );

// // // // // // // //     // Local mirror of server purchase records (for expiry checking offline)
// // // // // // // //     batch.execute('''
// // // // // // // //       CREATE TABLE IF NOT EXISTS purchases (
// // // // // // // //         pack_id      TEXT PRIMARY KEY REFERENCES packs(id) ON DELETE CASCADE,
// // // // // // // //         purchased_at INTEGER NOT NULL,
// // // // // // // //         expires_at   INTEGER NOT NULL
// // // // // // // //       )
// // // // // // // //     ''');

// // // // // // // //     // Sync log: tracks which packs need re-download
// // // // // // // //     batch.execute('''
// // // // // // // //       CREATE TABLE IF NOT EXISTS sync_log (
// // // // // // // //         pack_id        TEXT PRIMARY KEY,
// // // // // // // //         server_version INTEGER NOT NULL,
// // // // // // // //         local_version  INTEGER NOT NULL,
// // // // // // // //         synced_at      INTEGER NOT NULL
// // // // // // // //       )
// // // // // // // //     ''');

// // // // // // // //     await batch.commit(noResult: true);
// // // // // // // //     AppLogger.info('Migration 001 applied');
// // // // // // // //   }

// // // // // // // //   Future<void> close() async {
// // // // // // // //     await _db?.close();
// // // // // // // //     _db = null;
// // // // // // // //   }
// // // // // // // // }

// // // // // // // import 'dart:io';

// // // // // // // import 'package:sqflite/sqflite.dart';
// // // // // // // import 'package:path/path.dart' as p;

// // // // // // // import '../../utils/app_logger.dart';
// // // // // // // import '../../../features/offline/data/offline_repository.dart'
// // // // // // //     show OfflineRepository;

// // // // // // // /// Offline sessions schema — referenced by AppDatabase migration v2.
// // // // // // // abstract class OfflineSessionsMigration {
// // // // // // //   static const schema = OfflineRepository.schemaV2;
// // // // // // // }

// // // // // // // /// SQLite database singleton with versioned migrations.
// // // // // // // ///
// // // // // // // /// Stores: downloaded pack cards, purchase metadata, offline sync log.
// // // // // // // /// All game and social data lives in Supabase — SQLite is offline-only.
// // // // // // // class AppDatabase {
// // // // // // //   AppDatabase._();
// // // // // // //   static final AppDatabase instance = AppDatabase._();

// // // // // // //   static const _dbName = 'jma3a.db';
// // // // // // //   static const _dbVersion = 2;

// // // // // // //   Database? _db;

// // // // // // //   Database get db {
// // // // // // //     if (_db == null) {
// // // // // // //       throw StateError('AppDatabase not opened. Call open() first.');
// // // // // // //     }
// // // // // // //     return _db!;
// // // // // // //   }

// // // // // // //   bool get isOpen => _db?.isOpen ?? false;

// // // // // // //   // Future<void> open() async {
// // // // // // //   //   if (isOpen) return;

// // // // // // //   //   try {
// // // // // // //   //     final dbPath = p.join(await getDatabasesPath(), _dbName);

// // // // // // //   //     _db = await openDatabase(
// // // // // // //   //       dbPath,
// // // // // // //   //       version: _dbVersion,
// // // // // // //   //       onCreate: _onCreate,
// // // // // // //   //       onUpgrade: _onUpgrade,
// // // // // // //   //       onConfigure: (db) async {
// // // // // // //   //         await db.execute('PRAGMA foreign_keys = ON');
// // // // // // //   //         await db.execute('PRAGMA journal_mode = WAL');
// // // // // // //   //       },
// // // // // // //   //     );

// // // // // // //   //     AppLogger.info('SQLite database opened: $dbPath (v$_dbVersion)');
// // // // // // //   //   } catch (e) {
// // // // // // //   //     AppLogger.error('Failed to open database: $e');
// // // // // // //   //     rethrow;
// // // // // // //   //   }
// // // // // // //   // }

// // // // // // //   Future<void> open() async {
// // // // // // //     if (isOpen) return;

// // // // // // //     final dbPath = p.join(await getDatabasesPath(), _dbName);
// // // // // // //     final directory = p.dirname(dbPath);
// // // // // // //     await Directory(directory).create(recursive: true);

// // // // // // //     // Delete corrupted database if needed (uncomment once)
// // // // // // //     // final file = File(dbPath);
// // // // // // //     // if (await file.exists()) await file.delete();

// // // // // // //     _db = await openDatabase(
// // // // // // //       dbPath,
// // // // // // //       version: _dbVersion,
// // // // // // //       onCreate: _onCreate,
// // // // // // //       onUpgrade: _onUpgrade,
// // // // // // //       // Do not use onConfigure or onOpen
// // // // // // //     );

// // // // // // //     // ✅ Success – no PRAGMA statements
// // // // // // //     AppLogger.info('SQLite database opened: $dbPath (v$_dbVersion)');
// // // // // // //   }

// // // // // // //   // Helper method to safely execute database operations
// // // // // // //   Future<T?> safeDbOperation<T>(
// // // // // // //     Future<T> Function(Database db) operation,
// // // // // // //   ) async {
// // // // // // //     if (!isOpen) {
// // // // // // //       AppLogger.warning('Database not open, skipping operation');
// // // // // // //       return null;
// // // // // // //     }
// // // // // // //     try {
// // // // // // //       return await operation(_db!);
// // // // // // //     } catch (e) {
// // // // // // //       AppLogger.error('Database operation failed: $e');
// // // // // // //       return null;
// // // // // // //     }
// // // // // // //   }

// // // // // // //   // ── Schema creation ────────────────────────────────────────────────────
// // // // // // //   Future<void> _onCreate(Database db, int version) async {
// // // // // // //     AppLogger.info('Creating SQLite schema v$version');
// // // // // // //     await _runMigration(db, version);
// // // // // // //   }

// // // // // // //   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
// // // // // // //     AppLogger.info('Upgrading SQLite $oldVersion → $newVersion');
// // // // // // //     for (var v = oldVersion + 1; v <= newVersion; v++) {
// // // // // // //       await _runMigration(db, v);
// // // // // // //     }
// // // // // // //   }

// // // // // // //   Future<void> _runMigration(Database db, int version) async {
// // // // // // //     switch (version) {
// // // // // // //       case 1:
// // // // // // //         await _migration001(db);
// // // // // // //       case 2:
// // // // // // //         await _migration002(db);
// // // // // // //     }
// // // // // // //   }

// // // // // // //   Future<void> _migration002(Database db) async {
// // // // // // //     await db.execute(OfflineSessionsMigration.schema);
// // // // // // //     AppLogger.info('Migration 002: offline_sessions applied');
// // // // // // //   }

// // // // // // //   // ── Migration 001: Initial schema ──────────────────────────────────────
// // // // // // //   Future<void> _migration001(Database db) async {
// // // // // // //     final batch = db.batch();

// // // // // // //     batch.execute('''
// // // // // // //       CREATE TABLE IF NOT EXISTS packs (
// // // // // // //         id            TEXT PRIMARY KEY,
// // // // // // //         name_json     TEXT NOT NULL,
// // // // // // //         cover_url     TEXT,
// // // // // // //         game_type     TEXT NOT NULL,
// // // // // // //         language      TEXT NOT NULL DEFAULT 'en',
// // // // // // //         price         INTEGER NOT NULL DEFAULT 0,
// // // // // // //         server_version INTEGER NOT NULL DEFAULT 1,
// // // // // // //         downloaded_at INTEGER NOT NULL,
// // // // // // //         expires_at    INTEGER
// // // // // // //       )
// // // // // // //     ''');

// // // // // // //     batch.execute('''
// // // // // // //       CREATE TABLE IF NOT EXISTS pack_cards (
// // // // // // //         id           TEXT PRIMARY KEY,
// // // // // // //         pack_id      TEXT NOT NULL REFERENCES packs(id) ON DELETE CASCADE,
// // // // // // //         content_json TEXT NOT NULL,
// // // // // // //         card_type    TEXT NOT NULL,
// // // // // // //         difficulty   TEXT NOT NULL DEFAULT 'mild',
// // // // // // //         sort_order   INTEGER NOT NULL DEFAULT 0,
// // // // // // //         image_path   TEXT
// // // // // // //       )
// // // // // // //     ''');

// // // // // // //     batch.execute('''
// // // // // // //       CREATE VIEW IF NOT EXISTS pack_cards_cache AS
// // // // // // //       SELECT id, pack_id, content_json, card_type, difficulty, sort_order, image_path
// // // // // // //       FROM pack_cards
// // // // // // //     ''');

// // // // // // //     batch.execute(
// // // // // // //       'CREATE INDEX IF NOT EXISTS idx_cards_pack ON pack_cards(pack_id, sort_order)',
// // // // // // //     );

// // // // // // //     batch.execute('''
// // // // // // //       CREATE TABLE IF NOT EXISTS purchases (
// // // // // // //         pack_id      TEXT PRIMARY KEY REFERENCES packs(id) ON DELETE CASCADE,
// // // // // // //         purchased_at INTEGER NOT NULL,
// // // // // // //         expires_at   INTEGER NOT NULL
// // // // // // //       )
// // // // // // //     ''');

// // // // // // //     batch.execute('''
// // // // // // //       CREATE TABLE IF NOT EXISTS sync_log (
// // // // // // //         pack_id        TEXT PRIMARY KEY,
// // // // // // //         server_version INTEGER NOT NULL,
// // // // // // //         local_version  INTEGER NOT NULL,
// // // // // // //         synced_at      INTEGER NOT NULL
// // // // // // //       )
// // // // // // //     ''');

// // // // // // //     await batch.commit(noResult: true);
// // // // // // //     AppLogger.info('Migration 001 applied');
// // // // // // //   }

// // // // // // //   Future<void> close() async {
// // // // // // //     await _db?.close();
// // // // // // //     _db = null;
// // // // // // //   }
// // // // // // // }

// // // // // // import 'dart:io';
// // // // // // import 'package:sqflite/sqflite.dart';
// // // // // // import 'package:path/path.dart' as p;
// // // // // // import '../../utils/app_logger.dart';
// // // // // // import '../../../features/offline/data/offline_repository.dart'
// // // // // //     show OfflineRepository;

// // // // // // abstract class OfflineSessionsMigration {
// // // // // //   static const schema = OfflineRepository.schemaV2;
// // // // // // }

// // // // // // class AppDatabase {
// // // // // //   AppDatabase._();
// // // // // //   static final AppDatabase instance = AppDatabase._();

// // // // // //   static const _dbName = 'jma3a.db';
// // // // // //   static const _dbVersion = 2;

// // // // // //   Database? _db;
// // // // // //   Database get db {
// // // // // //     assert(_db != null, 'AppDatabase not opened. Call open() first.');
// // // // // //     return _db!;
// // // // // //   }

// // // // // //   bool get isOpen => _db?.isOpen ?? false;

// // // // // //   // Future<void> open() async {
// // // // // //   //   if (isOpen) return;

// // // // // //   //   final dbPath = p.join(await getDatabasesPath(), _dbName);
// // // // // //   //   final directory = p.dirname(dbPath);
// // // // // //   //   await Directory(directory).create(recursive: true);

// // // // // //   //   // Check if database exists and is valid
// // // // // //   //   final file = File(dbPath);
// // // // // //   //   bool needsRecreation = false;

// // // // // //   //   if (await file.exists()) {
// // // // // //   //     // Try to open and verify a table exists
// // // // // //   //     try {
// // // // // //   //       final testDb = await openDatabase(dbPath, readOnly: true);
// // // // // //   //       final result = await testDb.rawQuery(
// // // // // //   //         "SELECT name FROM sqlite_master WHERE type='table' AND name='packs'",
// // // // // //   //       );
// // // // // //   //       await testDb.close();
// // // // // //   //       if (result.isEmpty) {
// // // // // //   //         needsRecreation = true;
// // // // // //   //         AppLogger.warning(
// // // // // //   //           'Database exists but missing packs table – will recreate',
// // // // // //   //         );
// // // // // //   //       }
// // // // // //   //     } catch (e) {
// // // // // //   //       needsRecreation = true;
// // // // // //   //       AppLogger.warning('Database file corrupted – will recreate', error: e);
// // // // // //   //     }
// // // // // //   //   }

// // // // // //   //   if (needsRecreation) {
// // // // // //   //     await file.delete();
// // // // // //   //     AppLogger.info('Deleted invalid database file');
// // // // // //   //   }

// // // // // //   //   _db = await openDatabase(
// // // // // //   //     dbPath,
// // // // // //   //     version: _dbVersion,
// // // // // //   //     onCreate: _onCreate,
// // // // // //   //     onUpgrade: _onUpgrade,
// // // // // //   //   );

// // // // // //   //   AppLogger.info('SQLite database opened: $dbPath (v$_dbVersion)');
// // // // // //   // }
// // // // // //   Future<void> open() async {
// // // // // //     if (isOpen) return;

// // // // // //     final dbPath = p.join(await getDatabasesPath(), _dbName);
// // // // // //     final directory = p.dirname(dbPath);
// // // // // //     await Directory(directory).create(recursive: true);

// // // // // //     final file = File(dbPath);
// // // // // //     if (await file.exists()) {
// // // // // //       AppLogger.warning('Deleting existing database file (force recreation)');
// // // // // //       // await file.delete();
// // // // // //       await deleteDatabase(dbPath);
// // // // // //     }

// // // // // //     // _db = await openDatabase(
// // // // // //     //   dbPath,
// // // // // //     //   version: _dbVersion,
// // // // // //     //   onCreate: (db, version) async {
// // // // // //     //     AppLogger.info('onCreate called with version $version');
// // // // // //     //     await _runMigration(db, version);
// // // // // //     //     // Verify table creation
// // // // // //     //     final count = await db.rawQuery(
// // // // // //     //       "SELECT name FROM sqlite_master WHERE type='table' AND name='packs'",
// // // // // //     //     );
// // // // // //     //     AppLogger.info(
// // // // // //     //       'After migration, packs table exists: ${count.isNotEmpty}',
// // // // // //     //     );
// // // // // //     //   },
// // // // // //     //   onUpgrade: (db, oldVersion, newVersion) async {
// // // // // //     //     AppLogger.info('onUpgrade from $oldVersion to $newVersion');
// // // // // //     //     for (var v = oldVersion + 1; v <= newVersion; v++) {
// // // // // //     //       await _runMigration(db, v);
// // // // // //     //     }
// // // // // //     //   },
// // // // // //     // );
// // // // // //     _db = await openDatabase(
// // // // // //       dbPath,
// // // // // //       version: _dbVersion,
// // // // // //       onCreate: _onCreate,
// // // // // //       onUpgrade: _onUpgrade,
// // // // // //     );

// // // // // //     // Final verification
// // // // // //     final check = await _db!.rawQuery(
// // // // // //       "SELECT name FROM sqlite_master WHERE type='table' AND name='packs'",
// // // // // //     );
// // // // // //     if (check.isEmpty) {
// // // // // //       throw Exception('Failed to create packs table – schema missing');
// // // // // //     }

// // // // // //     AppLogger.info('SQLite database opened successfully: $dbPath');
// // // // // //   }

// // // // // //   // Future<void> _onCreate(Database db, int version) async {
// // // // // //   //   for (var v = 1; v <= version; v++) {
// // // // // //   //     await _runMigration(db, v);
// // // // // //   //   }
// // // // // //   // }
// // // // // //   Future<void> _onCreate(Database db, int version) async {
// // // // // //     await _migration001(db);
// // // // // //     await _migration002(db);
// // // // // //   }

// // // // // //   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
// // // // // //     for (var v = oldVersion + 1; v <= newVersion; v++) {
// // // // // //       await _runMigration(db, v);
// // // // // //     }
// // // // // //   }

// // // // // //   Future<void> _runMigration(Database db, int version) async {
// // // // // //     AppLogger.info('Running migration for version $version');
// // // // // //     switch (version) {
// // // // // //       case 1:
// // // // // //         await _migration001(db);
// // // // // //         break;
// // // // // //       case 2:
// // // // // //         await _migration002(db);
// // // // // //         break;
// // // // // //       default:
// // // // // //         AppLogger.warning('Unknown migration version $version');
// // // // // //     }
// // // // // //   }

// // // // // //   // Future<void> _onCreate(Database db, int version) async {
// // // // // //   //   AppLogger.info('Creating SQLite schema v$version');
// // // // // //   //   await _runMigration(db, version);
// // // // // //   // }

// // // // // //   // Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
// // // // // //   //   AppLogger.info('Upgrading SQLite $oldVersion → $newVersion');
// // // // // //   //   for (var v = oldVersion + 1; v <= newVersion; v++) {
// // // // // //   //     await _runMigration(db, v);
// // // // // //   //   }
// // // // // //   // }

// // // // // //   // Future<void> _runMigration(Database db, int version) async {
// // // // // //   //   switch (version) {
// // // // // //   //     case 1:
// // // // // //   //       await _migration001(db);
// // // // // //   //     case 2:
// // // // // //   //       await _migration002(db);
// // // // // //   //   }
// // // // // //   // }

// // // // // //   Future<void> _migration002(Database db) async {
// // // // // //     await db.execute(OfflineSessionsMigration.schema);
// // // // // //     AppLogger.info('Migration 002: offline_sessions applied');
// // // // // //   }

// // // // // //   Future<void> _migration001(Database db) async {
// // // // // //     try {
// // // // // //       final batch = db.batch();

// // // // // //       // Downloaded packs
// // // // // //       batch.execute('''
// // // // // //       CREATE TABLE IF NOT EXISTS packs (
// // // // // //         id            TEXT PRIMARY KEY,
// // // // // //         name_json     TEXT NOT NULL,
// // // // // //         cover_url     TEXT,
// // // // // //         game_type     TEXT NOT NULL,
// // // // // //         language      TEXT NOT NULL DEFAULT 'en',
// // // // // //         price         INTEGER NOT NULL DEFAULT 0,
// // // // // //         server_version INTEGER NOT NULL DEFAULT 1,
// // // // // //         downloaded_at INTEGER NOT NULL,
// // // // // //         expires_at    INTEGER
// // // // // //       )
// // // // // //     ''');

// // // // // //       // Pack cards
// // // // // //       batch.execute('''
// // // // // //       CREATE TABLE IF NOT EXISTS pack_cards (
// // // // // //         id           TEXT PRIMARY KEY,
// // // // // //         pack_id      TEXT NOT NULL REFERENCES packs(id) ON DELETE CASCADE,
// // // // // //         content_json TEXT NOT NULL,
// // // // // //         card_type    TEXT NOT NULL,
// // // // // //         difficulty   TEXT NOT NULL DEFAULT 'mild',
// // // // // //         sort_order   INTEGER NOT NULL DEFAULT 0,
// // // // // //         image_path   TEXT
// // // // // //       )
// // // // // //     ''');

// // // // // //       // View for compatibility
// // // // // //       batch.execute('''
// // // // // //       CREATE VIEW IF NOT EXISTS pack_cards_cache AS
// // // // // //       SELECT id, pack_id, content_json, card_type, difficulty, sort_order, image_path
// // // // // //       FROM pack_cards
// // // // // //     ''');

// // // // // //       batch.execute(
// // // // // //         'CREATE INDEX IF NOT EXISTS idx_cards_pack ON pack_cards(pack_id, sort_order)',
// // // // // //       );

// // // // // //       // Purchases table
// // // // // //       batch.execute('''
// // // // // //       CREATE TABLE IF NOT EXISTS purchases (
// // // // // //         pack_id      TEXT PRIMARY KEY REFERENCES packs(id) ON DELETE CASCADE,
// // // // // //         purchased_at INTEGER NOT NULL,
// // // // // //         expires_at   INTEGER NOT NULL
// // // // // //       )
// // // // // //     ''');

// // // // // //       // Sync log
// // // // // //       batch.execute('''
// // // // // //       CREATE TABLE IF NOT EXISTS sync_log (
// // // // // //         pack_id        TEXT PRIMARY KEY,
// // // // // //         server_version INTEGER NOT NULL,
// // // // // //         local_version  INTEGER NOT NULL,
// // // // // //         synced_at      INTEGER NOT NULL
// // // // // //       )
// // // // // //     ''');

// // // // // //       await batch.commit(noResult: true);
// // // // // //       AppLogger.info('Migration 001 applied');
// // // // // //     } catch (e, st) {
// // // // // //       AppLogger.error('Migration 001 failed', error: e, stackTrace: st);
// // // // // //       rethrow;
// // // // // //     }
// // // // // //   }

// // // // // //   Future<void> close() async {
// // // // // //     await _db?.close();
// // // // // //     _db = null;
// // // // // //   }
// // // // // // }

// // // // // // import 'package:sqflite/sqflite.dart';
// // // // // // import 'package:path/path.dart' as p;

// // // // // // import '../../utils/app_logger.dart';
// // // // // // import '../../../features/offline/data/offline_repository.dart'
// // // // // //     show OfflineRepository;

// // // // // // /// Offline sessions schema — referenced by AppDatabase migration v2.
// // // // // // abstract class OfflineSessionsMigration {
// // // // // //   static const schema = OfflineRepository.schemaV2;
// // // // // // }

// // // // // // /// SQLite database singleton with versioned migrations.
// // // // // // ///
// // // // // // /// Stores: downloaded pack cards, purchase metadata, offline sync log.
// // // // // // /// All game and social data lives in Supabase — SQLite is offline-only.
// // // // // // class AppDatabase {
// // // // // //   AppDatabase._();
// // // // // //   static final AppDatabase instance = AppDatabase._();

// // // // // //   static const _dbName = 'jma3a.db';
// // // // // //   static const _dbVersion = 2;

// // // // // //   Database? _db;
// // // // // //   Database get db {
// // // // // //     assert(_db != null, 'AppDatabase not opened. Call open() first.');
// // // // // //     return _db!;
// // // // // //   }

// // // // // //   /// Returns the database if open, null otherwise. Use in code that
// // // // // //   /// runs before initialization is guaranteed (e.g. screen initState).
// // // // // //   Database? get safeDb => (_db?.isOpen ?? false) ? _db : null;

// // // // // //   bool get isOpen => _db?.isOpen ?? false;

// // // // // //   Future<void> open() async {
// // // // // //     if (isOpen) return;

// // // // // //     final dbPath = p.join(await getDatabasesPath(), _dbName);

// // // // // //     _db = await openDatabase(
// // // // // //       dbPath,
// // // // // //       version: _dbVersion,
// // // // // //       onCreate: _onCreate,
// // // // // //       onUpgrade: _onUpgrade,
// // // // // //       onConfigure: (db) async {
// // // // // //         await db.rawQuery('PRAGMA foreign_keys = ON');
// // // // // //         await db.rawQuery('PRAGMA journal_mode = WAL');
// // // // // //       },
// // // // // //     );

// // // // // //     AppLogger.info('SQLite database opened: $dbPath (v$_dbVersion)');
// // // // // //   }

// // // // // //   // ── Schema creation ────────────────────────────────────────────────────
// // // // // //   Future<void> _onCreate(Database db, int version) async {
// // // // // //     AppLogger.info('Creating SQLite schema v$version');
// // // // // //     await _runMigration(db, version);
// // // // // //   }

// // // // // //   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
// // // // // //     AppLogger.info('Upgrading SQLite $oldVersion → $newVersion');
// // // // // //     for (var v = oldVersion + 1; v <= newVersion; v++) {
// // // // // //       await _runMigration(db, v);
// // // // // //     }
// // // // // //   }

// // // // // //   Future<void> _runMigration(Database db, int version) async {
// // // // // //     switch (version) {
// // // // // //       case 1:
// // // // // //         await _migration001(db);
// // // // // //       case 2:
// // // // // //         await _migration002(db);
// // // // // //     }
// // // // // //   }

// // // // // //   Future<void> _migration002(Database db) async {
// // // // // //     await db.execute(OfflineSessionsMigration.schema);
// // // // // //     AppLogger.info('Migration 002: offline_sessions applied');
// // // // // //   }

// // // // // //   // ── Migration 001: Initial schema ──────────────────────────────────────
// // // // // //   Future<void> _migration001(Database db) async {
// // // // // //     final batch = db.batch();

// // // // // //     // Downloaded packs (header only — cards in pack_cards table)
// // // // // //     batch.execute('''
// // // // // //       CREATE TABLE IF NOT EXISTS packs (
// // // // // //         id            TEXT PRIMARY KEY,
// // // // // //         name_json     TEXT NOT NULL,
// // // // // //         cover_url     TEXT,
// // // // // //         game_type     TEXT NOT NULL,
// // // // // //         language      TEXT NOT NULL DEFAULT 'en',
// // // // // //         price         INTEGER NOT NULL DEFAULT 0,
// // // // // //         server_version INTEGER NOT NULL DEFAULT 1,
// // // // // //         downloaded_at INTEGER NOT NULL,
// // // // // //         expires_at    INTEGER
// // // // // //       )
// // // // // //     ''');

// // // // // //     // Individual cards for each downloaded pack
// // // // // //     batch.execute('''
// // // // // //       CREATE TABLE IF NOT EXISTS pack_cards (
// // // // // //         id           TEXT PRIMARY KEY,
// // // // // //         pack_id      TEXT NOT NULL REFERENCES packs(id) ON DELETE CASCADE,
// // // // // //         content_json TEXT NOT NULL,
// // // // // //         card_type    TEXT NOT NULL,
// // // // // //         difficulty   TEXT NOT NULL DEFAULT 'mild',
// // // // // //         sort_order   INTEGER NOT NULL DEFAULT 0,
// // // // // //         image_path   TEXT
// // // // // //       )
// // // // // //     ''');

// // // // // //     // Alias view for TodRepository compatibility
// // // // // //     batch.execute('''
// // // // // //       CREATE VIEW IF NOT EXISTS pack_cards_cache AS
// // // // // //       SELECT id, pack_id, content_json, card_type, difficulty, sort_order, image_path
// // // // // //       FROM pack_cards
// // // // // //     ''');

// // // // // //     batch.execute(
// // // // // //       'CREATE INDEX IF NOT EXISTS idx_cards_pack ON pack_cards(pack_id, sort_order)',
// // // // // //     );

// // // // // //     // Local mirror of server purchase records (for expiry checking offline)
// // // // // //     batch.execute('''
// // // // // //       CREATE TABLE IF NOT EXISTS purchases (
// // // // // //         pack_id      TEXT PRIMARY KEY REFERENCES packs(id) ON DELETE CASCADE,
// // // // // //         purchased_at INTEGER NOT NULL,
// // // // // //         expires_at   INTEGER NOT NULL
// // // // // //       )
// // // // // //     ''');

// // // // // //     // Sync log: tracks which packs need re-download
// // // // // //     batch.execute('''
// // // // // //       CREATE TABLE IF NOT EXISTS sync_log (
// // // // // //         pack_id        TEXT PRIMARY KEY,
// // // // // //         server_version INTEGER NOT NULL,
// // // // // //         local_version  INTEGER NOT NULL,
// // // // // //         synced_at      INTEGER NOT NULL
// // // // // //       )
// // // // // //     ''');

// // // // // //     // Room cache — used by RoomCacheService
// // // // // //     batch.execute('''
// // // // // //       CREATE TABLE IF NOT EXISTS cached_rooms (
// // // // // //         id        TEXT PRIMARY KEY,
// // // // // //         data      TEXT NOT NULL,
// // // // // //         cached_at INTEGER NOT NULL
// // // // // //       )
// // // // // //     ''');

// // // // // //     batch.execute('''
// // // // // //       CREATE TABLE IF NOT EXISTS cached_chat_messages (
// // // // // //         id         TEXT PRIMARY KEY,
// // // // // //         room_id    TEXT NOT NULL,
// // // // // //         data       TEXT NOT NULL,
// // // // // //         created_at INTEGER NOT NULL
// // // // // //       )
// // // // // //     ''');

// // // // // //     batch.execute(
// // // // // //       'CREATE INDEX IF NOT EXISTS idx_chat_room ON cached_chat_messages(room_id, created_at)',
// // // // // //     );

// // // // // //     await batch.commit(noResult: true);
// // // // // //     AppLogger.info('Migration 001 applied');
// // // // // //   }

// // // // // //   Future<void> close() async {
// // // // // //     await _db?.close();
// // // // // //     _db = null;
// // // // // //   }
// // // // // // }

// // // // // import 'package:sqflite/sqflite.dart';
// // // // // import 'package:path/path.dart' as p;

// // // // // import '../../utils/app_logger.dart';
// // // // // import '../../../features/offline/data/offline_repository.dart'
// // // // //     show OfflineRepository;

// // // // // /// Offline sessions schema — referenced by AppDatabase migration v2.
// // // // // abstract class OfflineSessionsMigration {
// // // // //   static const schema = OfflineRepository.schemaV2;
// // // // // }

// // // // // /// SQLite database singleton with versioned migrations.
// // // // // ///
// // // // // /// Stores: downloaded pack cards, purchase metadata, offline sync log.
// // // // // /// All game and social data lives in Supabase — SQLite is offline-only.
// // // // // class AppDatabase {
// // // // //   AppDatabase._();
// // // // //   static final AppDatabase instance = AppDatabase._();

// // // // //   static const _dbName = 'jma3a.db';
// // // // //   static const _dbVersion = 3; // ✅ increased to 3

// // // // //   Database? _db;
// // // // //   Database get db {
// // // // //     assert(_db != null, 'AppDatabase not opened. Call open() first.');
// // // // //     return _db!;
// // // // //   }

// // // // //   /// Returns the database if open, null otherwise. Use in code that
// // // // //   /// runs before initialization is guaranteed (e.g. screen initState).
// // // // //   Database? get safeDb => (_db?.isOpen ?? false) ? _db : null;

// // // // //   bool get isOpen => _db?.isOpen ?? false;

// // // // //   Future<void> open() async {
// // // // //     if (isOpen) return;

// // // // //     final dbPath = p.join(await getDatabasesPath(), _dbName);

// // // // //     _db = await openDatabase(
// // // // //       dbPath,
// // // // //       version: _dbVersion,
// // // // //       onCreate: _onCreate,
// // // // //       onUpgrade: _onUpgrade,
// // // // //       onConfigure: (db) async {
// // // // //         await db.rawQuery('PRAGMA foreign_keys = ON');
// // // // //         await db.rawQuery('PRAGMA journal_mode = WAL');
// // // // //       },
// // // // //     );

// // // // //     AppLogger.info('SQLite database opened: $dbPath (v$_dbVersion)');
// // // // //   }

// // // // //   // ── Schema creation ────────────────────────────────────────────────────
// // // // //   Future<void> _onCreate(Database db, int version) async {
// // // // //     AppLogger.info('Creating SQLite schema v$version');
// // // // //     await _runMigration(db, version);
// // // // //   }

// // // // //   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
// // // // //     AppLogger.info('Upgrading SQLite $oldVersion → $newVersion');
// // // // //     for (var v = oldVersion + 1; v <= newVersion; v++) {
// // // // //       await _runMigration(db, v);
// // // // //     }
// // // // //   }

// // // // //   Future<void> _runMigration(Database db, int version) async {
// // // // //     switch (version) {
// // // // //       case 1:
// // // // //         await _migration001(db);
// // // // //       case 2:
// // // // //         await _migration002(db);
// // // // //       case 3:
// // // // //         await _migration003(db);
// // // // //     }
// // // // //   }

// // // // //   Future<void> _migration002(Database db) async {
// // // // //     await db.execute(OfflineSessionsMigration.schema);
// // // // //     AppLogger.info('Migration 002: offline_sessions applied');
// // // // //   }

// // // // //   Future<void> _migration003(Database db) async {
// // // // //     // Add is_active column to pack_cards (default 1 = active)
// // // // //     try {
// // // // //       await db.execute(
// // // // //         'ALTER TABLE pack_cards ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1',
// // // // //       );
// // // // //       AppLogger.info('Migration 003: added is_active column to pack_cards');
// // // // //     } catch (e) {
// // // // //       // Column might already exist (if migration ran partially)
// // // // //       AppLogger.warning(
// // // // //         'Migration 003: is_active column may already exist – $e',
// // // // //       );
// // // // //     }

// // // // //     // Recreate the view to include the new column
// // // // //     await db.execute('DROP VIEW IF EXISTS pack_cards_cache');
// // // // //     await db.execute('''
// // // // //       CREATE VIEW pack_cards_cache AS
// // // // //       SELECT id, pack_id, content_json, card_type, difficulty, sort_order, image_path, is_active
// // // // //       FROM pack_cards
// // // // //     ''');
// // // // //     AppLogger.info(
// // // // //       'Migration 003: recreated pack_cards_cache view with is_active',
// // // // //     );
// // // // //   }

// // // // //   // ── Migration 001: Initial schema ──────────────────────────────────────
// // // // //   Future<void> _migration001(Database db) async {
// // // // //     final batch = db.batch();

// // // // //     // Downloaded packs (header only — cards in pack_cards table)
// // // // //     batch.execute('''
// // // // //       CREATE TABLE IF NOT EXISTS packs (
// // // // //         id            TEXT PRIMARY KEY,
// // // // //         name_json     TEXT NOT NULL,
// // // // //         cover_url     TEXT,
// // // // //         game_type     TEXT NOT NULL,
// // // // //         language      TEXT NOT NULL DEFAULT 'en',
// // // // //         price         INTEGER NOT NULL DEFAULT 0,
// // // // //         server_version INTEGER NOT NULL DEFAULT 1,
// // // // //         downloaded_at INTEGER NOT NULL,
// // // // //         expires_at    INTEGER
// // // // //       )
// // // // //     ''');

// // // // //     // Individual cards for each downloaded pack (now includes is_active)
// // // // //     batch.execute('''
// // // // //       CREATE TABLE IF NOT EXISTS pack_cards (
// // // // //         id           TEXT PRIMARY KEY,
// // // // //         pack_id      TEXT NOT NULL REFERENCES packs(id) ON DELETE CASCADE,
// // // // //         content_json TEXT NOT NULL,
// // // // //         card_type    TEXT NOT NULL,
// // // // //         difficulty   TEXT NOT NULL DEFAULT 'mild',
// // // // //         sort_order   INTEGER NOT NULL DEFAULT 0,
// // // // //         image_path   TEXT,
// // // // //         is_active    INTEGER NOT NULL DEFAULT 1
// // // // //       )
// // // // //     ''');

// // // // //     // Alias view for TodRepository compatibility (includes is_active)
// // // // //     batch.execute('''
// // // // //       CREATE VIEW IF NOT EXISTS pack_cards_cache AS
// // // // //       SELECT id, pack_id, content_json, card_type, difficulty, sort_order, image_path, is_active
// // // // //       FROM pack_cards
// // // // //     ''');

// // // // //     batch.execute(
// // // // //       'CREATE INDEX IF NOT EXISTS idx_cards_pack ON pack_cards(pack_id, sort_order)',
// // // // //     );

// // // // //     // Local mirror of server purchase records (for expiry checking offline)
// // // // //     batch.execute('''
// // // // //       CREATE TABLE IF NOT EXISTS purchases (
// // // // //         pack_id      TEXT PRIMARY KEY REFERENCES packs(id) ON DELETE CASCADE,
// // // // //         purchased_at INTEGER NOT NULL,
// // // // //         expires_at   INTEGER NOT NULL
// // // // //       )
// // // // //     ''');

// // // // //     // Sync log: tracks which packs need re-download
// // // // //     batch.execute('''
// // // // //       CREATE TABLE IF NOT EXISTS sync_log (
// // // // //         pack_id        TEXT PRIMARY KEY,
// // // // //         server_version INTEGER NOT NULL,
// // // // //         local_version  INTEGER NOT NULL,
// // // // //         synced_at      INTEGER NOT NULL
// // // // //       )
// // // // //     ''');

// // // // //     // Room cache — used by RoomCacheService
// // // // //     batch.execute('''
// // // // //       CREATE TABLE IF NOT EXISTS cached_rooms (
// // // // //         id        TEXT PRIMARY KEY,
// // // // //         data      TEXT NOT NULL,
// // // // //         cached_at INTEGER NOT NULL
// // // // //       )
// // // // //     ''');

// // // // //     batch.execute('''
// // // // //       CREATE TABLE IF NOT EXISTS cached_chat_messages (
// // // // //         id         TEXT PRIMARY KEY,
// // // // //         room_id    TEXT NOT NULL,
// // // // //         data       TEXT NOT NULL,
// // // // //         created_at INTEGER NOT NULL
// // // // //       )
// // // // //     ''');

// // // // //     batch.execute(
// // // // //       'CREATE INDEX IF NOT EXISTS idx_chat_room ON cached_chat_messages(room_id, created_at)',
// // // // //     );

// // // // //     await batch.commit(noResult: true);
// // // // //     AppLogger.info('Migration 001 applied');
// // // // //   }

// // // // //   Future<void> close() async {
// // // // //     await _db?.close();
// // // // //     _db = null;
// // // // //   }
// // // // // }

// // // // import 'package:sqflite/sqflite.dart';
// // // // import 'package:path/path.dart' as p;

// // // // import '../../utils/app_logger.dart';
// // // // import '../../../features/offline/data/offline_repository.dart'
// // // //     show OfflineRepository;

// // // // /// Offline sessions schema — referenced by AppDatabase migration v2.
// // // // abstract class OfflineSessionsMigration {
// // // //   static const schema = OfflineRepository.schemaV2;
// // // // }

// // // // /// SQLite database singleton with versioned migrations.
// // // // ///
// // // // /// Stores: downloaded pack cards, purchase metadata, offline sync log.
// // // // /// All game and social data lives in Supabase — SQLite is offline-only.
// // // // class AppDatabase {
// // // //   AppDatabase._();
// // // //   static final AppDatabase instance = AppDatabase._();

// // // //   static const _dbName = 'jma3a.db';
// // // //   static const _dbVersion = 2;

// // // //   Database? _db;
// // // //   Database get db {
// // // //     assert(_db != null, 'AppDatabase not opened. Call open() first.');
// // // //     return _db!;
// // // //   }

// // // //   /// Returns the database if open, null otherwise. Use in code that
// // // //   /// runs before initialization is guaranteed (e.g. screen initState).
// // // //   Database? get safeDb => (_db?.isOpen ?? false) ? _db : null;

// // // //   bool get isOpen => _db?.isOpen ?? false;

// // // //   Future<void> open() async {
// // // //     if (isOpen) return;

// // // //     final dbPath = p.join(await getDatabasesPath(), _dbName);

// // // //     _db = await openDatabase(
// // // //       dbPath,
// // // //       version: _dbVersion,
// // // //       onCreate: _onCreate,
// // // //       onUpgrade: _onUpgrade,
// // // //       onConfigure: (db) async {
// // // //         await db.rawQuery('PRAGMA foreign_keys = ON');
// // // //         await db.rawQuery('PRAGMA journal_mode = WAL');
// // // //       },
// // // //     );

// // // //     AppLogger.info('SQLite database opened: $dbPath (v$_dbVersion)');
// // // //   }

// // // //   // ── Schema creation ────────────────────────────────────────────────────
// // // //   Future<void> _onCreate(Database db, int version) async {
// // // //     AppLogger.info('Creating SQLite schema v$version (fresh install)');
// // // //     // Run all migrations in order from 1 to current version
// // // //     for (var v = 1; v <= version; v++) {
// // // //       await _runMigration(db, v);
// // // //     }
// // // //   }

// // // //   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
// // // //     AppLogger.info('Upgrading SQLite $oldVersion → $newVersion');
// // // //     for (var v = oldVersion + 1; v <= newVersion; v++) {
// // // //       await _runMigration(db, v);
// // // //     }
// // // //   }

// // // //   Future<void> _runMigration(Database db, int version) async {
// // // //     switch (version) {
// // // //       case 1:
// // // //         await _migration001(db);
// // // //       case 2:
// // // //         await _migration002(db);
// // // //     }
// // // //   }

// // // //   Future<void> _migration002(Database db) async {
// // // //     await db.execute(OfflineSessionsMigration.schema);
// // // //     AppLogger.info('Migration 002: offline_sessions applied');
// // // //   }

// // // //   // ── Migration 001: Initial schema ──────────────────────────────────────
// // // //   Future<void> _migration001(Database db) async {
// // // //     final batch = db.batch();

// // // //     // Downloaded packs (header only — cards in pack_cards table)
// // // //     batch.execute('''
// // // //       CREATE TABLE IF NOT EXISTS packs (
// // // //         id            TEXT PRIMARY KEY,
// // // //         name_json     TEXT NOT NULL,
// // // //         cover_url     TEXT,
// // // //         game_type     TEXT NOT NULL,
// // // //         language      TEXT NOT NULL DEFAULT 'en',
// // // //         price         INTEGER NOT NULL DEFAULT 0,
// // // //         server_version INTEGER NOT NULL DEFAULT 1,
// // // //         downloaded_at INTEGER NOT NULL,
// // // //         expires_at    INTEGER
// // // //       )
// // // //     ''');

// // // //     // Individual cards for each downloaded pack
// // // //     batch.execute('''
// // // //       CREATE TABLE IF NOT EXISTS pack_cards (
// // // //         id           TEXT PRIMARY KEY,
// // // //         pack_id      TEXT NOT NULL REFERENCES packs(id) ON DELETE CASCADE,
// // // //         content_json TEXT NOT NULL,
// // // //         card_type    TEXT NOT NULL,
// // // //         difficulty   TEXT NOT NULL DEFAULT 'mild',
// // // //         sort_order   INTEGER NOT NULL DEFAULT 0,
// // // //         image_path   TEXT
// // // //       )
// // // //     ''');

// // // //     // Alias view for TodRepository compatibility
// // // //     batch.execute('''
// // // //       CREATE VIEW IF NOT EXISTS pack_cards_cache AS
// // // //       SELECT id, pack_id, content_json, card_type, difficulty, sort_order, image_path
// // // //       FROM pack_cards
// // // //     ''');

// // // //     batch.execute(
// // // //       'CREATE INDEX IF NOT EXISTS idx_cards_pack ON pack_cards(pack_id, sort_order)',
// // // //     );

// // // //     // Local mirror of server purchase records (for expiry checking offline)
// // // //     batch.execute('''
// // // //       CREATE TABLE IF NOT EXISTS purchases (
// // // //         pack_id      TEXT PRIMARY KEY REFERENCES packs(id) ON DELETE CASCADE,
// // // //         purchased_at INTEGER NOT NULL,
// // // //         expires_at   INTEGER NOT NULL
// // // //       )
// // // //     ''');

// // // //     // Sync log: tracks which packs need re-download
// // // //     batch.execute('''
// // // //       CREATE TABLE IF NOT EXISTS sync_log (
// // // //         pack_id        TEXT PRIMARY KEY,
// // // //         server_version INTEGER NOT NULL,
// // // //         local_version  INTEGER NOT NULL,
// // // //         synced_at      INTEGER NOT NULL
// // // //       )
// // // //     ''');

// // // //     // Room cache — used by RoomCacheService
// // // //     batch.execute('''
// // // //       CREATE TABLE IF NOT EXISTS cached_rooms (
// // // //         id        TEXT PRIMARY KEY,
// // // //         data      TEXT NOT NULL,
// // // //         cached_at INTEGER NOT NULL
// // // //       )
// // // //     ''');

// // // //     batch.execute('''
// // // //       CREATE TABLE IF NOT EXISTS cached_chat_messages (
// // // //         id         TEXT PRIMARY KEY,
// // // //         room_id    TEXT NOT NULL,
// // // //         data       TEXT NOT NULL,
// // // //         created_at INTEGER NOT NULL
// // // //       )
// // // //     ''');

// // // //     batch.execute(
// // // //       'CREATE INDEX IF NOT EXISTS idx_chat_room ON cached_chat_messages(room_id, created_at)',
// // // //     );

// // // //     await batch.commit(noResult: true);
// // // //     AppLogger.info('Migration 001 applied');
// // // //   }

// // // //   Future<void> close() async {
// // // //     await _db?.close();
// // // //     _db = null;
// // // //   }
// // // // }

// // // import 'package:sqflite/sqflite.dart';
// // // import 'package:path/path.dart' as p;

// // // import '../../utils/app_logger.dart';
// // // import '../../../features/offline/data/offline_repository.dart'
// // //     show OfflineRepository;

// // // /// Offline sessions schema — referenced by AppDatabase migration v2.
// // // abstract class OfflineSessionsMigration {
// // //   static const schema = OfflineRepository.schemaV2;
// // // }

// // // /// SQLite database singleton with versioned migrations.
// // // ///
// // // /// Stores: downloaded pack cards, purchase metadata, offline sync log.
// // // /// All game and social data lives in Supabase — SQLite is offline-only.
// // // class AppDatabase {
// // //   AppDatabase._();
// // //   static final AppDatabase instance = AppDatabase._();

// // //   static const _dbName = 'jma3a.db';
// // //   static const _dbVersion = 3;

// // //   Database? _db;
// // //   Database get db {
// // //     assert(_db != null, 'AppDatabase not opened. Call open() first.');
// // //     return _db!;
// // //   }

// // //   /// Returns the database if open, null otherwise. Use in code that
// // //   /// runs before initialization is guaranteed (e.g. screen initState).
// // //   Database? get safeDb => (_db?.isOpen ?? false) ? _db : null;

// // //   bool get isOpen => _db?.isOpen ?? false;

// // //   Future<void> open() async {
// // //     if (isOpen) return;

// // //     final dbPath = p.join(await getDatabasesPath(), _dbName);

// // //     _db = await openDatabase(
// // //       dbPath,
// // //       version: _dbVersion,
// // //       onCreate: _onCreate,
// // //       onUpgrade: _onUpgrade,
// // //       onConfigure: (db) async {
// // //         await db.rawQuery('PRAGMA foreign_keys = ON');
// // //         await db.rawQuery('PRAGMA journal_mode = WAL');
// // //       },
// // //     );

// // //     AppLogger.info('SQLite database opened: $dbPath (v$_dbVersion)');
// // //   }

// // //   // ── Schema creation ────────────────────────────────────────────────────
// // //   Future<void> _onCreate(Database db, int version) async {
// // //     AppLogger.info('Creating SQLite schema v$version (fresh install)');
// // //     // Run all migrations in order from 1 to current version
// // //     for (var v = 1; v <= version; v++) {
// // //       await _runMigration(db, v);
// // //     }
// // //   }

// // //   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
// // //     AppLogger.info('Upgrading SQLite $oldVersion → $newVersion');
// // //     for (var v = oldVersion + 1; v <= newVersion; v++) {
// // //       await _runMigration(db, v);
// // //     }
// // //   }

// // //   Future<void> _runMigration(Database db, int version) async {
// // //     switch (version) {
// // //       case 1:
// // //         await _migration001(db);
// // //       case 2:
// // //         await _migration002(db);
// // //       case 3:
// // //         await _migration003(db);
// // //     }
// // //   }

// // //   /// Migration 003: ensure all v1 tables exist (fixes devices that got v2
// // //   /// without v1 running due to the onCreate bug — all CREATE TABLE statements
// // //   /// use IF NOT EXISTS so this is safe to re-run).
// // //   Future<void> _migration003(Database db) async {
// // //     await _migration001(db);
// // //     AppLogger.info('Migration 003: ensured all base tables exist');
// // //   }

// // //   Future<void> _migration002(Database db) async {
// // //     await db.execute(OfflineSessionsMigration.schema);
// // //     AppLogger.info('Migration 002: offline_sessions applied');
// // //   }

// // //   // ── Migration 001: Initial schema ──────────────────────────────────────
// // //   Future<void> _migration001(Database db) async {
// // //     final batch = db.batch();

// // //     // Downloaded packs (header only — cards in pack_cards table)
// // //     batch.execute('''
// // //       CREATE TABLE IF NOT EXISTS packs (
// // //         id            TEXT PRIMARY KEY,
// // //         name_json     TEXT NOT NULL,
// // //         cover_url     TEXT,
// // //         game_type     TEXT NOT NULL,
// // //         language      TEXT NOT NULL DEFAULT 'en',
// // //         price         INTEGER NOT NULL DEFAULT 0,
// // //         server_version INTEGER NOT NULL DEFAULT 1,
// // //         downloaded_at INTEGER NOT NULL,
// // //         expires_at    INTEGER
// // //       )
// // //     ''');

// // //     // Individual cards for each downloaded pack
// // //     batch.execute('''
// // //       CREATE TABLE IF NOT EXISTS pack_cards (
// // //         id           TEXT PRIMARY KEY,
// // //         pack_id      TEXT NOT NULL REFERENCES packs(id) ON DELETE CASCADE,
// // //         content_json TEXT NOT NULL,
// // //         card_type    TEXT NOT NULL,
// // //         difficulty   TEXT NOT NULL DEFAULT 'mild',
// // //         sort_order   INTEGER NOT NULL DEFAULT 0,
// // //         image_path   TEXT
// // //       )
// // //     ''');

// // //     // Alias view for TodRepository compatibility
// // //     batch.execute('''
// // //       CREATE VIEW IF NOT EXISTS pack_cards_cache AS
// // //       SELECT id, pack_id, content_json, card_type, difficulty, sort_order, image_path
// // //       FROM pack_cards
// // //     ''');

// // //     batch.execute(
// // //       'CREATE INDEX IF NOT EXISTS idx_cards_pack ON pack_cards(pack_id, sort_order)',
// // //     );

// // //     // Local mirror of server purchase records (for expiry checking offline)
// // //     batch.execute('''
// // //       CREATE TABLE IF NOT EXISTS purchases (
// // //         pack_id      TEXT PRIMARY KEY REFERENCES packs(id) ON DELETE CASCADE,
// // //         purchased_at INTEGER NOT NULL,
// // //         expires_at   INTEGER NOT NULL
// // //       )
// // //     ''');

// // //     // Sync log: tracks which packs need re-download
// // //     batch.execute('''
// // //       CREATE TABLE IF NOT EXISTS sync_log (
// // //         pack_id        TEXT PRIMARY KEY,
// // //         server_version INTEGER NOT NULL,
// // //         local_version  INTEGER NOT NULL,
// // //         synced_at      INTEGER NOT NULL
// // //       )
// // //     ''');

// // //     // Room cache — used by RoomCacheService
// // //     batch.execute('''
// // //       CREATE TABLE IF NOT EXISTS cached_rooms (
// // //         id        TEXT PRIMARY KEY,
// // //         data      TEXT NOT NULL,
// // //         cached_at INTEGER NOT NULL
// // //       )
// // //     ''');

// // //     batch.execute('''
// // //       CREATE TABLE IF NOT EXISTS cached_chat_messages (
// // //         id         TEXT PRIMARY KEY,
// // //         room_id    TEXT NOT NULL,
// // //         data       TEXT NOT NULL,
// // //         created_at INTEGER NOT NULL
// // //       )
// // //     ''');

// // //     batch.execute(
// // //       'CREATE INDEX IF NOT EXISTS idx_chat_room ON cached_chat_messages(room_id, created_at)',
// // //     );

// // //     await batch.commit(noResult: true);
// // //     AppLogger.info('Migration 001 applied');
// // //   }

// // //   Future<void> close() async {
// // //     await _db?.close();
// // //     _db = null;
// // //   }
// // // }

// // import 'dart:async';

// // import 'package:sqflite/sqflite.dart';
// // import 'package:path/path.dart' as p;

// // import '../../utils/app_logger.dart';
// // import '../../../features/offline/data/offline_repository.dart'
// //     show OfflineRepository;

// // /// Offline sessions schema — referenced by AppDatabase migration v2.
// // abstract class OfflineSessionsMigration {
// //   static const schema = OfflineRepository.schemaV2;
// // }

// // /// SQLite database singleton with versioned migrations.
// // class AppDatabase {
// //   AppDatabase._();
// //   static final AppDatabase instance = AppDatabase._();

// //   static const _dbName = 'jma3a.db';
// //   static const _dbVersion = 4; // ✅ increased to 4

// //   Database? _db;
// //   final _readyCompleter = Completer<void>();

// //   /// Returns the database if open, null otherwise.
// //   Database? get safeDb => (_db?.isOpen ?? false) ? _db : null;

// //   bool get isOpen => _db?.isOpen ?? false;

// //   /// Future that completes when the database is fully opened and ready.
// //   Future<void> get ready => _readyCompleter.future;

// //   Database get db {
// //     assert(_db != null, 'AppDatabase not opened. Call open() first.');
// //     return _db!;
// //   }

// //   Future<void> open() async {
// //     if (isOpen) {
// //       _readyCompleter.complete();
// //       return;
// //     }

// //     final dbPath = p.join(await getDatabasesPath(), _dbName);

// //     _db = await openDatabase(
// //       dbPath,
// //       version: _dbVersion,
// //       onCreate: _onCreate,
// //       onUpgrade: _onUpgrade,
// //       onConfigure: (db) async {
// //         await db.rawQuery('PRAGMA foreign_keys = ON');
// //         await db.rawQuery('PRAGMA journal_mode = WAL');
// //       },
// //     );

// //     AppLogger.info('SQLite database opened: $dbPath (v$_dbVersion)');
// //     _readyCompleter.complete();
// //   }

// //   // ── Schema creation ────────────────────────────────────────────────────
// //   Future<void> _onCreate(Database db, int version) async {
// //     AppLogger.info('Creating SQLite schema v$version (fresh install)');
// //     for (var v = 1; v <= version; v++) {
// //       await _runMigration(db, v);
// //     }
// //   }

// //   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
// //     AppLogger.info('Upgrading SQLite $oldVersion → $newVersion');
// //     for (var v = oldVersion + 1; v <= newVersion; v++) {
// //       await _runMigration(db, v);
// //     }
// //   }

// //   Future<void> _runMigration(Database db, int version) async {
// //     switch (version) {
// //       case 1:
// //         await _migration001(db);
// //       case 2:
// //         await _migration002(db);
// //       case 3:
// //         await _migration003(db);
// //       case 4:
// //         await _migration004(db);
// //     }
// //   }

// //   /// Migration 002: adds offline_sessions table.
// //   Future<void> _migration002(Database db) async {
// //     await db.execute(OfflineSessionsMigration.schema);
// //     AppLogger.info('Migration 002: offline_sessions applied');
// //   }

// //   /// Migration 003: ensures all v1 tables exist (fixes devices that got v2
// //   /// without v1 running due to the onCreate bug).
// //   Future<void> _migration003(Database db) async {
// //     await _migration001(db);
// //     AppLogger.info('Migration 003: ensured all base tables exist');
// //   }

// //   /// Migration 004: re‑runs base schema creation to guarantee sync_log,
// //   /// purchases, pack_cards, etc. exist (idempotent).
// //   Future<void> _migration004(Database db) async {
// //     await _migration001(db);
// //     AppLogger.info('Migration 004: re‑enforced base schema');
// //   }

// //   // ── Migration 001: Initial schema (all CREATE IF NOT EXISTS) ───────────
// //   Future<void> _migration001(Database db) async {
// //     final batch = db.batch();

// //     // Downloaded packs
// //     batch.execute('''
// //       CREATE TABLE IF NOT EXISTS packs (
// //         id            TEXT PRIMARY KEY,
// //         name_json     TEXT NOT NULL,
// //         cover_url     TEXT,
// //         game_type     TEXT NOT NULL,
// //         language      TEXT NOT NULL DEFAULT 'en',
// //         price         INTEGER NOT NULL DEFAULT 0,
// //         server_version INTEGER NOT NULL DEFAULT 1,
// //         downloaded_at INTEGER NOT NULL,
// //         expires_at    INTEGER
// //       )
// //     ''');

// //     // Individual cards
// //     batch.execute('''
// //       CREATE TABLE IF NOT EXISTS pack_cards (
// //         id           TEXT PRIMARY KEY,
// //         pack_id      TEXT NOT NULL REFERENCES packs(id) ON DELETE CASCADE,
// //         content_json TEXT NOT NULL,
// //         card_type    TEXT NOT NULL,
// //         difficulty   TEXT NOT NULL DEFAULT 'mild',
// //         sort_order   INTEGER NOT NULL DEFAULT 0,
// //         image_path   TEXT
// //       )
// //     ''');

// //     // View for TodRepository compatibility
// //     batch.execute('''
// //       CREATE VIEW IF NOT EXISTS pack_cards_cache AS
// //       SELECT id, pack_id, content_json, card_type, difficulty, sort_order, image_path
// //       FROM pack_cards
// //     ''');

// //     batch.execute(
// //       'CREATE INDEX IF NOT EXISTS idx_cards_pack ON pack_cards(pack_id, sort_order)',
// //     );

// //     // Purchases table
// //     batch.execute('''
// //       CREATE TABLE IF NOT EXISTS purchases (
// //         pack_id      TEXT PRIMARY KEY REFERENCES packs(id) ON DELETE CASCADE,
// //         purchased_at INTEGER NOT NULL,
// //         expires_at   INTEGER NOT NULL
// //       )
// //     ''');

// //     // Sync log – the missing table that caused the error
// //     batch.execute('''
// //       CREATE TABLE IF NOT EXISTS sync_log (
// //         pack_id        TEXT PRIMARY KEY,
// //         server_version INTEGER NOT NULL,
// //         local_version  INTEGER NOT NULL,
// //         synced_at      INTEGER NOT NULL
// //       )
// //     ''');

// //     // Room cache tables
// //     batch.execute('''
// //       CREATE TABLE IF NOT EXISTS cached_rooms (
// //         id        TEXT PRIMARY KEY,
// //         data      TEXT NOT NULL,
// //         cached_at INTEGER NOT NULL
// //       )
// //     ''');

// //     batch.execute('''
// //       CREATE TABLE IF NOT EXISTS cached_chat_messages (
// //         id         TEXT PRIMARY KEY,
// //         room_id    TEXT NOT NULL,
// //         data       TEXT NOT NULL,
// //         created_at INTEGER NOT NULL
// //       )
// //     ''');

// //     batch.execute(
// //       'CREATE INDEX IF NOT EXISTS idx_chat_room ON cached_chat_messages(room_id, created_at)',
// //     );

// //     await batch.commit(noResult: true);
// //     AppLogger.info('Migration 001 applied');
// //   }

// //   Future<void> close() async {
// //     await _db?.close();
// //     _db = null;
// //   }
// // }

// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart' as p;

// import '../../utils/app_logger.dart';
// import '../../../features/offline/data/offline_repository.dart'
//     show OfflineRepository;

// /// Offline sessions schema — referenced by AppDatabase migration v2.
// abstract class OfflineSessionsMigration {
//   static const schema = OfflineRepository.schemaV2;
// }

// /// SQLite database singleton with versioned migrations.
// ///
// /// Stores: downloaded pack cards, purchase metadata, offline sync log.
// /// All game and social data lives in Supabase — SQLite is offline-only.
// class AppDatabase {
//   AppDatabase._();
//   static final AppDatabase instance = AppDatabase._();

//   static const _dbName = 'jma3a.db';
//   static const _dbVersion = 4;

//   Database? _db;
//   Database get db {
//     assert(_db != null, 'AppDatabase not opened. Call open() first.');
//     return _db!;
//   }

//   /// Returns the database if open, null otherwise. Use in code that
//   /// runs before initialization is guaranteed (e.g. screen initState).
//   Database? get safeDb => (_db?.isOpen ?? false) ? _db : null;

//   bool get isOpen => _db?.isOpen ?? false;

//   Future<void> open() async {
//     if (isOpen) return;

//     final dbPath = p.join(await getDatabasesPath(), _dbName);

//     _db = await openDatabase(
//       dbPath,
//       version: _dbVersion,
//       onCreate: _onCreate,
//       onUpgrade: _onUpgrade,
//       onConfigure: (db) async {
//         await db.rawQuery('PRAGMA foreign_keys = ON');
//         await db.rawQuery('PRAGMA journal_mode = WAL');
//       },
//     );

//     AppLogger.info('SQLite database opened: $dbPath (v$_dbVersion)');
//   }

//   // ── Schema creation ────────────────────────────────────────────────────
//   Future<void> _onCreate(Database db, int version) async {
//     AppLogger.info('Creating SQLite schema v$version (fresh install)');
//     // Run all migrations in order from 1 to current version
//     for (var v = 1; v <= version; v++) {
//       await _runMigration(db, v);
//     }
//   }

//   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
//     AppLogger.info('Upgrading SQLite $oldVersion → $newVersion');
//     for (var v = oldVersion + 1; v <= newVersion; v++) {
//       await _runMigration(db, v);
//     }
//   }

//   Future<void> _runMigration(Database db, int version) async {
//     switch (version) {
//       case 1:
//         await _migration001(db);
//       case 2:
//         await _migration002(db);
//       case 3:
//         await _migration003(db);
//       case 4:
//         await _migration004(db);
//     }
//   }

//   /// Migration 003: ensure all v1 tables exist (fixes devices that got v2
//   /// without v1 running due to the onCreate bug — all CREATE TABLE statements
//   /// use IF NOT EXISTS so this is safe to re-run).
//   Future<void> _migration003(Database db) async {
//     await _migration001(db);
//     AppLogger.info('Migration 003: ensured all base tables exist');
//   }

//   Future<void> _migration002(Database db) async {
//     await db.execute(OfflineSessionsMigration.schema);
//     AppLogger.info('Migration 002: offline_sessions applied');
//   }

//   // ── Migration 001: Initial schema ──────────────────────────────────────
//   Future<void> _migration001(Database db) async {
//     final batch = db.batch();

//     // Downloaded packs (header only — cards in pack_cards table)
//     batch.execute('''
//       CREATE TABLE IF NOT EXISTS packs (
//         id            TEXT PRIMARY KEY,
//         name_json     TEXT NOT NULL,
//         cover_url     TEXT,
//         game_type     TEXT NOT NULL,
//         language      TEXT NOT NULL DEFAULT 'en',
//         price         INTEGER NOT NULL DEFAULT 0,
//         server_version INTEGER NOT NULL DEFAULT 1,
//         downloaded_at INTEGER NOT NULL,
//         expires_at    INTEGER
//       )
//     ''');

//     // Individual cards for each downloaded pack
//     batch.execute('''
//       CREATE TABLE IF NOT EXISTS pack_cards (
//         id           TEXT PRIMARY KEY,
//         pack_id      TEXT NOT NULL REFERENCES packs(id) ON DELETE CASCADE,
//         content_json TEXT NOT NULL,
//         card_type    TEXT NOT NULL,
//         difficulty   TEXT NOT NULL DEFAULT 'mild',
//         sort_order   INTEGER NOT NULL DEFAULT 0,
//         image_path   TEXT
//       )
//     ''');

//     // Alias view for TodRepository compatibility
//     batch.execute('''
//       CREATE VIEW IF NOT EXISTS pack_cards_cache AS
//       SELECT id, pack_id, content_json, card_type, difficulty, sort_order, image_path
//       FROM pack_cards
//     ''');

//     batch.execute(
//       'CREATE INDEX IF NOT EXISTS idx_cards_pack ON pack_cards(pack_id, sort_order)',
//     );

//     // Local mirror of server purchase records (for expiry checking offline)
//     batch.execute('''
//       CREATE TABLE IF NOT EXISTS purchases (
//         pack_id      TEXT PRIMARY KEY REFERENCES packs(id) ON DELETE CASCADE,
//         purchased_at INTEGER NOT NULL,
//         expires_at   INTEGER NOT NULL
//       )
//     ''');

//     // Sync log: tracks which packs need re-download
//     batch.execute('''
//       CREATE TABLE IF NOT EXISTS sync_log (
//         pack_id        TEXT PRIMARY KEY,
//         server_version INTEGER NOT NULL,
//         local_version  INTEGER NOT NULL,
//         synced_at      INTEGER NOT NULL
//       )
//     ''');

//     // Room cache — used by RoomCacheService
//     batch.execute('''
//       CREATE TABLE IF NOT EXISTS cached_rooms (
//         id        TEXT PRIMARY KEY,
//         data      TEXT NOT NULL,
//         cached_at INTEGER NOT NULL
//       )
//     ''');

//     batch.execute('''
//       CREATE TABLE IF NOT EXISTS cached_chat_messages (
//         id         TEXT PRIMARY KEY,
//         room_id    TEXT NOT NULL,
//         data       TEXT NOT NULL,
//         created_at INTEGER NOT NULL
//       )
//     ''');

//     batch.execute(
//       'CREATE INDEX IF NOT EXISTS idx_chat_room ON cached_chat_messages(room_id, created_at)',
//     );

//     await batch.commit(noResult: true);
//     AppLogger.info('Migration 001 applied');
//   }

//   /// Migration 004: add pack_cover_url to offline_sessions
//   Future<void> _migration004(Database db) async {
//     // ALTER TABLE only adds if column doesn't exist (SQLite doesn't support IF NOT EXISTS
//     // for ADD COLUMN, so we catch the error if it already exists)
//     try {
//       await db.execute(
//         'ALTER TABLE offline_sessions ADD COLUMN pack_cover_url TEXT',
//       );
//       AppLogger.info('Migration 004: added pack_cover_url to offline_sessions');
//     } catch (_) {
//       // Column may already exist on fresh installs — safe to ignore
//       AppLogger.info('Migration 004: pack_cover_url already exists, skipped');
//     }
//   }

//   Future<void> close() async {
//     await _db?.close();
//     _db = null;
//   }
// }

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../../utils/app_logger.dart';
import '../../../features/offline/data/offline_repository.dart'
    show OfflineRepository;

/// Offline sessions schema — referenced by AppDatabase migration v2.
abstract class OfflineSessionsMigration {
  static const schema = OfflineRepository.schemaV2;
}

/// SQLite database singleton with versioned migrations.
///
/// Stores: downloaded pack cards, purchase metadata, offline sync log.
/// All game and social data lives in Supabase — SQLite is offline-only.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'jma3a.db';
  static const _dbVersion = 6;

  Database? _db;
  Database get db {
    assert(_db != null, 'AppDatabase not opened. Call open() first.');
    return _db!;
  }

  /// Returns the database if open, null otherwise. Use in code that
  /// runs before initialization is guaranteed (e.g. screen initState).
  Database? get safeDb => (_db?.isOpen ?? false) ? _db : null;

  bool get isOpen => _db?.isOpen ?? false;

  Future<void> open() async {
    if (isOpen) return;

    final dbPath = p.join(await getDatabasesPath(), _dbName);

    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.rawQuery('PRAGMA foreign_keys = ON');
        await db.rawQuery('PRAGMA journal_mode = WAL');
      },
    );

    AppLogger.info('SQLite database opened: $dbPath (v$_dbVersion)');
  }

  // ── Schema creation ────────────────────────────────────────────────────
  Future<void> _onCreate(Database db, int version) async {
    AppLogger.info('Creating SQLite schema v$version (fresh install)');
    // Run all migrations in order from 1 to current version
    for (var v = 1; v <= version; v++) {
      await _runMigration(db, v);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.info('Upgrading SQLite $oldVersion → $newVersion');
    for (var v = oldVersion + 1; v <= newVersion; v++) {
      await _runMigration(db, v);
    }
  }

  Future<void> _runMigration(Database db, int version) async {
    switch (version) {
      case 1:
        await _migration001(db);
      case 2:
        await _migration002(db);
      case 3:
        await _migration003(db);
      case 4:
        await _migration004(db);
      case 5:
        await _migration005(db);
      case 6:
        await _migration006(db);
    }
  }

  /// Migration 003: ensure all v1 tables exist (fixes devices that got v2
  /// without v1 running due to the onCreate bug — all CREATE TABLE statements
  /// use IF NOT EXISTS so this is safe to re-run).
  Future<void> _migration003(Database db) async {
    await _migration001(db);
    AppLogger.info('Migration 003: ensured all base tables exist');
  }

  Future<void> _migration002(Database db) async {
    await db.execute(OfflineSessionsMigration.schema);
    AppLogger.info('Migration 002: offline_sessions applied');
  }

  // ── Migration 001: Initial schema ──────────────────────────────────────
  Future<void> _migration001(Database db) async {
    final batch = db.batch();

    // Downloaded packs (header only — cards in pack_cards table)
    batch.execute('''
      CREATE TABLE IF NOT EXISTS packs (
        id            TEXT PRIMARY KEY,
        name_json     TEXT NOT NULL,
        cover_url     TEXT,
        game_type     TEXT NOT NULL,
        language      TEXT NOT NULL DEFAULT 'en',
        price         INTEGER NOT NULL DEFAULT 0,
        server_version INTEGER NOT NULL DEFAULT 1,
        downloaded_at INTEGER NOT NULL,
        expires_at    INTEGER
      )
    ''');

    // Individual cards for each downloaded pack
    batch.execute('''
      CREATE TABLE IF NOT EXISTS pack_cards (
        id           TEXT PRIMARY KEY,
        pack_id      TEXT NOT NULL REFERENCES packs(id) ON DELETE CASCADE,
        content_json TEXT NOT NULL,
        card_type    TEXT NOT NULL,
        difficulty   TEXT NOT NULL DEFAULT 'mild',
        sort_order   INTEGER NOT NULL DEFAULT 0,
        image_path   TEXT
      )
    ''');

    // Alias view for TodRepository compatibility
    batch.execute('''
      CREATE VIEW IF NOT EXISTS pack_cards_cache AS
      SELECT id, pack_id, content_json, card_type, difficulty, sort_order, image_path
      FROM pack_cards
    ''');

    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_cards_pack ON pack_cards(pack_id, sort_order)',
    );

    // Local mirror of server purchase records (for expiry checking offline)
    batch.execute('''
      CREATE TABLE IF NOT EXISTS purchases (
        pack_id      TEXT PRIMARY KEY,
        purchased_at INTEGER NOT NULL,
        expires_at   INTEGER NOT NULL
      )
    ''');

    // Sync log: tracks which packs need re-download
    batch.execute('''
      CREATE TABLE IF NOT EXISTS sync_log (
        pack_id        TEXT PRIMARY KEY,
        server_version INTEGER NOT NULL,
        local_version  INTEGER NOT NULL,
        synced_at      INTEGER NOT NULL
      )
    ''');

    // Room cache — used by RoomCacheService
    batch.execute('''
      CREATE TABLE IF NOT EXISTS cached_rooms (
        id        TEXT PRIMARY KEY,
        data      TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS cached_chat_messages (
        id         TEXT PRIMARY KEY,
        room_id    TEXT NOT NULL,
        data       TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_chat_room ON cached_chat_messages(room_id, created_at)',
    );

    await batch.commit(noResult: true);
    AppLogger.info('Migration 001 applied');
  }

  /// Migration 004: add pack_cover_url to offline_sessions
  Future<void> _migration004(Database db) async {
    // ALTER TABLE only adds if column doesn't exist (SQLite doesn't support IF NOT EXISTS
    // for ADD COLUMN, so we catch the error if it already exists)
    try {
      await db.execute(
        'ALTER TABLE offline_sessions ADD COLUMN pack_cover_url TEXT',
      );
      AppLogger.info('Migration 004: added pack_cover_url to offline_sessions');
    } catch (_) {
      // Column may already exist on fresh installs — safe to ignore
      AppLogger.info('Migration 004: pack_cover_url already exists, skipped');
    }
  }

  Future<void> _migration005(Database db) async {
    // Add local image cache columns to packs table
    for (final col in ['local_cover_path TEXT', 'local_sticker_paths TEXT']) {
      try {
        final colName = col.split(' ').first;
        await db.execute('ALTER TABLE packs ADD COLUMN $col');
        AppLogger.info('Migration 005: added $colName to packs');
      } catch (_) {
        // Column may already exist (fresh installs from migration001) — safe to ignore
      }
    }
  }

  /// Migration 006: drop foreign key from purchases.pack_id.
  /// purchases tracks server-side purchase records — the referenced pack may
  /// not be downloaded locally, causing SQLITE_CONSTRAINT_FOREIGNKEY on insert.
  Future<void> _migration006(Database db) async {
    // SQLite doesn't support DROP CONSTRAINT — recreate without the FK.
    await db.execute('DROP TABLE IF EXISTS purchases_old');
    await db.execute('ALTER TABLE purchases RENAME TO purchases_old');
    await db.execute('''
      CREATE TABLE purchases (
        pack_id      TEXT PRIMARY KEY,
        purchased_at INTEGER NOT NULL,
        expires_at   INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      INSERT OR IGNORE INTO purchases (pack_id, purchased_at, expires_at)
      SELECT pack_id, purchased_at, expires_at FROM purchases_old
    ''');
    await db.execute('DROP TABLE purchases_old');
    AppLogger.info('Migration 006: removed FK from purchases table');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
