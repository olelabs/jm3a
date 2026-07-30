// // // import 'package:jma3a/features/games/engine/base_game_engine.dart';

// // // // ═══════════════════════════════════════════════════════════════════════════
// // // // ENUMS
// // // // ═══════════════════════════════════════════════════════════════════════════

// // // enum TodCardType { truth, dare }

// // // enum TodDifficulty { mild, medium, spicy }

// // // enum TodTurnPhase {
// // //   choosingType, // player picks Truth or Dare
// // //   readingCard, // card is visible, player performing
// // //   awaitingResult, // timer expired or player pressed Done/Skip
// // //   punishmentVoting, // skip happened → punishment vote in progress
// // //   awaitingNextTurn, // turn ended, waiting for owner to advance
// // // }

// // // enum TodPunishmentVote { doIt, dontDoIt, changePunishment }

// // // enum TodEndCondition { roundLimit, scoreLimit, manual }

// // // // ═══════════════════════════════════════════════════════════════════════════
// // // // VALUE OBJECTS
// // // // ═══════════════════════════════════════════════════════════════════════════

// // // class TodCard {
// // //   const TodCard({
// // //     required this.id,
// // //     required this.content,
// // //     required this.type,
// // //     required this.difficulty,
// // //   });

// // //   final String id;
// // //   final String content;
// // //   final TodCardType type;
// // //   final TodDifficulty difficulty;

// // //   bool get isSpicy => difficulty == TodDifficulty.spicy;

// // //   Map<String, dynamic> toMap() => {
// // //     'id': id,
// // //     'content': content,
// // //     'type': type.name,
// // //     'difficulty': difficulty.name,
// // //   };

// // //   static TodCard fromMap(Map<String, dynamic> m) => TodCard(
// // //     id: m['id'] as String,
// // //     content: m['content'] as String,
// // //     type: TodCardType.values.firstWhere(
// // //       (t) => t.name == m['type'],
// // //       orElse: () => TodCardType.truth,
// // //     ),
// // //     difficulty: TodDifficulty.values.firstWhere(
// // //       (d) => d.name == m['difficulty'],
// // //       orElse: () => TodDifficulty.mild,
// // //     ),
// // //   );
// // // }

// // // /// A punishment proposal for a skipped turn.
// // // class TodPunishment {
// // //   const TodPunishment({
// // //     required this.id,
// // //     required this.text,
// // //     required this.proposedBy,
// // //     required this.proposedAt,
// // //   });

// // //   final String id;
// // //   final String text;
// // //   final String proposedBy; // userId
// // //   final int proposedAt; // epoch ms

// // //   Map<String, dynamic> toMap() => {
// // //     'id': id,
// // //     'text': text,
// // //     'proposed_by': proposedBy,
// // //     'proposed_at': proposedAt,
// // //   };

// // //   static TodPunishment fromMap(Map<String, dynamic> m) => TodPunishment(
// // //     id: m['id'] as String,
// // //     text: m['text'] as String,
// // //     proposedBy: m['proposed_by'] as String,
// // //     proposedAt: m['proposed_at'] as int,
// // //   );
// // // }

// // // /// Accumulated votes on a punishment proposal.
// // // class TodPunishmentVoteState {
// // //   const TodPunishmentVoteState({
// // //     required this.punishment,
// // //     required this.votes, // userId → vote
// // //     required this.totalVoters, // how many players can vote
// // //     this.moderatorOverride, // null = no override
// // //   });

// // //   final TodPunishment punishment;
// // //   final Map<String, TodPunishmentVote> votes;
// // //   final int totalVoters;
// // //   final TodPunishmentVote? moderatorOverride;

// // //   bool get hasOutcome => moderatorOverride != null || _majorityReached;

// // //   bool get _majorityReached {
// // //     if (votes.isEmpty) return false;
// // //     final majority = (totalVoters / 2).ceil();
// // //     final counts = <TodPunishmentVote, int>{};
// // //     for (final v in votes.values) {
// // //       counts[v] = (counts[v] ?? 0) + 1;
// // //     }
// // //     return counts.values.any((c) => c >= majority);
// // //   }

// // //   TodPunishmentVote? get resolvedVote {
// // //     if (moderatorOverride != null) return moderatorOverride;
// // //     if (!_majorityReached) return null;
// // //     final counts = <TodPunishmentVote, int>{};
// // //     for (final v in votes.values) {
// // //       counts[v] = (counts[v] ?? 0) + 1;
// // //     }
// // //     return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
// // //   }

// // //   Map<String, dynamic> toMap() => {
// // //     'punishment': punishment.toMap(),
// // //     'votes': votes.map((k, v) => MapEntry(k, v.name)),
// // //     'total_voters': totalVoters,
// // //     'moderator_override': moderatorOverride?.name,
// // //   };

// // //   static TodPunishmentVoteState fromMap(Map<String, dynamic> m) =>
// // //       TodPunishmentVoteState(
// // //         punishment: TodPunishment.fromMap(
// // //           m['punishment'] as Map<String, dynamic>,
// // //         ),
// // //         votes: (m['votes'] as Map<String, dynamic>? ?? {}).map(
// // //           (k, v) => MapEntry(
// // //             k,
// // //             TodPunishmentVote.values.firstWhere(
// // //               (e) => e.name == v,
// // //               orElse: () => TodPunishmentVote.doIt,
// // //             ),
// // //           ),
// // //         ),
// // //         totalVoters: m['total_voters'] as int? ?? 0,
// // //         moderatorOverride: m['moderator_override'] != null
// // //             ? TodPunishmentVote.values.firstWhere(
// // //                 (e) => e.name == m['moderator_override'],
// // //                 orElse: () => TodPunishmentVote.doIt,
// // //               )
// // //             : null,
// // //       );
// // // }

// // // /// Per-player scores tracked across turns.
// // // class TodPlayerScore {
// // //   const TodPlayerScore({
// // //     required this.userId,
// // //     this.completedTruths = 0,
// // //     this.completedDares = 0,
// // //     this.skips = 0,
// // //     this.punishmentsReceived = 0,
// // //     this.points = 0,
// // //   });

// // //   final String userId;
// // //   final int completedTruths;
// // //   final int completedDares;
// // //   final int skips;
// // //   final int punishmentsReceived;
// // //   final int points; // configurable scoring

// // //   int get totalCompleted => completedTruths + completedDares;

// // //   TodPlayerScore copyWith({
// // //     int? completedTruths,
// // //     int? completedDares,
// // //     int? skips,
// // //     int? punishmentsReceived,
// // //     int? points,
// // //   }) => TodPlayerScore(
// // //     userId: userId,
// // //     completedTruths: completedTruths ?? this.completedTruths,
// // //     completedDares: completedDares ?? this.completedDares,
// // //     skips: skips ?? this.skips,
// // //     punishmentsReceived: punishmentsReceived ?? this.punishmentsReceived,
// // //     points: points ?? this.points,
// // //   );

// // //   Map<String, dynamic> toMap() => {
// // //     'user_id': userId,
// // //     'completed_truths': completedTruths,
// // //     'completed_dares': completedDares,
// // //     'skips': skips,
// // //     'punishments_received': punishmentsReceived,
// // //     'points': points,
// // //   };

// // //   static TodPlayerScore fromMap(Map<String, dynamic> m) => TodPlayerScore(
// // //     userId: m['user_id'] as String,
// // //     completedTruths: m['completed_truths'] as int? ?? 0,
// // //     completedDares: m['completed_dares'] as int? ?? 0,
// // //     skips: m['skips'] as int? ?? 0,
// // //     punishmentsReceived: m['punishments_received'] as int? ?? 0,
// // //     points: m['points'] as int? ?? 0,
// // //   );
// // // }

// // // // ═══════════════════════════════════════════════════════════════════════════
// // // // GAME STATE
// // // // ═══════════════════════════════════════════════════════════════════════════

// // // // ── Round history ─────────────────────────────────────────────────────────────

// // // class TodReaction {
// // //   const TodReaction({
// // //     required this.userId,
// // //     required this.emoji,
// // //     required this.ts,
// // //   });
// // //   final String userId;
// // //   final String emoji;
// // //   final int ts;
// // //   Map<String, dynamic> toMap() => {'user_id': userId, 'emoji': emoji, 'ts': ts};
// // //   static TodReaction fromMap(Map<String, dynamic> m) => TodReaction(
// // //     userId: m['user_id'] as String,
// // //     emoji: m['emoji'] as String,
// // //     ts: m['ts'] as int? ?? 0,
// // //   );
// // // }

// // // class TodResponseVote {
// // //   const TodResponseVote({required this.voterId, required this.ts});
// // //   final String voterId;
// // //   final int ts;
// // //   Map<String, dynamic> toMap() => {'voter_id': voterId, 'ts': ts};
// // //   static TodResponseVote fromMap(Map<String, dynamic> m) => TodResponseVote(
// // //     voterId: m['voter_id'] as String,
// // //     ts: m['ts'] as int? ?? 0,
// // //   );
// // // }

// // // class TodRoundRecord {
// // //   const TodRoundRecord({
// // //     required this.roundNumber,
// // //     required this.playerId,
// // //     required this.card,
// // //     required this.response,
// // //     required this.proofImageB64,
// // //     this.reactions = const [],
// // //     this.votes = const [],
// // //   });
// // //   final int roundNumber;
// // //   final String playerId;
// // //   final TodCard? card;
// // //   final String response;
// // //   final String proofImageB64;
// // //   final List<TodReaction> reactions;
// // //   final List<TodResponseVote> votes;

// // //   int get voteCount => votes.length;

// // //   Map<String, dynamic> toMap() => {
// // //     'round_number': roundNumber,
// // //     'player_id': playerId,
// // //     'card': card?.toMap(),
// // //     'response': response,
// // //     'proof_image': proofImageB64,
// // //     'reactions': reactions.map((r) => r.toMap()).toList(),
// // //     'votes': votes.map((v) => v.toMap()).toList(),
// // //   };

// // //   static TodRoundRecord fromMap(Map<String, dynamic> m) => TodRoundRecord(
// // //     roundNumber: m['round_number'] as int? ?? 0,
// // //     playerId: m['player_id'] as String,
// // //     card: m['card'] != null
// // //         ? TodCard.fromMap(m['card'] as Map<String, dynamic>)
// // //         : null,
// // //     response: m['response'] as String? ?? '',
// // //     proofImageB64: m['proof_image'] as String? ?? '',
// // //     reactions:
// // //         (m['reactions'] as List?)
// // //             ?.map((r) => TodReaction.fromMap(r as Map<String, dynamic>))
// // //             .toList() ??
// // //         [],
// // //     votes:
// // //         (m['votes'] as List?)
// // //             ?.map((v) => TodResponseVote.fromMap(v as Map<String, dynamic>))
// // //             .toList() ??
// // //         [],
// // //   );

// // //   TodRoundRecord copyWith({
// // //     List<TodReaction>? reactions,
// // //     List<TodResponseVote>? votes,
// // //   }) => TodRoundRecord(
// // //     roundNumber: roundNumber,
// // //     playerId: playerId,
// // //     card: card,
// // //     response: response,
// // //     proofImageB64: proofImageB64,
// // //     reactions: reactions ?? this.reactions,
// // //     votes: votes ?? this.votes,
// // //   );
// // // }

// // // class TodState extends GameEngineState {
// // //   const TodState({
// // //     required super.snapshotAt,
// // //     required this.playerOrder,
// // //     required this.currentPlayerIndex,
// // //     required this.phase,
// // //     required this.roundNumber,
// // //     required this.maxRounds,
// // //     required this.scores,
// // //     this.currentCard,
// // //     this.currentPunishmentVote,
// // //     this.timerStartedAt,
// // //     this.turnStartedAt,
// // //     this.isOver = false,
// // //     this.endReason,
// // //     this.turnOrderMode = TurnOrderMode.circular,
// // //     this.randomTurnQueue = const [],
// // //     this.usedCardIds = const [],
// // //     this.turnResponse = '',
// // //     this.turnProofImageB64 = '',
// // //     this.currentReactions = const [],
// // //     this.currentVotes = const [],
// // //     this.history = const [],
// // //   });

