// // // // // // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // // // // // import 'package:flutter_localizations/flutter_localizations.dart';
// // // // // // // // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // // // // // // // import 'core/l10n/generated/app_localizations.dart';
// // // // // // // // // // // // // // import 'core/providers/app_provider.dart';
// // // // // // // // // // // // // // import 'core/providers/auth_provider.dart';
// // // // // // // // // // // // // // import 'core/providers/connectivity_provider.dart';
// // // // // // // // // // // // // // import 'core/router/app_router.dart';
// // // // // // // // // // // // // // import 'core/theme/app_theme.dart';
// // // // // // // // // // // // // // import 'features/friends/presentation/friends_provider.dart';
// // // // // // // // // // // // // // import 'features/notifications/presentation/notification_provider.dart';
// // // // // // // // // // // // // // import 'features/packs/presentation/pack_provider.dart';
// // // // // // // // // // // // // // import 'features/wallet/presentation/wallet_provider.dart';
// // // // // // // // // // // // // // import 'core/di/service_locator.dart';

// // // // // // // // // // // // // // class Jma3aApp extends StatelessWidget {
// // // // // // // // // // // // // //   const Jma3aApp({super.key});

// // // // // // // // // // // // // //   @override
// // // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // // //     return MultiProvider(
// // // // // // // // // // // // // //       providers: [
// // // // // // // // // // // // // //         // ── App-level providers (root, never disposed) ────────────────
// // // // // // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // // // // // //           create: (_) => ConnectivityProvider(
// // // // // // // // // // // // // //             connectivityService: sl.connectivityService,
// // // // // // // // // // // // // //           ),
// // // // // // // // // // // // // //         ),
// // // // // // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // // // // // //           create: (_) => AppProvider(
// // // // // // // // // // // // // //             localStorageService: sl.localStorageService,
// // // // // // // // // // // // // //           )..initialize(),
// // // // // // // // // // // // // //         ),
// // // // // // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // // // // // //           create: (_) => AuthProvider(
// // // // // // // // // // // // // //             authRepository: sl.authRepository,
// // // // // // // // // // // // // //             secureStorage: sl.secureStorageService,
// // // // // // // // // // // // // //           )..initialize(),
// // // // // // // // // // // // // //         ),

// // // // // // // // // // // // // //         // ── Auth-dependent providers (hydrated after login) ───────────
// // // // // // // // // // // // // //         // These listen to AuthProvider and self-initialize when user is set.
// // // // // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// // // // // // // // // // // // // //           create: (_) => FriendsProvider(
// // // // // // // // // // // // // //             friendsRepository: sl.friendsRepository,
// // // // // // // // // // // // // //           ),
// // // // // // // // // // // // // //           update: (_, auth, friends) =>
// // // // // // // // // // // // // //               (friends ?? FriendsProvider(friendsRepository: sl.friendsRepository))
// // // // // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // // // // //         ),
// // // // // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// // // // // // // // // // // // // //           create: (_) => NotificationProvider(
// // // // // // // // // // // // // //             notificationRepository: sl.notificationRepository,
// // // // // // // // // // // // // //           ),
// // // // // // // // // // // // // //           update: (_, auth, notifs) =>
// // // // // // // // // // // // // //               (notifs ?? NotificationProvider(notificationRepository: sl.notificationRepository))
// // // // // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // // // // //         ),
// // // // // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// // // // // // // // // // // // // //           create: (_) => WalletProvider(
// // // // // // // // // // // // // //             walletRepository: sl.walletRepository,
// // // // // // // // // // // // // //           ),
// // // // // // // // // // // // // //           update: (_, auth, wallet) =>
// // // // // // // // // // // // // //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// // // // // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // // // // //         ),
// // // // // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// // // // // // // // // // // // // //           create: (_) => PackProvider(
// // // // // // // // // // // // // //             packRepository: sl.packRepository,
// // // // // // // // // // // // // //             packSyncService: sl.packSyncService,
// // // // // // // // // // // // // //           ),
// // // // // // // // // // // // // //           update: (_, auth, packs) =>
// // // // // // // // // // // // // //               (packs ?? PackProvider(
// // // // // // // // // // // // // //                 packRepository: sl.packRepository,
// // // // // // // // // // // // // //                 packSyncService: sl.packSyncService,
// // // // // // // // // // // // // //               ))..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // // // // //         ),
// // // // // // // // // // // // // //       ],
// // // // // // // // // // // // // //       child: Consumer<AppProvider>(
// // // // // // // // // // // // // //         builder: (context, appProvider, _) {
// // // // // // // // // // // // // //           return MaterialApp.router(
// // // // // // // // // // // // // //             title: 'Jma3a',
// // // // // // // // // // // // // //             debugShowCheckedModeBanner: false,

// // // // // // // // // // // // // //             // ── Theme ─────────────────────────────────────────────────
// // // // // // // // // // // // // //             theme: AppTheme.light(),
// // // // // // // // // // // // // //             darkTheme: AppTheme.dark(),
// // // // // // // // // // // // // //             themeMode: appProvider.themeMode,

// // // // // // // // // // // // // //             // ── Routing ───────────────────────────────────────────────
// // // // // // // // // // // // // //             routerConfig: AppRouter.router,

// // // // // // // // // // // // // //             // ── Localization ──────────────────────────────────────────
// // // // // // // // // // // // // //             locale: appProvider.locale,
// // // // // // // // // // // // // //             localizationsDelegates: const [
// // // // // // // // // // // // // //               AppLocalizations.delegate,
// // // // // // // // // // // // // //               GlobalMaterialLocalizations.delegate,
// // // // // // // // // // // // // //               GlobalWidgetsLocalizations.delegate,
// // // // // // // // // // // // // //               GlobalCupertinoLocalizations.delegate,
// // // // // // // // // // // // // //             ],
// // // // // // // // // // // // // //             supportedLocales: AppLocalizations.supportedLocales,

// // // // // // // // // // // // // //             // ── Builder: global overlays (connectivity banner, etc.) ──
// // // // // // // // // // // // // //             builder: (context, child) {
// // // // // // // // // // // // // //               return _AppShell(child: child ?? const SizedBox.shrink());
// // // // // // // // // // // // // //             },
// // // // // // // // // // // // // //           );
// // // // // // // // // // // // // //         },
// // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // //     );
// // // // // // // // // // // // // //   }
// // // // // // // // // // // // // // }

// // // // // // // // // // // // // // /// Wraps every screen with global overlays and layout constraints.
// // // // // // // // // // // // // // class _AppShell extends StatelessWidget {
// // // // // // // // // // // // // //   const _AppShell({required this.child});
// // // // // // // // // // // // // //   final Widget child;

// // // // // // // // // // // // // //   @override
// // // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // // //     return Consumer<ConnectivityProvider>(
// // // // // // // // // // // // // //       builder: (context, connectivity, _) {
// // // // // // // // // // // // // //         return Stack(
// // // // // // // // // // // // // //           children: [
// // // // // // // // // // // // // //             child,
// // // // // // // // // // // // // //             // Connectivity banner slides in when offline
// // // // // // // // // // // // // //             if (!connectivity.isOnline)
// // // // // // // // // // // // // //               const Positioned(
// // // // // // // // // // // // // //                 bottom: 0,
// // // // // // // // // // // // // //                 left: 0,
// // // // // // // // // // // // // //                 right: 0,
// // // // // // // // // // // // // //                 child: _OfflineBanner(),
// // // // // // // // // // // // // //               ),
// // // // // // // // // // // // // //           ],
// // // // // // // // // // // // // //         );
// // // // // // // // // // // // // //       },
// // // // // // // // // // // // // //     );
// // // // // // // // // // // // // //   }
// // // // // // // // // // // // // // }

// // // // // // // // // // // // // // class _OfflineBanner extends StatelessWidget {
// // // // // // // // // // // // // //   const _OfflineBanner();

// // // // // // // // // // // // // //   @override
// // // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // // //     final theme = Theme.of(context);
// // // // // // // // // // // // // //     return Material(
// // // // // // // // // // // // // //       color: theme.colorScheme.error,
// // // // // // // // // // // // // //       child: SafeArea(
// // // // // // // // // // // // // //         top: false,
// // // // // // // // // // // // // //         child: Padding(
// // // // // // // // // // // // // //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // // // // // // // // // // // //           child: Row(
// // // // // // // // // // // // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // // // // // // // // // // // //             children: [
// // // // // // // // // // // // // //               Icon(Icons.wifi_off_rounded, size: 16, color: theme.colorScheme.onError),
// // // // // // // // // // // // // //               const SizedBox(width: 8),
// // // // // // // // // // // // // //               Text(
// // // // // // // // // // // // // //                 AppLocalizations.of(context).noInternetConnection,
// // // // // // // // // // // // // //                 style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // // // // // // // //                   color: theme.colorScheme.onError,
// // // // // // // // // // // // // //                   fontWeight: FontWeight.w500,
// // // // // // // // // // // // // //                 ),
// // // // // // // // // // // // // //               ),
// // // // // // // // // // // // // //             ],
// // // // // // // // // // // // // //           ),
// // // // // // // // // // // // // //         ),
// // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // //     );
// // // // // // // // // // // // // //   }
// // // // // // // // // // // // // // }

// // // // // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // // // // import 'package:flutter_localizations/flutter_localizations.dart';
// // // // // // // // // // // // // import 'package:jma3a/features/profile/presentation/profile_provider.dart';
// // // // // // // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // // // // // // import 'core/l10n/generated/app_localizations.dart';
// // // // // // // // // // // // // import 'core/providers/app_provider.dart';
// // // // // // // // // // // // // import 'core/providers/auth_provider.dart';
// // // // // // // // // // // // // import 'core/providers/connectivity_provider.dart';
// // // // // // // // // // // // // import 'core/router/app_router.dart';
// // // // // // // // // // // // // import 'core/theme/app_theme.dart';
// // // // // // // // // // // // // import 'core/di/service_locator.dart';
// // // // // // // // // // // // // import 'features/friends/presentation/friends_provider.dart';
// // // // // // // // // // // // // import 'features/notifications/presentation/notification_provider.dart';
// // // // // // // // // // // // // import 'features/packs/presentation/pack_provider.dart';
// // // // // // // // // // // // // // import 'features/profile/presentation/profile_provider.dart';
// // // // // // // // // // // // // import 'features/wallet/presentation/wallet_provider.dart';

// // // // // // // // // // // // // class Jma3aApp extends StatelessWidget {
// // // // // // // // // // // // //   const Jma3aApp({super.key});

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // //     return MultiProvider(
// // // // // // // // // // // // //       providers: [
// // // // // // // // // // // // //         // ── Infrastructure (always alive) ─────────────────────────────────
// // // // // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // // // // //           create: (_) =>
// // // // // // // // // // // // //               ConnectivityProvider(connectivityService: sl.connectivityService),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // // // // //           create: (_) =>
// // // // // // // // // // // // //               AppProvider(localStorageService: sl.localStorageService)
// // // // // // // // // // // // //                 ..initialize(),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // // // // //           create: (_) => AuthProvider(
// // // // // // // // // // // // //             authRepository: sl.authRepository,
// // // // // // // // // // // // //             secureStorage: sl.secureStorageService,
// // // // // // // // // // // // //           )..initialize(),
// // // // // // // // // // // // //         ),

// // // // // // // // // // // // //         // ── Auth-scoped providers (hydrated/cleared on login/logout) ───────
// // // // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
// // // // // // // // // // // // //           create: (ctx) => ProfileProvider(
// // // // // // // // // // // // //             profileRepository: sl.profileRepository,
// // // // // // // // // // // // //             authProvider: ctx.read<AuthProvider>(),
// // // // // // // // // // // // //           ),
// // // // // // // // // // // // //           update: (_, auth, profile) =>
// // // // // // // // // // // // //               (profile ??
// // // // // // // // // // // // //                     ProfileProvider(
// // // // // // // // // // // // //                       profileRepository: sl.profileRepository,
// // // // // // // // // // // // //                       authProvider: auth,
// // // // // // // // // // // // //                     ))
// // // // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// // // // // // // // // // // // //           create: (_) =>
// // // // // // // // // // // // //               FriendsProvider(friendsRepository: sl.friendsRepository),
// // // // // // // // // // // // //           update: (_, auth, friends) =>
// // // // // // // // // // // // //               (friends ??
// // // // // // // // // // // // //                     FriendsProvider(friendsRepository: sl.friendsRepository))
// // // // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// // // // // // // // // // // // //           create: (_) => NotificationProvider(
// // // // // // // // // // // // //             notificationRepository: sl.notificationRepository,
// // // // // // // // // // // // //           ),
// // // // // // // // // // // // //           update: (_, auth, notifs) =>
// // // // // // // // // // // // //               (notifs ??
// // // // // // // // // // // // //                     NotificationProvider(
// // // // // // // // // // // // //                       notificationRepository: sl.notificationRepository,
// // // // // // // // // // // // //                     ))
// // // // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// // // // // // // // // // // // //           create: (_) => WalletProvider(walletRepository: sl.walletRepository),
// // // // // // // // // // // // //           update: (_, auth, wallet) =>
// // // // // // // // // // // // //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// // // // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// // // // // // // // // // // // //           create: (_) => PackProvider(
// // // // // // // // // // // // //             packRepository: sl.packRepository,
// // // // // // // // // // // // //             packSyncService: sl.packSyncService,
// // // // // // // // // // // // //           ),
// // // // // // // // // // // // //           update: (_, auth, packs) =>
// // // // // // // // // // // // //               (packs ??
// // // // // // // // // // // // //                     PackProvider(
// // // // // // // // // // // // //                       packRepository: sl.packRepository,
// // // // // // // // // // // // //                       packSyncService: sl.packSyncService,
// // // // // // // // // // // // //                     ))
// // // // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //       ],
// // // // // // // // // // // // //       child: Consumer<AppProvider>(
// // // // // // // // // // // // //         builder: (context, appProvider, _) {
// // // // // // // // // // // // //           return MaterialApp.router(
// // // // // // // // // // // // //             title: 'Jma3a',
// // // // // // // // // // // // //             debugShowCheckedModeBanner: false,
// // // // // // // // // // // // //             theme: AppTheme.light(),
// // // // // // // // // // // // //             darkTheme: AppTheme.dark(),
// // // // // // // // // // // // //             themeMode: appProvider.themeMode,
// // // // // // // // // // // // //             routerConfig: AppRouter.router,
// // // // // // // // // // // // //             locale: appProvider.locale,
// // // // // // // // // // // // //             localizationsDelegates: const [
// // // // // // // // // // // // //               AppLocalizations.delegate,
// // // // // // // // // // // // //               GlobalMaterialLocalizations.delegate,
// // // // // // // // // // // // //               GlobalWidgetsLocalizations.delegate,
// // // // // // // // // // // // //               GlobalCupertinoLocalizations.delegate,
// // // // // // // // // // // // //             ],
// // // // // // // // // // // // //             supportedLocales: AppLocalizations.supportedLocales,
// // // // // // // // // // // // //             builder: (context, child) =>
// // // // // // // // // // // // //                 _AppShell(child: child ?? const SizedBox.shrink()),
// // // // // // // // // // // // //           );
// // // // // // // // // // // // //         },
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //   }
// // // // // // // // // // // // // }

// // // // // // // // // // // // // // class _AppShell extends StatefulWidget {
// // // // // // // // // // // // // //   const _AppShell({required this.child});
// // // // // // // // // // // // // //   final Widget child;

// // // // // // // // // // // // // //   @override
// // // // // // // // // // // // // //   State<_AppShell> createState() => _AppShellState();
// // // // // // // // // // // // // // }

// // // // // // // // // // // // // // class _AppShellState extends State<_AppShell> {
// // // // // // // // // // // // // //   @override
// // // // // // // // // // // // // //   void initState() {
// // // // // // // // // // // // // //     super.initState();
// // // // // // // // // // // // // //     // Wire OneSignal foreground handler → NotificationProvider toast queue
// // // // // // // // // // // // // //     sl.notificationService.registerForegroundHandler((type, title, body, data) {
// // // // // // // // // // // // // //       context.read<NotificationProvider>().pushToast(
// // // // // // // // // // // // // //         type: type,
// // // // // // // // // // // // // //         title: title,
// // // // // // // // // // // // // //         body: body,
// // // // // // // // // // // // // //         data: data,
// // // // // // // // // // // // // //       );
// // // // // // // // // // // // // //     });
// // // // // // // // // // // // // //   }

// // // // // // // // // // // // // //   @override
// // // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // // //     return Consumer<ConnectivityProvider>(
// // // // // // // // // // // // // //       builder: (context, connectivity, child) => Stack(
// // // // // // // // // // // // // //         children: [
// // // // // // // // // // // // // //           child!,
// // // // // // // // // // // // // //           if (!connectivity.isOnline)
// // // // // // // // // // // // // //             const Positioned(
// // // // // // // // // // // // // //               bottom: 0,
// // // // // // // // // // // // // //               left: 0,
// // // // // // // // // // // // // //               right: 0,
// // // // // // // // // // // // // //               child: _OfflineBanner(),
// // // // // // // // // // // // // //             ),
// // // // // // // // // // // // // //         ],
// // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // //     );
// // // // // // // // // // // // // //   }
// // // // // // // // // // // // // // }

// // // // // // // // // // // // // class _AppShell extends StatefulWidget {
// // // // // // // // // // // // //   const _AppShell({required this.child});
// // // // // // // // // // // // //   final Widget child;

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   State<_AppShell> createState() => _AppShellState();
// // // // // // // // // // // // // }

// // // // // // // // // // // // // class _AppShellState extends State<_AppShell> {
// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   void initState() {
// // // // // // // // // // // // //     super.initState();
// // // // // // // // // // // // //     // Use WidgetsBinding to ensure context is available after build
// // // // // // // // // // // // //     WidgetsBinding.instance.addPostFrameCallback((_) {
// // // // // // // // // // // // //       if (mounted) {
// // // // // // // // // // // // //         // Wire OneSignal foreground handler → NotificationProvider toast queue
// // // // // // // // // // // // //         sl.notificationService.registerForegroundHandler((
// // // // // // // // // // // // //           type,
// // // // // // // // // // // // //           title,
// // // // // // // // // // // // //           body,
// // // // // // // // // // // // //           data,
// // // // // // // // // // // // //         ) {
// // // // // // // // // // // // //           // Use mounted check before accessing context
// // // // // // // // // // // // //           if (mounted) {
// // // // // // // // // // // // //             final notificationProvider = context.read<NotificationProvider>();
// // // // // // // // // // // // //             notificationProvider.pushToast(
// // // // // // // // // // // // //               type: type,
// // // // // // // // // // // // //               title: title,
// // // // // // // // // // // // //               body: body,
// // // // // // // // // // // // //               data: data,
// // // // // // // // // // // // //             );
// // // // // // // // // // // // //           }
// // // // // // // // // // // // //         });
// // // // // // // // // // // // //       }
// // // // // // // // // // // // //     });
// // // // // // // // // // // // //   }

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // //     return Consumer<ConnectivityProvider>(
// // // // // // // // // // // // //       builder: (context, connectivity, child) {
// // // // // // // // // // // // //         return Stack(
// // // // // // // // // // // // //           children: [
// // // // // // // // // // // // //             // Use the widget.child instead of child! from Consumer
// // // // // // // // // // // // //             widget.child,
// // // // // // // // // // // // //             if (!connectivity.isOnline)
// // // // // // // // // // // // //               const Positioned(
// // // // // // // // // // // // //                 bottom: 0,
// // // // // // // // // // // // //                 left: 0,
// // // // // // // // // // // // //                 right: 0,
// // // // // // // // // // // // //                 child: _OfflineBanner(),
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //           ],
// // // // // // // // // // // // //         );
// // // // // // // // // // // // //       },
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //   }
// // // // // // // // // // // // // }

// // // // // // // // // // // // // class _OfflineBanner extends StatelessWidget {
// // // // // // // // // // // // //   const _OfflineBanner();

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // //     final theme = Theme.of(context);
// // // // // // // // // // // // //     return Material(
// // // // // // // // // // // // //       color: theme.colorScheme.error,
// // // // // // // // // // // // //       child: SafeArea(
// // // // // // // // // // // // //         top: false,
// // // // // // // // // // // // //         child: Padding(
// // // // // // // // // // // // //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // // // // // // // // // // //           child: Row(
// // // // // // // // // // // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // // // // // // // // // // //             children: [
// // // // // // // // // // // // //               Icon(
// // // // // // // // // // // // //                 Icons.wifi_off_rounded,
// // // // // // // // // // // // //                 size: 16,
// // // // // // // // // // // // //                 color: theme.colorScheme.onError,
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //               const SizedBox(width: 8),
// // // // // // // // // // // // //               Text(
// // // // // // // // // // // // //                 AppLocalizations.of(context).noInternetConnection,
// // // // // // // // // // // // //                 style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // // // // // // //                   color: theme.colorScheme.onError,
// // // // // // // // // // // // //                   fontWeight: FontWeight.w500,
// // // // // // // // // // // // //                 ),
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //             ],
// // // // // // // // // // // // //           ),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //   }
// // // // // // // // // // // // // }

// // // // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // // // import 'package:flutter_localizations/flutter_localizations.dart';
// // // // // // // // // // // // import 'package:jma3a/features/profile/presentation/profile_provider.dart';
// // // // // // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // // // // // import 'core/l10n/generated/app_localizations.dart';
// // // // // // // // // // // // import 'core/providers/app_provider.dart';
// // // // // // // // // // // // import 'core/providers/auth_provider.dart';
// // // // // // // // // // // // import 'core/providers/connectivity_provider.dart';
// // // // // // // // // // // // import 'core/router/app_router.dart';
// // // // // // // // // // // // import 'core/theme/app_theme.dart';
// // // // // // // // // // // // import 'core/di/service_locator.dart';
// // // // // // // // // // // // import 'features/friends/presentation/friends_provider.dart';
// // // // // // // // // // // // import 'features/notifications/presentation/notification_provider.dart';
// // // // // // // // // // // // import 'features/packs/presentation/pack_provider.dart';
// // // // // // // // // // // // import 'features/wallet/presentation/wallet_provider.dart';

// // // // // // // // // // // // class Jma3aApp extends StatelessWidget {
// // // // // // // // // // // //   const Jma3aApp({super.key});

// // // // // // // // // // // //   @override
// // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // //     return MultiProvider(
// // // // // // // // // // // //       providers: [
// // // // // // // // // // // //         // ── Infrastructure (always alive) ─────────────────────────────────
// // // // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // // // //           create: (_) =>
// // // // // // // // // // // //               ConnectivityProvider(connectivityService: sl.connectivityService),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // // // //           create: (_) =>
// // // // // // // // // // // //               AppProvider(localStorageService: sl.localStorageService)
// // // // // // // // // // // //                 ..initialize(),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // // // //           create: (_) => AuthProvider(
// // // // // // // // // // // //             authRepository: sl.authRepository,
// // // // // // // // // // // //             secureStorage: sl.secureStorageService,
// // // // // // // // // // // //           )..initialize(),
// // // // // // // // // // // //         ),

// // // // // // // // // // // //         // ── Auth-scoped providers (hydrated/cleared on login/logout) ───────
// // // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
// // // // // // // // // // // //           create: (ctx) => ProfileProvider(
// // // // // // // // // // // //             profileRepository: sl.profileRepository,
// // // // // // // // // // // //             authProvider: ctx.read<AuthProvider>(),
// // // // // // // // // // // //           ),
// // // // // // // // // // // //           update: (_, auth, profile) =>
// // // // // // // // // // // //               (profile ??
// // // // // // // // // // // //                     ProfileProvider(
// // // // // // // // // // // //                       profileRepository: sl.profileRepository,
// // // // // // // // // // // //                       authProvider: auth,
// // // // // // // // // // // //                     ))
// // // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// // // // // // // // // // // //           create: (_) =>
// // // // // // // // // // // //               FriendsProvider(friendsRepository: sl.friendsRepository),
// // // // // // // // // // // //           update: (_, auth, friends) =>
// // // // // // // // // // // //               (friends ??
// // // // // // // // // // // //                     FriendsProvider(friendsRepository: sl.friendsRepository))
// // // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// // // // // // // // // // // //           create: (_) => NotificationProvider(
// // // // // // // // // // // //             notificationRepository: sl.notificationRepository,
// // // // // // // // // // // //           ),
// // // // // // // // // // // //           update: (_, auth, notifs) =>
// // // // // // // // // // // //               (notifs ??
// // // // // // // // // // // //                     NotificationProvider(
// // // // // // // // // // // //                       notificationRepository: sl.notificationRepository,
// // // // // // // // // // // //                     ))
// // // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// // // // // // // // // // // //           create: (_) => WalletProvider(walletRepository: sl.walletRepository),
// // // // // // // // // // // //           update: (_, auth, wallet) =>
// // // // // // // // // // // //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// // // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// // // // // // // // // // // //           create: (_) => PackProvider(
// // // // // // // // // // // //             packRepository: sl.packRepository,
// // // // // // // // // // // //             packSyncService: sl.packSyncService,
// // // // // // // // // // // //           ),
// // // // // // // // // // // //           update: (_, auth, packs) =>
// // // // // // // // // // // //               (packs ??
// // // // // // // // // // // //                     PackProvider(
// // // // // // // // // // // //                       packRepository: sl.packRepository,
// // // // // // // // // // // //                       packSyncService: sl.packSyncService,
// // // // // // // // // // // //                     ))
// // // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //       ],
// // // // // // // // // // // //       child: Consumer<AppProvider>(
// // // // // // // // // // // //         builder: (context, appProvider, _) {
// // // // // // // // // // // //           return MaterialApp.router(
// // // // // // // // // // // //             title: 'Jma3a',
// // // // // // // // // // // //             debugShowCheckedModeBanner: false,
// // // // // // // // // // // //             theme: AppTheme.light(),
// // // // // // // // // // // //             darkTheme: AppTheme.dark(),
// // // // // // // // // // // //             themeMode: appProvider.themeMode,
// // // // // // // // // // // //             routerConfig: AppRouter.router,
// // // // // // // // // // // //             locale: appProvider.locale,
// // // // // // // // // // // //             localizationsDelegates: const [
// // // // // // // // // // // //               AppLocalizations.delegate,
// // // // // // // // // // // //               GlobalMaterialLocalizations.delegate,
// // // // // // // // // // // //               GlobalWidgetsLocalizations.delegate,
// // // // // // // // // // // //               GlobalCupertinoLocalizations.delegate,
// // // // // // // // // // // //             ],
// // // // // // // // // // // //             supportedLocales: AppLocalizations.supportedLocales,
// // // // // // // // // // // //             builder: (context, child) =>
// // // // // // // // // // // //                 _AppShell(child: child ?? const SizedBox.shrink()),
// // // // // // // // // // // //           );
// // // // // // // // // // // //         },
// // // // // // // // // // // //       ),
// // // // // // // // // // // //     );
// // // // // // // // // // // //   }
// // // // // // // // // // // // }

// // // // // // // // // // // // class _AppShell extends StatefulWidget {
// // // // // // // // // // // //   const _AppShell({required this.child});
// // // // // // // // // // // //   final Widget child;

// // // // // // // // // // // //   @override
// // // // // // // // // // // //   State<_AppShell> createState() => _AppShellState();
// // // // // // // // // // // // }

// // // // // // // // // // // // class _AppShellState extends State<_AppShell> {
// // // // // // // // // // // //   @override
// // // // // // // // // // // //   void initState() {
// // // // // // // // // // // //     super.initState();
// // // // // // // // // // // //     // Use WidgetsBinding to ensure context is available after build
// // // // // // // // // // // //     WidgetsBinding.instance.addPostFrameCallback((_) {
// // // // // // // // // // // //       if (mounted) {
// // // // // // // // // // // //         // Wire OneSignal foreground handler → NotificationProvider toast queue
// // // // // // // // // // // //         sl.notificationService.registerForegroundHandler((
// // // // // // // // // // // //           type,
// // // // // // // // // // // //           title,
// // // // // // // // // // // //           body,
// // // // // // // // // // // //           data,
// // // // // // // // // // // //         ) {
// // // // // // // // // // // //           // Use mounted check before accessing context
// // // // // // // // // // // //           if (mounted) {
// // // // // // // // // // // //             final notificationProvider = context.read<NotificationProvider>();
// // // // // // // // // // // //             notificationProvider.pushToast(
// // // // // // // // // // // //               type: type,
// // // // // // // // // // // //               title: title,
// // // // // // // // // // // //               body: body,
// // // // // // // // // // // //               data: data,
// // // // // // // // // // // //             );
// // // // // // // // // // // //           }
// // // // // // // // // // // //         });
// // // // // // // // // // // //       }
// // // // // // // // // // // //     });
// // // // // // // // // // // //   }

// // // // // // // // // // // //   @override
// // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // //     return Consumer<ConnectivityProvider>(
// // // // // // // // // // // //       builder: (context, connectivity, child) {
// // // // // // // // // // // //         return Stack(
// // // // // // // // // // // //           children: [
// // // // // // // // // // // //             widget.child,
// // // // // // // // // // // //             if (!connectivity.isOnline)
// // // // // // // // // // // //               const Positioned(
// // // // // // // // // // // //                 bottom: 0,
// // // // // // // // // // // //                 left: 0,
// // // // // // // // // // // //                 right: 0,
// // // // // // // // // // // //                 child: _OfflineBanner(),
// // // // // // // // // // // //               ),
// // // // // // // // // // // //           ],
// // // // // // // // // // // //         );
// // // // // // // // // // // //       },
// // // // // // // // // // // //     );
// // // // // // // // // // // //   }
// // // // // // // // // // // // }

