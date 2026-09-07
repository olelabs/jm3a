import 'route_names.dart';

/// The core account-state gate used by [AppRouter]'s redirect callback,
/// extracted as a pure function so the single most important invariant
/// in the app is directly unit-testable without a full GoRouter/widget
/// harness: **an authenticated account that still needs onboarding must
/// never reach Home (or any other authenticated destination) — not even
/// transiently.**
///
/// Deliberately excludes: first-launch intro, deep-link stash/resume,
/// guest mode, and app initialization — [AppRouter] handles those
/// directly, before ever consulting this function, and only calls this
/// once `isInitializing` is false and `isGuest` is false.
///
/// There is deliberately no password-related gate here. Existing users
/// authenticate via OTP regardless of `has_password`; only a brand-new
/// signup collects a password, and it does so as part of its own
/// self-contained flow (identifier -> password -> OTP, applied
/// atomically — see AuthProvider.verifyOtp), never via a global
/// redirect. `has_password` plays no role in routing.
String? computeAccountStateRedirect({
  required bool isLoggedIn,
  required bool needsOnboarding,
  required String loc,
  required bool isPublicRoute,
  required bool isAppRoute,
}) {
  if (!isLoggedIn) {
    return isPublicRoute ? null : RouteNames.authPasswordLogin;
  }

  // ── THE HARD GATE ────────────────────────────────────────────────────
  // Unconditional on `loc` for every real app destination — an
  // incomplete profile is sent to onboarding, full stop. Two narrow
  // exceptions, both mid-flow screens that always explicitly navigate
  // onward themselves the instant they finish (signup's OTP step, and
  // password recovery's OTP + new-password steps): letting this gate
  // fire on THEM instead would preempt that explicit navigation — the
  // router's redirect re-runs synchronously inside verifyOtp's own
  // notifyListeners() call, which flips isLoggedIn/needsOnboarding
  // BEFORE the screen's own subsequent code (the rest of its _submit())
  // ever gets to run, so an unconditional bounce here would fire first
  // and yank the user to onboarding before the screen's explicit
  // navigation ever executes. Nothing else ever reaches these two
  // routes while needsOnboarding could still be true.
  if (needsOnboarding) {
    final selfNavigating = loc == RouteNames.authOtp || loc == RouteNames.setPassword;
    return (loc == RouteNames.onboarding || selfNavigating)
        ? null
        : RouteNames.onboarding;
  }
  // ── End hard gate — from here on the account is guaranteed fully
  // ready: !needsOnboarding. ──────────────────────────────────────────

  if (isAppRoute) return null;

  // Fully ready, but still physically sitting on /auth/onboarding — the
  // profile was just completed (OnboardingScreen's own Continue handler
  // called AuthProvider.updateCurrentUser(), which is exactly what
  // flipped needsOnboarding to false and triggered this re-evaluation),
  // yet nothing has navigated away from this screen yet. Onboarding is
  // neither an app route nor a public route (it requires auth, so it
  // can't be public — an unauthenticated user must never see it — but
  // it also isn't a "real" app destination), so without this explicit
  // rule the hard gate above no longer applies (needsOnboarding is now
  // false) and every other rule below falls through to `return null`,
  // permanently stranding the user on their own now-stale onboarding
  // screen until they force-restart the app (which works only because
  // splash's own separate isLoggedIn/needsOnboarding check re-derives
  // the destination from scratch on cold start, bypassing this function
  // entirely). This is the one-line rule that was missing: the same
  // "stale entry screen -> home" cleanup the public-route rule below
  // already does, extended to the one authenticated-only entry screen
  // that isn't itself a public route.
  if (loc == RouteNames.onboarding) return RouteNames.home;

  // Fully ready, but still sitting on a public entry screen (stale deep
  // link, browser back, resumed from background) → go home. authOtp is
  // deliberately excluded: it's reused by already-authenticated in-app
  // flows (Settings' Update/Reset password), where a fully-ready account
  // legitimately revisits it — those flows navigate themselves
  // explicitly when they finish and must never be preempted here.
  if (isPublicRoute && loc != RouteNames.splash && loc != RouteNames.authOtp) {
    return RouteNames.home;
  }

  return null;
}
