
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../../core/extensions/context_ext.dart';

class TodWaitingOverlay extends StatefulWidget {
  const TodWaitingOverlay({super.key, this.playerName});
  final String? playerName;

  @override
  State<TodWaitingOverlay> createState() => _TodWaitingOverlayState();
}

class _TodWaitingOverlayState extends State<TodWaitingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.0),
              Colors.black.withOpacity(0.45),
            ],
          ),
        ),
        child: Align(
          alignment: const Alignment(0, 0.6),
          child:
              Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(3, (i) {
                            return AnimatedBuilder(
                              animation: _pulse,
                              builder: (_, __) {
                                final delay = i * 0.3;
                                final phase = (_pulse.value + delay) % 1.0;
                                final scale = 0.6 + phase * 0.5;
                                return Container(
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.4 + phase * 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  transform: Matrix4.identity()
                                    ..scale(scale, scale),
                                  transformAlignment: Alignment.center,
                                );
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          widget.playerName != null
                              ? '${widget.playerName} is choosing…'
                              : 'Waiting for player…',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.todWaitingChoosingQuestion,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(
                    begin: 0.12,
                    end: 0,
                    duration: 300.ms,
                    curve: Curves.easeOut,
                  ),
        ),
      ),
    );
  }
}
