// import '../engine/base_game_engine.dart';
// import '../engine/game_registry.dart';

// // ── Domain ────────────────────────────────────────────────────────────────────

// class NhieCard {
//   const NhieCard({required this.id, required this.content, required this.difficulty});
//   final String id;
//   final String content;
//   final String difficulty;

//   Map<String, dynamic> toMap() => {'id': id, 'content': content, 'difficulty': difficulty};
//   static NhieCard fromMap(Map<String, dynamic> m) => NhieCard(
//     id: m['id'] as String,
//     content: m['content'] as String,
//     difficulty: m['difficulty'] as String? ?? 'mild',
//   );
// }

// class NhieState extends GameEngineState {
//   const NhieState({
//     required super.snapshotAt,
//     required this.playerOrder,
//     required this.currentPlayerIndex,
//     required this.currentCard,
//     required this.roundNumber,
//     required this.maxRounds,
//     required this.votes,       // userId -> bool (true = "have", false = "never")
//     required this.scores,      // userId -> int (count of "have" answers)
//     required this.isVotingOpen,
//     required this.isOver,
//   });

//   final List<String> playerOrder;
//   final int currentPlayerIndex;
//   final NhieCard? currentCard;
//   final int roundNumber;
//   final int maxRounds;
//   final Map<String, bool> votes;
//   final Map<String, int> scores;
//   final bool isVotingOpen;
//   final bool isOver;

//   String get currentPlayerId =>
//       playerOrder.isEmpty ? '' : playerOrder[currentPlayerIndex % playerOrder.length];

//   NhieState copyWith({
//     int? snapshotAt,
//     int? currentPlayerIndex,
//     NhieCard? Function()? currentCard,
//     int? roundNumber,
//     Map<String, bool>? votes,
//     Map<String, int>? scores,
//     bool? isVotingOpen,
//     bool? isOver,
//   }) =>
//       NhieState(
//         snapshotAt: snapshotAt ?? this.snapshotAt,
//         playerOrder: playerOrder,
//         currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
//         currentCard: currentCard != null ? currentCard() : this.currentCard,
//         roundNumber: roundNumber ?? this.roundNumber,
//         maxRounds: maxRounds,
//         votes: votes ?? this.votes,
//         scores: scores ?? this.scores,
//         isVotingOpen: isVotingOpen ?? this.isVotingOpen,
//         isOver: isOver ?? this.isOver,
//       );

//   Map<String, dynamic> toMap() => {
//     'snapshot_at': snapshotAt,
//     'player_order': playerOrder,
//     'current_player_index': currentPlayerIndex,
//     'current_card': currentCard?.toMap(),
//     'round_number': roundNumber,
//     'max_rounds': maxRounds,
//     'votes': votes,
//     'scores': scores,
//     'is_voting_open': isVotingOpen,
//     'is_over': isOver,
//   };

//   static NhieState fromMap(Map<String, dynamic> m) => NhieState(
//     snapshotAt: m['snapshot_at'] as int? ?? 0,
//     playerOrder: (m['player_order'] as List?)?.cast<String>() ?? [],
//     currentPlayerIndex: m['current_player_index'] as int? ?? 0,
//     currentCard: m['current_card'] != null ? NhieCard.fromMap(m['current_card'] as Map<String, dynamic>) : null,
//     roundNumber: m['round_number'] as int? ?? 1,
//     maxRounds: m['max_rounds'] as int? ?? 10,
//     votes: (m['votes'] as Map?)?.cast<String, bool>() ?? {},
//     scores: (m['scores'] as Map?)?.map((k, v) => MapEntry(k as String, (v as num).toInt())) ?? {},
//     isVotingOpen: m['is_voting_open'] as bool? ?? false,
//     isOver: m['is_over'] as bool? ?? false,
//   );
// }

// // ── Events ────────────────────────────────────────────────────────────────────

// class NhieVoteEvent extends GameEngineEvent {
//   const NhieVoteEvent({required super.userId, required super.ts, required this.haveI});
//   final bool haveI; // true = "I have", false = "never have I ever"
// }

