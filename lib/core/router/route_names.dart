// // // // /// All route path constants in one place.
// // // // /// Use named routes for navigation: context.goNamed(RouteNames.home).
// // // // /// Never hardcode path strings in feature code.
// // // // abstract final class RouteNames {
// // // //   // ── Auth ────────────────────────────────────────────────────────────
// // // //   static const splash = '/';
// // // //   static const authEmail = '/auth/email';
// // // //   static const authOtp = '/auth/otp';
// // // //   static const onboarding = '/auth/onboarding';

// // // //   // ── Home shell tabs ──────────────────────────────────────────────────
// // // //   static const home = '/home';
// // // //   static const friends = '/friends';
// // // //   static const marketplace = '/marketplace';
// // // //   static const profile = '/profile';

// // // //   // ── Nested routes ─────────────────────────────────────────────────────
// // // //   static const room = 'room'; // /home/room/:roomId
// // // //   static const packDetail = 'pack'; // /marketplace/pack/:packId
// // // //   static const userProfile = 'user'; // /profile/:userId

// // // //   // ── Full-screen ────────────────────────────────────────────────────────
// // // //   static const wallet = '/wallet';
// // // //   static const notifications = '/notifications';
// // // //   static const settings = '/settings';
// // // //   static const offline = '/offline';
// // // // }

// // // abstract final class RouteNames {
// // //   static const splash = '/';
// // //   static const authEmail = '/auth/email';
// // //   static const authOtp = '/auth/otp';
// // //   static const onboarding = '/auth/onboarding';

// // //   static const home = '/home';
// // //   static const friends = '/friends';
// // //   static const marketplace = '/marketplace';
// // //   static const profile = '/profile';

// // //   static const room = 'room';
// // //   static const packDetail = 'pack';
// // //   static const userProfile = 'user';

// // //   static const wallet = '/wallet';
// // //   static const notifications = '/notifications';
// // //   static const settings = '/settings';
// // //   static const offline = '/offline';
// // //   static const premium = '/premium';
// // // }

// // abstract final class RouteNames {
// //   static const splash = '/';
// //   static const authEmail = '/auth/email';
// //   static const authOtp = '/auth/otp';
// //   static const onboarding = '/auth/onboarding';

// //   static const home = '/home';
// //   static const friends = '/friends';
// //   static const marketplace = '/marketplace';
// //   static const profile = '/profile';

// //   static const room = 'room';
// //   static const packDetail = 'pack';
// //   static const userProfile = 'user';

// //   static const wallet = '/wallet';
// //   static const notifications = '/notifications';
// //   static const settings = '/settings';
// //   static const offline = '/offline';
// //   static const premium = '/premium';
// //   static const themePicker = '/theme-picker';
// //   static const avatarPicker = '/avatar-picker';
// // }

// abstract final class RouteNames {
//   static const splash = '/';
//   static const authEmail = '/auth/email';
//   static const authOtp = '/auth/otp';
//   static const onboarding = '/auth/onboarding';

//   static const home = '/home';
//   static const friends = '/friends';
//   static const marketplace = '/marketplace';
//   static const profile = '/profile';

//   static const room = 'room';
//   static const packDetail = 'pack';
//   static const userProfile = 'user';

//   static const wallet = '/wallet';
//   static const notifications = '/notifications';
//   static const settings = '/settings';
//   static const offline = '/offline';
//   static const premium = '/premium';
//   static const themePicker = '/theme-picker';
//   static const avatarPicker = '/avatar-picker';
//   static const avatarCreator = '/avatar-creator';
// }

abstract final class RouteNames {
  static const splash = '/';
  static const intro = '/intro';
  static const signup = '/auth/signup';
  static const authOtp = '/auth/otp';
  static const onboarding = '/auth/onboarding';
  static const setPassword = '/auth/set-password';
  static const authPasswordLogin = '/auth/login';
  static const forgotPassword = '/auth/forgot-password';
  static const passwordSettings = '/settings/password';
  static const home = '/home';
  static const friends = '/friends';
  static const marketplace = '/marketplace';
  static const profile = '/profile';
  static const room = 'room';
  static const packDetail = 'pack';
  static const userProfile = 'user';
  static const publicProfile = 'publicProfile';
  static const wallet = '/wallet';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const offline = '/offline';
  static const premium = '/premium';
  static const themePicker = '/theme-picker';
  static const backgroundColor = '/theme-picker/background-color';
  static const gameCardColor = '/theme-picker/game-card-color';
  static const avatarPicker = '/avatar-picker';
  static const avatarCreator = '/avatar-creator';
  static const creatorVerification = '/creator-verification';
  static const creatorRecoveryComplaint = '/creator-recovery-complaint';
  static const join = '/join';
  // Item 7 (QR codes) — a real, GoRouter-registered route for the
  // camera scanner (see qr_scan_screen.dart), reached via context.push()
  // like every other drill-down screen. Previously pushed as a raw
  // Navigator.push(MaterialPageRoute(...)) entirely outside GoRouter's
  // own declarative page list — two independent navigation systems
  // manipulating the same root Navigator, which is exactly the kind of
  // desync that can leave a "popped" screen's state (and its still-live
  // camera) resurrected on the next GoRouter-driven rebuild. Registering
  // it here means the scanner's own pop/replace and every other route
  // change all go through the ONE system that actually owns the stack.
  static const scanQr = '/scan-qr';
  static const followers = '/profile/followers';
  static const aboutUs = '/settings/about';
  static const privacyPolicy = '/settings/privacy';
  static const termsConditions = '/settings/terms';
  static const officialResponses = '/settings/official-responses';
}
