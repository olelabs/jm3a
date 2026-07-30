// // // import 'package:flutter/material.dart';

// // // /// Image stickers — add PNG files to assets/images/stickers/ and list paths here.
// // // const kStickerAssets = <String>[
// // //   'assets/images/stickers/sticker_01.jpg',
// // //   'assets/images/stickers/sticker_02.jpg',
// // //   'assets/images/stickers/sticker_03.jpg',
// // //   'assets/images/stickers/sticker_04.jpg',
// // //   'assets/images/stickers/sticker_05.jpg',
// // //   'assets/images/stickers/sticker_06.jpg',
// // //   'assets/images/stickers/sticker_07.jpg',
// // //   'assets/images/stickers/sticker_08.jpg',
// // //   'assets/images/stickers/sticker_09.jpg',
// // //   'assets/images/stickers/sticker_10.jpg',
// // //   'assets/images/stickers/sticker_11.jpg',
// // //   'assets/images/stickers/sticker_12.jpg',
// // // ];

// // // /// Emoji reactions — players react to others' responses
// // // const kEmojiReactions = [
// // //   '😂',
// // //   '🔥',
// // //   '💀',
// // //   '👏',
// // //   '🤣',
// // //   '😭',
// // //   '🫡',
// // //   '💯',
// // //   '🤯',
// // //   '👑',
// // //   '😤',
// // //   '🥹',
// // //   '🫶',
// // //   '💅',
// // //   '🙈',
// // //   '😎',
// // //   '🤡',
// // //   '💔',
// // //   '🎉',
// // //   '😈',
// // // ];

// // // /// Sticker widget — shows image if exists, falls back to index number
// // // class StickerImage extends StatelessWidget {
// // //   const StickerImage({
// // //     super.key,
// // //     required this.assetPath,
// // //     this.size = 60,
// // //     this.selected = false,
// // //     this.onTap,
// // //   });

// // //   final String assetPath;
// // //   final double size;
// // //   final bool selected;
// // //   final VoidCallback? onTap;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = Theme.of(context);
// // //     return GestureDetector(
// // //       onTap: onTap,
// // //       child: AnimatedContainer(
// // //         duration: const Duration(milliseconds: 150),
// // //         width: size,
// // //         height: size,
// // //         decoration: BoxDecoration(
// // //           color: selected
// // //               ? theme.colorScheme.primaryContainer
// // //               : theme.colorScheme.surfaceContainerHighest,
// // //           borderRadius: BorderRadius.circular(10),
// // //           border: selected
// // //               ? Border.all(color: theme.colorScheme.primary, width: 2.5)
// // //               : null,
// // //         ),
// // //         child: ClipRRect(
// // //           borderRadius: BorderRadius.circular(selected ? 8 : 10),
// // //           child: assetPath.startsWith('http')
// // //               ? Image.network(
// // //                   assetPath,
// // //                   fit: BoxFit.cover,
// // //                   errorBuilder: (_, __, ___) => Center(
// // //                     child: Icon(
// // //                       Icons.image_not_supported_outlined,
// // //                       size: size * 0.4,
// // //                     ),
// // //                   ),
// // //                 )
// // //               : Image.asset(
// // //                   assetPath,
// // //                   fit: BoxFit.cover,
// // //                   errorBuilder: (_, __, ___) {
// // //                     final idx = kStickerAssets.indexOf(assetPath) + 1;
// // //                     return Center(
// // //                       child: Text(
// // //                         '🎭$idx',
// // //                         style: TextStyle(fontSize: size * 0.4),
// // //                       ),
// // //                     );
// // //                   },
// // //                 ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // /// Full sticker grid for picking a sticker
// // // class StickerPicker extends StatelessWidget {
// // //   const StickerPicker({
// // //     super.key,
// // //     required this.selected,
// // //     required this.onSelect,
// // //     this.stickerSize = 64,
// // //     this.customUrls,
// // //   });

