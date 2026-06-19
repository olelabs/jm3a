/// All route path constants in one place.
/// Use named routes for navigation: context.goNamed(RouteNames.home).
/// Never hardcode path strings in feature code.
abstract final class RouteNames {
  // ── Auth ────────────────────────────────────────────────────────────
  static const splash = '/';
  static const authEmail = '/auth/email';
  static const authOtp = '/auth/otp';
  static const onboarding = '/auth/onboarding';

  // ── Home shell tabs ──────────────────────────────────────────────────
  static const home = '/home';
  static const friends = '/friends';
  static const marketplace = '/marketplace';
  static const profile = '/profile';

  // ── Nested routes ─────────────────────────────────────────────────────
  static const room = 'room'; // /home/room/:roomId
  static const packDetail = 'pack'; // /marketplace/pack/:packId
  static const userProfile = 'user'; // /profile/:userId

  // ── Full-screen ────────────────────────────────────────────────────────
  static const wallet = '/wallet';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const offline = '/offline';
}
