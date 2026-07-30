// // // import 'dart:io';

// // // import 'package:jma3a/core/utils/app_logger.dart';
// // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // import '../config/app_config.dart';
// // // import '../network/supabase_client.dart';
// // // import '../network/api_client.dart';
// // // import '../storage/local_storage_service.dart';
// // // import '../storage/secure_storage_service.dart';
// // // import '../storage/database/app_database.dart';
// // // import '../services/connectivity_service.dart';
// // // import '../services/notification_service.dart';
// // // import '../services/image_cache_service.dart';
// // // import '../services/pack_sync_service.dart';
// // // import '../services/realtime_service.dart';
// // // import '../services/presence_service.dart';
// // // import '../../features/auth/data/auth_repository.dart';
// // // import '../../features/profile/data/profile_repository.dart';
// // // import '../../features/friends/data/friends_repository.dart';
// // // import '../../features/notifications/data/notification_repository.dart';
// // // import '../../features/wallet/data/wallet_repository.dart';
// // // import '../../features/packs/data/pack_repository.dart';
// // // import '../../features/rooms/data/room_repository.dart';
// // // import '../../features/rooms/data/room_cache_service.dart';

// // // class ServiceLocator {
// // //   ServiceLocator._();
// // //   static final ServiceLocator _instance = ServiceLocator._();
// // //   static ServiceLocator get instance => _instance;

// // //   // static Future<void> initialize() async {
// // //   //   AppConfig.validate();
// // //   //   await SupabaseClientConfig.initialize(
// // //   //     url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
// // //   //   await LocalStorageService.instance.initialize();
// // //   //   await AppDatabase.instance.open();
// // //   //   await RoomCacheService.instance.initialize();
// // //   //   await NotificationService.instance.initialize(appId: AppConfig.oneSignalAppId);
// // //   //   ApiClient.instance.initialize();
// // //   //   ImageCacheService.instance.configure();
// // //   // }

// // //   // service_locator.dart - remove the duplicate call
// // //   static Future<void> initialize() async {
// // //     AppConfig.validate();
// // //     await SupabaseClientConfig.initialize(
// // //       url: AppConfig.supabaseUrl,
// // //       anonKey: AppConfig.supabaseAnonKey,
// // //     );
// // //     await LocalStorageService.instance.initialize();
// // //     // REMOVE THIS LINE: await AppDatabase.instance.open();
// // //     await RoomCacheService.instance.initialize();
// // //     await NotificationService.instance.initialize(
// // //       appId: AppConfig.oneSignalAppId,
// // //     );
// // //     ApiClient.instance.initialize();

// // //     // Request storage permission if needed (Android)
// // //     if (Platform.isAndroid) {
// // //       AppLogger.info('Android device detected, checking storage...');
// // //     }

// // //     // Try to open database with error handling
// // //     try {
// // //       await AppDatabase.instance.open();
// // //     } catch (e) {
// // //       AppLogger.error(
// // //         'Database failed to open, continuing without local storage',
// // //         error: e,
// // //       );
// // //       // Don't rethrow - allow app to continue without offline storage
// // //     }

// // //     ImageCacheService.instance.configure();
// // //   }

// // //   ConnectivityService get connectivityService => ConnectivityService.instance;
// // //   LocalStorageService get localStorageService => LocalStorageService.instance;
// // //   SecureStorageService get secureStorageService =>
// // //       SecureStorageService.instance;
// // //   NotificationService get notificationService => NotificationService.instance;
// // //   ImageCacheService get imageCacheService => ImageCacheService.instance;
// // //   PackSyncService get packSyncService => PackSyncService.instance;
// // //   RealtimeService get realtimeService => RealtimeService.instance;
// // //   PresenceService get presenceService => PresenceService.instance;
// // //   RoomCacheService get roomCacheService => RoomCacheService.instance;
// // //   ApiClient get apiClient => ApiClient.instance;
// // //   SupabaseClient get supabase => Supabase.instance.client;

// // //   AuthRepository get authRepository => AuthRepository.instance;
// // //   ProfileRepository get profileRepository => ProfileRepository.instance;
// // //   FriendsRepository get friendsRepository => FriendsRepository.instance;
// // //   NotificationRepository get notificationRepository =>
// // //       NotificationRepository.instance;
// // //   WalletRepository get walletRepository => WalletRepository.instance;
// // //   PackRepository get packRepository => PackRepository.instance;
// // //   RoomRepository get roomRepository => RoomRepository.instance;
// // // }

// // // ServiceLocator get sl => ServiceLocator.instance;

// // import 'dart:io';

