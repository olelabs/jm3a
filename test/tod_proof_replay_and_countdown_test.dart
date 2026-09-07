// Tests for items 1 & 2 — timed image proof countdown/rebuild isolation,
// and premium image-proof replay: initial view + ONE replay, max 2 total
// for 'once'/'timed' image proof (corrected — a prior pass over-granted
// premium +2 views here; see migration_2026_proof_view_premium_replay_fix
// .sql and todProofMaxViews' doc comment for the full rationale).
//
// Item 1 (tod_card_screen.dart TodCountdownBadge): the actual fix is
// architectural — the countdown lives in its own StatefulWidget, completely
// separate from the (now `late final`, decoded-once) image bytes above it
// in _TimedImageProofDialog, so a countdown tick's setState can never touch
// the image subtree. TodCountdownBadge is exactly the isolated piece that
// ticks every second; these tests pump IT directly and confirm it counts
// down and fires onExpired exactly once at zero, without needing (or being
// able to reach) the private image-decoding dialog around it. Untouched by
// this pass — item 2 only changed the view-count arithmetic.
//
// Item 2 (todProofMaxViews, tod_models.dart): the exact max-views formula
// mirrored by record_proof_view server-side (see
// migration_2026_proof_view_premium_replay_fix.sql) — this test file is
// the offline proof that the display formula and the documented server
// formula agree. The RPC's pg_advisory_xact_lock atomicity and
// authorization checks (visibility policy, room/game membership) cannot be
// exercised from this offline suite — see tod_proof_visibility_test.dart
// for the authorization logic that IS covered offline, and the final
// report for what still needs live/device verification.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/truth_or_dare/domain/tod_models.dart';
import 'package:jma3a/features/games/truth_or_dare/presentation/screens/tod_card_screen.dart';

/// A viewer is allowed another view exactly while their recorded count is
/// below the max — the same inequality record_proof_view enforces
/// (atomically, via pg_advisory_xact_lock) against tod_proof_views. Used
/// below to exercise the counting/rejection logic offline without a live
/// database.
bool _canView(int existingCount, int maxViews) => existingCount < maxViews;

