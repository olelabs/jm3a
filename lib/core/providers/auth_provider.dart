// // // // import 'dart:async';

// // // // import 'package:flutter/foundation.dart';
// // // // import 'package:jma3a/core/storage/secure_storage_service.dart';
// // // // import 'package:supabase_flutter/supabase_flutter.dart'
// // // //     show Session, AuthChangeEvent;

// // // // import '../errors/failures.dart';
// // // // // import '../services/secure_storage_service.dart';
// // // // import '../utils/app_logger.dart';
// // // // import '../../features/auth/data/auth_repository.dart';
// // // // import '../../features/auth/domain/entities/user_entity.dart';

// // // // /// Authentication state for the entire app.
// // // // ///
// // // // /// This is the single source of truth for:
// // // // /// - Current user identity
// // // // /// - Session validity
// // // // /// - Auth flow states (sending, verifying, etc.)
// // // // /// - Onboarding state (needs profile completion)
// // // // ///
// // // // /// Drives the GoRouter redirect guard — all screens check here.
// // // // class AuthProvider extends ChangeNotifier {
// // // //   AuthProvider({
// // // //     required AuthRepository authRepository,
// // // //     required SecureStorageService secureStorage,
// // // //   }) : _authRepository = authRepository,
// // // //        _secureStorage = secureStorage;

// // // //   final AuthRepository _authRepository;
// // // //   final SecureStorageService _secureStorage;
// // // //   StreamSubscription<AuthStateChangeEvent>? _authStateSubscription;

// // // //   // ── State ──────────────────────────────────────────────────────────────
// // // //   UserEntity? _currentUser;
// // // //   Session? _session;
// // // //   bool _isInitializing = true;
// // // //   Failure? _error;
// // // //   bool _isSendingOtp = false;
// // // //   bool _isVerifyingOtp = false;

// // // //   // ── Getters ───────────────────────────────────────────────────────────
// // // //   UserEntity? get currentUser => _currentUser;
// // // //   Session? get session => _session;
// // // //   bool get isInitializing => _isInitializing;
// // // //   bool get isLoggedIn => _session != null && _currentUser != null;
// // // //   bool get needsOnboarding =>
// // // //       isLoggedIn && !(_currentUser?.hasCompletedProfile ?? false);
// // // //   bool get isSendingOtp => _isSendingOtp;
// // // //   bool get isVerifyingOtp => _isVerifyingOtp;
// // // //   Failure? get error => _error;

// // // //   // ── Initialization ─────────────────────────────────────────────────────
// // // //   /// Called once at app startup.
// // // //   /// Restores existing session (auto-login) then subscribes to future changes.
// // // //   Future<void> initialize() async {
// // // //     _isInitializing = true;
// // // //     notifyListeners();

// // // //     try {
// // // //       final result = await _authRepository.restoreSession();
// // // //       _session = result.$1;
// // // //       _currentUser = result.$2;
// // // //     } catch (e) {
// // // //       AppLogger.warning('AuthProvider: session restore failed, $e');
// // // //       _session = null;
// // // //       _currentUser = null;
// // // //     }

// // // //     // Subscribe to real-time auth state changes (token refresh, sign out from another device)
// // // //     _authStateSubscription = _authRepository.authStateStream.listen(
// // // //       _onAuthStateChange,
// // // //       onError: (e) => AppLogger.warning('AuthProvider: auth stream error, $e'),
// // // //     );

// // // //     _isInitializing = false;
// // // //     notifyListeners();
// // // //     AppLogger.info('AuthProvider initialized. isLoggedIn=$isLoggedIn');
// // // //   }

// // // //   // ── Auth state stream ──────────────────────────────────────────────────
// // // //   void _onAuthStateChange(AuthStateChangeEvent change) {
// // // //     _session = change.session;

// // // //     if (change.session == null) {
// // // //       // Signed out — clear user data
// // // //       _currentUser = null;
// // // //     }

// // // //     // On token refresh, the user entity itself doesn't change — only the session
// // // //     AppLogger.debug(
// // // //       'AuthProvider: auth state changed — event=${change.event.name}',
// // // //     );
// // // //     notifyListeners();
// // // //   }

// // // //   // ── Send OTP ────────────────────────────────────────────────────────────
// // // //   Future<({bool success, String? errorMessage})> sendOtp(String email) async {
// // // //     _isSendingOtp = true;
// // // //     _error = null;
// // // //     notifyListeners();

