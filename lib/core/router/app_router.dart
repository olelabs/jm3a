import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jma3a/features/games/presentation/meme_game_screen.dart';
import 'package:jma3a/features/games/presentation/nhie_game_screen.dart';
import 'package:jma3a/features/games/presentation/widgets/game_screen_security_gate.dart';
import 'package:jma3a/features/packs/domain/pack_entity.dart';
import 'package:jma3a/features/rooms/presentation/room_provider.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/app_theme_service.dart';
import '../storage/local_storage_service.dart';
import 'route_names.dart';
import 'auth_redirect.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/intro/presentation/screens/intro_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/set_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/settings/presentation/screens/password_settings_screen.dart';
import '../../features/rooms/presentation/screens/room_browser_screen.dart';
import '../../features/rooms/presentation/screens/lobby_screen.dart';
import '../../features/packs/presentation/screens/marketplace_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/change_username_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/notifications/presentation/screens/official_responses_screen.dart';
import '../../features/settings/presentation/screens/about_us_screen.dart';
import '../../features/settings/presentation/screens/privacy_policy_screen.dart';
import '../../features/settings/presentation/screens/terms_conditions_screen.dart';
import '../../features/offline/presentation/screens/offline_game_screen.dart';
import '../../features/games/engine/base_game_engine.dart';
import '../../features/games/truth_or_dare/presentation/screens/tod_game_screen.dart';
import '../../features/packs/presentation/screens/pack_detail_screen.dart';
import '../../features/wallet/presentation/screens/wallet_home_screen.dart';
import '../../features/friends/presentation/screens/friends_screen.dart';
import '../../features/friends/presentation/screens/user_profile_screen.dart';
import '../../features/friends/presentation/screens/username_profile_resolver_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/packs/presentation/screens/creator_dashboard_screen.dart';
import '../../features/packs/presentation/screens/create_pack_screen.dart';
import '../../features/premium/presentation/premium_screen.dart'; // ✅ restored
import '../../features/premium/presentation/theme_picker_screen.dart'; // ✅ restored
import '../../features/premium/presentation/background_color_screen.dart';
import '../../features/premium/presentation/game_card_color_screen.dart';
import '../../features/premium/presentation/premium_avatar_service.dart'; // likely needed for avatar picker
import '../../features/avatar/presentation/avatar_creator_screen.dart'; // ✅ restored
import '../../features/profile/presentation/screens/creator_recovery_complaint_screen.dart';
import '../../features/profile/presentation/screens/creator_verification_screen.dart';
import '../../features/friends/presentation/screens/followers_screen.dart';
import '../../features/rooms/presentation/screens/join_invite_screen.dart';
import '../../features/rooms/presentation/screens/qr_scan_screen.dart';
import '../../shared/screens/home_shell_screen.dart';
import '../../shared/screens/not_found_screen.dart';
import '../../deep_links.dart';

/// Every registered `/profile/<literal-segment>` route in this app —
/// [extractSharedProfileId] must treat all of these as reserved, never as
/// a shared profile id, or the exact real-device bug this set exists to
/// prevent recurs for whichever one is missing (see that function's own
/// doc comment). Add every future static `/profile/*` route here the
/// moment it's registered below.
const Set<String> reservedProfilePaths = {
  '/profile/edit',
  '/profile/change-username',
  RouteNames.followers,
};