// // //   final String? selected;
// // //   final ValueChanged<String> onSelect;
// // //   final double stickerSize;
// // //   final List<String>? customUrls; // custom pack reactions (URLs)

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final items = customUrls ?? kStickerAssets;
// // //     return GridView.builder(
// // //       shrinkWrap: true,
// // //       physics: const NeverScrollableScrollPhysics(),
// // //       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
// // //         crossAxisCount: 4,
// // //         mainAxisSpacing: 10,
// // //         crossAxisSpacing: 10,
// // //         childAspectRatio: 1,
// // //       ),
// // //       itemCount: items.length,
// // //       itemBuilder: (_, i) {
// // //         final path = items[i];
// // //         return StickerImage(
// // //           assetPath: path,
// // //           size: stickerSize,
// // //           selected: selected == path,
// // //           onTap: () => onSelect(selected == path ? '' : path),
// // //         );
// // //       },
// // //     );
// // //   }
// // // }

// // // /// Small sticker display (in submissions, history, etc.)
// // // class StickerDisplay extends StatelessWidget {
// // //   const StickerDisplay({super.key, required this.assetPath, this.size = 56});
// // //   final String assetPath;
// // //   final double size;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return StickerImage(assetPath: assetPath, size: size);
// // //   }
// // // }

// // // /// Emoji reaction row — shows tally + picker
// // // class EmojiReactionRow extends StatelessWidget {
// // //   const EmojiReactionRow({
// // //     super.key,
// // //     required this.reactionsByEmoji, // emoji -> count
// // //     required this.alreadyReacted,
// // //     required this.onReact,
// // //   });

// // //   final Map<String, int> reactionsByEmoji;
// // //   final bool alreadyReacted;
// // //   final ValueChanged<String> onReact;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = Theme.of(context);
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         // Tally row
// // //         if (reactionsByEmoji.isNotEmpty)
// // //           Wrap(
// // //             spacing: 6,
// // //             runSpacing: 4,
// // //             children: reactionsByEmoji.entries
// // //                 .map(
// // //                   (e) => Container(
// // //                     padding: const EdgeInsets.symmetric(
// // //                       horizontal: 8,
// // //                       vertical: 4,
// // //                     ),
// // //                     decoration: BoxDecoration(
// // //                       color: theme.colorScheme.surfaceContainerHighest,
// // //                       borderRadius: BorderRadius.circular(20),
// // //                     ),
// // //                     child: Text(
// // //                       '${e.key} ${e.value}',
// // //                       style: const TextStyle(fontSize: 14),
// // //                     ),
// // //                   ),
// // //                 )
// // //                 .toList(),
// // //           ),

// // //         // Picker (only if not yet reacted)
// // //         if (!alreadyReacted) ...[
// // //           if (reactionsByEmoji.isNotEmpty) const SizedBox(height: 6),
// // //           SizedBox(
// // //             height: 38,
// // //             child: ListView(
// // //               scrollDirection: Axis.horizontal,
// // //               children: kEmojiReactions
// // //                   .map(
// // //                     (s) => Padding(
// // //                       padding: const EdgeInsets.only(right: 4),
// // //                       child: InkWell(
// // //                         borderRadius: BorderRadius.circular(6),
// // //                         onTap: () => onReact(s),
// // //                         child: Container(
// // //                           width: 34,
// // //                           height: 34,
// // //                           alignment: Alignment.center,
// // //                           decoration: BoxDecoration(
// // //                             color: theme.colorScheme.surfaceContainerHighest,
// // //                             borderRadius: BorderRadius.circular(6),
// // //                           ),
// // //                           child: Text(s, style: const TextStyle(fontSize: 18)),
// // //                         ),
// // //                       ),
// // //                     ),
// // //                   )
// // //                   .toList(),
// // //             ),
// // //           ),
// // //         ],
// // //       ],
// // //     );
// // //   }
// // // }

// // import 'package:flutter/material.dart';

