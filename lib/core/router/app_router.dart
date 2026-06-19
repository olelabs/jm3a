// // // // // // // // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // // // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // // // // // // // // // import '../providers/auth_provider.dart';
// // // // // // // // // // // // // // // // import 'route_names.dart';
// // // // // // // // // // // // // // // // import '../../features/auth/presentation/screens/splash_screen.dart';
// // // // // // // // // // // // // // // // import '../../features/auth/presentation/screens/email_screen.dart';
// // // // // // // // // // // // // // // // import '../../features/auth/presentation/screens/otp_screen.dart';
// // // // // // // // // // // // // // // // import '../../features/auth/presentation/screens/onboarding_screen.dart';
// // // // // // // // // // // // // // // // import '../../features/rooms/presentation/screens/room_browser_screen.dart';
// // // // // // // // // // // // // // // // import '../../features/rooms/presentation/screens/lobby_screen.dart';
// // // // // // // // // // // // // // // // import '../../features/packs/presentation/screens/marketplace_screen.dart';
// // // // // // // // // // // // // // // // import '../../features/profile/presentation/screens/profile_screen.dart';
// // // // // // // // // // // // // // // // import '../../features/profile/presentation/screens/edit_profile_screen.dart';
// // // // // // // // // // // // // // // // import '../../features/profile/presentation/screens/change_username_screen.dart';
// // // // // // // // // // // // // // // // import '../../features/settings/presentation/settings_screen.dart';
// // // // // // // // // // // // // // // // import '../../features/offline/presentation/screens/offline_game_screen.dart';
// // // // // // // // // // // // // // // // import '../../features/games/engine/base_game_engine.dart';
// // // // // // // // // // // // // // // // import '../../features/games/truth_or_dare/presentation/screens/tod_game_screen.dart';
// // // // // // // // // // // // // // // // import '../../features/packs/presentation/screens/pack_detail_screen.dart';
// // // // // // // // // // // // // // // // import '../../features/wallet/presentation/screens/wallet_home_screen.dart';
// // // // // // // // // // // // // // // // import '../../features/friends/presentation/screens/friends_screen.dart';
// // // // // // // // // // // // // // // // import '../../features/friends/presentation/screens/user_profile_screen.dart';
// // // // // // // // // // // // // // // // import '../../features/notifications/presentation/screens/notifications_screen.dart';
// // // // // // // // // // // // // // // // import '../../features/packs/presentation/screens/creator_dashboard_screen.dart';
// // // // // // // // // // // // // // // // import '../../features/packs/presentation/screens/create_pack_screen.dart';
// // // // // // // // // // // // // // // // import '../../shared/screens/home_shell_screen.dart';
// // // // // // // // // // // // // // // // import '../../shared/screens/not_found_screen.dart';

// // // // // // // // // // // // // // // // class AppRouter {
// // // // // // // // // // // // // // // //   AppRouter._();

// // // // // // // // // // // // // // // //   static final _rootKey  = GlobalKey<NavigatorState>(debugLabel: 'root');
// // // // // // // // // // // // // // // //   static final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

// // // // // // // // // // // // // // // //   static final GoRouter router = GoRouter(
// // // // // // // // // // // // // // // //     navigatorKey: _rootKey,
// // // // // // // // // // // // // // // //     initialLocation: RouteNames.splash,
// // // // // // // // // // // // // // // //     debugLogDiagnostics: true,

// // // // // // // // // // // // // // // //     // ── Auth guard ────────────────────────────────────────────────────────
// // // // // // // // // // // // // // // //     redirect: (context, state) {
// // // // // // // // // // // // // // // //       final auth = context.read<AuthProvider>();
// // // // // // // // // // // // // // // //       final loc  = state.uri.toString();

// // // // // // // // // // // // // // // //       final alwaysPublic = [RouteNames.splash, RouteNames.authEmail, RouteNames.authOtp];
// // // // // // // // // // // // // // // //       final isPublic = alwaysPublic.any((r) => loc.startsWith(r));

// // // // // // // // // // // // // // // //       // Still initializing — hold on splash
// // // // // // // // // // // // // // // //       if (auth.isInitializing) {
// // // // // // // // // // // // // // // //         return loc == RouteNames.splash ? null : RouteNames.splash;
// // // // // // // // // // // // // // // //       }

// // // // // // // // // // // // // // // //       // Guest mode: only offline screen allowed
// // // // // // // // // // // // // // // //       if (auth.isGuest) {
// // // // // // // // // // // // // // // //         return loc.startsWith(RouteNames.offline) ? null : RouteNames.offline;
// // // // // // // // // // // // // // // //       }

// // // // // // // // // // // // // // // //       // Not logged in — force to email entry
// // // // // // // // // // // // // // // //       if (!auth.isLoggedIn && !isPublic) {
// // // // // // // // // // // // // // // //         return RouteNames.authEmail;
// // // // // // // // // // // // // // // //       }

// // // // // // // // // // // // // // // //       // Logged in, profile incomplete — force onboarding
// // // // // // // // // // // // // // // //       if (auth.isLoggedIn &&
// // // // // // // // // // // // // // // //           auth.needsOnboarding &&
// // // // // // // // // // // // // // // //           loc != RouteNames.onboarding) {
// // // // // // // // // // // // // // // //         return RouteNames.onboarding;
// // // // // // // // // // // // // // // //       }

// // // // // // // // // // // // // // // //       // Logged in, onboarded, on an auth screen — send home
// // // // // // // // // // // // // // // //       if (auth.isLoggedIn &&
// // // // // // // // // // // // // // // //           !auth.needsOnboarding &&
// // // // // // // // // // // // // // // //           isPublic &&
// // // // // // // // // // // // // // // //           loc != RouteNames.splash) {
// // // // // // // // // // // // // // // //         return RouteNames.home;
// // // // // // // // // // // // // // // //       }

// // // // // // // // // // // // // // // //       return null; // No redirect needed
// // // // // // // // // // // // // // // //     },

// // // // // // // // // // // // // // // //     routes: [
// // // // // // // // // // // // // // // //       // ── Auth ────────────────────────────────────────────────────────────
// // // // // // // // // // // // // // // //       GoRoute(path: RouteNames.splash,     builder: (_, __) => const SplashScreen()),
// // // // // // // // // // // // // // // //       GoRoute(path: RouteNames.authEmail,  builder: (_, __) => const EmailScreen()),
// // // // // // // // // // // // // // // //       GoRoute(
// // // // // // // // // // // // // // // //         path: RouteNames.authOtp,
// // // // // // // // // // // // // // // //         builder: (_, state) => OtpScreen(email: state.extra as String? ?? ''),
// // // // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // // // //       GoRoute(path: RouteNames.onboarding, builder: (_, __) => const OnboardingScreen()),

// // // // // // // // // // // // // // // //       // ── Main shell tabs ───────────────────────────────────────────────────
// // // // // // // // // // // // // // // //       ShellRoute(
// // // // // // // // // // // // // // // //         navigatorKey: _shellKey,
// // // // // // // // // // // // // // // //         builder: (_, __, child) => HomeShellScreen(child: child),
// // // // // // // // // // // // // // // //         routes: [
// // // // // // // // // // // // // // // //           GoRoute(
// // // // // // // // // // // // // // // //             path: RouteNames.home,
// // // // // // // // // // // // // // // //             builder: (_, __) => const RoomBrowserScreen(),
// // // // // // // // // // // // // // // //             routes: [
// // // // // // // // // // // // // // // //               GoRoute(
// // // // // // // // // // // // // // // //                 path: 'room/:roomId',
// // // // // // // // // // // // // // // //                 name: RouteNames.room,
// // // // // // // // // // // // // // // //                 parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // // // //                 builder: (_, state) =>
// // // // // // // // // // // // // // // //                     LobbyScreen(roomId: state.pathParameters['roomId']!),
// // // // // // // // // // // // // // // //                 routes: [
// // // // // // // // // // // // // // // //                   GoRoute(
// // // // // // // // // // // // // // // //                     path: 'game',
// // // // // // // // // // // // // // // //                     name: 'game',
// // // // // // // // // // // // // // // //                     parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // // // //                     builder: (_, state) {
// // // // // // // // // // // // // // // //                       final extra = state.extra as Map<String, dynamic>? ?? {};
// // // // // // // // // // // // // // // //                       final config = extra['config'] as GameConfig? ??
// // // // // // // // // // // // // // // //                           const GameConfig(
// // // // // // // // // // // // // // // //                             maxRounds: 10, turnTimerSeconds: 60,
// // // // // // // // // // // // // // // //                             allowSkip: true, allowSpicy: false,
// // // // // // // // // // // // // // // //                           );
// // // // // // // // // // // // // // // //                       return TodGameScreen(
// // // // // // // // // // // // // // // //                         roomId:             state.pathParameters['roomId']!,
// // // // // // // // // // // // // // // //                         config:             config,
// // // // // // // // // // // // // // // //                         playerIds:          (extra['playerIds'] as List?)?.cast<String>() ?? [],
// // // // // // // // // // // // // // // //                         playerDisplayNames: (extra['displayNames'] as Map?)?.cast<String, String>() ?? {},
// // // // // // // // // // // // // // // //                         packId:             extra['packId'] as String? ?? '',
// // // // // // // // // // // // // // // //                         isOwner:            extra['isOwner'] as bool? ?? false,
// // // // // // // // // // // // // // // //                         isModerator:        extra['isModerator'] as bool? ?? false,
// // // // // // // // // // // // // // // //                         sessionId:          extra['sessionId'] as String?,
// // // // // // // // // // // // // // // //                       );
// // // // // // // // // // // // // // // //                     },
// // // // // // // // // // // // // // // //                   ),
// // // // // // // // // // // // // // // //                 ],
// // // // // // // // // // // // // // // //               ),
// // // // // // // // // // // // // // // //             ],
// // // // // // // // // // // // // // // //           ),
// // // // // // // // // // // // // // // //           GoRoute(
// // // // // // // // // // // // // // // //             path: RouteNames.friends,
// // // // // // // // // // // // // // // //             builder: (_, __) => const _Placeholder('Friends'),
// // // // // // // // // // // // // // // //           ),
// // // // // // // // // // // // // // // //           GoRoute(
// // // // // // // // // // // // // // // //             path: RouteNames.marketplace,
// // // // // // // // // // // // // // // //             builder: (_, __) => const MarketplaceScreen(),
// // // // // // // // // // // // // // // //             routes: [
// // // // // // // // // // // // // // // //               GoRoute(
// // // // // // // // // // // // // // // //                 path: 'pack/:packId',
// // // // // // // // // // // // // // // //                 name: RouteNames.packDetail,
// // // // // // // // // // // // // // // //                 parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // // // //                 builder: (_, state) =>
// // // // // // // // // // // // // // // //                     _Placeholder('Pack: ${state.pathParameters["packId"]}'),
// // // // // // // // // // // // // // // //               ),
// // // // // // // // // // // // // // // //             ],
// // // // // // // // // // // // // // // //           ),
// // // // // // // // // // // // // // // //           GoRoute(
// // // // // // // // // // // // // // // //             path: RouteNames.profile,
// // // // // // // // // // // // // // // //             builder: (_, __) => const ProfileScreen(),
// // // // // // // // // // // // // // // //           ),
// // // // // // // // // // // // // // // //         ],
// // // // // // // // // // // // // // // //       ),

// // // // // // // // // // // // // // // //       // ── Full-screen routes (above shell) ─────────────────────────────────
// // // // // // // // // // // // // // // //       GoRoute(
// // // // // // // // // // // // // // // //         path: '/profile/edit',
// // // // // // // // // // // // // // // //         parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // // // //         builder: (_, __) => const EditProfileScreen(),
// // // // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // // // //       GoRoute(
// // // // // // // // // // // // // // // //         path: '/profile/change-username',
// // // // // // // // // // // // // // // //         parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // // // //         builder: (_, __) => const ChangeUsernameScreen(),
// // // // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // // // //       GoRoute(
// // // // // // // // // // // // // // // //         path: RouteNames.wallet,
// // // // // // // // // // // // // // // //         parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // // // //         builder: (_, __) => const WalletHomeScreen(),
// // // // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // // // //       GoRoute(
// // // // // // // // // // // // // // // //         path: RouteNames.notifications,
// // // // // // // // // // // // // // // //         parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // // // //         builder: (_, __) => const NotificationsScreen(),
// // // // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // // // //       GoRoute(
// // // // // // // // // // // // // // // //         path: '/creator',
// // // // // // // // // // // // // // // //         parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // // // //         builder: (_, __) => const CreatorDashboardScreen(),
// // // // // // // // // // // // // // // //         routes: [
// // // // // // // // // // // // // // // //           GoRoute(
// // // // // // // // // // // // // // // //             path: 'create-pack',
// // // // // // // // // // // // // // // //             builder: (_, __) => const CreatePackScreen(),
// // // // // // // // // // // // // // // //           ),
// // // // // // // // // // // // // // // //         ],
// // // // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // // // //       GoRoute(
// // // // // // // // // // // // // // // //         path: RouteNames.settings,
// // // // // // // // // // // // // // // //         parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // // // //         builder: (_, __) => const SettingsScreen(),
// // // // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // // // //       GoRoute(
// // // // // // // // // // // // // // // //         path: RouteNames.offline,
// // // // // // // // // // // // // // // //         parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // // // //         builder: (_, __) => const OfflineGameScreen(),
// // // // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // // // //     ],

// // // // // // // // // // // // // // // //     errorBuilder: (_, state) => NotFoundScreen(error: state.error),
// // // // // // // // // // // // // // // //   );
// // // // // // // // // // // // // // // // }

// // // // // // // // // // // // // // // // class _Placeholder extends StatelessWidget {
// // // // // // // // // // // // // // // //   const _Placeholder(this.label);
// // // // // // // // // // // // // // // //   final String label;

// // // // // // // // // // // // // // // //   @override
// // // // // // // // // // // // // // // //   Widget build(BuildContext context) => Scaffold(
// // // // // // // // // // // // // // // //         appBar: AppBar(title: Text(label)),
// // // // // // // // // // // // // // // //         body: Center(
// // // // // // // // // // // // // // // //           child: Text(label, style: Theme.of(context).textTheme.headlineMedium),
// // // // // // // // // // // // // // // //         ),
// // // // // // // // // // // // // // // //       );
// // // // // // // // // // // // // // // // }

// // // // // // // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // // // // // // // // import '../providers/auth_provider.dart';
// // // // // // // // // // // // // // // import 'route_names.dart';
// // // // // // // // // // // // // // // import '../../features/auth/presentation/screens/splash_screen.dart';
// // // // // // // // // // // // // // // import '../../features/auth/presentation/screens/email_screen.dart';
// // // // // // // // // // // // // // // import '../../features/auth/presentation/screens/otp_screen.dart';
// // // // // // // // // // // // // // // import '../../features/auth/presentation/screens/onboarding_screen.dart';
// // // // // // // // // // // // // // // import '../../features/rooms/presentation/screens/room_browser_screen.dart';
// // // // // // // // // // // // // // // import '../../features/rooms/presentation/screens/lobby_screen.dart';
// // // // // // // // // // // // // // // import '../../features/packs/presentation/screens/marketplace_screen.dart';
// // // // // // // // // // // // // // // import '../../features/profile/presentation/screens/profile_screen.dart';
// // // // // // // // // // // // // // // import '../../features/profile/presentation/screens/edit_profile_screen.dart';
// // // // // // // // // // // // // // // import '../../features/profile/presentation/screens/change_username_screen.dart';
// // // // // // // // // // // // // // // import '../../features/settings/presentation/settings_screen.dart';
// // // // // // // // // // // // // // // import '../../features/offline/presentation/screens/offline_game_screen.dart';
// // // // // // // // // // // // // // // import '../../features/games/engine/base_game_engine.dart';
// // // // // // // // // // // // // // // import '../../features/games/truth_or_dare/presentation/screens/tod_game_screen.dart';
// // // // // // // // // // // // // // // import '../../features/packs/presentation/screens/pack_detail_screen.dart';
// // // // // // // // // // // // // // // import '../../features/wallet/presentation/screens/wallet_home_screen.dart';
// // // // // // // // // // // // // // // import '../../features/friends/presentation/screens/friends_screen.dart';
// // // // // // // // // // // // // // // import '../../features/friends/presentation/screens/user_profile_screen.dart';
// // // // // // // // // // // // // // // import '../../features/notifications/presentation/screens/notifications_screen.dart';
// // // // // // // // // // // // // // // import '../../features/packs/presentation/screens/creator_dashboard_screen.dart';
// // // // // // // // // // // // // // // import '../../features/packs/presentation/screens/create_pack_screen.dart';
// // // // // // // // // // // // // // // import '../../shared/screens/home_shell_screen.dart';
// // // // // // // // // // // // // // // import '../../shared/screens/not_found_screen.dart';

// // // // // // // // // // // // // // // class AppRouter {
// // // // // // // // // // // // // // //   AppRouter._();

// // // // // // // // // // // // // // //   static final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
// // // // // // // // // // // // // // //   static final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

// // // // // // // // // // // // // // //   /// Call once from app.dart, passing AuthProvider as the listenable.
// // // // // // // // // // // // // // //   /// GoRouter re-evaluates redirect() every time AuthProvider notifies.
// // // // // // // // // // // // // // //   static GoRouter createRouter(AuthProvider authProvider) => GoRouter(
// // // // // // // // // // // // // // //     navigatorKey: _rootKey,
// // // // // // // // // // // // // // //     initialLocation: RouteNames.splash,
// // // // // // // // // // // // // // //     debugLogDiagnostics: false,
// // // // // // // // // // // // // // //     refreshListenable:
// // // // // // // // // // // // // // //         authProvider, // ← re-runs redirect on every notifyListeners()
// // // // // // // // // // // // // // //     // ── Auth guard ────────────────────────────────────────────────────────
// // // // // // // // // // // // // // //     redirect: (context, state) {
// // // // // // // // // // // // // // //       final auth = context.read<AuthProvider>();
// // // // // // // // // // // // // // //       final loc = state.uri.toString();

// // // // // // // // // // // // // // //       final alwaysPublic = [
// // // // // // // // // // // // // // //         RouteNames.splash,
// // // // // // // // // // // // // // //         RouteNames.authEmail,
// // // // // // // // // // // // // // //         RouteNames.authOtp,
// // // // // // // // // // // // // // //       ];
// // // // // // // // // // // // // // //       final isPublic = alwaysPublic.any((r) => loc.startsWith(r));

// // // // // // // // // // // // // // //       // Still initializing — hold on splash
// // // // // // // // // // // // // // //       if (auth.isInitializing) {
// // // // // // // // // // // // // // //         return loc == RouteNames.splash ? null : RouteNames.splash;
// // // // // // // // // // // // // // //       }

// // // // // // // // // // // // // // //       // Guest mode: only offline screen allowed
// // // // // // // // // // // // // // //       if (auth.isGuest) {
// // // // // // // // // // // // // // //         return loc.startsWith(RouteNames.offline) ? null : RouteNames.offline;
// // // // // // // // // // // // // // //       }

// // // // // // // // // // // // // // //       // Not logged in — force to email entry
// // // // // // // // // // // // // // //       if (!auth.isLoggedIn && !isPublic) {
// // // // // // // // // // // // // // //         return RouteNames.authEmail;
// // // // // // // // // // // // // // //       }

// // // // // // // // // // // // // // //       // Logged in, profile incomplete — force onboarding
// // // // // // // // // // // // // // //       if (auth.isLoggedIn &&
// // // // // // // // // // // // // // //           auth.needsOnboarding &&
// // // // // // // // // // // // // // //           loc != RouteNames.onboarding) {
// // // // // // // // // // // // // // //         return RouteNames.onboarding;
// // // // // // // // // // // // // // //       }

// // // // // // // // // // // // // // //       // Logged in, onboarded, on an auth screen — send home
// // // // // // // // // // // // // // //       if (auth.isLoggedIn &&
// // // // // // // // // // // // // // //           !auth.needsOnboarding &&
// // // // // // // // // // // // // // //           isPublic &&
// // // // // // // // // // // // // // //           loc != RouteNames.splash) {
// // // // // // // // // // // // // // //         return RouteNames.home;
// // // // // // // // // // // // // // //       }

// // // // // // // // // // // // // // //       return null; // No redirect needed
// // // // // // // // // // // // // // //     },

// // // // // // // // // // // // // // //     routes: [
// // // // // // // // // // // // // // //       // ── Auth ────────────────────────────────────────────────────────────
// // // // // // // // // // // // // // //       GoRoute(
// // // // // // // // // // // // // // //         path: RouteNames.splash,
// // // // // // // // // // // // // // //         builder: (_, __) => const SplashScreen(),
// // // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // // //       GoRoute(
// // // // // // // // // // // // // // //         path: RouteNames.authEmail,
// // // // // // // // // // // // // // //         builder: (_, __) => const EmailScreen(),
// // // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // // //       GoRoute(
// // // // // // // // // // // // // // //         path: RouteNames.authOtp,
// // // // // // // // // // // // // // //         builder: (_, state) => OtpScreen(email: state.extra as String? ?? ''),
// // // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // // //       GoRoute(
// // // // // // // // // // // // // // //         path: RouteNames.onboarding,
// // // // // // // // // // // // // // //         builder: (_, __) => const OnboardingScreen(),
// // // // // // // // // // // // // // //       ),

// // // // // // // // // // // // // // //       // ── Main shell tabs ───────────────────────────────────────────────────
// // // // // // // // // // // // // // //       ShellRoute(
// // // // // // // // // // // // // // //         navigatorKey: _shellKey,
// // // // // // // // // // // // // // //         builder: (_, __, child) => HomeShellScreen(child: child),
// // // // // // // // // // // // // // //         routes: [
// // // // // // // // // // // // // // //           GoRoute(
// // // // // // // // // // // // // // //             path: RouteNames.home,
// // // // // // // // // // // // // // //             builder: (_, __) => const RoomBrowserScreen(),
// // // // // // // // // // // // // // //             routes: [
// // // // // // // // // // // // // // //               GoRoute(
// // // // // // // // // // // // // // //                 path: 'room/:roomId',
// // // // // // // // // // // // // // //                 name: RouteNames.room,
// // // // // // // // // // // // // // //                 parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // // //                 builder: (_, state) =>
// // // // // // // // // // // // // // //                     LobbyScreen(roomId: state.pathParameters['roomId']!),
// // // // // // // // // // // // // // //                 routes: [
// // // // // // // // // // // // // // //                   GoRoute(
// // // // // // // // // // // // // // //                     path: 'game',
// // // // // // // // // // // // // // //                     name: 'game',
// // // // // // // // // // // // // // //                     parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // // //                     builder: (_, state) {
// // // // // // // // // // // // // // //                       final extra = state.extra as Map<String, dynamic>? ?? {};
// // // // // // // // // // // // // // //                       final config =
// // // // // // // // // // // // // // //                           extra['config'] as GameConfig? ??
// // // // // // // // // // // // // // //                           const GameConfig(
// // // // // // // // // // // // // // //                             maxRounds: 10,
// // // // // // // // // // // // // // //                             turnTimerSeconds: 60,
// // // // // // // // // // // // // // //                             allowSkip: true,
// // // // // // // // // // // // // // //                             allowSpicy: false,
// // // // // // // // // // // // // // //                           );
// // // // // // // // // // // // // // //                       return TodGameScreen(
// // // // // // // // // // // // // // //                         roomId: state.pathParameters['roomId']!,
// // // // // // // // // // // // // // //                         config: config,
// // // // // // // // // // // // // // //                         playerIds:
// // // // // // // // // // // // // // //                             (extra['playerIds'] as List?)?.cast<String>() ?? [],
// // // // // // // // // // // // // // //                         playerDisplayNames:
// // // // // // // // // // // // // // //                             (extra['displayNames'] as Map?)
// // // // // // // // // // // // // // //                                 ?.cast<String, String>() ??
// // // // // // // // // // // // // // //                             {},
// // // // // // // // // // // // // // //                         packId: extra['packId'] as String? ?? '',
// // // // // // // // // // // // // // //                         isOwner: extra['isOwner'] as bool? ?? false,
// // // // // // // // // // // // // // //                         isModerator: extra['isModerator'] as bool? ?? false,
// // // // // // // // // // // // // // //                         sessionId: extra['sessionId'] as String?,
// // // // // // // // // // // // // // //                       );
// // // // // // // // // // // // // // //                     },
// // // // // // // // // // // // // // //                   ),
// // // // // // // // // // // // // // //                 ],
// // // // // // // // // // // // // // //               ),
// // // // // // // // // // // // // // //             ],
// // // // // // // // // // // // // // //           ),
// // // // // // // // // // // // // // //           GoRoute(
// // // // // // // // // // // // // // //             path: RouteNames.friends,
// // // // // // // // // // // // // // //             builder: (_, __) => const FriendsScreen(),
// // // // // // // // // // // // // // //           ),
// // // // // // // // // // // // // // //           GoRoute(
// // // // // // // // // // // // // // //             path: RouteNames.marketplace,
// // // // // // // // // // // // // // //             builder: (_, __) => const MarketplaceScreen(),
// // // // // // // // // // // // // // //             routes: [
// // // // // // // // // // // // // // //               GoRoute(
// // // // // // // // // // // // // // //                 path: 'pack/:packId',
// // // // // // // // // // // // // // //                 name: RouteNames.packDetail,
// // // // // // // // // // // // // // //                 parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // // //                 builder: (_, state) =>
// // // // // // // // // // // // // // //                     _Placeholder('Pack: ${state.pathParameters["packId"]}'),
// // // // // // // // // // // // // // //               ),
// // // // // // // // // // // // // // //             ],
// // // // // // // // // // // // // // //           ),
// // // // // // // // // // // // // // //           GoRoute(
// // // // // // // // // // // // // // //             path: RouteNames.profile,
// // // // // // // // // // // // // // //             builder: (_, __) => const ProfileScreen(),
// // // // // // // // // // // // // // //           ),
// // // // // // // // // // // // // // //         ],
// // // // // // // // // // // // // // //       ),

