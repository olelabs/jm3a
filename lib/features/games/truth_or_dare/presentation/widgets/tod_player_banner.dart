// // import 'package:flutter/material.dart';
// // import 'package:flutter_animate/flutter_animate.dart';
// // import '../../../../../../core/extensions/context_ext.dart';
// // import '../../../../../../core/theme/app_colors.dart';

// // /// Player identity banner shown above every game screen.
// // /// Displays current player's name, turn indicator dots, and "Your turn!" pulse.
// // class TodPlayerBanner extends StatelessWidget {
// //   const TodPlayerBanner({
// //     super.key,
// //     required this.playerId,
// //     required this.playerName,
// //     required this.playerOrder,
// //     required this.isMyTurn,
// //   });

// //   final String       playerId;
// //   final String       playerName;
// //   final List<String> playerOrder;
// //   final bool         isMyTurn;

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = context.theme;
// //     final initial = playerName.isNotEmpty
// //         ? playerName[0].toUpperCase()
// //         : '?';

// //     return AnimatedContainer(
// //       duration: const Duration(milliseconds: 250),
// //       width:    double.infinity,
// //       padding:  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// //       decoration: BoxDecoration(
// //         color: isMyTurn
// //             ? AppColors.truthColor.withOpacity(0.08)
// //             : theme.colorScheme.surfaceContainerHighest,
// //         borderRadius: BorderRadius.circular(14),
// //         border: isMyTurn
// //             ? Border.all(color: AppColors.truthColor.withOpacity(0.3))
// //             : null,
// //       ),
// //       child: Row(
// //         children: [
// //           // Avatar with pulse if my turn
// //           _PlayerAvatar(initial: initial, isMyTurn: isMyTurn),
// //           const SizedBox(width: 12),

// //           // Name + label
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   isMyTurn ? '✨ Your turn!' : "It's their turn",
// //                   style: theme.textTheme.bodySmall?.copyWith(
// //                       color: isMyTurn
// //                           ? AppColors.truthColor
// //                           : theme.colorScheme.onSurfaceVariant,
// //                       fontWeight: FontWeight.w600),
// //                 ),
// //                 Text(
// //                   playerName,
// //                   style: theme.textTheme.titleSmall?.copyWith(
// //                       fontWeight: FontWeight.w700,
// //                       color: isMyTurn
// //                           ? AppColors.truthColor
// //                           : theme.colorScheme.onSurface),
// //                   maxLines: 1,
// //                   overflow: TextOverflow.ellipsis,
// //                 ),
// //               ],
// //             ),
// //           ),

