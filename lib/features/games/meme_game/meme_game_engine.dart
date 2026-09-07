// // // import '../engine/base_game_engine.dart';
// // // import '../engine/game_registry.dart';

// // // // ── Domain ────────────────────────────────────────────────────────────────────

// // // class MemePrompt {
// // //   const MemePrompt({
// // //     required this.id,
// // //     required this.imageUrl,
// // //     required this.caption,
// // //   });
// // //   final String id;
// // //   final String imageUrl;
// // //   final String caption; // e.g. "When you see your ex at the supermarket"

// // //   Map<String, dynamic> toMap() => {
// // //     'id': id,
// // //     'image_url': imageUrl,
// // //     'caption': caption,
// // //   };
// // //   static MemePrompt fromMap(Map<String, dynamic> m) => MemePrompt(
// // //     id: m['id'] as String,
// // //     imageUrl: m['image_url'] as String,
// // //     caption: m['caption'] as String,
// // //   );
// // // }

// // // enum MemePhase { submitting, voting, results }

// // // class MemeSubmission {
// // //   const MemeSubmission({
// // //     required this.userId,
// // //     required this.content,
// // //     required this.submittedAt,
// // //   });
// // //   final String userId;
// // //   final String content; // player's caption/answer
// // //   final int submittedAt;

// // //   Map<String, dynamic> toMap() => {
// // //     'user_id': userId,
// // //     'content': content,
// // //     'submitted_at': submittedAt,
// // //   };
// // //   static MemeSubmission fromMap(Map<String, dynamic> m) => MemeSubmission(
// // //     userId: m['user_id'] as String,
// // //     content: m['content'] as String,
// // //     submittedAt: m['submitted_at'] as int,
// // //   );
// // // }

// // // class MemeState extends GameEngineState {
// // //   const MemeState({
// // //     required super.snapshotAt,
// // //     required this.playerOrder,
// // //     required this.currentPrompt,
// // //     required this.phase,
// // //     required this.submissions, // userId -> MemeSubmission
// // //     required this.votes, // voterId -> userId they voted for
// // //     required this.scores, // userId -> total wins
// // //     required this.roundNumber,
// // //     required this.maxRounds,
// // //     required this.isOver,
// // //     required this.roundWinnerId,
// // //   });

// // //   final List<String> playerOrder;
// // //   final MemePrompt? currentPrompt;
// // //   final MemePhase phase;
// // //   final Map<String, MemeSubmission> submissions;
// // //   final Map<String, String> votes; // voter -> winner choice
// // //   final Map<String, int> scores;
// // //   final int roundNumber;
// // //   final int maxRounds;
// // //   final bool isOver;
// // //   final String? roundWinnerId;

// // //   bool get allSubmitted =>
// // //       playerOrder.every((id) => submissions.containsKey(id));
// // //   bool get allVoted => playerOrder.every((id) => votes.containsKey(id));
// // //   String? get leaderId => scores.isEmpty
// // //       ? null
// // //       : (scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
// // //             .first
// // //             .key;

// // //   MemeState copyWith({
// // //     int? snapshotAt,
// // //     MemePrompt? Function()? currentPrompt,
// // //     MemePhase? phase,
// // //     Map<String, MemeSubmission>? submissions,
// // //     Map<String, String>? votes,
// // //     Map<String, int>? scores,
// // //     int? roundNumber,
// // //     bool? isOver,
// // //     String? Function()? roundWinnerId,
// // //   }) => MemeState(
// // //     snapshotAt: snapshotAt ?? this.snapshotAt,
// // //     playerOrder: playerOrder,
// // //     currentPrompt: currentPrompt != null ? currentPrompt() : this.currentPrompt,
// // //     phase: phase ?? this.phase,
// // //     submissions: submissions ?? this.submissions,
// // //     votes: votes ?? this.votes,
// // //     scores: scores ?? this.scores,
// // //     roundNumber: roundNumber ?? this.roundNumber,
// // //     maxRounds: maxRounds,
// // //     isOver: isOver ?? this.isOver,
// // //     roundWinnerId: roundWinnerId != null ? roundWinnerId() : this.roundWinnerId,
// // //   );

// // //   Map<String, dynamic> toMap() => {
// // //     'snapshot_at': snapshotAt,
// // //     'player_order': playerOrder,
// // //     'current_prompt': currentPrompt?.toMap(),
// // //     'phase': phase.name,
// // //     'submissions': submissions.map((k, v) => MapEntry(k, v.toMap())),
// // //     'votes': votes,
// // //     'scores': scores,
// // //     'round_number': roundNumber,
// // //     'max_rounds': maxRounds,
// // //     'is_over': isOver,
// // //     'round_winner_id': roundWinnerId,
// // //   };

// // //   static MemeState fromMap(Map<String, dynamic> m) => MemeState(
// // //     snapshotAt: m['snapshot_at'] as int? ?? 0,
// // //     playerOrder: (m['player_order'] as List?)?.cast<String>() ?? [],
// // //     currentPrompt: m['current_prompt'] != null
// // //         ? MemePrompt.fromMap(m['current_prompt'] as Map<String, dynamic>)
// // //         : null,
// // //     phase: MemePhase.values.firstWhere(
// // //       (p) => p.name == m['phase'],
// // //       orElse: () => MemePhase.submitting,
// // //     ),
// // //     submissions:
// // //         (m['submissions'] as Map?)?.map(
// // //           (k, v) => MapEntry(
// // //             k as String,
// // //             MemeSubmission.fromMap(v as Map<String, dynamic>),
// // //           ),
// // //         ) ??
// // //         {},
// // //     votes: (m['votes'] as Map?)?.cast<String, String>() ?? {},
// // //     scores:
// // //         (m['scores'] as Map?)?.map(
// // //           (k, v) => MapEntry(k as String, (v as num).toInt()),
// // //         ) ??
// // //         {},
// // //     roundNumber: m['round_number'] as int? ?? 1,
// // //     maxRounds: m['max_rounds'] as int? ?? 10,
// // //     isOver: m['is_over'] as bool? ?? false,
// // //     roundWinnerId: m['round_winner_id'] as String?,
// // //   );
// // // }

// // // // ── Events ────────────────────────────────────────────────────────────────────

// // // class MemeSubmitEvent extends GameEngineEvent {
// // //   const MemeSubmitEvent({
// // //     required super.userId,
// // //     required super.ts,
// // //     required this.content,
// // //   });
// // //   final String content;
// // // }

// // // class MemeVoteEvent extends GameEngineEvent {
// // //   const MemeVoteEvent({
// // //     required super.userId,
// // //     required super.ts,
// // //     required this.targetUserId,
// // //   });
// // //   final String targetUserId;
// // // }

// // // // ── Engine ────────────────────────────────────────────────────────────────────

// // // class MemeGameEngine implements BaseGameEngine {
// // //   MemeGameEngine(this._config, {required List<MemePrompt> prompts})
// // //     : _prompts = prompts;

// // //   final GameConfig _config;
// // //   final List<MemePrompt> _prompts;
// // //   late MemeState _state;

// // //   void init(List<String> playerOrder) {
// // //     _prompts.shuffle();
// // //     _state = MemeState(
// // //       snapshotAt: DateTime.now().millisecondsSinceEpoch,
// // //       playerOrder: playerOrder,
// // //       currentPrompt: _prompts.isNotEmpty ? _prompts.first : null,
// // //       phase: MemePhase.submitting,
// // //       submissions: {},
// // //       votes: {},
// // //       scores: {for (final id in playerOrder) id: 0},
// // //       roundNumber: 1,
// // //       maxRounds: _config.maxRounds,
// // //       isOver: false,
// // //       roundWinnerId: null,
// // //     );
// // //   }

// // //   @override
// // //   MemeState get currentState => _state;

// // //   @override
// // //   MemeState handleEvent(GameEngineEvent event) {
// // //     _state = switch (event) {
// // //       MemeSubmitEvent e => _handleSubmit(e),
// // //       MemeVoteEvent e => _handleVote(e),
// // //       _ => _state,
// // //     };
// // //     return _state;
// // //   }