// // import 'package:jma3a/core/utils/app_logger.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart';
// // import '../config/app_config.dart';
// // import '../network/supabase_client.dart';
// // import '../network/api_client.dart';
// // import '../storage/local_storage_service.dart';
// // import '../storage/secure_storage_service.dart';
// // import '../storage/database/app_database.dart';
// // import '../services/connectivity_service.dart';
// // import '../services/notification_service.dart';
// // import '../services/image_cache_service.dart';
// // import '../services/pack_sync_service.dart';
// // import '../services/realtime_service.dart';
// // import '../services/presence_service.dart';
// // import '../../features/auth/data/auth_repository.dart';
// // import '../../features/profile/data/profile_repository.dart';
// // import '../../features/friends/data/friends_repository.dart';
// // import '../../features/notifications/data/notification_repository.dart';
// // import '../../features/wallet/data/wallet_repository.dart';
// // import '../../features/packs/data/pack_repository.dart';
// // import '../../features/rooms/data/room_repository.dart';
// // import '../../features/rooms/data/room_cache_service.dart';

// // class ServiceLocator {
// //   ServiceLocator._();
// //   static final ServiceLocator _instance = ServiceLocator._();
// //   static ServiceLocator get instance => _instance;

// //   static Future<void> initialize() async {
// //     AppConfig.validate();
// //     await SupabaseClientConfig.initialize(
// //       url: AppConfig.supabaseUrl,
// //       anonKey: AppConfig.supabaseAnonKey,
// //     );
// //     await LocalStorageService.instance.initialize();

// //     // CRITICAL: Open database BEFORE RoomCacheService
// //     // try {
// //     //   await AppDatabase.instance.open();
// //     //   AppLogger.info('Database opened successfully');
// //     // } catch (e) {
// //     //   AppLogger.error('Database failed to open', error: e);
// //     //   // Don't rethrow - continue with limited functionality
// //     // }

// //     // Now initialize services that depend on the database
// //     // await RoomCacheService.instance.initialize();
// //     await NotificationService.instance.initialize(
// //       appId: AppConfig.oneSignalAppId,
// //     );
// //     ApiClient.instance.initialize();

// //     // Request storage permission if needed (Android)
// //     if (Platform.isAndroid) {
// //       AppLogger.info('Android device detected, checking storage...');
// //     }

// //     ImageCacheService.instance.configure();
// //   }

// //   ConnectivityService get connectivityService => ConnectivityService.instance;
// //   LocalStorageService get localStorageService => LocalStorageService.instance;
// //   SecureStorageService get secureStorageService =>
// //       SecureStorageService.instance;
// //   NotificationService get notificationService => NotificationService.instance;
// //   ImageCacheService get imageCacheService => ImageCacheService.instance;
// //   PackSyncService get packSyncService => PackSyncService.instance;
// //   RealtimeService get realtimeService => RealtimeService.instance;
// //   PresenceService get presenceService => PresenceService.instance;
// //   RoomCacheService get roomCacheService => RoomCacheService.instance;
// //   ApiClient get apiClient => ApiClient.instance;
// //   SupabaseClient get supabase => Supabase.instance.client;

// //   AuthRepository get authRepository => AuthRepository.instance;
// //   ProfileRepository get profileRepository => ProfileRepository.instance;
// //   FriendsRepository get friendsRepository => FriendsRepository.instance;
// //   NotificationRepository get notificationRepository =>
// //       NotificationRepository.instance;
// //   WalletRepository get walletRepository => WalletRepository.instance;
// //   PackRepository get packRepository => PackRepository.instance;
// //   RoomRepository get roomRepository => RoomRepository.instance;
// // }

// // ServiceLocator get sl => ServiceLocator.instance;

// // lib/core/di/service_locator.dart
// import 'dart:io';

// import 'package:jma3a/core/utils/app_logger.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../config/app_config.dart';
// import '../network/supabase_client.dart';
// import '../network/api_client.dart';
// import '../storage/local_storage_service.dart';
// import '../storage/secure_storage_service.dart';
// import '../storage/database/app_database.dart';
// import '../services/connectivity_service.dart';
// import '../services/notification_service.dart';
// import '../services/image_cache_service.dart';
// import '../services/pack_sync_service.dart';
// import '../services/realtime_service.dart';
// import '../services/presence_service.dart';
// import '../../features/auth/data/auth_repository.dart';
// import '../../features/profile/data/profile_repository.dart';
// import '../../features/friends/data/friends_repository.dart';
// import '../../features/notifications/data/notification_repository.dart';
// import '../../features/wallet/data/wallet_repository.dart';
// import '../../features/packs/data/pack_repository.dart';
// import '../../features/rooms/data/room_repository.dart';
// import '../../features/rooms/data/room_cache_service.dart';