// // // // // // // // // // // // // // //       // ── Full-screen routes (above shell) ─────────────────────────────────
// // // // // // // // // // // // // // //       GoRoute(
// // // // // // // // // // // // // // //         path: '/profile/edit',
// // // // // // // // // // // // // // //         parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // // //         builder: (_, __) => const EditProfileScreen(),
// // // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // // //       GoRoute(
// // // // // // // // // // // // // // //         path: '/profile/change-username',
// // // // // // // // // // // // // // //         parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // // //         builder: (_, __) => const ChangeUsernameScreen(),
// // // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // // //       GoRoute(
// // // // // // // // // // // // // // //         path: RouteNames.wallet,
// // // // // // // // // // // // // // //         parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // // //         builder: (_, __) => const WalletHomeScreen(),
// // // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // // //       GoRoute(
// // // // // // // // // // // // // // //         path: RouteNames.notifications,
// // // // // // // // // // // // // // //         parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // // //         builder: (_, __) => const NotificationsScreen(),
// // // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // // //       GoRoute(
// // // // // // // // // // // // // // //         path: '/creator',
// // // // // // // // // // // // // // //         parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // // //         builder: (_, __) => const CreatorDashboardScreen(),
// // // // // // // // // // // // // // //         routes: [
// // // // // // // // // // // // // // //           GoRoute(
// // // // // // // // // // // // // // //             path: 'create-pack',
// // // // // // // // // // // // // // //             builder: (_, __) => const CreatePackScreen(),
// // // // // // // // // // // // // // //           ),
// // // // // // // // // // // // // // //         ],
// // // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // // //       GoRoute(
// // // // // // // // // // // // // // //         path: RouteNames.settings,
// // // // // // // // // // // // // // //         parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // // //         builder: (_, __) => const SettingsScreen(),
// // // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // // //       GoRoute(
// // // // // // // // // // // // // // //         path: RouteNames.offline,
// // // // // // // // // // // // // // //         parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // // //         builder: (_, __) => const OfflineGameScreen(),
// // // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // // //     ],

// // // // // // // // // // // // // // //     errorBuilder: (_, state) => NotFoundScreen(error: state.error),
// // // // // // // // // // // // // // //   );
// // // // // // // // // // // // // // // }

// // // // // // // // // // // // // // // class _Placeholder extends StatelessWidget {
// // // // // // // // // // // // // // //   const _Placeholder(this.label);
// // // // // // // // // // // // // // //   final String label;

// // // // // // // // // // // // // // //   @override
// // // // // // // // // // // // // // //   Widget build(BuildContext context) => Scaffold(
// // // // // // // // // // // // // // //     appBar: AppBar(title: Text(label)),
// // // // // // // // // // // // // // //     body: Center(
// // // // // // // // // // // // // // //       child: Text(label, style: Theme.of(context).textTheme.headlineMedium),
// // // // // // // // // // // // // // //     ),
// // // // // // // // // // // // // // //   );
// // // // // // // // // // // // // // // }
// // // // // // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // // // // // // // import '../providers/auth_provider.dart';
// // // // // // // // // // // // // // import 'route_names.dart';
// // // // // // // // // // // // // // import '../../features/auth/presentation/screens/splash_screen.dart';
// // // // // // // // // // // // // // import '../../features/auth/presentation/screens/email_screen.dart';
// // // // // // // // // // // // // // import '../../features/auth/presentation/screens/otp_screen.dart';
// // // // // // // // // // // // // // import '../../features/auth/presentation/screens/onboarding_screen.dart';
// // // // // // // // // // // // // // import '../../features/rooms/presentation/screens/room_browser_screen.dart';
// // // // // // // // // // // // // // import '../../features/rooms/presentation/screens/lobby_screen.dart';
// // // // // // // // // // // // // // import '../../features/packs/presentation/screens/marketplace_screen.dart';
// // // // // // // // // // // // // // import '../../features/profile/presentation/screens/profile_screen.dart';
// // // // // // // // // // // // // // import '../../features/profile/presentation/screens/edit_profile_screen.dart';
// // // // // // // // // // // // // // import '../../features/profile/presentation/screens/change_username_screen.dart';
// // // // // // // // // // // // // // import '../../features/settings/presentation/settings_screen.dart';
// // // // // // // // // // // // // // import '../../features/offline/presentation/screens/offline_game_screen.dart';
// // // // // // // // // // // // // // import '../../features/games/engine/base_game_engine.dart';
// // // // // // // // // // // // // // import '../../features/games/truth_or_dare/presentation/screens/tod_game_screen.dart';
// // // // // // // // // // // // // // import '../../features/packs/presentation/screens/pack_detail_screen.dart';
// // // // // // // // // // // // // // import '../../features/wallet/presentation/screens/wallet_home_screen.dart';
// // // // // // // // // // // // // // import '../../features/friends/presentation/screens/friends_screen.dart';
// // // // // // // // // // // // // // import '../../features/friends/presentation/screens/user_profile_screen.dart';
// // // // // // // // // // // // // // import '../../features/notifications/presentation/screens/notifications_screen.dart';
// // // // // // // // // // // // // // import '../../features/packs/presentation/screens/creator_dashboard_screen.dart';
// // // // // // // // // // // // // // import '../../features/packs/presentation/screens/create_pack_screen.dart';
// // // // // // // // // // // // // // import '../../shared/screens/home_shell_screen.dart';
// // // // // // // // // // // // // // import '../../shared/screens/not_found_screen.dart';

// // // // // // // // // // // // // // class AppRouter {
// // // // // // // // // // // // // //   AppRouter._();

// // // // // // // // // // // // // //   static final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
// // // // // // // // // // // // // //   static final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

// // // // // // // // // // // // // //   // Holds the last created router so services can navigate imperatively.
// // // // // // // // // // // // // //   static GoRouter? _instance;
// // // // // // // // // // // // // //   static GoRouter get router {
// // // // // // // // // // // // // //     assert(
// // // // // // // // // // // // // //       _instance != null,
// // // // // // // // // // // // // //       'AppRouter.router accessed before createRouter() was called.',
// // // // // // // // // // // // // //     );
// // // // // // // // // // // // // //     return _instance!;
// // // // // // // // // // // // // //   }

// // // // // // // // // // // // // //   /// Call once from app.dart, passing AuthProvider as the listenable.
// // // // // // // // // // // // // //   /// GoRouter re-evaluates redirect() every time AuthProvider notifies.
// // // // // // // // // // // // // //   static GoRouter createRouter(AuthProvider authProvider) {
// // // // // // // // // // // // // //     _instance = GoRouter(
// // // // // // // // // // // // // //       navigatorKey: _rootKey,
// // // // // // // // // // // // // //       initialLocation: RouteNames.splash,
// // // // // // // // // // // // // //       debugLogDiagnostics: false,
// // // // // // // // // // // // // //       refreshListenable:
// // // // // // // // // // // // // //           authProvider, // ← re-runs redirect on every notifyListeners()
// // // // // // // // // // // // // //       // ── Auth guard ────────────────────────────────────────────────────────
// // // // // // // // // // // // // //       redirect: (context, state) {
// // // // // // // // // // // // // //         final auth = context.read<AuthProvider>();
// // // // // // // // // // // // // //         final loc = state.uri.toString();

// // // // // // // // // // // // // //         final alwaysPublic = [
// // // // // // // // // // // // // //           RouteNames.splash,
// // // // // // // // // // // // // //           RouteNames.authEmail,
// // // // // // // // // // // // // //           RouteNames.authOtp,
// // // // // // // // // // // // // //         ];
// // // // // // // // // // // // // //         final isPublic = alwaysPublic.any((r) => loc.startsWith(r));

// // // // // // // // // // // // // //         // Still initializing — hold on splash
// // // // // // // // // // // // // //         if (auth.isInitializing) {
// // // // // // // // // // // // // //           return loc == RouteNames.splash ? null : RouteNames.splash;
// // // // // // // // // // // // // //         }

// // // // // // // // // // // // // //         // Guest mode: only offline screen allowed
// // // // // // // // // // // // // //         if (auth.isGuest) {
// // // // // // // // // // // // // //           return loc.startsWith(RouteNames.offline) ? null : RouteNames.offline;
// // // // // // // // // // // // // //         }

// // // // // // // // // // // // // //         // Not logged in — force to email entry
// // // // // // // // // // // // // //         if (!auth.isLoggedIn && !isPublic) {
// // // // // // // // // // // // // //           return RouteNames.authEmail;
// // // // // // // // // // // // // //         }

// // // // // // // // // // // // // //         // Logged in, profile incomplete — force onboarding
// // // // // // // // // // // // // //         if (auth.isLoggedIn &&
// // // // // // // // // // // // // //             auth.needsOnboarding &&
// // // // // // // // // // // // // //             loc != RouteNames.onboarding) {
// // // // // // // // // // // // // //           return RouteNames.onboarding;
// // // // // // // // // // // // // //         }

// // // // // // // // // // // // // //         // Logged in, onboarded, on an auth screen — send home
// // // // // // // // // // // // // //         if (auth.isLoggedIn &&
// // // // // // // // // // // // // //             !auth.needsOnboarding &&
// // // // // // // // // // // // // //             isPublic &&
// // // // // // // // // // // // // //             loc != RouteNames.splash) {
// // // // // // // // // // // // // //           return RouteNames.home;
// // // // // // // // // // // // // //         }

// // // // // // // // // // // // // //         return null; // No redirect needed
// // // // // // // // // // // // // //       },

// // // // // // // // // // // // // //       routes: [
// // // // // // // // // // // // // //         // ── Auth ────────────────────────────────────────────────────────────
// // // // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // // // //           path: RouteNames.splash,
// // // // // // // // // // // // // //           builder: (_, __) => const SplashScreen(),
// // // // // // // // // // // // // //         ),
// // // // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // // // //           path: RouteNames.authEmail,
// // // // // // // // // // // // // //           builder: (_, __) => const EmailScreen(),
// // // // // // // // // // // // // //         ),
// // // // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // // // //           path: RouteNames.authOtp,
// // // // // // // // // // // // // //           builder: (_, state) => OtpScreen(email: state.extra as String? ?? ''),
// // // // // // // // // // // // // //         ),
// // // // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // // // //           path: RouteNames.onboarding,
// // // // // // // // // // // // // //           builder: (_, __) => const OnboardingScreen(),
// // // // // // // // // // // // // //         ),

// // // // // // // // // // // // // //         // ── Main shell tabs ───────────────────────────────────────────────────
// // // // // // // // // // // // // //         ShellRoute(
// // // // // // // // // // // // // //           navigatorKey: _shellKey,
// // // // // // // // // // // // // //           builder: (_, __, child) => HomeShellScreen(child: child),
// // // // // // // // // // // // // //           routes: [
// // // // // // // // // // // // // //             GoRoute(
// // // // // // // // // // // // // //               path: RouteNames.home,
// // // // // // // // // // // // // //               builder: (_, __) => const RoomBrowserScreen(),
// // // // // // // // // // // // // //               routes: [
// // // // // // // // // // // // // //                 GoRoute(
// // // // // // // // // // // // // //                   path: 'room/:roomId',
// // // // // // // // // // // // // //                   name: RouteNames.room,
// // // // // // // // // // // // // //                   parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // //                   builder: (_, state) =>
// // // // // // // // // // // // // //                       LobbyScreen(roomId: state.pathParameters['roomId']!),
// // // // // // // // // // // // // //                   routes: [
// // // // // // // // // // // // // //                     GoRoute(
// // // // // // // // // // // // // //                       path: 'game',
// // // // // // // // // // // // // //                       name: 'game',
// // // // // // // // // // // // // //                       parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // //                       builder: (_, state) {
// // // // // // // // // // // // // //                         final extra =
// // // // // // // // // // // // // //                             state.extra as Map<String, dynamic>? ?? {};
// // // // // // // // // // // // // //                         final config =
// // // // // // // // // // // // // //                             extra['config'] as GameConfig? ??
// // // // // // // // // // // // // //                             const GameConfig(
// // // // // // // // // // // // // //                               maxRounds: 10,
// // // // // // // // // // // // // //                               turnTimerSeconds: 60,
// // // // // // // // // // // // // //                               allowSkip: true,
// // // // // // // // // // // // // //                               allowSpicy: false,
// // // // // // // // // // // // // //                             );
// // // // // // // // // // // // // //                         return TodGameScreen(
// // // // // // // // // // // // // //                           roomId: state.pathParameters['roomId']!,
// // // // // // // // // // // // // //                           config: config,
// // // // // // // // // // // // // //                           playerIds:
// // // // // // // // // // // // // //                               (extra['playerIds'] as List?)?.cast<String>() ??
// // // // // // // // // // // // // //                               [],
// // // // // // // // // // // // // //                           playerDisplayNames:
// // // // // // // // // // // // // //                               (extra['displayNames'] as Map?)
// // // // // // // // // // // // // //                                   ?.cast<String, String>() ??
// // // // // // // // // // // // // //                               {},
// // // // // // // // // // // // // //                           packId: extra['packId'] as String? ?? '',
// // // // // // // // // // // // // //                           isOwner: extra['isOwner'] as bool? ?? false,
// // // // // // // // // // // // // //                           isModerator: extra['isModerator'] as bool? ?? false,
// // // // // // // // // // // // // //                           sessionId: extra['sessionId'] as String?,
// // // // // // // // // // // // // //                         );
// // // // // // // // // // // // // //                       },
// // // // // // // // // // // // // //                     ),
// // // // // // // // // // // // // //                   ],
// // // // // // // // // // // // // //                 ),
// // // // // // // // // // // // // //               ],
// // // // // // // // // // // // // //             ),
// // // // // // // // // // // // // //             GoRoute(
// // // // // // // // // // // // // //               path: RouteNames.friends,
// // // // // // // // // // // // // //               builder: (_, __) => const FriendsScreen(),
// // // // // // // // // // // // // //             ),
// // // // // // // // // // // // // //             GoRoute(
// // // // // // // // // // // // // //               path: RouteNames.marketplace,
// // // // // // // // // // // // // //               builder: (_, __) => const MarketplaceScreen(),
// // // // // // // // // // // // // //               routes: [
// // // // // // // // // // // // // //                 GoRoute(
// // // // // // // // // // // // // //                   path: 'pack/:packId',
// // // // // // // // // // // // // //                   name: RouteNames.packDetail,
// // // // // // // // // // // // // //                   parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // //                   builder: (_, state) =>
// // // // // // // // // // // // // //                       _Placeholder('Pack: ${state.pathParameters["packId"]}'),
// // // // // // // // // // // // // //                 ),
// // // // // // // // // // // // // //               ],
// // // // // // // // // // // // // //             ),
// // // // // // // // // // // // // //             GoRoute(
// // // // // // // // // // // // // //               path: RouteNames.profile,
// // // // // // // // // // // // // //               builder: (_, __) => const ProfileScreen(),
// // // // // // // // // // // // // //             ),
// // // // // // // // // // // // // //           ],
// // // // // // // // // // // // // //         ),

// // // // // // // // // // // // // //         // ── Full-screen routes (above shell) ─────────────────────────────────
// // // // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // // // //           path: '/profile/edit',
// // // // // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // //           builder: (_, __) => const EditProfileScreen(),
// // // // // // // // // // // // // //         ),
// // // // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // // // //           path: '/profile/change-username',
// // // // // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // //           builder: (_, __) => const ChangeUsernameScreen(),
// // // // // // // // // // // // // //         ),
// // // // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // // // //           path: RouteNames.wallet,
// // // // // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // //           builder: (_, __) => const WalletHomeScreen(),
// // // // // // // // // // // // // //         ),
// // // // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // // // //           path: RouteNames.notifications,
// // // // // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // //           builder: (_, __) => const NotificationsScreen(),
// // // // // // // // // // // // // //         ),
// // // // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // // // //           path: '/creator',
// // // // // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // //           builder: (_, __) => const CreatorDashboardScreen(),
// // // // // // // // // // // // // //           routes: [
// // // // // // // // // // // // // //             GoRoute(
// // // // // // // // // // // // // //               path: 'create-pack',
// // // // // // // // // // // // // //               builder: (_, __) => const CreatePackScreen(),
// // // // // // // // // // // // // //             ),
// // // // // // // // // // // // // //           ],
// // // // // // // // // // // // // //         ),
// // // // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // // // //           path: RouteNames.settings,
// // // // // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // //           builder: (_, __) => const SettingsScreen(),
// // // // // // // // // // // // // //         ),
// // // // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // // // //           path: RouteNames.offline,
// // // // // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // // // // //           builder: (_, __) => const OfflineGameScreen(),
// // // // // // // // // // // // // //         ),
// // // // // // // // // // // // // //       ],

// // // // // // // // // // // // // //       errorBuilder: (_, state) => NotFoundScreen(error: state.error),
// // // // // // // // // // // // // //     );
// // // // // // // // // // // // // //     return _instance!;
// // // // // // // // // // // // // //   }
// // // // // // // // // // // // // // }

// // // // // // // // // // // // // // class _Placeholder extends StatelessWidget {
// // // // // // // // // // // // // //   const _Placeholder(this.label);
// // // // // // // // // // // // // //   final String label;

// // // // // // // // // // // // // //   @override
// // // // // // // // // // // // // //   Widget build(BuildContext context) => Scaffold(
// // // // // // // // // // // // // //     appBar: AppBar(title: Text(label)),
// // // // // // // // // // // // // //     body: Center(
// // // // // // // // // // // // // //       child: Text(label, style: Theme.of(context).textTheme.headlineMedium),
// // // // // // // // // // // // // //     ),
// // // // // // // // // // // // // //   );
// // // // // // // // // // // // // // }

// // // // // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // // // // // // import '../providers/auth_provider.dart';
// // // // // // // // // // // // // import 'route_names.dart';
// // // // // // // // // // // // // import '../../features/auth/presentation/screens/splash_screen.dart';
// // // // // // // // // // // // // import '../../features/auth/presentation/screens/email_screen.dart';
// // // // // // // // // // // // // import '../../features/auth/presentation/screens/otp_screen.dart';
// // // // // // // // // // // // // import '../../features/auth/presentation/screens/onboarding_screen.dart';
// // // // // // // // // // // // // import '../../features/rooms/presentation/screens/room_browser_screen.dart';
// // // // // // // // // // // // // import '../../features/rooms/presentation/screens/lobby_screen.dart';
// // // // // // // // // // // // // import '../../features/packs/presentation/screens/marketplace_screen.dart';
// // // // // // // // // // // // // import '../../features/profile/presentation/screens/profile_screen.dart';
// // // // // // // // // // // // // import '../../features/profile/presentation/screens/edit_profile_screen.dart';
// // // // // // // // // // // // // import '../../features/profile/presentation/screens/change_username_screen.dart';
// // // // // // // // // // // // // import '../../features/settings/presentation/settings_screen.dart';
// // // // // // // // // // // // // import '../../features/offline/presentation/screens/offline_game_screen.dart';
// // // // // // // // // // // // // import '../../features/games/engine/base_game_engine.dart';
// // // // // // // // // // // // // import '../../features/games/truth_or_dare/presentation/screens/tod_game_screen.dart';
// // // // // // // // // // // // // import '../../features/packs/presentation/screens/pack_detail_screen.dart';
// // // // // // // // // // // // // import '../../features/wallet/presentation/screens/wallet_home_screen.dart';
// // // // // // // // // // // // // import '../../features/friends/presentation/screens/friends_screen.dart';
// // // // // // // // // // // // // import '../../features/friends/presentation/screens/user_profile_screen.dart';
// // // // // // // // // // // // // import '../../features/notifications/presentation/screens/notifications_screen.dart';
// // // // // // // // // // // // // import '../../features/packs/presentation/screens/creator_dashboard_screen.dart';
// // // // // // // // // // // // // import '../../features/packs/presentation/screens/create_pack_screen.dart';
// // // // // // // // // // // // // import '../../shared/screens/home_shell_screen.dart';
// // // // // // // // // // // // // import '../../shared/screens/not_found_screen.dart';

// // // // // // // // // // // // // class AppRouter {
// // // // // // // // // // // // //   AppRouter._();

// // // // // // // // // // // // //   static final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
// // // // // // // // // // // // //   static final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

// // // // // // // // // // // // //   // Holds the last created router so services can navigate imperatively.
// // // // // // // // // // // // //   static GoRouter? _instance;
// // // // // // // // // // // // //   static GoRouter get router {
// // // // // // // // // // // // //     assert(
// // // // // // // // // // // // //       _instance != null,
// // // // // // // // // // // // //       'AppRouter.router accessed before createRouter() was called.',
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //     return _instance!;
// // // // // // // // // // // // //   }

// // // // // // // // // // // // //   /// Call once from app.dart, passing AuthProvider as the listenable.
// // // // // // // // // // // // //   /// GoRouter re-evaluates redirect() every time AuthProvider notifies.
// // // // // // // // // // // // //   static GoRouter createRouter(AuthProvider authProvider) {
// // // // // // // // // // // // //     _instance = GoRouter(
// // // // // // // // // // // // //       navigatorKey: _rootKey,
// // // // // // // // // // // // //       initialLocation: RouteNames.splash,
// // // // // // // // // // // // //       debugLogDiagnostics: false,
// // // // // // // // // // // // //       refreshListenable: authProvider,
// // // // // // // // // // // // //       redirect: (context, state) {
// // // // // // // // // // // // //         final auth = context.read<AuthProvider>();
// // // // // // // // // // // // //         final loc = state.uri.toString();

// // // // // // // // // // // // //         final alwaysPublic = [
// // // // // // // // // // // // //           RouteNames.splash,
// // // // // // // // // // // // //           RouteNames.authEmail,
// // // // // // // // // // // // //           RouteNames.authOtp,
// // // // // // // // // // // // //         ];
// // // // // // // // // // // // //         final isPublic = alwaysPublic.any((r) => loc.startsWith(r));

// // // // // // // // // // // // //         // Still initializing — hold on splash
// // // // // // // // // // // // //         if (auth.isInitializing) {
// // // // // // // // // // // // //           return loc == RouteNames.splash ? null : RouteNames.splash;
// // // // // // // // // // // // //         }

// // // // // // // // // // // // //         // Done initializing — splash must redirect regardless
// // // // // // // // // // // // //         if (loc == RouteNames.splash) {
// // // // // // // // // // // // //           if (auth.isGuest) return RouteNames.offline;
// // // // // // // // // // // // //           if (!auth.isLoggedIn) return RouteNames.authEmail;
// // // // // // // // // // // // //           if (auth.needsOnboarding) return RouteNames.onboarding;
// // // // // // // // // // // // //           return RouteNames.home;
// // // // // // // // // // // // //         }

// // // // // // // // // // // // //         // Guest mode: only offline screen allowed
// // // // // // // // // // // // //         if (auth.isGuest) {
// // // // // // // // // // // // //           return loc.startsWith(RouteNames.offline) ? null : RouteNames.offline;
// // // // // // // // // // // // //         }

// // // // // // // // // // // // //         // Not logged in — force to email entry
// // // // // // // // // // // // //         if (!auth.isLoggedIn && !isPublic) {
// // // // // // // // // // // // //           return RouteNames.authEmail;
// // // // // // // // // // // // //         }

// // // // // // // // // // // // //         // Logged in, profile incomplete — force onboarding
// // // // // // // // // // // // //         if (auth.isLoggedIn &&
// // // // // // // // // // // // //             auth.needsOnboarding &&
// // // // // // // // // // // // //             loc != RouteNames.onboarding) {
// // // // // // // // // // // // //           return RouteNames.onboarding;
// // // // // // // // // // // // //         }

// // // // // // // // // // // // //         // Logged in, onboarded, on an auth screen — send home
// // // // // // // // // // // // //         if (auth.isLoggedIn &&
// // // // // // // // // // // // //             !auth.needsOnboarding &&
// // // // // // // // // // // // //             isPublic &&
// // // // // // // // // // // // //             loc != RouteNames.splash) {
// // // // // // // // // // // // //           return RouteNames.home;
// // // // // // // // // // // // //         }

// // // // // // // // // // // // //         return null; // No redirect needed
// // // // // // // // // // // // //       },

// // // // // // // // // // // // //       routes: [
// // // // // // // // // // // // //         // ── Auth ────────────────────────────────────────────────────────────
// // // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // // //           path: RouteNames.splash,
// // // // // // // // // // // // //           builder: (_, __) => const SplashScreen(),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // // //           path: RouteNames.authEmail,
// // // // // // // // // // // // //           builder: (_, __) => const EmailScreen(),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // // //           path: RouteNames.authOtp,
// // // // // // // // // // // // //           builder: (_, state) => OtpScreen(email: state.extra as String? ?? ''),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // // //           path: RouteNames.onboarding,
// // // // // // // // // // // // //           builder: (_, __) => const OnboardingScreen(),
// // // // // // // // // // // // //         ),

