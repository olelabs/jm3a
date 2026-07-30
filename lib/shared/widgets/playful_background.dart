// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../../core/services/app_theme_service.dart';
// import '../../core/providers/auth_provider.dart';

// // class PlayfulBackground extends StatefulWidget {
// //   const PlayfulBackground({super.key, required this.child});
// //   final Widget child;

// //   @override
// //   State<PlayfulBackground> createState() => _PlayfulBackgroundState();
// // }

// // class _PlayfulBackgroundState extends State<PlayfulBackground>
// //     with TickerProviderStateMixin {
// //   late AnimationController _ctrl;
// //   final List<_Bubble> _bubbles = [];
// //   final _rng = Random();

// //   @override
// //   void initState() {
// //     super.initState();
// //     _ctrl = AnimationController(
// //       vsync: this,
// //       duration: const Duration(seconds: 12),
// //     )..repeat();
// //     for (var i = 0; i < 12; i++) {
// //       _bubbles.add(_Bubble.random(_rng, offset: i / 12));
// //     }
// //   }

// //   @override
// //   void dispose() {
// //     _ctrl.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final themeService = context.watch<AppThemeService>();
// //     final user = context.watch<AuthProvider>().currentUser;
// //     final isPlus = user?.premiumTier == 'premium_plus';

// //     if (!isPlus || !themeService.current.playfulBackground) {
// //       return widget.child;
// //     }

// //     final primary = Theme.of(context).colorScheme.primary;

// //     return Stack(
// //       children: [
// //         Positioned.fill(
// //           child: AnimatedBuilder(
// //             animation: _ctrl,
// //             builder: (_, __) => CustomPaint(
// //               painter: _BubblePainter(
// //                 bubbles: _bubbles,
// //                 progress: _ctrl.value,
// //                 color: primary,
// //               ),
// //             ),
// //           ),
// //         ),
// //         widget.child,
// //       ],
// //     );
// //   }
// // }

// class PlayfulBackground extends StatefulWidget {
//   const PlayfulBackground({super.key, required this.child});
//   final Widget child;

//   @override
//   State<PlayfulBackground> createState() => _PlayfulBackgroundState();
// }

// class _PlayfulBackgroundState extends State<PlayfulBackground>
//     with TickerProviderStateMixin {
//   late AnimationController _ctrl;
//   final List<_Bubble> _bubbles = [];
//   final _rng = Random();

//   @override
//   void initState() {
//     super.initState();
//     _ctrl = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 12),
//     )..repeat();
//     for (var i = 0; i < 16; i++) {
//       // more bubbles
//       _bubbles.add(_Bubble.random(_rng, offset: i / 16));
//     }
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final themeService = context.watch<AppThemeService>();
//     final user = context.watch<AuthProvider>().currentUser;
//     final isPlus = user?.premiumTier == 'premium_plus';
//     final showBg = isPlus && themeService.current.playfulBackground;

//     // Fallback if background is off
//     if (!showBg) {
//       return Container(
//         color: Theme.of(context).scaffoldBackgroundColor,
//         child: widget.child,
//       );
//     }

//     final primary = Theme.of(context).colorScheme.primary;

//     return Stack(
//       children: [
//         Positioned.fill(
//           child: AnimatedBuilder(
//             animation: _ctrl,
//             builder: (_, __) => CustomPaint(
//               painter: _BubblePainter(
//                 bubbles: _bubbles,
//                 progress: _ctrl.value,
//                 color: primary,
//               ),
//             ),
//           ),
//         ),
//         widget.child,
//       ],
//     );
//   }
// }

// class _Bubble {
//   _Bubble({
//     required this.x,
//     required this.size,
//     required this.speed,
//     required this.opacity,
//     required this.startProgress,
//     required this.wobble,
//   });

//   final double x;
//   final double size;
//   final double speed;
//   final double opacity;
//   final double startProgress;
//   final double wobble;

//   factory _Bubble.random(Random rng, {double offset = 0}) => _Bubble(
//     x: rng.nextDouble(),
//     size: 8 + rng.nextDouble() * 28,
//     speed: 0.3 + rng.nextDouble() * 0.7,
//     opacity: 0.06 + rng.nextDouble() * 0.1,
//     startProgress: offset,
//     wobble: rng.nextDouble() * 2 * pi,
//   );
// }

// class _BubblePainter extends CustomPainter {
//   const _BubblePainter({
//     required this.bubbles,
//     required this.progress,
//     required this.color,
//   });

//   final List<_Bubble> bubbles;
//   final double progress;
//   final Color color;

