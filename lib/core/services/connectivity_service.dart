// import 'dart:async';
// import 'package:connectivity_plus/connectivity_plus.dart';

// import '../utils/app_logger.dart';

// /// Monitors network connectivity and exposes a debounced stream.
// ///
// /// Debounce (2s) prevents brief network flickers from toggling
// /// the offline state during room gameplay.
// class ConnectivityService {
//   ConnectivityService._() {
//     _init();
//   }

//   static final ConnectivityService _instance = ConnectivityService._();
//   static ConnectivityService get instance => _instance;

//   final _connectivity = Connectivity();
//   final _controller = StreamController<bool>.broadcast();

//   bool _isOnline = true;
//   Timer? _debounceTimer;

//   bool get isOnline => _isOnline;
//   bool get isOffline => !_isOnline;
//   Stream<bool> get connectivityStream => _controller.stream;

//   Future<void> _init() async {
//     // Get initial state
//     final result = await _connectivity.checkConnectivity();
//     _isOnline = _isConnected(result);

//     // Listen for changes
//     _connectivity.onConnectivityChanged.listen((result) {
//       final online = _isConnected(result);
//       if (online == _isOnline) return;

//       // Debounce: only emit after stable for 2 seconds
//       _debounceTimer?.cancel();
//       _debounceTimer = Timer(const Duration(seconds: 2), () {
//         _isOnline = online;
//         _controller.add(online);
//         AppLogger.info('Connectivity: ${online ? "online" : "offline"}');
//       });
//     });
//   }

//   bool _isConnected(List<ConnectivityResult> result) {
//     return result.any((r) =>
//         r == ConnectivityResult.mobile ||
//         r == ConnectivityResult.wifi ||
//         r == ConnectivityResult.ethernet);
//   }

//   void dispose() {
//     _debounceTimer?.cancel();
//     _controller.close();
//   }
// }

import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../utils/app_logger.dart';

/// Monitors network connectivity with an actual reachability check.
///
/// Problem on iOS: after app reload [connectivity_plus] briefly emits
/// [ConnectivityResult.none] before the OS settles, causing a false
/// "no internet" banner. Fix: debounce + verify with a real HTTP HEAD
/// request before declaring offline.
class ConnectivityService {
  ConnectivityService._() {
    _init();
  }

  static final ConnectivityService _instance = ConnectivityService._();
  static ConnectivityService get instance => _instance;

  final _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();

  bool _isOnline = true; // optimistic default
  Timer? _debounceTimer;
  bool _verifying = false;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  Stream<bool> get connectivityStream => _controller.stream;

  Future<void> _init() async {
    // Get initial state — verify immediately instead of trusting the plugin
    final initial = await _connectivity.checkConnectivity();
    if (_hasInterface(initial)) {
      // Has an interface; verify with a real request
      _isOnline = await _canReach();
    } else {
      _isOnline = false;
    }
    _controller.add(_isOnline);

    _connectivity.onConnectivityChanged.listen((result) {
      // Debounce: wait for the OS to settle (especially important on iOS)
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 3), () async {
        if (_verifying) return;
        _verifying = true;
        try {
          final online = _hasInterface(result) ? await _canReach() : false;
          if (online != _isOnline) {
            _isOnline = online;
            _controller.add(online);
            AppLogger.info('Connectivity: ${online ? "online" : "offline"}');
          }
        } finally {
          _verifying = false;
        }
      });
    });
  }

  /// Returns true if any usable interface is reported.
  bool _hasInterface(List<ConnectivityResult> result) {
    return result.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.other,
    ); // iOS vpn / hotspot
  }

  /// Verifies reachability with a lightweight HEAD request.
  /// Uses multiple fallbacks so one blocked host doesn't cause false offline.
  Future<bool> _canReach() async {
    const hosts = ['8.8.8.8', '1.1.1.1', '208.67.222.222'];
    for (final host in hosts) {
      try {
        final result = await InternetAddress.lookup(
          host,
        ).timeout(const Duration(seconds: 4));
        if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {
        continue;
      }
    }
    return false;
  }

  void dispose() {
    _debounceTimer?.cancel();
    _controller.close();
  }
}
