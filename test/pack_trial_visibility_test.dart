// Trial Packs — visibility/badge coverage.
//
// The actual eligibility FILTERING (trial-enabled AND unowned AND not
// already trialed) is enforced server-side by get_eligible_trial_packs()
// (see migration_2026_pack_trial.sql) — a database RPC that cannot be
// exercised without a live Supabase instance, not available in this test
// environment. What IS directly testable here:
//   - PackEntity itself defaults every trial field off, so a pack that
//     predates this feature (or whose row the repository parses without
//     the two new columns present) never accidentally becomes a trial
//     pack on the client.
//   - packShowsTrialBadge (game_settings_sheet.dart), the pure predicate
//     the room-settings pack picker's badge is gated on.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/packs/domain/pack_entity.dart';
import 'package:jma3a/features/rooms/presentation/widgets/game_settings_sheet.dart';

void main() {
  group('PackEntity trial defaults', () {
    test(
      'a pack constructed without trial fields defaults to disabled/zero '
      '(matches the DB column defaults — no existing pack becomes a '
      'trial pack by accident)',
      () {
        const pack = PackEntity(
          id: 'p1',
          creatorId: 'c1',
          titleJson: {'en': 'Test'},
          status: PackStatus.approved,
          gameType: 'truth_or_dare',
          language: 'en',
          priceMru: 500,
          cardCount: 30,
          avgRating: 0,
          totalRatings: 0,
          totalPurchases: 0,
          totalPlays: 0,
        );
        expect(pack.trialEnabled, isFalse);
        expect(pack.trialCardCount, 0);
      },
    );

    test('an explicitly trial-enabled pack carries the configured count', () {
      const pack = PackEntity(
        id: 'p2',
        creatorId: 'c1',
        titleJson: {'en': 'Trial Pack'},
        status: PackStatus.approved,
        gameType: 'meme_game',
        language: 'en',
        priceMru: 500,
        cardCount: 30,
        avgRating: 0,
        totalRatings: 0,
        totalPurchases: 0,
        totalPlays: 0,
        trialEnabled: true,
        trialCardCount: 5,
      );
      expect(pack.trialEnabled, isTrue);
      expect(pack.trialCardCount, 5);
    });
  });

  group('packShowsTrialBadge', () {
    test('trial-enabled + not owned -> badge shows', () {
      expect(
        packShowsTrialBadge(trialEnabled: true, isOwned: false),
        isTrue,
      );
    });

    test(
      'trial-enabled + owned -> no badge (purchased packs behave as '
      'fully normal packs, trial logic never applies — section 15)',
      () {
        expect(
          packShowsTrialBadge(trialEnabled: true, isOwned: true),
          isFalse,
        );
      },
    );

    test('not trial-enabled -> no badge regardless of ownership', () {
      expect(
        packShowsTrialBadge(trialEnabled: false, isOwned: false),
        isFalse,
      );
      expect(
        packShowsTrialBadge(trialEnabled: false, isOwned: true),
        isFalse,
      );
    });
  });
}
