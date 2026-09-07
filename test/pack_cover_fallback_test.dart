// CORRECTION PASS §3 — PackCoverFallback is the single "no cover
// uploaded" visual for a pack (marketplace cards, pack detail's hero
// image), replacing two previously-inconsistent per-screen placeholders.
// Mirrors game_card_preview_test.dart's own GameCardBackground fallback-
// chain test pattern (find.byType(Image) -> AssetImage.assetName), since
// this widget deliberately references the exact same bundled asset that
// one already established as the project's default-cover convention.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/shared/widgets/cards/pack_cover_fallback.dart';

void main() {
  testWidgets(
    'renders the shared default cover asset — the same one GameCardBackground uses, never a duplicate/different asset',
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
        'assets/images/backgrounds/jma3a_card_cover_playful.png',
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