// // ── Engine ────────────────────────────────────────────────────────────────────

// class NeverHaveIEverEngine implements BaseGameEngine {
//   NeverHaveIEverEngine(this._config, {required List<NhieCard> cards})
//       : _cards = cards;

//   final GameConfig _config;
//   final List<NhieCard> _cards;
//   late NhieState _state;

//   void init(List<String> playerOrder) {
//     _cards.shuffle();
//     final scores = {for (final id in playerOrder) id: 0};
//     _state = NhieState(
//       snapshotAt: DateTime.now().millisecondsSinceEpoch,
//       playerOrder: playerOrder,
//       currentPlayerIndex: 0,
//       currentCard: _drawCard(),
//       roundNumber: 1,
//       maxRounds: _config.maxRounds,
//       votes: {},
//       scores: scores,
//       isVotingOpen: true,
//       isOver: false,
//     );
//   }

//   @override
//   NhieState get currentState => _state;

//   @override
//   NhieState handleEvent(GameEngineEvent event) {
//     if (event is NhieVoteEvent) {
//       _state = _handleVote(event);
//     }
//     return _state;
//   }

//   @override
//   NhieState advanceTurn() {
//     final nextIndex =
//         (_state.currentPlayerIndex + 1) % _state.playerOrder.length;
//     final newRound =
//         nextIndex == 0 ? _state.roundNumber + 1 : _state.roundNumber;
//     final isOver = newRound > _state.maxRounds;

//     _state = _state.copyWith(
//       snapshotAt: DateTime.now().millisecondsSinceEpoch,
//       currentPlayerIndex: nextIndex,
//       currentCard: _drawCard,
//       roundNumber: newRound,
//       votes: {},
//       isVotingOpen: !isOver,
//       isOver: isOver,
//     );
//     return _state;
//   }

//   @override
//   Map<String, dynamic> serializeState() => _state.toMap();

//   @override
//   void restoreFromSnapshot(Map<String, dynamic> snapshot) {
//     _state = NhieState.fromMap(snapshot);
//   }

//   @override
//   bool get isGameOver => _state.isOver;

//   // ── Handlers ──────────────────────────────────────────────────────────────
//   NhieState _handleVote(NhieVoteEvent event) {
//     if (!_state.isVotingOpen) return _state;
//     if (_state.votes.containsKey(event.userId)) return _state; // already voted

//     final newVotes = {..._state.votes, event.userId: event.haveI};
//     final newScores = Map<String, int>.from(_state.scores);
//     if (event.haveI) {
//       newScores[event.userId] = (newScores[event.userId] ?? 0) + 1;
//     }

//     // Close voting once all players have voted
//     final allVoted = _state.playerOrder
//         .every((id) => newVotes.containsKey(id));

//     return _state.copyWith(
//       snapshotAt: DateTime.now().millisecondsSinceEpoch,
//       votes: newVotes,
//       scores: newScores,
//       isVotingOpen: !allVoted,
//     );
//   }

//   NhieCard? _drawCard() {
//     final available = _cards
//         .where((c) => !_config.allowSpicy
//             ? c.difficulty != 'spicy'
//             : true)
//         .toList();
//     if (available.isEmpty) return null;
//     available.shuffle();
//     return available.first;
//   }
// }

import 'dart:math';

import '../engine/base_game_engine.dart';

// ── Domain ────────────────────────────────────────────────────────────────────

class NhieCard {
  const NhieCard({
    required this.id,
    required this.content,
    required this.difficulty,
  });
  final String id;
  final String content;
  final String difficulty;

  Map<String, dynamic> toMap() => {
    'id': id,
    'content': content,
    'difficulty': difficulty,
  };
  static NhieCard fromMap(Map<String, dynamic> m) => NhieCard(
    id: m['id'] as String,
    content: m['content'] as String,
    difficulty: m['difficulty'] as String? ?? 'mild',
  );
}

