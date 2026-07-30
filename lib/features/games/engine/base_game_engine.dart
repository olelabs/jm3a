// ── GameType ──────────────────────────────────────────────────────────────────
enum GameType {
  truthOrDare,
  neverHaveIEver,
  memeGame;

  String get displayName => switch (this) {
    GameType.truthOrDare => 'Truth or Dare',
    GameType.neverHaveIEver => 'Never Have I Ever',
    GameType.memeGame => 'Meme Game',
  };

  String toDbString() => switch (this) {
    GameType.truthOrDare => 'truth_or_dare',
    GameType.neverHaveIEver => 'never_have_i_ever',
    GameType.memeGame => 'meme_game',
  };
}

// ── TurnOrder ─────────────────────────────────────────────────────────────────
enum TurnOrderMode { circular, random }

// ── GameConfig ────────────────────────────────────────────────────────────────
/// Snapshot of room settings at game-start time.
/// Immutable for the lifetime of the session.
// class GameConfig {
//   const GameConfig({
//     required this.maxRounds,
//     required this.turnTimerSeconds,
//     required this.allowSkip,
//     required this.allowSpicy,
//     this.turnOrderMode = TurnOrderMode.circular,
//     this.enablePunishments = true,
//     this.packId,
//     this.language = 'en',
//   });

//   final int maxRounds;
//   final int turnTimerSeconds;
//   final bool allowSkip;
//   final bool allowSpicy;
//   final TurnOrderMode turnOrderMode;
//   final bool enablePunishments;
//   final String? packId;
//   final String language;

//   bool get timerEnabled => turnTimerSeconds > 0;

//   Map<String, dynamic> toMap() => {
//     'max_rounds': maxRounds,
//     'turn_timer_secs': turnTimerSeconds,
//     'allow_skip': allowSkip,
//     'allow_spicy': allowSpicy,
//     'turn_order_mode': turnOrderMode.name,
//     'enable_punishments': enablePunishments,
//     'pack_id': packId,
//     'language': language,
//   };

//   static GameConfig fromMap(Map<String, dynamic> m) => GameConfig(
//     maxRounds: m['max_rounds'] as int? ?? 10,
//     turnTimerSeconds: m['turn_timer_secs'] as int? ?? 60,
//     allowSkip: m['allow_skip'] as bool? ?? true,
//     allowSpicy: m['allow_spicy'] as bool? ?? false,
//     turnOrderMode: TurnOrderMode.values.firstWhere(
//       (t) => t.name == m['turn_order_mode'],
//       orElse: () => TurnOrderMode.circular,
//     ),
//     enablePunishments: m['enable_punishments'] as bool? ?? true,
//     packId: m['pack_id'] as String?,
//     language: m['language'] as String? ?? 'en',
//   );
// }

// ── Updated GameConfig — replace existing class in base_game_engine.dart ──────
// Add this to lib/features/games/engine/base_game_engine.dart

class GameConfig {
  const GameConfig({
    required this.maxRounds,
    required this.turnTimerSeconds,
    required this.allowSkip,
    required this.allowSpicy,
    this.packId,
    this.language = 'en',
    this.turnOrderMode = TurnOrderMode.circular,
    this.enablePunishments = false,
    this.punishmentSource = 'players',
    List<String>? suggestedPunishments,
    this.proofVisibilityPolicy = 'everyone',
    this.proofViewSeconds = 5,
    this.proofReplayMode = 'once',
  }) : suggestedPunishments = suggestedPunishments ?? const [];

  bool get timerEnabled => turnTimerSeconds > 0;

  final int maxRounds;
  final int turnTimerSeconds;
  final bool allowSkip;
  final TurnOrderMode turnOrderMode;
  final bool allowSpicy;
  final String? packId;
  final String language;
  final bool enablePunishments;

  /// 'players' (default — the existing live peer-vote flow, unchanged) or
  /// 'pack' (a skip resolves directly from the selected pack's
  /// suggested_punishments instead of the peer-proposal phase). Only
  /// meaningful when [enablePunishments] is true and the room's pack
  /// actually has punishments to draw from.
  final String punishmentSource;

