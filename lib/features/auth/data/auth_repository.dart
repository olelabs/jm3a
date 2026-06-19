// // // import 'dart:async';

// // // import 'package:supabase_flutter/supabase_flutter.dart';

// // // import '../../../core/data/base_repository.dart';
// // // import '../../../core/errors/failures.dart';
// // // import '../../../core/network/api_client.dart';
// // // import '../../../core/storage/local_storage_service.dart';
// // // import '../../../core/storage/secure_storage_service.dart';
// // // import '../../../core/utils/app_logger.dart';
// // // import '../domain/entities/user_entity.dart';

// // // /// Authentication repository.
// // // ///
// // // /// Routing:
// // // ///  - OTP send/verify      → Node.js API (owns OTP logic + Resend)
// // // ///  - Session management   → Supabase Flutter SDK (handles token refresh)
// // // ///  - Profile fetch/create → Supabase direct (RLS-protected reads)
// // // ///
// // // /// Token lifecycle:
// // // ///  - Supabase SDK stores tokens in flutter_secure_storage automatically.
// // // ///  - We additionally persist pendingOtpEmail in secure storage for
// // // ///    crash-recovery (user killed app mid-OTP flow).
// // // class AuthRepository extends BaseRepository {
// // //   AuthRepository._();
// // //   static final AuthRepository _instance = AuthRepository._();
// // //   static AuthRepository get instance => _instance;

// // //   final _supabase = Supabase.instance.client;
// // //   final _api = ApiClient.instance;
// // //   final _secure = SecureStorageService.instance;
// // //   final _local = LocalStorageService.instance;

// // //   // ── Auth state stream ───────────────────────────────────────────────────
// // //   /// Emits whenever Supabase auth state changes: sign-in, sign-out, token refresh.
// // //   Stream<AuthStateChangeEvent> get authStateStream => _supabase
// // //       .auth
// // //       .onAuthStateChange
// // //       .map((e) => AuthStateChangeEvent(session: e.session, event: e.event));

// // //   // ── Session restore ─────────────────────────────────────────────────────
// // //   /// Called once at app startup.
// // //   /// Supabase SDK auto-refreshes the token if it's still valid.
// // //   /// Returns (null, null) if no session exists.
// // //   // Future<(Session?, UserEntity?)> restoreSession() async {
// // //   //   final session = _supabase.auth.currentSession;
// // //   //   if (session == null) return (null, null);

// // //   //   // Verify token is still valid (SDK may have a cached expired session)
// // //   //   if (session.isExpired) {
// // //   //     try {
// // //   //       final refreshed = await _supabase.auth.refreshSession();
// // //   //       if (refreshed.session == null) return (null, null);
// // //   //       final user = await _fetchCurrentProfile(refreshed.session!.user.id);
// // //   //       AppLogger.info('AuthRepository: session restored via refresh');
// // //   //       return (refreshed.session, user);
// // //   //     } catch (e) {
// // //   //       AppLogger.warning('AuthRepository: token refresh failed, $e');
// // //   //       return (null, null);
// // //   //     }
// // //   //   }

// // //   //   final user = await _fetchCurrentProfile(session.user.id);
// // //   //   AppLogger.info('AuthRepository: session restored');
// // //   //   return (session, user);
// // //   // }
// // //   // In AuthRepository.dart
// // //   Future<(Session?, UserEntity?)> restoreSession() async {
// // //     try {
// // //       final session = _supabase.auth.currentSession;
// // //       if (session == null) return (null, null);

// // //       // Add timeout to prevent hanging
// // //       final user = await _fetchCurrentProfile(
// // //         session.user.id,
// // //       ).timeout(const Duration(seconds: 5), onTimeout: () => null);
// // //       return (session, user);
// // //     } catch (e) {
// // //       AppLogger.warning('Restore session failed: $e');
// // //       return (null, null);
// // //     }
// // //   }

// // //   // ── Pending OTP email persistence ────────────────────────────────────────
// // //   Future<void> savePendingOtpEmail(String email) =>
// // //       _secure.write(SecureKeys.pendingOtpEmail, email);

