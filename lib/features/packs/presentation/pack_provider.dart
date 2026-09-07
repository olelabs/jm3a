// // // import 'dart:async';

// // // import '../../../core/errors/failures.dart';
// // // import '../../../core/providers/base_provider.dart';
// // // import '../../../core/services/pack_sync_service.dart';
// // // import '../../../core/utils/app_logger.dart';
// // // import '../data/pack_download_manager.dart';
// // // import '../data/pack_repository.dart';
// // // import '../domain/pack_entity.dart';

// // // export '../domain/pack_entity.dart';

// // // class PackProvider extends BaseProvider {
// // //   PackProvider({
// // //     required PackRepository packRepository,
// // //     required PackSyncService packSyncService,
// // //   }) : _repo = packRepository,
// // //        _syncService = packSyncService {
// // //     // Restore download states from SQLite immediately on startup
// // //     // This runs regardless of auth state so guest mode and restarts work
// // //     _hydrateAllDownloads();
// // //   }

// // //   final PackRepository _repo;
// // //   final PackSyncService _syncService;
// // //   final _downloader = PackDownloadManager.instance;

// // //   List<PackEntity> _browsePacks = [];
// // //   List<PackEntity> _featuredPacks = [];
// // //   List<PackEntity> _promotedPacks = [];
// // //   List<PackCategory> _categories = [];
// // //   int _browsePage = 0;
// // //   bool _hasMorePacks = true;
// // //   bool _isLoadingMore = false;
// // //   List<PackEntity> _purchasedPacks = [];
// // //   List<PackEntity> _createdPacks = [];
// // //   List<PackPurchase> _purchaseRecords = [];
// // //   final _downloadStates = <String, PackDownloadState>{};
// // //   StreamSubscription<MapEntry<String, PackDownloadState>>? _downloadSub;
// // //   bool _isSyncing = false;

// // //   List<PackEntity> _localPacks =
// // //       []; // packs loaded from local SQLite (offline fallback)

// // //   List<PackEntity> get browsePacks => _browsePacks;
// // //   List<PackEntity> get featuredPacks => _featuredPacks;
// // //   List<PackEntity> get localPacks => _localPacks; // offline-ready SQLite cache

// // //   /// All pack IDs that are fully downloaded (regardless of purchase status)
// // //   List<String> get allDownloadedPackIds => _downloadStates.entries
// // //       .where((e) => e.value.isDownloaded)
// // //       .map((e) => e.key)
// // //       .toList();
// // //   List<PackEntity> get promotedPacks => _promotedPacks;
// // //   List<PackCategory> get categories => _categories;
// // //   List<PackEntity> get purchasedPacks => _purchasedPacks;
// // //   List<PackEntity> get createdPacks => _createdPacks;
// // //   List<PackEntity> get allPacks => {
// // //     ..._browsePacks,
// // //     ..._purchasedPacks,
// // //     ..._featuredPacks,
// // //     ..._promotedPacks,
// // //   }.toList();
// // //   bool get hasMorePacks => _hasMorePacks;
// // //   bool get isLoadingMore => _isLoadingMore;
// // //   bool get isSyncing => _isSyncing;

// // //   PackDownloadState downloadStateFor(String packId) =>
// // //       _downloadStates[packId] ?? PackDownloadState.initial(packId);

// // //   bool hasActivePurchase(String packId) =>
// // //       _purchasedPacks.any((p) => p.id == packId);

// // //   bool isOwned(PackEntity pack) => pack.isFree || hasActivePurchase(pack.id);

// // //   PackPurchase? purchaseFor(String packId) => _purchaseRecords
// // //       .cast<PackPurchase?>()
// // //       .firstWhere((r) => r?.packId == packId, orElse: () => null);

// // //   @override
// // //   void onUserLoggedIn(String userId) {
// // //     _listenDownloads();
// // //     _loadCategories();
// // //     loadBrowsePacks(reset: true);
// // //     _loadFeatured();
// // //     _loadPurchased(userId);
// // //     _syncPacks(userId);
// // //     // Restore download states from SQLite for all previously downloaded packs
// // //     _hydrateAllDownloads();
// // //   }

// // //   Future<void> _hydrateAllDownloads() async {
// // //     try {
// // //       final ids = await _downloader.getDownloadedPackIds();
// // //       for (final id in ids) {
// // //         try {
// // //           _downloadStates[id] = await _downloader.getDownloadState(id);
// // //         } catch (_) {}
// // //       }
// // //       // Populate local pack cache from SQLite for offline display
// // //       _localPacks = await _downloader.getDownloadedPacks();
// // //       if (ids.isNotEmpty) notifyListeners();
// // //     } catch (e) {
// // //       AppLogger.warning('PackProvider: _hydrateAllDownloads failed: $e');
// // //     }
// // //   }

// // //   @override
// // //   void onAuthChanged(String? userId) {
// // //     // Always restore download states from SQLite — they persist across auth changes
// // //     _hydrateAllDownloads();
// // //     if (currentUserId != userId) {
// // //       super.onAuthChanged(userId);
// // //     }
// // //   }

// // //   @override
// // //   void onUserLoggedOut() {
// // //     _downloadSub?.cancel();
// // //     _browsePacks = [];
// // //     _featuredPacks = [];
// // //     _promotedPacks = [];
// // //     _purchasedPacks = [];
// // //     _createdPacks = [];
// // //     _purchaseRecords = [];
// // //     // Do NOT clear _downloadStates — downloads persist across logout/guest mode
// // //     _hydrateAllDownloads();
// // //     super.onUserLoggedOut();
// // //   }

// // //   @override
// // //   void dispose() {
// // //     _downloadSub?.cancel();
// // //     super.dispose();
// // //   }