/// Real-device root cause (this pass) — `getSocialProfile("followers")`
/// threw `PostgrestException: invalid input syntax for type uuid:
/// "followers"`. Trace: `/profile/<id>` is not itself a real GoRoute
/// (only /profile/edit, /profile/change-username, /profile/followers,
/// and /user/:userId exist) — this redirect rule exists to turn a raw
/// `https://jma3a.com/profile/<id>` App Link into `/user/<id>` before
/// GoRouter tries to match it against any registered route. It used to
/// treat ANY single unreserved segment after `/profile/` as a shared
/// profile id — including the app's OWN internal `/profile/followers`
/// route (RouteNames.followers), which was missing from
/// [reservedProfilePaths]. So navigating to Followers redirected to
/// `/user/followers` -> `UserProfileScreen(userId: 'followers')` ->
/// `getSocialProfile('followers')` -> the UUID column rejected the
/// literal string "followers".
///
/// A pure function (not inlined in the redirect closure) so this exact
/// collision — and its fix — is independently unit-testable without a
/// live GoRouter/AuthProvider stack. Returns the shared profile id this
/// redirect rule would act on, or null if [loc] doesn't match at all
/// (not a `/profile/...` path, has extra segments, or is empty) OR is
/// one of [reservedProfilePaths] (an app-internal route, never a shared
/// profile link).
String? extractSharedProfileId(String loc) {
  if (!loc.startsWith('/profile/')) return null;
  if (reservedProfilePaths.contains(loc)) return null;
  if (!RegExp(r'^/profile/[^/]+$').hasMatch(loc)) return null;
  final id = loc.substring('/profile/'.length);
  return id.isEmpty ? null : id;
}

class AppRouter {
  AppRouter._();

  static final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  /// Lets a screen detect "a pushed route on top of me was popped" (e.g.
  /// Profile -> Edit Profile -> back) via RouteAware.didPopNext(), without
  /// each push site having to remember to await the result and call a
  /// refresh itself. Currently used by ProfileScreen — see requirement
  /// "refresh after returning from other screens".
  static final RouteObserver<PageRoute<dynamic>> routeObserver =
      RouteObserver<PageRoute<dynamic>>();

  static GoRouter? _instance;
  static GoRouter get router {
    assert(
      _instance != null,
      'AppRouter.router accessed before createRouter() was called.',
    );
    return _instance!;
  }

  // Signals when `router` is safe to use — completed once, at the end of
  // createRouter(). Anything that can run before the widget tree exists
  // (e.g. a OneSignal notification-click replayed during app startup,
  // which registers its listener in main() before runApp()) must await
  // this before calling `router.go(...)`/`.push(...)`, or it silently
  // no-ops against a null `_instance` — this was the root cause of
  // notification taps not navigating on iOS cold start.
  static final Completer<void> _readyCompleter = Completer<void>();
  static Future<void> get ready => _readyCompleter.future;
  static bool get isReady => _readyCompleter.isCompleted;

