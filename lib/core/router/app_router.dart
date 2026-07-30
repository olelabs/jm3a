import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jma3a/features/games/presentation/meme_game_screen.dart';
import 'package:jma3a/features/games/presentation/nhie_game_screen.dart';
import 'package:jma3a/features/packs/domain/pack_entity.dart';
import 'package:jma3a/features/rooms/presentation/room_provider.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'route_names.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/email_screen.dart';
import '../../features/auth/presentation/screens/phone_screen.dart'; // ✅ new
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/rooms/presentation/screens/room_browser_screen.dart';
import '../../features/rooms/presentation/screens/lobby_screen.dart';
import '../../features/packs/presentation/screens/marketplace_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/change_username_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/offline/presentation/screens/offline_game_screen.dart';
import '../../features/games/engine/base_game_engine.dart';
import '../../features/games/truth_or_dare/presentation/screens/tod_game_screen.dart';
import '../../features/packs/presentation/screens/pack_detail_screen.dart';
import '../../features/wallet/presentation/screens/wallet_home_screen.dart';
import '../../features/friends/presentation/screens/friends_screen.dart';
import '../../features/friends/presentation/screens/user_profile_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/packs/presentation/screens/creator_dashboard_screen.dart';
import '../../features/packs/presentation/screens/create_pack_screen.dart';
import '../../features/premium/presentation/premium_screen.dart'; // ✅ restored
import '../../features/premium/presentation/theme_picker_screen.dart'; // ✅ restored
import '../../features/premium/presentation/background_color_screen.dart';
import '../../features/premium/presentation/premium_avatar_service.dart'; // likely needed for avatar picker
import '../../features/avatar/presentation/avatar_creator_screen.dart'; // ✅ restored
import '../../shared/screens/home_shell_screen.dart';
import '../../shared/screens/not_found_screen.dart';

class AppRouter {
  AppRouter._();

  static final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

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
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        final loc = state.uri.toString();

        // Allow access to room sub‑routes when logged in (not guest)
        if (loc.contains('/room/') && auth.isLoggedIn && !auth.isGuest) {
          return null;
        }

        // Public routes (no auth required)
        final alwaysPublic = [
          RouteNames.splash,
          RouteNames.authEmail,
          RouteNames.authPhone, // ✅ added phone route
          RouteNames.authOtp,
        ];
        final isPublic = alwaysPublic.any((r) => loc.startsWith(r));

        // App routes that require a full (non‑guest) login
        final appRoutes = [
          RouteNames.home,
          RouteNames.settings,
          RouteNames.wallet,
          RouteNames.notifications,
          RouteNames.offline,
          '/profile',
          '/user/',
          '/marketplace',
          '/creator',
          RouteNames.premium, // ✅ added premium
          RouteNames.themePicker, // ✅ added theme picker
          RouteNames.backgroundColor,
          RouteNames.avatarPicker, // ✅ added avatar picker
          RouteNames.avatarCreator, // ✅ added avatar creator
        ];
        if (auth.isLoggedIn &&
            !auth.isGuest &&
            appRoutes.any((r) => loc.startsWith(r))) {
          return null;
        }

        // Still initializing → stay on splash
        if (auth.isInitializing) {
          return loc == RouteNames.splash ? null : RouteNames.splash;
        }

        // Splash screen logic
        if (loc == RouteNames.splash) {
          if (auth.isGuest) return RouteNames.offline;
          if (!auth.isLoggedIn)
            return RouteNames.authPhone; // ✅ now phone first
          if (auth.needsOnboarding) return RouteNames.onboarding;
          return RouteNames.home;
        }

        // Guest users can only access offline mode
        if (auth.isGuest) {
          return loc.startsWith(RouteNames.offline) ? null : RouteNames.offline;
        }

        // Not logged in → redirect to phone login (or email, based on your flow)
        if (!auth.isLoggedIn && !isPublic) {
          return RouteNames.authPhone;
        }

        // Logged in but needs onboarding → force onboarding
        if (auth.isLoggedIn &&
            auth.needsOnboarding &&
            (isPublic || loc == RouteNames.home) &&
            loc != RouteNames.onboarding) {
          return RouteNames.onboarding;
        }

        // Logged in, no onboarding needed, but still on a public route → go home
        if (auth.isLoggedIn &&
            !auth.needsOnboarding &&
            isPublic &&
            loc != RouteNames.splash) {
          return RouteNames.home;
        }

        return null;
      },
      routes: [
        // ---------- Auth ----------
        GoRoute(
          path: RouteNames.splash,
          builder: (_, __) => const SplashScreen(),
        ),
        GoRoute(
          path: RouteNames.authPhone, // ✅ new phone screen
          builder: (_, __) => const PhoneScreen(),
        ),
        GoRoute(
          path: RouteNames.authEmail, // kept for fallback
          builder: (_, __) => const EmailScreen(),
        ),
        GoRoute(
          path: RouteNames.authOtp,
          builder: (_, state) {
            final args = state.extra as OtpScreenArgs?;
            return OtpScreen(
              identifier: args?.identifier ?? '',
              phoneNumber: args?.phoneNumber,
            );
          },
        ),
        GoRoute(
          path: RouteNames.onboarding,
          builder: (_, __) => const OnboardingScreen(),
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

                return switch (gameType) {
                  'never_have_i_ever' => NhieGameScreen(
                    roomId: roomId,
                    config: config,
                    playerIds: playerIds,
                    playerDisplayNames: displayNames,
                    packId: packId,
                    packCoverUrl: packCoverUrl.isNotEmpty ? packCoverUrl : null,
                    isOwner: isOwner,
                    isModerator: isModerator,
                    isSpectator: isSpectator,
                    roomProvider: roomProvider,
                  ),
                  'meme_game' => MemeGameScreen(
                    roomId: roomId,
                    config: config,
                    playerIds: playerIds,
                    playerDisplayNames: displayNames,
                    packId: packId,
                    packCoverUrl: packCoverUrl.isNotEmpty ? packCoverUrl : null,
                    isOwner: isOwner,
                    isModerator: isModerator,
                    isSpectator: isSpectator,
                    roomProvider: roomProvider,
                  ),
                  _ => TodGameScreen(
                    roomId: roomId,
                    config: config,
                    playerIds: playerIds,
                    playerDisplayNames: displayNames,
                    packId: packId,
                    packCoverUrl: packCoverUrl.isNotEmpty ? packCoverUrl : null,
                    isOwner: isOwner,
                    isModerator: isModerator,
                    isSpectator: isSpectator,
                    sessionId: extra['sessionId'] as String?,
                    roomProvider: roomProvider,
                  ),
                };
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
          builder: (_, state) =>
              BackgroundColorScreen(initialColor: state.extra as Color),
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
      ],

      errorBuilder: (_, state) => NotFoundScreen(error: state.error),
    );
    if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    return _instance!;
  }
}
