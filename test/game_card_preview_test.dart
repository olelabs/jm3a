// Tests for item 17 — the pack-creation live card preview.
//
// GameCardBackground and GameCardPreview (lib/shared/widgets/game/) are
// the two new widgets this feature added. Both are pure, provider-free
// presentation widgets — no Supabase/RealtimeService dependency — so
// unlike the game screens' own private step widgets (_GeneralInfoStep/
// _CardsStep/_CardPreviewSwiper in create_pack_screen.dart, which can't
// be imported into an external test file at all, being library-private),
// these two can be pumped directly here.
//
// What's verified offline: the background fallback chain resolves in the
// documented priority order (specific image -> default asset -> flat
// color), and the per-game-type badge/content rendering. What's NOT
// verified here (needs a running app): actual network image loading, the
// private _CardPreviewSwiper's PageView interaction, and the live-typing
// preview wiring inside _CardsStep — see the final report.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/shared/widgets/game/game_card_background.dart';
import 'package:jma3a/shared/widgets/game/game_card_preview.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SizedBox(width: 200, height: 260, child: child)),
    ),
  );
  await tester.pump();
}

void main() {
  group('GameCardBackground — fallback chain (items 1-5)', () {
    testWidgets(
      '2. no imageUrl at all renders the default jma3a_card_cover_playful '
      'asset, never a network request',
      (tester) async {
        await _pump(
          tester,
          const GameCardBackground(imageUrl: null, fallbackColor: Colors.blue),
        );
        final asset = tester.widget<Image>(find.byType(Image));
        expect(
          (asset.image as AssetImage).assetName,
          'assets/images/backgrounds/jma3a_card_cover_playful.png',
        );
      },
    );

    testWidgets(
      '2b. an empty-string imageUrl is treated the same as null — default '
      'asset, not an empty network request',
      (tester) async {
        await _pump(
          tester,
          const GameCardBackground(imageUrl: '', fallbackColor: Colors.blue),
        );
        final asset = tester.widget<Image>(find.byType(Image));
        expect(
          (asset.image as AssetImage).assetName,
          'assets/images/backgrounds/jma3a_card_cover_playful.png',
        );
      },
    );

    testWidgets(
      '1. a real imageUrl is attempted first — the widget tree starts '
      'with a NetworkImage for that exact URL, not the default asset',
      (tester) async {
        await _pump(
          tester,
          const GameCardBackground(
            imageUrl: 'https://example.com/cover.png',
            fallbackColor: Colors.blue,
          ),
        );
        // .first: in the test environment every network request 400s
        // immediately (see flutter_test's own HttpClient warning), so by
        // the time this pumps, GameCardBackground's errorBuilder may
        // already have inserted its own (second, descendant) Image.asset
        // fallback into the tree. The outermost Image — first in
        // tree-order — is always the one GameCardBackground itself
        // declared, which is what this asserts on.
        final img = tester.widgetList<Image>(find.byType(Image)).first;
        expect(img.image, isA<NetworkImage>());
        expect((img.image as NetworkImage).url, 'https://example.com/cover.png');
      },
    );
  });

  group('GameCardPreview — per-game-type presentation (items 7/18)', () {
    testWidgets(
      '17. renders with no overflow at the 110px width the pack-creation '
      "compose-time live preview actually uses, and with the longest "
      'badge label (NHIE) — the tightest realistic case',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SizedBox(
                width: 110,
                height: 146,
                child: GameCardPreview(
                  gameType: 'never_have_i_ever',
                  content: 'Never have I ever forgotten a birthday',
                  isSpicy: true,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('renders the given content text', (tester) async {
      await _pump(
        tester,
        const GameCardPreview(
          gameType: 'never_have_i_ever',
          content: 'Never have I ever forgotten a birthday',
        ),
      );
      expect(
        find.text('Never have I ever forgotten a birthday'),
        findsOneWidget,
      );
    });

    testWidgets('9. empty content falls back to a placeholder glyph, never '
        'a blank card', (tester) async {
      await _pump(
        tester,
        const GameCardPreview(gameType: 'meme_game', content: ''),
      );
      expect(find.text('…'), findsOneWidget);
    });

    testWidgets(
      'NHIE game type shows the NEVER HAVE I EVER badge',
      (tester) async {
        await _pump(
          tester,
          const GameCardPreview(gameType: 'never_have_i_ever', content: 'x'),
        );
        expect(find.text('NEVER HAVE I EVER'), findsOneWidget);
      },
    );

    testWidgets('Meme game type shows the MEME PROMPT badge', (tester) async {
      await _pump(
        tester,
        const GameCardPreview(gameType: 'meme_game', content: 'x'),
      );
      expect(find.text('MEME PROMPT'), findsOneWidget);
    });

    testWidgets(
      'ToD truth card shows the TRUTH badge, dare shows DARE',
      (tester) async {
        await _pump(
          tester,
          const GameCardPreview(gameType: 'truth_or_dare', content: 'x'),
        );
        expect(find.text('TRUTH'), findsOneWidget);

        await _pump(
          tester,
          const GameCardPreview(
            gameType: 'truth_or_dare',
            content: 'x',
            cardTypeIsDare: true,
          ),
        );
        expect(find.text('DARE'), findsOneWidget);
      },
    );

    testWidgets('a spicy card shows the spicy chip', (tester) async {
      await _pump(
        tester,
        const GameCardPreview(
          gameType: 'truth_or_dare',
          content: 'x',
          cardTypeIsDare: true,
          isSpicy: true,
        ),
      );
      expect(find.text('🌶'), findsOneWidget);
    });

    testWidgets(
      '5. resolves its background through GameCardBackground — same '
      'widget instance type, same fallback chain, not a duplicated one',
      (tester) async {
        await _pump(
          tester,
          const GameCardPreview(gameType: 'meme_game', content: 'x'),
        );
        expect(find.byType(GameCardBackground), findsOneWidget);
      },
    );
  });
}
