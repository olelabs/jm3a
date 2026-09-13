// Regression coverage for item 9 — "Own Profile -> Followers -> tap a
// follower -> 'Profile not found'".
//
// Root cause traced end-to-end through FollowersScreen -> UserProfileScreen
// -> FriendsProvider.getSocialProfile -> FriendsRepository.getSocialProfile:
// no client-side identifier mismatch was found (FollowEntity.userId ->
// profiles.id -> UserProfileScreen(userId:) -> getSocialProfile(targetUserId:)
// is consistent at every step). getSocialProfile queries profiles_public
// first, falling back to the base `profiles` table only when that view has
// nothing for the id — a fallback subject to the same row-level security a
// normal client has on `profiles` for a non-self target. If profiles_public
// genuinely excludes a given row, that fallback can legitimately return
// nothing or be denied, and "Profile not found" was the only outcome —
// even for a real, visible follower.
//
// This file cannot reproduce that server-side exclusion (no live database
// access), but it CAN fully verify the fix's actual mechanism: when the
// profile lookup fails, UserProfileScreen falls back to the same
// publicly-visible identity already shown in the list row that led there
// (Followers/Friends/Explore), via these two pure, extracted functions —
// rather than the caller having to reconstruct a live BuildContext/
// FriendsProvider (which would need Supabase initialized) just to prove
// this decision logic is correct.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/friends/presentation/screens/user_profile_screen.dart';

void main() {
  group('hasKnownIdentity', () {
    test('true when a known display name is present', () {
      expect(hasKnownIdentity(knownDisplayName: 'Sara'), isTrue);
    });

    test('true when only a known username is present', () {
      expect(hasKnownIdentity(knownUsername: 'sara_99'), isTrue);
    });

    test('false when both are null', () {
      expect(hasKnownIdentity(), isFalse);
    });

    test('false when both are empty strings, not just null', () {
      expect(
        hasKnownIdentity(knownDisplayName: '', knownUsername: ''),
        isFalse,
      );
    });
  });

  group('buildKnownIdentityFallbackProfile', () {
    test(
      'carries the known display name, username, avatar and premium flag through',
      () {
        final profile = buildKnownIdentityFallbackProfile(
          userId: 'u1',
          knownDisplayName: 'Sara',
          knownUsername: 'sara_99',
          knownAvatarUrl: 'https://example.com/a.png',
          knownAvatarConfig: {'style': 'x'},
          knownIsPremium: true,
        );
        expect(profile.userId, 'u1');
        expect(profile.displayName, 'Sara');
        expect(profile.username, 'sara_99');
        expect(profile.avatarUrl, 'https://example.com/a.png');
        expect(profile.avatarConfig, {'style': 'x'});
        expect(profile.isPremium, isTrue);
      },
    );

    test('falls back to the username when display name is missing', () {
      final profile = buildKnownIdentityFallbackProfile(
        userId: 'u1',
        knownUsername: 'sara_99',
      );
      expect(profile.displayName, 'sara_99');
    });

    test('falls back to the raw userId when neither name nor username is known '
        '(never leaves displayName empty)', () {
      final profile = buildKnownIdentityFallbackProfile(userId: 'u1');
      expect(profile.displayName, 'u1');
    });

    test('stats default to zero and the profile is never official/blocked — '
        'this is a degraded, not a fabricated-full, profile', () {
      final profile = buildKnownIdentityFallbackProfile(
        userId: 'u1',
        knownDisplayName: 'Sara',
      );
      expect(profile.followersCount, 0);
      expect(profile.followingCount, 0);
      expect(profile.friendsCount, 0);
      expect(profile.gamesPlayed, 0);
      expect(profile.packsCount, 0);
      expect(profile.generalScore, 0);
      expect(profile.honestyPoints, 0);
      expect(profile.isOfficial, isFalse);
      expect(profile.isBlocked, isFalse);
      expect(profile.isBlockedBy, isFalse);
      expect(profile.canInteract, isTrue);
    });
  });
}
