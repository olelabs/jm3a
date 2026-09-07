/// Whether a user's streak "flame" should render as active.
///
/// [user_streaks.current_streak] is never zeroed by a cleanup job — it only
/// changes on the next qualifying completion (see
/// `on_game_session_completed()`), so the displayed number survives an
/// inactive period unchanged. The flame is a separate, purely-derived
/// signal: ON while the streak is still "live" (today or yesterday's UTC
/// calendar day saw a qualifying completion — the same one-day grace
/// `on_game_session_completed()` itself uses to decide continue-vs-reset),
/// OFF once more than a day has passed with nothing recorded. Computed
/// fresh on every read, never stored.
///
/// [lastIncrementDate] is `user_streaks.last_increment_date` (a UTC
/// calendar date, no time component) — null means no streak has ever
/// started. [nowUtc] defaults to the real current UTC time; overridable
/// for tests.
bool isStreakFlameOn({required DateTime? lastIncrementDate, DateTime? nowUtc}) {
  if (lastIncrementDate == null) return false;
  final now = nowUtc ?? DateTime.now().toUtc();
  final today = DateTime.utc(now.year, now.month, now.day);
  final last = DateTime.utc(
    lastIncrementDate.year,
    lastIncrementDate.month,
    lastIncrementDate.day,
  );
  final daysSince = today.difference(last).inDays;
  return daysSince >= 0 && daysSince <= 1;
}