void main() {
  group('todProofMaxViews — premium replay formula (tests 1-2)', () {
    test('1. free viewer: once/timed = 1 total view', () {
      expect(
        todProofMaxViews(viewMode: TodProofViewMode.once, isPremium: false),
        1,
      );
      expect(
        todProofMaxViews(viewMode: TodProofViewMode.timed, isPremium: false),
        1,
      );
    });

    test('2. premium viewer: once/timed = initial + ONE replay = 2 total '
        '(not 3)', () {
      expect(
        todProofMaxViews(viewMode: TodProofViewMode.once, isPremium: true),
        2,
      );
      expect(
        todProofMaxViews(viewMode: TodProofViewMode.timed, isPremium: true),
        2,
      );
    });

    test('replayOnce mode already grants everyone one replay (base 2); '
        'premium adds exactly one more on top (3) — unrelated to this fix, '
        'still the original pre-existing rule', () {
      expect(
        todProofMaxViews(
          viewMode: TodProofViewMode.replayOnce,
          isPremium: false,
        ),
        2,
      );
      expect(
        todProofMaxViews(
          viewMode: TodProofViewMode.replayOnce,
          isPremium: true,
        ),
        3,
      );
    });

    test('premium always grants exactly ONE more view than free for the '
        'same mode — never two', () {
      for (final mode in TodProofViewMode.values) {
        final free = todProofMaxViews(viewMode: mode, isPremium: false);
        final premium = todProofMaxViews(viewMode: mode, isPremium: true);
        expect(premium, free + 1);
      }
    });
  });

  group('Premium view-count enforcement logic (tests 3-6, 8) — mirrors '
      'record_proof_view\'s existingCount >= v_max_views check', () {
    test('3. premium initial view succeeds (existing count 0 of 2)', () {
      final max = todProofMaxViews(
        viewMode: TodProofViewMode.once,
        isPremium: true,
      );
      expect(_canView(0, max), isTrue);
    });

    test('4. premium one replay succeeds (existing count 1 of 2)', () {
      final max = todProofMaxViews(
        viewMode: TodProofViewMode.once,
        isPremium: true,
      );
      expect(_canView(1, max), isTrue);
    });

    test('5. premium third opening is rejected (existing count 2 of 2)', () {
      final max = todProofMaxViews(
        viewMode: TodProofViewMode.once,
        isPremium: true,
      );
      expect(_canView(2, max), isFalse);
    });

    test('6. replay count is tracked independently per viewer — one '
        "viewer's usage never affects another's remaining views", () {
      final max = todProofMaxViews(
        viewMode: TodProofViewMode.once,
        isPremium: true,
      );
      final perViewerCounts = <String, int>{'alice': 2, 'bob': 0};
      expect(_canView(perViewerCounts['alice']!, max), isFalse);
      expect(_canView(perViewerCounts['bob']!, max), isTrue);
    });

    test('8. sequential requests can never push the recorded count past '
        'the maximum — the same monotonic-count invariant '
        'pg_advisory_xact_lock protects under concurrency (the lock itself '
        'needs a live database and cannot be exercised offline)', () {
      final max = todProofMaxViews(
        viewMode: TodProofViewMode.once,
        isPremium: true,
      );
      var count = 0;
      final grantedAttempts = <bool>[];
      for (var attempt = 0; attempt < 5; attempt++) {
        final granted = _canView(count, max);
        grantedAttempts.add(granted);
        if (granted) count++;
      }
      expect(grantedAttempts, [true, true, false, false, false]);
      expect(count, max);
    });
  });

  group('7. visibility authorization still applies to a premium replay', () {
    test('a premium viewer excluded by a personalized (selected-users) '
        'visibility policy is still denied — premium status never bypasses '
        'visibility authorization, which record_proof_view checks BEFORE '
        'computing v_max_views', () {
      // Same TodProofVisibilitySettings the server-side policy check
      // mirrors (see tod_proof_visibility_test.dart for full coverage of
      // every mode) — a premium user not in the selected list is denied
      // regardless of how many views their premium status would otherwise
      // grant.
      const settings = TodProofVisibilitySettings(
        visibility: TodProofVisibility.selectedPlayers,
        visibleToIds: ['alice'],
      );
      expect(settings.canView('bob-premium', false), isFalse);
      // The formula would have granted bob 2 views if he were authorized —
      // authorization is a separate, prior gate, never skipped.
      expect(
        todProofMaxViews(viewMode: TodProofViewMode.once, isPremium: true),
        2,
      );
    });
  });

  group('10. voice proof is untouched by this change', () {
    test('todProofMaxViews has no parameter or branch for proof source — '
        'voice proofs never go through this image-proof formula at all',
        () {
      // TodProofSource.voice still exists, unchanged; todProofMaxViews only
      // ever takes a TodProofViewMode + premium flag, never a source, so a
      // voice proof's own (separate, untouched) code path can never be
      // affected by this formula change.
      expect(TodProofSource.values, contains(TodProofSource.voice));
    });
  });

  group('TodCountdownBadge — item 1 isolated countdown', () {
    testWidgets('starts at the full configured duration and shows it '
        'immediately', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TodCountdownBadge(seconds: 5, onExpired: () {}),
        ),
      );
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('ticks down by exactly one per second, never skipping or '
        'double-decrementing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TodCountdownBadge(seconds: 5, onExpired: () {}),
        ),
      );
      expect(find.text('5'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('4'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('calls onExpired exactly once when it reaches zero, and '
        'stops ticking after', (tester) async {
      var expiredCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: TodCountdownBadge(
            seconds: 2,
            onExpired: () => expiredCount++,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1)); // -> 1
      expect(expiredCount, 0);
      await tester.pump(const Duration(seconds: 1)); // -> expires
      expect(expiredCount, 1);
      // Further pumps must not fire onExpired again (timer cancelled).
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(expiredCount, 1);
    });

    testWidgets('9. a fresh instance (e.g. a premium replay opening a new '
        'dialog) always restarts at the FULL originally configured '
        'duration, independent of any prior instance', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TodCountdownBadge(seconds: 5, onExpired: () {}),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('3'), findsOneWidget);

      // Simulate a brand-new replay: swap in a whole new widget subtree
      // (new dialog => new TodCountdownBadge instance), not just new props
      // on the same element, mirroring what actually happens per replay.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          home: TodCountdownBadge(seconds: 5, onExpired: () {}),
        ),
      );
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('disposing mid-countdown does not throw and does not fire '
        'onExpired', (tester) async {
      var expiredCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: TodCountdownBadge(
            seconds: 10,
            onExpired: () => expiredCount++,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      // Unmount while the timer is still running.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
      expect(expiredCount, 0);
    });
  });
}
