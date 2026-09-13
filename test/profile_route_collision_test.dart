// Real-device root cause pass — regression coverage for:
//   PostgrestException: invalid input syntax for type uuid: "followers"
//   inside FriendsRepository.getSocialProfile.
//
// Root cause: extractSharedProfileId (app_router.dart) is the redirect
// rule that turns a raw `https://jma3a.com/profile/<id>` App Link into
// `/user/<id>` before GoRouter tries to match any registered route. It
// treated ANY single unreserved segment after `/profile/` as a shared
// profile id — including the app's OWN internal `/profile/followers`
// route (RouteNames.followers), which was missing from
// reservedProfilePaths. So navigating to Followers redirected to
// `/user/followers` -> UserProfileScreen(userId: 'followers') ->
// getSocialProfile('followers') -> the UUID column rejected the literal
// string "followers".
//
// These are the lowest-level, fastest, most direct tests of the actual
// fix — no live GoRouter/AuthProvider/Supabase stack needed. See
// test/real_router_regression_test.dart's own new
// "Router — /profile/followers route collision" group for the
// complementary full-router-level proof (Followers resolves to
// FollowersScreen, a real shared profile link still resolves to
// UserProfileScreen).
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/router/app_router.dart';
import 'package:jma3a/core/router/route_names.dart';

void main() {
  group('extractSharedProfileId — the exact function that produced "followers" '
      'as a shared-profile id', () {
    test('1: /profile/followers (RouteNames.followers) never extracts '
        '"followers" as a shared profile id — the exact real-device bug', () {
      expect(extractSharedProfileId(RouteNames.followers), isNull);
      expect(extractSharedProfileId('/profile/followers'), isNull);
    });

    test('every reserved /profile/* route is excluded', () {
      for (final path in reservedProfilePaths) {
        expect(extractSharedProfileId(path), isNull, reason: path);
      }
    });

    test('a genuine shared profile link (a real, non-reserved id) still '
        'extracts correctly — the fix only excludes reserved routes, it '
        'does not break real profile links', () {
      expect(
        extractSharedProfileId('/profile/a1b2c3d4-real-uuid'),
        'a1b2c3d4-real-uuid',
      );
      expect(
        extractSharedProfileId('/profile/some-other-user-id'),
        'some-other-user-id',
      );
    });

    test('non-/profile/ paths never match', () {
      expect(extractSharedProfileId('/home'), isNull);
      expect(extractSharedProfileId('/user/abc'), isNull);
      expect(extractSharedProfileId('/'), isNull);
    });

    test('a /profile/ path with extra segments never matches (only a '
        'single unreserved segment counts)', () {
      expect(extractSharedProfileId('/profile/abc/def'), isNull);
    });

    test('a bare "/profile/" with no id never matches', () {
      expect(extractSharedProfileId('/profile/'), isNull);
    });
  });

  group('reservedProfilePaths — the collision-prevention set', () {
    test('contains RouteNames.followers', () {
      expect(reservedProfilePaths, contains(RouteNames.followers));
    });

    test('contains every other registered static /profile/* route', () {
      expect(reservedProfilePaths, contains('/profile/edit'));
      expect(reservedProfilePaths, contains('/profile/change-username'));
    });
  });
}