// // //   Future<String?> getPendingOtpEmail() =>
// // //       _secure.read(SecureKeys.pendingOtpEmail);

// // //   Future<void> clearPendingOtpEmail() =>
// // //       _secure.delete(SecureKeys.pendingOtpEmail);

// // //   // ── OTP send ─────────────────────────────────────────────────────────────
// // //   Future<void> sendOtp(String email) => guardedCall(
// // //     operationName: 'sendOtp',
// // //     operation: () async {
// // //       await _api.post('/v1/auth/send-otp', data: {'email': email});
// // //       // Persist email in case user kills app before verifying
// // //       await savePendingOtpEmail(email);
// // //       AppLogger.info('OTP sent to $email');
// // //     },
// // //   );

// // //   // ── OTP verify ────────────────────────────────────────────────────────────
// // //   Future<(Session, UserEntity)> verifyOtp(String email, String otp) =>
// // //       guardedCall(
// // //         operationName: 'verifyOtp',
// // //         operation: () async {
// // //           final response = await _api.post<Map<String, dynamic>>(
// // //             '/v1/auth/verify-otp',
// // //             data: {'email': email, 'otp': otp},
// // //           );

// // //           final data = response.data!['data'] as Map<String, dynamic>;
// // //           final accessToken = data['access_token'] as String;
// // //           final refreshToken = data['refresh_token'] as String? ?? '';
// // //           final isNewUser = data['is_new_user'] as bool? ?? false;

// // //           // Exchange Node.js tokens with Supabase SDK
// // //           final authResponse = await _supabase.auth.setSession(accessToken);

// // //           // Fallback: if setSession fails, try refreshing
// // //           Session? session = authResponse.session;
// // //           if (session == null && refreshToken.isNotEmpty) {
// // //             final refreshed = await _supabase.auth.refreshSession();
// // //             session = refreshed.session;
// // //           }

// // //           if (session == null) {
// // //             throw const AuthFailure(message: 'Failed to establish session.');
// // //           }

// // //           await clearPendingOtpEmail();

// // //           UserEntity user;
// // //           if (isNewUser) {
// // //             user = _minimalUserEntity(session.user, email);
// // //           } else {
// // //             user =
// // //                 await _fetchCurrentProfile(session.user.id) ??
// // //                 _minimalUserEntity(session.user, email);
// // //           }

// // //           AppLogger.info('OTP verified, session created. isNewUser=$isNewUser');
// // //           return (session, user);
// // //         },
// // //       );

// // //   // ── Sign out ──────────────────────────────────────────────────────────────
// // //   Future<void> signOut() async {
// // //     try {
// // //       // Notify Node.js to update online status
// // //       await _api.post('/v1/auth/sign-out', data: {});
// // //     } catch (e) {
// // //       // Best-effort — always continue with local sign-out
// // //       AppLogger.warning('AuthRepository: sign-out API call failed, $e');
// // //     }

// // //     await _supabase.auth.signOut();
// // //     await _secure.deleteAll();
// // //     AppLogger.info('User signed out');
// // //   }

// // //   // ── Profile fetch ─────────────────────────────────────────────────────────
// // //   Future<UserEntity?> _fetchCurrentProfile(String userId) async {
// // //     try {
// // //       final row = await _supabase
// // //           .from('profiles')
// // //           .select()
// // //           .eq('id', userId)
// // //           .maybeSingle();

// // //       if (row == null) return null;
// // //       return _profileRowToEntity(row);
// // //     } catch (e) {
// // //       AppLogger.warning('AuthRepository: profile fetch failed, $e');
// // //       return null;
// // //     }
// // //   }

// // //   // ── Mappers ───────────────────────────────────────────────────────────────
// // //   UserEntity _minimalUserEntity(User user, String email) {
// // //     return UserEntity(id: user.id, email: user.email ?? email);
// // //   }

