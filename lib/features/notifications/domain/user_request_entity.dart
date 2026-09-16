import '../../packs/domain/pack_entity.dart' show pickLocalized;

/// The kinds of request a user can submit to the Jma3a official/admin side
/// that the backend ALREADY records with a reviewable status.
///
/// Blocking a user is deliberately absent: `blocked_users` has no status,
/// no reviewer and no decision — it takes effect immediately and is not a
/// request at all, so representing it here would misrepresent it as
/// something awaiting a decision. It stays in the existing blocked-users
/// UI.
enum UserRequestType {
  accountDeletion,
  packReport,
  userReport,
  creatorVerification,
  creatorRecoveryAppeal,
}

/// One request the CURRENT user submitted, with whatever decision has been
/// recorded against it.
///
/// A read-only projection over request tables that already exist and that
/// the user can already read under their own RLS policies
/// (`account_deletion_requests: own read`, `pack_reports: own read`,
/// `reports: own read`, `creator_verifications: own read`,
/// `creator_recovery_complaints: own read`). It introduces no second
/// request system, no new write path and no new status vocabulary — every
/// value here is read back from the row the user's own action created.
class UserRequestEntity {
  const UserRequestEntity({
    required this.id,
    required this.type,
    required this.status,
    required this.submittedAt,
    this.decidedAt,
    this.targetTitleJson,
    this.reportTargetType,
  });

  final String id;
  final UserRequestType type;

  /// The RAW status as stored, never normalized into an app-invented
  /// vocabulary. Per source table:
  /// * `account_deletion_requests`, `creator_recovery_complaints`,
  ///   `creator_verifications` — `pending` | `approved` | `rejected`
  /// * `pack_reports`, `reports` (report_status_enum) — `open` |
  ///   `under_review` | `resolved` | `dismissed`
  ///
  /// Rendering maps these to localized labels; an unrecognized value falls
  /// back to the raw string rather than being dropped or relabelled, so a
  /// status added server-side later still shows up honestly.
  final String status;

  final DateTime submittedAt;

  /// `reviewed_at` / `resolved_at` — when the official side actually
  /// acted. Null while the request is still outstanding.
  final DateTime? decidedAt;

  /// The reported pack's jsonb title, for a pack report. Resolved at
  /// render time like every other localized pack title in the app.
  final Map<String, dynamic>? targetTitleJson;

  /// `reports.target_type` (`profile` | `pack` | `chat_message` | `room`).
  ///
  /// Only the KIND of thing that was reported is surfaced, never the
  /// target's identity or what was done about it: a report concerns
  /// another user, and the moderation outcome is not the reporter's to
  /// see.
  final String? reportTargetType;

  /// Account deletion is the only request the backend can actually cancel
  /// (the `cancel_account_deletion_request` RPC), and only while it is
  /// still pending.
  ///
  /// Deliberately NOT widened to the other types just because they also
  /// have a `pending` state — no RPC exists to cancel those, so offering
  /// it would be a button that cannot work.
  bool get canCancel =>
      type == UserRequestType.accountDeletion && status == 'pending';

  /// The reported pack's title in [languageCode], or null when this
  /// request has no pack attached (or the pack row is no longer readable).
  String? targetTitleFor(String languageCode) {
    final json = targetTitleJson;
    if (json == null) return null;
    final title = pickLocalized(json, languageCode);
    return title.isEmpty ? null : title;
  }
}
