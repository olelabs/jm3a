// // // // import 'dart:math';
// // // // import 'package:uuid/uuid.dart';

// // // // import '../engine/base_game_engine.dart';
// // // // import 'domain/tod_models.dart';

// // // // const _uuid = Uuid();

// // // // /// Truth or Dare pure-Dart game engine.
// // // // /// Owner-authoritative: only the room owner runs this.
// // // // /// Followers call restoreFromSnapshot() on every broadcast.
// // // // class TruthOrDareEngine implements BaseGameEngine {
// // // //   TruthOrDareEngine(this._config, {required List<TodCard> cards})
// // // //     : _deck = List.of(cards);

// // // //   final GameConfig _config;
// // // //   final List<TodCard> _deck;
// // // //   late TodState _state;
// // // //   final _rng = Random.secure();

// // // //   void init({required List<String> playerOrder, int startingIndex = 0}) {
// // // //     _deck.shuffle(_rng);
// // // //     final scores = {
// // // //       for (final id in playerOrder) id: TodPlayerScore(userId: id),
// // // //     };
// // // //     final queue = _config.turnOrderMode == TurnOrderMode.random
// // // //         ? (_buildQueue(playerOrder))
// // // //         : <String>[];

// // // //     _state = TodState(
// // // //       snapshotAt: _now(),
// // // //       playerOrder: playerOrder,
// // // //       currentPlayerIndex: startingIndex,
// // // //       phase: TodTurnPhase.choosingType,
// // // //       roundNumber: 1,
// // // //       maxRounds: _config.maxRounds,
// // // //       scores: scores,
// // // //       turnOrderMode: _config.turnOrderMode,
// // // //       randomTurnQueue: queue,
// // // //       turnStartedAt: _now(),
// // // //     );
// // // //   }

// // // //   @override
// // // //   TodState get currentState => _state;
// // // //   @override
// // // //   bool get isGameOver => _state.isOver;

// // // //   @override
// // // //   TodState handleEvent(GameEngineEvent event) {
// // // //     _state = switch (event) {
// // // //       TodChoiceEvent e => _onChoice(e),
// // // //       TodCompleteEvent e => _onComplete(e),
// // // //       TodReactEvent e => _onReact(e),
// // // //       TodVoteResponseEvent e => _onVoteResponse(e),
// // // //       TodSkipEvent e => _onSkip(e),
// // // //       TodTimerExpiredEvent e => _onTimerExpired(e),
// // // //       TodProposePunishmentEvent e => _onProposePunishment(e),
// // // //       TodVotePunishmentEvent e => _onVotePunishment(e),
// // // //       TodModeratorOverrideEvent e => _onModeratorOverride(e),
// // // //       TodEndGameEvent e => _onEndGame(e),
// // // //       _ => _state,
// // // //     };
// // // //     return _state;
// // // //   }

// // // //   @override
// // // //   TodState advanceTurn() {
// // // //     if (_state.isOver) return _state;
// // // //     final nextIdx = _nextIndex();
// // // //     final wrapped =
// // // //         _state.turnOrderMode == TurnOrderMode.circular && nextIdx == 0;
// // // //     final newRound = wrapped ? _state.roundNumber + 1 : _state.roundNumber;
// // // //     final over = newRound > _state.maxRounds;
// // // //     final newQueue =
// // // //         _state.turnOrderMode == TurnOrderMode.random &&
// // // //             _state.randomTurnQueue.isEmpty &&
// // // //             !over
// // // //         ? _buildQueue(_state.playerOrder)
// // // //         : _state.randomTurnQueue;

// // // //     // Update last history record with reactions and votes collected during awaitingNextTurn
// // // //     final updatedHistory = _state.history.isNotEmpty
// // // //         ? [
// // // //             ..._state.history.sublist(0, _state.history.length - 1),
// // // //             _state.history.last.copyWith(
// // // //               reactions: _state.currentReactions,
// // // //               votes: _state.currentVotes,
// // // //             ),
// // // //           ]
// // // //         : _state.history;

// // // //     _state = _state.copyWith(
// // // //       snapshotAt: _now(),
// // // //       currentPlayerIndex: nextIdx,
// // // //       phase: TodTurnPhase.choosingType,
// // // //       roundNumber: newRound,
// // // //       currentCard: () => null,
// // // //       currentPunishmentVote: () => null,
// // // //       timerStartedAt: () => null,
// // // //       turnStartedAt: () => _now(),
// // // //       isOver: over,
// // // //       endReason: over ? 'round_limit' : null,
// // // //       randomTurnQueue: newQueue,
// // // //       turnResponse: '',
// // // //       turnProofImageB64: '',
// // // //       currentReactions: [],
// // // //       currentVotes: [],
// // // //       history: updatedHistory,
// // // //     );
// // // //     return _state;
// // // //   }

// // // //   @override
// // // //   Map<String, dynamic> serializeState() => _state.toMap();

// // // //   @override
// // // //   void restoreFromSnapshot(Map<String, dynamic> s) {
// // // //     _state = TodState.fromMap(s);
// // // //   }

// // // //   // ── Handlers ─────────────────────────────────────────────────────────────
// // // //   TodState _onChoice(TodChoiceEvent e) {
// // // //     if (e.userId != _state.currentPlayerId) return _state;
// // // //     if (_state.phase != TodTurnPhase.choosingType) return _state;
// // // //     final card = _draw(e.cardType);
// // // //     return _state.copyWith(
// // // //       snapshotAt: _now(),
// // // //       phase: TodTurnPhase.readingCard,
// // // //       currentCard: () => card,
// // // //       timerStartedAt: () => _config.timerEnabled ? _now() : null,
// // // //     );
// // // //   }

// // // //   TodState _onComplete(TodCompleteEvent e) {
// // // //     if (e.userId != _state.currentPlayerId) return _state;
// // // //     if (_state.phase != TodTurnPhase.readingCard) return _state;
// // // //     final card = _state.currentCard;
// // // //     final old = _state.scores[e.userId] ?? TodPlayerScore(userId: e.userId);
// // // //     final pts = card != null ? _pts(card) : 0;
// // // //     final upd = card?.type == TodCardType.truth
// // // //         ? old.copyWith(
// // // //             completedTruths: old.completedTruths + 1,
// // // //             points: old.points + pts,
// // // //           )
// // // //         : old.copyWith(
// // // //             completedDares: old.completedDares + 1,
// // // //             points: old.points + pts,
// // // //           );
// // // //     // Save round to history
// // // //     final record = TodRoundRecord(
// // // //       roundNumber: _state.roundNumber,
// // // //       playerId: e.userId,
// // // //       card: card,
// // // //       response: e.response,
// // // //       proofImageB64: e.proofImageB64,
// // // //     );
// // // //     return _state.copyWith(
// // // //       snapshotAt: _now(),
// // // //       phase: TodTurnPhase.awaitingNextTurn,
// // // //       scores: {..._state.scores, e.userId: upd},
// // // //       timerStartedAt: () => null,
// // // //       turnResponse: e.response,
// // // //       turnProofImageB64: e.proofImageB64,
// // // //       currentReactions: [],
// // // //       currentVotes: [],
// // // //       history: [..._state.history, record],
// // // //     );
// // // //   }

// // // //   TodState _onReact(TodReactEvent e) {
// // // //     // One reaction per player per turn
// // // //     if (_state.currentReactions.any((r) => r.userId == e.userId)) return _state;
// // // //     return _state.copyWith(
// // // //       snapshotAt: _now(),
// // // //       currentReactions: [
// // // //         ..._state.currentReactions,
// // // //         TodReaction(userId: e.userId, emoji: e.emoji, ts: e.ts),
// // // //       ],
// // // //     );
// // // //   }

// // // //   TodState _onVoteResponse(TodVoteResponseEvent e) {
// // // //     // One vote per player per turn
// // // //     if (_state.currentVotes.any((v) => v.voterId == e.userId)) return _state;
// // // //     return _state.copyWith(
// // // //       snapshotAt: _now(),
// // // //       currentVotes: [
// // // //         ..._state.currentVotes,
// // // //         TodResponseVote(voterId: e.userId, ts: e.ts),
// // // //       ],
// // // //     );
// // // //   }

// // // //   TodState _onSkip(TodSkipEvent e) {
// // // //     if (e.userId != _state.currentPlayerId) return _state;
// // // //     if (_state.phase != TodTurnPhase.readingCard) return _state;
// // // //     final old = _state.scores[e.userId] ?? TodPlayerScore(userId: e.userId);
// // // //     final upd = old.copyWith(skips: old.skips + 1);
// // // //     final nextPhase = _config.enablePunishments
// // // //         ? TodTurnPhase.punishmentVoting
// // // //         : TodTurnPhase.awaitingNextTurn;
// // // //     return _state.copyWith(
// // // //       snapshotAt: _now(),
// // // //       phase: nextPhase,
// // // //       scores: {..._state.scores, e.userId: upd},
// // // //       timerStartedAt: () => null,
// // // //     );
// // // //   }

// // // //   TodState _onTimerExpired(TodTimerExpiredEvent e) =>
// // // //       _onSkip(TodSkipEvent(userId: e.userId, ts: e.ts));

// // // //   TodState _onProposePunishment(TodProposePunishmentEvent e) {
// // // //     if (_state.phase != TodTurnPhase.punishmentVoting) return _state;
// // // //     final voteState = TodPunishmentVoteState(
// // // //       punishment: e.punishment,
// // // //       votes: {},
// // // //       totalVoters: _state.playerOrder.length - 1,
// // // //     );
// // // //     return _state.copyWith(
// // // //       snapshotAt: _now(),
// // // //       currentPunishmentVote: () => voteState,
// // // //     );
// // // //   }

// // // //   TodState _onVotePunishment(TodVotePunishmentEvent e) {
// // // //     if (_state.phase != TodTurnPhase.punishmentVoting) return _state;
// // // //     if (_state.currentPunishmentVote == null) return _state;
// // // //     if (e.userId == _state.currentPlayerId) return _state;
// // // //     final prev = _state.currentPunishmentVote!;
// // // //     final votes = {...prev.votes, e.userId: e.vote};
// // // //     final upd = TodPunishmentVoteState(
// // // //       punishment: prev.punishment,
// // // //       votes: votes,
// // // //       totalVoters: prev.totalVoters,
// // // //       moderatorOverride: prev.moderatorOverride,
// // // //     );
// // // //     var s = _state.copyWith(
// // // //       snapshotAt: _now(),
// // // //       currentPunishmentVote: () => upd,
// // // //     );
// // // //     if (upd.hasOutcome) s = _applyDecision(s, upd.resolvedVote);
// // // //     return s;
// // // //   }