// class ServiceLocator {
//   ServiceLocator._();
//   static final ServiceLocator _instance = ServiceLocator._();
//   static ServiceLocator get instance => _instance;

//   // static Future<void> initialize() async {
//   //   // AppConfig.();
//   //   AppConfig.validate();

//   //   await SupabaseClientConfig.initialize(
//   //     url: AppConfig.supabaseUrl,
//   //     anonKey: AppConfig.supabaseAnonKey,
//   //   );
//   //   await LocalStorageService.instance.initialize();

//   //   // DATABASE COMPLETELY DISABLED - COMMENT EVERYTHING
//   //   // await AppDatabase.instance.open();
//   //   // await RoomCacheService.instance.initialize();

//   //   await NotificationService.instance.initialize(
//   //     appId: AppConfig.oneSignalAppId,
//   //   );
//   //   ApiClient.instance.initialize();

//   //   if (Platform.isAndroid) {
//   //     AppLogger.info('Android device detected, checking storage...');
//   //   }

//   //   ImageCacheService.instance.configure();
//   // }
//   static Future<void> initialize() async {
//     // AppConfig.validate();

//     // await SupabaseClientConfig.initialize(
//     //   url: AppConfig.supabaseUrl,
//     //   anonKey: AppConfig.supabaseAnonKey,
//     // );
//     // await LocalStorageService.instance.initialize();

//     // // 1. Open database FIRST
//     // // await AppDatabase.instance.open();

//     // // 2. Initialize services that depend on database
//     // // await RoomCacheService.instance.initialize();
//     // await PackSyncService.instance.initialize(); // Add this line
//     AppLogger.info('ServiceLocator: starting');
//     AppConfig.validate();

//     await SupabaseClientConfig.initialize(
//       url: AppConfig.supabaseUrl,
//       anonKey: AppConfig.supabaseAnonKey,
//     );
//     AppLogger.info('Supabase ready');

//     await LocalStorageService.instance.initialize();
//     AppLogger.info('LocalStorage ready');

//     // --- DATABASE ---
//     try {
//       AppLogger.info('Opening AppDatabase...');
//       await AppDatabase.instance.open();
//       AppLogger.info('AppDatabase opened');
//     } catch (e, st) {
//       AppLogger.error('AppDatabase open failed', error: e, stackTrace: st);
//       rethrow;
//     }

//     // --- DB‑dependent services ---
//     try {
//       AppLogger.info('Initializing RoomCacheService...');
//       await RoomCacheService.instance.initialize();
//       AppLogger.info('RoomCacheService done');

//       AppLogger.info('Initializing PackSyncService...');
//       await PackSyncService.instance.initialize();
//       AppLogger.info('PackSyncService done');
//     } catch (e, st) {
//       AppLogger.error('DB service init failed', error: e, stackTrace: st);
//       rethrow;
//     }

//     await NotificationService.instance.initialize(
//       appId: AppConfig.oneSignalAppId,
//     );
//     ApiClient.instance.initialize();

//     if (Platform.isAndroid) {
//       AppLogger.info('Android device detected, checking storage...');
//     }

//     ImageCacheService.instance.configure();
//   }

//   ConnectivityService get connectivityService => ConnectivityService.instance;
//   LocalStorageService get localStorageService => LocalStorageService.instance;
//   SecureStorageService get secureStorageService =>
//       SecureStorageService.instance;
//   NotificationService get notificationService => NotificationService.instance;
//   ImageCacheService get imageCacheService => ImageCacheService.instance;
//   PackSyncService get packSyncService => PackSyncService.instance;
//   RealtimeService get realtimeService => RealtimeService.instance;
//   PresenceService get presenceService => PresenceService.instance;
//   RoomCacheService get roomCacheService => RoomCacheService.instance;
//   ApiClient get apiClient => ApiClient.instance;
//   SupabaseClient get supabase => Supabase.instance.client;

//   AuthRepository get authRepository => AuthRepository.instance;
//   ProfileRepository get profileRepository => ProfileRepository.instance;
//   FriendsRepository get friendsRepository => FriendsRepository.instance;
//   NotificationRepository get notificationRepository =>
//       NotificationRepository.instance;
//   WalletRepository get walletRepository => WalletRepository.instance;
//   PackRepository get packRepository => PackRepository.instance;
//   RoomRepository get roomRepository => RoomRepository.instance;
// }

// ServiceLocator get sl => ServiceLocator.instance;

// lib/core/di/service_locator.dart
import 'dart:io';