// // //   UserEntity _profileRowToEntity(Map<String, dynamic> row) {
// // //     return UserEntity(
// // //       id: row['id'] as String,
// // //       email: row['email'] as String? ?? '',
// // //       username: row['username'] as String?,
// // //       displayName: row['display_name'] as String?,
// // //       avatarUrl: row['avatar_url'] as String?,
// // //       bio: row['bio'] as String?,
// // //       countryCode: row['country_code'] as String?,
// // //       age: row['age'] as int?,
// // //       phoneNumber: row['phone_number'] as String?,
// // //       preferredLanguage: row['preferred_lang'] as String? ?? 'en',
// // //       verificationStatus: row['verification_status'] as String? ?? 'unverified',
// // //       onlineStatus: row['online_status'] as String? ?? 'offline',
// // //       inGameStatus: row['in_game_status'] as bool? ?? false,
// // //       isBanned: row['is_banned'] as bool? ?? false,
// // //       usernameChangedAt: row['username_changed_at'] != null
// // //           ? DateTime.parse(row['username_changed_at'] as String)
// // //           : null,
// // //       lastSeenAt: row['last_seen_at'] != null
// // //           ? DateTime.parse(row['last_seen_at'] as String)
// // //           : null,
// // //       createdAt: row['created_at'] != null
// // //           ? DateTime.parse(row['created_at'] as String)
// // //           : null,
// // //       updatedAt: row['updated_at'] != null
// // //           ? DateTime.parse(row['updated_at'] as String)
// // //           : null,
// // //     );
// // //   }
// // // }

// // // /// Wrapper for Supabase auth state change events.
// // // class AuthStateChangeEvent {
// // //   const AuthStateChangeEvent({required this.session, required this.event});
// // //   final Session? session;
// // //   final AuthChangeEvent event;
// // // }

// // import 'dart:async';

// // import 'package:supabase_flutter/supabase_flutter.dart';

// // import '../../../core/data/base_repository.dart';
// // import '../../../core/errors/failures.dart';
// // import '../../../core/network/api_client.dart';
// // import '../../../core/storage/local_storage_service.dart';
// // import '../../../core/storage/secure_storage_service.dart';
// // import '../../../core/utils/app_logger.dart';
// // import '../domain/entities/user_entity.dart';

// // /// Authentication repository.
// // ///
// // /// Routing:
// // ///  - OTP send/verify      → Node.js API (owns OTP logic + Resend)
// // ///  - Session management   → Supabase Flutter SDK (handles token refresh)
// // ///  - Profile fetch/create → Supabase direct (RLS-protected reads)
// // ///
// // /// Token lifecycle:
// // ///  - Supabase SDK stores tokens in flutter_secure_storage automatically.
// // ///  - We additionally persist pendingOtpEmail in secure storage for
// // ///    crash-recovery (user killed app mid-OTP flow).
// // class AuthRepository extends BaseRepository {
// //   AuthRepository._();
// //   static final AuthRepository _instance = AuthRepository._();
// //   static AuthRepository get instance => _instance;

// //   final _supabase = Supabase.instance.client;
// //   final _api = ApiClient.instance;
// //   final _secure = SecureStorageService.instance;
// //   final _local = LocalStorageService.instance;

// //   // ── Auth state stream ───────────────────────────────────────────────────
// //   /// Emits whenever Supabase auth state changes: sign-in, sign-out, token refresh.
// //   Stream<AuthStateChangeEvent> get authStateStream => _supabase
// //       .auth
// //       .onAuthStateChange
// //       .map((e) => AuthStateChangeEvent(session: e.session, event: e.event));

// //   // ── Session restore ─────────────────────────────────────────────────────
// //   /// Called once at app startup.
// //   /// Supabase SDK auto-refreshes the token if it's still valid.
// //   /// Returns (null, null) if no session exists.
// //   Future<(Session?, UserEntity?)> restoreSession() async {
// //     final session = _supabase.auth.currentSession;
// //     if (session == null) return (null, null);

// //     // Verify token is still valid (SDK may have a cached expired session)
// //     if (session.isExpired) {
// //       try {
// //         final refreshed = await _supabase.auth.refreshSession();
// //         if (refreshed.session == null) return (null, null);
// //         final user = await _fetchCurrentProfile(refreshed.session!.user.id);
// //         AppLogger.info('AuthRepository: session restored via refresh');
// //         return (refreshed.session, user);
// //       } catch (e) {
// //         AppLogger.warning('AuthRepository: token refresh failed, $e');
// //         return (null, null);
// //       }
// //     }

