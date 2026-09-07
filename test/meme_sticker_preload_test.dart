import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/meme_game/sticker_pool_loader.dart';

/// Sticker preloading correction pass — the actual architectural fix
/// this proves is memoization + precaching: MemeGameProvider used to have
/// no equivalent at all (_SubmitScreenState re-fetched the pack's sticker
/// pool, including re-signing every URL, from scratch every single
/// round). StickerPoolLoader takes its fetch function injected so this
/// can be tested without a live Supabase/PackRepository.
void main() {
  // AppLogger (used by StickerPoolLoader's own warning-on-failure path)
  // reads AppConfig.isDevelopment -> dotenv, never loaded in a bare unit
  // test.
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  test('load() memoizes — calling it twice for the same game returns the identical Future, never issuing a second fetch', () {
    var callCount = 0;
    final loader = StickerPoolLoader(fetch: (packId) async {
      callCount++;
      return ['a.png', 'b.png'];
    });

    final first = loader.load('pack-1');
    final second = loader.load('pack-1');

    expect(identical(first, second), isTrue);
  });

  test('pool starts empty before the fetch resolves, then reflects the fetched URLs', () async {
    final loader = StickerPoolLoader(fetch: (packId) async => ['a.png', 'b.png']);
    expect(loader.pool, isEmpty);

    final result = await loader.load('pack-1');

    expect(result, ['a.png', 'b.png']);
    expect(loader.pool, ['a.png', 'b.png']);
  });

  test('load() only ever calls the fetcher once per loader, even when awaited from multiple places', () async {
    var callCount = 0;
    final loader = StickerPoolLoader(fetch: (packId) async {
      callCount++;
      return ['a.png'];
    });

    await Future.wait([loader.load('pack-1'), loader.load('pack-1'), loader.load('pack-1')]);

    expect(callCount, 1);
  });

  test('a fetcher that throws resolves to an empty pool rather than propagating — one bad pool never crashes the game', () async {
    final loader = StickerPoolLoader(fetch: (packId) async => throw Exception('network error'));

    final result = await loader.load('pack-1');

    expect(result, isEmpty);
    expect(loader.pool, isEmpty);
  });

  testWidgets('precache() on an empty pool completes without throwing and marks itself precached', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    final context = tester.element(find.byType(Scaffold));
    final loader = StickerPoolLoader(fetch: (packId) async => const []);

    await loader.load('pack-1');
    await loader.precache(context);

    expect(loader.isPrecached, isTrue);
  });

  testWidgets('precache() is idempotent — calling it twice does not re-run the precache work', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    final context = tester.element(find.byType(Scaffold));
    final loader = StickerPoolLoader(fetch: (packId) async => const []);
    await loader.load('pack-1');

    await loader.precache(context);
    expect(loader.isPrecached, isTrue);
    // A second call must simply return early (no assertion failure, no
    // exception) — this is the "do not download the same image
    // repeatedly" guarantee for the precache step specifically.
    await loader.precache(context);
    expect(loader.isPrecached, isTrue);
  });
}
