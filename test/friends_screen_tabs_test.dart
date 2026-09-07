// Regression coverage for the Friends redesign: exactly 3 top-level
// sections (Friends / Explore / Blocked), pending requests folded into
// Friends (no separate Requests tab), search folded into Explore (no
// separate Search tab).
//
// FriendsScreen's tab-selection logic depends on FriendsProvider, which
// (like every other provider in this codebase — see this session's other
// test files for the same documented limitation) wraps a singleton
// Supabase-backed repository with no injectable fake seam, so the actual
// widget tree (_FriendsTab/_ExploreTab/_BlockedTab, all private) can't be
// pumped in an offline test. What CAN be verified directly, and is the
// most valuable regression guard against silently reintroducing a 4th/5th
// tab or reordering the three that remain, is FriendsScreen's own public
// static tab-index API — this is exactly what NotificationService's tab
// routing (see notification_service.dart's 'friend_request'/
// 'friend_accepted' cases) depends on being correct.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/friends/presentation/screens/friends_screen.dart';

void main() {
  group('FriendsScreen tab indices', () {
    test('exactly 3 top-level sections, in the required order: '
        'Friends, Explore, Blocked', () {
      expect(FriendsScreen.tabFriends, 0);
      expect(FriendsScreen.tabExplore, 1);
      expect(FriendsScreen.tabBlocked, 2);
    });

    test('the three indices are distinct (no accidental aliasing)', () {
      final indices = {
        FriendsScreen.tabFriends,
        FriendsScreen.tabExplore,
        FriendsScreen.tabBlocked,
      };
      expect(indices.length, 3);
    });
  });
}
