// // // import 'dart:async';

// // // import 'package:flutter/foundation.dart';
// // // import 'package:uuid/uuid.dart';

// // // import '../../../core/errors/failures.dart';
// // // import '../../../core/services/realtime_service.dart';
// // // import '../../../core/utils/app_logger.dart';
// // // import '../engine/base_game_engine.dart';
// // // import 'data/tod_repository.dart';
// // // import 'domain/tod_models.dart';
// // // import 'tod_timer_service.dart';
// // // import 'truth_or_dare_engine.dart';

// // // const _uuid = Uuid();

// // // enum TodLoadState { idle, loading, ready, error, gameOver }

// // // /// Bridges TruthOrDareEngine ↔ Flutter UI.
// // // ///
// // // /// Owner mode  : runs engine, processes all player_action events, broadcasts state.
// // // /// Follower mode: receives game_state broadcasts, restores from snapshot.
// // // ///
// // // /// Realtime flow (single room channel — shared with RoomProvider):
// // // ///   Owner  → game_state  (after every engine mutation)
// // // ///   Any    → player_action (choice, complete, skip, vote, etc.)
// // // ///   Owner  → processes player_action and re-broadcasts updated state
// // // ///   Rejoiner → sync_request → owner responds with broadcastState()
// // // ///
// // // /// Hookup: call onStateBroadcast/onPlayerAction/onSyncRequest from
// // // ///   the screen that owns this provider (TodGameScreen) — these are
// // // ///   forwarded from RealtimeService callbacks set up by RoomProvider.
// // // class TodGameProvider extends ChangeNotifier {
// // //   TodGameProvider({
// // //     required RealtimeService realtimeService,
// // //     required TodRepository repository,
// // //     required String currentUserId,
// // //     required String currentDisplayName,
// // //     this.isModerator = false,
// // //   }) : _realtime = realtimeService,
// // //        _repo = repository,
// // //        _userId = currentUserId,
// // //        _displayName = currentDisplayName;

// // //   final RealtimeService _realtime;
// // //   final TodRepository _repo;
// // //   final String _userId;
// // //   final String _displayName;
// // //   final bool isModerator;

// // //   // ── Session state ──────────────────────────────────────────────────────────
// // //   TruthOrDareEngine? _engine;
// // //   TodState? _state;
// // //   GameConfig? _config;
// // //   String? _roomId;
// // //   String? _sessionId;
// // //   bool _isOwner = false;
// // //   TodLoadState _loadState = TodLoadState.idle;
// // //   String? _error;
// // //   bool _hasSyncedState = false;
// // //   Timer? _syncTimeoutTimer;

// // //   // Player display names (resolved when game starts)
// // //   final _displayNames = <String, String>{};

// // //   // ── Timer ──────────────────────────────────────────────────────────────────
// // //   int _timerRemaining = 0;
// // //   bool _timerIsRunning = false;
// // //   Timer? _timerTicker;
// // //   Timer? _snapshotThrottle;

// // //   // ── Getters ────────────────────────────────────────────────────────────────
// // //   TodState? get state => _state;
// // //   TodLoadState get loadState => _loadState;
// // //   String? get error => _error;
// // //   bool get isOwner => _isOwner;
// // //   String get currentUserId => _userId;
// // //   bool get isReady => _loadState == TodLoadState.ready;
// // //   bool get hasSyncedState => _hasSyncedState;
// // //   int get timerRemaining => _timerRemaining;
// // //   bool get timerIsRunning => _timerIsRunning;
// // //   String? get sessionId => _sessionId;

// // //   bool get isMyTurn => _state?.currentPlayerId == _userId;
// // //   bool get canModerate => _isOwner || isModerator;
// // //   bool get isPunishmentPhase => _state?.phase == TodTurnPhase.punishmentVoting;
// // //   bool get isWaitingForChoice => _state?.phase == TodTurnPhase.choosingType;
// // //   bool get hasVotedOnPunishment {
// // //     final v = _state?.currentPunishmentVote;
// // //     return v?.votes.containsKey(_userId) ?? false;
// // //   }

// // //   /// Display name for any player in the game.
// // //   String displayNameFor(String userId) =>
// // //       _displayNames[userId] ?? 'Player ${userId.substring(0, 4)}';

// // //   // ── Owner: initialize ────────────────────────────────────────────────────
// // //   Future<void> initAsOwner({
// // //     required String roomId,
// // //     required GameConfig config,
// // //     required List<String> playerIds,
// // //     required Map<String, String> playerDisplayNames, // userId → displayName
// // //     required String packId,
// // //   }) async {
// // //     _setLoading();
// // //     _roomId = roomId;
// // //     _config = config;
// // //     _isOwner = true;
// // //     _displayNames.addAll(playerDisplayNames);

// // //     try {
// // //       // 1. Load cards — cache first, remote fallback
// // //       var cards = await _repo.loadCardsFromCache(
// // //         packId: packId,
// // //         language: config.language,
// // //         allowSpicy: config.allowSpicy,
// // //       );
// // //       if (cards.isEmpty) {
// // //         cards = await _repo.loadCards(
// // //           packId: packId,
// // //           language: config.language,
// // //           allowSpicy: config.allowSpicy,
// // //         );
// // //       }
// // //       if (cards.isEmpty) {
// // //         _setError(
// // //           'No cards found for this pack. Please select a different pack.',
// // //         );
// // //         return;
// // //       }

// // //       // 2. Build and initialise engine
// // //       _engine = TruthOrDareEngine(config, cards: cards);
// // //       _engine!.init(playerOrder: playerIds);
// // //       _state = _engine!.currentState as TodState;

// // //       // 3. Persist session row
// // //       _sessionId = await _repo.createSession(
// // //         roomId: roomId,
// // //         packId: packId,
// // //         config: config,
// // //         playerIds: playerIds,
// // //         ownerId: _userId,
// // //       );

// // //       // 4. Broadcast initial snapshot to all followers
// // //       await _broadcastState();

// // //       // 5. Lazy DB snapshot every 10s
// // //       _startSnapshotThrottle();

// // //       _loadState = TodLoadState.ready;
// // //       notifyListeners();
// // //     } catch (e, st) {
// // //       AppLogger.error(
// // //         'TodGameProvider: initAsOwner failed',
// // //         error: e,
// // //         stackTrace: st,
// // //       );
// // //       _setError(e is Failure ? e.message : e.toString());
// // //     }
// // //   }

// // //   // ── Follower: connect ──────────────────────────────────────────────────────
// // //   void initAsFollower({
// // //     required String roomId,
// // //     required GameConfig config,
// // //     String? sessionId,
// // //   }) {
// // //     _roomId = roomId;
// // //     _config = config;
// // //     _sessionId = sessionId;
// // //     _isOwner = false;
// // //     _loadState = TodLoadState.loading;

// // //     // Wait up to 8 seconds for owner broadcast; fallback to DB snapshot
// // //     _syncTimeoutTimer?.cancel();
// // //     _syncTimeoutTimer = Timer(const Duration(seconds: 8), () async {
// // //       if (!_hasSyncedState) {
// // //         AppLogger.warning('TodGameProvider: sync timeout — loading from DB');
// // //         await _tryLoadSnapshotFromDb();
// // //       }
// // //     });
// // //     notifyListeners();
// // //   }

// // //   // ── Broadcast receive (wired from TodGameScreen) ──────────────────────────

// // //   /// Called by TodGameScreen when a game_state broadcast arrives.
// // //   void onStateBroadcast(Map<String, dynamic> payload) {
// // //     final snapshot = payload['snapshot'] as Map<String, dynamic>?;
// // //     if (snapshot == null) return;

// // //     final incomingTs = snapshot['snapshot_at'] as int? ?? 0;
// // //     final currentTs = _state?.snapshotAt ?? 0;

// // //     // Discard stale broadcasts (already-seen or older snapshots)
// // //     if (incomingTs <= currentTs && _hasSyncedState) {
// // //       AppLogger.debug(
// // //         'TodGameProvider: stale broadcast ts=$incomingTs discarded',
// // //       );
// // //       return;
// // //     }

// // //     _state = TodState.fromMap(snapshot);
// // //     _hasSyncedState = true;
// // //     _syncTimeoutTimer?.cancel();
// // //     _loadState = _state!.isOver ? TodLoadState.gameOver : TodLoadState.ready;

// // //     _syncTimer();
// // //     notifyListeners();
// // //   }

// // //   /// Called by TodGameScreen when a player_action broadcast arrives (owner only).
// // //   void onPlayerAction(Map<String, dynamic> payload) {
// // //     if (!_isOwner || _engine == null) return;

// // //     final event = _parseEvent(payload);
// // //     if (event == null) {
// // //       AppLogger.warning('TodGameProvider: unknown action ${payload["action"]}');
// // //       return;
// // //     }

// // //     _engine!.handleEvent(event);
// // //     _state = _engine!.currentState as TodState;
// // //     _syncTimer();
// // //     _broadcastState();
// // //     notifyListeners();

// // //     if (_engine!.isGameOver) _handleGameOver();
// // //   }

// // //   /// Called by TodGameScreen when a sync_request broadcast arrives.
// // //   void onSyncRequest(Map<String, dynamic> payload) {
// // //     if (!_isOwner) return;
// // //     AppLogger.info(
// // //       'TodGameProvider: sync requested by ${payload["requester_id"]}',
// // //     );
// // //     _broadcastState();
// // //   }

// // //   // ── Player actions ─────────────────────────────────────────────────────────