// // //   final List<String> playerOrder;
// // //   final int currentPlayerIndex;
// // //   final TodTurnPhase phase;
// // //   final int roundNumber;
// // //   final int maxRounds;
// // //   final Map<String, TodPlayerScore> scores; // userId → score
// // //   final TodCard? currentCard;
// // //   final TodPunishmentVoteState? currentPunishmentVote;
// // //   final int? timerStartedAt; // epoch ms when timer started
// // //   final int? turnStartedAt; // epoch ms when turn began
// // //   final bool isOver;
// // //   final String? endReason;
// // //   final TurnOrderMode turnOrderMode;
// // //   final List<String> randomTurnQueue; // pre-shuffled for random mode
// // //   final List<String> usedCardIds; // prevents re-dealing same card
// // //   final String turnResponse; // player's text response
// // //   final String turnProofImageB64; // view-once proof image (base64)
// // //   final List<TodReaction> currentReactions; // reactions to current turn
// // //   final List<TodResponseVote> currentVotes; // votes for current response
// // //   final List<TodRoundRecord> history; // completed rounds

// // //   String get currentPlayerId => playerOrder.isEmpty
// // //       ? ''
// // //       : playerOrder[currentPlayerIndex % playerOrder.length];

// // //   bool get isInPunishmentPhase => phase == TodTurnPhase.punishmentVoting;

// // //   bool get isCurrentUsersTurn => false; // evaluated by provider with userId

// // //   List<TodPlayerScore> get sortedScores {
// // //     final list = scores.values.toList();
// // //     list.sort((a, b) => b.points.compareTo(a.points));
// // //     return list;
// // //   }

// // //   TodState copyWith({
// // //     int? snapshotAt,
// // //     int? currentPlayerIndex,
// // //     TodTurnPhase? phase,
// // //     int? roundNumber,
// // //     Map<String, TodPlayerScore>? scores,
// // //     TodCard? Function()? currentCard,
// // //     TodPunishmentVoteState? Function()? currentPunishmentVote,
// // //     int? Function()? timerStartedAt,
// // //     int? Function()? turnStartedAt,
// // //     bool? isOver,
// // //     String? endReason,
// // //     List<String>? randomTurnQueue,
// // //     List<String>? usedCardIds,
// // //     String? turnResponse,
// // //     String? turnProofImageB64,
// // //     List<TodReaction>? currentReactions,
// // //     List<TodResponseVote>? currentVotes,
// // //     List<TodRoundRecord>? history,
// // //   }) => TodState(
// // //     snapshotAt: snapshotAt ?? this.snapshotAt,
// // //     playerOrder: playerOrder,
// // //     currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
// // //     phase: phase ?? this.phase,
// // //     roundNumber: roundNumber ?? this.roundNumber,
// // //     maxRounds: maxRounds,
// // //     scores: scores ?? this.scores,
// // //     currentCard: currentCard != null ? currentCard() : this.currentCard,
// // //     currentPunishmentVote: currentPunishmentVote != null
// // //         ? currentPunishmentVote()
// // //         : this.currentPunishmentVote,
// // //     timerStartedAt: timerStartedAt != null
// // //         ? timerStartedAt()
// // //         : this.timerStartedAt,
// // //     turnStartedAt: turnStartedAt != null ? turnStartedAt() : this.turnStartedAt,
// // //     isOver: isOver ?? this.isOver,
// // //     endReason: endReason ?? this.endReason,
// // //     turnOrderMode: turnOrderMode,
// // //     randomTurnQueue: randomTurnQueue ?? this.randomTurnQueue,
// // //     usedCardIds: usedCardIds ?? this.usedCardIds,
// // //     turnResponse: turnResponse ?? this.turnResponse,
// // //     turnProofImageB64: turnProofImageB64 ?? this.turnProofImageB64,
// // //     currentReactions: currentReactions ?? this.currentReactions,
// // //     currentVotes: currentVotes ?? this.currentVotes,
// // //     history: history ?? this.history,
// // //   );

// // //   Map<String, dynamic> toMap() => {
// // //     'snapshot_at': snapshotAt,
// // //     'player_order': playerOrder,
// // //     'current_player_index': currentPlayerIndex,
// // //     'phase': phase.name,
// // //     'round_number': roundNumber,
// // //     'max_rounds': maxRounds,
// // //     'scores': scores.map((k, v) => MapEntry(k, v.toMap())),
// // //     'current_card': currentCard?.toMap(),
// // //     'current_punishment_vote': currentPunishmentVote?.toMap(),
// // //     'timer_started_at': timerStartedAt,
// // //     'turn_started_at': turnStartedAt,
// // //     'is_over': isOver,
// // //     'end_reason': endReason,
// // //     'turn_order_mode': turnOrderMode.name,
// // //     'random_turn_queue': randomTurnQueue,
// // //     'used_card_ids': usedCardIds,
// // //     'turn_response': turnResponse,
// // //     'turn_proof_image': turnProofImageB64,
// // //     'current_reactions': currentReactions.map((r) => r.toMap()).toList(),
// // //     'current_votes': currentVotes.map((v) => v.toMap()).toList(),
// // //     'history': history.map((r) => r.toMap()).toList(),
// // //   };

// // //   static TodState fromMap(Map<String, dynamic> m) {
// // //     final rawScores = (m['scores'] as Map<String, dynamic>? ?? {});
// // //     return TodState(
// // //       snapshotAt: m['snapshot_at'] as int? ?? 0,
// // //       playerOrder: (m['player_order'] as List?)?.cast<String>() ?? [],
// // //       currentPlayerIndex: m['current_player_index'] as int? ?? 0,
// // //       phase: TodTurnPhase.values.firstWhere(
// // //         (p) => p.name == m['phase'],
// // //         orElse: () => TodTurnPhase.choosingType,
// // //       ),
// // //       roundNumber: m['round_number'] as int? ?? 1,
// // //       maxRounds: m['max_rounds'] as int? ?? 10,
// // //       scores: rawScores.map(
// // //         (k, v) =>
// // //             MapEntry(k, TodPlayerScore.fromMap(v as Map<String, dynamic>)),
// // //       ),
// // //       currentCard: m['current_card'] != null
// // //           ? TodCard.fromMap(m['current_card'] as Map<String, dynamic>)
// // //           : null,
// // //       currentPunishmentVote: m['current_punishment_vote'] != null
// // //           ? TodPunishmentVoteState.fromMap(
// // //               m['current_punishment_vote'] as Map<String, dynamic>,
// // //             )
// // //           : null,
// // //       timerStartedAt: m['timer_started_at'] as int?,
// // //       turnStartedAt: m['turn_started_at'] as int?,
// // //       isOver: m['is_over'] as bool? ?? false,
// // //       endReason: m['end_reason'] as String?,
// // //       turnOrderMode: TurnOrderMode.values.firstWhere(
// // //         (t) => t.name == m['turn_order_mode'],
// // //         orElse: () => TurnOrderMode.circular,
// // //       ),
// // //       randomTurnQueue: (m['random_turn_queue'] as List?)?.cast<String>() ?? [],
// // //       usedCardIds: (m['used_card_ids'] as List?)?.cast<String>() ?? [],
// // //       turnResponse: m['turn_response'] as String? ?? '',
// // //       turnProofImageB64: m['turn_proof_image'] as String? ?? '',
// // //       currentReactions:
// // //           (m['current_reactions'] as List?)
// // //               ?.map((r) => TodReaction.fromMap(r as Map<String, dynamic>))
// // //               .toList() ??
// // //           [],
// // //       currentVotes:
// // //           (m['current_votes'] as List?)
// // //               ?.map((v) => TodResponseVote.fromMap(v as Map<String, dynamic>))
// // //               .toList() ??
// // //           [],
// // //       history:
// // //           (m['history'] as List?)
// // //               ?.map((r) => TodRoundRecord.fromMap(r as Map<String, dynamic>))
// // //               .toList() ??
// // //           [],
// // //     );
// // //   }
// // // }

// // // // ═══════════════════════════════════════════════════════════════════════════
// // // // EVENTS  (player → owner via Broadcast)
// // // // ═══════════════════════════════════════════════════════════════════════════

// // // /// Player chose Truth or Dare.
// // // class TodChoiceEvent extends GameEngineEvent {
// // //   const TodChoiceEvent({
// // //     required super.userId,
// // //     required super.ts,
// // //     required this.cardType,
// // //   });
// // //   final TodCardType cardType;
// // // }

// // // /// Player completed their turn (did the truth/dare).
// // // class TodCompleteEvent extends GameEngineEvent {
// // //   const TodCompleteEvent({
// // //     required super.userId,
// // //     required super.ts,
// // //     this.response = '',
// // //     this.proofImageB64 = '',
// // //   });
// // //   final String response;
// // //   final String proofImageB64;
// // // }

// // // /// Player reacts to the current response with an emoji
// // // class TodReactEvent extends GameEngineEvent {
// // //   const TodReactEvent({
// // //     required super.userId,
// // //     required super.ts,
// // //     required this.emoji,
// // //   });
// // //   final String emoji;
// // // }

// // // /// Player votes for the current response as best
// // // class TodVoteResponseEvent extends GameEngineEvent {
// // //   const TodVoteResponseEvent({required super.userId, required super.ts});
// // // }

// // // /// Player skipped their turn.
// // // class TodSkipEvent extends GameEngineEvent {
// // //   const TodSkipEvent({required super.userId, required super.ts});
// // // }

// // // /// Timer expired on the current player's turn.
// // // class TodTimerExpiredEvent extends GameEngineEvent {
// // //   const TodTimerExpiredEvent({
// // //     required super.userId, // the timed-out player
// // //     required super.ts,
// // //   });
// // // }

// // // /// Moderator/owner proposed a punishment text.
// // // class TodProposePunishmentEvent extends GameEngineEvent {
// // //   const TodProposePunishmentEvent({
// // //     required super.userId,
// // //     required super.ts,
// // //     required this.punishment,
// // //   });
// // //   final TodPunishment punishment;
// // // }

// // // /// A player voted on the current punishment.
// // // class TodVotePunishmentEvent extends GameEngineEvent {
// // //   const TodVotePunishmentEvent({
// // //     required super.userId,
// // //     required super.ts,
// // //     required this.vote,
// // //   });
// // //   final TodPunishmentVote vote;
// // // }

// // // /// Moderator overrides the punishment vote.
// // // class TodModeratorOverrideEvent extends GameEngineEvent {
// // //   const TodModeratorOverrideEvent({
// // //     required super.userId,
// // //     required super.ts,
// // //     required this.decision,
// // //     this.replacementText,
// // //   });
// // //   final TodPunishmentVote decision;
// // //   final String? replacementText;
// // // }

// // // /// Owner/mod manually ends the game.
// // // class TodEndGameEvent extends GameEngineEvent {
// // //   const TodEndGameEvent({
// // //     required super.userId,
// // //     required super.ts,
// // //     this.reason = 'manual',
// // //   });
// // //   final String reason;
// // // }

// // import 'package:jma3a/features/games/engine/base_game_engine.dart';

// // // ═══════════════════════════════════════════════════════════════════════════
// // // ENUMS
// // // ═══════════════════════════════════════════════════════════════════════════

// // enum TodCardType { truth, dare }

// // enum TodDifficulty { mild, medium, spicy }

// // enum TodTurnPhase {
// //   choosingType, // player picks Truth or Dare
// //   readingCard, // card is visible, player performing
// //   awaitingResult, // timer expired or player pressed Done/Skip
// //   punishmentVoting, // skip happened → punishment vote in progress
// //   awaitingNextTurn, // turn ended, waiting for owner to advance
// // }

// // enum TodPunishmentVote { doIt, dontDoIt, changePunishment }

// // enum TodEndCondition { roundLimit, scoreLimit, manual }

// // /// How a proof photo/video can be viewed by other players — Snapchat-style.
// // enum TodProofViewMode {
// //   once, // disappears the instant the viewer closes it — no second look
// //   replayOnce, // can be reopened exactly one more time, then gone
// //   timed, // shown for a fixed number of seconds, then auto-hides
// // }

// // // ═══════════════════════════════════════════════════════════════════════════
// // // VALUE OBJECTS
// // // ═══════════════════════════════════════════════════════════════════════════

// // class TodCard {
// //   const TodCard({
// //     required this.id,
// //     required this.content,
// //     required this.type,
// //     required this.difficulty,
// //   });

// //   final String id;
// //   final String content;
// //   final TodCardType type;
// //   final TodDifficulty difficulty;

// //   bool get isSpicy => difficulty == TodDifficulty.spicy;

// //   Map<String, dynamic> toMap() => {
// //     'id': id,
// //     'content': content,
// //     'type': type.name,
// //     'difficulty': difficulty.name,
// //   };

