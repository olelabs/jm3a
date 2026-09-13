// Regression coverage for item 4 (this pass, two sub-fixes):
//
// 1. defaultFollowStatuses — FollowersScreen's own-profile followers list
//    must never be discarded just because the secondary "are you already
//    following them back" bulk lookup (getFollowStatuses) failed. See
//    followers_screen.dart's own doc comment on this function.
// 2. ProfileStats.copyWith(followersCount:) — the followers count shown
//    on the own-profile stats tile must be overridable to the SAME source
//    of truth FollowersScreen's list uses (FriendsRepository.
//    getFollowersCount), not left stuck on the separate
//    profiles_public.followers_count value. See ProfileProvider.
//    _applyStats for where this is actually wired in (untestable
//    directly — it calls the live FriendsRepository singleton, which
//    requires Supabase); this covers the pure data-class piece that makes
//    that override possible.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/friends/data/friends_repository.dart';
import 'package:jma3a/features/friends/presentation/screens/followers_screen.dart';
import 'package:jma3a/features/profile/data/profile_repository.dart';

FollowEntity _follower(String id) => FollowEntity(
  userId: id,
  displayName: 'User $id',
  followedAt: DateTime(2026),
);

void main() {
  group('defaultFollowStatuses — item 4 (this pass): a getFollowStatuses '
      'failure must not discard an already-fetched followers list', () {
    test('produces a false entry for every follower, keyed by userId', () {
      final followers = [_follower('a'), _follower('b'), _follower('c')];
      expect(defaultFollowStatuses(followers), {
        'a': false,
        'b': false,
        'c': false,
      });
    });

    test('an empty followers list produces an empty map, not an error', () {
      expect(defaultFollowStatuses(const []), <String, bool>{});
    });

    test('never marks anyone as already-followed-back — this is a '
        'degraded fallback, not a fabricated positive relationship', () {
      final statuses = defaultFollowStatuses([_follower('x')]);
      expect(statuses.values.every((v) => v == false), isTrue);
    });
  });

  group('ProfileStats.copyWith — followersCount override', () {
    test(
      'overrides followersCount while leaving every other field untouched',
      () {
        const original = ProfileStats(
          friendsCount: 5,
          gamesPlayed: 10,
          packsCount: 2,
          followersCount: 999, // stale/wrong value from profiles_public
          followingCount: 3,
          generalScore: 1200,
          currentStreak: 4,
          longestStreak: 8,
          honestyPoints: 50,
        );

        final updated = original.copyWith(followersCount: 7);

        expect(updated.followersCount, 7);
        expect(updated.friendsCount, 5);
        expect(updated.gamesPlayed, 10);
        expect(updated.packsCount, 2);
        expect(updated.followingCount, 3);
        expect(updated.generalScore, 1200);
        expect(updated.currentStreak, 4);
        expect(updated.longestStreak, 8);
        expect(updated.honestyPoints, 50);
      },
    );

    test('followersCount stays unchanged when not passed to copyWith', () {
      const original = ProfileStats(followersCount: 42);
      final updated = original.copyWith(generalScore: 100);
      expect(updated.followersCount, 42);
    });

    test('generalScore/honestyPoints overrides still work alongside the '
        'new followersCount param (no regression to the existing usage)', () {
      const original = ProfileStats(
        generalScore: 10,
        honestyPoints: 5,
        followersCount: 1,
      );
      final updated = original.copyWith(generalScore: 20, honestyPoints: 15);
      expect(updated.generalScore, 20);
      expect(updated.honestyPoints, 15);
      expect(updated.followersCount, 1);
    });
  });
}