// // // // // // // // // // // // class _OfflineBanner extends StatelessWidget {
// // // // // // // // // // // //   const _OfflineBanner();

// // // // // // // // // // // //   @override
// // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // //     final theme = Theme.of(context);
// // // // // // // // // // // //     return Material(
// // // // // // // // // // // //       color: theme.colorScheme.error,
// // // // // // // // // // // //       child: SafeArea(
// // // // // // // // // // // //         top: false,
// // // // // // // // // // // //         child: Padding(
// // // // // // // // // // // //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // // // // // // // // // //           child: Row(
// // // // // // // // // // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // // // // // // // // // //             children: [
// // // // // // // // // // // //               Icon(
// // // // // // // // // // // //                 Icons.wifi_off_rounded,
// // // // // // // // // // // //                 size: 16,
// // // // // // // // // // // //                 color: theme.colorScheme.onError,
// // // // // // // // // // // //               ),
// // // // // // // // // // // //               const SizedBox(width: 8),
// // // // // // // // // // // //               Text(
// // // // // // // // // // // //                 AppLocalizations.of(context).noInternetConnection,
// // // // // // // // // // // //                 style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // // // // // //                   color: theme.colorScheme.onError,
// // // // // // // // // // // //                   fontWeight: FontWeight.w500,
// // // // // // // // // // // //                 ),
// // // // // // // // // // // //               ),
// // // // // // // // // // // //             ],
// // // // // // // // // // // //           ),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //       ),
// // // // // // // // // // // //     );
// // // // // // // // // // // //   }
// // // // // // // // // // // // }
// // // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // // import 'package:flutter_localizations/flutter_localizations.dart';
// // // // // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // // // // import 'core/l10n/generated/app_localizations.dart';
// // // // // // // // // // // import 'core/providers/app_provider.dart';
// // // // // // // // // // // import 'core/providers/auth_provider.dart';
// // // // // // // // // // // import 'core/providers/connectivity_provider.dart';
// // // // // // // // // // // import 'core/router/app_router.dart';
// // // // // // // // // // // import 'core/theme/app_theme.dart';
// // // // // // // // // // // import 'core/di/service_locator.dart';
// // // // // // // // // // // import 'features/friends/presentation/friends_provider.dart';
// // // // // // // // // // // import 'features/notifications/presentation/notification_provider.dart';
// // // // // // // // // // // import 'features/packs/presentation/pack_provider.dart';
// // // // // // // // // // // import 'features/profile/presentation/profile_provider.dart';
// // // // // // // // // // // import 'features/wallet/presentation/wallet_provider.dart';

// // // // // // // // // // // class Jma3aApp extends StatelessWidget {
// // // // // // // // // // //   const Jma3aApp({super.key});

// // // // // // // // // // //   @override
// // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // //     return MultiProvider(
// // // // // // // // // // //       providers: [
// // // // // // // // // // //         // ── Infrastructure (always alive) ─────────────────────────────────
// // // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // // //           create: (_) =>
// // // // // // // // // // //               ConnectivityProvider(connectivityService: sl.connectivityService),
// // // // // // // // // // //         ),
// // // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // // //           create: (_) =>
// // // // // // // // // // //               AppProvider(localStorageService: sl.localStorageService)
// // // // // // // // // // //                 ..initialize(),
// // // // // // // // // // //         ),
// // // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // // //           create: (_) => AuthProvider(
// // // // // // // // // // //             authRepository: sl.authRepository,
// // // // // // // // // // //             secureStorage: sl.secureStorageService,
// // // // // // // // // // //           )..initialize(),
// // // // // // // // // // //         ),

// // // // // // // // // // //         // ── Auth-scoped providers (hydrated/cleared on login/logout) ───────
// // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
// // // // // // // // // // //           create: (ctx) => ProfileProvider(
// // // // // // // // // // //             profileRepository: sl.profileRepository,
// // // // // // // // // // //             authProvider: ctx.read<AuthProvider>(),
// // // // // // // // // // //           ),
// // // // // // // // // // //           update: (_, auth, profile) =>
// // // // // // // // // // //               (profile ??
// // // // // // // // // // //                     ProfileProvider(
// // // // // // // // // // //                       profileRepository: sl.profileRepository,
// // // // // // // // // // //                       authProvider: auth,
// // // // // // // // // // //                     ))
// // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // //         ),
// // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// // // // // // // // // // //           create: (_) =>
// // // // // // // // // // //               FriendsProvider(friendsRepository: sl.friendsRepository),
// // // // // // // // // // //           update: (_, auth, friends) =>
// // // // // // // // // // //               (friends ??
// // // // // // // // // // //                     FriendsProvider(friendsRepository: sl.friendsRepository))
// // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // //         ),
// // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// // // // // // // // // // //           create: (_) => NotificationProvider(
// // // // // // // // // // //             notificationRepository: sl.notificationRepository,
// // // // // // // // // // //           ),
// // // // // // // // // // //           update: (_, auth, notifs) =>
// // // // // // // // // // //               (notifs ??
// // // // // // // // // // //                     NotificationProvider(
// // // // // // // // // // //                       notificationRepository: sl.notificationRepository,
// // // // // // // // // // //                     ))
// // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // //         ),
// // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// // // // // // // // // // //           create: (_) => WalletProvider(walletRepository: sl.walletRepository),
// // // // // // // // // // //           update: (_, auth, wallet) =>
// // // // // // // // // // //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // //         ),
// // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// // // // // // // // // // //           create: (_) => PackProvider(
// // // // // // // // // // //             packRepository: sl.packRepository,
// // // // // // // // // // //             packSyncService: sl.packSyncService,
// // // // // // // // // // //           ),
// // // // // // // // // // //           update: (_, auth, packs) =>
// // // // // // // // // // //               (packs ??
// // // // // // // // // // //                     PackProvider(
// // // // // // // // // // //                       packRepository: sl.packRepository,
// // // // // // // // // // //                       packSyncService: sl.packSyncService,
// // // // // // // // // // //                     ))
// // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // //         ),
// // // // // // // // // // //       ],
// // // // // // // // // // //       child: Consumer<AuthProvider>(
// // // // // // // // // // //         builder: (context, auth, _) {
// // // // // // // // // // //           return Consumer<AppProvider>(
// // // // // // // // // // //             builder: (context, appProvider, _) {
// // // // // // // // // // //               return MaterialApp.router(
// // // // // // // // // // //                 title: 'Jma3a',
// // // // // // // // // // //                 debugShowCheckedModeBanner: false,
// // // // // // // // // // //                 theme: AppTheme.light(),
// // // // // // // // // // //                 darkTheme: AppTheme.dark(),
// // // // // // // // // // //                 themeMode: appProvider.themeMode,
// // // // // // // // // // //                 routerConfig: AppRouter.createRouter(auth),
// // // // // // // // // // //                 locale: appProvider.locale,
// // // // // // // // // // //                 localizationsDelegates: const [
// // // // // // // // // // //                   AppLocalizations.delegate,
// // // // // // // // // // //                   GlobalMaterialLocalizations.delegate,
// // // // // // // // // // //                   GlobalWidgetsLocalizations.delegate,
// // // // // // // // // // //                   GlobalCupertinoLocalizations.delegate,
// // // // // // // // // // //                 ],
// // // // // // // // // // //                 supportedLocales: AppLocalizations.supportedLocales,
// // // // // // // // // // //                 builder: (context, child) =>
// // // // // // // // // // //                     _AppShell(child: child ?? const SizedBox.shrink()),
// // // // // // // // // // //               );
// // // // // // // // // // //             },
// // // // // // // // // // //           );
// // // // // // // // // // //         },
// // // // // // // // // // //       ),
// // // // // // // // // // //     );
// // // // // // // // // // //   }
// // // // // // // // // // // }

// // // // // // // // // // // class _AppShell extends StatefulWidget {
// // // // // // // // // // //   const _AppShell({required this.child});
// // // // // // // // // // //   final Widget child;

// // // // // // // // // // //   @override
// // // // // // // // // // //   State<_AppShell> createState() => _AppShellState();
// // // // // // // // // // // }

// // // // // // // // // // // class _AppShellState extends State<_AppShell> {
// // // // // // // // // // //   @override
// // // // // // // // // // //   void initState() {
// // // // // // // // // // //     super.initState();
// // // // // // // // // // //     // Wire OneSignal foreground handler → NotificationProvider toast queue
// // // // // // // // // // //     sl.notificationService.registerForegroundHandler((type, title, body, data) {
// // // // // // // // // // //       context.read<NotificationProvider>().pushToast(
// // // // // // // // // // //         type: type,
// // // // // // // // // // //         title: title,
// // // // // // // // // // //         body: body,
// // // // // // // // // // //         data: data,
// // // // // // // // // // //       );
// // // // // // // // // // //     });
// // // // // // // // // // //   }

// // // // // // // // // // //   @override
// // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // //     return Consumer<ConnectivityProvider>(
// // // // // // // // // // //       builder: (context, connectivity, _) => Stack(
// // // // // // // // // // //         children: [
// // // // // // // // // // //           widget.child,
// // // // // // // // // // //           if (!connectivity.isOnline)
// // // // // // // // // // //             const Positioned(
// // // // // // // // // // //               bottom: 0,
// // // // // // // // // // //               left: 0,
// // // // // // // // // // //               right: 0,
// // // // // // // // // // //               child: _OfflineBanner(),
// // // // // // // // // // //             ),
// // // // // // // // // // //         ],
// // // // // // // // // // //       ),
// // // // // // // // // // //     );
// // // // // // // // // // //   }
// // // // // // // // // // // }

// // // // // // // // // // // class _OfflineBanner extends StatelessWidget {
// // // // // // // // // // //   const _OfflineBanner();

// // // // // // // // // // //   @override
// // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // //     final theme = Theme.of(context);
// // // // // // // // // // //     return Material(
// // // // // // // // // // //       color: theme.colorScheme.error,
// // // // // // // // // // //       child: SafeArea(
// // // // // // // // // // //         top: false,
// // // // // // // // // // //         child: Padding(
// // // // // // // // // // //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // // // // // // // // //           child: Row(
// // // // // // // // // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // // // // // // // // //             children: [
// // // // // // // // // // //               Icon(
// // // // // // // // // // //                 Icons.wifi_off_rounded,
// // // // // // // // // // //                 size: 16,
// // // // // // // // // // //                 color: theme.colorScheme.onError,
// // // // // // // // // // //               ),
// // // // // // // // // // //               const SizedBox(width: 8),
// // // // // // // // // // //               Text(
// // // // // // // // // // //                 AppLocalizations.of(context).noInternetConnection,
// // // // // // // // // // //                 style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // // // // //                   color: theme.colorScheme.onError,
// // // // // // // // // // //                   fontWeight: FontWeight.w500,
// // // // // // // // // // //                 ),
// // // // // // // // // // //               ),
// // // // // // // // // // //             ],
// // // // // // // // // // //           ),
// // // // // // // // // // //         ),
// // // // // // // // // // //       ),
// // // // // // // // // // //     );
// // // // // // // // // // //   }
// // // // // // // // // // // }
// // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // import 'package:flutter_localizations/flutter_localizations.dart';
// // // // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // // // import 'core/l10n/generated/app_localizations.dart';
// // // // // // // // // // import 'core/providers/app_provider.dart';
// // // // // // // // // // import 'core/providers/auth_provider.dart';
// // // // // // // // // // import 'core/providers/connectivity_provider.dart';
// // // // // // // // // // import 'core/router/app_router.dart';
// // // // // // // // // // import 'core/theme/app_theme.dart';
// // // // // // // // // // import 'core/di/service_locator.dart';
// // // // // // // // // // import 'features/friends/presentation/friends_provider.dart';
// // // // // // // // // // import 'features/notifications/presentation/notification_provider.dart';
// // // // // // // // // // import 'features/packs/presentation/pack_provider.dart';
// // // // // // // // // // import 'features/profile/presentation/profile_provider.dart';
// // // // // // // // // // import 'features/wallet/presentation/wallet_provider.dart';

// // // // // // // // // // class Jma3aApp extends StatefulWidget {
// // // // // // // // // //   const Jma3aApp({super.key});

// // // // // // // // // //   @override
// // // // // // // // // //   State<Jma3aApp> createState() => _Jma3aAppState();
// // // // // // // // // // }

// // // // // // // // // // class _Jma3aAppState extends State<Jma3aApp> {
// // // // // // // // // //   @override
// // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // //     return MultiProvider(
// // // // // // // // // //       providers: [
// // // // // // // // // //         // ── Infrastructure (always alive) ─────────────────────────────────
// // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // //           create: (_) =>
// // // // // // // // // //               ConnectivityProvider(connectivityService: sl.connectivityService),
// // // // // // // // // //         ),
// // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // //           create: (_) =>
// // // // // // // // // //               AppProvider(localStorageService: sl.localStorageService)
// // // // // // // // // //                 ..initialize(),
// // // // // // // // // //         ),
// // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // //           create: (_) => AuthProvider(
// // // // // // // // // //             authRepository: sl.authRepository,
// // // // // // // // // //             secureStorage: sl.secureStorageService,
// // // // // // // // // //           )..initialize(),
// // // // // // // // // //         ),

// // // // // // // // // //         // ── Auth-scoped providers (hydrated/cleared on login/logout) ───────
// // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
// // // // // // // // // //           create: (ctx) => ProfileProvider(
// // // // // // // // // //             profileRepository: sl.profileRepository,
// // // // // // // // // //             authProvider: ctx.read<AuthProvider>(),
// // // // // // // // // //           ),
// // // // // // // // // //           update: (_, auth, profile) =>
// // // // // // // // // //               (profile ??
// // // // // // // // // //                     ProfileProvider(
// // // // // // // // // //                       profileRepository: sl.profileRepository,
// // // // // // // // // //                       authProvider: auth,
// // // // // // // // // //                     ))
// // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // //         ),
// // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// // // // // // // // // //           create: (_) =>
// // // // // // // // // //               FriendsProvider(friendsRepository: sl.friendsRepository),
// // // // // // // // // //           update: (_, auth, friends) =>
// // // // // // // // // //               (friends ??
// // // // // // // // // //                     FriendsProvider(friendsRepository: sl.friendsRepository))
// // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // //         ),
// // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// // // // // // // // // //           create: (_) => NotificationProvider(
// // // // // // // // // //             notificationRepository: sl.notificationRepository,
// // // // // // // // // //           ),
// // // // // // // // // //           update: (_, auth, notifs) =>
// // // // // // // // // //               (notifs ??
// // // // // // // // // //                     NotificationProvider(
// // // // // // // // // //                       notificationRepository: sl.notificationRepository,
// // // // // // // // // //                     ))
// // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // //         ),
// // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// // // // // // // // // //           create: (_) => WalletProvider(walletRepository: sl.walletRepository),
// // // // // // // // // //           update: (_, auth, wallet) =>
// // // // // // // // // //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // //         ),
// // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// // // // // // // // // //           create: (_) => PackProvider(
// // // // // // // // // //             packRepository: sl.packRepository,
// // // // // // // // // //             packSyncService: sl.packSyncService,
// // // // // // // // // //           ),
// // // // // // // // // //           update: (_, auth, packs) =>
// // // // // // // // // //               (packs ??
// // // // // // // // // //                     PackProvider(
// // // // // // // // // //                       packRepository: sl.packRepository,
// // // // // // // // // //                       packSyncService: sl.packSyncService,
// // // // // // // // // //                     ))
// // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // //         ),
// // // // // // // // // //       ],
// // // // // // // // // //       child: const _RouterHost(),
// // // // // // // // // //     );
// // // // // // // // // //   }
// // // // // // // // // // }

// // // // // // // // // // /// Created inside MultiProvider so context.read<AuthProvider>() works.
// // // // // // // // // // /// Router is built once in didChangeDependencies and never recreated.
// // // // // // // // // // class _RouterHost extends StatefulWidget {
// // // // // // // // // //   const _RouterHost();

// // // // // // // // // //   @override
// // // // // // // // // //   State<_RouterHost> createState() => _RouterHostState();
// // // // // // // // // // }

// // // // // // // // // // class _RouterHostState extends State<_RouterHost> {
// // // // // // // // // //   GoRouter? _router;

// // // // // // // // // //   @override
// // // // // // // // // //   void didChangeDependencies() {
// // // // // // // // // //     super.didChangeDependencies();
// // // // // // // // // //     _router ??= AppRouter.createRouter(context.read<AuthProvider>());
// // // // // // // // // //   }

// // // // // // // // // //   @override
// // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // //     if (_router == null) return const SizedBox.shrink();
// // // // // // // // // //     return Consumer<AppProvider>(
// // // // // // // // // //       builder: (context, appProvider, _) {
// // // // // // // // // //         return MaterialApp.router(
// // // // // // // // // //           title: 'Jma3a',
// // // // // // // // // //           debugShowCheckedModeBanner: false,
// // // // // // // // // //           theme: AppTheme.light(),
// // // // // // // // // //           darkTheme: AppTheme.dark(),
// // // // // // // // // //           themeMode: appProvider.themeMode,
// // // // // // // // // //           routerConfig: _router!,
// // // // // // // // // //           locale: appProvider.locale,
// // // // // // // // // //           localizationsDelegates: const [
// // // // // // // // // //             AppLocalizations.delegate,
// // // // // // // // // //             GlobalMaterialLocalizations.delegate,
// // // // // // // // // //             GlobalWidgetsLocalizations.delegate,
// // // // // // // // // //             GlobalCupertinoLocalizations.delegate,
// // // // // // // // // //           ],
// // // // // // // // // //           supportedLocales: AppLocalizations.supportedLocales,
// // // // // // // // // //           builder: (context, child) =>
// // // // // // // // // //               _AppShell(child: child ?? const SizedBox.shrink()),
// // // // // // // // // //         );
// // // // // // // // // //       },
// // // // // // // // // //     );
// // // // // // // // // //   }
// // // // // // // // // // }

// // // // // // // // // // class _AppShell extends StatefulWidget {
// // // // // // // // // //   const _AppShell({required this.child});
// // // // // // // // // //   final Widget child;

// // // // // // // // // //   @override
// // // // // // // // // //   State<_AppShell> createState() => _AppShellState();
// // // // // // // // // // }

// // // // // // // // // // class _AppShellState extends State<_AppShell> {
// // // // // // // // // //   @override
// // // // // // // // // //   void initState() {
// // // // // // // // // //     super.initState();
// // // // // // // // // //     // Wire OneSignal foreground handler → NotificationProvider toast queue
// // // // // // // // // //     sl.notificationService.registerForegroundHandler((type, title, body, data) {
// // // // // // // // // //       context.read<NotificationProvider>().pushToast(
// // // // // // // // // //         type: type,
// // // // // // // // // //         title: title,
// // // // // // // // // //         body: body,
// // // // // // // // // //         data: data,
// // // // // // // // // //       );
// // // // // // // // // //     });
// // // // // // // // // //   }

// // // // // // // // // //   @override
// // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // //     return Consumer<ConnectivityProvider>(
// // // // // // // // // //       builder: (context, connectivity, _) => Stack(
// // // // // // // // // //         children: [
// // // // // // // // // //           child,
// // // // // // // // // //           if (!connectivity.isOnline)
// // // // // // // // // //             const Positioned(
// // // // // // // // // //               bottom: 0,
// // // // // // // // // //               left: 0,
// // // // // // // // // //               right: 0,
// // // // // // // // // //               child: _OfflineBanner(),
// // // // // // // // // //             ),
// // // // // // // // // //         ],
// // // // // // // // // //       ),
// // // // // // // // // //     );
// // // // // // // // // //   }
// // // // // // // // // // }

// // // // // // // // // // class _OfflineBanner extends StatelessWidget {
// // // // // // // // // //   const _OfflineBanner();

// // // // // // // // // //   @override
// // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // //     final theme = Theme.of(context);
// // // // // // // // // //     return Material(
// // // // // // // // // //       color: theme.colorScheme.error,
// // // // // // // // // //       child: SafeArea(
// // // // // // // // // //         top: false,
// // // // // // // // // //         child: Padding(
// // // // // // // // // //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // // // // // // // //           child: Row(
// // // // // // // // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // // // // // // // //             children: [
// // // // // // // // // //               Icon(
// // // // // // // // // //                 Icons.wifi_off_rounded,
// // // // // // // // // //                 size: 16,
// // // // // // // // // //                 color: theme.colorScheme.onError,
// // // // // // // // // //               ),
// // // // // // // // // //               const SizedBox(width: 8),
// // // // // // // // // //               Text(
// // // // // // // // // //                 AppLocalizations.of(context).noInternetConnection,
// // // // // // // // // //                 style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // // // //                   color: theme.colorScheme.onError,
// // // // // // // // // //                   fontWeight: FontWeight.w500,
// // // // // // // // // //                 ),
// // // // // // // // // //               ),
// // // // // // // // // //             ],
// // // // // // // // // //           ),
// // // // // // // // // //         ),
// // // // // // // // // //       ),
// // // // // // // // // //     );
// // // // // // // // // //   }
// // // // // // // // // // }
// // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // import 'package:flutter_localizations/flutter_localizations.dart';
// // // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // // import 'core/l10n/generated/app_localizations.dart';
// // // // // // // // // import 'core/providers/app_provider.dart';
// // // // // // // // // import 'core/providers/auth_provider.dart';
// // // // // // // // // import 'core/providers/connectivity_provider.dart';
// // // // // // // // // import 'core/router/app_router.dart';
// // // // // // // // // import 'core/theme/app_theme.dart';
// // // // // // // // // import 'core/di/service_locator.dart';
// // // // // // // // // import 'features/friends/presentation/friends_provider.dart';
// // // // // // // // // import 'features/notifications/presentation/notification_provider.dart';
// // // // // // // // // import 'features/packs/presentation/pack_provider.dart';
// // // // // // // // // import 'features/profile/presentation/profile_provider.dart';
// // // // // // // // // import 'features/wallet/presentation/wallet_provider.dart';

// // // // // // // // // class Jma3aApp extends StatefulWidget {
// // // // // // // // //   const Jma3aApp({super.key});

// // // // // // // // //   @override
// // // // // // // // //   State<Jma3aApp> createState() => _Jma3aAppState();
// // // // // // // // // }

// // // // // // // // // class _Jma3aAppState extends State<Jma3aApp> {
// // // // // // // // //   @override
// // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // //     return MultiProvider(
// // // // // // // // //       providers: [
// // // // // // // // //         // ── Infrastructure (always alive) ─────────────────────────────────
// // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // //           create: (_) =>
// // // // // // // // //               ConnectivityProvider(connectivityService: sl.connectivityService),
// // // // // // // // //         ),
// // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // //           create: (_) =>
// // // // // // // // //               AppProvider(localStorageService: sl.localStorageService)
// // // // // // // // //                 ..initialize(),
// // // // // // // // //         ),
// // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // //           create: (_) => AuthProvider(
// // // // // // // // //             authRepository: sl.authRepository,
// // // // // // // // //             secureStorage: sl.secureStorageService,
// // // // // // // // //           )..initialize(),
// // // // // // // // //         ),

// // // // // // // // //         // ── Auth-scoped providers (hydrated/cleared on login/logout) ───────
// // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
// // // // // // // // //           create: (ctx) => ProfileProvider(
// // // // // // // // //             profileRepository: sl.profileRepository,
// // // // // // // // //             authProvider: ctx.read<AuthProvider>(),
// // // // // // // // //           ),
// // // // // // // // //           update: (_, auth, profile) =>
// // // // // // // // //               (profile ??
// // // // // // // // //                     ProfileProvider(
// // // // // // // // //                       profileRepository: sl.profileRepository,
// // // // // // // // //                       authProvider: auth,
// // // // // // // // //                     ))
// // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // //         ),
// // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// // // // // // // // //           create: (_) =>
// // // // // // // // //               FriendsProvider(friendsRepository: sl.friendsRepository),
// // // // // // // // //           update: (_, auth, friends) =>
// // // // // // // // //               (friends ??
// // // // // // // // //                     FriendsProvider(friendsRepository: sl.friendsRepository))
// // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // //         ),
// // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// // // // // // // // //           create: (_) => NotificationProvider(
// // // // // // // // //             notificationRepository: sl.notificationRepository,
// // // // // // // // //           ),
// // // // // // // // //           update: (_, auth, notifs) =>
// // // // // // // // //               (notifs ??
// // // // // // // // //                     NotificationProvider(
// // // // // // // // //                       notificationRepository: sl.notificationRepository,
// // // // // // // // //                     ))
// // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // //         ),
// // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// // // // // // // // //           create: (_) => WalletProvider(walletRepository: sl.walletRepository),
// // // // // // // // //           update: (_, auth, wallet) =>
// // // // // // // // //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // //         ),
// // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// // // // // // // // //           create: (_) => PackProvider(
// // // // // // // // //             packRepository: sl.packRepository,
// // // // // // // // //             packSyncService: sl.packSyncService,
// // // // // // // // //           ),
// // // // // // // // //           update: (_, auth, packs) =>
// // // // // // // // //               (packs ??
// // // // // // // // //                     PackProvider(
// // // // // // // // //                       packRepository: sl.packRepository,
// // // // // // // // //                       packSyncService: sl.packSyncService,
// // // // // // // // //                     ))
// // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // //         ),
// // // // // // // // //       ],
// // // // // // // // //       child: const _RouterHost(),
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // // }

// // // // // // // // // /// Created inside MultiProvider so context.read<AuthProvider>() works.
// // // // // // // // // /// Router is built once in didChangeDependencies and never recreated.
// // // // // // // // // class _RouterHost extends StatefulWidget {
// // // // // // // // //   const _RouterHost();

// // // // // // // // //   @override
// // // // // // // // //   State<_RouterHost> createState() => _RouterHostState();
// // // // // // // // // }

// // // // // // // // // class _RouterHostState extends State<_RouterHost> {
// // // // // // // // //   GoRouter? _router;

// // // // // // // // //   @override
// // // // // // // // //   void didChangeDependencies() {
// // // // // // // // //     super.didChangeDependencies();
// // // // // // // // //     _router ??= AppRouter.createRouter(context.read<AuthProvider>());
// // // // // // // // //   }

// // // // // // // // //   @override
// // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // //     if (_router == null) return const SizedBox.shrink();
// // // // // // // // //     return Consumer<AppProvider>(
// // // // // // // // //       builder: (context, appProvider, _) {
// // // // // // // // //         return MaterialApp.router(
// // // // // // // // //           title: 'Jma3a',
// // // // // // // // //           debugShowCheckedModeBanner: false,
// // // // // // // // //           theme: AppTheme.light(),
// // // // // // // // //           darkTheme: AppTheme.dark(),
// // // // // // // // //           themeMode: appProvider.themeMode,
// // // // // // // // //           routerConfig: _router!,
// // // // // // // // //           locale: appProvider.locale,
// // // // // // // // //           localizationsDelegates: const [
// // // // // // // // //             AppLocalizations.delegate,
// // // // // // // // //             GlobalMaterialLocalizations.delegate,
// // // // // // // // //             GlobalWidgetsLocalizations.delegate,
// // // // // // // // //             GlobalCupertinoLocalizations.delegate,
// // // // // // // // //           ],
// // // // // // // // //           supportedLocales: AppLocalizations.supportedLocales,
// // // // // // // // //           builder: (context, child) =>
// // // // // // // // //               _AppShell(child: child ?? const SizedBox.shrink()),
// // // // // // // // //         );
// // // // // // // // //       },
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // // }

// // // // // // // // // class _AppShell extends StatefulWidget {
// // // // // // // // //   const _AppShell({required this.child});
// // // // // // // // //   final Widget child;

// // // // // // // // //   @override
// // // // // // // // //   State<_AppShell> createState() => _AppShellState();
// // // // // // // // // }

// // // // // // // // // class _AppShellState extends State<_AppShell> {
// // // // // // // // //   @override
// // // // // // // // //   void initState() {
// // // // // // // // //     super.initState();
// // // // // // // // //     // Wire OneSignal foreground handler → NotificationProvider toast queue
// // // // // // // // //     sl.notificationService.registerForegroundHandler((type, title, body, data) {
// // // // // // // // //       context.read<NotificationProvider>().pushToast(
// // // // // // // // //         type: type,
// // // // // // // // //         title: title,
// // // // // // // // //         body: body,
// // // // // // // // //         data: data,
// // // // // // // // //       );
// // // // // // // // //     });
// // // // // // // // //   }

// // // // // // // // //   @override
// // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // //     return Consumer<ConnectivityProvider>(
// // // // // // // // //       builder: (context, connectivity, _) => Stack(
// // // // // // // // //         children: [
// // // // // // // // //           widget.child,
// // // // // // // // //           if (!connectivity.isOnline)
// // // // // // // // //             const Positioned(
// // // // // // // // //               bottom: 0,
// // // // // // // // //               left: 0,
// // // // // // // // //               right: 0,
// // // // // // // // //               child: _OfflineBanner(),
// // // // // // // // //             ),
// // // // // // // // //         ],
// // // // // // // // //       ),
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // // }

// // // // // // // // // class _OfflineBanner extends StatelessWidget {
// // // // // // // // //   const _OfflineBanner();

// // // // // // // // //   @override
// // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // //     final theme = Theme.of(context);
// // // // // // // // //     return Material(
// // // // // // // // //       color: theme.colorScheme.error,
// // // // // // // // //       child: SafeArea(
// // // // // // // // //         top: false,
// // // // // // // // //         child: Padding(
// // // // // // // // //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // // // // // // //           child: Row(
// // // // // // // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // // // // // // //             children: [
// // // // // // // // //               Icon(
// // // // // // // // //                 Icons.wifi_off_rounded,
// // // // // // // // //                 size: 16,
// // // // // // // // //                 color: theme.colorScheme.onError,
// // // // // // // // //               ),
// // // // // // // // //               const SizedBox(width: 8),
// // // // // // // // //               Text(
// // // // // // // // //                 AppLocalizations.of(context).noInternetConnection,
// // // // // // // // //                 style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // // //                   color: theme.colorScheme.onError,
// // // // // // // // //                   fontWeight: FontWeight.w500,
// // // // // // // // //                 ),
// // // // // // // // //               ),
// // // // // // // // //             ],
// // // // // // // // //           ),
// // // // // // // // //         ),
// // // // // // // // //       ),
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // // }

// // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // import 'package:flutter_localizations/flutter_localizations.dart';
// // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // import 'core/l10n/generated/app_localizations.dart';
// // // // // // // // import 'core/providers/app_provider.dart';
// // // // // // // // import 'core/providers/auth_provider.dart';
// // // // // // // // import 'core/providers/connectivity_provider.dart';
// // // // // // // // import 'core/router/app_router.dart';
// // // // // // // // import 'core/theme/app_theme.dart';
// // // // // // // // import 'core/di/service_locator.dart';
// // // // // // // // import 'features/friends/presentation/friends_provider.dart';
// // // // // // // // import 'features/notifications/presentation/notification_provider.dart';
// // // // // // // // import 'features/packs/presentation/pack_provider.dart';
// // // // // // // // import 'features/profile/presentation/profile_provider.dart';
// // // // // // // // import 'features/wallet/presentation/wallet_provider.dart';

// // // // // // // // class Jma3aApp extends StatefulWidget {
// // // // // // // //   const Jma3aApp({super.key});

// // // // // // // //   @override
// // // // // // // //   State<Jma3aApp> createState() => _Jma3aAppState();
// // // // // // // // }

// // // // // // // // class _Jma3aAppState extends State<Jma3aApp> {
// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     return MultiProvider(
// // // // // // // //       providers: [
// // // // // // // //         // ── Infrastructure (always alive) ─────────────────────────────────
// // // // // // // //         ChangeNotifierProvider(
// // // // // // // //           create: (_) =>
// // // // // // // //               ConnectivityProvider(connectivityService: sl.connectivityService),
// // // // // // // //         ),
// // // // // // // //         ChangeNotifierProvider(
// // // // // // // //           create: (_) =>
// // // // // // // //               AppProvider(localStorageService: sl.localStorageService)
// // // // // // // //                 ..initialize(),
// // // // // // // //         ),
// // // // // // // //         ChangeNotifierProvider(
// // // // // // // //           create: (_) => AuthProvider(
// // // // // // // //             authRepository: sl.authRepository,
// // // // // // // //             secureStorage: sl.secureStorageService,
// // // // // // // //           )..initialize(),
// // // // // // // //         ),

// // // // // // // //         // ── Auth-scoped providers (hydrated/cleared on login/logout) ───────
// // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
// // // // // // // //           create: (ctx) => ProfileProvider(
// // // // // // // //             profileRepository: sl.profileRepository,
// // // // // // // //             authProvider: ctx.read<AuthProvider>(),
// // // // // // // //           ),
// // // // // // // //           update: (_, auth, profile) =>
// // // // // // // //               (profile ??
// // // // // // // //                     ProfileProvider(
// // // // // // // //                       profileRepository: sl.profileRepository,
// // // // // // // //                       authProvider: auth,
// // // // // // // //                     ))
// // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // //         ),
// // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// // // // // // // //           create: (_) =>
// // // // // // // //               FriendsProvider(friendsRepository: sl.friendsRepository),
// // // // // // // //           update: (_, auth, friends) =>
// // // // // // // //               (friends ??
// // // // // // // //                     FriendsProvider(friendsRepository: sl.friendsRepository))
// // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // //         ),
// // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// // // // // // // //           create: (_) => NotificationProvider(
// // // // // // // //             notificationRepository: sl.notificationRepository,
// // // // // // // //           ),
// // // // // // // //           update: (_, auth, notifs) =>
// // // // // // // //               (notifs ??
// // // // // // // //                     NotificationProvider(
// // // // // // // //                       notificationRepository: sl.notificationRepository,
// // // // // // // //                     ))
// // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // //         ),
// // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// // // // // // // //           create: (_) => WalletProvider(walletRepository: sl.walletRepository),
// // // // // // // //           update: (_, auth, wallet) =>
// // // // // // // //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // //         ),
// // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// // // // // // // //           create: (_) => PackProvider(
// // // // // // // //             packRepository: sl.packRepository,
// // // // // // // //             packSyncService: sl.packSyncService,
// // // // // // // //           ),
// // // // // // // //           update: (_, auth, packs) =>
// // // // // // // //               (packs ??
// // // // // // // //                     PackProvider(
// // // // // // // //                       packRepository: sl.packRepository,
// // // // // // // //                       packSyncService: sl.packSyncService,
// // // // // // // //                     ))
// // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // //         ),
// // // // // // // //       ],
// // // // // // // //       child: const _RouterHost(),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // // }

// // // // // // // // /// Created inside MultiProvider so context.read<AuthProvider>() works.
// // // // // // // // /// Router is built once in didChangeDependencies and never recreated.
// // // // // // // // class _RouterHost extends StatefulWidget {
// // // // // // // //   const _RouterHost();

// // // // // // // //   @override
// // // // // // // //   State<_RouterHost> createState() => _RouterHostState();
// // // // // // // // }

// // // // // // // // class _RouterHostState extends State<_RouterHost> {
// // // // // // // //   GoRouter? _router;

// // // // // // // //   @override
// // // // // // // //   void didChangeDependencies() {
// // // // // // // //     super.didChangeDependencies();
// // // // // // // //     _router ??= AppRouter.createRouter(context.read<AuthProvider>());
// // // // // // // //   }

// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     if (_router == null) return const SizedBox.shrink();
// // // // // // // //     return Consumer<AppProvider>(
// // // // // // // //       builder: (context, appProvider, _) {
// // // // // // // //         return MaterialApp.router(
// // // // // // // //           title: 'Jma3a',
// // // // // // // //           debugShowCheckedModeBanner: false,
// // // // // // // //           theme: AppTheme.light(),
// // // // // // // //           darkTheme: AppTheme.dark(),
// // // // // // // //           themeMode: appProvider.themeMode,
// // // // // // // //           routerConfig: _router!,
// // // // // // // //           locale: appProvider.locale,
// // // // // // // //           localizationsDelegates: const [
// // // // // // // //             AppLocalizations.delegate,
// // // // // // // //             GlobalMaterialLocalizations.delegate,
// // // // // // // //             GlobalWidgetsLocalizations.delegate,
// // // // // // // //             GlobalCupertinoLocalizations.delegate,
// // // // // // // //           ],
// // // // // // // //           supportedLocales: AppLocalizations.supportedLocales,
// // // // // // // //           builder: (context, child) =>
// // // // // // // //               _AppShell(child: child ?? const SizedBox.shrink()),
// // // // // // // //         );
// // // // // // // //       },
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // // }

// // // // // // // // class _AppShell extends StatefulWidget {
// // // // // // // //   const _AppShell({required this.child});
// // // // // // // //   final Widget child;

// // // // // // // //   @override
// // // // // // // //   State<_AppShell> createState() => _AppShellState();
// // // // // // // // }

// // // // // // // // class _AppShellState extends State<_AppShell> {
// // // // // // // //   @override
// // // // // // // //   void initState() {
// // // // // // // //     super.initState();
// // // // // // // //     // Wire OneSignal foreground handler → NotificationProvider toast queue
// // // // // // // //     sl.notificationService.registerForegroundHandler((type, title, body, data) {
// // // // // // // //       context.read<NotificationProvider>().pushToast(
// // // // // // // //         type: type,
// // // // // // // //         title: title,
// // // // // // // //         body: body,
// // // // // // // //         data: data,
// // // // // // // //       );
// // // // // // // //     });
// // // // // // // //   }

// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     return Consumer<ConnectivityProvider>(
// // // // // // // //       builder: (context, connectivity, _) => Stack(
// // // // // // // //         children: [
// // // // // // // //           widget.child,
// // // // // // // //           if (!connectivity.isOnline)
// // // // // // // //             const Positioned(
// // // // // // // //               bottom: 0,
// // // // // // // //               left: 0,
// // // // // // // //               right: 0,
// // // // // // // //               child: _OfflineBanner(),
// // // // // // // //             ),
// // // // // // // //         ],
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // // }

// // // // // // // // class _OfflineBanner extends StatelessWidget {
// // // // // // // //   const _OfflineBanner();

// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     final theme = Theme.of(context);
// // // // // // // //     return Material(
// // // // // // // //       color: theme.colorScheme.error,
// // // // // // // //       child: SafeArea(
// // // // // // // //         top: false,
// // // // // // // //         child: Padding(
// // // // // // // //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // // // // // //           child: Row(
// // // // // // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // // // // // //             children: [
// // // // // // // //               Icon(
// // // // // // // //                 Icons.wifi_off_rounded,
// // // // // // // //                 size: 16,
// // // // // // // //                 color: theme.colorScheme.onError,
// // // // // // // //               ),
// // // // // // // //               const SizedBox(width: 8),
// // // // // // // //               Text(
// // // // // // // //                 AppLocalizations.of(context).noInternetConnection,
// // // // // // // //                 style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // //                   color: theme.colorScheme.onError,
// // // // // // // //                   fontWeight: FontWeight.w500,
// // // // // // // //                 ),
// // // // // // // //               ),
// // // // // // // //             ],
// // // // // // // //           ),
// // // // // // // //         ),
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // // }

// // // // // // // import 'package:flutter/material.dart';
// // // // // // // import 'package:flutter_localizations/flutter_localizations.dart';
// // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // import 'package:provider/provider.dart';

// // // // // // // import 'core/l10n/generated/app_localizations.dart';
// // // // // // // import 'core/providers/app_provider.dart';
// // // // // // // import 'core/providers/auth_provider.dart';
// // // // // // // import 'core/providers/connectivity_provider.dart';
// // // // // // // import 'core/router/app_router.dart';
// // // // // // // import 'core/theme/app_theme.dart';
// // // // // // // import 'core/di/service_locator.dart';
// // // // // // // import 'features/friends/presentation/friends_provider.dart';
// // // // // // // import 'features/notifications/presentation/notification_provider.dart';
// // // // // // // import 'features/packs/presentation/pack_provider.dart';
// // // // // // // import 'features/profile/presentation/profile_provider.dart';
// // // // // // // import 'features/wallet/presentation/wallet_provider.dart';

// // // // // // // class Jma3aApp extends StatefulWidget {
// // // // // // //   const Jma3aApp({super.key});

// // // // // // //   @override
// // // // // // //   State<Jma3aApp> createState() => _Jma3aAppState();
// // // // // // // }

// // // // // // // class _Jma3aAppState extends State<Jma3aApp> {
// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     return MultiProvider(
// // // // // // //       providers: [
// // // // // // //         // ── Infrastructure (always alive) ─────────────────────────────────
// // // // // // //         ChangeNotifierProvider(
// // // // // // //           create: (_) =>
// // // // // // //               ConnectivityProvider(connectivityService: sl.connectivityService),
// // // // // // //         ),
// // // // // // //         ChangeNotifierProvider(
// // // // // // //           create: (_) =>
// // // // // // //               AppProvider(localStorageService: sl.localStorageService)
// // // // // // //                 ..initialize(),
// // // // // // //         ),
// // // // // // //         ChangeNotifierProvider(
// // // // // // //           create: (_) => AuthProvider(
// // // // // // //             authRepository: sl.authRepository,
// // // // // // //             secureStorage: sl.secureStorageService,
// // // // // // //           )..initialize(),
// // // // // // //         ),

// // // // // // //         // ── Auth-scoped providers (hydrated/cleared on login/logout) ───────
// // // // // // //         ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
// // // // // // //           create: (ctx) => ProfileProvider(
// // // // // // //             profileRepository: sl.profileRepository,
// // // // // // //             authProvider: ctx.read<AuthProvider>(),
// // // // // // //           ),
// // // // // // //           update: (_, auth, profile) =>
// // // // // // //               (profile ??
// // // // // // //                     ProfileProvider(
// // // // // // //                       profileRepository: sl.profileRepository,
// // // // // // //                       authProvider: auth,
// // // // // // //                     ))
// // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // //         ),
// // // // // // //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// // // // // // //           create: (_) =>
// // // // // // //               FriendsProvider(friendsRepository: sl.friendsRepository),
// // // // // // //           update: (_, auth, friends) =>
// // // // // // //               (friends ??
// // // // // // //                     FriendsProvider(friendsRepository: sl.friendsRepository))
// // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // //         ),
// // // // // // //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// // // // // // //           create: (_) => NotificationProvider(
// // // // // // //             notificationRepository: sl.notificationRepository,
// // // // // // //           ),
// // // // // // //           update: (_, auth, notifs) =>
// // // // // // //               (notifs ??
// // // // // // //                     NotificationProvider(
// // // // // // //                       notificationRepository: sl.notificationRepository,
// // // // // // //                     ))
// // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // //         ),
// // // // // // //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// // // // // // //           create: (_) => WalletProvider(walletRepository: sl.walletRepository),
// // // // // // //           update: (_, auth, wallet) =>
// // // // // // //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // //         ),
// // // // // // //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// // // // // // //           create: (_) => PackProvider(
// // // // // // //             packRepository: sl.packRepository,
// // // // // // //             packSyncService: sl.packSyncService,
// // // // // // //           ),
// // // // // // //           update: (_, auth, packs) =>
// // // // // // //               (packs ??
// // // // // // //                     PackProvider(
// // // // // // //                       packRepository: sl.packRepository,
// // // // // // //                       packSyncService: sl.packSyncService,
// // // // // // //                     ))
// // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // //         ),
// // // // // // //       ],
// // // // // // //       child: const _RouterHost(),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // // /// Created inside MultiProvider so context.read<AuthProvider>() works.
// // // // // // // /// Router is built once in didChangeDependencies and never recreated.
// // // // // // // class _RouterHost extends StatefulWidget {
// // // // // // //   const _RouterHost();

// // // // // // //   @override
// // // // // // //   State<_RouterHost> createState() => _RouterHostState();
// // // // // // // }

// // // // // // // class _RouterHostState extends State<_RouterHost> {
// // // // // // //   GoRouter? _router;

// // // // // // //   @override
// // // // // // //   void didChangeDependencies() {
// // // // // // //     super.didChangeDependencies();
// // // // // // //     _router ??= AppRouter.createRouter(context.read<AuthProvider>());
// // // // // // //   }

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     if (_router == null) return const SizedBox.shrink();
// // // // // // //     // Read AppProvider without watching — theme/locale changes won't
// // // // // // //     // rebuild MaterialApp.router and reset navigation state.
// // // // // // //     final appProvider = context.read<AppProvider>();
// // // // // // //     return MaterialApp.router(
// // // // // // //       title: 'Jma3a',
// // // // // // //       debugShowCheckedModeBanner: false,
// // // // // // //       theme: AppTheme.light(),
// // // // // // //       darkTheme: AppTheme.dark(),
// // // // // // //       themeMode: appProvider.themeMode,
// // // // // // //       routerConfig: _router!,
// // // // // // //       locale: appProvider.locale,
// // // // // // //       localizationsDelegates: const [
// // // // // // //         AppLocalizations.delegate,
// // // // // // //         GlobalMaterialLocalizations.delegate,
// // // // // // //         GlobalWidgetsLocalizations.delegate,
// // // // // // //         GlobalCupertinoLocalizations.delegate,
// // // // // // //       ],
// // // // // // //       supportedLocales: AppLocalizations.supportedLocales,
// // // // // // //       builder: (context, child) =>
// // // // // // //           _AppShell(child: child ?? const SizedBox.shrink()),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // // class _AppShell extends StatefulWidget {
// // // // // // //   const _AppShell({required this.child});
// // // // // // //   final Widget child;

// // // // // // //   @override
// // // // // // //   State<_AppShell> createState() => _AppShellState();
// // // // // // // }