// // //   Future<void> chooseTruth() => _handleAction({
// // //     'action': 'tod_choice',
// // //     'card_type': TodCardType.truth.name,
// // //   });

// // //   Future<void> chooseDare() => _handleAction({
// // //     'action': 'tod_choice',
// // //     'card_type': TodCardType.dare.name,
// // //   });

// // //   Future<void> completeTurn({
// // //     String response = '',
// // //     String proofImageB64 = '',
// // //   }) => _handleAction({
// // //     'action': 'tod_complete',
// // //     'response': response,
// // //     'proof_image': proofImageB64,
// // //   });

// // //   Future<void> reactToResponse(String emoji) =>
// // //       _handleAction({'action': 'tod_react', 'emoji': emoji});

// // //   Future<void> voteForResponse() =>
// // //       _handleAction({'action': 'tod_vote_response'});

// // //   Future<void> skipTurn() => _handleAction({'action': 'tod_skip'});

// // //   Future<void> voteOnPunishment(TodPunishmentVote vote) =>
// // //       _sendAction({'action': 'tod_vote_punishment', 'vote': vote.name});

// // //   Future<void> proposePunishment(String text) => _sendAction({
// // //     'action': 'tod_propose_punishment',
// // //     'punishment': TodPunishment(
// // //       id: _uuid.v4(),
// // //       text: text,
// // //       proposedBy: _userId,
// // //       proposedAt: DateTime.now().millisecondsSinceEpoch,
// // //     ).toMap(),
// // //   });

// // //   // ── Moderator actions ──────────────────────────────────────────────────────

// // //   Future<void> overridePunishment(
// // //     TodPunishmentVote decision, {
// // //     String? replacementText,
// // //   }) {
// // //     if (!canModerate) return Future.value();
// // //     return _sendAction({
// // //       'action': 'tod_moderator_override',
// // //       'decision': decision.name,
// // //       'replacement_text': replacementText,
// // //     });
// // //   }

// // //   /// Owner: advance to the next turn directly (bypasses phase checks).
// // //   Future<void> ownerAdvanceTurn() async {
// // //     if (!_isOwner || _engine == null) return;
// // //     _engine!.advanceTurn();
// // //     _state = _engine!.currentState as TodState;
// // //     _syncTimer();
// // //     _broadcastState();
// // //     notifyListeners();
// // //     if (_engine!.isGameOver) _handleGameOver();
// // //   }

// // //   Future<void> endGame({String reason = 'manual'}) =>
// // //       _sendAction({'action': 'tod_end_game', 'reason': reason});

// // //   // ── Timer sync ─────────────────────────────────────────────────────────────
// // //   void _syncTimer() {
// // //     _timerTicker?.cancel();
// // //     final s = _state;
// // //     if (s == null) return;

// // //     final timerEnabled =
// // //         s.phase == TodTurnPhase.readingCard &&
// // //         s.timerStartedAt != null &&
// // //         (_config?.timerEnabled ?? false);

// // //     if (!timerEnabled) {
// // //       _timerRemaining = 0;
// // //       _timerIsRunning = false;
// // //       return;
// // //     }

// // //     final elapsed =
// // //         (DateTime.now().millisecondsSinceEpoch - s.timerStartedAt!) ~/ 1000;
// // //     _timerRemaining = (_config!.turnTimerSeconds - elapsed).clamp(
// // //       0,
// // //       _config!.turnTimerSeconds,
// // //     );
// // //     _timerIsRunning = _timerRemaining > 0;

// // //     if (!_timerIsRunning) return;

// // //     _timerTicker = Timer.periodic(const Duration(seconds: 1), (_) {
// // //       if (_timerRemaining > 0) {
// // //         _timerRemaining--;
// // //         notifyListeners();
// // //       }
// // //       if (_timerRemaining <= 0) {
// // //         _timerTicker?.cancel();
// // //         _timerIsRunning = false;

// // //         // Owner fires the timer expired event
// // //         if (_isOwner && _state?.currentPlayerId != null) {
// // //           _engine?.handleEvent(
// // //             TodTimerExpiredEvent(
// // //               userId: _state!.currentPlayerId,
// // //               ts: DateTime.now().millisecondsSinceEpoch,
// // //             ),
// // //           );
// // //           _state = _engine?.currentState as TodState?;
// // //           _broadcastState();
// // //           notifyListeners();
// // //         }
// // //       }
// // //     });
// // //   }

// // //   // ── Snapshot throttle ──────────────────────────────────────────────────────
// // //   void _startSnapshotThrottle() {
// // //     _snapshotThrottle?.cancel();
// // //     _snapshotThrottle = Timer.periodic(const Duration(seconds: 10), (_) {
// // //       if (_sessionId != null && _state != null && _isOwner) {
// // //         _repo
// // //             .saveSnapshot(sessionId: _sessionId!, snapshot: _state!.toMap())
// // //             .ignore();
// // //       }
// // //     });
// // //   }

// // //   // ── Internal ───────────────────────────────────────────────────────────────
// // //   Future<void> _handleAction(Map<String, dynamic> action) async {
// // //     final full = {
// // //       ...action,
// // //       'user_id': _userId,
// // //       'display_name': _displayName,
// // //       'ts': DateTime.now().millisecondsSinceEpoch,
// // //     };
// // //     // If this client is the owner/engine, process the event locally immediately.
// // //     // (Broadcasts with self:false never come back to the sender.)
// // //     if (_isOwner && _engine != null) {
// // //       onPlayerAction(full); // processes + broadcasts state to followers
// // //     } else {
// // //       // Follower — just broadcast the action for the owner to process
// // //       await _sendAction(action);
// // //     }
// // //   }

// // //   Future<void> _sendAction(Map<String, dynamic> action) async {
// // //     if (_roomId == null) return;
// // //     await _realtime.broadcastPlayerAction(_roomId!, {
// // //       ...action,
// // //       'user_id': _userId,
// // //       'display_name': _displayName,
// // //       'ts': DateTime.now().millisecondsSinceEpoch,
// // //     });
// // //   }

// // //   Future<void> _broadcastState() async {
// // //     if (_roomId == null || _state == null) return;
// // //     await _realtime.broadcastGameState(_roomId!, _state!.toMap(), _userId);
// // //   }

// // //   GameEngineEvent? _parseEvent(Map<String, dynamic> p) {
// // //     final action = p['action'] as String? ?? '';
// // //     final userId = p['user_id'] as String? ?? '';
// // //     final ts = p['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch;

// // //     return switch (action) {
// // //       'tod_choice' => TodChoiceEvent(
// // //         userId: userId,
// // //         ts: ts,
// // //         cardType: TodCardType.values.firstWhere(
// // //           (t) => t.name == p['card_type'],
// // //           orElse: () => TodCardType.truth,
// // //         ),
// // //       ),
// // //       'tod_complete' => TodCompleteEvent(
// // //         userId: userId,
// // //         ts: ts,
// // //         response: p['response'] as String? ?? '',
// // //         proofImageB64: p['proof_image'] as String? ?? '',
// // //       ),
// // //       'tod_react' => TodReactEvent(
// // //         userId: userId,
// // //         ts: ts,
// // //         emoji: p['emoji'] as String? ?? '👍',
// // //       ),
// // //       'tod_vote_response' => TodVoteResponseEvent(userId: userId, ts: ts),
// // //       'tod_skip' => TodSkipEvent(userId: userId, ts: ts),
// // //       'tod_vote_punishment' => TodVotePunishmentEvent(
// // //         userId: userId,
// // //         ts: ts,
// // //         vote: TodPunishmentVote.values.firstWhere(
// // //           (v) => v.name == p['vote'],
// // //           orElse: () => TodPunishmentVote.doIt,
// // //         ),
// // //       ),
// // //       'tod_propose_punishment' => TodProposePunishmentEvent(
// // //         userId: userId,
// // //         ts: ts,
// // //         punishment: TodPunishment.fromMap(
// // //           p['punishment'] as Map<String, dynamic>,
// // //         ),
// // //       ),
// // //       'tod_moderator_override' => TodModeratorOverrideEvent(
// // //         userId: userId,
// // //         ts: ts,
// // //         decision: TodPunishmentVote.values.firstWhere(
// // //           (v) => v.name == p['decision'],
// // //           orElse: () => TodPunishmentVote.doIt,
// // //         ),
// // //         replacementText: p['replacement_text'] as String?,
// // //       ),
// // //       'tod_end_game' => TodEndGameEvent(
// // //         userId: userId,
// // //         ts: ts,
// // //         reason: p['reason'] as String? ?? 'manual',
// // //       ),
// // //       _ => null,
// // //     };
// // //   }

// // //   Future<void> _tryLoadSnapshotFromDb() async {
// // //     if (_sessionId == null) return;
// // //     try {
// // //       final snapshot = await _repo.loadSnapshot(_sessionId!);
// // //       if (snapshot != null) {
// // //         _state = TodState.fromMap(snapshot);
// // //         _hasSyncedState = true;
// // //         _loadState = _state!.isOver
// // //             ? TodLoadState.gameOver
// // //             : TodLoadState.ready;
// // //         _syncTimer();
// // //         notifyListeners();
// // //       } else {
// // //         _setError('Could not recover session state. Please rejoin the room.');
// // //       }
// // //     } catch (e) {
// // //       _setError('Reconnection failed: ${e.toString()}');
// // //     }
// // //   }

// // //   void _handleGameOver() {
// // //     _timerTicker?.cancel();
// // //     _snapshotThrottle?.cancel();
// // //     _loadState = TodLoadState.gameOver;