// //     final user = await _fetchCurrentProfile(session.user.id);
// //     AppLogger.info('AuthRepository: session restored');
// //     return (session, user);
// //   }

// //   // ── Pending OTP email persistence ────────────────────────────────────────
// //   Future<void> savePendingOtpEmail(String email) =>
// //       _secure.write(SecureKeys.pendingOtpEmail, email);

// //   Future<String?> getPendingOtpEmail() =>
// //       _secure.read(SecureKeys.pendingOtpEmail);

// //   Future<void> clearPendingOtpEmail() =>
// //       _secure.delete(SecureKeys.pendingOtpEmail);

// //   // ── OTP send ─────────────────────────────────────────────────────────────
// //   Future<void> sendOtp(String email) => guardedCall(
// //     operationName: 'sendOtp',
// //     operation: () async {
// //       await _api.post('/v1/auth/send-otp', data: {'email': email});
// //       // Persist email in case user kills app before verifying
// //       await savePendingOtpEmail(email);
// //       AppLogger.info('OTP sent to $email');
// //     },
// //   );

// //   // ── OTP verify ────────────────────────────────────────────────────────────
// //   Future<(Session, UserEntity)> verifyOtp(String email, String otp) =>
// //       guardedCall(
// //         operationName: 'verifyOtp',
// //         operation: () async {
// //           final response = await _api.post<Map<String, dynamic>>(
// //             '/v1/auth/verify-otp',
// //             data: {'email': email, 'otp': otp},
// //           );

// //           final data = response.data!['data'] as Map<String, dynamic>;
// //           final hashedToken = data['hashed_token'] as String? ?? '';
// //           final isNewUser = data['is_new_user'] as bool? ?? false;

// //           if (hashedToken.isEmpty) {
// //             throw const AuthFailure(
// //               message: 'No session token received from server.',
// //             );
// //           }

// //           // Exchange the hashed_token for a real Supabase session.
// //           // generateLink(magiclink) produces a hashed_token; the correct
// //           // client-side exchange is verifyOtp with type=magiclink.
// //           final authResponse = await _supabase.auth.verifyOTP(
// //             email: email,
// //             token: hashedToken,
// //             type: OtpType.magiclink,
// //           );

// //           final session = authResponse.session;
// //           if (session == null) {
// //             throw const AuthFailure(message: 'Failed to establish session.');
// //           }

// //           await clearPendingOtpEmail();

// //           UserEntity user;
// //           if (isNewUser) {
// //             user = _minimalUserEntity(session.user, email);
// //           } else {
// //             user =
// //                 await _fetchCurrentProfile(session.user.id) ??
// //                 _minimalUserEntity(session.user, email);
// //           }

// //           AppLogger.info('OTP verified, session created. isNewUser=$isNewUser');
// //           return (session, user);
// //         },
// //       );

// //   // ── Sign out ──────────────────────────────────────────────────────────────
// //   Future<void> signOut() async {
// //     try {
// //       // Notify Node.js to update online status
// //       await _api.post('/v1/auth/sign-out', data: {});
// //     } catch (e) {
// //       // Best-effort — always continue with local sign-out
// //       AppLogger.warning('AuthRepository: sign-out API call failed, $e');
// //     }

// //     await _supabase.auth.signOut();
// //     await _secure.deleteAll();
// //     AppLogger.info('User signed out');
// //   }

// //   // ── Profile fetch ─────────────────────────────────────────────────────────
// //   Future<UserEntity?> _fetchCurrentProfile(String userId) async {
// //     try {
// //       final row = await _supabase
// //           .from('profiles')
// //           .select()
// //           .eq('id', userId)
// //           .maybeSingle();

// //       if (row == null) return null;
// //       return _profileRowToEntity(row);
// //     } catch (e) {
// //       AppLogger.warning('AuthRepository: profile fetch failed, $e');
// //       return null;
// //     }
// //   }