// // // // // // // class _AppShellState extends State<_AppShell> {
// // // // // // //   @override
// // // // // // //   void initState() {
// // // // // // //     super.initState();
// // // // // // //     // Wire OneSignal foreground handler → NotificationProvider toast queue
// // // // // // //     sl.notificationService.registerForegroundHandler((type, title, body, data) {
// // // // // // //       context.read<NotificationProvider>().pushToast(
// // // // // // //         type: type,
// // // // // // //         title: title,
// // // // // // //         body: body,
// // // // // // //         data: data,
// // // // // // //       );
// // // // // // //     });
// // // // // // //   }

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     return Consumer<ConnectivityProvider>(
// // // // // // //       builder: (context, connectivity, _) => Stack(
// // // // // // //         children: [
// // // // // // //           widget.child,
// // // // // // //           if (!connectivity.isOnline)
// // // // // // //             const Positioned(
// // // // // // //               bottom: 0,
// // // // // // //               left: 0,
// // // // // // //               right: 0,
// // // // // // //               child: _OfflineBanner(),
// // // // // // //             ),
// // // // // // //         ],
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // // class _OfflineBanner extends StatelessWidget {
// // // // // // //   const _OfflineBanner();

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     final theme = Theme.of(context);
// // // // // // //     return Material(
// // // // // // //       color: theme.colorScheme.error,
// // // // // // //       child: SafeArea(
// // // // // // //         top: false,
// // // // // // //         child: Padding(
// // // // // // //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // // // // //           child: Row(
// // // // // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // // // // //             children: [
// // // // // // //               Icon(
// // // // // // //                 Icons.wifi_off_rounded,
// // // // // // //                 size: 16,
// // // // // // //                 color: theme.colorScheme.onError,
// // // // // // //               ),
// // // // // // //               const SizedBox(width: 8),
// // // // // // //               Text(
// // // // // // //                 AppLocalizations.of(context).noInternetConnection,
// // // // // // //                 style: theme.textTheme.bodySmall?.copyWith(
// // // // // // //                   color: theme.colorScheme.onError,
// // // // // // //                   fontWeight: FontWeight.w500,
// // // // // // //                 ),
// // // // // // //               ),
// // // // // // //             ],
// // // // // // //           ),
// // // // // // //         ),
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:flutter_localizations/flutter_localizations.dart';
// // // // // // import 'package:go_router/go_router.dart';
// // // // // // import 'package:provider/provider.dart';

// // // // // // import 'core/l10n/generated/app_localizations.dart';
// // // // // // import 'core/providers/app_provider.dart';
// // // // // // import 'core/providers/auth_provider.dart';
// // // // // // import 'core/providers/connectivity_provider.dart';
// // // // // // import 'core/router/app_router.dart';
// // // // // // import 'core/theme/app_theme.dart';
// // // // // // import 'core/di/service_locator.dart';
// // // // // // import 'features/friends/presentation/friends_provider.dart';
// // // // // // import 'features/notifications/presentation/notification_provider.dart';
// // // // // // import 'features/packs/presentation/pack_provider.dart';
// // // // // // import 'features/profile/presentation/profile_provider.dart';
// // // // // // import 'features/offline/data/offline_game_provider.dart';
// // // // // // import 'features/offline/data/offline_repository.dart';
// // // // // // import 'features/wallet/presentation/wallet_provider.dart';

// // // // // // class Jma3aApp extends StatefulWidget {
// // // // // //   const Jma3aApp({super.key});

// // // // // //   @override
// // // // // //   State<Jma3aApp> createState() => _Jma3aAppState();
// // // // // // }

// // // // // // class _Jma3aAppState extends State<Jma3aApp> {
// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return MultiProvider(
// // // // // //       providers: [
// // // // // //         // ── Infrastructure (always alive) ─────────────────────────────────
// // // // // //         ChangeNotifierProvider(
// // // // // //           create: (_) =>
// // // // // //               ConnectivityProvider(connectivityService: sl.connectivityService),
// // // // // //         ),
// // // // // //         ChangeNotifierProvider(
// // // // // //           create: (_) =>
// // // // // //               AppProvider(localStorageService: sl.localStorageService)
// // // // // //                 ..initialize(),
// // // // // //         ),
// // // // // //         ChangeNotifierProvider(
// // // // // //           create: (_) => AuthProvider(
// // // // // //             authRepository: sl.authRepository,
// // // // // //             secureStorage: sl.secureStorageService,
// // // // // //           )..initialize(),
// // // // // //         ),

// // // // // //         // ── Auth-scoped providers (hydrated/cleared on login/logout) ───────
// // // // // //         ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
// // // // // //           create: (ctx) => ProfileProvider(
// // // // // //             profileRepository: sl.profileRepository,
// // // // // //             authProvider: ctx.read<AuthProvider>(),
// // // // // //           ),
// // // // // //           update: (_, auth, profile) =>
// // // // // //               (profile ??
// // // // // //                     ProfileProvider(
// // // // // //                       profileRepository: sl.profileRepository,
// // // // // //                       authProvider: auth,
// // // // // //                     ))
// // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // //         ),
// // // // // //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// // // // // //           create: (_) =>
// // // // // //               FriendsProvider(friendsRepository: sl.friendsRepository),
// // // // // //           update: (_, auth, friends) =>
// // // // // //               (friends ??
// // // // // //                     FriendsProvider(friendsRepository: sl.friendsRepository))
// // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // //         ),
// // // // // //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// // // // // //           create: (_) => NotificationProvider(
// // // // // //             notificationRepository: sl.notificationRepository,
// // // // // //           ),
// // // // // //           update: (_, auth, notifs) =>
// // // // // //               (notifs ??
// // // // // //                     NotificationProvider(
// // // // // //                       notificationRepository: sl.notificationRepository,
// // // // // //                     ))
// // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // //         ),
// // // // // //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// // // // // //           create: (_) => WalletProvider(walletRepository: sl.walletRepository),
// // // // // //           update: (_, auth, wallet) =>
// // // // // //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // //         ),
// // // // // //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// // // // // //           create: (_) => PackProvider(
// // // // // //             packRepository: sl.packRepository,
// // // // // //             packSyncService: sl.packSyncService,
// // // // // //           ),
// // // // // //           update: (_, auth, packs) =>
// // // // // //               (packs ??
// // // // // //                     PackProvider(
// // // // // //                       packRepository: sl.packRepository,
// // // // // //                       packSyncService: sl.packSyncService,
// // // // // //                     ))
// // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // //         ),
// // // // // //         ChangeNotifierProvider(
// // // // // //           create: (_) =>
// // // // // //               OfflineGameProvider(repository: OfflineRepository.instance),
// // // // // //         ),
// // // // // //       ],
// // // // // //       child: const _RouterHost(),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // /// Created inside MultiProvider so context.read<AuthProvider>() works.
// // // // // // /// Router is built once in didChangeDependencies and never recreated.
// // // // // // class _RouterHost extends StatefulWidget {
// // // // // //   const _RouterHost();

// // // // // //   @override
// // // // // //   State<_RouterHost> createState() => _RouterHostState();
// // // // // // }

// // // // // // class _RouterHostState extends State<_RouterHost> {
// // // // // //   GoRouter? _router;

// // // // // //   @override
// // // // // //   void didChangeDependencies() {
// // // // // //     super.didChangeDependencies();
// // // // // //     _router ??= AppRouter.createRouter(context.read<AuthProvider>());
// // // // // //   }

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     if (_router == null) return const SizedBox.shrink();
// // // // // //     // Read AppProvider without watching — theme/locale changes won't
// // // // // //     // rebuild MaterialApp.router and reset navigation state.
// // // // // //     final appProvider = context.read<AppProvider>();
// // // // // //     return MaterialApp.router(
// // // // // //       title: 'Jma3a',
// // // // // //       debugShowCheckedModeBanner: false,
// // // // // //       theme: AppTheme.light(),
// // // // // //       darkTheme: AppTheme.dark(),
// // // // // //       themeMode: appProvider.themeMode,
// // // // // //       routerConfig: _router!,
// // // // // //       locale: appProvider.locale,
// // // // // //       localizationsDelegates: const [
// // // // // //         AppLocalizations.delegate,
// // // // // //         GlobalMaterialLocalizations.delegate,
// // // // // //         GlobalWidgetsLocalizations.delegate,
// // // // // //         GlobalCupertinoLocalizations.delegate,
// // // // // //       ],
// // // // // //       supportedLocales: AppLocalizations.supportedLocales,
// // // // // //       builder: (context, child) =>
// // // // // //           _AppShell(child: child ?? const SizedBox.shrink()),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // class _AppShell extends StatefulWidget {
// // // // // //   const _AppShell({required this.child});
// // // // // //   final Widget child;

// // // // // //   @override
// // // // // //   State<_AppShell> createState() => _AppShellState();
// // // // // // }

// // // // // // class _AppShellState extends State<_AppShell> {
// // // // // //   @override
// // // // // //   void initState() {
// // // // // //     super.initState();
// // // // // //     // Wire OneSignal foreground handler → NotificationProvider toast queue
// // // // // //     sl.notificationService.registerForegroundHandler((type, title, body, data) {
// // // // // //       context.read<NotificationProvider>().pushToast(
// // // // // //         type: type,
// // // // // //         title: title,
// // // // // //         body: body,
// // // // // //         data: data,
// // // // // //       );
// // // // // //     });
// // // // // //   }

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return Consumer<ConnectivityProvider>(
// // // // // //       builder: (context, connectivity, _) => Stack(
// // // // // //         children: [
// // // // // //           widget.child,
// // // // // //           if (!connectivity.isOnline)
// // // // // //             const Positioned(
// // // // // //               bottom: 0,
// // // // // //               left: 0,
// // // // // //               right: 0,
// // // // // //               child: _OfflineBanner(),
// // // // // //             ),
// // // // // //         ],
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // class _OfflineBanner extends StatelessWidget {
// // // // // //   const _OfflineBanner();

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     final theme = Theme.of(context);
// // // // // //     return Material(
// // // // // //       color: theme.colorScheme.error,
// // // // // //       child: SafeArea(
// // // // // //         top: false,
// // // // // //         child: Padding(
// // // // // //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // // // //           child: Row(
// // // // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // // // //             children: [
// // // // // //               Icon(
// // // // // //                 Icons.wifi_off_rounded,
// // // // // //                 size: 16,
// // // // // //                 color: theme.colorScheme.onError,
// // // // // //               ),
// // // // // //               const SizedBox(width: 8),
// // // // // //               Text(
// // // // // //                 AppLocalizations.of(context).noInternetConnection,
// // // // // //                 style: theme.textTheme.bodySmall?.copyWith(
// // // // // //                   color: theme.colorScheme.onError,
// // // // // //                   fontWeight: FontWeight.w500,
// // // // // //                 ),
// // // // // //               ),
// // // // // //             ],
// // // // // //           ),
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:flutter_localizations/flutter_localizations.dart';
// // // // // import 'package:go_router/go_router.dart';
// // // // // import 'package:provider/provider.dart';

// // // // // import 'core/l10n/generated/app_localizations.dart';
// // // // // import 'core/providers/app_provider.dart';
// // // // // import 'core/providers/auth_provider.dart';
// // // // // import 'core/providers/connectivity_provider.dart';
// // // // // import 'core/router/app_router.dart';
// // // // // import 'core/theme/app_theme.dart';
// // // // // import 'core/di/service_locator.dart';
// // // // // import 'features/friends/presentation/friends_provider.dart';
// // // // // import 'features/notifications/presentation/notification_provider.dart';
// // // // // import 'features/packs/presentation/pack_provider.dart';
// // // // // import 'features/profile/presentation/profile_provider.dart';
// // // // // import 'features/offline/data/offline_game_provider.dart';
// // // // // import 'features/offline/data/offline_repository.dart';
// // // // // import 'features/wallet/presentation/wallet_provider.dart';

// // // // // class Jma3aApp extends StatefulWidget {
// // // // //   const Jma3aApp({super.key});

// // // // //   @override
// // // // //   State<Jma3aApp> createState() => _Jma3aAppState();
// // // // // }

// // // // // class _Jma3aAppState extends State<Jma3aApp> {
// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return MultiProvider(
// // // // //       providers: [
// // // // //         // ── Infrastructure (always alive) ─────────────────────────────────
// // // // //         ChangeNotifierProvider(
// // // // //           create: (_) =>
// // // // //               ConnectivityProvider(connectivityService: sl.connectivityService),
// // // // //         ),
// // // // //         ChangeNotifierProvider(
// // // // //           create: (_) =>
// // // // //               AppProvider(localStorageService: sl.localStorageService)
// // // // //                 ..initialize(),
// // // // //         ),
// // // // //         ChangeNotifierProvider(
// // // // //           create: (_) => AuthProvider(
// // // // //             authRepository: sl.authRepository,
// // // // //             secureStorage: sl.secureStorageService,
// // // // //           )..initialize(),
// // // // //         ),

// // // // //         // ── Auth-scoped providers (hydrated/cleared on login/logout) ───────
// // // // //         ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
// // // // //           create: (ctx) => ProfileProvider(
// // // // //             profileRepository: sl.profileRepository,
// // // // //             authProvider: ctx.read<AuthProvider>(),
// // // // //           ),
// // // // //           update: (_, auth, profile) =>
// // // // //               (profile ??
// // // // //                     ProfileProvider(
// // // // //                       profileRepository: sl.profileRepository,
// // // // //                       authProvider: auth,
// // // // //                     ))
// // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // //         ),
// // // // //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// // // // //           create: (_) =>
// // // // //               FriendsProvider(friendsRepository: sl.friendsRepository),
// // // // //           update: (_, auth, friends) =>
// // // // //               (friends ??
// // // // //                     FriendsProvider(friendsRepository: sl.friendsRepository))
// // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // //         ),
// // // // //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// // // // //           create: (_) => NotificationProvider(
// // // // //             notificationRepository: sl.notificationRepository,
// // // // //           ),
// // // // //           update: (_, auth, notifs) =>
// // // // //               (notifs ??
// // // // //                     NotificationProvider(
// // // // //                       notificationRepository: sl.notificationRepository,
// // // // //                     ))
// // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // //         ),
// // // // //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// // // // //           create: (_) => WalletProvider(walletRepository: sl.walletRepository),
// // // // //           update: (_, auth, wallet) =>
// // // // //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // //         ),
// // // // //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// // // // //           create: (_) => PackProvider(
// // // // //             packRepository: sl.packRepository,
// // // // //             packSyncService: sl.packSyncService,
// // // // //           ),
// // // // //           update: (_, auth, packs) =>
// // // // //               (packs ??
// // // // //                     PackProvider(
// // // // //                       packRepository: sl.packRepository,
// // // // //                       packSyncService: sl.packSyncService,
// // // // //                     ))
// // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // //         ),
// // // // //         ChangeNotifierProvider(
// // // // //           create: (_) =>
// // // // //               OfflineGameProvider(repository: OfflineRepository.instance),
// // // // //         ),
// // // // //       ],
// // // // //       child: const _RouterHost(),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // /// Created inside MultiProvider so context.read<AuthProvider>() works.
// // // // // /// Router is built once in didChangeDependencies and never recreated.
// // // // // class _RouterHost extends StatefulWidget {
// // // // //   const _RouterHost();

// // // // //   @override
// // // // //   State<_RouterHost> createState() => _RouterHostState();
// // // // // }

// // // // // class _RouterHostState extends State<_RouterHost> {
// // // // //   GoRouter? _router;

// // // // //   @override
// // // // //   void didChangeDependencies() {
// // // // //     super.didChangeDependencies();
// // // // //     _router ??= AppRouter.createRouter(context.read<AuthProvider>());
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     if (_router == null) return const SizedBox.shrink();
// // // // //     // Read AppProvider without watching — theme/locale changes won't
// // // // //     // rebuild MaterialApp.router and reset navigation state.
// // // // //     final appProvider = context.read<AppProvider>();
// // // // //     return MaterialApp.router(
// // // // //       title: 'Jma3a',
// // // // //       debugShowCheckedModeBanner: false,
// // // // //       theme: AppTheme.light(),
// // // // //       darkTheme: AppTheme.dark(),
// // // // //       themeMode: appProvider.themeMode,
// // // // //       routerConfig: _router!,
// // // // //       locale: appProvider.locale,
// // // // //       localizationsDelegates: const [
// // // // //         AppLocalizations.delegate,
// // // // //         GlobalMaterialLocalizations.delegate,
// // // // //         GlobalWidgetsLocalizations.delegate,
// // // // //         GlobalCupertinoLocalizations.delegate,
// // // // //       ],
// // // // //       supportedLocales: AppLocalizations.supportedLocales,
// // // // //       builder: (context, child) =>
// // // // //           _AppShell(child: child ?? const SizedBox.shrink()),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // class _AppShell extends StatefulWidget {
// // // // //   const _AppShell({required this.child});
// // // // //   final Widget child;

// // // // //   @override
// // // // //   State<_AppShell> createState() => _AppShellState();
// // // // // }

// // // // // class _AppShellState extends State<_AppShell> {
// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();
// // // // //     // Wire OneSignal foreground handler → NotificationProvider toast queue
// // // // //     sl.notificationService.registerForegroundHandler((type, title, body, data) {
// // // // //       context.read<NotificationProvider>().pushToast(
// // // // //         type: type,
// // // // //         title: title,
// // // // //         body: body,
// // // // //         data: data,
// // // // //       );
// // // // //     });
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Consumer<ConnectivityProvider>(
// // // // //       builder: (context, connectivity, _) => Stack(
// // // // //         children: [
// // // // //           widget.child,
// // // // //           if (!connectivity.isOnline)
// // // // //             const Positioned(
// // // // //               top: 0,
// // // // //               left: 0,
// // // // //               right: 0,
// // // // //               child: _OfflineBanner(),
// // // // //             ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // class _OfflineBanner extends StatelessWidget {
// // // // //   const _OfflineBanner();

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return IgnorePointer(
// // // // //       child: Material(
// // // // //         color: Colors.transparent,
// // // // //         child: SafeArea(
// // // // //           bottom: false,
// // // // //           child: Container(
// // // // //             color: const Color(0xFFB91C1C).withOpacity(0.92),
// // // // //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
// // // // //             child: Row(
// // // // //               mainAxisAlignment: MainAxisAlignment.center,
// // // // //               children: [
// // // // //                 const Icon(
// // // // //                   Icons.wifi_off_rounded,
// // // // //                   size: 12,
// // // // //                   color: Colors.white,
// // // // //                 ),
// // // // //                 const SizedBox(width: 6),
// // // // //                 Text(
// // // // //                   AppLocalizations.of(context).noInternetConnection,
// // // // //                   style: const TextStyle(
// // // // //                     color: Colors.white,
// // // // //                     fontSize: 11,
// // // // //                     fontWeight: FontWeight.w600,
// // // // //                   ),
// // // // //                 ),
// // // // //               ],
// // // // //             ),
// // // // //           ),
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // import 'package:flutter/material.dart';
// // // // import 'package:flutter_localizations/flutter_localizations.dart';
// // // // import 'package:go_router/go_router.dart';
// // // // import 'package:provider/provider.dart';

// // // // import 'core/l10n/generated/app_localizations.dart';
// // // // import 'core/providers/app_provider.dart';
// // // // import 'core/providers/auth_provider.dart';
// // // // import 'core/providers/connectivity_provider.dart';
// // // // import 'core/router/app_router.dart';
// // // // import 'core/theme/app_theme.dart';
// // // // import 'core/di/service_locator.dart';
// // // // import 'features/friends/presentation/friends_provider.dart';
// // // // import 'features/notifications/presentation/notification_provider.dart';
// // // // import 'features/packs/presentation/pack_provider.dart';
// // // // import 'features/profile/presentation/profile_provider.dart';
// // // // import 'features/offline/data/offline_game_provider.dart';
// // // // import 'features/offline/data/offline_repository.dart';
// // // // import 'features/wallet/presentation/wallet_provider.dart';

// // // // class Jma3aApp extends StatefulWidget {
// // // //   const Jma3aApp({super.key});

// // // //   @override
// // // //   State<Jma3aApp> createState() => _Jma3aAppState();
// // // // }

// // // // class _Jma3aAppState extends State<Jma3aApp> {
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return MultiProvider(
// // // //       providers: [
// // // //         // ── Infrastructure (always alive) ─────────────────────────────────
// // // //         ChangeNotifierProvider(
// // // //           create: (_) =>
// // // //               ConnectivityProvider(connectivityService: sl.connectivityService),
// // // //         ),
// // // //         ChangeNotifierProvider(
// // // //           create: (_) =>
// // // //               AppProvider(localStorageService: sl.localStorageService)
// // // //                 ..initialize(),
// // // //         ),
// // // //         ChangeNotifierProvider(
// // // //           create: (_) => AuthProvider(
// // // //             authRepository: sl.authRepository,
// // // //             secureStorage: sl.secureStorageService,
// // // //           )..initialize(),
// // // //         ),

// // // //         // ── Auth-scoped providers (hydrated/cleared on login/logout) ───────
// // // //         ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
// // // //           create: (ctx) => ProfileProvider(
// // // //             profileRepository: sl.profileRepository,
// // // //             authProvider: ctx.read<AuthProvider>(),
// // // //           ),
// // // //           update: (_, auth, profile) =>
// // // //               (profile ??
// // // //                     ProfileProvider(
// // // //                       profileRepository: sl.profileRepository,
// // // //                       authProvider: auth,
// // // //                     ))
// // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // //         ),
// // // //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// // // //           create: (_) =>
// // // //               FriendsProvider(friendsRepository: sl.friendsRepository),
// // // //           update: (_, auth, friends) =>
// // // //               (friends ??
// // // //                     FriendsProvider(friendsRepository: sl.friendsRepository))
// // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // //         ),
// // // //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// // // //           create: (_) => NotificationProvider(
// // // //             notificationRepository: sl.notificationRepository,
// // // //           ),
// // // //           update: (_, auth, notifs) =>
// // // //               (notifs ??
// // // //                     NotificationProvider(
// // // //                       notificationRepository: sl.notificationRepository,
// // // //                     ))
// // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // //         ),
// // // //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// // // //           create: (_) => WalletProvider(walletRepository: sl.walletRepository),
// // // //           update: (_, auth, wallet) =>
// // // //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // //         ),
// // // //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// // // //           create: (_) => PackProvider(
// // // //             packRepository: sl.packRepository,
// // // //             packSyncService: sl.packSyncService,
// // // //           ),
// // // //           update: (_, auth, packs) =>
// // // //               (packs ??
// // // //                     PackProvider(
// // // //                       packRepository: sl.packRepository,
// // // //                       packSyncService: sl.packSyncService,
// // // //                     ))
// // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // //         ),
// // // //         ChangeNotifierProvider(
// // // //           create: (_) =>
// // // //               OfflineGameProvider(repository: OfflineRepository.instance),
// // // //         ),
// // // //       ],
// // // //       child: const _RouterHost(),
// // // //     );
// // // //   }
// // // // }

// // // // /// Created inside MultiProvider so context.read<AuthProvider>() works.
// // // // /// Router is built once in didChangeDependencies and never recreated.
// // // // class _RouterHost extends StatefulWidget {
// // // //   const _RouterHost();

// // // //   @override
// // // //   State<_RouterHost> createState() => _RouterHostState();
// // // // }

// // // // class _RouterHostState extends State<_RouterHost> {
// // // //   GoRouter? _router;

// // // //   @override
// // // //   void didChangeDependencies() {
// // // //     super.didChangeDependencies();
// // // //     _router ??= AppRouter.createRouter(context.read<AuthProvider>());
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     if (_router == null) return const SizedBox.shrink();
// // // //     // Read AppProvider without watching — theme/locale changes won't
// // // //     // rebuild MaterialApp.router and reset navigation state.
// // // //     final appProvider = context.read<AppProvider>();
// // // //     return MaterialApp.router(
// // // //       title: 'Jma3a',
// // // //       debugShowCheckedModeBanner: false,
// // // //       theme: AppTheme.light(),
// // // //       darkTheme: AppTheme.dark(),
// // // //       themeMode: appProvider.themeMode,
// // // //       routerConfig: _router!,
// // // //       locale: appProvider.locale,
// // // //       localizationsDelegates: const [
// // // //         AppLocalizations.delegate,
// // // //         GlobalMaterialLocalizations.delegate,
// // // //         GlobalWidgetsLocalizations.delegate,
// // // //         GlobalCupertinoLocalizations.delegate,
// // // //       ],
// // // //       supportedLocales: AppLocalizations.supportedLocales,
// // // //       builder: (context, child) =>
// // // //           _AppShell(child: child ?? const SizedBox.shrink()),
// // // //     );
// // // //   }
// // // // }

// // // // class _AppShell extends StatefulWidget {
// // // //   const _AppShell({required this.child});
// // // //   final Widget child;

// // // //   @override
// // // //   State<_AppShell> createState() => _AppShellState();
// // // // }

// // // // class _AppShellState extends State<_AppShell> {
// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     // Wire OneSignal foreground handler → NotificationProvider toast queue
// // // //     sl.notificationService.registerForegroundHandler((type, title, body, data) {
// // // //       context.read<NotificationProvider>().pushToast(
// // // //         type: type,
// // // //         title: title,
// // // //         body: body,
// // // //         data: data,
// // // //       );
// // // //     });
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Consumer<ConnectivityProvider>(
// // // //       builder: (context, connectivity, _) => Stack(
// // // //         children: [
// // // //           widget.child,
// // // //           if (!connectivity.isOnline)
// // // //             const Positioned(
// // // //               top: 0,
// // // //               left: 0,
// // // //               right: 0,
// // // //               child: _OfflineBanner(),
// // // //             ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class _OfflineBanner extends StatelessWidget {
// // // //   const _OfflineBanner();

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return IgnorePointer(
// // // //       child: Material(
// // // //         color: Colors.transparent,
// // // //         child: SafeArea(
// // // //           bottom: false,
// // // //           child: Container(
// // // //             color: const Color(0xFFB91C1C).withOpacity(0.92),
// // // //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
// // // //             child: Row(
// // // //               mainAxisAlignment: MainAxisAlignment.center,
// // // //               children: [
// // // //                 const Icon(
// // // //                   Icons.wifi_off_rounded,
// // // //                   size: 12,
// // // //                   color: Colors.white,
// // // //                 ),
// // // //                 const SizedBox(width: 6),
// // // //                 Text(
// // // //                   AppLocalizations.of(context).noInternetConnection,
// // // //                   style: const TextStyle(
// // // //                     color: Colors.white,
// // // //                     fontSize: 11,
// // // //                     fontWeight: FontWeight.w600,
// // // //                   ),
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // import 'package:flutter/material.dart';
// // // import 'package:flutter_localizations/flutter_localizations.dart';
// // // import 'package:go_router/go_router.dart';
// // // import 'package:provider/provider.dart';

// // // import 'core/l10n/generated/app_localizations.dart';
// // // import 'core/providers/app_provider.dart';
// // // import 'core/providers/auth_provider.dart';
// // // import 'core/providers/connectivity_provider.dart';
// // // import 'core/router/app_router.dart';
// // // import 'core/theme/app_theme.dart';
// // // import 'core/di/service_locator.dart';
// // // import 'features/friends/presentation/friends_provider.dart';
// // // import 'features/notifications/presentation/notification_provider.dart';
// // // import 'features/packs/presentation/pack_provider.dart';
// // // import 'features/profile/presentation/profile_provider.dart';
// // // import 'features/offline/data/offline_game_provider.dart';
// // // import 'features/offline/data/offline_repository.dart';
// // // import 'features/wallet/presentation/wallet_provider.dart';

// // // class Jma3aApp extends StatefulWidget {
// // //   const Jma3aApp({super.key});

// // //   @override
// // //   State<Jma3aApp> createState() => _Jma3aAppState();
// // // }

// // // class _Jma3aAppState extends State<Jma3aApp> {
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return MultiProvider(
// // //       providers: [
// // //         // ── Infrastructure (always alive) ─────────────────────────────────
// // //         ChangeNotifierProvider(
// // //           create: (_) =>
// // //               ConnectivityProvider(connectivityService: sl.connectivityService),
// // //         ),
// // //         ChangeNotifierProvider(
// // //           create: (_) =>
// // //               AppProvider(localStorageService: sl.localStorageService)
// // //                 ..initialize(),
// // //         ),
// // //         ChangeNotifierProvider(
// // //           create: (_) => AuthProvider(
// // //             authRepository: sl.authRepository,
// // //             secureStorage: sl.secureStorageService,
// // //           )..initialize(),
// // //         ),

// // //         // ── Auth-scoped providers (hydrated/cleared on login/logout) ───────
// // //         ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
// // //           create: (ctx) => ProfileProvider(
// // //             profileRepository: sl.profileRepository,
// // //             authProvider: ctx.read<AuthProvider>(),
// // //           ),
// // //           update: (_, auth, profile) =>
// // //               (profile ??
// // //                     ProfileProvider(
// // //                       profileRepository: sl.profileRepository,
// // //                       authProvider: auth,
// // //                     ))
// // //                 ..onAuthChanged(auth.currentUser?.id),
// // //         ),
// // //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// // //           create: (_) =>
// // //               FriendsProvider(friendsRepository: sl.friendsRepository),
// // //           update: (_, auth, friends) =>
// // //               (friends ??
// // //                     FriendsProvider(friendsRepository: sl.friendsRepository))
// // //                 ..onAuthChanged(auth.currentUser?.id),
// // //         ),
// // //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// // //           create: (_) => NotificationProvider(
// // //             notificationRepository: sl.notificationRepository,
// // //           ),
// // //           update: (_, auth, notifs) =>
// // //               (notifs ??
// // //                     NotificationProvider(
// // //                       notificationRepository: sl.notificationRepository,
// // //                     ))
// // //                 ..onAuthChanged(auth.currentUser?.id),
// // //         ),
// // //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// // //           create: (_) => WalletProvider(walletRepository: sl.walletRepository),
// // //           update: (_, auth, wallet) =>
// // //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// // //                 ..onAuthChanged(auth.currentUser?.id),
// // //         ),
// // //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// // //           create: (_) => PackProvider(
// // //             packRepository: sl.packRepository,
// // //             packSyncService: sl.packSyncService,
// // //           ),
// // //           update: (_, auth, packs) =>
// // //               (packs ??
// // //                     PackProvider(
// // //                       packRepository: sl.packRepository,
// // //                       packSyncService: sl.packSyncService,
// // //                     ))
// // //                 ..onAuthChanged(auth.currentUser?.id),
// // //         ),
// // //         ChangeNotifierProvider(
// // //           create: (_) =>
// // //               OfflineGameProvider(repository: OfflineRepository.instance),
// // //         ),
// // //       ],
// // //       child: const _RouterHost(),
// // //     );
// // //   }
// // // }

// // // /// Created inside MultiProvider so context.read<AuthProvider>() works.
// // // /// Router is built once in didChangeDependencies and never recreated.
// // // class _RouterHost extends StatefulWidget {
// // //   const _RouterHost();

// // //   @override
// // //   State<_RouterHost> createState() => _RouterHostState();
// // // }

// // // class _RouterHostState extends State<_RouterHost> {
// // //   GoRouter? _router;

// // //   @override
// // //   void didChangeDependencies() {
// // //     super.didChangeDependencies();
// // //     _router ??= AppRouter.createRouter(context.read<AuthProvider>());
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     if (_router == null) return const SizedBox.shrink();
// // //     // Watch AppProvider so locale/theme changes rebuild immediately
// // //     final appProvider = context.watch<AppProvider>();
// // //     return MaterialApp.router(
// // //       title: 'Jma3a',
// // //       debugShowCheckedModeBanner: false,
// // //       theme: AppTheme.light(),
// // //       darkTheme: AppTheme.dark(),
// // //       themeMode: appProvider.themeMode,
// // //       routerConfig: _router!,
// // //       locale: appProvider.locale,
// // //       localizationsDelegates: const [
// // //         AppLocalizations.delegate,
// // //         GlobalMaterialLocalizations.delegate,
// // //         GlobalWidgetsLocalizations.delegate,
// // //         GlobalCupertinoLocalizations.delegate,
// // //       ],
// // //       supportedLocales: AppLocalizations.supportedLocales,
// // //       builder: (context, child) =>
// // //           _AppShell(child: child ?? const SizedBox.shrink()),
// // //     );
// // //   }
// // // }

// // // class _AppShell extends StatefulWidget {
// // //   const _AppShell({required this.child});
// // //   final Widget child;

// // //   @override
// // //   State<_AppShell> createState() => _AppShellState();
// // // }

// // // class _AppShellState extends State<_AppShell> {
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     // Wire OneSignal foreground handler → NotificationProvider toast queue
// // //     sl.notificationService.registerForegroundHandler((type, title, body, data) {
// // //       context.read<NotificationProvider>().pushToast(
// // //         type: type,
// // //         title: title,
// // //         body: body,
// // //         data: data,
// // //       );
// // //     });
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Consumer<ConnectivityProvider>(
// // //       builder: (context, connectivity, _) => Stack(
// // //         children: [
// // //           widget.child,
// // //           if (!connectivity.isOnline)
// // //             const Positioned(
// // //               top: 0,
// // //               left: 0,
// // //               right: 0,
// // //               child: _OfflineBanner(),
// // //             ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _OfflineBanner extends StatelessWidget {
// // //   const _OfflineBanner();

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return IgnorePointer(
// // //       child: Material(
// // //         color: Colors.transparent,
// // //         child: SafeArea(
// // //           bottom: false,
// // //           child: Container(
// // //             color: const Color(0xFFB91C1C).withOpacity(0.92),
// // //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
// // //             child: Row(
// // //               mainAxisAlignment: MainAxisAlignment.center,
// // //               children: [
// // //                 const Icon(
// // //                   Icons.wifi_off_rounded,
// // //                   size: 12,
// // //                   color: Colors.white,
// // //                 ),
// // //                 const SizedBox(width: 6),
// // //                 Text(
// // //                   AppLocalizations.of(context).noInternetConnection,
// // //                   style: const TextStyle(
// // //                     color: Colors.white,
// // //                     fontSize: 11,
// // //                     fontWeight: FontWeight.w600,
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // import 'package:flutter/material.dart';
// // import 'package:flutter_localizations/flutter_localizations.dart';
// // import 'package:go_router/go_router.dart';
// // import 'package:jma3a/deep_links.dart';
// // import 'package:provider/provider.dart';

// // import 'core/l10n/generated/app_localizations.dart';
// // import 'core/providers/app_provider.dart';
// // import 'core/providers/auth_provider.dart';
// // import 'core/providers/connectivity_provider.dart';
// // // import 'core/services/deep_link_service.dart';
// // import 'core/router/app_router.dart';
// // import 'core/theme/app_theme.dart';
// // import 'core/di/service_locator.dart';
// // import 'features/friends/presentation/friends_provider.dart';
// // import 'features/notifications/presentation/notification_provider.dart';
// // import 'features/packs/presentation/pack_provider.dart';
// // import 'features/profile/presentation/profile_provider.dart';
// // import 'features/offline/data/offline_game_provider.dart';
// // import 'features/offline/data/offline_repository.dart';
// // import 'features/wallet/presentation/wallet_provider.dart';

// // class Jma3aApp extends StatefulWidget {
// //   const Jma3aApp({super.key});

// //   @override
// //   State<Jma3aApp> createState() => _Jma3aAppState();
// // }

// // class _Jma3aAppState extends State<Jma3aApp> {
// //   @override
// //   Widget build(BuildContext context) {
// //     return MultiProvider(
// //       providers: [
// //         // ── Infrastructure (always alive) ─────────────────────────────────
// //         ChangeNotifierProvider(
// //           create: (_) =>
// //               ConnectivityProvider(connectivityService: sl.connectivityService),
// //         ),
// //         ChangeNotifierProvider(
// //           create: (_) =>
// //               AppProvider(localStorageService: sl.localStorageService)
// //                 ..initialize(),
// //         ),
// //         ChangeNotifierProvider(
// //           create: (_) => AuthProvider(
// //             authRepository: sl.authRepository,
// //             secureStorage: sl.secureStorageService,
// //           )..initialize(),
// //         ),

// //         // ── Auth-scoped providers (hydrated/cleared on login/logout) ───────
// //         ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
// //           create: (ctx) => ProfileProvider(
// //             profileRepository: sl.profileRepository,
// //             authProvider: ctx.read<AuthProvider>(),
// //           ),
// //           update: (_, auth, profile) =>
// //               (profile ??
// //                     ProfileProvider(
// //                       profileRepository: sl.profileRepository,
// //                       authProvider: auth,
// //                     ))
// //                 ..onAuthChanged(auth.currentUser?.id),
// //         ),
// //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// //           create: (_) =>
// //               FriendsProvider(friendsRepository: sl.friendsRepository),
// //           update: (_, auth, friends) =>
// //               (friends ??
// //                     FriendsProvider(friendsRepository: sl.friendsRepository))
// //                 ..onAuthChanged(auth.currentUser?.id),
// //         ),
// //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// //           create: (_) => NotificationProvider(
// //             notificationRepository: sl.notificationRepository,
// //           ),
// //           update: (_, auth, notifs) =>
// //               (notifs ??
// //                     NotificationProvider(
// //                       notificationRepository: sl.notificationRepository,
// //                     ))
// //                 ..onAuthChanged(auth.currentUser?.id),
// //         ),
// //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// //           create: (_) => WalletProvider(walletRepository: sl.walletRepository),
// //           update: (_, auth, wallet) =>
// //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// //                 ..onAuthChanged(auth.currentUser?.id),
// //         ),
// //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// //           create: (_) => PackProvider(
// //             packRepository: sl.packRepository,
// //             packSyncService: sl.packSyncService,
// //           ),
// //           update: (_, auth, packs) =>
// //               (packs ??
// //                     PackProvider(
// //                       packRepository: sl.packRepository,
// //                       packSyncService: sl.packSyncService,
// //                     ))
// //                 ..onAuthChanged(auth.currentUser?.id),
// //         ),
// //         ChangeNotifierProvider(
// //           create: (_) =>
// //               OfflineGameProvider(repository: OfflineRepository.instance),
// //         ),
// //       ],
// //       child: const _RouterHost(),
// //     );
// //   }
// // }

// // /// Created inside MultiProvider so context.read<AuthProvider>() works.
// // /// Router is built once in didChangeDependencies and never recreated.
// // class _RouterHost extends StatefulWidget {
// //   const _RouterHost();

// //   @override
// //   State<_RouterHost> createState() => _RouterHostState();
// // }

// // class _RouterHostState extends State<_RouterHost> {
// //   GoRouter? _router;

// //   @override
// //   void didChangeDependencies() {
// //     super.didChangeDependencies();
// //     _router ??= AppRouter.createRouter(context.read<AuthProvider>());
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     if (_router == null) return const SizedBox.shrink();
// //     // Watch AppProvider so locale/theme changes rebuild immediately
// //     final appProvider = context.watch<AppProvider>();
// //     return MaterialApp.router(
// //       title: 'Jma3a',
// //       debugShowCheckedModeBanner: false,
// //       theme: AppTheme.light(),
// //       darkTheme: AppTheme.dark(),
// //       themeMode: appProvider.themeMode,
// //       routerConfig: _router!,
// //       locale: appProvider.locale,
// //       localizationsDelegates: const [
// //         AppLocalizations.delegate,
// //         GlobalMaterialLocalizations.delegate,
// //         GlobalWidgetsLocalizations.delegate,
// //         GlobalCupertinoLocalizations.delegate,
// //       ],
// //       supportedLocales: AppLocalizations.supportedLocales,
// //       builder: (context, child) =>
// //           _AppShell(child: child ?? const SizedBox.shrink()),
// //     );
// //   }
// // }

// // class _AppShell extends StatefulWidget {
// //   const _AppShell({required this.child});
// //   final Widget child;

// //   @override
// //   State<_AppShell> createState() => _AppShellState();
// // }

// // class _AppShellState extends State<_AppShell> {
// //   @override
// //   void initState() {
// //     super.initState();
// //     // Init deep link service for invite links
// //     DeepLinkService.instance.init();
// //     // Wire OneSignal foreground handler → NotificationProvider toast queue
// //     sl.notificationService.registerForegroundHandler((type, title, body, data) {
// //       context.read<NotificationProvider>().pushToast(
// //         type: type,
// //         title: title,
// //         body: body,
// //         data: data,
// //       );
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Consumer<ConnectivityProvider>(
// //       builder: (context, connectivity, _) => Stack(
// //         children: [
// //           widget.child,
// //           if (!connectivity.isOnline)
// //             const Positioned(
// //               top: 0,
// //               left: 0,
// //               right: 0,
// //               child: _OfflineBanner(),
// //             ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class _OfflineBanner extends StatelessWidget {
// //   const _OfflineBanner();

// //   @override
// //   Widget build(BuildContext context) {
// //     return IgnorePointer(
// //       child: Material(
// //         color: Colors.transparent,
// //         child: SafeArea(
// //           bottom: false,
// //           child: Container(
// //             color: const Color(0xFFB91C1C).withOpacity(0.92),
// //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
// //             child: Row(
// //               mainAxisAlignment: MainAxisAlignment.center,
// //               children: [
// //                 const Icon(
// //                   Icons.wifi_off_rounded,
// //                   size: 12,
// //                   color: Colors.white,
// //                 ),
// //                 const SizedBox(width: 6),
// //                 Text(
// //                   AppLocalizations.of(context).noInternetConnection,
// //                   style: const TextStyle(
// //                     color: Colors.white,
// //                     fontSize: 11,
// //                     fontWeight: FontWeight.w600,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// // // // // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // // // // import 'package:flutter_localizations/flutter_localizations.dart';
// // // // // // // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // // // // // // import 'core/l10n/generated/app_localizations.dart';
// // // // // // // // // // // // // import 'core/providers/app_provider.dart';
// // // // // // // // // // // // // import 'core/providers/auth_provider.dart';
// // // // // // // // // // // // // import 'core/providers/connectivity_provider.dart';
// // // // // // // // // // // // // import 'core/router/app_router.dart';
// // // // // // // // // // // // // import 'core/theme/app_theme.dart';
// // // // // // // // // // // // // import 'features/friends/presentation/friends_provider.dart';
// // // // // // // // // // // // // import 'features/notifications/presentation/notification_provider.dart';
// // // // // // // // // // // // // import 'features/packs/presentation/pack_provider.dart';
// // // // // // // // // // // // // import 'features/wallet/presentation/wallet_provider.dart';
// // // // // // // // // // // // // import 'core/di/service_locator.dart';

// // // // // // // // // // // // // class Jma3aApp extends StatelessWidget {
// // // // // // // // // // // // //   const Jma3aApp({super.key});

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // //     return MultiProvider(
// // // // // // // // // // // // //       providers: [
// // // // // // // // // // // // //         // ── App-level providers (root, never disposed) ────────────────
// // // // // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // // // // //           create: (_) => ConnectivityProvider(
// // // // // // // // // // // // //             connectivityService: sl.connectivityService,
// // // // // // // // // // // // //           ),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // // // // //           create: (_) => AppProvider(
// // // // // // // // // // // // //             localStorageService: sl.localStorageService,
// // // // // // // // // // // // //           )..initialize(),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // // // // //           create: (_) => AuthProvider(
// // // // // // // // // // // // //             authRepository: sl.authRepository,
// // // // // // // // // // // // //             secureStorage: sl.secureStorageService,
// // // // // // // // // // // // //           )..initialize(),
// // // // // // // // // // // // //         ),

// // // // // // // // // // // // //         // ── Auth-dependent providers (hydrated after login) ───────────
// // // // // // // // // // // // //         // These listen to AuthProvider and self-initialize when user is set.
// // // // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// // // // // // // // // // // // //           create: (_) => FriendsProvider(
// // // // // // // // // // // // //             friendsRepository: sl.friendsRepository,
// // // // // // // // // // // // //           ),
// // // // // // // // // // // // //           update: (_, auth, friends) =>
// // // // // // // // // // // // //               (friends ?? FriendsProvider(friendsRepository: sl.friendsRepository))
// // // // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// // // // // // // // // // // // //           create: (_) => NotificationProvider(
// // // // // // // // // // // // //             notificationRepository: sl.notificationRepository,
// // // // // // // // // // // // //           ),
// // // // // // // // // // // // //           update: (_, auth, notifs) =>
// // // // // // // // // // // // //               (notifs ?? NotificationProvider(notificationRepository: sl.notificationRepository))
// // // // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// // // // // // // // // // // // //           create: (_) => WalletProvider(
// // // // // // // // // // // // //             walletRepository: sl.walletRepository,
// // // // // // // // // // // // //           ),
// // // // // // // // // // // // //           update: (_, auth, wallet) =>
// // // // // // // // // // // // //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// // // // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// // // // // // // // // // // // //           create: (_) => PackProvider(
// // // // // // // // // // // // //             packRepository: sl.packRepository,
// // // // // // // // // // // // //             packSyncService: sl.packSyncService,
// // // // // // // // // // // // //           ),
// // // // // // // // // // // // //           update: (_, auth, packs) =>
// // // // // // // // // // // // //               (packs ?? PackProvider(
// // // // // // // // // // // // //                 packRepository: sl.packRepository,
// // // // // // // // // // // // //                 packSyncService: sl.packSyncService,
// // // // // // // // // // // // //               ))..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //       ],
// // // // // // // // // // // // //       child: Consumer<AppProvider>(
// // // // // // // // // // // // //         builder: (context, appProvider, _) {
// // // // // // // // // // // // //           return MaterialApp.router(
// // // // // // // // // // // // //             title: 'Jma3a',
// // // // // // // // // // // // //             debugShowCheckedModeBanner: false,

// // // // // // // // // // // // //             // ── Theme ─────────────────────────────────────────────────
// // // // // // // // // // // // //             theme: AppTheme.light(),
// // // // // // // // // // // // //             darkTheme: AppTheme.dark(),
// // // // // // // // // // // // //             themeMode: appProvider.themeMode,

// // // // // // // // // // // // //             // ── Routing ───────────────────────────────────────────────
// // // // // // // // // // // // //             routerConfig: AppRouter.router,

// // // // // // // // // // // // //             // ── Localization ──────────────────────────────────────────
// // // // // // // // // // // // //             locale: appProvider.locale,
// // // // // // // // // // // // //             localizationsDelegates: const [
// // // // // // // // // // // // //               AppLocalizations.delegate,
// // // // // // // // // // // // //               GlobalMaterialLocalizations.delegate,
// // // // // // // // // // // // //               GlobalWidgetsLocalizations.delegate,
// // // // // // // // // // // // //               GlobalCupertinoLocalizations.delegate,
// // // // // // // // // // // // //             ],
// // // // // // // // // // // // //             supportedLocales: AppLocalizations.supportedLocales,

// // // // // // // // // // // // //             // ── Builder: global overlays (connectivity banner, etc.) ──
// // // // // // // // // // // // //             builder: (context, child) {
// // // // // // // // // // // // //               return _AppShell(child: child ?? const SizedBox.shrink());
// // // // // // // // // // // // //             },
// // // // // // // // // // // // //           );
// // // // // // // // // // // // //         },
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //   }
// // // // // // // // // // // // // }

// // // // // // // // // // // // // /// Wraps every screen with global overlays and layout constraints.
// // // // // // // // // // // // // class _AppShell extends StatelessWidget {
// // // // // // // // // // // // //   const _AppShell({required this.child});
// // // // // // // // // // // // //   final Widget child;

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // //     return Consumer<ConnectivityProvider>(
// // // // // // // // // // // // //       builder: (context, connectivity, _) {
// // // // // // // // // // // // //         return Stack(
// // // // // // // // // // // // //           children: [
// // // // // // // // // // // // //             child,
// // // // // // // // // // // // //             // Connectivity banner slides in when offline
// // // // // // // // // // // // //             if (!connectivity.isOnline)
// // // // // // // // // // // // //               const Positioned(
// // // // // // // // // // // // //                 bottom: 0,
// // // // // // // // // // // // //                 left: 0,
// // // // // // // // // // // // //                 right: 0,
// // // // // // // // // // // // //                 child: _OfflineBanner(),
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //           ],
// // // // // // // // // // // // //         );
// // // // // // // // // // // // //       },
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //   }
// // // // // // // // // // // // // }

// // // // // // // // // // // // // class _OfflineBanner extends StatelessWidget {
// // // // // // // // // // // // //   const _OfflineBanner();

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // //     final theme = Theme.of(context);
// // // // // // // // // // // // //     return Material(
// // // // // // // // // // // // //       color: theme.colorScheme.error,
// // // // // // // // // // // // //       child: SafeArea(
// // // // // // // // // // // // //         top: false,
// // // // // // // // // // // // //         child: Padding(
// // // // // // // // // // // // //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // // // // // // // // // // //           child: Row(
// // // // // // // // // // // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // // // // // // // // // // //             children: [
// // // // // // // // // // // // //               Icon(Icons.wifi_off_rounded, size: 16, color: theme.colorScheme.onError),
// // // // // // // // // // // // //               const SizedBox(width: 8),
// // // // // // // // // // // // //               Text(
// // // // // // // // // // // // //                 AppLocalizations.of(context).noInternetConnection,
// // // // // // // // // // // // //                 style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // // // // // // //                   color: theme.colorScheme.onError,
// // // // // // // // // // // // //                   fontWeight: FontWeight.w500,
// // // // // // // // // // // // //                 ),
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //             ],
// // // // // // // // // // // // //           ),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //   }
// // // // // // // // // // // // // }

// // // // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // // // import 'package:flutter_localizations/flutter_localizations.dart';
// // // // // // // // // // // // import 'package:jma3a/features/profile/presentation/profile_provider.dart';
// // // // // // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // // // // // import 'core/l10n/generated/app_localizations.dart';
// // // // // // // // // // // // import 'core/providers/app_provider.dart';
// // // // // // // // // // // // import 'core/providers/auth_provider.dart';
// // // // // // // // // // // // import 'core/providers/connectivity_provider.dart';
// // // // // // // // // // // // import 'core/router/app_router.dart';
// // // // // // // // // // // // import 'core/theme/app_theme.dart';
// // // // // // // // // // // // import 'core/di/service_locator.dart';
// // // // // // // // // // // // import 'features/friends/presentation/friends_provider.dart';
// // // // // // // // // // // // import 'features/notifications/presentation/notification_provider.dart';
// // // // // // // // // // // // import 'features/packs/presentation/pack_provider.dart';
// // // // // // // // // // // // // import 'features/profile/presentation/profile_provider.dart';
// // // // // // // // // // // // import 'features/wallet/presentation/wallet_provider.dart';

// // // // // // // // // // // // class Jma3aApp extends StatelessWidget {
// // // // // // // // // // // //   const Jma3aApp({super.key});

// // // // // // // // // // // //   @override
// // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // //     return MultiProvider(
// // // // // // // // // // // //       providers: [
// // // // // // // // // // // //         // ── Infrastructure (always alive) ─────────────────────────────────
// // // // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // // // //           create: (_) =>
// // // // // // // // // // // //               ConnectivityProvider(connectivityService: sl.connectivityService),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // // // //           create: (_) =>
// // // // // // // // // // // //               AppProvider(localStorageService: sl.localStorageService)
// // // // // // // // // // // //                 ..initialize(),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // // // //           create: (_) => AuthProvider(
// // // // // // // // // // // //             authRepository: sl.authRepository,
// // // // // // // // // // // //             secureStorage: sl.secureStorageService,
// // // // // // // // // // // //           )..initialize(),
// // // // // // // // // // // //         ),

// // // // // // // // // // // //         // ── Auth-scoped providers (hydrated/cleared on login/logout) ───────
// // // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
// // // // // // // // // // // //           create: (ctx) => ProfileProvider(
// // // // // // // // // // // //             profileRepository: sl.profileRepository,
// // // // // // // // // // // //             authProvider: ctx.read<AuthProvider>(),
// // // // // // // // // // // //           ),
// // // // // // // // // // // //           update: (_, auth, profile) =>
// // // // // // // // // // // //               (profile ??
// // // // // // // // // // // //                     ProfileProvider(
// // // // // // // // // // // //                       profileRepository: sl.profileRepository,
// // // // // // // // // // // //                       authProvider: auth,
// // // // // // // // // // // //                     ))
// // // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// // // // // // // // // // // //           create: (_) =>
// // // // // // // // // // // //               FriendsProvider(friendsRepository: sl.friendsRepository),
// // // // // // // // // // // //           update: (_, auth, friends) =>
// // // // // // // // // // // //               (friends ??
// // // // // // // // // // // //                     FriendsProvider(friendsRepository: sl.friendsRepository))
// // // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// // // // // // // // // // // //           create: (_) => NotificationProvider(
// // // // // // // // // // // //             notificationRepository: sl.notificationRepository,
// // // // // // // // // // // //           ),
// // // // // // // // // // // //           update: (_, auth, notifs) =>
// // // // // // // // // // // //               (notifs ??
// // // // // // // // // // // //                     NotificationProvider(
// // // // // // // // // // // //                       notificationRepository: sl.notificationRepository,
// // // // // // // // // // // //                     ))
// // // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// // // // // // // // // // // //           create: (_) => WalletProvider(walletRepository: sl.walletRepository),
// // // // // // // // // // // //           update: (_, auth, wallet) =>
// // // // // // // // // // // //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// // // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// // // // // // // // // // // //           create: (_) => PackProvider(
// // // // // // // // // // // //             packRepository: sl.packRepository,
// // // // // // // // // // // //             packSyncService: sl.packSyncService,
// // // // // // // // // // // //           ),
// // // // // // // // // // // //           update: (_, auth, packs) =>
// // // // // // // // // // // //               (packs ??
// // // // // // // // // // // //                     PackProvider(
// // // // // // // // // // // //                       packRepository: sl.packRepository,
// // // // // // // // // // // //                       packSyncService: sl.packSyncService,
// // // // // // // // // // // //                     ))
// // // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //       ],
// // // // // // // // // // // //       child: Consumer<AppProvider>(
// // // // // // // // // // // //         builder: (context, appProvider, _) {
// // // // // // // // // // // //           return MaterialApp.router(
// // // // // // // // // // // //             title: 'Jma3a',
// // // // // // // // // // // //             debugShowCheckedModeBanner: false,
// // // // // // // // // // // //             theme: AppTheme.light(),
// // // // // // // // // // // //             darkTheme: AppTheme.dark(),
// // // // // // // // // // // //             themeMode: appProvider.themeMode,
// // // // // // // // // // // //             routerConfig: AppRouter.router,
// // // // // // // // // // // //             locale: appProvider.locale,
// // // // // // // // // // // //             localizationsDelegates: const [
// // // // // // // // // // // //               AppLocalizations.delegate,
// // // // // // // // // // // //               GlobalMaterialLocalizations.delegate,
// // // // // // // // // // // //               GlobalWidgetsLocalizations.delegate,
// // // // // // // // // // // //               GlobalCupertinoLocalizations.delegate,
// // // // // // // // // // // //             ],
// // // // // // // // // // // //             supportedLocales: AppLocalizations.supportedLocales,
// // // // // // // // // // // //             builder: (context, child) =>
// // // // // // // // // // // //                 _AppShell(child: child ?? const SizedBox.shrink()),
// // // // // // // // // // // //           );
// // // // // // // // // // // //         },
// // // // // // // // // // // //       ),
// // // // // // // // // // // //     );
// // // // // // // // // // // //   }
// // // // // // // // // // // // }

// // // // // // // // // // // // // class _AppShell extends StatefulWidget {
// // // // // // // // // // // // //   const _AppShell({required this.child});
// // // // // // // // // // // // //   final Widget child;

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   State<_AppShell> createState() => _AppShellState();
// // // // // // // // // // // // // }

// // // // // // // // // // // // // class _AppShellState extends State<_AppShell> {
// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   void initState() {
// // // // // // // // // // // // //     super.initState();
// // // // // // // // // // // // //     // Wire OneSignal foreground handler → NotificationProvider toast queue
// // // // // // // // // // // // //     sl.notificationService.registerForegroundHandler((type, title, body, data) {
// // // // // // // // // // // // //       context.read<NotificationProvider>().pushToast(
// // // // // // // // // // // // //         type: type,
// // // // // // // // // // // // //         title: title,
// // // // // // // // // // // // //         body: body,
// // // // // // // // // // // // //         data: data,
// // // // // // // // // // // // //       );
// // // // // // // // // // // // //     });
// // // // // // // // // // // // //   }

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // //     return Consumer<ConnectivityProvider>(
// // // // // // // // // // // // //       builder: (context, connectivity, child) => Stack(
// // // // // // // // // // // // //         children: [
// // // // // // // // // // // // //           child!,
// // // // // // // // // // // // //           if (!connectivity.isOnline)
// // // // // // // // // // // // //             const Positioned(
// // // // // // // // // // // // //               bottom: 0,
// // // // // // // // // // // // //               left: 0,
// // // // // // // // // // // // //               right: 0,
// // // // // // // // // // // // //               child: _OfflineBanner(),
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //         ],
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //   }
// // // // // // // // // // // // // }

// // // // // // // // // // // // class _AppShell extends StatefulWidget {
// // // // // // // // // // // //   const _AppShell({required this.child});
// // // // // // // // // // // //   final Widget child;

// // // // // // // // // // // //   @override
// // // // // // // // // // // //   State<_AppShell> createState() => _AppShellState();
// // // // // // // // // // // // }

// // // // // // // // // // // // class _AppShellState extends State<_AppShell> {
// // // // // // // // // // // //   @override
// // // // // // // // // // // //   void initState() {
// // // // // // // // // // // //     super.initState();
// // // // // // // // // // // //     // Use WidgetsBinding to ensure context is available after build
// // // // // // // // // // // //     WidgetsBinding.instance.addPostFrameCallback((_) {
// // // // // // // // // // // //       if (mounted) {
// // // // // // // // // // // //         // Wire OneSignal foreground handler → NotificationProvider toast queue
// // // // // // // // // // // //         sl.notificationService.registerForegroundHandler((
// // // // // // // // // // // //           type,
// // // // // // // // // // // //           title,
// // // // // // // // // // // //           body,
// // // // // // // // // // // //           data,
// // // // // // // // // // // //         ) {
// // // // // // // // // // // //           // Use mounted check before accessing context
// // // // // // // // // // // //           if (mounted) {
// // // // // // // // // // // //             final notificationProvider = context.read<NotificationProvider>();
// // // // // // // // // // // //             notificationProvider.pushToast(
// // // // // // // // // // // //               type: type,
// // // // // // // // // // // //               title: title,
// // // // // // // // // // // //               body: body,
// // // // // // // // // // // //               data: data,
// // // // // // // // // // // //             );
// // // // // // // // // // // //           }
// // // // // // // // // // // //         });
// // // // // // // // // // // //       }
// // // // // // // // // // // //     });
// // // // // // // // // // // //   }

// // // // // // // // // // // //   @override
// // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // //     return Consumer<ConnectivityProvider>(
// // // // // // // // // // // //       builder: (context, connectivity, child) {
// // // // // // // // // // // //         return Stack(
// // // // // // // // // // // //           children: [
// // // // // // // // // // // //             // Use the widget.child instead of child! from Consumer
// // // // // // // // // // // //             widget.child,
// // // // // // // // // // // //             if (!connectivity.isOnline)
// // // // // // // // // // // //               const Positioned(
// // // // // // // // // // // //                 bottom: 0,
// // // // // // // // // // // //                 left: 0,
// // // // // // // // // // // //                 right: 0,
// // // // // // // // // // // //                 child: _OfflineBanner(),
// // // // // // // // // // // //               ),
// // // // // // // // // // // //           ],
// // // // // // // // // // // //         );
// // // // // // // // // // // //       },
// // // // // // // // // // // //     );
// // // // // // // // // // // //   }
// // // // // // // // // // // // }

// // // // // // // // // // // // class _OfflineBanner extends StatelessWidget {
// // // // // // // // // // // //   const _OfflineBanner();

// // // // // // // // // // // //   @override
// // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // //     final theme = Theme.of(context);
// // // // // // // // // // // //     return Material(
// // // // // // // // // // // //       color: theme.colorScheme.error,
// // // // // // // // // // // //       child: SafeArea(
// // // // // // // // // // // //         top: false,
// // // // // // // // // // // //         child: Padding(
// // // // // // // // // // // //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // // // // // // // // // //           child: Row(
// // // // // // // // // // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // // // // // // // // // //             children: [
// // // // // // // // // // // //               Icon(
// // // // // // // // // // // //                 Icons.wifi_off_rounded,
// // // // // // // // // // // //                 size: 16,
// // // // // // // // // // // //                 color: theme.colorScheme.onError,
// // // // // // // // // // // //               ),
// // // // // // // // // // // //               const SizedBox(width: 8),
// // // // // // // // // // // //               Text(
// // // // // // // // // // // //                 AppLocalizations.of(context).noInternetConnection,
// // // // // // // // // // // //                 style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // // // // // //                   color: theme.colorScheme.onError,
// // // // // // // // // // // //                   fontWeight: FontWeight.w500,
// // // // // // // // // // // //                 ),
// // // // // // // // // // // //               ),
// // // // // // // // // // // //             ],
// // // // // // // // // // // //           ),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //       ),
// // // // // // // // // // // //     );
// // // // // // // // // // // //   }
// // // // // // // // // // // // }

// // // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // // import 'package:flutter_localizations/flutter_localizations.dart';
// // // // // // // // // // // import 'package:jma3a/features/profile/presentation/profile_provider.dart';
// // // // // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // // // // import 'core/l10n/generated/app_localizations.dart';
// // // // // // // // // // // import 'core/providers/app_provider.dart';
// // // // // // // // // // // import 'core/providers/auth_provider.dart';
// // // // // // // // // // // import 'core/providers/connectivity_provider.dart';
// // // // // // // // // // // import 'core/router/app_router.dart';
// // // // // // // // // // // import 'core/theme/app_theme.dart';
// // // // // // // // // // // import 'core/di/service_locator.dart';
// // // // // // // // // // // import 'features/friends/presentation/friends_provider.dart';
// // // // // // // // // // // import 'features/notifications/presentation/notification_provider.dart';
// // // // // // // // // // // import 'features/packs/presentation/pack_provider.dart';
// // // // // // // // // // // import 'features/wallet/presentation/wallet_provider.dart';

// // // // // // // // // // // class Jma3aApp extends StatelessWidget {
// // // // // // // // // // //   const Jma3aApp({super.key});

// // // // // // // // // // //   @override
// // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // //     return MultiProvider(
// // // // // // // // // // //       providers: [
// // // // // // // // // // //         // ── Infrastructure (always alive) ─────────────────────────────────
// // // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // // //           create: (_) =>
// // // // // // // // // // //               ConnectivityProvider(connectivityService: sl.connectivityService),
// // // // // // // // // // //         ),
// // // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // // //           create: (_) =>
// // // // // // // // // // //               AppProvider(localStorageService: sl.localStorageService)
// // // // // // // // // // //                 ..initialize(),
// // // // // // // // // // //         ),
// // // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // // //           create: (_) => AuthProvider(
// // // // // // // // // // //             authRepository: sl.authRepository,
// // // // // // // // // // //             secureStorage: sl.secureStorageService,
// // // // // // // // // // //           )..initialize(),
// // // // // // // // // // //         ),

// // // // // // // // // // //         // ── Auth-scoped providers (hydrated/cleared on login/logout) ───────
// // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
// // // // // // // // // // //           create: (ctx) => ProfileProvider(
// // // // // // // // // // //             profileRepository: sl.profileRepository,
// // // // // // // // // // //             authProvider: ctx.read<AuthProvider>(),
// // // // // // // // // // //           ),
// // // // // // // // // // //           update: (_, auth, profile) =>
// // // // // // // // // // //               (profile ??
// // // // // // // // // // //                     ProfileProvider(
// // // // // // // // // // //                       profileRepository: sl.profileRepository,
// // // // // // // // // // //                       authProvider: auth,
// // // // // // // // // // //                     ))
// // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // //         ),
// // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// // // // // // // // // // //           create: (_) =>
// // // // // // // // // // //               FriendsProvider(friendsRepository: sl.friendsRepository),
// // // // // // // // // // //           update: (_, auth, friends) =>
// // // // // // // // // // //               (friends ??
// // // // // // // // // // //                     FriendsProvider(friendsRepository: sl.friendsRepository))
// // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // //         ),
// // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// // // // // // // // // // //           create: (_) => NotificationProvider(
// // // // // // // // // // //             notificationRepository: sl.notificationRepository,
// // // // // // // // // // //           ),
// // // // // // // // // // //           update: (_, auth, notifs) =>
// // // // // // // // // // //               (notifs ??
// // // // // // // // // // //                     NotificationProvider(
// // // // // // // // // // //                       notificationRepository: sl.notificationRepository,
// // // // // // // // // // //                     ))
// // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // //         ),
// // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// // // // // // // // // // //           create: (_) => WalletProvider(walletRepository: sl.walletRepository),
// // // // // // // // // // //           update: (_, auth, wallet) =>
// // // // // // // // // // //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // //         ),
// // // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// // // // // // // // // // //           create: (_) => PackProvider(
// // // // // // // // // // //             packRepository: sl.packRepository,
// // // // // // // // // // //             packSyncService: sl.packSyncService,
// // // // // // // // // // //           ),
// // // // // // // // // // //           update: (_, auth, packs) =>
// // // // // // // // // // //               (packs ??
// // // // // // // // // // //                     PackProvider(
// // // // // // // // // // //                       packRepository: sl.packRepository,
// // // // // // // // // // //                       packSyncService: sl.packSyncService,
// // // // // // // // // // //                     ))
// // // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // // //         ),
// // // // // // // // // // //       ],
// // // // // // // // // // //       child: Consumer<AppProvider>(
// // // // // // // // // // //         builder: (context, appProvider, _) {
// // // // // // // // // // //           return MaterialApp.router(
// // // // // // // // // // //             title: 'Jma3a',
// // // // // // // // // // //             debugShowCheckedModeBanner: false,
// // // // // // // // // // //             theme: AppTheme.light(),
// // // // // // // // // // //             darkTheme: AppTheme.dark(),
// // // // // // // // // // //             themeMode: appProvider.themeMode,
// // // // // // // // // // //             routerConfig: AppRouter.router,
// // // // // // // // // // //             locale: appProvider.locale,
// // // // // // // // // // //             localizationsDelegates: const [
// // // // // // // // // // //               AppLocalizations.delegate,
// // // // // // // // // // //               GlobalMaterialLocalizations.delegate,
// // // // // // // // // // //               GlobalWidgetsLocalizations.delegate,
// // // // // // // // // // //               GlobalCupertinoLocalizations.delegate,
// // // // // // // // // // //             ],
// // // // // // // // // // //             supportedLocales: AppLocalizations.supportedLocales,
// // // // // // // // // // //             builder: (context, child) =>
// // // // // // // // // // //                 _AppShell(child: child ?? const SizedBox.shrink()),
// // // // // // // // // // //           );
// // // // // // // // // // //         },
// // // // // // // // // // //       ),
// // // // // // // // // // //     );
// // // // // // // // // // //   }
// // // // // // // // // // // }

// // // // // // // // // // // class _AppShell extends StatefulWidget {
// // // // // // // // // // //   const _AppShell({required this.child});
// // // // // // // // // // //   final Widget child;

// // // // // // // // // // //   @override
// // // // // // // // // // //   State<_AppShell> createState() => _AppShellState();
// // // // // // // // // // // }

// // // // // // // // // // // class _AppShellState extends State<_AppShell> {
// // // // // // // // // // //   @override
// // // // // // // // // // //   void initState() {
// // // // // // // // // // //     super.initState();
// // // // // // // // // // //     // Use WidgetsBinding to ensure context is available after build
// // // // // // // // // // //     WidgetsBinding.instance.addPostFrameCallback((_) {
// // // // // // // // // // //       if (mounted) {
// // // // // // // // // // //         // Wire OneSignal foreground handler → NotificationProvider toast queue
// // // // // // // // // // //         sl.notificationService.registerForegroundHandler((
// // // // // // // // // // //           type,
// // // // // // // // // // //           title,
// // // // // // // // // // //           body,
// // // // // // // // // // //           data,
// // // // // // // // // // //         ) {
// // // // // // // // // // //           // Use mounted check before accessing context
// // // // // // // // // // //           if (mounted) {
// // // // // // // // // // //             final notificationProvider = context.read<NotificationProvider>();
// // // // // // // // // // //             notificationProvider.pushToast(
// // // // // // // // // // //               type: type,
// // // // // // // // // // //               title: title,
// // // // // // // // // // //               body: body,
// // // // // // // // // // //               data: data,
// // // // // // // // // // //             );
// // // // // // // // // // //           }
// // // // // // // // // // //         });
// // // // // // // // // // //       }
// // // // // // // // // // //     });
// // // // // // // // // // //   }

// // // // // // // // // // //   @override
// // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // //     return Consumer<ConnectivityProvider>(
// // // // // // // // // // //       builder: (context, connectivity, child) {
// // // // // // // // // // //         return Stack(
// // // // // // // // // // //           children: [
// // // // // // // // // // //             widget.child,
// // // // // // // // // // //             if (!connectivity.isOnline)
// // // // // // // // // // //               const Positioned(
// // // // // // // // // // //                 bottom: 0,
// // // // // // // // // // //                 left: 0,
// // // // // // // // // // //                 right: 0,
// // // // // // // // // // //                 child: _OfflineBanner(),
// // // // // // // // // // //               ),
// // // // // // // // // // //           ],
// // // // // // // // // // //         );
// // // // // // // // // // //       },
// // // // // // // // // // //     );
// // // // // // // // // // //   }
// // // // // // // // // // // }

// // // // // // // // // // // class _OfflineBanner extends StatelessWidget {
// // // // // // // // // // //   const _OfflineBanner();

// // // // // // // // // // //   @override
// // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // //     final theme = Theme.of(context);
// // // // // // // // // // //     return Material(
// // // // // // // // // // //       color: theme.colorScheme.error,
// // // // // // // // // // //       child: SafeArea(
// // // // // // // // // // //         top: false,
// // // // // // // // // // //         child: Padding(
// // // // // // // // // // //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // // // // // // // // //           child: Row(
// // // // // // // // // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // // // // // // // // //             children: [
// // // // // // // // // // //               Icon(
// // // // // // // // // // //                 Icons.wifi_off_rounded,
// // // // // // // // // // //                 size: 16,
// // // // // // // // // // //                 color: theme.colorScheme.onError,
// // // // // // // // // // //               ),
// // // // // // // // // // //               const SizedBox(width: 8),
// // // // // // // // // // //               Text(
// // // // // // // // // // //                 AppLocalizations.of(context).noInternetConnection,
// // // // // // // // // // //                 style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // // // // //                   color: theme.colorScheme.onError,
// // // // // // // // // // //                   fontWeight: FontWeight.w500,
// // // // // // // // // // //                 ),
// // // // // // // // // // //               ),
// // // // // // // // // // //             ],
// // // // // // // // // // //           ),
// // // // // // // // // // //         ),
// // // // // // // // // // //       ),
// // // // // // // // // // //     );
// // // // // // // // // // //   }
// // // // // // // // // // // }
// // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // import 'package:flutter_localizations/flutter_localizations.dart';
// // // // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // // // import 'core/l10n/generated/app_localizations.dart';
// // // // // // // // // // import 'core/providers/app_provider.dart';
// // // // // // // // // // import 'core/providers/auth_provider.dart';
// // // // // // // // // // import 'core/providers/connectivity_provider.dart';
// // // // // // // // // // import 'core/router/app_router.dart';
// // // // // // // // // // import 'core/theme/app_theme.dart';
// // // // // // // // // // import 'core/di/service_locator.dart';
// // // // // // // // // // import 'features/friends/presentation/friends_provider.dart';
// // // // // // // // // // import 'features/notifications/presentation/notification_provider.dart';
// // // // // // // // // // import 'features/packs/presentation/pack_provider.dart';
// // // // // // // // // // import 'features/profile/presentation/profile_provider.dart';
// // // // // // // // // // import 'features/wallet/presentation/wallet_provider.dart';

// // // // // // // // // // class Jma3aApp extends StatelessWidget {
// // // // // // // // // //   const Jma3aApp({super.key});

// // // // // // // // // //   @override
// // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // //     return MultiProvider(
// // // // // // // // // //       providers: [
// // // // // // // // // //         // ── Infrastructure (always alive) ─────────────────────────────────
// // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // //           create: (_) =>
// // // // // // // // // //               ConnectivityProvider(connectivityService: sl.connectivityService),
// // // // // // // // // //         ),
// // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // //           create: (_) =>
// // // // // // // // // //               AppProvider(localStorageService: sl.localStorageService)
// // // // // // // // // //                 ..initialize(),
// // // // // // // // // //         ),
// // // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // // //           create: (_) => AuthProvider(
// // // // // // // // // //             authRepository: sl.authRepository,
// // // // // // // // // //             secureStorage: sl.secureStorageService,
// // // // // // // // // //           )..initialize(),
// // // // // // // // // //         ),

// // // // // // // // // //         // ── Auth-scoped providers (hydrated/cleared on login/logout) ───────
// // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
// // // // // // // // // //           create: (ctx) => ProfileProvider(
// // // // // // // // // //             profileRepository: sl.profileRepository,
// // // // // // // // // //             authProvider: ctx.read<AuthProvider>(),
// // // // // // // // // //           ),
// // // // // // // // // //           update: (_, auth, profile) =>
// // // // // // // // // //               (profile ??
// // // // // // // // // //                     ProfileProvider(
// // // // // // // // // //                       profileRepository: sl.profileRepository,
// // // // // // // // // //                       authProvider: auth,
// // // // // // // // // //                     ))
// // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // //         ),
// // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// // // // // // // // // //           create: (_) =>
// // // // // // // // // //               FriendsProvider(friendsRepository: sl.friendsRepository),
// // // // // // // // // //           update: (_, auth, friends) =>
// // // // // // // // // //               (friends ??
// // // // // // // // // //                     FriendsProvider(friendsRepository: sl.friendsRepository))
// // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // //         ),
// // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// // // // // // // // // //           create: (_) => NotificationProvider(
// // // // // // // // // //             notificationRepository: sl.notificationRepository,
// // // // // // // // // //           ),
// // // // // // // // // //           update: (_, auth, notifs) =>
// // // // // // // // // //               (notifs ??
// // // // // // // // // //                     NotificationProvider(
// // // // // // // // // //                       notificationRepository: sl.notificationRepository,
// // // // // // // // // //                     ))
// // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // //         ),
// // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// // // // // // // // // //           create: (_) => WalletProvider(walletRepository: sl.walletRepository),
// // // // // // // // // //           update: (_, auth, wallet) =>
// // // // // // // // // //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // //         ),
// // // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// // // // // // // // // //           create: (_) => PackProvider(
// // // // // // // // // //             packRepository: sl.packRepository,
// // // // // // // // // //             packSyncService: sl.packSyncService,
// // // // // // // // // //           ),
// // // // // // // // // //           update: (_, auth, packs) =>
// // // // // // // // // //               (packs ??
// // // // // // // // // //                     PackProvider(
// // // // // // // // // //                       packRepository: sl.packRepository,
// // // // // // // // // //                       packSyncService: sl.packSyncService,
// // // // // // // // // //                     ))
// // // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // // //         ),
// // // // // // // // // //       ],
// // // // // // // // // //       child: Consumer<AuthProvider>(
// // // // // // // // // //         builder: (context, auth, _) {
// // // // // // // // // //           return Consumer<AppProvider>(
// // // // // // // // // //             builder: (context, appProvider, _) {
// // // // // // // // // //               return MaterialApp.router(
// // // // // // // // // //                 title: 'Jma3a',
// // // // // // // // // //                 debugShowCheckedModeBanner: false,
// // // // // // // // // //                 theme: AppTheme.light(),
// // // // // // // // // //                 darkTheme: AppTheme.dark(),
// // // // // // // // // //                 themeMode: appProvider.themeMode,
// // // // // // // // // //                 routerConfig: AppRouter.createRouter(auth),
// // // // // // // // // //                 locale: appProvider.locale,
// // // // // // // // // //                 localizationsDelegates: const [
// // // // // // // // // //                   AppLocalizations.delegate,
// // // // // // // // // //                   GlobalMaterialLocalizations.delegate,
// // // // // // // // // //                   GlobalWidgetsLocalizations.delegate,
// // // // // // // // // //                   GlobalCupertinoLocalizations.delegate,
// // // // // // // // // //                 ],
// // // // // // // // // //                 supportedLocales: AppLocalizations.supportedLocales,
// // // // // // // // // //                 builder: (context, child) =>
// // // // // // // // // //                     _AppShell(child: child ?? const SizedBox.shrink()),
// // // // // // // // // //               );
// // // // // // // // // //             },
// // // // // // // // // //           );
// // // // // // // // // //         },
// // // // // // // // // //       ),
// // // // // // // // // //     );
// // // // // // // // // //   }
// // // // // // // // // // }

// // // // // // // // // // class _AppShell extends StatefulWidget {
// // // // // // // // // //   const _AppShell({required this.child});
// // // // // // // // // //   final Widget child;

// // // // // // // // // //   @override
// // // // // // // // // //   State<_AppShell> createState() => _AppShellState();
// // // // // // // // // // }

// // // // // // // // // // class _AppShellState extends State<_AppShell> {
// // // // // // // // // //   @override
// // // // // // // // // //   void initState() {
// // // // // // // // // //     super.initState();
// // // // // // // // // //     // Wire OneSignal foreground handler → NotificationProvider toast queue
// // // // // // // // // //     sl.notificationService.registerForegroundHandler((type, title, body, data) {
// // // // // // // // // //       context.read<NotificationProvider>().pushToast(
// // // // // // // // // //         type: type,
// // // // // // // // // //         title: title,
// // // // // // // // // //         body: body,
// // // // // // // // // //         data: data,
// // // // // // // // // //       );
// // // // // // // // // //     });
// // // // // // // // // //   }

// // // // // // // // // //   @override
// // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // //     return Consumer<ConnectivityProvider>(
// // // // // // // // // //       builder: (context, connectivity, _) => Stack(
// // // // // // // // // //         children: [
// // // // // // // // // //           widget.child,
// // // // // // // // // //           if (!connectivity.isOnline)
// // // // // // // // // //             const Positioned(
// // // // // // // // // //               bottom: 0,
// // // // // // // // // //               left: 0,
// // // // // // // // // //               right: 0,
// // // // // // // // // //               child: _OfflineBanner(),
// // // // // // // // // //             ),
// // // // // // // // // //         ],
// // // // // // // // // //       ),
// // // // // // // // // //     );
// // // // // // // // // //   }
// // // // // // // // // // }

// // // // // // // // // // class _OfflineBanner extends StatelessWidget {
// // // // // // // // // //   const _OfflineBanner();

// // // // // // // // // //   @override
// // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // //     final theme = Theme.of(context);
// // // // // // // // // //     return Material(
// // // // // // // // // //       color: theme.colorScheme.error,
// // // // // // // // // //       child: SafeArea(
// // // // // // // // // //         top: false,
// // // // // // // // // //         child: Padding(
// // // // // // // // // //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // // // // // // // //           child: Row(
// // // // // // // // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // // // // // // // //             children: [
// // // // // // // // // //               Icon(
// // // // // // // // // //                 Icons.wifi_off_rounded,
// // // // // // // // // //                 size: 16,
// // // // // // // // // //                 color: theme.colorScheme.onError,
// // // // // // // // // //               ),
// // // // // // // // // //               const SizedBox(width: 8),
// // // // // // // // // //               Text(
// // // // // // // // // //                 AppLocalizations.of(context).noInternetConnection,
// // // // // // // // // //                 style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // // // //                   color: theme.colorScheme.onError,
// // // // // // // // // //                   fontWeight: FontWeight.w500,
// // // // // // // // // //                 ),
// // // // // // // // // //               ),
// // // // // // // // // //             ],
// // // // // // // // // //           ),
// // // // // // // // // //         ),
// // // // // // // // // //       ),
// // // // // // // // // //     );
// // // // // // // // // //   }
// // // // // // // // // // }
// // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // import 'package:flutter_localizations/flutter_localizations.dart';
// // // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // // import 'core/l10n/generated/app_localizations.dart';
// // // // // // // // // import 'core/providers/app_provider.dart';
// // // // // // // // // import 'core/providers/auth_provider.dart';
// // // // // // // // // import 'core/providers/connectivity_provider.dart';
// // // // // // // // // import 'core/router/app_router.dart';
// // // // // // // // // import 'core/theme/app_theme.dart';
// // // // // // // // // import 'core/di/service_locator.dart';
// // // // // // // // // import 'features/friends/presentation/friends_provider.dart';
// // // // // // // // // import 'features/notifications/presentation/notification_provider.dart';
// // // // // // // // // import 'features/packs/presentation/pack_provider.dart';
// // // // // // // // // import 'features/profile/presentation/profile_provider.dart';
// // // // // // // // // import 'features/wallet/presentation/wallet_provider.dart';

// // // // // // // // // class Jma3aApp extends StatefulWidget {
// // // // // // // // //   const Jma3aApp({super.key});

// // // // // // // // //   @override
// // // // // // // // //   State<Jma3aApp> createState() => _Jma3aAppState();
// // // // // // // // // }

// // // // // // // // // class _Jma3aAppState extends State<Jma3aApp> {
// // // // // // // // //   @override
// // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // //     return MultiProvider(
// // // // // // // // //       providers: [
// // // // // // // // //         // ── Infrastructure (always alive) ─────────────────────────────────
// // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // //           create: (_) =>
// // // // // // // // //               ConnectivityProvider(connectivityService: sl.connectivityService),
// // // // // // // // //         ),
// // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // //           create: (_) =>
// // // // // // // // //               AppProvider(localStorageService: sl.localStorageService)
// // // // // // // // //                 ..initialize(),
// // // // // // // // //         ),
// // // // // // // // //         ChangeNotifierProvider(
// // // // // // // // //           create: (_) => AuthProvider(
// // // // // // // // //             authRepository: sl.authRepository,
// // // // // // // // //             secureStorage: sl.secureStorageService,
// // // // // // // // //           )..initialize(),
// // // // // // // // //         ),

// // // // // // // // //         // ── Auth-scoped providers (hydrated/cleared on login/logout) ───────
// // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
// // // // // // // // //           create: (ctx) => ProfileProvider(
// // // // // // // // //             profileRepository: sl.profileRepository,
// // // // // // // // //             authProvider: ctx.read<AuthProvider>(),
// // // // // // // // //           ),
// // // // // // // // //           update: (_, auth, profile) =>
// // // // // // // // //               (profile ??
// // // // // // // // //                     ProfileProvider(
// // // // // // // // //                       profileRepository: sl.profileRepository,
// // // // // // // // //                       authProvider: auth,
// // // // // // // // //                     ))
// // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // //         ),
// // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// // // // // // // // //           create: (_) =>
// // // // // // // // //               FriendsProvider(friendsRepository: sl.friendsRepository),
// // // // // // // // //           update: (_, auth, friends) =>
// // // // // // // // //               (friends ??
// // // // // // // // //                     FriendsProvider(friendsRepository: sl.friendsRepository))
// // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // //         ),
// // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// // // // // // // // //           create: (_) => NotificationProvider(
// // // // // // // // //             notificationRepository: sl.notificationRepository,
// // // // // // // // //           ),
// // // // // // // // //           update: (_, auth, notifs) =>
// // // // // // // // //               (notifs ??
// // // // // // // // //                     NotificationProvider(
// // // // // // // // //                       notificationRepository: sl.notificationRepository,
// // // // // // // // //                     ))
// // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // //         ),
// // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// // // // // // // // //           create: (_) => WalletProvider(walletRepository: sl.walletRepository),
// // // // // // // // //           update: (_, auth, wallet) =>
// // // // // // // // //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // //         ),
// // // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// // // // // // // // //           create: (_) => PackProvider(
// // // // // // // // //             packRepository: sl.packRepository,
// // // // // // // // //             packSyncService: sl.packSyncService,
// // // // // // // // //           ),
// // // // // // // // //           update: (_, auth, packs) =>
// // // // // // // // //               (packs ??
// // // // // // // // //                     PackProvider(
// // // // // // // // //                       packRepository: sl.packRepository,
// // // // // // // // //                       packSyncService: sl.packSyncService,
// // // // // // // // //                     ))
// // // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // // //         ),
// // // // // // // // //       ],
// // // // // // // // //       child: const _RouterHost(),
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // // }

// // // // // // // // // /// Created inside MultiProvider so context.read<AuthProvider>() works.
// // // // // // // // // /// Router is built once in didChangeDependencies and never recreated.
// // // // // // // // // class _RouterHost extends StatefulWidget {
// // // // // // // // //   const _RouterHost();

// // // // // // // // //   @override
// // // // // // // // //   State<_RouterHost> createState() => _RouterHostState();
// // // // // // // // // }

// // // // // // // // // class _RouterHostState extends State<_RouterHost> {
// // // // // // // // //   GoRouter? _router;

// // // // // // // // //   @override
// // // // // // // // //   void didChangeDependencies() {
// // // // // // // // //     super.didChangeDependencies();
// // // // // // // // //     _router ??= AppRouter.createRouter(context.read<AuthProvider>());
// // // // // // // // //   }

// // // // // // // // //   @override
// // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // //     if (_router == null) return const SizedBox.shrink();
// // // // // // // // //     return Consumer<AppProvider>(
// // // // // // // // //       builder: (context, appProvider, _) {
// // // // // // // // //         return MaterialApp.router(
// // // // // // // // //           title: 'Jma3a',
// // // // // // // // //           debugShowCheckedModeBanner: false,
// // // // // // // // //           theme: AppTheme.light(),
// // // // // // // // //           darkTheme: AppTheme.dark(),
// // // // // // // // //           themeMode: appProvider.themeMode,
// // // // // // // // //           routerConfig: _router!,
// // // // // // // // //           locale: appProvider.locale,
// // // // // // // // //           localizationsDelegates: const [
// // // // // // // // //             AppLocalizations.delegate,
// // // // // // // // //             GlobalMaterialLocalizations.delegate,
// // // // // // // // //             GlobalWidgetsLocalizations.delegate,
// // // // // // // // //             GlobalCupertinoLocalizations.delegate,
// // // // // // // // //           ],
// // // // // // // // //           supportedLocales: AppLocalizations.supportedLocales,
// // // // // // // // //           builder: (context, child) =>
// // // // // // // // //               _AppShell(child: child ?? const SizedBox.shrink()),
// // // // // // // // //         );
// // // // // // // // //       },
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // // }

// // // // // // // // // class _AppShell extends StatefulWidget {
// // // // // // // // //   const _AppShell({required this.child});
// // // // // // // // //   final Widget child;

// // // // // // // // //   @override
// // // // // // // // //   State<_AppShell> createState() => _AppShellState();
// // // // // // // // // }

// // // // // // // // // class _AppShellState extends State<_AppShell> {
// // // // // // // // //   @override
// // // // // // // // //   void initState() {
// // // // // // // // //     super.initState();
// // // // // // // // //     // Wire OneSignal foreground handler → NotificationProvider toast queue
// // // // // // // // //     sl.notificationService.registerForegroundHandler((type, title, body, data) {
// // // // // // // // //       context.read<NotificationProvider>().pushToast(
// // // // // // // // //         type: type,
// // // // // // // // //         title: title,
// // // // // // // // //         body: body,
// // // // // // // // //         data: data,
// // // // // // // // //       );
// // // // // // // // //     });
// // // // // // // // //   }

// // // // // // // // //   @override
// // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // //     return Consumer<ConnectivityProvider>(
// // // // // // // // //       builder: (context, connectivity, _) => Stack(
// // // // // // // // //         children: [
// // // // // // // // //           child,
// // // // // // // // //           if (!connectivity.isOnline)
// // // // // // // // //             const Positioned(
// // // // // // // // //               bottom: 0,
// // // // // // // // //               left: 0,
// // // // // // // // //               right: 0,
// // // // // // // // //               child: _OfflineBanner(),
// // // // // // // // //             ),
// // // // // // // // //         ],
// // // // // // // // //       ),
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // // }

// // // // // // // // // class _OfflineBanner extends StatelessWidget {
// // // // // // // // //   const _OfflineBanner();

// // // // // // // // //   @override
// // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // //     final theme = Theme.of(context);
// // // // // // // // //     return Material(
// // // // // // // // //       color: theme.colorScheme.error,
// // // // // // // // //       child: SafeArea(
// // // // // // // // //         top: false,
// // // // // // // // //         child: Padding(
// // // // // // // // //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // // // // // // //           child: Row(
// // // // // // // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // // // // // // //             children: [
// // // // // // // // //               Icon(
// // // // // // // // //                 Icons.wifi_off_rounded,
// // // // // // // // //                 size: 16,
// // // // // // // // //                 color: theme.colorScheme.onError,
// // // // // // // // //               ),
// // // // // // // // //               const SizedBox(width: 8),
// // // // // // // // //               Text(
// // // // // // // // //                 AppLocalizations.of(context).noInternetConnection,
// // // // // // // // //                 style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // // //                   color: theme.colorScheme.onError,
// // // // // // // // //                   fontWeight: FontWeight.w500,
// // // // // // // // //                 ),
// // // // // // // // //               ),
// // // // // // // // //             ],
// // // // // // // // //           ),
// // // // // // // // //         ),
// // // // // // // // //       ),
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // // }
// // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // import 'package:flutter_localizations/flutter_localizations.dart';
// // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // import 'core/l10n/generated/app_localizations.dart';
// // // // // // // // import 'core/providers/app_provider.dart';
// // // // // // // // import 'core/providers/auth_provider.dart';
// // // // // // // // import 'core/providers/connectivity_provider.dart';
// // // // // // // // import 'core/router/app_router.dart';
// // // // // // // // import 'core/theme/app_theme.dart';
// // // // // // // // import 'core/di/service_locator.dart';
// // // // // // // // import 'features/friends/presentation/friends_provider.dart';
// // // // // // // // import 'features/notifications/presentation/notification_provider.dart';
// // // // // // // // import 'features/packs/presentation/pack_provider.dart';
// // // // // // // // import 'features/profile/presentation/profile_provider.dart';
// // // // // // // // import 'features/wallet/presentation/wallet_provider.dart';

// // // // // // // // class Jma3aApp extends StatefulWidget {
// // // // // // // //   const Jma3aApp({super.key});

// // // // // // // //   @override
// // // // // // // //   State<Jma3aApp> createState() => _Jma3aAppState();
// // // // // // // // }

// // // // // // // // class _Jma3aAppState extends State<Jma3aApp> {
// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     return MultiProvider(
// // // // // // // //       providers: [
// // // // // // // //         // ── Infrastructure (always alive) ─────────────────────────────────
// // // // // // // //         ChangeNotifierProvider(
// // // // // // // //           create: (_) =>
// // // // // // // //               ConnectivityProvider(connectivityService: sl.connectivityService),
// // // // // // // //         ),
// // // // // // // //         ChangeNotifierProvider(
// // // // // // // //           create: (_) =>
// // // // // // // //               AppProvider(localStorageService: sl.localStorageService)
// // // // // // // //                 ..initialize(),
// // // // // // // //         ),
// // // // // // // //         ChangeNotifierProvider(
// // // // // // // //           create: (_) => AuthProvider(
// // // // // // // //             authRepository: sl.authRepository,
// // // // // // // //             secureStorage: sl.secureStorageService,
// // // // // // // //           )..initialize(),
// // // // // // // //         ),

// // // // // // // //         // ── Auth-scoped providers (hydrated/cleared on login/logout) ───────
// // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
// // // // // // // //           create: (ctx) => ProfileProvider(
// // // // // // // //             profileRepository: sl.profileRepository,
// // // // // // // //             authProvider: ctx.read<AuthProvider>(),
// // // // // // // //           ),
// // // // // // // //           update: (_, auth, profile) =>
// // // // // // // //               (profile ??
// // // // // // // //                     ProfileProvider(
// // // // // // // //                       profileRepository: sl.profileRepository,
// // // // // // // //                       authProvider: auth,
// // // // // // // //                     ))
// // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // //         ),
// // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// // // // // // // //           create: (_) =>
// // // // // // // //               FriendsProvider(friendsRepository: sl.friendsRepository),
// // // // // // // //           update: (_, auth, friends) =>
// // // // // // // //               (friends ??
// // // // // // // //                     FriendsProvider(friendsRepository: sl.friendsRepository))
// // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // //         ),
// // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// // // // // // // //           create: (_) => NotificationProvider(
// // // // // // // //             notificationRepository: sl.notificationRepository,
// // // // // // // //           ),
// // // // // // // //           update: (_, auth, notifs) =>
// // // // // // // //               (notifs ??
// // // // // // // //                     NotificationProvider(
// // // // // // // //                       notificationRepository: sl.notificationRepository,
// // // // // // // //                     ))
// // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // //         ),
// // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// // // // // // // //           create: (_) => WalletProvider(walletRepository: sl.walletRepository),
// // // // // // // //           update: (_, auth, wallet) =>
// // // // // // // //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // //         ),
// // // // // // // //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// // // // // // // //           create: (_) => PackProvider(
// // // // // // // //             packRepository: sl.packRepository,
// // // // // // // //             packSyncService: sl.packSyncService,
// // // // // // // //           ),
// // // // // // // //           update: (_, auth, packs) =>
// // // // // // // //               (packs ??
// // // // // // // //                     PackProvider(
// // // // // // // //                       packRepository: sl.packRepository,
// // // // // // // //                       packSyncService: sl.packSyncService,
// // // // // // // //                     ))
// // // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // // //         ),
// // // // // // // //       ],
// // // // // // // //       child: const _RouterHost(),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // // }

// // // // // // // // /// Created inside MultiProvider so context.read<AuthProvider>() works.
// // // // // // // // /// Router is built once in didChangeDependencies and never recreated.
// // // // // // // // class _RouterHost extends StatefulWidget {
// // // // // // // //   const _RouterHost();

// // // // // // // //   @override
// // // // // // // //   State<_RouterHost> createState() => _RouterHostState();
// // // // // // // // }

// // // // // // // // class _RouterHostState extends State<_RouterHost> {
// // // // // // // //   GoRouter? _router;

// // // // // // // //   @override
// // // // // // // //   void didChangeDependencies() {
// // // // // // // //     super.didChangeDependencies();
// // // // // // // //     _router ??= AppRouter.createRouter(context.read<AuthProvider>());
// // // // // // // //   }

// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     if (_router == null) return const SizedBox.shrink();
// // // // // // // //     return Consumer<AppProvider>(
// // // // // // // //       builder: (context, appProvider, _) {
// // // // // // // //         return MaterialApp.router(
// // // // // // // //           title: 'Jma3a',
// // // // // // // //           debugShowCheckedModeBanner: false,
// // // // // // // //           theme: AppTheme.light(),
// // // // // // // //           darkTheme: AppTheme.dark(),
// // // // // // // //           themeMode: appProvider.themeMode,
// // // // // // // //           routerConfig: _router!,
// // // // // // // //           locale: appProvider.locale,
// // // // // // // //           localizationsDelegates: const [
// // // // // // // //             AppLocalizations.delegate,
// // // // // // // //             GlobalMaterialLocalizations.delegate,
// // // // // // // //             GlobalWidgetsLocalizations.delegate,
// // // // // // // //             GlobalCupertinoLocalizations.delegate,
// // // // // // // //           ],
// // // // // // // //           supportedLocales: AppLocalizations.supportedLocales,
// // // // // // // //           builder: (context, child) =>
// // // // // // // //               _AppShell(child: child ?? const SizedBox.shrink()),
// // // // // // // //         );
// // // // // // // //       },
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // // }

// // // // // // // // class _AppShell extends StatefulWidget {
// // // // // // // //   const _AppShell({required this.child});
// // // // // // // //   final Widget child;

// // // // // // // //   @override
// // // // // // // //   State<_AppShell> createState() => _AppShellState();
// // // // // // // // }

// // // // // // // // class _AppShellState extends State<_AppShell> {
// // // // // // // //   @override
// // // // // // // //   void initState() {
// // // // // // // //     super.initState();
// // // // // // // //     // Wire OneSignal foreground handler → NotificationProvider toast queue
// // // // // // // //     sl.notificationService.registerForegroundHandler((type, title, body, data) {
// // // // // // // //       context.read<NotificationProvider>().pushToast(
// // // // // // // //         type: type,
// // // // // // // //         title: title,
// // // // // // // //         body: body,
// // // // // // // //         data: data,
// // // // // // // //       );
// // // // // // // //     });
// // // // // // // //   }

// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     return Consumer<ConnectivityProvider>(
// // // // // // // //       builder: (context, connectivity, _) => Stack(
// // // // // // // //         children: [
// // // // // // // //           widget.child,
// // // // // // // //           if (!connectivity.isOnline)
// // // // // // // //             const Positioned(
// // // // // // // //               bottom: 0,
// // // // // // // //               left: 0,
// // // // // // // //               right: 0,
// // // // // // // //               child: _OfflineBanner(),
// // // // // // // //             ),
// // // // // // // //         ],
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // // }

// // // // // // // // class _OfflineBanner extends StatelessWidget {
// // // // // // // //   const _OfflineBanner();

// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     final theme = Theme.of(context);
// // // // // // // //     return Material(
// // // // // // // //       color: theme.colorScheme.error,
// // // // // // // //       child: SafeArea(
// // // // // // // //         top: false,
// // // // // // // //         child: Padding(
// // // // // // // //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // // // // // //           child: Row(
// // // // // // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // // // // // //             children: [
// // // // // // // //               Icon(
// // // // // // // //                 Icons.wifi_off_rounded,
// // // // // // // //                 size: 16,
// // // // // // // //                 color: theme.colorScheme.onError,
// // // // // // // //               ),
// // // // // // // //               const SizedBox(width: 8),
// // // // // // // //               Text(
// // // // // // // //                 AppLocalizations.of(context).noInternetConnection,
// // // // // // // //                 style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // //                   color: theme.colorScheme.onError,
// // // // // // // //                   fontWeight: FontWeight.w500,
// // // // // // // //                 ),
// // // // // // // //               ),
// // // // // // // //             ],
// // // // // // // //           ),
// // // // // // // //         ),
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // // }

// // // // // // // import 'package:flutter/material.dart';
// // // // // // // import 'package:flutter_localizations/flutter_localizations.dart';
// // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // import 'package:provider/provider.dart';

// // // // // // // import 'core/l10n/generated/app_localizations.dart';
// // // // // // // import 'core/providers/app_provider.dart';
// // // // // // // import 'core/providers/auth_provider.dart';
// // // // // // // import 'core/providers/connectivity_provider.dart';
// // // // // // // import 'core/router/app_router.dart';
// // // // // // // import 'core/theme/app_theme.dart';
// // // // // // // import 'core/di/service_locator.dart';
// // // // // // // import 'features/friends/presentation/friends_provider.dart';
// // // // // // // import 'features/notifications/presentation/notification_provider.dart';
// // // // // // // import 'features/packs/presentation/pack_provider.dart';
// // // // // // // import 'features/profile/presentation/profile_provider.dart';
// // // // // // // import 'features/wallet/presentation/wallet_provider.dart';

// // // // // // // class Jma3aApp extends StatefulWidget {
// // // // // // //   const Jma3aApp({super.key});

// // // // // // //   @override
// // // // // // //   State<Jma3aApp> createState() => _Jma3aAppState();
// // // // // // // }

// // // // // // // class _Jma3aAppState extends State<Jma3aApp> {
// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     return MultiProvider(
// // // // // // //       providers: [
// // // // // // //         // ── Infrastructure (always alive) ─────────────────────────────────
// // // // // // //         ChangeNotifierProvider(
// // // // // // //           create: (_) =>
// // // // // // //               ConnectivityProvider(connectivityService: sl.connectivityService),
// // // // // // //         ),
// // // // // // //         ChangeNotifierProvider(
// // // // // // //           create: (_) =>
// // // // // // //               AppProvider(localStorageService: sl.localStorageService)
// // // // // // //                 ..initialize(),
// // // // // // //         ),
// // // // // // //         ChangeNotifierProvider(
// // // // // // //           create: (_) => AuthProvider(
// // // // // // //             authRepository: sl.authRepository,
// // // // // // //             secureStorage: sl.secureStorageService,
// // // // // // //           )..initialize(),
// // // // // // //         ),

// // // // // // //         // ── Auth-scoped providers (hydrated/cleared on login/logout) ───────
// // // // // // //         ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
// // // // // // //           create: (ctx) => ProfileProvider(
// // // // // // //             profileRepository: sl.profileRepository,
// // // // // // //             authProvider: ctx.read<AuthProvider>(),
// // // // // // //           ),
// // // // // // //           update: (_, auth, profile) =>
// // // // // // //               (profile ??
// // // // // // //                     ProfileProvider(
// // // // // // //                       profileRepository: sl.profileRepository,
// // // // // // //                       authProvider: auth,
// // // // // // //                     ))
// // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // //         ),
// // // // // // //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// // // // // // //           create: (_) =>
// // // // // // //               FriendsProvider(friendsRepository: sl.friendsRepository),
// // // // // // //           update: (_, auth, friends) =>
// // // // // // //               (friends ??
// // // // // // //                     FriendsProvider(friendsRepository: sl.friendsRepository))
// // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // //         ),
// // // // // // //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// // // // // // //           create: (_) => NotificationProvider(
// // // // // // //             notificationRepository: sl.notificationRepository,
// // // // // // //           ),
// // // // // // //           update: (_, auth, notifs) =>
// // // // // // //               (notifs ??
// // // // // // //                     NotificationProvider(
// // // // // // //                       notificationRepository: sl.notificationRepository,
// // // // // // //                     ))
// // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // //         ),
// // // // // // //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// // // // // // //           create: (_) => WalletProvider(walletRepository: sl.walletRepository),
// // // // // // //           update: (_, auth, wallet) =>
// // // // // // //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // //         ),
// // // // // // //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// // // // // // //           create: (_) => PackProvider(
// // // // // // //             packRepository: sl.packRepository,
// // // // // // //             packSyncService: sl.packSyncService,
// // // // // // //           ),
// // // // // // //           update: (_, auth, packs) =>
// // // // // // //               (packs ??
// // // // // // //                     PackProvider(
// // // // // // //                       packRepository: sl.packRepository,
// // // // // // //                       packSyncService: sl.packSyncService,
// // // // // // //                     ))
// // // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // // //         ),
// // // // // // //       ],
// // // // // // //       child: const _RouterHost(),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // // /// Created inside MultiProvider so context.read<AuthProvider>() works.
// // // // // // // /// Router is built once in didChangeDependencies and never recreated.
// // // // // // // class _RouterHost extends StatefulWidget {
// // // // // // //   const _RouterHost();

// // // // // // //   @override
// // // // // // //   State<_RouterHost> createState() => _RouterHostState();
// // // // // // // }

// // // // // // // class _RouterHostState extends State<_RouterHost> {
// // // // // // //   GoRouter? _router;

// // // // // // //   @override
// // // // // // //   void didChangeDependencies() {
// // // // // // //     super.didChangeDependencies();
// // // // // // //     _router ??= AppRouter.createRouter(context.read<AuthProvider>());
// // // // // // //   }

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     if (_router == null) return const SizedBox.shrink();
// // // // // // //     return Consumer<AppProvider>(
// // // // // // //       builder: (context, appProvider, _) {
// // // // // // //         return MaterialApp.router(
// // // // // // //           title: 'Jma3a',
// // // // // // //           debugShowCheckedModeBanner: false,
// // // // // // //           theme: AppTheme.light(),
// // // // // // //           darkTheme: AppTheme.dark(),
// // // // // // //           themeMode: appProvider.themeMode,
// // // // // // //           routerConfig: _router!,
// // // // // // //           locale: appProvider.locale,
// // // // // // //           localizationsDelegates: const [
// // // // // // //             AppLocalizations.delegate,
// // // // // // //             GlobalMaterialLocalizations.delegate,
// // // // // // //             GlobalWidgetsLocalizations.delegate,
// // // // // // //             GlobalCupertinoLocalizations.delegate,
// // // // // // //           ],
// // // // // // //           supportedLocales: AppLocalizations.supportedLocales,
// // // // // // //           builder: (context, child) =>
// // // // // // //               _AppShell(child: child ?? const SizedBox.shrink()),
// // // // // // //         );
// // // // // // //       },
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // // class _AppShell extends StatefulWidget {
// // // // // // //   const _AppShell({required this.child});
// // // // // // //   final Widget child;

// // // // // // //   @override
// // // // // // //   State<_AppShell> createState() => _AppShellState();
// // // // // // // }

// // // // // // // class _AppShellState extends State<_AppShell> {
// // // // // // //   @override
// // // // // // //   void initState() {
// // // // // // //     super.initState();
// // // // // // //     // Wire OneSignal foreground handler → NotificationProvider toast queue
// // // // // // //     sl.notificationService.registerForegroundHandler((type, title, body, data) {
// // // // // // //       context.read<NotificationProvider>().pushToast(
// // // // // // //         type: type,
// // // // // // //         title: title,
// // // // // // //         body: body,
// // // // // // //         data: data,
// // // // // // //       );
// // // // // // //     });
// // // // // // //   }

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     return Consumer<ConnectivityProvider>(
// // // // // // //       builder: (context, connectivity, _) => Stack(
// // // // // // //         children: [
// // // // // // //           widget.child,
// // // // // // //           if (!connectivity.isOnline)
// // // // // // //             const Positioned(
// // // // // // //               bottom: 0,
// // // // // // //               left: 0,
// // // // // // //               right: 0,
// // // // // // //               child: _OfflineBanner(),
// // // // // // //             ),
// // // // // // //         ],
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // // class _OfflineBanner extends StatelessWidget {
// // // // // // //   const _OfflineBanner();

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     final theme = Theme.of(context);
// // // // // // //     return Material(
// // // // // // //       color: theme.colorScheme.error,
// // // // // // //       child: SafeArea(
// // // // // // //         top: false,
// // // // // // //         child: Padding(
// // // // // // //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // // // // //           child: Row(
// // // // // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // // // // //             children: [
// // // // // // //               Icon(
// // // // // // //                 Icons.wifi_off_rounded,
// // // // // // //                 size: 16,
// // // // // // //                 color: theme.colorScheme.onError,
// // // // // // //               ),
// // // // // // //               const SizedBox(width: 8),
// // // // // // //               Text(
// // // // // // //                 AppLocalizations.of(context).noInternetConnection,
// // // // // // //                 style: theme.textTheme.bodySmall?.copyWith(
// // // // // // //                   color: theme.colorScheme.onError,
// // // // // // //                   fontWeight: FontWeight.w500,
// // // // // // //                 ),
// // // // // // //               ),
// // // // // // //             ],
// // // // // // //           ),
// // // // // // //         ),
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:flutter_localizations/flutter_localizations.dart';
// // // // // // import 'package:go_router/go_router.dart';
// // // // // // import 'package:provider/provider.dart';

// // // // // // import 'core/l10n/generated/app_localizations.dart';
// // // // // // import 'core/providers/app_provider.dart';
// // // // // // import 'core/providers/auth_provider.dart';
// // // // // // import 'core/providers/connectivity_provider.dart';
// // // // // // import 'core/router/app_router.dart';
// // // // // // import 'core/theme/app_theme.dart';
// // // // // // import 'core/di/service_locator.dart';
// // // // // // import 'features/friends/presentation/friends_provider.dart';
// // // // // // import 'features/notifications/presentation/notification_provider.dart';
// // // // // // import 'features/packs/presentation/pack_provider.dart';
// // // // // // import 'features/profile/presentation/profile_provider.dart';
// // // // // // import 'features/wallet/presentation/wallet_provider.dart';

// // // // // // class Jma3aApp extends StatefulWidget {
// // // // // //   const Jma3aApp({super.key});

// // // // // //   @override
// // // // // //   State<Jma3aApp> createState() => _Jma3aAppState();
// // // // // // }

// // // // // // class _Jma3aAppState extends State<Jma3aApp> {
// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return MultiProvider(
// // // // // //       providers: [
// // // // // //         // ── Infrastructure (always alive) ─────────────────────────────────
// // // // // //         ChangeNotifierProvider(
// // // // // //           create: (_) =>
// // // // // //               ConnectivityProvider(connectivityService: sl.connectivityService),
// // // // // //         ),
// // // // // //         ChangeNotifierProvider(
// // // // // //           create: (_) =>
// // // // // //               AppProvider(localStorageService: sl.localStorageService)
// // // // // //                 ..initialize(),
// // // // // //         ),
// // // // // //         ChangeNotifierProvider(
// // // // // //           create: (_) => AuthProvider(
// // // // // //             authRepository: sl.authRepository,
// // // // // //             secureStorage: sl.secureStorageService,
// // // // // //           )..initialize(),
// // // // // //         ),

// // // // // //         // ── Auth-scoped providers (hydrated/cleared on login/logout) ───────
// // // // // //         ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
// // // // // //           create: (ctx) => ProfileProvider(
// // // // // //             profileRepository: sl.profileRepository,
// // // // // //             authProvider: ctx.read<AuthProvider>(),
// // // // // //           ),
// // // // // //           update: (_, auth, profile) =>
// // // // // //               (profile ??
// // // // // //                     ProfileProvider(
// // // // // //                       profileRepository: sl.profileRepository,
// // // // // //                       authProvider: auth,
// // // // // //                     ))
// // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // //         ),
// // // // // //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// // // // // //           create: (_) =>
// // // // // //               FriendsProvider(friendsRepository: sl.friendsRepository),
// // // // // //           update: (_, auth, friends) =>
// // // // // //               (friends ??
// // // // // //                     FriendsProvider(friendsRepository: sl.friendsRepository))
// // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // //         ),
// // // // // //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// // // // // //           create: (_) => NotificationProvider(
// // // // // //             notificationRepository: sl.notificationRepository,
// // // // // //           ),
// // // // // //           update: (_, auth, notifs) =>
// // // // // //               (notifs ??
// // // // // //                     NotificationProvider(
// // // // // //                       notificationRepository: sl.notificationRepository,
// // // // // //                     ))
// // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // //         ),
// // // // // //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// // // // // //           create: (_) => WalletProvider(walletRepository: sl.walletRepository),
// // // // // //           update: (_, auth, wallet) =>
// // // // // //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // //         ),
// // // // // //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// // // // // //           create: (_) => PackProvider(
// // // // // //             packRepository: sl.packRepository,
// // // // // //             packSyncService: sl.packSyncService,
// // // // // //           ),
// // // // // //           update: (_, auth, packs) =>
// // // // // //               (packs ??
// // // // // //                     PackProvider(
// // // // // //                       packRepository: sl.packRepository,
// // // // // //                       packSyncService: sl.packSyncService,
// // // // // //                     ))
// // // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // // //         ),
// // // // // //       ],
// // // // // //       child: const _RouterHost(),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // /// Created inside MultiProvider so context.read<AuthProvider>() works.
// // // // // // /// Router is built once in didChangeDependencies and never recreated.
// // // // // // class _RouterHost extends StatefulWidget {
// // // // // //   const _RouterHost();

// // // // // //   @override
// // // // // //   State<_RouterHost> createState() => _RouterHostState();
// // // // // // }

// // // // // // class _RouterHostState extends State<_RouterHost> {
// // // // // //   GoRouter? _router;

// // // // // //   @override
// // // // // //   void didChangeDependencies() {
// // // // // //     super.didChangeDependencies();
// // // // // //     _router ??= AppRouter.createRouter(context.read<AuthProvider>());
// // // // // //   }

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     if (_router == null) return const SizedBox.shrink();
// // // // // //     // Read AppProvider without watching — theme/locale changes won't
// // // // // //     // rebuild MaterialApp.router and reset navigation state.
// // // // // //     final appProvider = context.read<AppProvider>();
// // // // // //     return MaterialApp.router(
// // // // // //       title: 'Jma3a',
// // // // // //       debugShowCheckedModeBanner: false,
// // // // // //       theme: AppTheme.light(),
// // // // // //       darkTheme: AppTheme.dark(),
// // // // // //       themeMode: appProvider.themeMode,
// // // // // //       routerConfig: _router!,
// // // // // //       locale: appProvider.locale,
// // // // // //       localizationsDelegates: const [
// // // // // //         AppLocalizations.delegate,
// // // // // //         GlobalMaterialLocalizations.delegate,
// // // // // //         GlobalWidgetsLocalizations.delegate,
// // // // // //         GlobalCupertinoLocalizations.delegate,
// // // // // //       ],
// // // // // //       supportedLocales: AppLocalizations.supportedLocales,
// // // // // //       builder: (context, child) =>
// // // // // //           _AppShell(child: child ?? const SizedBox.shrink()),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // class _AppShell extends StatefulWidget {
// // // // // //   const _AppShell({required this.child});
// // // // // //   final Widget child;

// // // // // //   @override
// // // // // //   State<_AppShell> createState() => _AppShellState();
// // // // // // }

// // // // // // class _AppShellState extends State<_AppShell> {
// // // // // //   @override
// // // // // //   void initState() {
// // // // // //     super.initState();
// // // // // //     // Wire OneSignal foreground handler → NotificationProvider toast queue
// // // // // //     sl.notificationService.registerForegroundHandler((type, title, body, data) {
// // // // // //       context.read<NotificationProvider>().pushToast(
// // // // // //         type: type,
// // // // // //         title: title,
// // // // // //         body: body,
// // // // // //         data: data,
// // // // // //       );
// // // // // //     });
// // // // // //   }

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return Consumer<ConnectivityProvider>(
// // // // // //       builder: (context, connectivity, _) => Stack(
// // // // // //         children: [
// // // // // //           widget.child,
// // // // // //           if (!connectivity.isOnline)
// // // // // //             const Positioned(
// // // // // //               bottom: 0,
// // // // // //               left: 0,
// // // // // //               right: 0,
// // // // // //               child: _OfflineBanner(),
// // // // // //             ),
// // // // // //         ],
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // class _OfflineBanner extends StatelessWidget {
// // // // // //   const _OfflineBanner();

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     final theme = Theme.of(context);
// // // // // //     return Material(
// // // // // //       color: theme.colorScheme.error,
// // // // // //       child: SafeArea(
// // // // // //         top: false,
// // // // // //         child: Padding(
// // // // // //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // // // //           child: Row(
// // // // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // // // //             children: [
// // // // // //               Icon(
// // // // // //                 Icons.wifi_off_rounded,
// // // // // //                 size: 16,
// // // // // //                 color: theme.colorScheme.onError,
// // // // // //               ),
// // // // // //               const SizedBox(width: 8),
// // // // // //               Text(
// // // // // //                 AppLocalizations.of(context).noInternetConnection,
// // // // // //                 style: theme.textTheme.bodySmall?.copyWith(
// // // // // //                   color: theme.colorScheme.onError,
// // // // // //                   fontWeight: FontWeight.w500,
// // // // // //                 ),
// // // // // //               ),
// // // // // //             ],
// // // // // //           ),
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:flutter_localizations/flutter_localizations.dart';
// // // // // import 'package:go_router/go_router.dart';
// // // // // import 'package:provider/provider.dart';

// // // // // import 'core/l10n/generated/app_localizations.dart';
// // // // // import 'core/providers/app_provider.dart';
// // // // // import 'core/providers/auth_provider.dart';
// // // // // import 'core/providers/connectivity_provider.dart';
// // // // // import 'core/router/app_router.dart';
// // // // // import 'core/theme/app_theme.dart';
// // // // // import 'core/di/service_locator.dart';
// // // // // import 'features/friends/presentation/friends_provider.dart';
// // // // // import 'features/notifications/presentation/notification_provider.dart';
// // // // // import 'features/packs/presentation/pack_provider.dart';
// // // // // import 'features/profile/presentation/profile_provider.dart';
// // // // // import 'features/offline/data/offline_game_provider.dart';
// // // // // import 'features/offline/data/offline_repository.dart';
// // // // // import 'features/wallet/presentation/wallet_provider.dart';

// // // // // class Jma3aApp extends StatefulWidget {
// // // // //   const Jma3aApp({super.key});

// // // // //   @override
// // // // //   State<Jma3aApp> createState() => _Jma3aAppState();
// // // // // }

// // // // // class _Jma3aAppState extends State<Jma3aApp> {
// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return MultiProvider(
// // // // //       providers: [
// // // // //         // ── Infrastructure (always alive) ─────────────────────────────────
// // // // //         ChangeNotifierProvider(
// // // // //           create: (_) =>
// // // // //               ConnectivityProvider(connectivityService: sl.connectivityService),
// // // // //         ),
// // // // //         ChangeNotifierProvider(
// // // // //           create: (_) =>
// // // // //               AppProvider(localStorageService: sl.localStorageService)
// // // // //                 ..initialize(),
// // // // //         ),
// // // // //         ChangeNotifierProvider(
// // // // //           create: (_) => AuthProvider(
// // // // //             authRepository: sl.authRepository,
// // // // //             secureStorage: sl.secureStorageService,
// // // // //           )..initialize(),
// // // // //         ),

// // // // //         // ── Auth-scoped providers (hydrated/cleared on login/logout) ───────
// // // // //         ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
// // // // //           create: (ctx) => ProfileProvider(
// // // // //             profileRepository: sl.profileRepository,
// // // // //             authProvider: ctx.read<AuthProvider>(),
// // // // //           ),
// // // // //           update: (_, auth, profile) =>
// // // // //               (profile ??
// // // // //                     ProfileProvider(
// // // // //                       profileRepository: sl.profileRepository,
// // // // //                       authProvider: auth,
// // // // //                     ))
// // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // //         ),
// // // // //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// // // // //           create: (_) =>
// // // // //               FriendsProvider(friendsRepository: sl.friendsRepository),
// // // // //           update: (_, auth, friends) =>
// // // // //               (friends ??
// // // // //                     FriendsProvider(friendsRepository: sl.friendsRepository))
// // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // //         ),
// // // // //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// // // // //           create: (_) => NotificationProvider(
// // // // //             notificationRepository: sl.notificationRepository,
// // // // //           ),
// // // // //           update: (_, auth, notifs) =>
// // // // //               (notifs ??
// // // // //                     NotificationProvider(
// // // // //                       notificationRepository: sl.notificationRepository,
// // // // //                     ))
// // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // //         ),
// // // // //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// // // // //           create: (_) => WalletProvider(walletRepository: sl.walletRepository),
// // // // //           update: (_, auth, wallet) =>
// // // // //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // //         ),
// // // // //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// // // // //           create: (_) => PackProvider(
// // // // //             packRepository: sl.packRepository,
// // // // //             packSyncService: sl.packSyncService,
// // // // //           ),
// // // // //           update: (_, auth, packs) =>
// // // // //               (packs ??
// // // // //                     PackProvider(
// // // // //                       packRepository: sl.packRepository,
// // // // //                       packSyncService: sl.packSyncService,
// // // // //                     ))
// // // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // // //         ),
// // // // //         ChangeNotifierProvider(
// // // // //           create: (_) =>
// // // // //               OfflineGameProvider(repository: OfflineRepository.instance),
// // // // //         ),
// // // // //       ],
// // // // //       child: const _RouterHost(),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // /// Created inside MultiProvider so context.read<AuthProvider>() works.
// // // // // /// Router is built once in didChangeDependencies and never recreated.
// // // // // class _RouterHost extends StatefulWidget {
// // // // //   const _RouterHost();

// // // // //   @override
// // // // //   State<_RouterHost> createState() => _RouterHostState();
// // // // // }

// // // // // class _RouterHostState extends State<_RouterHost> {
// // // // //   GoRouter? _router;

// // // // //   @override
// // // // //   void didChangeDependencies() {
// // // // //     super.didChangeDependencies();
// // // // //     _router ??= AppRouter.createRouter(context.read<AuthProvider>());
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     if (_router == null) return const SizedBox.shrink();
// // // // //     // Read AppProvider without watching — theme/locale changes won't
// // // // //     // rebuild MaterialApp.router and reset navigation state.
// // // // //     final appProvider = context.read<AppProvider>();
// // // // //     return MaterialApp.router(
// // // // //       title: 'Jma3a',
// // // // //       debugShowCheckedModeBanner: false,
// // // // //       theme: AppTheme.light(),
// // // // //       darkTheme: AppTheme.dark(),
// // // // //       themeMode: appProvider.themeMode,
// // // // //       routerConfig: _router!,
// // // // //       locale: appProvider.locale,
// // // // //       localizationsDelegates: const [
// // // // //         AppLocalizations.delegate,
// // // // //         GlobalMaterialLocalizations.delegate,
// // // // //         GlobalWidgetsLocalizations.delegate,
// // // // //         GlobalCupertinoLocalizations.delegate,
// // // // //       ],
// // // // //       supportedLocales: AppLocalizations.supportedLocales,
// // // // //       builder: (context, child) =>
// // // // //           _AppShell(child: child ?? const SizedBox.shrink()),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // class _AppShell extends StatefulWidget {
// // // // //   const _AppShell({required this.child});
// // // // //   final Widget child;

// // // // //   @override
// // // // //   State<_AppShell> createState() => _AppShellState();
// // // // // }

// // // // // class _AppShellState extends State<_AppShell> {
// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();
// // // // //     // Wire OneSignal foreground handler → NotificationProvider toast queue
// // // // //     sl.notificationService.registerForegroundHandler((type, title, body, data) {
// // // // //       context.read<NotificationProvider>().pushToast(
// // // // //         type: type,
// // // // //         title: title,
// // // // //         body: body,
// // // // //         data: data,
// // // // //       );
// // // // //     });
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Consumer<ConnectivityProvider>(
// // // // //       builder: (context, connectivity, _) => Stack(
// // // // //         children: [
// // // // //           widget.child,
// // // // //           if (!connectivity.isOnline)
// // // // //             const Positioned(
// // // // //               bottom: 0,
// // // // //               left: 0,
// // // // //               right: 0,
// // // // //               child: _OfflineBanner(),
// // // // //             ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // class _OfflineBanner extends StatelessWidget {
// // // // //   const _OfflineBanner();

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final theme = Theme.of(context);
// // // // //     return Material(
// // // // //       color: theme.colorScheme.error,
// // // // //       child: SafeArea(
// // // // //         top: false,
// // // // //         child: Padding(
// // // // //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // // //           child: Row(
// // // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // // //             children: [
// // // // //               Icon(
// // // // //                 Icons.wifi_off_rounded,
// // // // //                 size: 16,
// // // // //                 color: theme.colorScheme.onError,
// // // // //               ),
// // // // //               const SizedBox(width: 8),
// // // // //               Text(
// // // // //                 AppLocalizations.of(context).noInternetConnection,
// // // // //                 style: theme.textTheme.bodySmall?.copyWith(
// // // // //                   color: theme.colorScheme.onError,
// // // // //                   fontWeight: FontWeight.w500,
// // // // //                 ),
// // // // //               ),
// // // // //             ],
// // // // //           ),
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // import 'package:flutter/material.dart';
// // // // import 'package:flutter_localizations/flutter_localizations.dart';
// // // // import 'package:go_router/go_router.dart';
// // // // import 'package:provider/provider.dart';

// // // // import 'core/l10n/generated/app_localizations.dart';
// // // // import 'core/providers/app_provider.dart';
// // // // import 'core/providers/auth_provider.dart';
// // // // import 'core/providers/connectivity_provider.dart';
// // // // import 'core/router/app_router.dart';
// // // // import 'core/theme/app_theme.dart';
// // // // import 'core/di/service_locator.dart';
// // // // import 'features/friends/presentation/friends_provider.dart';
// // // // import 'features/notifications/presentation/notification_provider.dart';
// // // // import 'features/packs/presentation/pack_provider.dart';
// // // // import 'features/profile/presentation/profile_provider.dart';
// // // // import 'features/offline/data/offline_game_provider.dart';
// // // // import 'features/offline/data/offline_repository.dart';
// // // // import 'features/wallet/presentation/wallet_provider.dart';

// // // // class Jma3aApp extends StatefulWidget {
// // // //   const Jma3aApp({super.key});

// // // //   @override
// // // //   State<Jma3aApp> createState() => _Jma3aAppState();
// // // // }

// // // // class _Jma3aAppState extends State<Jma3aApp> {
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return MultiProvider(
// // // //       providers: [
// // // //         // ── Infrastructure (always alive) ─────────────────────────────────
// // // //         ChangeNotifierProvider(
// // // //           create: (_) =>
// // // //               ConnectivityProvider(connectivityService: sl.connectivityService),
// // // //         ),
// // // //         ChangeNotifierProvider(
// // // //           create: (_) =>
// // // //               AppProvider(localStorageService: sl.localStorageService)
// // // //                 ..initialize(),
// // // //         ),
// // // //         ChangeNotifierProvider(
// // // //           create: (_) => AuthProvider(
// // // //             authRepository: sl.authRepository,
// // // //             secureStorage: sl.secureStorageService,
// // // //           )..initialize(),
// // // //         ),

// // // //         // ── Auth-scoped providers (hydrated/cleared on login/logout) ───────
// // // //         ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
// // // //           create: (ctx) => ProfileProvider(
// // // //             profileRepository: sl.profileRepository,
// // // //             authProvider: ctx.read<AuthProvider>(),
// // // //           ),
// // // //           update: (_, auth, profile) =>
// // // //               (profile ??
// // // //                     ProfileProvider(
// // // //                       profileRepository: sl.profileRepository,
// // // //                       authProvider: auth,
// // // //                     ))
// // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // //         ),
// // // //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// // // //           create: (_) =>
// // // //               FriendsProvider(friendsRepository: sl.friendsRepository),
// // // //           update: (_, auth, friends) =>
// // // //               (friends ??
// // // //                     FriendsProvider(friendsRepository: sl.friendsRepository))
// // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // //         ),
// // // //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// // // //           create: (_) => NotificationProvider(
// // // //             notificationRepository: sl.notificationRepository,
// // // //           ),
// // // //           update: (_, auth, notifs) =>
// // // //               (notifs ??
// // // //                     NotificationProvider(
// // // //                       notificationRepository: sl.notificationRepository,
// // // //                     ))
// // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // //         ),
// // // //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// // // //           create: (_) => WalletProvider(walletRepository: sl.walletRepository),
// // // //           update: (_, auth, wallet) =>
// // // //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // //         ),
// // // //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// // // //           create: (_) => PackProvider(
// // // //             packRepository: sl.packRepository,
// // // //             packSyncService: sl.packSyncService,
// // // //           ),
// // // //           update: (_, auth, packs) =>
// // // //               (packs ??
// // // //                     PackProvider(
// // // //                       packRepository: sl.packRepository,
// // // //                       packSyncService: sl.packSyncService,
// // // //                     ))
// // // //                 ..onAuthChanged(auth.currentUser?.id),
// // // //         ),
// // // //         ChangeNotifierProvider(
// // // //           create: (_) =>
// // // //               OfflineGameProvider(repository: OfflineRepository.instance),
// // // //         ),
// // // //       ],
// // // //       child: const _RouterHost(),
// // // //     );
// // // //   }
// // // // }

// // // // /// Created inside MultiProvider so context.read<AuthProvider>() works.
// // // // /// Router is built once in didChangeDependencies and never recreated.
// // // // class _RouterHost extends StatefulWidget {
// // // //   const _RouterHost();

// // // //   @override
// // // //   State<_RouterHost> createState() => _RouterHostState();
// // // // }

// // // // class _RouterHostState extends State<_RouterHost> {
// // // //   GoRouter? _router;

// // // //   @override
// // // //   void didChangeDependencies() {
// // // //     super.didChangeDependencies();
// // // //     _router ??= AppRouter.createRouter(context.read<AuthProvider>());
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     if (_router == null) return const SizedBox.shrink();
// // // //     // Read AppProvider without watching — theme/locale changes won't
// // // //     // rebuild MaterialApp.router and reset navigation state.
// // // //     final appProvider = context.read<AppProvider>();
// // // //     return MaterialApp.router(
// // // //       title: 'Jma3a',
// // // //       debugShowCheckedModeBanner: false,
// // // //       theme: AppTheme.light(),
// // // //       darkTheme: AppTheme.dark(),
// // // //       themeMode: appProvider.themeMode,
// // // //       routerConfig: _router!,
// // // //       locale: appProvider.locale,
// // // //       localizationsDelegates: const [
// // // //         AppLocalizations.delegate,
// // // //         GlobalMaterialLocalizations.delegate,
// // // //         GlobalWidgetsLocalizations.delegate,
// // // //         GlobalCupertinoLocalizations.delegate,
// // // //       ],
// // // //       supportedLocales: AppLocalizations.supportedLocales,
// // // //       builder: (context, child) =>
// // // //           _AppShell(child: child ?? const SizedBox.shrink()),
// // // //     );
// // // //   }
// // // // }

// // // // class _AppShell extends StatefulWidget {
// // // //   const _AppShell({required this.child});
// // // //   final Widget child;

// // // //   @override
// // // //   State<_AppShell> createState() => _AppShellState();
// // // // }

// // // // class _AppShellState extends State<_AppShell> {
// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     // Wire OneSignal foreground handler → NotificationProvider toast queue
// // // //     sl.notificationService.registerForegroundHandler((type, title, body, data) {
// // // //       context.read<NotificationProvider>().pushToast(
// // // //         type: type,
// // // //         title: title,
// // // //         body: body,
// // // //         data: data,
// // // //       );
// // // //     });
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Consumer<ConnectivityProvider>(
// // // //       builder: (context, connectivity, _) => Stack(
// // // //         children: [
// // // //           widget.child,
// // // //           if (!connectivity.isOnline)
// // // //             const Positioned(
// // // //               top: 0,
// // // //               left: 0,
// // // //               right: 0,
// // // //               child: _OfflineBanner(),
// // // //             ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class _OfflineBanner extends StatelessWidget {
// // // //   const _OfflineBanner();

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return IgnorePointer(
// // // //       child: Material(
// // // //         color: Colors.transparent,
// // // //         child: SafeArea(
// // // //           bottom: false,
// // // //           child: Container(
// // // //             color: const Color(0xFFB91C1C).withOpacity(0.92),
// // // //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
// // // //             child: Row(
// // // //               mainAxisAlignment: MainAxisAlignment.center,
// // // //               children: [
// // // //                 const Icon(
// // // //                   Icons.wifi_off_rounded,
// // // //                   size: 12,
// // // //                   color: Colors.white,
// // // //                 ),
// // // //                 const SizedBox(width: 6),
// // // //                 Text(
// // // //                   AppLocalizations.of(context).noInternetConnection,
// // // //                   style: const TextStyle(
// // // //                     color: Colors.white,
// // // //                     fontSize: 11,
// // // //                     fontWeight: FontWeight.w600,
// // // //                   ),
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // import 'package:flutter/material.dart';
// // // import 'package:flutter_localizations/flutter_localizations.dart';
// // // import 'package:go_router/go_router.dart';
// // // import 'package:provider/provider.dart';

// // // import 'core/l10n/generated/app_localizations.dart';
// // // import 'core/providers/app_provider.dart';
// // // import 'core/providers/auth_provider.dart';
// // // import 'core/providers/connectivity_provider.dart';
// // // import 'core/router/app_router.dart';
// // // import 'core/theme/app_theme.dart';
// // // import 'core/di/service_locator.dart';
// // // import 'features/friends/presentation/friends_provider.dart';
// // // import 'features/notifications/presentation/notification_provider.dart';
// // // import 'features/packs/presentation/pack_provider.dart';
// // // import 'features/profile/presentation/profile_provider.dart';
// // // import 'features/offline/data/offline_game_provider.dart';
// // // import 'features/offline/data/offline_repository.dart';
// // // import 'features/wallet/presentation/wallet_provider.dart';

// // // class Jma3aApp extends StatefulWidget {
// // //   const Jma3aApp({super.key});

// // //   @override
// // //   State<Jma3aApp> createState() => _Jma3aAppState();
// // // }

// // // class _Jma3aAppState extends State<Jma3aApp> {
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return MultiProvider(
// // //       providers: [
// // //         // ── Infrastructure (always alive) ─────────────────────────────────
// // //         ChangeNotifierProvider(
// // //           create: (_) =>
// // //               ConnectivityProvider(connectivityService: sl.connectivityService),
// // //         ),
// // //         ChangeNotifierProvider(
// // //           create: (_) =>
// // //               AppProvider(localStorageService: sl.localStorageService)
// // //                 ..initialize(),
// // //         ),
// // //         ChangeNotifierProvider(
// // //           create: (_) => AuthProvider(
// // //             authRepository: sl.authRepository,
// // //             secureStorage: sl.secureStorageService,
// // //           )..initialize(),
// // //         ),

// // //         // ── Auth-scoped providers (hydrated/cleared on login/logout) ───────
// // //         ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
// // //           create: (ctx) => ProfileProvider(
// // //             profileRepository: sl.profileRepository,
// // //             authProvider: ctx.read<AuthProvider>(),
// // //           ),
// // //           update: (_, auth, profile) =>
// // //               (profile ??
// // //                     ProfileProvider(
// // //                       profileRepository: sl.profileRepository,
// // //                       authProvider: auth,
// // //                     ))
// // //                 ..onAuthChanged(auth.currentUser?.id),
// // //         ),
// // //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// // //           create: (_) =>
// // //               FriendsProvider(friendsRepository: sl.friendsRepository),
// // //           update: (_, auth, friends) =>
// // //               (friends ??
// // //                     FriendsProvider(friendsRepository: sl.friendsRepository))
// // //                 ..onAuthChanged(auth.currentUser?.id),
// // //         ),
// // //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// // //           create: (_) => NotificationProvider(
// // //             notificationRepository: sl.notificationRepository,
// // //           ),
// // //           update: (_, auth, notifs) =>
// // //               (notifs ??
// // //                     NotificationProvider(
// // //                       notificationRepository: sl.notificationRepository,
// // //                     ))
// // //                 ..onAuthChanged(auth.currentUser?.id),
// // //         ),
// // //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// // //           create: (_) => WalletProvider(walletRepository: sl.walletRepository),
// // //           update: (_, auth, wallet) =>
// // //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// // //                 ..onAuthChanged(auth.currentUser?.id),
// // //         ),
// // //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// // //           create: (_) => PackProvider(
// // //             packRepository: sl.packRepository,
// // //             packSyncService: sl.packSyncService,
// // //           ),
// // //           update: (_, auth, packs) =>
// // //               (packs ??
// // //                     PackProvider(
// // //                       packRepository: sl.packRepository,
// // //                       packSyncService: sl.packSyncService,
// // //                     ))
// // //                 ..onAuthChanged(auth.currentUser?.id),
// // //         ),
// // //         ChangeNotifierProvider(
// // //           create: (_) =>
// // //               OfflineGameProvider(repository: OfflineRepository.instance),
// // //         ),
// // //       ],
// // //       child: const _RouterHost(),
// // //     );
// // //   }
// // // }

// // // /// Created inside MultiProvider so context.read<AuthProvider>() works.
// // // /// Router is built once in didChangeDependencies and never recreated.
// // // class _RouterHost extends StatefulWidget {
// // //   const _RouterHost();

// // //   @override
// // //   State<_RouterHost> createState() => _RouterHostState();
// // // }

// // // class _RouterHostState extends State<_RouterHost> {
// // //   GoRouter? _router;

// // //   @override
// // //   void didChangeDependencies() {
// // //     super.didChangeDependencies();
// // //     _router ??= AppRouter.createRouter(context.read<AuthProvider>());
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     if (_router == null) return const SizedBox.shrink();
// // //     // Read AppProvider without watching — theme/locale changes won't
// // //     // rebuild MaterialApp.router and reset navigation state.
// // //     final appProvider = context.read<AppProvider>();
// // //     return MaterialApp.router(
// // //       title: 'Jma3a',
// // //       debugShowCheckedModeBanner: false,
// // //       theme: AppTheme.light(),
// // //       darkTheme: AppTheme.dark(),
// // //       themeMode: appProvider.themeMode,
// // //       routerConfig: _router!,
// // //       locale: appProvider.locale,
// // //       localizationsDelegates: const [
// // //         AppLocalizations.delegate,
// // //         GlobalMaterialLocalizations.delegate,
// // //         GlobalWidgetsLocalizations.delegate,
// // //         GlobalCupertinoLocalizations.delegate,
// // //       ],
// // //       supportedLocales: AppLocalizations.supportedLocales,
// // //       builder: (context, child) =>
// // //           _AppShell(child: child ?? const SizedBox.shrink()),
// // //     );
// // //   }
// // // }

// // // class _AppShell extends StatefulWidget {
// // //   const _AppShell({required this.child});
// // //   final Widget child;

// // //   @override
// // //   State<_AppShell> createState() => _AppShellState();
// // // }

// // // class _AppShellState extends State<_AppShell> {
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     // Wire OneSignal foreground handler → NotificationProvider toast queue
// // //     sl.notificationService.registerForegroundHandler((type, title, body, data) {
// // //       context.read<NotificationProvider>().pushToast(
// // //         type: type,
// // //         title: title,
// // //         body: body,
// // //         data: data,
// // //       );
// // //     });
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Consumer<ConnectivityProvider>(
// // //       builder: (context, connectivity, _) => Stack(
// // //         children: [
// // //           widget.child,
// // //           if (!connectivity.isOnline)
// // //             const Positioned(
// // //               top: 0,
// // //               left: 0,
// // //               right: 0,
// // //               child: _OfflineBanner(),
// // //             ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _OfflineBanner extends StatelessWidget {
// // //   const _OfflineBanner();

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return IgnorePointer(
// // //       child: Material(
// // //         color: Colors.transparent,
// // //         child: SafeArea(
// // //           bottom: false,
// // //           child: Container(
// // //             color: const Color(0xFFB91C1C).withOpacity(0.92),
// // //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
// // //             child: Row(
// // //               mainAxisAlignment: MainAxisAlignment.center,
// // //               children: [
// // //                 const Icon(
// // //                   Icons.wifi_off_rounded,
// // //                   size: 12,
// // //                   color: Colors.white,
// // //                 ),
// // //                 const SizedBox(width: 6),
// // //                 Text(
// // //                   AppLocalizations.of(context).noInternetConnection,
// // //                   style: const TextStyle(
// // //                     color: Colors.white,
// // //                     fontSize: 11,
// // //                     fontWeight: FontWeight.w600,
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // import 'package:flutter/material.dart';
// // import 'package:flutter_localizations/flutter_localizations.dart';
// // import 'package:go_router/go_router.dart';
// // import 'package:provider/provider.dart';

// // import 'core/l10n/generated/app_localizations.dart';
// // import 'core/providers/app_provider.dart';
// // import 'core/providers/auth_provider.dart';
// // import 'core/providers/connectivity_provider.dart';
// // import 'core/router/app_router.dart';
// // import 'core/theme/app_theme.dart';
// // import 'core/di/service_locator.dart';
// // import 'features/friends/presentation/friends_provider.dart';
// // import 'features/notifications/presentation/notification_provider.dart';
// // import 'features/packs/presentation/pack_provider.dart';
// // import 'features/profile/presentation/profile_provider.dart';
// // import 'features/offline/data/offline_game_provider.dart';
// // import 'features/offline/data/offline_repository.dart';
// // import 'features/wallet/presentation/wallet_provider.dart';

// // class Jma3aApp extends StatefulWidget {
// //   const Jma3aApp({super.key});

// //   @override
// //   State<Jma3aApp> createState() => _Jma3aAppState();
// // }

// // class _Jma3aAppState extends State<Jma3aApp> {
// //   @override
// //   Widget build(BuildContext context) {
// //     return MultiProvider(
// //       providers: [
// //         // ── Infrastructure (always alive) ─────────────────────────────────
// //         ChangeNotifierProvider(
// //           create: (_) =>
// //               ConnectivityProvider(connectivityService: sl.connectivityService),
// //         ),
// //         ChangeNotifierProvider(
// //           create: (_) =>
// //               AppProvider(localStorageService: sl.localStorageService)
// //                 ..initialize(),
// //         ),
// //         ChangeNotifierProvider(
// //           create: (_) => AuthProvider(
// //             authRepository: sl.authRepository,
// //             secureStorage: sl.secureStorageService,
// //           )..initialize(),
// //         ),

// //         // ── Auth-scoped providers (hydrated/cleared on login/logout) ───────
// //         ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
// //           create: (ctx) => ProfileProvider(
// //             profileRepository: sl.profileRepository,
// //             authProvider: ctx.read<AuthProvider>(),
// //           ),
// //           update: (_, auth, profile) =>
// //               (profile ??
// //                     ProfileProvider(
// //                       profileRepository: sl.profileRepository,
// //                       authProvider: auth,
// //                     ))
// //                 ..onAuthChanged(auth.currentUser?.id),
// //         ),
// //         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
// //           create: (_) =>
// //               FriendsProvider(friendsRepository: sl.friendsRepository),
// //           update: (_, auth, friends) =>
// //               (friends ??
// //                     FriendsProvider(friendsRepository: sl.friendsRepository))
// //                 ..onAuthChanged(auth.currentUser?.id),
// //         ),
// //         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
// //           create: (_) => NotificationProvider(
// //             notificationRepository: sl.notificationRepository,
// //           ),
// //           update: (_, auth, notifs) =>
// //               (notifs ??
// //                     NotificationProvider(
// //                       notificationRepository: sl.notificationRepository,
// //                     ))
// //                 ..onAuthChanged(auth.currentUser?.id),
// //         ),
// //         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
// //           create: (_) => WalletProvider(walletRepository: sl.walletRepository),
// //           update: (_, auth, wallet) =>
// //               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
// //                 ..onAuthChanged(auth.currentUser?.id),
// //         ),
// //         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
// //           create: (_) => PackProvider(
// //             packRepository: sl.packRepository,
// //             packSyncService: sl.packSyncService,
// //           ),
// //           update: (_, auth, packs) =>
// //               (packs ??
// //                     PackProvider(
// //                       packRepository: sl.packRepository,
// //                       packSyncService: sl.packSyncService,
// //                     ))
// //                 ..onAuthChanged(auth.currentUser?.id),
// //         ),
// //         ChangeNotifierProvider(
// //           create: (_) =>
// //               OfflineGameProvider(repository: OfflineRepository.instance),
// //         ),
// //       ],
// //       child: const _RouterHost(),
// //     );
// //   }
// // }

// // /// Created inside MultiProvider so context.read<AuthProvider>() works.
// // /// Router is built once in didChangeDependencies and never recreated.
// // class _RouterHost extends StatefulWidget {
// //   const _RouterHost();

// //   @override
// //   State<_RouterHost> createState() => _RouterHostState();
// // }

// // class _RouterHostState extends State<_RouterHost> {
// //   GoRouter? _router;

// //   @override
// //   void didChangeDependencies() {
// //     super.didChangeDependencies();
// //     _router ??= AppRouter.createRouter(context.read<AuthProvider>());
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     if (_router == null) return const SizedBox.shrink();
// //     // Watch AppProvider so locale/theme changes rebuild immediately
// //     final appProvider = context.watch<AppProvider>();
// //     return MaterialApp.router(
// //       title: 'Jma3a',
// //       debugShowCheckedModeBanner: false,
// //       theme: AppTheme.light(),
// //       darkTheme: AppTheme.dark(),
// //       themeMode: appProvider.themeMode,
// //       routerConfig: _router!,
// //       locale: appProvider.locale,
// //       localizationsDelegates: const [
// //         AppLocalizations.delegate,
// //         GlobalMaterialLocalizations.delegate,
// //         GlobalWidgetsLocalizations.delegate,
// //         GlobalCupertinoLocalizations.delegate,
// //       ],
// //       supportedLocales: AppLocalizations.supportedLocales,
// //       builder: (context, child) =>
// //           _AppShell(child: child ?? const SizedBox.shrink()),
// //     );
// //   }
// // }

// // class _AppShell extends StatefulWidget {
// //   const _AppShell({required this.child});
// //   final Widget child;

// //   @override
// //   State<_AppShell> createState() => _AppShellState();
// // }

// // class _AppShellState extends State<_AppShell> {
// //   @override
// //   void initState() {
// //     super.initState();
// //     // Wire OneSignal foreground handler → NotificationProvider toast queue
// //     sl.notificationService.registerForegroundHandler((type, title, body, data) {
// //       context.read<NotificationProvider>().pushToast(
// //         type: type,
// //         title: title,
// //         body: body,
// //         data: data,
// //       );
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Consumer<ConnectivityProvider>(
// //       builder: (context, connectivity, _) => Stack(
// //         children: [
// //           widget.child,
// //           if (!connectivity.isOnline)
// //             const Positioned(
// //               top: 0,
// //               left: 0,
// //               right: 0,
// //               child: _OfflineBanner(),
// //             ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class _OfflineBanner extends StatelessWidget {
// //   const _OfflineBanner();

// //   @override
// //   Widget build(BuildContext context) {
// //     return IgnorePointer(
// //       child: Material(
// //         color: Colors.transparent,
// //         child: SafeArea(
// //           bottom: false,
// //           child: Container(
// //             color: const Color(0xFFB91C1C).withOpacity(0.92),
// //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
// //             child: Row(
// //               mainAxisAlignment: MainAxisAlignment.center,
// //               children: [
// //                 const Icon(
// //                   Icons.wifi_off_rounded,
// //                   size: 12,
// //                   color: Colors.white,
// //                 ),
// //                 const SizedBox(width: 6),
// //                 Text(
// //                   AppLocalizations.of(context).noInternetConnection,
// //                   style: const TextStyle(
// //                     color: Colors.white,
// //                     fontSize: 11,
// //                     fontWeight: FontWeight.w600,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:jma3a/deep_links.dart';
import 'package:provider/provider.dart';

import 'core/l10n/generated/app_localizations.dart';
import 'core/providers/app_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/connectivity_provider.dart';
// import 'core/services/deep_link_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/di/service_locator.dart';
import 'core/services/app_theme_service.dart';
import 'features/avatar/presentation/avatar_creator_screen.dart';
import 'features/friends/presentation/friends_provider.dart';
import 'features/notifications/presentation/notification_provider.dart';
import 'features/packs/presentation/pack_provider.dart';
import 'features/profile/presentation/profile_provider.dart';
import 'features/offline/data/offline_game_provider.dart';
import 'features/offline/data/offline_repository.dart';
import 'features/wallet/presentation/wallet_provider.dart';

// class Jma3aApp extends StatefulWidget {
//   const Jma3aApp({super.key});

//   @override
//   State<Jma3aApp> createState() => _Jma3aAppState();
// }

// class _Jma3aAppState extends State<Jma3aApp> {
//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         // ── Infrastructure (always alive) ─────────────────────────────────
//         ChangeNotifierProvider(
//           create: (_) =>
//               ConnectivityProvider(connectivityService: sl.connectivityService),
//         ),
//         ChangeNotifierProvider(
//           create: (_) =>
//               AppProvider(localStorageService: sl.localStorageService)
//                 ..initialize(),
//         ),
//         ChangeNotifierProvider(
//           create: (_) => AuthProvider(
//             authRepository: sl.authRepository,
//             secureStorage: sl.secureStorageService,
//           )..initialize(),
//         ),

//         // ── Auth-scoped providers (hydrated/cleared on login/logout) ───────
//         ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
//           create: (ctx) => ProfileProvider(
//             profileRepository: sl.profileRepository,
//             authProvider: ctx.read<AuthProvider>(),
//           ),
//           update: (_, auth, profile) =>
//               (profile ??
//                     ProfileProvider(
//                       profileRepository: sl.profileRepository,
//                       authProvider: auth,
//                     ))
//                 ..onAuthChanged(auth.currentUser?.id),
//         ),
//         ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
//           create: (_) =>
//               FriendsProvider(friendsRepository: sl.friendsRepository),
//           update: (_, auth, friends) =>
//               (friends ??
//                     FriendsProvider(friendsRepository: sl.friendsRepository))
//                 ..onAuthChanged(auth.currentUser?.id),
//         ),
//         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
//           create: (_) => NotificationProvider(
//             notificationRepository: sl.notificationRepository,
//           ),
//           update: (_, auth, notifs) =>
//               (notifs ??
//                     NotificationProvider(
//                       notificationRepository: sl.notificationRepository,
//                     ))
//                 ..onAuthChanged(auth.currentUser?.id),
//         ),
//         ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
//           create: (_) => WalletProvider(walletRepository: sl.walletRepository),
//           update: (_, auth, wallet) =>
//               (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
//                 ..onAuthChanged(auth.currentUser?.id),
//         ),
//         ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
//           create: (_) => PackProvider(
//             packRepository: sl.packRepository,
//             packSyncService: sl.packSyncService,
//           ),
//           update: (_, auth, packs) =>
//               (packs ??
//                     PackProvider(
//                       packRepository: sl.packRepository,
//                       packSyncService: sl.packSyncService,
//                     ))
//                 ..onAuthChanged(auth.currentUser?.id),
//         ),
//         ChangeNotifierProvider(
//           create: (_) =>
//               OfflineGameProvider(repository: OfflineRepository.instance),
//         ),
//         ChangeNotifierProvider(create: (_) => AppThemeService.instance..load()),
//         ChangeNotifierProvider(create: (_) => AvatarService.instance..load()),
//       ],
//       child: const _RouterHost(),
//     );
//   }
// }

// /// Created inside MultiProvider so context.read<AuthProvider>() works.
// /// Router is built once in didChangeDependencies and never recreated.
// class _RouterHost extends StatefulWidget {
//   const _RouterHost();

//   @override
//   State<_RouterHost> createState() => _RouterHostState();
// }

// class _RouterHostState extends State<_RouterHost> {
//   GoRouter? _router;

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     _router ??= AppRouter.createRouter(context.read<AuthProvider>());
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_router == null) return const SizedBox.shrink();
//     // Watch AppProvider so locale/theme changes rebuild immediately
//     final appProvider = context.watch<AppProvider>();
//     return MaterialApp.router(
//       title: 'Jma3a',
//       debugShowCheckedModeBanner: false,
//       theme: AppTheme.light(),
//       darkTheme: AppTheme.dark(),
//       themeMode: appProvider.themeMode,
//       routerConfig: _router!,
//       locale: appProvider.locale,
//       localizationsDelegates: const [
//         AppLocalizations.delegate,
//         GlobalMaterialLocalizations.delegate,
//         GlobalWidgetsLocalizations.delegate,
//         GlobalCupertinoLocalizations.delegate,
//       ],
//       supportedLocales: AppLocalizations.supportedLocales,
//       builder: (context, child) =>
//           _AppShell(child: child ?? const SizedBox.shrink()),
//     );
//   }
// }

// class _AppShell extends StatefulWidget {
//   const _AppShell({required this.child});
//   final Widget child;

//   @override
//   State<_AppShell> createState() => _AppShellState();
// }

// class _AppShellState extends State<_AppShell> {
//   @override
//   void initState() {
//     super.initState();
//     // Init deep link service for invite links
//     DeepLinkService.instance.init();
//     // Wire OneSignal foreground handler → NotificationProvider toast queue
//     sl.notificationService.registerForegroundHandler((type, title, body, data) {
//       context.read<NotificationProvider>().pushToast(
//         type: type,
//         title: title,
//         body: body,
//         data: data,
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ConnectivityProvider>(
//       builder: (context, connectivity, _) => Stack(
//         children: [
//           widget.child,
//           if (!connectivity.isOnline)
//             const Positioned(
//               top: 0,
//               left: 0,
//               right: 0,
//               child: _OfflineBanner(),
//             ),
//         ],
//       ),
//     );
//   }
// }

// class _OfflineBanner extends StatelessWidget {
//   const _OfflineBanner();

//   @override
//   Widget build(BuildContext context) {
//     return IgnorePointer(
//       child: Material(
//         color: Colors.transparent,
//         child: SafeArea(
//           bottom: false,
//           child: Container(
//             color: const Color(0xFFB91C1C).withOpacity(0.92),
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(
//                   Icons.wifi_off_rounded,
//                   size: 12,
//                   color: Colors.white,
//                 ),
//                 const SizedBox(width: 6),
//                 Text(
//                   AppLocalizations.of(context).noInternetConnection,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 11,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// import 'core/router/app_router.dart';
// import 'core/di/service_locator.dart';
// import 'core/services/app_theme_service.dart';
// import 'features/avatar/presentation/avatar_creator_screen.dart';
// import 'features/friends/presentation/friends_provider.dart';
// import 'features/notifications/presentation/notification_provider.dart';
// import 'features/packs/presentation/pack_provider.dart';
// import 'features/profile/presentation/profile_provider.dart';
// import 'features/offline/data/offline_game_provider.dart';
// import 'features/offline/data/offline_repository.dart';
// import 'features/wallet/presentation/wallet_provider.dart';

class Jma3aApp extends StatefulWidget {
  const Jma3aApp({super.key});

  @override
  State<Jma3aApp> createState() => _Jma3aAppState();
}

class _Jma3aAppState extends State<Jma3aApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              ConnectivityProvider(connectivityService: sl.connectivityService),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              AppProvider(localStorageService: sl.localStorageService)
                ..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authRepository: sl.authRepository,
            secureStorage: sl.secureStorageService,
          )..initialize(),
        ),

        ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
          create: (ctx) => ProfileProvider(
            profileRepository: sl.profileRepository,
            authProvider: ctx.read<AuthProvider>(),
          ),
          update: (_, auth, profile) =>
              (profile ??
                    ProfileProvider(
                      profileRepository: sl.profileRepository,
                      authProvider: auth,
                    ))
                ..onAuthChanged(auth.currentUser?.id),
        ),
        ChangeNotifierProxyProvider<AuthProvider, FriendsProvider>(
          create: (_) =>
              FriendsProvider(friendsRepository: sl.friendsRepository),
          update: (_, auth, friends) =>
              (friends ??
                    FriendsProvider(friendsRepository: sl.friendsRepository))
                ..onAuthChanged(auth.currentUser?.id),
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (_) => NotificationProvider(
            notificationRepository: sl.notificationRepository,
          ),
          update: (_, auth, notifs) =>
              (notifs ??
                    NotificationProvider(
                      notificationRepository: sl.notificationRepository,
                    ))
                ..onAuthChanged(auth.currentUser?.id),
        ),
        ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
          create: (_) => WalletProvider(walletRepository: sl.walletRepository),
          update: (_, auth, wallet) =>
              (wallet ?? WalletProvider(walletRepository: sl.walletRepository))
                ..onAuthChanged(auth.currentUser?.id),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PackProvider>(
          create: (_) => PackProvider(
            packRepository: sl.packRepository,
            packSyncService: sl.packSyncService,
          ),
          update: (_, auth, packs) =>
              (packs ??
                    PackProvider(
                      packRepository: sl.packRepository,
                      packSyncService: sl.packSyncService,
                    ))
                ..onAuthChanged(auth.currentUser?.id),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              OfflineGameProvider(repository: OfflineRepository.instance),
        ),
        ChangeNotifierProvider(create: (_) => AppThemeService.instance..load()),
        ChangeNotifierProvider(create: (_) => AvatarService.instance..load()),
      ],
      child: const _RouterHost(),
    );
  }
}

class _RouterHost extends StatefulWidget {
  const _RouterHost();

  @override
  State<_RouterHost> createState() => _RouterHostState();
}

class _RouterHostState extends State<_RouterHost> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router ??= AppRouter.createRouter(context.read<AuthProvider>());
  }

  @override
  Widget build(BuildContext context) {
    if (_router == null) return const SizedBox.shrink();
    final themeService = context.watch<AppThemeService>();
    // Premium background-color customization: gated on LIVE isPremiumActive
    // (a timestamp check, not the raw is_premium column, which can go
    // stale — see set_theme_background_color's own server-side check) so
    // this collapses to the theme default the instant a subscription
    // expires and reapplies automatically on resubscribe, without ever
    // touching the persisted value itself. previewBackgroundColor takes
    // priority while the background-color picker sheet is open.
    //
    // Selector (not context.watch<AuthProvider>()) deliberately: this
    // widget is the root of MaterialApp.router — ancestor of the Navigator
    // and every open route/overlay, including modal bottom sheets.
    // AuthProvider.notifyListeners() fires ~70 places for reasons unrelated
    // to premium/background state (presence, session refresh, unrelated
    // profile fields). Watching it directly rebuilt this root, and
    // therefore produced a brand-new ThemeData, on every one of those
    // notifications; if that landed while a bottom sheet route was still
    // resolving its first-frame layout, the cascading theme rebuild
    // re-entered RenderObject.layout() on a render object already mid-
    // layout, tripping Flutter's '!_debugDoingThisLayout' assertion —
    // reproduced even with a bare placeholder sheet, confirming the sheet's
    // own content was never the cause. Selector only rebuilds this root
    // when the two fields it actually reads change value.
    final (isPremiumActive, backgroundHex) = context.select<AuthProvider, (bool, String?)>(
      (auth) => (
        auth.currentUser?.isPremiumActive ?? false,
        auth.currentUser?.themeBackgroundColor,
      ),
    );
    final persistedBg = isPremiumActive
        ? AppThemeService.parseHexColor(backgroundHex)
        : null;
    final effectiveBg = isPremiumActive
        ? (themeService.previewBackgroundColor ?? persistedBg)
        : null;
    return MaterialApp.router(
      title: 'Jma3a',
      debugShowCheckedModeBanner: false,
      theme: themeService.lightTheme(backgroundOverride: effectiveBg),
      darkTheme: themeService.darkTheme(backgroundOverride: effectiveBg),
      themeMode: themeService.themeMode,
      routerConfig: _router!,
      locale: context.watch<AppProvider>().locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) =>
          _AppShell(child: child ?? const SizedBox.shrink()),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell({required this.child});
  final Widget child;

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  @override
  void initState() {
    super.initState();
    DeepLinkService.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) => Stack(
        children: [
          widget.child,
          if (!connectivity.isOnline)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _OfflineBanner(),
            ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: Container(
            color: const Color(0xFFB91C1C).withOpacity(0.92),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 12,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context).noInternetConnection,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
