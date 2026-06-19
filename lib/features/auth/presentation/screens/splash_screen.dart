// // import 'package:flutter/material.dart';
// // import 'package:flutter_animate/flutter_animate.dart';
// // import 'package:go_router/go_router.dart';
// // import 'package:jma3a/core/utils/app_logger.dart';
// // import 'package:provider/provider.dart';

// // import '../../../../core/extensions/context_ext.dart';
// // import '../../../../core/providers/auth_provider.dart';
// // import '../../../../core/router/route_names.dart';
// // import '../../../../core/theme/app_colors.dart';

// // /// App entry screen — shown while session is being restored.
// // ///
// // /// GoRouter redirect guard automatically navigates away once
// // /// AuthProvider.isInitializing = false. This screen just shows
// // /// the brand and a loading indicator during that window.
// // ///
// // /// Also handles the edge case where auth initialization takes too
// // /// long (>8s) by showing a retry option.
// // class SplashScreen extends StatefulWidget {
// //   const SplashScreen({super.key});

// //   @override
// //   State<SplashScreen> createState() => _SplashScreenState();
// // }

// // // lib/features/auth/presentation/screens/splash_screen.dart
// // class _SplashScreenState extends State<SplashScreen> {
// //   bool _showTimeout = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     print('=== SPLASH SCREEN INIT STATE ===');

// //     // Check auth state after build
// //     WidgetsBinding.instance.addPostFrameCallback((_) {
// //       final auth = context.read<AuthProvider>();
// //       print('Auth state - isInitializing: ${auth.isInitializing}');
// //       print('Auth state - isLoggedIn: ${auth.isLoggedIn}');
// //       print('Auth state - error: ${auth.error}');

// //       if (!auth.isInitializing && !auth.isLoggedIn) {
// //         print('Attempting to navigate to: ${RouteNames.authEmail}');
// //         try {
// //           context.go(RouteNames.authEmail);
// //           print('Navigation called successfully');
// //         } catch (e) {
// //           print('Navigation error: $e');
// //         }
// //       } else {
// //         print(
// //           'Not navigating - isInitializing=${auth.isInitializing}, isLoggedIn=${auth.isLoggedIn}',
// //         );
// //       }
// //     });

// //     // Show timeout after 8 seconds
// //     Future.delayed(const Duration(seconds: 8), () {
// //       if (mounted && context.read<AuthProvider>().isInitializing) {
// //         print('Timeout reached - forcing showTimeout=true');
// //         setState(() => _showTimeout = true);
// //       }
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     print('Building splash screen - showTimeout=$_showTimeout');
// //     return Scaffold(
// //       backgroundColor: AppColors.infoBlue,
// //       body: Center(
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             // Logo
// //             Container(
// //                   width: 88,
// //                   height: 88,
// //                   decoration: BoxDecoration(
// //                     color: Colors.white.withOpacity(0.12),
// //                     borderRadius: BorderRadius.circular(24),
// //                   ),
// //                   child: const Icon(
// //                     Icons.groups_rounded,
// //                     color: Colors.white,
// //                     size: 52,
// //                   ),
// //                 )
// //                 .animate()
// //                 .scale(
// //                   begin: const Offset(0.4, 0.4),
// //                   end: const Offset(1, 1),
// //                   duration: 700.ms,
// //                   curve: Curves.elasticOut,
// //                 )
// //                 .fadeIn(duration: 400.ms),

// //             const SizedBox(height: 28),

// //             Text(
// //                   'Jma3a',
// //                   style: context.textTheme.displaySmall?.copyWith(
// //                     color: Colors.white,
// //                     fontWeight: FontWeight.w800,
// //                     letterSpacing: -1,
// //                   ),
// //                 )
// //                 .animate(delay: 220.ms)
// //                 .fadeIn(duration: 400.ms)
// //                 .slideY(begin: 0.25, end: 0),

// //             const SizedBox(height: 6),