// //   static TodCard fromMap(Map<String, dynamic> m) => TodCard(
// //     id: m['id'] as String,
// //     content: m['content'] as String,
// //     type: TodCardType.values.firstWhere(
// //       (t) => t.name == m['type'],
// //       orElse: () => TodCardType.truth,
// //     ),
// //     difficulty: TodDifficulty.values.firstWhere(
// //       (d) => d.name == m['difficulty'],
// //       orElse: () => TodDifficulty.mild,
// //     ),
// //   );
// // }

// // /// A punishment proposal for a skipped turn.
// // class TodPunishment {
// //   const TodPunishment({
// //     required this.id,
// //     required this.text,
// //     required this.proposedBy,
// //     required this.proposedAt,
// //   });

// //   final String id;
// //   final String text;
// //   final String proposedBy; // userId
// //   final int proposedAt; // epoch ms

// //   Map<String, dynamic> toMap() => {
// //     'id': id,
// //     'text': text,
// //     'proposed_by': proposedBy,
// //     'proposed_at': proposedAt,
// //   };

// //   static TodPunishment fromMap(Map<String, dynamic> m) => TodPunishment(
// //     id: m['id'] as String,
// //     text: m['text'] as String,
// //     proposedBy: m['proposed_by'] as String,
// //     proposedAt: m['proposed_at'] as int,
// //   );
// // }

// // /// Accumulated votes on a punishment proposal.
// // class TodPunishmentVoteState {
// //   const TodPunishmentVoteState({
// //     required this.punishment,
// //     required this.votes, // userId → vote
// //     required this.totalVoters, // how many players can vote
// //     this.moderatorOverride, // null = no override
// //   });

// //   final TodPunishment punishment;
// //   final Map<String, TodPunishmentVote> votes;
// //   final int totalVoters;
// //   final TodPunishmentVote? moderatorOverride;

// //   bool get hasOutcome => moderatorOverride != null || _majorityReached;

// //   bool get _majorityReached {
// //     if (votes.isEmpty) return false;
// //     final majority = (totalVoters / 2).ceil();
// //     final counts = <TodPunishmentVote, int>{};
// //     for (final v in votes.values) {
// //       counts[v] = (counts[v] ?? 0) + 1;
// //     }
// //     return counts.values.any((c) => c >= majority);
// //   }

// //   TodPunishmentVote? get resolvedVote {
// //     if (moderatorOverride != null) return moderatorOverride;
// //     if (!_majorityReached) return null;
// //     final counts = <TodPunishmentVote, int>{};
// //     for (final v in votes.values) {
// //       counts[v] = (counts[v] ?? 0) + 1;
// //     }
// //     return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
// //   }

// //   Map<String, dynamic> toMap() => {
// //     'punishment': punishment.toMap(),
// //     'votes': votes.map((k, v) => MapEntry(k, v.name)),
// //     'total_voters': totalVoters,
// //     'moderator_override': moderatorOverride?.name,
// //   };

// //   static TodPunishmentVoteState fromMap(Map<String, dynamic> m) =>
// //       TodPunishmentVoteState(
// //         punishment: TodPunishment.fromMap(
// //           m['punishment'] as Map<String, dynamic>,
// //         ),
// //         votes: (m['votes'] as Map<String, dynamic>? ?? {}).map(
// //           (k, v) => MapEntry(
// //             k,
// //             TodPunishmentVote.values.firstWhere(
// //               (e) => e.name == v,
// //               orElse: () => TodPunishmentVote.doIt,
// //             ),
// //           ),
// //         ),
// //         totalVoters: m['total_voters'] as int? ?? 0,
// //         moderatorOverride: m['moderator_override'] != null
// //             ? TodPunishmentVote.values.firstWhere(
// //                 (e) => e.name == m['moderator_override'],
// //                 orElse: () => TodPunishmentVote.doIt,
// //               )
// //             : null,
// //       );
// // }

// // /// Per-player scores tracked across turns.
// // class TodPlayerScore {
// //   const TodPlayerScore({
// //     required this.userId,
// //     this.completedTruths = 0,
// //     this.completedDares = 0,
// //     this.skips = 0,
// //     this.punishmentsReceived = 0,
// //     this.points = 0,
// //   });

// //   final String userId;
// //   final int completedTruths;
// //   final int completedDares;
// //   final int skips;
// //   final int punishmentsReceived;
// //   final int points; // configurable scoring

// //   int get totalCompleted => completedTruths + completedDares;

// //   TodPlayerScore copyWith({
// //     int? completedTruths,
// //     int? completedDares,
// //     int? skips,
// //     int? punishmentsReceived,
// //     int? points,
// //   }) => TodPlayerScore(
// //     userId: userId,
// //     completedTruths: completedTruths ?? this.completedTruths,
// //     completedDares: completedDares ?? this.completedDares,
// //     skips: skips ?? this.skips,
// //     punishmentsReceived: punishmentsReceived ?? this.punishmentsReceived,
// //     points: points ?? this.points,
// //   );

// //   Map<String, dynamic> toMap() => {
// //     'user_id': userId,
// //     'completed_truths': completedTruths,
// //     'completed_dares': completedDares,
// //     'skips': skips,
// //     'punishments_received': punishmentsReceived,
// //     'points': points,
// //   };

// //   static TodPlayerScore fromMap(Map<String, dynamic> m) => TodPlayerScore(
// //     userId: m['user_id'] as String,
// //     completedTruths: m['completed_truths'] as int? ?? 0,
// //     completedDares: m['completed_dares'] as int? ?? 0,
// //     skips: m['skips'] as int? ?? 0,
// //     punishmentsReceived: m['punishments_received'] as int? ?? 0,
// //     points: m['points'] as int? ?? 0,
// //   );
// // }

// // // ═══════════════════════════════════════════════════════════════════════════
// // // GAME STATE
// // // ═══════════════════════════════════════════════════════════════════════════

// // // ── Round history ─────────────────────────────────────────────────────────────

// // class TodReaction {
// //   const TodReaction({
// //     required this.userId,
// //     required this.emoji,
// //     required this.ts,
// //   });
// //   final String userId;
// //   final String emoji;
// //   final int ts;
// //   Map<String, dynamic> toMap() => {'user_id': userId, 'emoji': emoji, 'ts': ts};
// //   static TodReaction fromMap(Map<String, dynamic> m) => TodReaction(
// //     userId: m['user_id'] as String,
// //     emoji: m['emoji'] as String,
// //     ts: m['ts'] as int? ?? 0,
// //   );
// // }

// // class TodResponseVote {
// //   const TodResponseVote({required this.voterId, required this.ts});
// //   final String voterId;
// //   final int ts;
// //   Map<String, dynamic> toMap() => {'voter_id': voterId, 'ts': ts};
// //   static TodResponseVote fromMap(Map<String, dynamic> m) => TodResponseVote(
// //     voterId: m['voter_id'] as String,
// //     ts: m['ts'] as int? ?? 0,
// //   );
// // }

// // class TodRoundRecord {
// //   const TodRoundRecord({
// //     required this.roundNumber,
// //     required this.playerId,
// //     required this.card,
// //     required this.response,
// //     this.hadProof = false,
// //     this.proofWatchedBy = const [],
// //     this.reactions = const [],
// //     this.votes = const [],
// //   });
// //   final int roundNumber;
// //   final String playerId;
// //   final TodCard? card;
// //   final String response;
// //   // ✅ History NEVER stores the actual proof photo/video — only whether one
// //   // existed and who watched it. The media itself lives only on
// //   // TodState.turnProofUrl during the live turn, and is discarded once the
// //   // turn advances (per the Snapchat-style ephemeral viewing requirement).
// //   final bool hadProof;
// //   final List<String> proofWatchedBy;
// //   final List<TodReaction> reactions;
// //   final List<TodResponseVote> votes;

// //   int get voteCount => votes.length;

// //   Map<String, dynamic> toMap() => {
// //     'round_number': roundNumber,
// //     'player_id': playerId,
// //     'card': card?.toMap(),
// //     'response': response,
// //     'had_proof': hadProof,
// //     'proof_watched_by': proofWatchedBy,
// //     'reactions': reactions.map((r) => r.toMap()).toList(),
// //     'votes': votes.map((v) => v.toMap()).toList(),
// //   };

// //   static TodRoundRecord fromMap(Map<String, dynamic> m) => TodRoundRecord(
// //     roundNumber: m['round_number'] as int? ?? 0,
// //     playerId: m['player_id'] as String,
// //     card: m['card'] != null
// //         ? TodCard.fromMap(m['card'] as Map<String, dynamic>)
// //         : null,
// //     response: m['response'] as String? ?? '',
// //     hadProof: m['had_proof'] as bool? ?? false,
// //     proofWatchedBy: (m['proof_watched_by'] as List?)?.cast<String>() ?? [],
// //     reactions:
// //         (m['reactions'] as List?)
// //             ?.map((r) => TodReaction.fromMap(r as Map<String, dynamic>))
// //             .toList() ??
// //         [],
// //     votes:
// //         (m['votes'] as List?)
// //             ?.map((v) => TodResponseVote.fromMap(v as Map<String, dynamic>))
// //             .toList() ??
// //         [],
// //   );

// //   TodRoundRecord copyWith({
// //     List<String>? proofWatchedBy,
// //     List<TodReaction>? reactions,
// //     List<TodResponseVote>? votes,
// //   }) => TodRoundRecord(
// //     roundNumber: roundNumber,
// //     playerId: playerId,
// //     card: card,
// //     response: response,
// //     hadProof: hadProof,
// //     proofWatchedBy: proofWatchedBy ?? this.proofWatchedBy,
// //     reactions: reactions ?? this.reactions,
// //     votes: votes ?? this.votes,
// //   );
// // }

// // class TodState extends GameEngineState {
// //   const TodState({
// //     required super.snapshotAt,
// //     required this.playerOrder,
// //     required this.currentPlayerIndex,
// //     required this.phase,
// //     required this.roundNumber,
// //     required this.maxRounds,
// //     required this.scores,
// //     this.currentCard,
// //     this.currentPunishmentVote,
// //     this.timerStartedAt,
// //     this.turnStartedAt,
// //     this.isOver = false,
// //     this.endReason,
// //     this.turnOrderMode = TurnOrderMode.circular,
// //     this.randomTurnQueue = const [],
// //     this.usedCardIds = const [],
// //     this.turnResponse = '',
// //     this.turnProofUrl = '',
// //     this.turnProofIsVideo = false,
// //     this.turnProofViewMode = TodProofViewMode.once,
// //     this.turnProofViewSeconds = 5,
// //     this.turnProofViewedBy = const [],
// //     this.currentReactions = const [],
// //     this.currentVotes = const [],
// //     this.history = const [],
// //   });

// //   final List<String> playerOrder;
// //   final int currentPlayerIndex;
// //   final TodTurnPhase phase;
// //   final int roundNumber;
// //   final int maxRounds;
// //   final Map<String, TodPlayerScore> scores; // userId → score
// //   final TodCard? currentCard;
// //   final TodPunishmentVoteState? currentPunishmentVote;
// //   final int? timerStartedAt; // epoch ms when timer started
// //   final int? turnStartedAt; // epoch ms when turn began
// //   final bool isOver;
// //   final String? endReason;
// //   final TurnOrderMode turnOrderMode;
// //   final List<String> randomTurnQueue; // pre-shuffled for random mode
// //   final List<String> usedCardIds; // prevents re-dealing same card
// //   final String turnResponse; // player's text response
// //   // Live proof media for the CURRENT turn only — cleared by advanceTurn().
// //   // Never persisted into history; see TodRoundRecord.hadProof/proofWatchedBy.
// //   final String turnProofUrl;
// //   final bool turnProofIsVideo;
// //   final TodProofViewMode turnProofViewMode;
// //   final int turnProofViewSeconds; // used when turnProofViewMode == timed
// //   final List<String> turnProofViewedBy;
// //   final List<TodReaction> currentReactions; // reactions to current turn
// //   final List<TodResponseVote> currentVotes; // votes for current response
// //   final List<TodRoundRecord> history; // completed rounds

// //   String get currentPlayerId => playerOrder.isEmpty
// //       ? ''
// //       : playerOrder[currentPlayerIndex % playerOrder.length];

// //   bool get isInPunishmentPhase => phase == TodTurnPhase.punishmentVoting;

// //   bool get isCurrentUsersTurn => false; // evaluated by provider with userId

// //   List<TodPlayerScore> get sortedScores {
// //     final list = scores.values.toList();
// //     list.sort((a, b) => b.points.compareTo(a.points));
// //     return list;
// //   }

