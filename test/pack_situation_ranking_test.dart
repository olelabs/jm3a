// Tests for item 7/9/10 — deterministic pack-situation ranking, and
// backward compatibility for packs with zero/multiple types.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/packs/data/pack_repository.dart';
import 'package:jma3a/features/packs/domain/pack_situation_tags.dart';

PackEntity _pack(String id, {List<String> tags = const []}) => PackEntity(
  id: id,
  creatorId: 'creator',
  titleJson: const {'en': 'Pack'},
  status: PackStatus.approved,
  gameType: 'truth_or_dare',
  language: 'en',
  priceMru: 0,
  cardCount: 20,
  avgRating: 0,
  totalRatings: 0,
  totalPurchases: 0,
  totalPlays: 0,
  tags: tags,
);

void main() {
  group('pack can have zero/multiple types (backward compatibility)', () {
    test('a pack with no tags at all is still a completely valid entity', () {
      final pack = _pack('p1');
      expect(pack.tags, isEmpty);
      expect(pack.situationMatchCount({'relationship'}), 0);
    });

    test('a pack can carry multiple types', () {
      final pack = _pack('p1', tags: const ['relationship', 'breakup', 'party']);
      expect(pack.tags, hasLength(3));
    });
  });

  group('rankPacksBySituation — item 7 deterministic ranking', () {
    test('no selected filters preserves existing ordering/behavior exactly', () {
      final packs = [
        _pack('a', tags: const ['relationship']),
        _pack('b'),
        _pack('c', tags: const ['party']),
      ];
      final ranked = rankPacksBySituation(packs, {});
      expect(ranked, same(packs)); // literally the same list, untouched
    });

    test('exact/full match ranks above partial match, which ranks above '
        'unrelated', () {
      final fullMatch = _pack(
        'full',
        tags: const ['relationship', 'breakup', 'dating'],
      );
      final partialMatch = _pack('partial', tags: const ['relationship', 'breakup']);
      final weakMatch = _pack('weak', tags: const ['relationship']);
      final unrelated = _pack('unrelated', tags: const ['party']);
      final noTags = _pack('none');

      final packs = [unrelated, weakMatch, noTags, fullMatch, partialMatch];
      final ranked = rankPacksBySituation(
        packs,
        {'relationship', 'breakup', 'dating'},
      );

      expect(
        ranked.map((p) => p.id).toList(),
        // full (3 overlaps) > partial (2) > weak (1) > {unrelated, none}
        // (0, tie broken by original relative order).
        ['full', 'partial', 'weak', 'unrelated', 'none'],
      );
    });

    test('ties (equal match count) preserve original relative order — '
        'deterministic, never random', () {
      final p1 = _pack('p1', tags: const ['relationship']);
      final p2 = _pack('p2', tags: const ['relationship']);
      final p3 = _pack('p3', tags: const ['relationship']);
      final packs = [p3, p1, p2];

      final ranked = rankPacksBySituation(packs, {'relationship'});
      expect(ranked.map((p) => p.id).toList(), ['p3', 'p1', 'p2']);

      // Running it again must produce the exact same order — not random.
      final rankedAgain = rankPacksBySituation(packs, {'relationship'});
      expect(rankedAgain.map((p) => p.id).toList(), ['p3', 'p1', 'p2']);
    });

    test('a pack matching zero of the selected tags still appears, just '
        'ranked lowest (packs are never hidden by the filter)', () {
      final matched = _pack('matched', tags: const ['relationship']);
      final unrelated = _pack('unrelated', tags: const ['travel']);
      final ranked = rankPacksBySituation([unrelated, matched], {'relationship'});
      expect(ranked.map((p) => p.id).toSet(), {'matched', 'unrelated'});
      expect(ranked.first.id, 'matched');
    });
  });
}