// // //   Future<void> loadBrowsePacks({
// // //     bool reset = false,
// // //     String? gameType,
// // //     String? categoryId,
// // //     bool freeOnly = false,
// // //     String? language,
// // //     String sortBy = 'avg_rating',
// // //   }) async {
// // //     if (reset) {
// // //       _browsePage = 0;
// // //       _hasMorePacks = true;
// // //       _browsePacks = [];
// // //     }
// // //     if (!_hasMorePacks) return;
// // //     await runAsync(() async {
// // //       const perPage = 20;
// // //       final packs = await _repo.browsePacks(
// // //         gameType: gameType,
// // //         categoryId: categoryId,
// // //         freeOnly: freeOnly,
// // //         language: language,
// // //         sortBy: sortBy,
// // //         page: _browsePage,
// // //         perPage: perPage,
// // //       );
// // //       _browsePacks = reset ? packs : [..._browsePacks, ...packs];
// // //       _hasMorePacks = packs.length == perPage;
// // //       _browsePage++;
// // //       await _hydrateDownloadStates(packs.map((p) => p.id).toList());
// // //     });
// // //   }

// // //   Future<void> loadMoreBrowsePacks({
// // //     String? gameType,
// // //     String? categoryId,
// // //   }) async {
// // //     if (_isLoadingMore || !_hasMorePacks) return;
// // //     _isLoadingMore = true;
// // //     notifyListeners();
// // //     try {
// // //       await loadBrowsePacks(gameType: gameType, categoryId: categoryId);
// // //     } finally {
// // //       _isLoadingMore = false;
// // //       notifyListeners();
// // //     }
// // //   }

// // //   Future<void> _loadFeatured() => runAsync(() async {
// // //     _featuredPacks = await _repo.getFeaturedPacks();
// // //     _promotedPacks = await _repo.getPromotedPacks();
// // //   }, setLoading: false);

// // //   Future<void> _loadCategories() => runAsync(() async {
// // //     _categories = await _repo.getCategories();
// // //   }, setLoading: false);

// // //   Future<void> _loadPurchased(String userId) => runAsync(() async {
// // //     _purchasedPacks = await _repo.getMyPurchasedPacks(userId);
// // //     _purchaseRecords = await _repo.getMyPurchaseRecords(userId);
// // //     await _hydrateDownloadStates(_purchasedPacks.map((p) => p.id).toList());
// // //   }, setLoading: false);

// // //   Future<void> loadCreatedPacks() async {
// // //     if (currentUserId == null) return;
// // //     await runAsync(() async {
// // //       _createdPacks = await _repo.getMyCreatedPacks(currentUserId!);
// // //     }, setLoading: false);
// // //   }

// // //   Future<String?> purchasePack(PackEntity pack) async {
// // //     try {
// // //       await _repo.purchasePack(pack.id);
// // //       // Reload and explicitly notify — runAsync(setLoading:false) won't notify on success
// // //       if (currentUserId != null) {
// // //         _purchasedPacks = await _repo.getMyPurchasedPacks(currentUserId!);
// // //         _purchaseRecords = await _repo.getMyPurchaseRecords(currentUserId!);
// // //         notifyListeners();
// // //       }
// // //       return null; // null = success
// // //     } catch (e) {
// // //       final msg = e.toString().replaceFirst('Exception: ', '');
// // //       return msg;
// // //     }
// // //   }

// // //   Future<void> downloadPack(PackEntity pack) async {
// // //     if (!isOwned(pack)) return;
// // //     await _downloader.download(pack);
// // //     // Refresh local SQLite cache so offline display stays current
// // //     await _hydrateAllDownloads();
// // //   }

// // //   Future<void> deletePack(String packId) async {
// // //     await _downloader.deleteDownload(packId);
// // //     _downloadStates[packId] = PackDownloadState.initial(packId);
// // //     notifyListeners();
// // //   }

// // //   void _listenDownloads() {
// // //     _downloadSub?.cancel();
// // //     _downloadSub = _downloader.globalProgress.listen((entry) {
// // //       _downloadStates[entry.key] = entry.value;
// // //       notifyListeners();
// // //     });
// // //   }

// // //   Future<void> _hydrateDownloadStates(List<String> packIds) async {
// // //     for (final id in packIds) {
// // //       if (!(_downloadStates[id]?.isDownloaded ?? false)) {
// // //         _downloadStates[id] = await _downloader.getDownloadState(id);
// // //       }
// // //     }
// // //     notifyListeners();
// // //   }

// // //   Future<bool> ratePack(String packId, int rating) async {
// // //     if (currentUserId == null) return false;
// // //     var success = false;
// // //     await runAsync(() async {
// // //       await _repo.ratePack(
// // //         packId: packId,
// // //         userId: currentUserId!,
// // //         rating: rating,
// // //       );
// // //       success = true;
// // //     }, setLoading: false);
// // //     return success;
// // //   }

// // //   Future<bool> submitReview({
// // //     required String packId,
// // //     required String content,
// // //     int? rating,
// // //   }) async {
// // //     if (currentUserId == null) return false;
// // //     var success = false;
// // //     await runAsync(() async {
// // //       await _repo.submitReview(
// // //         packId: packId,
// // //         userId: currentUserId!,
// // //         content: content,
// // //         rating: rating,
// // //       );
// // //       success = true;
// // //     }, setLoading: false);
// // //     return success;
// // //   }

// // //   Future<bool> reportPack({
// // //     required String packId,
// // //     required String reason,
// // //     String? details,
// // //   }) async {
// // //     if (currentUserId == null) return false;
// // //     var success = false;
// // //     await runAsync(() async {
// // //       await _repo.reportPack(
// // //         packId: packId,
// // //         reporterId: currentUserId!,
// // //         reason: reason,
// // //         details: details,
// // //       );
// // //       success = true;
// // //     }, setLoading: false);
// // //     return success;
// // //   }