// // //     if (_isOwner && _sessionId != null && _state != null) {
// // //       _repo
// // //           .completeSession(
// // //             sessionId: _sessionId!,
// // //             finalSnapshot: _state!.toMap(),
// // //             endReason: _state!.endReason ?? 'round_limit',
// // //           )
// // //           .ignore();
// // //     }
// // //     notifyListeners();
// // //   }

// // //   void _setLoading() {
// // //     _loadState = TodLoadState.loading;
// // //     _error = null;
// // //     notifyListeners();
// // //   }

// // //   void _setError(String msg) {
// // //     _loadState = TodLoadState.error;
// // //     _error = msg;
// // //     notifyListeners();
// // //   }

// // //   @override
// // //   void dispose() {
// // //     _timerTicker?.cancel();
// // //     _snapshotThrottle?.cancel();
// // //     _syncTimeoutTimer?.cancel();
// // //     super.dispose();
// // //   }
// // // }

// // import 'dart:async';

// // import 'package:flutter/foundation.dart';
// // import 'package:uuid/uuid.dart';

// // import '../../../core/errors/failures.dart';
// // import '../../../core/services/realtime_service.dart';
// // import '../../../core/utils/app_logger.dart';
// // import '../engine/base_game_engine.dart';
// // import 'data/tod_repository.dart';
// // import 'domain/tod_models.dart';
// // import 'tod_timer_service.dart';
// // import 'truth_or_dare_engine.dart';

// // const _uuid = Uuid();

// // enum TodLoadState { idle, loading, ready, error, gameOver }

// // /// Bridges TruthOrDareEngine ↔ Flutter UI.
// // ///
// // /// Owner mode  : runs engine, processes all player_action events, broadcasts state.
// // /// Follower mode: receives game_state broadcasts, restores from snapshot.
// // ///
// // /// Realtime flow (single room channel — shared with RoomProvider):
// // ///   Owner  → game_state  (after every engine mutation)
// // ///   Any    → player_action (choice, complete, skip, vote, etc.)
// // ///   Owner  → processes player_action and re-broadcasts updated state
// // ///   Rejoiner → sync_request → owner responds with broadcastState()
// // ///
// // /// Hookup: call onStateBroadcast/onPlayerAction/onSyncRequest from
// // ///   the screen that owns this provider (TodGameScreen) — these are
// // ///   forwarded from RealtimeService callbacks set up by RoomProvider.
// // class TodGameProvider extends ChangeNotifier {
// //   TodGameProvider({
// //     required RealtimeService realtimeService,
// //     required TodRepository repository,
// //     required String currentUserId,
// //     required String currentDisplayName,
// //     this.isModerator = false,
// //   }) : _realtime = realtimeService,
// //        _repo = repository,
// //        _userId = currentUserId,
// //        _displayName = currentDisplayName;

// //   final RealtimeService _realtime;
// //   final TodRepository _repo;
// //   final String _userId;
// //   final String _displayName;
// //   final bool isModerator;

// //   // ── Session state ──────────────────────────────────────────────────────────
// //   TruthOrDareEngine? _engine;
// //   TodState? _state;
// //   GameConfig? _config;
// //   String? _roomId;
// //   String? _sessionId;
// //   bool _isOwner = false;
// //   String? _packCoverUrl;
// //   TodLoadState _loadState = TodLoadState.idle;
// //   String? _error;
// //   bool _hasSyncedState = false;
// //   Timer? _syncTimeoutTimer;

// //   // Player display names (resolved when game starts)
// //   final _displayNames = <String, String>{};

// //   // ── Timer ──────────────────────────────────────────────────────────────────
// //   int _timerRemaining = 0;
// //   bool _timerIsRunning = false;
// //   Timer? _timerTicker;
// //   Timer? _snapshotThrottle;

// //   // ── Getters ────────────────────────────────────────────────────────────────
// //   TodState? get state => _state;
// //   String? get packCoverUrl => _packCoverUrl;
// //   TodLoadState get loadState => _loadState;
// //   String? get error => _error;
// //   bool get isOwner => _isOwner;
// //   String get currentUserId => _userId;
// //   bool get isReady => _loadState == TodLoadState.ready;
// //   bool get hasSyncedState => _hasSyncedState;
// //   int get timerRemaining => _timerRemaining;
// //   bool get timerIsRunning => _timerIsRunning;
// //   String? get sessionId => _sessionId;

// //   bool get isMyTurn => _state?.currentPlayerId == _userId;
// //   bool get canModerate => _isOwner || isModerator;
// //   bool get isPunishmentPhase => _state?.phase == TodTurnPhase.punishmentVoting;
// //   bool get isWaitingForChoice => _state?.phase == TodTurnPhase.choosingType;
// //   bool get hasVotedOnPunishment {
// //     final v = _state?.currentPunishmentVote;
// //     return v?.votes.containsKey(_userId) ?? false;
// //   }

// //   /// Display name for any player in the game.
// //   String displayNameFor(String userId) =>
// //       _displayNames[userId] ?? 'Player ${userId.substring(0, 4)}';

// //   // ── Owner: initialize ────────────────────────────────────────────────────
// //   Future<void> initAsOwner({
// //     required String roomId,
// //     required GameConfig config,
// //     required List<String> playerIds,
// //     required Map<String, String> playerDisplayNames, // userId → displayName
// //     required String packId,
// //     String? packCoverUrl,
// //   }) async {
// //     _setLoading();
// //     _roomId = roomId;
// //     _packCoverUrl = packCoverUrl;
// //     _config = config;
// //     _isOwner = true;
// //     _displayNames.addAll(playerDisplayNames);

// //     try {
// //       // 1. Load cards — cache first, remote fallback
// //       var cards = await _repo.loadCardsFromCache(
// //         packId: packId,
// //         language: config.language,
// //         allowSpicy: config.allowSpicy,
// //       );
// //       if (cards.isEmpty) {
// //         cards = await _repo.loadCards(
// //           packId: packId,
// //           language: config.language,
// //           allowSpicy: config.allowSpicy,
// //         );
// //       }
// //       if (cards.isEmpty) {
// //         _setError(
// //           'No cards found for this pack. Please select a different pack.',
// //         );
// //         return;
// //       }

// //       // 2. Build and initialise engine
// //       _engine = TruthOrDareEngine(config, cards: cards);
// //       _engine!.init(playerOrder: playerIds);
// //       _state = _engine!.currentState as TodState;

// //       // 3. Persist session row
// //       _sessionId = await _repo.createSession(
// //         roomId: roomId,
// //         packId: packId,
// //         config: config,
// //         playerIds: playerIds,
// //         ownerId: _userId,
// //       );

// //       // 4. Broadcast initial snapshot to all followers
// //       await _broadcastState();

// //       // 5. Lazy DB snapshot every 10s
// //       _startSnapshotThrottle();

// //       _loadState = TodLoadState.ready;
// //       notifyListeners();
// //     } catch (e, st) {
// //       AppLogger.error(
// //         'TodGameProvider: initAsOwner failed',
// //         error: e,
// //         stackTrace: st,
// //       );
// //       _setError(e is Failure ? e.message : e.toString());
// //     }
// //   }

// //   // ── Follower: connect ──────────────────────────────────────────────────────
// //   void initAsFollower({
// //     required String roomId,
// //     required GameConfig config,
// //     String? sessionId,
// //     String? packCoverUrl,
// //   }) {
// //     _roomId = roomId;
// //     _packCoverUrl = packCoverUrl;
// //     _config = config;
// //     _sessionId = sessionId;
// //     _isOwner = false;
// //     _loadState = TodLoadState.loading;

// //     // Wait up to 8 seconds for owner broadcast; fallback to DB snapshot
// //     _syncTimeoutTimer?.cancel();
// //     _syncTimeoutTimer = Timer(const Duration(seconds: 8), () async {
// //       if (!_hasSyncedState) {
// //         AppLogger.warning('TodGameProvider: sync timeout — loading from DB');
// //         await _tryLoadSnapshotFromDb();
// //       }
// //     });
// //     notifyListeners();
// //   }

// //   // ── Broadcast receive (wired from TodGameScreen) ──────────────────────────

// //   /// Called by TodGameScreen when a game_state broadcast arrives.
// //   void onStateBroadcast(Map<String, dynamic> payload) {
// //     final snapshot = payload['snapshot'] as Map<String, dynamic>?;
// //     if (snapshot == null) return;

// //     final incomingTs = snapshot['snapshot_at'] as int? ?? 0;
// //     final currentTs = _state?.snapshotAt ?? 0;

// //     // Discard stale broadcasts (already-seen or older snapshots)
// //     if (incomingTs <= currentTs && _hasSyncedState) {
// //       AppLogger.debug(
// //         'TodGameProvider: stale broadcast ts=$incomingTs discarded',
// //       );
// //       return;
// //     }

// //     _state = TodState.fromMap(snapshot);
// //     _hasSyncedState = true;
// //     _syncTimeoutTimer?.cancel();
// //     _loadState = _state!.isOver ? TodLoadState.gameOver : TodLoadState.ready;

// //     _syncTimer();
// //     notifyListeners();
// //   }

// //   /// Called by TodGameScreen when a player_action broadcast arrives (owner only).
// //   void onPlayerAction(Map<String, dynamic> payload) {
// //     if (!_isOwner || _engine == null) return;

// //     final event = _parseEvent(payload);
// //     if (event == null) {
// //       AppLogger.warning('TodGameProvider: unknown action ${payload["action"]}');
// //       return;
// //     }