//   @override
//   // void paint(Canvas canvas, Size size) {
//   //   for (final b in bubbles) {
//   //     final t = ((progress * b.speed + b.startProgress) % 1.0);
//   //     final y = size.height * (1 - t);
//   //     final x = size.width * b.x + sin(t * 4 * pi + b.wobble) * 18;
//   //     final paint = Paint()
//   //       ..color = color.withOpacity(b.opacity * (0.4 + 0.6 * t))
//   //       ..style = PaintingStyle.stroke
//   //       ..strokeWidth = 1.5;
//   //     canvas.drawCircle(Offset(x, y), b.size / 2, paint);
//   //     canvas.drawCircle(
//   //       Offset(x, y),
//   //       b.size / 2,
//   //       Paint()..color = color.withOpacity(b.opacity * 0.3 * (1 - t)),
//   //     );
//   //   }
//   // }
//   void paint(Canvas canvas, Size size) {
//     for (final b in bubbles) {
//       final t = ((progress * b.speed + b.startProgress) % 1.0);
//       final y = size.height * (1 - t);
//       final x = size.width * b.x + sin(t * 4 * pi + b.wobble) * 18;

//       // Stronger opacity and larger stroke
//       final baseOpacity = b.opacity * 3.0; // was 0.06–0.16 → now 0.18–0.48
//       final strokePaint = Paint()
//         ..color = color.withOpacity(baseOpacity * (0.4 + 0.6 * t))
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 3.0; // thicker
//       canvas.drawCircle(Offset(x, y), b.size / 2, strokePaint);

//       // Fill with a bit more visibility
//       final fillPaint = Paint()
//         ..color = color.withOpacity(baseOpacity * 0.5 * (1 - t))
//         ..style = PaintingStyle.fill;
//       canvas.drawCircle(Offset(x, y), b.size / 2, fillPaint);
//     }
//   }

//   @override
//   bool shouldRepaint(_BubblePainter old) => old.progress != progress;
// }

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_theme_service.dart';
import '../../core/providers/auth_provider.dart';

class PlayfulBackground extends StatefulWidget {
  const PlayfulBackground({super.key, required this.child});
  final Widget child;

  @override
  State<PlayfulBackground> createState() => _PlayfulBackgroundState();
}

class _PlayfulBackgroundState extends State<PlayfulBackground>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<_Particle> _particles = [];
  final _rng = Random();
  BackgroundMotif? _builtFor;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  void _buildParticles(BackgroundMotif motif) {
    _particles.clear();
    final count = motif == BackgroundMotif.confetti ? 24 : 16;
    for (var i = 0; i < count; i++) {
      _particles.add(_Particle.random(_rng, offset: i / count, motif: motif));
    }
    _builtFor = motif;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<AppThemeService>();
    final user = context.watch<AuthProvider>().currentUser;
    final isPlus = user?.premiumTier == 'premium_plus';
    final motif = themeService.current.motif;

    if (!isPlus || motif == BackgroundMotif.none) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: widget.child,
      );
    }

    if (_builtFor != motif) _buildParticles(motif);

    final primary = Theme.of(context).colorScheme.primary;

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              painter: _MotifPainter(
                particles: _particles,
                progress: _ctrl.value,
                color: primary,
                motif: motif,
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.startProgress,
    required this.wobble,
    required this.rotationSpeed,
  });

  final double x;
  final double size;
  final double speed;
  final double opacity;
  final double startProgress;
  final double wobble;
  final double rotationSpeed;

  factory _Particle.random(
    Random rng, {
    double offset = 0,
    required BackgroundMotif motif,
  }) {
    final baseSize = switch (motif) {
      BackgroundMotif.stars => 6.0 + rng.nextDouble() * 10,
      BackgroundMotif.sparkles => 4.0 + rng.nextDouble() * 8,
      BackgroundMotif.flames => 10.0 + rng.nextDouble() * 16,
      BackgroundMotif.leaves => 12.0 + rng.nextDouble() * 14,
      BackgroundMotif.confetti => 6.0 + rng.nextDouble() * 8,
      BackgroundMotif.hearts => 10.0 + rng.nextDouble() * 14,
      BackgroundMotif.rockets => 14.0 + rng.nextDouble() * 10,
      _ => 8.0 + rng.nextDouble() * 28,
    };
    return _Particle(
      x: rng.nextDouble(),
      size: baseSize,
      speed: 0.3 + rng.nextDouble() * 0.7,
      opacity: 0.18 + rng.nextDouble() * 0.3,
      startProgress: offset,
      wobble: rng.nextDouble() * 2 * pi,
      rotationSpeed: 0.5 + rng.nextDouble() * 1.5,
    );
  }
}

class _MotifPainter extends CustomPainter {
  const _MotifPainter({
    required this.particles,
    required this.progress,
    required this.color,
    required this.motif,
  });