// // // //     try {
// // // //       await _authRepository.sendOtp(email);
// // // //       return (success: true, errorMessage: null);
// // // //     } on Failure catch (f) {
// // // //       _error = f;
// // // //       return (success: false, errorMessage: f.message);
// // // //     } on RateLimitFailure catch (f) {
// // // //       _error = f;
// // // //       return (success: false, errorMessage: f.message);
// // // //     } finally {
// // // //       _isSendingOtp = false;
// // // //       notifyListeners();
// // // //     }
// // // //   }

// // // //   // ── Verify OTP ──────────────────────────────────────────────────────────
// // // //   Future<({bool success, String? errorMessage, int? attemptsRemaining})>
// // // //   verifyOtp(String email, String otp) async {
// // // //     _isVerifyingOtp = true;
// // // //     _error = null;
// // // //     notifyListeners();

// // // //     try {
// // // //       final result = await _authRepository.verifyOtp(email, otp);
// // // //       _session = result.$1;
// // // //       _currentUser = result.$2;
// // // //       return (success: true, errorMessage: null, attemptsRemaining: null);
// // // //     } on OtpFailure catch (f) {
// // // //       _error = f;
// // // //       // Parse remaining attempts from code if present
// // // //       final remaining = f.code?.startsWith('otp_invalid') == true
// // // //           ? _parseAttemptsRemaining(f.message)
// // // //           : null;
// // // //       return (
// // // //         success: false,
// // // //         errorMessage: f.message,
// // // //         attemptsRemaining: remaining,
// // // //       );
// // // //     } on Failure catch (f) {
// // // //       _error = f;
// // // //       return (success: false, errorMessage: f.message, attemptsRemaining: null);
// // // //     } finally {
// // // //       _isVerifyingOtp = false;
// // // //       notifyListeners();
// // // //     }
// // // //   }

// // // //   // ── Sign out ─────────────────────────────────────────────────────────────
// // // //   Future<void> signOut() async {
// // // //     await _authRepository.signOut();
// // // //     await _secureStorage.deleteAll();
// // // //     _session = null;
// // // //     _currentUser = null;
// // // //     _error = null;
// // // //     notifyListeners();
// // // //   }

// // // //   // ── Update current user ───────────────────────────────────────────────────
// // // //   /// Called by ProfileProvider/OnboardingScreen after profile creation/update.
// // // //   void updateCurrentUser(UserEntity user) {
// // // //     _currentUser = user;
// // // //     notifyListeners();
// // // //   }

// // // //   void clearError() {
// // // //     if (_error == null) return;
// // // //     _error = null;
// // // //     notifyListeners();
// // // //   }

// // // //   // ── Guest mode ────────────────────────────────────────────────────────────
// // // //   /// Guest mode: sets up an ephemeral in-memory session.
// // // //   /// No network — offline gameplay only.
// // // //   bool _isGuest = false;
// // // //   bool get isGuest => _isGuest;

// // // //   void enterGuestMode() {
// // // //     _isGuest = true;
// // // //     _currentUser = const UserEntity(
// // // //       id: 'guest',
// // // //       email: '',
// // // //       displayName: 'Guest',
// // // //       preferredLanguage: 'en',
// // // //     );
// // // //     notifyListeners();
// // // //   }

// // // //   void exitGuestMode() {
// // // //     _isGuest = false;
// // // //     _currentUser = null;
// // // //     notifyListeners();
// // // //   }

// // // //   // ── Helpers ───────────────────────────────────────────────────────────────
// // // //   int? _parseAttemptsRemaining(String message) {
// // // //     final match = RegExp(r'(\d+) attempt').firstMatch(message);
// // // //     if (match == null) return null;
// // // //     return int.tryParse(match.group(1) ?? '');
// // // //   }

// // // //   @override
// // // //   void dispose() {
// // // //     _authStateSubscription?.cancel();
// // // //     super.dispose();
// // // //   }
// // // // }

// // // import 'dart:async';

// // // import 'package:flutter/foundation.dart';
// // // import 'package:jma3a/core/storage/secure_storage_service.dart';
// // // import 'package:supabase_flutter/supabase_flutter.dart'
// // //     show Session, AuthChangeEvent;

// // // import '../errors/failures.dart';
// // // // import '../services/secure_storage_service.dart';
// // // import '../utils/app_logger.dart';
// // // import '../../features/auth/data/auth_repository.dart';
// // // import '../../features/auth/domain/entities/user_entity.dart';

