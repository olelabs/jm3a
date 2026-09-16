// Item 5 (default pack cover) — ImageCacheService.packCover()'s
// null/empty-URL branch (_packPlaceholder) now delegates to the same
// shared PackCoverFallback widget every other pack-cover surface uses
// (see pack_cover_fallback_test.dart), replacing its own previous
// gradient+logo-mark composition. This covers the one path that's
// synchronous and dependency-free (no ImageUrlSigner/network call is
// ever made when there's no URL to sign), matching this repo's
// established boundary of not mocking Supabase/network singletons in a
// plain widget test — the "has a real cover" branch (CachedNetworkImage
// via a signed URL) is exercised by real app usage, not unit-tested here.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/services/image_cache_service.dart';
import 'package:jma3a/shared/widgets/cards/pack_cover_fallback.dart';

void main() {
  group('ImageCacheService.packCover — no cover URL', () {
    testWidgets('a null url renders PackCoverFallback (the shared bundled default)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 100,
              child: ImageCacheService.instance.packCover(
                url: null,
                width: 100,
                height: 100,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PackCoverFallback), findsOneWidget);
      final asset = tester.widget<Image>(find.byType(Image));
      expect(
        (asset.image as AssetImage).assetName,
        'assets/images/backgrounds/jma3a_card_cover.png',
      );
    });

    testWidgets('an empty-string url also renders PackCoverFallback', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 100,
              child: ImageCacheService.instance.packCover(
                url: '',
                width: 100,
                height: 100,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PackCoverFallback), findsOneWidget);
    });

    testWidgets('never throws for a null url', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 100,
              child: ImageCacheService.instance.packCover(
                url: null,
                width: 100,
                height: 100,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