  final List<_Particle> particles;
  final double progress;
  final Color color;
  final BackgroundMotif motif;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress * p.speed + p.startProgress) % 1.0;
      final y = size.height * (1 - t);
      final x = size.width * p.x + sin(t * 4 * pi + p.wobble) * 18;
      final fade = (0.4 + 0.6 * t) * p.opacity;
      final angle = progress * p.rotationSpeed * 2 * pi;

      switch (motif) {
        case BackgroundMotif.bubbles:
          _drawBubble(canvas, Offset(x, y), p.size, fade);
        case BackgroundMotif.stars:
          _drawStar(canvas, Offset(x, y), p.size, fade, angle);
        case BackgroundMotif.sparkles:
          _drawSparkle(canvas, Offset(x, y), p.size, fade, angle);
        case BackgroundMotif.flames:
          _drawFlame(canvas, Offset(x, y), p.size, fade);
        case BackgroundMotif.leaves:
          _drawLeaf(canvas, Offset(x, y), p.size, fade, angle);
        case BackgroundMotif.confetti:
          _drawConfetti(canvas, Offset(x, y), p.size, fade, angle);
        case BackgroundMotif.hearts:
          _drawHeart(canvas, Offset(x, y), p.size, fade);
        case BackgroundMotif.rockets:
          _drawRocket(canvas, Offset(x, y), p.size, fade);
        case BackgroundMotif.none:
          break;
      }
    }
  }

  void _drawBubble(Canvas canvas, Offset c, double size, double opacity) {
    canvas.drawCircle(
      c,
      size / 2,
      Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      c,
      size / 2,
      Paint()..color = color.withOpacity(opacity * 0.3),
    );
  }

  void _drawStar(
    Canvas canvas,
    Offset c,
    double size,
    double opacity,
    double angle,
  ) {
    final path = Path();
    const points = 5;
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? size / 2 : size / 4;
      final a = (i * pi / points) + angle;
      final px = c.dx + r * cos(a);
      final py = c.dy + r * sin(a);
      if (i == 0)
        path.moveTo(px, py);
      else
        path.lineTo(px, py);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withOpacity(opacity));
  }

  void _drawSparkle(
    Canvas canvas,
    Offset c,
    double size,
    double opacity,
    double angle,
  ) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    canvas.drawLine(Offset(-size / 2, 0), Offset(size / 2, 0), paint);
    canvas.drawLine(Offset(0, -size / 2), Offset(0, size / 2), paint);
    canvas.restore();
    canvas.drawCircle(c, size / 6, Paint()..color = color.withOpacity(opacity));
  }

  void _drawFlame(Canvas canvas, Offset c, double size, double opacity) {
    final path = Path()
      ..moveTo(c.dx, c.dy + size / 2)
      ..quadraticBezierTo(c.dx - size / 2, c.dy, c.dx, c.dy - size / 2)
      ..quadraticBezierTo(c.dx + size / 2, c.dy, c.dx, c.dy + size / 2);
    canvas.drawPath(path, Paint()..color = color.withOpacity(opacity));
  }

  void _drawLeaf(
    Canvas canvas,
    Offset c,
    double size,
    double opacity,
    double angle,
  ) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(0, -size / 2)
      ..quadraticBezierTo(size / 2, 0, 0, size / 2)
      ..quadraticBezierTo(-size / 2, 0, 0, -size / 2);
    canvas.drawPath(path, Paint()..color = color.withOpacity(opacity));
    canvas.restore();
  }

  void _drawConfetti(
    Canvas canvas,
    Offset c,
    double size,
    double opacity,
    double angle,
  ) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: size, height: size * 0.4),
      Paint()..color = color.withOpacity(opacity),
    );
    canvas.restore();
  }

  void _drawHeart(Canvas canvas, Offset c, double size, double opacity) {
    final path = Path();
    final w = size / 2;
    path.moveTo(c.dx, c.dy + w * 0.6);
    path.cubicTo(
      c.dx - w,
      c.dy - w * 0.4,
      c.dx - w * 0.5,
      c.dy - w,
      c.dx,
      c.dy - w * 0.3,
    );
    path.cubicTo(
      c.dx + w * 0.5,
      c.dy - w,
      c.dx + w,
      c.dy - w * 0.4,
      c.dx,
      c.dy + w * 0.6,
    );
    canvas.drawPath(path, Paint()..color = color.withOpacity(opacity));
  }

  void _drawRocket(Canvas canvas, Offset c, double size, double opacity) {
    final paint = Paint()..color = color.withOpacity(opacity);
    final body = Path()
      ..moveTo(c.dx, c.dy - size / 2)
      ..lineTo(c.dx + size / 4, c.dy + size / 4)
      ..lineTo(c.dx - size / 4, c.dy + size / 4)
      ..close();
    canvas.drawPath(body, paint);
    canvas.drawCircle(
      Offset(c.dx, c.dy + size / 2),
      size / 8,
      Paint()..color = color.withOpacity(opacity * 0.6),
    );
  }

  @override
  bool shouldRepaint(_MotifPainter old) =>
      old.progress != progress || old.motif != motif;
}
