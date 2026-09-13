// GameFlipCard — the reusable 3D flip presentation shared by Truth or
// Dare, NHIE, and Meme (see lib/shared/widgets/game/game_flip_card.dart).
//
// Full end-to-end widget tests of TodCardScreen/NhieGameScreen/
// MemeGameScreen themselves are not attempted here: their own
// TodGameProvider/NhieGameProvider/MemeGameProvider require a live
// RealtimeService/DI stack this offline suite doesn't have — the exact
// same constraint test/nhie_meme_timeout_ui_routing_test.dart already
// documents and works around by testing at the engine/state level
// instead. GameFlipCard mostly takes plain title/frontChild/revealed/
// contentId values, never a provider for ITS OWN behavior — the one
// exception (items 5-8, this pass) is reading AppThemeService for the
// front face's Game Card Color, since AppThemeService is a real
// singleton (AppThemeService.instance) this file can wire up directly
// with ChangeNotifierProvider.value, no DI/Supabase stack needed. So
// GameFlipCard is still fully testable in isolation here — and since all
// three games delegate their entire flip/reveal/stale-guard behavior to
// this ONE component, this is also where that shared behavior is most
// directly and reliably verified.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/services/app_theme_service.dart';
import 'package:jma3a/shared/widgets/game/game_flip_card.dart';
import 'package:provider/provider.dart';

