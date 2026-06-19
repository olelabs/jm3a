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

    // Update last history record with reactions and votes collected during awaitingNextTurn
    final updatedHistory = _state.history.isNotEmpty
        ? [
            ..._state.history.sublist(0, _state.history.length - 1),
            _state.history.last.copyWith(
              reactions: _state.currentReactions,
              votes: _state.currentVotes,
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
    final upd = card?.type == TodCardType.truth
        ? old.copyWith(
            completedTruths: old.completedTruths + 1,
            points: old.points + pts,
          )
        : old.copyWith(
            completedDares: old.completedDares + 1,
            points: old.points + pts,
          );
    // Save round to history
    final record = TodRoundRecord(
      roundNumber: _state.roundNumber,
      playerId: e.userId,
      card: card,
      response: e.response,
      proofImageB64: e.proofImageB64,
    );
    return _state.copyWith(
      snapshotAt: _now(),
      phase: TodTurnPhase.awaitingNextTurn,
      scores: {..._state.scores, e.userId: upd},
      timerStartedAt: () => null,
      turnResponse: e.response,
      turnProofImageB64: e.proofImageB64,
      currentReactions: [],
      currentVotes: [],
      history: [..._state.history, record],
    );
  }

  TodState _onReact(TodReactEvent e) {
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
    return _state.copyWith(
      snapshotAt: _now(),
      phase: nextPhase,
      scores: {..._state.scores, e.userId: upd},
      timerStartedAt: () => null,
    );
  }

  TodState _onTimerExpired(TodTimerExpiredEvent e) =>
      _onSkip(TodSkipEvent(userId: e.userId, ts: e.ts));

  TodState _onProposePunishment(TodProposePunishmentEvent e) {
    if (_state.phase != TodTurnPhase.punishmentVoting) return _state;
    final voteState = TodPunishmentVoteState(
      punishment: e.punishment,
      votes: {},
      totalVoters: _state.playerOrder.length - 1,
    );
    return _state.copyWith(
      snapshotAt: _now(),
      currentPunishmentVote: () => voteState,
    );
  }

  TodState _onVotePunishment(TodVotePunishmentEvent e) {
    if (_state.phase != TodTurnPhase.punishmentVoting) return _state;
    if (_state.currentPunishmentVote == null) return _state;
    if (e.userId == _state.currentPlayerId) return _state;
    final prev = _state.currentPunishmentVote!;
    final votes = {...prev.votes, e.userId: e.vote};
    final upd = TodPunishmentVoteState(
      punishment: prev.punishment,
      votes: votes,
      totalVoters: prev.totalVoters,
      moderatorOverride: prev.moderatorOverride,
    );
    var s = _state.copyWith(
      snapshotAt: _now(),
      currentPunishmentVote: () => upd,
    );
    if (upd.hasOutcome) s = _applyDecision(s, upd.resolvedVote);
    return s;
  }

  TodState _onModeratorOverride(TodModeratorOverrideEvent e) {
    if (_state.phase != TodTurnPhase.punishmentVoting) return _state;
    final prev = _state.currentPunishmentVote;
    var punishment =
        prev?.punishment ??
        TodPunishment(
          id: _uuid.v4(),
          text: e.replacementText ?? 'Punishment',
          proposedBy: e.userId,
          proposedAt: _now(),
        );
    if (e.replacementText != null) {
      punishment = TodPunishment(
        id: _uuid.v4(),
        text: e.replacementText!,
        proposedBy: e.userId,
        proposedAt: _now(),
      );
    }
    final upd = TodPunishmentVoteState(
      punishment: punishment,
      votes: prev?.votes ?? {},
      totalVoters: prev?.totalVoters ?? _state.playerOrder.length - 1,
      moderatorOverride: e.decision,
    );
    var s = _state.copyWith(
      snapshotAt: _now(),
      currentPunishmentVote: () => upd,
    );
    return _applyDecision(s, e.decision);
  }

  TodState _onEndGame(TodEndGameEvent e) =>
      _state.copyWith(snapshotAt: _now(), isOver: true, endReason: e.reason);

  TodState _applyDecision(TodState s, TodPunishmentVote? d) {
    if (d == null) return s;
    if (d == TodPunishmentVote.changePunishment) {
      final prev = s.currentPunishmentVote!;
      final reset = TodPunishmentVoteState(
        punishment: prev.punishment,
        votes: {},
        totalVoters: prev.totalVoters,
      );
      return s.copyWith(snapshotAt: _now(), currentPunishmentVote: () => reset);
    }
    // doIt or dontDoIt → end punishment phase
    final scores = Map<String, TodPlayerScore>.from(s.scores);
    if (d == TodPunishmentVote.doIt) {
      final old = scores[s.currentPlayerId];
      if (old != null) {
        scores[s.currentPlayerId] = old.copyWith(
          punishmentsReceived: old.punishmentsReceived + 1,
        );
      }
    }
    return s.copyWith(
      snapshotAt: _now(),
      phase: TodTurnPhase.awaitingNextTurn,
      scores: scores,
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
