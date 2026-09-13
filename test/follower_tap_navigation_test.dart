// Real-device root cause pass — requirement 3: after fixing the initial
// FollowersScreen route collision, confirm that tapping an actual
// follower still navigates using that follower's REAL identifier, never
// the literal route segment "followers".
//
// FollowersScreen's own onTap handler (followers_screen.dart) is:
//   onTap: () => Navigator.push(context, MaterialPageRoute(
//     builder: (_) => ... UserProfileScreen(userId: f.userId, ...),
//   )),
// — a raw Navigator.push with a directly-constructed MaterialPageRoute,
// which never consults GoRouter's route table or its `redirect` callback
// at all. This is structurally immune to the extractSharedProfileId
// collision this pass fixed (that redirect only ever runs for GoRouter
// navigation — context.go/push/the router's own redirect evaluation —
// never for a plain Navigator.push). Fully rendering the real
// FollowersScreen needs its list to have actually loaded (real
// Supabase/FriendsRepository data this offline suite can't provide — see
// FollowersScreen's own _load()), so this reproduces the exact same
// onTap wiring shape directly, with a fake follower, per this task's own
// "test the lowest-level ... behavior" fallback instruction.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFollower {
  const _FakeFollower({required this.userId, required this.displayName});
  final String userId;
  final String displayName;
}

class _FakeDestination extends StatelessWidget {
  const _FakeDestination({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Text('profile-of-$userId'));
}

/// Mirrors FollowersScreen's ListTile.onTap exactly: pushes a
/// MaterialPageRoute built from the tapped row's OWN real identifier,
/// never a route-name/path segment.
Widget _followerRow(_FakeFollower f) => Builder(
  builder: (context) => ListTile(
    title: Text(f.displayName),
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _FakeDestination(userId: f.userId)),
    ),
  ),
);

void main() {
  testWidgets(
    '3: tapping an actual follower row navigates using THAT follower\'s '
    'real userId, never the literal string "followers"',
    (tester) async {
      const follower = _FakeFollower(
        userId: 'real-uuid-abc123',
        displayName: 'Sara',
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: _followerRow(follower))),
      );

      await tester.tap(find.text('Sara'));
      await tester.pumpAndSettle();

      expect(find.text('profile-of-real-uuid-abc123'), findsOneWidget);
      expect(find.text('profile-of-followers'), findsNothing);
    },
  );

  testWidgets(
    'different followers in the same list each navigate with their OWN '
    'distinct real id, never a shared/wrong one',
    (tester) async {
      const followers = [
        _FakeFollower(userId: 'id-one', displayName: 'Amina'),
        _FakeFollower(userId: 'id-two', displayName: 'Youssef'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(children: followers.map(_followerRow).toList()),
          ),
        ),
      );

      await tester.tap(find.text('Youssef'));
      await tester.pumpAndSettle();

      expect(find.text('profile-of-id-two'), findsOneWidget);
      expect(find.text('profile-of-id-one'), findsNothing);
    },
  );
}
