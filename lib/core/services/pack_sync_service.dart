// // import 'dart:async';

// // import 'package:sqflite/sqflite.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart';

// // import '../storage/database/app_database.dart';
// // import '../utils/app_logger.dart';
// // import '../../features/packs/data/pack_download_manager.dart';
// // import '../../features/packs/domain/pack_entity.dart';

// // /// Syncs purchased packs to local SQLite for offline play.
// // ///
// // /// Strategy:
// // ///   - On login: check which purchased packs aren't locally cached
// // ///   - Free packs: optionally auto-download on first access
// // ///   - No auto-version-sync required — user triggers manually
// // ///   - Cleanup: remove downloads for expired purchases
// // class PackSyncService {
// //   PackSyncService._();
// //   static final PackSyncService _instance = PackSyncService._();
// //   static PackSyncService get instance => _instance;

// //   final _supabase = Supabase.instance.client;
// //   final _downloader = PackDownloadManager.instance;
// //   final _progressCtrl = StreamController<SyncProgress>.broadcast();

// //   Stream<SyncProgress> get progressStream => _progressCtrl.stream;

// //   bool _isSyncing = false;
// //   bool get isSyncing => _isSyncing;

// //   // ── Main sync ──────────────────────────────────────────────────────────────

// //   /// Called after login to sync metadata (not download files).
// //   /// Downloads happen explicitly by the user or after purchase.
// //   Future<void> sync(String userId) async {
// //     if (_isSyncing) return;
// //     _isSyncing = true;

// //     try {
// //       AppLogger.info('PackSyncService: syncing for $userId');

// //       // 1. Fetch active purchases from Supabase
// //       final purchases = await _fetchActivePurchases(userId);
// //       _progressCtrl.add(SyncProgress(current: 0, total: purchases.length));

// //       // 2. Write purchase records to local SQLite (for offline expiry checks)
// //       await _cachePurchaseRecords(purchases);

// //       // 3. Clean up downloads for expired purchases
// //       await _downloader.deleteExpiredDownloads(purchases);

// //       AppLogger.info(
// //         'PackSyncService: sync complete (${purchases.length} packs)',
// //       );
// //     } catch (e, st) {
// //       AppLogger.error('PackSyncService: sync failed', error: e, stackTrace: st);
// //     } finally {
// //       _isSyncing = false;
// //       _progressCtrl.add(SyncProgress.complete());
// //     }
// //   }

// //   // ── Purchase record caching ────────────────────────────────────────────────

// //   Future<List<PackPurchase>> _fetchActivePurchases(String userId) async {
// //     final rows = await _supabase
// //         .from('pack_purchases')
// //         .select('pack_id, purchased_at, expires_at, price_paid_mru')
// //         .eq('buyer_id', userId)
// //         .eq('status', 'completed')
// //         .gt('expires_at', DateTime.now().toIso8601String());

// //     return rows
// //         .map(
// //           (r) => PackPurchase(
// //             packId: r['pack_id'] as String,
// //             purchasedAt: DateTime.parse(r['purchased_at'] as String),
// //             expiresAt: DateTime.parse(r['expires_at'] as String),
// //             pricePaidMru: r['price_paid_mru'] as int? ?? 0,
// //           ),
// //         )
// //         .toList();
// //   }

// //   Future<void> _cachePurchaseRecords(List<PackPurchase> purchases) async {
// //     final db = AppDatabase.instance.db;
// //     final batch = db.batch();

// //     // Clear stale records
// //     batch.delete('purchases');

// //     for (final p in purchases) {
// //       batch.insert(
// //         'purchases',
// //         {
// //           'pack_id': p.packId,
// //           'purchased_at': p.purchasedAt.millisecondsSinceEpoch,
// //           'expires_at': p.expiresAt.millisecondsSinceEpoch,
// //         },
// //         // conflictAlgorithm: 5, // REPLACE
// //         conflictAlgorithm: ConflictAlgorithm.replace,
// //       );
// //     }
// //     await batch.commit(noResult: true);
// //   }