// //   TodState copyWith({
// //     int? snapshotAt,
// //     int? currentPlayerIndex,
// //     TodTurnPhase? phase,
// //     int? roundNumber,
// //     Map<String, TodPlayerScore>? scores,
// //     TodCard? Function()? currentCard,
// //     TodPunishmentVoteState? Function()? currentPunishmentVote,
// //     int? Function()? timerStartedAt,
// //     int? Function()? turnStartedAt,
// //     bool? isOver,
// //     String? endReason,
// //     List<String>? randomTurnQueue,
// //     List<String>? usedCardIds,
// //     String? turnResponse,
// //     String? turnProofUrl,
// //     bool? turnProofIsVideo,
// //     TodProofViewMode? turnProofViewMode,
// //     int? turnProofViewSeconds,
// //     List<String>? turnProofViewedBy,
// //     List<TodReaction>? currentReactions,
// //     List<TodResponseVote>? currentVotes,
// //     List<TodRoundRecord>? history,
// //   }) => TodState(
// //     snapshotAt: snapshotAt ?? this.snapshotAt,
// //     playerOrder: playerOrder,
// //     currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
// //     phase: phase ?? this.phase,
// //     roundNumber: roundNumber ?? this.roundNumber,
// //     maxRounds: maxRounds,
// //     scores: scores ?? this.scores,
// //     currentCard: currentCard != null ? currentCard() : this.currentCard,
// //     currentPunishmentVote: currentPunishmentVote != null
// //         ? currentPunishmentVote()
// //         : this.currentPunishmentVote,
// //     timerStartedAt: timerStartedAt != null
// //         ? timerStartedAt()
// //         : this.timerStartedAt,
// //     turnStartedAt: turnStartedAt != null ? turnStartedAt() : this.turnStartedAt,
// //     isOver: isOver ?? this.isOver,
// //     endReason: endReason ?? this.endReason,
// //     turnOrderMode: turnOrderMode,
// //     randomTurnQueue: randomTurnQueue ?? this.randomTurnQueue,
// //     usedCardIds: usedCardIds ?? this.usedCardIds,
// //     turnResponse: turnResponse ?? this.turnResponse,
// //     turnProofUrl: turnProofUrl ?? this.turnProofUrl,
// //     turnProofIsVideo: turnProofIsVideo ?? this.turnProofIsVideo,
// //     turnProofViewMode: turnProofViewMode ?? this.turnProofViewMode,
// //     turnProofViewSeconds: turnProofViewSeconds ?? this.turnProofViewSeconds,
// //     turnProofViewedBy: turnProofViewedBy ?? this.turnProofViewedBy,
// //     currentReactions: currentReactions ?? this.currentReactions,
// //     currentVotes: currentVotes ?? this.currentVotes,
// //     history: history ?? this.history,
// //   );

// //   Map<String, dynamic> toMap() => {
// //     'snapshot_at': snapshotAt,
// //     'player_order': playerOrder,
// //     'current_player_index': currentPlayerIndex,
// //     'phase': phase.name,
// //     'round_number': roundNumber,
// //     'max_rounds': maxRounds,
// //     'scores': scores.map((k, v) => MapEntry(k, v.toMap())),
// //     'current_card': currentCard?.toMap(),
// //     'current_punishment_vote': currentPunishmentVote?.toMap(),
// //     'timer_started_at': timerStartedAt,
// //     'turn_started_at': turnStartedAt,
// //     'is_over': isOver,
// //     'end_reason': endReason,
// //     'turn_order_mode': turnOrderMode.name,
// //     'random_turn_queue': randomTurnQueue,
// //     'used_card_ids': usedCardIds,
// //     'turn_response': turnResponse,
// //     'turn_proof_url': turnProofUrl,
// //     'turn_proof_is_video': turnProofIsVideo,
// //     'turn_proof_view_mode': turnProofViewMode.name,
// //     'turn_proof_view_seconds': turnProofViewSeconds,
// //     'turn_proof_viewed_by': turnProofViewedBy,
// //     'current_reactions': currentReactions.map((r) => r.toMap()).toList(),
// //     'current_votes': currentVotes.map((v) => v.toMap()).toList(),
// //     'history': history.map((r) => r.toMap()).toList(),
// //   };

// //   static TodState fromMap(Map<String, dynamic> m) {
// //     final rawScores = (m['scores'] as Map<String, dynamic>? ?? {});
// //     return TodState(
// //       snapshotAt: m['snapshot_at'] as int? ?? 0,
// //       playerOrder: (m['player_order'] as List?)?.cast<String>() ?? [],
// //       currentPlayerIndex: m['current_player_index'] as int? ?? 0,
// //       phase: TodTurnPhase.values.firstWhere(
// //         (p) => p.name == m['phase'],
// //         orElse: () => TodTurnPhase.choosingType,
// //       ),
// //       roundNumber: m['round_number'] as int? ?? 1,
// //       maxRounds: m['max_rounds'] as int? ?? 10,
// //       scores: rawScores.map(
// //         (k, v) =>
// //             MapEntry(k, TodPlayerScore.fromMap(v as Map<String, dynamic>)),
// //       ),
// //       currentCard: m['current_card'] != null
// //           ? TodCard.fromMap(m['current_card'] as Map<String, dynamic>)
// //           : null,
// //       currentPunishmentVote: m['current_punishment_vote'] != null
// //           ? TodPunishmentVoteState.fromMap(
// //               m['current_punishment_vote'] as Map<String, dynamic>,
// //             )
// //           : null,
// //       timerStartedAt: m['timer_started_at'] as int?,
// //       turnStartedAt: m['turn_started_at'] as int?,
// //       isOver: m['is_over'] as bool? ?? false,
// //       endReason: m['end_reason'] as String?,
// //       turnOrderMode: TurnOrderMode.values.firstWhere(
// //         (t) => t.name == m['turn_order_mode'],
// //         orElse: () => TurnOrderMode.circular,
// //       ),
// //       randomTurnQueue: (m['random_turn_queue'] as List?)?.cast<String>() ?? [],
// //       usedCardIds: (m['used_card_ids'] as List?)?.cast<String>() ?? [],
// //       turnResponse: m['turn_response'] as String? ?? '',
// //       turnProofUrl: m['turn_proof_url'] as String? ?? '',
// //       turnProofIsVideo: m['turn_proof_is_video'] as bool? ?? false,
// //       turnProofViewMode: TodProofViewMode.values.firstWhere(
// //         (v) => v.name == m['turn_proof_view_mode'],
// //         orElse: () => TodProofViewMode.once,
// //       ),
// //       turnProofViewSeconds: m['turn_proof_view_seconds'] as int? ?? 5,
// //       turnProofViewedBy:
// //           (m['turn_proof_viewed_by'] as List?)?.cast<String>() ?? [],
// //       currentReactions:
// //           (m['current_reactions'] as List?)
// //               ?.map((r) => TodReaction.fromMap(r as Map<String, dynamic>))
// //               .toList() ??
// //           [],
// //       currentVotes:
// //           (m['current_votes'] as List?)
// //               ?.map((v) => TodResponseVote.fromMap(v as Map<String, dynamic>))
// //               .toList() ??
// //           [],
// //       history:
// //           (m['history'] as List?)
// //               ?.map((r) => TodRoundRecord.fromMap(r as Map<String, dynamic>))
// //               .toList() ??
// //           [],
// //     );
// //   }
// // }

// // // ═══════════════════════════════════════════════════════════════════════════
// // // EVENTS  (player → owner via Broadcast)
// // // ═══════════════════════════════════════════════════════════════════════════

// // /// Player chose Truth or Dare.
// // class TodChoiceEvent extends GameEngineEvent {
// //   const TodChoiceEvent({
// //     required super.userId,
// //     required super.ts,
// //     required this.cardType,
// //   });
// //   final TodCardType cardType;
// // }

// // /// Player completed their turn (did the truth/dare).
// // class TodCompleteEvent extends GameEngineEvent {
// //   const TodCompleteEvent({
// //     required super.userId,
// //     required super.ts,
// //     this.response = '',
// //     this.proofUrl = '',
// //     this.proofIsVideo = false,
// //     this.proofViewMode = TodProofViewMode.once,
// //     this.proofViewSeconds = 5,
// //   });
// //   final String response;
// //   final String proofUrl;
// //   final bool proofIsVideo;
// //   final TodProofViewMode proofViewMode;
// //   final int proofViewSeconds;
// // }

// // /// A player has opened/watched the current turn's proof media.
// // class TodProofViewedEvent extends GameEngineEvent {
// //   const TodProofViewedEvent({required super.userId, required super.ts});
// // }

// // /// Player reacts to the current response with an emoji
// // class TodReactEvent extends GameEngineEvent {
// //   const TodReactEvent({
// //     required super.userId,
// //     required super.ts,
// //     required this.emoji,
// //   });
// //   final String emoji;
// // }

// // /// Player votes for the current response as best
// // class TodVoteResponseEvent extends GameEngineEvent {
// //   const TodVoteResponseEvent({required super.userId, required super.ts});
// // }

// // /// Player skipped their turn.
// // class TodSkipEvent extends GameEngineEvent {
// //   const TodSkipEvent({required super.userId, required super.ts});
// // }

// // /// Timer expired on the current player's turn.
// // class TodTimerExpiredEvent extends GameEngineEvent {
// //   const TodTimerExpiredEvent({
// //     required super.userId, // the timed-out player
// //     required super.ts,
// //   });
// // }

// // /// Moderator/owner proposed a punishment text.
// // class TodProposePunishmentEvent extends GameEngineEvent {
// //   const TodProposePunishmentEvent({
// //     required super.userId,
// //     required super.ts,
// //     required this.punishment,
// //   });
// //   final TodPunishment punishment;
// // }

// // /// A player voted on the current punishment.
// // class TodVotePunishmentEvent extends GameEngineEvent {
// //   const TodVotePunishmentEvent({
// //     required super.userId,
// //     required super.ts,
// //     required this.vote,
// //   });
// //   final TodPunishmentVote vote;
// // }

// // /// Moderator overrides the punishment vote.
// // class TodModeratorOverrideEvent extends GameEngineEvent {
// //   const TodModeratorOverrideEvent({
// //     required super.userId,
// //     required super.ts,
// //     required this.decision,
// //     this.replacementText,
// //   });
// //   final TodPunishmentVote decision;
// //   final String? replacementText;
// // }

// // /// Owner/mod manually ends the game.
// // class TodEndGameEvent extends GameEngineEvent {
// //   const TodEndGameEvent({
// //     required super.userId,
// //     required super.ts,
// //     this.reason = 'manual',
// //   });
// //   final String reason;
// // }

// import 'package:jma3a/features/games/engine/base_game_engine.dart';

// // ═══════════════════════════════════════════════════════════════════════════
// // ENUMS
// // ═══════════════════════════════════════════════════════════════════════════

// enum TodCardType { truth, dare }

// enum TodDifficulty { mild, medium, spicy }

// enum TodTurnPhase {
//   choosingType, // player picks Truth or Dare
//   readingCard, // card is visible, player performing
//   awaitingResult, // timer expired or player pressed Done/Skip
//   punishmentVoting, // skip happened → punishment vote in progress
//   awaitingNextTurn, // turn ended, waiting for owner to advance
// }

// enum TodPunishmentVote { doIt, dontDoIt, changePunishment }

// enum TodEndCondition { roundLimit, scoreLimit, manual }

// /// How a proof photo/video can be viewed by other players — Snapchat-style.
// enum TodProofViewMode {
//   once, // disappears the instant the viewer closes it — no second look
//   replayOnce, // can be reopened exactly one more time, then gone
//   timed, // shown for a fixed number of seconds, then auto-hides
// }

// /// Where the proof photo came from — drives the Snapchat-style colored
// /// badge: red for a live camera shot, blue for an uploaded gallery photo.
// enum TodProofSource { camera, gallery }

// // ═══════════════════════════════════════════════════════════════════════════
// // VALUE OBJECTS
// // ═══════════════════════════════════════════════════════════════════════════

// class TodCard {
//   const TodCard({
//     required this.id,
//     required this.content,
//     required this.type,
//     required this.difficulty,
//   });

//   final String id;
//   final String content;
//   final TodCardType type;
//   final TodDifficulty difficulty;

//   bool get isSpicy => difficulty == TodDifficulty.spicy;

//   Map<String, dynamic> toMap() => {
//     'id': id,
//     'content': content,
//     'type': type.name,
//     'difficulty': difficulty.name,
//   };