// // // // // // // // // // // // //         // ── Main shell tabs ───────────────────────────────────────────────────
// // // // // // // // // // // // //         ShellRoute(
// // // // // // // // // // // // //           navigatorKey: _shellKey,
// // // // // // // // // // // // //           builder: (_, __, child) => HomeShellScreen(child: child),
// // // // // // // // // // // // //           routes: [
// // // // // // // // // // // // //             GoRoute(
// // // // // // // // // // // // //               path: RouteNames.home,
// // // // // // // // // // // // //               builder: (_, __) => const RoomBrowserScreen(),
// // // // // // // // // // // // //               routes: [
// // // // // // // // // // // // //                 GoRoute(
// // // // // // // // // // // // //                   path: 'room/:roomId',
// // // // // // // // // // // // //                   name: RouteNames.room,
// // // // // // // // // // // // //                   parentNavigatorKey: _rootKey,
// // // // // // // // // // // // //                   builder: (_, state) =>
// // // // // // // // // // // // //                       LobbyScreen(roomId: state.pathParameters['roomId']!),
// // // // // // // // // // // // //                   routes: [
// // // // // // // // // // // // //                     GoRoute(
// // // // // // // // // // // // //                       path: 'game',
// // // // // // // // // // // // //                       name: 'game',
// // // // // // // // // // // // //                       parentNavigatorKey: _rootKey,
// // // // // // // // // // // // //                       builder: (_, state) {
// // // // // // // // // // // // //                         final extra =
// // // // // // // // // // // // //                             state.extra as Map<String, dynamic>? ?? {};
// // // // // // // // // // // // //                         final config =
// // // // // // // // // // // // //                             extra['config'] as GameConfig? ??
// // // // // // // // // // // // //                             const GameConfig(
// // // // // // // // // // // // //                               maxRounds: 10,
// // // // // // // // // // // // //                               turnTimerSeconds: 60,
// // // // // // // // // // // // //                               allowSkip: true,
// // // // // // // // // // // // //                               allowSpicy: false,
// // // // // // // // // // // // //                             );
// // // // // // // // // // // // //                         return TodGameScreen(
// // // // // // // // // // // // //                           roomId: state.pathParameters['roomId']!,
// // // // // // // // // // // // //                           config: config,
// // // // // // // // // // // // //                           playerIds:
// // // // // // // // // // // // //                               (extra['playerIds'] as List?)?.cast<String>() ??
// // // // // // // // // // // // //                               [],
// // // // // // // // // // // // //                           playerDisplayNames:
// // // // // // // // // // // // //                               (extra['displayNames'] as Map?)
// // // // // // // // // // // // //                                   ?.cast<String, String>() ??
// // // // // // // // // // // // //                               {},
// // // // // // // // // // // // //                           packId: extra['packId'] as String? ?? '',
// // // // // // // // // // // // //                           isOwner: extra['isOwner'] as bool? ?? false,
// // // // // // // // // // // // //                           isModerator: extra['isModerator'] as bool? ?? false,
// // // // // // // // // // // // //                           sessionId: extra['sessionId'] as String?,
// // // // // // // // // // // // //                         );
// // // // // // // // // // // // //                       },
// // // // // // // // // // // // //                     ),
// // // // // // // // // // // // //                   ],
// // // // // // // // // // // // //                 ),
// // // // // // // // // // // // //               ],
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //             GoRoute(
// // // // // // // // // // // // //               path: RouteNames.friends,
// // // // // // // // // // // // //               builder: (_, __) => const FriendsScreen(),
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //             GoRoute(
// // // // // // // // // // // // //               path: RouteNames.marketplace,
// // // // // // // // // // // // //               builder: (_, __) => const MarketplaceScreen(),
// // // // // // // // // // // // //               routes: [
// // // // // // // // // // // // //                 GoRoute(
// // // // // // // // // // // // //                   path: 'pack/:packId',
// // // // // // // // // // // // //                   name: RouteNames.packDetail,
// // // // // // // // // // // // //                   parentNavigatorKey: _rootKey,
// // // // // // // // // // // // //                   builder: (_, state) =>
// // // // // // // // // // // // //                       _Placeholder('Pack: ${state.pathParameters["packId"]}'),
// // // // // // // // // // // // //                 ),
// // // // // // // // // // // // //               ],
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //             GoRoute(
// // // // // // // // // // // // //               path: RouteNames.profile,
// // // // // // // // // // // // //               builder: (_, __) => const ProfileScreen(),
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //           ],
// // // // // // // // // // // // //         ),

// // // // // // // // // // // // //         // ── Full-screen routes (above shell) ─────────────────────────────────
// // // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // // //           path: '/profile/edit',
// // // // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // // // //           builder: (_, __) => const EditProfileScreen(),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // // //           path: '/profile/change-username',
// // // // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // // // //           builder: (_, __) => const ChangeUsernameScreen(),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // // //           path: RouteNames.wallet,
// // // // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // // // //           builder: (_, __) => const WalletHomeScreen(),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // // //           path: RouteNames.notifications,
// // // // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // // // //           builder: (_, __) => const NotificationsScreen(),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // // //           path: '/creator',
// // // // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // // // //           builder: (_, __) => const CreatorDashboardScreen(),
// // // // // // // // // // // // //           routes: [
// // // // // // // // // // // // //             GoRoute(
// // // // // // // // // // // // //               path: 'create-pack',
// // // // // // // // // // // // //               builder: (_, __) => const CreatePackScreen(),
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //           ],
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // // //           path: RouteNames.settings,
// // // // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // // // //           builder: (_, __) => const SettingsScreen(),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // // //           path: RouteNames.offline,
// // // // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // // // //           builder: (_, __) => const OfflineGameScreen(),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //       ],

// // // // // // // // // // // // //       errorBuilder: (_, state) => NotFoundScreen(error: state.error),
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //     return _instance!;
// // // // // // // // // // // // //   }
// // // // // // // // // // // // // }