// // // //   TodState _onModeratorOverride(TodModeratorOverrideEvent e) {
// // // //     if (_state.phase != TodTurnPhase.punishmentVoting) return _state;
// // // //     final prev = _state.currentPunishmentVote;
// // // //     var punishment =
// // // //         prev?.punishment ??
// // // //         TodPunishment(
// // // //           id: _uuid.v4(),
// // // //           text: e.replacementText ?? 'Punishment',
// // // //           proposedBy: e.userId,
// // // //           proposedAt: _now(),
// // // //         );
// // // //     if (e.replacementText != null) {
// // // //       punishment = TodPunishment(
// // // //         id: _uuid.v4(),
// // // //         text: e.replacementText!,
// // // //         proposedBy: e.userId,
// // // //         proposedAt: _now(),
// // // //       );
// // // //     }
// // // //     final upd = TodPunishmentVoteState(
// // // //       punishment: punishment,
// // // //       votes: prev?.votes ?? {},
// // // //       totalVoters: prev?.totalVoters ?? _state.playerOrder.length - 1,
// // // //       moderatorOverride: e.decision,
// // // //     );
// // // //     var s = _state.copyWith(
// // // //       snapshotAt: _now(),
// // // //       currentPunishmentVote: () => upd,
// // // //     );
// // // //     return _applyDecision(s, e.decision);
// // // //   }

// // // //   TodState _onEndGame(TodEndGameEvent e) =>
// // // //       _state.copyWith(snapshotAt: _now(), isOver: true, endReason: e.reason);

// // // //   TodState _applyDecision(TodState s, TodPunishmentVote? d) {
// // // //     if (d == null) return s;
// // // //     if (d == TodPunishmentVote.changePunishment) {
// // // //       final prev = s.currentPunishmentVote!;
// // // //       final reset = TodPunishmentVoteState(
// // // //         punishment: prev.punishment,
// // // //         votes: {},
// // // //         totalVoters: prev.totalVoters,
// // // //       );
// // // //       return s.copyWith(snapshotAt: _now(), currentPunishmentVote: () => reset);
// // // //     }
// // // //     // doIt or dontDoIt → end punishment phase
// // // //     final scores = Map<String, TodPlayerScore>.from(s.scores);
// // // //     if (d == TodPunishmentVote.doIt) {
// // // //       final old = scores[s.currentPlayerId];
// // // //       if (old != null) {
// // // //         scores[s.currentPlayerId] = old.copyWith(
// // // //           punishmentsReceived: old.punishmentsReceived + 1,
// // // //         );
// // // //       }
// // // //     }
// // // //     return s.copyWith(
// // // //       snapshotAt: _now(),
// // // //       phase: TodTurnPhase.awaitingNextTurn,
// // // //       scores: scores,
// // // //     );
// // // //   }

// // // //   // ── Helpers ───────────────────────────────────────────────────────────────
// // // //   TodCard? _draw(TodCardType type) {
// // // //     final pool = _deck
// // // //         .where(
// // // //           (c) =>
// // // //               c.type == type &&
// // // //               (_config.allowSpicy || c.difficulty != TodDifficulty.spicy) &&
// // // //               !_state.usedCardIds.contains(c.id),
// // // //         )
// // // //         .toList();

// // // //     if (pool.isEmpty) {
// // // //       // Reset used IDs for this card type on exhaustion
// // // //       final all = _deck
// // // //           .where(
// // // //             (c) =>
// // // //                 c.type == type &&
// // // //                 (_config.allowSpicy || c.difficulty != TodDifficulty.spicy),
// // // //           )
// // // //           .toList();
// // // //       if (all.isEmpty) return null;
// // // //       all.shuffle(_rng);
// // // //       return all.first;
// // // //     }
// // // //     pool.shuffle(_rng);
// // // //     final drawn = pool.first;
// // // //     _state = _state.copyWith(usedCardIds: [..._state.usedCardIds, drawn.id]);
// // // //     return drawn;
// // // //   }

// // // //   int _nextIndex() {
// // // //     if (_state.turnOrderMode == TurnOrderMode.random) {
// // // //       final q = _state.randomTurnQueue;
// // // //       if (q.isEmpty) return 0;
// // // //       final id = q.first;
// // // //       _state = _state.copyWith(randomTurnQueue: q.skip(1).toList());
// // // //       final idx = _state.playerOrder.indexOf(id);
// // // //       return idx < 0 ? 0 : idx;
// // // //     }
// // // //     return (_state.currentPlayerIndex + 1) % _state.playerOrder.length;
// // // //   }

// // // //   List<String> _buildQueue(List<String> p) => (List.of(p)..shuffle(_rng));
// // // //   int _pts(TodCard c) => switch (c.difficulty) {
// // // //     TodDifficulty.mild => 1,
// // // //     TodDifficulty.medium => 2,
// // // //     TodDifficulty.spicy => 3,
// // // //   };
// // // //   int _now() => DateTime.now().millisecondsSinceEpoch;
// // // // }

// // // import 'dart:math';
// // // import 'package:uuid/uuid.dart';

// // // import '../engine/base_game_engine.dart';
// // // import 'domain/tod_models.dart';

// // // const _uuid = Uuid();

// // // /// Truth or Dare pure-Dart game engine.
// // // /// Owner-authoritative: only the room owner runs this.
// // // /// Followers call restoreFromSnapshot() on every broadcast.
// // // class TruthOrDareEngine implements BaseGameEngine {
// // //   TruthOrDareEngine(this._config, {required List<TodCard> cards})
// // //     : _deck = List.of(cards);

// // //   final GameConfig _config;
// // //   final List<TodCard> _deck;
// // //   late TodState _state;
// // //   final _rng = Random.secure();

// // //   void init({required List<String> playerOrder, int startingIndex = 0}) {
// // //     _deck.shuffle(_rng);
// // //     final scores = {
// // //       for (final id in playerOrder) id: TodPlayerScore(userId: id),
// // //     };
// // //     final queue = _config.turnOrderMode == TurnOrderMode.random
// // //         ? (_buildQueue(playerOrder))
// // //         : <String>[];

// // //     _state = TodState(
// // //       snapshotAt: _now(),
// // //       playerOrder: playerOrder,
// // //       currentPlayerIndex: startingIndex,
// // //       phase: TodTurnPhase.choosingType,
// // //       roundNumber: 1,
// // //       maxRounds: _config.maxRounds,
// // //       scores: scores,
// // //       turnOrderMode: _config.turnOrderMode,
// // //       randomTurnQueue: queue,
// // //       turnStartedAt: _now(),
// // //     );
// // //   }

// // //   @override
// // //   TodState get currentState => _state;
// // //   @override
// // //   bool get isGameOver => _state.isOver;

// // //   @override
// // //   TodState handleEvent(GameEngineEvent event) {
// // //     _state = switch (event) {
// // //       TodChoiceEvent e => _onChoice(e),
// // //       TodCompleteEvent e => _onComplete(e),
// // //       TodProofViewedEvent e => _onProofViewed(e),
// // //       TodReactEvent e => _onReact(e),
// // //       TodVoteResponseEvent e => _onVoteResponse(e),
// // //       TodSkipEvent e => _onSkip(e),
// // //       TodTimerExpiredEvent e => _onTimerExpired(e),
// // //       TodProposePunishmentEvent e => _onProposePunishment(e),
// // //       TodVotePunishmentEvent e => _onVotePunishment(e),
// // //       TodModeratorOverrideEvent e => _onModeratorOverride(e),
// // //       TodEndGameEvent e => _onEndGame(e),
// // //       _ => _state,
// // //     };
// // //     return _state;
// // //   }

// // //   @override
// // //   TodState advanceTurn() {
// // //     if (_state.isOver) return _state;
// // //     final nextIdx = _nextIndex();
// // //     final wrapped =
// // //         _state.turnOrderMode == TurnOrderMode.circular && nextIdx == 0;
// // //     final newRound = wrapped ? _state.roundNumber + 1 : _state.roundNumber;
// // //     final over = newRound > _state.maxRounds;
// // //     final newQueue =
// // //         _state.turnOrderMode == TurnOrderMode.random &&
// // //             _state.randomTurnQueue.isEmpty &&
// // //             !over
// // //         ? _buildQueue(_state.playerOrder)
// // //         : _state.randomTurnQueue;

// // //     // Update last history record with reactions/votes/proof-watched status
// // //     // collected during awaitingNextTurn — the media itself is never copied,
// // //     // only who watched it.
// // //     final updatedHistory = _state.history.isNotEmpty
// // //         ? [
// // //             ..._state.history.sublist(0, _state.history.length - 1),
// // //             _state.history.last.copyWith(
// // //               reactions: _state.currentReactions,
// // //               votes: _state.currentVotes,
// // //               proofWatchedBy: _state.turnProofViewedBy,
// // //             ),
// // //           ]
// // //         : _state.history;

// // //     _state = _state.copyWith(
// // //       snapshotAt: _now(),
// // //       currentPlayerIndex: nextIdx,
// // //       phase: TodTurnPhase.choosingType,
// // //       roundNumber: newRound,
// // //       currentCard: () => null,
// // //       currentPunishmentVote: () => null,
// // //       timerStartedAt: () => null,
// // //       turnStartedAt: () => _now(),
// // //       isOver: over,
// // //       endReason: over ? 'round_limit' : null,
// // //       randomTurnQueue: newQueue,
// // //       turnResponse: '',
// // //       turnProofUrl: '',
// // //       turnProofIsVideo: false,
// // //       turnProofViewMode: TodProofViewMode.once,
// // //       turnProofViewSeconds: 5,
// // //       turnProofViewedBy: const [],
// // //       currentReactions: [],
// // //       currentVotes: [],
// // //       history: updatedHistory,
// // //     );
// // //     return _state;
// // //   }

// // //   @override
// // //   Map<String, dynamic> serializeState() => _state.toMap();

// // //   @override
// // //   void restoreFromSnapshot(Map<String, dynamic> s) {
// // //     _state = TodState.fromMap(s);
// // //   }

// // //   // ── Handlers ─────────────────────────────────────────────────────────────
// // //   TodState _onChoice(TodChoiceEvent e) {
// // //     if (e.userId != _state.currentPlayerId) return _state;
// // //     if (_state.phase != TodTurnPhase.choosingType) return _state;
// // //     final card = _draw(e.cardType);
// // //     return _state.copyWith(
// // //       snapshotAt: _now(),
// // //       phase: TodTurnPhase.readingCard,
// // //       currentCard: () => card,
// // //       timerStartedAt: () => _config.timerEnabled ? _now() : null,
// // //     );
// // //   }