// // // /// Authentication state for the entire app.
// // // ///
// // // /// This is the single source of truth for:
// // // /// - Current user identity
// // // /// - Session validity
// // // /// - Auth flow states (sending, verifying, etc.)
// // // /// - Onboarding state (needs profile completion)
// // // ///
// // // /// Drives the GoRouter redirect guard — all screens check here.
// // // class AuthProvider extends ChangeNotifier {
// // //   AuthProvider({
// // //     required AuthRepository authRepository,
// // //     required SecureStorageService secureStorage,
// // //   }) : _authRepository = authRepository,
// // //        _secureStorage = secureStorage;

// // //   final AuthRepository _authRepository;
// // //   final SecureStorageService _secureStorage;
// // //   StreamSubscription<AuthStateChangeEvent>? _authStateSubscription;

// // //   // ── State ──────────────────────────────────────────────────────────────
// // //   UserEntity? _currentUser;
// // //   Session? _session;
// // //   bool _isInitializing = true;
// // //   Failure? _error;
// // //   bool _isSendingOtp = false;
// // //   bool _isVerifyingOtp = false;

// // //   // ── Getters ───────────────────────────────────────────────────────────
// // //   UserEntity? get currentUser => _currentUser;
// // //   Session? get session => _session;
// // //   bool get isInitializing => _isInitializing;
// // //   bool get isLoggedIn => _session != null && _currentUser != null;
// // //   bool get needsOnboarding =>
// // //       isLoggedIn && !(_currentUser?.hasCompletedProfile ?? false);
// // //   bool get isSendingOtp => _isSendingOtp;
// // //   bool get isVerifyingOtp => _isVerifyingOtp;
// // //   Failure? get error => _error;

// // //   // ── Initialization ─────────────────────────────────────────────────────
// // //   /// Called once at app startup.
// // //   /// Restores existing session (auto-login) then subscribes to future changes.
// // //   // Future<void> initialize() async {
// // //   //   _isInitializing = true;
// // //   //   notifyListeners();

// // //   //   AppLogger.info('AuthProvider.initialize() started');

// // //   //   try {
// // //   //     // Attempt to restore session
// // //   //     AppLogger.debug('Attempting to restore session...');
// // //   //     final result = await _authRepository.restoreSession();
// // //   //     _session = result.$1;
// // //   //     _currentUser = result.$2;
// // //   //     AppLogger.debug('Session restored: isLoggedIn=${_session != null}');
// // //   //   } catch (e, stackTrace) {
// // //   //     AppLogger.warning(
// // //   //       'AuthProvider: session restore failed',
// // //   //       error: e,
// // //   //       stackTrace: stackTrace,
// // //   //     );
// // //   //     _session = null;
// // //   //     _currentUser = null;
// // //   //   }

// // //   //   // Subscribe to real-time auth state changes
// // //   //   try {
// // //   //     _authStateSubscription = _authRepository.authStateStream.listen(
// // //   //       _onAuthStateChange,
// // //   //       onError: (e) =>
// // //   //           AppLogger.warning('AuthProvider: auth stream error, $e'),
// // //   //     );
// // //   //     AppLogger.debug('Auth state stream subscription established');
// // //   //   } catch (e) {
// // //   //     AppLogger.warning('Failed to subscribe to auth state stream', error: e);
// // //   //   }

// // //   //   // ALWAYS set initializing to false, even if errors occurred
// // //   //   _isInitializing = false;
// // //   //   notifyListeners();
// // //   //   AppLogger.info(
// // //   //     'AuthProvider initialized. isLoggedIn=$isLoggedIn, isInitializing=$_isInitializing',
// // //   //   );
// // //   // }
// // //   // lib/core/providers/auth_provider.dart - Add timeout
// // //   Future<void> initialize() async {
// // //     _isInitializing = true;
// // //     notifyListeners();

// // //     // Add a timeout to prevent hanging
// // //     Timer(const Duration(seconds: 5), () {
// // //       if (_isInitializing) {
// // //         AppLogger.warning(
// // //           'AuthProvider initialization timeout - forcing completion',
// // //         );
// // //         _isInitializing = false;
// // //         notifyListeners();
// // //       }
// // //     });

// // //     try {
// // //       final result = await _authRepository.restoreSession();
// // //       _session = result.$1;
// // //       _currentUser = result.$2;
// // //     } catch (e) {
// // //       AppLogger.warning('AuthProvider: session restore failed, $e');
// // //       _session = null;
// // //       _currentUser = null;
// // //     }

// // //     _authStateSubscription = _authRepository.authStateStream.listen(
// // //       _onAuthStateChange,
// // //       onError: (e) => AppLogger.warning('AuthProvider: auth stream error, $e'),
// // //     );

