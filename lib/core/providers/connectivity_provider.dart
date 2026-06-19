import 'dart:async';
import 'package:flutter/foundation.dart';

import '../services/connectivity_service.dart';

/// Exposes network connectivity state to the widget tree.
/// The offline banner in app.dart reads from this provider.
class ConnectivityProvider extends ChangeNotifier {
  ConnectivityProvider({required ConnectivityService connectivityService})
      : _service = connectivityService {
    _subscription = _service.connectivityStream.listen(_onConnectivityChanged);
    _isOnline = _service.isOnline;
  }

  final ConnectivityService _service;
  late final StreamSubscription<bool> _subscription;
  late bool _isOnline;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  void _onConnectivityChanged(bool isOnline) {
    if (_isOnline == isOnline) return;
    _isOnline = isOnline;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