// //   // ── Offline access check ───────────────────────────────────────────────────

// //   /// Check if a pack is accessible offline.
// //   /// Returns true if: pack is downloaded AND (it's free OR purchase hasn't expired).
// //   Future<bool> isPackAvailableOffline(String packId) async {
// //     final db = AppDatabase.instance.db;

// //     // Check if downloaded
// //     final packRow = await db.query(
// //       'packs',
// //       where: 'id = ?',
// //       whereArgs: [packId],
// //     );
// //     if (packRow.isEmpty) return false;

// //     // Free pack (price = 0) → available
// //     if ((packRow.first['price'] as int?) == 0) return true;

// //     // Check purchase not expired
// //     final purchaseRow = await db.query(
// //       'purchases',
// //       where: 'pack_id = ? AND expires_at > ?',
// //       whereArgs: [packId, DateTime.now().millisecondsSinceEpoch],
// //     );
// //     return purchaseRow.isNotEmpty;
// //   }
// // }

// // class SyncProgress {
// //   const SyncProgress({
// //     required this.current,
// //     required this.total,
// //     this.packId,
// //     this.isComplete = false,
// //   });

// //   factory SyncProgress.complete() =>
// //       const SyncProgress(current: 0, total: 0, isComplete: true);

// //   final int current;
// //   final int total;
// //   final String? packId;
// //   final bool isComplete;

// //   double get fraction => total == 0 ? 1.0 : current / total;
// // }

// // import 'dart:async';

// // import 'package:sqflite/sqflite.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart';

// // import '../storage/database/app_database.dart';
// // import '../utils/app_logger.dart';
// // import '../../features/packs/data/pack_download_manager.dart';
// // import '../../features/packs/domain/pack_entity.dart';

// // /// Syncs purchased packs to local SQLite for offline play.
// // ///
// // /// Strategy:
// // ///   - On login: check which purchased packs aren't locally cached
// // ///   - Free packs: optionally auto-download on first access
// // ///   - No auto-version-sync required — user triggers manually
// // ///   - Cleanup: remove downloads for expired purchases
// // class PackSyncService {
// //   PackSyncService._();
// //   static final PackSyncService _instance = PackSyncService._();
// //   static PackSyncService get instance => _instance;

// //   final _supabase  = Supabase.instance.client;
// //   final _downloader = PackDownloadManager.instance;
// //   final _progressCtrl = StreamController<SyncProgress>.broadcast();

// //   Stream<SyncProgress> get progressStream => _progressCtrl.stream;

// //   bool _isSyncing = false;
// //   bool get isSyncing => _isSyncing;

// //   // ── Main sync ──────────────────────────────────────────────────────────────

// //   /// Called after login to sync metadata (not download files).
// //   /// Downloads happen explicitly by the user or after purchase.
// //   Future<void> sync(String userId) async {
// //     if (_isSyncing) return;
// //     _isSyncing = true;

// //     try {
// //       AppLogger.info('PackSyncService: syncing for $userId');

// //       // 1. Fetch active purchases from Supabase
// //       final purchases = await _fetchActivePurchases(userId);
// //       _progressCtrl.add(SyncProgress(current: 0, total: purchases.length));

// //       // 2. Write purchase records to local SQLite (for offline expiry checks)
// //       await _cachePurchaseRecords(purchases);

// //       // 3. Clean up downloads for expired purchases
// //       await _downloader.deleteExpiredDownloads(purchases);

// //       AppLogger.info('PackSyncService: sync complete (${purchases.length} packs)');
// //     } catch (e, st) {
// //       AppLogger.error('PackSyncService: sync failed', error: e, stackTrace: st);
// //     } finally {
// //       _isSyncing = false;
// //       _progressCtrl.add(SyncProgress.complete());
// //     }
// //   }

// //   // ── Purchase record caching ────────────────────────────────────────────────

