// Regression coverage for making PackDetailScreen's creator row navigable
// (see pack_detail_screen.dart's _CreatorRow). That class is private and
// PackDetailScreen itself needs a live Supabase-backed PackProvider to
// build, which this offline suite can't provide — so, following this
// repo's own established fallback for exactly this situation (see
// follower_tap_navigation_test.dart's own doc comment), this reproduces
// _CreatorRow's own tap-handling shape exactly: an InkWell wrapping the
// creator content, navigating via `context.push('/user/${pack.creatorId}')`
// — the same call added to the real widget, against a router that
// registers the SAME '/user/:userId' path the real app uses.
//
// This is generic (never keys off "is this Jma3a"): the same navigation
// must work identically for a normal creator and an official
// (is_official_account) one — the official Jma3a profile becomes
// reachable simply because its packs' creator_id resolves through this
// same, unmodified path like anyone else's.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakePackCreator {
  const _FakePackCreator({
    required this.creatorId,
    required this.creatorName,
    this.isOfficialCreator = false,
  });
  final String creatorId;
  final String creatorName;
  final bool isOfficialCreator;
}

/// Mirrors _CreatorRow.build exactly: an InkWell around the creator's
/// name/avatar area, pushing '/user/${pack.creatorId}'.
Widget _creatorRow(_FakePackCreator pack) => Builder(
  builder: (context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () => context.push('/user/${pack.creatorId}'),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(pack.creatorName),
        if (pack.isOfficialCreator) const Icon(Icons.verified_rounded),
      ],
    ),
  ),
);

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/pack',
  routes: [
    GoRoute(
      path: '/pack',
      builder: (context, state) => Scaffold(
        body: Column(
          children: [
            _creatorRow(
              const _FakePackCreator(
                creatorId: 'normal-creator-id',
                creatorName: 'Amina',
              ),
            ),
            _creatorRow(
              const _FakePackCreator(
                creatorId: 'official-creator-id',
                creatorName: 'Jma3a',
                isOfficialCreator: true,
              ),
            ),
          ],
        ),
      ),
    ),
    GoRoute(
      path: '/user/:userId',
      builder: (context, state) =>
          Scaffold(body: Text('profile-of-${state.pathParameters['userId']}')),
    ),
  ],
);

void main() {
  testWidgets(
    'tapping a normal creator\'s row navigates to /user/<their real id>',
    (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));

      await tester.tap(find.text('Amina'));
      await tester.pumpAndSettle();

      expect(find.text('profile-of-normal-creator-id'), findsOneWidget);
    },
  );

  testWidgets('tapping the OFFICIAL creator\'s row navigates through the SAME '
      'unmodified /user/:userId route — no special-casing needed for it '
      'to reach the Jma3a profile', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));

    await tester.tap(find.text('Jma3a'));
    await tester.pumpAndSettle();

    expect(find.text('profile-of-official-creator-id'), findsOneWidget);
  });
}
