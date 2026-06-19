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
  });

  bool get timerEnabled => turnTimerSeconds > 0;

  final int maxRounds;
  final int turnTimerSeconds;
  final bool allowSkip;
  final TurnOrderMode turnOrderMode;
  final bool allowSpicy;
  final String? packId;
  final String language;
  final bool enablePunishments;

  Map<String, dynamic> toMap() => {
    'max_rounds': maxRounds,
    'turn_timer_secs': turnTimerSeconds,
    'allow_skip': allowSkip,
    'allow_spicy': allowSpicy,
    'pack_id': packId,
    'language': language,
    'turn_order_mode': turnOrderMode.name,
    'enable_punishments': enablePunishments,
  };

  static GameConfig fromMap(Map<String, dynamic> m) => GameConfig(
    maxRounds: m['max_rounds'] as int? ?? 10,
    turnTimerSeconds: m['turn_timer_secs'] as int? ?? 60,
    allowSkip: m['allow_skip'] as bool? ?? true,
    allowSpicy: m['allow_spicy'] as bool? ?? false,
    packId: m['pack_id'] as String?,
    language: m['language'] as String? ?? 'en',
    enablePunishments: m['enable_punishments'] as bool? ?? false,
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