//   static TodCard fromMap(Map<String, dynamic> m) => TodCard(
//     id: m['id'] as String,
//     content: m['content'] as String,
//     type: TodCardType.values.firstWhere(
//       (t) => t.name == m['type'],
//       orElse: () => TodCardType.truth,
//     ),
//     difficulty: TodDifficulty.values.firstWhere(
//       (d) => d.name == m['difficulty'],
//       orElse: () => TodDifficulty.mild,
//     ),
//   );
// }

// /// A punishment proposal for a skipped turn.
// class TodPunishment {
//   const TodPunishment({
//     required this.id,
//     required this.text,
//     required this.proposedBy,
//     required this.proposedAt,
//   });

//   final String id;
//   final String text;
//   final String proposedBy; // userId
//   final int proposedAt; // epoch ms

//   Map<String, dynamic> toMap() => {
//     'id': id,
//     'text': text,
//     'proposed_by': proposedBy,
//     'proposed_at': proposedAt,
//   };

//   static TodPunishment fromMap(Map<String, dynamic> m) => TodPunishment(
//     id: m['id'] as String,
//     text: m['text'] as String,
//     proposedBy: m['proposed_by'] as String,
//     proposedAt: m['proposed_at'] as int,
//   );
// }

// /// Accumulated votes on a punishment proposal.
// class TodPunishmentVoteState {
//   const TodPunishmentVoteState({
//     required this.punishment,
//     required this.votes, // userId → vote
//     required this.totalVoters, // how many players can vote
//     this.moderatorOverride, // null = no override
//   });

//   final TodPunishment punishment;
//   final Map<String, TodPunishmentVote> votes;
//   final int totalVoters;
//   final TodPunishmentVote? moderatorOverride;

//   bool get hasOutcome => moderatorOverride != null || _majorityReached;

//   bool get _majorityReached {
//     if (votes.isEmpty) return false;
//     final majority = (totalVoters / 2).ceil();
//     final counts = <TodPunishmentVote, int>{};
//     for (final v in votes.values) {
//       counts[v] = (counts[v] ?? 0) + 1;
//     }
//     return counts.values.any((c) => c >= majority);
//   }

//   TodPunishmentVote? get resolvedVote {
//     if (moderatorOverride != null) return moderatorOverride;
//     if (!_majorityReached) return null;
//     final counts = <TodPunishmentVote, int>{};
//     for (final v in votes.values) {
//       counts[v] = (counts[v] ?? 0) + 1;
//     }
//     return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
//   }

//   Map<String, dynamic> toMap() => {
//     'punishment': punishment.toMap(),
//     'votes': votes.map((k, v) => MapEntry(k, v.name)),
//     'total_voters': totalVoters,
//     'moderator_override': moderatorOverride?.name,
//   };

//   static TodPunishmentVoteState fromMap(Map<String, dynamic> m) =>
//       TodPunishmentVoteState(
//         punishment: TodPunishment.fromMap(
//           m['punishment'] as Map<String, dynamic>,
//         ),
//         votes: (m['votes'] as Map<String, dynamic>? ?? {}).map(
//           (k, v) => MapEntry(
//             k,
//             TodPunishmentVote.values.firstWhere(
//               (e) => e.name == v,
//               orElse: () => TodPunishmentVote.doIt,
//             ),
//           ),
//         ),
//         totalVoters: m['total_voters'] as int? ?? 0,
//         moderatorOverride: m['moderator_override'] != null
//             ? TodPunishmentVote.values.firstWhere(
//                 (e) => e.name == m['moderator_override'],
//                 orElse: () => TodPunishmentVote.doIt,
//               )
//             : null,
//       );
// }

// /// Per-player scores tracked across turns.
// class TodPlayerScore {
//   const TodPlayerScore({
//     required this.userId,
//     this.completedTruths = 0,
//     this.completedDares = 0,
//     this.skips = 0,
//     this.punishmentsReceived = 0,
//     this.points = 0,
//   });

//   final String userId;
//   final int completedTruths;
//   final int completedDares;
//   final int skips;
//   final int punishmentsReceived;
//   final int points; // configurable scoring

//   int get totalCompleted => completedTruths + completedDares;

//   TodPlayerScore copyWith({
//     int? completedTruths,
//     int? completedDares,
//     int? skips,
//     int? punishmentsReceived,
//     int? points,
//   }) => TodPlayerScore(
//     userId: userId,
//     completedTruths: completedTruths ?? this.completedTruths,
//     completedDares: completedDares ?? this.completedDares,
//     skips: skips ?? this.skips,
//     punishmentsReceived: punishmentsReceived ?? this.punishmentsReceived,
//     points: points ?? this.points,
//   );

//   Map<String, dynamic> toMap() => {
//     'user_id': userId,
//     'completed_truths': completedTruths,
//     'completed_dares': completedDares,
//     'skips': skips,
//     'punishments_received': punishmentsReceived,
//     'points': points,
//   };

//   static TodPlayerScore fromMap(Map<String, dynamic> m) => TodPlayerScore(
//     userId: m['user_id'] as String,
//     completedTruths: m['completed_truths'] as int? ?? 0,
//     completedDares: m['completed_dares'] as int? ?? 0,
//     skips: m['skips'] as int? ?? 0,
//     punishmentsReceived: m['punishments_received'] as int? ?? 0,
//     points: m['points'] as int? ?? 0,
//   );
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // GAME STATE
// // ═══════════════════════════════════════════════════════════════════════════

// // ── Round history ─────────────────────────────────────────────────────────────

// class TodReaction {
//   const TodReaction({
//     required this.userId,
//     required this.emoji,
//     required this.ts,
//   });
//   final String userId;
//   final String emoji;
//   final int ts;
//   Map<String, dynamic> toMap() => {'user_id': userId, 'emoji': emoji, 'ts': ts};
//   static TodReaction fromMap(Map<String, dynamic> m) => TodReaction(
//     userId: m['user_id'] as String,
//     emoji: m['emoji'] as String,
//     ts: m['ts'] as int? ?? 0,
//   );
// }

// class TodResponseVote {
//   const TodResponseVote({required this.voterId, required this.ts});
//   final String voterId;
//   final int ts;
//   Map<String, dynamic> toMap() => {'voter_id': voterId, 'ts': ts};
//   static TodResponseVote fromMap(Map<String, dynamic> m) => TodResponseVote(
//     voterId: m['voter_id'] as String,
//     ts: m['ts'] as int? ?? 0,
//   );
// }

// class TodRoundRecord {
//   const TodRoundRecord({
//     required this.roundNumber,
//     required this.playerId,
//     required this.card,
//     required this.response,
//     this.hadProof = false,
//     this.proofWatchedBy = const [],
//     this.reactions = const [],
//     this.votes = const [],
//   });
//   final int roundNumber;
//   final String playerId;
//   final TodCard? card;
//   final String response;
//   // ✅ History NEVER stores the actual proof photo — only whether one
//   // existed and who watched it. The media itself lives only on
//   // TodState.turnProofImageB64 during the live turn, and is discarded once
//   // the turn advances (per the Snapchat-style ephemeral viewing
//   // requirement).
//   final bool hadProof;
//   final List<String> proofWatchedBy;
//   final List<TodReaction> reactions;
//   final List<TodResponseVote> votes;

//   int get voteCount => votes.length;

//   Map<String, dynamic> toMap() => {
//     'round_number': roundNumber,
//     'player_id': playerId,
//     'card': card?.toMap(),
//     'response': response,
//     'had_proof': hadProof,
//     'proof_watched_by': proofWatchedBy,
//     'reactions': reactions.map((r) => r.toMap()).toList(),
//     'votes': votes.map((v) => v.toMap()).toList(),
//   };

//   static TodRoundRecord fromMap(Map<String, dynamic> m) => TodRoundRecord(
//     roundNumber: m['round_number'] as int? ?? 0,
//     playerId: m['player_id'] as String,
//     card: m['card'] != null
//         ? TodCard.fromMap(m['card'] as Map<String, dynamic>)
//         : null,
//     response: m['response'] as String? ?? '',
//     hadProof: m['had_proof'] as bool? ?? false,
//     proofWatchedBy: (m['proof_watched_by'] as List?)?.cast<String>() ?? [],
//     reactions:
//         (m['reactions'] as List?)
//             ?.map((r) => TodReaction.fromMap(r as Map<String, dynamic>))
//             .toList() ??
//         [],
//     votes:
//         (m['votes'] as List?)
//             ?.map((v) => TodResponseVote.fromMap(v as Map<String, dynamic>))
//             .toList() ??
//         [],
//   );

//   TodRoundRecord copyWith({
//     List<String>? proofWatchedBy,
//     List<TodReaction>? reactions,
//     List<TodResponseVote>? votes,
//   }) => TodRoundRecord(
//     roundNumber: roundNumber,
//     playerId: playerId,
//     card: card,
//     response: response,
//     hadProof: hadProof,
//     proofWatchedBy: proofWatchedBy ?? this.proofWatchedBy,
//     reactions: reactions ?? this.reactions,
//     votes: votes ?? this.votes,
//   );
// }

// class TodState extends GameEngineState {
//   const TodState({
//     required super.snapshotAt,
//     required this.playerOrder,
//     required this.currentPlayerIndex,
//     required this.phase,
//     required this.roundNumber,
//     required this.maxRounds,
//     required this.scores,
//     this.currentCard,
//     this.currentPunishmentVote,
//     this.timerStartedAt,
//     this.turnStartedAt,
//     this.isOver = false,
//     this.endReason,
//     this.turnOrderMode = TurnOrderMode.circular,
//     this.randomTurnQueue = const [],
//     this.usedCardIds = const [],
//     this.turnResponse = '',
//     this.turnProofImageB64 = '',
//     this.turnProofSource = TodProofSource.camera,
//     this.turnProofViewMode = TodProofViewMode.once,
//     this.turnProofViewSeconds = 5,
//     this.turnProofViewedBy = const [],
//     this.currentReactions = const [],
//     this.currentVotes = const [],
//     this.history = const [],
//   });

//   final List<String> playerOrder;
//   final int currentPlayerIndex;
//   final TodTurnPhase phase;
//   final int roundNumber;
//   final int maxRounds;
//   final Map<String, TodPlayerScore> scores; // userId → score
//   final TodCard? currentCard;
//   final TodPunishmentVoteState? currentPunishmentVote;
//   final int? timerStartedAt; // epoch ms when timer started
//   final int? turnStartedAt; // epoch ms when turn began
//   final bool isOver;
//   final String? endReason;
//   final TurnOrderMode turnOrderMode;
//   final List<String> randomTurnQueue; // pre-shuffled for random mode
//   final List<String> usedCardIds; // prevents re-dealing same card
//   final String turnResponse; // player's text response
//   // Live proof photo for the CURRENT turn only — cleared by advanceTurn().
//   // Never persisted into history; see TodRoundRecord.hadProof/proofWatchedBy.
//   // Travels as base64 inline over the realtime broadcast channel.
//   final String turnProofImageB64;
//   // Camera (live shot) vs gallery (uploaded) — drives the red/blue badge.
//   final TodProofSource turnProofSource;
//   final TodProofViewMode turnProofViewMode;
//   final int turnProofViewSeconds; // used when turnProofViewMode == timed
//   final List<String> turnProofViewedBy;
//   final List<TodReaction> currentReactions; // reactions to current turn
//   final List<TodResponseVote> currentVotes; // votes for current response
//   final List<TodRoundRecord> history; // completed rounds

//   String get currentPlayerId => playerOrder.isEmpty
//       ? ''
//       : playerOrder[currentPlayerIndex % playerOrder.length];

//   bool get isInPunishmentPhase => phase == TodTurnPhase.punishmentVoting;

//   bool get turnHasProof => turnProofImageB64.isNotEmpty;

//   bool get isCurrentUsersTurn => false; // evaluated by provider with userId

//   List<TodPlayerScore> get sortedScores {
//     final list = scores.values.toList();
//     list.sort((a, b) => b.points.compareTo(a.points));
//     return list;
//   }