/// A player's vote + optional message explanation
class NhieVoteEntry {
  const NhieVoteEntry({
    required this.userId,
    required this.haveI,
    this.message = '',
  });
  final String userId;
  final bool haveI; // true = I have, false = never
  final String message; // optional explanation

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'have_i': haveI,
    'message': message,
  };
  static NhieVoteEntry fromMap(Map<String, dynamic> m) => NhieVoteEntry(
    userId: m['user_id'] as String,
    haveI: m['have_i'] as bool? ?? false,
    message: m['message'] as String? ?? '',
  );
}

/// A sticker reaction (once per turn per player)
class NhieReaction {
  const NhieReaction({
    required this.userId,
    required this.sticker,
    required this.ts,
  });
  final String userId;
  final String sticker;
  final int ts;

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'sticker': sticker,
    'ts': ts,
  };
  static NhieReaction fromMap(Map<String, dynamic> m) => NhieReaction(
    userId: m['user_id'] as String,
    sticker: m['sticker'] as String,
    ts: m['ts'] as int? ?? 0,
  );
}

/// Snapshot of a completed round (for history)
class NhieRoundRecord {
  const NhieRoundRecord({
    required this.roundNumber,
    required this.card,
    required this.votes,
    required this.reactions,
  });
  final int roundNumber;
  final NhieCard card;
  final Map<String, NhieVoteEntry> votes; // userId -> entry
  final List<NhieReaction> reactions;

