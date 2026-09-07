import 'dart:async';
import 'dart:math';

import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';

import '../../features/avatar/presentation/avatar_creator_screen.dart';
import '../../features/rooms/domain/room_entity.dart';
import 'cards/user_avatar.dart';

/// A single reaction event, deliberately minimal — each game's own
/// reaction model (TodReaction/NhieReaction/EmojiReaction) has a
/// different shape, so callers map their own list into this common one
/// rather than this widget depending on any specific game's types.
///
/// [userId] is the reactor's id, not their avatar — the payload
/// deliberately does NOT carry avatarUrl/avatarConfig/isPremium. Every
/// caller already has a live RoomMemberEntity for every seated user (via
/// RoomProvider), which already carries that data and stays fresh as it
/// changes; duplicating it into every single reaction broadcast would
/// bloat the payload and go stale the moment a sender edited their
/// avatar mid-game. See [AnimatedReactionOverlay.avatarResolver].
typedef ReactionEvent = ({String emoji, int ts, String userId});

/// Looks up the live member behind a reaction's userId, or null if
/// they've left / haven't synced yet (e.g. a late-joining spectator whose
/// room member list hasn't caught up with an in-flight reaction) — never
/// throws. Typically `RoomProvider.memberById`.
typedef AvatarReactionResolver = RoomMemberEntity? Function(String userId);

/// Maps the app's plain-Unicode reaction emoji (see `kEmojiReactions` in
/// lib/Sticker.dart, the shared reaction-picker set every game draws
/// from) to their `animated_emoji` package equivalent.
///
/// Deliberately a lookup, not a rewrite of the sending side: reactions are
/// still sent/stored as plain Unicode strings (unchanged network protocol,
/// unchanged `TodReaction`/`EmojiReaction`/etc. models) — this only
/// decides how a given string is *rendered*. Anything not in this map
/// (premium avatar reactions like `avatar:wave`, or any emoji without a
/// matching animated asset, e.g. 👑) falls back to the original plain-text
/// glyph, exactly as before this change.
const Map<String, AnimatedEmojiData> kAnimatedEmojiMap = {
  '😂': AnimatedEmojis.joy,
  '❤️': AnimatedEmojis.redHeart,
  '🔥': AnimatedEmojis.fire,
  '💀': AnimatedEmojis.skull,
  '👏': AnimatedEmojis.clap,
  '🤣': AnimatedEmojis.rofl,
  '😭': AnimatedEmojis.loudlyCrying,
  '🫡': AnimatedEmojis.salute,
  '💯': AnimatedEmojis.oneHundred,
  '🤯': AnimatedEmojis.mindBlown,
  '😤': AnimatedEmojis.triumph,
  '🥹': AnimatedEmojis.holdingBackTears,
  '🫶': AnimatedEmojis.heartHands,
  '💅': AnimatedEmojis.nailCare,
  '🙈': AnimatedEmojis.seeNoEvilMonkey,
  '😎': AnimatedEmojis.sunglassesFace,
  '🤡': AnimatedEmojis.clown,
  '💔': AnimatedEmojis.brokenHeart,
  '🎉': AnimatedEmojis.partyPopper,
  '😈': AnimatedEmojis.impSmile,
  '😍': AnimatedEmojis.heartEyes,
  '👍': AnimatedEmojis.thumbsUp,
  '😡': AnimatedEmojis.rage,
  '😱': AnimatedEmojis.screaming,
  // Added for BrandedStatusView's loading/preparing badges (item 4) —
  // same map, same fallback mechanism, no second animation system.
  '🎯': AnimatedEmojis.directHit,
  '🙊': AnimatedEmojis.speakNoEvilMonkey,
  '😹': AnimatedEmojis.joyCat,
  // Added for NHIE's "Never" / "I Have" result reveal (item 4) — same
  // map, same fallback mechanism, no second animation system. '❌'
  // stands in for the app's existing "Never" glyph (🙅 has no animated
  // asset in this package); '✋' already matches the existing "I Have"
  // glyph exactly.
  '❌': AnimatedEmojis.crossMark,
  '✋': AnimatedEmojis.raisedHand,
};

/// Max flights rendered at once. A burst spawns several staggered copies
/// per reaction event (see `_spawnBurst`), and with several players
/// reacting in quick succession that can queue up fast — this caps actual
/// concurrent Lottie/animation work so a heavy burst degrades by simply
/// not spawning more (older flights still finish/fade normally) rather
/// than ever dropping frames.
const int _kMaxConcurrentFlights = 15;