// // //   TodState _onComplete(TodCompleteEvent e) {
// // //     if (e.userId != _state.currentPlayerId) return _state;
// // //     if (_state.phase != TodTurnPhase.readingCard) return _state;
// // //     final card = _state.currentCard;
// // //     final old = _state.scores[e.userId] ?? TodPlayerScore(userId: e.userId);
// // //     final pts = card != null ? _pts(card) : 0;
// // //     final upd = card?.type == TodCardType.truth
// // //         ? old.copyWith(
// // //             completedTruths: old.completedTruths + 1,
// // //             points: old.points + pts,
// // //           )
// // //         : old.copyWith(
// // //             completedDares: old.completedDares + 1,
// // //             points: old.points + pts,
// // //           );
// // //     // Save round to history — NOTE: no proof media is stored here, only
// // //     // whether one existed (hadProof). The actual file lives only on
// // //     // turnProofUrl for the duration of this turn and is discarded by
// // //     // advanceTurn() — see TodRoundRecord doc comment.
// // //     final record = TodRoundRecord(
// // //       roundNumber: _state.roundNumber,
// // //       playerId: e.userId,
// // //       card: card,
// // //       response: e.response,
// // //       hadProof: e.proofUrl.isNotEmpty,
// // //     );
// // //     return _state.copyWith(
// // //       snapshotAt: _now(),
// // //       phase: TodTurnPhase.awaitingNextTurn,
// // //       scores: {..._state.scores, e.userId: upd},
// // //       timerStartedAt: () => null,
// // //       turnResponse: e.response,
// // //       turnProofUrl: e.proofUrl,
// // //       turnProofIsVideo: e.proofIsVideo,
// // //       turnProofViewMode: e.proofViewMode,
// // //       turnProofViewSeconds: e.proofViewSeconds,
// // //       turnProofViewedBy: const [],
// // //       currentReactions: [],
// // //       currentVotes: [],
// // //       history: [..._state.history, record],
// // //     );
// // //   }

// // //   /// Someone opened/watched the current turn's proof — track it so it can
// // //   /// be carried into the history record's proofWatchedBy as "watched"
// // //   /// (never the media itself), and so re-view gating can check it.
// // //   TodState _onProofViewed(TodProofViewedEvent e) {
// // //     if (_state.turnProofViewedBy.contains(e.userId)) return _state;
// // //     return _state.copyWith(
// // //       snapshotAt: _now(),
// // //       turnProofViewedBy: [..._state.turnProofViewedBy, e.userId],
// // //     );
// // //   }

// // //   TodState _onReact(TodReactEvent e) {
// // //     // One reaction per player per turn
// // //     if (_state.currentReactions.any((r) => r.userId == e.userId)) return _state;
// // //     return _state.copyWith(
// // //       snapshotAt: _now(),
// // //       currentReactions: [
// // //         ..._state.currentReactions,
// // //         TodReaction(userId: e.userId, emoji: e.emoji, ts: e.ts),
// // //       ],
// // //     );
// // //   }

// // //   TodState _onVoteResponse(TodVoteResponseEvent e) {
// // //     // One vote per player per turn
// // //     if (_state.currentVotes.any((v) => v.voterId == e.userId)) return _state;
// // //     return _state.copyWith(
// // //       snapshotAt: _now(),
// // //       currentVotes: [
// // //         ..._state.currentVotes,
// // //         TodResponseVote(voterId: e.userId, ts: e.ts),
// // //       ],
// // //     );
// // //   }

// // //   TodState _onSkip(TodSkipEvent e) {
// // //     if (e.userId != _state.currentPlayerId) return _state;
// // //     if (_state.phase != TodTurnPhase.readingCard) return _state;
// // //     final old = _state.scores[e.userId] ?? TodPlayerScore(userId: e.userId);
// // //     final upd = old.copyWith(skips: old.skips + 1);
// // //     final nextPhase = _config.enablePunishments
// // //         ? TodTurnPhase.punishmentVoting
// // //         : TodTurnPhase.awaitingNextTurn;
// // //     return _state.copyWith(
// // //       snapshotAt: _now(),
// // //       phase: nextPhase,
// // //       scores: {..._state.scores, e.userId: upd},
// // //       timerStartedAt: () => null,
// // //     );
// // //   }

// // //   TodState _onTimerExpired(TodTimerExpiredEvent e) =>
// // //       _onSkip(TodSkipEvent(userId: e.userId, ts: e.ts));

// // //   TodState _onProposePunishment(TodProposePunishmentEvent e) {
// // //     if (_state.phase != TodTurnPhase.punishmentVoting) return _state;
// // //     final voteState = TodPunishmentVoteState(
// // //       punishment: e.punishment,
// // //       votes: {},
// // //       totalVoters: _state.playerOrder.length - 1,
// // //     );
// // //     return _state.copyWith(
// // //       snapshotAt: _now(),
// // //       currentPunishmentVote: () => voteState,
// // //     );
// // //   }

// // //   TodState _onVotePunishment(TodVotePunishmentEvent e) {
// // //     if (_state.phase != TodTurnPhase.punishmentVoting) return _state;
// // //     if (_state.currentPunishmentVote == null) return _state;
// // //     if (e.userId == _state.currentPlayerId) return _state;
// // //     final prev = _state.currentPunishmentVote!;
// // //     final votes = {...prev.votes, e.userId: e.vote};
// // //     final upd = TodPunishmentVoteState(
// // //       punishment: prev.punishment,
// // //       votes: votes,
// // //       totalVoters: prev.totalVoters,
// // //       moderatorOverride: prev.moderatorOverride,
// // //     );
// // //     var s = _state.copyWith(
// // //       snapshotAt: _now(),
// // //       currentPunishmentVote: () => upd,
// // //     );
// // //     if (upd.hasOutcome) s = _applyDecision(s, upd.resolvedVote);
// // //     return s;
// // //   }

// // //   TodState _onModeratorOverride(TodModeratorOverrideEvent e) {
// // //     if (_state.phase != TodTurnPhase.punishmentVoting) return _state;
// // //     final prev = _state.currentPunishmentVote;
// // //     var punishment =
// // //         prev?.punishment ??
// // //         TodPunishment(
// // //           id: _uuid.v4(),
// // //           text: e.replacementText ?? 'Punishment',
// // //           proposedBy: e.userId,
// // //           proposedAt: _now(),
// // //         );
// // //     if (e.replacementText != null) {
// // //       punishment = TodPunishment(
// // //         id: _uuid.v4(),
// // //         text: e.replacementText!,
// // //         proposedBy: e.userId,
// // //         proposedAt: _now(),
// // //       );
// // //     }
// // //     final upd = TodPunishmentVoteState(
// // //       punishment: punishment,
// // //       votes: prev?.votes ?? {},
// // //       totalVoters: prev?.totalVoters ?? _state.playerOrder.length - 1,
// // //       moderatorOverride: e.decision,
// // //     );
// // //     var s = _state.copyWith(
// // //       snapshotAt: _now(),
// // //       currentPunishmentVote: () => upd,
// // //     );
// // //     return _applyDecision(s, e.decision);
// // //   }

// // //   TodState _onEndGame(TodEndGameEvent e) =>
// // //       _state.copyWith(snapshotAt: _now(), isOver: true, endReason: e.reason);

// // //   TodState _applyDecision(TodState s, TodPunishmentVote? d) {
// // //     if (d == null) return s;
// // //     if (d == TodPunishmentVote.changePunishment) {
// // //       final prev = s.currentPunishmentVote!;
// // //       final reset = TodPunishmentVoteState(
// // //         punishment: prev.punishment,
// // //         votes: {},
// // //         totalVoters: prev.totalVoters,
// // //       );
// // //       return s.copyWith(snapshotAt: _now(), currentPunishmentVote: () => reset);
// // //     }
// // //     // doIt or dontDoIt → end punishment phase
// // //     final scores = Map<String, TodPlayerScore>.from(s.scores);
// // //     if (d == TodPunishmentVote.doIt) {
// // //       final old = scores[s.currentPlayerId];
// // //       if (old != null) {
// // //         scores[s.currentPlayerId] = old.copyWith(
// // //           punishmentsReceived: old.punishmentsReceived + 1,
// // //         );
// // //       }
// // //     }
// // //     return s.copyWith(
// // //       snapshotAt: _now(),
// // //       phase: TodTurnPhase.awaitingNextTurn,
// // //       scores: scores,
// // //     );
// // //   }

// // //   // ── Helpers ───────────────────────────────────────────────────────────────
// // //   TodCard? _draw(TodCardType type) {
// // //     final pool = _deck
// // //         .where(
// // //           (c) =>
// // //               c.type == type &&
// // //               (_config.allowSpicy || c.difficulty != TodDifficulty.spicy) &&
// // //               !_state.usedCardIds.contains(c.id),
// // //         )
// // //         .toList();

// // //     if (pool.isEmpty) {
// // //       // Reset used IDs for this card type on exhaustion
// // //       final all = _deck
// // //           .where(
// // //             (c) =>
// // //                 c.type == type &&
// // //                 (_config.allowSpicy || c.difficulty != TodDifficulty.spicy),
// // //           )
// // //           .toList();
// // //       if (all.isEmpty) return null;
// // //       all.shuffle(_rng);
// // //       return all.first;
// // //     }
// // //     pool.shuffle(_rng);
// // //     final drawn = pool.first;
// // //     _state = _state.copyWith(usedCardIds: [..._state.usedCardIds, drawn.id]);
// // //     return drawn;
// // //   }

// // //   int _nextIndex() {
// // //     if (_state.turnOrderMode == TurnOrderMode.random) {
// // //       final q = _state.randomTurnQueue;
// // //       if (q.isEmpty) return 0;
// // //       final id = q.first;
// // //       _state = _state.copyWith(randomTurnQueue: q.skip(1).toList());
// // //       final idx = _state.playerOrder.indexOf(id);
// // //       return idx < 0 ? 0 : idx;
// // //     }
// // //     return (_state.currentPlayerIndex + 1) % _state.playerOrder.length;
// // //   }

// // //   List<String> _buildQueue(List<String> p) => (List.of(p)..shuffle(_rng));
// // //   int _pts(TodCard c) => switch (c.difficulty) {
// // //     TodDifficulty.mild => 1,
// // //     TodDifficulty.medium => 2,
// // //     TodDifficulty.spicy => 3,
// // //   };
// // //   int _now() => DateTime.now().millisecondsSinceEpoch;
// // // }

// // import 'dart:math';
// // import 'package:uuid/uuid.dart';

// // import '../engine/base_game_engine.dart';
// // import 'domain/tod_models.dart';

// // const _uuid = Uuid();

// // /// Truth or Dare pure-Dart game engine.
// // /// Owner-authoritative: only the room owner runs this.
// // /// Followers call restoreFromSnapshot() on every broadcast.
// // class TruthOrDareEngine implements BaseGameEngine {
// //   TruthOrDareEngine(this._config, {required List<TodCard> cards})
// //     : _deck = List.of(cards);

// //   final GameConfig _config;
// //   final List<TodCard> _deck;
// //   late TodState _state;
// //   final _rng = Random.secure();

// //   void init({required List<String> playerOrder, int startingIndex = 0}) {
// //     _deck.shuffle(_rng);
// //     final scores = {
// //       for (final id in playerOrder) id: TodPlayerScore(userId: id),
// //     };
// //     final queue = _config.turnOrderMode == TurnOrderMode.random
// //         ? (_buildQueue(playerOrder))
// //         : <String>[];