// // //   Future<void> _syncPacks(String userId) async {
// // //     _isSyncing = true;
// // //     notifyListeners();
// // //     await _syncService.sync(userId);
// // //     _isSyncing = false;
// // //     notifyListeners();
// // //   }
// // // }

// // import 'dart:async';

// // import '../../../core/errors/failures.dart';
// // import '../../../core/providers/base_provider.dart';
// // import '../../../core/services/pack_sync_service.dart';
// // import '../../../core/utils/app_logger.dart';
// // import '../data/pack_download_manager.dart';
// // import '../data/pack_repository.dart';
// // import '../domain/pack_entity.dart';

// // export '../domain/pack_entity.dart';

// // class PackProvider extends BaseProvider {
// //   PackProvider({
// //     required PackRepository packRepository,
// //     required PackSyncService packSyncService,
// //   }) : _repo = packRepository,
// //        _syncService = packSyncService {
// //     // Restore download states from SQLite immediately on startup
// //     // This runs regardless of auth state so guest mode and restarts work
// //     _hydrateAllDownloads();
// //   }

// //   final PackRepository _repo;
// //   final PackSyncService _syncService;
// //   final _downloader = PackDownloadManager.instance;

// //   List<PackEntity> _browsePacks = [];
// //   List<PackEntity> _featuredPacks = [];
// //   List<PackEntity> _promotedPacks = [];
// //   List<PackCategory> _categories = [];
// //   int _browsePage = 0;
// //   bool _hasMorePacks = true;
// //   bool _isLoadingMore = false;
// //   List<PackEntity> _purchasedPacks = [];
// //   List<PackEntity> _createdPacks = [];
// //   List<PackPurchase> _purchaseRecords = [];
// //   final _downloadStates = <String, PackDownloadState>{};
// //   StreamSubscription<MapEntry<String, PackDownloadState>>? _downloadSub;
// //   bool _isSyncing = false;

// //   List<PackEntity> _localPacks =
// //       []; // packs loaded from local SQLite (offline fallback)

// //   List<PackEntity> get browsePacks => _browsePacks;
// //   List<PackEntity> get featuredPacks => _featuredPacks;
// //   List<PackEntity> get localPacks => _localPacks; // offline-ready SQLite cache

// //   /// All pack IDs that are fully downloaded (regardless of purchase status)
// //   List<String> get allDownloadedPackIds => _downloadStates.entries
// //       .where((e) => e.value.isDownloaded)
// //       .map((e) => e.key)
// //       .toList();
// //   List<PackEntity> get promotedPacks => _promotedPacks;
// //   List<PackCategory> get categories => _categories;
// //   List<PackEntity> get purchasedPacks => _purchasedPacks;
// //   List<PackEntity> get createdPacks => _createdPacks;
// //   List<PackEntity> get allPacks => {
// //     ..._browsePacks,
// //     ..._purchasedPacks,
// //     ..._featuredPacks,
// //     ..._promotedPacks,
// //   }.toList();
// //   bool get hasMorePacks => _hasMorePacks;
// //   bool get isLoadingMore => _isLoadingMore;
// //   bool get isSyncing => _isSyncing;

// //   PackDownloadState downloadStateFor(String packId) =>
// //       _downloadStates[packId] ?? PackDownloadState.initial(packId);

// //   bool hasActivePurchase(String packId) =>
// //       _purchasedPacks.any((p) => p.id == packId);

// //   bool isOwned(PackEntity pack) => pack.isFree || hasActivePurchase(pack.id);

// //   PackPurchase? purchaseFor(String packId) => _purchaseRecords
// //       .cast<PackPurchase?>()
// //       .firstWhere((r) => r?.packId == packId, orElse: () => null);

// //   @override
// //   void onUserLoggedIn(String userId) {
// //     _listenDownloads();
// //     _loadCategories();
// //     loadBrowsePacks(reset: true);
// //     _loadFeatured();
// //     _loadPurchased(userId);
// //     loadCreatedPacks();
// //     _syncPacks(userId);
// //     _hydrateAllDownloads();
// //   }

// //   Future<void> _hydrateAllDownloads() async {
// //     try {
// //       final ids = await _downloader.getDownloadedPackIds();
// //       for (final id in ids) {
// //         try {
// //           _downloadStates[id] = await _downloader.getDownloadState(id);
// //         } catch (_) {}
// //       }
// //       // Populate local pack cache from SQLite for offline display
// //       _localPacks = await _downloader.getDownloadedPacks();
// //       if (ids.isNotEmpty) notifyListeners();
// //     } catch (e) {
// //       AppLogger.warning('PackProvider: _hydrateAllDownloads failed: $e');
// //     }
// //   }

// //   @override
// //   void onAuthChanged(String? userId) {
// //     // Always restore download states from SQLite — they persist across auth changes
// //     _hydrateAllDownloads();
// //     if (currentUserId != userId) {
// //       super.onAuthChanged(userId);
// //     }
// //   }

// //   @override
// //   void onUserLoggedOut() {
// //     _downloadSub?.cancel();
// //     _browsePacks = [];
// //     _featuredPacks = [];
// //     _promotedPacks = [];
// //     _purchasedPacks = [];
// //     _createdPacks = [];
// //     _purchaseRecords = [];
// //     // Do NOT clear _downloadStates — downloads persist across logout/guest mode
// //     _hydrateAllDownloads();
// //     super.onUserLoggedOut();
// //   }

// //   @override
// //   void dispose() {
// //     _downloadSub?.cancel();
// //     super.dispose();
// //   }

