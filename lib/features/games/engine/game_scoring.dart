/// Shared, pure scoreboard helpers used by every game's results screen
/// (Truth-or-Dare, NHIE / Who's Most Likely, Meme). Centralising the winner /
/// ranking rules here is what keeps "who won" consistent across games and
/// removes the per-screen tie-break bug where a tied or all-zero board silently
/// crowned whoever happened to sit first in the player order (usually the host)
/// simply because the results list was sorted by a stable small-list sort.
library;

/// 0-based DENSE rank of [score] within [allScores]: the number of players who
/// scored STRICTLY higher. Players tied on the same score therefore share the
/// same rank (and thus the same medal), instead of being ordered by their
/// position in the list.
int denseRankForScore(int score, Iterable<int> allScores) =>
    allScores.where((s) => s > score).length;

/// The authoritative set of winner user IDs for a finished game: everyone who
/// shares the single highest score — but ONLY when that top score is greater
/// than zero. A board where nobody scored (all zero) has NO winner, so this
/// returns an empty set rather than arbitrarily picking the first player.
/// A genuine tie returns every tied user id.
Set<String> topScorers(Map<String, int> scores) {
  if (scores.isEmpty) return <String>{};
  final top = scores.values.reduce((a, b) => a > b ? a : b);
  if (top <= 0) return <String>{};
  return scores.entries
      .where((e) => e.value == top)
      .map((e) => e.key)
      .toSet();
}

/// Whether the finished game has a single, unambiguous winner (exactly one top
/// scorer with a positive score). False for an all-zero board or a tie.
bool hasSoleWinner(Map<String, int> scores) => topScorers(scores).length == 1;
