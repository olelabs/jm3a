import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/services/realtime_service.dart';
import '../../../core/utils/app_logger.dart';
import '../engine/base_game_engine.dart';
import '../engine/game_registry.dart';

/// Bridges the pure-Dart game engine with Flutter's Provider system.
///
/// Owner mode: runs engine, handles events, broadcasts state.
/// Follower mode: receives broadcasts, calls restoreFromSnapshot.
///
/// Created by the room owner when they press "Start Game".
/// Scoped to the game session — disposed when game ends or room is left.
class GameProvider extends ChangeNotifier {
  GameProvider({
    required RealtimeService realtimeService,
    required String currentUserId,
  }) : _realtime = realtimeService,
       _currentUserId = currentUserId;

  final RealtimeService _realtime;
  final String _currentUserId;

  BaseGameEngine? _engine;
  String? _roomId;
  bool _isOwner = false;
  bool _isInitialized = false;

  // Track if we've received initial sync (for follower mode)
  bool _hasSyncedState = false;
  Timer? _syncTimeoutTimer;

  // ── Getters ───────────────────────────────────────────────────────────────
  GameEngineState? get state => _engine?.currentState;
  bool get isOwner => _isOwner;
  bool get isInitialized => _isInitialized;
  bool get hasSyncedState => _hasSyncedState;
  bool get isGameOver => _engine?.isGameOver ?? false;

  // ── Initialize game ───────────────────────────────────────────────────────
  void initGame({
    required GameType type,
    required GameConfig config,
    required String roomId,
    required bool isOwner,
    required List<String> playerOrder,
  }) {
    final factory = gameRegistry[type];
    if (factory == null) {
      AppLogger.error('GameProvider: no engine registered for $type');
      return;
    }

    _engine = factory(config, []);
    _roomId = roomId;
    _isOwner = isOwner;
    _isInitialized = true;

    if (isOwner) {
      // Owner initializes the engine with player order and broadcasts first state
      _broadcastCurrentState();
    } else {
      // Follower: wait for sync from owner
      _hasSyncedState = false;
      _startSyncTimeout();
    }

    notifyListeners();
    AppLogger.info(
      'GameProvider: initialized ${type.displayName} — isOwner=$isOwner',
    );
  }

  // ── Owner: handle player action ───────────────────────────────────────────
  void handlePlayerEvent(GameEngineEvent event) {
    if (!_isOwner || _engine == null) return;

    _engine!.handleEvent(event);
    _broadcastCurrentState();
    notifyListeners();
  }

  void advanceTurn() {
    if (!_isOwner || _engine == null) return;

    _engine!.advanceTurn();
    _broadcastCurrentState();
    notifyListeners();

    if (_engine!.isGameOver) {
      AppLogger.info('GameProvider: game over');
    }
  }

  // ── Follower: receive state broadcast ─────────────────────────────────────
  /// Called by RoomProvider when a game_state broadcast arrives.
  void onStateBroadcast(Map<String, dynamic> payload) {
    if (_isOwner || _engine == null) return;

    final senderId = payload['sender_id'] as String?;
    final snapshot = payload['snapshot'] as Map<String, dynamic>?;

    if (snapshot == null) return;

    // Stale broadcast guard: discard if this snapshot is older than current
    final incomingTs = snapshot['snapshot_at'] as int? ?? 0;
    final currentTs = _engine!.currentState.snapshotAt;
    if (incomingTs <= currentTs && _hasSyncedState) {
      AppLogger.debug(
        'GameProvider: discarding stale broadcast (ts=$incomingTs <= $currentTs)',
      );
      return;
    }

    _engine!.restoreFromSnapshot(snapshot);
    _hasSyncedState = true;
    _syncTimeoutTimer?.cancel();
    notifyListeners();
  }

  // ── Owner: respond to sync request ────────────────────────────────────────
  /// Called when a player requests full state sync (rejoin/reconnect).
  void onSyncRequest(Map<String, dynamic> payload) {
    if (!_isOwner) return;
    AppLogger.info('GameProvider: received sync_request, broadcasting state');
    _broadcastCurrentState();
  }

  // ── Broadcast ─────────────────────────────────────────────────────────────
  void _broadcastCurrentState() {
    if (!_isOwner || _engine == null || _roomId == null) return;

    final snapshot = _engine!.serializeState();
    _realtime.broadcastGameState(_roomId!, snapshot, _currentUserId);
  }

  // ── Sync timeout (follower) ────────────────────────────────────────────────
  /// If no state received within 5s, fall back to DB snapshot.
  void _startSyncTimeout() {
    _syncTimeoutTimer?.cancel();
    _syncTimeoutTimer = Timer(const Duration(seconds: 5), () {
      if (!_hasSyncedState) {
        AppLogger.warning(
          'GameProvider: sync timeout — falling back to DB snapshot',
        );
        // TODO: fetch game_sessions.state_snapshot from DB
        _hasSyncedState = true;
        notifyListeners();
      }
    });
  }

  // ── Game actions (send as player_action broadcasts) ───────────────────────
  Future<void> sendAction(Map<String, dynamic> action) async {
    if (_roomId == null) return;
    await _realtime.broadcastPlayerAction(_roomId!, {
      ...action,
      'user_id': _currentUserId,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> submitVote(int value, String turnId) => sendAction({
    'action': 'vote',
    'vote_value': value,
    'target_turn_id': turnId,
  });

  Future<void> completeTurn({String? result}) =>
      sendAction({'action': 'turn_complete', 'turn_result': result});

  Future<void> skipTurn() => sendAction({'action': 'skip'});

  Future<void> submitMeme(String content) =>
      sendAction({'action': 'submit_meme', 'content': content});

  @override
  void dispose() {
    _syncTimeoutTimer?.cancel();
    super.dispose();
  }
}
