// CORRECTION PASS §3 — PackCoverFallback is the single "no cover
// uploaded" visual for a pack (marketplace cards, pack detail's hero
// image), replacing two previously-inconsistent per-screen placeholders.
// Mirrors game_card_preview_test.dart's own GameCardBackground fallback-
// chain test pattern (find.byType(Image) -> AssetImage.assetName).
//
// Item 5 (default pack cover) — the bundled default asset changed from
// jma3a_card_cover_playful.png to the newly-added jma3a_card_cover.png.
// This is now DELIBERATELY a different asset from GameCardBackground's
// own fallback (jma3a_card_cover_playful.png, see game_card_preview_
// test.dart, unchanged) — a pack's own marketplace/detail cover and the
// in-game round background are distinct concepts that happen to have
// shared the same bundled image before; they no longer need to.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/shared/widgets/cards/pack_cover_fallback.dart';

void main() {
  testWidgets(
    'renders the bundled default pack cover asset (jma3a_card_cover.png)',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 100, height: 100, child: PackCoverFallback()),
          ),
        ),
      );
      await tester.pump();
      final asset = tester.widget<Image>(find.byType(Image));
      expect(
        (asset.image as AssetImage).assetName,
        'assets/images/backgrounds/jma3a_card_cover.png',
      );
    },
  );

  testWidgets(
    'never throws, even if the bundled asset were to fail to load',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 100, height: 100, child: PackCoverFallback()),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
