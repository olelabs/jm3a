// Regression coverage for the "Store-granted pack visible in My Packs but
// not in Browse" bug.
//
// ROOT CAUSE (confirmed by investigation): Browse (_browsePacks) is a
// separately-cached, paginated snapshot; My Packs reads _purchasedPacks
// live. Browse's own query sorts by avg_rating DESC with perPage: 20 — a
// just-granted pack (avg_rating 0 by default) legitimately satisfies the
// free-or-owned filter but can still land past page 1. PackProvider.
// loadBrowsePacks now guarantees any OWNED pack matching the currently
// active filters is visible on the first page, by prepending it if the
// query's own first page didn't already include it, without changing the
// underlying sort/query.
//
// browsePackMatchesFilters is the pure predicate this injection uses to
// stay consistent with what the server query itself would apply — tested
// directly first, then loadBrowsePacks' merge behavior end-to-end against
// a fake repository.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/services/pack_sync_service.dart';
import 'package:jma3a/features/packs/data/pack_repository.dart';
import 'package:jma3a/features/packs/presentation/pack_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockPackSyncService extends Mock implements PackSyncService {}

PackEntity _pack(
  String id, {
  int priceMru = 0,
  String gameType = 'truth_or_dare',
  String? categoryId,
  String language = 'en',
  bool isMultilang = false,
  double avgRating = 0,
}) => PackEntity(
  id: id,
  creatorId: 'creator',
  titleJson: const {'en': 'Pack'},
  status: PackStatus.approved,
  gameType: gameType,
  language: language,
  isMultilang: isMultilang,
  categoryId: categoryId,
  priceMru: priceMru,
  cardCount: 20,
  avgRating: avgRating,
  totalRatings: 0,
  totalPurchases: 0,
  totalPlays: 0,
);

void main() {
  group('browsePackMatchesFilters (pure predicate)', () {
    test('no filters active — always matches', () {
      expect(browsePackMatchesFilters(_pack('p1')), isTrue);
    });

    test('game type filter — matches only the same game type', () {
      final pack = _pack('p1', gameType: 'meme_game');
      expect(browsePackMatchesFilters(pack, gameType: 'meme_game'), isTrue);
      expect(browsePackMatchesFilters(pack, gameType: 'truth_or_dare'), isFalse);
    });

    test('category filter — matches only the same category', () {
      final pack = _pack('p1', categoryId: 'cat-1');
      expect(browsePackMatchesFilters(pack, categoryId: 'cat-1'), isTrue);
      expect(browsePackMatchesFilters(pack, categoryId: 'cat-2'), isFalse);
    });

    test('language filter — matches same language or a multilang pack', () {
      final arPack = _pack('p1', language: 'ar');
      final multilangPack = _pack('p2', language: 'fr', isMultilang: true);
      expect(browsePackMatchesFilters(arPack, language: 'ar'), isTrue);
      expect(browsePackMatchesFilters(arPack, language: 'fr'), isFalse);
      expect(browsePackMatchesFilters(multilangPack, language: 'ar'), isTrue);
    });

    test('language filter value "multi" imposes no language restriction', () {
      expect(browsePackMatchesFilters(_pack('p1', language: 'fr'), language: 'multi'), isTrue);
    });

    test('every active filter must match simultaneously (AND)', () {
      final pack = _pack('p1', gameType: 'meme_game', categoryId: 'cat-1', language: 'ar');
      expect(
        browsePackMatchesFilters(pack, gameType: 'meme_game', categoryId: 'cat-1', language: 'ar'),
        isTrue,
      );
      expect(
        browsePackMatchesFilters(pack, gameType: 'meme_game', categoryId: 'cat-1', language: 'fr'),
        isFalse,
      );
    });
  });

  group('PackProvider.loadBrowsePacks — owned packs stay visible past pagination', () {
    late _FakePackRepository repo;
    late PackProvider provider;

    setUp(() {
      repo = _FakePackRepository();
      provider = PackProvider(packRepository: repo, packSyncService: _MockPackSyncService());
    });

    test('an owned pack the query did NOT return on page 1 is prepended '
        '(the exact regression: a zero-rated newly-granted pack sorted '
        'past the first 20 avg_rating-ordered results)', () async {
      final grantedPack = _pack('granted-1', priceMru: 500, avgRating: 0);
      provider.seedPurchasedPacksForTest([grantedPack]);
      // The query's own page 1 does not include it, exactly like a real
      // avg_rating DESC page would omit a freshly-granted, unrated pack.
      repo.queuedResults = [_pack('free-1'), _pack('free-2')];

      await provider.loadBrowsePacks(reset: true);

      expect(provider.browsePacks.map((p) => p.id), contains('granted-1'));
    });

    test('an owned pack already returned by the query is not duplicated', () async {
      final grantedPack = _pack('granted-1', priceMru: 500);
      provider.seedPurchasedPacksForTest([grantedPack]);
      repo.queuedResults = [grantedPack, _pack('free-1')];

      await provider.loadBrowsePacks(reset: true);

      expect(provider.browsePacks.where((p) => p.id == 'granted-1'), hasLength(1));
    });

    test('an owned pack that does not match the active game-type filter is '
        'NOT injected — ownership never overrides an active filter', () async {
      final ownedMemePack = _pack('owned-meme', priceMru: 500, gameType: 'meme_game');
      provider.seedPurchasedPacksForTest([ownedMemePack]);
      repo.queuedResults = [_pack('free-tod', gameType: 'truth_or_dare')];

      await provider.loadBrowsePacks(reset: true, gameType: 'truth_or_dare');

      expect(provider.browsePacks.map((p) => p.id), isNot(contains('owned-meme')));
    });

    test('a free pack in _purchasedPacks (isFree via price 0) is not '
        're-injected — only paid owned packs need the pagination rescue, '
        'since free packs already satisfy the query on their own', () async {
      final freePurchased = _pack('free-in-list', priceMru: 0);
      provider.seedPurchasedPacksForTest([freePurchased]);
      repo.queuedResults = [_pack('free-other')];

      await provider.loadBrowsePacks(reset: true);

      expect(provider.browsePacks.map((p) => p.id), isNot(contains('free-in-list')));
    });

    test('loadMoreBrowsePacks (reset: false) does not re-run the '
        'injection — the owned pack stays exactly once across pages', () async {
      final grantedPack = _pack('granted-1', priceMru: 500);
      provider.seedPurchasedPacksForTest([grantedPack]);
      repo.queuedResults = [_pack('free-1')];
      await provider.loadBrowsePacks(reset: true);
      expect(provider.browsePacks.where((p) => p.id == 'granted-1'), hasLength(1));

      repo.queuedResults = List.generate(20, (i) => _pack('page2-$i'));
      await provider.loadMoreBrowsePacks();

      expect(provider.browsePacks.where((p) => p.id == 'granted-1'), hasLength(1));
    });
  });
}

/// Returns whatever's queued in [queuedResults] regardless of the filters
/// passed — the filter-forwarding contract itself is already covered by
/// pack_filter_combination_test.dart; this fake exists only to drive
/// loadBrowsePacks' post-fetch merge logic under test here.
class _FakePackRepository implements PackRepository {
  List<PackEntity> queuedResults = const [];

  @override
  Future<List<PackEntity>> browsePacks({
    String? gameType,
    String? categoryId,
    List<String> ownedPackIds = const [],
    String? language,
    String? query,
    String sortBy = 'avg_rating',
    int page = 0,
    int perPage = 20,
  }) async => queuedResults;

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}
