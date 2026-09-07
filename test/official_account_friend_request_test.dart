// Jma3a Official (profiles.is_official_account) must never be offered as
// a friend-request target/source, while remaining followable. The real
// authority is the "friendships: requester insert" RLS policy (see
// 20260901090700_block_official_account_friend_requests.sql, verified live
// via a rolled-back dry run: normal->official rejected, official->normal
// rejected, normal->normal unaffected, official excluded from
// explore_people()). This covers the one pure, extractable piece of
// UI-level logic: canShowFriendRequestAction, the guard in front of
// _FriendshipAction on UserProfileScreen.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/friends/data/friends_repository.dart';
import 'package:jma3a/features/friends/presentation/screens/user_profile_screen.dart';

SocialProfile _profile({bool isOfficial = false, bool isBlocked = false, bool isBlockedBy = false}) {
  return SocialProfile(
    userId: 'u1',
    displayName: 'Someone',
    followersCount: 0,
    followingCount: 0,
    friendsCount: 0,
    isOfficial: isOfficial,
    isBlocked: isBlocked,
    isBlockedBy: isBlockedBy,
  );
}

void main() {
  group('canShowFriendRequestAction', () {
    test('hidden for the official account even though nothing else blocks interaction', () {
      expect(canShowFriendRequestAction(_profile(isOfficial: true)), isFalse);
    });

    test('shown for a normal, interactable user', () {
      expect(canShowFriendRequestAction(_profile()), isTrue);
    });

    test('still hidden for a normal user who is blocked (existing canInteract rule unaffected)', () {
      expect(canShowFriendRequestAction(_profile(isBlocked: true)), isFalse);
      expect(canShowFriendRequestAction(_profile(isBlockedBy: true)), isFalse);
    });

    test('official + blocked is still hidden (both reasons independently hide it)', () {
      expect(canShowFriendRequestAction(_profile(isOfficial: true, isBlocked: true)), isFalse);
    });
  });
}