  static GoRouter createRouter(AuthProvider authProvider) {
    _instance = GoRouter(
      navigatorKey: rootKey,
      initialLocation: RouteNames.splash,
      debugLogDiagnostics: true,
      refreshListenable: authProvider,
      observers: [routeObserver],
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        final loc = state.uri.toString();

        // First-launch product tour — takes priority over every other
        // redirect rule below (including auth) so it shows exactly once,
        // regardless of guest/logged-in/logged-out state. Gated by
        // LocalStorageService, which is guaranteed initialized before the
        // router exists (ServiceLocator.initialize() is awaited in
        // main() before runApp()), so this synchronous read is safe here.
        final hasSeenIntro =
            LocalStorageService.instance.getBool(kHasSeenIntroKey) ?? false;
        if (!hasSeenIntro) {
          return loc == RouteNames.intro ? null : RouteNames.intro;
        }
        if (loc == RouteNames.intro) {
          // Intro already completed (e.g. a stale deep link) — bounce to
          // splash so the normal auth-based rules below decide next.
          return RouteNames.splash;
        }

        // Room-invite deep link (https://jma3a.com/join or jma3a://join,
        // both normalized to this route by DeepLinkService) hit while not
        // fully logged in yet — stash it so it isn't lost to the auth
        // redirect a few rules down, then let that redirect run as
        // normal. Must run before the "resume pending invite" rule right
        // below it (a link opened a second time while one is already
        // pending should overwrite it, not be ignored) and before the
        // appRoutes fast-path further down (which would otherwise return
        // null for /join before this ever got a chance to stash anything).
        if (loc.startsWith(RouteNames.join) &&
            !(auth.isLoggedIn && !auth.isGuest)) {
          final code = state.uri.queryParameters['code'];
          if (code != null && code.isNotEmpty) {
            DeepLinkService.instance.pendingInvite = RoomInvitePayload(
              code: code,
              invitedBy: state.uri.queryParameters['invited_by'],
            );
          }
        }

        // Resume a deep link that arrived before login/onboarding
        // completed. Must run before the appRoutes fast-path below (which
        // would otherwise return null for the current location — e.g.
        // Home right after login — before this ever gets a chance to
        // redirect to /join instead) so the user lands on the invite
        // screen right after finishing login rather than on Home.
        final pendingInvite = DeepLinkService.instance.pendingInvite;
        if (pendingInvite != null &&
            auth.isLoggedIn &&
            !auth.isGuest &&
            !auth.needsOnboarding &&
            !auth.isInitializing &&
            !loc.startsWith(RouteNames.join)) {
          DeepLinkService.instance.clearPendingInvite();
          return Uri(
            path: RouteNames.join,
            queryParameters: {
              'code': pendingInvite.code,
              if (pendingInvite.invitedBy != null)
                'invited_by': pendingInvite.invitedBy!,
            },
          ).toString();
        }

        // Profile sharing correction pass — see extractSharedProfileId's
        // own doc comment (top of file) for the full rationale and the
        // real-device "followers" collision it was fixed to exclude.
        // Two outcomes here: already authenticated -> redirect straight
        // to /user/:userId; not yet authenticated -> stash it (same
        // shape as the room-invite rules above) so it survives the auth
        // redirect below and resumes to the real profile route — never
        // the generic home screen — once login finishes.
        final sharedProfileId = extractSharedProfileId(loc);
        if (sharedProfileId != null) {
          if (auth.isLoggedIn &&
              !auth.isGuest &&
              !auth.needsOnboarding &&
              !auth.isInitializing) {
            return '/user/$sharedProfileId';
          }
          DeepLinkService.instance.pendingProfile = ProfileLinkPayload(
            userId: sharedProfileId,
          );
        }

        final pendingProfile = DeepLinkService.instance.pendingProfile;
        if (pendingProfile != null &&
            auth.isLoggedIn &&
            !auth.isGuest &&
            !auth.needsOnboarding &&
            !auth.isInitializing &&
            !loc.startsWith('/user/')) {
          DeepLinkService.instance.clearPendingProfile();
          return '/user/${pendingProfile.userId}';
        }

        // Allow access to room sub‑routes when logged in (not guest) AND
        // the account is fully ready — critical invariant (see brief):
        // an incomplete profile must never reach an authenticated
        // destination via a bypass like this one, so this can't rubber-
        // stamp access ahead of the needsOnboarding check further down.
        if (loc.contains('/room/') &&
            auth.isLoggedIn &&
            !auth.isGuest &&
            !auth.needsOnboarding) {
          return null;
        }

        // Public routes (no auth required). RouteNames.splash ('/') is
        // deliberately checked by EXACT equality, never startsWith — as
        // a prefix, '/' matches every single absolute path in the app,
        // which silently made isPublic true for every location (masking
        // this whole rule for anything not already caught by isAppRoute
        // below — concretely, /auth/set-password: neither an app route
        // nor genuinely public, but the '/' prefix bug made it read as
        // public, so a fully-ready account explicitly sent there by the
        // password-recovery flow got immediately bounced to Home by the
        // "stale public route" cleanup two branches down instead of
        // ever reaching the new-password step).
        final alwaysPublic = [
          RouteNames.signup,
          RouteNames.authOtp,
          RouteNames.authPasswordLogin,
          RouteNames.forgotPassword,
        ];
        final isPublic =
            loc == RouteNames.splash ||
            alwaysPublic.any((r) => loc.startsWith(r));

        // App routes that require a full (non‑guest) login
        final appRoutes = [
          RouteNames.home,
          RouteNames.settings,
          RouteNames.wallet,
          RouteNames.notifications,
          RouteNames.offline,
          ...reservedProfilePaths,
          '/user/',
          '/marketplace',
          '/creator',
          RouteNames.premium, // ✅ added premium
          RouteNames.themePicker, // ✅ added theme picker
          RouteNames.backgroundColor,
          RouteNames.gameCardColor,
          RouteNames.avatarPicker, // ✅ added avatar picker
          RouteNames.avatarCreator, // ✅ added avatar creator
          RouteNames.join,
        ];
        // Critical invariant (see brief): this fast-path must NEVER
        // rubber-stamp access to Home or any other authenticated
        // destination for an account that still needs onboarding — that
        // check runs unconditionally below regardless of what loc
        // already is, but this early return would otherwise skip it
        // entirely for anyone who already happens to be sitting on (or
        // gets navigated to) an app route, e.g. Home, before finishing
        // onboarding. Same reasoning extends to isInitializing: without
        // it, a deep-link push (e.g. DeepLinkService resolving a profile
        // link on cold start) that lands here in the narrow window where
        // isLoggedIn/needsOnboarding already read "ready" but
        // isInitializing hasn't flipped false yet would rubber-stamp
        // straight through — and for a literal, non-registered location
        // like the old bare '/profile' prefix used to admit, that meant
        // GoRouter had nothing left to match and fell through to
        // errorBuilder (NotFoundScreen) instead of the "still
        // initializing -> splash" rule below ever getting a chance to
        // run. Real-device root cause of "native Camera scan -> Screen
        // not found" — see DeepLinkService/_onProfileLink's own doc
        // comment (app.dart) for the other half of this fix.
        if (auth.isLoggedIn &&
            !auth.isGuest &&
            !auth.needsOnboarding &&
            !auth.isInitializing &&
            appRoutes.any((r) => loc.startsWith(r))) {
          return null;
        }

        // Still initializing → stay on splash
        if (auth.isInitializing) {
          return loc == RouteNames.splash ? null : RouteNames.splash;
        }

        // Splash screen logic. No password dimension here at all:
        // existing users authenticate via OTP regardless of
        // has_password, so the only questions are "logged in?" and
        // "onboarding complete?".
        if (loc == RouteNames.splash) {
          if (auth.isGuest) return RouteNames.offline;
          if (!auth.isLoggedIn) return RouteNames.authPasswordLogin;
          if (auth.needsOnboarding) return RouteNames.onboarding;
          return RouteNames.home;
        }

        // Guest users can only access offline mode
        if (auth.isGuest) {
          return loc.startsWith(RouteNames.offline) ? null : RouteNames.offline;
        }

        // The core account-state gate (not-logged-in routing, and the
        // hard "no incomplete account may reach an authenticated
        // destination" invariant) is a pure, independently unit-tested
        // function — see computeAccountStateRedirect's own doc for the
        // full rationale and ordering guarantees.
        return computeAccountStateRedirect(
          isLoggedIn: auth.isLoggedIn,
          needsOnboarding: auth.needsOnboarding,
          loc: loc,
          isPublicRoute: isPublic,
          isAppRoute: appRoutes.any((r) => loc.startsWith(r)),
        );
      },
      routes: [
        // ---------- Auth ----------
        GoRoute(
          path: RouteNames.splash,
          builder: (_, __) => const SplashScreen(),
        ),
        GoRoute(
          path: RouteNames.intro,
          builder: (_, __) => const IntroScreen(),
        ),
        GoRoute(
          path: RouteNames.signup,
          builder: (_, __) => const SignupScreen(),
        ),
        GoRoute(
          path: RouteNames.authOtp,
          builder: (_, state) {
            final args = state.extra as OtpScreenArgs?;
            return OtpScreen(
              identifier: args?.identifier ?? '',
              phoneNumber: args?.phoneNumber,
              isPasswordRecovery: args?.isPasswordRecovery ?? false,
              pendingPassword: args?.pendingPassword,
              returnToSettingsOnSuccess:
                  args?.returnToSettingsOnSuccess ?? false,
            );
          },
        ),
        GoRoute(
          path: RouteNames.onboarding,
          builder: (_, __) => const OnboardingScreen(),
        ),
        GoRoute(
          path: RouteNames.setPassword,
          builder: (_, state) {
            final args = state.extra as SetPasswordScreenArgs?;
            return SetPasswordScreen(
              isRecovery: args?.isRecovery ?? false,
              returnToSettingsOnSuccess:
                  args?.returnToSettingsOnSuccess ?? false,
            );
          },
        ),
        GoRoute(
          path: RouteNames.authPasswordLogin,
          builder: (_, state) =>
              LoginScreen(prefillIdentifier: state.extra as String?),
        ),
        GoRoute(
          path: RouteNames.forgotPassword,
          builder: (_, state) =>
              ForgotPasswordScreen(prefillIdentifier: state.extra as String?),
        ),

        // ---------- Main ----------
        GoRoute(
          path: RouteNames.home,
          builder: (_, __) => const HomeShellScreen(),
        ),

        // ---------- Pack detail ----------
        GoRoute(
          path: '/marketplace/pack/:packId',
          name: RouteNames.packDetail,
          parentNavigatorKey: rootKey,
          builder: (_, state) =>
              PackDetailScreen(packId: state.pathParameters['packId']!),
        ),

        // ---------- Room + Game ----------
        GoRoute(
          path: '/home/room/:roomId',
          name: RouteNames.room,
          parentNavigatorKey: rootKey,
          builder: (_, state) =>
              LobbyScreen(roomId: state.pathParameters['roomId']!),
          routes: [
            GoRoute(
              path: 'game',
              name: 'game',
              parentNavigatorKey: rootKey,
              builder: (_, state) {
                final extra = state.extra as Map<String, dynamic>? ?? {};
                final config =
                    extra['config'] as GameConfig? ??
                    const GameConfig(
                      maxRounds: 10,
                      turnTimerSeconds: 60,
                      allowSkip: true,
                      allowSpicy: false,
                    );
                final roomId = state.pathParameters['roomId']!;
                final playerIds =
                    (extra['playerIds'] as List?)?.cast<String>() ?? [];
                final displayNames =
                    (extra['displayNames'] as Map?)?.cast<String, String>() ??
                    {};
                final packId = extra['packId'] as String? ?? '';
                final packCoverUrl = extra['packCoverUrl'] as String? ?? '';
                final isOwner = extra['isOwner'] as bool? ?? false;
                final isModerator = extra['isModerator'] as bool? ?? false;
                final isSpectator = extra['isSpectator'] as bool? ?? false;
                final gameType =
                    extra['gameType'] as String? ?? 'truth_or_dare';
                // The LobbyScreen that started/joined this game is pushed
                // (not replaced), so its RoomProvider instance stays alive
                // underneath the game route — pass it straight through
                // instead of standing up a second, duplicate membership
                // subscription. May be null (e.g. a stale/backgrounded
                // deep link); screens must handle that gracefully.
                final roomProvider = extra['roomProvider'] as RoomProvider?;

                return GameScreenSecurityGate(
                  child: switch (gameType) {
                    'never_have_i_ever' => NhieGameScreen(
                      roomId: roomId,
                      config: config,
                      playerIds: playerIds,
                      playerDisplayNames: displayNames,
                      packId: packId,
                      packCoverUrl: packCoverUrl.isNotEmpty
                          ? packCoverUrl
                          : null,
                      isOwner: isOwner,
                      isModerator: isModerator,
                      isSpectator: isSpectator,
                      // See TodGameScreen.isNewGameStart's doc comment —
                      // same signal, same reason, now wired to this game too.
                      isNewGameStart: extra['isNewGameStart'] as bool? ?? false,
                      roomProvider: roomProvider,
                    ),
                    'meme_game' => MemeGameScreen(
                      roomId: roomId,
                      config: config,
                      playerIds: playerIds,
                      playerDisplayNames: displayNames,
                      packId: packId,
                      packCoverUrl: packCoverUrl.isNotEmpty
                          ? packCoverUrl
                          : null,
                      isOwner: isOwner,
                      isModerator: isModerator,
                      isSpectator: isSpectator,
                      isNewGameStart: extra['isNewGameStart'] as bool? ?? false,
                      roomProvider: roomProvider,
                    ),
                    _ => TodGameScreen(
                      roomId: roomId,
                      config: config,
                      playerIds: playerIds,
                      playerDisplayNames: displayNames,
                      packId: packId,
                      packCoverUrl: packCoverUrl.isNotEmpty
                          ? packCoverUrl
                          : null,
                      isOwner: isOwner,
                      isModerator: isModerator,
                      isSpectator: isSpectator,
                      sessionId: extra['sessionId'] as String?,
                      // Set only by lobby_screen.dart's _onStartGame (a
                      // genuine, fresh "Start Game" press) — every other
                      // path into this route (reconnect, "Continue Game",
                      // the automatic status-change listener) is entering
                      // an ALREADY-running game and must resume it, never
                      // start over. Without this explicit signal,
                      // TodGameProvider.initAsOwner had no way to tell
                      // "brand new game" apart from "reconnecting after
                      // the last game already ended" — both just found
                      // the most recent session row — so starting a new
                      // game in a room whose last game had finished
                      // incorrectly restored that finished game's state
                      // instead of starting fresh.
                      isNewGameStart: extra['isNewGameStart'] as bool? ?? false,
                      roomProvider: roomProvider,
                    ),
                  },
                );
              },
            ),
          ],
        ),

        // ---------- Profile ----------
        GoRoute(
          path: '/profile/edit',
          parentNavigatorKey: rootKey,
          builder: (_, __) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/user/:userId',
          name: RouteNames.userProfile,
          parentNavigatorKey: rootKey,
          builder: (_, state) =>
              UserProfileScreen(userId: state.pathParameters['userId']!),
        ),
        // Public profile URL (see AppConstants.publicProfileUrl) — the
        // ONLY form a profile is ever shared/opened with externally, and
        // it never carries the internal userId. A genuine registered
        // route (unlike '/profile/<uuid>' above, which only works via the
        // synchronous redirect hack because its path collides with this
        // app's own /profile/edit /profile/change-username routes) so
        // GoRouter's native App Link URI parsing resolves it directly on
        // cold start, with no redirect-callback changes needed.
        GoRoute(
          path: '/u/:username',
          name: RouteNames.publicProfile,
          parentNavigatorKey: rootKey,
          builder: (_, state) => UsernameProfileResolverScreen(
            username: state.pathParameters['username']!,
          ),
        ),
        GoRoute(
          path: '/profile/change-username',
          parentNavigatorKey: rootKey,
          builder: (_, __) => const ChangeUsernameScreen(),
        ),

        // ---------- Wallet & Notifications ----------
        GoRoute(
          path: RouteNames.wallet,
          parentNavigatorKey: rootKey,
          builder: (_, __) => const WalletHomeScreen(),
        ),
        GoRoute(
          path: RouteNames.notifications,
          parentNavigatorKey: rootKey,
          builder: (_, __) => const NotificationsScreen(),
        ),

        // ---------- Creator ----------
        GoRoute(
          path: '/creator',
          parentNavigatorKey: rootKey,
          builder: (_, __) => const CreatorDashboardScreen(),
          routes: [
            GoRoute(
              path: 'create-pack',
              builder: (_, state) {
                final extra = state.extra as Map<String, dynamic>?;
                final packId = extra?['packId'] as String?;
                final pack = extra?['draft'] as PackEntity?;
                return CreatePackScreen(
                  existingPackId: packId,
                  existingPack: pack,
                );
              },
            ),
          ],
        ),

        // ---------- Settings ----------
        GoRoute(
          path: RouteNames.settings,
          parentNavigatorKey: rootKey,
          builder: (_, __) => const SettingsScreen(),
        ),
        GoRoute(
          path: RouteNames.passwordSettings,
          parentNavigatorKey: rootKey,
          builder: (_, __) => const PasswordSettingsScreen(),
        ),
        GoRoute(
          path: RouteNames.aboutUs,
          parentNavigatorKey: rootKey,
          builder: (_, __) => const AboutUsScreen(),
        ),
        GoRoute(
          path: RouteNames.privacyPolicy,
          parentNavigatorKey: rootKey,
          builder: (_, __) => const PrivacyPolicyScreen(),
        ),
        GoRoute(
          path: RouteNames.termsConditions,
          parentNavigatorKey: rootKey,
          builder: (_, __) => const TermsConditionsScreen(),
        ),
        GoRoute(
          path: RouteNames.officialResponses,
          parentNavigatorKey: rootKey,
          builder: (_, __) => const OfficialResponsesScreen(),
        ),

        // ---------- Offline ----------
        GoRoute(
          path: RouteNames.offline,
          parentNavigatorKey: rootKey,
          builder: (_, __) => const OfflineGameScreen(),
        ),

        // ---------- Premium & Avatar ----------
        GoRoute(
          path: RouteNames.premium,
          parentNavigatorKey: rootKey,
          builder: (_, __) => const PremiumScreen(),
        ),
        GoRoute(
          path: RouteNames.themePicker,
          parentNavigatorKey: rootKey,
          builder: (_, __) => const ThemePickerScreen(),
        ),
        GoRoute(
          path: RouteNames.backgroundColor,
          parentNavigatorKey: rootKey,
          // `state.extra` is a plain in-memory Dart object, not part of the
          // URI — GoRouter doesn't guarantee it survives every re-match of
          // this route. AuthProvider (this router's refreshListenable)
          // notifies from ~70 unrelated call sites, including right after
          // this screen's own successful save — any of those can trigger a
          // route re-evaluation with `extra` absent. The old bare
          // `state.extra as Color` force-cast crashed with "type 'Null' is
          // not a subtype of type 'Color'" whenever that happened. Falls
          // back to the same value theme_picker_screen.dart already
          // computes when it pushes this route (the user's persisted
          // color, or the ambient theme's surface), so the picker still
          // opens showing the right color instead of crashing.
          builder: (context, state) {
            final fallback =
                AppThemeService.parseHexColor(
                  context
                      .read<AuthProvider>()
                      .currentUser
                      ?.themeBackgroundColor,
                ) ??
                Theme.of(context).colorScheme.surface;
            return BackgroundColorScreen(
              initialColor: state.extra as Color? ?? fallback,
            );
          },
        ),
        GoRoute(
          path: RouteNames.gameCardColor,
          parentNavigatorKey: rootKey,
          builder: (_, __) => const GameCardColorScreen(),
        ),
        GoRoute(
          path: RouteNames.avatarPicker,
          parentNavigatorKey: rootKey,
          builder: (_, __) => const AvatarPickerScreen(),
        ),
        GoRoute(
          path: RouteNames.avatarCreator,
          parentNavigatorKey: rootKey,
          builder: (_, __) => const AvatarCreatorScreen(),
        ),
        GoRoute(
          path: RouteNames.creatorVerification,
          parentNavigatorKey: rootKey,
          builder: (_, __) => const CreatorVerificationScreen(),
        ),
        GoRoute(
          path: RouteNames.creatorRecoveryComplaint,
          parentNavigatorKey: rootKey,
          builder: (_, __) => const CreatorRecoveryComplaintScreen(),
        ),
        GoRoute(
          path: RouteNames.followers,
          parentNavigatorKey: rootKey,
          builder: (_, __) => const FollowersScreen(),
        ),
        GoRoute(
          path: RouteNames.join,
          parentNavigatorKey: rootKey,
          builder: (_, state) => JoinInviteScreen(
            code: state.uri.queryParameters['code'] ?? '',
            invitedBy: state.uri.queryParameters['invited_by'],
          ),
        ),
        GoRoute(
          path: RouteNames.scanQr,
          parentNavigatorKey: rootKey,
          builder: (_, _) => const QrScanScreen(),
        ),
      ],

      errorBuilder: (_, state) => NotFoundScreen(error: state.error),
    );
    if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    return _instance!;
  }
}