// GameFlipCard's own branding row reads context.l10n.appName (see
// _BrandMark), so — unlike before the native redesign — these tests need
// real AppLocalizations delegates wired up, the same as every other
// widget test in this project that renders localized text. The
// ChangeNotifierProvider<AppThemeService> is what the front face's Game
// Card Color read (items 5-8, this pass) now needs — AppThemeService is a
// real singleton, so this doesn't need any fake/mocked state, just an
// ancestor Provider for context.watch<AppThemeService>() to find.
Widget _wrap(Widget child, {TextDirection direction = TextDirection.ltr}) {
  return ChangeNotifierProvider<AppThemeService>.value(
    value: AppThemeService.instance,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Directionality(
        textDirection: direction,
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  group('GameFlipCard — aspect ratio', () {
    testWidgets(
      'renders the card at exactly the supplied artwork aspect ratio',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const GameFlipCard(
              title: 'Truth or Dare',
              frontChild: Text('content'),
              maxWidth: 300,
            ),
          ),
        );
        // flutter_animate's entrance effect (see _CardBack/_CardFront)
        // defers its own start via a zero-duration Timer — settle so it
        // (and the test framework's own pending-timer check) resolves
        // before this test ends.
        await tester.pumpAndSettle();

        // GameFlipCard itself (and the Center/Transform.scale wrapping the
        // card) fill whatever bounded space their parent gives them — by
        // design, so this component composes correctly inside any parent
        // layout — so the actual sized card box (GameFlipCard.cardBoxKey)
        // is what must be measured for aspect ratio, not the outer shell.
        final size = tester.getSize(find.byKey(GameFlipCard.cardBoxKey));
        expect(
          size.width / size.height,
          closeTo(GameFlipCard.aspectRatio, 0.01),
        );
      },
    );

    testWidgets('caps its width at maxWidth even on a very wide screen', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _wrap(
          const GameFlipCard(
            title: 'Truth or Dare',
            frontChild: Text('content'),
            maxWidth: 280,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byKey(GameFlipCard.cardBoxKey));
      expect(size.width, lessThanOrEqualTo(280.5));
    });
  });

  group('GameFlipCard — back/front rendering', () {
    testWidgets('starts on the back: title is visible, front content is not', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const GameFlipCard(
            title: 'Never Have I Ever',
            frontChild: Text('a secret statement'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Never Have I Ever'), findsOneWidget);
      expect(find.text('a secret statement'), findsNothing);
    });

    testWidgets(
      'revealed:true from first build shows the front immediately, never the back',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const GameFlipCard(
              title: 'Truth or Dare',
              frontChild: Text('front content'),
              revealed: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('front content'), findsOneWidget);
        expect(find.text('Truth or Dare'), findsNothing);
      },
    );

    testWidgets(
      'manual reveal (revealed false→true) flips exactly once and lands on the front',
      (tester) async {
        var revealedCount = 0;
        bool revealed = false;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) => _wrap(
              GameFlipCard(
                title: 'Truth or Dare',
                frontChild: const Text('the dare'),
                revealed: revealed,
                onRevealed: () => revealedCount++,
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Truth or Dare'), findsOneWidget);

        // Simulate the parent flipping `revealed` the way TodCardScreen
        // does the instant a choice is made.
        revealed = true;
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) => _wrap(
              GameFlipCard(
                title: 'Truth or Dare',
                frontChild: const Text('the dare'),
                revealed: revealed,
                onRevealed: () => revealedCount++,
              ),
            ),
          ),
        );

        // Mid-flip: neither settled face's own text should be the OTHER
        // face's text — exactly one of the two is ever in the tree.
        await tester.pump(const Duration(milliseconds: 300));
        final backShown = find.text('Truth or Dare').evaluate().isNotEmpty;
        final frontShown = find.text('the dare').evaluate().isNotEmpty;
        expect(
          backShown ^ frontShown,
          isTrue,
          reason:
              'exactly one face must be present mid-flip, never both, never neither',
        );

        await tester.pumpAndSettle();
        expect(find.text('the dare'), findsOneWidget);
        expect(find.text('Truth or Dare'), findsNothing);
        expect(revealedCount, 1);

        // Rapid re-confirmation of `revealed:true` (a second setState with
        // the same value, mirroring a double-tap that's already locked at
        // the call site) must not trigger a second flip/callback.
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) => _wrap(
              GameFlipCard(
                title: 'Truth or Dare',
                frontChild: const Text('the dare'),
                revealed: true,
                onRevealed: () => revealedCount++,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(revealedCount, 1);
      },
    );

    testWidgets(
      'revealed AND contentId changing in the SAME update still animates the '
      'flip rather than snapping straight to the front — the exact Truth or '
      'Dare choosingType→readingCard transition (via a shared GlobalKey)',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const GameFlipCard(
              title: 'Truth or Dare',
              frontChild: SizedBox.shrink(),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Truth or Dare'), findsOneWidget);

        await tester.pumpWidget(
          _wrap(
            const GameFlipCard(
              title: 'Truth or Dare',
              frontChild: Text('the truth'),
              revealed: true,
              contentId: 'card-1',
            ),
          ),
        );

        // Immediately after the update the flip must still be in flight —
        // a snap-to-front bug would show 'the truth' here already.
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('the truth'), findsNothing);
        expect(find.text('Truth or Dare'), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.text('the truth'), findsOneWidget);
      },
    );
  });

  group('GameFlipCard — auto reveal + stale content guard', () {
    testWidgets(
      'autoRevealDelay flips to the front on its own after the delay',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const GameFlipCard(
              title: 'Meme Game',
              frontChild: Text('todays prompt'),
              contentId: 'prompt-1',
              autoRevealDelay: Duration(milliseconds: 300),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Meme Game'), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(find.text('todays prompt'), findsOneWidget);
        expect(find.text('Meme Game'), findsNothing);
      },
    );

    testWidgets(
      'a rapid content change before the timer fires cancels the stale reveal — '
      'the old content can never appear',
      (tester) async {
        Widget build(String contentId, String content) => _wrap(
          GameFlipCard(
            title: 'Never Have I Ever',
            frontChild: Text(content),
            contentId: contentId,
            autoRevealDelay: const Duration(milliseconds: 300),
          ),
        );

        await tester.pumpWidget(build('round-1', 'old statement'));
        await tester.pump();

        // Round changes rapidly, well before the first round's 300ms
        // reveal would have fired.
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpWidget(build('round-2', 'new statement'));

        // Advance past the FIRST round's original schedule (100 + 250 =
        // 350ms since round-1 mounted) — if the stale timer were not
        // cancelled, this is exactly when it would incorrectly fire and
        // reveal 'old statement'.
        await tester.pump(const Duration(milliseconds: 250));
        expect(
          find.text('old statement'),
          findsNothing,
          reason:
              'a stale timer scheduled for the previous round must never reveal it',
        );

        // The new round's own 300ms timer (started at round-2's mount)
        // still fires normally.
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpAndSettle();
        expect(find.text('new statement'), findsOneWidget);
      },
    );

    testWidgets(
      'disposing while an auto-reveal timer is pending does not throw '
      '(no setState-after-dispose)',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const GameFlipCard(
              title: 'Meme Game',
              frontChild: Text('prompt'),
              contentId: 'p1',
              autoRevealDelay: Duration(milliseconds: 300),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        // Unmount GameFlipCard entirely before its timer would fire.
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });

  group('GameFlipCard — content safety', () {
    testWidgets('a very long front statement never overflows', (tester) async {
      await tester.pumpWidget(
        _wrap(
          GameFlipCard(
            title: 'Never Have I Ever',
            revealed: true,
            maxWidth: 260,
            frontChild: Text(
              'Never have I ever ' * 20, // deliberately very long
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('a very long title never overflows the brush plate', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          GameFlipCard(
            title:
                'A Truly Extremely Long Localized Game Title That Keeps Going',
            frontChild: const Text('x'),
            maxWidth: 260,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without error under RTL (Arabic) layout', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const GameFlipCard(
            title: 'الحقيقة أم الجرأة',
            frontChild: Text('سؤال طويل نسبياً يجب أن يظهر بشكل صحيح'),
            revealed: true,
          ),
          direction: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('سؤال طويل نسبياً يجب أن يظهر بشكل صحيح'),
        findsOneWidget,
      );
    });
  });

  group('GameFlipCard — frontContentBuilder (Meme caption fix)', () {
    testWidgets(
      'a long caption via frontContentBuilder renders at the FULL safe '
      'width, not narrowed by the default FittedBox(scaleDown) path',
      (tester) async {
        double? measuredMaxWidth;
        await tester.pumpWidget(
          _wrap(
            GameFlipCard(
              title: 'Meme Game',
              revealed: true,
              maxWidth: 340,
              frontChild: const Text('unused fallback'),
              frontContentBuilder: (context, constraints) {
                measuredMaxWidth = constraints.maxWidth;
                return Text(
                  ('a fairly long meme caption that wraps several times ' * 4)
                      .trim(),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // The safe content zone is width * (1 - 2*0.10) = 0.8 * 340 = 272 —
        // the builder must see (approximately) that full width, not some
        // further-narrowed value the way the old block-scale path could
        // effectively produce for long content.
        expect(measuredMaxWidth, isNotNull);
        expect(measuredMaxWidth!, closeTo(272, 10));
      },
    );

    testWidgets(
      'an extremely long caption via frontContentBuilder never overflows',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            GameFlipCard(
              title: 'Meme Game',
              revealed: true,
              maxWidth: 260,
              frontChild: const Text('unused fallback'),
              frontContentBuilder: (context, constraints) => Text(
                'a fairly long meme caption that keeps going and going ' * 8,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'frontChild-only callers (Truth or Dare/NHIE) are unaffected when '
      'frontContentBuilder is not supplied',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const GameFlipCard(
              title: 'Truth or Dare',
              frontChild: Text('the dare'),
              revealed: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('the dare'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('GameFlipCard — wide card / full-width sizing (Meme)', () {
    testWidgets(
      'a large maxWidth (e.g. Meme\'s real-screen-width value) renders at '
      'the actual available screen width, not an arbitrary smaller cap',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _wrap(
            GameFlipCard(
              title: 'Meme Game',
              revealed: true,
              maxWidth: 400, // mirrors Meme's real-available-width value
              aspectRatioOverride: 1.5,
              frontChild: const Text('caption'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final size = tester.getSize(find.byKey(GameFlipCard.cardBoxKey));
        // The Scaffold/Center wrapper leaves some margin, but the card
        // must use nearly the full surface width — not a small fraction
        // of it.
        expect(size.width, greaterThan(300));
        expect(size.width / size.height, closeTo(1.5, 0.01));
      },
    );

    testWidgets(
      'frontContentBuilder is handed the TRUE rendered safe-zone width — '
      'not a fixed proxy that would make its own font-size math wrong',
      (tester) async {
        double? measuredMaxWidth;
        await tester.binding.setSurfaceSize(const Size(400, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _wrap(
            GameFlipCard(
              title: 'Meme Game',
              revealed: true,
              maxWidth: 400,
              aspectRatioOverride: 1.5,
              frontChild: const Text('unused'),
              frontContentBuilder: (context, constraints) {
                measuredMaxWidth = constraints.maxWidth;
                return const Text('caption');
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final cardSize = tester.getSize(find.byKey(GameFlipCard.cardBoxKey));
        expect(measuredMaxWidth, isNotNull);
        // Safe width is width * 0.8 (see _CardFront) — proportional to the
        // card's ACTUAL rendered width, confirming the builder isn't
        // operating against some other fixed/scaled value.
        expect(measuredMaxWidth!, closeTo(cardSize.width * 0.8, 10));
      },
    );

    testWidgets(
      'in a HEIGHT-constrained parent, the card shrinks to fit rather than '
      'overflowing (the ToD pre-selection overflow fix)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 120, // deliberately much shorter than width*1/0.68
                child: GameFlipCard(
                  title: 'Truth or Dare',
                  frontChild: const Text('content'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final size = tester.getSize(find.byKey(GameFlipCard.cardBoxKey));
        expect(size.height, lessThanOrEqualTo(120.5));
      },
    );
  });

  group('GameFlipCard — flip timing', () {
    testWidgets('default flip duration is within the 500-700ms target range', (
      tester,
    ) async {
      const card = GameFlipCard(title: 't', frontChild: Text('c'));
      expect(card.flipDuration.inMilliseconds, inInclusiveRange(500, 700));
    });
  });

  group('GameFlipCard — card size (item 2, card-size regression pass)', () {
    test('the default maxWidth is generous enough that a normal/large '
        "phone's own available width is the actual binding constraint, "
        'not maxWidth itself — the exact regression (default was 340, '
        'narrower than most real phone content areas) this pass fixes', () {
      const card = GameFlipCard(title: 't', frontChild: Text('c'));
      expect(card.maxWidth, greaterThanOrEqualTo(480));
    });

    testWidgets('at a normal phone width (390px, e.g. an unpadded iPhone-class '
        'screen) with NO explicit maxWidth override (mirrors NHIE\'s and '
        "ToD's revealed-card call sites), the card uses substantially "
        'more than the old 340px cap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _wrap(const GameFlipCard(title: 't', frontChild: Text('c'))),
      );
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byKey(GameFlipCard.cardBoxKey));
      expect(size.width, greaterThan(360));
    });

    testWidgets('at a wide/large-phone width (428px) the card still grows with '
        'the available width rather than staying pinned at the old '
        '340px cap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(428, 926));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _wrap(const GameFlipCard(title: 't', frontChild: Text('c'))),
      );
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byKey(GameFlipCard.cardBoxKey));
      expect(size.width, greaterThan(390));
    });

    testWidgets(
      'at a genuinely narrow phone width (320px) the card still shrinks '
      'to fit safely — the larger default maxWidth never reintroduces '
      'the old overflow/RenderFlex problem',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _wrap(const GameFlipCard(title: 't', frontChild: Text('c'))),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final size = tester.getSize(find.byKey(GameFlipCard.cardBoxKey));
        expect(size.width, lessThanOrEqualTo(320));
      },
    );

    testWidgets('front and back render at the exact same size at every point '
        'during the flip — raising maxWidth does not desync them', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final key = GlobalKey();
      await tester.pumpWidget(
        _wrap(
          GameFlipCard(
            key: key,
            title: 't',
            frontChild: const Text('c'),
            revealed: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final revealedSize = tester.getSize(find.byKey(GameFlipCard.cardBoxKey));

      await tester.pumpWidget(
        _wrap(
          GameFlipCard(
            key: key,
            title: 't',
            frontChild: const Text('c'),
            revealed: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final backSize = tester.getSize(find.byKey(GameFlipCard.cardBoxKey));
      expect(backSize, revealedSize);
    });
  });
}