// // /// Image stickers — add PNG files to assets/images/stickers/ and list paths here.
// // const kStickerAssets = <String>[
// //   'assets/images/stickers/sticker_01.jpg',
// //   'assets/images/stickers/sticker_02.jpg',
// //   'assets/images/stickers/sticker_03.jpg',
// //   'assets/images/stickers/sticker_04.jpg',
// //   'assets/images/stickers/sticker_05.jpg',
// //   'assets/images/stickers/sticker_06.jpg',
// //   'assets/images/stickers/sticker_07.jpg',
// //   'assets/images/stickers/sticker_08.jpg',
// //   'assets/images/stickers/sticker_09.jpg',
// //   'assets/images/stickers/sticker_10.jpg',
// //   'assets/images/stickers/sticker_11.jpg',
// //   'assets/images/stickers/sticker_12.jpg',
// // ];

// // /// Emoji reactions — players react to others' responses
// // const kEmojiReactions = [
// //   '😂',
// //   '🔥',
// //   '💀',
// //   '👏',
// //   '🤣',
// //   '😭',
// //   '🫡',
// //   '💯',
// //   '🤯',
// //   '👑',
// //   '😤',
// //   '🥹',
// //   '🫶',
// //   '💅',
// //   '🙈',
// //   '😎',
// //   '🤡',
// //   '💔',
// //   '🎉',
// //   '😈',
// // ];

// // /// Sticker widget — shows image if exists, falls back to index number
// // class StickerImage extends StatelessWidget {
// //   const StickerImage({
// //     super.key,
// //     required this.assetPath,
// //     this.size = 60,
// //     this.selected = false,
// //     this.onTap,
// //   });

// //   final String assetPath;
// //   final double size;
// //   final bool selected;
// //   final VoidCallback? onTap;

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = Theme.of(context);
// //     return GestureDetector(
// //       onTap: onTap,
// //       child: AnimatedContainer(
// //         duration: const Duration(milliseconds: 150),
// //         width: size,
// //         height: size,
// //         decoration: BoxDecoration(
// //           color: selected
// //               ? theme.colorScheme.primaryContainer
// //               : theme.colorScheme.surfaceContainerHighest,
// //           borderRadius: BorderRadius.circular(10),
// //           border: selected
// //               ? Border.all(color: theme.colorScheme.primary, width: 2.5)
// //               : null,
// //         ),
// //         child: ClipRRect(
// //           borderRadius: BorderRadius.circular(selected ? 8 : 10),
// //           child: assetPath.startsWith('http')
// //               ? Image.network(
// //                   assetPath,
// //                   fit: BoxFit.cover,
// //                   errorBuilder: (_, __, ___) => Center(
// //                     child: Icon(
// //                       Icons.image_not_supported_outlined,
// //                       size: size * 0.4,
// //                     ),
// //                   ),
// //                 )
// //               : Image.asset(
// //                   assetPath,
// //                   fit: BoxFit.cover,
// //                   errorBuilder: (_, __, ___) {
// //                     final idx = kStickerAssets.indexOf(assetPath) + 1;
// //                     return Center(
// //                       child: Text(
// //                         '🎭$idx',
// //                         style: TextStyle(fontSize: size * 0.4),
// //                       ),
// //                     );
// //                   },
// //                 ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// // /// Full sticker grid for picking a sticker
// // class StickerPicker extends StatelessWidget {
// //   const StickerPicker({
// //     super.key,
// //     required this.selected,
// //     required this.onSelect,
// //     this.stickerSize = 64,
// //     this.customUrls,
// //   });

// //   final String? selected;
// //   final ValueChanged<String> onSelect;
// //   final double stickerSize;
// //   final List<String>? customUrls; // custom pack reactions (URLs)

// //   @override
// //   Widget build(BuildContext context) {
// //     final items = customUrls ?? kStickerAssets;
// //     return GridView.builder(
// //       shrinkWrap: true,
// //       physics: const NeverScrollableScrollPhysics(),
// //       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
// //         crossAxisCount: 4,
// //         mainAxisSpacing: 10,
// //         crossAxisSpacing: 10,
// //         childAspectRatio: 1,
// //       ),
// //       itemCount: items.length,
// //       itemBuilder: (_, i) {
// //         final path = items[i];
// //         return StickerImage(
// //           assetPath: path,
// //           size: stickerSize,
// //           selected: selected == path,
// //           onTap: () => onSelect(selected == path ? '' : path),
// //         );
// //       },
// //     );
// //   }
// // }

