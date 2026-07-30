// import 'dart:async';
// import 'package:flutter/scheduler.dart';

// import 'package:flutter/foundation.dart';
// import 'package:uuid/uuid.dart';

// import '../../../core/di/service_locator.dart';
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
//     required TodRepository repository,
//     required String currentUserId,
//     required String currentDisplayName,
//     this.isModerator = false,
//   }) : _realtime = realtimeService,
//        _repo = repository,
//        _userId = currentUserId,
//        _displayName = currentDisplayName;

//   final RealtimeService _realtime;
//   final TodRepository _repo;
//   final String _userId;
//   final String _displayName;
//   final bool isModerator;

//   // ── Session state ──────────────────────────────────────────────────────────
//   TruthOrDareEngine? _engine;
//   TodState? _state;
//   GameConfig? _config;
//   String? _roomId;
//   String? _sessionId;
//   bool _isOwner = false;
//   String? _packCoverUrl;

//   // ── Next-round readiness gate ─────────────────────────────────────────────
//   // Owner can't advance the turn until every other player has confirmed
//   // they've read the current response. Tracked here (not in TodState) since
//   // it's a per-turn UI gate, not persisted game state — it resets every turn.
//   final Set<String> _readyForNext = {};
//   Set<String> get readyForNext => Set.unmodifiable(_readyForNext);

//   /// Everyone except the owner themself must be ready before the owner can
//   /// advance — the owner is the one clicking "Next", they don't ready up
//   /// against themselves. Away players are exempt — their turns get skipped.
//   bool get allOthersReady {
//     final awayOrGone = _awayPlayerIds;
//     final others = (_state?.playerOrder ?? const <String>[])
//         .where((id) => id != _userId && !awayOrGone.contains(id))
//         .toSet();
//     return others.isEmpty || _readyForNext.containsAll(others);
//   }

//   bool get hasMarkedReady => _readyForNext.contains(_userId);

//   // ── Away / definitively-left players ────────────────────────────────────
//   // Maintained by the owner (who controls game flow) and broadcast to
//   // followers so they know whose turns to skip the turn indicator for.
//   final Set<String> _awayPlayerIds = {};

//   Set<String> get awayPlayerIds => Set.unmodifiable(_awayPlayerIds);

//   void markPlayerAway(String userId, {bool forGood = false}) {
//     _awayPlayerIds.add(userId);
//     // If it's their turn right now and admin hasn't paused, auto-advance
//     if (_isOwner &&
//         _state != null &&
//         _state!.currentPlayerId == userId &&
//         _state!.phase == TodTurnPhase.choosingType) {
//       Future.microtask(() => ownerAdvanceTurn(force: true));
//     }
//     _safeNotify();
//   }

//   void markPlayerReturned(String userId) {
//     _awayPlayerIds.remove(userId);
//     _safeNotify();
//   }

//   bool get isCurrentPlayerAway =>
//       _state != null && _awayPlayerIds.contains(_state!.currentPlayerId);

//   // ── Chat state ──────────────────────────────────────────────────────────────
//   final List<TodChatMsg> _chatMessages = [];
//   int _unreadChat = 0;
//   List<TodChatMsg> get chatMessages => _chatMessages;
//   int get unreadChat => _unreadChat;
//   void clearUnreadChat() {
//     _unreadChat = 0;
//     _safeNotify();
//   }

//   TodLoadState _loadState = TodLoadState.idle;
//   String? _error;
//   bool _hasSyncedState = false;
//   Timer? _syncTimeoutTimer;

//   // Player display names (resolved when game starts)
//   final _displayNames = <String, String>{};

//   // ── Timer ──────────────────────────────────────────────────────────────────
//   int _timerRemaining = 0;
//   bool _timerIsRunning = false;
//   Timer? _timerTicker;
//   Timer? _snapshotThrottle;

//   // ── Getters ────────────────────────────────────────────────────────────────
//   TodState? get state => _state;
//   String? get packCoverUrl => _packCoverUrl;
//   TodLoadState get loadState => _loadState;
//   String? get error => _error;
//   bool _disposed = false;

//   void _safeNotify() {
//     if (_disposed) return;
//     final phase = SchedulerBinding.instance.schedulerPhase;
//     if (phase == SchedulerPhase.persistentCallbacks ||
//         phase == SchedulerPhase.transientCallbacks ||
//         phase == SchedulerPhase.midFrameMicrotasks) {
//       SchedulerBinding.instance.addPostFrameCallback((_) {
//         if (!_disposed) notifyListeners();
//       });
//     } else {
//       notifyListeners();
//     }
//   }

//   bool get isOwner => _isOwner;
//   String get currentUserId => _userId;
//   bool get isReady => _loadState == TodLoadState.ready;
//   bool get hasSyncedState => _hasSyncedState;
//   int get timerRemaining => _timerRemaining;
//   bool get timerIsRunning => _timerIsRunning;

//   /// Pause the turn timer (called when player starts typing or picking media).

//   String? get sessionId => _sessionId;

//   bool get isMyTurn => _state?.currentPlayerId == _userId;
//   bool get canModerate => _isOwner || isModerator;
//   bool get isPunishmentPhase => _state?.phase == TodTurnPhase.punishmentVoting;
//   bool get isWaitingForChoice => _state?.phase == TodTurnPhase.choosingType;
//   bool get hasVotedOnPunishment {
//     final v = _state?.currentPunishmentVote;
//     return v?.votes.containsKey(_userId) ?? false;
//   }

//   /// Display name for any player in the game.
//   String displayNameFor(String userId) =>
//       _displayNames[userId] ?? 'Player ${userId.substring(0, 4)}';

//   // ── Owner: initialize ────────────────────────────────────────────────────
//   Future<void> initAsOwner({
//     required String roomId,
//     required GameConfig config,
//     required List<String> playerIds,
//     required Map<String, String> playerDisplayNames,
//     required String packId,
//     required bool isPremium,
//     String? packCoverUrl,
//   }) async {
//     _setLoading();
//     _roomId = roomId;
//     _packCoverUrl = packCoverUrl;
//     _config = config;
//     _isOwner = true;
//     _displayNames.addAll(playerDisplayNames);

//     try {
//       // 0. Pre-flight checks (quota + pack already played in this room).
//       final checkError = await sl.roomRepository.runGameSessionChecks(
//         userId: _userId,
//         roomId: roomId,
//         packId: packId,
//         isPremium: isPremium,
//       );
//       if (checkError == 'pack_already_played') {
//         _setError(
//           'This pack has already been played in this room. Choose a different pack.',
//         );
//         return;
//       }

//       // 1. Load cards — cache first, remote fallback
//       var cards = await _repo.loadCardsFromCache(
//         packId: packId,
//         language: config.language,
//         allowSpicy: config.allowSpicy,
//       );
//       if (cards.isEmpty) {
//         cards = await _repo.loadCards(
//           packId: packId,
//           language: config.language,
//           allowSpicy: config.allowSpicy,
//         );
//       }
//       if (cards.isEmpty) {
//         _setError(
//           'No cards found for this pack. Please select a different pack.',
//         );
//         return;
//       }

//       // 1b. Merge any custom cards added by premium players for this session.
//       // Custom cards are session-local (never in the shared pack) and exist
//       // in session_custom_cards. We load them after the session ID is known
//       // (step 3) and inject them into the deck — see step 3b below.

//       // 2. Build engine (deck loaded; state set below)
//       _engine = TruthOrDareEngine(config, cards: cards);

//       // 3. Resume an existing in-progress session if one exists, instead of
//       // always starting fresh. Without this, every time the owner enters
//       // this screen (including resuming a paused game) it silently created
//       // a brand-new game_sessions row and a brand-new engine state, so
//       // "Resume Game" never actually restored where the players left off.
//       final existing = await _repo.findActiveSession(roomId);
//       final existingSnapshot =
//           existing?['state_snapshot'] as Map<String, dynamic>?;
//       if (existing != null &&
//           existingSnapshot != null &&
//           existingSnapshot.isNotEmpty) {
//         _sessionId = existing['id'] as String;
//         _engine!.restoreFromSnapshot(existingSnapshot);
//         _state = _engine!.currentState as TodState;
//         AppLogger.info('TodGameProvider: resumed existing session $_sessionId');
//       } else {
//         _engine!.init(playerOrder: playerIds);
//         _state = _engine!.currentState as TodState;

//         // Persist session row
//         _sessionId = await _repo.createSession(
//           roomId: roomId,
//           packId: packId,
//           config: config,
//           playerIds: playerIds,
//           ownerId: _userId,
//         );
//       }