// //     _engine!.handleEvent(event);
// //     _state = _engine!.currentState as TodState;
// //     _syncTimer();
// //     _broadcastState();
// //     notifyListeners();

// //     if (_engine!.isGameOver) _handleGameOver();
// //   }

// //   /// Called by TodGameScreen when a sync_request broadcast arrives.
// //   void onSyncRequest(Map<String, dynamic> payload) {
// //     if (!_isOwner) return;
// //     AppLogger.info(
// //       'TodGameProvider: sync requested by ${payload["requester_id"]}',
// //     );
// //     _broadcastState();
// //   }

// //   // ── Player actions ─────────────────────────────────────────────────────────

// //   Future<void> chooseTruth() => _handleAction({
// //     'action': 'tod_choice',
// //     'card_type': TodCardType.truth.name,
// //   });

// //   Future<void> chooseDare() => _handleAction({
// //     'action': 'tod_choice',
// //     'card_type': TodCardType.dare.name,
// //   });

// //   Future<void> completeTurn({
// //     String response = '',
// //     String proofImageB64 = '',
// //   }) => _handleAction({
// //     'action': 'tod_complete',
// //     'response': response,
// //     'proof_image': proofImageB64,
// //   });

// //   Future<void> reactToResponse(String emoji) =>
// //       _handleAction({'action': 'tod_react', 'emoji': emoji});

// //   Future<void> voteForResponse() =>
// //       _handleAction({'action': 'tod_vote_response'});

// //   Future<void> skipTurn() => _handleAction({'action': 'tod_skip'});

// //   Future<void> voteOnPunishment(TodPunishmentVote vote) =>
// //       _sendAction({'action': 'tod_vote_punishment', 'vote': vote.name});

// //   Future<void> proposePunishment(String text) => _sendAction({
// //     'action': 'tod_propose_punishment',
// //     'punishment': TodPunishment(
// //       id: _uuid.v4(),
// //       text: text,
// //       proposedBy: _userId,
// //       proposedAt: DateTime.now().millisecondsSinceEpoch,
// //     ).toMap(),
// //   });

// //   // ── Moderator actions ──────────────────────────────────────────────────────

// //   Future<void> overridePunishment(
// //     TodPunishmentVote decision, {
// //     String? replacementText,
// //   }) {
// //     if (!canModerate) return Future.value();
// //     return _sendAction({
// //       'action': 'tod_moderator_override',
// //       'decision': decision.name,
// //       'replacement_text': replacementText,
// //     });
// //   }

// //   /// Owner: advance to the next turn directly (bypasses phase checks).
// //   Future<void> ownerAdvanceTurn() async {
// //     if (!_isOwner || _engine == null) return;
// //     _engine!.advanceTurn();
// //     _state = _engine!.currentState as TodState;
// //     _syncTimer();
// //     _broadcastState();
// //     notifyListeners();
// //     if (_engine!.isGameOver) _handleGameOver();
// //   }

// //   Future<void> endGame({String reason = 'manual'}) =>
// //       _sendAction({'action': 'tod_end_game', 'reason': reason});

// //   // ── Timer sync ─────────────────────────────────────────────────────────────
// //   void _syncTimer() {
// //     _timerTicker?.cancel();
// //     final s = _state;
// //     if (s == null) return;

// //     final timerEnabled =
// //         s.phase == TodTurnPhase.readingCard &&
// //         s.timerStartedAt != null &&
// //         (_config?.timerEnabled ?? false);

// //     if (!timerEnabled) {
// //       _timerRemaining = 0;
// //       _timerIsRunning = false;
// //       return;
// //     }

// //     final elapsed =
// //         (DateTime.now().millisecondsSinceEpoch - s.timerStartedAt!) ~/ 1000;
// //     _timerRemaining = (_config!.turnTimerSeconds - elapsed).clamp(
// //       0,
// //       _config!.turnTimerSeconds,
// //     );
// //     _timerIsRunning = _timerRemaining > 0;

// //     if (!_timerIsRunning) return;

// //     _timerTicker = Timer.periodic(const Duration(seconds: 1), (_) {
// //       if (_timerRemaining > 0) {
// //         _timerRemaining--;
// //         notifyListeners();
// //       }
// //       if (_timerRemaining <= 0) {
// //         _timerTicker?.cancel();
// //         _timerIsRunning = false;

// //         // Owner fires the timer expired event
// //         if (_isOwner && _state?.currentPlayerId != null) {
// //           _engine?.handleEvent(
// //             TodTimerExpiredEvent(
// //               userId: _state!.currentPlayerId,
// //               ts: DateTime.now().millisecondsSinceEpoch,
// //             ),
// //           );
// //           _state = _engine?.currentState as TodState?;
// //           _broadcastState();
// //           notifyListeners();
// //         }
// //       }
// //     });
// //   }

// //   // ── Snapshot throttle ──────────────────────────────────────────────────────
// //   void _startSnapshotThrottle() {
// //     _snapshotThrottle?.cancel();
// //     _snapshotThrottle = Timer.periodic(const Duration(seconds: 10), (_) {
// //       if (_sessionId != null && _state != null && _isOwner) {
// //         _repo
// //             .saveSnapshot(sessionId: _sessionId!, snapshot: _state!.toMap())
// //             .ignore();
// //       }
// //     });
// //   }

// //   // ── Internal ───────────────────────────────────────────────────────────────
// //   Future<void> _handleAction(Map<String, dynamic> action) async {
// //     final full = {
// //       ...action,
// //       'user_id': _userId,
// //       'display_name': _displayName,
// //       'ts': DateTime.now().millisecondsSinceEpoch,
// //     };
// //     // If this client is the owner/engine, process the event locally immediately.
// //     // (Broadcasts with self:false never come back to the sender.)
// //     if (_isOwner && _engine != null) {
// //       onPlayerAction(full); // processes + broadcasts state to followers
// //     } else {
// //       // Follower — just broadcast the action for the owner to process
// //       await _sendAction(action);
// //     }
// //   }

// //   Future<void> _sendAction(Map<String, dynamic> action) async {
// //     if (_roomId == null) return;
// //     await _realtime.broadcastPlayerAction(_roomId!, {
// //       ...action,
// //       'user_id': _userId,
// //       'display_name': _displayName,
// //       'ts': DateTime.now().millisecondsSinceEpoch,
// //     });
// //   }

// //   Future<void> _broadcastState() async {
// //     if (_roomId == null || _state == null) return;
// //     await _realtime.broadcastGameState(_roomId!, _state!.toMap(), _userId);
// //   }

// //   GameEngineEvent? _parseEvent(Map<String, dynamic> p) {
// //     final action = p['action'] as String? ?? '';
// //     final userId = p['user_id'] as String? ?? '';
// //     final ts = p['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch;

// //     return switch (action) {
// //       'tod_choice' => TodChoiceEvent(
// //         userId: userId,
// //         ts: ts,
// //         cardType: TodCardType.values.firstWhere(
// //           (t) => t.name == p['card_type'],
// //           orElse: () => TodCardType.truth,
// //         ),
// //       ),
// //       'tod_complete' => TodCompleteEvent(
// //         userId: userId,
// //         ts: ts,
// //         response: p['response'] as String? ?? '',
// //         proofImageB64: p['proof_image'] as String? ?? '',
// //       ),
// //       'tod_react' => TodReactEvent(
// //         userId: userId,
// //         ts: ts,
// //         emoji: p['emoji'] as String? ?? '👍',
// //       ),
// //       'tod_vote_response' => TodVoteResponseEvent(userId: userId, ts: ts),
// //       'tod_skip' => TodSkipEvent(userId: userId, ts: ts),
// //       'tod_vote_punishment' => TodVotePunishmentEvent(
// //         userId: userId,
// //         ts: ts,
// //         vote: TodPunishmentVote.values.firstWhere(
// //           (v) => v.name == p['vote'],
// //           orElse: () => TodPunishmentVote.doIt,
// //         ),
// //       ),
// //       'tod_propose_punishment' => TodProposePunishmentEvent(
// //         userId: userId,
// //         ts: ts,
// //         punishment: TodPunishment.fromMap(
// //           p['punishment'] as Map<String, dynamic>,
// //         ),
// //       ),
// //       'tod_moderator_override' => TodModeratorOverrideEvent(
// //         userId: userId,
// //         ts: ts,
// //         decision: TodPunishmentVote.values.firstWhere(
// //           (v) => v.name == p['decision'],
// //           orElse: () => TodPunishmentVote.doIt,
// //         ),
// //         replacementText: p['replacement_text'] as String?,
// //       ),
// //       'tod_end_game' => TodEndGameEvent(
// //         userId: userId,
// //         ts: ts,
// //         reason: p['reason'] as String? ?? 'manual',
// //       ),
// //       _ => null,
// //     };
// //   }

// //   Future<void> _tryLoadSnapshotFromDb() async {
// //     if (_sessionId == null) return;
// //     try {
// //       final snapshot = await _repo.loadSnapshot(_sessionId!);
// //       if (snapshot != null) {
// //         _state = TodState.fromMap(snapshot);
// //         _hasSyncedState = true;
// //         _loadState = _state!.isOver
// //             ? TodLoadState.gameOver
// //             : TodLoadState.ready;
// //         _syncTimer();
// //         notifyListeners();
// //       } else {
// //         _setError('Could not recover session state. Please rejoin the room.');
// //       }
// //     } catch (e) {
// //       _setError('Reconnection failed: ${e.toString()}');
// //     }
// //   }

