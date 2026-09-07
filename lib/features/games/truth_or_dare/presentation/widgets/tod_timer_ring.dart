import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../../core/extensions/context_ext.dart';

/// Circular countdown ring displayed above the card.
class TodTimerRing extends StatelessWidget {
  const TodTimerRing({
    super.key,
    required this.remaining,
    required this.total,
    required this.color,
  });

  final int   remaining;
  final int   total;
  final Color color;

  double get _progress => total > 0 ? remaining / total : 0;

  bool get _isUrgent => _progress <= 0.25;

  Color get _ringColor {
    if (_progress > 0.5) return color;
    if (_progress > 0.25) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final ring = SizedBox(
      width: 80, height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isUrgent)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _ringColor.withOpacity(0.45),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          CustomPaint(
            size: const Size(80, 80),
            painter: _RingPainter(progress: _progress, color: _ringColor),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$remaining',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: _ringColor)),
              Text(context.l10n.secAbbrev, style: TextStyle(fontSize: 10, color: _ringColor)),
            ],
          ),
        ],
      ),
    );

    if (!_isUrgent) return ring;

    return ring
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1.0, end: 1.06, duration: 550.ms, curve: Curves.easeInOut);
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.color});
  final double progress;
  final Color  color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    final paint  = Paint()
      ..color       = color.withOpacity(0.12)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap   = StrokeCap.round;
    canvas.drawCircle(center, radius, paint);
    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}