//       // 3b. Merge custom cards added by premium players into the deck.
//       // This runs after we have a session ID (whether resumed or new).
//       // Custom cards are always additive — they extend the deck, not
//       // replace any pack cards.
//       if (_sessionId != null) {
//         try {
//           final customCards = await _repo.loadCustomCards(_sessionId!);
//           if (customCards.isNotEmpty) {
//             cards = [...cards, ...customCards];
//             AppLogger.info(
//               'TodGameProvider: merged ${customCards.length} custom cards into deck',
//             );
//           }
//         } catch (e) {
//           AppLogger.warning('TodGameProvider: custom card load failed: $e');
//         }
//       }

//       // Rebuild the engine with the final merged card list so the custom
//       // cards are actually in the deck going forward.
//       if (_sessionId != null) {
//         _engine = TruthOrDareEngine(config, cards: cards);
//         if (_state != null) _engine!.restoreFromSnapshot(_state!.toMap());
//       }

//       // 4. Broadcast current (fresh or restored) snapshot to all followers
//       await _broadcastState();

//       // 5. Lazy DB snapshot every 10s
//       _startSnapshotThrottle();

//       _loadState = TodLoadState.ready;
//       _safeNotify();
//     } catch (e, st) {
//       AppLogger.error(
//         'TodGameProvider: initAsOwner failed',
//         error: e,
//         stackTrace: st,
//       );
//       _setError(e is Failure ? e.message : e.toString());
//     }
//   }

//   // ── Follower: connect ──────────────────────────────────────────────────────
//   void initAsFollower({
//     required String roomId,
//     required GameConfig config,
//     String? sessionId,
//     String? packCoverUrl,
//   }) {
//     _roomId = roomId;
//     _packCoverUrl = packCoverUrl;
//     _config = config;
//     _sessionId = sessionId;
//     _isOwner = false;
//     _loadState = TodLoadState.loading;

//     // Wait up to 8 seconds for owner broadcast; fallback to DB snapshot
//     _syncTimeoutTimer?.cancel();
//     _syncTimeoutTimer = Timer(const Duration(seconds: 8), () async {
//       if (!_hasSyncedState) {
//         AppLogger.warning('TodGameProvider: sync timeout — loading from DB');
//         await _tryLoadSnapshotFromDb();
//       }
//     });
//     _safeNotify();
//   }

//   // ── Broadcast receive (wired from TodGameScreen) ──────────────────────────

//   /// Called by TodGameScreen when a game_state broadcast arrives.
//   void onStateBroadcast(Map<String, dynamic> payload) {
//     final snapshot = payload['snapshot'] as Map<String, dynamic>?;
//     if (snapshot == null) return;

//     final incomingTs = snapshot['snapshot_at'] as int? ?? 0;
//     final currentTs = _state?.snapshotAt ?? 0;

//     // Discard stale broadcasts (already-seen or older snapshots)
//     if (incomingTs <= currentTs && _hasSyncedState) {
//       AppLogger.debug(
//         'TodGameProvider: stale broadcast ts=$incomingTs discarded',
//       );
//       return;
//     }

//     final previousRound = _state?.roundNumber;
//     _state = TodState.fromMap(snapshot);
//     _hasSyncedState = true;
//     _syncTimeoutTimer?.cancel();
//     _loadState = _state!.isOver ? TodLoadState.gameOver : TodLoadState.ready;

//     // New round started — any ready-for-next confirmations from the
//     // previous round no longer apply.
//     if (previousRound != null && _state!.roundNumber != previousRound) {
//       _readyForNext.clear();
//     }

//     _syncTimer();
//     _safeNotify();
//   }

//   /// Called when a `tod_ready_count` room event arrives (follower side) —
//   /// keeps everyone's view of who's ready in sync for display purposes.
//   /// The owner is the only one who actually enforces the gate, but this
//   /// lets followers see "2/3 ready" too.
//   void onReadyCountUpdate(List<String> readyUserIds) {
//     _readyForNext
//       ..clear()
//       ..addAll(readyUserIds);
//     _safeNotify();
//   }

//   /// Called by TodGameScreen when a player_action broadcast arrives (owner only).
//   void onPlayerAction(Map<String, dynamic> payload) {
//     if (!_isOwner || _engine == null) return;

//     final action = payload['action'] as String?;
//     if (action == 'tod_ready_next') {
//       final uid = payload['user_id'] as String?;
//       if (uid != null && _readyForNext.add(uid)) {
//         _safeNotify();
//         // Let followers know the live ready count (purely informational —
//         // the owner is the only one who actually enforces the gate).
//         _realtime.broadcastRoomEvent(_roomId ?? '', {
//           'type': 'tod_ready_count',
//           'ready_user_ids': _readyForNext.toList(),
//         }).ignore();
//       }
//       return;
//     }

//     final event = _parseEvent(payload);
//     if (event == null) {
//       AppLogger.warning('TodGameProvider: unknown action ${payload["action"]}');
//       return;
//     }

//     _engine!.handleEvent(event);
//     _state = _engine!.currentState as TodState;
//     _syncTimer();
//     _broadcastState();
//     _safeNotify();

//     if (_engine!.isGameOver) _handleGameOver();
//   }

//   /// Called by TodGameScreen when a sync_request broadcast arrives.
//   void onSyncRequest(Map<String, dynamic> payload) {
//     if (!_isOwner) return;
//     AppLogger.info(
//       'TodGameProvider: sync requested by ${payload["requester_id"]}',
//     );
//     _broadcastState();
//   }

//   // ── Player actions ─────────────────────────────────────────────────────────

//   Future<void> chooseTruth() => _handleAction({
//     'action': 'tod_choice',
//     'card_type': TodCardType.truth.name,
//   });

//   Future<void> chooseDare() => _handleAction({
//     'action': 'tod_choice',
//     'card_type': TodCardType.dare.name,
//   });

//   Future<void> completeTurn({
//     String response = '',
//     String proofImageB64 = '',
//     String proofVoiceB64 = '',
//     TodProofSource proofSource = TodProofSource.camera,
//     TodProofViewMode proofViewMode = TodProofViewMode.once,
//     int proofViewSeconds = 5,
//     TodProofVisibilitySettings proofVisibility =
//         const TodProofVisibilitySettings(),
//   }) => _handleAction({
//     'action': 'tod_complete',
//     'response': response,
//     'proof_image': proofImageB64,
//     'proof_voice': proofVoiceB64,
//     'proof_source': proofSource.name,
//     'proof_view_mode': proofViewMode.name,
//     'proof_view_seconds': proofViewSeconds,
//     'proof_visibility': proofVisibility.toMap(),
//   });

//   /// Mark the current turn's proof as viewed by me. Safe to call repeatedly
//   /// — only the first call per turn actually does anything.
//   Future<void> markProofViewed() =>
//       _handleAction({'action': 'tod_proof_viewed'});

//   /// Owner starts the 10-second proof-requirement vote.
//   Future<void> startProofVote() =>
//       _handleAction({'action': 'tod_start_proof_vote'});

//   /// Player casts their proof-requirement vote.
//   Future<void> castProofVote(TodProofVoteOption option) =>
//       _handleAction({'action': 'tod_cast_proof_vote', 'option': option.name});

//   Future<void> reactToResponse(String emoji) =>
//       _handleAction({'action': 'tod_react', 'emoji': emoji});

//   Future<void> voteForResponse() =>
//       _handleAction({'action': 'tod_vote_response'});

//   Future<void> skipTurn() => _handleAction({'action': 'tod_skip'});

//   /// Player confirms they've seen/read the current response and the owner
//   /// can move on once everyone else has done the same.
//   Future<void> markReadyForNext() {
//     if (_userId.isEmpty) return Future.value();
//     return _handleAction({'action': 'tod_ready_next'});
//   }

//   /// Premium players can add a custom card to the session-local deck.
//   /// The card is saved to session_custom_cards (not the shared pack) and
//   /// injected into the engine's remaining card pool immediately so it can
//   /// come up in the current game.
//   Future<({bool success, String? error})> addCustomCard({
//     required TodCardType type,
//     required String content,
//     required TodDifficulty difficulty,
//   }) async {
//     if (_sessionId == null || _roomId == null) {
//       return (success: false, error: 'Game not started yet');
//     }
//     if (!(_engine?.currentState is TodState)) {
//       return (success: false, error: 'Game not ready');
//     }
//     try {
//       final card = await _repo.addCustomCard(
//         sessionId: _sessionId!,
//         roomId: _roomId!,
//         addedBy: _userId,
//         type: type,
//         content: content.trim(),
//         difficulty: difficulty,
//       );
//       // Inject directly into the engine's remaining deck so it can appear
//       // this turn — no restart needed.
//       _engine?.injectCard(card);
//       _broadcastState();
//       return (success: true, error: null);
//     } catch (e) {
//       return (success: false, error: e.toString());
//     }
//   }