// //   void _handleGameOver() {
// //     _timerTicker?.cancel();
// //     _snapshotThrottle?.cancel();
// //     _loadState = TodLoadState.gameOver;

// //     if (_isOwner && _sessionId != null && _state != null) {
// //       _repo
// //           .completeSession(
// //             sessionId: _sessionId!,
// //             finalSnapshot: _state!.toMap(),
// //             endReason: _state!.endReason ?? 'round_limit',
// //           )
// //           .ignore();
// //     }
// //     notifyListeners();
// //   }

// //   void _setLoading() {
// //     _loadState = TodLoadState.loading;
// //     _error = null;
// //     notifyListeners();
// //   }

// //   void _setError(String msg) {
// //     _loadState = TodLoadState.error;
// //     _error = msg;
// //     notifyListeners();
// //   }

// //   @override
// //   void dispose() {
// //     _timerTicker?.cancel();
// //     _snapshotThrottle?.cancel();
// //     _syncTimeoutTimer?.cancel();
// //     super.dispose();
// //   }
// // }

// import 'dart:async';

// import 'package:flutter/foundation.dart';
// import 'package:uuid/uuid.dart';

// import '../../../core/errors/failures.dart';
// import '../../../core/services/realtime_service.dart';
// import '../../../core/utils/app_logger.dart';
// import '../engine/base_game_engine.dart';
// import 'data/tod_repository.dart';
// import 'domain/tod_models.dart';
// import 'tod_timer_service.dart';
// import 'truth_or_dare_engine.dart';

// const _uuid = Uuid();

// enum TodLoadState { idle, loading, ready, error, gameOver }

// /// Bridges TruthOrDareEngine ↔ Flutter UI.
// ///
// /// Owner mode  : runs engine, processes all player_action events, broadcasts state.
// /// Follower mode: receives game_state broadcasts, restores from snapshot.
// ///
// /// Realtime flow (single room channel — shared with RoomProvider):
// ///   Owner  → game_state  (after every engine mutation)
// ///   Any    → player_action (choice, complete, skip, vote, etc.)
// ///   Owner  → processes player_action and re-broadcasts updated state
// ///   Rejoiner → sync_request → owner responds with broadcastState()
// ///
// /// Hookup: call onStateBroadcast/onPlayerAction/onSyncRequest from
// ///   the screen that owns this provider (TodGameScreen) — these are
// ///   forwarded from RealtimeService callbacks set up by RoomProvider.
// class TodGameProvider extends ChangeNotifier {
//   TodGameProvider({
//     required RealtimeService realtimeService,
//     required TodRepository   repository,
//     required String          currentUserId,
//     required String          currentDisplayName,
//     this.isModerator = false,
//   })  : _realtime    = realtimeService,
//         _repo        = repository,
//         _userId      = currentUserId,
//         _displayName = currentDisplayName;

//   final RealtimeService _realtime;
//   final TodRepository   _repo;
//   final String          _userId;
//   final String          _displayName;
//   final bool            isModerator;

//   // ── Session state ──────────────────────────────────────────────────────────
//   TruthOrDareEngine? _engine;
//   TodState?          _state;
//   GameConfig?        _config;
//   String?            _roomId;
//   String?            _sessionId;
//   bool               _isOwner         = false;
//   String?            _packCoverUrl;

//   // ── Chat state ──────────────────────────────────────────────────────────────
//   final List<_ChatMsg> _chatMessages = [];
//   int _unreadChat = 0;
//   List<_ChatMsg> get chatMessages  => _chatMessages;
//   int            get unreadChat    => _unreadChat;
//   void           clearUnreadChat() { _unreadChat = 0; notifyListeners(); }
//   TodLoadState       _loadState       = TodLoadState.idle;
//   String?            _error;
//   bool               _hasSyncedState  = false;
//   Timer?             _syncTimeoutTimer;

//   // Player display names (resolved when game starts)
//   final _displayNames = <String, String>{};

//   // ── Timer ──────────────────────────────────────────────────────────────────
//   int  _timerRemaining  = 0;
//   bool _timerIsRunning  = false;
//   Timer? _timerTicker;
//   Timer? _snapshotThrottle;

//   // ── Getters ────────────────────────────────────────────────────────────────
//   TodState?    get state          => _state;
//   String?      get packCoverUrl    => _packCoverUrl;
//   TodLoadState get loadState      => _loadState;
//   String?      get error          => _error;
//   bool         get isOwner        => _isOwner;
//   String       get currentUserId  => _userId;
//   bool         get isReady        => _loadState == TodLoadState.ready;
//   bool         get hasSyncedState => _hasSyncedState;
//   int          get timerRemaining => _timerRemaining;
//   bool         get timerIsRunning => _timerIsRunning;
//   String?      get sessionId      => _sessionId;

//   bool get isMyTurn      => _state?.currentPlayerId == _userId;
//   bool get canModerate   => _isOwner || isModerator;
//   bool get isPunishmentPhase =>
//       _state?.phase == TodTurnPhase.punishmentVoting;
//   bool get isWaitingForChoice =>
//       _state?.phase == TodTurnPhase.choosingType;
//   bool get hasVotedOnPunishment {
//     final v = _state?.currentPunishmentVote;
//     return v?.votes.containsKey(_userId) ?? false;
//   }

//   /// Display name for any player in the game.
//   String displayNameFor(String userId) =>
//       _displayNames[userId] ?? 'Player ${userId.substring(0, 4)}';

//   // ── Owner: initialize ────────────────────────────────────────────────────
//   Future<void> initAsOwner({
//     required String       roomId,
//     required GameConfig   config,
//     required List<String> playerIds,
//     required Map<String, String> playerDisplayNames, // userId → displayName
//     required String       packId,
//     String?               packCoverUrl,
//   }) async {
//     _setLoading();
//     _roomId       = roomId;
//     _packCoverUrl = packCoverUrl;
//     _config       = config;
//     _isOwner      = true;
//     _displayNames.addAll(playerDisplayNames);

//     try {
//       // 1. Load cards — cache first, remote fallback
//       var cards = await _repo.loadCardsFromCache(
//           packId: packId, language: config.language,
//           allowSpicy: config.allowSpicy);
//       if (cards.isEmpty) {
//         cards = await _repo.loadCards(
//             packId: packId, language: config.language,
//             allowSpicy: config.allowSpicy);
//       }
//       if (cards.isEmpty) {
//         _setError('No cards found for this pack. Please select a different pack.');
//         return;
//       }

//       // 2. Build and initialise engine
//       _engine = TruthOrDareEngine(config, cards: cards);
//       _engine!.init(playerOrder: playerIds);
//       _state = _engine!.currentState as TodState;

//       // 3. Persist session row
//       _sessionId = await _repo.createSession(
//         roomId:    roomId,
//         packId:    packId,
//         config:    config,
//         playerIds: playerIds,
//         ownerId:   _userId,
//       );

//       // 4. Broadcast initial snapshot to all followers
//       await _broadcastState();

//       // 5. Lazy DB snapshot every 10s
//       _startSnapshotThrottle();

//       _loadState = TodLoadState.ready;
//       notifyListeners();
//     } catch (e, st) {
//       AppLogger.error('TodGameProvider: initAsOwner failed', error: e, stackTrace: st);
//       _setError(e is Failure ? e.message : e.toString());
//     }
//   }

//   // ── Follower: connect ──────────────────────────────────────────────────────
//   void initAsFollower({
//     required String     roomId,
//     required GameConfig config,
//     String?             sessionId,
//     String?             packCoverUrl,
//   }) {
//     _roomId       = roomId;
//     _packCoverUrl = packCoverUrl;
//     _config    = config;
//     _sessionId = sessionId;
//     _isOwner   = false;
//     _loadState = TodLoadState.loading;

//     // Wait up to 8 seconds for owner broadcast; fallback to DB snapshot
//     _syncTimeoutTimer?.cancel();
//     _syncTimeoutTimer = Timer(const Duration(seconds: 8), () async {
//       if (!_hasSyncedState) {
//         AppLogger.warning('TodGameProvider: sync timeout — loading from DB');
//         await _tryLoadSnapshotFromDb();
//       }
//     });
//     notifyListeners();
//   }

//   // ── Broadcast receive (wired from TodGameScreen) ──────────────────────────

//   /// Called by TodGameScreen when a game_state broadcast arrives.
//   void onStateBroadcast(Map<String, dynamic> payload) {
//     final snapshot = payload['snapshot'] as Map<String, dynamic>?;
//     if (snapshot == null) return;

//     final incomingTs = snapshot['snapshot_at'] as int? ?? 0;
//     final currentTs  = _state?.snapshotAt ?? 0;

//     // Discard stale broadcasts (already-seen or older snapshots)
//     if (incomingTs <= currentTs && _hasSyncedState) {
//       AppLogger.debug('TodGameProvider: stale broadcast ts=$incomingTs discarded');
//       return;
//     }

//     _state          = TodState.fromMap(snapshot);
//     _hasSyncedState = true;
//     _syncTimeoutTimer?.cancel();
//     _loadState = _state!.isOver ? TodLoadState.gameOver : TodLoadState.ready;

//     _syncTimer();
//     notifyListeners();
//   }

//   /// Called by TodGameScreen when a player_action broadcast arrives (owner only).
//   void onPlayerAction(Map<String, dynamic> payload) {
//     if (!_isOwner || _engine == null) return;

//     final event = _parseEvent(payload);
//     if (event == null) {
//       AppLogger.warning(
//           'TodGameProvider: unknown action ${payload["action"]}');
//       return;
//     }

