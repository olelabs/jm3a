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
import 'package:jma3a/core/services/notification_service.dart';
import 'package:jma3a/core/storage/secure_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show Session, AuthChangeEvent;

import '../errors/failures.dart';
import '../utils/app_logger.dart';
import '../router/app_router.dart';
import '../router/route_names.dart';
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
  bool _isSettingPassword = false;
  bool _isLoggingInWithPassword = false;
  bool _isChangingPassword = false;
  bool _isVerifyingCurrentPassword = false;
  bool _isCheckingIdentifier = false;

  // Separate from `_error` deliberately: `_error` is per-call transient
  // state that screens read off sendOtp()/verifyOtp()'s own return value,
  // not observed reactively — a dialog watching it globally would also
  // pop up for routine things like a mistyped OTP. This is the one
  // Failure type that must be shown globally regardless of which screen
  // is active (login-time, session-restore, or a live ban while already
  // inside the app all funnel through here) — see _AppShell.
  SuspendedFailure? _suspensionNotice;

  UserEntity? get currentUser => _currentUser;
  Session? get session => _session;
  bool get isInitializing => _isInitializing;
  bool get isLoggedIn => _session != null && _currentUser != null;
  bool get needsOnboarding =>
      isLoggedIn && !(_currentUser?.hasCompletedProfile ?? false);
  bool get isSendingOtp => _isSendingOtp;
  bool get isVerifyingOtp => _isVerifyingOtp;
  bool get isSettingPassword => _isSettingPassword;
  bool get isLoggingInWithPassword => _isLoggingInWithPassword;
  bool get isChangingPassword => _isChangingPassword;
  bool get isVerifyingCurrentPassword => _isVerifyingCurrentPassword;
  bool get isCheckingIdentifier => _isCheckingIdentifier;
  Failure? get error => _error;
  SuspendedFailure? get suspensionNotice => _suspensionNotice;

  void clearSuspensionNotice() {
    if (_suspensionNotice == null) return;
    _suspensionNotice = null;
    notifyListeners();
  }

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
    } on SuspendedFailure catch (f) {
      // Startup-time enforcement: restoreSession() already signed out
      // and cleared secure storage before throwing — this just records
      // the notice so _AppShell shows the correct temporary/permanent
      // message once the redirect (driven by isLoggedIn below) lands on
      // the auth flow.
      AppLogger.info('AuthProvider: session restore blocked — suspended');
      _suspensionNotice = f;
      _session = null;
      _currentUser = null;
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

  /// [pendingPassword], when supplied, is applied ATOMICALLY as part of
  /// this same call — verified OTP and the resulting password state are
  /// only ever committed and broadcast (via the single notifyListeners()
  /// in `finally`) together, as one consistent snapshot. This avoids ever
  /// notifying an intermediate "verified, password not applied yet"
  /// state that a naive "verify, then separately call setPassword from
  /// the screen" sequence would otherwise briefly produce.
  Future<({
    bool success,
    // True the moment the OTP itself is verified, independent of
    // [success] — lets the caller distinguish "the code was wrong/
    // expired" (otpVerified: false) from "the code was right, but
    // applying pendingPassword afterward failed" (otpVerified: true,
    // success: false). Conflating the two would misroute a plain wrong-
    // OTP retry as a password-application failure, or vice versa.
    bool otpVerified,
    String? errorMessage,
    int? attemptsRemaining,
    bool passwordApplied,
  })>
  verifyOtp(String email, String otp, {String? pendingPassword}) async {
    _isVerifyingOtp = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authRepository.verifyOtp(email, otp);
      var session = result.$1;
      var user = result.$2;

      if (pendingPassword != null) {
        try {
          // setPassword() revokes the session verifyOtp just established
          // (Supabase's own behavior on any password change) and returns
          // the freshly-minted replacement — that is the CURRENT valid
          // session from here on, not the one verifyOtp returned above.
          session = await _authRepository.setPassword(
            pendingPassword,
            pendingPassword,
          );
          user = user.copyWith(hasPassword: true);
        } on Failure catch (f) {
          if (user.hasPassword) {
            // Settings' Update Password flow: this account already had a
            // real, working password before this attempt — that
            // password is untouched. The OTP itself was still a valid
            // identity proof, so the session is worth keeping; just
            // surface the failure.
            _session = session;
            _currentUser = user;
            _error = f;
            return (
              success: false,
              otpVerified: true,
              errorMessage: f.message,
              attemptsRemaining: null,
              passwordApplied: false,
            );
          }
          // Brand-new signup that verified OTP but couldn't finish
          // establishing a password — per the product requirement, this
          // must never leave the router observing "authenticated, no
          // password" for an account that can't complete signup. Roll
          // back the session entirely rather than continuing into
          // onboarding with no password.
          try {
            await _authRepository.signOut();
          } catch (_) {
            // Best-effort — session is being discarded either way below.
          }
          _session = null;
          _currentUser = null;
          _error = f;
          return (
            success: false,
            otpVerified: true,
            errorMessage: f.message,
            attemptsRemaining: null,
            passwordApplied: false,
          );
        }
      }

      _session = session;
      _currentUser = user;
      return (
        success: true,
        otpVerified: true,
        errorMessage: null,
        attemptsRemaining: null,
        passwordApplied: pendingPassword != null,
      );
    } on OtpFailure catch (f) {
      _error = f;
      final remaining = f.code?.startsWith('otp_invalid') == true
          ? _parseAttemptsRemaining(f.message)
          : null;
      return (
        success: false,
        otpVerified: false,
        errorMessage: f.message,
        attemptsRemaining: remaining,
        passwordApplied: false,
      );
    } on Failure catch (f) {
      _error = f;
      // Login-time enforcement — verifyOtp() already undid the
      // just-established Supabase session before throwing, so there's
      // nothing further to sign out here; just record the notice so
      // _AppShell shows the correct message. errorMessage below is still
      // returned as a plain-English fallback in case the dialog is
      // somehow slower to appear than this screen's own error display.
      if (f is SuspendedFailure) _suspensionNotice = f;
      return (
        success: false,
        otpVerified: false,
        errorMessage: f.message,
        attemptsRemaining: null,
        passwordApplied: false,
      );
    } finally {
      _isVerifyingOtp = false;
      notifyListeners();
    }
  }

  /// Mandatory first-time password setup, and the final step of password
  /// recovery, both funnel through here — either way the caller already
  /// holds a valid session (from verifyOtp) and is just establishing/
  /// replacing the password on that same account.
  ///
  /// Setting the password revokes the session the caller authenticated
  /// with (see AuthRepository.setPassword's own doc) — the fresh one it
  /// returns is adopted into [_session] here so the very next
  /// authenticated action (e.g. onboarding's own API calls, right after
  /// this returns) is backed by a valid token, not a dead one.
  Future<({bool success, String? errorMessage})> setPassword(
    String password,
    String confirmation,
  ) async {
    _isSettingPassword = true;
    _error = null;
    notifyListeners();

    try {
      _session = await _authRepository.setPassword(password, confirmation);
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(hasPassword: true);
      }
      return (success: true, errorMessage: null);
    } on Failure catch (f) {
      _error = f;
      return (success: false, errorMessage: f.message);
    } finally {
      _isSettingPassword = false;
      notifyListeners();
    }
  }

  /// `code` lets the login screen distinguish a legacy no-password
  /// account (`password_not_set`) from a plain wrong password
  /// (`invalid_credentials`) — the backend deliberately returns a
  /// different code for each (see authService.loginWithPassword) so the
  /// UI can point at Forgot password instead of a dead-end error.
  Future<({bool success, String? errorMessage, String? code})>
  loginWithPassword(String identifier, String password) async {
    _isLoggingInWithPassword = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authRepository.loginWithPassword(
        identifier,
        password,
      );
      _session = result.$1;
      _currentUser = result.$2;
      return (success: true, errorMessage: null, code: null);
    } on Failure catch (f) {
      _error = f;
      if (f is SuspendedFailure) _suspensionNotice = f;
      return (success: false, errorMessage: f.message, code: f.code);
    } finally {
      _isLoggingInWithPassword = false;
      notifyListeners();
    }
  }

  /// Settings-screen password change for an already password-ready
  /// account — see AuthRepository.changePassword for why this requires
  /// the current password rather than trusting the session alone.
  Future<({bool success, String? errorMessage})> changePassword(
    String currentPassword,
    String newPassword,
    String confirmation,
  ) async {
    _isChangingPassword = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.changePassword(
        currentPassword,
        newPassword,
        confirmation,
      );
      return (success: true, errorMessage: null);
    } on Failure catch (f) {
      _error = f;
      return (success: false, errorMessage: f.message);
    } finally {
      _isChangingPassword = false;
      notifyListeners();
    }
  }

  /// Update Password flow, step 1 — see AuthRepository.verifyCurrentPassword.
  /// No state mutation on success; the caller (the Settings screen) is
  /// what decides to reveal the new-password fields.
  Future<({bool success, String? errorMessage})> verifyCurrentPassword(
    String currentPassword,
  ) async {
    _isVerifyingCurrentPassword = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.verifyCurrentPassword(currentPassword);
      return (success: true, errorMessage: null);
    } on Failure catch (f) {
      _error = f;
      return (success: false, errorMessage: f.message);
    } finally {
      _isVerifyingCurrentPassword = false;
      notifyListeners();
    }
  }

  /// Signup existence check — see AuthRepository.checkIdentifierExists.
  Future<({bool success, bool exists, String? errorMessage})>
  checkIdentifierExists(String identifier) async {
    _isCheckingIdentifier = true;
    _error = null;
    notifyListeners();

    try {
      final exists = await _authRepository.checkIdentifierExists(identifier);
      return (success: true, exists: exists, errorMessage: null);
    } on Failure catch (f) {
      _error = f;
      return (success: false, exists: false, errorMessage: f.message);
    } finally {
      _isCheckingIdentifier = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    // Dissociates this device from OneSignal's external_id BEFORE the
    // actual sign-out — otherwise, if the device signs in as a different
    // account afterward without this call, it stays associated with the
    // previous user and could keep receiving/showing their pushes.
    // Previously missing entirely (dead code existed in
    // NotificationService.logout() but nothing called it).
    NotificationService.instance.logout();
    await _authRepository.signOut();
    await _secureStorage.deleteAll();
    _session = null;
    _currentUser = null;
    _error = null;
    _suspensionNotice = null;
    notifyListeners();
    _navigateToLoginReliably();
  }

  /// Router redirect bug fix: GoRouter's `refreshListenable` reliably
  /// re-runs `redirect` when this notifies, but a REFRESH alone (no
  /// accompanying navigation attempt to a new location) does not always
  /// get its computed result committed to the displayed page — confirmed
  /// by direct reproduction: after signOut() cleared all state and
  /// called notifyListeners(), the router's own redirect callback WAS
  /// invoked and correctly computed `/auth/login`, but the UI stayed on
  /// whatever screen was showing (e.g. Set Password) until an explicit
  /// `router.go(...)` call was made. Every other place in this codebase
  /// that changes app state already pairs it with an explicit
  /// AppRouter.router call (see e.g. settings_screen.dart's own sign-out
  /// button) — this makes signOut() reliable on its own, regardless of
  /// which caller invokes it (including handleAccountSuspended(), which
  /// previously had no explicit navigation at all).
  ///
  /// Guarded by AppRouter.isReady: signOut() can in principle run before
  /// the router exists (e.g. a startup-time SuspendedFailure), in which
  /// case there is no stale screen to correct — the router's own
  /// initial-splash redirect logic already lands on the right place.
  void _navigateToLoginReliably() {
    if (!AppRouter.isReady) return;
    AppRouter.router.go(RouteNames.authPasswordLogin);
  }

  /// Called when a moderation action bans/suspends the CURRENT user while
  /// they're already inside the app (see ProfileProvider's own-profile
  /// realtime subscription, which detects the profiles row UPDATE and
  /// calls this). Reuses signOut() for the actual teardown rather than
  /// duplicating it, then layers the notice on top so _AppShell shows the
  /// message immediately — the router's redirect guard reacts to
  /// isLoggedIn becoming false on its own (refreshListenable: this).
  Future<void> handleAccountSuspended(SuspendedFailure failure) async {
    if (!isLoggedIn) return;
    await signOut();
    _suspensionNotice = failure;
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
    try {
      final session = await _authRepository.restoreSession();
      if (session.$1 == null) return;
      _currentUser = session.$2 ?? _currentUser;
      notifyListeners();
    } on SuspendedFailure catch (f) {
      _suspensionNotice = f;
      _session = null;
      _currentUser = null;
      notifyListeners();
    }
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
