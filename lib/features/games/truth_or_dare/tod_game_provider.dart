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
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/errors/failures.dart';
import '../../../core/data/honesty_vote_repository.dart';
import '../../../core/services/realtime_service.dart';
import '../../../core/services/targeted_chat_listener.dart';
import '../../../core/utils/app_logger.dart';
import '../../rooms/domain/room_entity.dart';
import '../../rooms/presentation/room_provider.dart';
import '../game_session_messages.dart';
import '../engine/base_game_engine.dart';
import '../../../shared/widgets/game/game_chat_sheet.dart';
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

  // Item 2 — Premium Plus targeted chat, in-game context. A separate,
  // secure (RLS-gated CDC) delivery path from the "everyone" broadcast
  // chat above — see TargetedChatListener's own doc comment for the full
  // rationale. Started by the screen once the room is known (same "set
  // by the screen right after construction" convention as [roomProvider]
  // below), stopped in [dispose].
  final _targetedChatListener = TargetedChatListener();

  /// Call once from the game screen's initState, after [roomProvider] is
  /// set. Idempotent (TargetedChatListener.start always tears down any
  /// previous subscription first) — safe to call again if the room
  /// somehow changes.
  void startTargetedChatListener(String roomId) {
    _targetedChatListener.start(
      roomId: roomId,
      onInsert: _handleTargetedChatInsert,
    );
  }

  void _handleTargetedChatInsert(Map<String, dynamic> row) {
    // Only this session's own targeted messages belong in THIS game's
    // chat — a lobby message (game_session_id null) or one from a
    // different/earlier session in the same room is not for this sheet.
    if (row['game_session_id'] != _sessionId) return;
    final msgId = row['id'] as String?;
    if (msgId == null) return;
    if (_chatMessages.any((m) => m.id == msgId)) return;

    // No joined profile data over CDC — resolve the sender's name from
    // the room's own already-synced member list, same as every other
    // in-room identity lookup this provider already does.
    final senderId = row['user_id'] as String? ?? '';
    final senderName =
        roomProvider?.memberById(senderId)?.displayName ??
        _displayNames[senderId] ??
        'Player';
    final msg = TodChatMsg(
      id: msgId,
      senderId: senderId,
      senderName: senderName,
      text: row['content'] as String? ?? '',
      ts: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      replyToId: row['reply_to_id'] as String?,
      replyToSenderName: row['reply_to_display_name'] as String?,
      replyToText: row['reply_to_content'] as String?,
      audienceType: row['audience_type'] as String? ?? 'everyone',
    );
    _chatMessages.add(msg);
    _safeNotify();
  }

  /// Current game participants eligible to be targeted — every current
  /// room member except spectators, anyone who's left, and the sender
  /// themselves. The server (send_targeted_chat_message) re-verifies
  /// against the session's actual player_ids regardless of what this
  /// list shows, so an over-inclusive candidate here (e.g. a spectator)
  /// fails closed as a clean "recipient no longer available" error
  /// rather than a security gap.
  List<RoomMemberEntity> get gameParticipants =>
      roomProvider?.members
          .where(
            (m) =>
                m.userId != _userId &&
                !m.isSpectator &&
                !m.leftDefinitively,
          )
          .toList() ??
      const [];

  /// Item 2 — the targeted counterpart to [sendChat]. Server-authoritative
  /// (send_targeted_chat_message re-checks Premium Plus + session
  /// membership + recipient context); this only calls it and reflects the
  /// confirmed result locally.
  Future<bool> sendTargetedChat(
    String text, {
    required List<String> recipientIds,
    required List<String> recipientNames,
    GameChatMsg? replyTo,
  }) async {
    if (_roomId == null || _sessionId == null || text.trim().isEmpty) {
      return false;
    }
    try {
      final replySnippet = replyTo != null && replyTo.text.length > 120
          ? '${replyTo.text.substring(0, 120)}…'
          : replyTo?.text;
      final row = await sl.roomRepository.sendTargetedChatMessage(
        roomId: _roomId!,
        content: text.trim(),
        recipientIds: recipientIds,
        gameSessionId: _sessionId,
        replyToId: replyTo?.id,
        replyToContent: replySnippet,
        replyToDisplayName: replyTo?.senderName,
      );
      final msg = TodChatMsg(
        id: row.id,
        senderId: _userId,
        senderName: _displayNames[_userId] ?? 'Me',
        text: row.content,
        ts: row.createdAt,
        replyToId: row.replyToId,
        replyToSenderName: row.replyToDisplayName,
        replyToText: row.replyToContent,
        audienceType: row.audienceType,
        recipientNames: recipientNames,
      );
      _chatMessages.add(msg);
      _safeNotify();
      return true;
    } catch (_) {
      return false;
    }
  }

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

  // ── Game session ready barrier ──────────────────────────────────────
  // Root cause this fixes: after "Start Game", every client navigates
  // into the game screen at roughly the same time, but each client's own
  // provider/engine/realtime-subscription setup is independently async
  // (network, CDC lag, cold app start). A slower client could see the
  // game screen (state broadcasts already render fine) while its own
  // action-sending path silently wasn't ready yet — reading as
  // "behaves like a spectator" with no visible cause. This makes the
  // session's CREATED -> STARTING -> ACTIVE -> ENDED lifecycle explicit
  // and gates every gameplay action on it, instead of implicitly trusting
  // "the screen mounted" to mean "this client is ready".
  /// 'starting' | 'active' | 'ended' — see game_sessions.lifecycle_state.
  String _lifecycleState = 'active';
  String get lifecycleState => _lifecycleState;
  // A room-level host-disconnect pause (RoomProvider.isPausedForHostReconnect)
  // is not itself a game_sessions.lifecycle_state transition broadcast by
  // anyone — the owner is the one who's absent, so nothing is running to
  // broadcast it — but every action gate in this provider (onPlayerAction,
  // _handleAction) keys off this single getter, so folding the room's
  // pause signal in here is what actually makes "paused" reject actions
  // at the engine level instead of only visually overlaying the screen.
  // roomProvider already updates near-instantly off the 'pause' broadcast
  // and its own poll fallback — no extra round trip needed.
  bool get isSessionActive =>
      _lifecycleState == 'active' &&
      roomProvider?.isPausedForHostReconnect != true;
  bool get isSessionStarting => _lifecycleState == 'starting';

  List<String> _expectedReadyPlayerIds = const [];
  final _readyConfirmedUserIds = <String>{};
  int get readyConfirmedCount => _readyConfirmedUserIds.length;
  int get expectedReadyCount => _expectedReadyPlayerIds.length;
  Timer? _readyBarrierTimeout;
  Timer? _sessionActivePollTimer;

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
      // isGameMuted: a moderator-muted player already can't submit an
      // action (see _handleAction's own isGameMuted check) — but without
      // excluding them here too, the engine could still SELECT their turn
      // (this set is what ready-checks/turn-eligibility/force-advance-if-
      // current-player-becomes-ineligible all key off), and nothing could
      // ever complete it: the game would hang on a turn nobody is allowed
      // to take.
      return m == null || m.isAway || m.isDisconnected || m.isGameMuted;
    }).toSet();
  }

  /// The set actually used for turn/ready computations — the union of the
  /// instant, locally-witnessed broadcast signal and the durable, backend-
  /// synced one. Neither alone is sufficient: the local set reacts instantly
  /// but is lost on reconnect; the durable one is always eventually correct
  /// but may lag a beat behind the broadcast on the acting client itself.
  Set<String> get _effectiveAwayIds => _awayPlayerIds.union(_durableAwayIds);

  /// The set used for TURN ROTATION only — genuinely absent players
  /// (left/away/disconnected), deliberately NOT the merely game-muted. A
  /// moderator-muted player keeps their turn: it parks on them, blocked
  /// (they can't submit — see _handleAction's isGameMuted check), until the
  /// mute is lifted or a moderator advances past them. This is narrower
  /// than [_effectiveAwayIds], which still counts muted players for
  /// ready-exemption and the action chokepoint. Excluding only muted-AND-
  /// otherwise-present ids means a player who is muted *and* actually gone
  /// is still skipped, as before.
  Set<String> get _turnSkipIds {
    final rp = roomProvider;
    if (rp == null) return _effectiveAwayIds;
    final members = {for (final m in rp.members) m.userId: m};
    bool mutedButPresent(String id) {
      final m = members[id];
      return m != null && m.isGameMuted && !m.isAway && !m.isDisconnected;
    }

    return _effectiveAwayIds.where((id) => !mutedButPresent(id)).toSet();
  }

  Set<String> get awayPlayerIds => Set.unmodifiable(_effectiveAwayIds);

  /// Live count of players still actually in the game (excludes
  /// kicked/banned/left players) — `playerOrder.length` is frozen at game
  /// start since `playerOrder` never shrinks for the life of a session.
  int get activePlayerCount => (_state?.playerOrder ?? const <String>[])
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
    // No-op when nothing actually changed — the owner's per-tick reconcile
    // loop (tod_game_screen) calls this every cycle for players it now
    // considers present (including muted ones, which it no longer marks
    // away), so guarding avoids a notify storm.
    if (!_awayPlayerIds.remove(userId)) return;
    _safeNotify();
  }

  bool get isCurrentPlayerAway =>
      _state != null && _turnSkipIds.contains(_state!.currentPlayerId);

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
        if (DateTime.now().difference(_lastStateReceivedAt) > _staleThreshold) {
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
    // True only for a genuine, fresh "Start Game" press — see
    // TodGameScreen.isNewGameStart's doc comment. Skips the resume
    // lookup below entirely: without this, a brand-new game started in a
    // room whose PREVIOUS game had already finished (session status
    // 'completed', row never deleted — see completeSession) would find
    // that finished session as "the most recent" and incorrectly restore
    // its finished state (isOver: true, old scores, old used cards, old
    // counters) instead of starting fresh, because nothing else
    // distinguished "reconnecting after the game ended" from "starting a
    // brand new one" — both call this same method the same way.
    bool isNewGame = false,
  }) async {
    _setLoading();
    _roomId = roomId;
    _packCoverUrl = packCoverUrl;
    _config = config;
    _isOwner = true;
    _displayNames.addAll(playerDisplayNames);

    try {
      // The pack-already-played check now runs once, up front, in
      // lobby_screen.dart's _onStartGame — before the game_started
      // broadcast and room status flip, for every game mode (not just
      // ToD), instead of here. Running it unconditionally on every call
      // to initAsOwner would incorrectly reject every RECONNECT too: once
      // start_game_session_checks correctly reports "already claimed"
      // for a room+pack (fixed to actually be atomic — see the
      // 20260818090000 migration), the very first successful start
      // permanently claims the pack, so re-running this same check here
      // on the owner's own reconnect to their own already-running game
      // would immediately (and wrongly) error out every time.

      // Resolve which session this call is dealing with BEFORE building
      // anything off `config` — a resumed session (reconnect, app
      // restart, owner failover mid-game) must use the config it actually
      // started with, persisted on the session row, not whatever config
      // this call happened to be constructed with (which — for a
      // reconnect — is freshly reconstructed from generic room settings
      // and no longer carries any of the Truth or Dare-specific rules at
      // all; those only ever exist in the pre-game setup sheet's
      // one-time result and this persisted column). Only a genuinely NEW
      // session uses the passed-in `config` as-is.
      // isNewGame short-circuits the lookup entirely — a fresh start must
      // never resume ANY prior session for this room, active or
      // otherwise (findLatestSession deliberately has no status filter,
      // by design, for the separate "reconnect after the game already
      // ended" case — that same breadth is exactly what makes it unsafe
      // to consult here).
      var existing = isNewGame
          ? null
          : await _repo.findActiveSession(roomId) ??
                await _repo.findLatestSession(roomId);
      var existingStatus = existing?['status'] as String?;

      // Reconnect (isNewGame == false) with NO session row found on this
      // FIRST lookup: this is AMBIGUOUS, not proof the game ended —
      // RLS/timing/reconnect-state can all produce a transient miss on
      // this client's own read even though the session row genuinely
      // still exists elsewhere. initAsFollower already tolerates this
      // exact ambiguity for a non-owner (see its own comment: a null
      // lookup "doesn't prove there's no session") — this mirrors that
      // same principle for the owner instead of treating a single miss as
      // definitive. CONFIRMED ROOT CAUSE of a real regression: a
      // reconnecting owner's transient lookup miss used to be enough, on
      // its own, to write rooms.status = waiting for the WHOLE ROOM —
      // evicting every other still-actively-playing client the instant
      // they discovered it (via the 5s reconcile poll, or near-instantly
      // via ANY unrelated 'join' broadcast triggering _refreshMembers).
      if (!isNewGame && existing == null) {
        String? liveRoomStatus;
        try {
          final row = await Supabase.instance.client
              .from('rooms')
              .select('status')
              .eq('id', roomId)
              .maybeSingle();
          liveRoomStatus = row?['status'] as String?;
        } catch (e) {
          AppLogger.warning(
            'TodGameProvider: owner reconnect room-status re-check failed: $e',
          );
        }
        // The room itself still claiming in_game/paused is authoritative
        // evidence a session MUST exist — retry the exact same lookup
        // once more instead of assuming termination from a single miss.
        if (liveRoomStatus == 'in_game' || liveRoomStatus == 'paused') {
          existing =
              await _repo.findActiveSession(roomId) ??
              await _repo.findLatestSession(roomId);
          existingStatus = existing?['status'] as String?;
        }
        AppLogger.info(
          'Owner reconnect session check: room=$roomId user=$_userId '
          'isNewGame=$isNewGame session=${existing?['id']} '
          'status=$existingStatus roomStatus=$liveRoomStatus decision='
          '${existing != null ? 'resume' : 'preserve_room_state_no_action'}',
        );
        if (existing == null) {
          // Still nothing to resume even after the re-check — but this is
          // NOT confirmed termination (only a genuinely 'aborted' session
          // row below is), so the room and every other player are left
          // completely untouched: no status write, no broadcast, nobody
          // else is affected. Only this owner's own screen shows a
          // recoverable error.
          _setError(kSessionEndedErrorMessage);
          return;
        }
      }
      // 'aborted' means this session was explicitly, deliberately
      // terminated (auto-end for not-enough-players, host-disconnect
      // timeout, manual quit, room close) — not the engine's own natural
      // completion. This IS confirmed, authoritative evidence of
      // termination (unlike a null lookup above) — self-heal the room
      // status and surface a clear error so the screen sends the owner
      // back to the lobby. Only 'active' (genuinely still live) or
      // 'completed' (natural end — the existing results/game-over screen
      // already handles that from the restored snapshot) are valid
      // reconnect targets; everything else routes back to the lobby.
      if (!isNewGame && existingStatus == 'aborted') {
        AppLogger.warning(
          'Owner reconnect session check: room=$roomId user=$_userId '
          'session=${existing?['id']} status=$existingStatus '
          'decision=confirmed_game_ended',
        );
        try {
          await sl.roomRepository.updateStatus(roomId, RoomStatus.waiting);
        } catch (_) {}
        _setError(kSessionEndedErrorMessage);
        return;
      }
      final existingSnapshot =
          existing?['state_snapshot'] as Map<String, dynamic>?;
      final existingConfigMap = existing?['config'] as Map<String, dynamic>?;
      final isResuming =
          !isNewGame &&
          existing != null &&
          existingSnapshot != null &&
          existingSnapshot.isNotEmpty &&
          (existingStatus == 'active' || existingStatus == 'completed');
      final effectiveConfig =
          isResuming &&
              existingConfigMap != null &&
              existingConfigMap.isNotEmpty
          ? GameConfig.fromMap(existingConfigMap)
          : config;
      _config = effectiveConfig;

      var cards = await _repo.loadCardsFromCache(
        packId: packId,
        language: effectiveConfig.language,
        allowSpicy: effectiveConfig.allowSpicy,
      );
      if (cards.isEmpty) {
        cards = await _repo.loadCards(
          packId: packId,
          language: effectiveConfig.language,
          allowSpicy: effectiveConfig.allowSpicy,
        );
      }
      if (cards.isEmpty) {
        _setError(
          'No cards found for this pack. Please select a different pack.',
        );
        await _revertRoomFromStartingOnFailure(roomId);
        return;
      }

      _engine = TruthOrDareEngine(effectiveConfig, cards: cards);

      if (isResuming) {
        _sessionId = existing['id'] as String;
        _engine!.restoreFromSnapshot(existingSnapshot);
        _state = _engine!.currentState as TodState;
        _gameOverHandled = existingStatus != 'active';
        _lifecycleState = existing['lifecycle_state'] as String? ?? 'active';
        AppLogger.info(
          'TodGameProvider: resumed existing session $_sessionId '
          'lifecycle=$_lifecycleState',
        );
      } else {
        // Never trust the playerIds this call was made with for a
        // genuinely new session — RoomProvider.members it was built from
        // could already be stale by the time execution reaches here (the
        // Start Game flow has several awaits before this point: a pack
        // lookup, the server-side pack-already-played check, Truth or
        // Dare's own pre-game config sheet, a full modal the owner can
        // sit on indefinitely). A player who left during any of that
        // window would otherwise be baked into the new session's
        // player_ids/turn order/ready barrier, which would then wait on
        // a confirmation or a turn from someone no longer in the room —
        // "admin enters loading forever". Re-derive who's actually here
        // right now, immediately before creating the session.
        var freshPlayerIds = playerIds;
        try {
          final fetched = await _repo.fetchActiveMemberIds(roomId);
          if (fetched.isNotEmpty) freshPlayerIds = fetched;
        } catch (e) {
          AppLogger.warning(
            'TodGameProvider: fetchActiveMemberIds failed, falling back '
            'to passed-in playerIds: $e',
          );
        }

        _engine!.init(playerOrder: freshPlayerIds);
        _state = _engine!.currentState as TodState;
        _lifecycleState = 'starting';

        _sessionId = await _repo.createSession(
          roomId: roomId,
          packId: packId,
          config: effectiveConfig,
          playerIds: freshPlayerIds,
          ownerId: _userId,
          stateSnapshot: _state!.toMap(),
        );
        AppLogger.info(
          'SESSION_CREATED room=$roomId session=$_sessionId '
          'players=$freshPlayerIds',
        );

        // GAME SESSION CREATED/AVAILABLE: the game_sessions row provably
        // exists now — safe to release every other client from the
        // STARTING_GAME lock (LobbyScreen's _GameStartingLock,
        // RoomProvider._handleGameSessionReady) and let _syncGameRoute
        // carry them into this game screen. The broadcast covers
        // currently-connected clients immediately; the DB write covers
        // anyone who reconnects, or was slow to subscribe, before it
        // arrives — either alone is sufficient, this is belt-and-suspenders.
        _realtime.broadcastRoomEvent(roomId, {
          'type': 'game_session_ready',
        }).ignore();
        try {
          await sl.roomRepository.updateStatus(roomId, RoomStatus.inGame);
        } catch (e) {
          AppLogger.warning(
            'TodGameProvider: failed to flip room to in_game after '
            'session creation: $e',
          );
        }
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
        _engine = TruthOrDareEngine(effectiveConfig, cards: cards);
        if (_state != null) _engine!.restoreFromSnapshot(_state!.toMap());
      }

      await _broadcastState();

      _startSnapshotThrottle();

      _loadState = (_state?.isOver ?? false)
          ? TodLoadState.gameOver
          : TodLoadState.ready;
      _safeNotify();

      // Started (or resumed a still-interrupted-mid-barrier) session:
      // wait for every expected player to confirm they loaded it, or the
      // owner's own timeout, before allowing any gameplay action — see
      // _handleAction/onPlayerAction's isSessionActive gate.
      if (_lifecycleState == 'starting' && _sessionId != null) {
        _startReadyBarrier(playerIds);
      }
    } catch (e, st) {
      AppLogger.error(
        'TodGameProvider: initAsOwner failed',
        error: e,
        stackTrace: st,
      );
      _setError(e is Failure ? e.message : e.toString());
      // Only reaches here with _sessionId still null when session creation
      // itself never completed (a reconnect that already had _sessionId
      // set from an existing row fails BEFORE any of this, since that
      // assignment is the very first thing the resume branch does) — see
      // _revertRoomFromStartingOnFailure's doc comment for why this is
      // gated on the room's live status rather than assumed.
      if (_sessionId == null) {
        await _revertRoomFromStartingOnFailure(roomId);
      }
    }
  }

  /// STARTUP FAILURE (see initAsOwner's cards.isEmpty bail-out and catch
  /// block, its only two callers): a genuine, definitive failure to create
  /// a new game session must not leave the room permanently locked in
  /// STARTING_GAME. Re-reads the room's live status rather than assuming
  /// it — this same failure path can also be reached mid-reconnect (an
  /// already in_game room), where forcing it back to `waiting` would
  /// wrongly evict every other player from an otherwise-fine ongoing game
  /// just because of e.g. a transient card-load error on the reconnecting
  /// owner's client. Only a room still sitting in `starting` — i.e. one
  /// that never got the chance to be unlocked — is safe to release here.
  Future<void> _revertRoomFromStartingOnFailure(String roomId) async {
    try {
      final row = await Supabase.instance.client
          .from('rooms')
          .select('status')
          .eq('id', roomId)
          .maybeSingle();
      if (row != null && row['status'] == 'starting') {
        await sl.roomRepository.updateStatus(roomId, RoomStatus.waiting);
      }
    } catch (_) {}
  }

  // ── Ready barrier implementation ────────────────────────────────────
  void _startReadyBarrier(List<String> playerIds) {
    _expectedReadyPlayerIds = playerIds;
    _readyConfirmedUserIds.clear();
    _confirmReady();
    _readyBarrierTimeout?.cancel();
    // Weak-connection safety net: never leave the room waiting forever
    // for a straggler who may never confirm (killed app, dead network).
    _readyBarrierTimeout = Timer(const Duration(seconds: 10), () {
      if (_lifecycleState == 'starting') {
        AppLogger.warning(
          'TodGameProvider: ready barrier TIMEOUT room=$_roomId '
          'session=$_sessionId confirmed=$_readyConfirmedUserIds '
          'expected=$_expectedReadyPlayerIds — activating anyway',
        );
        _activateSession();
      }
    });
  }

  /// Called by every client (owner and followers alike) once THIS
  /// client's own engine/provider/subscriptions are actually ready to
  /// process actions — records it durably (DB, survives a reconnect that
  /// missed the broadcast) and tells the owner immediately (broadcast,
  /// for the common case).
  Future<void> _confirmReady() async {
    if (_sessionId == null || _roomId == null) return;
    try {
      await _repo.confirmSessionReady(_sessionId!);
    } catch (e) {
      AppLogger.warning('TodGameProvider: confirmSessionReady failed: $e');
    }
    AppLogger.info(
      'PLAYER_JOINED_SESSION room=$_roomId session=$_sessionId user=$_userId',
    );
    if (_isOwner) {
      handleSessionReadyEvent(_userId);
    } else {
      _realtime.broadcastRoomEvent(_roomId!, {
        'type': 'session_ready',
        'session_id': _sessionId,
        'user_id': _userId,
      }).ignore();
    }
  }

  /// Called by the owner's client (directly for its own confirmation, or
  /// via tod_game_screen.dart's onRoomEvent for a 'session_ready'
  /// broadcast from a follower) whenever a player confirms readiness.
  void handleSessionReadyEvent(String userId) {
    if (!_isOwner || _lifecycleState != 'starting') return;
    // Ignore a confirmation from a session that's since been superseded
    // (new game started) or from someone not actually dealt into this
    // one — same session-membership reasoning as onPlayerAction.
    if (!_expectedReadyPlayerIds.contains(userId)) return;
    _readyConfirmedUserIds.add(userId);
    AppLogger.info(
      'PLAYER_READY room=$_roomId session=$_sessionId user=$userId '
      'confirmed=${_readyConfirmedUserIds.length}/${_expectedReadyPlayerIds.length}',
    );
    _safeNotify();
    if (_expectedReadyPlayerIds.every(_readyConfirmedUserIds.contains)) {
      _activateSession();
    }
  }

  Future<void> _activateSession() async {
    if (_lifecycleState != 'starting') return; // idempotent
    _readyBarrierTimeout?.cancel();
    _lifecycleState = 'active';
    AppLogger.info('SESSION_ACTIVE room=$_roomId session=$_sessionId');
    if (_isOwner && _sessionId != null) {
      _repo.activateSession(_sessionId!).ignore();
    }
    await _broadcastState();
    _safeNotify();
  }

  /// Follower-only weak-connection fallback: the normal path to learn the
  /// session went active is the state broadcast the owner sends right
  /// after activating (see _activateSession), which carries
  /// lifecycle_state — but Realtime Broadcast has no delivery guarantee,
  /// so a client that missed it would otherwise wait forever. Polls the
  /// DB directly every few seconds until active, capped so a genuinely
  /// stuck session still surfaces as an error rather than spinning
  /// forever.
  void _pollForSessionActive() {
    _sessionActivePollTimer?.cancel();
    var attempts = 0;
    _sessionActivePollTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) async {
      attempts++;
      if (_isOwner || _lifecycleState != 'starting' || _sessionId == null) {
        timer.cancel();
        return;
      }
      if (attempts > 10) {
        // ~30s with no activation and no ownership handoff — surface it
        // rather than leaving the player staring at "waiting" forever.
        timer.cancel();
        AppLogger.warning(
          'TodGameProvider: session_active poll gave up room=$_roomId '
          'session=$_sessionId',
        );
        _setError('Could not confirm the game started. Please rejoin.');
        return;
      }
      try {
        final state = await _repo.getSessionLifecycleState(_sessionId!);
        if (state == 'active') {
          timer.cancel();
          _lifecycleState = 'active';
          AppLogger.info(
            'SESSION_ACTIVE (via poll) room=$_roomId session=$_sessionId '
            'user=$_userId',
          );
          _safeNotify();
        }
      } catch (e) {
        AppLogger.warning('TodGameProvider: session_active poll failed: $e');
      }
    });
  }

  Future<void> initAsFollower({
    required String roomId,
    required GameConfig config,
    String? sessionId,
    String? packCoverUrl,
  }) async {
    _roomId = roomId;
    _packCoverUrl = packCoverUrl;
    _config = config;
    _sessionId = sessionId;
    _isOwner = false;
    _loadState = TodLoadState.loading;

    // The passed-in `config` is only guaranteed correct for the very
    // first join, straight off the game_started broadcast payload — on a
    // reconnect there's no fresh broadcast to reconstruct it from
    // correctly, and the fallback (rebuilt from generic room settings)
    // no longer carries any Truth or Dare-specific rule at all. Same fix
    // as initAsOwner: prefer the config actually persisted on the
    // session row, so a reconnecting follower's UI (Skip button, proof
    // visibility, punishment badge) reflects the real, immutable
    // per-game config instead of silently drifting to defaults.
    try {
      var existing = await _repo.findActiveSession(roomId);
      existing ??= await _repo.findLatestSession(roomId);
      final existingStatus = existing?['status'] as String?;
      // 'aborted' is an unambiguous "this session was deliberately closed"
      // signal (auto-end, host-disconnect timeout, quit) — never a race
      // artifact, since that row only exists after a close already fully
      // committed. Bail to the lobby exactly like initAsOwner does. `existing
      // == null` is deliberately NOT treated the same way here: on a
      // genuinely fresh game start, the owner's createSession() may not
      // have committed yet when a fast follower's own lookup runs (the
      // game_started broadcast that sent them here carries no session id
      // at all), so null here is ambiguous — the live state broadcast
      // (onStateBroadcast) remains the real source of truth for that case.
      if (existingStatus == 'aborted') {
        AppLogger.warning(
          'SESSION_ENDED room=$roomId session=${existing?['id']} '
          'reason=follower_found_aborted_session',
        );
        _setError(kSessionEndedErrorMessage);
        return;
      }
      final existingConfigMap = existing?['config'] as Map<String, dynamic>?;
      if (existingConfigMap != null && existingConfigMap.isNotEmpty) {
        _config = GameConfig.fromMap(existingConfigMap);
      }
      _sessionId ??= existing?['id'] as String?;
      _lifecycleState = existing?['lifecycle_state'] as String? ?? 'active';
      AppLogger.info(
        'PLAYER_JOINED_SESSION room=$roomId session=$_sessionId '
        'user=$_userId lifecycle=$_lifecycleState',
      );
    } catch (e) {
      AppLogger.warning(
        'TodGameProvider: initAsFollower config lookup failed: $e',
      );
    }

    if (_lifecycleState == 'starting') {
      // Tell the owner "I loaded this exact session" and start polling
      // as a weak-connection fallback in case the eventual
      // session_active broadcast/state-embedded flag never arrives.
      _confirmReady();
      _pollForSessionActive();
    }

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
        AppLogger.error(
          'TodGameProvider: ownership handoff engine build failed: $e',
        );
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
    // Logged BEFORE any parsing or staleness check — this is the earliest
    // possible confirmation that a broadcast reached this client's
    // callback at all. Pairs with TOD_STATE_APPLIED/TOD_AWAITING_VIEW to
    // give the full chain: TOD_BROADCAST_RECEIVED -> (possibly
    // TOD_BROADCAST_DISCARDED reason=...) -> TOD_STATE_APPLIED ->
    // TOD_AWAITING_VIEW. If this line never appears on a client at all,
    // the problem is upstream of this provider entirely (realtime
    // subscription/delivery), not state parsing or rendering.
    AppLogger.debug(
      'TOD_BROADCAST_RECEIVED isOwner=$_isOwner '
      'snapshotAt=${(payload['snapshot'] as Map<String, dynamic>?)?['snapshot_at']} '
      'payloadKeys=${payload.keys.toList()}',
    );

    final snapshot = payload['snapshot'] as Map<String, dynamic>?;
    if (snapshot == null) {
      AppLogger.debug('TOD_BROADCAST_DISCARDED reason=no_snapshot');
      return;
    }

    // Reject a snapshot belonging to a PREVIOUS game session outright —
    // the timestamp-based staleness check below only protects against
    // out-of-order broadcasts WITHIN the session already being tracked;
    // it does nothing right at the start of a brand-new session, before
    // _hasSyncedState is true, when a delayed broadcast from the OLD
    // session could otherwise be adopted as if it were the current game.
    final payloadSessionId = payload['session_id'] as String?;
    if (payloadSessionId != null &&
        _sessionId != null &&
        payloadSessionId != _sessionId) {
      AppLogger.debug(
        'TodGameProvider: discarded state from stale session '
        '$payloadSessionId (current: $_sessionId)',
      );
      AppLogger.debug(
        'TOD_BROADCAST_DISCARDED reason=wrong_session '
        'payloadSession=$payloadSessionId currentSession=$_sessionId',
      );
      return;
    }

    // Applied regardless of whether the STATE portion of this broadcast
    // ends up discarded as stale below — this is the primary path a
    // follower learns the owner activated the session (see
    // _activateSession's immediate _broadcastState() call right after).
    // The weak-connection fallback is _pollForSessionActive.
    final incomingLifecycle = payload['lifecycle_state'] as String?;
    if (!_isOwner &&
        incomingLifecycle != null &&
        _lifecycleState != incomingLifecycle) {
      final wasStarting = _lifecycleState == 'starting';
      _lifecycleState = incomingLifecycle;
      if (wasStarting && incomingLifecycle == 'active') {
        _sessionActivePollTimer?.cancel();
        AppLogger.info(
          'SESSION_ACTIVE (via broadcast) room=$_roomId '
          'session=$_sessionId user=$_userId',
        );
      }
      // Notify immediately here too — the rest of this method may still
      // return early below (a stale STATE snapshot), but the lifecycle
      // change itself is never stale and must reach the UI right away.
      _safeNotify();
    }

    final incomingTs = snapshot['snapshot_at'] as int? ?? 0;
    final currentTs = _state?.snapshotAt ?? 0;

    if (incomingTs <= currentTs && _hasSyncedState) {
      AppLogger.debug(
        'TodGameProvider: stale broadcast ts=$incomingTs discarded',
      );
      AppLogger.debug(
        'TOD_BROADCAST_DISCARDED reason=stale incomingTs=$incomingTs '
        'currentTs=$currentTs',
      );
      return;
    }

    final previousTurnStartedAt = _state?.turnStartedAt;
    TodState parsed;
    try {
      parsed = TodState.fromMap(snapshot);
    } catch (e, st) {
      // A parse failure here must never permanently strand a non-owner
      // client on stale/no state. Previously this exception propagated
      // uncaught out of onStateBroadcast; RealtimeService._fanOut (see
      // its own doc comment) catches and logs it per-listener, but that
      // silently drops THIS broadcast with no recovery — _state stays
      // whatever it was before (null, on a first snapshot), _hasSyncedState
      // never flips true, and the UI just sits on TodLoadingScreen/stale
      // content indefinitely with no visible error. That is exactly what
      // a "blank screen" looks like from the outside. Recover the same
      // way the stale-broadcast watchdog already does (see
      // _startStaleWatchdog) — request a fresh broadcast, then fall back
      // to a direct DB read — just immediately instead of waiting up to
      // 15s for the watchdog to notice.
      AppLogger.error(
        'TodGameProvider: failed to parse broadcast state snapshot '
        '(keys=${snapshot.keys.toList()})',
        error: e,
        stackTrace: st,
      );
      AppLogger.debug('TOD_BROADCAST_DISCARDED reason=parse_failure error=$e');
      if (!_isOwner && _roomId != null) {
        _realtime
            .broadcastSyncRequest(_roomId!, _userId, _state?.roundNumber ?? 0)
            .ignore();
        _tryLoadSnapshotFromDb();
      }
      return;
    }
    _state = parsed;
    _hasSyncedState = true;
    _lastStateReceivedAt = DateTime.now();
    _syncTimeoutTimer?.cancel();
    _loadState = _state!.isOver ? TodLoadState.gameOver : TodLoadState.ready;

    // Diagnostic instrumentation for the "remote player sees a blank
    // result screen" report — pairs with the matching log in
    // _AwaitingView.build() (tod_card_screen.dart). If THIS log shows a
    // real response/proof arrived but the _AwaitingView log for the same
    // round never fires (or fires with different data), the bug is in
    // routing/rendering, not state delivery. AppLogger.debug is a no-op
    // in production builds.
    AppLogger.debug(
      'TOD_STATE_APPLIED isOwner=$_isOwner localPlayerId=$_userId '
      'round=${_state!.roundNumber} phase=${_state!.phase.name} '
      'currentTurnPlayerId=${_state!.currentPlayerId} '
      'snapshotAt=${_state!.snapshotAt} '
      'hasTurnResponse=${_state!.turnResponse.isNotEmpty} '
      'hasTurnProofImage=${_state!.turnProofImageB64.isNotEmpty} '
      'hasTurnProofVoice=${_state!.turnProofVoiceB64.isNotEmpty}',
    );

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

    // Defense-in-depth mirror of _handleAction's own gate — the owner
    // (the actual authority here) must never apply an action while the
    // session itself hasn't reached ACTIVE, regardless of what the
    // sender's own client believed.
    if (!isSessionActive) {
      AppLogger.warning(
        'ACTION_REJECTED_BEFORE_READY room=$_roomId session=$_sessionId '
        'user=${payload['user_id']} lifecycle=$_lifecycleState '
        'action=${payload['action']}',
      );
      return;
    }

    // The owner's client is the closest thing to "the server" in this
    // broadcast-relay architecture (see class doc) — it MUST independently
    // verify the sender before applying any action.
    //
    // ROOT CAUSE of "real players randomly treated as spectators" (unable
    // to press buttons/submit despite seeing the game update normally):
    // this used to check ONLY roomProvider.members — a live,
    // async-populated list RoomProvider itself is still syncing (initial
    // fetch, CDC, the periodic reconcile poll) right after a game starts.
    // A genuine player whose very first action arrived before that sync
    // caught up got silently and PERMANENTLY rejected — nothing ever
    // re-checked them, so every later action failed too, even after
    // roomProvider.members caught up seconds afterward. This is exactly
    // why it looked random and could affect "only some players" or
    // "everyone but the host": whichever clients' actions happened to
    // race the owner's own member-list sync lost, silently, with no retry.
    //
    // Fixed by checking session membership FIRST: playerOrder is fixed
    // the instant the game starts (from the same playerIds this engine
    // was initialized with) and needs no async round-trip — it's
    // immediately, always correct for anyone actually dealt into this
    // game. roomProvider.members is now only a SECOND gate, to catch a
    // real removal (kick/ban/leave) that happened AFTER the game started
    // — never the sole source of truth for "is this a real player".
    final senderId = payload['user_id'] as String?;
    if (senderId == null) return;
    final isSessionPlayer = _state?.playerOrder.contains(senderId) ?? false;
    if (!isSessionPlayer) {
      AppLogger.warning(
        'TodGameProvider: rejected action "${payload['action']}" from '
        'non-session-player $senderId',
      );
      return;
    }
    final members = roomProvider?.members;
    if (members != null && !members.any((m) => m.userId == senderId)) {
      AppLogger.warning(
        'TodGameProvider: rejected action "${payload['action']}" from '
        'removed member $senderId',
      );
      return;
    }
    // A late/delayed broadcast from a PREVIOUS game in this same room
    // (network delay, backgrounded app catching up) must never be
    // applied to whatever game is running now — playerOrder alone can't
    // tell these apart, since consecutive games usually share the same
    // players. Only rejects on a CONFIRMED mismatch (both sides
    // resolved, genuinely different) — never on either side still being
    // null/unresolved, which would otherwise risk the same class of
    // false-rejection bug this whole check was written to avoid
    // elsewhere in this method.
    final payloadSessionId = payload['session_id'] as String?;
    if (payloadSessionId != null &&
        _sessionId != null &&
        payloadSessionId != _sessionId) {
      AppLogger.warning(
        'TodGameProvider: rejected action "${payload['action']}" from '
        'stale session $payloadSessionId (current: $_sessionId)',
      );
      return;
    }

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

  /// Durable, immediately-consistent record of THIS turn's proof
  /// visibility + viewing rules — a side channel, not a game-state action
  /// (never goes through _handleAction/the engine). Unlike the shared
  /// broadcast state (instant but only ever eventually-persisted, every
  /// 10s, via TodRepository.saveSnapshot), this lands synchronously so
  /// record_proof_view can enforce it immediately, including for a viewer
  /// who reconnects before the next periodic snapshot would have caught up.
  /// See TodCardScreen._showCompleteSheet's call site.
  Future<void> saveProofMetadata({
    required int turnStartedAt,
    required TodProofVisibilitySettings visibility,
    required TodProofViewMode viewMode,
    required int viewSeconds,
  }) async {
    if (_sessionId == null) return;
    await _repo.saveTurnProofMetadata(
      sessionId: _sessionId!,
      turnStartedAt: turnStartedAt,
      visibility: visibility,
      viewMode: viewMode,
      viewSeconds: viewSeconds,
    );
  }

  /// Fetches server-authoritative watched/replay counts for a batch of
  /// history rounds. Called once by the history panel when it opens (never
  /// from build()/a subscription callback) so it never re-fires on rebuild.
  /// Returns {} on any failure or when there's no session yet — the UI
  /// falls back to showing only the (already-available) watched-by count.
  Future<Map<int, ({int distinctViewers, int totalViews})>>
      fetchProofViewStats(List<int> turnStartedAts) async {
    if (_sessionId == null || turnStartedAts.isEmpty) return {};
    try {
      return await _repo.getProofViewStats(
        sessionId: _sessionId!,
        turnStartedAts: turnStartedAts,
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> startProofVote() =>
      _handleAction({'action': 'tod_start_proof_vote'});

  Future<void> castProofVote(TodProofVoteOption option) =>
      _handleAction({'action': 'tod_cast_proof_vote', 'option': option.name});

  Future<void> reactToResponse(String emoji) =>
      _handleAction({'action': 'tod_react', 'emoji': emoji});

  Future<void> voteForResponse() =>
      _handleAction({'action': 'tod_vote_response'});

  // ── Honesty voting (shared across ToD/NHIE/Meme, see
  // core/data/honesty_vote_repository.dart) ─────────────────────────────
  final _honestyRepo = HonestyVoteRepository.instance;
  final Set<String> _honestyVotedKeys = {};

  bool hasVotedHonesty(String responseKey, String targetUserId) =>
      _honestyVotedKeys.contains('$responseKey|$targetUserId');

  // ── Live dishonest-reason visibility (item: instant reveal, private
  // history) — a content-free realtime "go re-fetch" ping, never the
  // reason text or voter identity; see buildDishonestReasonBroadcastPayload
  // and applyDishonestReasonSignal in tod_models.dart for why. ───────────
  Map<String, int> _dishonestReasonGeneration = {};

  /// Bumped once per 'dishonest_reason_added' signal received for
  /// [responseKey] — DishonestReasonsPanel's ToD call site folds this into
  /// its widget Key so a bump forces a fresh, RLS-backed re-fetch.
  int dishonestReasonGeneration(String responseKey) =>
      _dishonestReasonGeneration[responseKey] ?? 0;

  void onDishonestReasonAdded(Map<String, dynamic> payload) {
    final updated = applyDishonestReasonSignal(_dishonestReasonGeneration, payload);
    if (identical(updated, _dishonestReasonGeneration)) return;
    _dishonestReasonGeneration = updated;
    _safeNotify();
  }

  List<String> get honestyEligibleParticipants => _state?.playerOrder ?? [];

  /// Casts an Honest/Not-honest vote on [targetUserId]'s response for the
  /// current round. Server (cast_honesty_vote) is the real authority for
  /// every rule (self/outsider/duplicate/reason-required-for-dishonest) —
  /// this only tracks local UI state (disable the buttons after voting)
  /// and surfaces a failure. [reason] is required by the server when
  /// [isHonest] is false (min 3 trimmed chars) — the calling UI already
  /// gates Submit on the same rule, but this call is what's actually
  /// authoritative.
  Future<void> castHonestyVote({
    required String targetUserId,
    required bool isHonest,
    String? reason,
  }) async {
    if (_sessionId == null || _state == null) return;
    final responseKey = 'round:${_state!.roundNumber}';
    // Sourced from the engine's own broadcast state (history), never
    // decided by the voter — see honestyVoteCardTypeForRound's doc
    // comment. The server derives the actual point delta from this; a
    // null here (no matching record yet) just falls back to the existing
    // normal rate, unchanged from before this parameter existed.
    final cardType = honestyVoteCardTypeForRound(_state!, _state!.roundNumber);
    // Marked voted only on a genuine server round-trip success (whether
    // newly applied or an already-existed no-op) — a network/offline
    // failure leaves it untouched so the UI still offers a retry, instead
    // of falsely showing "voted" for a vote that never reached the server.
    final result = await _honestyRepo.castVote(
      gameSessionId: _sessionId!,
      responseKey: responseKey,
      targetUserId: targetUserId,
      isHonest: isHonest,
      reason: reason,
      cardType: cardType,
    );
    _honestyVotedKeys.add('$responseKey|$targetUserId');
    // Only after the server has actually accepted a NEW dishonest vote
    // (result.applied — never on the idempotent "already voted" no-op,
    // which would just be a stale re-signal) — relaying confirmed
    // server-accepted state, never inventing it. The target's own client
    // re-fetches the real reason list itself; this payload carries none
    // of it (see buildDishonestReasonBroadcastPayload).
    if (result.applied && !isHonest && _roomId != null) {
      _realtime
          .broadcastRoomEvent(
            _roomId!,
            buildDishonestReasonBroadcastPayload(
              responseKey: responseKey,
              targetUserId: targetUserId,
            ),
          )
          .ignore();
    }
    notifyListeners();
  }

  /// Every "Not honest" reason left for MY OWN current-round response —
  /// used by the affected-player reveal in _AwaitingView. See
  /// HonestyVoteRepository.getDishonestReasons for the RLS/anonymity
  /// contract (voter identity is never returned).
  Future<List<HonestyVoteReason>> getMyDishonestReasons() {
    if (_sessionId == null || _state == null) return Future.value(const []);
    return _honestyRepo.getDishonestReasons(
      gameSessionId: _sessionId!,
      responseKey: 'round:${_state!.roundNumber}',
    );
  }

  /// Same anonymous, RLS-backed query as [getMyDishonestReasons], but for
  /// any PAST round of the current session (item: Game History → my own
  /// past turn → dishonest reasons) — used by _HistoryPanel, gated there
  /// to only ever call this for a round the viewer themselves played
  /// (round.playerId == currentUserId); honesty_votes' own RLS
  /// independently enforces the same restriction, so this is
  /// defense-in-depth, not the only guard.
  Future<List<HonestyVoteReason>> getDishonestReasonsForRound(int roundNumber) {
    if (_sessionId == null) return Future.value(const []);
    return _honestyRepo.getDishonestReasons(
      gameSessionId: _sessionId!,
      responseKey: 'round:$roundNumber',
    );
  }

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
      return (success: false, error: 'game_not_started_yet');
    }
    if (!(_engine?.currentState is TodState)) {
      return (success: false, error: 'game_not_ready');
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

  Future<void> voteOnPunishment(String optionId) =>
      _handleAction({'action': 'tod_vote_punishment', 'option_id': optionId});

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
      // genuinely-absent player here so the game keeps moving without them,
      // exactly as if they'd been removed from playerOrder. A merely
      // game-muted (but present) player is deliberately NOT skipped — the
      // turn parks on them, blocked, until they're unmuted or a moderator
      // advances (see _turnSkipIds).
      var guard = 0;
      while (!_state!.isOver &&
          _turnSkipIds.contains(_state!.currentPlayerId) &&
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

  /// Returns true once the message has been both recorded locally and
  /// successfully broadcast, false if the broadcast failed (item 7) — the
  /// caller (GameChatSheet) uses this to decide whether it's safe to clear
  /// the composer/close the keyboard, or whether the draft must be kept
  /// for a retry. [replyTo] carries item 6's reply reference, if any.
  Future<bool> sendChat(String text, {GameChatMsg? replyTo}) async {
    if (_roomId == null || text.trim().isEmpty) return false;
    if (_effectiveAwayIds.contains(_userId)) return false;
    final id = '${_userId}_${DateTime.now().microsecondsSinceEpoch}';
    final msg = TodChatMsg(
      id: id,
      senderId: _userId,
      senderName: _displayNames[_userId] ?? 'Me',
      text: text.trim(),
      ts: DateTime.now(),
      replyToId: replyTo?.id,
      replyToSenderName: replyTo?.senderName,
      replyToText: replyTo?.text,
    );
    _chatMessages.add(msg);
    _safeNotify();
    try {
      await _realtime.broadcastChat(_roomId!, {
        'id': id,
        'user_id': _userId,
        'display_name': _displayNames[_userId] ?? 'Me',
        'content': text.trim(),
        'ts': DateTime.now().millisecondsSinceEpoch,
        if (replyTo != null) 'reply_to_id': replyTo.id,
        if (replyTo != null) 'reply_to_sender_name': replyTo.senderName,
        if (replyTo != null) 'reply_to_text': replyTo.text,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Pauses the turn timer for everyone (owner, other players, and
  /// spectators alike) — e.g. while the current player is performing their
  /// truth/dare. Stored in canonical TodState (not a one-off broadcast), so
  /// _syncTimer() derives the same paused state for every client, including
  /// one that (re)joins or resyncs while the pause is active.
  Future<void> pauseTimer() => _handleAction({'action': 'tod_pause_timer'});

  /// Resumes a previously paused turn timer, preserving the remaining time.
  Future<void> resumeTimer() => _handleAction({'action': 'tod_resume_timer'});

  void _syncTimer() {
    _timerTicker?.cancel();
    // Turn progression must stop the instant the session isn't active —
    // a local Timer.periodic keeps running independent of network/room
    // state, so without this a turn timer already ticking when a
    // host-disconnect pause begins would keep counting down and (on
    // whichever client is _isOwner) fire TodTimerExpiredEvent and advance
    // the turn while the game is paused.
    if (!isSessionActive) {
      _timerIsRunning = false;
      return;
    }
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
      final elapsedAtPause = (s.timerPausedAt! - s.timerStartedAt!) ~/ 1000;
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
      // A pause can begin mid-countdown, after this ticker already
      // started — _syncTimer()'s own guard only protects timers that
      // haven't started yet, so the running ticker needs its own check on
      // every tick, not just cosmetically (skip the visible countdown
      // too), to actually stop turn progression the moment the session
      // stops being active.
      if (!isSessionActive) {
        _timerTicker?.cancel();
        return;
      }
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
    // No gameplay action is valid before this client's OWN session has
    // reached ACTIVE — this is the actual chokepoint fix for "sees the
    // game but can't interact": a client whose screen mounted and is
    // rendering broadcasts fine, but whose own readiness hasn't been
    // confirmed/activated yet, must not be able to act (or be able to
    // TRY to act and be silently ignored downstream) — surfaced instead
    // of silent, matching ACTION_REJECTED_BEFORE_READY.
    if (!isSessionActive) {
      AppLogger.warning(
        'ACTION_REJECTED_BEFORE_READY room=$_roomId session=$_sessionId '
        'user=$_userId lifecycle=$_lifecycleState action=${action['action']}',
      );
      return;
    }
    // A kicked/banned/left player must not be able to act again even in the
    // brief window before their client has processed the moderation
    // broadcast and navigated away — this is the single chokepoint every
    // player-initiated action (submit/vote/react/ready/punishment-vote)
    // routes through.
    if (_effectiveAwayIds.contains(_userId)) return;
    // Game session membership decides if I belong to the game — fixed at
    // game-init time (playerOrder, from the same playerIds this engine
    // was initialized with), no async dependency on RoomProvider's own
    // sync timing. Checking roomProvider.currentMember FIRST (a live,
    // async-populated read) risked treating "RoomProvider hasn't
    // finished syncing yet" the same as "I'm not really in this game" —
    // mirrors the fix already applied to onPlayerAction's owner-side
    // validation.
    if (!(_state?.playerOrder.contains(_userId) ?? false)) return;
    // Room membership only decides if I was later removed (kick/ban/
    // leave) — but only once RoomProvider has actually completed its
    // first load (isInitialized); before that, its member list is
    // legitimately empty/incomplete and must never be read as "removed".
    final rp = roomProvider;
    if (rp != null && rp.isInitialized) {
      final stillInRoom = rp.members.any((m) => m.userId == _userId);
      if (!stillInRoom) return;
    }
    // Moderator-imposed game mute (RoomMemberEntity.isGameMuted, distinct
    // from chat mute) — muted players can still watch but not act.
    if (rp?.currentMember?.isGameMuted ?? false) return;
    final full = {
      ...action,
      'user_id': _userId,
      'display_name': _displayName,
      'ts': DateTime.now().millisecondsSinceEpoch,
      // Lets a late-arriving action from a PREVIOUS game in this same
      // room (network delay, backgrounded app) be told apart from one
      // belonging to the game currently running — see onPlayerAction's
      // check. May be null very briefly (session creation is still
      // in-flight) — that's fine, onPlayerAction only rejects on a
      // confirmed mismatch, never on either side being unresolved yet.
      'session_id': _sessionId,
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
      'session_id': _sessionId,
    });
  }

  Future<void> _broadcastState() async {
    if (_roomId == null || _state == null) return;
    _maybeAnnounceChoosing();
    await _realtime.broadcastGameState(
      _roomId!,
      _state!.toMap(),
      _userId,
      sessionId: _sessionId,
      lifecycleState: _lifecycleState,
    );
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
      final (snapshot, lifecycle, status) = await _repo.loadSnapshot(
        _sessionId!,
      );
      // Deliberately closed (not the engine's own natural completion) —
      // never render this snapshot as if the game were still live. See
      // the identical check in initAsOwner/initAsFollower for the full
      // rationale; this is the same rule applied to the weak-connection
      // DB-read fallback path.
      if (status == 'aborted') {
        AppLogger.warning(
          'SESSION_ENDED room=$_roomId session=$_sessionId '
          'reason=snapshot_fallback_found_aborted_session',
        );
        _setError(kSessionEndedErrorMessage);
        return;
      }
      if (snapshot != null) {
        // Weak-connection fallback (no broadcast received in time) must
        // respect the ready barrier exactly like every other path does —
        // this predates the barrier and previously unlocked the full
        // interactive UI purely off snapshot content, regardless of
        // whether the session had actually reached 'active'.
        if (lifecycle != null && lifecycle != _lifecycleState) {
          final wasStarting = _lifecycleState == 'starting';
          _lifecycleState = lifecycle;
          if (wasStarting && lifecycle == 'active') {
            _sessionActivePollTimer?.cancel();
          }
        }
        if (_lifecycleState == 'starting') {
          // Still not ready — don't render the game as playable. Make
          // sure the confirm/poll machinery is actually running for this
          // client (a weak-connection client may have reached here
          // without ever having gone through initAsFollower's own
          // lookup successfully).
          if (_sessionActivePollTimer == null) {
            _confirmReady();
            _pollForSessionActive();
          }
          _lastStateReceivedAt = DateTime.now();
          _safeNotify();
          return;
        }
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

  /// ROOT CAUSE of "ban removes users correctly, but kick does not":
  /// this used to only mark the target away (broadcasting 'game_kick',
  /// which _handleModeration only ever treats as "flip isAway=true" —
  /// never calling _removeMember, never setting room_members.left_at,
  /// never firing RoomLifecycleEvent for the target) — so a kicked
  /// player's own room_members row, and their own client's session
  /// membership, were both left completely intact. Nothing ever told
  /// their client to stop acting or leave the game screen; every other
  /// client just saw them greyed out as "away". banPlayerFromGame
  /// (below) never had this gap — it always called the real room-level
  /// ban RPC and broadcast a genuine 'ban' event. Kick now does the same:
  /// a real room-level kick, not just an in-game away-marking.
  Future<void> kickPlayerFromGame(String targetUserId) async {
    if (!canModerate || _roomId == null) return;
    markPlayerAway(targetUserId, forGood: true);
    try {
      await sl.roomRepository.kickMember(_roomId!, targetUserId);
    } catch (e) {
      AppLogger.warning('TodGameProvider: kickPlayerFromGame RPC failed: $e');
    }
    await _realtime.broadcastModeration(_roomId!, {
      'type': 'kick',
      'target_user_id': targetUserId,
      'by_name': _displayName,
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
    _readyBarrierTimeout?.cancel();
    _sessionActivePollTimer?.cancel();
    _targetedChatListener.stop();
    super.dispose();
  }
}

/// ToD's in-game chat message — now the shared [GameChatMsg] model (item 4)
/// so NHIE/Meme can reuse the exact same type/UI. Kept as a type alias so
/// every existing `TodChatMsg(...)` call site here and in
/// tod_game_screen.dart keeps compiling and behaving identically.
typedef TodChatMsg = GameChatMsg;
