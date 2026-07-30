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
    this.reactions = const [],
    this.history = const [],
  });

  final List<String> playerOrder;
  final MemePrompt? currentPrompt;
  final MemePhase phase;
  final Map<String, MemeSubmission> submissions;
  final Map<String, String> votes;
  final Map<String, int> scores;
  final int roundNumber;
  final int maxRounds;
  final bool isOver;
  final String? roundWinnerId;
  final List<EmojiReaction> reactions; // reactions to current round submissions
  final List<MemeRoundRecord> history;

  MemeState copyWith({
    int? snapshotAt,
    MemePrompt? Function()? currentPrompt,
    MemePhase? phase,
    Map<String, MemeSubmission>? submissions,
    Map<String, String>? votes,
    Map<String, int>? scores,
    int? roundNumber,
    int? maxRounds,
    bool? isOver,
    String? Function()? roundWinnerId,
    List<EmojiReaction>? reactions,
    List<MemeRoundRecord>? history,
  }) => MemeState(
    snapshotAt: snapshotAt ?? this.snapshotAt,
    playerOrder: playerOrder,
    currentPrompt: currentPrompt != null ? currentPrompt() : this.currentPrompt,
    phase: phase ?? this.phase,
    submissions: submissions ?? this.submissions,
    votes: votes ?? this.votes,
    scores: scores ?? this.scores,
    roundNumber: roundNumber ?? this.roundNumber,
    maxRounds: maxRounds ?? this.maxRounds,
    isOver: isOver ?? this.isOver,
    roundWinnerId: roundWinnerId != null ? roundWinnerId() : this.roundWinnerId,
    reactions: reactions ?? this.reactions,
    history: history ?? this.history,
  );

  Map<String, dynamic> toMap() => {
    'snapshot_at': snapshotAt,
    'player_order': playerOrder,
    'current_prompt': currentPrompt?.toMap(),
    'phase': phase.name,
    'submissions': submissions.map((k, v) => MapEntry(k, v.toMap())),
    'votes': votes,
    'scores': scores,
    'round_number': roundNumber,
    'max_rounds': maxRounds,
    'is_over': isOver,
    'round_winner_id': roundWinnerId,
    'reactions': reactions.map((r) => r.toMap()).toList(),
    'history': history.map((r) => r.toMap()).toList(),
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
      scores: {for (final id in playerOrder) id: 0},
      roundNumber: 1,
      maxRounds: _config.maxRounds,
      isOver: false,
      roundWinnerId: null,
      reactions: [],
      history: [],
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
      MemeReactEvent e => _handleReact(e),
      _ => _state,
    };
    return _state;
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
      roundNumber: newRound,
      isOver: isOver,
      roundWinnerId: () => null,
      reactions: [],
      history: [..._state.history, if (record != null) record],
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
    final playerCount = _state.playerOrder.length;
    if (playerCount > 0) {
      final requiredRounds = (_prompts.length / playerCount).ceil();
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

  // ── Handlers ────────────────────────────────────────────────────────────────

  MemeState _handleSubmit(MemeSubmitEvent e) {
    if (!_state.playerOrder.contains(e.userId)) return _state;
    if (_state.phase != MemePhase.submitting) return _state;
    if (_state.submissions.containsKey(e.userId)) return _state;
    if (e.caption.isEmpty && e.stickerChoice.isEmpty)
      return _state; // need at least one

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
    return _state.copyWith(
      snapshotAt: DateTime.now().millisecondsSinceEpoch,
      submissions: newSubs,
      phase: allIn ? MemePhase.voting : MemePhase.submitting,
    );
  }

  MemeState _handleVote(MemeVoteEvent e) {
    // Spectators are never part of playerOrder — this authoritative check
    // (not just a UI-layer gate) is what actually prevents an injected vote
    // from a non-player, which would otherwise close voting on a raw count
    // before every real player has actually voted.
    if (!_state.playerOrder.contains(e.userId)) return _state;
    if (_state.phase != MemePhase.voting) return _state;
    if (_state.votes.containsKey(e.userId)) return _state;

    final newVotes = {..._state.votes, e.userId: e.targetUserId};
    final allVoted = _state.playerOrder.every(
      (id) => newVotes.containsKey(id),
    );
    if (!allVoted)
      return _state.copyWith(
        snapshotAt: DateTime.now().millisecondsSinceEpoch,
        votes: newVotes,
      );

    final tally = <String, int>{};
    for (final t in newVotes.values) tally[t] = (tally[t] ?? 0) + 1;
    final winnerId =
        (tally.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;

    final newScores = Map<String, int>.from(_state.scores);
    newScores[winnerId] = (newScores[winnerId] ?? 0) + 1;

    return _state.copyWith(
      snapshotAt: DateTime.now().millisecondsSinceEpoch,
      votes: newVotes,
      scores: newScores,
      phase: MemePhase.results,
      roundWinnerId: () => winnerId,
    );
  }

  MemeState _handleReact(MemeReactEvent e) {
    if (!_state.playerOrder.contains(e.userId)) return _state;
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
