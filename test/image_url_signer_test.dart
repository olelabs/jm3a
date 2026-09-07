// Covers the consumer-side fix for "pack images not appearing": packs
// store Wasabi object references, not directly-viewable URLs (the bucket
// stays private — see the new POST /v1/storage/sign-urls endpoint). This
// tests ImageUrlSigner's caching/batching/fallback logic in isolation via
// its injectable-fetch test constructor, since PackRepository itself has
// no mock seam (a Supabase-backed singleton).
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/services/image_url_signer.dart';

void main() {
  // ImageUrlSigner.signAll logs via AppLogger on a fetch failure, which
  // reads AppConfig.isDevelopment → dotenv — never loaded in a bare unit
  // test. testLoad() is flutter_dotenv's own supported way to satisfy
  // that without a real .env file.
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  group('ImageUrlSigner', () {
    test('sign() returns null/empty input unchanged without calling fetch', () async {
      var calls = 0;
      final signer = ImageUrlSigner.forTest(
        fetch: (urls) async {
          calls++;
          return {for (final u in urls) u: '$u?signed'};
        },
      );
      expect(await signer.sign(null), isNull);
      expect(await signer.sign(''), '');
      expect(calls, 0);
    });

    test('signs a URL via the injected fetch', () async {
      final signer = ImageUrlSigner.forTest(
        fetch: (urls) async => {for (final u in urls) u: '$u?signed=1'},
      );
      expect(await signer.sign('packs/covers/a.jpg'), 'packs/covers/a.jpg?signed=1');
    });

    test('signAll batches distinct URLs into a single fetch call', () async {
      final requestedBatches = <List<String>>[];
      final signer = ImageUrlSigner.forTest(
        fetch: (urls) async {
          requestedBatches.add(urls);
          return {for (final u in urls) u: '$u?signed'};
        },
      );
      final result = await signer.signAll(['a.jpg', 'b.jpg', 'c.jpg']);
      expect(requestedBatches.length, 1);
      expect(requestedBatches.first.toSet(), {'a.jpg', 'b.jpg', 'c.jpg'});
      expect(result['a.jpg'], 'a.jpg?signed');
      expect(result['b.jpg'], 'b.jpg?signed');
      expect(result['c.jpg'], 'c.jpg?signed');
    });

    test('a cached, unexpired URL is served without a second fetch call', () async {
      var calls = 0;
      var now = DateTime(2026, 1, 1, 12);
      final signer = ImageUrlSigner.forTest(
        fetch: (urls) async {
          calls++;
          return {for (final u in urls) u: '$u?signed'};
        },
        now: () => now,
      );
      await signer.sign('a.jpg');
      expect(calls, 1);

      now = now.add(const Duration(minutes: 10)); // well within the 50-minute cache window
      await signer.sign('a.jpg');
      expect(calls, 1, reason: 'still cached, no second network call');
    });

    test('an expired cache entry is re-fetched', () async {
      var calls = 0;
      var now = DateTime(2026, 1, 1, 12);
      final signer = ImageUrlSigner.forTest(
        fetch: (urls) async {
          calls++;
          return {for (final u in urls) u: '$u?signed=$calls'};
        },
        now: () => now,
      );
      expect(await signer.sign('a.jpg'), 'a.jpg?signed=1');

      now = now.add(const Duration(minutes: 51)); // past the 50-minute cache window
      expect(await signer.sign('a.jpg'), 'a.jpg?signed=2');
      expect(calls, 2);
    });

    test('a fetch failure falls back to the raw URL rather than throwing', () async {
      final signer = ImageUrlSigner.forTest(
        fetch: (urls) async => throw Exception('network error'),
      );
      expect(await signer.sign('a.jpg'), 'a.jpg');
    });

    test('mixed cached + uncached URLs: only the uncached ones are re-fetched', () async {
      final requestedBatches = <List<String>>[];
      var now = DateTime(2026, 1, 1, 12);
      final signer = ImageUrlSigner.forTest(
        fetch: (urls) async {
          requestedBatches.add(List.of(urls));
          return {for (final u in urls) u: '$u?signed'};
        },
        now: () => now,
      );
      await signer.signAll(['a.jpg']);
      now = now.add(const Duration(minutes: 5));
      await signer.signAll(['a.jpg', 'b.jpg']);

      expect(requestedBatches.length, 2);
      expect(requestedBatches.last, ['b.jpg'], reason: 'a.jpg was still cached');
    });

    test('a fetch response missing a requested URL falls back to the raw URL for that one', () async {
      final signer = ImageUrlSigner.forTest(
        fetch: (urls) async => {'a.jpg': 'a.jpg?signed'}, // b.jpg intentionally omitted
      );
      final result = await signer.signAll(['a.jpg', 'b.jpg']);
      expect(result['a.jpg'], 'a.jpg?signed');
      expect(result['b.jpg'], 'b.jpg');
    });
  });
}
