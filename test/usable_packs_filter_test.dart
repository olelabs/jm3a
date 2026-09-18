// The Packs screen shows only packs the user can actually USE: free ones
// (price_mru = 0) plus the paid ones they own. Unowned paid packs are never
// listed, which is also why the old "Free" filter chip no longer exists —
// there is no free/paid split left to narrow.
//
// This exercises the fake-repository contract used across the pack tests
// (the same free-or-owned rule PackRepository applies in its PostgREST
// `or` filter), proving the rule itself rather than the query string.
import 'package:flutter_test/flutter_test.dart';

class _Pack {
  const _Pack(this.id, this.priceMru);
  final String id;
  final int priceMru;
  bool get isFree => priceMru == 0;
}

List<_Pack> _usable(List<_Pack> catalog, List<String> ownedPackIds) =>
    catalog.where((p) => p.isFree || ownedPackIds.contains(p.id)).toList();

void main() {
  const catalog = [
    _Pack('free-1', 0),
    _Pack('free-2', 0),
    _Pack('paid-owned', 500),
    _Pack('paid-unowned', 750),
  ];

  test('free packs are always shown', () {
    expect(
      _usable(catalog, const []).map((p) => p.id),
      containsAll(<String>['free-1', 'free-2']),
    );
  });

  test('an unowned paid pack is never shown', () {
    expect(
      _usable(catalog, const ['paid-owned']).map((p) => p.id),
      isNot(contains('paid-unowned')),
    );
  });

  test('a paid pack the user owns IS shown', () {
    expect(
      _usable(catalog, const ['paid-owned']).map((p) => p.id),
      contains('paid-owned'),
    );
  });

  test('with no purchases at all, only free packs remain', () {
    expect(
      _usable(catalog, const []).map((p) => p.id).toSet(),
      {'free-1', 'free-2'},
    );
  });

  test('ownership never hides a free pack', () {
    expect(_usable(catalog, const ['paid-owned']), hasLength(3));
  });
}
