import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

/// A single reaction event, deliberately minimal — each game's own
/// reaction model (TodReaction/NhieReaction/EmojiReaction) has a
/// different shape, so callers map their own list into this common one
/// rather than this widget depending on any specific game's types.
typedef ReactionEvent = ({String emoji, int ts});

/// Floats emoji reactions up across the screen as they arrive, instead of
/// only ever showing a static tally of counts. Drop into a `Stack` inside
/// any game screen — non-blocking (`IgnorePointer`), lightweight (each
/// flight is a single `TweenAnimationBuilder`, self-removing when done).
///
/// [onNewReaction] fires once per newly-observed event, at the same point
/// the flight animation is spawned — the intended hook point for a future
/// synchronized sound effect, so that wiring won't need to touch the
/// diffing logic below.
class AnimatedReactionOverlay extends StatefulWidget {
  const AnimatedReactionOverlay({
    super.key,
    required this.reactions,
    this.onNewReaction,
  });

  final List<ReactionEvent> reactions;
  final void Function(String emoji)? onNewReaction;

  @override
  State<AnimatedReactionOverlay> createState() =>
      _AnimatedReactionOverlayState();
}

class _AnimatedReactionOverlayState extends State<AnimatedReactionOverlay> {
  final _rng = Random();
  final Set<int> _seenTs = {};
  final List<_Flight> _flights = [];
  final List<Timer> _burstTimers = [];
  int _nextFlightId = 0;

  @override
  void initState() {
    super.initState();
    _seenTs.addAll(widget.reactions.map((r) => r.ts));
  }

  @override
  void dispose() {
    for (final t in _burstTimers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AnimatedReactionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // The underlying list is cleared wholesale every turn/round by the
    // game engine, not incrementally — if it just went from non-empty to
    // empty, forget every previously-seen ts instead of treating the next
    // turn's (likely overlapping) timestamps as already-animated.
    if (widget.reactions.isEmpty && oldWidget.reactions.isNotEmpty) {
      _seenTs.clear();
      return;
    }

    for (final r in widget.reactions) {
      if (_seenTs.add(r.ts)) {
        widget.onNewReaction?.call(r.emoji);
        _spawnBurst(r.emoji);
      }
    }
  }

  /// WhatsApp-style burst: one reaction event spawns several staggered
  /// flying copies instead of a single emoji — still exactly one
  /// [ReactionEvent] per action (no protocol/broadcast change), this is
  /// purely how it's rendered.
  void _spawnBurst(String emoji) {
    const burstCount = 4;
    for (var i = 0; i < burstCount; i++) {
      if (i == 0) {
        _spawnOne(emoji);
        continue;
      }
      final delay = Duration(milliseconds: i * 90 + _rng.nextInt(60));
      final timer = Timer(delay, () {
        if (mounted) _spawnOne(emoji);
      });
      _burstTimers.add(timer);
    }
  }

  void _spawnOne(String emoji) {
    final id = _nextFlightId++;
    setState(() {
      _flights.add(
        _Flight(
          id: id,
          emoji: emoji,
          startX: 0.1 + _rng.nextDouble() * 0.8,
          drift: (_rng.nextDouble() - 0.5) * 60,
          durationMs: 1600 + _rng.nextInt(600),
        ),
      );
    });
  }

  void _remove(int id) {
    if (!mounted) return;
    setState(() => _flights.removeWhere((f) => f.id == id));
  }

  @override
  Widget build(BuildContext context) {
    if (_flights.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: Stack(
        children: _flights
            .map(
              (f) => _FlyingEmoji(
                key: ValueKey(f.id),
                flight: f,
                onDone: () => _remove(f.id),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Flight {
  _Flight({
    required this.id,
    required this.emoji,
    required this.startX,
    required this.drift,
    required this.durationMs,
  });
  final int id;
  final String emoji;
  final double startX; // fraction of width, 0..1
  final double drift; // px of horizontal sway by the end
  final int durationMs;
}

class _FlyingEmoji extends StatefulWidget {
  const _FlyingEmoji({super.key, required this.flight, required this.onDone});
  final _Flight flight;
  final VoidCallback onDone;

  @override
  State<_FlyingEmoji> createState() => _FlyingEmojiState();
}

class _FlyingEmojiState extends State<_FlyingEmoji> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: widget.flight.durationMs),
      curve: Curves.easeOut,
      onEnd: widget.onDone,
      builder: (context, t, child) {
        // Rises from just above the bottom action bar up past the top of
        // the screen, drifting sideways and fading out over the back
        // third of the flight.
        final top = size.height * 0.82 - (size.height * 0.75 * t);
        final opacity = t < 0.75 ? 1.0 : (1 - (t - 0.75) / 0.25).clamp(0.0, 1.0);
        final scale = 0.8 + 0.4 * (t < 0.15 ? t / 0.15 : 1.0);
        return Positioned(
          top: top,
          left: size.width * widget.flight.startX + widget.flight.drift * t,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Text(
                widget.flight.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
        );
      },
    );
  }
}
