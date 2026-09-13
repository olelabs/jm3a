import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/cards/user_avatar.dart';
import '../../../games/engine/base_game_engine.dart';

/// Item 5 (room share pass) — the actual, real data a share card can show
/// without fabricating anything: room identity, the ONE game/pack this
/// room is actually configured for (RoomEntity.gameType/packId — a room
/// has exactly one, never a list, so this never invents a multi-game
/// carousel), and the inviter's OWN already-visible identity/stats
/// (RoomMemberEntity — the same data every other in-room UI already
/// shows for them, see HonestyScoreLine). No user id/UUID is ever passed
/// through here — only display-facing fields.
class RoomShareCardData {
  const RoomShareCardData({
    required this.roomName,
    required this.coverEmoji,
    required this.maxPlayers,
    this.gameType,
    this.packName,
    required this.inviterDisplayName,
    this.inviterAvatarUrl,
    this.inviterAvatarConfig,
    this.inviterIsPremium = false,
    required this.inviterHonestyPoints,
    required this.inviterGeneralScore,
  });

  final String roomName;
  final String coverEmoji;
  final int maxPlayers;

  /// Null when the room genuinely has no game type set yet (a brand-new
  /// room before the owner picks one) — the card simply omits the game
  /// pill rather than guessing/defaulting to one, per this task's own
  /// "do not fabricate data" instruction.
  final GameType? gameType;
  final String? packName;

  final String inviterDisplayName;
  final String? inviterAvatarUrl;
  final Map<String, dynamic>? inviterAvatarConfig;
  final bool inviterIsPremium;
  final int inviterHonestyPoints;
  final int inviterGeneralScore;
}

String _gameTypeEmoji(GameType type) => switch (type) {
  GameType.truthOrDare => '🎯',
  GameType.neverHaveIEver => '🙋',
  GameType.memeGame => '😂',
};

String _gameTypeName(BuildContext context, GameType type) => switch (type) {
  GameType.truthOrDare => context.l10n.gameNameTruthOrDare,
  GameType.neverHaveIEver => context.l10n.gameNameNeverHaveIEver,
  GameType.memeGame => context.l10n.gameNameMeme,
};

/// A compact circular stat badge ("◉ 1,420") — same iconography as
/// [HonestyScoreLine] (Icons.handshake_rounded / Icons.star_rounded), just
/// rendered as a self-contained circular chip instead of an inline
/// identity-adjacent text row, per item 5's "circular score/honesty
/// indicators" visual direction.
class _CircularStat extends StatelessWidget {
  const _CircularStat({
    required this.icon,
    required this.value,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final String value;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.16),
            border: Border.all(
              color: color.withValues(alpha: 0.55),
              width: 1.5,
            ),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// A small pill badge for the game/pack row ("○ Truth or Dare").
class _GamePill extends StatelessWidget {
  const _GamePill({required this.emoji, required this.label});
  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The actual room-invite share card — a premium, dark, circular-forward
/// "Apple Watch app card" visual language (see item 5's own wireframe):
/// a large circular room-icon badge, the room's real name/player limit,
/// its one real game (+ pack, if any), then a compact inviter identity
/// strip (circular avatar + name + two circular stat badges), and a
/// closing call-to-action line. Every value comes from [data] — nothing
/// here is invented or hardcoded.
///
/// Fixed-size (not responsive) by design: this widget is only ever
/// rendered off-screen for RepaintBoundary capture (see
/// captureRoomShareCard below), never shown live in the app's own UI, so
/// it always renders at the exact same on-image pixel dimensions
/// regardless of the sharing device's actual screen size.
class RoomShareCard extends StatelessWidget {
  const RoomShareCard({super.key, required this.data});

  final RoomShareCardData data;

  static const double cardWidth = 360;
  static const double cardHeight = 620;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.brandPurpleDark,
              Color(0xFF1B1140),
              AppColors.brandBlueDark,
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Room icon — circular, matching the inviter avatar below so
            // both "identities" (the room, the inviter) read the same
            // visual language.
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    data.coverEmoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              data.roomName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.roomShareMaxPlayers(data.maxPlayers),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (data.gameType != null)
                    _GamePill(
                      emoji: _gameTypeEmoji(data.gameType!),
                      label: _gameTypeName(context, data.gameType!),
                    ),
                  if (data.packName != null && data.packName!.isNotEmpty)
                    _GamePill(emoji: '📦', label: data.packName!),
                ],
              ),
            ),
            const Spacer(),
            Divider(color: Colors.white.withValues(alpha: 0.14), height: 1),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonPink.withValues(alpha: 0.35),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: UserAvatar(
                    avatarUrl: data.inviterAvatarUrl,
                    avatarConfig: data.inviterAvatarConfig,
                    isPremium: data.inviterIsPremium,
                    displayName: data.inviterDisplayName,
                    size: 48,
                    borderWidth: 2,
                    borderColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.roomShareInvitedBy,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        data.inviterDisplayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CircularStat(
                  icon: Icons.star_rounded,
                  value: '${data.inviterGeneralScore}',
                  color: AppColors.warningAmber,
                  label: context.l10n.roomShareScoreLabel,
                ),
                _CircularStat(
                  icon: Icons.handshake_rounded,
                  value:
                      '${data.inviterHonestyPoints > 0 ? '+' : ''}${data.inviterHonestyPoints}',
                  color: data.inviterHonestyPoints < 0
                      ? AppColors.dareRed
                      : AppColors.nhieGreen,
                  label: context.l10n.roomShareHonestyLabel,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                context.l10n.roomShareJoinCta,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.brandPurpleDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders [RoomShareCard] off-screen and captures it as PNG bytes — a
/// fully client-side "share preview image" (see this pass's own report
/// for why this, not a server-generated Open-Graph/link-unfurl preview,
/// is what's actually achievable without web/backend infrastructure this
/// project doesn't have). Uses a real [Overlay] entry (not a detached
/// widget tree) so network images (the inviter's avatar) actually
/// resolve — a completely detached render object tree never receives
/// image-decode callbacks. Waits a short, fixed settle window for that
/// avatar fetch to finish before capturing; best-effort (see doc comment
/// on the wait duration below), not a guaranteed image-load barrier.
Future<Uint8List?> captureRoomShareCard(
  BuildContext context,
  RoomShareCardData data,
) async {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return null;

  final boundaryKey = GlobalKey();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      // Off-screen, but still LAID OUT/PAINTED (unlike Offstage, which
      // skips painting entirely) — RepaintBoundary needs an actual paint
      // pass to have anything to capture.
      left: -RoomShareCard.cardWidth - 100,
      top: 0,
      child: RepaintBoundary(
        key: boundaryKey,
        child: RoomShareCard(data: data),
      ),
    ),
  );

  overlay.insert(entry);
  try {
    // Best-effort network-image settle window — long enough for a
    // same-region avatar fetch in the common case, short enough not to
    // stall the share sheet noticeably. UserAvatar's own initials
    // fallback still renders correctly either way if this isn't enough
    // time (never a broken-image icon), so this is a quality trade-off,
    // not a correctness one.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final renderObject = boundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;
    final image = await renderObject.toImage(pixelRatio: 2.5);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  } finally {
    entry.remove();
  }
}
