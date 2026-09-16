// Trial Packs — fix 1 regression (root cause A1): the `game` GoRoute
// (app_router.dart) previously fell back to a packId-less GameConfig
// whenever its `extra` map was missing/incomplete — GoRouter's `extra`
// is NOT restored across app process death / OS state restoration, a
// real production scenario. Every trial gate reads `config.packId`
// (ownerAdvanceTurn) or receives `packId` as a required init param
// (initAsOwner/startPackTrial), so a missing value there silently
// disabled trial enforcement for the whole session — the game would
// play on indefinitely past the configured trial_card_count.
//
// gameRouteExtrasComplete is the pure guard the route builder now checks
// before ever constructing an owner game screen; a false result routes
// to the existing NotFoundScreen instead of continuing with unenforceable
// trial state. The route builder itself needs a live GoRouterState to
// pump — this tests the one decision it actually makes.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/router/app_router.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';

void main() {
  group('gameRouteExtrasComplete', () {
    test('a real config with a non-empty packId -> complete', () {
      const config = GameConfig(
        maxRounds: 10,
        turnTimerSeconds: 60,
        allowSkip: true,
        allowSpicy: false,
        packId: 'pack-123',
      );
      expect(
        gameRouteExtrasComplete(config: config, packId: 'pack-123'),
        isTrue,
      );
    });

    test('missing config (null) -> incomplete, regardless of packId', () {
      expect(
        gameRouteExtrasComplete(config: null, packId: 'pack-123'),
        isFalse,
      );
    });

    test(
      'missing packId (empty string, matching the old '
      "extra['packId'] as String? ?? '' default) -> incomplete, even "
      'with a real config',
      () {
        const config = GameConfig(
          maxRounds: 10,
          turnTimerSeconds: 60,
          allowSkip: true,
          allowSpicy: false,
        );
        expect(gameRouteExtrasComplete(config: config, packId: ''), isFalse);
      },
    );

    test('both missing -> incomplete (the exact real-device failure mode)', () {
      expect(gameRouteExtrasComplete(config: null, packId: ''), isFalse);
    });
  });
}