// //             Text(
// //               'جماعة',
// //               style: context.textTheme.titleMedium?.copyWith(
// //                 color: Colors.white.withOpacity(0.55),
// //                 fontFamily: 'Cairo',
// //               ),
// //             ).animate(delay: 350.ms).fadeIn(duration: 400.ms),

// //             const SizedBox(height: 72),

// //             if (!_showTimeout)
// //               SizedBox(
// //                 width: 22,
// //                 height: 22,
// //                 child: CircularProgressIndicator(
// //                   strokeWidth: 2.5,
// //                   color: Colors.white.withOpacity(0.6),
// //                 ),
// //               ).animate(delay: 700.ms).fadeIn(duration: 400.ms)
// //             else
// //               Column(
// //                 children: [
// //                   Text(
// //                     'Taking longer than usual…',
// //                     style: context.textTheme.bodySmall?.copyWith(
// //                       color: Colors.white.withOpacity(0.6),
// //                     ),
// //                   ),
// //                   const SizedBox(height: 12),
// //                   TextButton(
// //                     onPressed: () {
// //                       print('Continue without signing in pressed');
// //                       context.go(RouteNames.authEmail);
// //                     },
// //                     style: TextButton.styleFrom(foregroundColor: Colors.white),
// //                     child: const Text('Continue without signing in'),
// //                   ),
// //                 ],
// //               ).animate().fadeIn(),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// // // class _SplashScreenState extends State<SplashScreen> {
// // //   bool _showTimeout = false;

// // //   @override
// // //   // void initState() {
// // //   //   super.initState();
// // //   //   // Show "something went wrong" option after 8 seconds
// // //   //   Future.delayed(const Duration(seconds: 8), () {
// // //   //     if (mounted && context.read<AuthProvider>().isInitializing) {
// // //   //       setState(() => _showTimeout = true);
// // //   //     }
// // //   //   });
// // //   // }
// // //   // void initState() {
// // //   //   super.initState();
// // //   //   // Check if AuthProvider initialization is taking too long
// // //   //   Future.delayed(const Duration(seconds: 5), () {
// // //   //     if (mounted && context.read<AuthProvider>().isInitializing) {
// // //   //       AppLogger.warning(
// // //   //         'AuthProvider initialization timeout - forcing navigation',
// // //   //       );
// // //   //       if (mounted) {
// // //   //         context.go(RouteNames.authEmail);
// // //   //       }
// // //   //     }
// // //   //   });
// // //   //   // Show "something went wrong" option after 8 seconds
// // //   //   Future.delayed(const Duration(seconds: 8), () {
// // //   //     if (mounted && context.read<AuthProvider>().isInitializing) {
// // //   //       setState(() => _showTimeout = true);
// // //   //     }
// // //   //   });
// // //   // }
// // //   @override
// // //   void initState() {
// // //     super.initState();

// // //     // Debug: Check auth state after build
// // //     WidgetsBinding.instance.addPostFrameCallback((_) {
// // //       final auth = context.read<AuthProvider>();
// // //       print('SplashScreen - isInitializing: ${auth.isInitializing}');
// // //       print('SplashScreen - isLoggedIn: ${auth.isLoggedIn}');

// // //       // Manually navigate if needed
// // //       if (!auth.isInitializing && !auth.isLoggedIn) {
// // //         print('Manually navigating to auth email');
// // //         context.go(RouteNames.authEmail);
// // //       }
// // //     });
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     // Listen to AuthProvider changes
// // //     return Consumer<AuthProvider>(
// // //       builder: (context, authProvider, _) {
// // //         // If initialization is complete, let GoRouter handle navigation
// // //         if (!authProvider.isInitializing && mounted) {
// // //           // Small delay to let GoRouter pick up the change
// // //           WidgetsBinding.instance.addPostFrameCallback((_) {
// // //             if (mounted) {
// // //               // Force rebuild of router
// // //               context.go(RouteNames.splash);
// // //             }
// // //           });
// // //         }