//     _engine!.handleEvent(event);
//     _state = _engine!.currentState as TodState;
//     _syncTimer();
//     _broadcastState();
//     notifyListeners();

//     if (_engine!.isGameOver) _handleGameOver();
//   }

//   /// Called by TodGameScreen when a sync_request broadcast arrives.
//   void onSyncRequest(Map<String, dynamic> payload) {
//     if (!_isOwner) return;
//     AppLogger.info(
//         'TodGameProvider: sync requested by ${payload["requester_id"]}');
//     _broadcastState();
//   }

//   // ── Player actions ─────────────────────────────────────────────────────────

//   Future<void> chooseTruth() => _handleAction({
//         'action':    'tod_choice',
//         'card_type': TodCardType.truth.name,
//       });

//   Future<void> chooseDare() => _handleAction({
//         'action':    'tod_choice',
//         'card_type': TodCardType.dare.name,
//       });

//   Future<void> completeTurn({String response = '', String proofImageB64 = ''}) =>
//       _handleAction({'action': 'tod_complete', 'response': response, 'proof_image': proofImageB64});

//   Future<void> reactToResponse(String emoji) =>
//       _handleAction({'action': 'tod_react', 'emoji': emoji});

//   Future<void> voteForResponse() =>
//       _handleAction({'action': 'tod_vote_response'});

//   Future<void> skipTurn() =>
//       _handleAction({'action': 'tod_skip'});

//   Future<void> voteOnPunishment(TodPunishmentVote vote) => _sendAction({
//         'action': 'tod_vote_punishment',
//         'vote':   vote.name,
//       });

//   Future<void> proposePunishment(String text) => _sendAction({
//         'action': 'tod_propose_punishment',
//         'punishment': TodPunishment(
//           id:         _uuid.v4(),
//           text:       text,
//           proposedBy: _userId,
//           proposedAt: DateTime.now().millisecondsSinceEpoch,
//         ).toMap(),
//       });

//   // ── Moderator actions ──────────────────────────────────────────────────────

//   Future<void> overridePunishment(
//     TodPunishmentVote decision, {
//     String? replacementText,
//   }) {
//     if (!canModerate) return Future.value();
//     return _sendAction({
//       'action':           'tod_moderator_override',
//       'decision':         decision.name,
//       'replacement_text': replacementText,
//     });
//   }

//   /// Owner: advance to the next turn directly (bypasses phase checks).
//   Future<void> ownerAdvanceTurn() async {
//     if (!_isOwner || _engine == null) return;
//     _engine!.advanceTurn();
//     _state = _engine!.currentState as TodState;
//     _syncTimer();
//     _broadcastState();
//     notifyListeners();
//     if (_engine!.isGameOver) _handleGameOver();
//   }

//   Future<void> endGame({String reason = 'manual'}) =>
//       _sendAction({'action': 'tod_end_game', 'reason': reason});

//   Future<void> sendChat(String text) async {
//     if (_roomId == null || text.trim().isEmpty) return;
//     final msg = _ChatMsg(
//       senderId: _userId, senderName: _displayNames[_userId] ?? 'Me',
//       text: text.trim(), ts: DateTime.now());
//     _chatMessages.add(msg);
//     notifyListeners();
//     try {
//       await _realtime.broadcastChatMessage(_roomId!, {
//         'user_id': _userId, 'display_name': _displayNames[_userId] ?? 'Me',
//         'content': text.trim(), 'ts': DateTime.now().millisecondsSinceEpoch,
//       });
//     } catch (_) {}
//   }

//   // ── Timer sync ─────────────────────────────────────────────────────────────
//   void _syncTimer() {
//     _timerTicker?.cancel();
//     final s = _state;
//     if (s == null) return;

//     final timerEnabled =
//         s.phase == TodTurnPhase.readingCard &&
//         s.timerStartedAt != null &&
//         (_config?.timerEnabled ?? false);

//     if (!timerEnabled) {
//       _timerRemaining = 0;
//       _timerIsRunning = false;
//       return;
//     }

//     final elapsed =
//         (DateTime.now().millisecondsSinceEpoch - s.timerStartedAt!) ~/ 1000;
//     _timerRemaining =
//         (_config!.turnTimerSeconds - elapsed).clamp(0, _config!.turnTimerSeconds);
//     _timerIsRunning = _timerRemaining > 0;

//     if (!_timerIsRunning) return;

//     _timerTicker = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (_timerRemaining > 0) {
//         _timerRemaining--;
//         notifyListeners();
//       }
//       if (_timerRemaining <= 0) {
//         _timerTicker?.cancel();
//         _timerIsRunning = false;

//         // Owner fires the timer expired event
//         if (_isOwner && _state?.currentPlayerId != null) {
//           _engine?.handleEvent(TodTimerExpiredEvent(
//             userId: _state!.currentPlayerId,
//             ts:     DateTime.now().millisecondsSinceEpoch,
//           ));
//           _state = _engine?.currentState as TodState?;
//           _broadcastState();
//           notifyListeners();
//         }
//       }
//     });
//   }

//   // ── Snapshot throttle ──────────────────────────────────────────────────────
//   void _startSnapshotThrottle() {
//     _snapshotThrottle?.cancel();
//     _snapshotThrottle = Timer.periodic(const Duration(seconds: 10), (_) {
//       if (_sessionId != null && _state != null && _isOwner) {
//         _repo.saveSnapshot(
//           sessionId: _sessionId!,
//           snapshot:  _state!.toMap(),
//         ).ignore();
//       }
//     });
//   }

//   // ── Internal ───────────────────────────────────────────────────────────────
//   Future<void> _handleAction(Map<String, dynamic> action) async {
//     final full = {
//       ...action,
//       'user_id':      _userId,
//       'display_name': _displayName,
//       'ts':           DateTime.now().millisecondsSinceEpoch,
//     };
//     // If this client is the owner/engine, process the event locally immediately.
//     // (Broadcasts with self:false never come back to the sender.)
//     if (_isOwner && _engine != null) {
//       onPlayerAction(full);  // processes + broadcasts state to followers
//     } else {
//       // Follower — just broadcast the action for the owner to process
//       await _sendAction(action);
//     }
//   }

//   Future<void> _sendAction(Map<String, dynamic> action) async {
//     if (_roomId == null) return;
//     await _realtime.broadcastPlayerAction(_roomId!, {
//       ...action,
//       'user_id':      _userId,
//       'display_name': _displayName,
//       'ts':           DateTime.now().millisecondsSinceEpoch,
//     });
//   }

//   Future<void> _broadcastState() async {
//     if (_roomId == null || _state == null) return;
//     await _realtime.broadcastGameState(_roomId!, _state!.toMap(), _userId);
//   }

//   GameEngineEvent? _parseEvent(Map<String, dynamic> p) {
//     final action = p['action']  as String? ?? '';
//     final userId = p['user_id'] as String? ?? '';
//     final ts     = p['ts']      as int?    ??
//         DateTime.now().millisecondsSinceEpoch;

//     return switch (action) {
//       'tod_choice' => TodChoiceEvent(
//           userId:   userId,
//           ts:       ts,
//           cardType: TodCardType.values.firstWhere(
//             (t) => t.name == p['card_type'],
//             orElse: () => TodCardType.truth,
//           ),
//         ),
//       'tod_complete'           => TodCompleteEvent(userId: userId, ts: ts,
//           response: p['response'] as String? ?? '',
//           proofImageB64: p['proof_image'] as String? ?? ''),
//       'tod_react'              => TodReactEvent(userId: userId, ts: ts,
//           emoji: p['emoji'] as String? ?? '👍'),
//       'tod_vote_response'      => TodVoteResponseEvent(userId: userId, ts: ts),
//       'tod_skip'               => TodSkipEvent(userId: userId, ts: ts),
//       'tod_vote_punishment' => TodVotePunishmentEvent(
//           userId: userId,
//           ts:     ts,
//           vote:   TodPunishmentVote.values.firstWhere(
//             (v) => v.name == p['vote'],
//             orElse: () => TodPunishmentVote.doIt,
//           ),
//         ),
//       'tod_propose_punishment' => TodProposePunishmentEvent(
//           userId:     userId,
//           ts:         ts,
//           punishment: TodPunishment.fromMap(
//               p['punishment'] as Map<String, dynamic>),
//         ),
//       'tod_moderator_override' => TodModeratorOverrideEvent(
//           userId:          userId,
//           ts:              ts,
//           decision:        TodPunishmentVote.values.firstWhere(
//             (v) => v.name == p['decision'],
//             orElse: () => TodPunishmentVote.doIt,
//           ),
//           replacementText: p['replacement_text'] as String?,
//         ),
//       'tod_end_game' => TodEndGameEvent(
//           userId: userId,
//           ts:     ts,
//           reason: p['reason'] as String? ?? 'manual',
//         ),
//       _ => null,
//     };
//   }

//   Future<void> _tryLoadSnapshotFromDb() async {
//     if (_sessionId == null) return;
//     try {
//       final snapshot = await _repo.loadSnapshot(_sessionId!);
//       if (snapshot != null) {
//         _state          = TodState.fromMap(snapshot);
//         _hasSyncedState = true;
//         _loadState      = _state!.isOver
//             ? TodLoadState.gameOver
//             : TodLoadState.ready;
//         _syncTimer();
//         notifyListeners();
//       } else {
//         _setError('Could not recover session state. Please rejoin the room.');
//       }
//     } catch (e) {
//       _setError('Reconnection failed: ${e.toString()}');
//     }
//   }