// // //   @override
// // //   MemeState advanceTurn() {
// // //     final newRound = _state.roundNumber + 1;
// // //     final isOver = newRound > _state.maxRounds;
// // //     final nextPrompt = newRound <= _prompts.length
// // //         ? _prompts[newRound - 1]
// // //         : null;

// // //     _state = _state.copyWith(
// // //       snapshotAt: DateTime.now().millisecondsSinceEpoch,
// // //       currentPrompt: () => nextPrompt,
// // //       phase: MemePhase.submitting,
// // //       submissions: {},
// // //       votes: {},
// // //       roundNumber: newRound,
// // //       isOver: isOver,
// // //       roundWinnerId: () => null,
// // //     );
// // //     return _state;
// // //   }

// // //   @override
// // //   Map<String, dynamic> serializeState() => _state.toMap();

// // //   @override
// // //   void restoreFromSnapshot(Map<String, dynamic> snapshot) {
// // //     _state = MemeState.fromMap(snapshot);
// // //   }

// // //   @override
// // //   bool get isGameOver => _state.isOver;

// // //   // ── Handlers ──────────────────────────────────────────────────────────────
// // //   MemeState _handleSubmit(MemeSubmitEvent event) {
// // //     if (_state.phase != MemePhase.submitting) return _state;
// // //     if (_state.submissions.containsKey(event.userId)) return _state;

// // //     final newSubmissions = {
// // //       ..._state.submissions,
// // //       event.userId: MemeSubmission(
// // //         userId: event.userId,
// // //         content: event.content,
// // //         submittedAt: event.ts,
// // //       ),
// // //     };

// // //     // Move to voting once all submitted
// // //     final phase = newSubmissions.length >= _state.playerOrder.length
// // //         ? MemePhase.voting
// // //         : MemePhase.submitting;

// // //     return _state.copyWith(
// // //       snapshotAt: DateTime.now().millisecondsSinceEpoch,
// // //       submissions: newSubmissions,
// // //       phase: phase,
// // //     );
// // //   }

// // //   MemeState _handleVote(MemeVoteEvent event) {
// // //     if (_state.phase != MemePhase.voting) return _state;
// // //     if (_state.votes.containsKey(event.userId)) return _state;
// // //     // Can't vote for yourself
// // //     if (event.targetUserId == event.userId) return _state;

// // //     final newVotes = {..._state.votes, event.userId: event.targetUserId};

// // //     final allVoted = _state.playerOrder.every((id) => newVotes.containsKey(id));
// // //     if (!allVoted) {
// // //       return _state.copyWith(
// // //         snapshotAt: DateTime.now().millisecondsSinceEpoch,
// // //         votes: newVotes,
// // //       );
// // //     }

// // //     // Tally votes and award winner
// // //     final tally = <String, int>{};
// // //     for (final targetId in newVotes.values) {
// // //       tally[targetId] = (tally[targetId] ?? 0) + 1;
// // //     }
// // //     final winnerId = tally.entries
// // //         .toList()
// // //         .reduce((a, b) => a.value >= b.value ? a : b)
// // //         .key;

// // //     final newScores = Map<String, int>.from(_state.scores);
// // //     newScores[winnerId] = (newScores[winnerId] ?? 0) + 1;

// // //     return _state.copyWith(
// // //       snapshotAt: DateTime.now().millisecondsSinceEpoch,
// // //       votes: newVotes,
// // //       scores: newScores,
// // //       phase: MemePhase.results,
// // //       roundWinnerId: () => winnerId,
// // //     );
// // //   }
// // // }

// // import '../engine/base_game_engine.dart';

// // // ── Domain ────────────────────────────────────────────────────────────────────

// // class MemePrompt {
// //   const MemePrompt({
// //     required this.id,
// //     required this.imageUrl,
// //     required this.caption,
// //   });
// //   final String id;
// //   final String imageUrl;
// //   final String caption;

// //   Map<String, dynamic> toMap() => {
// //     'id': id,
// //     'image_url': imageUrl,
// //     'caption': caption,
// //   };
// //   static MemePrompt fromMap(Map<String, dynamic> m) => MemePrompt(
// //     id: m['id'] as String,
// //     imageUrl: m['image_url'] as String? ?? '',
// //     caption: m['caption'] as String,
// //   );
// // }

// // enum MemePhase { submitting, voting, results }

// // class MemeSubmission {
// //   const MemeSubmission({
// //     required this.userId,
// //     required this.content,
// //     required this.submittedAt,
// //   });
// //   final String userId;
// //   final String content;
// //   final int submittedAt;

// //   Map<String, dynamic> toMap() => {
// //     'user_id': userId,
// //     'content': content,
// //     'submitted_at': submittedAt,
// //   };
// //   static MemeSubmission fromMap(Map<String, dynamic> m) => MemeSubmission(
// //     userId: m['user_id'] as String,
// //     content: m['content'] as String,
// //     submittedAt: m['submitted_at'] as int? ?? 0,
// //   );
// // }

// // class StickerReaction {
// //   const StickerReaction({
// //     required this.userId,
// //     required this.sticker,
// //     required this.ts,
// //   });
// //   final String userId;
// //   final String sticker; // emoji or asset name
// //   final int ts;

// //   Map<String, dynamic> toMap() => {
// //     'user_id': userId,
// //     'sticker': sticker,
// //     'ts': ts,
// //   };
// //   static StickerReaction fromMap(Map<String, dynamic> m) => StickerReaction(
// //     userId: m['user_id'] as String,
// //     sticker: m['sticker'] as String,
// //     ts: m['ts'] as int? ?? 0,
// //   );
// // }

// // class MemeState extends GameEngineState {
// //   const MemeState({
// //     required super.snapshotAt,
// //     required this.playerOrder,
// //     required this.currentPrompt,
// //     required this.phase,
// //     required this.submissions,
// //     required this.votes,
// //     required this.scores,
// //     required this.roundNumber,
// //     required this.maxRounds,
// //     required this.isOver,
// //     required this.roundWinnerId,
// //     this.reactions = const [],
// //   });

// //   final List<String> playerOrder;
// //   final MemePrompt? currentPrompt;
// //   final MemePhase phase;
// //   final Map<String, MemeSubmission> submissions;
// //   final Map<String, String> votes;
// //   final Map<String, int> scores;
// //   final int roundNumber;
// //   final int maxRounds;
// //   final bool isOver;
// //   final String? roundWinnerId;
// //   final List<StickerReaction> reactions;

// //   bool get allSubmitted =>
// //       playerOrder.every((id) => submissions.containsKey(id));
// //   bool get allVoted => playerOrder.every((id) => votes.containsKey(id));

// //   MemeState copyWith({
// //     int? snapshotAt,
// //     MemePrompt? Function()? currentPrompt,
// //     MemePhase? phase,
// //     Map<String, MemeSubmission>? submissions,
// //     Map<String, String>? votes,
// //     Map<String, int>? scores,
// //     int? roundNumber,
// //     bool? isOver,
// //     String? Function()? roundWinnerId,
// //     List<StickerReaction>? reactions,
// //   }) => MemeState(
// //     snapshotAt: snapshotAt ?? this.snapshotAt,
// //     playerOrder: playerOrder,
// //     currentPrompt: currentPrompt != null ? currentPrompt() : this.currentPrompt,
// //     phase: phase ?? this.phase,
// //     submissions: submissions ?? this.submissions,
// //     votes: votes ?? this.votes,
// //     scores: scores ?? this.scores,
// //     roundNumber: roundNumber ?? this.roundNumber,
// //     maxRounds: maxRounds,
// //     isOver: isOver ?? this.isOver,
// //     roundWinnerId: roundWinnerId != null ? roundWinnerId() : this.roundWinnerId,
// //     reactions: reactions ?? this.reactions,
// //   );