// //   // ── Mappers ───────────────────────────────────────────────────────────────
// //   UserEntity _minimalUserEntity(User user, String email) {
// //     return UserEntity(id: user.id, email: user.email ?? email);
// //   }

// //   UserEntity _profileRowToEntity(Map<String, dynamic> row) {
// //     return UserEntity(
// //       id: row['id'] as String,
// //       email: row['email'] as String? ?? '',
// //       username: row['username'] as String?,
// //       displayName: row['display_name'] as String?,
// //       avatarUrl: row['avatar_url'] as String?,
// //       bio: row['bio'] as String?,
// //       countryCode: row['country_code'] as String?,
// //       age: row['age'] as int?,
// //       phoneNumber: row['phone_number'] as String?,
// //       preferredLanguage: row['preferred_lang'] as String? ?? 'en',
// //       verificationStatus: row['verification_status'] as String? ?? 'unverified',
// //       onlineStatus: row['online_status'] as String? ?? 'offline',
// //       inGameStatus: row['in_game_status'] as bool? ?? false,
// //       isBanned: row['is_banned'] as bool? ?? false,
// //       usernameChangedAt: row['username_changed_at'] != null
// //           ? DateTime.parse(row['username_changed_at'] as String)
// //           : null,
// //       lastSeenAt: row['last_seen_at'] != null
// //           ? DateTime.parse(row['last_seen_at'] as String)
// //           : null,
// //       createdAt: row['created_at'] != null
// //           ? DateTime.parse(row['created_at'] as String)
// //           : null,
// //       updatedAt: row['updated_at'] != null
// //           ? DateTime.parse(row['updated_at'] as String)
// //           : null,
// //     );
// //   }
// // }

// // /// Wrapper for Supabase auth state change events.
// // class AuthStateChangeEvent {
// //   const AuthStateChangeEvent({required this.session, required this.event});
// //   final Session? session;
// //   final AuthChangeEvent event;
// // }

// import 'dart:async';

// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../../../core/data/base_repository.dart';
// import '../../../core/errors/failures.dart';
// import '../../../core/network/api_client.dart';
// import '../../../core/storage/local_storage_service.dart';
// import '../../../core/storage/secure_storage_service.dart';
// import '../../../core/utils/app_logger.dart';
// import '../domain/entities/user_entity.dart';

// /// Authentication repository.
// ///
// /// Routing:
// ///  - OTP send/verify      → Node.js API (owns OTP logic + Resend)
// ///  - Session management   → Supabase Flutter SDK (handles token refresh)
// ///  - Profile fetch/create → Supabase direct (RLS-protected reads)
// ///
// /// Token lifecycle:
// ///  - Supabase SDK stores tokens in flutter_secure_storage automatically.
// ///  - We additionally persist pendingOtpEmail in secure storage for
// ///    crash-recovery (user killed app mid-OTP flow).
// class AuthRepository extends BaseRepository {
//   AuthRepository._();
//   static final AuthRepository _instance = AuthRepository._();
//   static AuthRepository get instance => _instance;

//   final _supabase = Supabase.instance.client;
//   final _api = ApiClient.instance;
//   final _secure = SecureStorageService.instance;
//   final _local = LocalStorageService.instance;

//   // ── Auth state stream ───────────────────────────────────────────────────
//   /// Emits whenever Supabase auth state changes: sign-in, sign-out, token refresh.
//   Stream<AuthStateChangeEvent> get authStateStream => _supabase
//       .auth
//       .onAuthStateChange
//       .map((e) => AuthStateChangeEvent(session: e.session, event: e.event));

//   // ── Session restore ─────────────────────────────────────────────────────
//   /// Called once at app startup.
//   /// Supabase SDK auto-refreshes the token if it's still valid.
//   /// Returns (null, null) if no session exists.
//   Future<(Session?, UserEntity?)> restoreSession() async {
//     final session = _supabase.auth.currentSession;
//     if (session == null) return (null, null);