// // //         return Scaffold(
// // //           backgroundColor: AppColors.infoBlue,
// // //           body: Center(
// // //             child: Column(
// // //               mainAxisSize: MainAxisSize.min,
// // //               children: [
// // //                 // Logo
// // //                 Container(
// // //                       width: 88,
// // //                       height: 88,
// // //                       decoration: BoxDecoration(
// // //                         color: Colors.white.withOpacity(0.12),
// // //                         borderRadius: BorderRadius.circular(24),
// // //                       ),
// // //                       child: const Icon(
// // //                         Icons.groups_rounded,
// // //                         color: Colors.white,
// // //                         size: 52,
// // //                       ),
// // //                     )
// // //                     .animate()
// // //                     .scale(
// // //                       begin: const Offset(0.4, 0.4),
// // //                       end: const Offset(1, 1),
// // //                       duration: 700.ms,
// // //                       curve: Curves.elasticOut,
// // //                     )
// // //                     .fadeIn(duration: 400.ms),

// // //                 const SizedBox(height: 28),

// // //                 Text(
// // //                       'Jma3a',
// // //                       style: context.textTheme.displaySmall?.copyWith(
// // //                         color: Colors.white,
// // //                         fontWeight: FontWeight.w800,
// // //                         letterSpacing: -1,
// // //                       ),
// // //                     )
// // //                     .animate(delay: 220.ms)
// // //                     .fadeIn(duration: 400.ms)
// // //                     .slideY(begin: 0.25, end: 0),

// // //                 const SizedBox(height: 6),

// // //                 Text(
// // //                   'جماعة',
// // //                   style: context.textTheme.titleMedium?.copyWith(
// // //                     color: Colors.white.withOpacity(0.55),
// // //                     fontFamily: 'Cairo',
// // //                   ),
// // //                 ).animate(delay: 350.ms).fadeIn(duration: 400.ms),

// // //                 const SizedBox(height: 72),

// // //                 if (!_showTimeout)
// // //                   SizedBox(
// // //                     width: 22,
// // //                     height: 22,
// // //                     child: CircularProgressIndicator(
// // //                       strokeWidth: 2.5,
// // //                       color: Colors.white.withOpacity(0.6),
// // //                     ),
// // //                   ).animate(delay: 700.ms).fadeIn(duration: 400.ms)
// // //                 else
// // //                   Column(
// // //                     children: [
// // //                       Text(
// // //                         'Taking longer than usual…',
// // //                         style: context.textTheme.bodySmall?.copyWith(
// // //                           color: Colors.white.withOpacity(0.6),
// // //                         ),
// // //                       ),
// // //                       const SizedBox(height: 12),
// // //                       TextButton(
// // //                         onPressed: () => context.go(RouteNames.authEmail),
// // //                         style: TextButton.styleFrom(
// // //                           foregroundColor: Colors.white,
// // //                         ),
// // //                         child: const Text('Continue without signing in'),
// // //                       ),
// // //                     ],
// // //                   ).animate().fadeIn(),
// // //               ],
// // //             ),
// // //           ),
// // //         );
// // //       },
// // //     );
// // //   }
// // // }

// // lib/features/auth/presentation/screens/splash_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';

// import '../../../../core/extensions/context_ext.dart';
// import '../../../../core/providers/auth_provider.dart';
// import '../../../../core/router/route_names.dart';
// import '../../../../core/theme/app_colors.dart';

// /// App entry screen — shown while session is being restored.
// ///
// /// GoRouter redirect guard automatically navigates away once
// /// AuthProvider.isInitializing = false. This screen just shows
// /// the brand and a loading indicator during that window.
// ///
// /// Also handles the edge case where auth initialization takes too
// /// long (>8s) by showing a retry option.
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   bool _showTimeout = false;

//   @override
//   void initState() {
//     super.initState();

//     // Check auth state after build and navigate if needed
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final auth = context.read<AuthProvider>();

//       if (!auth.isInitializing && !auth.isLoggedIn) {
//         // Navigate to email screen
//         context.go(RouteNames.authEmail);
//       }
//     });