// // //     _isInitializing = false;
// // //     notifyListeners();
// // //     AppLogger.info('AuthProvider initialized. isLoggedIn=$isLoggedIn');
// // //   }

// // //   // ── Auth state stream ──────────────────────────────────────────────────
// // //   void _onAuthStateChange(AuthStateChangeEvent change) {
// // //     AppLogger.debug(
// // //       'AuthProvider: auth state changed — event=${change.event.name}',
// // //     );
// // //     _session = change.session;

// // //     if (change.session == null) {
// // //       // Signed out — clear user data
// // //       _currentUser = null;
// // //     }

// // //     notifyListeners();
// // //   }

// // //   // ── Send OTP ────────────────────────────────────────────────────────────
// // //   Future<({bool success, String? errorMessage})> sendOtp(String email) async {
// // //     _isSendingOtp = true;
// // //     _error = null;
// // //     notifyListeners();

// // //     try {
// // //       await _authRepository.sendOtp(email);
// // //       return (success: true, errorMessage: null);
// // //     } on Failure catch (f) {
// // //       _error = f;
// // //       return (success: false, errorMessage: f.message);
// // //     } on RateLimitFailure catch (f) {
// // //       _error = f;
// // //       return (success: false, errorMessage: f.message);
// // //     } finally {
// // //       _isSendingOtp = false;
// // //       notifyListeners();
// // //     }
// // //   }

// // //   // ── Verify OTP ──────────────────────────────────────────────────────────
// // //   Future<({bool success, String? errorMessage, int? attemptsRemaining})>
// // //   verifyOtp(String email, String otp) async {
// // //     _isVerifyingOtp = true;
// // //     _error = null;
// // //     notifyListeners();

// // //     try {
// // //       final result = await _authRepository.verifyOtp(email, otp);
// // //       _session = result.$1;
// // //       _currentUser = result.$2;
// // //       return (success: true, errorMessage: null, attemptsRemaining: null);
// // //     } on OtpFailure catch (f) {
// // //       _error = f;
// // //       // Parse remaining attempts from code if present
// // //       final remaining = f.code?.startsWith('otp_invalid') == true
// // //           ? _parseAttemptsRemaining(f.message)
// // //           : null;
// // //       return (
// // //         success: false,
// // //         errorMessage: f.message,
// // //         attemptsRemaining: remaining,
// // //       );
// // //     } on Failure catch (f) {
// // //       _error = f;
// // //       return (success: false, errorMessage: f.message, attemptsRemaining: null);
// // //     } finally {
// // //       _isVerifyingOtp = false;
// // //       notifyListeners();
// // //     }
// // //   }

// // //   // ── Sign out ─────────────────────────────────────────────────────────────
// // //   Future<void> signOut() async {
// // //     await _authRepository.signOut();
// // //     await _secureStorage.deleteAll();
// // //     _session = null;
// // //     _currentUser = null;
// // //     _error = null;
// // //     notifyListeners();
// // //   }

// // //   // ── Update current user ───────────────────────────────────────────────────
// // //   /// Called by ProfileProvider/OnboardingScreen after profile creation/update.
// // //   void updateCurrentUser(UserEntity user) {
// // //     _currentUser = user;
// // //     notifyListeners();
// // //   }

// // //   void clearError() {
// // //     if (_error == null) return;
// // //     _error = null;
// // //     notifyListeners();
// // //   }

// // //   // ── Guest mode ────────────────────────────────────────────────────────────
// // //   /// Guest mode: sets up an ephemeral in-memory session.
// // //   /// No network — offline gameplay only.
// // //   bool _isGuest = false;
// // //   bool get isGuest => _isGuest;

// // //   void enterGuestMode() {
// // //     _isGuest = true;
// // //     _currentUser = const UserEntity(
// // //       id: 'guest',
// // //       email: '',
// // //       displayName: 'Guest',
// // //       preferredLanguage: 'en',
// // //     );
// // //     notifyListeners();
// // //   }

// // //   void exitGuestMode() {
// // //     _isGuest = false;
// // //     _currentUser = null;
// // //     notifyListeners();
// // //   }

// // //   // ── Helpers ───────────────────────────────────────────────────────────────
// // //   int? _parseAttemptsRemaining(String message) {
// // //     final match = RegExp(r'(\d+) attempt').firstMatch(message);
// // //     if (match == null) return null;
// // //     return int.tryParse(match.group(1) ?? '');
// // //   }

// // //   @override
// // //   void dispose() {
// // //     _authStateSubscription?.cancel();
// // //     super.dispose();
// // //   }
// // // }