// //     _state = TodState(
// //       snapshotAt: _now(),
// //       playerOrder: playerOrder,
// //       currentPlayerIndex: startingIndex,
// //       phase: TodTurnPhase.choosingType,
// //       roundNumber: 1,
// //       maxRounds: _config.maxRounds,
// //       scores: scores,
// //       turnOrderMode: _config.turnOrderMode,
// //       randomTurnQueue: queue,
// //       turnStartedAt: _now(),
// //     );
// //   }

// //   @override
// //   TodState get currentState => _state;
// //   @override
// //   bool get isGameOver => _state.isOver;

// //   @override
// //   TodState handleEvent(GameEngineEvent event) {
// //     _state = switch (event) {
// //       TodChoiceEvent e => _onChoice(e),
// //       TodCompleteEvent e => _onComplete(e),
// //       TodProofViewedEvent e => _onProofViewed(e),
// //       TodReactEvent e => _onReact(e),
// //       TodVoteResponseEvent e => _onVoteResponse(e),
// //       TodSkipEvent e => _onSkip(e),
// //       TodTimerExpiredEvent e => _onTimerExpired(e),
// //       TodProposePunishmentEvent e => _onProposePunishment(e),
// //       TodVotePunishmentEvent e => _onVotePunishment(e),
// //       TodModeratorOverrideEvent e => _onModeratorOverride(e),
// //       TodEndGameEvent e => _onEndGame(e),
// //       _ => _state,
// //     };
// //     return _state;
// //   }

// //   @override
// //   TodState advanceTurn() {
// //     if (_state.isOver) return _state;
// //     final nextIdx = _nextIndex();
// //     final wrapped =
// //         _state.turnOrderMode == TurnOrderMode.circular && nextIdx == 0;
// //     final newRound = wrapped ? _state.roundNumber + 1 : _state.roundNumber;
// //     final over = newRound > _state.maxRounds;
// //     final newQueue =
// //         _state.turnOrderMode == TurnOrderMode.random &&
// //             _state.randomTurnQueue.isEmpty &&
// //             !over
// //         ? _buildQueue(_state.playerOrder)
// //         : _state.randomTurnQueue;

// //     // Update last history record with reactions/votes/proof-watched status
// //     // collected during awaitingNextTurn — the media itself is never copied,
// //     // only who watched it.
// //     final updatedHistory = _state.history.isNotEmpty
// //         ? [
// //             ..._state.history.sublist(0, _state.history.length - 1),
// //             _state.history.last.copyWith(
// //               reactions: _state.currentReactions,
// //               votes: _state.currentVotes,
// //               proofWatchedBy: _state.turnProofViewedBy,
// //             ),
// //           ]
// //         : _state.history;

// //     _state = _state.copyWith(
// //       snapshotAt: _now(),
// //       currentPlayerIndex: nextIdx,
// //       phase: TodTurnPhase.choosingType,
// //       roundNumber: newRound,
// //       currentCard: () => null,
// //       currentPunishmentVote: () => null,
// //       timerStartedAt: () => null,
// //       turnStartedAt: () => _now(),
// //       isOver: over,
// //       endReason: over ? 'round_limit' : null,
// //       randomTurnQueue: newQueue,
// //       turnResponse: '',
// //       turnProofImageB64: '',
// //       turnProofSource: TodProofSource.camera,
// //       turnProofViewMode: TodProofViewMode.once,
// //       turnProofViewSeconds: 5,
// //       turnProofViewedBy: const [],
// //       currentReactions: [],
// //       currentVotes: [],
// //       history: updatedHistory,
// //     );
// //     return _state;
// //   }

// //   @override
// //   Map<String, dynamic> serializeState() => _state.toMap();

// //   @override
// //   void restoreFromSnapshot(Map<String, dynamic> s) {
// //     _state = TodState.fromMap(s);
// //   }

// //   // ── Handlers ─────────────────────────────────────────────────────────────
// //   TodState _onChoice(TodChoiceEvent e) {
// //     if (e.userId != _state.currentPlayerId) return _state;
// //     if (_state.phase != TodTurnPhase.choosingType) return _state;
// //     final card = _draw(e.cardType);
// //     return _state.copyWith(
// //       snapshotAt: _now(),
// //       phase: TodTurnPhase.readingCard,
// //       currentCard: () => card,
// //       timerStartedAt: () => _config.timerEnabled ? _now() : null,
// //     );
// //   }

// //   TodState _onComplete(TodCompleteEvent e) {
// //     if (e.userId != _state.currentPlayerId) return _state;
// //     if (_state.phase != TodTurnPhase.readingCard) return _state;
// //     final card = _state.currentCard;
// //     final old = _state.scores[e.userId] ?? TodPlayerScore(userId: e.userId);
// //     final pts = card != null ? _pts(card) : 0;
// //     final upd = card?.type == TodCardType.truth
// //         ? old.copyWith(
// //             completedTruths: old.completedTruths + 1,
// //             points: old.points + pts,
// //           )
// //         : old.copyWith(
// //             completedDares: old.completedDares + 1,
// //             points: old.points + pts,
// //           );
// //     // Save round to history — NOTE: no proof media is stored here, only
// //     // whether one existed (hadProof). The actual photo lives only on
// //     // turnProofImageB64 for the duration of this turn and is discarded by
// //     // advanceTurn() — see TodRoundRecord doc comment.
// //     final record = TodRoundRecord(
// //       roundNumber: _state.roundNumber,
// //       playerId: e.userId,
// //       card: card,
// //       response: e.response,
// //       hadProof: e.proofImageB64.isNotEmpty,
// //     );
// //     return _state.copyWith(
// //       snapshotAt: _now(),
// //       phase: TodTurnPhase.awaitingNextTurn,
// //       scores: {..._state.scores, e.userId: upd},
// //       timerStartedAt: () => null,
// //       turnResponse: e.response,
// //       turnProofImageB64: e.proofImageB64,
// //       turnProofSource: e.proofSource,
// //       turnProofViewMode: e.proofViewMode,
// //       turnProofViewSeconds: e.proofViewSeconds,
// //       turnProofViewedBy: const [],
// //       currentReactions: [],
// //       currentVotes: [],
// //       history: [..._state.history, record],
// //     );
// //   }

// //   /// Someone opened/watched the current turn's proof — track it so it can
// //   /// be carried into the history record's proofWatchedBy as "watched"
// //   /// (never the media itself), and so re-view gating can check it.
// //   TodState _onProofViewed(TodProofViewedEvent e) {
// //     if (_state.turnProofViewedBy.contains(e.userId)) return _state;
// //     return _state.copyWith(
// //       snapshotAt: _now(),
// //       turnProofViewedBy: [..._state.turnProofViewedBy, e.userId],
// //     );
// //   }

// //   TodState _onReact(TodReactEvent e) {
// //     // One reaction per player per turn
// //     if (_state.currentReactions.any((r) => r.userId == e.userId)) return _state;
// //     return _state.copyWith(
// //       snapshotAt: _now(),
// //       currentReactions: [
// //         ..._state.currentReactions,
// //         TodReaction(userId: e.userId, emoji: e.emoji, ts: e.ts),
// //       ],
// //     );
// //   }

// //   TodState _onVoteResponse(TodVoteResponseEvent e) {
// //     // One vote per player per turn
// //     if (_state.currentVotes.any((v) => v.voterId == e.userId)) return _state;
// //     return _state.copyWith(
// //       snapshotAt: _now(),
// //       currentVotes: [
// //         ..._state.currentVotes,
// //         TodResponseVote(voterId: e.userId, ts: e.ts),
// //       ],
// //     );
// //   }

// //   TodState _onSkip(TodSkipEvent e) {
// //     if (e.userId != _state.currentPlayerId) return _state;
// //     if (_state.phase != TodTurnPhase.readingCard) return _state;
// //     final old = _state.scores[e.userId] ?? TodPlayerScore(userId: e.userId);
// //     final upd = old.copyWith(skips: old.skips + 1);
// //     final nextPhase = _config.enablePunishments
// //         ? TodTurnPhase.punishmentVoting
// //         : TodTurnPhase.awaitingNextTurn;
// //     return _state.copyWith(
// //       snapshotAt: _now(),
// //       phase: nextPhase,
// //       scores: {..._state.scores, e.userId: upd},
// //       timerStartedAt: () => null,
// //     );
// //   }

// //   TodState _onTimerExpired(TodTimerExpiredEvent e) =>
// //       _onSkip(TodSkipEvent(userId: e.userId, ts: e.ts));

// //   TodState _onProposePunishment(TodProposePunishmentEvent e) {
// //     if (_state.phase != TodTurnPhase.punishmentVoting) return _state;
// //     final voteState = TodPunishmentVoteState(
// //       punishment: e.punishment,
// //       votes: {},
// //       totalVoters: _state.playerOrder.length - 1,
// //     );
// //     return _state.copyWith(
// //       snapshotAt: _now(),
// //       currentPunishmentVote: () => voteState,
// //     );
// //   }

// //   TodState _onVotePunishment(TodVotePunishmentEvent e) {
// //     if (_state.phase != TodTurnPhase.punishmentVoting) return _state;
// //     if (_state.currentPunishmentVote == null) return _state;
// //     if (e.userId == _state.currentPlayerId) return _state;
// //     final prev = _state.currentPunishmentVote!;
// //     final votes = {...prev.votes, e.userId: e.vote};
// //     final upd = TodPunishmentVoteState(
// //       punishment: prev.punishment,
// //       votes: votes,
// //       totalVoters: prev.totalVoters,
// //       moderatorOverride: prev.moderatorOverride,
// //     );
// //     var s = _state.copyWith(
// //       snapshotAt: _now(),
// //       currentPunishmentVote: () => upd,
// //     );
// //     if (upd.hasOutcome) s = _applyDecision(s, upd.resolvedVote);
// //     return s;
// //   }

// //   TodState _onModeratorOverride(TodModeratorOverrideEvent e) {
// //     if (_state.phase != TodTurnPhase.punishmentVoting) return _state;
// //     final prev = _state.currentPunishmentVote;
// //     var punishment =
// //         prev?.punishment ??
// //         TodPunishment(
// //           id: _uuid.v4(),
// //           text: e.replacementText ?? 'Punishment',
// //           proposedBy: e.userId,
// //           proposedAt: _now(),
// //         );
// //     if (e.replacementText != null) {
// //       punishment = TodPunishment(
// //         id: _uuid.v4(),
// //         text: e.replacementText!,
// //         proposedBy: e.userId,
// //         proposedAt: _now(),
// //       );
// //     }
// //     final upd = TodPunishmentVoteState(
// //       punishment: punishment,
// //       votes: prev?.votes ?? {},
// //       totalVoters: prev?.totalVoters ?? _state.playerOrder.length - 1,
// //       moderatorOverride: e.decision,
// //     );
// //     var s = _state.copyWith(
// //       snapshotAt: _now(),
// //       currentPunishmentVote: () => upd,
// //     );
// //     return _applyDecision(s, e.decision);
// //   }

// //   TodState _onEndGame(TodEndGameEvent e) =>
// //       _state.copyWith(snapshotAt: _now(), isOver: true, endReason: e.reason);

