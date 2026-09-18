// Regression coverage for "an unowned paid pack showing in the user's own
// Profile > Most Played section" (paid-pack-visibility audit, item 3).
//
// ROOT CAUSE: PackRepository.getMostPlayedPacksForUser has no
// price/ownership condition — it only reflects rooms the profile owner
// was a member of, so it can legitimately include a paid pack they played
// without buying (or no longer own). user_profile_screen.dart (viewing
// SOMEONE ELSE's profile) already guards this with
// `_mostPlayed.where(packProvider.isOwned)`; profile_screen.dart (the
// user's OWN profile) was missing the identical guard, so its own
// "Most Played" section could surface — and link to — an unowned paid
// pack. profile_screen.dart's `visibleMostPlayed` now applies the exact
// same `PackProvider.isOwned` filter before that list is rendered or
// becomes tappable, so an excluded pack has no card to navigate from —
// no separate navigation guard needed.
//
// This exercises PackProvider.isOwned directly against the same shape of
// mixed list (free / owned-paid / unowned-paid) that mostPlayedPacks can
// contain, mirroring exactly the filter expression profile_screen.dart
// now applies — same style as pack_browse_ownership_refresh_test.dart's
// direct-provider-logic coverage for the sibling Browse-visibility fix.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/services/pack_sync_service.dart';
import 'package:jma3a/features/packs/data/pack_repository.dart';
import 'package:jma3a/features/packs/presentation/pack_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockPackSyncService extends Mock implements PackSyncService {}

class _UnimplementedPackRepository implements PackRepository {
  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

PackEntity _pack(String id, {int priceMru = 0}) => PackEntity(
  id: id,
  creatorId: 'creator',
  titleJson: const {'en': 'Pack'},
  status: PackStatus.approved,
  gameType: 'truth_or_dare',
  language: 'en',
  priceMru: priceMru,
  cardCount: 20,
  avgRating: 0,
  totalRatings: 0,
  totalPurchases: 0,
  totalPlays: 0,
);

void main() {
  test(
    "own-profile Most Played: an unowned paid pack is excluded by the same "
    'PackProvider.isOwned filter profile_screen.dart applies to '
    'mostPlayedPacks — a free pack and an owned paid pack both survive',
    () {
      final provider = PackProvider(
        packRepository: _UnimplementedPackRepository(),
        packSyncService: _MockPackSyncService(),
      );

      final freePack = _pack('free-1');
      final ownedPaidPack = _pack('owned-paid-1', priceMru: 500);
      final unownedPaidPack = _pack('unowned-paid-1', priceMru: 500);
      provider.seedPurchasedPacksForTest([ownedPaidPack]);

      // Same "played in a room" list mostPlayedPacks can hold, regardless
      // of current ownership — the mix this fix's filter must resolve.
      final mostPlayed = [freePack, ownedPaidPack, unownedPaidPack];

      final visibleMostPlayed = mostPlayed.where(provider.isOwned).toList();

      expect(
        visibleMostPlayed.map((p) => p.id),
        containsAll(['free-1', 'owned-paid-1']),
      );
      expect(
        visibleMostPlayed.map((p) => p.id),
        isNot(contains('unowned-paid-1')),
      );
      expect(visibleMostPlayed, hasLength(2));
    },
  );
}