// //   Map<String, dynamic> toMap() => {
// //     'snapshot_at': snapshotAt,
// //     'player_order': playerOrder,
// //     'current_prompt': currentPrompt?.toMap(),
// //     'phase': phase.name,
// //     'submissions': submissions.map((k, v) => MapEntry(k, v.toMap())),
// //     'votes': votes,
// //     'scores': scores,
// //     'round_number': roundNumber,
// //     'max_rounds': maxRounds,
// //     'is_over': isOver,
// //     'round_winner_id': roundWinnerId,
// //     'reactions': reactions.map((r) => r.toMap()).toList(),
// //   };

// //   static MemeState fromMap(Map<String, dynamic> m) => MemeState(
// //     snapshotAt: m['snapshot_at'] as int? ?? 0,
// //     playerOrder: (m['player_order'] as List?)?.cast<String>() ?? [],
// //     currentPrompt: m['current_prompt'] != null
// //         ? MemePrompt.fromMap(m['current_prompt'] as Map<String, dynamic>)
// //         : null,
// //     phase: MemePhase.values.firstWhere(
// //       (p) => p.name == m['phase'],
// //       orElse: () => MemePhase.submitting,
// //     ),
// //     submissions:
// //         (m['submissions'] as Map?)?.map(
// //           (k, v) => MapEntry(
// //             k as String,
// //             MemeSubmission.fromMap(v as Map<String, dynamic>),
// //           ),
// //         ) ??
// //         {},
// //     votes: (m['votes'] as Map?)?.cast<String, String>() ?? {},
// //     scores:
// //         (m['scores'] as Map?)?.map(
// //           (k, v) => MapEntry(k as String, (v as num).toInt()),
// //         ) ??
// //         {},
// //     roundNumber: m['round_number'] as int? ?? 1,
// //     maxRounds: m['max_rounds'] as int? ?? 10,
// //     isOver: m['is_over'] as bool? ?? false,
// //     roundWinnerId: m['round_winner_id'] as String?,
// //     reactions:
// //         (m['reactions'] as List?)
// //             ?.map((r) => StickerReaction.fromMap(r as Map<String, dynamic>))
// //             .toList() ??
// //         [],
// //   );
// // }

// // // ── Events ────────────────────────────────────────────────────────────────────

// // class MemeSubmitEvent extends GameEngineEvent {
// //   const MemeSubmitEvent({
// //     required super.userId,
// //     required super.ts,
// //     required this.content,
// //   });
// //   final String content;
// // }

// // class MemeVoteEvent extends GameEngineEvent {
// //   const MemeVoteEvent({
// //     required super.userId,
// //     required super.ts,
// //     required this.targetUserId,
// //   });
// //   final String targetUserId;
// // }

// // class MemeStickerEvent extends GameEngineEvent {
// //   const MemeStickerEvent({
// //     required super.userId,
// //     required super.ts,
// //     required this.sticker,
// //   });
// //   final String sticker;
// // }

// // // ── Engine ────────────────────────────────────────────────────────────────────

// // class MemeGameEngine implements BaseGameEngine {
// //   MemeGameEngine(this._config, {required List<MemePrompt> prompts})
// //     : _prompts = List.from(prompts)..shuffle();

// //   final GameConfig _config;
// //   final List<MemePrompt> _prompts;
// //   final Set<String> _usedPromptIds = {};
// //   late MemeState _state;

// //   @override
// //   MemeState get currentState => _state;

// //   void init(List<String> playerOrder) {
// //     _usedPromptIds.clear();
// //     final first = _nextPrompt();
// //     _state = MemeState(
// //       snapshotAt: DateTime.now().millisecondsSinceEpoch,
// //       playerOrder: playerOrder,
// //       currentPrompt: first,
// //       phase: MemePhase.submitting,
// //       submissions: {},
// //       votes: {},
// //       scores: {for (final id in playerOrder) id: 0},
// //       roundNumber: 1,
// //       maxRounds: _config.maxRounds,
// //       isOver: false,
// //       roundWinnerId: null,
// //       reactions: [],
// //     );
// //   }

// //   MemePrompt? _nextPrompt() {
// //     final available = _prompts
// //         .where((p) => !_usedPromptIds.contains(p.id))
// //         .toList();
// //     if (available.isEmpty) return null;
// //     final prompt = available.first;
// //     _usedPromptIds.add(prompt.id);
// //     return prompt;
// //   }

// //   @override
// //   MemeState handleEvent(GameEngineEvent event) {
// //     _state = switch (event) {
// //       MemeSubmitEvent e => _handleSubmit(e),
// //       MemeVoteEvent e => _handleVote(e),
// //       MemeStickerEvent e => _handleSticker(e),
// //       _ => _state,
// //     };
// //     return _state;
// //   }

// //   @override
// //   MemeState advanceTurn() {
// //     final newRound = _state.roundNumber + 1;
// //     final isOver = newRound > _state.maxRounds || _nextPrompt() == null;
// //     final next = isOver ? null : _nextPrompt();
// //     // _nextPrompt was called above — undo the double-mark if isOver
// //     if (next != null) _usedPromptIds.remove(next.id);
// //     final nextPrompt = isOver ? null : _nextPrompt();

// //     _state = _state.copyWith(
// //       snapshotAt: DateTime.now().millisecondsSinceEpoch,
// //       currentPrompt: () => nextPrompt,
// //       phase: MemePhase.submitting,
// //       submissions: {},
// //       votes: {},
// //       roundNumber: newRound,
// //       isOver: isOver,
// //       roundWinnerId: () => null,
// //       reactions: [],
// //     );
// //     return _state;
// //   }

// //   @override
// //   Map<String, dynamic> serializeState() => _state.toMap();

// //   @override
// //   void restoreFromSnapshot(Map<String, dynamic> snapshot) {
// //     _state = MemeState.fromMap(snapshot);
// //   }

// //   @override
// //   bool get isGameOver => _state.isOver;

// //   // ── Handlers ────────────────────────────────────────────────────────────────

// //   MemeState _handleSubmit(MemeSubmitEvent e) {
// //     if (_state.phase != MemePhase.submitting) return _state;
// //     if (_state.submissions.containsKey(e.userId)) return _state;

// //     final newSubs = {
// //       ..._state.submissions,
// //       e.userId: MemeSubmission(
// //         userId: e.userId,
// //         content: e.content,
// //         submittedAt: e.ts,
// //       ),
// //     };
// //     final allIn = newSubs.length >= _state.playerOrder.length;
// //     return _state.copyWith(
// //       snapshotAt: DateTime.now().millisecondsSinceEpoch,
// //       submissions: newSubs,
// //       phase: allIn ? MemePhase.voting : MemePhase.submitting,
// //     );
// //   }

// //   MemeState _handleVote(MemeVoteEvent e) {
// //     if (_state.phase != MemePhase.voting) return _state;
// //     if (_state.votes.containsKey(e.userId)) return _state;

// //     final newVotes = {..._state.votes, e.userId: e.targetUserId};
// //     // Count eligible voters (everyone votes, including for their own if solo)
// //     final eligibleVoters = _state.playerOrder.length;
// //     final allVoted = newVotes.length >= eligibleVoters;

// //     if (!allVoted) {
// //       return _state.copyWith(
// //         snapshotAt: DateTime.now().millisecondsSinceEpoch,
// //         votes: newVotes,
// //       );
// //     }

// //     // Tally
// //     final tally = <String, int>{};
// //     for (final target in newVotes.values) {
// //       tally[target] = (tally[target] ?? 0) + 1;
// //     }
// //     final winnerId =
// //         (tally.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
// //             .first
// //             .key;

// //     final newScores = Map<String, int>.from(_state.scores);
// //     newScores[winnerId] = (newScores[winnerId] ?? 0) + 1;

// //     return _state.copyWith(
// //       snapshotAt: DateTime.now().millisecondsSinceEpoch,
// //       votes: newVotes,
// //       scores: newScores,
// //       phase: MemePhase.results,
// //       roundWinnerId: () => winnerId,
// //     );
// //   }