// // import 'dart:async';

// // import 'package:flutter/foundation.dart';
// // import 'package:jma3a/core/storage/secure_storage_service.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart'
// //     show Session, AuthChangeEvent;

// // import '../errors/failures.dart';
// // import '../utils/app_logger.dart';
// // import '../../features/auth/data/auth_repository.dart';
// // import '../../features/auth/domain/entities/user_entity.dart';

// // class AuthProvider extends ChangeNotifier {
// //   AuthProvider({
// //     required AuthRepository authRepository,
// //     required SecureStorageService secureStorage,
// //   }) : _authRepository = authRepository,
// //        _secureStorage = secureStorage;

// //   final AuthRepository _authRepository;
// //   final SecureStorageService _secureStorage;
// //   StreamSubscription<AuthStateChangeEvent>? _authStateSubscription;

// //   UserEntity? _currentUser;
// //   Session? _session;
// //   bool _isInitializing = true;
// //   Failure? _error;
// //   bool _isSendingOtp = false;
// //   bool _isVerifyingOtp = false;

// //   UserEntity? get currentUser => _currentUser;
// //   Session? get session => _session;
// //   bool get isInitializing => _isInitializing;
// //   bool get isLoggedIn => _session != null && _currentUser != null;
// //   bool get needsOnboarding =>
// //       isLoggedIn && !(_currentUser?.hasCompletedProfile ?? false);
// //   bool get isSendingOtp => _isSendingOtp;
// //   bool get isVerifyingOtp => _isVerifyingOtp;
// //   Failure? get error => _error;

// //   Future<void> initialize() async {
// //     _isInitializing = true;
// //     notifyListeners();

// //     Timer(const Duration(seconds: 5), () {
// //       if (_isInitializing) {
// //         AppLogger.warning(
// //           'AuthProvider initialization timeout - forcing completion',
// //         );
// //         _isInitializing = false;
// //         notifyListeners();
// //       }
// //     });

// //     try {
// //       final result = await _authRepository.restoreSession();
// //       _session = result.$1;
// //       _currentUser = result.$2;
// //     } catch (e) {
// //       AppLogger.warning('AuthProvider: session restore failed, $e');
// //       _session = null;
// //       _currentUser = null;
// //     }

// //     _authStateSubscription = _authRepository.authStateStream.listen(
// //       _onAuthStateChange,
// //       onError: (e) => AppLogger.warning('AuthProvider: auth stream error, $e'),
// //     );

// //     _isInitializing = false;
// //     notifyListeners();
// //     AppLogger.info('AuthProvider initialized. isLoggedIn=$isLoggedIn');
// //   }

// //   void _onAuthStateChange(AuthStateChangeEvent change) {
// //     AppLogger.debug(
// //       'AuthProvider: auth state changed — event=${change.event.name}',
// //     );
// //     _session = change.session;

// //     if (change.session == null) {
// //       _currentUser = null;
// //       notifyListeners();
// //       return;
// //     }

// //     final event = change.event;
// //     if (event == AuthChangeEvent.signedIn ||
// //         event == AuthChangeEvent.tokenRefreshed ||
// //         event == AuthChangeEvent.userUpdated) {
// //       if (_currentUser == null) {
// //         _authRepository
// //             .restoreSession()
// //             .then((result) {
// //               _session = result.$1 ?? _session;
// //               _currentUser = result.$2;
// //               notifyListeners();
// //             })
// //             .catchError((e) {
// //               AppLogger.warning('AuthProvider: profile reload failed, $e');
// //             });
// //         return;
// //       }
// //     }

// //     notifyListeners();
// //   }

// //   Future<({bool success, String? errorMessage})> sendOtp(String email) async {
// //     _isSendingOtp = true;
// //     _error = null;
// //     notifyListeners();

// //     try {
// //       await _authRepository.sendOtp(email);
// //       return (success: true, errorMessage: null);
// //     } on Failure catch (f) {
// //       _error = f;
// //       return (success: false, errorMessage: f.message);
// //     } on RateLimitFailure catch (f) {
// //       _error = f;
// //       return (success: false, errorMessage: f.message);
// //     } finally {
// //       _isSendingOtp = false;
// //       notifyListeners();
// //     }
// //   }

// //   Future<({bool success, String? errorMessage, int? attemptsRemaining})>
// //   verifyOtp(String email, String otp) async {
// //     _isVerifyingOtp = true;
// //     _error = null;
// //     notifyListeners();

