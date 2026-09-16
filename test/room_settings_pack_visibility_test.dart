// Regression coverage for "Room Settings → Truth or Dare pack picker shows
// 'No packs available'" even though approved, non-deleted Truth or Dare
// packs exist (verified directly against Supabase: status = 'approved',
// deleted_at IS NULL, game_type = 'truth_or_dare').
//
// ROOT CAUSE: game_settings_sheet.dart's _loadPacks() built its browsable
// pool from PackProvider.browsePacks — a SINGLE cache shared with (and
// mutated by) the Packs/Marketplace screen's own game-type/category/
// free-only filters (marketplace_screen.dart's onGameTypeChanged/
// onFreeOnlyChanged, the "Item 2" combined-AND-filters fix). Once that
// screen's filters were ever applied for a different game type — or any
// combination with zero matches — the shared cache stayed narrowed to
// that result, and Room Settings silently inherited it instead of the
// real set of approved packs, even though the query layer
// (PackRepository.browsePacks) and every individual predicate
// (status/deleted_at/game_type/category/language) were themselves
// correct — confirmed by pack_filter_combination_test.dart and
// pack_tabs_and_situation_filters_test.dart already covering those.
//
// THE FIX: game_settings_sheet.dart now fetches its own browsable pool
// directly via fetchRoomSettingsBrowsablePacks (freeOnly: true, no
// gameType restriction — every tab still needs its own packs, category/
// language stay purely additive client-side filters), independent of
// whatever filter state the Marketplace screen left the shared
// PackProvider cache in.
//
// This drives fetchRoomSettingsBrowsablePacks against a lightweight fake
// PackRepository, the same offline-testable pattern
// pack_filter_combination_test.dart already uses for PackProvider.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/packs/data/pack_repository.dart';
import 'package:jma3a/features/rooms/presentation/widgets/game_settings_sheet.dart';

PackEntity _approvedPack(
  String id, {
  required String gameType,
  int price = 0,
}) => PackEntity(
  id: id,
  creatorId: 'creator',
  titleJson: const {'en': 'Pack'},
  status: PackStatus.approved,
  gameType: gameType,
  language: 'en',
  priceMru: price,
  cardCount: 20,
  avgRating: 0,
  totalRatings: 0,
  totalPurchases: 0,
  totalPlays: 0,
);

class _RecordedBrowseCall {
  _RecordedBrowseCall({required this.gameType, required this.freeOnly});
  final String? gameType;
  final bool freeOnly;
}

/// Mirrors the shared library of approved packs a real Supabase
/// `packs` table would already be filtering to (status='approved',
/// deleted_at IS NULL) — this fake only needs to reproduce
/// browsePacks' own AND-of-filters contract, already proven correct
/// against the real implementation by pack_filter_combination_test.dart.
class _FakePackRepository implements PackRepository {
  _FakePackRepository(this._catalog);
  final List<PackEntity> _catalog;
  final calls = <_RecordedBrowseCall>[];

  @override
  Future<List<PackEntity>> browsePacks({
    String? query,
    String? gameType,
    String? categoryId,
    bool freeOnly = false,
    String? language,
    String sortBy = 'avg_rating',
    int page = 0,
    int perPage = 20,
  }) async {
    calls.add(_RecordedBrowseCall(gameType: gameType, freeOnly: freeOnly));
    return _catalog.where((p) {
      if (gameType != null && p.gameType != gameType) return false;
      if (categoryId != null && p.categoryId != categoryId) return false;
      if (freeOnly && !p.isFree) return false;
      return true;
    }).toList();
  }

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

void main() {
  group('fetchRoomSettingsBrowsablePacks', () {
    test(
      'approved Truth or Dare packs appear with the default (no game-type, '
      'no category, no language) filters, alongside every other game '
      "type's packs — the exact 'No packs available' regression this "
      'proves fixed',
      () async {
        final repo = _FakePackRepository([
          _approvedPack('tod-classic', gameType: 'truth_or_dare'),
          _approvedPack('tod-arabic-night', gameType: 'truth_or_dare'),
          _approvedPack('nhie-1', gameType: 'never_have_i_ever'),
          _approvedPack('meme-1', gameType: 'meme_game'),
        ]);

        final result = await fetchRoomSettingsBrowsablePacks(repo);

        expect(
          result.map((p) => p.id).toSet(),
          {'tod-classic', 'tod-arabic-night', 'nhie-1', 'meme-1'},
          reason:
              'every approved free pack across all 3 game types must be '
              "present — GameSettingsSheet's own tab switcher (_packTab) "
              'filters this pool client-side with no refetch, so it can '
              'never be scoped to a single game type up front',
        );
      },
    );

    test(
      'never asks the repository to restrict by game type — the pool must '
      'stay usable for every tab (ToD/NHIE/Meme), not just whichever one '
      'happened to be selected last',
      () async {
        final repo = _FakePackRepository([
          _approvedPack('tod-1', gameType: 'truth_or_dare'),
        ]);

        await fetchRoomSettingsBrowsablePacks(repo);

        expect(repo.calls, hasLength(1));
        expect(
          repo.calls.single.gameType,
          isNull,
          reason:
              'a non-null gameType here would silently hide every other '
              "tab's packs, exactly like the shared "
              'PackProvider.browsePacks cache used to when the '
              'Marketplace screen last narrowed it to a different game '
              'type',
        );
        expect(repo.calls.single.freeOnly, isTrue);
      },
    );

    test(
      'a paid Truth or Dare pack is correctly excluded from the browsable '
      '(free-tier) pool — owned/purchased packs come from '
      'PackProvider.purchasedPacks/localPacks separately, not from here',
      () async {
        final repo = _FakePackRepository([
          _approvedPack('tod-free', gameType: 'truth_or_dare'),
          _approvedPack('tod-paid', gameType: 'truth_or_dare', price: 500),
        ]);

        final result = await fetchRoomSettingsBrowsablePacks(repo);

        expect(result.map((p) => p.id).toSet(), {'tod-free'});
      },
    );
  });
}