//   Future<void> voteOnPunishment(TodPunishmentVote vote) =>
//       _sendAction({'action': 'tod_vote_punishment', 'vote': vote.name});

//   Future<void> proposePunishment(String text) => _sendAction({
//     'action': 'tod_propose_punishment',
//     'punishment': TodPunishment(
//       id: _uuid.v4(),
//       text: text,
//       proposedBy: _userId,
//       proposedAt: DateTime.now().millisecondsSinceEpoch,
//     ).toMap(),
//   });

//   // ── Moderator actions ──────────────────────────────────────────────────────

//   Future<void> overridePunishment(
//     TodPunishmentVote decision, {
//     String? replacementText,
//   }) {
//     if (!canModerate) return Future.value();
//     return _sendAction({
//       'action': 'tod_moderator_override',
//       'decision': decision.name,
//       'replacement_text': replacementText,
//     });
//   }

//   /// Owner: advance to the next turn directly (bypasses phase checks).
//   /// Blocked until every other player has confirmed they're ready —
//   /// see [allOthersReady] / [markReadyForNext].
//   Future<void> ownerAdvanceTurn({bool force = false}) async {
//     if (!_isOwner || _engine == null) return;
//     if (!force && !allOthersReady) {
//       AppLogger.debug(
//         'TodGameProvider: advance blocked — waiting on ${(_state?.playerOrder ?? const <String>[]).where((id) => id != _userId && !_readyForNext.contains(id) && !_awayPlayerIds.contains(id)).toList()}',
//       );
//       return;
//     }
//     _readyForNext.clear();
//     _engine!.advanceTurn();
//     _state = _engine!.currentState as TodState;
//     _syncTimer();
//     _broadcastState();
//     _safeNotify();
//     if (_engine!.isGameOver) _handleGameOver();
//   }

//   Future<void> endGame({String reason = 'manual'}) =>
//       _sendAction({'action': 'tod_end_game', 'reason': reason});

//   Future<void> sendChat(String text) async {
//     if (_roomId == null || text.trim().isEmpty) return;
//     final msg = TodChatMsg(
//       senderId: _userId,
//       senderName: _displayNames[_userId] ?? 'Me',
//       text: text.trim(),
//       ts: DateTime.now(),
//     );
//     _chatMessages.add(msg);
//     _safeNotify();
//     try {
//       await _realtime.broadcastChat(_roomId!, {
//         'user_id': _userId,
//         'display_name': _displayNames[_userId] ?? 'Me',
//         'content': text.trim(),
//         'ts': DateTime.now().millisecondsSinceEpoch,
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
//     _timerRemaining = (_config!.turnTimerSeconds - elapsed).clamp(
//       0,
//       _config!.turnTimerSeconds,
//     );
//     _timerIsRunning = _timerRemaining > 0;

//     if (!_timerIsRunning) return;

//     _timerTicker = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (_timerRemaining > 0) {
//         _timerRemaining--;
//         _safeNotify();
//       }
//       if (_timerRemaining <= 0) {
//         _timerTicker?.cancel();
//         _timerIsRunning = false;

//         // Owner fires the timer expired event
//         if (_isOwner && _state?.currentPlayerId != null) {
//           _engine?.handleEvent(
//             TodTimerExpiredEvent(
//               userId: _state!.currentPlayerId,
//               ts: DateTime.now().millisecondsSinceEpoch,
//             ),
//           );
//           _state = _engine?.currentState as TodState?;
//           _broadcastState();
//           _safeNotify();
//         }
//       }
//     });
//   }

//   // ── Snapshot throttle ──────────────────────────────────────────────────────
//   void _startSnapshotThrottle() {
//     _snapshotThrottle?.cancel();
//     _snapshotThrottle = Timer.periodic(const Duration(seconds: 10), (_) {
//       if (_sessionId != null && _state != null && _isOwner) {
//         _repo
//             .saveSnapshot(sessionId: _sessionId!, snapshot: _state!.toMap())
//             .ignore();
//       }
//     });
//   }

//   // ── Internal ───────────────────────────────────────────────────────────────
//   Future<void> _handleAction(Map<String, dynamic> action) async {
//     final full = {
//       ...action,
//       'user_id': _userId,
//       'display_name': _displayName,
//       'ts': DateTime.now().millisecondsSinceEpoch,
//     };
//     // If this client is the owner/engine, process the event locally immediately.
//     // (Broadcasts with self:false never come back to the sender.)
//     if (_isOwner && _engine != null) {
//       onPlayerAction(full); // processes + broadcasts state to followers
//     } else {
//       // Follower — just broadcast the action for the owner to process
//       await _sendAction(action);
//     }
//   }

//   Future<void> _sendAction(Map<String, dynamic> action) async {
//     if (_roomId == null) return;
//     await _realtime.broadcastPlayerAction(_roomId!, {
//       ...action,
//       'user_id': _userId,
//       'display_name': _displayName,
//       'ts': DateTime.now().millisecondsSinceEpoch,
//     });
//   }

//   Future<void> _broadcastState() async {
//     if (_roomId == null || _state == null) return;
//     await _realtime.broadcastGameState(_roomId!, _state!.toMap(), _userId);
//   }

//   GameEngineEvent? _parseEvent(Map<String, dynamic> p) {
//     final action = p['action'] as String? ?? '';
//     final userId = p['user_id'] as String? ?? '';
//     final ts = p['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch;

//     return switch (action) {
//       'tod_choice' => TodChoiceEvent(
//         userId: userId,
//         ts: ts,
//         cardType: TodCardType.values.firstWhere(
//           (t) => t.name == p['card_type'],
//           orElse: () => TodCardType.truth,
//         ),
//       ),
//       'tod_complete' => TodCompleteEvent(
//         userId: userId,
//         ts: ts,
//         response: p['response'] as String? ?? '',
//         proofImageB64: p['proof_image'] as String? ?? '',
//         proofVoiceB64: p['proof_voice'] as String? ?? '',
//         proofSource: TodProofSource.values.firstWhere(
//           (s) => s.name == p['proof_source'],
//           orElse: () => TodProofSource.camera,
//         ),
//         proofViewMode: TodProofViewMode.values.firstWhere(
//           (m) => m.name == p['proof_view_mode'],
//           orElse: () => TodProofViewMode.once,
//         ),
//         proofViewSeconds: p['proof_view_seconds'] as int? ?? 5,
//         proofVisibility: p['proof_visibility'] != null
//             ? TodProofVisibilitySettings.fromMap(
//                 p['proof_visibility'] as Map<String, dynamic>,
//               )
//             : const TodProofVisibilitySettings(),
//       ),
//       'tod_proof_viewed' => TodProofViewedEvent(userId: userId, ts: ts),
//       'tod_start_proof_vote' => TodStartProofVoteEvent(userId: userId, ts: ts),
//       'tod_cast_proof_vote' => TodCastProofVoteEvent(
//         userId: userId,
//         ts: ts,
//         option: TodProofVoteOption.values.firstWhere(
//           (o) => o.name == p['option'],
//           orElse: () => TodProofVoteOption.noPreference,
//         ),
//       ),
//       'tod_react' => TodReactEvent(
//         userId: userId,
//         ts: ts,
//         emoji: p['emoji'] as String? ?? '👍',
//       ),
//       'tod_vote_response' => TodVoteResponseEvent(userId: userId, ts: ts),
//       'tod_skip' => TodSkipEvent(userId: userId, ts: ts),
//       'tod_vote_punishment' => TodVotePunishmentEvent(
//         userId: userId,
//         ts: ts,
//         vote: TodPunishmentVote.values.firstWhere(
//           (v) => v.name == p['vote'],
//           orElse: () => TodPunishmentVote.doIt,
//         ),
//       ),
//       'tod_propose_punishment' => TodProposePunishmentEvent(
//         userId: userId,
//         ts: ts,
//         punishment: TodPunishment.fromMap(
//           p['punishment'] as Map<String, dynamic>,
//         ),
//       ),
//       'tod_moderator_override' => TodModeratorOverrideEvent(
//         userId: userId,
//         ts: ts,
//         decision: TodPunishmentVote.values.firstWhere(
//           (v) => v.name == p['decision'],
//           orElse: () => TodPunishmentVote.doIt,
//         ),
//         replacementText: p['replacement_text'] as String?,
//       ),
//       'tod_end_game' => TodEndGameEvent(
//         userId: userId,
//         ts: ts,
//         reason: p['reason'] as String? ?? 'manual',
//       ),
//       _ => null,
//     };
//   }