//     // Verify token is still valid (SDK may have a cached expired session)
//     if (session.isExpired) {
//       try {
//         final refreshed = await _supabase.auth.refreshSession();
//         if (refreshed.session == null) return (null, null);
//         final user = await _fetchCurrentProfile(refreshed.session!.user.id);
//         AppLogger.info('AuthRepository: session restored via refresh');
//         return (refreshed.session, user);
//       } catch (e) {
//         AppLogger.warning('AuthRepository: token refresh failed, $e');
//         return (null, null);
//       }
//     }

//     final user = await _fetchCurrentProfile(session.user.id);
//     AppLogger.info('AuthRepository: session restored');
//     return (session, user);
//   }

//   // ── Pending OTP email persistence ────────────────────────────────────────
//   Future<void> savePendingOtpEmail(String email) =>
//       _secure.write(SecureKeys.pendingOtpEmail, email);

//   Future<String?> getPendingOtpEmail() =>
//       _secure.read(SecureKeys.pendingOtpEmail);

//   Future<void> clearPendingOtpEmail() =>
//       _secure.delete(SecureKeys.pendingOtpEmail);

//   // ── OTP send ─────────────────────────────────────────────────────────────
//   Future<void> sendOtp(String email) => guardedCall(
//     operationName: 'sendOtp',
//     operation: () async {
//       await _api.post('/v1/auth/send-otp', data: {'email': email});
//       // Persist email in case user kills app before verifying
//       await savePendingOtpEmail(email);
//       AppLogger.info('OTP sent to $email');
//     },
//   );

//   // ── OTP verify ────────────────────────────────────────────────────────────
//   Future<(Session, UserEntity)> verifyOtp(String email, String otp) =>
//       guardedCall(
//         operationName: 'verifyOtp',
//         operation: () async {
//           final response = await _api.post<Map<String, dynamic>>(
//             '/v1/auth/verify-otp',
//             data: {'email': email, 'otp': otp},
//           );

//           final data = response.data!['data'] as Map<String, dynamic>;
//           final accessToken = data['access_token'] as String? ?? '';
//           final refreshToken = data['refresh_token'] as String? ?? '';
//           final isNewUser = data['is_new_user'] as bool? ?? false;

//           if (accessToken.isEmpty || refreshToken.isEmpty) {
//             throw const AuthFailure(
//               message: 'No session token received from server.',
//             );
//           }

//           // Server returned real JWT tokens — set session directly
//           final authResponse = await _supabase.auth.setSession(accessToken);

//           final session = authResponse.session;
//           if (session == null) {
//             throw const AuthFailure(message: 'Failed to establish session.');
//           }

//           await clearPendingOtpEmail();

//           UserEntity user;
//           if (isNewUser) {
//             user = _minimalUserEntity(session.user, email);
//           } else {
//             user =
//                 await _fetchCurrentProfile(session.user.id) ??
//                 _minimalUserEntity(session.user, email);
//           }

//           AppLogger.info('OTP verified, session created. isNewUser=$isNewUser');
//           return (session, user);
//         },
//       );

//   // ── Sign out ──────────────────────────────────────────────────────────────
//   Future<void> signOut() async {
//     try {
//       // Notify Node.js to update online status
//       await _api.post('/v1/auth/sign-out', data: {});
//     } catch (e) {
//       // Best-effort — always continue with local sign-out
//       AppLogger.warning('AuthRepository: sign-out API call failed, $e');
//     }

//     await _supabase.auth.signOut();
//     await _secure.deleteAll();
//     AppLogger.info('User signed out');
//   }

//   // ── Profile fetch ─────────────────────────────────────────────────────────
//   Future<UserEntity?> _fetchCurrentProfile(String userId) async {
//     try {
//       final row = await _supabase
//           .from('profiles')
//           .select()
//           .eq('id', userId)
//           .maybeSingle();

//       if (row == null) return null;
//       return _profileRowToEntity(row);
//     } catch (e) {
//       AppLogger.warning('AuthRepository: profile fetch failed, $e');
//       return null;
//     }
//   }

//   // ── Mappers ───────────────────────────────────────────────────────────────
//   UserEntity _minimalUserEntity(User user, String email) {
//     return UserEntity(id: user.id, email: user.email ?? email);
//   }

