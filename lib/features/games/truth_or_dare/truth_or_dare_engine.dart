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

  @override
  TodState advanceTurn() {
    if (_state.isOver) return _state;
    final nextIdx = _nextIndex();
    final wrapped =
        _state.turnOrderMode == TurnOrderMode.circular && nextIdx == 0;
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
    final card = _draw(e.cardType);
    return _state.copyWith(
      snapshotAt: _now(),
      phase: TodTurnPhase.readingCard,
      currentCard: () => card,
      timerStartedAt: () => _config.timerEnabled ? _now() : null,
    );
  }

  TodState _onComplete(TodCompleteEvent e) {
    if (e.userId != _state.currentPlayerId) return _state;
    if (_state.phase != TodTurnPhase.readingCard) return _state;
    final card = _state.currentCard;
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

  TodState _onSkip(TodSkipEvent e) {
    if (e.userId != _state.currentPlayerId) return _state;
    if (_state.phase != TodTurnPhase.readingCard) return _state;
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
      final options = [
        for (var i = 0; i < _config.suggestedPunishments.length; i++)
          TodPunishment(
            id: 'pack_${i}_${e.ts}',
            text: _config.suggestedPunishments[i],
            proposedBy: 'pack',
            proposedAt: e.ts,
          ),
      ];
      next = next.copyWith(
        currentPunishmentVote: () =>
            TodPunishmentVoteState(options: options, expectedSubmissions: 0),
      );
    }

    return next;
  }

  TodState _onTimerExpired(TodTimerExpiredEvent e) =>
      _onSkip(TodSkipEvent(userId: e.userId, ts: e.ts));

  /// One non-skipped player submits exactly one punishment option — called
  /// once per eligible player per skip, not once by a moderator proposing
  /// several at a time.
  TodState _onProposePunishment(TodProposePunishmentEvent e) {
    if (!_state.playerOrder.contains(e.userId)) return _state;
    if (_state.phase != TodTurnPhase.punishmentVoting) return _state;
    if (e.userId == _state.currentPlayerId) return _state; // skipped player doesn't submit
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
    return s.copyWith(
      snapshotAt: _now(),
      phase: TodTurnPhase.readingCard,
      currentCard: () => card,
      timerStartedAt: () => _config.timerEnabled ? _now() : null,
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
      // Reset used IDs for this card type on exhaustion
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
  int _now() => DateTime.now().millisecondsSinceEpoch;
}