// //   Future<void> loadBrowsePacks({
// //     bool reset = false,
// //     String? gameType,
// //     String? categoryId,
// //     bool freeOnly = false,
// //     String? language,
// //     String sortBy = 'avg_rating',
// //   }) async {
// //     if (reset) {
// //       _browsePage = 0;
// //       _hasMorePacks = true;
// //       _browsePacks = [];
// //     }
// //     if (!_hasMorePacks) return;
// //     await runAsync(() async {
// //       const perPage = 20;
// //       final packs = await _repo.browsePacks(
// //         gameType: gameType,
// //         categoryId: categoryId,
// //         freeOnly: freeOnly,
// //         language: language,
// //         sortBy: sortBy,
// //         page: _browsePage,
// //         perPage: perPage,
// //       );
// //       _browsePacks = reset ? packs : [..._browsePacks, ...packs];
// //       _hasMorePacks = packs.length == perPage;
// //       _browsePage++;
// //       await _hydrateDownloadStates(packs.map((p) => p.id).toList());
// //     });
// //   }

// //   Future<void> loadMoreBrowsePacks({
// //     String? gameType,
// //     String? categoryId,
// //   }) async {
// //     if (_isLoadingMore || !_hasMorePacks) return;
// //     _isLoadingMore = true;
// //     notifyListeners();
// //     try {
// //       await loadBrowsePacks(gameType: gameType, categoryId: categoryId);
// //     } finally {
// //       _isLoadingMore = false;
// //       notifyListeners();
// //     }
// //   }

// //   Future<void> _loadFeatured() => runAsync(() async {
// //     _featuredPacks = await _repo.getFeaturedPacks();
// //     _promotedPacks = await _repo.getPromotedPacks();
// //   }, setLoading: false);

// //   Future<void> _loadCategories() => runAsync(() async {
// //     _categories = await _repo.getCategories();
// //   }, setLoading: false);

// //   Future<void> _loadPurchased(String userId) => runAsync(() async {
// //     _purchasedPacks = await _repo.getMyPurchasedPacks(userId);
// //     _purchaseRecords = await _repo.getMyPurchaseRecords(userId);
// //     await _hydrateDownloadStates(_purchasedPacks.map((p) => p.id).toList());
// //   }, setLoading: false);

// //   Future<void> loadCreatedPacks() async {
// //     if (currentUserId == null) return;
// //     await runAsync(() async {
// //       _createdPacks = await _repo.getMyCreatedPacks(currentUserId!);
// //     }, setLoading: false);
// //   }

// //   Future<String?> purchasePack(PackEntity pack) async {
// //     try {
// //       await _repo.purchasePack(pack.id);
// //       // Reload and explicitly notify — runAsync(setLoading:false) won't notify on success
// //       if (currentUserId != null) {
// //         _purchasedPacks = await _repo.getMyPurchasedPacks(currentUserId!);
// //         _purchaseRecords = await _repo.getMyPurchaseRecords(currentUserId!);
// //         notifyListeners();
// //       }
// //       return null; // null = success
// //     } catch (e) {
// //       final msg = e.toString().replaceFirst('Exception: ', '');
// //       return msg;
// //     }
// //   }

// //   Future<void> downloadPack(PackEntity pack) async {
// //     if (!isOwned(pack)) return;
// //     await _downloader.download(pack);
// //     // Refresh local SQLite cache so offline display stays current
// //     await _hydrateAllDownloads();
// //   }

// //   Future<void> deletePack(String packId) async {
// //     await _downloader.deleteDownload(packId);
// //     _downloadStates[packId] = PackDownloadState.initial(packId);
// //     notifyListeners();
// //   }

// //   void _listenDownloads() {
// //     _downloadSub?.cancel();
// //     _downloadSub = _downloader.globalProgress.listen((entry) {
// //       _downloadStates[entry.key] = entry.value;
// //       notifyListeners();
// //     });
// //   }

// //   Future<void> _hydrateDownloadStates(List<String> packIds) async {
// //     for (final id in packIds) {
// //       if (!(_downloadStates[id]?.isDownloaded ?? false)) {
// //         _downloadStates[id] = await _downloader.getDownloadState(id);
// //       }
// //     }
// //     notifyListeners();
// //   }

// //   Future<bool> ratePack(String packId, int rating) async {
// //     if (currentUserId == null) return false;
// //     var success = false;
// //     await runAsync(() async {
// //       await _repo.ratePack(
// //         packId: packId,
// //         userId: currentUserId!,
// //         rating: rating,
// //       );
// //       success = true;
// //     }, setLoading: false);
// //     return success;
// //   }

// //   Future<bool> submitReview({
// //     required String packId,
// //     required String content,
// //     int? rating,
// //   }) async {
// //     if (currentUserId == null) return false;
// //     var success = false;
// //     await runAsync(() async {
// //       await _repo.submitReview(
// //         packId: packId,
// //         userId: currentUserId!,
// //         content: content,
// //         rating: rating,
// //       );
// //       success = true;
// //     }, setLoading: false);
// //     return success;
// //   }

// //   Future<bool> reportPack({
// //     required String packId,
// //     required String reason,
// //     String? details,
// //   }) async {
// //     if (currentUserId == null) return false;
// //     var success = false;
// //     await runAsync(() async {
// //       await _repo.reportPack(
// //         packId: packId,
// //         reporterId: currentUserId!,
// //         reason: reason,
// //         details: details,
// //       );
// //       success = true;
// //     }, setLoading: false);
// //     return success;
// //   }

// //   Future<void> _syncPacks(String userId) async {
// //     _isSyncing = true;
// //     notifyListeners();
// //     await _syncService.sync(userId);
// //     _isSyncing = false;
// //     notifyListeners();
// //   }
// // }

// import 'dart:async';

