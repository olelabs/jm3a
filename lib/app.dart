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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jma3a/deep_links.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/errors/failures.dart';
import 'core/l10n/generated/app_localizations.dart';
import 'core/providers/app_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/services/app_update_service.dart';
import 'core/theme/app_colors.dart';
// import 'core/services/deep_link_service.dart';
import 'core/router/app_router.dart';
import 'core/router/route_names.dart';
import 'core/di/service_locator.dart';
import 'core/services/app_theme_service.dart';
import 'core/utils/app_logger.dart';
import 'core/config/platform_config_provider.dart';
import 'features/avatar/presentation/avatar_creator_screen.dart';
import 'features/friends/presentation/friends_provider.dart';
import 'features/notifications/presentation/notification_provider.dart';
import 'features/notifications/presentation/widgets/in_app_toast_overlay.dart';
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
        // One check per app launch, independent of login state (a forced
        // update must be able to block the app before/without a session)
        // — see AppUpdateService's own doc comment for why this isn't a
        // polling service.
        ChangeNotifierProvider(create: (_) => AppUpdateService()..checkForUpdate()),
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
        // Global, not user-scoped — loaded once regardless of login state.
        ChangeNotifierProvider(
          create: (_) =>
              PlatformConfigProvider(repository: sl.platformConfigRepository)
                ..load(),
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
  // Guards against re-showing the dialog on every rebuild — only a new
  // notice *instance* (a fresh ban/suspension event, or the previous one
  // cleared and a new one set) should trigger showDialog again.
  SuspendedFailure? _shownSuspensionNotice;

  // A forced update, unlike the suspension dialog, is never dismissed by
  // this app instance's own doing — the only way out is actually
  // updating (which means relaunching, re-running checkForUpdate). So
  // this is a one-way latch, not an identity comparison.
  bool _forceUpdateDialogShown = false;

  StreamSubscription<RoomInvitePayload>? _inviteSub;
  StreamSubscription<ProfileLinkPayload>? _profileSub;

  @override
  void initState() {
    super.initState();
    DeepLinkService.instance.init();
    // Room-invite deep links (https://jma3a.com/join or jma3a://join) —
    // pushed to the /join route the moment the router is ready. If the
    // user isn't logged in yet, AppRouter's own redirect chain takes over
    // from there (stashes it, sends them to login, resumes it once
    // they're actually authenticated) — see app_router.dart. This only
    // has to handle the "can act on it right now" half; DeepLinkService.
    // pendingInvite covers the deferred half even if this listener never
    // fires (e.g. the link arrived before this widget existed).
    _inviteSub = DeepLinkService.instance.inviteStream.listen(_onInvite);
    // Profile sharing correction pass — same shape: pushed to the raw
    // /profile/:userId link path (never straight to /user/:userId), so
    // AppRouter's own redirect logic is what actually decides whether to
    // resolve it immediately (already authenticated) or stash it for
    // after login — the same single normalization point a cold-start
    // native App Link URI parse goes through too, rather than
    // duplicating that decision here.
    _profileSub = DeepLinkService.instance.profileStream.listen(_onProfileLink);
  }

  /// The ONE place that turns a resolved profile deep link into an actual
  /// navigation for the "app already running/warm" case — cold start is
  /// handled entirely by AppRouter's own redirect "resume pendingProfile"
  /// logic (app_router.dart), which runs as part of the INITIAL route
  /// resolution and therefore never needs a real Navigator push at all.
  /// Pushes straight to `/user/<id>` (never the legacy `/profile/<id>`
  /// hop, which only exists for resolving a raw, already-in-flight
  /// location string) — a real, always-registered route, so this can
  /// never land on errorBuilder/NotFoundScreen regardless of timing.
  /// Deliberately gated on the exact same readiness check AppRouter's own
  /// redirect resume rule uses: if auth isn't ready yet, this does
  /// NOTHING and leaves DeepLinkService.pendingProfile stashed exactly as
  /// [DeepLinkService._handle] set it — the redirect resume rule is what
  /// consumes it once auth finishes (as part of cold-start's initial
  /// route resolution). Consuming it HERE too, unconditionally, would
  /// either double-navigate (both this push and the later redirect firing
  /// for the same link) or — worse — silently drop the link if this push
  /// gets bounced to login/splash by the auth gate before the resume rule
  /// ever gets a chance to run. A real, additive push() (not a redirect
  /// substitution) is what lets Back return to whatever screen was
  /// already showing, per the "no replacement navigation" requirement.
  Future<void> _onProfileLink(ProfileLinkPayload payload) async {
    await AppRouter.ready;
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn ||
        auth.isGuest ||
        auth.needsOnboarding ||
        auth.isInitializing) {
      return;
    }
    DeepLinkService.instance.clearPendingProfile();
    AppRouter.router.push('/user/${payload.userId}');
  }

  /// Same "single authoritative consumption point, only once actually
  /// ready" shape as [_onProfileLink] — AppRouter's own redirect "resume
  /// pendingInvite" logic already used the same four-condition readiness
  /// check to decide when to act on it; mirrored here so this direct-push
  /// path and that resume path never both fire for the same invite.
  Future<void> _onInvite(RoomInvitePayload payload) async {
    await AppRouter.ready;
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn ||
        auth.isGuest ||
        auth.needsOnboarding ||
        auth.isInitializing) {
      return;
    }
    DeepLinkService.instance.clearPendingInvite();
    AppRouter.router.push(
      Uri(
        path: RouteNames.join,
        queryParameters: {
          'code': payload.code,
          if (payload.invitedBy != null) 'invited_by': payload.invitedBy!,
        },
      ).toString(),
    );
  }

  @override
  void dispose() {
    _inviteSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }

  void _maybeShowSuspensionDialog(SuspendedFailure? notice) {
    if (notice == null || identical(notice, _shownSuspensionNotice)) return;
    _shownSuspensionNotice = notice;
    unawaited(_showSuspensionDialog(notice));
  }

  Future<void> _showSuspensionDialog(SuspendedFailure notice) async {
    final navigatorContext = await _waitForRootNavigator();
    if (navigatorContext == null || !navigatorContext.mounted || !mounted) {
      return;
    }
    AppLogger.debug('AppShell: Showing suspension dialog...');
    await showDialog<void>(
      context: navigatorContext,
      barrierDismissible: false,
      builder: (_) => _SuspensionDialog(notice: notice),
    );
    if (mounted) context.read<AuthProvider>().clearSuspensionNotice();
  }

  void _maybeShowForceUpdateDialog(AppUpdateService updateService) {
    if (!updateService.isForceUpdateRequired || _forceUpdateDialogShown) return;
    _forceUpdateDialogShown = true;
    unawaited(_showForceUpdateDialog(updateService.updateInfo!));
  }

  Future<void> _showForceUpdateDialog(AppUpdateInfo info) async {
    final navigatorContext = await _waitForRootNavigator();
    if (navigatorContext == null || !navigatorContext.mounted) return;
    AppLogger.debug('AppShell: Showing update dialog...');
    await showDialog<void>(
      context: navigatorContext,
      barrierDismissible: false,
      builder: (_) => _ForceUpdateDialog(info: info),
    );
  }

  /// _AppShellState's own [context] is NOT usable for showDialog(): it's
  /// the BuildContext MaterialApp.router's `builder` callback receives,
  /// which sits ABOVE the Router/Navigator (widget.child, rendered
  /// *inside* this state's build method, is where the Navigator actually
  /// lives) — so Navigator.of(context) can never resolve from here no
  /// matter how long we wait. That's the exact "context does not include
  /// a Navigator" error this was throwing. AppRouter.rootKey is the
  /// GlobalKey passed as GoRouter's own `navigatorKey`, so it's attached
  /// directly to the real root Navigator — its currentContext IS a
  /// Navigator descendant once that Navigator has completed its first
  /// build. This polls one frame at a time (instead of a single
  /// post-frame callback) because that first build may not have happened
  /// yet the first time this runs — reliable across cold start, session
  /// restore, and already-logged-in/out, since the root Navigator exists
  /// from GoRouter's construction in main() regardless of auth state.
  Future<BuildContext?> _waitForRootNavigator() async {
    const maxAttempts = 300; // ~5s at 60fps — safety cap, not expected to hit
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final navigatorContext = AppRouter.rootKey.currentContext;
      final ready =
          navigatorContext != null && AppRouter.rootKey.currentState != null;
      AppLogger.debug('AppShell: Navigator ready: $ready');
      if (ready) return navigatorContext;
      if (!mounted) return null;
      await WidgetsBinding.instance.endOfFrame;
    }
    AppLogger.warning('AppShell: gave up waiting for root Navigator');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Mounted for the entire app lifetime, above the Navigator — this is
    // what lets a single dialog here cover both "suspended while already
    // inside the app" (any screen) and "suspended at cold start" (splash
    // runs under this same shell) without separate wiring in either
    // place. Requirement: "if user is currently inside the app" /
    // "if the app is reopened" both funnel through AuthProvider setting
    // the same suspensionNotice — see AuthProvider.handleAccountSuspended
    // and initialize().
    _maybeShowSuspensionDialog(context.watch<AuthProvider>().suspensionNotice);

    final updateService = context.watch<AppUpdateService>();
    _maybeShowForceUpdateDialog(updateService);

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
          if (updateService.showOptionalBanner)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _UpdateBanner(
                info: updateService.updateInfo!,
                onDismiss: updateService.dismissOptionalBanner,
              ),
            ),
          const InAppToastOverlay(),
        ],
      ),
    );
  }
}