// //     try {
// //       final result = await _authRepository.verifyOtp(email, otp);
// //       _session = result.$1;
// //       _currentUser = result.$2;
// //       return (success: true, errorMessage: null, attemptsRemaining: null);
// //     } on OtpFailure catch (f) {
// //       _error = f;
// //       final remaining = f.code?.startsWith('otp_invalid') == true
// //           ? _parseAttemptsRemaining(f.message)
// //           : null;
// //       return (
// //         success: false,
// //         errorMessage: f.message,
// //         attemptsRemaining: remaining,
// //       );
// //     } on Failure catch (f) {
// //       _error = f;
// //       return (success: false, errorMessage: f.message, attemptsRemaining: null);
// //     } finally {
// //       _isVerifyingOtp = false;
// //       notifyListeners();
// //     }
// //   }

// //   Future<void> signOut() async {
// //     await _authRepository.signOut();
// //     await _secureStorage.deleteAll();
// //     _session = null;
// //     _currentUser = null;
// //     _error = null;
// //     notifyListeners();
// //   }

// //   void updateCurrentUser(UserEntity user) {
// //     _currentUser = user;
// //     notifyListeners();
// //   }

// //   void clearError() {
// //     if (_error == null) return;
// //     _error = null;
// //     notifyListeners();
// //   }

// //   bool _isGuest = false;
// //   bool get isGuest => _isGuest;

// //   void enterGuestMode() {
// //     _isGuest = true;
// //     _currentUser = const UserEntity(
// //       id: 'guest',
// //       email: '',
// //       displayName: 'Guest',
// //       preferredLanguage: 'en',
// //     );
// //     notifyListeners();
// //   }

// //   void exitGuestMode() {
// //     _isGuest = false;
// //     _currentUser = null;
// //     notifyListeners();
// //   }

// //   int? _parseAttemptsRemaining(String message) {
// //     final match = RegExp(r'(\d+) attempt').firstMatch(message);
// //     if (match == null) return null;
// //     return int.tryParse(match.group(1) ?? '');
// //   }

// //   @override
// //   void dispose() {
// //     _authStateSubscription?.cancel();
// //     super.dispose();
// //   }
// // }

// import 'dart:async';

// import 'package:flutter/foundation.dart';
// import 'package:jma3a/core/storage/secure_storage_service.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'
//     show Session, AuthChangeEvent;

// import '../errors/failures.dart';
// import '../utils/app_logger.dart';
// import '../../features/auth/data/auth_repository.dart';
// import '../../features/auth/domain/entities/user_entity.dart';

// class AuthProvider extends ChangeNotifier {
//   AuthProvider({
//     required AuthRepository authRepository,
//     required SecureStorageService secureStorage,
//   }) : _authRepository = authRepository,
//        _secureStorage = secureStorage;

//   final AuthRepository _authRepository;
//   final SecureStorageService _secureStorage;
//   StreamSubscription<AuthStateChangeEvent>? _authStateSubscription;

//   UserEntity? _currentUser;
//   Session? _session;
//   bool _isInitializing = true;
//   Failure? _error;
//   bool _isSendingOtp = false;
//   bool _isVerifyingOtp = false;

//   UserEntity? get currentUser => _currentUser;
//   Session? get session => _session;
//   bool get isInitializing => _isInitializing;
//   bool get isLoggedIn => _session != null && _currentUser != null;
//   bool get needsOnboarding =>
//       isLoggedIn && !(_currentUser?.hasCompletedProfile ?? false);
//   bool get isSendingOtp => _isSendingOtp;
//   bool get isVerifyingOtp => _isVerifyingOtp;
//   Failure? get error => _error;

//   Future<void> initialize() async {
//     _isInitializing = true;
//     notifyListeners();

//     Timer(const Duration(seconds: 5), () {
//       if (_isInitializing) {
//         AppLogger.warning(
//           'AuthProvider initialization timeout - forcing completion',
//         );
//         _isInitializing = false;
//         notifyListeners();
//       }
//     });

//     try {
//       final result = await _authRepository.restoreSession();
//       _session = result.$1;
//       _currentUser = result.$2;
//     } catch (e) {
//       AppLogger.warning('AuthProvider: session restore failed, $e');
//       _session = null;
//       _currentUser = null;
//     }

//     _authStateSubscription = _authRepository.authStateStream.listen(
//       _onAuthStateChange,
//       onError: (e) => AppLogger.warning('AuthProvider: auth stream error, $e'),
//     );

//     _isInitializing = false;
//     notifyListeners();
//     AppLogger.info('AuthProvider initialized. isLoggedIn=$isLoggedIn');
//   }