// //   TodState _applyDecision(TodState s, TodPunishmentVote? d) {
// //     if (d == null) return s;
// //     if (d == TodPunishmentVote.changePunishment) {
// //       final prev = s.currentPunishmentVote!;
// //       final reset = TodPunishmentVoteState(
// //         punishment: prev.punishment,
// //         votes: {},
// //         totalVoters: prev.totalVoters,
// //       );
// //       return s.copyWith(snapshotAt: _now(), currentPunishmentVote: () => reset);
// //     }
// //     // doIt or dontDoIt → end punishment phase
// //     final scores = Map<String, TodPlayerScore>.from(s.scores);
// //     if (d == TodPunishmentVote.doIt) {
// //       final old = scores[s.currentPlayerId];
// //       if (old != null) {
// //         scores[s.currentPlayerId] = old.copyWith(
// //           punishmentsReceived: old.punishmentsReceived + 1,
// //         );
// //       }
// //     }
// //     return s.copyWith(
// //       snapshotAt: _now(),
// //       phase: TodTurnPhase.awaitingNextTurn,
// //       scores: scores,
// //     );
// //   }

// //   // ── Helpers ───────────────────────────────────────────────────────────────
// //   TodCard? _draw(TodCardType type) {
// //     final pool = _deck
// //         .where(
// //           (c) =>
// //               c.type == type &&
// //               (_config.allowSpicy || c.difficulty != TodDifficulty.spicy) &&
// //               !_state.usedCardIds.contains(c.id),
// //         )
// //         .toList();

// //     if (pool.isEmpty) {
// //       // Reset used IDs for this card type on exhaustion
// //       final all = _deck
// //           .where(
// //             (c) =>
// //                 c.type == type &&
// //                 (_config.allowSpicy || c.difficulty != TodDifficulty.spicy),
// //           )
// //           .toList();
// //       if (all.isEmpty) return null;
// //       all.shuffle(_rng);
// //       return all.first;
// //     }
// //     pool.shuffle(_rng);
// //     final drawn = pool.first;
// //     _state = _state.copyWith(usedCardIds: [..._state.usedCardIds, drawn.id]);
// //     return drawn;
// //   }

// //   int _nextIndex() {
// //     if (_state.turnOrderMode == TurnOrderMode.random) {
// //       final q = _state.randomTurnQueue;
// //       if (q.isEmpty) return 0;
// //       final id = q.first;
// //       _state = _state.copyWith(randomTurnQueue: q.skip(1).toList());
// //       final idx = _state.playerOrder.indexOf(id);
// //       return idx < 0 ? 0 : idx;
// //     }
// //     return (_state.currentPlayerIndex + 1) % _state.playerOrder.length;
// //   }

// //   List<String> _buildQueue(List<String> p) => (List.of(p)..shuffle(_rng));
// //   int _pts(TodCard c) => switch (c.difficulty) {
// //     TodDifficulty.mild => 1,
// //     TodDifficulty.medium => 2,
// //     TodDifficulty.spicy => 3,
// //   };
// //   int _now() => DateTime.now().millisecondsSinceEpoch;
// // }

// import 'dart:math';
// import 'package:uuid/uuid.dart';

// import '../engine/base_game_engine.dart';
// import 'domain/tod_models.dart';

// const _uuid = Uuid();

// /// Truth or Dare pure-Dart game engine.
// /// Owner-authoritative: only the room owner runs this.
// /// Followers call restoreFromSnapshot() on every broadcast.
// class TruthOrDareEngine implements BaseGameEngine {
//   TruthOrDareEngine(this._config, {required List<TodCard> cards})
//     : _deck = List.of(cards);

//   final GameConfig _config;
//   final List<TodCard> _deck;
//   late TodState _state;
//   final _rng = Random.secure();

//   void init({required List<String> playerOrder, int startingIndex = 0}) {
//     _deck.shuffle(_rng);
//     final scores = {
//       for (final id in playerOrder) id: TodPlayerScore(userId: id),
//     };
//     final queue = _config.turnOrderMode == TurnOrderMode.random
//         ? (_buildQueue(playerOrder))
//         : <String>[];

//     _state = TodState(
//       snapshotAt: _now(),
//       playerOrder: playerOrder,
//       currentPlayerIndex: startingIndex,
//       phase: TodTurnPhase.choosingType,
//       roundNumber: 1,
//       maxRounds: _config.maxRounds,
//       scores: scores,
//       turnOrderMode: _config.turnOrderMode,
//       randomTurnQueue: queue,
//       turnStartedAt: _now(),
//     );
//   }

//   @override
//   TodState get currentState => _state;
//   @override
//   bool get isGameOver => _state.isOver;

//   @override
//   TodState handleEvent(GameEngineEvent event) {
//     _state = switch (event) {
//       TodChoiceEvent e => _onChoice(e),
//       TodCompleteEvent e => _onComplete(e),
//       TodProofViewedEvent e => _onProofViewed(e),
//       TodReactEvent e => _onReact(e),
//       TodVoteResponseEvent e => _onVoteResponse(e),
//       TodSkipEvent e => _onSkip(e),
//       TodTimerExpiredEvent e => _onTimerExpired(e),
//       TodProposePunishmentEvent e => _onProposePunishment(e),
//       TodVotePunishmentEvent e => _onVotePunishment(e),
//       TodModeratorOverrideEvent e => _onModeratorOverride(e),
//       TodEndGameEvent e => _onEndGame(e),
//       _ => _state,
//     };
//     return _state;
//   }

//   @override
//   TodState advanceTurn() {
//     if (_state.isOver) return _state;
//     final nextIdx = _nextIndex();
//     final wrapped =
//         _state.turnOrderMode == TurnOrderMode.circular && nextIdx == 0;
//     final newRound = wrapped ? _state.roundNumber + 1 : _state.roundNumber;
//     final over = newRound > _state.maxRounds;
//     final newQueue =
//         _state.turnOrderMode == TurnOrderMode.random &&
//             _state.randomTurnQueue.isEmpty &&
//             !over
//         ? _buildQueue(_state.playerOrder)
//         : _state.randomTurnQueue;

//     // Update last history record with reactions/votes/proof-watched status
//     // collected during awaitingNextTurn — the media itself is never copied,
//     // only who watched it.
//     final updatedHistory = _state.history.isNotEmpty
//         ? [
//             ..._state.history.sublist(0, _state.history.length - 1),
//             _state.history.last.copyWith(
//               reactions: _state.currentReactions,
//               votes: _state.currentVotes,
//               proofWatchedBy: _state.turnProofViewedBy,
//             ),
//           ]
//         : _state.history;

//     _state = _state.copyWith(
//       snapshotAt: _now(),
//       currentPlayerIndex: nextIdx,
//       phase: TodTurnPhase.choosingType,
//       roundNumber: newRound,
//       currentCard: () => null,
//       currentPunishmentVote: () => null,
//       timerStartedAt: () => null,
//       turnStartedAt: () => _now(),
//       isOver: over,
//       endReason: over ? 'round_limit' : null,
//       randomTurnQueue: newQueue,
//       turnResponse: '',
//       turnProofImageB64: '',
//       turnProofSource: TodProofSource.camera,
//       turnProofViewMode: TodProofViewMode.once,
//       turnProofViewSeconds: 5,
//       turnProofViewedBy: const [],
//       currentReactions: [],
//       currentVotes: [],
//       history: updatedHistory,
//     );
//     return _state;
//   }

//   @override
//   Map<String, dynamic> serializeState() => _state.toMap();

//   @override
//   void restoreFromSnapshot(Map<String, dynamic> s) {
//     _state = TodState.fromMap(s);
//   }

//   /// Inject a card into the remaining deck so it can appear during the
//   /// current game. Used for premium session-local custom cards — the card
//   /// is inserted at a random position to avoid always appearing last.
//   void injectCard(TodCard card) {
//     final pos = _deck.isNotEmpty ? _rng.nextInt(_deck.length) : 0;
//     _deck.insert(pos, card);
//   }

//   // ── Handlers ─────────────────────────────────────────────────────────────
//   TodState _onChoice(TodChoiceEvent e) {
//     if (e.userId != _state.currentPlayerId) return _state;
//     if (_state.phase != TodTurnPhase.choosingType) return _state;
//     final card = _draw(e.cardType);
//     return _state.copyWith(
//       snapshotAt: _now(),
//       phase: TodTurnPhase.readingCard,
//       currentCard: () => card,
//       timerStartedAt: () => _config.timerEnabled ? _now() : null,
//     );
//   }

//   TodState _onComplete(TodCompleteEvent e) {
//     if (e.userId != _state.currentPlayerId) return _state;
//     if (_state.phase != TodTurnPhase.readingCard) return _state;
//     final card = _state.currentCard;
//     final old = _state.scores[e.userId] ?? TodPlayerScore(userId: e.userId);
//     final pts = card != null ? _pts(card) : 0;
//     final upd = card?.type == TodCardType.truth
//         ? old.copyWith(
//             completedTruths: old.completedTruths + 1,
//             points: old.points + pts,
//           )
//         : old.copyWith(
//             completedDares: old.completedDares + 1,
//             points: old.points + pts,
//           );
//     // Save round to history — NOTE: no proof media is stored here, only
//     // whether one existed (hadProof). The actual photo lives only on
//     // turnProofImageB64 for the duration of this turn and is discarded by
//     // advanceTurn() — see TodRoundRecord doc comment.
//     final record = TodRoundRecord(
//       roundNumber: _state.roundNumber,
//       playerId: e.userId,
//       card: card,
//       response: e.response,
//       hadProof: e.proofImageB64.isNotEmpty,
//     );
//     return _state.copyWith(
//       snapshotAt: _now(),
//       phase: TodTurnPhase.awaitingNextTurn,
//       scores: {..._state.scores, e.userId: upd},
//       timerStartedAt: () => null,
//       turnResponse: e.response,
//       turnProofImageB64: e.proofImageB64,
//       turnProofSource: e.proofSource,
//       turnProofViewMode: e.proofViewMode,
//       turnProofViewSeconds: e.proofViewSeconds,
//       turnProofViewedBy: const [],
//       currentReactions: [],
//       currentVotes: [],
//       history: [..._state.history, record],
//     );
//   }

//   /// Someone opened/watched the current turn's proof — track it so it can
//   /// be carried into the history record's proofWatchedBy as "watched"
//   /// (never the media itself), and so re-view gating can check it.
//   TodState _onProofViewed(TodProofViewedEvent e) {
//     if (_state.turnProofViewedBy.contains(e.userId)) return _state;
//     return _state.copyWith(
//       snapshotAt: _now(),
//       turnProofViewedBy: [..._state.turnProofViewedBy, e.userId],
//     );
//   }

//   TodState _onReact(TodReactEvent e) {
//     // One reaction per player per turn
//     if (_state.currentReactions.any((r) => r.userId == e.userId)) return _state;
//     return _state.copyWith(
//       snapshotAt: _now(),
//       currentReactions: [
//         ..._state.currentReactions,
//         TodReaction(userId: e.userId, emoji: e.emoji, ts: e.ts),
//       ],
//     );
//   }

