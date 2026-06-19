import 'dart:async';

/// Manages the countdown timer for a single Truth or Dare turn.
///
/// The timer is always started/stopped by the owner client and synced
/// via the `timer_started_at` epoch in the game state. Followers derive
/// remaining time from `timer_started_at` — no separate Broadcast needed.
///
/// Usage:
///   - Owner calls start() after a card is drawn
///   - Owner calls stop() on complete/skip
///   - Both owner and follower show visual countdown from the snapshot ts
class TodTimerService {
  TodTimerService._();
  static final TodTimerService _instance = TodTimerService._();
  static TodTimerService get instance => _instance;

  Timer?   _ticker;
  int      _durationSeconds = 0;
  int?     _startedAtMs;
  VoidCallback? _onExpired;
  void Function(int)? _onTick; // called every second with remaining seconds

  bool get isRunning => _ticker?.isActive ?? false;

  int get remainingSeconds {
    if (_startedAtMs == null) return _durationSeconds;
    final elapsed =
        (DateTime.now().millisecondsSinceEpoch - _startedAtMs!) ~/ 1000;
    return (_durationSeconds - elapsed).clamp(0, _durationSeconds);
  }

  double get progress {
    if (_durationSeconds <= 0) return 0;
    return 1 - (remainingSeconds / _durationSeconds);
  }

  // ── Owner: start timer ─────────────────────────────────────────────────────
  void start({
    required int durationSeconds,
    required int startedAtMs,     // from state.timerStartedAt
    required VoidCallback onExpired,
    void Function(int remainingSeconds)? onTick,
  }) {
    stop();
    _durationSeconds = durationSeconds;
    _startedAtMs     = startedAtMs;
    _onExpired       = onExpired;
    _onTick          = onTick;

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = remainingSeconds;
      _onTick?.call(remaining);
      if (remaining <= 0) {
        stop();
        _onExpired?.call();
      }
    });
  }

  // ── Follower: sync to owner's timer ───────────────────────────────────────
  /// Re-syncs when a broadcast snapshot with timer_started_at arrives.
  void syncFromSnapshot({
    required int durationSeconds,
    required int startedAtMs,
    void Function(int)? onTick,
  }) {
    stop();
    _durationSeconds = durationSeconds;
    _startedAtMs     = startedAtMs;
    _onTick          = onTick;

    if (remainingSeconds <= 0) return; // already expired in snapshot

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = remainingSeconds;
      _onTick?.call(remaining);
      if (remaining <= 0) stop();
    });
  }

  void stop() {
    _ticker?.cancel();
    _ticker = null;
  }

  void dispose() {
    stop();
    _onExpired = null;
    _onTick    = null;
  }
}

typedef VoidCallback = void Function();