// import '../../../core/errors/failures.dart';
// import '../../../core/providers/base_provider.dart';
// import '../../../core/services/pack_sync_service.dart';
// import '../../../core/utils/app_logger.dart';
// import '../data/pack_download_manager.dart';
// import '../data/pack_repository.dart';
// import '../domain/pack_entity.dart';

// export '../domain/pack_entity.dart';

// class PackProvider extends BaseProvider {
//   PackProvider({
//     required PackRepository packRepository,
//     required PackSyncService packSyncService,
//   }) : _repo = packRepository,
//        _syncService = packSyncService {
//     _hydrateAllDownloads();
//   }

//   final PackRepository _repo;
//   final PackSyncService _syncService;
//   final _downloader = PackDownloadManager.instance;

//   List<PackEntity> _browsePacks = [];
//   List<PackEntity> _featuredPacks = [];
//   List<PackEntity> _promotedPacks = [];
//   List<PackCategory> _categories = [];
//   int _browsePage = 0;
//   bool _hasMorePacks = true;
//   bool _isLoadingMore = false;
//   List<PackEntity> _purchasedPacks = [];
//   List<PackEntity> _createdPacks = [];
//   List<PackPurchase> _purchaseRecords = [];
//   final _downloadStates = <String, PackDownloadState>{};
//   StreamSubscription<MapEntry<String, PackDownloadState>>? _downloadSub;
//   bool _isSyncing = false;

//   List<PackEntity> _localPacks = [];

//   List<PackEntity> get browsePacks => _browsePacks;
//   List<PackEntity> get featuredPacks => _featuredPacks;
//   List<PackEntity> get localPacks => _localPacks;

//   List<String> get allDownloadedPackIds => _downloadStates.entries
//       .where((e) => e.value.isDownloaded)
//       .map((e) => e.key)
//       .toList();
//   List<PackEntity> get promotedPacks => _promotedPacks;
//   List<PackCategory> get categories => _categories;
//   List<PackEntity> get purchasedPacks => _purchasedPacks;
//   List<PackEntity> get createdPacks => _createdPacks;
//   List<PackEntity> get allPacks => {
//     ..._browsePacks,
//     ..._purchasedPacks,
//     ..._featuredPacks,
//     ..._promotedPacks,
//   }.toList();
//   bool get hasMorePacks => _hasMorePacks;
//   bool get isLoadingMore => _isLoadingMore;
//   bool get isSyncing => _isSyncing;

//   PackDownloadState downloadStateFor(String packId) =>
//       _downloadStates[packId] ?? PackDownloadState.initial(packId);

//   bool hasActivePurchase(String packId) =>
//       _purchasedPacks.any((p) => p.id == packId);

//   bool isOwned(PackEntity pack) => pack.isFree || hasActivePurchase(pack.id);

//   PackPurchase? purchaseFor(String packId) => _purchaseRecords
//       .cast<PackPurchase?>()
//       .firstWhere((r) => r?.packId == packId, orElse: () => null);

//   @override
//   void onUserLoggedIn(String userId) {
//     _listenDownloads();
//     _loadCategories();
//     loadBrowsePacks(reset: true);
//     _loadFeatured();
//     _loadPurchased(userId);
//     loadCreatedPacks();
//     _syncPacks(userId);
//     _hydrateAllDownloads();
//   }

//   Future<void> _hydrateAllDownloads() async {
//     try {
//       final ids = await _downloader.getDownloadedPackIds();
//       for (final id in ids) {
//         try {
//           _downloadStates[id] = await _downloader.getDownloadState(id);
//         } catch (_) {}
//       }
//       _localPacks = await _downloader.getDownloadedPacks();
//       if (ids.isNotEmpty) notifyListeners();
//     } catch (e) {
//       AppLogger.warning('PackProvider: _hydrateAllDownloads failed: $e');
//     }
//   }

//   @override
//   void onAuthChanged(String? userId) {
//     _hydrateAllDownloads();
//     if (currentUserId != userId) {
//       super.onAuthChanged(userId);
//     }
//   }

//   @override
//   void onUserLoggedOut() {
//     _downloadSub?.cancel();
//     _browsePacks = [];
//     _featuredPacks = [];
//     _promotedPacks = [];
//     _purchasedPacks = [];
//     _createdPacks = [];
//     _purchaseRecords = [];
//     _hydrateAllDownloads();
//     super.onUserLoggedOut();
//   }

//   @override
//   void dispose() {
//     _downloadSub?.cancel();
//     super.dispose();
//   }

//   Future<void> loadBrowsePacks({
//     bool reset = false,
//     String? gameType,
//     String? categoryId,
//     bool freeOnly = false,
//     String? language,
//     String sortBy = 'avg_rating',
//   }) async {
//     if (reset) {
//       _browsePage = 0;
//       _hasMorePacks = true;
//       _browsePacks = [];
//     }
//     if (!_hasMorePacks) return;
//     await runAsync(() async {
//       const perPage = 20;
//       final packs = await _repo.browsePacks(
//         gameType: gameType,
//         categoryId: categoryId,
//         freeOnly: freeOnly,
//         language: language,
//         sortBy: sortBy,
//         page: _browsePage,
//         perPage: perPage,
//       );
//       _browsePacks = reset ? packs : [..._browsePacks, ...packs];
//       _hasMorePacks = packs.length == perPage;
//       _browsePage++;
//       await _hydrateDownloadStates(packs.map((p) => p.id).toList());
//     });
//   }

//   Future<void> loadMoreBrowsePacks({
//     String? gameType,
//     String? categoryId,
//   }) async {
//     if (_isLoadingMore || !_hasMorePacks) return;
//     _isLoadingMore = true;
//     notifyListeners();
//     try {
//       await loadBrowsePacks(gameType: gameType, categoryId: categoryId);
//     } finally {
//       _isLoadingMore = false;
//       notifyListeners();
//     }
//   }