// //   Future<List<PackPurchase>> _fetchActivePurchases(String userId) async {
// //     final rows = await _supabase
// //         .from('pack_purchases')
// //         .select('pack_id, purchased_at, expires_at, price_paid_mru')
// //         .eq('buyer_id', userId)
// //         .eq('status', 'completed')
// //         .gt('expires_at', DateTime.now().toIso8601String());

// //     return rows.map((r) => PackPurchase(
// //       packId:       r['pack_id']      as String,
// //       purchasedAt:  DateTime.parse(r['purchased_at'] as String),
// //       expiresAt:    DateTime.parse(r['expires_at'] as String),
// //       pricePaidMru: r['price_paid_mru'] as int? ?? 0,
// //     )).toList();
// //   }

// //   Future<void> _cachePurchaseRecords(List<PackPurchase> purchases) async {
// //     if (!AppDatabase.instance.isOpen) return;
// //     final db    = AppDatabase.instance.db;
// //     final batch = db.batch();

// //     // Clear stale records
// //     batch.delete('purchases');

// //     for (final p in purchases) {
// //       batch.insert(
// //         'purchases',
// //         {
// //           'pack_id':      p.packId,
// //           'purchased_at': p.purchasedAt.millisecondsSinceEpoch,
// //           'expires_at':   p.expiresAt.millisecondsSinceEpoch,
// //         },
// //         conflictAlgorithm: ConflictAlgorithm.replace,
// //       );
// //     }
// //     await batch.commit(noResult: true);
// //   }

// //   // ── Offline access check ───────────────────────────────────────────────────

// //   /// Check if a pack is accessible offline.
// //   /// Returns true if: pack is downloaded AND (it's free OR purchase hasn't expired).
// //   Future<bool> isPackAvailableOffline(String packId) async {
// //     if (!AppDatabase.instance.isOpen) return false;
// //     final db = AppDatabase.instance.db;

// //     // Check if downloaded
// //     final packRow = await db.query('packs', where: 'id = ?', whereArgs: [packId]);
// //     if (packRow.isEmpty) return false;

// //     // Free pack (price = 0) → available
// //     if ((packRow.first['price'] as int?) == 0) return true;

// //     // Check purchase not expired
// //     final purchaseRow = await db.query(
// //       'purchases',
// //       where: 'pack_id = ? AND expires_at > ?',
// //       whereArgs: [packId, DateTime.now().millisecondsSinceEpoch],
// //     );
// //     return purchaseRow.isNotEmpty;
// //   }
// // }

// // class SyncProgress {
// //   const SyncProgress({
// //     required this.current,
// //     required this.total,
// //     this.packId,
// //     this.isComplete = false,
// //   });

// //   factory SyncProgress.complete() =>
// //       const SyncProgress(current: 0, total: 0, isComplete: true);

// //   final int     current;
// //   final int     total;
// //   final String? packId;
// //   final bool    isComplete;

// //   double get fraction => total == 0 ? 1.0 : current / total;
// // }

// import 'dart:async';

// import 'package:sqflite/sqflite.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../storage/database/app_database.dart';
// import '../utils/app_logger.dart';
// import '../../features/packs/data/pack_download_manager.dart';
// import '../../features/packs/domain/pack_entity.dart';

// /// Syncs purchased packs to local SQLite for offline play.
// class PackSyncService {
//   PackSyncService._();
//   static final PackSyncService _instance = PackSyncService._();
//   static PackSyncService get instance => _instance;

//   final _supabase = Supabase.instance.client;
//   final _downloader = PackDownloadManager.instance;
//   final _progressCtrl = StreamController<SyncProgress>.broadcast();

//   Stream<SyncProgress> get progressStream => _progressCtrl.stream;

//   bool _isSyncing = false;
//   bool get isSyncing => _isSyncing;

//   // Flag to track if service is initialized
//   bool _isInitialized = false;

//   // ── Initialize service ─────────────────────────────────────────────────────

//   /// Call this after AppDatabase is opened
//   Future<void> initialize() async {
//     if (_isInitialized) return;

//     // Wait for database to be available
//     await _waitForDatabase();