//     // Show timeout option after 8 seconds
//     Future.delayed(const Duration(seconds: 8), () {
//       if (mounted && context.read<AuthProvider>().isInitializing) {
//         setState(() => _showTimeout = true);
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.infoBlue,
//       body: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Logo
//             Container(
//                   width: 88,
//                   height: 88,
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.12),
//                     borderRadius: BorderRadius.circular(24),
//                   ),
//                   child: const Icon(
//                     Icons.groups_rounded,
//                     color: Colors.white,
//                     size: 52,
//                   ),
//                 )
//                 .animate()
//                 .scale(
//                   begin: const Offset(0.4, 0.4),
//                   end: const Offset(1, 1),
//                   duration: 700.ms,
//                   curve: Curves.elasticOut,
//                 )
//                 .fadeIn(duration: 400.ms),

//             const SizedBox(height: 28),

//             Text(
//                   'Jma3a',
//                   style: context.textTheme.displaySmall?.copyWith(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w800,
//                     letterSpacing: -1,
//                   ),
//                 )
//                 .animate(delay: 220.ms)
//                 .fadeIn(duration: 400.ms)
//                 .slideY(begin: 0.25, end: 0),

//             const SizedBox(height: 6),

//             Text(
//               'جماعة',
//               style: context.textTheme.titleMedium?.copyWith(
//                 color: Colors.white.withOpacity(0.55),
//                 fontFamily: 'Cairo',
//               ),
//             ).animate(delay: 350.ms).fadeIn(duration: 400.ms),

//             const SizedBox(height: 72),

//             if (!_showTimeout)
//               SizedBox(
//                 width: 22,
//                 height: 22,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2.5,
//                   color: Colors.white.withOpacity(0.6),
//                 ),
//               ).animate(delay: 700.ms).fadeIn(duration: 400.ms)
//             else
//               Column(
//                 children: [
//                   Text(
//                     'Taking longer than usual…',
//                     style: context.textTheme.bodySmall?.copyWith(
//                       color: Colors.white.withOpacity(0.6),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   TextButton(
//                     onPressed: () => context.go(RouteNames.authEmail),
//                     style: TextButton.styleFrom(foregroundColor: Colors.white),
//                     child: const Text('Continue without signing in'),
//                   ),
//                 ],
//               ).animate().fadeIn(),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // lib/features/auth/presentation/screens/splash_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';

// import '../../../../core/extensions/context_ext.dart';
// import '../../../../core/providers/auth_provider.dart';
// import '../../../../core/router/route_names.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/utils/app_logger.dart';

// /// App entry screen — shown while session is being restored.
// ///
// /// Waits for [AuthProvider] to complete initialization, then lets
// /// [GoRouter]'s redirect logic handle where to go (home or auth).
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   bool _showTimeout = false;
//   bool _hasNavigated = false;

//   @override
//   void initState() {
//     super.initState();
//     AppLogger.info('SplashScreen: initState');

//     // Listen to auth provider changes after build
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _checkAndNavigate(context.read<AuthProvider>());
//     });

//     // Fallback timeout: if auth never initializes, force navigation after 8 seconds
//     Future.delayed(const Duration(seconds: 8), () {
//       if (!mounted) return;
//       final auth = context.read<AuthProvider>();
//       if (auth.isInitializing) {
//         AppLogger.warning('SplashScreen: timeout, forcing navigation');
//         setState(() => _showTimeout = true);
//       }
//     });
//   }

//   void _checkAndNavigate(AuthProvider auth) {
//     if (_hasNavigated) return;