//   Future<void> _tryLoadSnapshotFromDb() async {
//     if (_sessionId == null) return;
//     try {
//       final snapshot = await _repo.loadSnapshot(_sessionId!);
//       if (snapshot != null) {
//         _state = TodState.fromMap(snapshot);
//         _hasSyncedState = true;
//         _loadState = _state!.isOver
//             ? TodLoadState.gameOver
//             : TodLoadState.ready;
//         _syncTimer();
//         _safeNotify();
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
//       // Serialize scores as { userId: { points, truths, dares } }
//       final finalScores = _state!.scores.map(
//         (uid, s) => MapEntry(uid, s.toMap()),
//       );
//       _repo
//           .completeSession(
//             sessionId: _sessionId!,
//             finalSnapshot: _state!.toMap(),
//             endReason: _state!.endReason ?? 'round_limit',
//             finalScores: finalScores,
//           )
//           .ignore();
//     }
//     _safeNotify();
//   }

//   void _setLoading() {
//     _loadState = TodLoadState.loading;
//     _error = null;
//     _safeNotify();
//   }

//   void _setError(String msg) {
//     _loadState = TodLoadState.error;
//     _error = msg;
//     _safeNotify();
//   }

//   /// Admin/mod can kick a player mid-game. Broadcasts 'kick' room event so
//   /// the kicked player's screen navigates home, then removes them from the
//   /// turn order via the moderator override event.
//   Future<void> kickPlayerFromGame(String targetUserId) async {
//     if (!canModerate || _roomId == null) return;
//     // Broadcast the kick room event (screen handles navigation for the target)
//     await _realtime.broadcastRoomEvent(_roomId!, {
//       'type': 'kick',
//       'target_user_id': targetUserId,
//       'by': _userId,
//     });
//     // Remove from the game's player order
//     _handleAction({'action': 'tod_moderator_override', 'target': targetUserId});
//   }

//   void addChatMessage(TodChatMsg msg) {
//     if (_chatMessages.any(
//       (m) =>
//           m.senderName == msg.senderName &&
//           m.text == msg.text &&
//           msg.ts.difference(m.ts).abs().inSeconds < 2,
//     ))
//       return; // dedup
//     _chatMessages.add(msg);
//     _unreadChat++;
//     _safeNotify();
//   }

//   @override
//   void dispose() {
//     _disposed = true;
//     _timerTicker?.cancel();
//     _snapshotThrottle?.cancel();
//     _syncTimeoutTimer?.cancel();
//     super.dispose();
//   }
// }

// /// Simple in-game chat message — shared between TodGameProvider and the screen.
// class TodChatMsg {
//   const TodChatMsg({
//     required this.senderId,
//     required this.senderName,
//     required this.text,
//     required this.ts,
//   });
//   final String senderId;
//   final String senderName;
//   final String text;
//   final DateTime ts;
// }

import 'dart:async';
import 'package:flutter/scheduler.dart';

import 'package:flutter/foundation.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/errors/failures.dart';
import '../../../core/services/realtime_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../rooms/presentation/room_provider.dart';
import '../engine/base_game_engine.dart';
import 'data/tod_repository.dart';
import 'domain/tod_models.dart';
import 'tod_timer_service.dart';
import 'truth_or_dare_engine.dart';