  Map<String, dynamic> toMap() => {
    'round_number': roundNumber,
    'card': card.toMap(),
    'votes': votes.map((k, v) => MapEntry(k, v.toMap())),
    'reactions': reactions.map((r) => r.toMap()).toList(),
  };
  static NhieRoundRecord fromMap(Map<String, dynamic> m) => NhieRoundRecord(
    roundNumber: m['round_number'] as int? ?? 0,
    card: NhieCard.fromMap(m['card'] as Map<String, dynamic>),
    votes:
        (m['votes'] as Map?)?.map(
          (k, v) => MapEntry(
            k as String,
            NhieVoteEntry.fromMap(v as Map<String, dynamic>),
          ),
        ) ??
        {},
    reactions:
        (m['reactions'] as List?)
            ?.map((r) => NhieReaction.fromMap(r as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

class NhieState extends GameEngineState {
  const NhieState({
    required super.snapshotAt,
    required this.playerOrder,
    required this.currentPlayerIndex,
    required this.currentCard,
    required this.roundNumber,
    required this.maxRounds,
    required this.voteEntries,
    required this.scores,
    required this.isVotingOpen,
    required this.isOver,
    this.reactions = const [],
    this.history = const [],
  });

  final List<String> playerOrder;
  final int currentPlayerIndex;
  final NhieCard? currentCard;
  final int roundNumber;
  final int maxRounds;
  final Map<String, NhieVoteEntry> voteEntries; // userId -> entry
  final Map<String, int> scores;
  final bool isVotingOpen;
  final bool isOver;
  final List<NhieReaction> reactions; // current turn reactions
  final List<NhieRoundRecord> history; // completed rounds

  String get currentPlayerId => playerOrder.isEmpty
      ? ''
      : playerOrder[currentPlayerIndex % playerOrder.length];

  // Backward-compat: plain bool map for UI
  Map<String, bool> get votes =>
      voteEntries.map((k, v) => MapEntry(k, v.haveI));

  NhieState copyWith({
    int? snapshotAt,
    int? currentPlayerIndex,
    NhieCard? Function()? currentCard,
    int? roundNumber,
    int? maxRounds,
    Map<String, NhieVoteEntry>? voteEntries,
    Map<String, int>? scores,
    bool? isVotingOpen,
    bool? isOver,
    List<NhieReaction>? reactions,
    List<NhieRoundRecord>? history,
  }) => NhieState(
    snapshotAt: snapshotAt ?? this.snapshotAt,
    playerOrder: playerOrder,
    currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
    currentCard: currentCard != null ? currentCard() : this.currentCard,
    roundNumber: roundNumber ?? this.roundNumber,
    maxRounds: maxRounds ?? this.maxRounds,
    voteEntries: voteEntries ?? this.voteEntries,
    scores: scores ?? this.scores,
    isVotingOpen: isVotingOpen ?? this.isVotingOpen,
    isOver: isOver ?? this.isOver,
    reactions: reactions ?? this.reactions,
    history: history ?? this.history,
  );

  Map<String, dynamic> toMap() => {
    'snapshot_at': snapshotAt,
    'player_order': playerOrder,
    'current_player_index': currentPlayerIndex,
    'current_card': currentCard?.toMap(),
    'round_number': roundNumber,
    'max_rounds': maxRounds,
    'vote_entries': voteEntries.map((k, v) => MapEntry(k, v.toMap())),
    'scores': scores,
    'is_voting_open': isVotingOpen,
    'is_over': isOver,
    'reactions': reactions.map((r) => r.toMap()).toList(),
    'history': history.map((r) => r.toMap()).toList(),
  };

  static NhieState fromMap(Map<String, dynamic> m) => NhieState(
    snapshotAt: m['snapshot_at'] as int? ?? 0,
    playerOrder: (m['player_order'] as List?)?.cast<String>() ?? [],
    currentPlayerIndex: m['current_player_index'] as int? ?? 0,
    currentCard: m['current_card'] != null
        ? NhieCard.fromMap(m['current_card'] as Map<String, dynamic>)
        : null,
    roundNumber: m['round_number'] as int? ?? 1,
    maxRounds: m['max_rounds'] as int? ?? 10,
    voteEntries:
        (m['vote_entries'] as Map?)?.map(
          (k, v) => MapEntry(
            k as String,
            NhieVoteEntry.fromMap(v as Map<String, dynamic>),
          ),
        ) ??
        {},
    scores:
        (m['scores'] as Map?)?.map(
          (k, v) => MapEntry(k as String, (v as num).toInt()),
        ) ??
        {},
    isVotingOpen: m['is_voting_open'] as bool? ?? false,
    isOver: m['is_over'] as bool? ?? false,
    reactions:
        (m['reactions'] as List?)
            ?.map((r) => NhieReaction.fromMap(r as Map<String, dynamic>))
            .toList() ??
        [],
    history:
        (m['history'] as List?)
            ?.map((r) => NhieRoundRecord.fromMap(r as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

// ── Events ────────────────────────────────────────────────────────────────────

class NhieVoteEvent extends GameEngineEvent {
  const NhieVoteEvent({
    required super.userId,
    required super.ts,
    required this.haveI,
    this.message = '',
  });
  final bool haveI;
  final String message;
}

class NhieReactionEvent extends GameEngineEvent {
  const NhieReactionEvent({
    required super.userId,
    required super.ts,
    required this.sticker,
  });
  final String sticker;
}

// ── Engine ────────────────────────────────────────────────────────────────────

class NeverHaveIEverEngine implements BaseGameEngine {
  NeverHaveIEverEngine(this._config, {required List<NhieCard> cards})
    : _cards = List.from(cards)..shuffle();

  final GameConfig _config;
  final List<NhieCard> _cards;
  final Set<String> _usedCardIds = {};
  final _rng = Random();
  late NhieState _state;

  @override
  NhieState get currentState => _state;

  void init(List<String> playerOrder) {
    _usedCardIds.clear();
    _state = NhieState(
      snapshotAt: DateTime.now().millisecondsSinceEpoch,
      playerOrder: playerOrder,
      currentPlayerIndex: 0,
      currentCard: _nextCard(),
      roundNumber: 1,
      maxRounds: _config.maxRounds,
      voteEntries: {},
      scores: {for (final id in playerOrder) id: 0},
      isVotingOpen: true,
      isOver: false,
      reactions: [],
      history: [],
    );
  }

  NhieCard? _nextCard() {
    final available = _cards
        .where(
          (c) =>
              !_usedCardIds.contains(c.id) &&
              (_config.allowSpicy || c.difficulty != 'spicy'),
        )
        .toList();
    if (available.isEmpty) return null;
    final card = available.first;
    _usedCardIds.add(card.id);
    return card;
  }

  @override
  NhieState handleEvent(GameEngineEvent event) {
    _state = switch (event) {
      NhieVoteEvent e => _handleVote(e),
      NhieReactionEvent e => _handleReaction(e),
      _ => _state,
    };
    return _state;
  }

  @override
  NhieState advanceTurn() {
    // Save current round to history
    final record = _state.currentCard != null
        ? NhieRoundRecord(
            roundNumber: _state.roundNumber,
            card: _state.currentCard!,
            votes: _state.voteEntries,
            reactions: _state.reactions,
          )
        : null;
    final newHistory = [..._state.history, if (record != null) record];

    final nextIndex =
        (_state.currentPlayerIndex + 1) % _state.playerOrder.length;
    final newRound = nextIndex == 0
        ? _state.roundNumber + 1
        : _state.roundNumber;
    final isOver = newRound > _state.maxRounds;

    _state = _state.copyWith(
      snapshotAt: DateTime.now().millisecondsSinceEpoch,
      currentPlayerIndex: nextIndex,
      currentCard: _nextCard,
      roundNumber: newRound,
      voteEntries: {},
      isVotingOpen: !isOver,
      isOver: isOver,
      reactions: [],
      history: newHistory,
    );
    return _state;
  }

  @override
  Map<String, dynamic> serializeState() => _state.toMap();

  @override
  void restoreFromSnapshot(Map<String, dynamic> snapshot) {
    _state = NhieState.fromMap(snapshot);
  }

  /// Inject a card into the remaining deck so it can appear during the
  /// current game. Used for premium session-local custom cards — the card
  /// is inserted at a random position to avoid always appearing last.
  /// Also bumps maxRounds if needed so the enlarged deck can't be cut off
  /// by the round limit before every card (built-in + custom) is drawn.
  void injectCard(NhieCard card) {
    final pos = _cards.isNotEmpty ? _rng.nextInt(_cards.length) : 0;
    _cards.insert(pos, card);
    final playerCount = _state.playerOrder.length;
    if (playerCount > 0) {
      final requiredRounds = (_cards.length / playerCount).ceil();
      if (requiredRounds > _state.maxRounds) {
        _state = _state.copyWith(maxRounds: requiredRounds);
      }
    }
  }

  @override
  bool get isGameOver => _state.isOver;

  /// Owner-initiated early termination (e.g. every other player has left)
  /// — bypasses the normal round-completion path straight to game-over so
  /// the existing `isGameOver` broadcast/persist logic picks it up as-is.
  void forceEnd() {
    _state = _state.copyWith(isOver: true);
  }

  NhieState _handleVote(NhieVoteEvent e) {
    if (!_state.playerOrder.contains(e.userId)) return _state;
    if (!_state.isVotingOpen) return _state;
    if (_state.voteEntries.containsKey(e.userId)) return _state;

    final newEntries = {
      ..._state.voteEntries,
      e.userId: NhieVoteEntry(
        userId: e.userId,
        haveI: e.haveI,
        message: e.message,
      ),
    };
    final newScores = Map<String, int>.from(_state.scores);
    if (e.haveI) newScores[e.userId] = (newScores[e.userId] ?? 0) + 1;

    final allVoted = _state.playerOrder.every(
      (id) => newEntries.containsKey(id),
    );

    return _state.copyWith(
      snapshotAt: DateTime.now().millisecondsSinceEpoch,
      voteEntries: newEntries,
      scores: newScores,
      isVotingOpen: !allVoted,
    );
  }

  NhieState _handleReaction(NhieReactionEvent e) {
    if (!_state.playerOrder.contains(e.userId)) return _state;
    // One reaction per player per turn
    if (_state.reactions.any((r) => r.userId == e.userId)) return _state;
    return _state.copyWith(
      snapshotAt: DateTime.now().millisecondsSinceEpoch,
      reactions: [
        ..._state.reactions,
        NhieReaction(userId: e.userId, sticker: e.sticker, ts: e.ts),
      ],
    );
  }
}
