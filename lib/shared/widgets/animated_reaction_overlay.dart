import 'dart:math';

import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';

import '../../features/avatar/presentation/avatar_creator_screen.dart';
import '../../features/rooms/domain/room_entity.dart';
import 'cards/player_profile_card.dart';
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
  // Item 6 (reaction-expansion pass) — real animated_emoji matches for
  // the new reactions appended to kEmojiReactions (Sticker.dart). '😍'
  // and '👍' already existed above; every other new reaction that
  // doesn't have a real match here (e.g. '😔', '🥺') simply falls back
  // to its plain glyph, exactly like the pre-existing '👑' already does.
  '🤩': AnimatedEmojis.starStruck,
  '🥳': AnimatedEmojis.partyingFace,
  '😘': AnimatedEmojis.kissingHeart,
  '💖': AnimatedEmojis.sparklingHeart,
  '✨': AnimatedEmojis.sparkles,
  '🌟': AnimatedEmojis.glowingStar,
  '🌈': AnimatedEmojis.rainbow,
  '🏆': AnimatedEmojis.trophy,
  '🤝': AnimatedEmojis.handshake,
  '🤞': AnimatedEmojis.crossedFingers,
  '👀': AnimatedEmojis.eyes,
  '😆': AnimatedEmojis.laughing,
  '😉': AnimatedEmojis.wink,
  '😏': AnimatedEmojis.smirk,
  '🫠': AnimatedEmojis.melting,
  '🤠': AnimatedEmojis.cowboy,
  '😲': AnimatedEmojis.astonished,
  '😳': AnimatedEmojis.flushed,
  '🙄': AnimatedEmojis.rollingEyes,
  '😠': AnimatedEmojis.angry,
};

/// Max flights rendered at once. With several players reacting in quick
/// succession, spawns can queue up fast — this caps actual concurrent
/// Lottie/animation work so a heavy burst degrades by simply not spawning
/// more (older flights still finish/fade normally) rather than ever
/// dropping frames.
const int _kMaxConcurrentFlights = 15;

/// Floats a reaction (icon/emoji/custom reaction graphic + the reacting
/// player's NAME — deliberately no profile-picture avatar, see
/// _ReactionContent's own doc comment) from the bottom-right of the
/// screen diagonally up toward the center/upper-center, fading out as it
/// travels. Drop into a `Stack` inside any game screen (as
/// `Positioned.fill` — see each call site's own comment on why) —
/// lightweight (each flight owns exactly one `AnimationController`,
/// self-removing when done) and never rebuilds the surrounding game
/// screen for its own animation frames.
///
/// Every event gets its OWN flight with its OWN independent lifecycle —
/// new reactions are appended to [_flights], never replacing an existing
/// one, and multiple flights (including repeats from the same user, and
/// bursts from different users) animate fully independently and
/// concurrently, each fading and self-removing on its own schedule.
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

  /// Resolves a reaction's sender to their live room member data. Every
  /// flight uses this for the reactor's NAME; an avatar-token reaction
  /// additionally uses it to render the sender's own expressive avatar as
  /// the reaction graphic itself (not a plain identity photo — see
  /// _ReactionContent's doc comment). Null (the default) or a lookup miss
  /// both degrade gracefully (empty name, UserAvatar's own initials
  /// fallback for an avatar-token reaction), never a crash or a
  /// broken-image placeholder.
  final AvatarReactionResolver? avatarResolver;

  @override
  State<AnimatedReactionOverlay> createState() =>
      _AnimatedReactionOverlayState();
}

class _AnimatedReactionOverlayState extends State<AnimatedReactionOverlay> {
  final _rng = Random();
  final Set<int> _seenTs = {};
  final List<_Flight> _flights = [];
  int _nextFlightId = 0;

  @override
  void initState() {
    super.initState();
    // Pre-existing reactions at mount (e.g. reconnect mid-round) must not
    // all replay — only genuinely new ones after this point are shown.
    _seenTs.addAll(widget.reactions.map((r) => r.ts));
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

    // Each event ts is only ever spawned once — this Set is the single
    // duplicate-event guard for both a genuinely repeated broadcast and a
    // rebuild that hands back the same underlying list.
    for (final r in widget.reactions) {
      if (_seenTs.add(r.ts)) {
        widget.onNewReaction?.call(r.emoji);
        _spawn(r.emoji, r.userId);
      }
    }
  }

