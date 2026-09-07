import 'package:flutter/material.dart';

import '../../../core/data/honesty_vote_repository.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';

/// Shown to the player whose response a round was — surfaces every
/// "Not honest" reason left for it, grouped, WITHOUT voter identity (see
/// HonestyVoteRepository.getDishonestReasons for the RLS/anonymity
/// contract). Shared by ToD/NHIE/Meme's result views (one widget, not
/// three) — [fetch] is each game's own `getMyDishonestReasons()`.
///
/// Fetched exactly once per [roundKey] (pass the round/turn identifier as
/// the widget key from the call site, e.g. `ValueKey('dishonest_$n')`),
/// never from build()/a stream callback, so it can't re-fire on rebuild.
/// A reason cast by another player after this fetch won't appear until
/// the next round's fresh fetch — an accepted, documented limitation
/// (honesty_votes has no realtime broadcast; adding one purely for this
/// secondary reveal was judged not worth a new subscription for how brief
/// this on-screen window is).
class DishonestReasonsPanel extends StatefulWidget {
  const DishonestReasonsPanel({super.key, required this.fetch});
  final Future<List<HonestyVoteReason>> Function() fetch;

  @override
  State<DishonestReasonsPanel> createState() => _DishonestReasonsPanelState();
}

class _DishonestReasonsPanelState extends State<DishonestReasonsPanel> {
  // Wrapped so a SYNCHRONOUS throw from widget.fetch() (not just an async
  // rejection) can never escape this field's lazy initializer and crash
  // this widget's build — this is a purely secondary/optional section;
  // see this file's own doc comment and TodGameProvider.onStateBroadcast's
  // matching fix for the "honesty UI must never blank the response"
  // requirement. Currently every real `fetch` implementation already
  // guards against this (see TodGameProvider.getMyDishonestReasons), but
  // this widget is shared across three games' call sites and must not
  // depend on every future caller getting that right.
  late final Future<List<HonestyVoteReason>> _future = _safeFetch();

  Future<List<HonestyVoteReason>> _safeFetch() {
    try {
      return widget.fetch();
    } catch (e, st) {
      return Future.error(e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HonestyVoteReason>>(
      future: _future,
      builder: (context, snapshot) {
        final reasons = snapshot.data ?? const <HonestyVoteReason>[];
        if (reasons.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.errorRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.errorRed.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.honestyReasonsCount(reasons.length),
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.errorRed,
                  ),
                ),
                const SizedBox(height: 6),
                for (final r in reasons)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('• ${r.reason}', style: context.textTheme.bodySmall),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
