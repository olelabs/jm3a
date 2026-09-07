import 'package:flutter/material.dart';

import '../../../core/data/honesty_vote_repository.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import 'dishonest_reason_sheet.dart';

/// Compact Honest/Not-honest icon-button pair for use inline in a list row
/// (NHIE's per-player reveal row, Meme's per-submission row) where a
/// full-size labeled button pair (see ToD's own _HonestyVoteRow, which has
/// more vertical room since it shows one target at a time) would be too
/// wide. Same shared `cast_honesty_vote` mechanism underneath — this is
/// purely a presentation variant, not a second voting system.
///
/// Reduced to nothing for anyone ineligible (self, spectator, non-
/// participant, already voted) — never a disabled/greyed pair, matching
/// "no exposed internal scoring mechanics".
class CompactHonestyVoteButtons extends StatefulWidget {
  const CompactHonestyVoteButtons({
    super.key,
    required this.voterId,
    required this.targetUserId,
    required this.participantIds,
    required this.responseKey,
    required this.hasVoted,
    required this.onVote,
  });

  final String voterId;
  final String targetUserId;
  final List<String> participantIds;
  final String responseKey;
  final bool hasVoted;
  final Future<void> Function({
    required String targetUserId,
    required bool isHonest,
    String? reason,
  }) onVote;

  @override
  State<CompactHonestyVoteButtons> createState() =>
      _CompactHonestyVoteButtonsState();
}

class _CompactHonestyVoteButtonsState
    extends State<CompactHonestyVoteButtons> {
  bool _submitting = false;

  Future<void> _vote(bool isHonest, {String? reason}) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.onVote(
        targetUserId: widget.targetUserId,
        isHonest: isHonest,
        reason: reason,
      );
    } catch (_) {
      if (mounted) {
        context.showSnackBar(context.l10n.honestyVoteFailed, isError: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// "Not honest" requires a reason before the vote is sent — see
  /// DishonestReasonSheet for the shared min-length UX gate (the server
  /// independently re-validates regardless).
  Future<void> _voteDishonest() async {
    final reason = await showDishonestReasonSheet(context);
    if (reason == null) return; // cancelled
    await _vote(false, reason: reason);
  }

  @override
  Widget build(BuildContext context) {
    final eligible = canCastHonestyVote(
      voterId: widget.voterId,
      targetUserId: widget.targetUserId,
      participantIds: widget.participantIds,
      alreadyVoted: widget.hasVoted,
    );
    if (!eligible) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: context.l10n.honestyVoteHonest,
          onPressed: _submitting ? null : () => _vote(true),
          icon: Icon(
            Icons.check_circle_outline_rounded,
            size: 18,
            color: AppColors.successGreen,
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: context.l10n.honestyVoteNotHonest,
          onPressed: _submitting ? null : _voteDishonest,
          icon: Icon(Icons.cancel_outlined, size: 18, color: AppColors.errorRed),
        ),
      ],
    );
  }
}

/// Full-size, labeled Honest/Not-honest button pair for a single-target
/// reveal screen (ToD's own result view, which shows one response at a
/// time and has vertical room for labels — unlike NHIE/Meme's per-row
/// reveal list, which uses the compact icon-only variant above). Same
/// shared `cast_honesty_vote` mechanism, same eligibility rule, just a
/// different presentation for a different layout context.
///
/// Extracted from TodCardScreen's private `_HonestyVoteRow` into this
/// public, provider-free widget specifically so it can be rendered
/// directly in a real widget test (see
/// test/friends_narrow_width_layout_test.dart-style real-widget coverage)
/// without a live TodGameProvider — it takes plain values/callbacks
/// instead. This is also the exact widget a real-device trace identified
/// as the root cause of "Player B sees a blank ToD result screen": both
/// OutlinedButtons inherited the app-wide theme's
/// minimumSize: Size(double.infinity, 52) while sitting in a Row that
/// gives non-Expanded children unbounded max width — see the
/// minimumSize:Size.zero overrides below.
class HonestyVoteRow extends StatefulWidget {
  const HonestyVoteRow({
    super.key,
    required this.voterId,
    required this.targetUserId,
    required this.participantIds,
    required this.hasVoted,
    required this.onVote,
  });

  final String voterId;
  final String targetUserId;
  final List<String> participantIds;
  final bool hasVoted;
  final Future<void> Function({
    required String targetUserId,
    required bool isHonest,
    String? reason,
  }) onVote;

  @override
  State<HonestyVoteRow> createState() => _HonestyVoteRowState();
}

class _HonestyVoteRowState extends State<HonestyVoteRow> {
  bool _submitting = false;

  Future<void> _vote(bool isHonest, {String? reason}) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.onVote(
        targetUserId: widget.targetUserId,
        isHonest: isHonest,
        reason: reason,
      );
    } catch (_) {
      if (mounted) {
        context.showSnackBar(context.l10n.honestyVoteFailed, isError: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _voteDishonest() async {
    final reason = await showDishonestReasonSheet(context);
    if (reason == null) return; // cancelled
    await _vote(false, reason: reason);
  }

  @override
  Widget build(BuildContext context) {
    final eligible = canCastHonestyVote(
      voterId: widget.voterId,
      targetUserId: widget.targetUserId,
      participantIds: widget.participantIds,
      alreadyVoted: widget.hasVoted,
    );
    if (!eligible) {
      if (widget.hasVoted) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            context.l10n.honestyVoteRecorded,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }
    // ROOT CAUSE of the "Player B blank ToD result screen" report: both
    // buttons below inherit the app-wide OutlinedButton theme's
    // minimumSize: Size(double.infinity, 52) (see app_theme.dart —
    // intended for full-width primary CTAs). A Row gives an UNBOUNDED max
    // width to non-Expanded children, so two themed buttons side by side
    // threw "BoxConstraints forces an infinite width" the instant this
    // row rendered for a non-turn player — confirmed via a real-device
    // Flutter creator-chain trace. Explicit minimumSize:Size.zero (not a
    // fixed width — "Honest"/"Not honest" translate to different lengths
    // per locale; each button sizes to its own label/icon content
    // instead) is the same established fix used throughout this
    // investigation for this exact theme interaction.
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 34,
            child: OutlinedButton.icon(
              onPressed: _submitting ? null : () => _vote(true),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
              label: Text(context.l10n.honestyVoteHonest),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.successGreen,
                side: BorderSide(color: AppColors.successGreen.withOpacity(0.5)),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 34,
            child: OutlinedButton.icon(
              onPressed: _submitting ? null : _voteDishonest,
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: Text(context.l10n.honestyVoteNotHonest),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.errorRed,
                side: BorderSide(color: AppColors.errorRed.withOpacity(0.5)),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
