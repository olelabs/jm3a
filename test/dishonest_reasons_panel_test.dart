// Regression tests for Part A of the "ToD blank screen" report: honesty
// voting is a secondary section and must never prevent a response from
// rendering, even when the honesty data fails to load.
//
// DishonestReasonsPanel is deliberately provider-free (just a plain
// `Future<List<HonestyVoteReason>> Function()` callback) — the one piece
// of the honesty-on-response-reveal UI this codebase's established
// "no Supabase mock seam" testing boundary actually allows a real widget
// test to exercise directly, without a live TodGameProvider/Supabase
// client. The response Container itself (in _AwaitingView) is a SIBLING
// widget, entirely unconditional on this panel — see
// TodGameProvider.onStateBroadcast's own regression coverage
// (tod_state_broadcast_roundtrip_test.dart) for the state-sync half of
// this bug report.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/data/honesty_vote_repository.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/shared/widgets/game/dishonest_reasons_panel.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets(
    'zero honesty votes: the panel renders (collapses to nothing) without '
    'throwing — a response must still be considered fully rendered with no '
    'honesty data at all',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          DishonestReasonsPanel(
            key: const ValueKey('r1'),
            fetch: () async => const [],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(DishonestReasonsPanel), findsOneWidget);
    },
  );

  testWidgets(
    'a dishonest vote with a reason renders that reason, and does not '
    'prevent the rest of the tree around it from rendering',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              const Text('the response text'), // stands in for _AwaitingView's response Container — a sibling, not a dependent.
              DishonestReasonsPanel(
                key: const ValueKey('r2'),
                fetch: () async => [
                  HonestyVoteReason(
                    reason: 'You said something different earlier',
                    createdAt: DateTime.now(),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('the response text'), findsOneWidget);
      expect(find.textContaining('You said something different earlier'), findsOneWidget);
    },
  );

  testWidgets(
    'an ASYNCHRONOUS honesty-query failure degrades gracefully — the panel '
    'collapses to nothing rather than throwing, and sibling content (the '
    'response) is unaffected',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              const Text('the response text'),
              DishonestReasonsPanel(
                key: const ValueKey('r3'),
                fetch: () async => throw Exception('network down'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('the response text'), findsOneWidget);
    },
  );

  testWidgets(
    'a SYNCHRONOUS throw from fetch() (not an async rejection) is caught by '
    'the panel\'s own _safeFetch wrapper — this is the specific hardening '
    'added alongside TodGameProvider.onStateBroadcast\'s fix; a badly-'
    'behaved fetch implementation must never crash this widget\'s build',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              const Text('the response text'),
              DishonestReasonsPanel(
                key: const ValueKey('r4'),
                fetch: () => throw StateError('synchronous failure'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('the response text'), findsOneWidget);
    },
  );
}
