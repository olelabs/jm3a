// Item 6 (ToD result screen redesign) regression coverage for
// TodResultCard — the shared "identity + content + answer + proof"
// presentation both the player-facing and spectator-facing result views
// are built from (see tod_card_screen.dart's own doc comment on the
// class). Proves:
// - It renders without overflow across a narrow phone, a normal phone,
//   and a large/tablet width.
// - It renders without overflow in RTL (Arabic).
// - Every content combination (with/without card, with/without answer,
//   with/without proof, and the "no answer/proof at all" empty state)
//   renders cleanly.
// - A long display name / long card content / long answer don't
//   overflow either.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/theme/app_theme.dart';
import 'package:jma3a/features/games/truth_or_dare/domain/tod_models.dart';
import 'package:jma3a/features/games/truth_or_dare/presentation/screens/tod_card_screen.dart';

Widget _wrap(
  Widget child, {
  double width = 390,
  TextDirection direction = TextDirection.ltr,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: direction == TextDirection.rtl
        ? const Locale('ar')
        : const Locale('en'),
    home: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: SizedBox(
          width: width,
          child: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );
}

const _truthCard = TodCard(
  id: 't1',
  content: 'What is the most embarrassing thing that happened to you?',
  type: TodCardType.truth,
  difficulty: TodDifficulty.mild,
);

const _dareCard = TodCard(
  id: 'd1',
  content: 'Do 10 push-ups right now in front of everyone.',
  type: TodCardType.dare,
  difficulty: TodDifficulty.mild,
);

void main() {
  group('TodResultCard — item 6: renders without overflow', () {
    for (final width in [320.0, 390.0, 700.0]) {
      testWidgets('at width $width, with card + answer, no proof', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            const TodResultCard(
              member: null,
              displayName: 'Sara',
              card: _truthCard,
              response:
                  'It was really embarrassing, I fell in front of everyone!',
              proofWidget: null,
            ),
            width: width,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'width=$width');
      });
    }

    testWidgets('with a dare card instead of truth', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TodResultCard(
            member: null,
            displayName: 'Alex',
            card: _dareCard,
            response: '',
            proofWidget: null,
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('with a proof widget present', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TodResultCard(
            member: null,
            displayName: 'Sara',
            card: _truthCard,
            response: 'My answer here',
            proofWidget: Container(
              height: 60,
              color: Colors.black,
              alignment: Alignment.center,
              child: const Text(
                'proof placeholder',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('proof placeholder'), findsOneWidget);
    });

    testWidgets('the empty state renders when there is no answer AND no proof '
        '(item 5\'s explicit "appropriate empty state" requirement)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const TodResultCard(
            member: null,
            displayName: 'Sara',
            card: _truthCard,
            response: '',
            proofWidget: null,
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TodResultCard)),
      );
      expect(find.text(l10n.todNoAnswerOrProofYet), findsOneWidget);
    });

    testWidgets('a very long display name, card content, and answer do '
        'not overflow', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TodResultCard(
            member: null,
            displayName:
                'A Really Really Long Display Name That Could Overflow The Row',
            card: TodCard(
              id: 't2',
              content:
                  'This is a deliberately long truth question content string '
                  'meant to stress-test the content chip and make sure it '
                  'wraps instead of overflowing the card on a narrow phone.',
              type: TodCardType.truth,
              difficulty: TodDifficulty.mild,
            ),
            response:
                'This is a deliberately long answer response that a player '
                'might type, long enough to test whether the answer block '
                'wraps and clamps at maxLines instead of overflowing '
                'horizontally or vertically off the card.',
            proofWidget: null,
          ),
          width: 320,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow in RTL (Arabic)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TodResultCard(
            member: null,
            displayName: 'سارة',
            card: TodCard(
              id: 't3',
              content: 'ما هو أكثر موقف محرج حدث لك؟',
              type: TodCardType.truth,
              difficulty: TodDifficulty.mild,
            ),
            response: 'كانت محرجة جدًا، سقطت أمام الجميع!',
            proofWidget: null,
          ),
          direction: TextDirection.rtl,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('with no card at all (e.g. a punishment turn) still '
        'renders cleanly', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TodResultCard(
            member: null,
            displayName: 'Sara',
            card: null,
            response: 'Some response',
            proofWidget: null,
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