  void _spawn(String emoji, String userId) {
    // Cap concurrent flights instead of letting a heavy pile-on grow
    // unboundedly — a dropped spawn here is invisible to the user (a few
    // fewer flights during a huge burst of reactions), whereas exceeding
    // the cap costs real frame time across every active game screen.
    if (_flights.length >= _kMaxConcurrentFlights) return;

    final id = _nextFlightId++;
    setState(() {
      _flights.add(
        _Flight(
          id: id,
          emoji: emoji,
          userId: userId,
          // Bottom-right origin, spread with a controlled random offset so
          // several concurrent flights never stack on exactly the same
          // spot.
          startX: 0.58 + _rng.nextDouble() * 0.34,
          startYFraction: 0.80 + _rng.nextDouble() * 0.10,
          // Toward the center/upper-center — also randomized within a
          // tighter band so flights converge without literally
          // overlapping.
          endX: 0.32 + _rng.nextDouble() * 0.30,
          endYFraction: 0.14 + _rng.nextDouble() * 0.12,
          swayAmplitude: 6 + _rng.nextDouble() * 12,
          swayPhase: _rng.nextDouble() * pi * 2,
          swayCycles: 1 + _rng.nextDouble() * 0.6,
          rotationAmplitude:
              (0.05 + _rng.nextDouble() * 0.10) * (_rng.nextBool() ? 1 : -1),
          rotationPhase: _rng.nextDouble() * pi * 2,
          scaleTarget: 0.9 + _rng.nextDouble() * 0.2,
          // Noticeably slower than a typical burst-style reaction (that
          // reference is ~1-1.5s) and long enough that the icon/name stay
          // clearly readable for most of the flight, not just an instant.
          durationMs: 3600 + _rng.nextInt(1400),
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
    // Not IgnorePointer: each flight's own composite (icon+name) is
    // individually tappable (opens the player's profile — see _Flight),
    // but a bare Positioned child with no gesture detector of its own
    // never absorbs a hit-test on its own, so every pixel of the overlay
    // OUTSIDE an actual flight's rendered content still passes taps
    // straight through to the game controls underneath, unblocked.
    return Stack(
      children: _flights
          .map(
            (f) => _FlyingReaction(
              key: ValueKey(f.id),
              flight: f,
              onDone: () => _remove(f.id),
              avatarResolver: widget.avatarResolver,
            ),
          )
          .toList(),
    );
  }
}

class _Flight {
  _Flight({
    required this.id,
    required this.emoji,
    required this.userId,
    required this.startX,
    required this.startYFraction,
    required this.endX,
    required this.endYFraction,
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
  final double startX; // fraction of width
  final double startYFraction; // fraction of height
  final double endX; // fraction of width
  final double endYFraction; // fraction of height
  final double swayAmplitude; // px of side-to-side wobble riding the path
  final double swayPhase;
  final double swayCycles;
  final double rotationAmplitude; // radians of tilt wobble, signed
  final double rotationPhase;
  final double scaleTarget; // resting scale once "popped in"
  final int durationMs;
}

class _FlyingReaction extends StatefulWidget {
  const _FlyingReaction({
    super.key,
    required this.flight,
    required this.onDone,
    this.avatarResolver,
  });
  final _Flight flight;
  final VoidCallback onDone;
  final AvatarReactionResolver? avatarResolver;

  @override
  State<_FlyingReaction> createState() => _FlyingReactionState();
}

class _FlyingReactionState extends State<_FlyingReaction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // One controller drives every animated property of this flight
    // (position, sway, rotation, scale, opacity) via derived values below
    // — its own independent lifecycle, entirely unaffected by any other
    // concurrent flight.
    _controller =
        AnimationController(
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

  void _openProfile(RoomMemberEntity? member) {
    if (member == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Center(child: PlayerProfileCard(member: member)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final flight = widget.flight;
    final member = widget.avatarResolver?.call(flight.userId);
    final isAvatarReaction = AvatarConfig.isAvatarReaction(flight.emoji);
    final animatedEmoji = isAvatarReaction
        ? null
        : kAnimatedEmojiMap[flight.emoji];

    // AnimatedBuilder must be the outermost wrapper here, with Positioned
    // returned directly from its builder — Positioned only takes effect
    // when the enclosing Stack can see it as the immediate ParentDataWidget
    // on whatever RenderObjectWidget ends up as Stack's actual child (see
    // this file's git history for the exact "Incorrect use of
    // ParentDataWidget" pitfall this avoids).
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final riseT = Curves.easeOut.transform(t);

        // Safe-area-respecting travel band: never starts below the
        // bottom inset or ends above the top inset.
        final topStart = size.height * flight.startYFraction;
        final topEnd = (size.height * flight.endYFraction) + padding.top + 4;
        final top = topStart + (topEnd - topStart) * riseT;

        final leftStart = size.width * flight.startX;
        final leftEnd = size.width * flight.endX;
        final sway =
            sin(t * pi * 2 * flight.swayCycles + flight.swayPhase) *
            flight.swayAmplitude *
            // Sway eases in from spawn so it doesn't visibly "snap"
            // sideways in the first frame.
            min(t * 4, 1.0);
        final left = leftStart + (leftEnd - leftStart) * riseT + sway;

        // Gentle continuous tilt wobble (not a one-way spin).
        final rotation =
            sin(t * pi * 2 + flight.rotationPhase) * flight.rotationAmplitude;

        // Pops in with a small overshoot over the first ~15% of the
        // flight, then holds close to its resting scale.
        final popT = Curves.easeOutBack.transform(min(t / 0.15, 1.0));
        final scale = 0.5 + (flight.scaleTarget - 0.5) * popT;

        // Fade in quickly at spawn, hold through the middle so the
        // name stays clearly readable, fade out over the final quarter.
        final opacity = t < 0.10
            ? t / 0.10
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openProfile(member),
        child: _ReactionContent(
          emoji: flight.emoji,
          isAvatarReaction: isAvatarReaction,
          animatedEmoji: animatedEmoji,
          member: member,
        ),
      ),
    );
  }
}

/// The reaction's visible content: the reaction icon/emoji/custom
/// reaction graphic + the reactor's NAME only — see
/// AnimatedReactionOverlay's own class doc. Deliberately no profile
/// picture: the reactor's identity is conveyed by name alone, not their
/// avatar, so removing it doesn't leave a name floating awkwardly next
/// to an empty gap where an avatar used to sit. An avatar-token reaction
/// (`avatar:<key>`) is unaffected by this — it renders the sender's
/// expressive avatar as the reaction GRAPHIC itself (the actual reaction
/// content, e.g. "😂 via my own face"), which is categorically different
/// from a plain identity photo and is explicitly one of the reaction
/// types this widget keeps (see the class doc's "emoji/custom reaction
/// asset/avatar reaction" list).
class _ReactionContent extends StatelessWidget {
  const _ReactionContent({
    required this.emoji,
    required this.isAvatarReaction,
    required this.animatedEmoji,
    required this.member,
  });

  final String emoji;
  final bool isAvatarReaction;
  final AnimatedEmojiData? animatedEmoji;
  final RoomMemberEntity? member;

  static const double _iconSize = 30;

  Widget _icon() {
    if (isAvatarReaction) {
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
          avatarReactionKey: AvatarConfig.avatarReactionKey(emoji),
          size: 40,
          borderWidth: 2,
          borderColor: Colors.white,
        ),
      );
    }
    if (animatedEmoji != null) {
      return AnimatedEmoji(
        animatedEmoji!,
        size: _iconSize,
        source: AnimatedEmojiSource.asset,
        errorWidget: Text(emoji, style: const TextStyle(fontSize: 26)),
      );
    }
    return Text(emoji, style: const TextStyle(fontSize: 26));
  }

  @override
  Widget build(BuildContext context) {
    final name = member?.displayName ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _icon(),
            if (name.isNotEmpty) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    // Item 1 (this pass) — explicit TextDecoration.none.
                    // This Text's style previously left `decoration`
                    // unset, so it silently inherited whatever the
                    // nearest ambient DefaultTextStyle happened to carry
                    // (Flutter merges an unset property from the given
                    // style onto the inherited one, it does not reset it)
                    // — that ambient decoration is what showed as stray
                    // line(s) under every reactor's name. Every property
                    // is now pinned explicitly so this name never again
                    // depends on whatever DefaultTextStyle happens to be
                    // above it in a given game screen's widget tree.
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