// // // // // // // // // // // // // class _Placeholder extends StatelessWidget {
// // // // // // // // // // // // //   const _Placeholder(this.label);
// // // // // // // // // // // // //   final String label;

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   Widget build(BuildContext context) => Scaffold(
// // // // // // // // // // // // //     appBar: AppBar(title: Text(label)),
// // // // // // // // // // // // //     body: Center(
// // // // // // // // // // // // //       child: Text(label, style: Theme.of(context).textTheme.headlineMedium),
// // // // // // // // // // // // //     ),
// // // // // // // // // // // // //   );
// // // // // // // // // // // // // }

// // // // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // // // // // import '../providers/auth_provider.dart';
// // // // // // // // // // // // import 'route_names.dart';
// // // // // // // // // // // // import '../../features/auth/presentation/screens/splash_screen.dart';
// // // // // // // // // // // // import '../../features/auth/presentation/screens/email_screen.dart';
// // // // // // // // // // // // import '../../features/auth/presentation/screens/otp_screen.dart';
// // // // // // // // // // // // import '../../features/auth/presentation/screens/onboarding_screen.dart';
// // // // // // // // // // // // import '../../features/rooms/presentation/screens/room_browser_screen.dart';
// // // // // // // // // // // // import '../../features/rooms/presentation/screens/lobby_screen.dart';
// // // // // // // // // // // // import '../../features/packs/presentation/screens/marketplace_screen.dart';
// // // // // // // // // // // // import '../../features/profile/presentation/screens/profile_screen.dart';
// // // // // // // // // // // // import '../../features/profile/presentation/screens/edit_profile_screen.dart';
// // // // // // // // // // // // import '../../features/profile/presentation/screens/change_username_screen.dart';
// // // // // // // // // // // // import '../../features/settings/presentation/settings_screen.dart';
// // // // // // // // // // // // import '../../features/offline/presentation/screens/offline_game_screen.dart';
// // // // // // // // // // // // import '../../features/games/engine/base_game_engine.dart';
// // // // // // // // // // // // import '../../features/games/truth_or_dare/presentation/screens/tod_game_screen.dart';
// // // // // // // // // // // // import '../../features/packs/presentation/screens/pack_detail_screen.dart';
// // // // // // // // // // // // import '../../features/wallet/presentation/screens/wallet_home_screen.dart';
// // // // // // // // // // // // import '../../features/friends/presentation/screens/friends_screen.dart';
// // // // // // // // // // // // import '../../features/friends/presentation/screens/user_profile_screen.dart';
// // // // // // // // // // // // import '../../features/notifications/presentation/screens/notifications_screen.dart';
// // // // // // // // // // // // import '../../features/packs/presentation/screens/creator_dashboard_screen.dart';
// // // // // // // // // // // // import '../../features/packs/presentation/screens/create_pack_screen.dart';
// // // // // // // // // // // // import '../../shared/screens/home_shell_screen.dart';
// // // // // // // // // // // // import '../../shared/screens/not_found_screen.dart';

// // // // // // // // // // // // class AppRouter {
// // // // // // // // // // // //   AppRouter._();

// // // // // // // // // // // //   static final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
// // // // // // // // // // // //   static final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

// // // // // // // // // // // //   // Holds the last created router so services can navigate imperatively.
// // // // // // // // // // // //   static GoRouter? _instance;
// // // // // // // // // // // //   static GoRouter get router {
// // // // // // // // // // // //     assert(
// // // // // // // // // // // //       _instance != null,
// // // // // // // // // // // //       'AppRouter.router accessed before createRouter() was called.',
// // // // // // // // // // // //     );
// // // // // // // // // // // //     return _instance!;
// // // // // // // // // // // //   }

// // // // // // // // // // // //   /// Call once from app.dart, passing AuthProvider as the listenable.
// // // // // // // // // // // //   /// GoRouter re-evaluates redirect() every time AuthProvider notifies.
// // // // // // // // // // // //   static GoRouter createRouter(AuthProvider authProvider) {
// // // // // // // // // // // //     _instance = GoRouter(
// // // // // // // // // // // //       navigatorKey: _rootKey,
// // // // // // // // // // // //       initialLocation: RouteNames.splash,
// // // // // // // // // // // //       debugLogDiagnostics: false,
// // // // // // // // // // // //       refreshListenable: authProvider,
// // // // // // // // // // // //       // redirect: (context, state) {
// // // // // // // // // // // //       //   final auth = context.read<AuthProvider>();
// // // // // // // // // // // //       //   final loc = state.uri.toString();
// // // // // // // // // // // //       //   print(
// // // // // // // // // // // //       //     'Redirect: loc=$loc, isGuest=${auth.isGuest}, isLoggedIn=${auth.isLoggedIn}',
// // // // // // // // // // // //       //   );
// // // // // // // // // // // //       //   final alwaysPublic = [
// // // // // // // // // // // //       //     RouteNames.splash,
// // // // // // // // // // // //       //     RouteNames.authEmail,
// // // // // // // // // // // //       //     RouteNames.authOtp,
// // // // // // // // // // // //       //   ];
// // // // // // // // // // // //       //   final isPublic = alwaysPublic.any((r) => loc.startsWith(r));

// // // // // // // // // // // //       //   // Still initializing — hold on splash
// // // // // // // // // // // //       //   if (auth.isInitializing) {
// // // // // // // // // // // //       //     return loc == RouteNames.splash ? null : RouteNames.splash;
// // // // // // // // // // // //       //   }

// // // // // // // // // // // //       //   // Done initializing — splash must redirect regardless
// // // // // // // // // // // //       //   if (loc == RouteNames.splash) {
// // // // // // // // // // // //       //     if (auth.isGuest) return RouteNames.offline;
// // // // // // // // // // // //       //     if (!auth.isLoggedIn) return RouteNames.authEmail;
// // // // // // // // // // // //       //     if (auth.needsOnboarding) return RouteNames.onboarding;
// // // // // // // // // // // //       //     return RouteNames.home;
// // // // // // // // // // // //       //   }

// // // // // // // // // // // //       //   // Guest mode: only offline screen allowed
// // // // // // // // // // // //       //   if (auth.isGuest) {
// // // // // // // // // // // //       //     return loc.startsWith(RouteNames.offline) ? null : RouteNames.offline;
// // // // // // // // // // // //       //   }

// // // // // // // // // // // //       //   // Not logged in — force to email entry
// // // // // // // // // // // //       //   if (!auth.isLoggedIn && !isPublic) {
// // // // // // // // // // // //       //     return RouteNames.authEmail;
// // // // // // // // // // // //       //   }

// // // // // // // // // // // //       //   // Logged in, profile incomplete — force onboarding
// // // // // // // // // // // //       //   if (auth.isLoggedIn &&
// // // // // // // // // // // //       //       auth.needsOnboarding &&
// // // // // // // // // // // //       //       loc != RouteNames.onboarding) {
// // // // // // // // // // // //       //     return RouteNames.onboarding;
// // // // // // // // // // // //       //   }

// // // // // // // // // // // //       //   // Logged in, onboarded, on an auth screen — send home
// // // // // // // // // // // //       //   if (auth.isLoggedIn &&
// // // // // // // // // // // //       //       !auth.needsOnboarding &&
// // // // // // // // // // // //       //       isPublic &&
// // // // // // // // // // // //       //       loc != RouteNames.splash) {
// // // // // // // // // // // //       //     return RouteNames.home;
// // // // // // // // // // // //       //   }

// // // // // // // // // // // //       //   return null; // No redirect needed
// // // // // // // // // // // //       // },
// // // // // // // // // // // //       redirect: (context, state) {
// // // // // // // // // // // //         final auth = context.read<AuthProvider>();
// // // // // // // // // // // //         final loc = state.uri.toString();
// // // // // // // // // // // //         print(
// // // // // // // // // // // //           '🔁 REDIRECT: loc=$loc, isInitializing=${auth.isInitializing}, isGuest=${auth.isGuest}, isLoggedIn=${auth.isLoggedIn}, needsOnboarding=${auth.needsOnboarding}',
// // // // // // // // // // // //         );

// // // // // // // // // // // //         final alwaysPublic = [
// // // // // // // // // // // //           RouteNames.splash,
// // // // // // // // // // // //           RouteNames.authEmail,
// // // // // // // // // // // //           RouteNames.authOtp,
// // // // // // // // // // // //         ];
// // // // // // // // // // // //         final isPublic = alwaysPublic.any((r) => loc.startsWith(r));
// // // // // // // // // // // //         print('   isPublic=$isPublic');

// // // // // // // // // // // //         if (auth.isInitializing) {
// // // // // // // // // // // //           print('   → initializing, go to splash if needed');
// // // // // // // // // // // //           return loc == RouteNames.splash ? null : RouteNames.splash;
// // // // // // // // // // // //         }

// // // // // // // // // // // //         if (loc == RouteNames.splash) {
// // // // // // // // // // // //           if (auth.isGuest) {
// // // // // // // // // // // //             print('   → splash guest → offline');
// // // // // // // // // // // //             return RouteNames.offline;
// // // // // // // // // // // //           }
// // // // // // // // // // // //           if (!auth.isLoggedIn) {
// // // // // // // // // // // //             print('   → splash not logged in → authEmail');
// // // // // // // // // // // //             return RouteNames.authEmail;
// // // // // // // // // // // //           }
// // // // // // // // // // // //           if (auth.needsOnboarding) {
// // // // // // // // // // // //             print('   → splash needs onboarding → onboarding');
// // // // // // // // // // // //             return RouteNames.onboarding;
// // // // // // // // // // // //           }
// // // // // // // // // // // //           print('   → splash logged in → home');
// // // // // // // // // // // //           return RouteNames.home;
// // // // // // // // // // // //         }

// // // // // // // // // // // //         if (auth.isGuest) {
// // // // // // // // // // // //           if (loc.startsWith(RouteNames.offline)) {
// // // // // // // // // // // //             print('   → guest on offline, stay');
// // // // // // // // // // // //             return null;
// // // // // // // // // // // //           }
// // // // // // // // // // // //           print('   → guest not on offline → offline');
// // // // // // // // // // // //           return RouteNames.offline;
// // // // // // // // // // // //         }

// // // // // // // // // // // //         if (!auth.isLoggedIn && !isPublic) {
// // // // // // // // // // // //           print('   → not logged in & not public → authEmail');
// // // // // // // // // // // //           return RouteNames.authEmail;
// // // // // // // // // // // //         }

// // // // // // // // // // // //         if (auth.isLoggedIn &&
// // // // // // // // // // // //             auth.needsOnboarding &&
// // // // // // // // // // // //             loc != RouteNames.onboarding) {
// // // // // // // // // // // //           print(
// // // // // // // // // // // //             '   → logged in needs onboarding not on onboarding → onboarding',
// // // // // // // // // // // //           );
// // // // // // // // // // // //           return RouteNames.onboarding;
// // // // // // // // // // // //         }

// // // // // // // // // // // //         if (auth.isLoggedIn &&
// // // // // // // // // // // //             !auth.needsOnboarding &&
// // // // // // // // // // // //             isPublic &&
// // // // // // // // // // // //             loc != RouteNames.splash) {
// // // // // // // // // // // //           print('   → logged in onboarded on public route → home');
// // // // // // // // // // // //           return RouteNames.home;
// // // // // // // // // // // //         }

// // // // // // // // // // // //         print('   → no redirect');
// // // // // // // // // // // //         return null;
// // // // // // // // // // // //       },

// // // // // // // // // // // //       routes: [
// // // // // // // // // // // //         // ── Auth ────────────────────────────────────────────────────────────
// // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // //           path: RouteNames.splash,
// // // // // // // // // // // //           builder: (_, __) => const SplashScreen(),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // //           path: RouteNames.authEmail,
// // // // // // // // // // // //           builder: (_, __) => const EmailScreen(),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // //           path: RouteNames.authOtp,
// // // // // // // // // // // //           builder: (_, state) => OtpScreen(email: state.extra as String? ?? ''),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // //           path: RouteNames.onboarding,
// // // // // // // // // // // //           builder: (_, __) => const OnboardingScreen(),
// // // // // // // // // // // //         ),

// // // // // // // // // // // //         // ── Main shell tabs ───────────────────────────────────────────────────
// // // // // // // // // // // //         ShellRoute(
// // // // // // // // // // // //           navigatorKey: _shellKey,
// // // // // // // // // // // //           builder: (_, __, child) => HomeShellScreen(child: child),
// // // // // // // // // // // //           routes: [
// // // // // // // // // // // //             GoRoute(
// // // // // // // // // // // //               path: RouteNames.home,
// // // // // // // // // // // //               builder: (_, __) => const RoomBrowserScreen(),
// // // // // // // // // // // //             ),
// // // // // // // // // // // //             GoRoute(
// // // // // // // // // // // //               path: RouteNames.friends,
// // // // // // // // // // // //               builder: (_, __) => const FriendsScreen(),
// // // // // // // // // // // //             ),
// // // // // // // // // // // //             GoRoute(
// // // // // // // // // // // //               path: RouteNames.marketplace,
// // // // // // // // // // // //               builder: (_, __) => const MarketplaceScreen(),
// // // // // // // // // // // //               routes: [
// // // // // // // // // // // //                 GoRoute(
// // // // // // // // // // // //                   path: 'pack/:packId',
// // // // // // // // // // // //                   name: RouteNames.packDetail,
// // // // // // // // // // // //                   parentNavigatorKey: _rootKey,
// // // // // // // // // // // //                   builder: (_, state) =>
// // // // // // // // // // // //                       _Placeholder('Pack: ${state.pathParameters["packId"]}'),
// // // // // // // // // // // //                 ),
// // // // // // // // // // // //               ],
// // // // // // // // // // // //             ),
// // // // // // // // // // // //             GoRoute(
// // // // // // // // // // // //               path: RouteNames.profile,
// // // // // // // // // // // //               builder: (_, __) => const ProfileScreen(),
// // // // // // // // // // // //             ),
// // // // // // // // // // // //           ],
// // // // // // // // // // // //         ),

// // // // // // // // // // // //         // ── Room — full-screen above shell ────────────────────────────────────
// // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // //           path: '/home/room/:roomId',
// // // // // // // // // // // //           name: RouteNames.room,
// // // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // // //           builder: (_, state) =>
// // // // // // // // // // // //               LobbyScreen(roomId: state.pathParameters['roomId']!),
// // // // // // // // // // // //           routes: [
// // // // // // // // // // // //             GoRoute(
// // // // // // // // // // // //               path: 'game',
// // // // // // // // // // // //               name: 'game',
// // // // // // // // // // // //               parentNavigatorKey: _rootKey,
// // // // // // // // // // // //               builder: (_, state) {
// // // // // // // // // // // //                 final extra = state.extra as Map<String, dynamic>? ?? {};
// // // // // // // // // // // //                 final config =
// // // // // // // // // // // //                     extra['config'] as GameConfig? ??
// // // // // // // // // // // //                     const GameConfig(
// // // // // // // // // // // //                       maxRounds: 10,
// // // // // // // // // // // //                       turnTimerSeconds: 60,
// // // // // // // // // // // //                       allowSkip: true,
// // // // // // // // // // // //                       allowSpicy: false,
// // // // // // // // // // // //                     );
// // // // // // // // // // // //                 return TodGameScreen(
// // // // // // // // // // // //                   roomId: state.pathParameters['roomId']!,
// // // // // // // // // // // //                   config: config,
// // // // // // // // // // // //                   playerIds:
// // // // // // // // // // // //                       (extra['playerIds'] as List?)?.cast<String>() ?? [],
// // // // // // // // // // // //                   playerDisplayNames:
// // // // // // // // // // // //                       (extra['displayNames'] as Map?)?.cast<String, String>() ??
// // // // // // // // // // // //                       {},
// // // // // // // // // // // //                   packId: extra['packId'] as String? ?? '',
// // // // // // // // // // // //                   isOwner: extra['isOwner'] as bool? ?? false,
// // // // // // // // // // // //                   isModerator: extra['isModerator'] as bool? ?? false,
// // // // // // // // // // // //                   sessionId: extra['sessionId'] as String?,
// // // // // // // // // // // //                 );
// // // // // // // // // // // //               },
// // // // // // // // // // // //             ),
// // // // // // // // // // // //           ],
// // // // // // // // // // // //         ),

// // // // // // // // // // // //         // ── Full-screen routes (above shell) ─────────────────────────────────
// // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // //           path: '/profile/edit',
// // // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // // //           builder: (_, __) => const EditProfileScreen(),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // //           path: '/profile/change-username',
// // // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // // //           builder: (_, __) => const ChangeUsernameScreen(),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // //           path: RouteNames.wallet,
// // // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // // //           builder: (_, __) => const WalletHomeScreen(),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // //           path: RouteNames.notifications,
// // // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // // //           builder: (_, __) => const NotificationsScreen(),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // //           path: '/creator',
// // // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // // //           builder: (_, __) => const CreatorDashboardScreen(),
// // // // // // // // // // // //           routes: [
// // // // // // // // // // // //             GoRoute(
// // // // // // // // // // // //               path: 'create-pack',
// // // // // // // // // // // //               builder: (_, __) => const CreatePackScreen(),
// // // // // // // // // // // //             ),
// // // // // // // // // // // //           ],
// // // // // // // // // // // //         ),
// // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // //           path: RouteNames.settings,
// // // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // // //           builder: (_, __) => const SettingsScreen(),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //         GoRoute(
// // // // // // // // // // // //           path: RouteNames.offline,
// // // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // // //           builder: (_, __) => const OfflineGameScreen(),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //       ],

// // // // // // // // // // // //       errorBuilder: (_, state) => NotFoundScreen(error: state.error),
// // // // // // // // // // // //     );
// // // // // // // // // // // //     return _instance!;
// // // // // // // // // // // //   }
// // // // // // // // // // // // }

// // // // // // // // // // // // class _Placeholder extends StatelessWidget {
// // // // // // // // // // // //   const _Placeholder(this.label);
// // // // // // // // // // // //   final String label;

// // // // // // // // // // // //   @override
// // // // // // // // // // // //   Widget build(BuildContext context) => Scaffold(
// // // // // // // // // // // //     appBar: AppBar(title: Text(label)),
// // // // // // // // // // // //     body: Center(
// // // // // // // // // // // //       child: Text(label, style: Theme.of(context).textTheme.headlineMedium),
// // // // // // // // // // // //     ),
// // // // // // // // // // // //   );
// // // // // // // // // // // // }

// // // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // // // // import '../providers/auth_provider.dart';
// // // // // // // // // // // import 'route_names.dart';
// // // // // // // // // // // import '../../features/auth/presentation/screens/splash_screen.dart';
// // // // // // // // // // // import '../../features/auth/presentation/screens/email_screen.dart';
// // // // // // // // // // // import '../../features/auth/presentation/screens/otp_screen.dart';
// // // // // // // // // // // import '../../features/auth/presentation/screens/onboarding_screen.dart';
// // // // // // // // // // // import '../../features/rooms/presentation/screens/room_browser_screen.dart';
// // // // // // // // // // // import '../../features/rooms/presentation/screens/lobby_screen.dart';
// // // // // // // // // // // import '../../features/packs/presentation/screens/marketplace_screen.dart';
// // // // // // // // // // // import '../../features/profile/presentation/screens/profile_screen.dart';
// // // // // // // // // // // import '../../features/profile/presentation/screens/edit_profile_screen.dart';
// // // // // // // // // // // import '../../features/profile/presentation/screens/change_username_screen.dart';
// // // // // // // // // // // import '../../features/settings/presentation/settings_screen.dart';
// // // // // // // // // // // import '../../features/offline/presentation/screens/offline_game_screen.dart';
// // // // // // // // // // // import '../../features/games/engine/base_game_engine.dart';
// // // // // // // // // // // import '../../features/games/truth_or_dare/presentation/screens/tod_game_screen.dart';
// // // // // // // // // // // import '../../features/packs/presentation/screens/pack_detail_screen.dart';
// // // // // // // // // // // import '../../features/wallet/presentation/screens/wallet_home_screen.dart';
// // // // // // // // // // // import '../../features/friends/presentation/screens/friends_screen.dart';
// // // // // // // // // // // import '../../features/friends/presentation/screens/user_profile_screen.dart';
// // // // // // // // // // // import '../../features/notifications/presentation/screens/notifications_screen.dart';
// // // // // // // // // // // import '../../features/packs/presentation/screens/creator_dashboard_screen.dart';
// // // // // // // // // // // import '../../features/packs/presentation/screens/create_pack_screen.dart';
// // // // // // // // // // // import '../../shared/screens/home_shell_screen.dart';
// // // // // // // // // // // import '../../shared/screens/not_found_screen.dart';

// // // // // // // // // // // class AppRouter {
// // // // // // // // // // //   AppRouter._();

// // // // // // // // // // //   static final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
// // // // // // // // // // //   static final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

// // // // // // // // // // //   // Holds the last created router so services can navigate imperatively.
// // // // // // // // // // //   static GoRouter? _instance;
// // // // // // // // // // //   static GoRouter get router {
// // // // // // // // // // //     assert(
// // // // // // // // // // //       _instance != null,
// // // // // // // // // // //       'AppRouter.router accessed before createRouter() was called.',
// // // // // // // // // // //     );
// // // // // // // // // // //     return _instance!;
// // // // // // // // // // //   }

// // // // // // // // // // //   /// Call once from app.dart, passing AuthProvider as the listenable.
// // // // // // // // // // //   /// GoRouter re-evaluates redirect() every time AuthProvider notifies.
// // // // // // // // // // //   static GoRouter createRouter(AuthProvider authProvider) {
// // // // // // // // // // //     _instance = GoRouter(
// // // // // // // // // // //       navigatorKey: _rootKey,
// // // // // // // // // // //       initialLocation: RouteNames.splash,
// // // // // // // // // // //       debugLogDiagnostics: true,
// // // // // // // // // // //       refreshListenable: authProvider,
// // // // // // // // // // //       redirect: (context, state) {
// // // // // // // // // // //         final auth = context.read<AuthProvider>();
// // // // // // // // // // //         final loc = state.uri.toString();

// // // // // // // // // // //         final alwaysPublic = [
// // // // // // // // // // //           RouteNames.splash,
// // // // // // // // // // //           RouteNames.authEmail,
// // // // // // // // // // //           RouteNames.authOtp,
// // // // // // // // // // //         ];
// // // // // // // // // // //         final isPublic = alwaysPublic.any((r) => loc.startsWith(r));

// // // // // // // // // // //         // Still initializing — hold on splash
// // // // // // // // // // //         if (auth.isInitializing) {
// // // // // // // // // // //           return loc == RouteNames.splash ? null : RouteNames.splash;
// // // // // // // // // // //         }

// // // // // // // // // // //         // Done initializing — splash must redirect regardless
// // // // // // // // // // //         if (loc == RouteNames.splash) {
// // // // // // // // // // //           if (auth.isGuest) return RouteNames.offline;
// // // // // // // // // // //           if (!auth.isLoggedIn) return RouteNames.authEmail;
// // // // // // // // // // //           if (auth.needsOnboarding) return RouteNames.onboarding;
// // // // // // // // // // //           return RouteNames.home;
// // // // // // // // // // //         }

// // // // // // // // // // //         // Guest mode: only offline screen allowed
// // // // // // // // // // //         if (auth.isGuest) {
// // // // // // // // // // //           return loc.startsWith(RouteNames.offline) ? null : RouteNames.offline;
// // // // // // // // // // //         }

// // // // // // // // // // //         // Not logged in — force to email entry
// // // // // // // // // // //         if (!auth.isLoggedIn && !isPublic) {
// // // // // // // // // // //           return RouteNames.authEmail;
// // // // // // // // // // //         }

// // // // // // // // // // //         // Logged in, profile incomplete — force onboarding
// // // // // // // // // // //         if (auth.isLoggedIn &&
// // // // // // // // // // //             auth.needsOnboarding &&
// // // // // // // // // // //             loc != RouteNames.onboarding) {
// // // // // // // // // // //           return RouteNames.onboarding;
// // // // // // // // // // //         }

// // // // // // // // // // //         // Logged in, onboarded, on an auth screen — send home
// // // // // // // // // // //         if (auth.isLoggedIn &&
// // // // // // // // // // //             !auth.needsOnboarding &&
// // // // // // // // // // //             isPublic &&
// // // // // // // // // // //             loc != RouteNames.splash) {
// // // // // // // // // // //           return RouteNames.home;
// // // // // // // // // // //         }

// // // // // // // // // // //         return null; // No redirect needed
// // // // // // // // // // //       },

// // // // // // // // // // //       routes: [
// // // // // // // // // // //         // ── Auth ────────────────────────────────────────────────────────────
// // // // // // // // // // //         GoRoute(
// // // // // // // // // // //           path: RouteNames.splash,
// // // // // // // // // // //           builder: (_, __) => const SplashScreen(),
// // // // // // // // // // //         ),
// // // // // // // // // // //         GoRoute(
// // // // // // // // // // //           path: RouteNames.authEmail,
// // // // // // // // // // //           builder: (_, __) => const EmailScreen(),
// // // // // // // // // // //         ),
// // // // // // // // // // //         GoRoute(
// // // // // // // // // // //           path: RouteNames.authOtp,
// // // // // // // // // // //           builder: (_, state) => OtpScreen(email: state.extra as String? ?? ''),
// // // // // // // // // // //         ),
// // // // // // // // // // //         GoRoute(
// // // // // // // // // // //           path: RouteNames.onboarding,
// // // // // // // // // // //           builder: (_, __) => const OnboardingScreen(),
// // // // // // // // // // //         ),

// // // // // // // // // // //         // ── Main shell tabs ───────────────────────────────────────────────────
// // // // // // // // // // //         ShellRoute(
// // // // // // // // // // //           navigatorKey: _shellKey,
// // // // // // // // // // //           builder: (_, __, child) => HomeShellScreen(child: child),
// // // // // // // // // // //           routes: [
// // // // // // // // // // //             GoRoute(
// // // // // // // // // // //               path: RouteNames.home,
// // // // // // // // // // //               builder: (_, __) => const RoomBrowserScreen(),
// // // // // // // // // // //             ),
// // // // // // // // // // //             GoRoute(
// // // // // // // // // // //               path: RouteNames.friends,
// // // // // // // // // // //               builder: (_, __) => const FriendsScreen(),
// // // // // // // // // // //             ),
// // // // // // // // // // //             GoRoute(
// // // // // // // // // // //               path: RouteNames.marketplace,
// // // // // // // // // // //               builder: (_, __) => const MarketplaceScreen(),
// // // // // // // // // // //               routes: [
// // // // // // // // // // //                 GoRoute(
// // // // // // // // // // //                   path: 'pack/:packId',
// // // // // // // // // // //                   name: RouteNames.packDetail,
// // // // // // // // // // //                   parentNavigatorKey: _rootKey,
// // // // // // // // // // //                   builder: (_, state) =>
// // // // // // // // // // //                       _Placeholder('Pack: ${state.pathParameters["packId"]}'),
// // // // // // // // // // //                 ),
// // // // // // // // // // //               ],
// // // // // // // // // // //             ),
// // // // // // // // // // //             GoRoute(
// // // // // // // // // // //               path: RouteNames.profile,
// // // // // // // // // // //               builder: (_, __) => const ProfileScreen(),
// // // // // // // // // // //             ),
// // // // // // // // // // //           ],
// // // // // // // // // // //         ),

// // // // // // // // // // //         // ── Room — full-screen above shell ────────────────────────────────────
// // // // // // // // // // //         GoRoute(
// // // // // // // // // // //           path: '/home/room/:roomId',
// // // // // // // // // // //           name: RouteNames.room,
// // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // //           builder: (_, state) =>
// // // // // // // // // // //               LobbyScreen(roomId: state.pathParameters['roomId']!),
// // // // // // // // // // //           routes: [
// // // // // // // // // // //             GoRoute(
// // // // // // // // // // //               path: 'game',
// // // // // // // // // // //               name: 'game',
// // // // // // // // // // //               parentNavigatorKey: _rootKey,
// // // // // // // // // // //               builder: (_, state) {
// // // // // // // // // // //                 final extra = state.extra as Map<String, dynamic>? ?? {};
// // // // // // // // // // //                 final config =
// // // // // // // // // // //                     extra['config'] as GameConfig? ??
// // // // // // // // // // //                     const GameConfig(
// // // // // // // // // // //                       maxRounds: 10,
// // // // // // // // // // //                       turnTimerSeconds: 60,
// // // // // // // // // // //                       allowSkip: true,
// // // // // // // // // // //                       allowSpicy: false,
// // // // // // // // // // //                     );
// // // // // // // // // // //                 return TodGameScreen(
// // // // // // // // // // //                   roomId: state.pathParameters['roomId']!,
// // // // // // // // // // //                   config: config,
// // // // // // // // // // //                   playerIds:
// // // // // // // // // // //                       (extra['playerIds'] as List?)?.cast<String>() ?? [],
// // // // // // // // // // //                   playerDisplayNames:
// // // // // // // // // // //                       (extra['displayNames'] as Map?)?.cast<String, String>() ??
// // // // // // // // // // //                       {},
// // // // // // // // // // //                   packId: extra['packId'] as String? ?? '',
// // // // // // // // // // //                   isOwner: extra['isOwner'] as bool? ?? false,
// // // // // // // // // // //                   isModerator: extra['isModerator'] as bool? ?? false,
// // // // // // // // // // //                   sessionId: extra['sessionId'] as String?,
// // // // // // // // // // //                 );
// // // // // // // // // // //               },
// // // // // // // // // // //             ),
// // // // // // // // // // //           ],
// // // // // // // // // // //         ),

// // // // // // // // // // //         // ── Full-screen routes (above shell) ─────────────────────────────────
// // // // // // // // // // //         GoRoute(
// // // // // // // // // // //           path: '/profile/edit',
// // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // //           builder: (_, __) => const EditProfileScreen(),
// // // // // // // // // // //         ),
// // // // // // // // // // //         GoRoute(
// // // // // // // // // // //           path: '/profile/change-username',
// // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // //           builder: (_, __) => const ChangeUsernameScreen(),
// // // // // // // // // // //         ),
// // // // // // // // // // //         GoRoute(
// // // // // // // // // // //           path: RouteNames.wallet,
// // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // //           builder: (_, __) => const WalletHomeScreen(),
// // // // // // // // // // //         ),
// // // // // // // // // // //         GoRoute(
// // // // // // // // // // //           path: RouteNames.notifications,
// // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // //           builder: (_, __) => const NotificationsScreen(),
// // // // // // // // // // //         ),
// // // // // // // // // // //         GoRoute(
// // // // // // // // // // //           path: '/creator',
// // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // //           builder: (_, __) => const CreatorDashboardScreen(),
// // // // // // // // // // //           routes: [
// // // // // // // // // // //             GoRoute(
// // // // // // // // // // //               path: 'create-pack',
// // // // // // // // // // //               builder: (_, __) => const CreatePackScreen(),
// // // // // // // // // // //             ),
// // // // // // // // // // //           ],
// // // // // // // // // // //         ),
// // // // // // // // // // //         GoRoute(
// // // // // // // // // // //           path: RouteNames.settings,
// // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // //           builder: (_, __) => const SettingsScreen(),
// // // // // // // // // // //         ),
// // // // // // // // // // //         GoRoute(
// // // // // // // // // // //           path: RouteNames.offline,
// // // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // // //           builder: (_, __) => const OfflineGameScreen(),
// // // // // // // // // // //         ),
// // // // // // // // // // //       ],

// // // // // // // // // // //       errorBuilder: (_, state) => NotFoundScreen(error: state.error),
// // // // // // // // // // //     );
// // // // // // // // // // //     return _instance!;
// // // // // // // // // // //   }
// // // // // // // // // // // }

// // // // // // // // // // // class _Placeholder extends StatelessWidget {
// // // // // // // // // // //   const _Placeholder(this.label);
// // // // // // // // // // //   final String label;

// // // // // // // // // // //   @override
// // // // // // // // // // //   Widget build(BuildContext context) => Scaffold(
// // // // // // // // // // //     appBar: AppBar(title: Text(label)),
// // // // // // // // // // //     body: Center(
// // // // // // // // // // //       child: Text(label, style: Theme.of(context).textTheme.headlineMedium),
// // // // // // // // // // //     ),
// // // // // // // // // // //   );
// // // // // // // // // // // }

// // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // // // import '../providers/auth_provider.dart';
// // // // // // // // // // import 'route_names.dart';
// // // // // // // // // // import '../../features/auth/presentation/screens/splash_screen.dart';
// // // // // // // // // // import '../../features/auth/presentation/screens/email_screen.dart';
// // // // // // // // // // import '../../features/auth/presentation/screens/otp_screen.dart';
// // // // // // // // // // import '../../features/auth/presentation/screens/onboarding_screen.dart';
// // // // // // // // // // import '../../features/rooms/presentation/screens/room_browser_screen.dart';
// // // // // // // // // // import '../../features/rooms/presentation/screens/lobby_screen.dart';
// // // // // // // // // // import '../../features/packs/presentation/screens/marketplace_screen.dart';
// // // // // // // // // // import '../../features/profile/presentation/screens/profile_screen.dart';
// // // // // // // // // // import '../../features/profile/presentation/screens/edit_profile_screen.dart';
// // // // // // // // // // import '../../features/profile/presentation/screens/change_username_screen.dart';
// // // // // // // // // // import '../../features/settings/presentation/settings_screen.dart';
// // // // // // // // // // import '../../features/offline/presentation/screens/offline_game_screen.dart';
// // // // // // // // // // import '../../features/games/engine/base_game_engine.dart';
// // // // // // // // // // import '../../features/games/truth_or_dare/presentation/screens/tod_game_screen.dart';
// // // // // // // // // // import '../../features/packs/presentation/screens/pack_detail_screen.dart';
// // // // // // // // // // import '../../features/wallet/presentation/screens/wallet_home_screen.dart';
// // // // // // // // // // import '../../features/friends/presentation/screens/friends_screen.dart';
// // // // // // // // // // import '../../features/friends/presentation/screens/user_profile_screen.dart';
// // // // // // // // // // import '../../features/notifications/presentation/screens/notifications_screen.dart';
// // // // // // // // // // import '../../features/packs/presentation/screens/creator_dashboard_screen.dart';
// // // // // // // // // // import '../../features/packs/presentation/screens/create_pack_screen.dart';
// // // // // // // // // // import '../../shared/screens/home_shell_screen.dart';
// // // // // // // // // // import '../../shared/screens/not_found_screen.dart';

// // // // // // // // // // class AppRouter {
// // // // // // // // // //   AppRouter._();

// // // // // // // // // //   static final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
// // // // // // // // // //   static final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

// // // // // // // // // //   // Holds the last created router so services can navigate imperatively.
// // // // // // // // // //   static GoRouter? _instance;
// // // // // // // // // //   static GoRouter get router {
// // // // // // // // // //     assert(
// // // // // // // // // //       _instance != null,
// // // // // // // // // //       'AppRouter.router accessed before createRouter() was called.',
// // // // // // // // // //     );
// // // // // // // // // //     return _instance!;
// // // // // // // // // //   }

// // // // // // // // // //   /// Call once from app.dart, passing AuthProvider as the listenable.
// // // // // // // // // //   /// GoRouter re-evaluates redirect() every time AuthProvider notifies.
// // // // // // // // // //   static GoRouter createRouter(AuthProvider authProvider) {
// // // // // // // // // //     _instance = GoRouter(
// // // // // // // // // //       navigatorKey: _rootKey,
// // // // // // // // // //       initialLocation: RouteNames.splash,
// // // // // // // // // //       debugLogDiagnostics: true,
// // // // // // // // // //       refreshListenable: authProvider,
// // // // // // // // // //       redirect: (context, state) {
// // // // // // // // // //         final auth = context.read<AuthProvider>();
// // // // // // // // // //         final loc = state.uri.toString();

// // // // // // // // // //         final alwaysPublic = [
// // // // // // // // // //           RouteNames.splash,
// // // // // // // // // //           RouteNames.authEmail,
// // // // // // // // // //           RouteNames.authOtp,
// // // // // // // // // //         ];
// // // // // // // // // //         final isPublic = alwaysPublic.any((r) => loc.startsWith(r));

// // // // // // // // // //         // Still initializing — hold on splash
// // // // // // // // // //         if (auth.isInitializing) {
// // // // // // // // // //           return loc == RouteNames.splash ? null : RouteNames.splash;
// // // // // // // // // //         }

// // // // // // // // // //         // Done initializing — splash must redirect regardless
// // // // // // // // // //         if (loc == RouteNames.splash) {
// // // // // // // // // //           if (auth.isGuest) return RouteNames.offline;
// // // // // // // // // //           if (!auth.isLoggedIn) return RouteNames.authEmail;
// // // // // // // // // //           if (auth.needsOnboarding) return RouteNames.onboarding;
// // // // // // // // // //           return RouteNames.home;
// // // // // // // // // //         }

// // // // // // // // // //         // Guest mode: only offline screen allowed
// // // // // // // // // //         if (auth.isGuest) {
// // // // // // // // // //           return loc.startsWith(RouteNames.offline) ? null : RouteNames.offline;
// // // // // // // // // //         }

// // // // // // // // // //         // Not logged in — force to email entry
// // // // // // // // // //         if (!auth.isLoggedIn && !isPublic) {
// // // // // // // // // //           return RouteNames.authEmail;
// // // // // // // // // //         }

// // // // // // // // // //         // Logged in, profile incomplete — force onboarding only from auth/splash screens
// // // // // // // // // //         // Don't redirect from within the app (e.g. /home/room/...) to avoid
// // // // // // // // // //         // breaking navigation while profile is still loading
// // // // // // // // // //         if (auth.isLoggedIn &&
// // // // // // // // // //             auth.needsOnboarding &&
// // // // // // // // // //             (isPublic || loc == RouteNames.home) &&
// // // // // // // // // //             loc != RouteNames.onboarding) {
// // // // // // // // // //           return RouteNames.onboarding;
// // // // // // // // // //         }

// // // // // // // // // //         // Logged in, onboarded, on an auth screen — send home
// // // // // // // // // //         if (auth.isLoggedIn &&
// // // // // // // // // //             !auth.needsOnboarding &&
// // // // // // // // // //             isPublic &&
// // // // // // // // // //             loc != RouteNames.splash) {
// // // // // // // // // //           return RouteNames.home;
// // // // // // // // // //         }

// // // // // // // // // //         return null; // No redirect needed
// // // // // // // // // //       },

// // // // // // // // // //       routes: [
// // // // // // // // // //         // ── Auth ────────────────────────────────────────────────────────────
// // // // // // // // // //         GoRoute(
// // // // // // // // // //           path: RouteNames.splash,
// // // // // // // // // //           builder: (_, __) => const SplashScreen(),
// // // // // // // // // //         ),
// // // // // // // // // //         GoRoute(
// // // // // // // // // //           path: RouteNames.authEmail,
// // // // // // // // // //           builder: (_, __) => const EmailScreen(),
// // // // // // // // // //         ),
// // // // // // // // // //         GoRoute(
// // // // // // // // // //           path: RouteNames.authOtp,
// // // // // // // // // //           builder: (_, state) => OtpScreen(email: state.extra as String? ?? ''),
// // // // // // // // // //         ),
// // // // // // // // // //         GoRoute(
// // // // // // // // // //           path: RouteNames.onboarding,
// // // // // // // // // //           builder: (_, __) => const OnboardingScreen(),
// // // // // // // // // //         ),

// // // // // // // // // //         // ── Main shell tabs ───────────────────────────────────────────────────
// // // // // // // // // //         ShellRoute(
// // // // // // // // // //           navigatorKey: _shellKey,
// // // // // // // // // //           builder: (_, __, child) => HomeShellScreen(child: child),
// // // // // // // // // //           routes: [
// // // // // // // // // //             GoRoute(
// // // // // // // // // //               path: RouteNames.home,
// // // // // // // // // //               builder: (_, __) => const RoomBrowserScreen(),
// // // // // // // // // //             ),
// // // // // // // // // //             GoRoute(
// // // // // // // // // //               path: RouteNames.friends,
// // // // // // // // // //               builder: (_, __) => const FriendsScreen(),
// // // // // // // // // //             ),
// // // // // // // // // //             GoRoute(
// // // // // // // // // //               path: RouteNames.marketplace,
// // // // // // // // // //               builder: (_, __) => const MarketplaceScreen(),
// // // // // // // // // //               routes: [
// // // // // // // // // //                 GoRoute(
// // // // // // // // // //                   path: 'pack/:packId',
// // // // // // // // // //                   name: RouteNames.packDetail,
// // // // // // // // // //                   parentNavigatorKey: _rootKey,
// // // // // // // // // //                   builder: (_, state) =>
// // // // // // // // // //                       _Placeholder('Pack: ${state.pathParameters["packId"]}'),
// // // // // // // // // //                 ),
// // // // // // // // // //               ],
// // // // // // // // // //             ),
// // // // // // // // // //             GoRoute(
// // // // // // // // // //               path: RouteNames.profile,
// // // // // // // // // //               builder: (_, __) => const ProfileScreen(),
// // // // // // // // // //             ),
// // // // // // // // // //           ],
// // // // // // // // // //         ),

// // // // // // // // // //         // ── Room — full-screen above shell ────────────────────────────────────
// // // // // // // // // //         GoRoute(
// // // // // // // // // //           path: '/home/room/:roomId',
// // // // // // // // // //           name: RouteNames.room,
// // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // //           builder: (_, state) =>
// // // // // // // // // //               LobbyScreen(roomId: state.pathParameters['roomId']!),
// // // // // // // // // //           routes: [
// // // // // // // // // //             GoRoute(
// // // // // // // // // //               path: 'game',
// // // // // // // // // //               name: 'game',
// // // // // // // // // //               parentNavigatorKey: _rootKey,
// // // // // // // // // //               builder: (_, state) {
// // // // // // // // // //                 final extra = state.extra as Map<String, dynamic>? ?? {};
// // // // // // // // // //                 final config =
// // // // // // // // // //                     extra['config'] as GameConfig? ??
// // // // // // // // // //                     const GameConfig(
// // // // // // // // // //                       maxRounds: 10,
// // // // // // // // // //                       turnTimerSeconds: 60,
// // // // // // // // // //                       allowSkip: true,
// // // // // // // // // //                       allowSpicy: false,
// // // // // // // // // //                     );
// // // // // // // // // //                 return TodGameScreen(
// // // // // // // // // //                   roomId: state.pathParameters['roomId']!,
// // // // // // // // // //                   config: config,
// // // // // // // // // //                   playerIds:
// // // // // // // // // //                       (extra['playerIds'] as List?)?.cast<String>() ?? [],
// // // // // // // // // //                   playerDisplayNames:
// // // // // // // // // //                       (extra['displayNames'] as Map?)?.cast<String, String>() ??
// // // // // // // // // //                       {},
// // // // // // // // // //                   packId: extra['packId'] as String? ?? '',
// // // // // // // // // //                   isOwner: extra['isOwner'] as bool? ?? false,
// // // // // // // // // //                   isModerator: extra['isModerator'] as bool? ?? false,
// // // // // // // // // //                   sessionId: extra['sessionId'] as String?,
// // // // // // // // // //                 );
// // // // // // // // // //               },
// // // // // // // // // //             ),
// // // // // // // // // //           ],
// // // // // // // // // //         ),

// // // // // // // // // //         // ── Full-screen routes (above shell) ─────────────────────────────────
// // // // // // // // // //         GoRoute(
// // // // // // // // // //           path: '/profile/edit',
// // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // //           builder: (_, __) => const EditProfileScreen(),
// // // // // // // // // //         ),
// // // // // // // // // //         GoRoute(
// // // // // // // // // //           path: '/profile/change-username',
// // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // //           builder: (_, __) => const ChangeUsernameScreen(),
// // // // // // // // // //         ),
// // // // // // // // // //         GoRoute(
// // // // // // // // // //           path: RouteNames.wallet,
// // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // //           builder: (_, __) => const WalletHomeScreen(),
// // // // // // // // // //         ),
// // // // // // // // // //         GoRoute(
// // // // // // // // // //           path: RouteNames.notifications,
// // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // //           builder: (_, __) => const NotificationsScreen(),
// // // // // // // // // //         ),
// // // // // // // // // //         GoRoute(
// // // // // // // // // //           path: '/creator',
// // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // //           builder: (_, __) => const CreatorDashboardScreen(),
// // // // // // // // // //           routes: [
// // // // // // // // // //             GoRoute(
// // // // // // // // // //               path: 'create-pack',
// // // // // // // // // //               builder: (_, __) => const CreatePackScreen(),
// // // // // // // // // //             ),
// // // // // // // // // //           ],
// // // // // // // // // //         ),
// // // // // // // // // //         GoRoute(
// // // // // // // // // //           path: RouteNames.settings,
// // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // //           builder: (_, __) => const SettingsScreen(),
// // // // // // // // // //         ),
// // // // // // // // // //         GoRoute(
// // // // // // // // // //           path: RouteNames.offline,
// // // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // // //           builder: (_, __) => const OfflineGameScreen(),
// // // // // // // // // //         ),
// // // // // // // // // //       ],

// // // // // // // // // //       errorBuilder: (_, state) => NotFoundScreen(error: state.error),
// // // // // // // // // //     );
// // // // // // // // // //     return _instance!;
// // // // // // // // // //   }
// // // // // // // // // // }

// // // // // // // // // // class _Placeholder extends StatelessWidget {
// // // // // // // // // //   const _Placeholder(this.label);
// // // // // // // // // //   final String label;

// // // // // // // // // //   @override
// // // // // // // // // //   Widget build(BuildContext context) => Scaffold(
// // // // // // // // // //     appBar: AppBar(title: Text(label)),
// // // // // // // // // //     body: Center(
// // // // // // // // // //       child: Text(label, style: Theme.of(context).textTheme.headlineMedium),
// // // // // // // // // //     ),
// // // // // // // // // //   );
// // // // // // // // // // }

// // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // // import '../providers/auth_provider.dart';
// // // // // // // // // import 'route_names.dart';
// // // // // // // // // import '../../features/auth/presentation/screens/splash_screen.dart';
// // // // // // // // // import '../../features/auth/presentation/screens/email_screen.dart';
// // // // // // // // // import '../../features/auth/presentation/screens/otp_screen.dart';
// // // // // // // // // import '../../features/auth/presentation/screens/onboarding_screen.dart';
// // // // // // // // // import '../../features/rooms/presentation/screens/room_browser_screen.dart';
// // // // // // // // // import '../../features/rooms/presentation/screens/lobby_screen.dart';
// // // // // // // // // import '../../features/packs/presentation/screens/marketplace_screen.dart';
// // // // // // // // // import '../../features/profile/presentation/screens/profile_screen.dart';
// // // // // // // // // import '../../features/profile/presentation/screens/edit_profile_screen.dart';
// // // // // // // // // import '../../features/profile/presentation/screens/change_username_screen.dart';
// // // // // // // // // import '../../features/settings/presentation/settings_screen.dart';
// // // // // // // // // import '../../features/offline/presentation/screens/offline_game_screen.dart';
// // // // // // // // // import '../../features/games/engine/base_game_engine.dart';
// // // // // // // // // import '../../features/games/truth_or_dare/presentation/screens/tod_game_screen.dart';
// // // // // // // // // import '../../features/packs/presentation/screens/pack_detail_screen.dart';
// // // // // // // // // import '../../features/wallet/presentation/screens/wallet_home_screen.dart';
// // // // // // // // // import '../../features/friends/presentation/screens/friends_screen.dart';
// // // // // // // // // import '../../features/friends/presentation/screens/user_profile_screen.dart';
// // // // // // // // // import '../../features/notifications/presentation/screens/notifications_screen.dart';
// // // // // // // // // import '../../features/packs/presentation/screens/creator_dashboard_screen.dart';
// // // // // // // // // import '../../features/packs/presentation/screens/create_pack_screen.dart';
// // // // // // // // // import '../../shared/screens/home_shell_screen.dart';
// // // // // // // // // import '../../shared/screens/not_found_screen.dart';

// // // // // // // // // class AppRouter {
// // // // // // // // //   AppRouter._();

// // // // // // // // //   static final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// // // // // // // // //   // Holds the last created router so services can navigate imperatively.
// // // // // // // // //   static GoRouter? _instance;
// // // // // // // // //   static GoRouter get router {
// // // // // // // // //     assert(
// // // // // // // // //       _instance != null,
// // // // // // // // //       'AppRouter.router accessed before createRouter() was called.',
// // // // // // // // //     );
// // // // // // // // //     return _instance!;
// // // // // // // // //   }

// // // // // // // // //   /// Call once from app.dart, passing AuthProvider as the listenable.
// // // // // // // // //   /// GoRouter re-evaluates redirect() every time AuthProvider notifies.
// // // // // // // // //   static GoRouter createRouter(AuthProvider authProvider) {
// // // // // // // // //     _instance = GoRouter(
// // // // // // // // //       navigatorKey: _rootKey,
// // // // // // // // //       initialLocation: RouteNames.splash,
// // // // // // // // //       debugLogDiagnostics: true,
// // // // // // // // //       refreshListenable: authProvider,
// // // // // // // // //       // redirect: (context, state) {
// // // // // // // // //       //   final auth = context.read<AuthProvider>();
// // // // // // // // //       //   final loc = state.uri.toString();

// // // // // // // // //       //   final alwaysPublic = [
// // // // // // // // //       //     RouteNames.splash,
// // // // // // // // //       //     RouteNames.authEmail,
// // // // // // // // //       //     RouteNames.authOtp,
// // // // // // // // //       //   ];
// // // // // // // // //       //   final isPublic = alwaysPublic.any((r) => loc.startsWith(r));

// // // // // // // // //       //   // Still initializing — hold on splash
// // // // // // // // //       //   if (auth.isInitializing) {
// // // // // // // // //       //     return loc == RouteNames.splash ? null : RouteNames.splash;
// // // // // // // // //       //   }

// // // // // // // // //       //   // Done initializing — splash must redirect regardless
// // // // // // // // //       //   if (loc == RouteNames.splash) {
// // // // // // // // //       //     if (auth.isGuest) return RouteNames.offline;
// // // // // // // // //       //     if (!auth.isLoggedIn) return RouteNames.authEmail;
// // // // // // // // //       //     if (auth.needsOnboarding) return RouteNames.onboarding;
// // // // // // // // //       //     return RouteNames.home;
// // // // // // // // //       //   }

// // // // // // // // //       //   // Guest mode: only offline screen allowed
// // // // // // // // //       //   if (auth.isGuest) {
// // // // // // // // //       //     return loc.startsWith(RouteNames.offline) ? null : RouteNames.offline;
// // // // // // // // //       //   }

// // // // // // // // //       //   // Not logged in — force to email entry
// // // // // // // // //       //   if (!auth.isLoggedIn && !isPublic) {
// // // // // // // // //       //     return RouteNames.authEmail;
// // // // // // // // //       //   }

// // // // // // // // //       //   // Logged in, profile incomplete — force onboarding only from auth/splash screens
// // // // // // // // //       //   // Don't redirect from within the app (e.g. /home/room/...) to avoid
// // // // // // // // //       //   // breaking navigation while profile is still loading
// // // // // // // // //       //   if (auth.isLoggedIn &&
// // // // // // // // //       //       auth.needsOnboarding &&
// // // // // // // // //       //       (isPublic || loc == RouteNames.home) &&
// // // // // // // // //       //       loc != RouteNames.onboarding) {
// // // // // // // // //       //     return RouteNames.onboarding;
// // // // // // // // //       //   }

// // // // // // // // //       //   // Logged in, onboarded, on an auth screen — send home
// // // // // // // // //       //   if (auth.isLoggedIn &&
// // // // // // // // //       //       !auth.needsOnboarding &&
// // // // // // // // //       //       isPublic &&
// // // // // // // // //       //       loc != RouteNames.splash) {
// // // // // // // // //       //     return RouteNames.home;
// // // // // // // // //       //   }

// // // // // // // // //       //   return null; // No redirect needed
// // // // // // // // //       // },
// // // // // // // // //       redirect: (context, state) {
// // // // // // // // //         final auth = context.read<AuthProvider>();
// // // // // // // // //         final loc = state.uri.toString();

// // // // // // // // //         // --- Room routes: always allow for logged‑in users ---
// // // // // // // // //         if (loc.contains('/room/') && auth.isLoggedIn && !auth.isGuest) {
// // // // // // // // //           return null; // Stay on the room
// // // // // // // // //         }

// // // // // // // // //         // --- The rest of your existing redirect logic (unchanged) ---
// // // // // // // // //         final alwaysPublic = [
// // // // // // // // //           RouteNames.splash,
// // // // // // // // //           RouteNames.authEmail,
// // // // // // // // //           RouteNames.authOtp,
// // // // // // // // //         ];
// // // // // // // // //         final isPublic = alwaysPublic.any((r) => loc.startsWith(r));

// // // // // // // // //         if (auth.isInitializing) {
// // // // // // // // //           return loc == RouteNames.splash ? null : RouteNames.splash;
// // // // // // // // //         }

// // // // // // // // //         if (loc == RouteNames.splash) {
// // // // // // // // //           if (auth.isGuest) return RouteNames.offline;
// // // // // // // // //           if (!auth.isLoggedIn) return RouteNames.authEmail;
// // // // // // // // //           if (auth.needsOnboarding) return RouteNames.onboarding;
// // // // // // // // //           return RouteNames.home;
// // // // // // // // //         }

// // // // // // // // //         if (auth.isGuest) {
// // // // // // // // //           return loc.startsWith(RouteNames.offline) ? null : RouteNames.offline;
// // // // // // // // //         }

// // // // // // // // //         if (!auth.isLoggedIn && !isPublic) {
// // // // // // // // //           return RouteNames.authEmail;
// // // // // // // // //         }

// // // // // // // // //         if (auth.isLoggedIn &&
// // // // // // // // //             auth.needsOnboarding &&
// // // // // // // // //             (isPublic || loc == RouteNames.home) &&
// // // // // // // // //             loc != RouteNames.onboarding) {
// // // // // // // // //           return RouteNames.onboarding;
// // // // // // // // //         }

// // // // // // // // //         if (auth.isLoggedIn &&
// // // // // // // // //             !auth.needsOnboarding &&
// // // // // // // // //             isPublic &&
// // // // // // // // //             loc != RouteNames.splash) {
// // // // // // // // //           return RouteNames.home;
// // // // // // // // //         }

// // // // // // // // //         return null;
// // // // // // // // //       },
// // // // // // // // //       routes: [
// // // // // // // // //         // ── Auth ────────────────────────────────────────────────────────────
// // // // // // // // //         GoRoute(
// // // // // // // // //           path: RouteNames.splash,
// // // // // // // // //           builder: (_, __) => const SplashScreen(),
// // // // // // // // //         ),
// // // // // // // // //         GoRoute(
// // // // // // // // //           path: RouteNames.authEmail,
// // // // // // // // //           builder: (_, __) => const EmailScreen(),
// // // // // // // // //         ),
// // // // // // // // //         GoRoute(
// // // // // // // // //           path: RouteNames.authOtp,
// // // // // // // // //           builder: (_, state) => OtpScreen(email: state.extra as String? ?? ''),
// // // // // // // // //         ),
// // // // // // // // //         GoRoute(
// // // // // // // // //           path: RouteNames.onboarding,
// // // // // // // // //           builder: (_, __) => const OnboardingScreen(),
// // // // // // // // //         ),

// // // // // // // // //         // ── Main shell tabs — StatefulShellRoute keeps each tab's state ─────────
// // // // // // // // //         StatefulShellRoute.indexedStack(
// // // // // // // // //           builder: (_, __, navigationShell) =>
// // // // // // // // //               HomeShellScreen(navigationShell: navigationShell),
// // // // // // // // //           branches: [
// // // // // // // // //             StatefulShellBranch(
// // // // // // // // //               routes: [
// // // // // // // // //                 GoRoute(
// // // // // // // // //                   path: RouteNames.home,
// // // // // // // // //                   builder: (_, __) => const RoomBrowserScreen(),
// // // // // // // // //                 ),
// // // // // // // // //               ],
// // // // // // // // //             ),
// // // // // // // // //             StatefulShellBranch(
// // // // // // // // //               routes: [
// // // // // // // // //                 GoRoute(
// // // // // // // // //                   path: RouteNames.friends,
// // // // // // // // //                   builder: (_, __) => const FriendsScreen(),
// // // // // // // // //                 ),
// // // // // // // // //               ],
// // // // // // // // //             ),
// // // // // // // // //             StatefulShellBranch(
// // // // // // // // //               routes: [
// // // // // // // // //                 GoRoute(
// // // // // // // // //                   path: RouteNames.marketplace,
// // // // // // // // //                   builder: (_, __) => const MarketplaceScreen(),
// // // // // // // // //                   routes: [
// // // // // // // // //                     GoRoute(
// // // // // // // // //                       path: 'pack/:packId',
// // // // // // // // //                       name: RouteNames.packDetail,
// // // // // // // // //                       parentNavigatorKey: _rootKey,
// // // // // // // // //                       builder: (_, state) => _Placeholder(
// // // // // // // // //                         'Pack: ${state.pathParameters["packId"]}',
// // // // // // // // //                       ),
// // // // // // // // //                     ),
// // // // // // // // //                   ],
// // // // // // // // //                 ),
// // // // // // // // //               ],
// // // // // // // // //             ),
// // // // // // // // //             StatefulShellBranch(
// // // // // // // // //               routes: [
// // // // // // // // //                 GoRoute(
// // // // // // // // //                   path: RouteNames.profile,
// // // // // // // // //                   builder: (_, __) => const ProfileScreen(),
// // // // // // // // //                 ),
// // // // // // // // //               ],
// // // // // // // // //             ),
// // // // // // // // //           ],
// // // // // // // // //         ),

// // // // // // // // //         // ── Room — full-screen above shell ────────────────────────────────────
// // // // // // // // //         GoRoute(
// // // // // // // // //           path: '/home/room/:roomId',
// // // // // // // // //           name: RouteNames.room,
// // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // //           builder: (_, state) =>
// // // // // // // // //               LobbyScreen(roomId: state.pathParameters['roomId']!),
// // // // // // // // //           routes: [
// // // // // // // // //             GoRoute(
// // // // // // // // //               path: 'game',
// // // // // // // // //               name: 'game',
// // // // // // // // //               parentNavigatorKey: _rootKey,
// // // // // // // // //               builder: (_, state) {
// // // // // // // // //                 final extra = state.extra as Map<String, dynamic>? ?? {};
// // // // // // // // //                 final config =
// // // // // // // // //                     extra['config'] as GameConfig? ??
// // // // // // // // //                     const GameConfig(
// // // // // // // // //                       maxRounds: 10,
// // // // // // // // //                       turnTimerSeconds: 60,
// // // // // // // // //                       allowSkip: true,
// // // // // // // // //                       allowSpicy: false,
// // // // // // // // //                     );
// // // // // // // // //                 return TodGameScreen(
// // // // // // // // //                   roomId: state.pathParameters['roomId']!,
// // // // // // // // //                   config: config,
// // // // // // // // //                   playerIds:
// // // // // // // // //                       (extra['playerIds'] as List?)?.cast<String>() ?? [],
// // // // // // // // //                   playerDisplayNames:
// // // // // // // // //                       (extra['displayNames'] as Map?)?.cast<String, String>() ??
// // // // // // // // //                       {},
// // // // // // // // //                   packId: extra['packId'] as String? ?? '',
// // // // // // // // //                   isOwner: extra['isOwner'] as bool? ?? false,
// // // // // // // // //                   isModerator: extra['isModerator'] as bool? ?? false,
// // // // // // // // //                   sessionId: extra['sessionId'] as String?,
// // // // // // // // //                 );
// // // // // // // // //               },
// // // // // // // // //             ),
// // // // // // // // //           ],
// // // // // // // // //         ),

// // // // // // // // //         // ── Full-screen routes (above shell) ─────────────────────────────────
// // // // // // // // //         GoRoute(
// // // // // // // // //           path: '/profile/edit',
// // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // //           builder: (_, __) => const EditProfileScreen(),
// // // // // // // // //         ),
// // // // // // // // //         GoRoute(
// // // // // // // // //           path: '/profile/change-username',
// // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // //           builder: (_, __) => const ChangeUsernameScreen(),
// // // // // // // // //         ),
// // // // // // // // //         GoRoute(
// // // // // // // // //           path: RouteNames.wallet,
// // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // //           builder: (_, __) => const WalletHomeScreen(),
// // // // // // // // //         ),
// // // // // // // // //         GoRoute(
// // // // // // // // //           path: RouteNames.notifications,
// // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // //           builder: (_, __) => const NotificationsScreen(),
// // // // // // // // //         ),
// // // // // // // // //         GoRoute(
// // // // // // // // //           path: '/creator',
// // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // //           builder: (_, __) => const CreatorDashboardScreen(),
// // // // // // // // //           routes: [
// // // // // // // // //             GoRoute(
// // // // // // // // //               path: 'create-pack',
// // // // // // // // //               builder: (_, __) => const CreatePackScreen(),
// // // // // // // // //             ),
// // // // // // // // //           ],
// // // // // // // // //         ),
// // // // // // // // //         GoRoute(
// // // // // // // // //           path: RouteNames.settings,
// // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // //           builder: (_, __) => const SettingsScreen(),
// // // // // // // // //         ),
// // // // // // // // //         GoRoute(
// // // // // // // // //           path: RouteNames.offline,
// // // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // // //           builder: (_, __) => const OfflineGameScreen(),
// // // // // // // // //         ),
// // // // // // // // //       ],

// // // // // // // // //       errorBuilder: (_, state) => NotFoundScreen(error: state.error),
// // // // // // // // //     );
// // // // // // // // //     return _instance!;
// // // // // // // // //   }
// // // // // // // // // }

// // // // // // // // // class _Placeholder extends StatelessWidget {
// // // // // // // // //   const _Placeholder(this.label);
// // // // // // // // //   final String label;

// // // // // // // // //   @override
// // // // // // // // //   Widget build(BuildContext context) => Scaffold(
// // // // // // // // //     appBar: AppBar(title: Text(label)),
// // // // // // // // //     body: Center(
// // // // // // // // //       child: Text(label, style: Theme.of(context).textTheme.headlineMedium),
// // // // // // // // //     ),
// // // // // // // // //   );
// // // // // // // // // }

// // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // import '../providers/auth_provider.dart';
// // // // // // // // import 'route_names.dart';
// // // // // // // // import '../../features/auth/presentation/screens/splash_screen.dart';
// // // // // // // // import '../../features/auth/presentation/screens/email_screen.dart';
// // // // // // // // import '../../features/auth/presentation/screens/otp_screen.dart';
// // // // // // // // import '../../features/auth/presentation/screens/onboarding_screen.dart';
// // // // // // // // import '../../features/rooms/presentation/screens/room_browser_screen.dart';
// // // // // // // // import '../../features/rooms/presentation/screens/lobby_screen.dart';
// // // // // // // // import '../../features/packs/presentation/screens/marketplace_screen.dart';
// // // // // // // // import '../../features/profile/presentation/screens/profile_screen.dart';
// // // // // // // // import '../../features/profile/presentation/screens/edit_profile_screen.dart';
// // // // // // // // import '../../features/profile/presentation/screens/change_username_screen.dart';
// // // // // // // // import '../../features/settings/presentation/settings_screen.dart';
// // // // // // // // import '../../features/offline/presentation/screens/offline_game_screen.dart';
// // // // // // // // import '../../features/games/engine/base_game_engine.dart';
// // // // // // // // import '../../features/games/truth_or_dare/presentation/screens/tod_game_screen.dart';
// // // // // // // // import '../../features/packs/presentation/screens/pack_detail_screen.dart';
// // // // // // // // import '../../features/wallet/presentation/screens/wallet_home_screen.dart';
// // // // // // // // import '../../features/friends/presentation/screens/friends_screen.dart';
// // // // // // // // import '../../features/friends/presentation/screens/user_profile_screen.dart';
// // // // // // // // import '../../features/notifications/presentation/screens/notifications_screen.dart';
// // // // // // // // import '../../features/packs/presentation/screens/creator_dashboard_screen.dart';
// // // // // // // // import '../../features/packs/presentation/screens/create_pack_screen.dart';
// // // // // // // // import '../../shared/screens/home_shell_screen.dart';
// // // // // // // // import '../../shared/screens/not_found_screen.dart';

// // // // // // // // class AppRouter {
// // // // // // // //   AppRouter._();

// // // // // // // //   static final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
// // // // // // // //   static final _shellRooms = GlobalKey<NavigatorState>(debugLabel: 'rooms');
// // // // // // // //   static final _shellFriends = GlobalKey<NavigatorState>(debugLabel: 'friends');
// // // // // // // //   static final _shellPacks = GlobalKey<NavigatorState>(debugLabel: 'packs');
// // // // // // // //   static final _shellProfile = GlobalKey<NavigatorState>(debugLabel: 'profile');

// // // // // // // //   static GoRouter? _instance;
// // // // // // // //   static GoRouter get router {
// // // // // // // //     assert(
// // // // // // // //       _instance != null,
// // // // // // // //       'AppRouter.router accessed before createRouter() was called.',
// // // // // // // //     );
// // // // // // // //     return _instance!;
// // // // // // // //   }

// // // // // // // //   static GoRouter createRouter(AuthProvider authProvider) {
// // // // // // // //     _instance = GoRouter(
// // // // // // // //       navigatorKey: _rootKey,
// // // // // // // //       initialLocation: RouteNames.splash,
// // // // // // // //       debugLogDiagnostics: true,
// // // // // // // //       refreshListenable: authProvider,
// // // // // // // //       redirect: (context, state) {
// // // // // // // //         final auth = context.read<AuthProvider>();
// // // // // // // //         final loc = state.uri.toString();

// // // // // // // //         if (loc.contains('/room/') && auth.isLoggedIn && !auth.isGuest) {
// // // // // // // //           return null;
// // // // // // // //         }

// // // // // // // //         final alwaysPublic = [
// // // // // // // //           RouteNames.splash,
// // // // // // // //           RouteNames.authEmail,
// // // // // // // //           RouteNames.authOtp,
// // // // // // // //         ];
// // // // // // // //         final isPublic = alwaysPublic.any((r) => loc.startsWith(r));

// // // // // // // //         if (auth.isInitializing) {
// // // // // // // //           return loc == RouteNames.splash ? null : RouteNames.splash;
// // // // // // // //         }

// // // // // // // //         if (loc == RouteNames.splash) {
// // // // // // // //           if (auth.isGuest) return RouteNames.offline;
// // // // // // // //           if (!auth.isLoggedIn) return RouteNames.authEmail;
// // // // // // // //           if (auth.needsOnboarding) return RouteNames.onboarding;
// // // // // // // //           return RouteNames.home;
// // // // // // // //         }

// // // // // // // //         if (auth.isGuest) {
// // // // // // // //           return loc.startsWith(RouteNames.offline) ? null : RouteNames.offline;
// // // // // // // //         }

// // // // // // // //         if (!auth.isLoggedIn && !isPublic) {
// // // // // // // //           return RouteNames.authEmail;
// // // // // // // //         }

// // // // // // // //         if (auth.isLoggedIn &&
// // // // // // // //             auth.needsOnboarding &&
// // // // // // // //             (isPublic || loc == RouteNames.home) &&
// // // // // // // //             loc != RouteNames.onboarding) {
// // // // // // // //           return RouteNames.onboarding;
// // // // // // // //         }

// // // // // // // //         if (auth.isLoggedIn &&
// // // // // // // //             !auth.needsOnboarding &&
// // // // // // // //             isPublic &&
// // // // // // // //             loc != RouteNames.splash) {
// // // // // // // //           return RouteNames.home;
// // // // // // // //         }

// // // // // // // //         return null;
// // // // // // // //       },
// // // // // // // //       routes: [
// // // // // // // //         GoRoute(
// // // // // // // //           path: RouteNames.splash,
// // // // // // // //           builder: (_, __) => const SplashScreen(),
// // // // // // // //         ),
// // // // // // // //         GoRoute(
// // // // // // // //           path: RouteNames.authEmail,
// // // // // // // //           builder: (_, __) => const EmailScreen(),
// // // // // // // //         ),
// // // // // // // //         GoRoute(
// // // // // // // //           path: RouteNames.authOtp,
// // // // // // // //           builder: (_, state) => OtpScreen(email: state.extra as String? ?? ''),
// // // // // // // //         ),
// // // // // // // //         GoRoute(
// // // // // // // //           path: RouteNames.onboarding,
// // // // // // // //           builder: (_, __) => const OnboardingScreen(),
// // // // // // // //         ),

// // // // // // // //         StatefulShellRoute.indexedStack(
// // // // // // // //           builder: (_, __, navigationShell) =>
// // // // // // // //               HomeShellScreen(navigationShell: navigationShell),
// // // // // // // //           branches: [
// // // // // // // //             StatefulShellBranch(
// // // // // // // //               navigatorKey: _shellRooms,
// // // // // // // //               routes: [
// // // // // // // //                 GoRoute(
// // // // // // // //                   path: RouteNames.home,
// // // // // // // //                   builder: (_, __) => const RoomBrowserScreen(),
// // // // // // // //                 ),
// // // // // // // //               ],
// // // // // // // //             ),
// // // // // // // //             StatefulShellBranch(
// // // // // // // //               navigatorKey: _shellFriends,
// // // // // // // //               routes: [
// // // // // // // //                 GoRoute(
// // // // // // // //                   path: RouteNames.friends,
// // // // // // // //                   builder: (_, __) => const FriendsScreen(),
// // // // // // // //                 ),
// // // // // // // //               ],
// // // // // // // //             ),
// // // // // // // //             StatefulShellBranch(
// // // // // // // //               navigatorKey: _shellPacks,
// // // // // // // //               routes: [
// // // // // // // //                 GoRoute(
// // // // // // // //                   path: RouteNames.marketplace,
// // // // // // // //                   builder: (_, __) => const MarketplaceScreen(),
// // // // // // // //                   routes: [
// // // // // // // //                     GoRoute(
// // // // // // // //                       path: 'pack/:packId',
// // // // // // // //                       name: RouteNames.packDetail,
// // // // // // // //                       parentNavigatorKey: _rootKey,
// // // // // // // //                       builder: (_, state) => PackDetailScreen(
// // // // // // // //                         packId: state.pathParameters['packId']!,
// // // // // // // //                       ),
// // // // // // // //                     ),
// // // // // // // //                   ],
// // // // // // // //                 ),
// // // // // // // //               ],
// // // // // // // //             ),
// // // // // // // //             StatefulShellBranch(
// // // // // // // //               navigatorKey: _shellProfile,
// // // // // // // //               routes: [
// // // // // // // //                 GoRoute(
// // // // // // // //                   path: RouteNames.profile,
// // // // // // // //                   builder: (_, __) => const ProfileScreen(),
// // // // // // // //                 ),
// // // // // // // //               ],
// // // // // // // //             ),
// // // // // // // //           ],
// // // // // // // //         ),

// // // // // // // //         GoRoute(
// // // // // // // //           path: '/home/room/:roomId',
// // // // // // // //           name: RouteNames.room,
// // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // //           builder: (_, state) =>
// // // // // // // //               LobbyScreen(roomId: state.pathParameters['roomId']!),
// // // // // // // //           routes: [
// // // // // // // //             GoRoute(
// // // // // // // //               path: 'game',
// // // // // // // //               name: 'game',
// // // // // // // //               parentNavigatorKey: _rootKey,
// // // // // // // //               builder: (_, state) {
// // // // // // // //                 final extra = state.extra as Map<String, dynamic>? ?? {};
// // // // // // // //                 final config =
// // // // // // // //                     extra['config'] as GameConfig? ??
// // // // // // // //                     const GameConfig(
// // // // // // // //                       maxRounds: 10,
// // // // // // // //                       turnTimerSeconds: 60,
// // // // // // // //                       allowSkip: true,
// // // // // // // //                       allowSpicy: false,
// // // // // // // //                     );
// // // // // // // //                 return TodGameScreen(
// // // // // // // //                   roomId: state.pathParameters['roomId']!,
// // // // // // // //                   config: config,
// // // // // // // //                   playerIds:
// // // // // // // //                       (extra['playerIds'] as List?)?.cast<String>() ?? [],
// // // // // // // //                   playerDisplayNames:
// // // // // // // //                       (extra['displayNames'] as Map?)?.cast<String, String>() ??
// // // // // // // //                       {},
// // // // // // // //                   packId: extra['packId'] as String? ?? '',
// // // // // // // //                   isOwner: extra['isOwner'] as bool? ?? false,
// // // // // // // //                   isModerator: extra['isModerator'] as bool? ?? false,
// // // // // // // //                   sessionId: extra['sessionId'] as String?,
// // // // // // // //                 );
// // // // // // // //               },
// // // // // // // //             ),
// // // // // // // //           ],
// // // // // // // //         ),

// // // // // // // //         GoRoute(
// // // // // // // //           path: '/profile/edit',
// // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // //           builder: (_, __) => const EditProfileScreen(),
// // // // // // // //         ),
// // // // // // // //         GoRoute(
// // // // // // // //           path: '/profile/change-username',
// // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // //           builder: (_, __) => const ChangeUsernameScreen(),
// // // // // // // //         ),
// // // // // // // //         GoRoute(
// // // // // // // //           path: RouteNames.wallet,
// // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // //           builder: (_, __) => const WalletHomeScreen(),
// // // // // // // //         ),
// // // // // // // //         GoRoute(
// // // // // // // //           path: RouteNames.notifications,
// // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // //           builder: (_, __) => const NotificationsScreen(),
// // // // // // // //         ),
// // // // // // // //         GoRoute(
// // // // // // // //           path: '/creator',
// // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // //           builder: (_, __) => const CreatorDashboardScreen(),
// // // // // // // //           routes: [
// // // // // // // //             GoRoute(
// // // // // // // //               path: 'create-pack',
// // // // // // // //               builder: (_, __) => const CreatePackScreen(),
// // // // // // // //             ),
// // // // // // // //           ],
// // // // // // // //         ),
// // // // // // // //         GoRoute(
// // // // // // // //           path: RouteNames.settings,
// // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // //           builder: (_, __) => const SettingsScreen(),
// // // // // // // //         ),
// // // // // // // //         GoRoute(
// // // // // // // //           path: RouteNames.offline,
// // // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // // //           builder: (_, __) => const OfflineGameScreen(),
// // // // // // // //         ),
// // // // // // // //       ],

// // // // // // // //       errorBuilder: (_, state) => NotFoundScreen(error: state.error),
// // // // // // // //     );
// // // // // // // //     return _instance!;
// // // // // // // //   }
// // // // // // // // }

// // // // // // // import 'package:flutter/material.dart';
// // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // import 'package:provider/provider.dart';

// // // // // // // import '../providers/auth_provider.dart';
// // // // // // // import 'route_names.dart';
// // // // // // // import '../../features/auth/presentation/screens/splash_screen.dart';
// // // // // // // import '../../features/auth/presentation/screens/email_screen.dart';
// // // // // // // import '../../features/auth/presentation/screens/otp_screen.dart';
// // // // // // // import '../../features/auth/presentation/screens/onboarding_screen.dart';
// // // // // // // import '../../features/rooms/presentation/screens/room_browser_screen.dart';
// // // // // // // import '../../features/rooms/presentation/screens/lobby_screen.dart';
// // // // // // // import '../../features/packs/presentation/screens/marketplace_screen.dart';
// // // // // // // import '../../features/profile/presentation/screens/profile_screen.dart';
// // // // // // // import '../../features/profile/presentation/screens/edit_profile_screen.dart';
// // // // // // // import '../../features/profile/presentation/screens/change_username_screen.dart';
// // // // // // // import '../../features/settings/presentation/settings_screen.dart';
// // // // // // // import '../../features/offline/presentation/screens/offline_game_screen.dart';
// // // // // // // import '../../features/games/engine/base_game_engine.dart';
// // // // // // // import '../../features/games/truth_or_dare/presentation/screens/tod_game_screen.dart';
// // // // // // // import '../../features/packs/presentation/screens/pack_detail_screen.dart';
// // // // // // // import '../../features/wallet/presentation/screens/wallet_home_screen.dart';
// // // // // // // import '../../features/friends/presentation/screens/friends_screen.dart';
// // // // // // // import '../../features/friends/presentation/screens/user_profile_screen.dart';
// // // // // // // import '../../features/notifications/presentation/screens/notifications_screen.dart';
// // // // // // // import '../../features/packs/presentation/screens/creator_dashboard_screen.dart';
// // // // // // // import '../../features/packs/presentation/screens/create_pack_screen.dart';
// // // // // // // import '../../shared/screens/home_shell_screen.dart';
// // // // // // // import '../../shared/screens/not_found_screen.dart';

// // // // // // // class AppRouter {
// // // // // // //   AppRouter._();

// // // // // // //   static final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// // // // // // //   static GoRouter? _instance;
// // // // // // //   static GoRouter get router {
// // // // // // //     assert(
// // // // // // //       _instance != null,
// // // // // // //       'AppRouter.router accessed before createRouter() was called.',
// // // // // // //     );
// // // // // // //     return _instance!;
// // // // // // //   }

// // // // // // //   static GoRouter createRouter(AuthProvider authProvider) {
// // // // // // //     _instance = GoRouter(
// // // // // // //       navigatorKey: _rootKey,
// // // // // // //       initialLocation: RouteNames.splash,
// // // // // // //       debugLogDiagnostics: true,
// // // // // // //       refreshListenable: authProvider,
// // // // // // //       redirect: (context, state) {
// // // // // // //         final auth = context.read<AuthProvider>();
// // // // // // //         final loc = state.uri.toString();

// // // // // // //         // Allow room and game routes for logged-in users
// // // // // // //         if ((loc.contains('/room') || loc.contains('/game')) &&
// // // // // // //             auth.isLoggedIn &&
// // // // // // //             !auth.isGuest) {
// // // // // // //           return null;
// // // // // // //         }

// // // // // // //         final alwaysPublic = [
// // // // // // //           RouteNames.splash,
// // // // // // //           RouteNames.authEmail,
// // // // // // //           RouteNames.authOtp,
// // // // // // //         ];
// // // // // // //         final isPublic = alwaysPublic.any((r) => loc.startsWith(r));

// // // // // // //         if (auth.isInitializing) {
// // // // // // //           return loc == RouteNames.splash ? null : RouteNames.splash;
// // // // // // //         }

// // // // // // //         if (loc == RouteNames.splash) {
// // // // // // //           if (auth.isGuest) return RouteNames.offline;
// // // // // // //           if (!auth.isLoggedIn) return RouteNames.authEmail;
// // // // // // //           if (auth.needsOnboarding) return RouteNames.onboarding;
// // // // // // //           return RouteNames.home;
// // // // // // //         }

// // // // // // //         if (auth.isGuest) {
// // // // // // //           return loc.startsWith(RouteNames.offline) ? null : RouteNames.offline;
// // // // // // //         }

// // // // // // //         if (!auth.isLoggedIn && !isPublic) {
// // // // // // //           return RouteNames.authEmail;
// // // // // // //         }

// // // // // // //         if (auth.isLoggedIn &&
// // // // // // //             auth.needsOnboarding &&
// // // // // // //             (isPublic || loc == RouteNames.home) &&
// // // // // // //             loc != RouteNames.onboarding) {
// // // // // // //           return RouteNames.onboarding;
// // // // // // //         }

// // // // // // //         if (auth.isLoggedIn &&
// // // // // // //             !auth.needsOnboarding &&
// // // // // // //             isPublic &&
// // // // // // //             loc != RouteNames.splash) {
// // // // // // //           return RouteNames.home;
// // // // // // //         }

// // // // // // //         return null;
// // // // // // //       },
// // // // // // //       routes: [
// // // // // // //         // ── Auth Routes (No Shell) ──────────────────────────────────────────
// // // // // // //         GoRoute(
// // // // // // //           path: RouteNames.splash,
// // // // // // //           name: RouteNames.splash,
// // // // // // //           builder: (_, __) => const SplashScreen(),
// // // // // // //         ),
// // // // // // //         GoRoute(
// // // // // // //           path: RouteNames.authEmail,
// // // // // // //           name: RouteNames.authEmail,
// // // // // // //           builder: (_, __) => const EmailScreen(),
// // // // // // //         ),
// // // // // // //         GoRoute(
// // // // // // //           path: RouteNames.authOtp,
// // // // // // //           name: RouteNames.authOtp,
// // // // // // //           builder: (_, state) => OtpScreen(email: state.extra as String? ?? ''),
// // // // // // //         ),
// // // // // // //         GoRoute(
// // // // // // //           path: RouteNames.onboarding,
// // // // // // //           name: RouteNames.onboarding,
// // // // // // //           builder: (_, __) => const OnboardingScreen(),
// // // // // // //         ),
// // // // // // //         GoRoute(
// // // // // // //           path: RouteNames.offline,
// // // // // // //           name: RouteNames.offline,
// // // // // // //           builder: (_, __) => const OfflineGameScreen(),
// // // // // // //         ),

// // // // // // //         // ── Room and Game Routes (Full Screen, No Shell) ────────────────────
// // // // // // //         GoRoute(
// // // // // // //           path: '/room/:roomId',
// // // // // // //           name: 'lobby',
// // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // //           builder: (context, state) {
// // // // // // //             final roomId = state.pathParameters['roomId']!;
// // // // // // //             return LobbyScreen(roomId: roomId);
// // // // // // //           },
// // // // // // //         ),
// // // // // // //         GoRoute(
// // // // // // //           path: '/room/:roomId/game',
// // // // // // //           name: 'game',
// // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // //           builder: (context, state) {
// // // // // // //             final extra = state.extra as Map<String, dynamic>? ?? {};
// // // // // // //             final roomId = state.pathParameters['roomId']!;
// // // // // // //             final config =
// // // // // // //                 extra['config'] as GameConfig? ??
// // // // // // //                 const GameConfig(
// // // // // // //                   maxRounds: 10,
// // // // // // //                   turnTimerSeconds: 60,
// // // // // // //                   allowSkip: true,
// // // // // // //                   allowSpicy: false,
// // // // // // //                 );

// // // // // // //             return TodGameScreen(
// // // // // // //               roomId: roomId,
// // // // // // //               config: config,
// // // // // // //               playerIds: (extra['playerIds'] as List?)?.cast<String>() ?? [],
// // // // // // //               playerDisplayNames:
// // // // // // //                   (extra['displayNames'] as Map?)?.cast<String, String>() ?? {},
// // // // // // //               packId: extra['packId'] as String? ?? '',
// // // // // // //               isOwner: extra['isOwner'] as bool? ?? false,
// // // // // // //               isModerator: extra['isModerator'] as bool? ?? false,
// // // // // // //               sessionId: extra['sessionId'] as String?,
// // // // // // //             );
// // // // // // //           },
// // // // // // //         ),

// // // // // // //         // ── Main Shell with Bottom Navigation ───────────────────────────────
// // // // // // //         StatefulShellRoute.indexedStack(
// // // // // // //           builder: (context, state, navigationShell) {
// // // // // // //             return HomeShellScreen(navigationShell: navigationShell);
// // // // // // //           },
// // // // // // //           branches: [
// // // // // // //             // Branch 0: Home (Rooms)
// // // // // // //             StatefulShellBranch(
// // // // // // //               routes: [
// // // // // // //                 GoRoute(
// // // // // // //                   path: RouteNames.home,
// // // // // // //                   name: RouteNames.home,
// // // // // // //                   builder: (context, state) => const RoomBrowserScreen(),
// // // // // // //                   routes: [
// // // // // // //                     GoRoute(
// // // // // // //                       path: 'room/:roomId',
// // // // // // //                       builder: (context, state) => const SizedBox.shrink(),
// // // // // // //                     ),
// // // // // // //                   ],
// // // // // // //                 ),
// // // // // // //               ],
// // // // // // //             ),

// // // // // // //             // Branch 1: Friends
// // // // // // //             StatefulShellBranch(
// // // // // // //               routes: [
// // // // // // //                 GoRoute(
// // // // // // //                   path: RouteNames.friends,
// // // // // // //                   name: RouteNames.friends,
// // // // // // //                   builder: (context, state) => const FriendsScreen(),
// // // // // // //                   routes: [
// // // // // // //                     GoRoute(
// // // // // // //                       path: 'user/:userId',
// // // // // // //                       name: 'user_profile',
// // // // // // //                       builder: (context, state) => UserProfileScreen(
// // // // // // //                         userId: state.pathParameters['userId']!,
// // // // // // //                       ),
// // // // // // //                     ),
// // // // // // //                   ],
// // // // // // //                 ),
// // // // // // //               ],
// // // // // // //             ),

// // // // // // //             // Branch 2: Marketplace
// // // // // // //             StatefulShellBranch(
// // // // // // //               routes: [
// // // // // // //                 GoRoute(
// // // // // // //                   path: RouteNames.marketplace,
// // // // // // //                   name: RouteNames.marketplace,
// // // // // // //                   builder: (context, state) => const MarketplaceScreen(),
// // // // // // //                   routes: [
// // // // // // //                     GoRoute(
// // // // // // //                       path: 'pack/:packId',
// // // // // // //                       name: RouteNames.packDetail,
// // // // // // //                       builder: (context, state) => PackDetailScreen(
// // // // // // //                         packId: state.pathParameters['packId']!,
// // // // // // //                       ),
// // // // // // //                     ),
// // // // // // //                   ],
// // // // // // //                 ),
// // // // // // //               ],
// // // // // // //             ),

// // // // // // //             // Branch 3: Profile
// // // // // // //             StatefulShellBranch(
// // // // // // //               routes: [
// // // // // // //                 GoRoute(
// // // // // // //                   path: RouteNames.profile,
// // // // // // //                   name: RouteNames.profile,
// // // // // // //                   builder: (context, state) => const ProfileScreen(),
// // // // // // //                   routes: [
// // // // // // //                     GoRoute(
// // // // // // //                       path: 'edit',
// // // // // // //                       name: 'edit_profile',
// // // // // // //                       builder: (context, state) => const EditProfileScreen(),
// // // // // // //                     ),
// // // // // // //                     GoRoute(
// // // // // // //                       path: 'change-username',
// // // // // // //                       name: 'change_username',
// // // // // // //                       builder: (context, state) => const ChangeUsernameScreen(),
// // // // // // //                     ),
// // // // // // //                   ],
// // // // // // //                 ),
// // // // // // //               ],
// // // // // // //             ),
// // // // // // //           ],
// // // // // // //         ),

// // // // // // //         // ── Other Full Screen Routes ────────────────────────────────────────
// // // // // // //         GoRoute(
// // // // // // //           path: RouteNames.wallet,
// // // // // // //           name: RouteNames.wallet,
// // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // //           builder: (_, __) => const WalletHomeScreen(),
// // // // // // //         ),
// // // // // // //         GoRoute(
// // // // // // //           path: RouteNames.notifications,
// // // // // // //           name: RouteNames.notifications,
// // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // //           builder: (_, __) => const NotificationsScreen(),
// // // // // // //         ),
// // // // // // //         GoRoute(
// // // // // // //           path: RouteNames.settings,
// // // // // // //           name: RouteNames.settings,
// // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // //           builder: (_, __) => const SettingsScreen(),
// // // // // // //         ),
// // // // // // //         GoRoute(
// // // // // // //           path: '/creator',
// // // // // // //           name: 'creator_dashboard',
// // // // // // //           parentNavigatorKey: _rootKey,
// // // // // // //           builder: (_, __) => const CreatorDashboardScreen(),
// // // // // // //           routes: [
// // // // // // //             GoRoute(
// // // // // // //               path: 'create-pack',
// // // // // // //               name: 'create_pack',
// // // // // // //               builder: (_, __) => const CreatePackScreen(),
// // // // // // //             ),
// // // // // // //           ],
// // // // // // //         ),
// // // // // // //       ],

// // // // // // //       errorBuilder: (context, state) => NotFoundScreen(error: state.error),
// // // // // // //     );
// // // // // // //     return _instance!;
// // // // // // //   }
// // // // // // // }
// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:go_router/go_router.dart';
// // // // // // import 'package:provider/provider.dart';

// // // // // // import '../providers/auth_provider.dart';
// // // // // // import 'route_names.dart';
// // // // // // import '../../features/auth/presentation/screens/splash_screen.dart';
// // // // // // import '../../features/auth/presentation/screens/email_screen.dart';
// // // // // // import '../../features/auth/presentation/screens/otp_screen.dart';
// // // // // // import '../../features/auth/presentation/screens/onboarding_screen.dart';
// // // // // // import '../../features/rooms/presentation/screens/room_browser_screen.dart';
// // // // // // import '../../features/rooms/presentation/screens/lobby_screen.dart';
// // // // // // import '../../features/packs/presentation/screens/marketplace_screen.dart';
// // // // // // import '../../features/profile/presentation/screens/profile_screen.dart';
// // // // // // import '../../features/profile/presentation/screens/edit_profile_screen.dart';
// // // // // // import '../../features/profile/presentation/screens/change_username_screen.dart';
// // // // // // import '../../features/settings/presentation/settings_screen.dart';
// // // // // // import '../../features/offline/presentation/screens/offline_game_screen.dart';
// // // // // // import '../../features/games/engine/base_game_engine.dart';
// // // // // // import '../../features/games/truth_or_dare/presentation/screens/tod_game_screen.dart';
// // // // // // import '../../features/packs/presentation/screens/pack_detail_screen.dart';
// // // // // // import '../../features/wallet/presentation/screens/wallet_home_screen.dart';
// // // // // // import '../../features/friends/presentation/screens/friends_screen.dart';
// // // // // // import '../../features/friends/presentation/screens/user_profile_screen.dart';
// // // // // // import '../../features/notifications/presentation/screens/notifications_screen.dart';
// // // // // // import '../../features/packs/presentation/screens/creator_dashboard_screen.dart';
// // // // // // import '../../features/packs/presentation/screens/create_pack_screen.dart';
// // // // // // import '../../shared/screens/home_shell_screen.dart';
// // // // // // import '../../shared/screens/not_found_screen.dart';

// // // // // // class AppRouter {
// // // // // //   AppRouter._();

// // // // // //   static final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// // // // // //   static GoRouter? _instance;
// // // // // //   static GoRouter get router {
// // // // // //     assert(
// // // // // //       _instance != null,
// // // // // //       'AppRouter.router accessed before createRouter() was called.',
// // // // // //     );
// // // // // //     return _instance!;
// // // // // //   }

// // // // // //   static GoRouter createRouter(AuthProvider authProvider) {
// // // // // //     _instance = GoRouter(
// // // // // //       navigatorKey: _rootKey,
// // // // // //       initialLocation: RouteNames.splash,
// // // // // //       debugLogDiagnostics: true,
// // // // // //       refreshListenable: authProvider,
// // // // // //       redirect: (context, state) {
// // // // // //         final auth = context.read<AuthProvider>();
// // // // // //         final loc = state.uri.toString();

// // // // // //         if (loc.contains('/room/') && auth.isLoggedIn && !auth.isGuest) {
// // // // // //           return null;
// // // // // //         }

// // // // // //         final alwaysPublic = [
// // // // // //           RouteNames.splash,
// // // // // //           RouteNames.authEmail,
// // // // // //           RouteNames.authOtp,
// // // // // //         ];
// // // // // //         final isPublic = alwaysPublic.any((r) => loc.startsWith(r));

// // // // // //         if (auth.isInitializing) {
// // // // // //           return loc == RouteNames.splash ? null : RouteNames.splash;
// // // // // //         }

// // // // // //         if (loc == RouteNames.splash) {
// // // // // //           if (auth.isGuest) return RouteNames.offline;
// // // // // //           if (!auth.isLoggedIn) return RouteNames.authEmail;
// // // // // //           if (auth.needsOnboarding) return RouteNames.onboarding;
// // // // // //           return RouteNames.home;
// // // // // //         }

// // // // // //         if (auth.isGuest) {
// // // // // //           return loc.startsWith(RouteNames.offline) ? null : RouteNames.offline;
// // // // // //         }

// // // // // //         if (!auth.isLoggedIn && !isPublic) {
// // // // // //           return RouteNames.authEmail;
// // // // // //         }

// // // // // //         if (auth.isLoggedIn &&
// // // // // //             auth.needsOnboarding &&
// // // // // //             (isPublic || loc == RouteNames.home) &&
// // // // // //             loc != RouteNames.onboarding) {
// // // // // //           return RouteNames.onboarding;
// // // // // //         }

// // // // // //         if (auth.isLoggedIn &&
// // // // // //             !auth.needsOnboarding &&
// // // // // //             isPublic &&
// // // // // //             loc != RouteNames.splash) {
// // // // // //           return RouteNames.home;
// // // // // //         }

// // // // // //         return null;
// // // // // //       },
// // // // // //       routes: [
// // // // // //         GoRoute(
// // // // // //           path: RouteNames.splash,
// // // // // //           builder: (_, __) => const SplashScreen(),
// // // // // //         ),
// // // // // //         GoRoute(
// // // // // //           path: RouteNames.authEmail,
// // // // // //           builder: (_, __) => const EmailScreen(),
// // // // // //         ),
// // // // // //         GoRoute(
// // // // // //           path: RouteNames.authOtp,
// // // // // //           builder: (_, state) => OtpScreen(email: state.extra as String? ?? ''),
// // // // // //         ),
// // // // // //         GoRoute(
// // // // // //           path: RouteNames.onboarding,
// // // // // //           builder: (_, __) => const OnboardingScreen(),
// // // // // //         ),

// // // // // //         GoRoute(
// // // // // //           path: RouteNames.home,
// // // // // //           builder: (_, __) => const HomeShellScreen(),
// // // // // //         ),
// // // // // //         GoRoute(
// // // // // //           path: '/home/room/:roomId',
// // // // // //           name: RouteNames.room,
// // // // // //           parentNavigatorKey: _rootKey,
// // // // // //           builder: (_, state) =>
// // // // // //               LobbyScreen(roomId: state.pathParameters['roomId']!),
// // // // // //           routes: [
// // // // // //             GoRoute(
// // // // // //               path: 'game',
// // // // // //               name: 'game',
// // // // // //               parentNavigatorKey: _rootKey,
// // // // // //               builder: (_, state) {
// // // // // //                 final extra = state.extra as Map<String, dynamic>? ?? {};
// // // // // //                 final config =
// // // // // //                     extra['config'] as GameConfig? ??
// // // // // //                     const GameConfig(
// // // // // //                       maxRounds: 10,
// // // // // //                       turnTimerSeconds: 60,
// // // // // //                       allowSkip: true,
// // // // // //                       allowSpicy: false,
// // // // // //                     );
// // // // // //                 return TodGameScreen(
// // // // // //                   roomId: state.pathParameters['roomId']!,
// // // // // //                   config: config,
// // // // // //                   playerIds:
// // // // // //                       (extra['playerIds'] as List?)?.cast<String>() ?? [],
// // // // // //                   playerDisplayNames:
// // // // // //                       (extra['displayNames'] as Map?)?.cast<String, String>() ??
// // // // // //                       {},
// // // // // //                   packId: extra['packId'] as String? ?? '',
// // // // // //                   isOwner: extra['isOwner'] as bool? ?? false,
// // // // // //                   isModerator: extra['isModerator'] as bool? ?? false,
// // // // // //                   sessionId: extra['sessionId'] as String?,
// // // // // //                 );
// // // // // //               },
// // // // // //             ),
// // // // // //           ],
// // // // // //         ),

// // // // // //         GoRoute(
// // // // // //           path: '/profile/edit',
// // // // // //           parentNavigatorKey: _rootKey,
// // // // // //           builder: (_, __) => const EditProfileScreen(),
// // // // // //         ),
// // // // // //         GoRoute(
// // // // // //           path: '/profile/change-username',
// // // // // //           parentNavigatorKey: _rootKey,
// // // // // //           builder: (_, __) => const ChangeUsernameScreen(),
// // // // // //         ),
// // // // // //         GoRoute(
// // // // // //           path: RouteNames.wallet,
// // // // // //           parentNavigatorKey: _rootKey,
// // // // // //           builder: (_, __) => const WalletHomeScreen(),
// // // // // //         ),
// // // // // //         GoRoute(
// // // // // //           path: RouteNames.notifications,
// // // // // //           parentNavigatorKey: _rootKey,
// // // // // //           builder: (_, __) => const NotificationsScreen(),
// // // // // //         ),
// // // // // //         GoRoute(
// // // // // //           path: '/creator',
// // // // // //           parentNavigatorKey: _rootKey,
// // // // // //           builder: (_, __) => const CreatorDashboardScreen(),
// // // // // //           routes: [
// // // // // //             GoRoute(
// // // // // //               path: 'create-pack',
// // // // // //               builder: (_, __) => const CreatePackScreen(),
// // // // // //             ),
// // // // // //           ],
// // // // // //         ),
// // // // // //         GoRoute(
// // // // // //           path: RouteNames.settings,
// // // // // //           parentNavigatorKey: _rootKey,
// // // // // //           builder: (_, __) => const SettingsScreen(),
// // // // // //         ),
// // // // // //         GoRoute(
// // // // // //           path: RouteNames.offline,
// // // // // //           parentNavigatorKey: _rootKey,
// // // // // //           builder: (_, __) => const OfflineGameScreen(),
// // // // // //         ),
// // // // // //       ],

// // // // // //       errorBuilder: (_, state) => NotFoundScreen(error: state.error),
// // // // // //     );
// // // // // //     return _instance!;
// // // // // //   }
// // // // // // }

// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:go_router/go_router.dart';
// // // // // import 'package:provider/provider.dart';

// // // // // import '../providers/auth_provider.dart';
// // // // // import 'route_names.dart';
// // // // // import '../../features/auth/presentation/screens/splash_screen.dart';
// // // // // import '../../features/auth/presentation/screens/email_screen.dart';
// // // // // import '../../features/auth/presentation/screens/otp_screen.dart';
// // // // // import '../../features/auth/presentation/screens/onboarding_screen.dart';
// // // // // import '../../features/rooms/presentation/screens/room_browser_screen.dart';
// // // // // import '../../features/rooms/presentation/screens/lobby_screen.dart';
// // // // // import '../../features/packs/presentation/screens/marketplace_screen.dart';
// // // // // import '../../features/profile/presentation/screens/profile_screen.dart';
// // // // // import '../../features/profile/presentation/screens/edit_profile_screen.dart';
// // // // // import '../../features/profile/presentation/screens/change_username_screen.dart';
// // // // // import '../../features/settings/presentation/settings_screen.dart';
// // // // // import '../../features/offline/presentation/screens/offline_game_screen.dart';
// // // // // import '../../features/games/engine/base_game_engine.dart';
// // // // // import '../../features/games/truth_or_dare/presentation/screens/tod_game_screen.dart';
// // // // // import '../../features/packs/presentation/screens/pack_detail_screen.dart';
// // // // // import '../../features/wallet/presentation/screens/wallet_home_screen.dart';
// // // // // import '../../features/friends/presentation/screens/friends_screen.dart';
// // // // // import '../../features/friends/presentation/screens/user_profile_screen.dart';
// // // // // import '../../features/notifications/presentation/screens/notifications_screen.dart';
// // // // // import '../../features/packs/presentation/screens/creator_dashboard_screen.dart';
// // // // // import '../../features/packs/presentation/screens/create_pack_screen.dart';
// // // // // import '../../shared/screens/home_shell_screen.dart';
// // // // // import '../../shared/screens/not_found_screen.dart';

// // // // // class AppRouter {
// // // // //   AppRouter._();

// // // // //   static final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// // // // //   static GoRouter? _instance;
// // // // //   static GoRouter get router {
// // // // //     assert(
// // // // //       _instance != null,
// // // // //       'AppRouter.router accessed before createRouter() was called.',
// // // // //     );
// // // // //     return _instance!;
// // // // //   }

// // // // //   static GoRouter createRouter(AuthProvider authProvider) {
// // // // //     _instance = GoRouter(
// // // // //       navigatorKey: _rootKey,
// // // // //       initialLocation: RouteNames.splash,
// // // // //       debugLogDiagnostics: true,
// // // // //       refreshListenable: authProvider,
// // // // //       redirect: (context, state) {
// // // // //         final auth = context.read<AuthProvider>();
// // // // //         final loc = state.uri.toString();

// // // // //         if (loc.contains('/room/') && auth.isLoggedIn && !auth.isGuest) {
// // // // //           return null;
// // // // //         }

// // // // //         final alwaysPublic = [
// // // // //           RouteNames.splash,
// // // // //           RouteNames.authEmail,
// // // // //           RouteNames.authOtp,
// // // // //         ];
// // // // //         final isPublic = alwaysPublic.any((r) => loc.startsWith(r));

// // // // //         if (auth.isInitializing) {
// // // // //           return loc == RouteNames.splash ? null : RouteNames.splash;
// // // // //         }

// // // // //         if (loc == RouteNames.splash) {
// // // // //           if (auth.isGuest) return RouteNames.offline;
// // // // //           if (!auth.isLoggedIn) return RouteNames.authEmail;
// // // // //           if (auth.needsOnboarding) return RouteNames.onboarding;
// // // // //           return RouteNames.home;
// // // // //         }

// // // // //         if (auth.isGuest) {
// // // // //           return loc.startsWith(RouteNames.offline) ? null : RouteNames.offline;
// // // // //         }

// // // // //         if (!auth.isLoggedIn && !isPublic) {
// // // // //           return RouteNames.authEmail;
// // // // //         }

// // // // //         if (auth.isLoggedIn &&
// // // // //             auth.needsOnboarding &&
// // // // //             (isPublic || loc == RouteNames.home) &&
// // // // //             loc != RouteNames.onboarding) {
// // // // //           return RouteNames.onboarding;
// // // // //         }

// // // // //         if (auth.isLoggedIn &&
// // // // //             !auth.needsOnboarding &&
// // // // //             isPublic &&
// // // // //             loc != RouteNames.splash) {
// // // // //           return RouteNames.home;
// // // // //         }

// // // // //         return null;
// // // // //       },
// // // // //       routes: [
// // // // //         GoRoute(
// // // // //           path: RouteNames.splash,
// // // // //           builder: (_, __) => const SplashScreen(),
// // // // //         ),
// // // // //         GoRoute(
// // // // //           path: RouteNames.authEmail,
// // // // //           builder: (_, __) => const EmailScreen(),
// // // // //         ),
// // // // //         GoRoute(
// // // // //           path: RouteNames.authOtp,
// // // // //           builder: (_, state) => OtpScreen(email: state.extra as String? ?? ''),
// // // // //         ),
// // // // //         GoRoute(
// // // // //           path: RouteNames.onboarding,
// // // // //           builder: (_, __) => const OnboardingScreen(),
// // // // //         ),

// // // // //         GoRoute(
// // // // //           path: RouteNames.home,
// // // // //           builder: (_, __) => const HomeShellScreen(),
// // // // //         ),

// // // // //         // ── Pack detail — full-screen above shell ─────────────────────────
// // // // //         GoRoute(
// // // // //           path: '/marketplace/pack/:packId',
// // // // //           name: RouteNames.packDetail,
// // // // //           parentNavigatorKey: _rootKey,
// // // // //           builder: (_, state) =>
// // // // //               PackDetailScreen(packId: state.pathParameters['packId']!),
// // // // //         ),
// // // // //         GoRoute(
// // // // //           path: '/test/:packId',
// // // // //           builder: (_, state) => Scaffold(
// // // // //             appBar: AppBar(title: const Text('Test')),
// // // // //             body: Center(
// // // // //               child: Text('PackId: ${state.pathParameters['packId']}'),
// // // // //             ),
// // // // //           ),
// // // // //         ),
// // // // //         GoRoute(
// // // // //           path: '/home/room/:roomId',
// // // // //           name: RouteNames.room,
// // // // //           parentNavigatorKey: _rootKey,
// // // // //           builder: (_, state) =>
// // // // //               LobbyScreen(roomId: state.pathParameters['roomId']!),
// // // // //           routes: [
// // // // //             GoRoute(
// // // // //               path: 'game',
// // // // //               name: 'game',
// // // // //               parentNavigatorKey: _rootKey,
// // // // //               builder: (_, state) {
// // // // //                 final extra = state.extra as Map<String, dynamic>? ?? {};
// // // // //                 final config =
// // // // //                     extra['config'] as GameConfig? ??
// // // // //                     const GameConfig(
// // // // //                       maxRounds: 10,
// // // // //                       turnTimerSeconds: 60,
// // // // //                       allowSkip: true,
// // // // //                       allowSpicy: false,
// // // // //                     );
// // // // //                 return TodGameScreen(
// // // // //                   roomId: state.pathParameters['roomId']!,
// // // // //                   config: config,
// // // // //                   playerIds:
// // // // //                       (extra['playerIds'] as List?)?.cast<String>() ?? [],
// // // // //                   playerDisplayNames:
// // // // //                       (extra['displayNames'] as Map?)?.cast<String, String>() ??
// // // // //                       {},
// // // // //                   packId: extra['packId'] as String? ?? '',
// // // // //                   isOwner: extra['isOwner'] as bool? ?? false,
// // // // //                   isModerator: extra['isModerator'] as bool? ?? false,
// // // // //                   sessionId: extra['sessionId'] as String?,
// // // // //                 );
// // // // //               },
// // // // //             ),
// // // // //           ],
// // // // //         ),

// // // // //         GoRoute(
// // // // //           path: '/profile/edit',
// // // // //           parentNavigatorKey: _rootKey,
// // // // //           builder: (_, __) => const EditProfileScreen(),
// // // // //         ),
// // // // //         GoRoute(
// // // // //           path: '/user/:userId',
// // // // //           name: RouteNames.userProfile,
// // // // //           parentNavigatorKey: _rootKey,
// // // // //           builder: (_, state) =>
// // // // //               UserProfileScreen(userId: state.pathParameters['userId']!),
// // // // //         ),
// // // // //         GoRoute(
// // // // //           path: '/profile/change-username',
// // // // //           parentNavigatorKey: _rootKey,
// // // // //           builder: (_, __) => const ChangeUsernameScreen(),
// // // // //         ),
// // // // //         GoRoute(
// // // // //           path: RouteNames.wallet,
// // // // //           parentNavigatorKey: _rootKey,
// // // // //           builder: (_, __) => const WalletHomeScreen(),
// // // // //         ),
// // // // //         GoRoute(
// // // // //           path: RouteNames.notifications,
// // // // //           parentNavigatorKey: _rootKey,
// // // // //           builder: (_, __) => const NotificationsScreen(),
// // // // //         ),
// // // // //         GoRoute(
// // // // //           path: '/creator',
// // // // //           parentNavigatorKey: _rootKey,
// // // // //           builder: (_, __) => const CreatorDashboardScreen(),
// // // // //           routes: [
// // // // //             GoRoute(
// // // // //               path: 'create-pack',
// // // // //               builder: (_, __) => const CreatePackScreen(),
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //         GoRoute(
// // // // //           path: RouteNames.settings,
// // // // //           parentNavigatorKey: _rootKey,
// // // // //           builder: (_, __) => const SettingsScreen(),
// // // // //         ),
// // // // //         GoRoute(
// // // // //           path: RouteNames.offline,
// // // // //           parentNavigatorKey: _rootKey,
// // // // //           builder: (_, __) => const OfflineGameScreen(),
// // // // //         ),
// // // // //       ],

// // // // //       errorBuilder: (_, state) => NotFoundScreen(error: state.error),
// // // // //     );
// // // // //     return _instance!;
// // // // //   }
// // // // // }

// // // // import 'package:flutter/material.dart';
// // // // import 'package:go_router/go_router.dart';
// // // // import 'package:jma3a/features/offline/presentation/screens/offline_play_screen.dart';
// // // // import 'package:provider/provider.dart';

// // // // import '../providers/auth_provider.dart';
// // // // import 'route_names.dart';
// // // // import '../../features/auth/presentation/screens/splash_screen.dart';
// // // // import '../../features/auth/presentation/screens/email_screen.dart';
// // // // import '../../features/auth/presentation/screens/otp_screen.dart';
// // // // import '../../features/auth/presentation/screens/onboarding_screen.dart';
// // // // import '../../features/rooms/presentation/screens/room_browser_screen.dart';
// // // // import '../../features/rooms/presentation/screens/lobby_screen.dart';
// // // // import '../../features/packs/presentation/screens/marketplace_screen.dart';
// // // // import '../../features/profile/presentation/screens/profile_screen.dart';
// // // // import '../../features/profile/presentation/screens/edit_profile_screen.dart';
// // // // import '../../features/profile/presentation/screens/change_username_screen.dart';
// // // // import '../../features/settings/presentation/settings_screen.dart';
// // // // import '../../features/offline/presentation/screens/offline_game_screen.dart';
// // // // import '../../features/games/engine/base_game_engine.dart';
// // // // import '../../features/games/truth_or_dare/presentation/screens/tod_game_screen.dart';
// // // // import '../../features/packs/presentation/screens/pack_detail_screen.dart';
// // // // import '../../features/wallet/presentation/screens/wallet_home_screen.dart';
// // // // import '../../features/friends/presentation/screens/friends_screen.dart';
// // // // import '../../features/friends/presentation/screens/user_profile_screen.dart';
// // // // import '../../features/notifications/presentation/screens/notifications_screen.dart';
// // // // import '../../features/packs/presentation/screens/creator_dashboard_screen.dart';
// // // // import '../../features/packs/presentation/screens/create_pack_screen.dart';
// // // // import '../../shared/screens/home_shell_screen.dart';
// // // // import '../../shared/screens/not_found_screen.dart';

// // // // class AppRouter {
// // // //   AppRouter._();

// // // //   static final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// // // //   static GoRouter? _instance;
// // // //   static GoRouter get router {
// // // //     assert(
// // // //       _instance != null,
// // // //       'AppRouter.router accessed before createRouter() was called.',
// // // //     );
// // // //     return _instance!;
// // // //   }

// // // //   static GoRouter createRouter(AuthProvider authProvider) {
// // // //     _instance = GoRouter(
// // // //       navigatorKey: rootKey,
// // // //       initialLocation: RouteNames.splash,
// // // //       debugLogDiagnostics: true,
// // // //       refreshListenable: authProvider,
// // // //       redirect: (context, state) {
// // // //         final auth = context.read<AuthProvider>();
// // // //         final loc = state.uri.toString();

// // // //         if (loc.contains('/room/') && auth.isLoggedIn && !auth.isGuest) {
// // // //           return null;
// // // //         }

// // // //         final alwaysPublic = [
// // // //           RouteNames.splash,
// // // //           RouteNames.authEmail,
// // // //           RouteNames.authOtp,
// // // //         ];
// // // //         final isPublic = alwaysPublic.any((r) => loc.startsWith(r));

// // // //         // Logged-in app routes — never redirect these
// // // //         final appRoutes = [
// // // //           RouteNames.home,
// // // //           RouteNames.settings,
// // // //           RouteNames.wallet,
// // // //           RouteNames.notifications,
// // // //           RouteNames.offline,
// // // //           '/profile',
// // // //           '/user/',
// // // //           '/marketplace',
// // // //           '/creator',
// // // //         ];
// // // //         if (auth.isLoggedIn &&
// // // //             !auth.isGuest &&
// // // //             appRoutes.any((r) => loc.startsWith(r))) {
// // // //           return null;
// // // //         }

// // // //         if (auth.isInitializing) {
// // // //           return loc == RouteNames.splash ? null : RouteNames.splash;
// // // //         }

// // // //         if (loc == RouteNames.splash) {
// // // //           if (auth.isGuest) return RouteNames.offline;
// // // //           if (!auth.isLoggedIn) return RouteNames.authEmail;
// // // //           if (auth.needsOnboarding) return RouteNames.onboarding;
// // // //           return RouteNames.home;
// // // //         }

// // // //         if (auth.isGuest) {
// // // //           return loc.startsWith(RouteNames.offline) ? null : RouteNames.offline;
// // // //         }

// // // //         if (!auth.isLoggedIn && !isPublic) {
// // // //           return RouteNames.authEmail;
// // // //         }

// // // //         if (auth.isLoggedIn &&
// // // //             auth.needsOnboarding &&
// // // //             (isPublic || loc == RouteNames.home) &&
// // // //             loc != RouteNames.onboarding) {
// // // //           return RouteNames.onboarding;
// // // //         }

// // // //         if (auth.isLoggedIn &&
// // // //             !auth.needsOnboarding &&
// // // //             isPublic &&
// // // //             loc != RouteNames.splash) {
// // // //           return RouteNames.home;
// // // //         }

// // // //         return null;
// // // //       },
// // // //       routes: [
// // // //         GoRoute(
// // // //           path: RouteNames.splash,
// // // //           builder: (_, __) => const SplashScreen(),
// // // //         ),
// // // //         GoRoute(
// // // //           path: RouteNames.authEmail,
// // // //           builder: (_, __) => const EmailScreen(),
// // // //         ),
// // // //         GoRoute(
// // // //           path: RouteNames.authOtp,
// // // //           builder: (_, state) => OtpScreen(email: state.extra as String? ?? ''),
// // // //         ),
// // // //         GoRoute(
// // // //           path: RouteNames.onboarding,
// // // //           builder: (_, __) => const OnboardingScreen(),
// // // //         ),

// // // //         GoRoute(
// // // //           path: RouteNames.home,
// // // //           builder: (_, __) => const HomeShellScreen(),
// // // //         ),

// // // //         // ── Pack detail — full-screen above shell ─────────────────────────
// // // //         GoRoute(
// // // //           path: '/marketplace/pack/:packId',
// // // //           name: RouteNames.packDetail,
// // // //           parentNavigatorKey: rootKey,
// // // //           builder: (_, state) =>
// // // //               PackDetailScreen(packId: state.pathParameters['packId']!),
// // // //         ),
// // // //         GoRoute(
// // // //           path: '/home/room/:roomId',
// // // //           name: RouteNames.room,
// // // //           parentNavigatorKey: rootKey,
// // // //           builder: (_, state) =>
// // // //               LobbyScreen(roomId: state.pathParameters['roomId']!),
// // // //           routes: [
// // // //             GoRoute(
// // // //               path: 'game',
// // // //               name: 'game',
// // // //               parentNavigatorKey: rootKey,
// // // //               builder: (_, state) {
// // // //                 final extra = state.extra as Map<String, dynamic>? ?? {};
// // // //                 final config =
// // // //                     extra['config'] as GameConfig? ??
// // // //                     const GameConfig(
// // // //                       maxRounds: 10,
// // // //                       turnTimerSeconds: 60,
// // // //                       allowSkip: true,
// // // //                       allowSpicy: false,
// // // //                     );
// // // //                 return TodGameScreen(
// // // //                   roomId: state.pathParameters['roomId']!,
// // // //                   config: config,
// // // //                   playerIds:
// // // //                       (extra['playerIds'] as List?)?.cast<String>() ?? [],
// // // //                   playerDisplayNames:
// // // //                       (extra['displayNames'] as Map?)?.cast<String, String>() ??
// // // //                       {},
// // // //                   packId: extra['packId'] as String? ?? '',
// // // //                   isOwner: extra['isOwner'] as bool? ?? false,
// // // //                   isModerator: extra['isModerator'] as bool? ?? false,
// // // //                   sessionId: extra['sessionId'] as String?,
// // // //                 );
// // // //               },
// // // //             ),
// // // //           ],
// // // //         ),

// // // //         GoRoute(
// // // //           path: '/profile/edit',
// // // //           parentNavigatorKey: rootKey,
// // // //           builder: (_, __) => const EditProfileScreen(),
// // // //         ),
// // // //         GoRoute(
// // // //           path: '/user/:userId',
// // // //           name: RouteNames.userProfile,
// // // //           parentNavigatorKey: rootKey,
// // // //           builder: (_, state) =>
// // // //               UserProfileScreen(userId: state.pathParameters['userId']!),
// // // //         ),
// // // //         GoRoute(
// // // //           path: '/profile/change-username',
// // // //           parentNavigatorKey: rootKey,
// // // //           builder: (_, __) => const ChangeUsernameScreen(),
// // // //         ),
// // // //         GoRoute(
// // // //           path: RouteNames.wallet,
// // // //           parentNavigatorKey: rootKey,
// // // //           builder: (_, __) => const WalletHomeScreen(),
// // // //         ),
// // // //         GoRoute(
// // // //           path: RouteNames.notifications,
// // // //           parentNavigatorKey: rootKey,
// // // //           builder: (_, __) => const NotificationsScreen(),
// // // //         ),
// // // //         GoRoute(
// // // //           path: '/creator',
// // // //           parentNavigatorKey: rootKey,
// // // //           builder: (_, __) => const CreatorDashboardScreen(),
// // // //           routes: [
// // // //             GoRoute(
// // // //               path: 'create-pack',
// // // //               builder: (_, __) => const CreatePackScreen(),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //         GoRoute(
// // // //           path: RouteNames.settings,
// // // //           parentNavigatorKey: rootKey,
// // // //           builder: (_, __) => const SettingsScreen(),
// // // //         ),
// // // //         GoRoute(
// // // //           path: RouteNames.offline,
// // // //           parentNavigatorKey: rootKey,
// // // //           builder: (_, __) => const OfflinePlayScreen(),
// // // //         ),
// // // //       ],

// // // //       errorBuilder: (_, state) => NotFoundScreen(error: state.error),
// // // //     );
// // // //     return _instance!;
// // // //   }
// // // // }

// // // import 'package:flutter/material.dart';
// // // import 'package:go_router/go_router.dart';
// // // import 'package:jma3a/features/games/presentation/meme_game_screen.dart';
// // // import 'package:jma3a/features/games/presentation/nhie_game_screen.dart';
// // // import 'package:provider/provider.dart';

// // // import '../providers/auth_provider.dart';
// // // import 'route_names.dart';
// // // import '../../features/auth/presentation/screens/splash_screen.dart';
// // // import '../../features/auth/presentation/screens/email_screen.dart';
// // // import '../../features/auth/presentation/screens/otp_screen.dart';
// // // import '../../features/auth/presentation/screens/onboarding_screen.dart';
// // // import '../../features/rooms/presentation/screens/room_browser_screen.dart';
// // // import '../../features/rooms/presentation/screens/lobby_screen.dart';
// // // import '../../features/packs/presentation/screens/marketplace_screen.dart';
// // // import '../../features/profile/presentation/screens/profile_screen.dart';
// // // import '../../features/profile/presentation/screens/edit_profile_screen.dart';
// // // import '../../features/profile/presentation/screens/change_username_screen.dart';
// // // import '../../features/settings/presentation/settings_screen.dart';
// // // import '../../features/offline/presentation/screens/offline_game_screen.dart';
// // // import '../../features/games/engine/base_game_engine.dart';
// // // import '../../features/games/truth_or_dare/presentation/screens/tod_game_screen.dart';
// // // import '../../features/packs/presentation/screens/pack_detail_screen.dart';
// // // import '../../features/wallet/presentation/screens/wallet_home_screen.dart';
// // // import '../../features/friends/presentation/screens/friends_screen.dart';
// // // import '../../features/friends/presentation/screens/user_profile_screen.dart';
// // // import '../../features/notifications/presentation/screens/notifications_screen.dart';
// // // import '../../features/packs/presentation/screens/creator_dashboard_screen.dart';
// // // import '../../features/packs/presentation/screens/create_pack_screen.dart';
// // // // import '../../features/games/never_have_i_ever/presentation/nhie_game_screen.dart';
// // // // import '../../features/games/meme_game/presentation/meme_game_screen.dart';
// // // import '../../shared/screens/home_shell_screen.dart';
// // // import '../../shared/screens/not_found_screen.dart';

// // // class AppRouter {
// // //   AppRouter._();

// // //   static final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// // //   static GoRouter? _instance;
// // //   static GoRouter get router {
// // //     assert(
// // //       _instance != null,
// // //       'AppRouter.router accessed before createRouter() was called.',
// // //     );
// // //     return _instance!;
// // //   }

// // //   static GoRouter createRouter(AuthProvider authProvider) {
// // //     _instance = GoRouter(
// // //       navigatorKey: rootKey,
// // //       initialLocation: RouteNames.splash,
// // //       debugLogDiagnostics: true,
// // //       refreshListenable: authProvider,
// // //       redirect: (context, state) {
// // //         final auth = context.read<AuthProvider>();
// // //         final loc = state.uri.toString();

// // //         if (loc.contains('/room/') && auth.isLoggedIn && !auth.isGuest) {
// // //           return null;
// // //         }

// // //         final alwaysPublic = [
// // //           RouteNames.splash,
// // //           RouteNames.authEmail,
// // //           RouteNames.authOtp,
// // //         ];
// // //         final isPublic = alwaysPublic.any((r) => loc.startsWith(r));

// // //         // Logged-in app routes — never redirect these
// // //         final appRoutes = [
// // //           RouteNames.home,
// // //           RouteNames.settings,
// // //           RouteNames.wallet,
// // //           RouteNames.notifications,
// // //           RouteNames.offline,
// // //           '/profile',
// // //           '/user/',
// // //           '/marketplace',
// // //           '/creator',
// // //         ];
// // //         if (auth.isLoggedIn &&
// // //             !auth.isGuest &&
// // //             appRoutes.any((r) => loc.startsWith(r))) {
// // //           return null;
// // //         }

// // //         if (auth.isInitializing) {
// // //           return loc == RouteNames.splash ? null : RouteNames.splash;
// // //         }

// // //         if (loc == RouteNames.splash) {
// // //           if (auth.isGuest) return RouteNames.offline;
// // //           if (!auth.isLoggedIn) return RouteNames.authEmail;
// // //           if (auth.needsOnboarding) return RouteNames.onboarding;
// // //           return RouteNames.home;
// // //         }

// // //         if (auth.isGuest) {
// // //           return loc.startsWith(RouteNames.offline) ? null : RouteNames.offline;
// // //         }

// // //         if (!auth.isLoggedIn && !isPublic) {
// // //           return RouteNames.authEmail;
// // //         }

// // //         if (auth.isLoggedIn &&
// // //             auth.needsOnboarding &&
// // //             (isPublic || loc == RouteNames.home) &&
// // //             loc != RouteNames.onboarding) {
// // //           return RouteNames.onboarding;
// // //         }

// // //         if (auth.isLoggedIn &&
// // //             !auth.needsOnboarding &&
// // //             isPublic &&
// // //             loc != RouteNames.splash) {
// // //           return RouteNames.home;
// // //         }

// // //         return null;
// // //       },
// // //       routes: [
// // //         GoRoute(
// // //           path: RouteNames.splash,
// // //           builder: (_, __) => const SplashScreen(),
// // //         ),
// // //         GoRoute(
// // //           path: RouteNames.authEmail,
// // //           builder: (_, __) => const EmailScreen(),
// // //         ),
// // //         GoRoute(
// // //           path: RouteNames.authOtp,
// // //           builder: (_, state) => OtpScreen(email: state.extra as String? ?? ''),
// // //         ),
// // //         GoRoute(
// // //           path: RouteNames.onboarding,
// // //           builder: (_, __) => const OnboardingScreen(),
// // //         ),

// // //         GoRoute(
// // //           path: RouteNames.home,
// // //           builder: (_, __) => const HomeShellScreen(),
// // //         ),

// // //         // ── Pack detail — full-screen above shell ─────────────────────────
// // //         GoRoute(
// // //           path: '/marketplace/pack/:packId',
// // //           name: RouteNames.packDetail,
// // //           parentNavigatorKey: rootKey,
// // //           builder: (_, state) =>
// // //               PackDetailScreen(packId: state.pathParameters['packId']!),
// // //         ),
// // //         GoRoute(
// // //           path: '/home/room/:roomId',
// // //           name: RouteNames.room,
// // //           parentNavigatorKey: rootKey,
// // //           builder: (_, state) =>
// // //               LobbyScreen(roomId: state.pathParameters['roomId']!),
// // //           routes: [
// // //             GoRoute(
// // //               path: 'game',
// // //               name: 'game',
// // //               parentNavigatorKey: rootKey,
// // //               builder: (_, state) {
// // //                 final extra = state.extra as Map<String, dynamic>? ?? {};
// // //                 final config =
// // //                     extra['config'] as GameConfig? ??
// // //                     const GameConfig(
// // //                       maxRounds: 10,
// // //                       turnTimerSeconds: 60,
// // //                       allowSkip: true,
// // //                       allowSpicy: false,
// // //                     );
// // //                 final roomId = state.pathParameters['roomId']!;
// // //                 final playerIds =
// // //                     (extra['playerIds'] as List?)?.cast<String>() ?? [];
// // //                 final displayNames =
// // //                     (extra['displayNames'] as Map?)?.cast<String, String>() ??
// // //                     {};
// // //                 final packId = extra['packId'] as String? ?? '';
// // //                 final isOwner = extra['isOwner'] as bool? ?? false;
// // //                 final isModerator = extra['isModerator'] as bool? ?? false;
// // //                 final gameType =
// // //                     extra['gameType'] as String? ?? 'truth_or_dare';

// // //                 return switch (gameType) {
// // //                   'never_have_i_ever' => NhieGameScreen(
// // //                     roomId: roomId,
// // //                     config: config,
// // //                     playerIds: playerIds,
// // //                     playerDisplayNames: displayNames,
// // //                     packId: packId,
// // //                     isOwner: isOwner,
// // //                     isModerator: isModerator,
// // //                   ),
// // //                   'meme_game' => MemeGameScreen(
// // //                     roomId: roomId,
// // //                     config: config,
// // //                     playerIds: playerIds,
// // //                     playerDisplayNames: displayNames,
// // //                     packId: packId,
// // //                     isOwner: isOwner,
// // //                     isModerator: isModerator,
// // //                   ),
// // //                   _ => TodGameScreen(
// // //                     roomId: roomId,
// // //                     config: config,
// // //                     playerIds: playerIds,
// // //                     playerDisplayNames: displayNames,
// // //                     packId: packId,
// // //                     isOwner: isOwner,
// // //                     isModerator: isModerator,
// // //                     sessionId: extra['sessionId'] as String?,
// // //                   ),
// // //                 };
// // //               },
// // //             ),
// // //           ],
// // //         ),

// // //         GoRoute(
// // //           path: '/profile/edit',
// // //           parentNavigatorKey: rootKey,
// // //           builder: (_, __) => const EditProfileScreen(),
// // //         ),
// // //         GoRoute(
// // //           path: '/user/:userId',
// // //           name: RouteNames.userProfile,
// // //           parentNavigatorKey: rootKey,
// // //           builder: (_, state) =>
// // //               UserProfileScreen(userId: state.pathParameters['userId']!),
// // //         ),
// // //         GoRoute(
// // //           path: '/profile/change-username',
// // //           parentNavigatorKey: rootKey,
// // //           builder: (_, __) => const ChangeUsernameScreen(),
// // //         ),
// // //         GoRoute(
// // //           path: RouteNames.wallet,
// // //           parentNavigatorKey: rootKey,
// // //           builder: (_, __) => const WalletHomeScreen(),
// // //         ),
// // //         GoRoute(
// // //           path: RouteNames.notifications,
// // //           parentNavigatorKey: rootKey,
// // //           builder: (_, __) => const NotificationsScreen(),
// // //         ),
// // //         GoRoute(
// // //           path: '/creator',
// // //           parentNavigatorKey: rootKey,
// // //           builder: (_, __) => const CreatorDashboardScreen(),
// // //           routes: [
// // //             GoRoute(
// // //               path: 'create-pack',
// // //               builder: (_, __) => const CreatePackScreen(),
// // //             ),
// // //           ],
// // //         ),
// // //         GoRoute(
// // //           path: RouteNames.settings,
// // //           parentNavigatorKey: rootKey,
// // //           builder: (_, __) => const SettingsScreen(),
// // //         ),
// // //         GoRoute(
// // //           path: RouteNames.offline,
// // //           parentNavigatorKey: rootKey,
// // //           builder: (_, __) => const OfflineGameScreen(),
// // //         ),
// // //       ],

// // //       errorBuilder: (_, state) => NotFoundScreen(error: state.error),
// // //     );
// // //     return _instance!;
// // //   }
// // // }

// // import 'package:flutter/material.dart';
// // import 'package:go_router/go_router.dart';
// // import 'package:jma3a/features/games/presentation/meme_game_screen.dart';
// // import 'package:jma3a/features/games/presentation/nhie_game_screen.dart';
// // import 'package:jma3a/features/packs/domain/pack_entity.dart';
// // import 'package:provider/provider.dart';

// // import '../providers/auth_provider.dart';
// // import 'route_names.dart';
// // import '../../features/auth/presentation/screens/splash_screen.dart';
// // import '../../features/auth/presentation/screens/email_screen.dart';
// // import '../../features/auth/presentation/screens/otp_screen.dart';
// // import '../../features/auth/presentation/screens/onboarding_screen.dart';
// // import '../../features/rooms/presentation/screens/room_browser_screen.dart';
// // import '../../features/rooms/presentation/screens/lobby_screen.dart';
// // import '../../features/packs/presentation/screens/marketplace_screen.dart';
// // import '../../features/profile/presentation/screens/profile_screen.dart';
// // import '../../features/profile/presentation/screens/edit_profile_screen.dart';
// // import '../../features/profile/presentation/screens/change_username_screen.dart';
// // import '../../features/settings/presentation/settings_screen.dart';
// // import '../../features/offline/presentation/screens/offline_game_screen.dart';
// // import '../../features/games/engine/base_game_engine.dart';
// // import '../../features/games/truth_or_dare/presentation/screens/tod_game_screen.dart';
// // import '../../features/packs/presentation/screens/pack_detail_screen.dart';
// // import '../../features/wallet/presentation/screens/wallet_home_screen.dart';
// // import '../../features/friends/presentation/screens/friends_screen.dart';
// // import '../../features/friends/presentation/screens/user_profile_screen.dart';
// // import '../../features/notifications/presentation/screens/notifications_screen.dart';
// // import '../../features/packs/presentation/screens/creator_dashboard_screen.dart';
// // import '../../features/packs/presentation/screens/create_pack_screen.dart';
// // // import '../../features/games/never_have_i_ever/presentation/nhie_game_screen.dart';
// // // import '../../features/games/meme_game/presentation/meme_game_screen.dart';
// // import '../../shared/screens/home_shell_screen.dart';
// // import '../../shared/screens/not_found_screen.dart';

// // class AppRouter {
// //   AppRouter._();

// //   static final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// //   static GoRouter? _instance;
// //   static GoRouter get router {
// //     assert(
// //       _instance != null,
// //       'AppRouter.router accessed before createRouter() was called.',
// //     );
// //     return _instance!;
// //   }

// //   static GoRouter createRouter(AuthProvider authProvider) {
// //     _instance = GoRouter(
// //       navigatorKey: rootKey,
// //       initialLocation: RouteNames.splash,
// //       debugLogDiagnostics: true,
// //       refreshListenable: authProvider,
// //       redirect: (context, state) {
// //         final auth = context.read<AuthProvider>();
// //         final loc = state.uri.toString();

// //         if (loc.contains('/room/') && auth.isLoggedIn && !auth.isGuest) {
// //           return null;
// //         }

// //         final alwaysPublic = [
// //           RouteNames.splash,
// //           RouteNames.authEmail,
// //           RouteNames.authOtp,
// //         ];
// //         final isPublic = alwaysPublic.any((r) => loc.startsWith(r));

// //         // Logged-in app routes — never redirect these
// //         final appRoutes = [
// //           RouteNames.home,
// //           RouteNames.settings,
// //           RouteNames.wallet,
// //           RouteNames.notifications,
// //           RouteNames.offline,
// //           '/profile',
// //           '/user/',
// //           '/marketplace',
// //           '/creator',
// //         ];
// //         if (auth.isLoggedIn &&
// //             !auth.isGuest &&
// //             appRoutes.any((r) => loc.startsWith(r))) {
// //           return null;
// //         }

// //         if (auth.isInitializing) {
// //           return loc == RouteNames.splash ? null : RouteNames.splash;
// //         }

// //         if (loc == RouteNames.splash) {
// //           if (auth.isGuest) return RouteNames.offline;
// //           if (!auth.isLoggedIn) return RouteNames.authEmail;
// //           if (auth.needsOnboarding) return RouteNames.onboarding;
// //           return RouteNames.home;
// //         }

// //         if (auth.isGuest) {
// //           return loc.startsWith(RouteNames.offline) ? null : RouteNames.offline;
// //         }

// //         if (!auth.isLoggedIn && !isPublic) {
// //           return RouteNames.authEmail;
// //         }

// //         if (auth.isLoggedIn &&
// //             auth.needsOnboarding &&
// //             (isPublic || loc == RouteNames.home) &&
// //             loc != RouteNames.onboarding) {
// //           return RouteNames.onboarding;
// //         }

// //         if (auth.isLoggedIn &&
// //             !auth.needsOnboarding &&
// //             isPublic &&
// //             loc != RouteNames.splash) {
// //           return RouteNames.home;
// //         }

// //         return null;
// //       },
// //       routes: [
// //         GoRoute(
// //           path: RouteNames.splash,
// //           builder: (_, __) => const SplashScreen(),
// //         ),
// //         GoRoute(
// //           path: RouteNames.authEmail,
// //           builder: (_, __) => const EmailScreen(),
// //         ),
// //         GoRoute(
// //           path: RouteNames.authOtp,
// //           builder: (_, state) => OtpScreen(email: state.extra as String? ?? ''),
// //         ),
// //         GoRoute(
// //           path: RouteNames.onboarding,
// //           builder: (_, __) => const OnboardingScreen(),
// //         ),

// //         GoRoute(
// //           path: RouteNames.home,
// //           builder: (_, __) => const HomeShellScreen(),
// //         ),

// //         // ── Pack detail — full-screen above shell ─────────────────────────
// //         GoRoute(
// //           path: '/marketplace/pack/:packId',
// //           name: RouteNames.packDetail,
// //           parentNavigatorKey: rootKey,
// //           builder: (_, state) =>
// //               PackDetailScreen(packId: state.pathParameters['packId']!),
// //         ),
// //         GoRoute(
// //           path: '/home/room/:roomId',
// //           name: RouteNames.room,
// //           parentNavigatorKey: rootKey,
// //           builder: (_, state) =>
// //               LobbyScreen(roomId: state.pathParameters['roomId']!),
// //           routes: [
// //             GoRoute(
// //               path: 'game',
// //               name: 'game',
// //               parentNavigatorKey: rootKey,
// //               builder: (_, state) {
// //                 final extra = state.extra as Map<String, dynamic>? ?? {};
// //                 final config =
// //                     extra['config'] as GameConfig? ??
// //                     const GameConfig(
// //                       maxRounds: 10,
// //                       turnTimerSeconds: 60,
// //                       allowSkip: true,
// //                       allowSpicy: false,
// //                     );
// //                 final roomId = state.pathParameters['roomId']!;
// //                 final playerIds =
// //                     (extra['playerIds'] as List?)?.cast<String>() ?? [];
// //                 final displayNames =
// //                     (extra['displayNames'] as Map?)?.cast<String, String>() ??
// //                     {};
// //                 final packId = extra['packId'] as String? ?? '';
// //                 final isOwner = extra['isOwner'] as bool? ?? false;
// //                 final isModerator = extra['isModerator'] as bool? ?? false;
// //                 final gameType =
// //                     extra['gameType'] as String? ?? 'truth_or_dare';

// //                 return switch (gameType) {
// //                   'never_have_i_ever' => NhieGameScreen(
// //                     roomId: roomId,
// //                     config: config,
// //                     playerIds: playerIds,
// //                     playerDisplayNames: displayNames,
// //                     packId: packId,
// //                     isOwner: isOwner,
// //                     isModerator: isModerator,
// //                   ),
// //                   'meme_game' => MemeGameScreen(
// //                     roomId: roomId,
// //                     config: config,
// //                     playerIds: playerIds,
// //                     playerDisplayNames: displayNames,
// //                     packId: packId,
// //                     isOwner: isOwner,
// //                     isModerator: isModerator,
// //                   ),
// //                   _ => TodGameScreen(
// //                     roomId: roomId,
// //                     config: config,
// //                     playerIds: playerIds,
// //                     playerDisplayNames: displayNames,
// //                     packId: packId,
// //                     isOwner: isOwner,
// //                     isModerator: isModerator,
// //                     sessionId: extra['sessionId'] as String?,
// //                   ),
// //                 };
// //               },
// //             ),
// //           ],
// //         ),

// //         GoRoute(
// //           path: '/profile/edit',
// //           parentNavigatorKey: rootKey,
// //           builder: (_, __) => const EditProfileScreen(),
// //         ),
// //         GoRoute(
// //           path: '/user/:userId',
// //           name: RouteNames.userProfile,
// //           parentNavigatorKey: rootKey,
// //           builder: (_, state) =>
// //               UserProfileScreen(userId: state.pathParameters['userId']!),
// //         ),
// //         GoRoute(
// //           path: '/profile/change-username',
// //           parentNavigatorKey: rootKey,
// //           builder: (_, __) => const ChangeUsernameScreen(),
// //         ),
// //         GoRoute(
// //           path: RouteNames.wallet,
// //           parentNavigatorKey: rootKey,
// //           builder: (_, __) => const WalletHomeScreen(),
// //         ),
// //         GoRoute(
// //           path: RouteNames.notifications,
// //           parentNavigatorKey: rootKey,
// //           builder: (_, __) => const NotificationsScreen(),
// //         ),
// //         GoRoute(
// //           path: '/creator',
// //           parentNavigatorKey: rootKey,
// //           builder: (_, __) => const CreatorDashboardScreen(),
// //           routes: [
// //             GoRoute(
// //               path: 'create-pack',
// //               builder: (_, state) {
// //                 final extra = state.extra as Map<String, dynamic>?;
// //                 final packId = extra?['packId'] as String?;
// //                 final pack = extra?['draft'] as PackEntity?;
// //                 return CreatePackScreen(
// //                   existingPackId: packId,
// //                   existingPack: pack,
// //                 );
// //               },
// //             ),
// //           ],
// //         ),
// //         GoRoute(
// //           path: RouteNames.settings,
// //           parentNavigatorKey: rootKey,
// //           builder: (_, __) => const SettingsScreen(),
// //         ),
// //         GoRoute(
// //           path: RouteNames.offline,
// //           parentNavigatorKey: rootKey,
// //           builder: (_, __) => const OfflineGameScreen(),
// //         ),
// //       ],

// //       errorBuilder: (_, state) => NotFoundScreen(error: state.error),
// //     );
// //     return _instance!;
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:jma3a/features/games/presentation/meme_game_screen.dart';
// import 'package:jma3a/features/games/presentation/nhie_game_screen.dart';
// import 'package:jma3a/features/packs/domain/pack_entity.dart';
// import 'package:provider/provider.dart';

// import '../providers/auth_provider.dart';
// import 'route_names.dart';
// import '../../features/auth/presentation/screens/splash_screen.dart';
// import '../../features/auth/presentation/screens/email_screen.dart';
// import '../../features/auth/presentation/screens/otp_screen.dart';
// import '../../features/auth/presentation/screens/onboarding_screen.dart';
// import '../../features/rooms/presentation/screens/room_browser_screen.dart';
// import '../../features/rooms/presentation/screens/lobby_screen.dart';
// import '../../features/packs/presentation/screens/marketplace_screen.dart';
// import '../../features/profile/presentation/screens/profile_screen.dart';
// import '../../features/profile/presentation/screens/edit_profile_screen.dart';
// import '../../features/profile/presentation/screens/change_username_screen.dart';
// import '../../features/settings/presentation/settings_screen.dart';
// import '../../features/offline/presentation/screens/offline_game_screen.dart';
// import '../../features/games/engine/base_game_engine.dart';
// import '../../features/games/truth_or_dare/presentation/screens/tod_game_screen.dart';
// import '../../features/packs/presentation/screens/pack_detail_screen.dart';
// import '../../features/wallet/presentation/screens/wallet_home_screen.dart';
// import '../../features/friends/presentation/screens/friends_screen.dart';
// import '../../features/friends/presentation/screens/user_profile_screen.dart';
// import '../../features/notifications/presentation/screens/notifications_screen.dart';
// import '../../features/packs/presentation/screens/creator_dashboard_screen.dart';
// import '../../features/packs/presentation/screens/create_pack_screen.dart';
// // import '../../features/games/never_have_i_ever/presentation/nhie_game_screen.dart';
// // import '../../features/games/meme_game/presentation/meme_game_screen.dart';
// import '../../shared/screens/home_shell_screen.dart';
// import '../../shared/screens/not_found_screen.dart';

// class AppRouter {
//   AppRouter._();

//   static final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

//   static GoRouter? _instance;
//   static GoRouter get router {
//     assert(
//       _instance != null,
//       'AppRouter.router accessed before createRouter() was called.',
//     );
//     return _instance!;
//   }

//   static GoRouter createRouter(AuthProvider authProvider) {
//     _instance = GoRouter(
//       navigatorKey: rootKey,
//       initialLocation: RouteNames.splash,
//       debugLogDiagnostics: true,
//       refreshListenable: authProvider,
//       redirect: (context, state) {
//         final auth = context.read<AuthProvider>();
//         final loc = state.uri.toString();

//         if (loc.contains('/room/') && auth.isLoggedIn && !auth.isGuest) {
//           return null;
//         }

//         final alwaysPublic = [
//           RouteNames.splash,
//           RouteNames.authEmail,
//           RouteNames.authOtp,
//         ];
//         final isPublic = alwaysPublic.any((r) => loc.startsWith(r));

//         // Logged-in app routes — never redirect these
//         final appRoutes = [
//           RouteNames.home,
//           RouteNames.settings,
//           RouteNames.wallet,
//           RouteNames.notifications,
//           RouteNames.offline,
//           '/profile',
//           '/user/',
//           '/marketplace',
//           '/creator',
//         ];
//         if (auth.isLoggedIn &&
//             !auth.isGuest &&
//             appRoutes.any((r) => loc.startsWith(r))) {
//           return null;
//         }

//         if (auth.isInitializing) {
//           return loc == RouteNames.splash ? null : RouteNames.splash;
//         }

//         if (loc == RouteNames.splash) {
//           if (auth.isGuest) return RouteNames.offline;
//           if (!auth.isLoggedIn) return RouteNames.authEmail;
//           if (auth.needsOnboarding) return RouteNames.onboarding;
//           return RouteNames.home;
//         }

//         if (auth.isGuest) {
//           return loc.startsWith(RouteNames.offline) ? null : RouteNames.offline;
//         }

//         if (!auth.isLoggedIn && !isPublic) {
//           return RouteNames.authEmail;
//         }

//         if (auth.isLoggedIn &&
//             auth.needsOnboarding &&
//             (isPublic || loc == RouteNames.home) &&
//             loc != RouteNames.onboarding) {
//           return RouteNames.onboarding;
//         }

//         if (auth.isLoggedIn &&
//             !auth.needsOnboarding &&
//             isPublic &&
//             loc != RouteNames.splash) {
//           return RouteNames.home;
//         }

//         return null;
//       },
//       routes: [
//         GoRoute(
//           path: RouteNames.splash,
//           builder: (_, __) => const SplashScreen(),
//         ),
//         GoRoute(
//           path: RouteNames.authEmail,
//           builder: (_, __) => const EmailScreen(),
//         ),
//         GoRoute(
//           path: RouteNames.authOtp,
//           builder: (_, state) => OtpScreen(email: state.extra as String? ?? ''),
//         ),
//         GoRoute(
//           path: RouteNames.onboarding,
//           builder: (_, __) => const OnboardingScreen(),
//         ),

//         GoRoute(
//           path: RouteNames.home,
//           builder: (_, __) => const HomeShellScreen(),
//         ),

//         // ── Pack detail — full-screen above shell ─────────────────────────
//         GoRoute(
//           path: '/marketplace/pack/:packId',
//           name: RouteNames.packDetail,
//           parentNavigatorKey: rootKey,
//           builder: (_, state) =>
//               PackDetailScreen(packId: state.pathParameters['packId']!),
//         ),
//         GoRoute(
//           path: '/home/room/:roomId',
//           name: RouteNames.room,
//           parentNavigatorKey: rootKey,
//           builder: (_, state) =>
//               LobbyScreen(roomId: state.pathParameters['roomId']!),
//           routes: [
//             GoRoute(
//               path: 'game',
//               name: 'game',
//               parentNavigatorKey: rootKey,
//               builder: (_, state) {
//                 final extra = state.extra as Map<String, dynamic>? ?? {};
//                 final config =
//                     extra['config'] as GameConfig? ??
//                     const GameConfig(
//                       maxRounds: 10,
//                       turnTimerSeconds: 60,
//                       allowSkip: true,
//                       allowSpicy: false,
//                     );
//                 final roomId = state.pathParameters['roomId']!;
//                 final playerIds =
//                     (extra['playerIds'] as List?)?.cast<String>() ?? [];
//                 final displayNames =
//                     (extra['displayNames'] as Map?)?.cast<String, String>() ??
//                     {};
//                 final packId = extra['packId'] as String? ?? '';
//                 final packCoverUrl = extra['packCoverUrl'] as String? ?? '';
//                 final isOwner = extra['isOwner'] as bool? ?? false;
//                 final isModerator = extra['isModerator'] as bool? ?? false;
//                 final gameType =
//                     extra['gameType'] as String? ?? 'truth_or_dare';

//                 return switch (gameType) {
//                   'never_have_i_ever' => NhieGameScreen(
//                     roomId: roomId,
//                     config: config,
//                     playerIds: playerIds,
//                     playerDisplayNames: displayNames,
//                     packId: packId,
//                     isOwner: isOwner,
//                     isModerator: isModerator,
//                   ),
//                   'meme_game' => MemeGameScreen(
//                     roomId: roomId,
//                     config: config,
//                     playerIds: playerIds,
//                     playerDisplayNames: displayNames,
//                     packId: packId,
//                     isOwner: isOwner,
//                     isModerator: isModerator,
//                   ),
//                   _ => TodGameScreen(
//                     roomId: roomId,
//                     config: config,
//                     playerIds: playerIds,
//                     playerDisplayNames: displayNames,
//                     packId: packId,
//                     packCoverUrl: packCoverUrl.isNotEmpty ? packCoverUrl : null,
//                     isOwner: isOwner,
//                     isModerator: isModerator,
//                     sessionId: extra['sessionId'] as String?,
//                   ),
//                 };
//               },
//             ),
//           ],
//         ),

//         GoRoute(
//           path: '/profile/edit',
//           parentNavigatorKey: rootKey,
//           builder: (_, __) => const EditProfileScreen(),
//         ),
//         GoRoute(
//           path: '/user/:userId',
//           name: RouteNames.userProfile,
//           parentNavigatorKey: rootKey,
//           builder: (_, state) =>
//               UserProfileScreen(userId: state.pathParameters['userId']!),
//         ),
//         GoRoute(
//           path: '/profile/change-username',
//           parentNavigatorKey: rootKey,
//           builder: (_, __) => const ChangeUsernameScreen(),
//         ),
//         GoRoute(
//           path: RouteNames.wallet,
//           parentNavigatorKey: rootKey,
//           builder: (_, __) => const WalletHomeScreen(),
//         ),
//         GoRoute(
//           path: RouteNames.notifications,
//           parentNavigatorKey: rootKey,
//           builder: (_, __) => const NotificationsScreen(),
//         ),
//         GoRoute(
//           path: '/creator',
//           parentNavigatorKey: rootKey,
//           builder: (_, __) => const CreatorDashboardScreen(),
//           routes: [
//             GoRoute(
//               path: 'create-pack',
//               builder: (_, state) {
//                 final extra = state.extra as Map<String, dynamic>?;
//                 final packId = extra?['packId'] as String?;
//                 final pack = extra?['draft'] as PackEntity?;
//                 return CreatePackScreen(
//                   existingPackId: packId,
//                   existingPack: pack,
//                 );
//               },
//             ),
//           ],
//         ),
//         GoRoute(
//           path: RouteNames.settings,
//           parentNavigatorKey: rootKey,
//           builder: (_, __) => const SettingsScreen(),
//         ),
//         GoRoute(
//           path: RouteNames.offline,
//           parentNavigatorKey: rootKey,
//           builder: (_, __) => const OfflineGameScreen(),
//         ),
//       ],

//       errorBuilder: (_, state) => NotFoundScreen(error: state.error),
//     );
//     return _instance!;
//   }
// }

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jma3a/features/games/presentation/meme_game_screen.dart';
import 'package:jma3a/features/games/presentation/nhie_game_screen.dart';
import 'package:jma3a/features/packs/domain/pack_entity.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'route_names.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/email_screen.dart';
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
// import '../../features/games/never_have_i_ever/presentation/nhie_game_screen.dart';
// import '../../features/games/meme_game/presentation/meme_game_screen.dart';
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

  static GoRouter createRouter(AuthProvider authProvider) {
    _instance = GoRouter(
      navigatorKey: rootKey,
      initialLocation: RouteNames.splash,
      debugLogDiagnostics: true,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        final loc = state.uri.toString();

        if (loc.contains('/room/') && auth.isLoggedIn && !auth.isGuest) {
          return null;
        }

        final alwaysPublic = [
          RouteNames.splash,
          RouteNames.authEmail,
          RouteNames.authOtp,
        ];
        final isPublic = alwaysPublic.any((r) => loc.startsWith(r));

        // Logged-in app routes — never redirect these
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
        ];
        if (auth.isLoggedIn &&
            !auth.isGuest &&
            appRoutes.any((r) => loc.startsWith(r))) {
          return null;
        }

        if (auth.isInitializing) {
          return loc == RouteNames.splash ? null : RouteNames.splash;
        }

        if (loc == RouteNames.splash) {
          if (auth.isGuest) return RouteNames.offline;
          if (!auth.isLoggedIn) return RouteNames.authEmail;
          if (auth.needsOnboarding) return RouteNames.onboarding;
          return RouteNames.home;
        }

        if (auth.isGuest) {
          return loc.startsWith(RouteNames.offline) ? null : RouteNames.offline;
        }

        if (!auth.isLoggedIn && !isPublic) {
          return RouteNames.authEmail;
        }

        if (auth.isLoggedIn &&
            auth.needsOnboarding &&
            (isPublic || loc == RouteNames.home) &&
            loc != RouteNames.onboarding) {
          return RouteNames.onboarding;
        }

        if (auth.isLoggedIn &&
            !auth.needsOnboarding &&
            isPublic &&
            loc != RouteNames.splash) {
          return RouteNames.home;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: RouteNames.splash,
          builder: (_, __) => const SplashScreen(),
        ),
        GoRoute(
          path: RouteNames.authEmail,
          builder: (_, __) => const EmailScreen(),
        ),
        GoRoute(
          path: RouteNames.authOtp,
          builder: (_, state) => OtpScreen(email: state.extra as String? ?? ''),
        ),
        GoRoute(
          path: RouteNames.onboarding,
          builder: (_, __) => const OnboardingScreen(),
        ),

        GoRoute(
          path: RouteNames.home,
          builder: (_, __) => const HomeShellScreen(),
        ),

        // ── Pack detail — full-screen above shell ─────────────────────────
        GoRoute(
          path: '/marketplace/pack/:packId',
          name: RouteNames.packDetail,
          parentNavigatorKey: rootKey,
          builder: (_, state) =>
              PackDetailScreen(packId: state.pathParameters['packId']!),
        ),
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
                final gameType =
                    extra['gameType'] as String? ?? 'truth_or_dare';

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
                    sessionId: extra['sessionId'] as String?,
                  ),
                };
              },
            ),
          ],
        ),

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
        GoRoute(
          path: RouteNames.settings,
          parentNavigatorKey: rootKey,
          builder: (_, __) => const SettingsScreen(),
        ),
        GoRoute(
          path: RouteNames.offline,
          parentNavigatorKey: rootKey,
          builder: (_, __) => const OfflineGameScreen(),
        ),
      ],

      errorBuilder: (_, state) => NotFoundScreen(error: state.error),
    );
    return _instance!;
  }
}