/// Floats emoji reactions up across the screen as they arrive, instead of
/// only ever showing a static tally of counts. Drop into a `Stack` inside
/// any game screen — non-blocking (`IgnorePointer`), lightweight (each
/// flight owns exactly one `AnimationController`, self-removing when
/// done).
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
    this.avatarResolver,
  });

  final List<ReactionEvent> reactions;
  final void Function(String emoji)? onNewReaction;

  /// Resolves an avatar-reaction's sender to their live room member data
  /// (avatarUrl/avatarConfig/isPremium). Only consulted for reactions
  /// whose emoji is `AvatarConfig.isAvatarReaction` — plain emoji
  /// reactions never touch this. Null (the default) or a lookup miss both
  /// degrade gracefully to UserAvatar's own initials fallback, never a
  /// crash or a broken-image placeholder.
  final AvatarReactionResolver? avatarResolver;

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
        _spawnBurst(r.emoji, r.userId);
      }
    }
  }

  /// WhatsApp-style burst: one reaction event spawns several staggered
  /// flying copies instead of a single emoji — still exactly one
  /// [ReactionEvent] per action (no protocol/broadcast change), this is
  /// purely how it's rendered.
  void _spawnBurst(String emoji, String userId) {
    const burstCount = 4;
    for (var i = 0; i < burstCount; i++) {
      if (i == 0) {
        _spawnOne(emoji, userId);
        continue;
      }
      final delay = Duration(milliseconds: i * 90 + _rng.nextInt(60));
      final timer = Timer(delay, () {
        if (mounted) _spawnOne(emoji, userId);
      });
      _burstTimers.add(timer);
    }
  }

  void _spawnOne(String emoji, String userId) {
    // Cap concurrent flights instead of letting a heavy burst pile up
    // unboundedly — a dropped spawn here is invisible to the user (a few
    // fewer copies during a huge pile-on), whereas exceeding the cap costs
    // real frame time across every active game screen.
    if (_flights.length >= _kMaxConcurrentFlights) return;

    final id = _nextFlightId++;
    setState(() {
      _flights.add(
        _Flight(
          id: id,
          emoji: emoji,
          userId: userId,
          startX: 0.1 + _rng.nextDouble() * 0.8,
          drift: (_rng.nextDouble() - 0.5) * 60,
          swayAmplitude: 14 + _rng.nextDouble() * 22,
          swayPhase: _rng.nextDouble() * pi * 2,
          swayCycles: 1 + _rng.nextDouble(),
          rotationAmplitude: (0.12 + _rng.nextDouble() * 0.22) *
              (_rng.nextBool() ? 1 : -1),
          rotationPhase: _rng.nextDouble() * pi * 2,
          scaleTarget: 0.85 + _rng.nextDouble() * 0.3,
          durationMs: 1800 + _rng.nextInt(800),
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
                avatarResolver: widget.avatarResolver,
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
    required this.userId,
    required this.startX,
    required this.drift,
    required this.swayAmplitude,
    required this.swayPhase,
    required this.swayCycles,
    required this.rotationAmplitude,
    required this.rotationPhase,
    required this.scaleTarget,
    required this.durationMs,
  });
  final int id;
  final String emoji;
  final String userId;
  final double startX; // fraction of width, 0..1
  final double drift; // px of steady horizontal carry by the end
  final double swayAmplitude; // px of side-to-side wobble on top of drift
  final double swayPhase;
  final double swayCycles;
  final double rotationAmplitude; // radians of tilt wobble, signed
  final double rotationPhase;
  final double scaleTarget; // resting scale once "popped in", 0.85..1.15
  final int durationMs;
}

class _FlyingEmoji extends StatefulWidget {
  const _FlyingEmoji({
    super.key,
    required this.flight,
    required this.onDone,
    this.avatarResolver,
  });
  final _Flight flight;
  final VoidCallback onDone;
  final AvatarReactionResolver? avatarResolver;

  @override
  State<_FlyingEmoji> createState() => _FlyingEmojiState();
}

class _FlyingEmojiState extends State<_FlyingEmoji>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // One controller drives every animated property of this flight
    // (position, sway, rotation, scale, opacity) via derived values below,
    // rather than a separate controller per property — the "reuse
    // animation controllers efficiently" this system needs when up to 15
    // of these can be alive at once.
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.flight.durationMs),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onDone();
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final flight = widget.flight;
    final isAvatarReaction = AvatarConfig.isAvatarReaction(flight.emoji);
    final animatedEmoji = isAvatarReaction
        ? null
        : kAnimatedEmojiMap[flight.emoji];

    // AnimatedBuilder must be the outermost wrapper here, with Positioned
    // returned directly from its builder — Positioned only takes effect
    // when the enclosing Stack can see it as the immediate ParentDataWidget
    // on whatever RenderObjectWidget ends up as Stack's actual child. The
    // previous ordering (RepaintBoundary wrapping AnimatedBuilder, with
    // Positioned built *inside* it) put RepaintBoundary's RenderObject
    // between Stack and Positioned's target — so Stack's real direct child
    // was RenderRepaintBoundary, which never got StackParentData at all.
    // Flutter reports that mismatch as a caught "Incorrect use of
    // ParentDataWidget" error (non-fatal, so nothing crashes) and simply
    // ignores the position, leaving every flight as an unpositioned Stack
    // child — collapsed into the Stack's default corner alignment. Moving
    // RepaintBoundary inside Positioned (still wrapping the exact same
    // Opacity/Transform subtree, so per-flight repaint isolation is
    // unchanged) fixes this: Positioned's target is now genuinely Stack's
    // direct child.
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;

        // Rises from the bottom portion of the screen up past the top,
        // easing out (Curves.easeOut) so it decelerates near the end
        // instead of a constant-speed climb — reads as drifting rather
        // than launched.
        final riseT = Curves.easeOut.transform(t);
        final top = size.height * 0.85 - (size.height * 0.78 * riseT);

        // Horizontal motion is a steady carry (drift) plus a sine sway
        // riding on top of it, so the path curves left/right instead of
        // moving in a straight diagonal line — the TikTok/IG-Live feel
        // the task asks for.
        final sway = sin(
              t * pi * 2 * flight.swayCycles + flight.swayPhase,
            ) *
            flight.swayAmplitude *
            // Sway eases in from spawn so it doesn't visibly "snap"
            // sideways in the first frame.
            min(t * 4, 1.0);
        final left = size.width * flight.startX + flight.drift * t + sway;

        // Gentle continuous tilt wobble (not a one-way spin) — "slightly
        // rotate" while staying playful rather than dizzying.
        final rotation = sin(
              t * pi * 2 + flight.rotationPhase,
            ) *
            flight.rotationAmplitude;

        // Pops in with a small overshoot over the first ~20% of the
        // flight, then holds close to its resting scale with a faint
        // breathing wobble for the remainder — "slightly scale while
        // moving" instead of a static size once spawned.
        final popT = Curves.easeOutBack.transform(min(t / 0.2, 1.0));
        final breathing = sin(t * pi * 3) * 0.04;
        final scale = 0.4 +
            (flight.scaleTarget - 0.4) * popT +
            (t > 0.2 ? breathing : 0);

        // Fade in quickly at spawn, hold, fade out over the back
        // quarter of the flight.
        final opacity = t < 0.12
            ? t / 0.12
            : (t < 0.75 ? 1.0 : (1 - (t - 0.75) / 0.25).clamp(0.0, 1.0));

        return Positioned(
          top: top,
          left: left,
          child: RepaintBoundary(
            child: Opacity(
              opacity: opacity,
              child: Transform.rotate(
                angle: rotation,
                child: Transform.scale(scale: scale, child: child),
              ),
            ),
          ),
        );
      },
      // Built once per flight (not per frame) — AnimatedBuilder re-runs
      // only the transform wrapper above on each tick, not this leaf.
      child: isAvatarReaction
          ? _FlyingAvatarReaction(
              userId: flight.userId,
              reactionKey: AvatarConfig.avatarReactionKey(flight.emoji),
              resolver: widget.avatarResolver,
            )
          : animatedEmoji != null
          ? AnimatedEmoji(
              animatedEmoji,
              size: 40,
              source: AnimatedEmojiSource.asset,
              errorWidget: Text(
                flight.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            )
          : Text(
              flight.emoji,
              style: const TextStyle(fontSize: 32),
            ),
    );
  }
}