//   TodState _onVoteResponse(TodVoteResponseEvent e) {
//     // One vote per player per turn
//     if (_state.currentVotes.any((v) => v.voterId == e.userId)) return _state;
//     return _state.copyWith(
//       snapshotAt: _now(),
//       currentVotes: [
//         ..._state.currentVotes,
//         TodResponseVote(voterId: e.userId, ts: e.ts),
//       ],
//     );
//   }

//   TodState _onSkip(TodSkipEvent e) {
//     if (e.userId != _state.currentPlayerId) return _state;
//     if (_state.phase != TodTurnPhase.readingCard) return _state;
//     final old = _state.scores[e.userId] ?? TodPlayerScore(userId: e.userId);
//     final upd = old.copyWith(skips: old.skips + 1);
//     final nextPhase = _config.enablePunishments
//         ? TodTurnPhase.punishmentVoting
//         : TodTurnPhase.awaitingNextTurn;
//     return _state.copyWith(
//       snapshotAt: _now(),
//       phase: nextPhase,
//       scores: {..._state.scores, e.userId: upd},
//       timerStartedAt: () => null,
//     );
//   }

//   TodState _onTimerExpired(TodTimerExpiredEvent e) =>
//       _onSkip(TodSkipEvent(userId: e.userId, ts: e.ts));

//   TodState _onProposePunishment(TodProposePunishmentEvent e) {
//     if (_state.phase != TodTurnPhase.punishmentVoting) return _state;
//     final voteState = TodPunishmentVoteState(
//       punishment: e.punishment,
//       votes: {},
//       totalVoters: _state.playerOrder.length - 1,
//     );
//     return _state.copyWith(
//       snapshotAt: _now(),
//       currentPunishmentVote: () => voteState,
//     );
//   }

//   TodState _onVotePunishment(TodVotePunishmentEvent e) {
//     if (_state.phase != TodTurnPhase.punishmentVoting) return _state;
//     if (_state.currentPunishmentVote == null) return _state;
//     if (e.userId == _state.currentPlayerId) return _state;
//     final prev = _state.currentPunishmentVote!;
//     final votes = {...prev.votes, e.userId: e.vote};
//     final upd = TodPunishmentVoteState(
//       punishment: prev.punishment,
//       votes: votes,
//       totalVoters: prev.totalVoters,
//       moderatorOverride: prev.moderatorOverride,
//     );
//     var s = _state.copyWith(
//       snapshotAt: _now(),
//       currentPunishmentVote: () => upd,
//     );
//     if (upd.hasOutcome) s = _applyDecision(s, upd.resolvedVote);
//     return s;
//   }

//   TodState _onModeratorOverride(TodModeratorOverrideEvent e) {
//     if (_state.phase != TodTurnPhase.punishmentVoting) return _state;
//     final prev = _state.currentPunishmentVote;
//     var punishment =
//         prev?.punishment ??
//         TodPunishment(
//           id: _uuid.v4(),
//           text: e.replacementText ?? 'Punishment',
//           proposedBy: e.userId,
//           proposedAt: _now(),
//         );
//     if (e.replacementText != null) {
//       punishment = TodPunishment(
//         id: _uuid.v4(),
//         text: e.replacementText!,
//         proposedBy: e.userId,
//         proposedAt: _now(),
//       );
//     }
//     final upd = TodPunishmentVoteState(
//       punishment: punishment,
//       votes: prev?.votes ?? {},
//       totalVoters: prev?.totalVoters ?? _state.playerOrder.length - 1,
//       moderatorOverride: e.decision,
//     );
//     var s = _state.copyWith(
//       snapshotAt: _now(),
//       currentPunishmentVote: () => upd,
//     );
//     return _applyDecision(s, e.decision);
//   }

//   TodState _onEndGame(TodEndGameEvent e) =>
//       _state.copyWith(snapshotAt: _now(), isOver: true, endReason: e.reason);

//   TodState _applyDecision(TodState s, TodPunishmentVote? d) {
//     if (d == null) return s;
//     if (d == TodPunishmentVote.changePunishment) {
//       final prev = s.currentPunishmentVote!;
//       final reset = TodPunishmentVoteState(
//         punishment: prev.punishment,
//         votes: {},
//         totalVoters: prev.totalVoters,
//       );
//       return s.copyWith(snapshotAt: _now(), currentPunishmentVote: () => reset);
//     }
//     // doIt or dontDoIt → end punishment phase
//     final scores = Map<String, TodPlayerScore>.from(s.scores);
//     if (d == TodPunishmentVote.doIt) {
//       final old = scores[s.currentPlayerId];
//       if (old != null) {
//         scores[s.currentPlayerId] = old.copyWith(
//           punishmentsReceived: old.punishmentsReceived + 1,
//         );
//       }
//     }
//     return s.copyWith(
//       snapshotAt: _now(),
//       phase: TodTurnPhase.awaitingNextTurn,
//       scores: scores,
//     );
//   }

//   // ── Helpers ───────────────────────────────────────────────────────────────
//   TodCard? _draw(TodCardType type) {
//     final pool = _deck
//         .where(
//           (c) =>
//               c.type == type &&
//               (_config.allowSpicy || c.difficulty != TodDifficulty.spicy) &&
//               !_state.usedCardIds.contains(c.id),
//         )
//         .toList();

//     if (pool.isEmpty) {
//       // Reset used IDs for this card type on exhaustion
//       final all = _deck
//           .where(
//             (c) =>
//                 c.type == type &&
//                 (_config.allowSpicy || c.difficulty != TodDifficulty.spicy),
//           )
//           .toList();
//       if (all.isEmpty) return null;
//       all.shuffle(_rng);
//       return all.first;
//     }
//     pool.shuffle(_rng);
//     final drawn = pool.first;
//     _state = _state.copyWith(usedCardIds: [..._state.usedCardIds, drawn.id]);
//     return drawn;
//   }

//   int _nextIndex() {
//     if (_state.turnOrderMode == TurnOrderMode.random) {
//       final q = _state.randomTurnQueue;
//       if (q.isEmpty) return 0;
//       final id = q.first;
//       _state = _state.copyWith(randomTurnQueue: q.skip(1).toList());
//       final idx = _state.playerOrder.indexOf(id);
//       return idx < 0 ? 0 : idx;
//     }
//     return (_state.currentPlayerIndex + 1) % _state.playerOrder.length;
//   }

//   List<String> _buildQueue(List<String> p) => (List.of(p)..shuffle(_rng));
//   int _pts(TodCard c) => switch (c.difficulty) {
//     TodDifficulty.mild => 1,
//     TodDifficulty.medium => 2,
//     TodDifficulty.spicy => 3,
//   };
//   int _now() => DateTime.now().millisecondsSinceEpoch;
// }

import 'dart:math';
import 'package:uuid/uuid.dart';

import '../engine/base_game_engine.dart';
import 'domain/tod_models.dart';

const _uuid = Uuid();

/// Truth or Dare pure-Dart game engine.
/// Owner-authoritative: only the room owner runs this.
/// Followers call restoreFromSnapshot() on every broadcast.
class TruthOrDareEngine implements BaseGameEngine {
  TruthOrDareEngine(this._config, {required List<TodCard> cards})
    : _deck = List.of(cards);

  final GameConfig _config;
  final List<TodCard> _deck;
  late TodState _state;
  final _rng = Random.secure();

  void init({required List<String> playerOrder, int startingIndex = 0}) {
    _deck.shuffle(_rng);
    final scores = {
      for (final id in playerOrder) id: TodPlayerScore(userId: id),
    };
    final queue = _config.turnOrderMode == TurnOrderMode.random
        ? (_buildQueue(playerOrder))
        : <String>[];

    _state = TodState(
      snapshotAt: _now(),
      playerOrder: playerOrder,
      currentPlayerIndex: startingIndex,
      phase: TodTurnPhase.choosingType,
      roundNumber: 1,
      maxRounds: _config.maxRounds,
      scores: scores,
      turnOrderMode: _config.turnOrderMode,
      randomTurnQueue: queue,
      turnStartedAt: _now(),
    );
  }

  @override
  TodState get currentState => _state;
  @override
  bool get isGameOver => _state.isOver;

  @override
  TodState handleEvent(GameEngineEvent event) {
    _state = switch (event) {
      TodChoiceEvent e => _onChoice(e),
      TodCompleteEvent e => _onComplete(e),
      TodProofViewedEvent e => _onProofViewed(e),
      TodStartProofVoteEvent e => _onStartProofVote(e),
      TodCastProofVoteEvent e => _onCastProofVote(e),
      TodReactEvent e => _onReact(e),
      TodVoteResponseEvent e => _onVoteResponse(e),
      TodSkipEvent e => _onSkip(e),
      TodTimerExpiredEvent e => _onTimerExpired(e),
      TodProposePunishmentEvent e => _onProposePunishment(e),
      TodVotePunishmentEvent e => _onVotePunishment(e),
      TodModeratorOverrideEvent e => _onModeratorOverride(e),
      TodEndGameEvent e => _onEndGame(e),
      _ => _state,
    };
    return _state;
  }

  /// [forcePlayerId], when given, advances directly to that player instead
  /// of the natural next index — used by TodGameProvider's TurnQueue-based
  /// selection (see turn_queue.dart) so a just-unmuted player rejoins at
  /// the END of the active rotation rather than their original fixed
  /// playerOrder slot, and so a newly-muted current player is skipped
  /// immediately regardless of turn phase. Only honored in circular mode
  /// and only if the id is actually part of playerOrder — falls back to
  /// the normal [_nextIndex] computation otherwise (random-mode turn
  /// order, which reshuffles every lap, is unaffected and out of scope
  /// for this — its own skip/away handling is unchanged).
  @override
  TodState advanceTurn({String? forcePlayerId}) {
    if (_state.isOver) return _state;
    final forcedIdx = (forcePlayerId != null &&
            _state.turnOrderMode == TurnOrderMode.circular)
        ? _state.playerOrder.indexOf(forcePlayerId)
        : -1;
    final nextIdx = forcedIdx >= 0 ? forcedIdx : _nextIndex();
    final wrapped =
        _state.turnOrderMode == TurnOrderMode.circular &&
        (forcedIdx >= 0
            ? nextIdx <= _state.currentPlayerIndex
            : nextIdx == 0);
    final newRound = wrapped ? _state.roundNumber + 1 : _state.roundNumber;
    final over = newRound > _state.maxRounds;
    final newQueue =
        _state.turnOrderMode == TurnOrderMode.random &&
            _state.randomTurnQueue.isEmpty &&
            !over
        ? _buildQueue(_state.playerOrder)
        : _state.randomTurnQueue;

    // Update last history record with reactions/votes/proof-watched status
    // collected during awaitingNextTurn — the media itself is never copied,
    // only who watched it.
    final updatedHistory = _state.history.isNotEmpty
        ? [
            ..._state.history.sublist(0, _state.history.length - 1),
            _state.history.last.copyWith(
              reactions: _state.currentReactions,
              votes: _state.currentVotes,
              proofWatchedBy: _state.turnProofViewedBy.keys.toList(),
            ),
          ]
        : _state.history;

    _state = _state.copyWith(
      snapshotAt: _now(),
      currentPlayerIndex: nextIdx,
      phase: TodTurnPhase.choosingType,
      roundNumber: newRound,
      currentCard: () => null,
      currentPunishmentVote: () => null,
      timerStartedAt: () => null,
      turnStartedAt: () => _now(),
      isOver: over,
      endReason: over ? 'round_limit' : null,
      randomTurnQueue: newQueue,
      turnResponse: '',
      turnProofImageB64: '',
      turnProofVoiceB64: '',
      turnProofSource: TodProofSource.camera,
      turnProofViewMode: TodProofViewMode.once,
      turnProofViewSeconds: 5,
      turnProofViewedBy: const {},
      turnProofVisibility: const TodProofVisibilitySettings(),
      proofVoteState: () => null,
      currentReactions: [],
      currentVotes: [],
      history: updatedHistory,
    );
    return _state;
  }

