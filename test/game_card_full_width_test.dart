// Item 3/4 (full-width card pass) — regression coverage for:
//
// - ToD: the card used to derive WIDTH from GameFlipCard's fixed
//   portrait aspectRatio (0.68) applied against the available HEIGHT
//   (height * 0.68), which is almost always narrower than the actually
//   available width — todFullWidthCardBox (tod_card_screen.dart) fixes
//   this by using the full available width directly, deriving the
//   aspect ratio FROM that instead of the other way around.
// - Meme: the card used to physically shrink (width AND height) once
//   revealed+550ms elapsed ("minimize"), via a BoxFit.contain scale of a
//   fixed-aspect-ratio box — which can never keep full width while
//   shrinking height for a fixed ratio. The card now renders at one
//   constant size for its whole lifetime (see meme_game_screen.dart's
//   own note at the GameFlipCard call site) — covered here via
//   GameFlipCard itself, proving front and back render at the exact
//   same width regardless of maxWidth/aspectRatioOverride, which is the
//   structural guarantee Meme's fix relies on.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/services/app_theme_service.dart';
import 'package:jma3a/features/games/truth_or_dare/presentation/screens/tod_card_screen.dart';
import 'package:jma3a/shared/widgets/game/game_flip_card.dart';
import 'package:provider/provider.dart';

Widget _wrap(Widget child) {
  return ChangeNotifierProvider<AppThemeService>.value(
    value: AppThemeService.instance,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('todFullWidthCardBox — item 3', () {
    test('when height is the binding constraint (the normal phone case — '
        'this Expanded region shares vertical space with the banner/'
        'buttons around it), width still equals the FULL available width, '
        'not a narrower height-derived value', () {
      // A tall-narrow box: plenty of height relative to width, the
      // opposite of what a fixed 0.68 portrait ratio would need to
      // stay height-bound — exactly the shape that used to leave the
      // card visibly narrower than the available width.
      const constraints = BoxConstraints(
        minWidth: 0,
        maxWidth: 360,
        minHeight: 0,
        maxHeight: 500,
      );
      final box = todFullWidthCardBox(constraints);
      expect(box.width, 360);
      expect(box.height, 500);
      expect(box.aspectRatio, closeTo(360 / 500, 0.0001));
    });

    test('width is capped at maxWidth (520 default) on a tablet-sized box', () {
      const constraints = BoxConstraints(
        minWidth: 0,
        maxWidth: 900,
        minHeight: 0,
        maxHeight: 1200,
      );
      final box = todFullWidthCardBox(constraints);
      expect(box.width, 520);
    });

    test('an unbounded height falls back to the original portrait ratio '
        '(never divides by/against infinity)', () {
      const constraints = BoxConstraints(
        minWidth: 0,
        maxWidth: 300,
        minHeight: 0,
        maxHeight: double.infinity,
      );
      final box = todFullWidthCardBox(constraints);
      expect(box.width, 300);
      expect(box.height, 300 / GameFlipCard.aspectRatio);
      expect(box.aspectRatio, closeTo(GameFlipCard.aspectRatio, 0.0001));
    });

    test('a custom maxWidth override is respected', () {
      const constraints = BoxConstraints(
        minWidth: 0,
        maxWidth: 900,
        minHeight: 0,
        maxHeight: 900,
      );
      final box = todFullWidthCardBox(constraints, maxWidth: 400);
      expect(box.width, 400);
    });
  });

  group('GameFlipCard — front/back render at the SAME width regardless of '
      'aspect ratio (item 4 structural guarantee Meme\'s fix relies on)', () {
    testWidgets(
      'a wide aspectRatioOverride (Meme-style) still yields identical '
      'front and back widths',
      (tester) async {
        const width = 380.0;
        const aspectRatio = 380.0 / 220.0; // wide, short — Meme-shaped
        final key = GlobalKey();

        await tester.pumpWidget(
          _wrap(
            GameFlipCard(
              key: key,
              title: 't',
              frontChild: const Text('caption'),
              maxWidth: width,
              aspectRatioOverride: aspectRatio,
              revealed: false,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final backSize = tester.getSize(find.byKey(GameFlipCard.cardBoxKey));

        await tester.pumpWidget(
          _wrap(
            GameFlipCard(
              key: key,
              title: 't',
              frontChild: const Text('caption'),
              maxWidth: width,
              aspectRatioOverride: aspectRatio,
              revealed: true,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final frontSize = tester.getSize(find.byKey(GameFlipCard.cardBoxKey));

        expect(frontSize.width, backSize.width);
        expect(frontSize.height, backSize.height);
        expect(backSize.width, closeTo(width, 0.5));
      },
    );

    testWidgets(
      'repeated flips (back -> front -> back -> front) never change the '
      'rendered width — the exact scenario this task asked to verify',
      (tester) async {
        const width = 340.0;
        const aspectRatio = 1.5;
        final key = GlobalKey();

        Widget build({required bool revealed}) => _wrap(
          GameFlipCard(
            key: key,
            title: 't',
            frontChild: const Text('caption'),
            maxWidth: width,
            aspectRatioOverride: aspectRatio,
            revealed: revealed,
          ),
        );

        final widths = <double>[];
        for (final revealed in [false, true, false, true, false, true]) {
          await tester.pumpWidget(build(revealed: revealed));
          await tester.pumpAndSettle();
          widths.add(tester.getSize(find.byKey(GameFlipCard.cardBoxKey)).width);
        }

        for (final w in widths) {
          expect(w, closeTo(width, 0.5));
        }
      },
    );

    testWidgets('width stability holds at a narrow phone width, a normal phone '
        'width, and a large/tablet width', (tester) async {
      for (final testWidth in [300.0, 390.0, 700.0]) {
        final key = GlobalKey();
        await tester.pumpWidget(
          _wrap(
            GameFlipCard(
              key: key,
              title: 't',
              frontChild: const Text('c'),
              maxWidth: testWidth,
              aspectRatioOverride: 1.4,
              revealed: false,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final back = tester.getSize(find.byKey(GameFlipCard.cardBoxKey));

        await tester.pumpWidget(
          _wrap(
            GameFlipCard(
              key: key,
              title: 't',
              frontChild: const Text('c'),
              maxWidth: testWidth,
              aspectRatioOverride: 1.4,
              revealed: true,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final front = tester.getSize(find.byKey(GameFlipCard.cardBoxKey));

        expect(front.width, back.width, reason: 'maxWidth=$testWidth');
      }
    });
  });
}
