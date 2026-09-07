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
                          child: Text(context.l10n.authContinueWithoutSigningIn),
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
