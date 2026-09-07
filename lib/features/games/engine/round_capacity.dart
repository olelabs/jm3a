import 'base_game_engine.dart';

/// Items 2/3/12 — the ONE authoritative source for "how many rounds can
/// this configuration actually support," used identically by:
///   - the room settings UI (to show/clamp the valid Max Rounds range)
///   - the server-side start-game validation (create_game_session RPC,
///     via migration_2026_round_capacity_validation.sql — mirrors this
///     exact formula in SQL so a stale/modified client can never bypass
///     the UI's check)
///
/// No separate formula lives anywhere else — if either side needs to
/// change how capacity is computed, it changes here (and in the SQL
/// mirror) and nowhere else.

/// How many cards/prompts one round consumes for [gameType], given
/// [activePlayers] currently in the game.
///
/// NHIE and Meme each revolve around exactly ONE shared card/prompt per
/// round (every player responds to/votes on the same one) — player count
/// doesn't change how many cards a round costs, only how many people are
/// answering. Truth or Dare is different: every player draws their OWN
/// card each round (a "round" = one full cycle through the player order),
/// so a round costs one card PER ACTIVE PLAYER.
int cardsConsumedPerRound({
  required GameType gameType,
  required int activePlayers,
}) => switch (gameType) {
  GameType.truthOrDare => activePlayers < 1 ? 1 : activePlayers,
  GameType.neverHaveIEver || GameType.memeGame => 1,
};

/// Maximum number of rounds this configuration can sustain without ever
/// asking the engine to draw a card/prompt that doesn't exist.
///
/// Returns null when there's no ceiling to enforce — [uniqueCards] false
/// means repeats are allowed, so the engine's own existing shuffle/repeat
/// behavior (e.g. ToD's 'shuffle' cardRepetitionMode) is relied on exactly
/// as before; [availableCardCount] <= 0 with unique cards required means
/// the game can't run at all (0 rounds).
int? calculateMaxPossibleRounds({
  required GameType gameType,
  required int availableCardCount,
  required int activePlayers,
  required bool uniqueCards,
}) {
  if (!uniqueCards) return null;
  if (availableCardCount <= 0) return 0;
  final perRound = cardsConsumedPerRound(
    gameType: gameType,
    activePlayers: activePlayers,
  );
  if (perRound <= 0) return 0;
  return availableCardCount ~/ perRound;
}

/// Item 3/8 — whether [selectedMaxRounds] is achievable under this
/// configuration. Always true when [uniqueCards] is false (no ceiling —
/// see [calculateMaxPossibleRounds]).
bool isMaxRoundsValid({
  required GameType gameType,
  required int availableCardCount,
  required int activePlayers,
  required bool uniqueCards,
  required int selectedMaxRounds,
}) {
  final maxPossible = calculateMaxPossibleRounds(
    gameType: gameType,
    availableCardCount: availableCardCount,
    activePlayers: activePlayers,
    uniqueCards: uniqueCards,
  );
  if (maxPossible == null) return true;
  return selectedMaxRounds <= maxPossible;
}