//     _isInitialized = true;
//     AppLogger.info('PackSyncService: initialized');
//   }

//   Future<void> _waitForDatabase() async {
//     int attempts = 0;
//     const maxAttempts = 10;

//     while (!AppDatabase.instance.isOpen && attempts < maxAttempts) {
//       await Future.delayed(const Duration(milliseconds: 100));
//       attempts++;
//     }

//     if (!AppDatabase.instance.isOpen) {
//       AppLogger.warning(
//         'PackSyncService: Database not available after waiting',
//       );
//     }
//   }

//   // ── Main sync ──────────────────────────────────────────────────────────────

//   /// Called after login to sync metadata (not download files).
//   Future<void> sync(String userId) async {
//     if (_isSyncing) return;

//     // Check if database is available
//     if (!AppDatabase.instance.isOpen) {
//       AppLogger.warning('PackSyncService: Database not open, cannot sync');
//       return;
//     }

//     _isSyncing = true;

//     try {
//       AppLogger.info('PackSyncService: syncing for $userId');

//       // 1. Fetch active purchases from Supabase
//       final purchases = await _fetchActivePurchases(userId);
//       _progressCtrl.add(SyncProgress(current: 0, total: purchases.length));

//       // 2. Write purchase records to local SQLite (for offline expiry checks)
//       await _cachePurchaseRecords(purchases);

//       // 3. Clean up downloads for expired purchases
//       await _downloader.deleteExpiredDownloads(purchases);

//       AppLogger.info(
//         'PackSyncService: sync complete (${purchases.length} packs)',
//       );
//     } catch (e, st) {
//       AppLogger.error('PackSyncService: sync failed', error: e, stackTrace: st);
//     } finally {
//       _isSyncing = false;
//       _progressCtrl.add(SyncProgress.complete());
//     }
//   }

//   // ── Purchase record caching ────────────────────────────────────────────────

//   Future<List<PackPurchase>> _fetchActivePurchases(String userId) async {
//     try {
//       final rows = await _supabase
//           .from('pack_purchases')
//           .select('pack_id, purchased_at, expires_at, price_paid_mru')
//           .eq('buyer_id', userId)
//           .eq('status', 'completed')
//           .gt('expires_at', DateTime.now().toIso8601String());

//       return rows
//           .map(
//             (r) => PackPurchase(
//               packId: r['pack_id'] as String,
//               purchasedAt: DateTime.parse(r['purchased_at'] as String),
//               expiresAt: DateTime.parse(r['expires_at'] as String),
//               pricePaidMru: r['price_paid_mru'] as int? ?? 0,
//             ),
//           )
//           .toList();
//     } catch (e) {
//       AppLogger.error('Failed to fetch purchases: $e');
//       return [];
//     }
//   }

//   Future<void> _cachePurchaseRecords(List<PackPurchase> purchases) async {
//     if (!AppDatabase.instance.isOpen) {
//       AppLogger.warning('Database not open, skipping purchase record caching');
//       return;
//     }

//     try {
//       final db = AppDatabase.instance.db;

//       // Clear stale records - don't assign to variable since delete returns void
//       await db.delete('purchases');

//       // Insert new records using batch
//       final batch = db.batch();
//       for (final p in purchases) {
//         batch.insert('purchases', {
//           'pack_id': p.packId,
//           'purchased_at': p.purchasedAt.millisecondsSinceEpoch,
//           'expires_at': p.expiresAt.millisecondsSinceEpoch,
//         }, conflictAlgorithm: ConflictAlgorithm.replace);
//       }
//       await batch.commit(noResult: true);
//       AppLogger.debug('Cached ${purchases.length} purchase records');
//     } catch (e) {
//       AppLogger.error('Failed to cache purchase records: $e');
//     }
//   }

//   // ── Offline access check ───────────────────────────────────────────────────

//   /// Check if a pack is accessible offline.
//   Future<bool> isPackAvailableOffline(String packId) async {
//     if (!AppDatabase.instance.isOpen) {
//       AppLogger.warning('Database not open, pack not available offline');
//       return false;
//     }