/// The avatar-reaction leaf: wraps the app's single canonical avatar
/// renderer (UserAvatar — the same widget used in friends/profile/room
/// members/chat/leaderboards) with just a size and a decorative ring, and
/// nothing else. No image loading, URL resolution, or SVG-vs-raster
/// branching happens here — that all stays in UserAvatar, so a premium
/// avatar reaction automatically renders identically to (and inherits any
/// future feature added to) every other avatar in the app: generated
/// avatars, uploaded avatars, frames, borders, background colors.
class _FlyingAvatarReaction extends StatelessWidget {
  const _FlyingAvatarReaction({
    required this.userId,
    required this.reactionKey,
    required this.resolver,
  });

  final String userId;
  final String reactionKey;
  final AvatarReactionResolver? resolver;

  static const _size = 44.0;

  @override
  Widget build(BuildContext context) {
    // A lookup miss (member left, or a late-joining spectator whose room
    // member list hasn't synced this sender yet) is expected, not
    // exceptional — UserAvatar already renders a graceful initials
    // fallback for null avatarUrl/avatarConfig, so there is nothing
    // avatar-reaction-specific to guard against here.
    final member = resolver?.call(userId);
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
          ),
        ],
      ),
      child: UserAvatar(
        avatarUrl: member?.avatarUrl,
        avatarConfig: member?.avatarConfig,
        isPremium: member?.isPremium ?? false,
        displayName: member?.displayName,
        avatarReactionKey: reactionKey,
        size: _size,
        borderWidth: 2,
        borderColor: Colors.white,
      ),
    );
  }
}