//   void _handleGameOver() {
//     _timerTicker?.cancel();
//     _snapshotThrottle?.cancel();
//     _loadState = TodLoadState.gameOver;

//     if (_isOwner && _sessionId != null && _state != null) {
//       _repo.completeSession(
//         sessionId:     _sessionId!,
//         finalSnapshot: _state!.toMap(),
//         endReason:     _state!.endReason ?? 'round_limit',
//       ).ignore();
//     }
//     notifyListeners();
//   }

//   void _setLoading() {
//     _loadState = TodLoadState.loading;
//     _error     = null;
//     notifyListeners();
//   }

//   void _setError(String msg) {
//     _loadState = TodLoadState.error;
//     _error     = msg;
//     notifyListeners();
//   }

//   void addChatMessage(_ChatMsg msg) {
//     if (_chatMessages.any((m) => m.senderName == msg.senderName && m.text == msg.text &&
//         msg.ts.difference(m.ts).abs().inSeconds < 2)) return; // dedup
//     _chatMessages.add(msg);
//     _unreadChat++;
//     notifyListeners();
//   }

//   @override
//   void dispose() {
//     _timerTicker?.cancel();
//     _snapshotThrottle?.cancel();
//     _syncTimeoutTimer?.cancel();
//     super.dispose();
//   }
// }

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/failures.dart';
import '../../../core/services/realtime_service.dart';
import '../../../core/utils/app_logger.dart';
import '../engine/base_game_engine.dart';
import 'data/tod_repository.dart';
import 'domain/tod_models.dart';
import 'tod_timer_service.dart';
import 'truth_or_dare_engine.dart';

const _uuid = Uuid();

enum TodLoadState { idle, loading, ready, error, gameOver }

/// Bridges TruthOrDareEngine ↔ Flutter UI.
///
/// Owner mode  : runs engine, processes all player_action events, broadcasts state.
/// Follower mode: receives game_state broadcasts, restores from snapshot.
///
/// Realtime flow (single room channel — shared with RoomProvider):
///   Owner  → game_state  (after every engine mutation)
///   Any    → player_action (choice, complete, skip, vote, etc.)
///   Owner  → processes player_action and re-broadcasts updated state
///   Rejoiner → sync_request → owner responds with broadcastState()
///
/// Hookup: call onStateBroadcast/onPlayerAction/onSyncRequest from
///   the screen that owns this provider (TodGameScreen) — these are
///   forwarded from RealtimeService callbacks set up by RoomProvider.
class TodGameProvider extends ChangeNotifier {
  TodGameProvider({
    required RealtimeService realtimeService,
    required TodRepository repository,
    required String currentUserId,
    required String currentDisplayName,
    this.isModerator = false,
  }) : _realtime = realtimeService,
       _repo = repository,
       _userId = currentUserId,
       _displayName = currentDisplayName;

  final RealtimeService _realtime;
  final TodRepository _repo;
  final String _userId;
  final String _displayName;
  final bool isModerator;

  // ── Session state ──────────────────────────────────────────────────────────
  TruthOrDareEngine? _engine;
  TodState? _state;
  GameConfig? _config;
  String? _roomId;
  String? _sessionId;
  bool _isOwner = false;
  String? _packCoverUrl;

  // ── Chat state ──────────────────────────────────────────────────────────────
  final List<TodChatMsg> _chatMessages = [];
  int _unreadChat = 0;
  List<TodChatMsg> get chatMessages => _chatMessages;
  int get unreadChat => _unreadChat;
  void clearUnreadChat() {
    _unreadChat = 0;
    notifyListeners();
  }

  TodLoadState _loadState = TodLoadState.idle;
  String? _error;
  bool _hasSyncedState = false;
  Timer? _syncTimeoutTimer;

  // Player display names (resolved when game starts)
  final _displayNames = <String, String>{};

  // ── Timer ──────────────────────────────────────────────────────────────────
  int _timerRemaining = 0;
  bool _timerIsRunning = false;
  Timer? _timerTicker;
  Timer? _snapshotThrottle;

  // ── Getters ────────────────────────────────────────────────────────────────
  TodState? get state => _state;
  String? get packCoverUrl => _packCoverUrl;
  TodLoadState get loadState => _loadState;
  String? get error => _error;
  bool get isOwner => _isOwner;
  String get currentUserId => _userId;
  bool get isReady => _loadState == TodLoadState.ready;
  bool get hasSyncedState => _hasSyncedState;
  int get timerRemaining => _timerRemaining;
  bool get timerIsRunning => _timerIsRunning;
  String? get sessionId => _sessionId;

  bool get isMyTurn => _state?.currentPlayerId == _userId;
  bool get canModerate => _isOwner || isModerator;
  bool get isPunishmentPhase => _state?.phase == TodTurnPhase.punishmentVoting;
  bool get isWaitingForChoice => _state?.phase == TodTurnPhase.choosingType;
  bool get hasVotedOnPunishment {
    final v = _state?.currentPunishmentVote;
    return v?.votes.containsKey(_userId) ?? false;
  }

  /// Display name for any player in the game.
  String displayNameFor(String userId) =>
      _displayNames[userId] ?? 'Player ${userId.substring(0, 4)}';

  // ── Owner: initialize ────────────────────────────────────────────────────
  Future<void> initAsOwner({
    required String roomId,
    required GameConfig config,
    required List<String> playerIds,
    required Map<String, String> playerDisplayNames, // userId → displayName
    required String packId,
    String? packCoverUrl,
  }) async {
    _setLoading();
    _roomId = roomId;
    _packCoverUrl = packCoverUrl;
    _config = config;
    _isOwner = true;
    _displayNames.addAll(playerDisplayNames);

    try {
      // 1. Load cards — cache first, remote fallback
      var cards = await _repo.loadCardsFromCache(
        packId: packId,
        language: config.language,
        allowSpicy: config.allowSpicy,
      );
      if (cards.isEmpty) {
        cards = await _repo.loadCards(
          packId: packId,
          language: config.language,
          allowSpicy: config.allowSpicy,
        );
      }
      if (cards.isEmpty) {
        _setError(
          'No cards found for this pack. Please select a different pack.',
        );
        return;
      }

      // 2. Build and initialise engine
      _engine = TruthOrDareEngine(config, cards: cards);
      _engine!.init(playerOrder: playerIds);
      _state = _engine!.currentState as TodState;

      // 3. Persist session row
      _sessionId = await _repo.createSession(
        roomId: roomId,
        packId: packId,
        config: config,
        playerIds: playerIds,
        ownerId: _userId,
      );

      // 4. Broadcast initial snapshot to all followers
      await _broadcastState();

      // 5. Lazy DB snapshot every 10s
      _startSnapshotThrottle();

      _loadState = TodLoadState.ready;
      notifyListeners();
    } catch (e, st) {
      AppLogger.error(
        'TodGameProvider: initAsOwner failed',
        error: e,
        stackTrace: st,
      );
      _setError(e is Failure ? e.message : e.toString());
    }
  }

  // ── Follower: connect ──────────────────────────────────────────────────────
  void initAsFollower({
    required String roomId,
    required GameConfig config,
    String? sessionId,
    String? packCoverUrl,
  }) {
    _roomId = roomId;
    _packCoverUrl = packCoverUrl;
    _config = config;
    _sessionId = sessionId;
    _isOwner = false;
    _loadState = TodLoadState.loading;

    // Wait up to 8 seconds for owner broadcast; fallback to DB snapshot
    _syncTimeoutTimer?.cancel();
    _syncTimeoutTimer = Timer(const Duration(seconds: 8), () async {
      if (!_hasSyncedState) {
        AppLogger.warning('TodGameProvider: sync timeout — loading from DB');
        await _tryLoadSnapshotFromDb();
      }
    });
    notifyListeners();
  }

  // ── Broadcast receive (wired from TodGameScreen) ──────────────────────────

  /// Called by TodGameScreen when a game_state broadcast arrives.
  void onStateBroadcast(Map<String, dynamic> payload) {
    final snapshot = payload['snapshot'] as Map<String, dynamic>?;
    if (snapshot == null) return;

    final incomingTs = snapshot['snapshot_at'] as int? ?? 0;
    final currentTs = _state?.snapshotAt ?? 0;

    // Discard stale broadcasts (already-seen or older snapshots)
    if (incomingTs <= currentTs && _hasSyncedState) {
      AppLogger.debug(
        'TodGameProvider: stale broadcast ts=$incomingTs discarded',
      );
      return;
    }

    _state = TodState.fromMap(snapshot);
    _hasSyncedState = true;
    _syncTimeoutTimer?.cancel();
    _loadState = _state!.isOver ? TodLoadState.gameOver : TodLoadState.ready;

    _syncTimer();
    notifyListeners();
  }

  /// Called by TodGameScreen when a player_action broadcast arrives (owner only).
  void onPlayerAction(Map<String, dynamic> payload) {
    if (!_isOwner || _engine == null) return;

    final event = _parseEvent(payload);
    if (event == null) {
      AppLogger.warning('TodGameProvider: unknown action ${payload["action"]}');
      return;
    }

    _engine!.handleEvent(event);
    _state = _engine!.currentState as TodState;
    _syncTimer();
    _broadcastState();
    notifyListeners();

    if (_engine!.isGameOver) _handleGameOver();
  }

  /// Called by TodGameScreen when a sync_request broadcast arrives.
  void onSyncRequest(Map<String, dynamic> payload) {
    if (!_isOwner) return;
    AppLogger.info(
      'TodGameProvider: sync requested by ${payload["requester_id"]}',
    );
    _broadcastState();
  }