import 'package:jma3a/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../network/supabase_client.dart';
import '../network/api_client.dart';
import '../storage/local_storage_service.dart';
import '../storage/secure_storage_service.dart';
import '../storage/database/app_database.dart';
import '../services/connectivity_service.dart';
import '../services/notification_service.dart';
import '../services/local_notification_service.dart';
import '../services/image_cache_service.dart';
import '../services/pack_sync_service.dart';
import '../services/realtime_service.dart';
import '../services/presence_service.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/friends/data/friends_repository.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../features/wallet/data/wallet_repository.dart';
import '../../features/packs/data/pack_repository.dart';
import '../../features/rooms/data/room_repository.dart';
import '../../features/rooms/data/room_cache_service.dart';

class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator _instance = ServiceLocator._();
  static ServiceLocator get instance => _instance;

  // static Future<void> initialize() async {
  //   // AppConfig.();
  //   AppConfig.validate();

  //   await SupabaseClientConfig.initialize(
  //     url: AppConfig.supabaseUrl,
  //     anonKey: AppConfig.supabaseAnonKey,
  //   );
  //   await LocalStorageService.instance.initialize();

  //   // DATABASE COMPLETELY DISABLED - COMMENT EVERYTHING
  //   // await AppDatabase.instance.open();
  //   // await RoomCacheService.instance.initialize();

  //   await NotificationService.instance.initialize(
  //     appId: AppConfig.oneSignalAppId,
  //   );
  //   ApiClient.instance.initialize();

  //   if (Platform.isAndroid) {
  //     AppLogger.info('Android device detected, checking storage...');
  //   }

  //   ImageCacheService.instance.configure();
  // }
  static Future<void> initialize() async {
    // AppConfig.validate();

    // await SupabaseClientConfig.initialize(
    //   url: AppConfig.supabaseUrl,
    //   anonKey: AppConfig.supabaseAnonKey,
    // );
    // await LocalStorageService.instance.initialize();

    // // 1. Open database FIRST
    // // await AppDatabase.instance.open();

    // // 2. Initialize services that depend on database
    // // await RoomCacheService.instance.initialize();
    // await PackSyncService.instance.initialize(); // Add this line
    AppLogger.info('ServiceLocator: starting');
    AppConfig.validate();

    await SupabaseClientConfig.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    AppLogger.info('Supabase ready');

    await LocalStorageService.instance.initialize();
    AppLogger.info('LocalStorage ready');

    // --- DATABASE ---
    try {
      AppLogger.info('Opening AppDatabase...');
      await AppDatabase.instance.open();
      AppLogger.info('AppDatabase opened');
    } catch (e, st) {
      AppLogger.error('AppDatabase open failed', error: e, stackTrace: st);
      rethrow;
    }

    // --- DB‑dependent services ---
    try {
      AppLogger.info('Initializing RoomCacheService...');
      await RoomCacheService.instance.initialize();
      AppLogger.info('RoomCacheService done');

      AppLogger.info('Initializing PackSyncService...');
      await PackSyncService.instance.initialize();
      AppLogger.info('PackSyncService done');
    } catch (e, st) {
      AppLogger.error('DB service init failed', error: e, stackTrace: st);
      rethrow;
    }

    await NotificationService.instance.initialize(
      appId: AppConfig.oneSignalAppId,
    );
    ApiClient.instance.initialize();

    if (Platform.isAndroid) {
      AppLogger.info('Android device detected, checking storage...');
    }

    ImageCacheService.instance.configure();
  }

  ConnectivityService get connectivityService => ConnectivityService.instance;
  LocalStorageService get localStorageService => LocalStorageService.instance;
  SecureStorageService get secureStorageService =>
      SecureStorageService.instance;
  NotificationService get notificationService => NotificationService.instance;
  LocalNotificationService get localNotificationService =>
      LocalNotificationService.instance;
  ImageCacheService get imageCacheService => ImageCacheService.instance;
  PackSyncService get packSyncService => PackSyncService.instance;
  RealtimeService get realtimeService => RealtimeService.instance;
  PresenceService get presenceService => PresenceService.instance;
  RoomCacheService get roomCacheService => RoomCacheService.instance;
  ApiClient get apiClient => ApiClient.instance;
  SupabaseClient get supabase => Supabase.instance.client;

  AuthRepository get authRepository => AuthRepository.instance;
  ProfileRepository get profileRepository => ProfileRepository.instance;
  FriendsRepository get friendsRepository => FriendsRepository.instance;
  NotificationRepository get notificationRepository =>
      NotificationRepository.instance;
  WalletRepository get walletRepository => WalletRepository.instance;
  PackRepository get packRepository => PackRepository.instance;
  RoomRepository get roomRepository => RoomRepository.instance;
}

ServiceLocator get sl => ServiceLocator.instance;