// // /// Small sticker display (in submissions, history, etc.)
// // class StickerDisplay extends StatelessWidget {
// //   const StickerDisplay({super.key, required this.assetPath, this.size = 56});
// //   final String assetPath;
// //   final double size;

// //   @override
// //   Widget build(BuildContext context) {
// //     return StickerImage(assetPath: assetPath, size: size);
// //   }
// // }

// // /// Emoji reaction row — shows tally + picker
// // class EmojiReactionRow extends StatelessWidget {
// //   const EmojiReactionRow({
// //     super.key,
// //     required this.reactionsByEmoji, // emoji -> count
// //     required this.alreadyReacted,
// //     required this.onReact,
// //   });

// //   final Map<String, int> reactionsByEmoji;
// //   final bool alreadyReacted;
// //   final ValueChanged<String> onReact;

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = Theme.of(context);
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         // Tally row
// //         if (reactionsByEmoji.isNotEmpty)
// //           Wrap(
// //             spacing: 6,
// //             runSpacing: 4,
// //             children: reactionsByEmoji.entries
// //                 .map(
// //                   (e) => Container(
// //                     padding: const EdgeInsets.symmetric(
// //                       horizontal: 8,
// //                       vertical: 4,
// //                     ),
// //                     decoration: BoxDecoration(
// //                       color: theme.colorScheme.surfaceContainerHighest,
// //                       borderRadius: BorderRadius.circular(20),
// //                     ),
// //                     child: Text(
// //                       '${e.key} ${e.value}',
// //                       style: const TextStyle(fontSize: 14),
// //                     ),
// //                   ),
// //                 )
// //                 .toList(),
// //           ),

// //         // Picker (only if not yet reacted)
// //         if (!alreadyReacted) ...[
// //           if (reactionsByEmoji.isNotEmpty) const SizedBox(height: 6),
// //           SizedBox(
// //             height: 38,
// //             child: ListView(
// //               scrollDirection: Axis.horizontal,
// //               children: kEmojiReactions
// //                   .map(
// //                     (s) => Padding(
// //                       padding: const EdgeInsets.only(right: 4),
// //                       child: InkWell(
// //                         borderRadius: BorderRadius.circular(6),
// //                         onTap: () => onReact(s),
// //                         child: Container(
// //                           width: 34,
// //                           height: 34,
// //                           alignment: Alignment.center,
// //                           decoration: BoxDecoration(
// //                             color: theme.colorScheme.surfaceContainerHighest,
// //                             borderRadius: BorderRadius.circular(6),
// //                           ),
// //                           child: Text(s, style: const TextStyle(fontSize: 18)),
// //                         ),
// //                       ),
// //                     ),
// //                   )
// //                   .toList(),
// //             ),
// //           ),
// //         ],
// //       ],
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';

// import 'features/avatar/presentation/avatar_creator_screen.dart';

// const kStickerAssets = <String>[
//   'assets/images/stickers/sticker_01.jpg',
//   'assets/images/stickers/sticker_02.jpg',
//   'assets/images/stickers/sticker_03.jpg',
//   'assets/images/stickers/sticker_04.jpg',
//   'assets/images/stickers/sticker_05.jpg',
//   'assets/images/stickers/sticker_06.jpg',
//   'assets/images/stickers/sticker_07.jpg',
//   'assets/images/stickers/sticker_08.jpg',
//   'assets/images/stickers/sticker_09.jpg',
//   'assets/images/stickers/sticker_10.jpg',
//   'assets/images/stickers/sticker_11.jpg',
//   'assets/images/stickers/sticker_12.jpg',
// ];

