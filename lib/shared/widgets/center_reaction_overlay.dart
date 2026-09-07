import 'dart:async';
import 'dart:collection';

import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';

import '../../features/avatar/presentation/avatar_creator_screen.dart';
import 'animated_reaction_overlay.dart'
    show ReactionEvent, AvatarReactionResolver, kAnimatedEmojiMap;
import 'cards/user_avatar.dart';

/// Shared, game-agnostic reaction presenter used by EVERY game (Truth-or-Dare,
/// NHIE, Meme). Replaces the old floating/flying reaction behavior: when a new
/// reaction arrives it is shown ONCE, large, in the center of the screen, with
/// the reacting user's name underneath, for [displayDuration] (default 3s),
/// then auto-dismisses. Tapping anywhere dismisses immediately.
///
/// - An avatar reaction (value `avatar:<key>`) renders the reacting user's REAL
///   avatar via the shared [UserAvatar]; an emoji reaction renders the emoji.
///   The internal token ("avatar:dead1") is NEVER shown to the user.
/// - Purely presentational: it only observes [reactions] and never mutates game
///   state, so multiplayer synchronization is unaffected.
/// - Reactions are de-duplicated by timestamp (same diffing the engines rely
///   on), so each event is presented exactly once; bursts queue up (capped) and
///   play back one at a time.
///
/// Drop into a `Stack` (e.g. `Positioned.fill`) on any game screen. While idle
/// it is a zero-size, non-interactive placeholder, so it never blocks the game.
class CenterReactionOverlay extends StatefulWidget {
  const CenterReactionOverlay({
    super.key,
    required this.reactions,
    this.avatarResolver,
    this.onNewReaction,
    this.displayDuration = const Duration(seconds: 3),
  });

  /// Current reaction list for the round/turn, mapped by each game into the
  /// shared [ReactionEvent] shape (emoji/token, ts, reactor userId).
  final List<ReactionEvent> reactions;

  /// Resolves a reactor's userId to their live room member (name + avatar).
  /// Typically `RoomProvider.memberById`. A miss degrades gracefully.
  final AvatarReactionResolver? avatarResolver;

  /// Fires once per newly-observed reaction (hook point for a future sound
  /// effect), at the same moment it is enqueued for display.
  final void Function(String value)? onNewReaction;

  final Duration displayDuration;

  @override
  State<CenterReactionOverlay> createState() => _CenterReactionOverlayState();
}

class _CenterReactionOverlayState extends State<CenterReactionOverlay> {
  final Set<int> _seenTs = {};
  final Queue<ReactionEvent> _queue = Queue<ReactionEvent>();
  ReactionEvent? _current;
  Timer? _timer;

  // Cap the backlog so a heavy burst can't queue a minute of playback — during
  // a pile-on the newest reactions still show; the oldest surplus is dropped.
  static const int _maxQueued = 4;

  @override
  void initState() {
    super.initState();
    // Pre-existing reactions at mount (e.g. reconnect mid-round) must not all
    // replay — only genuinely new ones after this point are presented.
    _seenTs.addAll(widget.reactions.map((r) => r.ts));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CenterReactionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The engines clear the reaction list wholesale each turn/round; when it
    // empties, forget seen timestamps so the next round's (possibly reused)
    // timestamps are treated as new.
    if (widget.reactions.isEmpty && oldWidget.reactions.isNotEmpty) {
      _seenTs.clear();
      return;
    }
    for (final r in widget.reactions) {
      if (_seenTs.add(r.ts)) {
        widget.onNewReaction?.call(r.emoji);
        _enqueue(r);
      }
    }
  }

  void _enqueue(ReactionEvent r) {
    _queue.addLast(r);
    while (_queue.length > _maxQueued) {
      _queue.removeFirst();
    }
    if (_current == null) _showNext();
  }

  void _showNext() {
    _timer?.cancel();
    if (_queue.isEmpty) {
      if (mounted) setState(() => _current = null);
      return;
    }
    final next = _queue.removeFirst();
    if (mounted) setState(() => _current = next);
    _timer = Timer(widget.displayDuration, _showNext);
  }

  void _dismiss() {
    // Tap dismisses the current one immediately and advances to any queued.
    _showNext();
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    if (current == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final member = widget.avatarResolver?.call(current.userId);
    final name = member?.displayName ?? '';
    final isAvatar = AvatarConfig.isAvatarReaction(current.emoji);

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dismiss,
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          alignment: Alignment.center,
          child: TweenAnimationBuilder<double>(
            key: ValueKey(current.ts),
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            builder: (context, t, child) => Transform.scale(
              scale: 0.6 + 0.4 * t.clamp(0.0, 1.0),
              child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAvatar)
                  UserAvatar(
                    avatarUrl: member?.avatarUrl,
                    avatarConfig: member?.avatarConfig,
                    isPremium: member?.isPremium ?? false,
                    displayName: member?.displayName,
                    avatarReactionKey:
                        AvatarConfig.avatarReactionKey(current.emoji),
                    size: 140,
                    borderWidth: 3,
                    borderColor: Colors.white,
                  )
                else if (kAnimatedEmojiMap[current.emoji] != null)
                  // Animated (Lottie) emoji — the same asset the old floating
                  // overlay used, now shown large and centered so icon
                  // reactions actually animate again.
                  AnimatedEmoji(
                    kAnimatedEmojiMap[current.emoji]!,
                    size: 120,
                    source: AnimatedEmojiSource.asset,
                    repeat: true,
                    errorWidget: Text(
                      current.emoji,
                      style: const TextStyle(fontSize: 120),
                    ),
                  )
                else
                  Text(
                    current.emoji,
                    style: const TextStyle(fontSize: 120),
                  ),
                if (name.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