//     try {
//       final db = AppDatabase.instance.db;

//       // Check if downloaded
//       final packRow = await db.query(
//         'packs',
//         where: 'id = ?',
//         whereArgs: [packId],
//       );
//       if (packRow.isEmpty) return false;

//       // Free pack (price = 0) → available
//       if ((packRow.first['price'] as int?) == 0) return true;

//       // Check purchase not expired
//       final purchaseRow = await db.query(
//         'purchases',
//         where: 'pack_id = ? AND expires_at > ?',
//         whereArgs: [packId, DateTime.now().millisecondsSinceEpoch],
//       );
//       return purchaseRow.isNotEmpty;
//     } catch (e) {
//       AppLogger.error('Failed to check pack availability: $e');
//       return false;
//     }
//   }

//   // ── Utility methods ────────────────────────────────────────────────────────

//   /// Check if a pack is downloaded
//   Future<bool> isPackDownloaded(String packId) async {
//     if (!AppDatabase.instance.isOpen) return false;

//     try {
//       final db = AppDatabase.instance.db;
//       final packRow = await db.query(
//         'packs',
//         where: 'id = ?',
//         whereArgs: [packId],
//       );
//       return packRow.isNotEmpty;
//     } catch (e) {
//       AppLogger.error('Failed to check if pack is downloaded: $e');
//       return false;
//     }
//   }

//   /// Get all downloaded pack IDs
//   Future<List<String>> getDownloadedPackIds() async {
//     if (!AppDatabase.instance.isOpen) return [];

//     try {
//       final db = AppDatabase.instance.db;
//       final result = await db.query('packs', columns: ['id']);
//       return result.map((row) => row['id'] as String).toList();
//     } catch (e) {
//       AppLogger.error('Failed to get downloaded pack IDs: $e');
//       return [];
//     }
//   }

//   /// Dispose method to clean up resources
//   void dispose() {
//     _progressCtrl.close();
//   }
// }

// class SyncProgress {
//   const SyncProgress({
//     required this.current,
//     required this.total,
//     this.packId,
//     this.isComplete = false,
//   });

//   factory SyncProgress.complete() =>
//       const SyncProgress(current: 0, total: 0, isComplete: true);

//   final int current;
//   final int total;
//   final String? packId;
//   final bool isComplete;

//   double get fraction => total == 0 ? 1.0 : current / total;
// }

import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../storage/database/app_database.dart';
import '../utils/app_logger.dart';
import '../../features/packs/data/pack_download_manager.dart';
import '../../features/packs/domain/pack_entity.dart';

class PackSyncService {
  PackSyncService._();
  static final PackSyncService _instance = PackSyncService._();
  static PackSyncService get instance => _instance;

  final _supabase = Supabase.instance.client;
  final _downloader = PackDownloadManager.instance;
  final _progressCtrl = StreamController<SyncProgress>.broadcast();

  Stream<SyncProgress> get progressStream => _progressCtrl.stream;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _waitForDatabase();