enum TodLoadState { idle, loading, ready, error, gameOver }

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

  /// Set by the screen (which owns the RoomProvider reference) right after
  /// construction — lets the owner's client validate a moderator-delegated
  /// action (advance/skip turn, end game) sent by someone else's client
  /// against their actual granted permissions before executing it. The
  /// owner's client is the sole authority running the game engine, so this
  /// check must happen here, not just on the sender's side.
  bool Function(String userId, String permissionKey)? permissionChecker;

  bool _isAllowed(String? uid, String permissionKey) =>
      permissionChecker == null ||
      (uid != null && permissionChecker!(uid, permissionKey));

  /// Set by the screen right after construction, same as [permissionChecker]
  /// — gives this provider read access to the room's durable, backend-synced
  /// member list so turn/ready logic never has to trust its own ephemeral,
  /// broadcast-only away-tracking alone (see [_effectiveAwayIds]).
  RoomProvider? roomProvider;

  // Shared between _TodGameScreenState (owns the realtime listeners) and
  // _TodGameScaffoldState (owns the PopScope) via this single provider
  // instance, so a programmatic pop triggered by a realtime event (e.g.
  // onGameEnded) doesn't get misread by PopScope as the user backing out,
  // which would incorrectly open the Quit Game confirmation dialog.
  bool isNavigatingAway = false;

  TruthOrDareEngine? _engine;
  TodState? _state;
  GameConfig? _config;
  GameConfig? get config => _config;
  String? _roomId;
  String? get roomId => _roomId;
  String? _sessionId;
  bool _isOwner = false;
  String? _packCoverUrl;

  final Set<String> _readyForNext = {};
  Set<String> get readyForNext => Set.unmodifiable(_readyForNext);

  // A moderator entrusted with managing game flow (advance_turn/skip_turn)
  // shouldn't be blocked BY the ready gate any more than they're blocked
  // FROM forcing progression — this exempts them from being counted among
  // "others who must ready up", symmetric with the owner's own existing
  // exemption (trivially "everyone but me"). Must explicitly exclude the
  // owner: RoomProvider.memberHasPermission already ORs in isOwner, so a
  // naive check here would also silently exempt the owner from OTHER
  // players' ready-checks, which isn't what's being asked for.
  bool _isExemptModerator(String id) {
    final rp = roomProvider;
    if (rp == null || id == rp.room?.ownerId) return false;
    return rp.memberHasPermission(id, 'advance_turn') ||
        rp.memberHasPermission(id, 'skip_turn');
  }

  bool get allOthersReady {
    final awayOrGone = _effectiveAwayIds;
    final others = (_state?.playerOrder ?? const <String>[])
        .where(
          (id) =>
              id != _userId &&
              !awayOrGone.contains(id) &&
              !_isExemptModerator(id),
        )
        .toSet();
    return others.isEmpty || _readyForNext.containsAll(others);
  }

  bool get hasMarkedReady => _readyForNext.contains(_userId);

  final Set<String> _awayPlayerIds = {};

  /// Away/gone ids derived from the room's durable, backend-synced member
  /// list (kicked-from-game is persisted to `room_members.is_away`, kicked-
  /// or-left-from-room drops the row from `roomProvider.members` entirely —
  /// see `getRoomWithDetails`). Unlike [_awayPlayerIds] (fed only by a
  /// one-shot moderation broadcast this specific client happened to be
  /// connected for), this reflects a fresh fetch + realtime `room_members`
  /// subscription, so a client that reconnected, briefly dropped, or joined
  /// after the broadcast fired still computes the correct active-player set.
  Set<String> get _durableAwayIds {
    final rp = roomProvider;
    final order = _state?.playerOrder;
    if (rp == null || order == null) return const {};
    final members = {for (final m in rp.members) m.userId: m};
    return order.where((id) {
      final m = members[id];
      return m == null || m.isAway || m.isDisconnected;
    }).toSet();
  }

  /// The set actually used for turn/ready computations — the union of the
  /// instant, locally-witnessed broadcast signal and the durable, backend-
  /// synced one. Neither alone is sufficient: the local set reacts instantly
  /// but is lost on reconnect; the durable one is always eventually correct
  /// but may lag a beat behind the broadcast on the acting client itself.
  Set<String> get _effectiveAwayIds => _awayPlayerIds.union(_durableAwayIds);

  Set<String> get awayPlayerIds => Set.unmodifiable(_effectiveAwayIds);

  /// Live count of players still actually in the game (excludes
  /// kicked/banned/left players) — `playerOrder.length` is frozen at game
  /// start since `playerOrder` never shrinks for the life of a session.
  int get activePlayerCount =>
      (_state?.playerOrder ?? const <String>[])
          .where((id) => !_effectiveAwayIds.contains(id))
          .length;

  void markPlayerAway(String userId, {bool forGood = false}) {
    _awayPlayerIds.add(userId);
    if (_isOwner &&
        _state != null &&
        _state!.currentPlayerId == userId &&
        _state!.phase == TodTurnPhase.choosingType) {
      Future.microtask(() => ownerAdvanceTurn(force: true));
    }
    _safeNotify();
  }

  void markPlayerReturned(String userId) {
    _awayPlayerIds.remove(userId);
    _safeNotify();
  }

  bool get isCurrentPlayerAway =>
      _state != null && _effectiveAwayIds.contains(_state!.currentPlayerId);

  final List<TodChatMsg> _chatMessages = [];
  int _unreadChat = 0;
  List<TodChatMsg> get chatMessages => _chatMessages;
  int get unreadChat => _unreadChat;
  void clearUnreadChat() {
    _unreadChat = 0;
    _safeNotify();
  }

  TodLoadState _loadState = TodLoadState.idle;
  String? _error;
  bool _hasSyncedState = false;
  Timer? _syncTimeoutTimer;

  // Followers never run the engine — they're a pure renderer of whatever
  // state last arrived over a fire-and-forget realtime broadcast (no ack,
  // no retry, no replay). The existing snapshot_at ordering guard in
  // onStateBroadcast protects against a *stale* (out-of-order) update but
  // does nothing for a *missing* one on an otherwise-healthy socket — this
  // watchdog is what actually detects "I haven't heard anything in a
  // while" and self-heals, first by asking the owner to resend, then (if
  // that doesn't land either) by reading straight from the database, which
  // the owner persists periodically regardless of whether any broadcast
  // succeeds. This is the general-purpose backstop every "stuck waiting"
  // symptom needs — not a per-action patch.
  DateTime _lastStateReceivedAt = DateTime.now();
  Timer? _staleWatchdog;
  DateTime? _lastStaleRecoveryAttempt;
  static const _staleThreshold = Duration(seconds: 15);
  static const _staleRecoveryCooldown = Duration(seconds: 10);

  void _startStaleWatchdog() {
    _staleWatchdog?.cancel();
    _staleWatchdog = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_isOwner || _state == null || _state!.isOver || _roomId == null) {
        return;
      }
      final sinceLastState = DateTime.now().difference(_lastStateReceivedAt);
      if (sinceLastState <= _staleThreshold) return;

      final lastAttempt = _lastStaleRecoveryAttempt;
      if (lastAttempt != null &&
          DateTime.now().difference(lastAttempt) < _staleRecoveryCooldown) {
        return;
      }
      _lastStaleRecoveryAttempt = DateTime.now();
      AppLogger.warning(
        'TodGameProvider: no state broadcast for ${sinceLastState.inSeconds}s — requesting resync',
      );
      _realtime
          .broadcastSyncRequest(_roomId!, _userId, _state?.roundNumber ?? 0)
          .ignore();

      // Give the owner a short window to answer the resync request over
      // realtime before falling back to a direct DB read — the DB read is
      // the guaranteed-to-work path (it doesn't depend on any broadcast
      // succeeding), but the realtime round-trip is faster when it works.
      Timer(const Duration(seconds: 4), () {
        if (_disposed || _isOwner) return;
        if (DateTime.now().difference(_lastStateReceivedAt) >
            _staleThreshold) {
          AppLogger.warning(
            'TodGameProvider: resync request unanswered — reading state from DB',
          );
          _tryLoadSnapshotFromDb();
        }
      });
    });
  }

  final _displayNames = <String, String>{};

  int _timerRemaining = 0;
  bool _timerIsRunning = false;
  Timer? _timerTicker;
  Timer? _snapshotThrottle;

  TodState? get state => _state;
  String? get packCoverUrl => _packCoverUrl;
  TodLoadState get loadState => _loadState;
  String? get error => _error;
  bool _disposed = false;

  void _safeNotify() {
    if (_disposed) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.transientCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  bool get isOwner => _isOwner;
  String get currentUserId => _userId;
  bool get isReady => _loadState == TodLoadState.ready;
  bool get hasSyncedState => _hasSyncedState;

  /// Whether the CURRENT client can trigger the given moderator-delegated
  /// action here — the owner always can; otherwise checked against the
  /// permission the room granted this user (via [permissionChecker]).
  bool _canHere(String permissionKey) =>
      _isOwner || (permissionChecker?.call(_userId, permissionKey) ?? false);
  bool get canAdvanceTurnHere =>
      _canHere('advance_turn') || _canHere('skip_turn');
  int get timerRemaining => _timerRemaining;
  bool get timerIsRunning => _timerIsRunning;

  String? get sessionId => _sessionId;

  bool get isMyTurn => _state?.currentPlayerId == _userId;
  bool get canModerate => _isOwner || isModerator;
  bool get isPunishmentPhase => _state?.phase == TodTurnPhase.punishmentVoting;
  bool get isWaitingForChoice => _state?.phase == TodTurnPhase.choosingType;
  /// Whether I (a non-skipped player) have already submitted my one
  /// punishment option for the current skip.
  bool get hasSubmittedPunishment {
    final v = _state?.currentPunishmentVote;
    return v?.options.any((o) => o.proposedBy == _userId) ?? false;
  }

  String displayNameFor(String userId) =>
      _displayNames[userId] ?? 'Player ${userId.substring(0, 4)}';

  Future<void> initAsOwner({
    required String roomId,
    required GameConfig config,
    required List<String> playerIds,
    required Map<String, String> playerDisplayNames,
    required String packId,
    required bool isPremium,
    String? packCoverUrl,
  }) async {
    _setLoading();
    _roomId = roomId;
    _packCoverUrl = packCoverUrl;
    _config = config;
    _isOwner = true;
    _displayNames.addAll(playerDisplayNames);

    try {
      final checkError = await sl.roomRepository.runGameSessionChecks(
        userId: _userId,
        roomId: roomId,
        packId: packId,
        isPremium: isPremium,
      );
      if (checkError == 'pack_already_played') {
        _setError(
          'This pack has already been played in this room. Choose a different pack.',
        );
        return;
      }

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

      _engine = TruthOrDareEngine(config, cards: cards);

      var existing = await _repo.findActiveSession(roomId);
      existing ??= await _repo.findLatestSession(roomId);
      final existingStatus = existing?['status'] as String?;
      final existingSnapshot =
          existing?['state_snapshot'] as Map<String, dynamic>?;
      if (existing != null &&
          existingSnapshot != null &&
          existingSnapshot.isNotEmpty &&
          (existingStatus == 'active' ||
              existingStatus == 'completed' ||
              existingStatus == 'aborted')) {
        _sessionId = existing['id'] as String;
        _engine!.restoreFromSnapshot(existingSnapshot);
        _state = _engine!.currentState as TodState;
        _gameOverHandled = existingStatus != 'active';
        AppLogger.info('TodGameProvider: resumed existing session $_sessionId');
      } else {
        _engine!.init(playerOrder: playerIds);
        _state = _engine!.currentState as TodState;

        _sessionId = await _repo.createSession(
          roomId: roomId,
          packId: packId,
          config: config,
          playerIds: playerIds,
          ownerId: _userId,
        );
      }

      if (_sessionId != null) {
        try {
          final customCards = await _repo.loadCustomCards(_sessionId!);
          if (customCards.isNotEmpty) {
            cards = [...cards, ...customCards];
            AppLogger.info(
              'TodGameProvider: merged ${customCards.length} custom cards into deck',
            );
          }
        } catch (e) {
          AppLogger.warning('TodGameProvider: custom card load failed: $e');
        }
      }

      if (_sessionId != null) {
        _engine = TruthOrDareEngine(config, cards: cards);
        if (_state != null) _engine!.restoreFromSnapshot(_state!.toMap());
      }

      await _broadcastState();

      _startSnapshotThrottle();

      _loadState = (_state?.isOver ?? false)
          ? TodLoadState.gameOver
          : TodLoadState.ready;
      _safeNotify();
    } catch (e, st) {
      AppLogger.error(
        'TodGameProvider: initAsOwner failed',
        error: e,
        stackTrace: st,
      );
      _setError(e is Failure ? e.message : e.toString());
    }
  }

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

    _syncTimeoutTimer?.cancel();
    _syncTimeoutTimer = Timer(const Duration(seconds: 8), () async {
      if (!_hasSyncedState) {
        AppLogger.warning('TodGameProvider: sync timeout — loading from DB');
        await _tryLoadSnapshotFromDb();
      }
    });
    _lastStateReceivedAt = DateTime.now();
    _startStaleWatchdog();
    _safeNotify();
  }

  /// Called when [RoomProvider.isOwner] changes mid-game (room ownership
  /// transferred). A follower never runs a local [_engine] — it only tracks
  /// [_state] from broadcasts — so becoming the new authoritative owner
  /// means constructing one from the last-synced state before this provider
  /// can start applying/broadcasting actions. The old owner just stops
  /// broadcasting and keeps receiving state as a normal follower from here.
  Future<void> applyOwnershipChange(bool amOwner) async {
    if (amOwner == _isOwner) return;
    if (!amOwner) {
      _isOwner = false;
      // Now a follower — needs the same staleness watchdog a client that
      // started as a follower gets from initAsFollower(). Reset the clock
      // so this transition itself doesn't immediately read as "stale".
      _lastStateReceivedAt = DateTime.now();
      _startStaleWatchdog();
      _safeNotify();
      return;
    }
    if (_engine == null && _state != null && _config != null) {
      try {
        _engine = await _buildEngineFromCurrentState(_config!);
      } catch (e) {
        AppLogger.error('TodGameProvider: ownership handoff engine build failed: $e');
        return;
      }
    }
    if (_engine == null) return;
    _isOwner = true;
    _startSnapshotThrottle();
    _syncTimer();
    _safeNotify();
  }

  /// Loads the deck for [config] and builds a fresh engine restored from
  /// the current synced [_state] — the same card-loading/custom-card-merge
  /// steps [initAsOwner] runs at game start, reused here for the ownership
  /// mid-game handoff so there's one implementation of "build a working
  /// engine for this room's session", not two.
  Future<TruthOrDareEngine> _buildEngineFromCurrentState(
    GameConfig config,
  ) async {
    var cards = <TodCard>[];
    final packId = config.packId;
    if (packId != null) {
      cards = await _repo.loadCardsFromCache(
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
    }
    if (_sessionId != null) {
      try {
        final customCards = await _repo.loadCustomCards(_sessionId!);
        if (customCards.isNotEmpty) cards = [...cards, ...customCards];
      } catch (e) {
        AppLogger.warning('TodGameProvider: custom card load failed: $e');
      }
    }
    final engine = TruthOrDareEngine(config, cards: cards);
    engine.restoreFromSnapshot(_state!.toMap());
    return engine;
  }

  void onStateBroadcast(Map<String, dynamic> payload) {
    final snapshot = payload['snapshot'] as Map<String, dynamic>?;
    if (snapshot == null) return;

    final incomingTs = snapshot['snapshot_at'] as int? ?? 0;
    final currentTs = _state?.snapshotAt ?? 0;

    if (incomingTs <= currentTs && _hasSyncedState) {
      AppLogger.debug(
        'TodGameProvider: stale broadcast ts=$incomingTs discarded',
      );
      return;
    }

    final previousTurnStartedAt = _state?.turnStartedAt;
    _state = TodState.fromMap(snapshot);
    _hasSyncedState = true;
    _lastStateReceivedAt = DateTime.now();
    _syncTimeoutTimer?.cancel();
    _loadState = _state!.isOver ? TodLoadState.gameOver : TodLoadState.ready;

    // Ready state must reset every TURN, not every ROUND — roundNumber only
    // increments when the turn index wraps back to 0 across the full
    // player order, but the owner's `_readyForNext` is cleared on every
    // single turn advance (ownerAdvanceTurn). Using roundNumber here left
    // a follower's stale "already marked ready" flag in place for every
    // non-wrapping turn, so `markReadyForNext()`'s already-ready guard
    // silently dropped their next ready press forever and the owner could
    // never see everyone ready again. turnStartedAt is set fresh by the
    // engine on every advanceTurn() call, unlike roundNumber.
    if (previousTurnStartedAt != null &&
        _state!.turnStartedAt != previousTurnStartedAt) {
      _readyForNext.clear();
      _myReadyIntent = false;
    }

    _syncTimer();
    _safeNotify();
  }

  int _lastReadyCountTs = 0;

  void onReadyCountUpdate(
    List<String> readyUserIds, {
    int? ts,
    int? turnStartedAt,
  }) {
    // A ready_count broadcast is only meaningful for the round it was
    // computed for. State-broadcast and ready-count travel as two separate
    // messages with no ordering guarantee between them — the very last
    // ready_count of a round (the one that made everyone ready and caused
    // the advance) can arrive AFTER the new round's state broadcast already
    // reset _readyForNext, and since its ts is not necessarily older than
    // _lastReadyCountTs it would otherwise slip past the ts guard below and
    // re-populate the stale, already-complete list for the round that just
    // ended — this is what made the Ready button get stuck forever. Tagging
    // every ready_count with the round it belongs to (turnStartedAt) and
    // rejecting a mismatch closes that gap regardless of ts ordering.
    if (turnStartedAt != null &&
        _state?.turnStartedAt != null &&
        turnStartedAt != _state!.turnStartedAt) {
      return;
    }
    // Multiple players marking ready in quick succession fires multiple
    // ready_count broadcasts back to back — with no delivery-order
    // guarantee, an older one arriving after a newer one would otherwise
    // silently un-ready someone who already marked ready.
    if (ts != null && ts < _lastReadyCountTs) return;
    if (ts != null) _lastReadyCountTs = ts;
    _readyForNext
      ..clear()
      ..addAll(readyUserIds);
    // Self-heal a lost tod_ready_next broadcast: if I intended to be ready
    // for this round but the owner's authoritative list doesn't have me
    // (their copy never received my original press — no ack/retry on
    // realtime broadcasts), resend rather than leaving myself and the
    // host stuck forever.
    if (_myReadyIntent && !_readyForNext.contains(_userId)) {
      _readyForNext.add(_userId); // keep the "You're ready" UI stable
      _handleAction({'action': 'tod_ready_next'}).ignore();
    }
    _safeNotify();
  }

  // Cosmetic-only "Ahmed is answering…" style indicator — fire-and-forget,
  // like tod_ready_count above. A missed or duplicate broadcast has no
  // correctness impact (unlike game state itself, which gets the stronger
  // snapshot/watchdog guarantees), so this deliberately doesn't get its own
  // ack/retry/DB-fallback machinery.
  String? _peerActivity;
  String? _peerActivityUserId;
  int? _peerActivityTurnStartedAt;
  int? _lastAnnouncedChoosingTurn;

  /// The current activity label to show for the OTHER player performing the
  /// turn (never for yourself), or null if there's nothing current — either
  /// no activity has been reported yet, or it belongs to a turn that has
  /// since ended (same staleness guard shape as the ready-count one above).
  String? get peerActivityLabel {
    if (_peerActivity == null || _peerActivityUserId == _userId) return null;
    if (_peerActivityTurnStartedAt != _state?.turnStartedAt) return null;
    return _peerActivity;
  }

  String? get peerActivityUserId =>
      peerActivityLabel == null ? null : _peerActivityUserId;

  /// Called by the acting player's own client at natural transition points
  /// (opening the response sheet, starting a proof upload, submitting).
  void broadcastActivity(String activity) {
    if (_roomId == null || _state == null) return;
    _realtime.broadcastRoomEvent(_roomId!, {
      'type': 'tod_player_activity',
      'user_id': _userId,
      'activity': activity,
      'turn_started_at': _state!.turnStartedAt,
      'ts': DateTime.now().millisecondsSinceEpoch,
    }).ignore();
  }

  /// The "choosing" state is announced by the OWNER's client instead (see
  /// _broadcastState below) since only the owner's engine knows a fresh
  /// turn has started — the acting player may not even be the owner.
  void _maybeAnnounceChoosing() {
    final s = _state;
    if (s == null) return;
    if (s.phase != TodTurnPhase.choosingType) return;
    if (_lastAnnouncedChoosingTurn == s.turnStartedAt) return;
    _lastAnnouncedChoosingTurn = s.turnStartedAt;
    if (_roomId == null) return;
    _realtime.broadcastRoomEvent(_roomId!, {
      'type': 'tod_player_activity',
      'user_id': s.currentPlayerId,
      'activity': 'choosing',
      'turn_started_at': s.turnStartedAt,
      'ts': DateTime.now().millisecondsSinceEpoch,
    }).ignore();
  }

  void onPlayerActivityUpdate(Map<String, dynamic> payload) {
    final uid = payload['user_id'] as String?;
    final activity = payload['activity'] as String?;
    if (uid == null || activity == null) return;
    _peerActivityUserId = uid;
    _peerActivity = activity;
    _peerActivityTurnStartedAt = payload['turn_started_at'] as int?;
    _safeNotify();
  }

  void onPlayerAction(Map<String, dynamic> payload) {
    if (!_isOwner || _engine == null) return;

    final action = payload['action'] as String?;
    if (action == 'tod_ready_next') {
      final uid = payload['user_id'] as String?;
      final isPlayer = _state?.playerOrder.contains(uid) ?? false;
      if (uid != null && isPlayer && _readyForNext.add(uid)) {
        _safeNotify();
        final ts = DateTime.now().millisecondsSinceEpoch;
        _lastReadyCountTs = ts;
        _realtime.broadcastRoomEvent(_roomId ?? '', {
          'type': 'tod_ready_count',
          'ready_user_ids': _readyForNext.toList(),
          'ts': ts,
          'turn_started_at': _state?.turnStartedAt,
        }).ignore();
      }
      return;
    }
    if (action == 'tod_mod_advance_turn') {
      final uid = payload['user_id'] as String?;
      final force = payload['force'] as bool? ?? false;
      if (_isAllowed(uid, 'advance_turn') || _isAllowed(uid, 'skip_turn')) {
        ownerAdvanceTurn(force: force);
      }
      return;
    }
    if (action == 'tod_pause_timer' || action == 'tod_resume_timer') {
      final uid = payload['user_id'] as String?;
      final s = _state;
      // Only the player currently up can pause/resume their own timer.
      if (s == null || uid == null || uid != s.currentPlayerId) return;
      if (action == 'tod_pause_timer') {
        if (s.timerPausedAt != null) return;
        _state = s.copyWith(
          snapshotAt: DateTime.now().millisecondsSinceEpoch,
          timerPausedAt: () => DateTime.now().millisecondsSinceEpoch,
        );
      } else {
        if (s.timerPausedAt == null) return;
        final pausedDuration =
            DateTime.now().millisecondsSinceEpoch - s.timerPausedAt!;
        _state = s.copyWith(
          snapshotAt: DateTime.now().millisecondsSinceEpoch,
          timerStartedAt: () => (s.timerStartedAt ?? 0) + pausedDuration,
          timerPausedAt: () => null,
        );
      }
      _syncTimer();
      _broadcastState();
      _safeNotify();
      return;
    }

    // tod_end_game can also be sent directly by the owner's own client
    // (via _handleAction's local-apply branch, not a broadcast round
    // trip) — but if it ever arrives here as an actual received broadcast
    // from someone else, ending the game is owner-only, never delegable.
    if (action == 'tod_end_game' &&
        payload['user_id'] != roomProvider?.room?.ownerId) {
      return;
    }

    final event = _parseEvent(payload);
    if (event == null) {
      AppLogger.warning('TodGameProvider: unknown action ${payload["action"]}');
      return;
    }

    _engine!.handleEvent(event);
    _state = _engine!.currentState as TodState;
    _syncTimer();
    _broadcastState();
    _safeNotify();

    if (_engine!.isGameOver) _handleGameOver();
  }

  void onSyncRequest(Map<String, dynamic> payload) {
    if (!_isOwner) return;
    AppLogger.info(
      'TodGameProvider: sync requested by ${payload["requester_id"]}',
    );
    _broadcastState();
    // The ready list is broadcast separately from game state (as a room
    // event, not part of the snapshot) — resend it here too so a client
    // that reconnected mid-round doesn't miss it and get stuck waiting.
    final ts = DateTime.now().millisecondsSinceEpoch;
    _lastReadyCountTs = ts;
    _realtime.broadcastRoomEvent(_roomId ?? '', {
      'type': 'tod_ready_count',
      'ready_user_ids': _readyForNext.toList(),
      'ts': ts,
      'turn_started_at': _state?.turnStartedAt,
    }).ignore();
  }

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
    String proofVoiceB64 = '',
    TodProofSource proofSource = TodProofSource.camera,
    TodProofViewMode proofViewMode = TodProofViewMode.once,
    int proofViewSeconds = 5,
    TodProofVisibilitySettings proofVisibility =
        const TodProofVisibilitySettings(),
  }) => _handleAction({
    'action': 'tod_complete',
    'response': response,
    'proof_image': proofImageB64,
    'proof_voice': proofVoiceB64,
    'proof_source': proofSource.name,
    'proof_view_mode': proofViewMode.name,
    'proof_view_seconds': proofViewSeconds,
    'proof_visibility': proofVisibility.toMap(),
  });

  Future<void> markProofViewed() =>
      _handleAction({'action': 'tod_proof_viewed'});

  Future<void> startProofVote() =>
      _handleAction({'action': 'tod_start_proof_vote'});

  Future<void> castProofVote(TodProofVoteOption option) =>
      _handleAction({'action': 'tod_cast_proof_vote', 'option': option.name});

  Future<void> reactToResponse(String emoji) =>
      _handleAction({'action': 'tod_react', 'emoji': emoji});

  Future<void> voteForResponse() =>
      _handleAction({'action': 'tod_vote_response'});

  Future<void> skipTurn() => _handleAction({'action': 'tod_skip'});

  // Durable "I intend to be ready for the current round" flag — unlike
  // _readyForNext (which gets wholesale overwritten by each authoritative
  // tod_ready_count broadcast), this survives a broadcast that never
  // reached the owner, so onReadyCountUpdate can detect the mismatch and
  // resend instead of leaving the presser stuck forever. Cleared only on
  // an actual round change or reconnect-with-fresh-state.
  bool _myReadyIntent = false;

  Future<void> markReadyForNext() {
    final isPlayer = _state?.playerOrder.contains(_userId) ?? false;
    if (_userId.isEmpty || hasMarkedReady || !isPlayer) return Future.value();
    _myReadyIntent = true;
    // Optimistic local update so the UI (gated on hasMarkedReady) disables
    // the button immediately, instead of waiting on the realtime round-trip
    // through the owner and back — which left the button tappable and let
    // rapid taps fire redundant broadcasts.
    _readyForNext.add(_userId);
    _safeNotify();
    return _handleAction({'action': 'tod_ready_next'});
  }

  Future<({bool success, String? error})> addCustomCard({
    required TodCardType type,
    required String content,
    required TodDifficulty difficulty,
  }) async {
    if (_sessionId == null || _roomId == null) {
      return (success: false, error: 'Game not started yet');
    }
    if (!(_engine?.currentState is TodState)) {
      return (success: false, error: 'Game not ready');
    }
    try {
      final card = await _repo.addCustomCard(
        sessionId: _sessionId!,
        roomId: _roomId!,
        addedBy: _userId,
        type: type,
        content: content.trim(),
        difficulty: difficulty,
      );
      _engine?.injectCard(card);
      _broadcastState();
      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  Future<void> voteOnPunishment(String optionId) => _handleAction({
    'action': 'tod_vote_punishment',
    'option_id': optionId,
  });

  /// Every non-skipped player submits exactly one punishment option — the
  /// skipped player later picks one from the collected set themselves.
  Future<void> submitPunishment(String text) {
    if (text.trim().isEmpty) return Future.value();
    return _handleAction({'action': 'tod_propose_punishment', 'text': text});
  }

  Future<void> overridePunishment(String optionId) {
    if (!canModerate) return Future.value();
    return _handleAction({
      'action': 'tod_moderator_override',
      'option_id': optionId,
    });
  }

  bool _advancing = false;

  Future<void> ownerAdvanceTurn({bool force = false}) async {
    if (!_isOwner || _engine == null) return;
    if (!force && !allOthersReady) {
      AppLogger.debug(
        'TodGameProvider: advance blocked — waiting on ${(_state?.playerOrder ?? const <String>[]).where((id) => id != _userId && !_readyForNext.contains(id) && !_effectiveAwayIds.contains(id)).toList()}',
      );
      return;
    }
    // Explicit re-entrancy guard against a rapid double-tap triggering two
    // engine advances back to back — previously only prevented by the
    // ordering accident of clearing _readyForNext synchronously right
    // before mutating the engine, with no await in between.
    if (_advancing) return;
    _advancing = true;
    try {
      _readyForNext.clear();
      _engine!.advanceTurn();
      _state = _engine!.currentState as TodState;
      // playerOrder is fixed for the life of the session — a kicked/left
      // player is never removed from it, only added to _awayPlayerIds. The
      // engine's turn rotation has no concept of "away", so left unchecked
      // the rotation would eventually land back on them in a later round
      // with no one able to act, stalling the game. Skip forward past any
      // away player here so the game keeps moving without them, exactly as
      // if they'd been removed from playerOrder.
      var guard = 0;
      while (!_state!.isOver &&
          _effectiveAwayIds.contains(_state!.currentPlayerId) &&
          guard < _state!.playerOrder.length) {
        _engine!.advanceTurn();
        _state = _engine!.currentState as TodState;
        guard++;
      }
      _syncTimer();
      _broadcastState();
      _safeNotify();
      if (_engine!.isGameOver) _handleGameOver();
    } finally {
      _advancing = false;
    }
  }

  Future<void> endGame({String reason = 'manual'}) =>
      _handleAction({'action': 'tod_end_game', 'reason': reason});

  /// Advance/skip the turn, delegating to the owner's client if the caller
  /// isn't the owner — used by a moderator granted 'advance_turn' or
  /// 'skip_turn' (the engine has one underlying advance mechanic; `force`
  /// is what makes it a "skip" in the UI's sense of forcing past a stuck
  /// reader).
  Future<void> requestAdvanceTurn({bool force = false}) async {
    if (_isOwner) {
      await ownerAdvanceTurn(force: force);
      return;
    }
    if (_roomId == null) return;
    await _realtime.broadcastPlayerAction(_roomId!, {
      'action': 'tod_mod_advance_turn',
      'force': force,
      'user_id': _userId,
      'display_name': _displayName,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Ending the game is owner-only — never delegable to a moderator, even
  /// via a granted permission (the old 'end_game' delegation broadcast,
  /// tod_mod_end_game, is gone; only the owner's own client can call this).
  Future<void> requestEndGame({String reason = 'manual'}) async {
    if (!_isOwner) return;
    await endGame(reason: reason);
  }

  Future<void> sendChat(String text) async {
    if (_roomId == null || text.trim().isEmpty) return;
    if (_effectiveAwayIds.contains(_userId)) return;
    final msg = TodChatMsg(
      senderId: _userId,
      senderName: _displayNames[_userId] ?? 'Me',
      text: text.trim(),
      ts: DateTime.now(),
    );
    _chatMessages.add(msg);
    _safeNotify();
    try {
      await _realtime.broadcastChat(_roomId!, {
        'user_id': _userId,
        'display_name': _displayNames[_userId] ?? 'Me',
        'content': text.trim(),
        'ts': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}
  }

  /// Pauses the turn timer for everyone (owner, other players, and
  /// spectators alike) — e.g. while the current player is performing their
  /// truth/dare. Stored in canonical TodState (not a one-off broadcast), so
  /// _syncTimer() derives the same paused state for every client, including
  /// one that (re)joins or resyncs while the pause is active.
  Future<void> pauseTimer() =>
      _handleAction({'action': 'tod_pause_timer'});

  /// Resumes a previously paused turn timer, preserving the remaining time.
  Future<void> resumeTimer() =>
      _handleAction({'action': 'tod_resume_timer'});

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

    if (s.timerPausedAt != null) {
      final elapsedAtPause =
          (s.timerPausedAt! - s.timerStartedAt!) ~/ 1000;
      _timerRemaining = (_config!.turnTimerSeconds - elapsedAtPause).clamp(
        0,
        _config!.turnTimerSeconds,
      );
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
        _safeNotify();
      }
      if (_timerRemaining <= 0) {
        _timerTicker?.cancel();
        _timerIsRunning = false;

        if (_isOwner && _state?.currentPlayerId != null) {
          _engine?.handleEvent(
            TodTimerExpiredEvent(
              userId: _state!.currentPlayerId,
              ts: DateTime.now().millisecondsSinceEpoch,
            ),
          );
          _state = _engine?.currentState as TodState?;
          _broadcastState();
          _safeNotify();
        }
      }
    });
  }

  void _startSnapshotThrottle() {
    _snapshotThrottle?.cancel();
    // Tightened from 10s: this is the only thing standing between an owner
    // crash and up to a full interval of lost state for the DB-reconciliation
    // fallback (see _startStaleWatchdog) to recover from — NHIE/Meme persist
    // on every broadcast already, so this closes most of the asymmetry
    // between the three games' loss windows without needing a full
    // debounce-per-mutation rewrite.
    _snapshotThrottle = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_sessionId != null && _state != null && _isOwner) {
        _repo
            .saveSnapshot(sessionId: _sessionId!, snapshot: _state!.toMap())
            .ignore();
      }
    });
  }

  Future<void> _handleAction(Map<String, dynamic> action) async {
    // A kicked/banned/left player must not be able to act again even in the
    // brief window before their client has processed the moderation
    // broadcast and navigated away — this is the single chokepoint every
    // player-initiated action (submit/vote/react/ready/punishment-vote)
    // routes through.
    if (_effectiveAwayIds.contains(_userId)) return;
    // Moderator-imposed game mute (RoomMemberEntity.isGameMuted, distinct
    // from chat mute) — muted players can still watch but not act.
    if (roomProvider?.currentMember?.isGameMuted ?? false) return;
    final full = {
      ...action,
      'user_id': _userId,
      'display_name': _displayName,
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
    if (_isOwner && _engine != null) {
      onPlayerAction(full);
    } else {
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
    _maybeAnnounceChoosing();
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
        proofVoiceB64: p['proof_voice'] as String? ?? '',
        proofSource: TodProofSource.values.firstWhere(
          (s) => s.name == p['proof_source'],
          orElse: () => TodProofSource.camera,
        ),
        proofViewMode: TodProofViewMode.values.firstWhere(
          (m) => m.name == p['proof_view_mode'],
          orElse: () => TodProofViewMode.once,
        ),
        proofViewSeconds: p['proof_view_seconds'] as int? ?? 5,
        proofVisibility: p['proof_visibility'] != null
            ? TodProofVisibilitySettings.fromMap(
                p['proof_visibility'] as Map<String, dynamic>,
              )
            : const TodProofVisibilitySettings(),
      ),
      'tod_proof_viewed' => TodProofViewedEvent(userId: userId, ts: ts),
      'tod_start_proof_vote' => TodStartProofVoteEvent(userId: userId, ts: ts),
      'tod_cast_proof_vote' => TodCastProofVoteEvent(
        userId: userId,
        ts: ts,
        option: TodProofVoteOption.values.firstWhere(
          (o) => o.name == p['option'],
          orElse: () => TodProofVoteOption.noPreference,
        ),
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
        optionId: p['option_id'] as String? ?? '',
      ),
      'tod_propose_punishment' => TodProposePunishmentEvent(
        userId: userId,
        ts: ts,
        text: p['text'] as String? ?? '',
      ),
      'tod_moderator_override' => TodModeratorOverrideEvent(
        userId: userId,
        ts: ts,
        optionId: p['option_id'] as String? ?? '',
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
        final incoming = TodState.fromMap(snapshot);
        // Only apply if actually newer than what we already have — this is
        // also called by the staleness watchdog, where a race against a
        // broadcast that lands at the same moment shouldn't regress state.
        if (_state != null &&
            _hasSyncedState &&
            incoming.snapshotAt <= (_state?.snapshotAt ?? 0)) {
          _lastStateReceivedAt = DateTime.now();
          return;
        }
        _state = incoming;
        _hasSyncedState = true;
        _lastStateReceivedAt = DateTime.now();
        _loadState = _state!.isOver
            ? TodLoadState.gameOver
            : TodLoadState.ready;
        _syncTimer();
        _safeNotify();
      } else {
        _setError('Could not recover session state. Please rejoin the room.');
      }
    } catch (e) {
      _setError('Reconnection failed: ${e.toString()}');
    }
  }

  bool _gameOverHandled = false;

  void _handleGameOver() {
    _timerTicker?.cancel();
    _snapshotThrottle?.cancel();
    _loadState = TodLoadState.gameOver;

    if (_gameOverHandled) {
      _safeNotify();
      return;
    }
    _gameOverHandled = true;

    if (_isOwner && _sessionId != null && _state != null) {
      final finalScores = _state!.scores.map(
        (uid, s) => MapEntry(uid, s.toMap()),
      );
      _repo
          .completeSession(
            sessionId: _sessionId!,
            finalSnapshot: _state!.toMap(),
            endReason: _state!.endReason ?? 'round_limit',
            finalScores: finalScores,
          )
          .ignore();
    }
    if (_isOwner && _roomId != null) {
      sl.roomRepository.notifyGameEnded(_roomId!).ignore();
    }
    _safeNotify();
  }

  void _setLoading() {
    _loadState = TodLoadState.loading;
    _error = null;
    _safeNotify();
  }

  void _setError(String msg) {
    _loadState = TodLoadState.error;
    _error = msg;
    _safeNotify();
  }

  Future<void> kickPlayerFromGame(String targetUserId) async {
    if (!canModerate || _roomId == null) return;
    markPlayerAway(targetUserId, forGood: true);
    // Persist durably so every client (including one that reconnects,
    // briefly drops, or joins after this specific broadcast) derives the
    // correct active-player set via roomProvider.members, not just whoever
    // is connected at this exact moment — see _durableAwayIds.
    await sl.roomRepository
        .markMemberAwayInGame(_roomId!, targetUserId, away: true)
        .catchError((_) {});
    await _realtime.broadcastModeration(_roomId!, {
      'type': 'game_kick',
      'target_user_id': targetUserId,
      'by': _userId,
    });
  }

  Future<void> banPlayerFromGame(String targetUserId, {String? reason}) async {
    if (!canModerate || _roomId == null) return;
    markPlayerAway(targetUserId, forGood: true);
    await sl.roomRepository.banMember(
      roomId: _roomId!,
      targetUserId: targetUserId,
      bannedBy: _userId,
      reason: reason,
    );
    await _realtime.broadcastModeration(_roomId!, {
      'type': 'ban',
      'target_user_id': targetUserId,
      'reason': reason,
    });
  }

  void addChatMessage(TodChatMsg msg) {
    if (_chatMessages.any(
      (m) =>
          m.senderName == msg.senderName &&
          m.text == msg.text &&
          msg.ts.difference(m.ts).abs().inSeconds < 2,
    ))
      return;
    _chatMessages.add(msg);
    _unreadChat++;
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    _timerTicker?.cancel();
    _snapshotThrottle?.cancel();
    _syncTimeoutTimer?.cancel();
    _staleWatchdog?.cancel();
    super.dispose();
  }
}

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