//   void _onAuthStateChange(AuthStateChangeEvent change) {
//     AppLogger.debug(
//       'AuthProvider: auth state changed — event=${change.event.name}',
//     );
//     _session = change.session;

//     if (change.session == null) {
//       _currentUser = null;
//       notifyListeners();
//       return;
//     }

//     final event = change.event;
//     if (event == AuthChangeEvent.signedIn ||
//         event == AuthChangeEvent.tokenRefreshed ||
//         event == AuthChangeEvent.userUpdated) {
//       if (_currentUser == null) {
//         _authRepository
//             .restoreSession()
//             .then((result) {
//               _session = result.$1 ?? _session;
//               _currentUser = result.$2;
//               notifyListeners();
//             })
//             .catchError((e) {
//               AppLogger.warning('AuthProvider: profile reload failed, $e');
//             });
//         return;
//       }
//     }

//     notifyListeners();
//   }

//   Future<void> refreshCurrentUser() async {
//     final session = await _authRepository.restoreSession();
//     if (session.$1 == null) return;
//     _currentUser = session.$2 ?? _currentUser;
//     notifyListeners();
//   }

//   Future<({bool success, String? errorMessage})> sendOtp(String email) async {
//     _isSendingOtp = true;
//     _error = null;
//     notifyListeners();

//     try {
//       await _authRepository.sendOtp(email);
//       return (success: true, errorMessage: null);
//     } on Failure catch (f) {
//       _error = f;
//       return (success: false, errorMessage: f.message);
//     } on RateLimitFailure catch (f) {
//       _error = f;
//       return (success: false, errorMessage: f.message);
//     } finally {
//       _isSendingOtp = false;
//       notifyListeners();
//     }
//   }

//   Future<({bool success, String? errorMessage, int? attemptsRemaining})>
//   verifyOtp(String email, String otp) async {
//     _isVerifyingOtp = true;
//     _error = null;
//     notifyListeners();

//     try {
//       final result = await _authRepository.verifyOtp(email, otp);
//       _session = result.$1;
//       _currentUser = result.$2;
//       return (success: true, errorMessage: null, attemptsRemaining: null);
//     } on OtpFailure catch (f) {
//       _error = f;
//       final remaining = f.code?.startsWith('otp_invalid') == true
//           ? _parseAttemptsRemaining(f.message)
//           : null;
//       return (
//         success: false,
//         errorMessage: f.message,
//         attemptsRemaining: remaining,
//       );
//     } on Failure catch (f) {
//       _error = f;
//       return (success: false, errorMessage: f.message, attemptsRemaining: null);
//     } finally {
//       _isVerifyingOtp = false;
//       notifyListeners();
//     }
//   }

//   Future<void> signOut() async {
//     await _authRepository.signOut();
//     await _secureStorage.deleteAll();
//     _session = null;
//     _currentUser = null;
//     _error = null;
//     notifyListeners();
//   }

//   void updateCurrentUser(UserEntity user) {
//     _currentUser = user;
//     notifyListeners();
//   }

//   void clearError() {
//     if (_error == null) return;
//     _error = null;
//     notifyListeners();
//   }

//   bool _isGuest = false;
//   bool get isGuest => _isGuest;

//   void enterGuestMode() {
//     _isGuest = true;
//     _currentUser = const UserEntity(
//       id: 'guest',
//       email: '',
//       displayName: 'Guest',
//       preferredLanguage: 'en',
//     );
//     notifyListeners();
//   }

//   void exitGuestMode() {
//     _isGuest = false;
//     _currentUser = null;
//     notifyListeners();
//   }

//   int? _parseAttemptsRemaining(String message) {
//     final match = RegExp(r'(\d+) attempt').firstMatch(message);
//     if (match == null) return null;
//     return int.tryParse(match.group(1) ?? '');
//   }

//   @override
//   void dispose() {
//     _authStateSubscription?.cancel();
//     super.dispose();
//   }
// }

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jma3a/core/storage/secure_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show Session, AuthChangeEvent;