//   TodState copyWith({
//     int? snapshotAt,
//     int? currentPlayerIndex,
//     TodTurnPhase? phase,
//     int? roundNumber,
//     Map<String, TodPlayerScore>? scores,
//     TodCard? Function()? currentCard,
//     TodPunishmentVoteState? Function()? currentPunishmentVote,
//     int? Function()? timerStartedAt,
//     int? Function()? turnStartedAt,
//     bool? isOver,
//     String? endReason,
//     List<String>? randomTurnQueue,
//     List<String>? usedCardIds,
//     String? turnResponse,
//     String? turnProofImageB64,
//     TodProofSource? turnProofSource,
//     TodProofViewMode? turnProofViewMode,
//     int? turnProofViewSeconds,
//     List<String>? turnProofViewedBy,
//     List<TodReaction>? currentReactions,
//     List<TodResponseVote>? currentVotes,
//     List<TodRoundRecord>? history,
//   }) => TodState(
//     snapshotAt: snapshotAt ?? this.snapshotAt,
//     playerOrder: playerOrder,
//     currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
//     phase: phase ?? this.phase,
//     roundNumber: roundNumber ?? this.roundNumber,
//     maxRounds: maxRounds,
//     scores: scores ?? this.scores,
//     currentCard: currentCard != null ? currentCard() : this.currentCard,
//     currentPunishmentVote: currentPunishmentVote != null
//         ? currentPunishmentVote()
//         : this.currentPunishmentVote,
//     timerStartedAt: timerStartedAt != null
//         ? timerStartedAt()
//         : this.timerStartedAt,
//     turnStartedAt: turnStartedAt != null ? turnStartedAt() : this.turnStartedAt,
//     isOver: isOver ?? this.isOver,
//     endReason: endReason ?? this.endReason,
//     turnOrderMode: turnOrderMode,
//     randomTurnQueue: randomTurnQueue ?? this.randomTurnQueue,
//     usedCardIds: usedCardIds ?? this.usedCardIds,
//     turnResponse: turnResponse ?? this.turnResponse,
//     turnProofImageB64: turnProofImageB64 ?? this.turnProofImageB64,
//     turnProofSource: turnProofSource ?? this.turnProofSource,
//     turnProofViewMode: turnProofViewMode ?? this.turnProofViewMode,
//     turnProofViewSeconds: turnProofViewSeconds ?? this.turnProofViewSeconds,
//     turnProofViewedBy: turnProofViewedBy ?? this.turnProofViewedBy,
//     currentReactions: currentReactions ?? this.currentReactions,
//     currentVotes: currentVotes ?? this.currentVotes,
//     history: history ?? this.history,
//   );

//   Map<String, dynamic> toMap() => {
//     'snapshot_at': snapshotAt,
//     'player_order': playerOrder,
//     'current_player_index': currentPlayerIndex,
//     'phase': phase.name,
//     'round_number': roundNumber,
//     'max_rounds': maxRounds,
//     'scores': scores.map((k, v) => MapEntry(k, v.toMap())),
//     'current_card': currentCard?.toMap(),
//     'current_punishment_vote': currentPunishmentVote?.toMap(),
//     'timer_started_at': timerStartedAt,
//     'turn_started_at': turnStartedAt,
//     'is_over': isOver,
//     'end_reason': endReason,
//     'turn_order_mode': turnOrderMode.name,
//     'random_turn_queue': randomTurnQueue,
//     'used_card_ids': usedCardIds,
//     'turn_response': turnResponse,
//     'turn_proof_image': turnProofImageB64,
//     'turn_proof_source': turnProofSource.name,
//     'turn_proof_view_mode': turnProofViewMode.name,
//     'turn_proof_view_seconds': turnProofViewSeconds,
//     'turn_proof_viewed_by': turnProofViewedBy,
//     'current_reactions': currentReactions.map((r) => r.toMap()).toList(),
//     'current_votes': currentVotes.map((v) => v.toMap()).toList(),
//     'history': history.map((r) => r.toMap()).toList(),
//   };

//   static TodState fromMap(Map<String, dynamic> m) {
//     final rawScores = (m['scores'] as Map<String, dynamic>? ?? {});
//     return TodState(
//       snapshotAt: m['snapshot_at'] as int? ?? 0,
//       playerOrder: (m['player_order'] as List?)?.cast<String>() ?? [],
//       currentPlayerIndex: m['current_player_index'] as int? ?? 0,
//       phase: TodTurnPhase.values.firstWhere(
//         (p) => p.name == m['phase'],
//         orElse: () => TodTurnPhase.choosingType,
//       ),
//       roundNumber: m['round_number'] as int? ?? 1,
//       maxRounds: m['max_rounds'] as int? ?? 10,
//       scores: rawScores.map(
//         (k, v) =>
//             MapEntry(k, TodPlayerScore.fromMap(v as Map<String, dynamic>)),
//       ),
//       currentCard: m['current_card'] != null
//           ? TodCard.fromMap(m['current_card'] as Map<String, dynamic>)
//           : null,
//       currentPunishmentVote: m['current_punishment_vote'] != null
//           ? TodPunishmentVoteState.fromMap(
//               m['current_punishment_vote'] as Map<String, dynamic>,
//             )
//           : null,
//       timerStartedAt: m['timer_started_at'] as int?,
//       turnStartedAt: m['turn_started_at'] as int?,
//       isOver: m['is_over'] as bool? ?? false,
//       endReason: m['end_reason'] as String?,
//       turnOrderMode: TurnOrderMode.values.firstWhere(
//         (t) => t.name == m['turn_order_mode'],
//         orElse: () => TurnOrderMode.circular,
//       ),
//       randomTurnQueue: (m['random_turn_queue'] as List?)?.cast<String>() ?? [],
//       usedCardIds: (m['used_card_ids'] as List?)?.cast<String>() ?? [],
//       turnResponse: m['turn_response'] as String? ?? '',
//       turnProofImageB64: m['turn_proof_image'] as String? ?? '',
//       turnProofSource: TodProofSource.values.firstWhere(
//         (s) => s.name == m['turn_proof_source'],
//         orElse: () => TodProofSource.camera,
//       ),
//       turnProofViewMode: TodProofViewMode.values.firstWhere(
//         (v) => v.name == m['turn_proof_view_mode'],
//         orElse: () => TodProofViewMode.once,
//       ),
//       turnProofViewSeconds: m['turn_proof_view_seconds'] as int? ?? 5,
//       turnProofViewedBy:
//           (m['turn_proof_viewed_by'] as List?)?.cast<String>() ?? [],
//       currentReactions:
//           (m['current_reactions'] as List?)
//               ?.map((r) => TodReaction.fromMap(r as Map<String, dynamic>))
//               .toList() ??
//           [],
//       currentVotes:
//           (m['current_votes'] as List?)
//               ?.map((v) => TodResponseVote.fromMap(v as Map<String, dynamic>))
//               .toList() ??
//           [],
//       history:
//           (m['history'] as List?)
//               ?.map((r) => TodRoundRecord.fromMap(r as Map<String, dynamic>))
//               .toList() ??
//           [],
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // EVENTS  (player → owner via Broadcast)
// // ═══════════════════════════════════════════════════════════════════════════

// /// Player chose Truth or Dare.
// class TodChoiceEvent extends GameEngineEvent {
//   const TodChoiceEvent({
//     required super.userId,
//     required super.ts,
//     required this.cardType,
//   });
//   final TodCardType cardType;
// }

// /// Player completed their turn (did the truth/dare).
// class TodCompleteEvent extends GameEngineEvent {
//   const TodCompleteEvent({
//     required super.userId,
//     required super.ts,
//     this.response = '',
//     this.proofImageB64 = '',
//     this.proofSource = TodProofSource.camera,
//     this.proofViewMode = TodProofViewMode.once,
//     this.proofViewSeconds = 5,
//   });
//   final String response;
//   final String proofImageB64;
//   final TodProofSource proofSource;
//   final TodProofViewMode proofViewMode;
//   final int proofViewSeconds;
// }

// /// A player has opened/watched the current turn's proof media.
// class TodProofViewedEvent extends GameEngineEvent {
//   const TodProofViewedEvent({required super.userId, required super.ts});
// }

// /// Player reacts to the current response with an emoji
// class TodReactEvent extends GameEngineEvent {
//   const TodReactEvent({
//     required super.userId,
//     required super.ts,
//     required this.emoji,
//   });
//   final String emoji;
// }

// /// Player votes for the current response as best
// class TodVoteResponseEvent extends GameEngineEvent {
//   const TodVoteResponseEvent({required super.userId, required super.ts});
// }

// /// Player skipped their turn.
// class TodSkipEvent extends GameEngineEvent {
//   const TodSkipEvent({required super.userId, required super.ts});
// }

// /// Timer expired on the current player's turn.
// class TodTimerExpiredEvent extends GameEngineEvent {
//   const TodTimerExpiredEvent({
//     required super.userId, // the timed-out player
//     required super.ts,
//   });
// }

// /// Moderator/owner proposed a punishment text.
// class TodProposePunishmentEvent extends GameEngineEvent {
//   const TodProposePunishmentEvent({
//     required super.userId,
//     required super.ts,
//     required this.punishment,
//   });
//   final TodPunishment punishment;
// }

// /// A player voted on the current punishment.
// class TodVotePunishmentEvent extends GameEngineEvent {
//   const TodVotePunishmentEvent({
//     required super.userId,
//     required super.ts,
//     required this.vote,
//   });
//   final TodPunishmentVote vote;
// }

// /// Moderator overrides the punishment vote.
// class TodModeratorOverrideEvent extends GameEngineEvent {
//   const TodModeratorOverrideEvent({
//     required super.userId,
//     required super.ts,
//     required this.decision,
//     this.replacementText,
//   });
//   final TodPunishmentVote decision;
//   final String? replacementText;
// }

// /// Owner/mod manually ends the game.
// class TodEndGameEvent extends GameEngineEvent {
//   const TodEndGameEvent({
//     required super.userId,
//     required super.ts,
//     this.reason = 'manual',
//   });
//   final String reason;
// }

import 'package:jma3a/features/games/engine/base_game_engine.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════

enum TodCardType { truth, dare }

enum TodDifficulty { mild, medium, spicy }

enum TodTurnPhase {
  choosingType, // player picks Truth or Dare
  readingCard, // card is visible, player performing
  awaitingResult, // timer expired or player pressed Done/Skip
  punishmentVoting, // skip happened → punishment vote in progress
  awaitingNextTurn, // turn ended, waiting for owner to advance
}

enum TodEndCondition { roundLimit, scoreLimit, manual }

/// How a proof photo/video can be viewed by other players — Snapchat-style.
enum TodProofViewMode {
  once, // disappears the instant the viewer closes it — no second look
  replayOnce, // can be reopened exactly one more time, then gone
  timed, // shown for a fixed number of seconds, then auto-hides
}

/// Where the proof photo came from — drives the Snapchat-style colored
/// badge: red for a live camera shot, blue for an uploaded gallery photo.
enum TodProofSource { camera, gallery, voice }

// ── Proof voting ──────────────────────────────────────────────────────────────
/// What players vote for during the 10-second proof-requirement vote.
enum TodProofVoteOption { voiceProof, imageProof, noPreference }

/// Active proof-requirement vote state — lives on TodState while voting is
/// happening, cleared once the 10 s window closes or all players have voted.
class TodProofVoteState {
  const TodProofVoteState({required this.startedAt, this.votes = const {}});
  final int startedAt; // epoch ms
  final Map<String, TodProofVoteOption> votes; // userId → vote