// //           // Turn order dots
// //           _TurnDots(
// //             playerOrder: playerOrder,
// //             currentPlayerId: playerId,
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class _PlayerAvatar extends StatelessWidget {
// //   const _PlayerAvatar({required this.initial, required this.isMyTurn});
// //   final String initial;
// //   final bool   isMyTurn;

// //   @override
// //   Widget build(BuildContext context) {
// //     final avatar = CircleAvatar(
// //       radius: 18,
// //       backgroundColor: isMyTurn
// //           ? AppColors.truthColor
// //           : context.colorScheme.onSurfaceVariant.withOpacity(0.2),
// //       child: Text(
// //         initial,
// //         style: TextStyle(
// //             color:      isMyTurn ? Colors.white : context.colorScheme.onSurfaceVariant,
// //             fontWeight: FontWeight.w800,
// //             fontSize:   16),
// //       ),
// //     );

// //     if (!isMyTurn) return avatar;

// //     return avatar
// //         .animate(onPlay: (c) => c.repeat())
// //         .scaleXY(
// //           begin: 1.0,
// //           end:   1.1,
// //           duration: 800.ms,
// //           curve: Curves.easeInOut,
// //         )
// //         .then()
// //         .scaleXY(begin: 1.1, end: 1.0, duration: 800.ms);
// //   }
// // }

// // class _TurnDots extends StatelessWidget {
// //   const _TurnDots({
// //     required this.playerOrder,
// //     required this.currentPlayerId,
// //   });
// //   final List<String> playerOrder;
// //   final String       currentPlayerId;

// //   @override
// //   Widget build(BuildContext context) {
// //     // Show max 8 dots to avoid overflow
// //     final order = playerOrder.length > 8
// //         ? playerOrder.sublist(0, 8)
// //         : playerOrder;

// //     return Row(
// //       mainAxisSize: MainAxisSize.min,
// //       children: order.asMap().entries.map((e) {
// //         final isCurrent = e.value == currentPlayerId;
// //         return AnimatedContainer(
// //           duration: const Duration(milliseconds: 200),
// //           width:  isCurrent ? 10 : 5,
// //           height: isCurrent ? 10 : 5,
// //           margin: const EdgeInsets.only(left: 4),
// //           decoration: BoxDecoration(
// //             color:  isCurrent
// //                 ? AppColors.truthColor
// //                 : context.colorScheme.onSurfaceVariant.withOpacity(0.25),
// //             shape: BoxShape.circle,
// //           ),
// //         );
// //       }).toList(),
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import '../../../../../../core/extensions/context_ext.dart';
// import '../../../../../../core/theme/app_colors.dart';

// /// Player identity banner shown above every game screen.
// /// Displays current player's name, turn indicator dots, and "Your turn!" pulse.
// class TodPlayerBanner extends StatelessWidget {
//   const TodPlayerBanner({
//     super.key,
//     required this.playerId,
//     required this.playerName,
//     required this.playerOrder,
//     required this.isMyTurn,
//     this.onPlayerTap,
//   });

//   final String playerId;
//   final String playerName;
//   final List<String> playerOrder;
//   final bool isMyTurn;
//   final VoidCallback? onPlayerTap;

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     final initial = playerName.isNotEmpty ? playerName[0].toUpperCase() : '?';

//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 250),
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: isMyTurn
//             ? AppColors.truthColor.withOpacity(0.08)
//             : theme.colorScheme.surfaceContainerHighest,
//         borderRadius: BorderRadius.circular(14),
//         border: isMyTurn
//             ? Border.all(color: AppColors.truthColor.withOpacity(0.3))
//             : null,
//       ),
//       child: Row(
//         children: [
//           // Avatar with pulse if my turn — tap to see profile
//           GestureDetector(
//             onTap: onPlayerTap,
//             child: _PlayerAvatar(initial: initial, isMyTurn: isMyTurn),
//           ),
//           const SizedBox(width: 12),

//           // Name + label
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   isMyTurn ? '✨ Your turn!' : "It's their turn",
//                   style: theme.textTheme.bodySmall?.copyWith(
//                     color: isMyTurn
//                         ? AppColors.truthColor
//                         : theme.colorScheme.onSurfaceVariant,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 Text(
//                   playerName,
//                   style: theme.textTheme.titleSmall?.copyWith(
//                     fontWeight: FontWeight.w700,
//                     color: isMyTurn
//                         ? AppColors.truthColor
//                         : theme.colorScheme.onSurface,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),

//           // Turn order dots
//           _TurnDots(playerOrder: playerOrder, currentPlayerId: playerId),
//         ],
//       ),
//     );
//   }
// }

// class _PlayerAvatar extends StatelessWidget {
//   const _PlayerAvatar({required this.initial, required this.isMyTurn});
//   final String initial;
//   final bool isMyTurn;

//   @override
//   Widget build(BuildContext context) {
//     final avatar = CircleAvatar(
//       radius: 18,
//       backgroundColor: isMyTurn
//           ? AppColors.truthColor
//           : context.colorScheme.onSurfaceVariant.withOpacity(0.2),
//       child: Text(
//         initial,
//         style: TextStyle(
//           color: isMyTurn ? Colors.white : context.colorScheme.onSurfaceVariant,
//           fontWeight: FontWeight.w800,
//           fontSize: 16,
//         ),
//       ),
//     );

//     if (!isMyTurn) return avatar;

//     return avatar
//         .animate(onPlay: (c) => c.repeat())
//         .scaleXY(
//           begin: 1.0,
//           end: 1.1,
//           duration: 800.ms,
//           curve: Curves.easeInOut,
//         )
//         .then()
//         .scaleXY(begin: 1.1, end: 1.0, duration: 800.ms);
//   }
// }

// class _TurnDots extends StatelessWidget {
//   const _TurnDots({required this.playerOrder, required this.currentPlayerId});
//   final List<String> playerOrder;
//   final String currentPlayerId;

//   @override
//   Widget build(BuildContext context) {
//     // Show max 8 dots to avoid overflow
//     final order = playerOrder.length > 8
//         ? playerOrder.sublist(0, 8)
//         : playerOrder;

//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: order.asMap().entries.map((e) {
//         final isCurrent = e.value == currentPlayerId;
//         return AnimatedContainer(
//           duration: const Duration(milliseconds: 200),
//           width: isCurrent ? 10 : 5,
//           height: isCurrent ? 10 : 5,
//           margin: const EdgeInsets.only(left: 4),
//           decoration: BoxDecoration(
//             color: isCurrent
//                 ? AppColors.truthColor
//                 : context.colorScheme.onSurfaceVariant.withOpacity(0.25),
//             shape: BoxShape.circle,
//           ),
//         );
//       }).toList(),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../../core/extensions/context_ext.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../shared/widgets/cards/honesty_score_line.dart';
import '../../../../../../shared/widgets/cards/user_avatar.dart';

class TodPlayerBanner extends StatelessWidget {
  const TodPlayerBanner({
    super.key,
    required this.playerId,
    required this.playerName,
    required this.playerOrder,
    required this.isMyTurn,
    this.onPlayerTap,
    this.avatarConfig,
    this.avatarUrl,
    this.isPremium = false,
    this.honestyPoints,
    this.generalScore,
  });

  final String playerId;
  final String playerName;
  final List<String> playerOrder;
  final bool isMyTurn;
  final VoidCallback? onPlayerTap;
  final Map<String, dynamic>? avatarConfig;
  final String? avatarUrl;
  final bool isPremium;

  /// Live values from RoomProvider.members (the single shared source of
  /// truth also used by the lobby — see MemberTile) — null while the
  /// current player isn't resolvable from that list yet, in which case
  /// the stat row is simply omitted rather than showing a fabricated 0.
  final int? honestyPoints;
  final int? generalScore;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final banner = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMyTurn
            ? AppColors.truthColor.withOpacity(0.08)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: isMyTurn
            ? Border.all(color: AppColors.truthColor.withOpacity(0.3))
            : null,
        boxShadow: isMyTurn
            ? [
                BoxShadow(
                  color: AppColors.truthColor.withOpacity(0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPlayerTap,
            child: _PlayerAvatar(
              playerName: playerName,
              isMyTurn: isMyTurn,
              avatarUrl: avatarUrl,
              avatarConfig: avatarConfig,
              isPremium: isPremium,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMyTurn)
                  Container(
                    margin: const EdgeInsets.only(bottom: 3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.truthColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      context.l10n.todYourTurnBadge,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  )
                else
                  Text(
                    context.l10n.todTheirTurn,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  playerName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isMyTurn
                        ? AppColors.truthColor
                        : theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (honestyPoints != null && generalScore != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: HonestyScoreLine(
                      honestyPoints: honestyPoints!,
                      generalScore: generalScore!,
                      iconSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          _TurnDots(playerOrder: playerOrder, currentPlayerId: playerId),
        ],
      ),
    );

    // Own subtle entrance separate from the outer phase transition — a
    // small pop/slide whenever this banner is rebuilt for a new turn, since
    // it's the primary "whose turn is it" signal.
    return banner
        .animate()
        .fadeIn(duration: 220.ms)
        .slideY(begin: -0.08, end: 0, duration: 220.ms, curve: Curves.easeOut);
  }
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({
    required this.playerName,
    required this.isMyTurn,
    this.avatarUrl,
    this.avatarConfig,
    this.isPremium = false,
  });
  final String playerName;
  final bool isMyTurn;
  final String? avatarUrl;
  final Map<String, dynamic>? avatarConfig;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final avatar = UserAvatar(
      size: 36,
      displayName: playerName,
      avatarUrl: avatarUrl,
      avatarConfig: avatarConfig,
      isPremium: isPremium,
      borderWidth: isMyTurn ? 2 : 0,
      borderColor: AppColors.truthColor,
    );

    if (!isMyTurn) return avatar;

    // Soft ambient glow ring behind the active player's avatar, on top of
    // the existing pulse — makes "whose turn" readable at a glance even
    // before the eye lands on the name text.
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.truthColor.withOpacity(0.45),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: avatar
          .animate(onPlay: (c) => c.repeat())
          .scaleXY(
            begin: 1.0,
            end: 1.08,
            duration: 800.ms,
            curve: Curves.easeInOut,
          )
          .then()
          .scaleXY(begin: 1.08, end: 1.0, duration: 800.ms),
    );
  }
}

class _TurnDots extends StatelessWidget {
  const _TurnDots({required this.playerOrder, required this.currentPlayerId});
  final List<String> playerOrder;
  final String currentPlayerId;

  @override
  Widget build(BuildContext context) {
    final order = playerOrder.length > 8
        ? playerOrder.sublist(0, 8)
        : playerOrder;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: order.asMap().entries.map((e) {
        final isCurrent = e.value == currentPlayerId;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isCurrent ? 10 : 5,
          height: isCurrent ? 10 : 5,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: isCurrent
                ? AppColors.truthColor
                : context.colorScheme.onSurfaceVariant.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }
}
