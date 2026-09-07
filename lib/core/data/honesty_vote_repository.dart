import 'package:supabase_flutter/supabase_flutter.dart';

import 'base_repository.dart';

/// Result of a cast_honesty_vote call.
class HonestyVoteResult {
  const HonestyVoteResult({
    required this.applied,
    required this.voteId,
    required this.isHonest,
    this.points,
    this.reason,
  });

  /// False when this was a no-op — the caller already voted on this exact
  /// (session, responseKey, target) before. [isHonest] then reflects the
  /// ORIGINAL vote (votes are immutable once cast — see the migration
  /// header for cast_honesty_vote), not what this call attempted to send.
  final bool applied;
  final String voteId;
  final bool isHonest;

  /// The point delta actually applied to the target's honesty_points.
  /// Null when [applied] is false (nothing was applied).
  final int? points;

  /// The reason stored with a "Not honest" vote — null for an Honest vote,
  /// and (on a duplicate/idempotent call) reflects the ORIGINAL reason, not
  /// whatever text this call attempted to send.
  final String? reason;

  static HonestyVoteResult fromMap(Map<String, dynamic> m) => HonestyVoteResult(
    applied: m['applied'] as bool? ?? false,
    voteId: m['vote_id'] as String? ?? '',
    isHonest: m['is_honest'] as bool? ?? false,
    points: (m['points'] as num?)?.toInt(),
    reason: m['reason'] as String?,
  );
}

/// One reason a fellow player gave for a "Not honest" vote on a response —
/// deliberately excludes voter identity (see honesty_vote_repository's own
/// getDishonestReasons doc comment for why).
class HonestyVoteReason {
  const HonestyVoteReason({required this.reason, required this.createdAt});
  final String reason;
  final DateTime createdAt;

  static HonestyVoteReason fromMap(Map<String, dynamic> m) => HonestyVoteReason(
    reason: m['reason'] as String? ?? '',
    createdAt: DateTime.parse(m['created_at'] as String),
  );
}

/// Pure, shared client-side eligibility check — mirrors (but does not
/// replace) the server-side rules cast_honesty_vote enforces, so the UI
/// can disable/hide the vote buttons for an ineligible viewer instead of
/// round-tripping to the server just to get rejected. The server remains
/// the actual authority; this is UX-only and used identically by all three
/// games rather than each reimplementing its own version.
bool canCastHonestyVote({
  required String voterId,
  required String targetUserId,
  required List<String> participantIds,
  required bool alreadyVoted,
}) {
  if (voterId.isEmpty || targetUserId.isEmpty) return false;
  if (voterId == targetUserId) return false;
  if (alreadyVoted) return false;
  return participantIds.contains(voterId) && participantIds.contains(targetUserId);
}

/// ONE shared mechanism for casting an Honest/Not-honest vote on another
/// player's response, reused by Truth or Dare, Never Have I Ever, and Meme
/// Game alike — all three route through the same `cast_honesty_vote` RPC
/// (see migration 20260831090100_honesty_points.sql), never three
/// independent implementations. All server-side authorization (self-vote,
/// outsider, non-participant target, duplicate/idempotency) is enforced by
/// that RPC — this repository is a thin, honest pass-through, never a
/// second place that could disagree with the server about what's allowed.
class HonestyVoteRepository extends BaseRepository {
  HonestyVoteRepository._();
  static final HonestyVoteRepository _instance = HonestyVoteRepository._();
  static HonestyVoteRepository get instance => _instance;

  final _supabase = Supabase.instance.client;

  /// [responseKey] is a game-agnostic stable identifier for "the response
  /// being voted on" within [gameSessionId] — by convention 'round:N' for
  /// all three games (see the migration header for why this is safe to
  /// share across ToD/NHIE/Meme without a game-specific shape).
  ///
  /// [reason] is required by the server for a "Not honest" vote (min 3
  /// trimmed characters — see cast_honesty_vote's own validation in
  /// 20260901090000_honesty_vote_reason.sql) and ignored for an Honest
  /// vote. This method does not pre-validate it — the caller (the
  /// dishonest-reason sheet) already gates Submit on the same rule for a
  /// responsive UI, but the server call here is what's actually
  /// authoritative; a stale/tampered client sending an empty reason still
  /// gets rejected here, not silently accepted.
  Future<HonestyVoteResult> castVote({
    required String gameSessionId,
    required String responseKey,
    required String targetUserId,
    required bool isHonest,
    String? reason,
    // 'truth' | 'dare' | 'punishment' | null. Only Truth or Dare's caller
    // (TodGameProvider) has a meaningful value — NHIE/Meme pass null and
    // get the same flat rate as before this parameter existed. The
    // server derives the actual point delta from this; it is never a
    // point value itself. See cast_honesty_vote's p_card_type.
    String? cardType,
  }) => guardedCall(
    operationName: 'castHonestyVote',
    operation: () async {
      final result = await _supabase.rpc(
        'cast_honesty_vote',
        params: {
          'p_game_session_id': gameSessionId,
          'p_response_key': responseKey,
          'p_target_user_id': targetUserId,
          'p_is_honest': isHonest,
          'p_reason': reason,
          'p_card_type': cardType,
        },
      );
      return HonestyVoteResult.fromMap(Map<String, dynamic>.from(result as Map));
    },
  );

  /// Every "Not honest" reason left for the CURRENT user's own response —
  /// relies entirely on honesty_votes' existing "participant read" RLS
  /// policy (voter OR target may SELECT), which already scopes this to
  /// rows where the caller is the target; no new policy or RPC was needed.
  /// Deliberately selects only `reason, created_at` — never `voter_id` —
  /// so voter identity is never surfaced to the affected player, matching
  /// the existing in-game vote UI's own anonymity (a product choice, not a
  /// stricter security boundary than the row's own RLS already allows).
  Future<List<HonestyVoteReason>> getDishonestReasons({
    required String gameSessionId,
    required String responseKey,
  }) => guardedCall(
    operationName: 'getDishonestReasons',
    operation: () async {
      final rows = await _supabase
          .from('honesty_votes')
          .select('reason, created_at')
          .eq('game_session_id', gameSessionId)
          .eq('response_key', responseKey)
          .eq('is_honest', false)
          .not('reason', 'is', null)
          .order('created_at');
      return (rows as List)
          .map((r) => HonestyVoteReason.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();
    },
  );
}