// const kEmojiReactions = [
//   '😂',
//   '🔥',
//   '💀',
//   '👏',
//   '🤣',
//   '😭',
//   '🫡',
//   '💯',
//   '🤯',
//   '👑',
//   '😤',
//   '🥹',
//   '🫶',
//   '💅',
//   '🙈',
//   '😎',
//   '🤡',
//   '💔',
//   '🎉',
//   '😈',
// ];

// class StickerImage extends StatelessWidget {
//   const StickerImage({
//     super.key,
//     required this.assetPath,
//     this.size = 60,
//     this.selected = false,
//     this.onTap,
//   });

//   final String assetPath;
//   final double size;
//   final bool selected;
//   final VoidCallback? onTap;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 150),
//         width: size,
//         height: size,
//         decoration: BoxDecoration(
//           color: selected
//               ? theme.colorScheme.primaryContainer
//               : theme.colorScheme.surfaceContainerHighest,
//           borderRadius: BorderRadius.circular(10),
//           border: selected
//               ? Border.all(color: theme.colorScheme.primary, width: 2.5)
//               : null,
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(selected ? 8 : 10),
//           child: assetPath.startsWith('http')
//               ? Image.network(
//                   assetPath,
//                   fit: BoxFit.cover,
//                   errorBuilder: (_, __, ___) => Center(
//                     child: Icon(
//                       Icons.image_not_supported_outlined,
//                       size: size * 0.4,
//                     ),
//                   ),
//                 )
//               : Image.asset(
//                   assetPath,
//                   fit: BoxFit.cover,
//                   errorBuilder: (_, __, ___) {
//                     final idx = kStickerAssets.indexOf(assetPath) + 1;
//                     return Center(
//                       child: Text(
//                         '🎭$idx',
//                         style: TextStyle(fontSize: size * 0.4),
//                       ),
//                     );
//                   },
//                 ),
//         ),
//       ),
//     );
//   }
// }

// class StickerPicker extends StatelessWidget {
//   const StickerPicker({
//     super.key,
//     required this.selected,
//     required this.onSelect,
//     this.stickerSize = 64,
//     this.customUrls,
//   });

//   final String? selected;
//   final ValueChanged<String> onSelect;
//   final double stickerSize;
//   final List<String>? customUrls;

//   @override
//   Widget build(BuildContext context) {
//     final items = customUrls ?? kStickerAssets;
//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 4,
//         mainAxisSpacing: 10,
//         crossAxisSpacing: 10,
//         childAspectRatio: 1,
//       ),
//       itemCount: items.length,
//       itemBuilder: (_, i) {
//         final path = items[i];
//         return StickerImage(
//           assetPath: path,
//           size: stickerSize,
//           selected: selected == path,
//           onTap: () => onSelect(selected == path ? '' : path),
//         );
//       },
//     );
//   }
// }

// class StickerDisplay extends StatelessWidget {
//   const StickerDisplay({super.key, required this.assetPath, this.size = 56});
//   final String assetPath;
//   final double size;

//   @override
//   Widget build(BuildContext context) {
//     return StickerImage(assetPath: assetPath, size: size);
//   }
// }

// const kReactionKeys = [
//   'laugh',
//   'fire',
//   'dead',
//   'clap',
//   'rofl',
//   'cry',
//   'salute',
//   'hundred',
//   'mindblown',
//   'crown',
//   'annoyed',
//   'touched',
// ];

// class ReactionDisplay extends StatelessWidget {
//   const ReactionDisplay({
//     super.key,
//     required this.value,
//     this.size = 18,
//     this.avatarConfig,
//   });

//   final String value;
//   final double size;
//   final Map<String, dynamic>? avatarConfig;

//   @override
//   Widget build(BuildContext context) {
//     if (AvatarConfig.isAvatarReaction(value) && avatarConfig != null) {
//       final key = AvatarConfig.avatarReactionKey(value);
//       final url = AvatarConfig.fromMap(avatarConfig!).reactionUrl(key);
//       return ClipOval(
//         child: AvatarDisplay(avatarUrl: url, size: size * 1.6),
//       );
//     }
//     final display = AvatarConfig.isAvatarReaction(value)
//         ? (AvatarConfig
//                   .reactionExpressions[AvatarConfig.avatarReactionKey(value)]
//                   ?.emoji ??
//               '🙂')
//         : value;
//     return Text(display, style: TextStyle(fontSize: size));
//   }
// }