// //   MemeState _handleSticker(MemeStickerEvent e) {
// //     final newReactions = [
// //       ..._state.reactions,
// //       StickerReaction(userId: e.userId, sticker: e.sticker, ts: e.ts),
// //     ];
// //     return _state.copyWith(
// //       snapshotAt: DateTime.now().millisecondsSinceEpoch,
// //       reactions: newReactions,
// //     );
// //   }
// // }

// import '../engine/base_game_engine.dart';

// // ─────────────────────────────────────────────────────────────────────────────
// // Preset sticker set (built into the app — used across Meme + NHIE)
// // ─────────────────────────────────────────────────────────────────────────────

// const kAppStickers = [
//   '😂',
//   '🔥',
//   '💀',
//   '👏',
//   '🤣',
//   '😭',
//   '🫡',
//   '💯',
//   '🤯',
//   '👑',
//   '😤',
//   '🥹',
//   '🫶',
//   '💅',
//   '🙈',
//   '😎',
//   '🤡',
//   '💔',
//   '🎉',
//   '😈',
// ];

// // ── MemePrompt ────────────────────────────────────────────────────────────────

// class MemePrompt {
//   const MemePrompt({required this.id, this.imageUrl, required this.caption});
//   final String id;
//   final String caption;
//   final String? imageUrl;

//   Map<String, dynamic> toMap() => {'id': id, 'caption': caption};
//   static MemePrompt fromMap(Map<String, dynamic> m) =>
//       MemePrompt(id: m['id'] as String, caption: m['caption'] as String? ?? '');
// }

// // ── MemeSubmission ────────────────────────────────────────────────────────────
// // A player's response: optional caption + optional sticker

// class MemeSubmission {
//   const MemeSubmission({
//     required this.userId,
//     required this.submittedAt,
//     this.caption = '', // optional free-text caption
//     this.stickerChoice = '', // optional sticker from kAppStickers
//   });
//   final String userId;
//   final int submittedAt;
//   final String caption;
//   final String stickerChoice;

//   bool get isEmpty => caption.isEmpty && stickerChoice.isEmpty;

//   Map<String, dynamic> toMap() => {
//     'user_id': userId,
//     'submitted_at': submittedAt,
//     'caption': caption,
//     'sticker_choice': stickerChoice,
//   };
//   static MemeSubmission fromMap(Map<String, dynamic> m) => MemeSubmission(
//     userId: m['user_id'] as String,
//     submittedAt: m['submitted_at'] as int? ?? 0,
//     caption: m['caption'] as String? ?? '',
//     stickerChoice: m['sticker_choice'] as String? ?? '',
//   );
// }

// // ── EmojiReaction ─────────────────────────────────────────────────────────────
// // Other players' emoji reactions to a specific submission

// class EmojiReaction {
//   const EmojiReaction({
//     required this.reactorId,
//     required this.targetUserId, // whose submission they reacted to
//     required this.emoji,
//     required this.ts,
//   });
//   final String reactorId;
//   final String targetUserId;
//   final String emoji;
//   final int ts;

//   Map<String, dynamic> toMap() => {
//     'reactor_id': reactorId,
//     'target_user_id': targetUserId,
//     'emoji': emoji,
//     'ts': ts,
//   };
//   static EmojiReaction fromMap(Map<String, dynamic> m) => EmojiReaction(
//     reactorId: m['reactor_id'] as String,
//     targetUserId: m['target_user_id'] as String,
//     emoji: m['emoji'] as String,
//     ts: m['ts'] as int? ?? 0,
//   );
// }

// // ── MemeRoundRecord ───────────────────────────────────────────────────────────

// class MemeRoundRecord {
//   const MemeRoundRecord({
//     required this.roundNumber,
//     required this.prompt,
//     required this.submissions,
//     required this.votes,
//     required this.winnerId,
//     required this.reactions,
//   });
//   final int roundNumber;
//   final MemePrompt prompt;
//   final Map<String, MemeSubmission> submissions;
//   final Map<String, String> votes; // voterId -> targetUserId
//   final String? winnerId;
//   final List<EmojiReaction> reactions;

//   Map<String, dynamic> toMap() => {
//     'round_number': roundNumber,
//     'prompt': prompt.toMap(),
//     'submissions': submissions.map((k, v) => MapEntry(k, v.toMap())),
//     'votes': votes,
//     'winner_id': winnerId,
//     'reactions': reactions.map((r) => r.toMap()).toList(),
//   };
//   static MemeRoundRecord fromMap(Map<String, dynamic> m) => MemeRoundRecord(
//     roundNumber: m['round_number'] as int? ?? 0,
//     prompt: MemePrompt.fromMap(m['prompt'] as Map<String, dynamic>),
//     submissions:
//         (m['submissions'] as Map?)?.map(
//           (k, v) => MapEntry(
//             k as String,
//             MemeSubmission.fromMap(v as Map<String, dynamic>),
//           ),
//         ) ??
//         {},
//     votes: (m['votes'] as Map?)?.cast<String, String>() ?? {},
//     winnerId: m['winner_id'] as String?,
//     reactions:
//         (m['reactions'] as List?)
//             ?.map((r) => EmojiReaction.fromMap(r as Map<String, dynamic>))
//             .toList() ??
//         [],
//   );
// }

// enum MemePhase { submitting, voting, results }

// // ── MemeState ─────────────────────────────────────────────────────────────────

// class MemeState extends GameEngineState {
//   const MemeState({
//     required super.snapshotAt,
//     required this.playerOrder,
//     required this.currentPrompt,
//     required this.phase,
//     required this.submissions,
//     required this.votes,
//     required this.scores,
//     required this.roundNumber,
//     required this.maxRounds,
//     required this.isOver,
//     required this.roundWinnerId,
//     this.reactions = const [],
//     this.history = const [],
//   });

//   final List<String> playerOrder;
//   final MemePrompt? currentPrompt;
//   final MemePhase phase;
//   final Map<String, MemeSubmission> submissions;
//   final Map<String, String> votes;
//   final Map<String, int> scores;
//   final int roundNumber;
//   final int maxRounds;
//   final bool isOver;
//   final String? roundWinnerId;
//   final List<EmojiReaction> reactions; // reactions to current round submissions
//   final List<MemeRoundRecord> history;

//   MemeState copyWith({
//     int? snapshotAt,
//     MemePrompt? Function()? currentPrompt,
//     MemePhase? phase,
//     Map<String, MemeSubmission>? submissions,
//     Map<String, String>? votes,
//     Map<String, int>? scores,
//     int? roundNumber,
//     bool? isOver,
//     String? Function()? roundWinnerId,
//     List<EmojiReaction>? reactions,
//     List<MemeRoundRecord>? history,
//   }) => MemeState(
//     snapshotAt: snapshotAt ?? this.snapshotAt,
//     playerOrder: playerOrder,
//     currentPrompt: currentPrompt != null ? currentPrompt() : this.currentPrompt,
//     phase: phase ?? this.phase,
//     submissions: submissions ?? this.submissions,
//     votes: votes ?? this.votes,
//     scores: scores ?? this.scores,
//     roundNumber: roundNumber ?? this.roundNumber,
//     maxRounds: maxRounds,
//     isOver: isOver ?? this.isOver,
//     roundWinnerId: roundWinnerId != null ? roundWinnerId() : this.roundWinnerId,
//     reactions: reactions ?? this.reactions,
//     history: history ?? this.history,
//   );

//   Map<String, dynamic> toMap() => {
//     'snapshot_at': snapshotAt,
//     'player_order': playerOrder,
//     'current_prompt': currentPrompt?.toMap(),
//     'phase': phase.name,
//     'submissions': submissions.map((k, v) => MapEntry(k, v.toMap())),
//     'votes': votes,
//     'scores': scores,
//     'round_number': roundNumber,
//     'max_rounds': maxRounds,
//     'is_over': isOver,
//     'round_winner_id': roundWinnerId,
//     'reactions': reactions.map((r) => r.toMap()).toList(),
//     'history': history.map((r) => r.toMap()).toList(),
//   };