  @override
  Map<String, dynamic> serializeState() => _state.toMap();

  @override
  void restoreFromSnapshot(Map<String, dynamic> s) {
    _state = TodState.fromMap(s);
  }

  /// Inject a card into the remaining deck so it can appear during the
  /// current game. Used for premium session-local custom cards — the card
  /// is inserted at a random position to avoid always appearing last.
  void injectCard(TodCard card) {
    final pos = _deck.isNotEmpty ? _rng.nextInt(_deck.length) : 0;
    _deck.insert(pos, card);
  }

  // ── Handlers ─────────────────────────────────────────────────────────────
  TodState _onChoice(TodChoiceEvent e) {
    if (e.userId != _state.currentPlayerId) return _state;
    if (_state.phase != TodTurnPhase.choosingType) return _state;

    // Force Dare rules (GameConfig.forceDareMode) — enforced here, not just
    // hidden client-side, since this owner-run engine IS the authoritative
    // side of this broadcast-relay architecture (same as every other game
    // rule — turn order, timers, scoring — none of which have a separate
    // backend re-validation path either). A follower whose UI failed to
    // hide the Truth option (stale client, tampered build) simply gets
    // silently converted to a dare here instead of honored as a truth.
    var type = e.cardType;
    if (type == TodCardType.truth) {
      final overLimit = switch (_config.forceDareMode) {
        'per_player' => (_state.truthCountByPlayer[e.userId] ?? 0) >=
            _config.maxTruths,
        'per_turn' => _state.globalTruthStreak >= _config.maxTruths,
        _ => false,
      };
      if (overLimit) type = TodCardType.dare;
    }

    final card = _draw(type);
    if (card == null) {
      // Unique-card-repetition mode: this type's pool is exhausted and
      // _draw deliberately did not reset/reshuffle it (see _draw) — per
      // spec, the game ends normally rather than silently falling back to
      // repeats.
      return _state.copyWith(snapshotAt: _now(), isOver: true, endReason: 'cards_exhausted');
    }

    var truthCounts = _state.truthCountByPlayer;
    var globalStreak = _state.globalTruthStreak;
    if (type == TodCardType.truth) {
      truthCounts = {
        ...truthCounts,
        e.userId: (truthCounts[e.userId] ?? 0) + 1,
      };
      globalStreak += 1;
    } else if (_config.forceDareMode == 'per_turn') {
      // Any dare — forced or freely chosen — breaks the shared streak, so
      // every player may choose truth again.
      globalStreak = 0;
    } else if (_config.forceDareMode == 'per_player' &&
        (truthCounts[e.userId] ?? 0) != 0) {
      // Completing a dare resets THIS player's own counter — the cycle
      // (N truths, then a dare) repeats for them specifically, rather
      // than permanently locking them into dares for the rest of the
      // game once maxed once.
      truthCounts = {...truthCounts, e.userId: 0};
    }

    return _state.copyWith(
      snapshotAt: _now(),
      phase: TodTurnPhase.readingCard,
      currentCard: () => card,
      timerStartedAt: () => _config.timerEnabled ? _now() : null,
      truthCountByPlayer: truthCounts,
      globalTruthStreak: globalStreak,
    );
  }

  TodState _onComplete(TodCompleteEvent e) {
    if (e.userId != _state.currentPlayerId) return _state;
    if (_state.phase != TodTurnPhase.readingCard) return _state;
    final card = _state.currentCard;

    // Response/proof validation — authoritative here (not just a disabled
    // Done button client-side), since this owner-run engine is the only
    // real gate a modified client's direct 'tod_complete' broadcast has to
    // pass (same reasoning as the Force Dare / allowSkip checks above). A
    // no-op return leaves the turn in readingCard, so the real player just
    // sees nothing happen rather than the round silently completing empty.
    final trimmedResponse = e.response.trim();
    final hasAnyProof = e.proofImageB64.isNotEmpty || e.proofVoiceB64.isNotEmpty;
    if (card?.type == TodCardType.truth) {
      // Truths have no meaningful non-text way to answer — text has
      // always been required here (mirrors the pre-existing client gate).
      if (trimmedResponse.isEmpty) return _state;
    } else {
      // Dares (including punishments) may be demonstrated by proof alone
      // (e.g. a photo with no caption) — previously neither was required
      // at all, which is the gap being closed here. Some meaningful
      // content, text or proof, must exist either way.
      if (trimmedResponse.isEmpty && !hasAnyProof) return _state;
    }
    // If the group specifically voted a proof type mandatory for this
    // turn, that exact proof must be present regardless of the above —
    // wires up TodProofVoteState.winner, which previously decided nothing.
    final requiredProof = _state.proofVoteState?.winner;
    if (requiredProof == TodProofVoteOption.voiceProof &&
        e.proofVoiceB64.isEmpty) {
      return _state;
    }
    if (requiredProof == TodProofVoteOption.imageProof &&
        e.proofImageB64.isEmpty) {
      return _state;
    }
    final old = _state.scores[e.userId] ?? TodPlayerScore(userId: e.userId);
    final pts = card != null ? _pts(card) : 0;
    final isPunishment = card?.id.startsWith(_punishmentIdPrefix) ?? false;
    var upd = card?.type == TodCardType.truth
        ? old.copyWith(
            completedTruths: old.completedTruths + 1,
            points: old.points + pts,
          )
        : old.copyWith(
            completedDares: old.completedDares + 1,
            points: old.points + pts,
          );
    if (isPunishment) {
      upd = upd.copyWith(punishmentsReceived: upd.punishmentsReceived + 1);
    }
    final record = TodRoundRecord(
      roundNumber: _state.roundNumber,
      playerId: e.userId,
      card: card,
      response: e.response,
      hadProof: e.proofImageB64.isNotEmpty || e.proofVoiceB64.isNotEmpty,
      turnStartedAt: _state.turnStartedAt,
    );
    return _state.copyWith(
      snapshotAt: _now(),
      phase: TodTurnPhase.awaitingNextTurn,
      scores: {..._state.scores, e.userId: upd},
      timerStartedAt: () => null,
      turnResponse: e.response,
      turnProofImageB64: e.proofImageB64,
      turnProofVoiceB64: e.proofVoiceB64,
      turnProofSource: e.proofSource,
      turnProofViewMode: e.proofViewMode,
      turnProofViewSeconds: e.proofViewSeconds,
      turnProofViewedBy: const {},
      turnProofVisibility: e.proofVisibility,
      proofVoteState: () => null,
      currentReactions: [],
      currentVotes: [],
      history: [..._state.history, record],
    );
  }

  /// Someone opened the current turn's proof — increment their personal
  /// view count. The UI grants exactly one open per user; this count exists
  /// so "already viewed" can be derived from shared state instead of local
  /// widget state (which would reset on rebuild/reconnect).
  TodState _onProofViewed(TodProofViewedEvent e) {
    final current = _state.turnProofViewedBy[e.userId] ?? 0;
    return _state.copyWith(
      snapshotAt: _now(),
      turnProofViewedBy: {..._state.turnProofViewedBy, e.userId: current + 1},
    );
  }

  TodState _onStartProofVote(TodStartProofVoteEvent e) {
    // Only the owner can start, only once per turn, only in readingCard phase
    if (_state.phase != TodTurnPhase.readingCard) return _state;
    if (_state.proofVoteState != null) return _state;
    return _state.copyWith(
      snapshotAt: _now(),
      proofVoteState: () =>
          TodProofVoteState(startedAt: DateTime.now().millisecondsSinceEpoch),
    );
  }

  TodState _onCastProofVote(TodCastProofVoteEvent e) {
    // Spectators are never part of playerOrder — this authoritative check
    // (not just a UI-layer gate) is what actually prevents their vote from
    // being counted, regardless of what a client sends.
    if (!_state.playerOrder.contains(e.userId)) return _state;
    final vote = _state.proofVoteState;
    if (vote == null || vote.isExpired) return _state;
    // Current player cannot vote on their own proof requirement
    if (e.userId == _state.currentPlayerId) return _state;
    return _state.copyWith(
      snapshotAt: _now(),
      proofVoteState: () => vote.copyWithVote(e.userId, e.option),
    );
  }

  TodState _onReact(TodReactEvent e) {
    if (!_state.playerOrder.contains(e.userId)) return _state;
    // One reaction per player per turn
    if (_state.currentReactions.any((r) => r.userId == e.userId)) return _state;
    return _state.copyWith(
      snapshotAt: _now(),
      currentReactions: [
        ..._state.currentReactions,
        TodReaction(userId: e.userId, emoji: e.emoji, ts: e.ts),
      ],
    );
  }

  TodState _onVoteResponse(TodVoteResponseEvent e) {
    if (!_state.playerOrder.contains(e.userId)) return _state;
    // One vote per player per turn
    if (_state.currentVotes.any((v) => v.voterId == e.userId)) return _state;
    return _state.copyWith(
      snapshotAt: _now(),
      currentVotes: [
        ..._state.currentVotes,
        TodResponseVote(voterId: e.userId, ts: e.ts),
      ],
    );
  }