//   UserEntity _profileRowToEntity(Map<String, dynamic> row) {
//     return UserEntity(
//       id: row['id'] as String,
//       email: row['email'] as String? ?? '',
//       username: row['username'] as String?,
//       displayName: row['display_name'] as String?,
//       avatarUrl: row['avatar_url'] as String?,
//       bio: row['bio'] as String?,
//       countryCode: row['country_code'] as String?,
//       age: row['age'] as int?,
//       phoneNumber: row['phone_number'] as String?,
//       preferredLanguage: row['preferred_lang'] as String? ?? 'en',
//       verificationStatus: row['verification_status'] as String? ?? 'unverified',
//       onlineStatus: row['online_status'] as String? ?? 'offline',
//       inGameStatus: row['in_game_status'] as bool? ?? false,
//       isBanned: row['is_banned'] as bool? ?? false,
//       usernameChangedAt: row['username_changed_at'] != null
//           ? DateTime.parse(row['username_changed_at'] as String)
//           : null,
//       lastSeenAt: row['last_seen_at'] != null
//           ? DateTime.parse(row['last_seen_at'] as String)
//           : null,
//       createdAt: row['created_at'] != null
//           ? DateTime.parse(row['created_at'] as String)
//           : null,
//       updatedAt: row['updated_at'] != null
//           ? DateTime.parse(row['updated_at'] as String)
//           : null,
//     );
//   }
// }

// /// Wrapper for Supabase auth state change events.
// class AuthStateChangeEvent {
//   const AuthStateChangeEvent({required this.session, required this.event});
//   final Session? session;
//   final AuthChangeEvent event;
// }

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/base_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/entities/user_entity.dart';

/// Authentication repository.
///
/// Routing:
///  - OTP send/verify      → Node.js API (owns OTP logic + Resend)
///  - Session management   → Supabase Flutter SDK (handles token refresh)
///  - Profile fetch/create → Supabase direct (RLS-protected reads)
///
/// Token lifecycle:
///  - Supabase SDK stores tokens in flutter_secure_storage automatically.
///  - We additionally persist pendingOtpEmail in secure storage for
///    crash-recovery (user killed app mid-OTP flow).
class AuthRepository extends BaseRepository {
  AuthRepository._();
  static final AuthRepository _instance = AuthRepository._();
  static AuthRepository get instance => _instance;

  final _supabase = Supabase.instance.client;
  final _api = ApiClient.instance;
  final _secure = SecureStorageService.instance;
  final _local = LocalStorageService.instance;

  // ── Auth state stream ───────────────────────────────────────────────────
  /// Emits whenever Supabase auth state changes: sign-in, sign-out, token refresh.
  Stream<AuthStateChangeEvent> get authStateStream => _supabase
      .auth
      .onAuthStateChange
      .map((e) => AuthStateChangeEvent(session: e.session, event: e.event));

  // ── Session restore ─────────────────────────────────────────────────────
  /// Called once at app startup.
  /// Supabase SDK auto-refreshes the token if it's still valid.
  /// Returns (null, null) if no session exists.
  Future<(Session?, UserEntity?)> restoreSession() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return (null, null);

    // Verify token is still valid (SDK may have a cached expired session)
    if (session.isExpired) {
      try {
        final refreshed = await _supabase.auth.refreshSession();
        if (refreshed.session == null) return (null, null);
        final user = await _fetchCurrentProfile(refreshed.session!.user.id);
        AppLogger.info('AuthRepository: session restored via refresh');
        return (refreshed.session, user);
      } catch (e) {
        AppLogger.warning('AuthRepository: token refresh failed, $e');
        return (null, null);
      }
    }

