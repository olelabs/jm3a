import 'dart:math';
import 'package:flutter/material.dart';

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

  Color get _ringColor {
    if (_progress > 0.5) return color;
    if (_progress > 0.25) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80, height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
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
              Text('sec', style: TextStyle(fontSize: 10, color: _ringColor)),
            ],
          ),
        ],
      ),
    );
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