  TodState _onSkip(TodSkipEvent e, {bool isTimeout = false}) {
    if (e.userId != _state.currentPlayerId) return _state;
    if (_state.phase != TodTurnPhase.readingCard) return _state;
    // A voluntary skip requires GameConfig.allowSkip — enforced here, not
    // just by hiding the Skip button client-side, so a stale/tampered
    // client can't send one anyway (same authoritative-engine reasoning
    // as the Force Dare check in _onChoice). Timer-expiry auto-skip is a
    // separate game-flow mechanism (the player simply ran out of time),
    // not the player circumventing the rule, so it always proceeds
    // regardless of this setting — otherwise a disabled-skip room would
    // leave an unresponsive player's turn stuck forever.
    if (!isTimeout && !_config.allowSkip) return _state;
    final old = _state.scores[e.userId] ?? TodPlayerScore(userId: e.userId);
    final upd = old.copyWith(skips: old.skips + 1);
    final nextPhase = _config.enablePunishments
        ? TodTurnPhase.punishmentVoting
        : TodTurnPhase.awaitingNextTurn;
    var next = _state.copyWith(
      snapshotAt: _now(),
      phase: nextPhase,
      scores: {..._state.scores, e.userId: upd},
      timerStartedAt: () => null,
    );

    // Pack-sourced punishments (room owner opted into GameConfig.
    // punishmentSource == 'pack' and the selected pack actually has some)
    // skip the peer-proposal phase entirely by pre-populating the vote
    // state with the pack's own options and expectedSubmissions: 0 —
    // TodPunishmentVoteState.submissionsComplete is `options.length >=
    // expectedSubmissions`, vacuously true at 0, so the skipped player can
    // pick immediately via the existing, completely unchanged
    // _onVotePunishment/_resolvePunishment path. When punishmentSource is
    // 'players' (the default), currentPunishmentVote is never
    // pre-populated here, so behavior is byte-for-byte identical to
    // before this feature existed.
    if (_config.enablePunishments &&
        _config.punishmentSource == 'pack' &&
        _config.suggestedPunishments.isNotEmpty) {
      // Reuse prevention: a pack punishment already picked earlier this
      // game (tracked by list index — pack punishments have no DB id) is
      // excluded from the offered options, so the same one can't be
      // handed out twice while others remain unused. Once every option
      // has been used at least once, the used-set resets so a small pack
      // cycles instead of leaving zero eligible options for the rest of
      // the game.
      final total = _config.suggestedPunishments.length;
      final priorUsed = _state.usedPunishmentIndices.toSet();
      final activeUsed = priorUsed.length >= total
          ? const <int>{}
          : priorUsed;
      final options = [
        for (var i = 0; i < total; i++)
          if (!activeUsed.contains(i))
            TodPunishment(
              id: 'pack_${i}_${e.ts}',
              text: _config.suggestedPunishments[i],
              proposedBy: 'pack',
              proposedAt: e.ts,
              sourceIndex: i,
            ),
      ];
      next = next.copyWith(
        currentPunishmentVote: () =>
            TodPunishmentVoteState(options: options, expectedSubmissions: 0),
        usedPunishmentIndices: activeUsed.length == priorUsed.length
            ? null
            : const [],
      );
    }

    return next;
  }

  TodState _onTimerExpired(TodTimerExpiredEvent e) =>
      _onSkip(TodSkipEvent(userId: e.userId, ts: e.ts), isTimeout: true);

  /// One non-skipped player submits exactly one punishment option — called
  /// once per eligible player per skip, not once by a moderator proposing
  /// several at a time.
  TodState _onProposePunishment(TodProposePunishmentEvent e) {
    if (!_state.playerOrder.contains(e.userId)) return _state;
    if (_state.phase != TodTurnPhase.punishmentVoting) return _state;
    if (e.userId == _state.currentPlayerId) return _state; // skipped player doesn't submit
    // Pack-sourced punishments (see _onSkip) pre-populate the vote with
    // the pack's own options and expectedSubmissions: 0 — the two
    // punishment systems must never run simultaneously, so a stray/stale
    // player-proposal event arriving while punishmentSource == 'pack'
    // must not be allowed to mix a player-submitted option into what's
    // supposed to be a pack-only list.
    if (_config.punishmentSource != 'players') return _state;
    final text = e.text.trim();
    if (text.isEmpty) return _state;

    final prev = _state.currentPunishmentVote;
    final expected = _state.playerOrder.length - 1;
    // One submission per player — ignore a duplicate resubmission.
    if (prev != null && prev.options.any((o) => o.proposedBy == e.userId)) {
      return _state;
    }
    final option = TodPunishment(
      id: '${e.userId}_${e.ts}',
      text: text,
      proposedBy: e.userId,
      proposedAt: e.ts,
    );
    final voteState = TodPunishmentVoteState(
      options: [...?prev?.options, option],
      expectedSubmissions: expected,
    );
    return _state.copyWith(
      snapshotAt: _now(),
      currentPunishmentVote: () => voteState,
    );
  }

  /// The skipped player (only) picks whichever submitted punishment they'll
  /// do, once every expected submission is in — resolves immediately, no
  /// group vote or tally.
  TodState _onVotePunishment(TodVotePunishmentEvent e) {
    if (_state.phase != TodTurnPhase.punishmentVoting) return _state;
    if (e.userId != _state.currentPlayerId) return _state;
    final prev = _state.currentPunishmentVote;
    if (prev == null || !prev.submissionsComplete) return _state;
    final chosen = prev.options.where((o) => o.id == e.optionId).firstOrNull;
    if (chosen == null) return _state;
    return _resolvePunishment(_state, chosen);
  }

  /// Moderator force-resolves on the skipped player's behalf (e.g. they
  /// went unresponsive/away) instead of waiting for their pick.
  TodState _onModeratorOverride(TodModeratorOverrideEvent e) {
    if (_state.phase != TodTurnPhase.punishmentVoting) return _state;
    final prev = _state.currentPunishmentVote;
    if (prev == null) return _state;
    final chosen = prev.options
        .where((o) => o.id == e.optionId)
        .firstOrNull;
    if (chosen == null) return _state;
    return _resolvePunishment(_state, chosen);
  }

  TodState _onEndGame(TodEndGameEvent e) {
    if (_state.isOver) return _state;
    return _state.copyWith(snapshotAt: _now(), isOver: true, endReason: e.reason);
  }

  /// Punishment can never be skipped or bypassed — once the vote resolves,
  /// the winning option becomes the current turn's card and execution goes
  /// through the exact same flow as a normal Dare (synced countdown timer,
  /// proof capture/viewing, `completeTurn()`/history), rather than a
  /// separate, weaker code path. `_onComplete` bumps `punishmentsReceived`
  /// for any card whose id carries the `_punishmentIdPrefix`.
  static const _punishmentIdPrefix = 'punishment_';

  TodState _resolvePunishment(TodState s, TodPunishment? option) {
    if (option == null) return s;
    final card = TodCard(
      id: '$_punishmentIdPrefix${option.id}',
      content: option.text,
      type: TodCardType.dare,
      difficulty: TodDifficulty.mild,
    );
    // Record the pack index as used (peer-proposed options have no
    // sourceIndex and are left untouched — see the reuse-prevention note
    // in _onSkip).
    final usedIndices =
        option.sourceIndex != null &&
            !s.usedPunishmentIndices.contains(option.sourceIndex)
        ? [...s.usedPunishmentIndices, option.sourceIndex!]
        : s.usedPunishmentIndices;
    return s.copyWith(
      snapshotAt: _now(),
      phase: TodTurnPhase.readingCard,
      currentCard: () => card,
      timerStartedAt: () => _config.timerEnabled ? _now() : null,
      usedPunishmentIndices: usedIndices,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  TodCard? _draw(TodCardType type) {
    final pool = _deck
        .where(
          (c) =>
              c.type == type &&
              (_config.allowSpicy || c.difficulty != TodDifficulty.spicy) &&
              !_state.usedCardIds.contains(c.id),
        )
        .toList();

    if (pool.isEmpty) {
      // Unique mode: never reset/reshuffle a fully-used pool — every card
      // appears at most once, and running out means the game is over
      // (handled by the caller via _onChoice returning null here).
      if (_config.cardRepetitionMode == 'unique') return null;

      // Shuffle-continuously mode (default, original behavior): reset
      // used IDs for this card type on exhaustion so cards can repeat.
      final all = _deck
          .where(
            (c) =>
                c.type == type &&
                (_config.allowSpicy || c.difficulty != TodDifficulty.spicy),
          )
          .toList();
      if (all.isEmpty) return null;
      all.shuffle(_rng);
      return all.first;
    }
    pool.shuffle(_rng);
    final drawn = pool.first;
    _state = _state.copyWith(usedCardIds: [..._state.usedCardIds, drawn.id]);
    return drawn;
  }

  int _nextIndex() {
    if (_state.turnOrderMode == TurnOrderMode.random) {
      final q = _state.randomTurnQueue;
      if (q.isEmpty) return 0;
      final id = q.first;
      _state = _state.copyWith(randomTurnQueue: q.skip(1).toList());
      final idx = _state.playerOrder.indexOf(id);
      return idx < 0 ? 0 : idx;
    }
    return (_state.currentPlayerIndex + 1) % _state.playerOrder.length;
  }

  List<String> _buildQueue(List<String> p) => (List.of(p)..shuffle(_rng));
  int _pts(TodCard c) => switch (c.difficulty) {
    TodDifficulty.mild => 1,
    TodDifficulty.medium => 2,
    TodDifficulty.spicy => 3,
  };

  // ROOT CAUSE (punishment response/proof invisible to other players):
  // every TodState.copyWith(snapshotAt: _now(), ...) call used plain
  // DateTime.now().millisecondsSinceEpoch, and TodGameProvider.
  // onStateBroadcast discards an incoming broadcast whose snapshot_at is
  // <= what it already has (a deliberate out-of-order/stale-broadcast
  // guard — see that method's own comments). Millisecond resolution is
  // NOT fine enough: a punishment turn is the one ToD flow that fires
  // several state mutations back-to-back with no user think-time between
  // them (each of the N-1 other players' TodProposePunishmentEvent, then
  // the pick/resolve, then — once the punished player types a response —
  // completion), so two consecutive _now() calls landing in the exact
  // same millisecond is common, not a rare edge case (reproduced
  // deterministically in a plain unit test with zero artificial delay —
  // see truth_or_dare_engine_snapshot_ordering_test.dart). Whichever
  // broadcast loses that tie is silently DROPPED by every follower's
  // onStateBroadcast — including, when the collision lands on the
  // completion step, the punished player's own response/proof. The
  // player who performed the punishment never notices, because the
  // owner's client applies its own engine mutations directly and
  // synchronously (onPlayerAction) and never goes through
  // onStateBroadcast's staleness guard for its own actions at all — only
  // followers depend on that guard, so only they can silently lose an
  // update. A normal Truth/Dare turn has only two, human-paced mutations
  // (choice, then completion) and rarely collides, which is why this
  // symptom reads as "punishment-specific" even though the underlying
  // flaw is general.
  //
  // Fix: make snapshotAt strictly monotonic per engine instance instead
  // of a raw wall-clock read, so two calls can never tie regardless of
  // how close together they happen — closes the bug at its source
  // without weakening or duplicating onStateBroadcast's (otherwise
  // correct) ordering guard.
  int _lastSnapshotAt = 0;
  int _now() {
    final wallClock = DateTime.now().millisecondsSinceEpoch;
    final next = wallClock > _lastSnapshotAt ? wallClock : _lastSnapshotAt + 1;
    _lastSnapshotAt = next;
    return next;
  }
}
