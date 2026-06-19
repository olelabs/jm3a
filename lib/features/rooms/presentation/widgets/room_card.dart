import 'package:flutter/material.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/cards/j_card.dart';
import '../../../../shared/widgets/cards/user_avatar.dart';
import '../../domain/room_entity.dart';

class RoomCard extends StatelessWidget {
  const RoomCard({super.key, required this.room, required this.onTap});
  final RoomEntity room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme  = context.theme;
    final l10n   = context.l10n;
    final isFull = room.isFull;

    return Opacity(
      opacity: isFull ? 0.55 : 1.0,
      child: JCard(
        onTap: isFull ? null : onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Emoji avatar
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _gameColor(room.gameType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(room.coverEmoji,
                    style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + privacy icon
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (room.isPrivate)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(Icons.lock_outline_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _StatusBadge(status: room.status),
                      const SizedBox(width: 8),
                      Icon(Icons.people_outline_rounded,
                          size: 13,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text(
                        l10n.roomsPlayers(room.currentPlayers, room.maxPlayers),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      if (room.gameType != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _gameEmoji(room.gameType),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Join indicator
            const SizedBox(width: 8),
            if (!isFull)
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant)
            else
              Text(context.l10n.roomsFull,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Color _gameColor(dynamic gt) => switch (gt?.toString()) {
    'GameType.truthOrDare'    => AppColors.truthColor,
    'GameType.neverHaveIEver' => AppColors.tealGreen,
    'GameType.memeGame'       => AppColors.purple,
    _                         => AppColors.navyBlue,
  };

  String _gameEmoji(dynamic gt) => switch (gt?.toString()) {
    'GameType.truthOrDare'    => '🎯',
    'GameType.neverHaveIEver' => '🍹',
    'GameType.memeGame'       => '😂',
    _                         => '',
  };
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final RoomStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      RoomStatus.waiting  => ('Waiting', AppColors.successGreen),
      RoomStatus.inGame   => ('In Game', AppColors.amberOrangeLight),
      RoomStatus.paused   => ('Paused',  AppColors.warningAmber),
      _                   => ('Closed',  AppColors.textTertiaryLight),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