  /// Returns the winning option, or null if no majority (all equal).
  TodProofVoteOption? get winner {
    if (votes.isEmpty) return null;
    final counts = <TodProofVoteOption, int>{};
    for (final v in votes.values) {
      counts[v] = (counts[v] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.length >= 2 && sorted[0].value == sorted[1].value) return null;
    return sorted.first.key;
  }

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch - startedAt > 10000;

  Map<String, dynamic> toMap() => {
    'started_at': startedAt,
    'votes': votes.map((k, v) => MapEntry(k, v.name)),
  };

  static TodProofVoteState fromMap(Map<String, dynamic> m) => TodProofVoteState(
    startedAt: m['started_at'] as int? ?? 0,
    votes: (m['votes'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(
        k,
        TodProofVoteOption.values.firstWhere(
          (e) => e.name == v,
          orElse: () => TodProofVoteOption.noPreference,
        ),
      ),
    ),
  );

  TodProofVoteState copyWithVote(String userId, TodProofVoteOption option) =>
      TodProofVoteState(
        startedAt: startedAt,
        votes: {...votes, userId: option},
      );
}

// ── Proof visibility ──────────────────────────────────────────────────────────
/// Who can see the proof after the player submits it. `playersOnly` and
/// `spectatorsOnly` are the room-owner-configurable policy presets;
/// `selectedPlayers` is a separate, more granular per-turn custom picker
/// (unrelated to the room setting) kept for any future use.
enum TodProofVisibility { everyone, playersOnly, spectatorsOnly, selectedPlayers }

class TodProofVisibilitySettings {
  const TodProofVisibilitySettings({
    this.visibility = TodProofVisibility.everyone,
    this.allowSpectators = true,
    this.visibleToIds = const [],
  });
  final TodProofVisibility visibility;

  /// Only meaningful when visibility == everyone — playersOnly/
  /// spectatorsOnly already fully determine spectator access on their own.
  final bool allowSpectators;

  /// Only used when visibility == selectedPlayers.
  final List<String> visibleToIds;

  bool canView(String userId, bool isSpectator) => switch (visibility) {
    TodProofVisibility.everyone => !isSpectator || allowSpectators,
    TodProofVisibility.playersOnly => !isSpectator,
    TodProofVisibility.spectatorsOnly => isSpectator,
    TodProofVisibility.selectedPlayers => visibleToIds.contains(userId),
  };

  Map<String, dynamic> toMap() => {
    'visibility': visibility.name,
    'allow_spectators': allowSpectators,
    'visible_to_ids': visibleToIds,
  };

  static TodProofVisibilitySettings fromMap(Map<String, dynamic> m) =>
      TodProofVisibilitySettings(
        visibility: TodProofVisibility.values.firstWhere(
          (v) => v.name == m['visibility'],
          orElse: () => TodProofVisibility.everyone,
        ),
        allowSpectators: m['allow_spectators'] as bool? ?? true,
        visibleToIds:
            (m['visible_to_ids'] as List?)?.cast<String>() ?? const [],
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// VALUE OBJECTS
// ═══════════════════════════════════════════════════════════════════════════

class TodCard {
  const TodCard({
    required this.id,
    required this.content,
    required this.type,
    required this.difficulty,
  });

  final String id;
  final String content;
  final TodCardType type;
  final TodDifficulty difficulty;

  bool get isSpicy => difficulty == TodDifficulty.spicy;

  Map<String, dynamic> toMap() => {
    'id': id,
    'content': content,
    'type': type.name,
    'difficulty': difficulty.name,
  };

  static TodCard fromMap(Map<String, dynamic> m) => TodCard(
    id: m['id'] as String,
    content: m['content'] as String,
    type: TodCardType.values.firstWhere(
      (t) => t.name == m['type'],
      orElse: () => TodCardType.truth,
    ),
    difficulty: TodDifficulty.values.firstWhere(
      (d) => d.name == m['difficulty'],
      orElse: () => TodDifficulty.mild,
    ),
  );
}

/// A punishment proposal for a skipped turn.
class TodPunishment {
  const TodPunishment({
    required this.id,
    required this.text,
    required this.proposedBy,
    required this.proposedAt,
  });

  final String id;
  final String text;
  final String proposedBy; // userId
  final int proposedAt; // epoch ms

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'proposed_by': proposedBy,
    'proposed_at': proposedAt,
  };

  static TodPunishment fromMap(Map<String, dynamic> m) => TodPunishment(
    id: m['id'] as String,
    text: m['text'] as String,
    proposedBy: m['proposed_by'] as String,
    proposedAt: m['proposed_at'] as int,
  );
}

/// Every player except the skipped one submits exactly one punishment
/// option; once every expected submission is in, the *skipped player*
/// (not a group vote) picks whichever one they'll do. A moderator can
/// force-resolve on the skipped player's behalf if they go unresponsive.
/// There is no "don't do it" outcome — punishment can never be skipped or
/// bypassed, only *which* specific punishment gets picked can vary.
class TodPunishmentVoteState {
  const TodPunishmentVoteState({
    required this.options,
    required this.expectedSubmissions,
    this.moderatorOverrideOptionId, // null = no override
  });

  /// One per submitting player, grows as each of them submits — order is
  /// submission order, not display order.
  final List<TodPunishment> options;
  /// playerOrder.length - 1 (every player except the skipped one).
  final int expectedSubmissions;
  final String? moderatorOverrideOptionId;

  bool get submissionsComplete => options.length >= expectedSubmissions;

  Map<String, dynamic> toMap() => {
    'options': options.map((o) => o.toMap()).toList(),
    'expected_submissions': expectedSubmissions,
    'moderator_override_option_id': moderatorOverrideOptionId,
  };

  static TodPunishmentVoteState fromMap(Map<String, dynamic> m) =>
      TodPunishmentVoteState(
        options: (m['options'] as List<dynamic>? ?? [])
            .map((o) => TodPunishment.fromMap(o as Map<String, dynamic>))
            .toList(),
        expectedSubmissions: m['expected_submissions'] as int? ?? 0,
        moderatorOverrideOptionId:
            m['moderator_override_option_id'] as String?,
      );
}

/// Per-player scores tracked across turns.
class TodPlayerScore {
  const TodPlayerScore({
    required this.userId,
    this.completedTruths = 0,
    this.completedDares = 0,
    this.skips = 0,
    this.punishmentsReceived = 0,
    this.points = 0,
  });

  final String userId;
  final int completedTruths;
  final int completedDares;
  final int skips;
  final int punishmentsReceived;
  final int points; // configurable scoring

  int get totalCompleted => completedTruths + completedDares;

  TodPlayerScore copyWith({
    int? completedTruths,
    int? completedDares,
    int? skips,
    int? punishmentsReceived,
    int? points,
  }) => TodPlayerScore(
    userId: userId,
    completedTruths: completedTruths ?? this.completedTruths,
    completedDares: completedDares ?? this.completedDares,
    skips: skips ?? this.skips,
    punishmentsReceived: punishmentsReceived ?? this.punishmentsReceived,
    points: points ?? this.points,
  );

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'completed_truths': completedTruths,
    'completed_dares': completedDares,
    'skips': skips,
    'punishments_received': punishmentsReceived,
    'points': points,
  };

  static TodPlayerScore fromMap(Map<String, dynamic> m) => TodPlayerScore(
    userId: m['user_id'] as String,
    completedTruths: m['completed_truths'] as int? ?? 0,
    completedDares: m['completed_dares'] as int? ?? 0,
    skips: m['skips'] as int? ?? 0,
    punishmentsReceived: m['punishments_received'] as int? ?? 0,
    points: m['points'] as int? ?? 0,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// GAME STATE
// ═══════════════════════════════════════════════════════════════════════════

// ── Round history ─────────────────────────────────────────────────────────────

class TodReaction {
  const TodReaction({
    required this.userId,
    required this.emoji,
    required this.ts,
  });
  final String userId;
  final String emoji;
  final int ts;
  Map<String, dynamic> toMap() => {'user_id': userId, 'emoji': emoji, 'ts': ts};
  static TodReaction fromMap(Map<String, dynamic> m) => TodReaction(
    userId: m['user_id'] as String,
    emoji: m['emoji'] as String,
    ts: m['ts'] as int? ?? 0,
  );
}

class TodResponseVote {
  const TodResponseVote({required this.voterId, required this.ts});
  final String voterId;
  final int ts;
  Map<String, dynamic> toMap() => {'voter_id': voterId, 'ts': ts};
  static TodResponseVote fromMap(Map<String, dynamic> m) => TodResponseVote(
    voterId: m['voter_id'] as String,
    ts: m['ts'] as int? ?? 0,
  );
}

class TodRoundRecord {
  const TodRoundRecord({
    required this.roundNumber,
    required this.playerId,
    required this.card,
    required this.response,
    this.hadProof = false,
    this.proofWatchedBy = const [],
    this.reactions = const [],
    this.votes = const [],
  });
  final int roundNumber;
  final String playerId;
  final TodCard? card;
  final String response;
  // ✅ History NEVER stores the actual proof photo — only whether one
  // existed and who watched it. The media itself lives only on
  // TodState.turnProofImageB64 during the live turn, and is discarded once
  // the turn advances (per the Snapchat-style ephemeral viewing
  // requirement).
  final bool hadProof;
  final List<String> proofWatchedBy;
  final List<TodReaction> reactions;
  final List<TodResponseVote> votes;

  int get voteCount => votes.length;

  Map<String, dynamic> toMap() => {
    'round_number': roundNumber,
    'player_id': playerId,
    'card': card?.toMap(),
    'response': response,
    'had_proof': hadProof,
    'proof_watched_by': proofWatchedBy,
    'reactions': reactions.map((r) => r.toMap()).toList(),
    'votes': votes.map((v) => v.toMap()).toList(),
  };

  static TodRoundRecord fromMap(Map<String, dynamic> m) => TodRoundRecord(
    roundNumber: m['round_number'] as int? ?? 0,
    playerId: m['player_id'] as String,
    card: m['card'] != null
        ? TodCard.fromMap(m['card'] as Map<String, dynamic>)
        : null,
    response: m['response'] as String? ?? '',
    hadProof: m['had_proof'] as bool? ?? false,
    proofWatchedBy: (m['proof_watched_by'] as List?)?.cast<String>() ?? [],
    reactions:
        (m['reactions'] as List?)
            ?.map((r) => TodReaction.fromMap(r as Map<String, dynamic>))
            .toList() ??
        [],
    votes:
        (m['votes'] as List?)
            ?.map((v) => TodResponseVote.fromMap(v as Map<String, dynamic>))
            .toList() ??
        [],
  );

  TodRoundRecord copyWith({
    List<String>? proofWatchedBy,
    List<TodReaction>? reactions,
    List<TodResponseVote>? votes,
  }) => TodRoundRecord(
    roundNumber: roundNumber,
    playerId: playerId,
    card: card,
    response: response,
    hadProof: hadProof,
    proofWatchedBy: proofWatchedBy ?? this.proofWatchedBy,
    reactions: reactions ?? this.reactions,
    votes: votes ?? this.votes,
  );
}

class TodState extends GameEngineState {
  const TodState({
    required super.snapshotAt,
    required this.playerOrder,
    required this.currentPlayerIndex,
    required this.phase,
    required this.roundNumber,
    required this.maxRounds,
    required this.scores,
    this.currentCard,
    this.currentPunishmentVote,
    this.timerStartedAt,
    this.timerPausedAt,
    this.turnStartedAt,
    this.isOver = false,
    this.endReason,
    this.turnOrderMode = TurnOrderMode.circular,
    this.randomTurnQueue = const [],
    this.usedCardIds = const [],
    this.turnResponse = '',
    this.turnProofImageB64 = '',
    this.turnProofVoiceB64 = '',
    this.turnProofSource = TodProofSource.camera,
    this.turnProofViewMode = TodProofViewMode.once,
    this.turnProofViewSeconds = 5,
    this.turnProofViewedBy = const {},
    this.turnProofVisibility = const TodProofVisibilitySettings(),
    this.proofVoteState,
    this.currentReactions = const [],
    this.currentVotes = const [],
    this.history = const [],
  });

  final List<String> playerOrder;
  final int currentPlayerIndex;
  final TodTurnPhase phase;
  final int roundNumber;
  final int maxRounds;
  final Map<String, TodPlayerScore> scores; // userId → score
  final TodCard? currentCard;
  final TodPunishmentVoteState? currentPunishmentVote;
  final int? timerStartedAt; // epoch ms when timer started
  // Non-null while the timer is paused (e.g. player is performing their
  // truth/dare). Synced via canonical state so every client — including
  // spectators and late (re)joiners — sees the same paused/running state.
  final int? timerPausedAt;
  final int? turnStartedAt; // epoch ms when turn began
  final bool isOver;
  final String? endReason;
  final TurnOrderMode turnOrderMode;
  final List<String> randomTurnQueue; // pre-shuffled for random mode
  final List<String> usedCardIds; // prevents re-dealing same card
  final String turnResponse; // player's text response
  // Live proof photo for the CURRENT turn only — cleared by advanceTurn().
  // Never persisted into history; see TodRoundRecord.hadProof/proofWatchedBy.
  // Travels as base64 inline over the realtime broadcast channel.
  // Live proof for the CURRENT turn only — cleared by advanceTurn().
  // Image travels as base64 over broadcast; voice same approach.
  final String turnProofImageB64;
  final String turnProofVoiceB64; // Opus/AAC base64 voice memo
  // Camera (live shot) vs gallery (uploaded) vs voice — drives badge colour.
  final TodProofSource turnProofSource;
  final TodProofViewMode turnProofViewMode;
  final int turnProofViewSeconds; // used when turnProofViewMode == timed
  /// userId → open-count (premium: up to 3; standard: mode limits apply).
  final Map<String, int> turnProofViewedBy;
  final TodProofVisibilitySettings turnProofVisibility;

  /// Non-null while the 10-second proof-requirement vote is active.
  final TodProofVoteState? proofVoteState;
  final List<TodReaction> currentReactions; // reactions to current turn
  final List<TodResponseVote> currentVotes; // votes for current response
  final List<TodRoundRecord> history; // completed rounds

  String get currentPlayerId => playerOrder.isEmpty
      ? ''
      : playerOrder[currentPlayerIndex % playerOrder.length];

  bool get isInPunishmentPhase => phase == TodTurnPhase.punishmentVoting;

  bool get turnHasProof =>
      turnProofImageB64.isNotEmpty || turnProofVoiceB64.isNotEmpty;
  bool get turnHasVoiceProof => turnProofVoiceB64.isNotEmpty;
  bool get turnHasImageProof => turnProofImageB64.isNotEmpty;
  bool get isInProofVote =>
      proofVoteState != null && !proofVoteState!.isExpired;

  bool get isCurrentUsersTurn => false; // evaluated by provider with userId

  List<TodPlayerScore> get sortedScores {
    final list = scores.values.toList();
    list.sort((a, b) => b.points.compareTo(a.points));
    return list;
  }

  TodState copyWith({
    int? snapshotAt,
    int? currentPlayerIndex,
    TodTurnPhase? phase,
    int? roundNumber,
    Map<String, TodPlayerScore>? scores,
    TodCard? Function()? currentCard,
    TodPunishmentVoteState? Function()? currentPunishmentVote,
    int? Function()? timerStartedAt,
    int? Function()? timerPausedAt,
    int? Function()? turnStartedAt,
    bool? isOver,
    String? endReason,
    List<String>? randomTurnQueue,
    List<String>? usedCardIds,
    String? turnResponse,
    String? turnProofImageB64,
    String? turnProofVoiceB64,
    TodProofSource? turnProofSource,
    TodProofViewMode? turnProofViewMode,
    int? turnProofViewSeconds,
    Map<String, int>? turnProofViewedBy,
    TodProofVisibilitySettings? turnProofVisibility,
    TodProofVoteState? Function()? proofVoteState,
    List<TodReaction>? currentReactions,
    List<TodResponseVote>? currentVotes,
    List<TodRoundRecord>? history,
  }) => TodState(
    snapshotAt: snapshotAt ?? this.snapshotAt,
    playerOrder: playerOrder,
    currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
    phase: phase ?? this.phase,
    roundNumber: roundNumber ?? this.roundNumber,
    maxRounds: maxRounds,
    scores: scores ?? this.scores,
    currentCard: currentCard != null ? currentCard() : this.currentCard,
    currentPunishmentVote: currentPunishmentVote != null
        ? currentPunishmentVote()
        : this.currentPunishmentVote,
    timerStartedAt: timerStartedAt != null
        ? timerStartedAt()
        : this.timerStartedAt,
    timerPausedAt: timerPausedAt != null
        ? timerPausedAt()
        : this.timerPausedAt,
    turnStartedAt: turnStartedAt != null ? turnStartedAt() : this.turnStartedAt,
    isOver: isOver ?? this.isOver,
    endReason: endReason ?? this.endReason,
    turnOrderMode: turnOrderMode,
    randomTurnQueue: randomTurnQueue ?? this.randomTurnQueue,
    usedCardIds: usedCardIds ?? this.usedCardIds,
    turnResponse: turnResponse ?? this.turnResponse,
    turnProofImageB64: turnProofImageB64 ?? this.turnProofImageB64,
    turnProofVoiceB64: turnProofVoiceB64 ?? this.turnProofVoiceB64,
    turnProofSource: turnProofSource ?? this.turnProofSource,
    turnProofViewMode: turnProofViewMode ?? this.turnProofViewMode,
    turnProofViewSeconds: turnProofViewSeconds ?? this.turnProofViewSeconds,
    turnProofViewedBy: turnProofViewedBy ?? this.turnProofViewedBy,
    turnProofVisibility: turnProofVisibility ?? this.turnProofVisibility,
    proofVoteState: proofVoteState != null
        ? proofVoteState()
        : this.proofVoteState,
    currentReactions: currentReactions ?? this.currentReactions,
    currentVotes: currentVotes ?? this.currentVotes,
    history: history ?? this.history,
  );

  Map<String, dynamic> toMap() => {
    'snapshot_at': snapshotAt,
    'player_order': playerOrder,
    'current_player_index': currentPlayerIndex,
    'phase': phase.name,
    'round_number': roundNumber,
    'max_rounds': maxRounds,
    'scores': scores.map((k, v) => MapEntry(k, v.toMap())),
    'current_card': currentCard?.toMap(),
    'current_punishment_vote': currentPunishmentVote?.toMap(),
    'timer_started_at': timerStartedAt,
    'timer_paused_at': timerPausedAt,
    'turn_started_at': turnStartedAt,
    'is_over': isOver,
    'end_reason': endReason,
    'turn_order_mode': turnOrderMode.name,
    'random_turn_queue': randomTurnQueue,
    'used_card_ids': usedCardIds,
    'turn_response': turnResponse,
    'turn_proof_image': turnProofImageB64,
    'turn_proof_voice': turnProofVoiceB64,
    'turn_proof_source': turnProofSource.name,
    'turn_proof_view_mode': turnProofViewMode.name,
    'turn_proof_view_seconds': turnProofViewSeconds,
    'turn_proof_viewed_by': turnProofViewedBy,
    'turn_proof_visibility': turnProofVisibility.toMap(),
    'proof_vote_state': proofVoteState?.toMap(),
    'current_reactions': currentReactions.map((r) => r.toMap()).toList(),
    'current_votes': currentVotes.map((v) => v.toMap()).toList(),
    'history': history.map((r) => r.toMap()).toList(),
  };

  static TodState fromMap(Map<String, dynamic> m) {
    final rawScores = (m['scores'] as Map<String, dynamic>? ?? {});
    return TodState(
      snapshotAt: m['snapshot_at'] as int? ?? 0,
      playerOrder: (m['player_order'] as List?)?.cast<String>() ?? [],
      currentPlayerIndex: m['current_player_index'] as int? ?? 0,
      phase: TodTurnPhase.values.firstWhere(
        (p) => p.name == m['phase'],
        orElse: () => TodTurnPhase.choosingType,
      ),
      roundNumber: m['round_number'] as int? ?? 1,
      maxRounds: m['max_rounds'] as int? ?? 10,
      scores: rawScores.map(
        (k, v) =>
            MapEntry(k, TodPlayerScore.fromMap(v as Map<String, dynamic>)),
      ),
      currentCard: m['current_card'] != null
          ? TodCard.fromMap(m['current_card'] as Map<String, dynamic>)
          : null,
      currentPunishmentVote: m['current_punishment_vote'] != null
          ? TodPunishmentVoteState.fromMap(
              m['current_punishment_vote'] as Map<String, dynamic>,
            )
          : null,
      timerStartedAt: m['timer_started_at'] as int?,
      timerPausedAt: m['timer_paused_at'] as int?,
      turnStartedAt: m['turn_started_at'] as int?,
      isOver: m['is_over'] as bool? ?? false,
      endReason: m['end_reason'] as String?,
      turnOrderMode: TurnOrderMode.values.firstWhere(
        (t) => t.name == m['turn_order_mode'],
        orElse: () => TurnOrderMode.circular,
      ),
      randomTurnQueue: (m['random_turn_queue'] as List?)?.cast<String>() ?? [],
      usedCardIds: (m['used_card_ids'] as List?)?.cast<String>() ?? [],
      turnResponse: m['turn_response'] as String? ?? '',
      turnProofImageB64: m['turn_proof_image'] as String? ?? '',
      turnProofVoiceB64: m['turn_proof_voice'] as String? ?? '',
      turnProofSource: TodProofSource.values.firstWhere(
        (s) => s.name == m['turn_proof_source'],
        orElse: () => TodProofSource.camera,
      ),
      turnProofViewMode: TodProofViewMode.values.firstWhere(
        (v) => v.name == m['turn_proof_view_mode'],
        orElse: () => TodProofViewMode.once,
      ),
      turnProofViewSeconds: m['turn_proof_view_seconds'] as int? ?? 5,
      turnProofViewedBy:
          (m['turn_proof_viewed_by'] as Map<String, dynamic>? ?? {}).map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ),
      turnProofVisibility: m['turn_proof_visibility'] != null
          ? TodProofVisibilitySettings.fromMap(
              m['turn_proof_visibility'] as Map<String, dynamic>,
            )
          : const TodProofVisibilitySettings(),
      proofVoteState: m['proof_vote_state'] != null
          ? TodProofVoteState.fromMap(
              m['proof_vote_state'] as Map<String, dynamic>,
            )
          : null,
      currentReactions:
          (m['current_reactions'] as List?)
              ?.map((r) => TodReaction.fromMap(r as Map<String, dynamic>))
              .toList() ??
          [],
      currentVotes:
          (m['current_votes'] as List?)
              ?.map((v) => TodResponseVote.fromMap(v as Map<String, dynamic>))
              .toList() ??
          [],
      history:
          (m['history'] as List?)
              ?.map((r) => TodRoundRecord.fromMap(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EVENTS  (player → owner via Broadcast)
// ═══════════════════════════════════════════════════════════════════════════

/// Player chose Truth or Dare.
class TodChoiceEvent extends GameEngineEvent {
  const TodChoiceEvent({
    required super.userId,
    required super.ts,
    required this.cardType,
  });
  final TodCardType cardType;
}

/// Player completed their turn (did the truth/dare).
class TodCompleteEvent extends GameEngineEvent {
  const TodCompleteEvent({
    required super.userId,
    required super.ts,
    this.response = '',
    this.proofImageB64 = '',
    this.proofVoiceB64 = '',
    this.proofSource = TodProofSource.camera,
    this.proofViewMode = TodProofViewMode.once,
    this.proofViewSeconds = 5,
    this.proofVisibility = const TodProofVisibilitySettings(),
  });
  final String response;
  final String proofImageB64;
  final String proofVoiceB64;
  final TodProofSource proofSource;
  final TodProofViewMode proofViewMode;
  final int proofViewSeconds;
  final TodProofVisibilitySettings proofVisibility;
}

/// Owner starts a 10-second proof-requirement vote (players vote on whether
/// they want voice proof, image proof, or no proof from the current player).
class TodStartProofVoteEvent extends GameEngineEvent {
  const TodStartProofVoteEvent({required super.userId, required super.ts});
}

/// A player casts their proof-requirement vote.
class TodCastProofVoteEvent extends GameEngineEvent {
  const TodCastProofVoteEvent({
    required super.userId,
    required super.ts,
    required this.option,
  });
  final TodProofVoteOption option;
}

/// A player has opened/watched the current turn's proof — updates the
/// per-user view-count map.
class TodProofViewedEvent extends GameEngineEvent {
  const TodProofViewedEvent({required super.userId, required super.ts});
}

/// Player reacts to the current response with an emoji
class TodReactEvent extends GameEngineEvent {
  const TodReactEvent({
    required super.userId,
    required super.ts,
    required this.emoji,
  });
  final String emoji;
}

/// Player votes for the current response as best
class TodVoteResponseEvent extends GameEngineEvent {
  const TodVoteResponseEvent({required super.userId, required super.ts});
}

/// Player skipped their turn.
class TodSkipEvent extends GameEngineEvent {
  const TodSkipEvent({required super.userId, required super.ts});
}

/// Timer expired on the current player's turn.
class TodTimerExpiredEvent extends GameEngineEvent {
  const TodTimerExpiredEvent({
    required super.userId, // the timed-out player
    required super.ts,
  });
}

/// Moderator/owner proposed 3-5 punishment options for the group to vote
/// on.
/// One non-skipped player submitting exactly one punishment option — every
/// eligible player calls this once per skip, not a single moderator
/// proposing several at once.
class TodProposePunishmentEvent extends GameEngineEvent {
  const TodProposePunishmentEvent({
    required super.userId,
    required super.ts,
    required this.text,
  });
  final String text;
}

/// The skipped player picked which submitted punishment they'll do —
/// resolves immediately, no group vote or tally involved.
class TodVotePunishmentEvent extends GameEngineEvent {
  const TodVotePunishmentEvent({
    required super.userId,
    required super.ts,
    required this.optionId,
  });
  final String optionId;
}

/// Moderator force-resolves on the skipped player's behalf (e.g. they went
/// unresponsive/away), without waiting for their pick.
class TodModeratorOverrideEvent extends GameEngineEvent {
  const TodModeratorOverrideEvent({
    required super.userId,
    required super.ts,
    required this.optionId,
  });
  final String optionId;
}

/// Owner/mod manually ends the game.
class TodEndGameEvent extends GameEngineEvent {
  const TodEndGameEvent({
    required super.userId,
    required super.ts,
    this.reason = 'manual',
  });
  final String reason;
}