import '../errors/failures.dart';
import '../utils/app_logger.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/entities/user_entity.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthRepository authRepository,
    required SecureStorageService secureStorage,
  }) : _authRepository = authRepository,
       _secureStorage = secureStorage;

  final AuthRepository _authRepository;
  final SecureStorageService _secureStorage;
  StreamSubscription<AuthStateChangeEvent>? _authStateSubscription;

  UserEntity? _currentUser;
  Session? _session;
  bool _isInitializing = true;
  Failure? _error;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;

  UserEntity? get currentUser => _currentUser;
  Session? get session => _session;
  bool get isInitializing => _isInitializing;
  bool get isLoggedIn => _session != null && _currentUser != null;
  bool get needsOnboarding =>
      isLoggedIn && !(_currentUser?.hasCompletedProfile ?? false);
  bool get isSendingOtp => _isSendingOtp;
  bool get isVerifyingOtp => _isVerifyingOtp;
  Failure? get error => _error;

  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    Timer(const Duration(seconds: 5), () {
      if (_isInitializing) {
        AppLogger.warning(
          'AuthProvider initialization timeout - forcing completion',
        );
        _isInitializing = false;
        notifyListeners();
      }
    });

    try {
      final result = await _authRepository.restoreSession();
      _session = result.$1;
      _currentUser = result.$2;
    } catch (e) {
      AppLogger.warning('AuthProvider: session restore failed, $e');
      _session = null;
      _currentUser = null;
    }

    _authStateSubscription = _authRepository.authStateStream.listen(
      _onAuthStateChange,
      onError: (e) => AppLogger.warning('AuthProvider: auth stream error, $e'),
    );

    _isInitializing = false;
    notifyListeners();
    AppLogger.info('AuthProvider initialized. isLoggedIn=$isLoggedIn');
  }

  void _onAuthStateChange(AuthStateChangeEvent change) {
    AppLogger.debug(
      'AuthProvider: auth state changed — event=${change.event.name}',
    );
    _session = change.session;

    if (change.session == null) {
      _currentUser = null;
    }

    notifyListeners();
  }

  Future<({bool success, String? errorMessage})> sendOtp(String email) async {
    _isSendingOtp = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.sendOtp(email);
      return (success: true, errorMessage: null);
    } on Failure catch (f) {
      _error = f;
      return (success: false, errorMessage: f.message);
    } on RateLimitFailure catch (f) {
      _error = f;
      return (success: false, errorMessage: f.message);
    } finally {
      _isSendingOtp = false;
      notifyListeners();
    }
  }

  Future<({bool success, String? errorMessage, String? syntheticEmail})>
  sendPhoneOtp(String phone) async {
    _isSendingOtp = true;
    _error = null;
    notifyListeners();

    try {
      final syntheticEmail = await _authRepository.sendPhoneOtp(phone);
      return (
        success: true,
        errorMessage: null,
        syntheticEmail: syntheticEmail,
      );
    } on Failure catch (f) {
      _error = f;
      return (success: false, errorMessage: f.message, syntheticEmail: null);
    } on RateLimitFailure catch (f) {
      _error = f;
      return (success: false, errorMessage: f.message, syntheticEmail: null);
    } finally {
      _isSendingOtp = false;
      notifyListeners();
    }
  }

  Future<({bool success, String? errorMessage, int? attemptsRemaining})>
  verifyOtp(String email, String otp) async {
    _isVerifyingOtp = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authRepository.verifyOtp(email, otp);
      _session = result.$1;
      _currentUser = result.$2;
      return (success: true, errorMessage: null, attemptsRemaining: null);
    } on OtpFailure catch (f) {
      _error = f;
      final remaining = f.code?.startsWith('otp_invalid') == true
          ? _parseAttemptsRemaining(f.message)
          : null;
      return (
        success: false,
        errorMessage: f.message,
        attemptsRemaining: remaining,
      );
    } on Failure catch (f) {
      _error = f;
      return (success: false, errorMessage: f.message, attemptsRemaining: null);
    } finally {
      _isVerifyingOtp = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    await _secureStorage.deleteAll();
    _session = null;
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  void updateCurrentUser(UserEntity user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  bool _isGuest = false;
  bool get isGuest => _isGuest;

  void enterGuestMode() {
    _isGuest = true;
    _currentUser = const UserEntity(
      id: 'guest',
      email: '',
      displayName: 'Guest',
      preferredLanguage: 'en',
    );
    notifyListeners();
  }

  void exitGuestMode() {
    _isGuest = false;
    _currentUser = null;
    notifyListeners();
  }

  Future<void> refreshCurrentUser() async {
    final session = await _authRepository.restoreSession();
    if (session.$1 == null) return;
    _currentUser = session.$2 ?? _currentUser;
    notifyListeners();
  }

  int? _parseAttemptsRemaining(String message) {
    final match = RegExp(r'(\d+) attempt').firstMatch(message);
    if (match == null) return null;
    return int.tryParse(match.group(1) ?? '');
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
