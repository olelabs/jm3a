import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/friends/presentation/friends_provider.dart';
import '../../../features/friends/presentation/screens/user_profile_screen.dart';
import '../../../features/rooms/domain/room_entity.dart';
import 'user_avatar.dart';

/// Compact player-profile preview — shown from a game reaction/player tap.
/// A circular avatar as the focal point with small round score/streak/
/// honesty badges around it, then the name below.
///
/// Score and honesty come straight from [member] — [RoomMemberEntity]
/// already carries live, server-authoritative `generalScore`/
/// `honestyPoints` (see RoomProvider's profiles-CDC extension), so
/// showing them here needs no extra fetch. Streak is NOT on
/// [RoomMemberEntity] (it isn't part of the room-membership live stream),
/// so this widget makes exactly one additional call —
/// `FriendsProvider.getSocialProfile`, the same authoritative source
/// UserProfileScreen already uses for another user's streak — and reveals
/// the streak badge only once that resolves to a value greater than 0.
/// Never invents/recomputes any of these three values.
class PlayerProfileCard extends StatefulWidget {
  const PlayerProfileCard({super.key, required this.member});

  final RoomMemberEntity member;

  @override
  State<PlayerProfileCard> createState() => _PlayerProfileCardState();
}

class _PlayerProfileCardState extends State<PlayerProfileCard> {
  int? _currentStreak;

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    try {
      final profile = await context.read<FriendsProvider>().getSocialProfile(
        widget.member.userId,
      );
      if (!mounted || profile == null) return;
      setState(() => _currentStreak = profile.currentStreak);
    } catch (_) {
      // Streak is a nice-to-have enhancement on top of the always-available
      // member data — a failed fetch just means the badge never appears,
      // never a broken card.
    }
  }

  void _openFullProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: widget.member.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final theme = context.theme;
    final streak = _currentStreak;

    return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _openFullProfile,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AvatarWithBadges(member: member, streak: streak),
                  const SizedBox(height: 14),
                  Text(
                    member.displayName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 200.ms)
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          duration: 220.ms,
          curve: Curves.easeOutBack,
        );
  }
}

class _AvatarWithBadges extends StatelessWidget {
  const _AvatarWithBadges({required this.member, required this.streak});

  final RoomMemberEntity member;
  final int? streak;

  static const double _avatarSize = 88;
  // Fixed box the avatar + its surrounding badges lay out within — large
  // enough for a badge to sit half-overlapping the avatar's edge on every
  // side without ever being clipped, small enough to stay balanced next
  // to the name below it. Independent of the caller's own screen size —
  // the CALLER (a bottom sheet/dialog) is what adapts to different phone
  // sizes; this fixed-size composition just avoids overflowing whatever
  // space it's given.
  static const double _boxSize = 132;

  @override
  Widget build(BuildContext context) {
    final showStreak = (streak ?? 0) > 0;
    return SizedBox(
      width: _boxSize,
      height: _boxSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          UserAvatar(
            avatarUrl: member.avatarUrl,
            avatarConfig: member.avatarConfig,
            isPremium: member.isPremium,
            displayName: member.displayName,
            size: _avatarSize,
            borderWidth: 3,
            borderColor: Theme.of(context).colorScheme.surface,
          ),
          // Score — top-left, existing star convention (see
          // HonestyScoreLine/shared/widgets/cards).
          Positioned(
            top: 4,
            left: 0,
            child: _RoundStatBadge(
              icon: Icons.star_rounded,
              color: AppColors.amberOrangeLight,
              label: context.l10n.profileScore,
              value: '${member.generalScore}',
            ),
          ),
          // Honesty — bottom-right, existing handshake + sign-color
          // convention (see HonestyScoreLine/_HonestyStatBadge).
          Positioned(
            bottom: 4,
            right: 0,
            child: _RoundStatBadge(
              icon: Icons.handshake_rounded,
              color: member.honestyPoints < 0
                  ? AppColors.dareRed
                  : member.honestyPoints == 0
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : AppColors.nhieGreen,
              label: context.l10n.profileHonestyPoints,
              value:
                  '${member.honestyPoints > 0 ? '+' : ''}${member.honestyPoints}',
            ),
          ),
          // Streak — top-right, only when the player actually has one (see
          // class doc comment) — never a fake "0 streak" badge.
          if (showStreak)
            Positioned(
              top: 4,
              right: 6,
              child: _RoundStatBadge(
                emoji: '🔥',
                color: AppColors.amberOrangeLight,
                label: context.l10n.profileStreakDays(streak!),
                value: '$streak',
              ),
            ),
        ],
      ),
    );
  }
}

/// Small round icon+value badge — a compact variant of the same
/// score/honesty visual language HonestyScoreLine already establishes for
/// in-game player UI, just circular instead of an inline row so several
/// can sit around the avatar without crowding it. Tapping/long-pressing
/// isn't needed here: [label] is exposed via [Semantics]/[Tooltip] so the
/// badge stays meaningful without a text caption competing for space.
class _RoundStatBadge extends StatelessWidget {
  const _RoundStatBadge({
    this.icon,
    this.emoji,
    required this.color,
    required this.label,
    required this.value,
  }) : assert(
         icon != null || emoji != null,
         'a badge needs either a Material icon or an emoji glyph',
       );

  final IconData? icon;
  final String? emoji;
  final Color color;
  final String label;
  final String value;

  static const double _size = 36;

  @override
  Widget build(BuildContext context) {
    // The value is shown visibly (small, under the icon), not only via
    // Tooltip — a tooltip needs a long-press to discover on a touch
    // device, which would leave the badge's actual number effectively
    // hidden for most players. Semantics still carries the same "label:
    // value" pair for screen readers.
    return Semantics(
      label: '$label: $value',
      child: Tooltip(
        message: '$label: $value',
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              icon != null
                  ? Icon(icon, size: 13, color: color)
                  : Text(emoji!, style: const TextStyle(fontSize: 11)),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
