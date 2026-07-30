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
  });

  final String playerId;
  final String playerName;
  final List<String> playerOrder;
  final bool isMyTurn;
  final VoidCallback? onPlayerTap;
  final Map<String, dynamic>? avatarConfig;
  final String? avatarUrl;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return AnimatedContainer(
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
                Text(
                  isMyTurn ? '✨ Your turn!' : "It's their turn",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isMyTurn
                        ? AppColors.truthColor
                        : theme.colorScheme.onSurfaceVariant,
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
              ],
            ),
          ),
          _TurnDots(playerOrder: playerOrder, currentPlayerId: playerId),
        ],
      ),
    );
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

    return avatar
        .animate(onPlay: (c) => c.repeat())
        .scaleXY(
          begin: 1.0,
          end: 1.08,
          duration: 800.ms,
          curve: Curves.easeInOut,
        )
        .then()
        .scaleXY(begin: 1.08, end: 1.0, duration: 800.ms);
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
