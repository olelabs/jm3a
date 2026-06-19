// import 'package:flutter/foundation.dart';

// import '../errors/failures.dart';

// /// Base class for all feature-level ChangeNotifier providers.
// ///
// /// Provides uniform loading/error state management and lifecycle hooks.
// /// Every feature provider should extend this.
// ///
// /// Usage:
// /// ```dart
// /// class PackProvider extends BaseProvider {
// ///   Future<void> loadPacks() => runAsync(() async {
// ///     _packs = await _repository.getPacks();
// ///   });
// /// }
// /// ```
// abstract class BaseProvider extends ChangeNotifier {
//   // ── Loading state ────────────────────────────────────────────────────
//   bool _isLoading = false;
//   bool get isLoading => _isLoading;

//   // ── Error state ───────────────────────────────────────────────────────
//   Failure? _failure;
//   Failure? get failure => _failure;
//   bool get hasError => _failure != null;

//   // ── Auth lifecycle hook ───────────────────────────────────────────────
//   String? _currentUserId;
//   String? get currentUserId => _currentUserId;

//   /// Called by ProxyProvider when auth state changes.
//   /// Override to trigger feature-specific initialization / cleanup.
//   void onAuthChanged(String? userId) {
//     if (_currentUserId == userId) return;
//     _currentUserId = userId;

//     if (userId != null) {
//       onUserLoggedIn(userId);
//     } else {
//       onUserLoggedOut();
//     }
//   }

//   /// Override to hydrate feature data after login.
//   @protected
//   void onUserLoggedIn(String userId) {}

//   /// Override to clear feature data after logout.
//   @protected
//   void onUserLoggedOut() {
//     _failure = null;
//     _isLoading = false;
//     notifyListeners();
//   }

//   // ── Async operation runner ────────────────────────────────────────────
//   /// Runs an async operation with automatic loading/error state management.
//   ///
//   /// [throwOnFailure]: if true, re-throws the Failure after setting state.
//   @protected
//   Future<T?> runAsync<T>(
//     Future<T> Function() operation, {
//     bool throwOnFailure = false,
//     bool setLoading = true,
//   }) async {
//     if (setLoading) {
//       _isLoading = true;
//       _failure = null;
//       notifyListeners();
//     }

//     try {
//       final result = await operation();
//       return result;
//     } on Failure catch (f) {
//       _failure = f;
//       notifyListeners();
//       if (throwOnFailure) rethrow;
//       return null;
//     } finally {
//       if (setLoading) {
//         _isLoading = false;
//         notifyListeners();
//       }
//     }
//   }

//   void clearError() {
//     if (_failure == null) return;
//     _failure = null;
//     notifyListeners();
//   }

//   void setLoading(bool loading) {
//     if (_isLoading == loading) return;
//     _isLoading = loading;
//     notifyListeners();
//   }

//   @protected
//   void setFailure(Failure? failure) {
//     _failure = failure;
//     notifyListeners();
//   }
// }

import 'package:flutter/foundation.dart';

import '../errors/failures.dart';

/// Base class for all feature-level ChangeNotifier providers.
///
/// Provides uniform loading/error state management and lifecycle hooks.
/// Every feature provider should extend this.
///
/// Usage:
/// ```dart
/// class PackProvider extends BaseProvider {
///   Future<void> loadPacks() => runAsync(() async {
///     _packs = await _repository.getPacks();
///   });
/// }
/// ```
abstract class BaseProvider extends ChangeNotifier {
  // ── Loading state ────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ── Error state ───────────────────────────────────────────────────────
  Failure? _failure;
  Failure? get failure => _failure;
  bool get hasError => _failure != null;

  // ── Auth lifecycle hook ───────────────────────────────────────────────
  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  /// Called by ProxyProvider when auth state changes.
  /// Override to trigger feature-specific initialization / cleanup.
  void onAuthChanged(String? userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;

    // 'guest' is not a real user — don't fire logged-in hooks
    if (userId != null && userId != 'guest') {
      onUserLoggedIn(userId);
    } else {
      onUserLoggedOut();
    }
  }

  /// Override to hydrate feature data after login.
  @protected
  void onUserLoggedIn(String userId) {}

  /// Override to clear feature data after logout.
  @protected
  void onUserLoggedOut() {
    _failure = null;
    _isLoading = false;
    notifyListeners();
  }

  // ── Async operation runner ────────────────────────────────────────────
  /// Runs an async operation with automatic loading/error state management.
  ///
  /// [throwOnFailure]: if true, re-throws the Failure after setting state.
  @protected
  Future<T?> runAsync<T>(
    Future<T> Function() operation, {
    bool throwOnFailure = false,
    bool setLoading = true,
  }) async {
    if (setLoading) {
      _isLoading = true;
      _failure = null;
      notifyListeners();
    }

    try {
      final result = await operation();
      return result;
    } on Failure catch (f) {
      _failure = f;
      notifyListeners();
      if (throwOnFailure) rethrow;
      return null;
    } finally {
      if (setLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void clearError() {
    if (_failure == null) return;
    _failure = null;
    notifyListeners();
  }

  void setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    notifyListeners();
  }

  @protected
  void setFailure(Failure? failure) {
    _failure = failure;
    notifyListeners();
  }
}