  // ── Player actions ─────────────────────────────────────────────────────────

  Future<void> chooseTruth() => _handleAction({
    'action': 'tod_choice',
    'card_type': TodCardType.truth.name,
  });

  Future<void> chooseDare() => _handleAction({
    'action': 'tod_choice',
    'card_type': TodCardType.dare.name,
  });

  Future<void> completeTurn({
    String response = '',
    String proofImageB64 = '',
  }) => _handleAction({
    'action': 'tod_complete',
    'response': response,
    'proof_image': proofImageB64,
  });

  Future<void> reactToResponse(String emoji) =>
      _handleAction({'action': 'tod_react', 'emoji': emoji});

  Future<void> voteForResponse() =>
      _handleAction({'action': 'tod_vote_response'});

  Future<void> skipTurn() => _handleAction({'action': 'tod_skip'});

  Future<void> voteOnPunishment(TodPunishmentVote vote) =>
      _sendAction({'action': 'tod_vote_punishment', 'vote': vote.name});

  Future<void> proposePunishment(String text) => _sendAction({
    'action': 'tod_propose_punishment',
    'punishment': TodPunishment(
      id: _uuid.v4(),
      text: text,
      proposedBy: _userId,
      proposedAt: DateTime.now().millisecondsSinceEpoch,
    ).toMap(),
  });

  // ── Moderator actions ──────────────────────────────────────────────────────

  Future<void> overridePunishment(
    TodPunishmentVote decision, {
    String? replacementText,
  }) {
    if (!canModerate) return Future.value();
    return _sendAction({
      'action': 'tod_moderator_override',
      'decision': decision.name,
      'replacement_text': replacementText,
    });
  }

  /// Owner: advance to the next turn directly (bypasses phase checks).
  Future<void> ownerAdvanceTurn() async {
    if (!_isOwner || _engine == null) return;
    _engine!.advanceTurn();
    _state = _engine!.currentState as TodState;
    _syncTimer();
    _broadcastState();
    notifyListeners();
    if (_engine!.isGameOver) _handleGameOver();
  }

  Future<void> endGame({String reason = 'manual'}) =>
      _sendAction({'action': 'tod_end_game', 'reason': reason});

  Future<void> sendChat(String text) async {
    if (_roomId == null || text.trim().isEmpty) return;
    final msg = TodChatMsg(
      senderId: _userId,
      senderName: _displayNames[_userId] ?? 'Me',
      text: text.trim(),
      ts: DateTime.now(),
    );
    _chatMessages.add(msg);
    notifyListeners();
    try {
      await _realtime.broadcastChat(_roomId!, {
        'user_id': _userId,
        'display_name': _displayNames[_userId] ?? 'Me',
        'content': text.trim(),
        'ts': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}
  }

  // ── Timer sync ─────────────────────────────────────────────────────────────
  void _syncTimer() {
    _timerTicker?.cancel();
    final s = _state;
    if (s == null) return;

    final timerEnabled =
        s.phase == TodTurnPhase.readingCard &&
        s.timerStartedAt != null &&
        (_config?.timerEnabled ?? false);

    if (!timerEnabled) {
      _timerRemaining = 0;
      _timerIsRunning = false;
      return;
    }

    final elapsed =
        (DateTime.now().millisecondsSinceEpoch - s.timerStartedAt!) ~/ 1000;
    _timerRemaining = (_config!.turnTimerSeconds - elapsed).clamp(
      0,
      _config!.turnTimerSeconds,
    );
    _timerIsRunning = _timerRemaining > 0;

    if (!_timerIsRunning) return;

    _timerTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timerRemaining > 0) {
        _timerRemaining--;
        notifyListeners();
      }
      if (_timerRemaining <= 0) {
        _timerTicker?.cancel();
        _timerIsRunning = false;

        // Owner fires the timer expired event
        if (_isOwner && _state?.currentPlayerId != null) {
          _engine?.handleEvent(
            TodTimerExpiredEvent(
              userId: _state!.currentPlayerId,
              ts: DateTime.now().millisecondsSinceEpoch,
            ),
          );
          _state = _engine?.currentState as TodState?;
          _broadcastState();
          notifyListeners();
        }
      }
    });
  }

  // ── Snapshot throttle ──────────────────────────────────────────────────────
  void _startSnapshotThrottle() {
    _snapshotThrottle?.cancel();
    _snapshotThrottle = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_sessionId != null && _state != null && _isOwner) {
        _repo
            .saveSnapshot(sessionId: _sessionId!, snapshot: _state!.toMap())
            .ignore();
      }
    });
  }

  // ── Internal ───────────────────────────────────────────────────────────────
  Future<void> _handleAction(Map<String, dynamic> action) async {
    final full = {
      ...action,
      'user_id': _userId,
      'display_name': _displayName,
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
    // If this client is the owner/engine, process the event locally immediately.
    // (Broadcasts with self:false never come back to the sender.)
    if (_isOwner && _engine != null) {
      onPlayerAction(full); // processes + broadcasts state to followers
    } else {
      // Follower — just broadcast the action for the owner to process
      await _sendAction(action);
    }
  }

  Future<void> _sendAction(Map<String, dynamic> action) async {
    if (_roomId == null) return;
    await _realtime.broadcastPlayerAction(_roomId!, {
      ...action,
      'user_id': _userId,
      'display_name': _displayName,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _broadcastState() async {
    if (_roomId == null || _state == null) return;
    await _realtime.broadcastGameState(_roomId!, _state!.toMap(), _userId);
  }

  GameEngineEvent? _parseEvent(Map<String, dynamic> p) {
    final action = p['action'] as String? ?? '';
    final userId = p['user_id'] as String? ?? '';
    final ts = p['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch;

    return switch (action) {
      'tod_choice' => TodChoiceEvent(
        userId: userId,
        ts: ts,
        cardType: TodCardType.values.firstWhere(
          (t) => t.name == p['card_type'],
          orElse: () => TodCardType.truth,
        ),
      ),
      'tod_complete' => TodCompleteEvent(
        userId: userId,
        ts: ts,
        response: p['response'] as String? ?? '',
        proofImageB64: p['proof_image'] as String? ?? '',
      ),
      'tod_react' => TodReactEvent(
        userId: userId,
        ts: ts,
        emoji: p['emoji'] as String? ?? '👍',
      ),
      'tod_vote_response' => TodVoteResponseEvent(userId: userId, ts: ts),
      'tod_skip' => TodSkipEvent(userId: userId, ts: ts),
      'tod_vote_punishment' => TodVotePunishmentEvent(
        userId: userId,
        ts: ts,
        vote: TodPunishmentVote.values.firstWhere(
          (v) => v.name == p['vote'],
          orElse: () => TodPunishmentVote.doIt,
        ),
      ),
      'tod_propose_punishment' => TodProposePunishmentEvent(
        userId: userId,
        ts: ts,
        punishment: TodPunishment.fromMap(
          p['punishment'] as Map<String, dynamic>,
        ),
      ),
      'tod_moderator_override' => TodModeratorOverrideEvent(
        userId: userId,
        ts: ts,
        decision: TodPunishmentVote.values.firstWhere(
          (v) => v.name == p['decision'],
          orElse: () => TodPunishmentVote.doIt,
        ),
        replacementText: p['replacement_text'] as String?,
      ),
      'tod_end_game' => TodEndGameEvent(
        userId: userId,
        ts: ts,
        reason: p['reason'] as String? ?? 'manual',
      ),
      _ => null,
    };
  }

  Future<void> _tryLoadSnapshotFromDb() async {
    if (_sessionId == null) return;
    try {
      final snapshot = await _repo.loadSnapshot(_sessionId!);
      if (snapshot != null) {
        _state = TodState.fromMap(snapshot);
        _hasSyncedState = true;
        _loadState = _state!.isOver
            ? TodLoadState.gameOver
            : TodLoadState.ready;
        _syncTimer();
        notifyListeners();
      } else {
        _setError('Could not recover session state. Please rejoin the room.');
      }
    } catch (e) {
      _setError('Reconnection failed: ${e.toString()}');
    }
  }

  void _handleGameOver() {
    _timerTicker?.cancel();
    _snapshotThrottle?.cancel();
    _loadState = TodLoadState.gameOver;

    if (_isOwner && _sessionId != null && _state != null) {
      _repo
          .completeSession(
            sessionId: _sessionId!,
            finalSnapshot: _state!.toMap(),
            endReason: _state!.endReason ?? 'round_limit',
          )
          .ignore();
    }
    notifyListeners();
  }

  void _setLoading() {
    _loadState = TodLoadState.loading;
    _error = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _loadState = TodLoadState.error;
    _error = msg;
    notifyListeners();
  }

  void addChatMessage(TodChatMsg msg) {
    if (_chatMessages.any(
      (m) =>
          m.senderName == msg.senderName &&
          m.text == msg.text &&
          msg.ts.difference(m.ts).abs().inSeconds < 2,
    ))
      return; // dedup
    _chatMessages.add(msg);
    _unreadChat++;
    notifyListeners();
  }

  @override
  void dispose() {
    _timerTicker?.cancel();
    _snapshotThrottle?.cancel();
    _syncTimeoutTimer?.cancel();
    super.dispose();
  }
}

/// Simple in-game chat message — shared between TodGameProvider and the screen.
class TodChatMsg {
  const TodChatMsg({
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.ts,
  });
  final String senderId;
  final String senderName;
  final String text;
  final DateTime ts;
}