//   Future<void> _loadFeatured() => runAsync(() async {
//     _featuredPacks = await _repo.getFeaturedPacks();
//     _promotedPacks = await _repo.getPromotedPacks();
//   }, setLoading: false);

//   Future<void> _loadCategories() => runAsync(() async {
//     _categories = await _repo.getCategories();
//   }, setLoading: false);

//   Future<void> _loadPurchased(String userId) => runAsync(() async {
//     _purchasedPacks = await _repo.getMyPurchasedPacks(userId);
//     _purchaseRecords = await _repo.getMyPurchaseRecords(userId);
//     await _hydrateDownloadStates(_purchasedPacks.map((p) => p.id).toList());
//   }, setLoading: false);

//   Future<void> loadCreatedPacks() async {
//     if (currentUserId == null) return;
//     await runAsync(() async {
//       _createdPacks = await _repo.getMyCreatedPacks(currentUserId!);
//     }, setLoading: false);
//   }

//   Future<String?> purchasePack(PackEntity pack) async {
//     try {
//       await _repo.purchasePack(pack.id);
//       if (currentUserId != null) {
//         _purchasedPacks = await _repo.getMyPurchasedPacks(currentUserId!);
//         _purchaseRecords = await _repo.getMyPurchaseRecords(currentUserId!);
//         notifyListeners();
//       }
//       return null;
//     } catch (e) {
//       final msg = e.toString().replaceFirst('Exception: ', '');
//       return msg;
//     }
//   }

//   Future<bool> downloadPack(PackEntity pack, {required bool isPremium}) async {
//     if (!isOwned(pack)) return false;
//     final limit = isPremium ? 10 : 1;
//     if (_localPacks.length >= limit) return false;
//     await _downloader.download(pack);
//     await _hydrateAllDownloads();
//     return true;
//   }

//   Future<void> deletePack(String packId) async {
//     await _downloader.deleteDownload(packId);
//     _downloadStates[packId] = PackDownloadState.initial(packId);
//     notifyListeners();
//   }

//   void _listenDownloads() {
//     _downloadSub?.cancel();
//     _downloadSub = _downloader.globalProgress.listen((entry) {
//       _downloadStates[entry.key] = entry.value;
//       notifyListeners();
//     });
//   }

//   Future<void> _hydrateDownloadStates(List<String> packIds) async {
//     for (final id in packIds) {
//       if (!(_downloadStates[id]?.isDownloaded ?? false)) {
//         _downloadStates[id] = await _downloader.getDownloadState(id);
//       }
//     }
//     notifyListeners();
//   }

//   Future<bool> ratePack(String packId, int rating) async {
//     if (currentUserId == null) return false;
//     var success = false;
//     await runAsync(() async {
//       await _repo.ratePack(
//         packId: packId,
//         userId: currentUserId!,
//         rating: rating,
//       );
//       success = true;
//     }, setLoading: false);
//     return success;
//   }

//   Future<bool> submitReview({
//     required String packId,
//     required String content,
//     int? rating,
//   }) async {
//     if (currentUserId == null) return false;
//     var success = false;
//     await runAsync(() async {
//       await _repo.submitReview(
//         packId: packId,
//         userId: currentUserId!,
//         content: content,
//         rating: rating,
//       );
//       success = true;
//     }, setLoading: false);
//     return success;
//   }

//   Future<bool> reportPack({
//     required String packId,
//     required String reason,
//     String? details,
//   }) async {
//     if (currentUserId == null) return false;
//     var success = false;
//     await runAsync(() async {
//       await _repo.reportPack(
//         packId: packId,
//         reporterId: currentUserId!,
//         reason: reason,
//         details: details,
//       );
//       success = true;
//     }, setLoading: false);
//     return success;
//   }

//   Future<void> _syncPacks(String userId) async {
//     _isSyncing = true;
//     notifyListeners();
//     await _syncService.sync(userId);
//     _isSyncing = false;
//     notifyListeners();
//   }
// }

import 'dart:async';

import '../../../core/errors/failures.dart';
import '../../../core/providers/base_provider.dart';
import '../../../core/services/pack_sync_service.dart';
import '../../../core/utils/app_logger.dart';
import '../data/pack_download_manager.dart';
import '../data/pack_repository.dart';
import '../domain/pack_entity.dart';

export '../domain/pack_entity.dart';

class PackProvider extends BaseProvider {
  PackProvider({
    required PackRepository packRepository,
    required PackSyncService packSyncService,
  }) : _repo = packRepository,
       _syncService = packSyncService {
    _hydrateAllDownloads();
  }

  final PackRepository _repo;
  final PackSyncService _syncService;
  final _downloader = PackDownloadManager.instance;

  List<PackEntity> _browsePacks = [];
  List<PackEntity> _featuredPacks = [];
  List<PackEntity> _promotedPacks = [];
  List<PackCategory> _categories = [];
  int _browsePage = 0;
  bool _hasMorePacks = true;
  bool _isLoadingMore = false;
  List<PackEntity> _purchasedPacks = [];
  List<PackEntity> _createdPacks = [];
  List<PackPurchase> _purchaseRecords = [];
  final _downloadStates = <String, PackDownloadState>{};
  StreamSubscription<MapEntry<String, PackDownloadState>>? _downloadSub;
  bool _isSyncing = false;

  List<PackEntity> _localPacks = [];

  // ── Search ──────────────────────────────────────────────────────────────
  List<PackEntity> _searchResults = [];
  String _searchQuery = '';
  int _searchPage = 0;
  bool _hasMoreSearchResults = true;
  bool _isSearching = false;
  bool _isLoadingMoreSearch = false;