//   static MemeState fromMap(Map<String, dynamic> m) => MemeState(
//     snapshotAt: m['snapshot_at'] as int? ?? 0,
//     playerOrder: (m['player_order'] as List?)?.cast<String>() ?? [],
//     currentPrompt: m['current_prompt'] != null
//         ? MemePrompt.fromMap(m['current_prompt'] as Map<String, dynamic>)
//         : null,
//     phase: MemePhase.values.firstWhere(
//       (p) => p.name == m['phase'],
//       orElse: () => MemePhase.submitting,
//     ),
//     submissions:
//         (m['submissions'] as Map?)?.map(
//           (k, v) => MapEntry(
//             k as String,
//             MemeSubmission.fromMap(v as Map<String, dynamic>),
//           ),
//         ) ??
//         {},
//     votes: (m['votes'] as Map?)?.cast<String, String>() ?? {},
//     scores:
//         (m['scores'] as Map?)?.map(
//           (k, v) => MapEntry(k as String, (v as num).toInt()),
//         ) ??
//         {},
//     roundNumber: m['round_number'] as int? ?? 1,
//     maxRounds: m['max_rounds'] as int? ?? 10,
//     isOver: m['is_over'] as bool? ?? false,
//     roundWinnerId: m['round_winner_id'] as String?,
//     reactions:
//         (m['reactions'] as List?)
//             ?.map((r) => EmojiReaction.fromMap(r as Map<String, dynamic>))
//             .toList() ??
//         [],
//     history:
//         (m['history'] as List?)
//             ?.map((r) => MemeRoundRecord.fromMap(r as Map<String, dynamic>))
//             .toList() ??
//         [],
//   );
// }

// // ── Events ────────────────────────────────────────────────────────────────────

// class MemeSubmitEvent extends GameEngineEvent {
//   const MemeSubmitEvent({
//     required super.userId,
//     required super.ts,
//     this.caption = '',
//     this.stickerChoice = '',
//   });
//   final String caption;
//   final String stickerChoice;
// }

// class MemeVoteEvent extends GameEngineEvent {
//   const MemeVoteEvent({
//     required super.userId,
//     required super.ts,
//     required this.targetUserId,
//   });
//   final String targetUserId;
// }

// class MemeReactEvent extends GameEngineEvent {
//   const MemeReactEvent({
//     required super.userId,
//     required super.ts,
//     required this.targetUserId,
//     required this.emoji,
//   });
//   final String targetUserId;
//   final String emoji;
// }

// // ── Engine ────────────────────────────────────────────────────────────────────

// class MemeGameEngine implements BaseGameEngine {
//   MemeGameEngine(this._config, {required List<MemePrompt> prompts})
//     : _prompts = List.from(prompts)..shuffle();

//   final GameConfig _config;
//   final List<MemePrompt> _prompts;
//   final Set<String> _usedPromptIds = {};
//   late MemeState _state;

//   @override
//   MemeState get currentState => _state;

//   void init(List<String> playerOrder) {
//     _usedPromptIds.clear();
//     _state = MemeState(
//       snapshotAt: DateTime.now().millisecondsSinceEpoch,
//       playerOrder: playerOrder,
//       currentPrompt: _nextPrompt(),
//       phase: MemePhase.submitting,
//       submissions: {},
//       votes: {},
//       scores: {for (final id in playerOrder) id: 0},
//       roundNumber: 1,
//       maxRounds: _config.maxRounds,
//       isOver: false,
//       roundWinnerId: null,
//       reactions: [],
//       history: [],
//     );
//   }

//   MemePrompt? _nextPrompt() {
//     final available = _prompts
//         .where((p) => !_usedPromptIds.contains(p.id))
//         .toList();
//     if (available.isEmpty) return null;
//     _usedPromptIds.add(available.first.id);
//     return available.first;
//   }

//   @override
//   MemeState handleEvent(GameEngineEvent event) {
//     _state = switch (event) {
//       MemeSubmitEvent e => _handleSubmit(e),
//       MemeVoteEvent e => _handleVote(e),
//       MemeReactEvent e => _handleReact(e),
//       _ => _state,
//     };
//     return _state;
//   }

//   @override
//   MemeState advanceTurn() {
//     // Save to history
//     final record = _state.currentPrompt != null
//         ? MemeRoundRecord(
//             roundNumber: _state.roundNumber,
//             prompt: _state.currentPrompt!,
//             submissions: _state.submissions,
//             votes: _state.votes,
//             winnerId: _state.roundWinnerId,
//             reactions: _state.reactions,
//           )
//         : null;

//     final newRound = _state.roundNumber + 1;
//     final nextPrompt = _nextPrompt();
//     final isOver = newRound > _state.maxRounds || nextPrompt == null;

//     _state = _state.copyWith(
//       snapshotAt: DateTime.now().millisecondsSinceEpoch,
//       currentPrompt: () => isOver ? null : nextPrompt,
//       phase: MemePhase.submitting,
//       submissions: {},
//       votes: {},
//       roundNumber: newRound,
//       isOver: isOver,
//       roundWinnerId: () => null,
//       reactions: [],
//       history: [..._state.history, if (record != null) record],
//     );
//     return _state;
//   }

//   @override
//   Map<String, dynamic> serializeState() => _state.toMap();
//   @override
//   void restoreFromSnapshot(Map<String, dynamic> s) {
//     _state = MemeState.fromMap(s);
//   }

//   @override
//   bool get isGameOver => _state.isOver;

//   // ── Handlers ────────────────────────────────────────────────────────────────

//   MemeState _handleSubmit(MemeSubmitEvent e) {
//     if (_state.phase != MemePhase.submitting) return _state;
//     if (_state.submissions.containsKey(e.userId)) return _state;
//     if (e.caption.isEmpty && e.stickerChoice.isEmpty)
//       return _state; // need at least one

//     final newSubs = {
//       ..._state.submissions,
//       e.userId: MemeSubmission(
//         userId: e.userId,
//         submittedAt: e.ts,
//         caption: e.caption,
//         stickerChoice: e.stickerChoice,
//       ),
//     };
//     final allIn = newSubs.length >= _state.playerOrder.length;
//     return _state.copyWith(
//       snapshotAt: DateTime.now().millisecondsSinceEpoch,
//       submissions: newSubs,
//       phase: allIn ? MemePhase.voting : MemePhase.submitting,
//     );
//   }

//   MemeState _handleVote(MemeVoteEvent e) {
//     if (_state.phase != MemePhase.voting) return _state;
//     if (_state.votes.containsKey(e.userId)) return _state;

//     final newVotes = {..._state.votes, e.userId: e.targetUserId};
//     final allVoted = newVotes.length >= _state.playerOrder.length;
//     if (!allVoted)
//       return _state.copyWith(
//         snapshotAt: DateTime.now().millisecondsSinceEpoch,
//         votes: newVotes,
//       );

//     final tally = <String, int>{};
//     for (final t in newVotes.values) tally[t] = (tally[t] ?? 0) + 1;
//     final winnerId =
//         (tally.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
//             .first
//             .key;

//     final newScores = Map<String, int>.from(_state.scores);
//     newScores[winnerId] = (newScores[winnerId] ?? 0) + 1;

//     return _state.copyWith(
//       snapshotAt: DateTime.now().millisecondsSinceEpoch,
//       votes: newVotes,
//       scores: newScores,
//       phase: MemePhase.results,
//       roundWinnerId: () => winnerId,
//     );
//   }

//   MemeState _handleReact(MemeReactEvent e) {
//     // One reaction per (reactor, target) pair
//     if (_state.reactions.any(
//       (r) => r.reactorId == e.userId && r.targetUserId == e.targetUserId,
//     ))
//       return _state;
//     return _state.copyWith(
//       snapshotAt: DateTime.now().millisecondsSinceEpoch,
//       reactions: [
//         ..._state.reactions,
//         EmojiReaction(
//           reactorId: e.userId,
//           targetUserId: e.targetUserId,
//           emoji: e.emoji,
//           ts: e.ts,
//         ),
//       ],
//     );
//   }
// }

