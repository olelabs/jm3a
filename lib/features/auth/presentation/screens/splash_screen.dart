import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/app_version.dart';
import '../../../../shared/widgets/mouj_tech_brand.dart';

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
  String? _versionText;

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

    formattedAppVersion().then((v) {
      if (mounted) setState(() => _versionText = v);
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

            // Ownership + version disclosure — sits below the main splash
            // composition, never delaying or altering it (no animation
            // dependency on auth-init timing). Safe-area handling comes
            // from MoujTechBrand itself; this Column only needs its own
            // bottom padding since the version line sits below that.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MoujTechBrand(
                    size: MoujTechBrandSize.compact,
                    padding: EdgeInsets.zero,
                  ),
                  if (_versionText != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, top: 2),
                      child: Text(
                        '${context.l10n.settingsVersionLabel} $_versionText',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                          color: Colors.white.withOpacity(0.35),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                ],
              ),
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo mark — item 7 (splash-logo pass): switched from
                  // jma3a_logo_white.png (a mostly-transparent, dots-only
                  // mark — ~11% opaque) to jma3a_logo.png, the app's real
                  // full-color icon (a ~96%-opaque filled rounded square:
                  // gradient background + dots/smile). Forcing that onto
                  // a white tint (BlendMode.srcIn) would replace nearly
                  // every pixel with flat white, leaving only a blank
                  // rounded square with no visible mark at all — so this
                  // deliberately renders jma3a_logo.png in its own real
                  // colors instead of a broken all-white silhouette;
                  // the wordmark just below (j/a/a already white,
                  // m/3 accented) is what actually carries "white" here,
                  // unaffected by this asset swap. The translucent
                  // frame/padding below was sized for the old
                  // transparent-background mark — since jma3a_logo.png
                  // already IS a complete, polished rounded icon, the
                  // frame is now just a thin glow ring around it instead
                  // of a background box behind loose shapes.
                  Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.24),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        // ClipRRect (not the Container's own clipBehavior)
                        // so the border/shadow above stay OUTSIDE the
                        // clip — only the image itself is clipped to a
                        // slightly smaller radius, nesting cleanly inside
                        // the 1.5px border line instead of the image's
                        // own corners poking past it.
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22.5),
                          child: Image.asset(
                            'assets/images/backgrounds/jma3a_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.groups_rounded,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
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
                          context.l10n.authTakingLonger,
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
                            context.go(RouteNames.authPasswordLogin);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            context.l10n.authContinueWithoutSigningIn,
                          ),
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
