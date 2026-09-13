/// Turn-selection policy shared by every game's provider (Truth or Dare,
/// Never Have I Ever, Meme Game): decides which player id is "next" given
/// a fixed player order, the current player, and the set of players
/// currently ineligible for a turn (away, disconnected, or game-muted —
/// "muted = temporary spectator for turn purposes," per the moderation
/// model in RoomMemberEntity.isGameMuted).
///
/// Deliberately NOT a replacement for each engine's own playerOrder /
/// currentPlayerIndex state — scoring, round-counting, and history all
/// stay keyed off that fixed list, unchanged. This is only the POLICY
/// that decides which fixed-list id to advance to next; the caller still
/// looks up that id's index in the engine's own (unchanged) playerOrder
/// to actually advance it. Pure Dart, no Flutter/Provider dependency,
/// matching [BaseGameEngine]'s own "pure Dart" contract — this is the
/// shared "eligible players" mechanism every game's provider should
/// consult instead of re-deriving its own skip/reorder logic.
///
/// The one piece of real, mutable state this owns is the "recently
/// returned" order: when an ineligible player becomes eligible again
/// (unmuted), [markReturned] moves them to the END of the internal
/// rotation instead of leaving them at their original fixed-list
/// position — so they play last among currently-eligible players, not
/// next, and never resume "their old spot" in the sequence. Muting
/// itself needs no explicit call here: pass the current skip set to
/// [nextEligible] each time, and an ineligible id is simply skipped
/// without needing to be removed from the rotation first — so repeated
/// mute/unmute of the same player can never duplicate them in [order].
class TurnQueue {
  TurnQueue(List<String> playerOrder) : _order = List.of(playerOrder);

  final List<String> _order;

  /// The current rotation order (the same ids as the engine's fixed
  /// playerOrder, reordered only by [markReturned] calls) — exposed for
  /// debugging/tests, not consumed by engine state directly.
  List<String> get order => List.unmodifiable(_order);

  /// Moves [id] to the back of the rotation. Call this exactly when a
  /// player transitions from ineligible back to eligible (unmuted) —
  /// never on mute itself, since eligibility during a mute is handled
  /// purely by passing the current skip set to [nextEligible]. A no-op
  /// if [id] isn't part of this queue (e.g. already left the game).
  void markReturned(String id) {
    final idx = _order.indexOf(id);
    if (idx == -1) return;
    _order
      ..removeAt(idx)
      ..add(id);
  }

  /// The next eligible player id strictly after [currentId] in the
  /// rotation, skipping every id in [skipIds] — wraps around, and can
  /// return [currentId] itself if every OTHER player is ineligible (the
  /// "all but one player muted" case: the sole eligible player keeps
  /// taking consecutive turns rather than the game stalling). Returns
  /// null only if every player, [currentId] included, is in [skipIds] —
  /// nobody is eligible for a turn at all; callers must not advance in
  /// that case and should wait for someone to become eligible again.
  String? nextEligible(String currentId, Set<String> skipIds) {
    if (_order.isEmpty) return null;
    final base = _order.indexOf(currentId); // -1 (not found) starts at 0
    for (var step = 1; step <= _order.length; step++) {
      final candidate = _order[(base + step) % _order.length];
      if (!skipIds.contains(candidate)) return candidate;
    }
    return null;
  }
}