  List<PackEntity> get searchResults => _searchResults;
  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;
  bool get isLoadingMoreSearch => _isLoadingMoreSearch;
  bool get hasMoreSearchResults => _hasMoreSearchResults;

  List<PackEntity> get browsePacks => _browsePacks;
  List<PackEntity> get featuredPacks => _featuredPacks;
  List<PackEntity> get localPacks => _localPacks;

  // The actual limit value comes from PlatformConfigProvider
  // (app_settings-backed, never hardcoded here) — callers pass it in
  // rather than this provider computing it, since PackProvider isn't wired
  // to PlatformConfigProvider. This is a local-storage limit (how many
  // packs are cached offline on this device) with no shared server
  // resource at stake, so it stays a client-side presentation limit.
  bool isAtDownloadLimit({required int limit}) => _localPacks.length >= limit;

  List<String> get allDownloadedPackIds => _downloadStates.entries
      .where((e) => e.value.isDownloaded)
      .map((e) => e.key)
      .toList();
  List<PackEntity> get promotedPacks => _promotedPacks;
  List<PackCategory> get categories => _categories;
  List<PackEntity> get purchasedPacks => _purchasedPacks;
  List<PackEntity> get createdPacks => _createdPacks;
  List<PackEntity> get allPacks => {
    ..._browsePacks,
    ..._purchasedPacks,
    ..._featuredPacks,
    ..._promotedPacks,
  }.toList();
  bool get hasMorePacks => _hasMorePacks;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSyncing => _isSyncing;

  PackDownloadState downloadStateFor(String packId) =>
      _downloadStates[packId] ?? PackDownloadState.initial(packId);

  bool hasActivePurchase(String packId) =>
      _purchasedPacks.any((p) => p.id == packId);

  bool isOwned(PackEntity pack) => pack.isFree || hasActivePurchase(pack.id);

  PackPurchase? purchaseFor(String packId) => _purchaseRecords
      .cast<PackPurchase?>()
      .firstWhere((r) => r?.packId == packId, orElse: () => null);

  @override
  void onUserLoggedIn(String userId) {
    _listenDownloads();
    _loadCategories();
    loadBrowsePacks(reset: true);
    _loadFeatured();
    _loadPurchased(userId);
    loadCreatedPacks();
    _syncPacks(userId);
    _hydrateAllDownloads();
  }

  Future<void> _hydrateAllDownloads() async {
    try {
      final ids = await _downloader.getDownloadedPackIds();
      for (final id in ids) {
        try {
          _downloadStates[id] = await _downloader.getDownloadState(id);
        } catch (_) {}
      }
      _localPacks = await _downloader.getDownloadedPacks();
      if (ids.isNotEmpty) notifyListeners();
    } catch (e) {
      AppLogger.warning('PackProvider: _hydrateAllDownloads failed: $e');
    }
  }

  @override
  void onAuthChanged(String? userId) {
    _hydrateAllDownloads();
    if (currentUserId != userId) {
      super.onAuthChanged(userId);
    }
  }

  @override
  void onUserLoggedOut() {
    _downloadSub?.cancel();
    _browsePacks = [];
    _featuredPacks = [];
    _promotedPacks = [];
    _searchResults = [];
    _searchQuery = '';
    _searchPage = 0;
    _hasMoreSearchResults = true;
    _purchasedPacks = [];
    _createdPacks = [];
    _purchaseRecords = [];
    _hydrateAllDownloads();
    super.onUserLoggedOut();
  }

  @override
  void dispose() {
    _downloadSub?.cancel();
    super.dispose();
  }

  Future<void> loadBrowsePacks({
    bool reset = false,
    String? gameType,
    String? categoryId,
    bool freeOnly = false,
    String? language,
    String sortBy = 'avg_rating',
  }) async {
    if (reset) {
      _browsePage = 0;
      _hasMorePacks = true;
      _browsePacks = [];
    }
    if (!_hasMorePacks) return;
    await runAsync(() async {
      const perPage = 20;
      final packs = await _repo.browsePacks(
        gameType: gameType,
        categoryId: categoryId,
        freeOnly: freeOnly,
        language: language,
        sortBy: sortBy,
        page: _browsePage,
        perPage: perPage,
      );
      _browsePacks = reset ? packs : [..._browsePacks, ...packs];
      _hasMorePacks = packs.length == perPage;
      _browsePage++;
      await _hydrateDownloadStates(packs.map((p) => p.id).toList());
    });
  }

