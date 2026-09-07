// Critical product invariant: an authenticated account whose profile
// onboarding isn't complete must NEVER reach Home or any other
// authenticated destination — not even transiently. This is the single
// most important thing this function guarantees, tested directly and
// exhaustively here without needing a full GoRouter/widget harness.
//
// Deliberately no has_password/needsPasswordSetup coverage here: this
// function has no password-related branch at all. Existing accounts
// authenticate via OTP regardless of has_password; only signup collects
// a password, atomically, inside its own self-contained flow — never via
// this global redirect.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/router/auth_redirect.dart';
import 'package:jma3a/core/router/route_names.dart';

void main() {
  group('computeAccountStateRedirect — not logged in', () {
    test('a public route is allowed', () {
      expect(
        computeAccountStateRedirect(
          isLoggedIn: false,
          needsOnboarding: false,
          loc: RouteNames.authPasswordLogin,
          isPublicRoute: true,
          isAppRoute: false,
        ),
        isNull,
      );
    });

    test('a non-public route is redirected to login', () {
      expect(
        computeAccountStateRedirect(
          isLoggedIn: false,
          needsOnboarding: false,
          loc: RouteNames.home,
          isPublicRoute: false,
          isAppRoute: true,
        ),
        RouteNames.authPasswordLogin,
      );
    });
  });

  group('computeAccountStateRedirect — THE HARD GATE', () {
    test(
      'needsOnboarding=true is forced even when the location is already an app route (e.g. Home)',
      () {
        expect(
          computeAccountStateRedirect(
            isLoggedIn: true,
            needsOnboarding: true,
            loc: RouteNames.home,
            isPublicRoute: false,
            isAppRoute: true,
          ),
          RouteNames.onboarding,
        );
      },
    );

    test('already on onboarding: no redirect loop', () {
      expect(
        computeAccountStateRedirect(
          isLoggedIn: true,
          needsOnboarding: true,
          loc: RouteNames.onboarding,
          isPublicRoute: false,
          isAppRoute: false,
        ),
        isNull,
      );
    });

    test(
      'authOtp is EXCLUDED even while needsOnboarding — signup and password '
      'recovery both explicitly navigate onward themselves the instant '
      'verifyOtp succeeds; letting this gate fire here too would preempt '
      'that with a premature bounce to onboarding',
      () {
        expect(
          computeAccountStateRedirect(
            isLoggedIn: true,
            needsOnboarding: true,
            loc: RouteNames.authOtp,
            isPublicRoute: true,
            isAppRoute: false,
          ),
          isNull,
        );
      },
    );

    test(
      'setPassword is EXCLUDED even while needsOnboarding — password '
      'recovery reaching Set Password for an account whose profile also '
      'happens to be incomplete must not be redirected away before it '
      'can finish; SetPasswordScreen itself routes to onboarding right '
      'after a successful submit',
      () {
        expect(
          computeAccountStateRedirect(
            isLoggedIn: true,
            needsOnboarding: true,
            loc: RouteNames.setPassword,
            isPublicRoute: false,
            isAppRoute: false,
          ),
          isNull,
        );
      },
    );
  });

  group('computeAccountStateRedirect — fully ready account', () {
    test('existing account with complete profile: Home is allowed', () {
      expect(
        computeAccountStateRedirect(
          isLoggedIn: true,
          needsOnboarding: false,
          loc: RouteNames.home,
          isPublicRoute: false,
          isAppRoute: true,
        ),
        isNull,
      );
    });

    test('stale login screen after becoming fully ready -> bounced home', () {
      expect(
        computeAccountStateRedirect(
          isLoggedIn: true,
          needsOnboarding: false,
          loc: RouteNames.authPasswordLogin,
          isPublicRoute: true,
          isAppRoute: false,
        ),
        RouteNames.home,
      );
    });

    test(
      'authOtp is EXCLUDED from the stale-public-route cleanup — '
      'Settings Update/Reset Password legitimately revisits this screen while fully ready',
      () {
        expect(
          computeAccountStateRedirect(
            isLoggedIn: true,
            needsOnboarding: false,
            loc: RouteNames.authOtp,
            isPublicRoute: true,
            isAppRoute: false,
          ),
          isNull,
        );
      },
    );

    // Regression: OnboardingScreen's own Continue handler calls
    // AuthProvider.updateCurrentUser() with the now-complete profile,
    // which flips needsOnboarding to false and triggers this function to
    // re-run — while `loc` is still literally RouteNames.onboarding
    // (nothing has navigated away yet; the whole point is that the
    // ROUTER is supposed to do that). RouteNames.onboarding is neither
    // an app route nor (correctly) a public route — an unauthenticated
    // user must never see it — so without this explicit case, every
    // rule above and below it falls through to `return null`,
    // permanently stranding the user on their own stale onboarding
    // screen: it looked like "the app doesn't navigate to Home after
    // completing profile setup", and only a full app restart appeared to
    // fix it (cold start re-derives the destination from splash's own
    // separate logic, which never consults this function's stale-locking
    // gap at all).
    test(
      'onboarding just completed while STILL physically on /auth/onboarding -> Home, not stuck',
      () {
        expect(
          computeAccountStateRedirect(
            isLoggedIn: true,
            needsOnboarding: false,
            loc: RouteNames.onboarding,
            isPublicRoute: false,
            isAppRoute: false,
          ),
          RouteNames.home,
        );
      },
    );
  });
}
