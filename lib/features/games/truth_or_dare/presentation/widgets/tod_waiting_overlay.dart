import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../../core/extensions/context_ext.dart';

class TodWaitingOverlay extends StatelessWidget {
  const TodWaitingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.0),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: context.colorScheme.surface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1),
                    blurRadius: 20, offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.colorScheme.primary)),
                const SizedBox(width: 10),
                Text("Waiting for player…",
                    style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ).animate().fadeIn().scale(
                begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
        ),
      ),
    );
  }
}