  Future<void> loadMoreBrowsePacks({
    String? gameType,
    String? categoryId,
  }) async {
    if (_isLoadingMore || !_hasMorePacks) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      await loadBrowsePacks(gameType: gameType, categoryId: categoryId);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Searches by pack name, creator name, or category — see
  /// PackRepository.searchPacks. Reuses the same gameType/categoryId/
  /// freeOnly filter params the Browse tab already has, so a search
  /// happening under an active filter narrows within it rather than
  /// ignoring it. A dedicated _isSearching (not the base runAsync
  /// isLoading) so search and Browse-tab loading never stomp on each
  /// other's spinner state — same reason loadMoreBrowsePacks above has
  /// its own _isLoadingMore instead of reusing isLoading.
  Future<void> search(
    String query, {
    bool reset = true,
    String? gameType,
    String? categoryId,
    bool freeOnly = false,
  }) async {
    _searchQuery = query;
    if (reset) {
      _searchPage = 0;
      _hasMoreSearchResults = true;
      _searchResults = [];
    }
    // Same 2-character floor as FriendsProvider.search — short-circuits
    // before ever calling the repository, not just a display-layer gate,
    // so a 1-character query never fires a request (wasteful, and
    // plainto_tsquery would happily return a huge unfiltered match set).
    if (query.trim().length < 2) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }
    if (!_hasMoreSearchResults) return;

    _isSearching = true;
    notifyListeners();
    try {
      const perPage = 20;
      final results = await _repo.searchPacks(
        query: query,
        gameType: gameType,
        categoryId: categoryId,
        freeOnly: freeOnly,
        page: _searchPage,
        perPage: perPage,
      );
      _searchResults = reset ? results : [..._searchResults, ...results];
      _hasMoreSearchResults = results.length == perPage;
      _searchPage++;
      await _hydrateDownloadStates(results.map((p) => p.id).toList());
    } catch (e) {
      AppLogger.error('PackProvider: search failed', error: e);
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreSearchResults({
    String? gameType,
    String? categoryId,
    bool freeOnly = false,
  }) async {
    if (_isLoadingMoreSearch ||
        !_hasMoreSearchResults ||
        _searchQuery.trim().isEmpty) {
      return;
    }
    _isLoadingMoreSearch = true;
    notifyListeners();
    try {
      await search(
        _searchQuery,
        reset: false,
        gameType: gameType,
        categoryId: categoryId,
        freeOnly: freeOnly,
      );
    } finally {
      _isLoadingMoreSearch = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _searchPage = 0;
    _hasMoreSearchResults = true;
    notifyListeners();
  }

  Future<void> _loadFeatured() => runAsync(() async {
    _featuredPacks = await _repo.getFeaturedPacks();
    _promotedPacks = await _repo.getPromotedPacks();
  }, setLoading: false);

  Future<void> _loadCategories() => runAsync(() async {
    _categories = await _repo.getCategories();
  }, setLoading: false);

  Future<void> _loadPurchased(String userId) => runAsync(() async {
    _purchasedPacks = await _repo.getMyPurchasedPacks(userId);
    _purchaseRecords = await _repo.getMyPurchaseRecords(userId);
    await _hydrateDownloadStates(_purchasedPacks.map((p) => p.id).toList());
  }, setLoading: false);

  Future<void> loadCreatedPacks() async {
    if (currentUserId == null) return;
    await runAsync(() async {
      _createdPacks = await _repo.getMyCreatedPacks(currentUserId!);
    }, setLoading: false);
  }

  /// Client-side, best-effort mirror of the real server-side guarantee
  /// (idx_packs_one_draft_per_creator) — purely so the "+ New Pack" entry
  /// point can show a friendly blocking message immediately instead of
  /// always navigating in and failing on save. [createdPacks] can be
  /// stale (not yet refreshed after another device deleted/published a
  /// draft), so this is presentation-only: the database is still what
  /// actually prevents a second draft from ever being created.
  bool get hasDraftPack =>
      _createdPacks.any((p) => p.status == PackStatus.draft);

  Future<String?> purchasePack(PackEntity pack) async {
    try {
      await _repo.purchasePack(pack.id);
      if (currentUserId != null) {
        _purchasedPacks = await _repo.getMyPurchasedPacks(currentUserId!);
        _purchaseRecords = await _repo.getMyPurchaseRecords(currentUserId!);
        notifyListeners();
      }
      return null;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      return msg;
    }
  }

  /// [offlinePackLimit] comes from PlatformConfigProvider
  /// (app_settings-backed), never hardcoded here.
  Future<bool> downloadPack(
    PackEntity pack, {
    required bool isPremium,
    required int offlinePackLimit,
  }) async {
    if (!isOwned(pack)) return false;
    if (_localPacks.length >= offlinePackLimit) return false;
    await _downloader.download(pack);
    await _hydrateAllDownloads();
    return true;
  }

  Future<void> deletePack(String packId) async {
    await _downloader.deleteDownload(packId);
    _downloadStates[packId] = PackDownloadState.initial(packId);
    notifyListeners();
  }

  void _listenDownloads() {
    _downloadSub?.cancel();
    _downloadSub = _downloader.globalProgress.listen((entry) {
      _downloadStates[entry.key] = entry.value;
      notifyListeners();
    });
  }

  Future<void> _hydrateDownloadStates(List<String> packIds) async {
    for (final id in packIds) {
      if (!(_downloadStates[id]?.isDownloaded ?? false)) {
        _downloadStates[id] = await _downloader.getDownloadState(id);
      }
    }
    notifyListeners();
  }

  Future<bool> ratePack(String packId, int rating) async {
    if (currentUserId == null) return false;
    var success = false;
    await runAsync(() async {
      await _repo.ratePack(
        packId: packId,
        userId: currentUserId!,
        rating: rating,
      );
      success = true;
    }, setLoading: false);
    return success;
  }

  Future<bool> unratePack(String packId) async {
    if (currentUserId == null) return false;
    var success = false;
    await runAsync(() async {
      await _repo.unratePack(packId: packId, userId: currentUserId!);
      success = true;
    }, setLoading: false);
    return success;
  }

  Future<bool> submitReview({
    required String packId,
    required String content,
    int? rating,
  }) async {
    if (currentUserId == null) return false;
    var success = false;
    await runAsync(() async {
      await _repo.submitReview(
        packId: packId,
        userId: currentUserId!,
        content: content,
        rating: rating,
      );
      success = true;
    }, setLoading: false);
    return success;
  }

  Future<bool> reportPack({
    required String packId,
    required String reason,
    String? details,
  }) async {
    if (currentUserId == null) return false;
    var success = false;
    await runAsync(() async {
      await _repo.reportPack(
        packId: packId,
        reporterId: currentUserId!,
        reason: reason,
        details: details,
      );
      success = true;
    }, setLoading: false);
    return success;
  }

  Future<void> _syncPacks(String userId) async {
    _isSyncing = true;
    notifyListeners();
    await _syncService.sync(userId);
    _isSyncing = false;
    notifyListeners();
  }
}