// class EmojiReactionRow extends StatelessWidget {
//   const EmojiReactionRow({
//     super.key,
//     required this.reactionsByEmoji,
//     required this.alreadyReacted,
//     required this.onReact,
//     this.useAvatarMode = false,
//     this.ownAvatarConfig,
//     this.avatarConfigByValue = const {},
//   });

//   final Map<String, int> reactionsByEmoji;
//   final bool alreadyReacted;
//   final ValueChanged<String> onReact;
//   final bool useAvatarMode;
//   final Map<String, dynamic>? ownAvatarConfig;
//   final Map<String, Map<String, dynamic>?> avatarConfigByValue;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (reactionsByEmoji.isNotEmpty)
//           Wrap(
//             spacing: 6,
//             runSpacing: 4,
//             children: reactionsByEmoji.entries
//                 .map(
//                   (e) => Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: theme.colorScheme.surfaceContainerHighest,
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         ReactionDisplay(
//                           value: e.key,
//                           size: 14,
//                           avatarConfig: avatarConfigByValue[e.key],
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           '${e.value}',
//                           style: const TextStyle(fontSize: 12),
//                         ),
//                       ],
//                     ),
//                   ),
//                 )
//                 .toList(),
//           ),

//         if (!alreadyReacted) ...[
//           if (reactionsByEmoji.isNotEmpty) const SizedBox(height: 6),
//           SizedBox(
//             height: 38,
//             child: ListView(
//               scrollDirection: Axis.horizontal,
//               children:
//                   (useAvatarMode && ownAvatarConfig != null
//                           ? kReactionKeys
//                                 .map((k) => '${AvatarConfig.reactionPrefix}$k')
//                                 .toList()
//                           : kEmojiReactions)
//                       .map(
//                         (s) => Padding(
//                           padding: const EdgeInsets.only(right: 4),
//                           child: InkWell(
//                             borderRadius: BorderRadius.circular(6),
//                             onTap: () => onReact(s),
//                             child: Container(
//                               width: 34,
//                               height: 34,
//                               alignment: Alignment.center,
//                               decoration: BoxDecoration(
//                                 color:
//                                     theme.colorScheme.surfaceContainerHighest,
//                                 borderRadius: BorderRadius.circular(6),
//                               ),
//                               child: ReactionDisplay(
//                                 value: s,
//                                 size: 18,
//                                 avatarConfig: useAvatarMode
//                                     ? ownAvatarConfig
//                                     : null,
//                               ),
//                             ),
//                           ),
//                         ),
//                       )
//                       .toList(),
//             ),
//           ),
//         ],
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';

import 'features/avatar/presentation/avatar_creator_screen.dart';

const kStickerAssets = <String>[
  'assets/images/stickers/sticker_01.jpg',
  'assets/images/stickers/sticker_02.jpg',
  'assets/images/stickers/sticker_03.jpg',
  'assets/images/stickers/sticker_04.jpg',
  'assets/images/stickers/sticker_05.jpg',
  'assets/images/stickers/sticker_06.jpg',
  'assets/images/stickers/sticker_07.jpg',
  'assets/images/stickers/sticker_08.jpg',
  'assets/images/stickers/sticker_09.jpg',
  'assets/images/stickers/sticker_10.jpg',
  'assets/images/stickers/sticker_11.jpg',
  'assets/images/stickers/sticker_12.jpg',
];

const kEmojiReactions = [
  '😂',
  '❤️',
  '🔥',
  '💀',
  '👏',
  '🤣',
  '😭',
  '🫡',
  '💯',
  '🤯',
  '👑',
  '😤',
  '🥹',
  '🫶',
  '💅',
  '🙈',
  '😎',
  '🤡',
  '💔',
  '🎉',
  '😈',
];

class StickerImage extends StatelessWidget {
  const StickerImage({
    super.key,
    required this.assetPath,
    this.size = 60,
    this.selected = false,
    this.onTap,
  });

  final String assetPath;
  final double size;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? Border.all(color: theme.colorScheme.primary, width: 2.5)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(selected ? 8 : 10),
          child: assetPath.startsWith('http')
              ? Image.network(
                  assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: size * 0.4,
                    ),
                  ),
                )
              : Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    final idx = kStickerAssets.indexOf(assetPath) + 1;
                    return Center(
                      child: Text(
                        '🎭$idx',
                        style: TextStyle(fontSize: size * 0.4),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class StickerPicker extends StatelessWidget {
  const StickerPicker({
    super.key,
    required this.selected,
    required this.onSelect,
    this.stickerSize = 64,
    this.customUrls,
  });

  final String? selected;
  final ValueChanged<String> onSelect;
  final double stickerSize;
  final List<String>? customUrls;

  @override
  Widget build(BuildContext context) {
    final items = customUrls ?? kStickerAssets;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final path = items[i];
        return StickerImage(
          assetPath: path,
          size: stickerSize,
          selected: selected == path,
          onTap: () => onSelect(selected == path ? '' : path),
        );
      },
    );
  }
}

