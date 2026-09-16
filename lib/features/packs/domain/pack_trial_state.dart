/// Trial Packs — try before purchase.
///
/// Client-facing trial state for a pack, as returned by the server-
/// authoritative RPCs (get_eligible_trial_packs / start_pack_trial /
/// try_consume_trial_card — see migration_2026_pack_trial.sql). This is
/// a read model only: the client never computes or persists trial state
/// itself, it only reflects what the database last reported.
enum PackTrialState {
  /// This pack has no trial configuration, or trial doesn't apply here
  /// (e.g. the user already owns it) — play normally, no trial UI.
  notTrialPack,

  /// Trial-enabled, unowned by the current user, not yet started.
  eligible,

  /// Trial-enabled, unowned, started, cards_played < trial_card_count.
  active,

  /// Trial-enabled, unowned, cards_played >= trial_card_count — the
  /// purchase prompt should be shown; no further trial cards.
  exhausted,

  /// The current user owns this pack (purchased) — normal owned-pack
  /// behavior, trial logic never applies.
  owned,
}

/// A snapshot of a user's trial progress for one pack, as reported by
/// try_consume_trial_card()/start_pack_trial(). Immutable — a fresh one
/// is built from each RPC response, never mutated locally.
class PackTrialStatus {
  const PackTrialStatus({
    this.state = PackTrialState.notTrialPack,
    this.cardsPlayed = 0,
    this.trialCardCount = 0,
  });

  final PackTrialState state;
  final int cardsPlayed;
  final int trialCardCount;

  int get cardsRemaining =>
      (trialCardCount - cardsPlayed).clamp(0, trialCardCount);

  bool get isExhausted => state == PackTrialState.exhausted;
  bool get isActive => state == PackTrialState.active;

  /// Maps try_consume_trial_card()'s `reason` column to a state.
  ///
  /// Bug fix (real-device report): 'trial' means the RPC's own
  /// `allowed` was true — this specific card WAS legitimately granted,
  /// including the exact card that brings cardsPlayed to trialCardCount
  /// (e.g. the 5th card when trialCardCount=5). Previously this branch
  /// treated reaching the limit as immediate `exhausted`, which made the
  /// caller (ownerAdvanceTurn's gate) refuse to reveal the LAST allowed
  /// card — stopping the trial one card early (4 cards shown instead of
  /// 5) instead of at the configured count. `exhausted` must only ever
  /// come from the RPC's own explicit `trial_exhausted` reason — the
  /// response returned by the NEXT call, the one that tried to go PAST
  /// the limit (e.g. requesting card 6), which the RPC itself refuses
  /// with `allowed: false` before touching cards_played at all. This is
  /// the one thing that actually decides "reveal it" vs "stop here" —
  /// get it right and every card 1..trialCardCount is shown, the
  /// (trialCardCount+1)th never is.
  factory PackTrialStatus.fromConsumeResult({
    required bool allowed,
    required String reason,
    required int cardsPlayed,
    required int trialCardCount,
  }) {
    final state = switch (reason) {
      'not_trial_pack' => PackTrialState.notTrialPack,
      'owned' => PackTrialState.owned,
      'trial_exhausted' => PackTrialState.exhausted,
      'no_active_trial' => PackTrialState.eligible,
      'trial' => PackTrialState.active,
      _ => PackTrialState.notTrialPack,
    };
    return PackTrialStatus(
      state: state,
      cardsPlayed: cardsPlayed,
      trialCardCount: trialCardCount,
    );
  }
}
