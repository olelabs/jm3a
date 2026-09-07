// Regression coverage for the CONFIRMED root cause of "Player B sees a
// blank ToD result screen": HonestyVoteRow (extracted from
// TodCardScreen's private _HonestyVoteRow — see that file's own
// _HonestyVoteRow wrapper) had two OutlinedButtons sitting directly in a
// Row with no minimumSize override. The app-wide OutlinedButton theme
// sets minimumSize: Size(double.infinity, 52) (for full-width primary
// CTAs); a Row gives non-Expanded children an unbounded max width, so
// this threw "BoxConstraints forces an infinite width" the instant the
// row rendered for a non-turn player — confirmed via a real-device
// Flutter creator-chain trace landing exactly on
// tod_card_screen.dart:2428 (OutlinedButton -> Row -> Padding ->
// _HonestyVoteRow).
//
// HonestyVoteRow is now a public, provider-free widget specifically so
// it can be rendered directly here — the actual production widget, not a
// reconstruction — with the REAL AppTheme, at the REAL reported widths.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/theme/app_theme.dart';
import 'package:jma3a/shared/widgets/game/honesty_vote_buttons.dart';

Widget _wrap(
  Widget child, {
  double width = 390,
  TextDirection direction = TextDirection.ltr,
}) => MediaQuery(
  data: MediaQueryData(size: Size(width, 800)),
  child: Directionality(
    textDirection: direction,
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: direction == TextDirection.rtl ? const Locale('ar') : null,
      home: Scaffold(
        // Mirrors the real host: _AwaitingView's SingleChildScrollView ->
        // Column, not a bare Center — the same scrolling environment that
        // previously produced the crash.
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [child]),
        ),
      ),
    ),
  ),
);

void main() {
  group('HonestyVoteRow — real production widget, narrow widths', () {
    for (final width in [320.0, 360.0, 390.0]) {
      testWidgets('eligible voter: renders both buttons without exception '
          'at ${width}px', (tester) async {
        await tester.pumpWidget(
          _wrap(
            HonestyVoteRow(
              voterId: 'voter1',
              targetUserId: 'target1',
              participantIds: const ['voter1', 'target1', 'p3'],
              hasVoted: false,
              onVote: ({required targetUserId, required isHonest, reason}) async {},
            ),
            width: width,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byType(OutlinedButton), findsNWidgets(2));
      });
    }

    testWidgets('already-voted state (text only, no buttons) renders '
        'without exception at the narrowest width', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HonestyVoteRow(
            voterId: 'voter1',
            targetUserId: 'target1',
            participantIds: const ['voter1', 'target1'],
            hasVoted: true,
            onVote: ({required targetUserId, required isHonest, reason}) async {},
          ),
          width: 320,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('ineligible voter (self, or not a participant) collapses '
        'to nothing without exception', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HonestyVoteRow(
            voterId: 'voter1',
            targetUserId: 'voter1', // self
            participantIds: const ['voter1'],
            hasVoted: false,
            onVote: ({required targetUserId, required isHonest, reason}) async {},
          ),
          width: 320,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('renders without exception in Arabic RTL', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HonestyVoteRow(
            voterId: 'voter1',
            targetUserId: 'target1',
            participantIds: const ['voter1', 'target1'],
            hasVoted: false,
            onVote: ({required targetUserId, required isHonest, reason}) async {},
          ),
          width: 360,
          direction: TextDirection.rtl,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without exception in French (a longer translated '
        'label than English) at the narrowest width', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(320, 800)),
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HonestyVoteRow(
                      voterId: 'voter1',
                      targetUserId: 'target1',
                      participantIds: const ['voter1', 'target1'],
                      hasVoted: false,
                      onVote: ({required targetUserId, required isHonest, reason}) async {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('sanity check: proves this suite catches the regression (not '
      'trivially passing)', () {
    testWidgets('the UNFIXED shape (two bare OutlinedButtons in a Row, no '
        'minimumSize override) genuinely throws under the real app theme',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Honest'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Not honest'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNotNull);
    });
  });
}
