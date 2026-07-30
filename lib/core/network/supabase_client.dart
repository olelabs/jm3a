// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../utils/app_logger.dart';

// /// Wraps Supabase.initialize() with structured logging and error context.
// abstract final class SupabaseClientConfig {
//   static Future<void> initialize({
//     required String url,
//     required String anonKey,
//   }) async {
//     await Supabase.initialize(
//       url: url,
//       anonKey: anonKey,
//       debug: false, // Set to AppConfig.isDevelopment if verbose logs needed
//     );

//     AppLogger.info('Supabase initialized: $url');
//   }
// }

// /// Typed extension on SupabaseClient for cleaner access patterns.
// extension SupabaseExtensions on SupabaseClient {
//   /// Current user ID or throws if not authenticated.
//   String get requireUserId {
//     final id = auth.currentUser?.id;
//     if (id == null) throw Exception('User not authenticated');
//     return id;
//   }

//   /// Current user ID or null.
//   String? get currentUserId => auth.currentUser?.id;

//   /// Whether the current user is authenticated.
//   bool get isAuthenticated => auth.currentUser != null;
// }

import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_logger.dart';

abstract final class SupabaseClientConfig {
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: false,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
    );

    AppLogger.info('Supabase initialized: $url');
  }
}

extension SupabaseExtensions on SupabaseClient {
  String get requireUserId {
    final id = auth.currentUser?.id;
    if (id == null) throw Exception('User not authenticated');
    return id;
  }

  String? get currentUserId => auth.currentUser?.id;

  bool get isAuthenticated => auth.currentUser != null;
}