  /// The selected pack's creator-authored punishment options (empty or
  /// >=10, enforced at pack-creation time) — only consulted when
  /// [punishmentSource] is 'pack'.
  final List<String> suggestedPunishments;

  // ── Truth or Dare proof settings ──────────────────────────────────────
  // Kept as plain strings (not TodProofVisibility/TodProofViewMode) so
  // this shared, cross-game config file doesn't import ToD-specific
  // domain types — ToD's own code maps these onto its real enums at the
  // point a turn's proof is actually submitted. Meaningless for NHIE/Meme,
  // same as allowSpicy/enablePunishments already are for them.
  /// 'everyone' | 'players_only' | 'spectators_only'
  final String proofVisibilityPolicy;
  /// Seconds a timed-mode proof stays visible before auto-hiding.
  final int proofViewSeconds;
  /// 'once' | 'replay_once'
  final String proofReplayMode;

  Map<String, dynamic> toMap() => {
    'max_rounds': maxRounds,
    'turn_timer_secs': turnTimerSeconds,
    'allow_skip': allowSkip,
    'allow_spicy': allowSpicy,
    'pack_id': packId,
    'language': language,
    'turn_order_mode': turnOrderMode.name,
    'enable_punishments': enablePunishments,
    'punishment_source': punishmentSource,
    'suggested_punishments': suggestedPunishments,
    'proof_visibility_policy': proofVisibilityPolicy,
    'proof_view_seconds': proofViewSeconds,
    'proof_replay_mode': proofReplayMode,
  };

  static GameConfig fromMap(Map<String, dynamic> m) => GameConfig(
    maxRounds: m['max_rounds'] as int? ?? 10,
    turnTimerSeconds: m['turn_timer_secs'] as int? ?? 60,
    allowSkip: m['allow_skip'] as bool? ?? true,
    allowSpicy: m['allow_spicy'] as bool? ?? false,
    packId: m['pack_id'] as String?,
    language: m['language'] as String? ?? 'en',
    enablePunishments: m['enable_punishments'] as bool? ?? false,
    punishmentSource: m['punishment_source'] as String? ?? 'players',
    suggestedPunishments: (m['suggested_punishments'] as List?)
        ?.map((e) => e.toString())
        .toList(),
    proofVisibilityPolicy:
        m['proof_visibility_policy'] as String? ?? 'everyone',
    proofViewSeconds: m['proof_view_seconds'] as int? ?? 5,
    proofReplayMode: m['proof_replay_mode'] as String? ?? 'once',
    turnOrderMode: TurnOrderMode.values.firstWhere(
      (t) => t.name == m['turn_order_mode'],
      orElse: () => TurnOrderMode.circular,
    ),
  );
}

// ── Base state ────────────────────────────────────────────────────────────────
/// Every game state must carry a snapshotAt timestamp.
/// Used by followers to discard stale broadcasts.
abstract class GameEngineState {
  const GameEngineState({required this.snapshotAt});
  final int snapshotAt;
}

// ── Base event ────────────────────────────────────────────────────────────────
/// All player-sent events carry userId + timestamp for ordering.
abstract class GameEngineEvent {
  const GameEngineEvent({required this.userId, required this.ts});
  final String userId;
  final int ts;
}

// ── Base engine contract ──────────────────────────────────────────────────────
/// Pure Dart — no Flutter, no Provider.
/// The owner client runs the engine; followers restore from broadcast snapshots.
abstract class BaseGameEngine {
  GameEngineState get currentState;

  /// Process an incoming player event (owner only).
  GameEngineState handleEvent(GameEngineEvent event);

  /// Advance to the next turn (owner only).
  GameEngineState advanceTurn();

  /// Serialize current state for broadcast payload.
  Map<String, dynamic> serializeState();

  /// Restore from a received broadcast snapshot.
  void restoreFromSnapshot(Map<String, dynamic> snapshot);

  bool get isGameOver;
}