class StickerDisplay extends StatelessWidget {
  const StickerDisplay({super.key, required this.assetPath, this.size = 56});
  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return StickerImage(assetPath: assetPath, size: size);
  }
}

const kReactionKeys = [
  'laugh',
  'fire',
  'dead',
  'clap',
  'rofl',
  'cry',
  'salute',
  'hundred',
  'mindblown',
  'crown',
  'annoyed',
  'touched',
];

class ReactionDisplay extends StatelessWidget {
  const ReactionDisplay({
    super.key,
    required this.value,
    this.size = 18,
    this.avatarConfig,
  });

  final String value;
  final double size;
  final Map<String, dynamic>? avatarConfig;

  @override
  Widget build(BuildContext context) {
    if (AvatarConfig.isAvatarReaction(value) && avatarConfig != null) {
      final key = AvatarConfig.avatarReactionKey(value);
      final url = AvatarConfig.fromMap(avatarConfig!).reactionUrl(key);
      return ClipOval(
        child: AvatarDisplay(avatarUrl: url, size: size * 1.6),
      );
    }
    final display = AvatarConfig.isAvatarReaction(value)
        ? (AvatarConfig
                  .reactionExpressions[AvatarConfig.avatarReactionKey(value)]
                  ?.emoji ??
              '🙂')
        : value;
    return Text(display, style: TextStyle(fontSize: size));
  }
}

class EmojiReactionRow extends StatelessWidget {
  const EmojiReactionRow({
    super.key,
    required this.reactionsByEmoji,
    required this.alreadyReacted,
    required this.onReact,
    this.useAvatarMode = false,
    this.ownAvatarConfig,
    this.avatarConfigByValue = const {},
  });

  final Map<String, int> reactionsByEmoji;
  final bool alreadyReacted;
  final ValueChanged<String> onReact;
  final bool useAvatarMode;
  final Map<String, dynamic>? ownAvatarConfig;
  final Map<String, Map<String, dynamic>?> avatarConfigByValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reactionsByEmoji.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: reactionsByEmoji.entries
                .map(
                  (e) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ReactionDisplay(
                          value: e.key,
                          size: 14,
                          avatarConfig: avatarConfigByValue[e.key],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${e.value}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),

        if (!alreadyReacted) ...[
          if (reactionsByEmoji.isNotEmpty) const SizedBox(height: 6),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  [
                        if (useAvatarMode && ownAvatarConfig != null)
                          ...kReactionKeys.map(
                            (k) => '${AvatarConfig.reactionPrefix}$k',
                          ),
                        ...kEmojiReactions,
                      ]
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => onReact(s),
                            child: Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: ReactionDisplay(
                                value: s,
                                size: 18,
                                avatarConfig: AvatarConfig.isAvatarReaction(s)
                                    ? ownAvatarConfig
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ],
    );
  }
}
