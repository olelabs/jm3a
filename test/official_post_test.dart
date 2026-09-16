// Item 1 (official content: separate posts from ads) — pure parsing +
// type-separation coverage for OfficialContentItem.fromMap (see
// lib/features/friends/data/official_content_repository.dart), mirroring
// ExplorePerson.fromMap's own test style (test/explore_people_test.dart):
// the network/Supabase side of OfficialContentRepository.getPosts()/
// getAdvertisements() isn't unit-tested (this repo's established
// boundary — only the pure row-mapping is). The actual query-level type
// filter (`.eq('type', ...)`) is exercised by real app usage; what's
// tested here is the parsing contract those two queries' results feed
// into, and that filtering a mixed batch by `.type` cleanly separates
// posts from ads with no overlap — the exact regression this item
// guards against (a post previously rendering under Advertisements).
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/friends/data/official_content_repository.dart';

void main() {
  group('OfficialContentItem.fromMap', () {
    test('parses a full "post" row', () {
      final p = OfficialContentItem.fromMap({
        'id': 'p1',
        'type': 'post',
        'title': 'New pack drop',
        'body': 'Three new Truth or Dare packs are live today.',
        'image_url': 'https://example.com/cover.png',
        'created_at': '2026-09-14T12:00:00.000Z',
      });
      expect(p.id, 'p1');
      expect(p.type, OfficialContentType.post);
      expect(p.title, 'New pack drop');
      expect(p.body, 'Three new Truth or Dare packs are live today.');
      expect(p.imageUrl, 'https://example.com/cover.png');
      expect(p.createdAt, DateTime.parse('2026-09-14T12:00:00.000Z'));
    });

    test('parses a full "ad" row', () {
      final a = OfficialContentItem.fromMap({
        'id': 'a1',
        'type': 'ad',
        'title': 'Premium Plus',
        'body': 'Unlock more with Premium Plus.',
        'created_at': '2026-09-14T12:00:00.000Z',
      });
      expect(a.type, OfficialContentType.ad);
    });

    test(
      'a missing/unrecognized type never falls back to ad — the safer '
      'default is post, so an unexpected value can never silently render '
      'as an advertisement',
      () {
        expect(
          OfficialContentItem.fromMap({
            'id': 'p2',
            'title': 'X',
            'body': 'Y',
            'created_at': '2026-09-01T00:00:00.000Z',
          }).type,
          OfficialContentType.post,
        );
        expect(
          OfficialContentItem.fromMap({
            'id': 'p3',
            'type': 'something_unexpected',
            'title': 'X',
            'body': 'Y',
            'created_at': '2026-09-01T00:00:00.000Z',
          }).type,
          OfficialContentType.post,
        );
      },
    );

    test('image_url is optional, never throws when absent', () {
      final p = OfficialContentItem.fromMap({
        'id': 'p4',
        'type': 'post',
        'title': 'Announcement',
        'body': 'No image on this one.',
        'created_at': '2026-09-01T00:00:00.000Z',
      });
      expect(p.imageUrl, isNull);
    });

    test('missing title/body fall back to empty strings, never throws', () {
      final p = OfficialContentItem.fromMap({
        'id': 'p5',
        'type': 'post',
        'created_at': '2026-09-01T00:00:00.000Z',
      });
      expect(p.title, '');
      expect(p.body, '');
    });
  });

  group('post/ad separation — the actual Jma3a-Feed-vs-Advertisements rule', () {
    final mixedRows = [
      {
        'id': 'post-1',
        'type': 'post',
        'title': 'Feed post',
        'body': 'body',
        'created_at': '2026-09-01T00:00:00.000Z',
      },
      {
        'id': 'ad-1',
        'type': 'ad',
        'title': 'Ad item',
        'body': 'body',
        'created_at': '2026-09-02T00:00:00.000Z',
      },
      {
        'id': 'post-2',
        'type': 'post',
        'title': 'Another feed post',
        'body': 'body',
        'created_at': '2026-09-03T00:00:00.000Z',
      },
    ];

    test('a post appears in the Jma3a Feed set (type == post)', () {
      final items = mixedRows.map(OfficialContentItem.fromMap).toList();
      final feed = items.where((i) => i.type == OfficialContentType.post);
      expect(feed.map((i) => i.id), containsAll(['post-1', 'post-2']));
    });

    test('a post never appears in the Advertisements set (type == ad)', () {
      final items = mixedRows.map(OfficialContentItem.fromMap).toList();
      final ads = items.where((i) => i.type == OfficialContentType.ad);
      expect(ads.map((i) => i.id), isNot(contains('post-1')));
      expect(ads.map((i) => i.id), isNot(contains('post-2')));
    });

    test('an ad appears in the Advertisements set', () {
      final items = mixedRows.map(OfficialContentItem.fromMap).toList();
      final ads = items.where((i) => i.type == OfficialContentType.ad);
      expect(ads.map((i) => i.id), contains('ad-1'));
    });

    test('an ad never appears in the Jma3a Feed set', () {
      final items = mixedRows.map(OfficialContentItem.fromMap).toList();
      final feed = items.where((i) => i.type == OfficialContentType.post);
      expect(feed.map((i) => i.id), isNot(contains('ad-1')));
    });
  });
}