//     if (!auth.isInitializing) {
//       _hasNavigated = true;
//       // Let GoRouter's redirect handle where to go.
//       // We just need to trigger a rebuild of the router by pushing a dummy route.
//       // The safest way: replace with the current location to force redirect evaluation.
//       final currentLocation = GoRouterState.of(context).uri.toString();
//       AppLogger.info(
//         'SplashScreen: auth init complete, forcing redirect check (current=$currentLocation)',
//       );
//       context.go(currentLocation);
//     } else {
//       AppLogger.debug('SplashScreen: waiting for auth init...');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.infoBlue,
//       body: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Logo
//             Container(
//                   width: 88,
//                   height: 88,
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.12),
//                     borderRadius: BorderRadius.circular(24),
//                   ),
//                   child: const Icon(
//                     Icons.groups_rounded,
//                     color: Colors.white,
//                     size: 52,
//                   ),
//                 )
//                 .animate()
//                 .scale(
//                   begin: const Offset(0.4, 0.4),
//                   end: const Offset(1, 1),
//                   duration: 700.ms,
//                   curve: Curves.elasticOut,
//                 )
//                 .fadeIn(duration: 400.ms),

//             const SizedBox(height: 28),

//             Text(
//                   'Jma3a',
//                   style: context.textTheme.displaySmall?.copyWith(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w800,
//                     letterSpacing: -1,
//                   ),
//                 )
//                 .animate(delay: 220.ms)
//                 .fadeIn(duration: 400.ms)
//                 .slideY(begin: 0.25, end: 0),

//             const SizedBox(height: 6),

//             Text(
//               'جماعة',
//               style: context.textTheme.titleMedium?.copyWith(
//                 color: Colors.white.withOpacity(0.55),
//                 fontFamily: 'Cairo',
//               ),
//             ).animate(delay: 350.ms).fadeIn(duration: 400.ms),

//             const SizedBox(height: 72),

//             if (!_showTimeout)
//               SizedBox(
//                 width: 22,
//                 height: 22,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2.5,
//                   color: Colors.white.withOpacity(0.6),
//                 ),
//               ).animate(delay: 700.ms).fadeIn(duration: 400.ms)
//             else
//               Column(
//                 children: [
//                   Text(
//                     'Taking longer than usual…',
//                     style: context.textTheme.bodySmall?.copyWith(
//                       color: Colors.white.withOpacity(0.6),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   TextButton(
//                     onPressed: () {
//                       AppLogger.info(
//                         'SplashScreen: user tapped continue without sign in',
//                       );
//                       context.go(RouteNames.authEmail);
//                     },
//                     style: TextButton.styleFrom(foregroundColor: Colors.white),
//                     child: const Text('Continue without signing in'),
//                   ),
//                 ],
//               ).animate().fadeIn(),
//           ],
//         ),
//       ),
//     );
//   }
// }

// lib/features/auth/presentation/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_logger.dart';