import 'dart:math';

import '../engine/base_game_engine.dart';
import '../engine/round_capacity.dart';

// ── MemePrompt ────────────────────────────────────────────────────────────────

class MemePrompt {
  const MemePrompt({required this.id, required this.caption});
  final String id;
  final String caption;

  Map<String, dynamic> toMap() => {'id': id, 'caption': caption};
  static MemePrompt fromMap(Map<String, dynamic> m) =>
      MemePrompt(id: m['id'] as String, caption: m['caption'] as String? ?? '');
}

// ── MemeSubmission ────────────────────────────────────────────────────────────
// A player's response: optional caption + optional sticker

class MemeSubmission {
  const MemeSubmission({
    required this.userId,
    required this.submittedAt,
    this.caption = '', // optional free-text caption
    this.stickerChoice = '', // optional sticker from kAppStickers
  });
  final String userId;
  final int submittedAt;
  final String caption;
  final String stickerChoice;

  bool get isEmpty => caption.isEmpty && stickerChoice.isEmpty;

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'submitted_at': submittedAt,
    'caption': caption,
    'sticker_choice': stickerChoice,
  };
  static MemeSubmission fromMap(Map<String, dynamic> m) => MemeSubmission(
    userId: m['user_id'] as String,
    submittedAt: m['submitted_at'] as int? ?? 0,
    caption: m['caption'] as String? ?? '',
    stickerChoice: m['sticker_choice'] as String? ?? '',
  );
}

// ── EmojiReaction ─────────────────────────────────────────────────────────────
// Other players' emoji reactions to a specific submission

class EmojiReaction {
  const EmojiReaction({
    required this.reactorId,
    required this.targetUserId, // whose submission they reacted to
    required this.emoji,
    required this.ts,
  });
  final String reactorId;
  final String targetUserId;
  final String emoji;
  final int ts;

  Map<String, dynamic> toMap() => {
    'reactor_id': reactorId,
    'target_user_id': targetUserId,
    'emoji': emoji,
    'ts': ts,
  };
  static EmojiReaction fromMap(Map<String, dynamic> m) => EmojiReaction(
    reactorId: m['reactor_id'] as String,
    targetUserId: m['target_user_id'] as String,
    emoji: m['emoji'] as String,
    ts: m['ts'] as int? ?? 0,
  );
}

// ── MemeRoundRecord ───────────────────────────────────────────────────────────

class MemeRoundRecord {
  const MemeRoundRecord({
    required this.roundNumber,
    required this.prompt,
    required this.submissions,
    required this.votes,
    required this.winnerId,
    required this.reactions,
  });
  final int roundNumber;
  final MemePrompt prompt;
  final Map<String, MemeSubmission> submissions;
  final Map<String, String> votes; // voterId -> targetUserId
  final String? winnerId;
  final List<EmojiReaction> reactions;