Future<void> _openAppStore(String? url) async {
  if (url == null) return;
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _ForceUpdateDialog extends StatelessWidget {
  const _ForceUpdateDialog({required this.info});
  final AppUpdateInfo info;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // canPop: false + no cancel/close action anywhere in this dialog —
    // "cannot dismiss, cannot use the app, only action: Update".
    return PopScope(
      canPop: false,
      child: AlertDialog(
        icon: const Icon(
          Icons.system_update_rounded,
          color: AppColors.brandOrangeLight,
        ),
        title: Text(info.title ?? l10n.appUpdateDefaultTitle),
        content: Text(info.message ?? l10n.appUpdateDefaultMessage),
        actions: [
          FilledButton(
            onPressed: () => _openAppStore(info.storeUrl),
            child: Text(l10n.appUpdateNowButton),
          ),
        ],
      ),
    );
  }
}

class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner({required this.info, required this.onDismiss});
  final AppUpdateInfo info;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      bottom: false,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.brandOrangeLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.system_update_rounded,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  info.title ?? l10n.appUpdateBannerMessage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _openAppStore(info.storeUrl),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  l10n.appUpdateNowButton,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              InkWell(
                onTap: onDismiss,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuspensionDialog extends StatelessWidget {
  const _SuspensionDialog({required this.notice});
  final SuspendedFailure notice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = notice.isPermanent
        ? l10n.accountBannedPermanently
        : l10n.accountSuspendedUntil(
            notice.bannedUntil != null
                ? DateFormat.yMMMd(
                    Localizations.localeOf(context).toString(),
                  ).add_jm().format(notice.bannedUntil!.toLocal())
                : '',
          );
    // canPop: false — "prevent any further interaction" applies to the
    // back gesture too, not just the tap-outside barrier above.
    return PopScope(
      canPop: false,
      child: AlertDialog(
        icon: const Icon(Icons.block_rounded, color: AppColors.errorRed),
        title: Text(l10n.accountSuspendedDialogTitle),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
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