/// App entry screen — shown while session is being restored.
///
/// Waits for [AuthProvider] to complete initialization, then lets
/// [GoRouter]'s redirect logic handle where to go (home or auth).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showTimeout = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    AppLogger.info('SplashScreen: initState');

    // Listen to auth provider changes after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndNavigate(context.read<AuthProvider>());
    });

    // Fallback timeout: if auth never initializes, force navigation after 8 seconds
    Future.delayed(const Duration(seconds: 8), () {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.isInitializing) {
        AppLogger.warning('SplashScreen: timeout, forcing navigation');
        setState(() => _showTimeout = true);
      }
    });
  }

  void _checkAndNavigate(AuthProvider auth) {
    if (_hasNavigated) return;

    if (!auth.isInitializing) {
      _hasNavigated = true;
      // Let GoRouter's redirect handle where to go.
      // We just need to trigger a rebuild of the router by pushing a dummy route.
      // The safest way: replace with the current location to force redirect evaluation.
      final currentLocation = GoRouterState.of(context).uri.toString();
      AppLogger.info(
        'SplashScreen: auth init complete, forcing redirect check (current=$currentLocation)',
      );
      context.go(currentLocation);
    } else {
      AppLogger.debug('SplashScreen: waiting for auth init...');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF163354), Color(0xFF0E1F35), Color(0xFF091627)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative glow blobs
            Positioned(
              top: -60,
              left: -40,
              child: _Glow(color: AppColors.successGreen, size: 220),
            ),
            Positioned(
              top: 80,
              right: -60,
              child: _Glow(color: AppColors.errorRed, size: 260),
            ),
            Positioned(
              bottom: -80,
              right: -40,
              child: _Glow(color: AppColors.truthColor, size: 240),
            ),

            // Floating accent dots
            const Positioned(
              top: 120,
              right: 70,
              child: _Dot(color: AppColors.nhieGreen, size: 10, opacity: 0.55),
            ),
            const Positioned(
              top: 220,
              left: 50,
              child: _Dot(color: AppColors.errorRed, size: 14, opacity: 0.45),
            ),
            const Positioned(
              bottom: 160,
              right: 60,
              child: _Dot(color: AppColors.truthColor, size: 7, opacity: 0.6),
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo mark
                  Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.14),
                            width: 1,
                          ),
                        ),
                        child: CustomPaint(
                          size: const Size(96, 96),
                          painter: _Jma3aMarkPainter(),
                        ),
                      )
                      .animate()
                      .scale(
                        begin: const Offset(0.4, 0.4),
                        end: const Offset(1, 1),
                        duration: 700.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 32),

                  // Wordmark: jma3a with accent letters
                  RichText(
                        text: TextSpan(
                          style: context.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                          children: const [
                            TextSpan(
                              text: 'j',
                              style: TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: 'm',
                              style: TextStyle(color: AppColors.nhieGreen),
                            ),
                            TextSpan(
                              text: 'a',
                              style: TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: '3',
                              style: TextStyle(color: AppColors.dareColor),
                            ),
                            TextSpan(
                              text: 'a',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      )
                      .animate(delay: 220.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.25, end: 0),

                  const SizedBox(height: 8),

                  Text(
                    'جماعة',
                    style: context.textTheme.titleMedium?.copyWith(
                      color: AppColors.nhieGreen.withOpacity(0.75),
                      fontFamily: 'Cairo',
                      letterSpacing: 2,
                    ),
                  ).animate(delay: 350.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: 72),

                  if (!_showTimeout)
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ).animate(delay: 700.ms).fadeIn(duration: 400.ms)
                  else
                    Column(
                      children: [
                        Text(
                          'Taking longer than usual…',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            AppLogger.info(
                              'SplashScreen: user tapped continue without sign in',
                            );
                            context.go(RouteNames.authEmail);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Continue without signing in'),
                        ),
                      ],
                    ).animate().fadeIn(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft radial glow blob used as a decorative background accent.
class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.30), color.withOpacity(0.0)],
        ),
      ),
    );
  }
}

/// Small floating accent dot.
class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size, this.opacity = 1});

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }
}

/// Paints the jma3a "group" mark: three overlapping player dots
/// connected by a smile-like curve, echoing the brand's multiplayer theme.
class _Jma3aMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final whitePaint = Paint()..color = Colors.white;
    final whiteSoft = Paint()..color = Colors.white.withOpacity(0.9);
    final whiteFaint = Paint()..color = Colors.white.withOpacity(0.8);

    // Three player circles (group motif)
    canvas.drawCircle(Offset(w * 0.34, h * 0.40), w * 0.10, whiteSoft);
    canvas.drawCircle(Offset(w * 0.56, h * 0.32), w * 0.115, whitePaint);
    canvas.drawCircle(Offset(w * 0.69, h * 0.49), w * 0.08, whiteFaint);

    // Accent dots
    canvas.drawCircle(
      Offset(w * 0.56, h * 0.15),
      w * 0.028,
      Paint()..color = const Color(0xFF2DC08A),
    );
    canvas.drawCircle(
      Offset(w * 0.71, h * 0.22),
      w * 0.022,
      Paint()..color = const Color(0xFFE8A838),
    );

    // Connecting curve (smile)
    final path = Path()
      ..moveTo(w * 0.28, h * 0.66)
      ..quadraticBezierTo(w * 0.5, h * 0.80, w * 0.72, h * 0.66);
    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.034
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