  Map<String, dynamic> toMap() => {
    'round_number': roundNumber,
    'prompt': prompt.toMap(),
    'submissions': submissions.map((k, v) => MapEntry(k, v.toMap())),
    'votes': votes,
    'winner_id': winnerId,
    'reactions': reactions.map((r) => r.toMap()).toList(),
  };
  static MemeRoundRecord fromMap(Map<String, dynamic> m) => MemeRoundRecord(
    roundNumber: m['round_number'] as int? ?? 0,
    prompt: MemePrompt.fromMap(m['prompt'] as Map<String, dynamic>),
    submissions:
        (m['submissions'] as Map?)?.map(
          (k, v) => MapEntry(
            k as String,
            MemeSubmission.fromMap(v as Map<String, dynamic>),
          ),
        ) ??
        {},
    votes: (m['votes'] as Map?)?.cast<String, String>() ?? {},
    winnerId: m['winner_id'] as String?,
    reactions:
        (m['reactions'] as List?)
            ?.map((r) => EmojiReaction.fromMap(r as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

enum MemePhase { submitting, voting, results }

// ── MemeState ─────────────────────────────────────────────────────────────────

class MemeState extends GameEngineState {
  const MemeState({
    required super.snapshotAt,
    required this.playerOrder,
    required this.currentPrompt,
    required this.phase,
    required this.submissions,
    required this.votes,
    required this.scores,
    required this.roundNumber,
    required this.maxRounds,
    required this.isOver,
    required this.roundWinnerId,
    this.passes = const {},
    this.reactions = const [],
    this.history = const [],
    this.usedStickersByPlayer = const {},
    this.timerStartedAt,
  });

  final List<String> playerOrder;
  final MemePrompt? currentPrompt;
  final MemePhase phase;
  final Map<String, MemeSubmission> submissions;
  final Map<String, String> votes;

  /// Players who explicitly PASSED this round (chose "Ready for next round"
  /// instead of voting). A pass makes the player "done" for round-completion
  /// without casting a vote, and awards nobody a point. Kept separate from
  /// [votes] so the tally never counts a pass as a vote. Voting completes when
  /// every player has either voted OR passed.
  final Set<String> passes;
  final Map<String, int> scores;
  final int roundNumber;
  final int maxRounds;
  final bool isOver;
  final String? roundWinnerId;
  final List<EmojiReaction> reactions; // reactions to current round submissions
  final List<MemeRoundRecord> history;

  /// Per-PLAYER sticker history for the CURRENT game (item 5) — a sticker
  /// once submitted by a player becomes unavailable to that SAME player for
  /// every later round, but never affects any other player's own
  /// availability. Deliberately not reset by advanceTurn() (unlike
  /// submissions/votes/passes, which are per-round) — this persists for the
  /// life of the game, exactly like scores. Reset only by init() (a
  /// genuinely new game). Survives serialization/reconnect/host migration
  /// for free: it's just part of this same MemeState, restored via the
  /// existing toMap/fromMap + snapshot/broadcast machinery every other
  /// field already relies on.
  final Map<String, Set<String>> usedStickersByPlayer;

  /// Item 1 — epoch ms the current round's submission timer started, or
  /// null when no timer is running. Same lifecycle as TodState/NhieState's
  /// timerStartedAt: set once per round (on init/advanceTurn into
  /// `submitting`), cleared the moment `submitting` ends (every player
  /// submitted, or the timer expired) — never touched by a mere rebuild.
  final int? timerStartedAt;

  MemeState copyWith({
    int? snapshotAt,
    MemePrompt? Function()? currentPrompt,
    MemePhase? phase,
    Map<String, MemeSubmission>? submissions,
    Map<String, String>? votes,
    Set<String>? passes,
    Map<String, int>? scores,
    int? roundNumber,
    int? maxRounds,
    bool? isOver,
    String? Function()? roundWinnerId,
    List<EmojiReaction>? reactions,
    List<MemeRoundRecord>? history,
    Map<String, Set<String>>? usedStickersByPlayer,
    int? Function()? timerStartedAt,
  }) => MemeState(
    snapshotAt: snapshotAt ?? this.snapshotAt,
    playerOrder: playerOrder,
    currentPrompt: currentPrompt != null ? currentPrompt() : this.currentPrompt,
    phase: phase ?? this.phase,
    submissions: submissions ?? this.submissions,
    votes: votes ?? this.votes,
    passes: passes ?? this.passes,
    scores: scores ?? this.scores,
    roundNumber: roundNumber ?? this.roundNumber,
    maxRounds: maxRounds ?? this.maxRounds,
    isOver: isOver ?? this.isOver,
    roundWinnerId: roundWinnerId != null ? roundWinnerId() : this.roundWinnerId,
    reactions: reactions ?? this.reactions,
    history: history ?? this.history,
    usedStickersByPlayer: usedStickersByPlayer ?? this.usedStickersByPlayer,
    timerStartedAt: timerStartedAt != null
        ? timerStartedAt()
        : this.timerStartedAt,
  );

  Map<String, dynamic> toMap() => {
    'snapshot_at': snapshotAt,
    'player_order': playerOrder,
    'current_prompt': currentPrompt?.toMap(),
    'phase': phase.name,
    'submissions': submissions.map((k, v) => MapEntry(k, v.toMap())),
    'votes': votes,
    'passes': passes.toList(),
    'scores': scores,
    'round_number': roundNumber,
    'max_rounds': maxRounds,
    'is_over': isOver,
    'round_winner_id': roundWinnerId,
    'reactions': reactions.map((r) => r.toMap()).toList(),
    'history': history.map((r) => r.toMap()).toList(),
    'used_stickers_by_player': usedStickersByPlayer.map(
      (k, v) => MapEntry(k, v.toList()),
    ),
    'timer_started_at': timerStartedAt,
  };

  static MemeState fromMap(Map<String, dynamic> m) => MemeState(
    snapshotAt: m['snapshot_at'] as int? ?? 0,
    playerOrder: (m['player_order'] as List?)?.cast<String>() ?? [],
    currentPrompt: m['current_prompt'] != null
        ? MemePrompt.fromMap(m['current_prompt'] as Map<String, dynamic>)
        : null,
    phase: MemePhase.values.firstWhere(
      (p) => p.name == m['phase'],
      orElse: () => MemePhase.submitting,
    ),
    submissions:
        (m['submissions'] as Map?)?.map(
          (k, v) => MapEntry(
            k as String,
            MemeSubmission.fromMap(v as Map<String, dynamic>),
          ),
        ) ??
        {},
    votes: (m['votes'] as Map?)?.cast<String, String>() ?? {},
    passes: (m['passes'] as List?)?.cast<String>().toSet() ?? <String>{},
    scores:
        (m['scores'] as Map?)?.map(
          (k, v) => MapEntry(k as String, (v as num).toInt()),
        ) ??
        {},
    roundNumber: m['round_number'] as int? ?? 1,
    maxRounds: m['max_rounds'] as int? ?? 10,
    isOver: m['is_over'] as bool? ?? false,
    roundWinnerId: m['round_winner_id'] as String?,
    reactions:
        (m['reactions'] as List?)
            ?.map((r) => EmojiReaction.fromMap(r as Map<String, dynamic>))
            .toList() ??
        [],
    history:
        (m['history'] as List?)
            ?.map((r) => MemeRoundRecord.fromMap(r as Map<String, dynamic>))
            .toList() ??
        [],
    // Absent on an older/pre-migration snapshot — every player simply
    // starts with no used-sticker history, same as a fresh game.
    usedStickersByPlayer:
        (m['used_stickers_by_player'] as Map?)?.map(
          (k, v) => MapEntry(k as String, (v as List).cast<String>().toSet()),
        ) ??
        {},
    timerStartedAt: m['timer_started_at'] as int?,
  );
}

// ── Events ────────────────────────────────────────────────────────────────────

class MemeSubmitEvent extends GameEngineEvent {
  const MemeSubmitEvent({
    required super.userId,
    required super.ts,
    this.caption = '',
    this.stickerChoice = '',
  });
  final String caption;
  final String stickerChoice;
}

class MemeVoteEvent extends GameEngineEvent {
  const MemeVoteEvent({
    required super.userId,
    required super.ts,
    required this.targetUserId,
  });
  final String targetUserId;
}

class MemeReactEvent extends GameEngineEvent {
  const MemeReactEvent({
    required super.userId,
    required super.ts,
    required this.targetUserId,
    required this.emoji,
  });
  final String targetUserId;
  final String emoji;
}

/// A player choosing NOT to vote this round ("Ready for next round" / Pass).
/// Counts toward round completion without casting a vote or awarding points.
class MemePassEvent extends GameEngineEvent {
  const MemePassEvent({required super.userId, required super.ts});
}

/// Item 1 — dispatched ONCE by the owner's client when its local countdown
/// (derived from state.timerStartedAt) reaches zero during the submitting
/// phase. Handled authoritatively by this engine, not the UI — a stale/
/// tampered client that somehow still tries to submit after this fires is
/// rejected by the same `phase != submitting` guard `_handleSubmit`
/// already has.
class MemeTimerExpiredEvent extends GameEngineEvent {
  const MemeTimerExpiredEvent({required super.userId, required super.ts});
}

// ── Engine ────────────────────────────────────────────────────────────────────

class MemeGameEngine implements BaseGameEngine {
  MemeGameEngine(this._config, {required List<MemePrompt> prompts})
    : _prompts = List.from(prompts)..shuffle();

  final GameConfig _config;
  final List<MemePrompt> _prompts;
  final Set<String> _usedPromptIds = {};
  final _rng = Random();
  late MemeState _state;

  @override
  MemeState get currentState => _state;

  void init(List<String> playerOrder) {
    _usedPromptIds.clear();
    _state = MemeState(
      snapshotAt: DateTime.now().millisecondsSinceEpoch,
      playerOrder: playerOrder,
      currentPrompt: _nextPrompt(),
      phase: MemePhase.submitting,
      submissions: {},
      votes: {},
      passes: {},
      scores: {for (final id in playerOrder) id: 0},
      roundNumber: 1,
      maxRounds: _config.maxRounds,
      isOver: false,
      roundWinnerId: null,
      reactions: [],
      history: [],
      usedStickersByPlayer: {for (final id in playerOrder) id: <String>{}},
      timerStartedAt: _config.timerEnabled
          ? DateTime.now().millisecondsSinceEpoch
          : null,
    );
  }

  MemePrompt? _nextPrompt() {
    final available = _prompts
        .where((p) => !_usedPromptIds.contains(p.id))
        .toList();
    if (available.isEmpty) return null;
    _usedPromptIds.add(available.first.id);
    return available.first;
  }

  @override
  MemeState handleEvent(GameEngineEvent event) {
    _state = switch (event) {
      MemeSubmitEvent e => _handleSubmit(e),
      MemeVoteEvent e => _handleVote(e),
      MemePassEvent e => _handlePass(e),
      MemeReactEvent e => _handleReact(e),
      MemeTimerExpiredEvent e => _onTimerExpired(e),
      _ => _state,
    };
    return _state;
  }

  /// Item 1 — force-closes submissions the same way `_handleSubmit` does
  /// once everyone has submitted, except stragglers simply get no
  /// submission (no sticker/caption recorded) rather than being made to
  /// respond. Reuses the exact same `phase != submitting` guard every
  /// submit/vote/pass handler already has to reject any late submission
  /// arriving after this.
  MemeState _onTimerExpired(MemeTimerExpiredEvent e) {
    if (_state.phase != MemePhase.submitting) return _state;
    return _state.copyWith(
      snapshotAt: DateTime.now().millisecondsSinceEpoch,
      phase: MemePhase.voting,
      timerStartedAt: () => null,
    );
  }

  @override
  MemeState advanceTurn() {
    // Save to history
    final record = _state.currentPrompt != null
        ? MemeRoundRecord(
            roundNumber: _state.roundNumber,
            prompt: _state.currentPrompt!,
            submissions: _state.submissions,
            votes: _state.votes,
            winnerId: _state.roundWinnerId,
            reactions: _state.reactions,
          )
        : null;

    final newRound = _state.roundNumber + 1;
    final nextPrompt = _nextPrompt();
    final isOver = newRound > _state.maxRounds || nextPrompt == null;

    _state = _state.copyWith(
      snapshotAt: DateTime.now().millisecondsSinceEpoch,
      currentPrompt: () => isOver ? null : nextPrompt,
      phase: MemePhase.submitting,
      submissions: {},
      votes: {},
      passes: {},
      roundNumber: newRound,
      isOver: isOver,
      roundWinnerId: () => null,
      reactions: [],
      history: [..._state.history, if (record != null) record],
      // Item 1 — a fresh round always gets a fresh timer, never inherits
      // whatever remained (or had already expired) from the previous one.
      timerStartedAt: () =>
          !isOver && _config.timerEnabled
              ? DateTime.now().millisecondsSinceEpoch
              : null,
    );
    return _state;
  }

  @override
  Map<String, dynamic> serializeState() => _state.toMap();
  @override
  void restoreFromSnapshot(Map<String, dynamic> s) {
    _state = MemeState.fromMap(s);
  }

  /// Inject a prompt into the remaining deck so it can appear during the
  /// current game. Used for premium session-local custom cards — the card
  /// is inserted at a random position to avoid always appearing last. Also
  /// bumps maxRounds if needed so the enlarged deck can't be cut off by the
  /// round limit before every prompt (built-in + custom) is drawn.
  void injectCard(MemePrompt prompt) {
    final pos = _prompts.isNotEmpty ? _rng.nextInt(_prompts.length) : 0;
    _prompts.insert(pos, prompt);
    // Item 18.5 — reuses the ONE shared capacity formula (round_capacity
    // .dart) instead of a second, duplicated (and previously incorrect —
    // Meme draws one prompt per round regardless of player count, but
    // this used to divide by playerCount) calculation.
    final maxPossible = calculateMaxPossibleRounds(
      gameType: GameType.memeGame,
      availableCardCount: _prompts.length,
      activePlayers: _state.playerOrder.length,
      uniqueCards: true,
    );
    if (maxPossible != null && maxPossible > _state.maxRounds) {
      _state = _state.copyWith(maxRounds: maxPossible);
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

  // ── Handlers ────────────────────────────────────────────────────────────────

  MemeState _handleSubmit(MemeSubmitEvent e) {
    if (!_state.playerOrder.contains(e.userId)) return _state;
    if (_state.phase != MemePhase.submitting) return _state;
    if (_state.submissions.containsKey(e.userId)) return _state;
    if (e.caption.isEmpty && e.stickerChoice.isEmpty) {
      return _state; // need at least one
    }
    // Item 5: authoritative (engine-side, not just UI-hidden) rejection of a
    // sticker this SAME player already used earlier in the current game.
    // Silent no-op return, matching every other invalid-action check above —
    // a stale/duplicate/reconnected client resubmitting the same sticker
    // just gets ignored rather than corrupting state or double-counting.
    // Other players' own used-sticker sets are never consulted here, so this
    // never affects anyone but the submitting player.
    if (e.stickerChoice.isNotEmpty &&
        (_state.usedStickersByPlayer[e.userId]?.contains(e.stickerChoice) ??
            false)) {
      return _state;
    }

    final newSubs = {
      ..._state.submissions,
      e.userId: MemeSubmission(
        userId: e.userId,
        submittedAt: e.ts,
        caption: e.caption,
        stickerChoice: e.stickerChoice,
      ),
    };
    final allIn = _state.playerOrder.every((id) => newSubs.containsKey(id));
    final newUsedStickers = e.stickerChoice.isEmpty
        ? _state.usedStickersByPlayer
        : {
            ..._state.usedStickersByPlayer,
            e.userId: {
              ...?_state.usedStickersByPlayer[e.userId],
              e.stickerChoice,
            },
          };
    return _state.copyWith(
      snapshotAt: DateTime.now().millisecondsSinceEpoch,
      submissions: newSubs,
      phase: allIn ? MemePhase.voting : MemePhase.submitting,
      usedStickersByPlayer: newUsedStickers,
      // Item 1 — the timer only matters while submissions are still open;
      // once everyone has submitted there's nothing left to time out.
      timerStartedAt: allIn ? () => null : null,
    );
  }

  MemeState _handleVote(MemeVoteEvent e) {
    // Spectators are never part of playerOrder — this authoritative check
    // (not just a UI-layer gate) is what actually prevents an injected vote
    // from a non-player, which would otherwise close voting on a raw count
    // before every real player has actually voted.
    if (!_state.playerOrder.contains(e.userId)) return _state;
    if (_state.phase != MemePhase.voting) return _state;
    // Reject a duplicate vote AND a vote from someone who already passed —
    // one response per player per round, whichever kind they chose first.
    if (_state.votes.containsKey(e.userId) ||
        _state.passes.contains(e.userId)) {
      return _state;
    }
    // A player can't vote for a target who didn't submit this round (also
    // covers a self-target where the player made no submission).
    if (!_state.submissions.containsKey(e.targetUserId)) return _state;

    final newVotes = {..._state.votes, e.userId: e.targetUserId};
    return _resolveVotingProgress(votes: newVotes, passes: _state.passes);
  }

  /// A player opting out of voting this round. Recorded as a pass (no vote, no
  /// points) and still counts toward round completion.
  MemeState _handlePass(MemePassEvent e) {
    if (!_state.playerOrder.contains(e.userId)) return _state;
    if (_state.phase != MemePhase.voting) return _state;
    // One response per player: reject a pass from someone who already voted or
    // already passed (duplicate-pass protection).
    if (_state.votes.containsKey(e.userId) ||
        _state.passes.contains(e.userId)) {
      return _state;
    }
    final newPasses = {..._state.passes, e.userId};
    return _resolveVotingProgress(votes: _state.votes, passes: newPasses);
  }

  /// Shared authoritative resolution for both vote and pass: if every player
  /// has now either voted OR passed, close the round — tally ONLY real votes
  /// (passes count for nobody), award the round point(s), and move to results.
  /// Otherwise just record the new votes/passes and stay in voting.
  MemeState _resolveVotingProgress({
    required Map<String, String> votes,
    required Set<String> passes,
  }) {
    final everyoneResponded = _state.playerOrder.every(
      (id) => votes.containsKey(id) || passes.contains(id),
    );
    if (!everyoneResponded) {
      return _state.copyWith(
        snapshotAt: DateTime.now().millisecondsSinceEpoch,
        votes: votes,
        passes: passes,
      );
    }

    // Tally the real votes. If NOBODY voted (everyone passed), there is no
    // round winner and no point is awarded — never crown someone off zero
    // votes, and never fall back to player order.
    final tally = <String, int>{};
    for (final t in votes.values) {
      tally[t] = (tally[t] ?? 0) + 1;
    }
    final newScores = Map<String, int>.from(_state.scores);
    String? roundWinnerId;
    if (tally.isNotEmpty) {
      final maxVotes = tally.values.reduce((a, b) => a > b ? a : b);
      // Tied highest = tied winners: every top vote-getter gets the point.
      final winners = tally.entries
          .where((en) => en.value == maxVotes)
          .map((en) => en.key)
          .toList();
      for (final w in winners) {
        newScores[w] = (newScores[w] ?? 0) + 1;
      }
      // roundWinnerId names a single winner only when it's unambiguous.
      roundWinnerId = winners.length == 1 ? winners.single : null;
    }

    return _state.copyWith(
      snapshotAt: DateTime.now().millisecondsSinceEpoch,
      votes: votes,
      passes: passes,
      scores: newScores,
      phase: MemePhase.results,
      roundWinnerId: () => roundWinnerId,
    );
  }

  MemeState _handleReact(MemeReactEvent e) {
    if (!_state.playerOrder.contains(e.userId)) return _state;
    // Real-device bug: a player who never submitted their own
    // caption/sticker (e.g. left slow after a partial-submission timeout)
    // could still react to other players' submissions once phase reaches
    // voting/results. Reuses `submissions` — the SAME map _handleSubmit
    // populates — as the authoritative "has this player responded yet"
    // signal, rather than a second/parallel response-tracking field.
    if (!_state.submissions.containsKey(e.userId)) return _state;
    // One reaction per (reactor, target) pair
    if (_state.reactions.any(
      (r) => r.reactorId == e.userId && r.targetUserId == e.targetUserId,
    ))
      return _state;
    return _state.copyWith(
      snapshotAt: DateTime.now().millisecondsSinceEpoch,
      reactions: [
        ..._state.reactions,
        EmojiReaction(
          reactorId: e.userId,
          targetUserId: e.targetUserId,
          emoji: e.emoji,
          ts: e.ts,
        ),
      ],
    );
  }
}