    final user = await _fetchCurrentProfile(session.user.id);
    AppLogger.info('AuthRepository: session restored');
    return (session, user);
  }

  // ── Pending OTP email persistence ────────────────────────────────────────
  Future<void> savePendingOtpEmail(String email) =>
      _secure.write(SecureKeys.pendingOtpEmail, email);

  Future<String?> getPendingOtpEmail() =>
      _secure.read(SecureKeys.pendingOtpEmail);

  Future<void> clearPendingOtpEmail() =>
      _secure.delete(SecureKeys.pendingOtpEmail);

  // ── OTP send ─────────────────────────────────────────────────────────────
  Future<void> sendOtp(String email) => guardedCall(
    operationName: 'sendOtp',
    operation: () async {
      await _api.post('/v1/auth/send-otp', data: {'email': email});
      // Persist email in case user kills app before verifying
      await savePendingOtpEmail(email);
      AppLogger.info('OTP sent to $email');
    },
  );

  // ── OTP verify ────────────────────────────────────────────────────────────
  Future<(Session, UserEntity)> verifyOtp(String email, String otp) =>
      guardedCall(
        operationName: 'verifyOtp',
        operation: () async {
          final response = await _api.post<Map<String, dynamic>>(
            '/v1/auth/verify-otp',
            data: {'email': email, 'otp': otp},
          );

          final data = response.data!['data'] as Map<String, dynamic>;
          final accessToken = data['access_token'] as String? ?? '';
          final refreshToken = data['refresh_token'] as String? ?? '';
          final isNewUser = data['is_new_user'] as bool? ?? false;

          if (accessToken.isEmpty || refreshToken.isEmpty) {
            throw const AuthFailure(
              message: 'No session token received from server.',
            );
          }

          // Server returned real JWT tokens — set session with both tokens
          final authResponse = await _supabase.auth.setSession(
            refreshToken,
            accessToken: accessToken,
            // refreshToken,
          );

          final session = authResponse.session;
          if (session == null) {
            throw const AuthFailure(message: 'Failed to establish session.');
          }

          await clearPendingOtpEmail();

          UserEntity user;
          if (isNewUser) {
            user = _minimalUserEntity(session.user, email);
          } else {
            user =
                await _fetchCurrentProfile(session.user.id) ??
                _minimalUserEntity(session.user, email);
          }

          AppLogger.info('OTP verified, session created. isNewUser=$isNewUser');
          return (session, user);
        },
      );

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      // Notify Node.js to update online status
      await _api.post('/v1/auth/sign-out', data: {});
    } catch (e) {
      // Best-effort — always continue with local sign-out
      AppLogger.warning('AuthRepository: sign-out API call failed, $e');
    }

    await _supabase.auth.signOut();
    await _secure.deleteAll();
    AppLogger.info('User signed out');
  }

  // ── Profile fetch ─────────────────────────────────────────────────────────
  Future<UserEntity?> _fetchCurrentProfile(String userId) async {
    try {
      final row = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (row == null) return null;
      return _profileRowToEntity(row);
    } catch (e) {
      AppLogger.warning('AuthRepository: profile fetch failed, $e');
      return null;
    }
  }

  // ── Mappers ───────────────────────────────────────────────────────────────
  UserEntity _minimalUserEntity(User user, String email) {
    return UserEntity(id: user.id, email: user.email ?? email);
  }

  UserEntity _profileRowToEntity(Map<String, dynamic> row) {
    return UserEntity(
      id: row['id'] as String,
      email: row['email'] as String? ?? '',
      username: row['username'] as String?,
      displayName: row['display_name'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      bio: row['bio'] as String?,
      countryCode: row['country_code'] as String?,
      age: row['age'] as int?,
      phoneNumber: row['phone_number'] as String?,
      preferredLanguage: row['preferred_lang'] as String? ?? 'en',
      verificationStatus: row['verification_status'] as String? ?? 'unverified',
      onlineStatus: row['online_status'] as String? ?? 'offline',
      inGameStatus: row['in_game_status'] as bool? ?? false,
      isBanned: row['is_banned'] as bool? ?? false,
      usernameChangedAt: row['username_changed_at'] != null
          ? DateTime.parse(row['username_changed_at'] as String)
          : null,
      lastSeenAt: row['last_seen_at'] != null
          ? DateTime.parse(row['last_seen_at'] as String)
          : null,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }
}

/// Wrapper for Supabase auth state change events.
class AuthStateChangeEvent {
  const AuthStateChangeEvent({required this.session, required this.event});
  final Session? session;
  final AuthChangeEvent event;
}