    _isInitialized = true;
    AppLogger.info('PackSyncService: initialized');
  }

  Future<void> _waitForDatabase() async {
    int attempts = 0;
    const maxAttempts = 10;

    while (!AppDatabase.instance.isOpen && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (!AppDatabase.instance.isOpen) {
      AppLogger.warning(
        'PackSyncService: Database not available after waiting',
      );
    }
  }

  Future<void> sync(String userId) async {
    if (_isSyncing) return;

    if (!AppDatabase.instance.isOpen) {
      AppLogger.warning('PackSyncService: Database not open, cannot sync');
      return;
    }

    _isSyncing = true;

    try {
      AppLogger.info('PackSyncService: syncing for $userId');

      final purchases = await _fetchActivePurchases(userId);
      _progressCtrl.add(SyncProgress(current: 0, total: purchases.length));

      await _cachePurchaseRecords(purchases);

      await _downloader.deleteExpiredDownloads(purchases);

      AppLogger.info(
        'PackSyncService: sync complete (${purchases.length} packs)',
      );
    } catch (e, st) {
      AppLogger.error('PackSyncService: sync failed', error: e, stackTrace: st);
    } finally {
      _isSyncing = false;
      _progressCtrl.add(SyncProgress.complete());
    }
  }

  Future<List<PackPurchase>> _fetchActivePurchases(String userId) async {
    try {
      final rows = await _supabase
          .from('pack_purchases')
          .select('pack_id, purchased_at, expires_at, price_paid_mru')
          .eq('buyer_id', userId)
          .eq('status', 'completed')
          .gt('expires_at', DateTime.now().toIso8601String());

      return rows
          .map(
            (r) => PackPurchase(
              packId: r['pack_id'] as String,
              purchasedAt: DateTime.parse(r['purchased_at'] as String),
              expiresAt: DateTime.parse(r['expires_at'] as String),
              pricePaidMru: r['price_paid_mru'] as int? ?? 0,
            ),
          )
          .toList();
    } catch (e) {
      AppLogger.error('Failed to fetch purchases: $e');
      return [];
    }
  }

  Future<void> _cachePurchaseRecords(List<PackPurchase> purchases) async {
    if (!AppDatabase.instance.isOpen) {
      AppLogger.warning('Database not open, skipping purchase record caching');
      return;
    }

    try {
      final db = AppDatabase.instance.db;

      await db.delete('purchases');

      final batch = db.batch();
      for (final p in purchases) {
        batch.insert('purchases', {
          'pack_id': p.packId,
          'purchased_at': p.purchasedAt.millisecondsSinceEpoch,
          'expires_at': p.expiresAt?.millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
      AppLogger.debug('Cached ${purchases.length} purchase records');
    } catch (e) {
      AppLogger.error('Failed to cache purchase records: $e');
    }
  }

  Future<bool> isPackAvailableOffline(String packId) async {
    if (!AppDatabase.instance.isOpen) {
      AppLogger.warning('Database not open, pack not available offline');
      return false;
    }

    try {
      final db = AppDatabase.instance.db;

      final packRow = await db.query(
        'packs',
        where: 'id = ?',
        whereArgs: [packId],
      );
      if (packRow.isEmpty) return false;

      if ((packRow.first['price'] as int?) == 0) return true;

      final purchaseRow = await db.query(
        'purchases',
        where: 'pack_id = ? AND expires_at > ?',
        whereArgs: [packId, DateTime.now().millisecondsSinceEpoch],
      );
      return purchaseRow.isNotEmpty;
    } catch (e) {
      AppLogger.error('Failed to check pack availability: $e');
      return false;
    }
  }

  Future<bool> isPackDownloaded(String packId) async {
    if (!AppDatabase.instance.isOpen) return false;

    try {
      final db = AppDatabase.instance.db;
      final packRow = await db.query(
        'packs',
        where: 'id = ?',
        whereArgs: [packId],
      );
      return packRow.isNotEmpty;
    } catch (e) {
      AppLogger.error('Failed to check if pack is downloaded: $e');
      return false;
    }
  }

  Future<List<String>> getDownloadedPackIds() async {
    if (!AppDatabase.instance.isOpen) return [];

    try {
      final db = AppDatabase.instance.db;
      final result = await db.query('packs', columns: ['id']);
      return result.map((row) => row['id'] as String).toList();
    } catch (e) {
      AppLogger.error('Failed to get downloaded pack IDs: $e');
      return [];
    }
  }

  void dispose() {
    _progressCtrl.close();
  }
}

class SyncProgress {
  const SyncProgress({
    required this.current,
    required this.total,
    this.packId,
    this.isComplete = false,
  });

  factory SyncProgress.complete() =>
      const SyncProgress(current: 0, total: 0, isComplete: true);

  final int current;
  final int total;
  final String? packId;
  final bool isComplete;

  double get fraction => total == 0 ? 1.0 : current / total;
}
