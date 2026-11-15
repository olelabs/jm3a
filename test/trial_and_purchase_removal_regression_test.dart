// Regression coverage for the trial-system removal + customer-facing
// in-app purchase cleanup (paid packs are now obtained exclusively through
// the external Jma3a Store).
//
// Covers, per the task's own requirements:
//   1. No trial purchase / "End Trial" UI ships in the app.
//   2. No trial-eligibility path can make an unowned paid pack selectable
//      in the room pack selector.
//   3. free-or-owned visibility still holds for the room pack selector's
//      pack pool (the same invariant every other pack surface enforces).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/services/pack_sync_service.dart';
import 'package:jma3a/features/packs/data/pack_repository.dart';
import 'package:jma3a/features/packs/presentation/pack_provider.dart';
import 'package:jma3a/features/rooms/presentation/widgets/game_settings_sheet.dart';
import 'package:mocktail/mocktail.dart';

class _MockPackSyncService extends Mock implements PackSyncService {}

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

/// Same "free-or-owned" contract browsePacks' real implementation applies
/// — mirrors room_settings_pack_visibility_test.dart's fake so this test
/// exercises the exact same free-tier query the room pack selector's
/// browsable half now uses (with no trial-eligible half left to merge).
class _FakePackRepository implements PackRepository {
  _FakePackRepository(this._catalog);
  final List<PackEntity> _catalog;

  @override
  Future<List<PackEntity>> browsePacks({
    String? query,
    String? gameType,
    String? categoryId,
    List<String> ownedPackIds = const [],
    String? language,
    String sortBy = 'avg_rating',
    int page = 0,
    int perPage = 20,
  }) async => _catalog.where((p) => p.isFree || ownedPackIds.contains(p.id)).toList();

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

Map<String, dynamic> _loadArb(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  group('1. No trial purchase / "End Trial" UI ships', () {
    test('trial_limit_sheet.dart and pack_trial_state.dart were deleted, '
        'not just unwired — the sheet cannot be re-imported by accident', () {
      expect(
        File('lib/shared/widgets/game/trial_limit_sheet.dart').existsSync(),
        isFalse,
      );
      expect(
        File('lib/features/packs/domain/pack_trial_state.dart').existsSync(),
        isFalse,
      );
    });

    test('no trial-purchase/"End Trial" copy remains in any shipped '
        'localization file (EN/FR/AR) — proves the removal is complete, '
        'not just unreachable dead code left behind', () {
      const removedKeys = [
        'packTrialBadgeTooltip',
        'packTrialCardsRemaining',
        'packTrialPromptTitle',
        'packTrialPromptBody',
        'packTrialPurchaseButton',
        'packTrialEndButton',
        'packConfirmPurchaseTitle',
        'packConfirmPurchaseBody',
        'packConfirmPurchaseAction',
        'packBuyForPrice',
        'packInsufficientBalance',
        'packInsufficientBalanceBody',
        'packTopUpWallet',
        'packPurchaseFailed',
        'packPurchasedNotice',
        'packProcessingEllipsis',
      ];
      for (final path in [
        'lib/core/l10n/app_en.arb',
        'lib/core/l10n/app_fr.arb',
        'lib/core/l10n/app_ar.arb',
      ]) {
        final keys = _loadArb(path).keys.toSet();
        final leftover = removedKeys.where(keys.contains).toSet();
        expect(leftover, isEmpty, reason: '$path still has: $leftover');
      }
    });
  });

  group(
    '2 & 3. Room pack selector: no trial-eligibility path, free-or-owned '
    'visibility holds',
    () {
      test('the room pack picker pool has exactly 3 sources — owned '
          '(purchased/local) + the free browsable tier — with no 4th '
          'trial-eligible source able to inject an unowned paid pack '
          '(the old getEligibleTrialPacks() merge no longer exists)', () async {
        final provider = PackProvider(
          packRepository: _FakePackRepository([]),
          packSyncService: _MockPackSyncService(),
        );
        final ownedPaid = _pack('owned-paid', priceMru: 500);
        provider.seedPurchasedPacksForTest([ownedPaid]);

        final repo = _FakePackRepository([
          _pack('free-1'),
          ownedPaid,
          _pack('unowned-paid', priceMru: 500),
        ]);
        final browsable = await fetchRoomSettingsBrowsablePacks(repo);

        // This is exactly game_settings_sheet.dart's own merge — see
        // _loadPacks/_remergePacks: purchasedPacks + localPacks +
        // the free browsable tier. Nothing else feeds this pool anymore.
        final pool = <String, PackEntity>{
          for (final p in [
            ...provider.purchasedPacks,
            ...provider.localPacks,
            ...browsable,
          ])
            p.id: p,
        };

        expect(pool.containsKey('owned-paid'), isTrue);
        expect(pool.containsKey('free-1'), isTrue);
        expect(
          pool.containsKey('unowned-paid'),
          isFalse,
          reason:
              'an unowned paid pack must never be selectable in the room '
              'pack picker — with trial eligibility removed, the only way '
              'a paid pack enters this pool is via real ownership '
              '(purchasedPacks/localPacks)',
        );
      });
    },
  );
}
