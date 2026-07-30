// // // // // // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // // // // // import 'package:provider/provider.dart';
// // // // // // // // // // // // // // import '../../../../core/extensions/context_ext.dart';
// // // // // // // // // // // // // // import '../../../../core/theme/app_colors.dart';
// // // // // // // // // // // // // // import '../room_provider.dart';

// // // // // // // // // // // // // // class GameSettingsSheet extends StatelessWidget {
// // // // // // // // // // // // // //   const GameSettingsSheet({super.key});

// // // // // // // // // // // // // //   @override
// // // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // // //     final theme = context.theme;
// // // // // // // // // // // // // //     final l10n  = context.l10n;

// // // // // // // // // // // // // //     return Container(
// // // // // // // // // // // // // //       decoration: BoxDecoration(
// // // // // // // // // // // // // //         color: theme.colorScheme.surface,
// // // // // // // // // // // // // //         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
// // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // //       padding: EdgeInsets.fromLTRB(
// // // // // // // // // // // // // //           24, 12, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
// // // // // // // // // // // // // //       child: Consumer<RoomProvider>(builder: (_, room, __) {
// // // // // // // // // // // // // //         final s = room.settings;
// // // // // // // // // // // // // //         return Column(
// // // // // // // // // // // // // //           mainAxisSize: MainAxisSize.min,
// // // // // // // // // // // // // //           crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // // // // // // // //           children: [
// // // // // // // // // // // // // //             // Handle
// // // // // // // // // // // // // //             Center(
// // // // // // // // // // // // // //               child: Container(
// // // // // // // // // // // // // //                 width: 36, height: 4,
// // // // // // // // // // // // // //                 decoration: BoxDecoration(
// // // // // // // // // // // // // //                   color: theme.colorScheme.outlineVariant,
// // // // // // // // // // // // // //                   borderRadius: BorderRadius.circular(2)),
// // // // // // // // // // // // // //               ),
// // // // // // // // // // // // // //             ),
// // // // // // // // // // // // // //             const SizedBox(height: 20),

// // // // // // // // // // // // // //             Text(l10n.gameSettings,
// // // // // // // // // // // // // //                 style: theme.textTheme.titleLarge?.copyWith(
// // // // // // // // // // // // // //                     fontWeight: FontWeight.w700)),
// // // // // // // // // // // // // //             const SizedBox(height: 20),

// // // // // // // // // // // // // //             // Turn timer
// // // // // // // // // // // // // //             _SliderRow(
// // // // // // // // // // // // // //               label: l10n.gameSettingsTurnTimer,
// // // // // // // // // // // // // //               value: s.turnTimerSeconds.toDouble(),
// // // // // // // // // // // // // //               display: l10n.gameSettingsSeconds(s.turnTimerSeconds),
// // // // // // // // // // // // // //               min: 15, max: 120, divisions: 21,
// // // // // // // // // // // // // //               onChanged: (v) =>
// // // // // // // // // // // // // //                   room.updateSetting('turn_timer_secs', v.round()),
// // // // // // // // // // // // // //             ),

// // // // // // // // // // // // // //             // Max rounds
// // // // // // // // // // // // // //             _SliderRow(
// // // // // // // // // // // // // //               label: l10n.gameSettingsMaxRounds,
// // // // // // // // // // // // // //               value: s.maxRounds.toDouble(),
// // // // // // // // // // // // // //               display: '${s.maxRounds}',
// // // // // // // // // // // // // //               min: 3, max: 30, divisions: 27,
// // // // // // // // // // // // // //               onChanged: (v) => room.updateSetting('max_rounds', v.round()),
// // // // // // // // // // // // // //             ),
// // // // // // // // // // // // // //             const SizedBox(height: 4),

// // // // // // // // // // // // // //             // Allow skip
// // // // // // // // // // // // // //             _SwitchRow(
// // // // // // // // // // // // // //               label: l10n.gameSettingsAllowSkip,
// // // // // // // // // // // // // //               icon: Icons.skip_next_rounded,
// // // // // // // // // // // // // //               value: s.allowSkip,
// // // // // // // // // // // // // //               onChanged: (v) => room.updateSetting('allow_skip', v),
// // // // // // // // // // // // // //             ),

// // // // // // // // // // // // // //             // Chat enabled
// // // // // // // // // // // // // //             _SwitchRow(
// // // // // // // // // // // // // //               label: 'Chat',
// // // // // // // // // // // // // //               icon: Icons.chat_bubble_outline_rounded,
// // // // // // // // // // // // // //               value: s.chatEnabled,
// // // // // // // // // // // // // //               onChanged: (v) => room.updateSetting('chat_enabled', v),
// // // // // // // // // // // // // //             ),

// // // // // // // // // // // // // //             // Allow spectators
// // // // // // // // // // // // // //             _SwitchRow(
// // // // // // // // // // // // // //               label: 'Allow spectators',
// // // // // // // // // // // // // //               icon: Icons.visibility_outlined,
// // // // // // // // // // // // // //               value: s.allowSpectators,
// // // // // // // // // // // // // //               onChanged: (v) => room.updateSetting('allow_spectators', v),
// // // // // // // // // // // // // //             ),

// // // // // // // // // // // // // //             // Spicy content
// // // // // // // // // // // // // //             if (room.room?.allowSpicy == true)
// // // // // // // // // // // // // //               _SwitchRow(
// // // // // // // // // // // // // //                 label: l10n.gameSettingsAllowSpicy,
// // // // // // // // // // // // // //                 icon: Icons.local_fire_department_outlined,
// // // // // // // // // // // // // //                 value: room.room?.allowSpicy ?? false,
// // // // // // // // // // // // // //                 onChanged: null, // room-level setting, not session
// // // // // // // // // // // // // //               ),
// // // // // // // // // // // // // //           ],
// // // // // // // // // // // // // //         );
// // // // // // // // // // // // // //       }),
// // // // // // // // // // // // // //     );
// // // // // // // // // // // // // //   }
// // // // // // // // // // // // // // }

// // // // // // // // // // // // // // class _SliderRow extends StatelessWidget {
// // // // // // // // // // // // // //   const _SliderRow({
// // // // // // // // // // // // // //     required this.label,
// // // // // // // // // // // // // //     required this.value,
// // // // // // // // // // // // // //     required this.display,
// // // // // // // // // // // // // //     required this.min,
// // // // // // // // // // // // // //     required this.max,
// // // // // // // // // // // // // //     required this.divisions,
// // // // // // // // // // // // // //     required this.onChanged,
// // // // // // // // // // // // // //   });

// // // // // // // // // // // // // //   final String label;
// // // // // // // // // // // // // //   final double value;
// // // // // // // // // // // // // //   final String display;
// // // // // // // // // // // // // //   final double min;
// // // // // // // // // // // // // //   final double max;
// // // // // // // // // // // // // //   final int divisions;
// // // // // // // // // // // // // //   final void Function(double) onChanged;

// // // // // // // // // // // // // //   @override
// // // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // // //     return Column(
// // // // // // // // // // // // // //       children: [
// // // // // // // // // // // // // //         Row(
// // // // // // // // // // // // // //           children: [
// // // // // // // // // // // // // //             Text(label, style: context.textTheme.titleSmall),
// // // // // // // // // // // // // //             const Spacer(),
// // // // // // // // // // // // // //             Text(display,
// // // // // // // // // // // // // //                 style: context.textTheme.titleSmall?.copyWith(
// // // // // // // // // // // // // //                     color: context.colorScheme.primary,
// // // // // // // // // // // // // //                     fontWeight: FontWeight.w700)),
// // // // // // // // // // // // // //           ],
// // // // // // // // // // // // // //         ),
// // // // // // // // // // // // // //         Slider(
// // // // // // // // // // // // // //           value: value,
// // // // // // // // // // // // // //           min: min, max: max, divisions: divisions,
// // // // // // // // // // // // // //           label: display,
// // // // // // // // // // // // // //           onChanged: onChanged,
// // // // // // // // // // // // // //         ),
// // // // // // // // // // // // // //       ],
// // // // // // // // // // // // // //     );
// // // // // // // // // // // // // //   }
// // // // // // // // // // // // // // }

// // // // // // // // // // // // // // class _SwitchRow extends StatelessWidget {
// // // // // // // // // // // // // //   const _SwitchRow({
// // // // // // // // // // // // // //     required this.label,
// // // // // // // // // // // // // //     required this.icon,
// // // // // // // // // // // // // //     required this.value,
// // // // // // // // // // // // // //     required this.onChanged,
// // // // // // // // // // // // // //   });

// // // // // // // // // // // // // //   final String label;
// // // // // // // // // // // // // //   final IconData icon;
// // // // // // // // // // // // // //   final bool value;
// // // // // // // // // // // // // //   final void Function(bool)? onChanged;

// // // // // // // // // // // // // //   @override
// // // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // // //     return SwitchListTile(
// // // // // // // // // // // // // //       title: Row(
// // // // // // // // // // // // // //         children: [
// // // // // // // // // // // // // //           Icon(icon, size: 18, color: context.colorScheme.onSurfaceVariant),
// // // // // // // // // // // // // //           const SizedBox(width: 8),
// // // // // // // // // // // // // //           Text(label, style: context.textTheme.titleSmall),
// // // // // // // // // // // // // //         ],
// // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // //       value: value,
// // // // // // // // // // // // // //       onChanged: onChanged,
// // // // // // // // // // // // // //       contentPadding: EdgeInsets.zero,
// // // // // // // // // // // // // //       dense: true,
// // // // // // // // // // // // // //     );
// // // // // // // // // // // // // //   }
// // // // // // // // // // // // // // }

// // // // // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // // // // // // import 'package:provider/provider.dart';
// // // // // // // // // // // // // import '../../../../core/extensions/context_ext.dart';
// // // // // // // // // // // // // import '../../../../core/theme/app_colors.dart';
// // // // // // // // // // // // // import '../room_provider.dart';

// // // // // // // // // // // // // class GameSettingsSheet extends StatelessWidget {
// // // // // // // // // // // // //   const GameSettingsSheet({super.key});

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // //     final theme = context.theme;
// // // // // // // // // // // // //     final l10n = context.l10n;

// // // // // // // // // // // // //     return Container(
// // // // // // // // // // // // //       decoration: BoxDecoration(
// // // // // // // // // // // // //         color: theme.colorScheme.surface,
// // // // // // // // // // // // //         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //       padding: EdgeInsets.fromLTRB(
// // // // // // // // // // // // //         24,
// // // // // // // // // // // // //         12,
// // // // // // // // // // // // //         24,
// // // // // // // // // // // // //         MediaQuery.viewInsetsOf(context).bottom + 24,
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //       child: Consumer<RoomProvider>(
// // // // // // // // // // // // //         builder: (_, room, __) {
// // // // // // // // // // // // //           final s = room.settings;
// // // // // // // // // // // // //           return Column(
// // // // // // // // // // // // //             mainAxisSize: MainAxisSize.min,
// // // // // // // // // // // // //             crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // // // // // // //             children: [
// // // // // // // // // // // // //               // Handle
// // // // // // // // // // // // //               Center(
// // // // // // // // // // // // //                 child: Container(
// // // // // // // // // // // // //                   width: 36,
// // // // // // // // // // // // //                   height: 4,
// // // // // // // // // // // // //                   decoration: BoxDecoration(
// // // // // // // // // // // // //                     color: theme.colorScheme.outlineVariant,
// // // // // // // // // // // // //                     borderRadius: BorderRadius.circular(2),
// // // // // // // // // // // // //                   ),
// // // // // // // // // // // // //                 ),
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //               const SizedBox(height: 20),

// // // // // // // // // // // // //               Text(
// // // // // // // // // // // // //                 l10n.gameSettings,
// // // // // // // // // // // // //                 style: theme.textTheme.titleLarge?.copyWith(
// // // // // // // // // // // // //                   fontWeight: FontWeight.w700,
// // // // // // // // // // // // //                 ),
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //               const SizedBox(height: 20),

// // // // // // // // // // // // //               // Pack selection
// // // // // // // // // // // // //               if (room.isOwner) ...[
// // // // // // // // // // // // //                 Text('Pack', style: theme.textTheme.labelLarge),
// // // // // // // // // // // // //                 const SizedBox(height: 8),
// // // // // // // // // // // // //                 InkWell(
// // // // // // // // // // // // //                   borderRadius: BorderRadius.circular(12),
// // // // // // // // // // // // //                   onTap: () async {
// // // // // // // // // // // // //                     Navigator.pop(context);
// // // // // // // // // // // // //                     // Navigate to marketplace to pick a pack
// // // // // // // // // // // // //                     context.go('/marketplace');
// // // // // // // // // // // // //                   },
// // // // // // // // // // // // //                   child: Container(
// // // // // // // // // // // // //                     padding: const EdgeInsets.symmetric(
// // // // // // // // // // // // //                       horizontal: 16,
// // // // // // // // // // // // //                       vertical: 12,
// // // // // // // // // // // // //                     ),
// // // // // // // // // // // // //                     decoration: BoxDecoration(
// // // // // // // // // // // // //                       border: Border.all(
// // // // // // // // // // // // //                         color: room.room?.packId?.isNotEmpty == true
// // // // // // // // // // // // //                             ? theme.colorScheme.primary
// // // // // // // // // // // // //                             : theme.colorScheme.error,
// // // // // // // // // // // // //                       ),
// // // // // // // // // // // // //                       borderRadius: BorderRadius.circular(12),
// // // // // // // // // // // // //                     ),
// // // // // // // // // // // // //                     child: Row(
// // // // // // // // // // // // //                       children: [
// // // // // // // // // // // // //                         Icon(
// // // // // // // // // // // // //                           Icons.style_rounded,
// // // // // // // // // // // // //                           color: room.room?.packId?.isNotEmpty == true
// // // // // // // // // // // // //                               ? theme.colorScheme.primary
// // // // // // // // // // // // //                               : theme.colorScheme.error,
// // // // // // // // // // // // //                         ),
// // // // // // // // // // // // //                         const SizedBox(width: 12),
// // // // // // // // // // // // //                         Expanded(
// // // // // // // // // // // // //                           child: Text(
// // // // // // // // // // // // //                             room.room?.packId?.isNotEmpty == true
// // // // // // // // // // // // //                                 ? 'Pack selected ✓'
// // // // // // // // // // // // //                                 : 'No pack selected — tap to browse',
// // // // // // // // // // // // //                             style: TextStyle(
// // // // // // // // // // // // //                               color: room.room?.packId?.isNotEmpty == true
// // // // // // // // // // // // //                                   ? theme.colorScheme.primary
// // // // // // // // // // // // //                                   : theme.colorScheme.error,
// // // // // // // // // // // // //                             ),
// // // // // // // // // // // // //                           ),
// // // // // // // // // // // // //                         ),
// // // // // // // // // // // // //                         const Icon(Icons.chevron_right_rounded),
// // // // // // // // // // // // //                       ],
// // // // // // // // // // // // //                     ),
// // // // // // // // // // // // //                   ),
// // // // // // // // // // // // //                 ),
// // // // // // // // // // // // //                 const SizedBox(height: 16),
// // // // // // // // // // // // //               ],

// // // // // // // // // // // // //               // Turn timer
// // // // // // // // // // // // //               _SliderRow(
// // // // // // // // // // // // //                 label: l10n.gameSettingsTurnTimer,
// // // // // // // // // // // // //                 value: s.turnTimerSeconds.toDouble(),
// // // // // // // // // // // // //                 display: l10n.gameSettingsSeconds(s.turnTimerSeconds),
// // // // // // // // // // // // //                 min: 15,
// // // // // // // // // // // // //                 max: 120,
// // // // // // // // // // // // //                 divisions: 21,
// // // // // // // // // // // // //                 onChanged: (v) =>
// // // // // // // // // // // // //                     room.updateSetting('turn_timer_secs', v.round()),
// // // // // // // // // // // // //               ),

// // // // // // // // // // // // //               // Max rounds
// // // // // // // // // // // // //               _SliderRow(
// // // // // // // // // // // // //                 label: l10n.gameSettingsMaxRounds,
// // // // // // // // // // // // //                 value: s.maxRounds.toDouble(),
// // // // // // // // // // // // //                 display: '${s.maxRounds}',
// // // // // // // // // // // // //                 min: 3,
// // // // // // // // // // // // //                 max: 30,
// // // // // // // // // // // // //                 divisions: 27,
// // // // // // // // // // // // //                 onChanged: (v) => room.updateSetting('max_rounds', v.round()),
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //               const SizedBox(height: 4),

// // // // // // // // // // // // //               // Allow skip
// // // // // // // // // // // // //               _SwitchRow(
// // // // // // // // // // // // //                 label: l10n.gameSettingsAllowSkip,
// // // // // // // // // // // // //                 icon: Icons.skip_next_rounded,
// // // // // // // // // // // // //                 value: s.allowSkip,
// // // // // // // // // // // // //                 onChanged: (v) => room.updateSetting('allow_skip', v),
// // // // // // // // // // // // //               ),

// // // // // // // // // // // // //               // Chat enabled
// // // // // // // // // // // // //               _SwitchRow(
// // // // // // // // // // // // //                 label: 'Chat',
// // // // // // // // // // // // //                 icon: Icons.chat_bubble_outline_rounded,
// // // // // // // // // // // // //                 value: s.chatEnabled,
// // // // // // // // // // // // //                 onChanged: (v) => room.updateSetting('chat_enabled', v),
// // // // // // // // // // // // //               ),

// // // // // // // // // // // // //               // Allow spectators
// // // // // // // // // // // // //               _SwitchRow(
// // // // // // // // // // // // //                 label: 'Allow spectators',
// // // // // // // // // // // // //                 icon: Icons.visibility_outlined,
// // // // // // // // // // // // //                 value: s.allowSpectators,
// // // // // // // // // // // // //                 onChanged: (v) => room.updateSetting('allow_spectators', v),
// // // // // // // // // // // // //               ),

// // // // // // // // // // // // //               // Spicy content
// // // // // // // // // // // // //               if (room.room?.allowSpicy == true)
// // // // // // // // // // // // //                 _SwitchRow(
// // // // // // // // // // // // //                   label: l10n.gameSettingsAllowSpicy,
// // // // // // // // // // // // //                   icon: Icons.local_fire_department_outlined,
// // // // // // // // // // // // //                   value: room.room?.allowSpicy ?? false,
// // // // // // // // // // // // //                   onChanged: null, // room-level setting, not session
// // // // // // // // // // // // //                 ),
// // // // // // // // // // // // //             ],
// // // // // // // // // // // // //           );
// // // // // // // // // // // // //         },
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //   }
// // // // // // // // // // // // // }

// // // // // // // // // // // // // class _SliderRow extends StatelessWidget {
// // // // // // // // // // // // //   const _SliderRow({
// // // // // // // // // // // // //     required this.label,
// // // // // // // // // // // // //     required this.value,
// // // // // // // // // // // // //     required this.display,
// // // // // // // // // // // // //     required this.min,
// // // // // // // // // // // // //     required this.max,
// // // // // // // // // // // // //     required this.divisions,
// // // // // // // // // // // // //     required this.onChanged,
// // // // // // // // // // // // //   });

// // // // // // // // // // // // //   final String label;
// // // // // // // // // // // // //   final double value;
// // // // // // // // // // // // //   final String display;
// // // // // // // // // // // // //   final double min;
// // // // // // // // // // // // //   final double max;
// // // // // // // // // // // // //   final int divisions;
// // // // // // // // // // // // //   final void Function(double) onChanged;

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // //     return Column(
// // // // // // // // // // // // //       children: [
// // // // // // // // // // // // //         Row(
// // // // // // // // // // // // //           children: [
// // // // // // // // // // // // //             Text(label, style: context.textTheme.titleSmall),
// // // // // // // // // // // // //             const Spacer(),
// // // // // // // // // // // // //             Text(
// // // // // // // // // // // // //               display,
// // // // // // // // // // // // //               style: context.textTheme.titleSmall?.copyWith(
// // // // // // // // // // // // //                 color: context.colorScheme.primary,
// // // // // // // // // // // // //                 fontWeight: FontWeight.w700,
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //           ],
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         Slider(
// // // // // // // // // // // // //           value: value,
// // // // // // // // // // // // //           min: min,
// // // // // // // // // // // // //           max: max,
// // // // // // // // // // // // //           divisions: divisions,
// // // // // // // // // // // // //           label: display,
// // // // // // // // // // // // //           onChanged: onChanged,
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //       ],
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //   }
// // // // // // // // // // // // // }

// // // // // // // // // // // // // class _SwitchRow extends StatelessWidget {
// // // // // // // // // // // // //   const _SwitchRow({
// // // // // // // // // // // // //     required this.label,
// // // // // // // // // // // // //     required this.icon,
// // // // // // // // // // // // //     required this.value,
// // // // // // // // // // // // //     required this.onChanged,
// // // // // // // // // // // // //   });

// // // // // // // // // // // // //   final String label;
// // // // // // // // // // // // //   final IconData icon;
// // // // // // // // // // // // //   final bool value;
// // // // // // // // // // // // //   final void Function(bool)? onChanged;

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // //     return SwitchListTile(
// // // // // // // // // // // // //       title: Row(
// // // // // // // // // // // // //         children: [
// // // // // // // // // // // // //           Icon(icon, size: 18, color: context.colorScheme.onSurfaceVariant),
// // // // // // // // // // // // //           const SizedBox(width: 8),
// // // // // // // // // // // // //           Text(label, style: context.textTheme.titleSmall),
// // // // // // // // // // // // //         ],
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //       value: value,
// // // // // // // // // // // // //       onChanged: onChanged,
// // // // // // // // // // // // //       contentPadding: EdgeInsets.zero,
// // // // // // // // // // // // //       dense: true,
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //   }
// // // // // // // // // // // // // }

// // // // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // // // // // import '../../../../core/extensions/context_ext.dart';
// // // // // // // // // // // // import '../../../../core/theme/app_colors.dart';
// // // // // // // // // // // // import '../../../packs/data/pack_repository.dart';
// // // // // // // // // // // // import '../../../packs/domain/pack_entity.dart';
// // // // // // // // // // // // import '../room_provider.dart';

// // // // // // // // // // // // class GameSettingsSheet extends StatefulWidget {
// // // // // // // // // // // //   const GameSettingsSheet({super.key});

// // // // // // // // // // // //   @override
// // // // // // // // // // // //   State<GameSettingsSheet> createState() => _GameSettingsSheetState();
// // // // // // // // // // // // }

// // // // // // // // // // // // class _GameSettingsSheetState extends State<GameSettingsSheet> {
// // // // // // // // // // // //   List<PackEntity> _packs = [];
// // // // // // // // // // // //   bool _loadingPacks = true;

// // // // // // // // // // // //   @override
// // // // // // // // // // // //   void initState() {
// // // // // // // // // // // //     super.initState();
// // // // // // // // // // // //     _loadPacks();
// // // // // // // // // // // //   }

// // // // // // // // // // // //   Future<void> _loadPacks() async {
// // // // // // // // // // // //     try {
// // // // // // // // // // // //       final packs = await PackRepository.instance.browsePacks(
// // // // // // // // // // // //         gameType: 'truth_or_dare',
// // // // // // // // // // // //         perPage: 30,
// // // // // // // // // // // //       );
// // // // // // // // // // // //       if (mounted)
// // // // // // // // // // // //         setState(() {
// // // // // // // // // // // //           _packs = packs;
// // // // // // // // // // // //           _loadingPacks = false;
// // // // // // // // // // // //         });
// // // // // // // // // // // //     } catch (e) {
// // // // // // // // // // // //       if (mounted) setState(() => _loadingPacks = false);
// // // // // // // // // // // //     }
// // // // // // // // // // // //   }

// // // // // // // // // // // //   @override
// // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // //     final theme = context.theme;
// // // // // // // // // // // //     final l10n = context.l10n;

// // // // // // // // // // // //     return Container(
// // // // // // // // // // // //       decoration: BoxDecoration(
// // // // // // // // // // // //         color: theme.colorScheme.surface,
// // // // // // // // // // // //         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
// // // // // // // // // // // //       ),
// // // // // // // // // // // //       padding: EdgeInsets.fromLTRB(
// // // // // // // // // // // //         24,
// // // // // // // // // // // //         12,
// // // // // // // // // // // //         24,
// // // // // // // // // // // //         MediaQuery.viewInsetsOf(context).bottom + 24,
// // // // // // // // // // // //       ),
// // // // // // // // // // // //       child: Consumer<RoomProvider>(
// // // // // // // // // // // //         builder: (_, room, __) {
// // // // // // // // // // // //           final s = room.settings;
// // // // // // // // // // // //           return SingleChildScrollView(
// // // // // // // // // // // //             child: Column(
// // // // // // // // // // // //               mainAxisSize: MainAxisSize.min,
// // // // // // // // // // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // // // // // //               children: [
// // // // // // // // // // // //                 // Handle
// // // // // // // // // // // //                 Center(
// // // // // // // // // // // //                   child: Container(
// // // // // // // // // // // //                     width: 36,
// // // // // // // // // // // //                     height: 4,
// // // // // // // // // // // //                     decoration: BoxDecoration(
// // // // // // // // // // // //                       color: theme.colorScheme.outlineVariant,
// // // // // // // // // // // //                       borderRadius: BorderRadius.circular(2),
// // // // // // // // // // // //                     ),
// // // // // // // // // // // //                   ),
// // // // // // // // // // // //                 ),
// // // // // // // // // // // //                 const SizedBox(height: 20),

// // // // // // // // // // // //                 Text(
// // // // // // // // // // // //                   l10n.gameSettings,
// // // // // // // // // // // //                   style: theme.textTheme.titleLarge?.copyWith(
// // // // // // // // // // // //                     fontWeight: FontWeight.w700,
// // // // // // // // // // // //                   ),
// // // // // // // // // // // //                 ),
// // // // // // // // // // // //                 const SizedBox(height: 20),

// // // // // // // // // // // //                 // ── Pack picker ───────────────────────────────────────────────
// // // // // // // // // // // //                 if (room.isOwner) ...[
// // // // // // // // // // // //                   Text(
// // // // // // // // // // // //                     'Select Pack',
// // // // // // // // // // // //                     style: theme.textTheme.labelLarge?.copyWith(
// // // // // // // // // // // //                       fontWeight: FontWeight.w600,
// // // // // // // // // // // //                     ),
// // // // // // // // // // // //                   ),
// // // // // // // // // // // //                   const SizedBox(height: 8),
// // // // // // // // // // // //                   if (_loadingPacks)
// // // // // // // // // // // //                     const Padding(
// // // // // // // // // // // //                       padding: EdgeInsets.symmetric(vertical: 16),
// // // // // // // // // // // //                       child: Center(child: CircularProgressIndicator()),
// // // // // // // // // // // //                     )
// // // // // // // // // // // //                   else if (_packs.isEmpty)
// // // // // // // // // // // //                     Container(
// // // // // // // // // // // //                       padding: const EdgeInsets.all(16),
// // // // // // // // // // // //                       decoration: BoxDecoration(
// // // // // // // // // // // //                         color: theme.colorScheme.surfaceContainerHighest,
// // // // // // // // // // // //                         borderRadius: BorderRadius.circular(12),
// // // // // // // // // // // //                       ),
// // // // // // // // // // // //                       child: Row(
// // // // // // // // // // // //                         children: [
// // // // // // // // // // // //                           Icon(
// // // // // // // // // // // //                             Icons.info_outline,
// // // // // // // // // // // //                             color: theme.colorScheme.onSurfaceVariant,
// // // // // // // // // // // //                           ),
// // // // // // // // // // // //                           const SizedBox(width: 12),
// // // // // // // // // // // //                           Expanded(
// // // // // // // // // // // //                             child: Text(
// // // // // // // // // // // //                               'No packs available. Run the seed SQL in Supabase.',
// // // // // // // // // // // //                               style: theme.textTheme.bodySmall,
// // // // // // // // // // // //                             ),
// // // // // // // // // // // //                           ),
// // // // // // // // // // // //                         ],
// // // // // // // // // // // //                       ),
// // // // // // // // // // // //                     )
// // // // // // // // // // // //                   else
// // // // // // // // // // // //                     SizedBox(
// // // // // // // // // // // //                       height: 110,
// // // // // // // // // // // //                       child: ListView.separated(
// // // // // // // // // // // //                         scrollDirection: Axis.horizontal,
// // // // // // // // // // // //                         itemCount: _packs.length,
// // // // // // // // // // // //                         separatorBuilder: (_, __) => const SizedBox(width: 10),
// // // // // // // // // // // //                         itemBuilder: (ctx, i) {
// // // // // // // // // // // //                           final pack = _packs[i];
// // // // // // // // // // // //                           final selected = room.room?.packId == pack.id;
// // // // // // // // // // // //                           return GestureDetector(
// // // // // // // // // // // //                             onTap: () => room.setPackId(pack.id),
// // // // // // // // // // // //                             child: AnimatedContainer(
// // // // // // // // // // // //                               duration: const Duration(milliseconds: 180),
// // // // // // // // // // // //                               width: 140,
// // // // // // // // // // // //                               padding: const EdgeInsets.all(12),
// // // // // // // // // // // //                               decoration: BoxDecoration(
// // // // // // // // // // // //                                 color: selected
// // // // // // // // // // // //                                     ? theme.colorScheme.primaryContainer
// // // // // // // // // // // //                                     : theme.colorScheme.surfaceContainerHighest,
// // // // // // // // // // // //                                 borderRadius: BorderRadius.circular(12),
// // // // // // // // // // // //                                 border: Border.all(
// // // // // // // // // // // //                                   color: selected
// // // // // // // // // // // //                                       ? theme.colorScheme.primary
// // // // // // // // // // // //                                       : Colors.transparent,
// // // // // // // // // // // //                                   width: 2,
// // // // // // // // // // // //                                 ),
// // // // // // // // // // // //                               ),
// // // // // // // // // // // //                               child: Column(
// // // // // // // // // // // //                                 crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // // // // // //                                 children: [
// // // // // // // // // // // //                                   Row(
// // // // // // // // // // // //                                     children: [
// // // // // // // // // // // //                                       Text(
// // // // // // // // // // // //                                         pack.coverEmoji,
// // // // // // // // // // // //                                         style: const TextStyle(fontSize: 20),
// // // // // // // // // // // //                                       ),
// // // // // // // // // // // //                                       const Spacer(),
// // // // // // // // // // // //                                       if (selected)
// // // // // // // // // // // //                                         Icon(
// // // // // // // // // // // //                                           Icons.check_circle_rounded,
// // // // // // // // // // // //                                           color: theme.colorScheme.primary,
// // // // // // // // // // // //                                           size: 18,
// // // // // // // // // // // //                                         ),
// // // // // // // // // // // //                                     ],
// // // // // // // // // // // //                                   ),
// // // // // // // // // // // //                                   const SizedBox(height: 6),
// // // // // // // // // // // //                                   Text(
// // // // // // // // // // // //                                     pack.titleJson['en'] as String? ?? pack.id,
// // // // // // // // // // // //                                     style: theme.textTheme.labelMedium
// // // // // // // // // // // //                                         ?.copyWith(fontWeight: FontWeight.w600),
// // // // // // // // // // // //                                     maxLines: 2,
// // // // // // // // // // // //                                     overflow: TextOverflow.ellipsis,
// // // // // // // // // // // //                                   ),
// // // // // // // // // // // //                                   const SizedBox(height: 4),
// // // // // // // // // // // //                                   Text(
// // // // // // // // // // // //                                     '${pack.cardCount} cards',
// // // // // // // // // // // //                                     style: theme.textTheme.labelSmall?.copyWith(
// // // // // // // // // // // //                                       color: theme.colorScheme.onSurfaceVariant,
// // // // // // // // // // // //                                     ),
// // // // // // // // // // // //                                   ),
// // // // // // // // // // // //                                 ],
// // // // // // // // // // // //                               ),
// // // // // // // // // // // //                             ),
// // // // // // // // // // // //                           );
// // // // // // // // // // // //                         },
// // // // // // // // // // // //                       ),
// // // // // // // // // // // //                     ),
// // // // // // // // // // // //                   const SizedBox(height: 20),
// // // // // // // // // // // //                 ],

// // // // // // // // // // // //                 // ── Game settings ─────────────────────────────────────────────
// // // // // // // // // // // //                 _SliderRow(
// // // // // // // // // // // //                   label: l10n.gameSettingsTurnTimer,
// // // // // // // // // // // //                   value: s.turnTimerSeconds.toDouble(),
// // // // // // // // // // // //                   display: l10n.gameSettingsSeconds(s.turnTimerSeconds),
// // // // // // // // // // // //                   min: 15,
// // // // // // // // // // // //                   max: 120,
// // // // // // // // // // // //                   divisions: 21,
// // // // // // // // // // // //                   onChanged: (v) =>
// // // // // // // // // // // //                       room.updateSetting('turn_timer_secs', v.round()),
// // // // // // // // // // // //                 ),
// // // // // // // // // // // //                 _SliderRow(
// // // // // // // // // // // //                   label: l10n.gameSettingsMaxRounds,
// // // // // // // // // // // //                   value: s.maxRounds.toDouble(),
// // // // // // // // // // // //                   display: '${s.maxRounds}',
// // // // // // // // // // // //                   min: 3,
// // // // // // // // // // // //                   max: 30,
// // // // // // // // // // // //                   divisions: 27,
// // // // // // // // // // // //                   onChanged: (v) => room.updateSetting('max_rounds', v.round()),
// // // // // // // // // // // //                 ),
// // // // // // // // // // // //                 const SizedBox(height: 4),
// // // // // // // // // // // //                 _SwitchRow(
// // // // // // // // // // // //                   label: l10n.gameSettingsAllowSkip,
// // // // // // // // // // // //                   icon: Icons.skip_next_rounded,
// // // // // // // // // // // //                   value: s.allowSkip,
// // // // // // // // // // // //                   onChanged: (v) => room.updateSetting('allow_skip', v),
// // // // // // // // // // // //                 ),
// // // // // // // // // // // //                 _SwitchRow(
// // // // // // // // // // // //                   label: 'Chat',
// // // // // // // // // // // //                   icon: Icons.chat_bubble_outline_rounded,
// // // // // // // // // // // //                   value: s.chatEnabled,
// // // // // // // // // // // //                   onChanged: (v) => room.updateSetting('chat_enabled', v),
// // // // // // // // // // // //                 ),
// // // // // // // // // // // //                 _SwitchRow(
// // // // // // // // // // // //                   label: 'Allow spectators',
// // // // // // // // // // // //                   icon: Icons.visibility_outlined,
// // // // // // // // // // // //                   value: s.allowSpectators,
// // // // // // // // // // // //                   onChanged: (v) => room.updateSetting('allow_spectators', v),
// // // // // // // // // // // //                 ),
// // // // // // // // // // // //                 if (room.room?.allowSpicy == true)
// // // // // // // // // // // //                   _SwitchRow(
// // // // // // // // // // // //                     label: l10n.gameSettingsAllowSpicy,
// // // // // // // // // // // //                     icon: Icons.local_fire_department_outlined,
// // // // // // // // // // // //                     value: room.room?.allowSpicy ?? false,
// // // // // // // // // // // //                     onChanged: null,
// // // // // // // // // // // //                   ),
// // // // // // // // // // // //               ],
// // // // // // // // // // // //             ),
// // // // // // // // // // // //           );
// // // // // // // // // // // //         },
// // // // // // // // // // // //       ),
// // // // // // // // // // // //     );
// // // // // // // // // // // //   }
// // // // // // // // // // // // }

// // // // // // // // // // // // // ── Helpers ───────────────────────────────────────────────────────────────────

// // // // // // // // // // // // extension _PackX on PackEntity {
// // // // // // // // // // // //   String get coverEmoji {
// // // // // // // // // // // //     if (titleJson['en']?.toString().toLowerCase().contains('arabic') == true)
// // // // // // // // // // // //       return '🌙';
// // // // // // // // // // // //     if (titleJson['en']?.toString().toLowerCase().contains('party') == true)
// // // // // // // // // // // //       return '🎉';
// // // // // // // // // // // //     return '🎮';
// // // // // // // // // // // //   }
// // // // // // // // // // // // }

// // // // // // // // // // // // class _SliderRow extends StatelessWidget {
// // // // // // // // // // // //   const _SliderRow({
// // // // // // // // // // // //     required this.label,
// // // // // // // // // // // //     required this.value,
// // // // // // // // // // // //     required this.display,
// // // // // // // // // // // //     required this.min,
// // // // // // // // // // // //     required this.max,
// // // // // // // // // // // //     required this.divisions,
// // // // // // // // // // // //     required this.onChanged,
// // // // // // // // // // // //   });
// // // // // // // // // // // //   final String label;
// // // // // // // // // // // //   final double value;
// // // // // // // // // // // //   final String display;
// // // // // // // // // // // //   final double min, max;
// // // // // // // // // // // //   final int divisions;
// // // // // // // // // // // //   final void Function(double) onChanged;

// // // // // // // // // // // //   @override
// // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // //     final theme = context.theme;
// // // // // // // // // // // //     return Padding(
// // // // // // // // // // // //       padding: const EdgeInsets.symmetric(vertical: 4),
// // // // // // // // // // // //       child: Row(
// // // // // // // // // // // //         children: [
// // // // // // // // // // // //           Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
// // // // // // // // // // // //           Text(
// // // // // // // // // // // //             display,
// // // // // // // // // // // //             style: theme.textTheme.labelMedium?.copyWith(
// // // // // // // // // // // //               color: theme.colorScheme.primary,
// // // // // // // // // // // //               fontWeight: FontWeight.w600,
// // // // // // // // // // // //             ),
// // // // // // // // // // // //           ),
// // // // // // // // // // // //           const SizedBox(width: 8),
// // // // // // // // // // // //           SizedBox(
// // // // // // // // // // // //             width: 120,
// // // // // // // // // // // //             child: Slider(
// // // // // // // // // // // //               value: value.clamp(min, max),
// // // // // // // // // // // //               min: min,
// // // // // // // // // // // //               max: max,
// // // // // // // // // // // //               divisions: divisions,
// // // // // // // // // // // //               onChanged: onChanged,
// // // // // // // // // // // //             ),
// // // // // // // // // // // //           ),
// // // // // // // // // // // //         ],
// // // // // // // // // // // //       ),
// // // // // // // // // // // //     );
// // // // // // // // // // // //   }
// // // // // // // // // // // // }

// // // // // // // // // // // // class _SwitchRow extends StatelessWidget {
// // // // // // // // // // // //   const _SwitchRow({
// // // // // // // // // // // //     required this.label,
// // // // // // // // // // // //     required this.icon,
// // // // // // // // // // // //     required this.value,
// // // // // // // // // // // //     required this.onChanged,
// // // // // // // // // // // //   });
// // // // // // // // // // // //   final String label;
// // // // // // // // // // // //   final IconData icon;
// // // // // // // // // // // //   final bool value;
// // // // // // // // // // // //   final void Function(bool)? onChanged;

// // // // // // // // // // // //   @override
// // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // //     final theme = context.theme;
// // // // // // // // // // // //     return Padding(
// // // // // // // // // // // //       padding: const EdgeInsets.symmetric(vertical: 2),
// // // // // // // // // // // //       child: Row(
// // // // // // // // // // // //         children: [
// // // // // // // // // // // //           Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
// // // // // // // // // // // //           const SizedBox(width: 12),
// // // // // // // // // // // //           Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
// // // // // // // // // // // //           Switch(value: value, onChanged: onChanged),
// // // // // // // // // // // //         ],
// // // // // // // // // // // //       ),
// // // // // // // // // // // //     );
// // // // // // // // // // // //   }
// // // // // // // // // // // // }

// // // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // // // // import '../../../../core/extensions/context_ext.dart';
// // // // // // // // // // // import '../../../../core/theme/app_colors.dart';
// // // // // // // // // // // import '../../../packs/data/pack_repository.dart';
// // // // // // // // // // // import '../../../packs/domain/pack_entity.dart';
// // // // // // // // // // // import '../room_provider.dart';

// // // // // // // // // // // class GameSettingsSheet extends StatefulWidget {
// // // // // // // // // // //   const GameSettingsSheet({super.key});

// // // // // // // // // // //   @override
// // // // // // // // // // //   State<GameSettingsSheet> createState() => _GameSettingsSheetState();
// // // // // // // // // // // }

// // // // // // // // // // // class _GameSettingsSheetState extends State<GameSettingsSheet> {
// // // // // // // // // // //   List<PackEntity> _packs = [];
// // // // // // // // // // //   bool _loadingPacks = true;

// // // // // // // // // // //   @override
// // // // // // // // // // //   void initState() {
// // // // // // // // // // //     super.initState();
// // // // // // // // // // //     _loadPacks();
// // // // // // // // // // //   }

// // // // // // // // // // //   Future<void> _loadPacks() async {
// // // // // // // // // // //     try {
// // // // // // // // // // //       final packs = await PackRepository.instance.browsePacks(perPage: 50);
// // // // // // // // // // //       if (mounted)
// // // // // // // // // // //         setState(() {
// // // // // // // // // // //           _packs = packs;
// // // // // // // // // // //           _loadingPacks = false;
// // // // // // // // // // //         });
// // // // // // // // // // //     } catch (e) {
// // // // // // // // // // //       if (mounted) setState(() => _loadingPacks = false);
// // // // // // // // // // //     }
// // // // // // // // // // //   }

// // // // // // // // // // //   @override
// // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // //     final theme = context.theme;
// // // // // // // // // // //     final l10n = context.l10n;

// // // // // // // // // // //     return Container(
// // // // // // // // // // //       decoration: BoxDecoration(
// // // // // // // // // // //         color: theme.colorScheme.surface,
// // // // // // // // // // //         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
// // // // // // // // // // //       ),
// // // // // // // // // // //       padding: EdgeInsets.fromLTRB(
// // // // // // // // // // //         24,
// // // // // // // // // // //         12,
// // // // // // // // // // //         24,
// // // // // // // // // // //         MediaQuery.viewInsetsOf(context).bottom + 24,
// // // // // // // // // // //       ),
// // // // // // // // // // //       child: Consumer<RoomProvider>(
// // // // // // // // // // //         builder: (_, room, __) {
// // // // // // // // // // //           final s = room.settings;
// // // // // // // // // // //           return SingleChildScrollView(
// // // // // // // // // // //             child: Column(
// // // // // // // // // // //               mainAxisSize: MainAxisSize.min,
// // // // // // // // // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // // // // //               children: [
// // // // // // // // // // //                 // Handle
// // // // // // // // // // //                 Center(
// // // // // // // // // // //                   child: Container(
// // // // // // // // // // //                     width: 36,
// // // // // // // // // // //                     height: 4,
// // // // // // // // // // //                     decoration: BoxDecoration(
// // // // // // // // // // //                       color: theme.colorScheme.outlineVariant,
// // // // // // // // // // //                       borderRadius: BorderRadius.circular(2),
// // // // // // // // // // //                     ),
// // // // // // // // // // //                   ),
// // // // // // // // // // //                 ),
// // // // // // // // // // //                 const SizedBox(height: 20),

// // // // // // // // // // //                 Text(
// // // // // // // // // // //                   l10n.gameSettings,
// // // // // // // // // // //                   style: theme.textTheme.titleLarge?.copyWith(
// // // // // // // // // // //                     fontWeight: FontWeight.w700,
// // // // // // // // // // //                   ),
// // // // // // // // // // //                 ),
// // // // // // // // // // //                 const SizedBox(height: 20),

// // // // // // // // // // //                 // ── Pack picker ───────────────────────────────────────────────
// // // // // // // // // // //                 if (room.isOwner) ...[
// // // // // // // // // // //                   Text(
// // // // // // // // // // //                     'Select Pack',
// // // // // // // // // // //                     style: theme.textTheme.labelLarge?.copyWith(
// // // // // // // // // // //                       fontWeight: FontWeight.w600,
// // // // // // // // // // //                     ),
// // // // // // // // // // //                   ),
// // // // // // // // // // //                   const SizedBox(height: 8),
// // // // // // // // // // //                   if (_loadingPacks)
// // // // // // // // // // //                     const Padding(
// // // // // // // // // // //                       padding: EdgeInsets.symmetric(vertical: 16),
// // // // // // // // // // //                       child: Center(child: CircularProgressIndicator()),
// // // // // // // // // // //                     )
// // // // // // // // // // //                   else if (_packs.isEmpty)
// // // // // // // // // // //                     Container(
// // // // // // // // // // //                       padding: const EdgeInsets.all(16),
// // // // // // // // // // //                       decoration: BoxDecoration(
// // // // // // // // // // //                         color: theme.colorScheme.surfaceContainerHighest,
// // // // // // // // // // //                         borderRadius: BorderRadius.circular(12),
// // // // // // // // // // //                       ),
// // // // // // // // // // //                       child: Row(
// // // // // // // // // // //                         children: [
// // // // // // // // // // //                           Icon(
// // // // // // // // // // //                             Icons.info_outline,
// // // // // // // // // // //                             color: theme.colorScheme.onSurfaceVariant,
// // // // // // // // // // //                           ),
// // // // // // // // // // //                           const SizedBox(width: 12),
// // // // // // // // // // //                           Expanded(
// // // // // // // // // // //                             child: Text(
// // // // // // // // // // //                               'No packs available. Run the seed SQL in Supabase.',
// // // // // // // // // // //                               style: theme.textTheme.bodySmall,
// // // // // // // // // // //                             ),
// // // // // // // // // // //                           ),
// // // // // // // // // // //                         ],
// // // // // // // // // // //                       ),
// // // // // // // // // // //                     )
// // // // // // // // // // //                   else
// // // // // // // // // // //                     SizedBox(
// // // // // // // // // // //                       height: 110,
// // // // // // // // // // //                       child: ListView.separated(
// // // // // // // // // // //                         scrollDirection: Axis.horizontal,
// // // // // // // // // // //                         itemCount: _packs.length,
// // // // // // // // // // //                         separatorBuilder: (_, __) => const SizedBox(width: 10),
// // // // // // // // // // //                         itemBuilder: (ctx, i) {
// // // // // // // // // // //                           final pack = _packs[i];
// // // // // // // // // // //                           final selected = room.room?.packId == pack.id;
// // // // // // // // // // //                           return GestureDetector(
// // // // // // // // // // //                             onTap: () => room.setPackId(pack.id),
// // // // // // // // // // //                             child: AnimatedContainer(
// // // // // // // // // // //                               duration: const Duration(milliseconds: 180),
// // // // // // // // // // //                               width: 140,
// // // // // // // // // // //                               padding: const EdgeInsets.all(12),
// // // // // // // // // // //                               decoration: BoxDecoration(
// // // // // // // // // // //                                 color: selected
// // // // // // // // // // //                                     ? theme.colorScheme.primaryContainer
// // // // // // // // // // //                                     : theme.colorScheme.surfaceContainerHighest,
// // // // // // // // // // //                                 borderRadius: BorderRadius.circular(12),
// // // // // // // // // // //                                 border: Border.all(
// // // // // // // // // // //                                   color: selected
// // // // // // // // // // //                                       ? theme.colorScheme.primary
// // // // // // // // // // //                                       : Colors.transparent,
// // // // // // // // // // //                                   width: 2,
// // // // // // // // // // //                                 ),
// // // // // // // // // // //                               ),
// // // // // // // // // // //                               child: Column(
// // // // // // // // // // //                                 crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // // // // //                                 children: [
// // // // // // // // // // //                                   Row(
// // // // // // // // // // //                                     children: [
// // // // // // // // // // //                                       Text(
// // // // // // // // // // //                                         pack.coverEmoji,
// // // // // // // // // // //                                         style: const TextStyle(fontSize: 20),
// // // // // // // // // // //                                       ),
// // // // // // // // // // //                                       const Spacer(),
// // // // // // // // // // //                                       if (selected)
// // // // // // // // // // //                                         Icon(
// // // // // // // // // // //                                           Icons.check_circle_rounded,
// // // // // // // // // // //                                           color: theme.colorScheme.primary,
// // // // // // // // // // //                                           size: 18,
// // // // // // // // // // //                                         ),
// // // // // // // // // // //                                     ],
// // // // // // // // // // //                                   ),
// // // // // // // // // // //                                   const SizedBox(height: 6),
// // // // // // // // // // //                                   Text(
// // // // // // // // // // //                                     pack.titleJson['en'] as String? ?? pack.id,
// // // // // // // // // // //                                     style: theme.textTheme.labelMedium
// // // // // // // // // // //                                         ?.copyWith(fontWeight: FontWeight.w600),
// // // // // // // // // // //                                     maxLines: 2,
// // // // // // // // // // //                                     overflow: TextOverflow.ellipsis,
// // // // // // // // // // //                                   ),
// // // // // // // // // // //                                   const SizedBox(height: 4),
// // // // // // // // // // //                                   Text(
// // // // // // // // // // //                                     '${pack.cardCount} cards',
// // // // // // // // // // //                                     style: theme.textTheme.labelSmall?.copyWith(
// // // // // // // // // // //                                       color: theme.colorScheme.onSurfaceVariant,
// // // // // // // // // // //                                     ),
// // // // // // // // // // //                                   ),
// // // // // // // // // // //                                 ],
// // // // // // // // // // //                               ),
// // // // // // // // // // //                             ),
// // // // // // // // // // //                           );
// // // // // // // // // // //                         },
// // // // // // // // // // //                       ),
// // // // // // // // // // //                     ),
// // // // // // // // // // //                   const SizedBox(height: 20),
// // // // // // // // // // //                 ],

// // // // // // // // // // //                 // ── Game settings ─────────────────────────────────────────────
// // // // // // // // // // //                 _SliderRow(
// // // // // // // // // // //                   label: l10n.gameSettingsTurnTimer,
// // // // // // // // // // //                   value: s.turnTimerSeconds.toDouble(),
// // // // // // // // // // //                   display: l10n.gameSettingsSeconds(s.turnTimerSeconds),
// // // // // // // // // // //                   min: 15,
// // // // // // // // // // //                   max: 120,
// // // // // // // // // // //                   divisions: 21,
// // // // // // // // // // //                   onChanged: (v) =>
// // // // // // // // // // //                       room.updateSetting('turn_timer_secs', v.round()),
// // // // // // // // // // //                 ),
// // // // // // // // // // //                 _SliderRow(
// // // // // // // // // // //                   label: l10n.gameSettingsMaxRounds,
// // // // // // // // // // //                   value: s.maxRounds.toDouble(),
// // // // // // // // // // //                   display: '${s.maxRounds}',
// // // // // // // // // // //                   min: 3,
// // // // // // // // // // //                   max: 30,
// // // // // // // // // // //                   divisions: 27,
// // // // // // // // // // //                   onChanged: (v) => room.updateSetting('max_rounds', v.round()),
// // // // // // // // // // //                 ),
// // // // // // // // // // //                 const SizedBox(height: 4),
// // // // // // // // // // //                 _SwitchRow(
// // // // // // // // // // //                   label: l10n.gameSettingsAllowSkip,
// // // // // // // // // // //                   icon: Icons.skip_next_rounded,
// // // // // // // // // // //                   value: s.allowSkip,
// // // // // // // // // // //                   onChanged: (v) => room.updateSetting('allow_skip', v),
// // // // // // // // // // //                 ),
// // // // // // // // // // //                 _SwitchRow(
// // // // // // // // // // //                   label: 'Chat',
// // // // // // // // // // //                   icon: Icons.chat_bubble_outline_rounded,
// // // // // // // // // // //                   value: s.chatEnabled,
// // // // // // // // // // //                   onChanged: (v) => room.updateSetting('chat_enabled', v),
// // // // // // // // // // //                 ),
// // // // // // // // // // //                 _SwitchRow(
// // // // // // // // // // //                   label: 'Allow spectators',
// // // // // // // // // // //                   icon: Icons.visibility_outlined,
// // // // // // // // // // //                   value: s.allowSpectators,
// // // // // // // // // // //                   onChanged: (v) => room.updateSetting('allow_spectators', v),
// // // // // // // // // // //                 ),
// // // // // // // // // // //                 if (room.room?.allowSpicy == true)
// // // // // // // // // // //                   _SwitchRow(
// // // // // // // // // // //                     label: l10n.gameSettingsAllowSpicy,
// // // // // // // // // // //                     icon: Icons.local_fire_department_outlined,
// // // // // // // // // // //                     value: room.room?.allowSpicy ?? false,
// // // // // // // // // // //                     onChanged: null,
// // // // // // // // // // //                   ),
// // // // // // // // // // //               ],
// // // // // // // // // // //             ),
// // // // // // // // // // //           );
// // // // // // // // // // //         },
// // // // // // // // // // //       ),
// // // // // // // // // // //     );
// // // // // // // // // // //   }
// // // // // // // // // // // }

// // // // // // // // // // // // ── Helpers ───────────────────────────────────────────────────────────────────

// // // // // // // // // // // extension _PackX on PackEntity {
// // // // // // // // // // //   String get coverEmoji {
// // // // // // // // // // //     if (titleJson['en']?.toString().toLowerCase().contains('arabic') == true)
// // // // // // // // // // //       return '🌙';
// // // // // // // // // // //     if (titleJson['en']?.toString().toLowerCase().contains('party') == true)
// // // // // // // // // // //       return '🎉';
// // // // // // // // // // //     return '🎮';
// // // // // // // // // // //   }
// // // // // // // // // // // }

// // // // // // // // // // // class _SliderRow extends StatelessWidget {
// // // // // // // // // // //   const _SliderRow({
// // // // // // // // // // //     required this.label,
// // // // // // // // // // //     required this.value,
// // // // // // // // // // //     required this.display,
// // // // // // // // // // //     required this.min,
// // // // // // // // // // //     required this.max,
// // // // // // // // // // //     required this.divisions,
// // // // // // // // // // //     required this.onChanged,
// // // // // // // // // // //   });
// // // // // // // // // // //   final String label;
// // // // // // // // // // //   final double value;
// // // // // // // // // // //   final String display;
// // // // // // // // // // //   final double min, max;
// // // // // // // // // // //   final int divisions;
// // // // // // // // // // //   final void Function(double) onChanged;

// // // // // // // // // // //   @override
// // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // //     final theme = context.theme;
// // // // // // // // // // //     return Padding(
// // // // // // // // // // //       padding: const EdgeInsets.symmetric(vertical: 4),
// // // // // // // // // // //       child: Row(
// // // // // // // // // // //         children: [
// // // // // // // // // // //           Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
// // // // // // // // // // //           Text(
// // // // // // // // // // //             display,
// // // // // // // // // // //             style: theme.textTheme.labelMedium?.copyWith(
// // // // // // // // // // //               color: theme.colorScheme.primary,
// // // // // // // // // // //               fontWeight: FontWeight.w600,
// // // // // // // // // // //             ),
// // // // // // // // // // //           ),
// // // // // // // // // // //           const SizedBox(width: 8),
// // // // // // // // // // //           SizedBox(
// // // // // // // // // // //             width: 120,
// // // // // // // // // // //             child: Slider(
// // // // // // // // // // //               value: value.clamp(min, max),
// // // // // // // // // // //               min: min,
// // // // // // // // // // //               max: max,
// // // // // // // // // // //               divisions: divisions,
// // // // // // // // // // //               onChanged: onChanged,
// // // // // // // // // // //             ),
// // // // // // // // // // //           ),
// // // // // // // // // // //         ],
// // // // // // // // // // //       ),
// // // // // // // // // // //     );
// // // // // // // // // // //   }
// // // // // // // // // // // }

// // // // // // // // // // // class _SwitchRow extends StatelessWidget {
// // // // // // // // // // //   const _SwitchRow({
// // // // // // // // // // //     required this.label,
// // // // // // // // // // //     required this.icon,
// // // // // // // // // // //     required this.value,
// // // // // // // // // // //     required this.onChanged,
// // // // // // // // // // //   });
// // // // // // // // // // //   final String label;
// // // // // // // // // // //   final IconData icon;
// // // // // // // // // // //   final bool value;
// // // // // // // // // // //   final void Function(bool)? onChanged;

// // // // // // // // // // //   @override
// // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // //     final theme = context.theme;
// // // // // // // // // // //     return Padding(
// // // // // // // // // // //       padding: const EdgeInsets.symmetric(vertical: 2),
// // // // // // // // // // //       child: Row(
// // // // // // // // // // //         children: [
// // // // // // // // // // //           Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
// // // // // // // // // // //           const SizedBox(width: 12),
// // // // // // // // // // //           Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
// // // // // // // // // // //           Switch(value: value, onChanged: onChanged),
// // // // // // // // // // //         ],
// // // // // // // // // // //       ),
// // // // // // // // // // //     );
// // // // // // // // // // //   }
// // // // // // // // // // // }

// // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // // // import '../../../../core/extensions/context_ext.dart';
// // // // // // // // // // import '../../../../core/theme/app_colors.dart';
// // // // // // // // // // import '../../../packs/data/pack_repository.dart';
// // // // // // // // // // import '../../../packs/domain/pack_entity.dart';
// // // // // // // // // // import '../../../packs/presentation/pack_provider.dart';
// // // // // // // // // // import '../room_provider.dart';

// // // // // // // // // // class GameSettingsSheet extends StatefulWidget {
// // // // // // // // // //   const GameSettingsSheet({super.key});

// // // // // // // // // //   @override
// // // // // // // // // //   State<GameSettingsSheet> createState() => _GameSettingsSheetState();
// // // // // // // // // // }

// // // // // // // // // // class _GameSettingsSheetState extends State<GameSettingsSheet> {
// // // // // // // // // //   List<PackEntity> _packs = [];
// // // // // // // // // //   bool _loadingPacks = true;

// // // // // // // // // //   @override
// // // // // // // // // //   void initState() {
// // // // // // // // // //     super.initState();
// // // // // // // // // //     _loadPacks();
// // // // // // // // // //   }

// // // // // // // // // //   Future<void> _loadPacks() async {
// // // // // // // // // //     try {
// // // // // // // // // //       final packProvider = context.read<PackProvider>();
// // // // // // // // // //       // Only show packs the user owns (purchased or free+downloaded)
// // // // // // // // // //       final owned = [
// // // // // // // // // //         ...packProvider.purchasedPacks,
// // // // // // // // // //         ...packProvider.localPacks,
// // // // // // // // // //         ...packProvider.browsePacks.where((p) => p.isFree),
// // // // // // // // // //       ];
// // // // // // // // // //       // Deduplicate by id
// // // // // // // // // //       final seen = <String>{};
// // // // // // // // // //       final unique = owned.where((p) => seen.add(p.id)).toList();
// // // // // // // // // //       if (mounted)
// // // // // // // // // //         setState(() {
// // // // // // // // // //           _packs = unique;
// // // // // // // // // //           _loadingPacks = false;
// // // // // // // // // //         });
// // // // // // // // // //     } catch (e) {
// // // // // // // // // //       if (mounted) setState(() => _loadingPacks = false);
// // // // // // // // // //     }
// // // // // // // // // //   }

// // // // // // // // // //   @override
// // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // //     final theme = context.theme;
// // // // // // // // // //     final l10n = context.l10n;

// // // // // // // // // //     return Container(
// // // // // // // // // //       decoration: BoxDecoration(
// // // // // // // // // //         color: theme.colorScheme.surface,
// // // // // // // // // //         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
// // // // // // // // // //       ),
// // // // // // // // // //       padding: EdgeInsets.fromLTRB(
// // // // // // // // // //         24,
// // // // // // // // // //         12,
// // // // // // // // // //         24,
// // // // // // // // // //         MediaQuery.viewInsetsOf(context).bottom + 24,
// // // // // // // // // //       ),
// // // // // // // // // //       child: Consumer<RoomProvider>(
// // // // // // // // // //         builder: (_, room, __) {
// // // // // // // // // //           final s = room.settings;
// // // // // // // // // //           return SingleChildScrollView(
// // // // // // // // // //             child: Column(
// // // // // // // // // //               mainAxisSize: MainAxisSize.min,
// // // // // // // // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // // // //               children: [
// // // // // // // // // //                 // Handle
// // // // // // // // // //                 Center(
// // // // // // // // // //                   child: Container(
// // // // // // // // // //                     width: 36,
// // // // // // // // // //                     height: 4,
// // // // // // // // // //                     decoration: BoxDecoration(
// // // // // // // // // //                       color: theme.colorScheme.outlineVariant,
// // // // // // // // // //                       borderRadius: BorderRadius.circular(2),
// // // // // // // // // //                     ),
// // // // // // // // // //                   ),
// // // // // // // // // //                 ),
// // // // // // // // // //                 const SizedBox(height: 20),

// // // // // // // // // //                 Text(
// // // // // // // // // //                   l10n.gameSettings,
// // // // // // // // // //                   style: theme.textTheme.titleLarge?.copyWith(
// // // // // // // // // //                     fontWeight: FontWeight.w700,
// // // // // // // // // //                   ),
// // // // // // // // // //                 ),
// // // // // // // // // //                 const SizedBox(height: 20),

// // // // // // // // // //                 // ── Pack picker ───────────────────────────────────────────────
// // // // // // // // // //                 if (room.isOwner) ...[
// // // // // // // // // //                   Text(
// // // // // // // // // //                     'Select Pack',
// // // // // // // // // //                     style: theme.textTheme.labelLarge?.copyWith(
// // // // // // // // // //                       fontWeight: FontWeight.w600,
// // // // // // // // // //                     ),
// // // // // // // // // //                   ),
// // // // // // // // // //                   const SizedBox(height: 8),
// // // // // // // // // //                   if (_loadingPacks)
// // // // // // // // // //                     const Padding(
// // // // // // // // // //                       padding: EdgeInsets.symmetric(vertical: 16),
// // // // // // // // // //                       child: Center(child: CircularProgressIndicator()),
// // // // // // // // // //                     )
// // // // // // // // // //                   else if (_packs.isEmpty)
// // // // // // // // // //                     Container(
// // // // // // // // // //                       padding: const EdgeInsets.all(16),
// // // // // // // // // //                       decoration: BoxDecoration(
// // // // // // // // // //                         color: theme.colorScheme.surfaceContainerHighest,
// // // // // // // // // //                         borderRadius: BorderRadius.circular(12),
// // // // // // // // // //                       ),
// // // // // // // // // //                       child: Row(
// // // // // // // // // //                         children: [
// // // // // // // // // //                           Icon(
// // // // // // // // // //                             Icons.info_outline,
// // // // // // // // // //                             color: theme.colorScheme.onSurfaceVariant,
// // // // // // // // // //                           ),
// // // // // // // // // //                           const SizedBox(width: 12),
// // // // // // // // // //                           Expanded(
// // // // // // // // // //                             child: Text(
// // // // // // // // // //                               'No packs available. Run the seed SQL in Supabase.',
// // // // // // // // // //                               style: theme.textTheme.bodySmall,
// // // // // // // // // //                             ),
// // // // // // // // // //                           ),
// // // // // // // // // //                         ],
// // // // // // // // // //                       ),
// // // // // // // // // //                     )
// // // // // // // // // //                   else
// // // // // // // // // //                     SizedBox(
// // // // // // // // // //                       height: 110,
// // // // // // // // // //                       child: ListView.separated(
// // // // // // // // // //                         scrollDirection: Axis.horizontal,
// // // // // // // // // //                         itemCount: _packs.length,
// // // // // // // // // //                         separatorBuilder: (_, __) => const SizedBox(width: 10),
// // // // // // // // // //                         itemBuilder: (ctx, i) {
// // // // // // // // // //                           final pack = _packs[i];
// // // // // // // // // //                           final selected = room.room?.packId == pack.id;
// // // // // // // // // //                           return GestureDetector(
// // // // // // // // // //                             onTap: () => room.setPackId(pack.id),
// // // // // // // // // //                             child: AnimatedContainer(
// // // // // // // // // //                               duration: const Duration(milliseconds: 180),
// // // // // // // // // //                               width: 140,
// // // // // // // // // //                               padding: const EdgeInsets.all(12),
// // // // // // // // // //                               decoration: BoxDecoration(
// // // // // // // // // //                                 color: selected
// // // // // // // // // //                                     ? theme.colorScheme.primaryContainer
// // // // // // // // // //                                     : theme.colorScheme.surfaceContainerHighest,
// // // // // // // // // //                                 borderRadius: BorderRadius.circular(12),
// // // // // // // // // //                                 border: Border.all(
// // // // // // // // // //                                   color: selected
// // // // // // // // // //                                       ? theme.colorScheme.primary
// // // // // // // // // //                                       : Colors.transparent,
// // // // // // // // // //                                   width: 2,
// // // // // // // // // //                                 ),
// // // // // // // // // //                               ),
// // // // // // // // // //                               child: Column(
// // // // // // // // // //                                 crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // // // //                                 children: [
// // // // // // // // // //                                   Row(
// // // // // // // // // //                                     children: [
// // // // // // // // // //                                       Text(
// // // // // // // // // //                                         pack.coverEmoji,
// // // // // // // // // //                                         style: const TextStyle(fontSize: 20),
// // // // // // // // // //                                       ),
// // // // // // // // // //                                       const Spacer(),
// // // // // // // // // //                                       if (selected)
// // // // // // // // // //                                         Icon(
// // // // // // // // // //                                           Icons.check_circle_rounded,
// // // // // // // // // //                                           color: theme.colorScheme.primary,
// // // // // // // // // //                                           size: 18,
// // // // // // // // // //                                         ),
// // // // // // // // // //                                     ],
// // // // // // // // // //                                   ),
// // // // // // // // // //                                   const SizedBox(height: 6),
// // // // // // // // // //                                   Text(
// // // // // // // // // //                                     pack.titleJson['en'] as String? ?? pack.id,
// // // // // // // // // //                                     style: theme.textTheme.labelMedium
// // // // // // // // // //                                         ?.copyWith(fontWeight: FontWeight.w600),
// // // // // // // // // //                                     maxLines: 2,
// // // // // // // // // //                                     overflow: TextOverflow.ellipsis,
// // // // // // // // // //                                   ),
// // // // // // // // // //                                   const SizedBox(height: 4),
// // // // // // // // // //                                   Text(
// // // // // // // // // //                                     '${pack.cardCount} cards',
// // // // // // // // // //                                     style: theme.textTheme.labelSmall?.copyWith(
// // // // // // // // // //                                       color: theme.colorScheme.onSurfaceVariant,
// // // // // // // // // //                                     ),
// // // // // // // // // //                                   ),
// // // // // // // // // //                                 ],
// // // // // // // // // //                               ),
// // // // // // // // // //                             ),
// // // // // // // // // //                           );
// // // // // // // // // //                         },
// // // // // // // // // //                       ),
// // // // // // // // // //                     ),
// // // // // // // // // //                   const SizedBox(height: 20),
// // // // // // // // // //                 ],

// // // // // // // // // //                 // ── Game settings ─────────────────────────────────────────────
// // // // // // // // // //                 _SliderRow(
// // // // // // // // // //                   label: l10n.gameSettingsTurnTimer,
// // // // // // // // // //                   value: s.turnTimerSeconds.toDouble(),
// // // // // // // // // //                   display: l10n.gameSettingsSeconds(s.turnTimerSeconds),
// // // // // // // // // //                   min: 15,
// // // // // // // // // //                   max: 120,
// // // // // // // // // //                   divisions: 21,
// // // // // // // // // //                   onChanged: (v) =>
// // // // // // // // // //                       room.updateSetting('turn_timer_secs', v.round()),
// // // // // // // // // //                 ),
// // // // // // // // // //                 _SliderRow(
// // // // // // // // // //                   label: l10n.gameSettingsMaxRounds,
// // // // // // // // // //                   value: s.maxRounds.toDouble(),
// // // // // // // // // //                   display: '${s.maxRounds}',
// // // // // // // // // //                   min: 3,
// // // // // // // // // //                   max: 30,
// // // // // // // // // //                   divisions: 27,
// // // // // // // // // //                   onChanged: (v) => room.updateSetting('max_rounds', v.round()),
// // // // // // // // // //                 ),
// // // // // // // // // //                 const SizedBox(height: 4),
// // // // // // // // // //                 _SwitchRow(
// // // // // // // // // //                   label: l10n.gameSettingsAllowSkip,
// // // // // // // // // //                   icon: Icons.skip_next_rounded,
// // // // // // // // // //                   value: s.allowSkip,
// // // // // // // // // //                   onChanged: (v) => room.updateSetting('allow_skip', v),
// // // // // // // // // //                 ),
// // // // // // // // // //                 _SwitchRow(
// // // // // // // // // //                   label: 'Chat',
// // // // // // // // // //                   icon: Icons.chat_bubble_outline_rounded,
// // // // // // // // // //                   value: s.chatEnabled,
// // // // // // // // // //                   onChanged: (v) => room.updateSetting('chat_enabled', v),
// // // // // // // // // //                 ),
// // // // // // // // // //                 _SwitchRow(
// // // // // // // // // //                   label: 'Allow spectators',
// // // // // // // // // //                   icon: Icons.visibility_outlined,
// // // // // // // // // //                   value: s.allowSpectators,
// // // // // // // // // //                   onChanged: (v) => room.updateSetting('allow_spectators', v),
// // // // // // // // // //                 ),
// // // // // // // // // //                 if (room.room?.allowSpicy == true)
// // // // // // // // // //                   _SwitchRow(
// // // // // // // // // //                     label: l10n.gameSettingsAllowSpicy,
// // // // // // // // // //                     icon: Icons.local_fire_department_outlined,
// // // // // // // // // //                     value: room.room?.allowSpicy ?? false,
// // // // // // // // // //                     onChanged: null,
// // // // // // // // // //                   ),
// // // // // // // // // //               ],
// // // // // // // // // //             ),
// // // // // // // // // //           );
// // // // // // // // // //         },
// // // // // // // // // //       ),
// // // // // // // // // //     );
// // // // // // // // // //   }
// // // // // // // // // // }

// // // // // // // // // // // ── Helpers ───────────────────────────────────────────────────────────────────

// // // // // // // // // // extension _PackX on PackEntity {
// // // // // // // // // //   String get coverEmoji {
// // // // // // // // // //     if (titleJson['en']?.toString().toLowerCase().contains('arabic') == true)
// // // // // // // // // //       return '🌙';
// // // // // // // // // //     if (titleJson['en']?.toString().toLowerCase().contains('party') == true)
// // // // // // // // // //       return '🎉';
// // // // // // // // // //     return '🎮';
// // // // // // // // // //   }
// // // // // // // // // // }

// // // // // // // // // // class _SliderRow extends StatelessWidget {
// // // // // // // // // //   const _SliderRow({
// // // // // // // // // //     required this.label,
// // // // // // // // // //     required this.value,
// // // // // // // // // //     required this.display,
// // // // // // // // // //     required this.min,
// // // // // // // // // //     required this.max,
// // // // // // // // // //     required this.divisions,
// // // // // // // // // //     required this.onChanged,
// // // // // // // // // //   });
// // // // // // // // // //   final String label;
// // // // // // // // // //   final double value;
// // // // // // // // // //   final String display;
// // // // // // // // // //   final double min, max;
// // // // // // // // // //   final int divisions;
// // // // // // // // // //   final void Function(double) onChanged;

// // // // // // // // // //   @override
// // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // //     final theme = context.theme;
// // // // // // // // // //     return Padding(
// // // // // // // // // //       padding: const EdgeInsets.symmetric(vertical: 4),
// // // // // // // // // //       child: Row(
// // // // // // // // // //         children: [
// // // // // // // // // //           Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
// // // // // // // // // //           Text(
// // // // // // // // // //             display,
// // // // // // // // // //             style: theme.textTheme.labelMedium?.copyWith(
// // // // // // // // // //               color: theme.colorScheme.primary,
// // // // // // // // // //               fontWeight: FontWeight.w600,
// // // // // // // // // //             ),
// // // // // // // // // //           ),
// // // // // // // // // //           const SizedBox(width: 8),
// // // // // // // // // //           SizedBox(
// // // // // // // // // //             width: 120,
// // // // // // // // // //             child: Slider(
// // // // // // // // // //               value: value.clamp(min, max),
// // // // // // // // // //               min: min,
// // // // // // // // // //               max: max,
// // // // // // // // // //               divisions: divisions,
// // // // // // // // // //               onChanged: onChanged,
// // // // // // // // // //             ),
// // // // // // // // // //           ),
// // // // // // // // // //         ],
// // // // // // // // // //       ),
// // // // // // // // // //     );
// // // // // // // // // //   }
// // // // // // // // // // }

// // // // // // // // // // class _SwitchRow extends StatelessWidget {
// // // // // // // // // //   const _SwitchRow({
// // // // // // // // // //     required this.label,
// // // // // // // // // //     required this.icon,
// // // // // // // // // //     required this.value,
// // // // // // // // // //     required this.onChanged,
// // // // // // // // // //   });
// // // // // // // // // //   final String label;
// // // // // // // // // //   final IconData icon;
// // // // // // // // // //   final bool value;
// // // // // // // // // //   final void Function(bool)? onChanged;

// // // // // // // // // //   @override
// // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // //     final theme = context.theme;
// // // // // // // // // //     return Padding(
// // // // // // // // // //       padding: const EdgeInsets.symmetric(vertical: 2),
// // // // // // // // // //       child: Row(
// // // // // // // // // //         children: [
// // // // // // // // // //           Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
// // // // // // // // // //           const SizedBox(width: 12),
// // // // // // // // // //           Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
// // // // // // // // // //           Switch(value: value, onChanged: onChanged),
// // // // // // // // // //         ],
// // // // // // // // // //       ),
// // // // // // // // // //     );
// // // // // // // // // //   }
// // // // // // // // // // }

// // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // // import '../../../../core/extensions/context_ext.dart';
// // // // // // // // // import '../../../../core/theme/app_colors.dart';
// // // // // // // // // import '../../../packs/data/pack_repository.dart';
// // // // // // // // // import '../../../packs/domain/pack_entity.dart';
// // // // // // // // // import '../../../packs/presentation/pack_provider.dart';
// // // // // // // // // import '../room_provider.dart';

// // // // // // // // // class GameSettingsSheet extends StatefulWidget {
// // // // // // // // //   const GameSettingsSheet({super.key});

// // // // // // // // //   @override
// // // // // // // // //   State<GameSettingsSheet> createState() => _GameSettingsSheetState();
// // // // // // // // // }

// // // // // // // // // class _GameSettingsSheetState extends State<GameSettingsSheet> {
// // // // // // // // //   List<PackEntity> _packs = [];
// // // // // // // // //   bool _loadingPacks = true;

// // // // // // // // //   @override
// // // // // // // // //   void initState() {
// // // // // // // // //     super.initState();
// // // // // // // // //     _loadPacks();
// // // // // // // // //   }

// // // // // // // // //   Future<void> _loadPacks() async {
// // // // // // // // //     try {
// // // // // // // // //       final packProvider = context.read<PackProvider>();
// // // // // // // // //       // Only show packs the user owns (purchased or free+downloaded)
// // // // // // // // //       final owned = [
// // // // // // // // //         ...packProvider.purchasedPacks,
// // // // // // // // //         ...packProvider.localPacks,
// // // // // // // // //         ...packProvider.browsePacks.where((p) => p.isFree),
// // // // // // // // //       ];
// // // // // // // // //       // Deduplicate by id
// // // // // // // // //       final seen = <String>{};
// // // // // // // // //       final unique = owned.where((p) => seen.add(p.id)).toList();
// // // // // // // // //       if (mounted)
// // // // // // // // //         setState(() {
// // // // // // // // //           _packs = unique;
// // // // // // // // //           _loadingPacks = false;
// // // // // // // // //         });
// // // // // // // // //     } catch (e) {
// // // // // // // // //       if (mounted) setState(() => _loadingPacks = false);
// // // // // // // // //     }
// // // // // // // // //   }

// // // // // // // // //   @override
// // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // //     final theme = context.theme;
// // // // // // // // //     final l10n = context.l10n;

// // // // // // // // //     return Container(
// // // // // // // // //       decoration: BoxDecoration(
// // // // // // // // //         color: theme.colorScheme.surface,
// // // // // // // // //         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
// // // // // // // // //       ),
// // // // // // // // //       padding: EdgeInsets.fromLTRB(
// // // // // // // // //         24,
// // // // // // // // //         12,
// // // // // // // // //         24,
// // // // // // // // //         MediaQuery.viewInsetsOf(context).bottom + 24,
// // // // // // // // //       ),
// // // // // // // // //       child: Consumer<RoomProvider>(
// // // // // // // // //         builder: (_, room, __) {
// // // // // // // // //           final s = room.settings;
// // // // // // // // //           return SingleChildScrollView(
// // // // // // // // //             child: Column(
// // // // // // // // //               mainAxisSize: MainAxisSize.min,
// // // // // // // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // // //               children: [
// // // // // // // // //                 // Handle
// // // // // // // // //                 Center(
// // // // // // // // //                   child: Container(
// // // // // // // // //                     width: 36,
// // // // // // // // //                     height: 4,
// // // // // // // // //                     decoration: BoxDecoration(
// // // // // // // // //                       color: theme.colorScheme.outlineVariant,
// // // // // // // // //                       borderRadius: BorderRadius.circular(2),
// // // // // // // // //                     ),
// // // // // // // // //                   ),
// // // // // // // // //                 ),
// // // // // // // // //                 const SizedBox(height: 20),

// // // // // // // // //                 Text(
// // // // // // // // //                   l10n.gameSettings,
// // // // // // // // //                   style: theme.textTheme.titleLarge?.copyWith(
// // // // // // // // //                     fontWeight: FontWeight.w700,
// // // // // // // // //                   ),
// // // // // // // // //                 ),
// // // // // // // // //                 const SizedBox(height: 20),

// // // // // // // // //                 // ── Pack picker ───────────────────────────────────────────────
// // // // // // // // //                 if (room.isOwner) ...[
// // // // // // // // //                   Text(
// // // // // // // // //                     'Select Pack',
// // // // // // // // //                     style: theme.textTheme.labelLarge?.copyWith(
// // // // // // // // //                       fontWeight: FontWeight.w600,
// // // // // // // // //                     ),
// // // // // // // // //                   ),
// // // // // // // // //                   const SizedBox(height: 8),
// // // // // // // // //                   if (_loadingPacks)
// // // // // // // // //                     const Padding(
// // // // // // // // //                       padding: EdgeInsets.symmetric(vertical: 16),
// // // // // // // // //                       child: Center(child: CircularProgressIndicator()),
// // // // // // // // //                     )
// // // // // // // // //                   else if (_packs.isEmpty)
// // // // // // // // //                     Container(
// // // // // // // // //                       padding: const EdgeInsets.all(16),
// // // // // // // // //                       decoration: BoxDecoration(
// // // // // // // // //                         color: theme.colorScheme.surfaceContainerHighest,
// // // // // // // // //                         borderRadius: BorderRadius.circular(12),
// // // // // // // // //                       ),
// // // // // // // // //                       child: Row(
// // // // // // // // //                         children: [
// // // // // // // // //                           Icon(
// // // // // // // // //                             Icons.info_outline,
// // // // // // // // //                             color: theme.colorScheme.onSurfaceVariant,
// // // // // // // // //                           ),
// // // // // // // // //                           const SizedBox(width: 12),
// // // // // // // // //                           Expanded(
// // // // // // // // //                             child: Text(
// // // // // // // // //                               'No packs available. Run the seed SQL in Supabase.',
// // // // // // // // //                               style: theme.textTheme.bodySmall,
// // // // // // // // //                             ),
// // // // // // // // //                           ),
// // // // // // // // //                         ],
// // // // // // // // //                       ),
// // // // // // // // //                     )
// // // // // // // // //                   else
// // // // // // // // //                     SizedBox(
// // // // // // // // //                       height: 110,
// // // // // // // // //                       child: ListView.separated(
// // // // // // // // //                         scrollDirection: Axis.horizontal,
// // // // // // // // //                         itemCount: _packs.length,
// // // // // // // // //                         separatorBuilder: (_, __) => const SizedBox(width: 10),
// // // // // // // // //                         itemBuilder: (ctx, i) {
// // // // // // // // //                           final pack = _packs[i];
// // // // // // // // //                           final selected = room.room?.packId == pack.id;
// // // // // // // // //                           return GestureDetector(
// // // // // // // // //                             onTap: () => room.setPackId(pack.id),
// // // // // // // // //                             child: AnimatedContainer(
// // // // // // // // //                               duration: const Duration(milliseconds: 180),
// // // // // // // // //                               width: 140,
// // // // // // // // //                               padding: const EdgeInsets.all(12),
// // // // // // // // //                               decoration: BoxDecoration(
// // // // // // // // //                                 color: selected
// // // // // // // // //                                     ? theme.colorScheme.primaryContainer
// // // // // // // // //                                     : theme.colorScheme.surfaceContainerHighest,
// // // // // // // // //                                 borderRadius: BorderRadius.circular(12),
// // // // // // // // //                                 border: Border.all(
// // // // // // // // //                                   color: selected
// // // // // // // // //                                       ? theme.colorScheme.primary
// // // // // // // // //                                       : Colors.transparent,
// // // // // // // // //                                   width: 2,
// // // // // // // // //                                 ),
// // // // // // // // //                               ),
// // // // // // // // //                               child: Column(
// // // // // // // // //                                 crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // // //                                 children: [
// // // // // // // // //                                   Row(
// // // // // // // // //                                     children: [
// // // // // // // // //                                       Text(
// // // // // // // // //                                         pack.coverEmoji,
// // // // // // // // //                                         style: const TextStyle(fontSize: 20),
// // // // // // // // //                                       ),
// // // // // // // // //                                       const Spacer(),
// // // // // // // // //                                       if (selected)
// // // // // // // // //                                         Icon(
// // // // // // // // //                                           Icons.check_circle_rounded,
// // // // // // // // //                                           color: theme.colorScheme.primary,
// // // // // // // // //                                           size: 18,
// // // // // // // // //                                         ),
// // // // // // // // //                                     ],
// // // // // // // // //                                   ),
// // // // // // // // //                                   const SizedBox(height: 6),
// // // // // // // // //                                   Text(
// // // // // // // // //                                     pack.titleJson['en'] as String? ?? pack.id,
// // // // // // // // //                                     style: theme.textTheme.labelMedium
// // // // // // // // //                                         ?.copyWith(fontWeight: FontWeight.w600),
// // // // // // // // //                                     maxLines: 2,
// // // // // // // // //                                     overflow: TextOverflow.ellipsis,
// // // // // // // // //                                   ),
// // // // // // // // //                                   const SizedBox(height: 4),
// // // // // // // // //                                   Text(
// // // // // // // // //                                     '${pack.cardCount} cards',
// // // // // // // // //                                     style: theme.textTheme.labelSmall?.copyWith(
// // // // // // // // //                                       color: theme.colorScheme.onSurfaceVariant,
// // // // // // // // //                                     ),
// // // // // // // // //                                   ),
// // // // // // // // //                                 ],
// // // // // // // // //                               ),
// // // // // // // // //                             ),
// // // // // // // // //                           );
// // // // // // // // //                         },
// // // // // // // // //                       ),
// // // // // // // // //                     ),
// // // // // // // // //                   const SizedBox(height: 20),
// // // // // // // // //                 ],

// // // // // // // // //                 // ── Game settings ─────────────────────────────────────────────
// // // // // // // // //                 _SliderRow(
// // // // // // // // //                   label: l10n.gameSettingsTurnTimer,
// // // // // // // // //                   value: s.turnTimerSeconds.toDouble(),
// // // // // // // // //                   display: l10n.gameSettingsSeconds(s.turnTimerSeconds),
// // // // // // // // //                   min: 15,
// // // // // // // // //                   max: 120,
// // // // // // // // //                   divisions: 21,
// // // // // // // // //                   onChanged: (v) =>
// // // // // // // // //                       room.updateSetting('turn_timer_secs', v.round()),
// // // // // // // // //                 ),
// // // // // // // // //                 _SliderRow(
// // // // // // // // //                   label: l10n.gameSettingsMaxRounds,
// // // // // // // // //                   value: s.maxRounds.toDouble(),
// // // // // // // // //                   display: '${s.maxRounds}',
// // // // // // // // //                   min: 3,
// // // // // // // // //                   max: 30,
// // // // // // // // //                   divisions: 27,
// // // // // // // // //                   onChanged: (v) => room.updateSetting('max_rounds', v.round()),
// // // // // // // // //                 ),
// // // // // // // // //                 const SizedBox(height: 4),
// // // // // // // // //                 _SwitchRow(
// // // // // // // // //                   label: l10n.gameSettingsAllowSkip,
// // // // // // // // //                   icon: Icons.skip_next_rounded,
// // // // // // // // //                   value: s.allowSkip,
// // // // // // // // //                   onChanged: (v) => room.updateSetting('allow_skip', v),
// // // // // // // // //                 ),
// // // // // // // // //                 _SwitchRow(
// // // // // // // // //                   label: 'Chat',
// // // // // // // // //                   icon: Icons.chat_bubble_outline_rounded,
// // // // // // // // //                   value: s.chatEnabled,
// // // // // // // // //                   onChanged: (v) => room.updateSetting('chat_enabled', v),
// // // // // // // // //                 ),
// // // // // // // // //                 _SwitchRow(
// // // // // // // // //                   label: 'Allow spectators',
// // // // // // // // //                   icon: Icons.visibility_outlined,
// // // // // // // // //                   value: s.allowSpectators,
// // // // // // // // //                   onChanged: (v) => room.updateSetting('allow_spectators', v),
// // // // // // // // //                 ),
// // // // // // // // //                 _SwitchRow(
// // // // // // // // //                   label: '🌶️ Spicy Cards',
// // // // // // // // //                   icon: Icons.local_fire_department_outlined,
// // // // // // // // //                   value: s.allowSpicy,
// // // // // // // // //                   onChanged: (v) => room.updateSetting('allow_spicy', v),
// // // // // // // // //                 ),
// // // // // // // // //                 _SwitchRow(
// // // // // // // // //                   label: '🔐 Require Approval',
// // // // // // // // //                   icon: Icons.lock_outline_rounded,
// // // // // // // // //                   value: s.requiresApproval,
// // // // // // // // //                   onChanged: (v) => room.updateSetting('requires_approval', v),
// // // // // // // // //                 ),
// // // // // // // // //               ],
// // // // // // // // //             ),
// // // // // // // // //           );
// // // // // // // // //         },
// // // // // // // // //       ),
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // // }

// // // // // // // // // // ── Helpers ───────────────────────────────────────────────────────────────────

// // // // // // // // // extension _PackX on PackEntity {
// // // // // // // // //   String get coverEmoji {
// // // // // // // // //     if (titleJson['en']?.toString().toLowerCase().contains('arabic') == true)
// // // // // // // // //       return '🌙';
// // // // // // // // //     if (titleJson['en']?.toString().toLowerCase().contains('party') == true)
// // // // // // // // //       return '🎉';
// // // // // // // // //     return '🎮';
// // // // // // // // //   }
// // // // // // // // // }

// // // // // // // // // class _SliderRow extends StatelessWidget {
// // // // // // // // //   const _SliderRow({
// // // // // // // // //     required this.label,
// // // // // // // // //     required this.value,
// // // // // // // // //     required this.display,
// // // // // // // // //     required this.min,
// // // // // // // // //     required this.max,
// // // // // // // // //     required this.divisions,
// // // // // // // // //     required this.onChanged,
// // // // // // // // //   });
// // // // // // // // //   final String label;
// // // // // // // // //   final double value;
// // // // // // // // //   final String display;
// // // // // // // // //   final double min, max;
// // // // // // // // //   final int divisions;
// // // // // // // // //   final void Function(double) onChanged;

// // // // // // // // //   @override
// // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // //     final theme = context.theme;
// // // // // // // // //     return Padding(
// // // // // // // // //       padding: const EdgeInsets.symmetric(vertical: 4),
// // // // // // // // //       child: Row(
// // // // // // // // //         children: [
// // // // // // // // //           Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
// // // // // // // // //           Text(
// // // // // // // // //             display,
// // // // // // // // //             style: theme.textTheme.labelMedium?.copyWith(
// // // // // // // // //               color: theme.colorScheme.primary,
// // // // // // // // //               fontWeight: FontWeight.w600,
// // // // // // // // //             ),
// // // // // // // // //           ),
// // // // // // // // //           const SizedBox(width: 8),
// // // // // // // // //           SizedBox(
// // // // // // // // //             width: 120,
// // // // // // // // //             child: Slider(
// // // // // // // // //               value: value.clamp(min, max),
// // // // // // // // //               min: min,
// // // // // // // // //               max: max,
// // // // // // // // //               divisions: divisions,
// // // // // // // // //               onChanged: onChanged,
// // // // // // // // //             ),
// // // // // // // // //           ),
// // // // // // // // //         ],
// // // // // // // // //       ),
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // // }

// // // // // // // // // class _SwitchRow extends StatelessWidget {
// // // // // // // // //   const _SwitchRow({
// // // // // // // // //     required this.label,
// // // // // // // // //     required this.icon,
// // // // // // // // //     required this.value,
// // // // // // // // //     required this.onChanged,
// // // // // // // // //   });
// // // // // // // // //   final String label;
// // // // // // // // //   final IconData icon;
// // // // // // // // //   final bool value;
// // // // // // // // //   final void Function(bool)? onChanged;

// // // // // // // // //   @override
// // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // //     final theme = context.theme;
// // // // // // // // //     return Padding(
// // // // // // // // //       padding: const EdgeInsets.symmetric(vertical: 2),
// // // // // // // // //       child: Row(
// // // // // // // // //         children: [
// // // // // // // // //           Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
// // // // // // // // //           const SizedBox(width: 12),
// // // // // // // // //           Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
// // // // // // // // //           Switch(value: value, onChanged: onChanged),
// // // // // // // // //         ],
// // // // // // // // //       ),
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // // }

// // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // import '../../../../core/extensions/context_ext.dart';
// // // // // // // // import '../../../../core/theme/app_colors.dart';
// // // // // // // // import '../../../packs/data/pack_repository.dart';
// // // // // // // // import '../../../packs/domain/pack_entity.dart';
// // // // // // // // import '../../../packs/presentation/pack_provider.dart';
// // // // // // // // import '../room_provider.dart';

// // // // // // // // class GameSettingsSheet extends StatefulWidget {
// // // // // // // //   const GameSettingsSheet({super.key});

// // // // // // // //   @override
// // // // // // // //   State<GameSettingsSheet> createState() => _GameSettingsSheetState();
// // // // // // // // }

// // // // // // // // class _GameSettingsSheetState extends State<GameSettingsSheet> {
// // // // // // // //   List<PackEntity> _packs = [];
// // // // // // // //   bool _loadingPacks = true;

// // // // // // // //   @override
// // // // // // // //   void initState() {
// // // // // // // //     super.initState();
// // // // // // // //     _loadPacks();
// // // // // // // //   }

// // // // // // // //   Future<void> _loadPacks() async {
// // // // // // // //     try {
// // // // // // // //       final packProvider = context.read<PackProvider>();
// // // // // // // //       // Only show packs the user owns (purchased or free+downloaded)
// // // // // // // //       final owned = [
// // // // // // // //         ...packProvider.purchasedPacks,
// // // // // // // //         ...packProvider.localPacks,
// // // // // // // //         ...packProvider.browsePacks.where((p) => p.isFree),
// // // // // // // //       ];
// // // // // // // //       // Deduplicate by id
// // // // // // // //       final seen = <String>{};
// // // // // // // //       final unique = owned.where((p) => seen.add(p.id)).toList();
// // // // // // // //       if (mounted)
// // // // // // // //         setState(() {
// // // // // // // //           _packs = unique;
// // // // // // // //           _loadingPacks = false;
// // // // // // // //         });
// // // // // // // //     } catch (e) {
// // // // // // // //       if (mounted) setState(() => _loadingPacks = false);
// // // // // // // //     }
// // // // // // // //   }

// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     final theme = context.theme;
// // // // // // // //     final l10n = context.l10n;

// // // // // // // //     return Container(
// // // // // // // //       decoration: BoxDecoration(
// // // // // // // //         color: theme.colorScheme.surface,
// // // // // // // //         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
// // // // // // // //       ),
// // // // // // // //       padding: EdgeInsets.fromLTRB(
// // // // // // // //         24,
// // // // // // // //         12,
// // // // // // // //         24,
// // // // // // // //         MediaQuery.viewInsetsOf(context).bottom + 24,
// // // // // // // //       ),
// // // // // // // //       child: Consumer<RoomProvider>(
// // // // // // // //         builder: (_, room, __) {
// // // // // // // //           final s = room.settings;
// // // // // // // //           return SingleChildScrollView(
// // // // // // // //             child: Column(
// // // // // // // //               mainAxisSize: MainAxisSize.min,
// // // // // // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // //               children: [
// // // // // // // //                 // Handle
// // // // // // // //                 Center(
// // // // // // // //                   child: Container(
// // // // // // // //                     width: 36,
// // // // // // // //                     height: 4,
// // // // // // // //                     decoration: BoxDecoration(
// // // // // // // //                       color: theme.colorScheme.outlineVariant,
// // // // // // // //                       borderRadius: BorderRadius.circular(2),
// // // // // // // //                     ),
// // // // // // // //                   ),
// // // // // // // //                 ),
// // // // // // // //                 const SizedBox(height: 20),

// // // // // // // //                 Text(
// // // // // // // //                   l10n.gameSettings,
// // // // // // // //                   style: theme.textTheme.titleLarge?.copyWith(
// // // // // // // //                     fontWeight: FontWeight.w700,
// // // // // // // //                   ),
// // // // // // // //                 ),
// // // // // // // //                 const SizedBox(height: 20),

// // // // // // // //                 // ── Pack picker ───────────────────────────────────────────────
// // // // // // // //                 if (room.isOwner) ...[
// // // // // // // //                   Text(
// // // // // // // //                     'Select Pack',
// // // // // // // //                     style: theme.textTheme.labelLarge?.copyWith(
// // // // // // // //                       fontWeight: FontWeight.w600,
// // // // // // // //                     ),
// // // // // // // //                   ),
// // // // // // // //                   const SizedBox(height: 8),
// // // // // // // //                   if (_loadingPacks)
// // // // // // // //                     const Padding(
// // // // // // // //                       padding: EdgeInsets.symmetric(vertical: 16),
// // // // // // // //                       child: Center(child: CircularProgressIndicator()),
// // // // // // // //                     )
// // // // // // // //                   else if (_packs.isEmpty)
// // // // // // // //                     Container(
// // // // // // // //                       padding: const EdgeInsets.all(16),
// // // // // // // //                       decoration: BoxDecoration(
// // // // // // // //                         color: theme.colorScheme.surfaceContainerHighest,
// // // // // // // //                         borderRadius: BorderRadius.circular(12),
// // // // // // // //                       ),
// // // // // // // //                       child: Row(
// // // // // // // //                         children: [
// // // // // // // //                           Icon(
// // // // // // // //                             Icons.info_outline,
// // // // // // // //                             color: theme.colorScheme.onSurfaceVariant,
// // // // // // // //                           ),
// // // // // // // //                           const SizedBox(width: 12),
// // // // // // // //                           Expanded(
// // // // // // // //                             child: Text(
// // // // // // // //                               'No packs available. Run the seed SQL in Supabase.',
// // // // // // // //                               style: theme.textTheme.bodySmall,
// // // // // // // //                             ),
// // // // // // // //                           ),
// // // // // // // //                         ],
// // // // // // // //                       ),
// // // // // // // //                     )
// // // // // // // //                   else
// // // // // // // //                     SizedBox(
// // // // // // // //                       height: 110,
// // // // // // // //                       child: ListView.separated(
// // // // // // // //                         scrollDirection: Axis.horizontal,
// // // // // // // //                         itemCount: _packs.length,
// // // // // // // //                         separatorBuilder: (_, __) => const SizedBox(width: 10),
// // // // // // // //                         itemBuilder: (ctx, i) {
// // // // // // // //                           final pack = _packs[i];
// // // // // // // //                           final selected = room.room?.packId == pack.id;
// // // // // // // //                           return GestureDetector(
// // // // // // // //                             onTap: () => room.setPackId(pack.id),
// // // // // // // //                             child: AnimatedContainer(
// // // // // // // //                               duration: const Duration(milliseconds: 180),
// // // // // // // //                               width: 140,
// // // // // // // //                               padding: const EdgeInsets.all(12),
// // // // // // // //                               decoration: BoxDecoration(
// // // // // // // //                                 color: selected
// // // // // // // //                                     ? theme.colorScheme.primaryContainer
// // // // // // // //                                     : theme.colorScheme.surfaceContainerHighest,
// // // // // // // //                                 borderRadius: BorderRadius.circular(12),
// // // // // // // //                                 border: Border.all(
// // // // // // // //                                   color: selected
// // // // // // // //                                       ? theme.colorScheme.primary
// // // // // // // //                                       : Colors.transparent,
// // // // // // // //                                   width: 2,
// // // // // // // //                                 ),
// // // // // // // //                               ),
// // // // // // // //                               child: Column(
// // // // // // // //                                 crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // //                                 children: [
// // // // // // // //                                   Row(
// // // // // // // //                                     children: [
// // // // // // // //                                       Text(
// // // // // // // //                                         pack.coverEmoji,
// // // // // // // //                                         style: const TextStyle(fontSize: 20),
// // // // // // // //                                       ),
// // // // // // // //                                       const Spacer(),
// // // // // // // //                                       if (selected)
// // // // // // // //                                         Icon(
// // // // // // // //                                           Icons.check_circle_rounded,
// // // // // // // //                                           color: theme.colorScheme.primary,
// // // // // // // //                                           size: 18,
// // // // // // // //                                         ),
// // // // // // // //                                     ],
// // // // // // // //                                   ),
// // // // // // // //                                   const SizedBox(height: 6),
// // // // // // // //                                   Text(
// // // // // // // //                                     pack.titleJson['en'] as String? ?? pack.id,
// // // // // // // //                                     style: theme.textTheme.labelMedium
// // // // // // // //                                         ?.copyWith(fontWeight: FontWeight.w600),
// // // // // // // //                                     maxLines: 2,
// // // // // // // //                                     overflow: TextOverflow.ellipsis,
// // // // // // // //                                   ),
// // // // // // // //                                   const SizedBox(height: 4),
// // // // // // // //                                   Text(
// // // // // // // //                                     '${pack.cardCount} cards',
// // // // // // // //                                     style: theme.textTheme.labelSmall?.copyWith(
// // // // // // // //                                       color: theme.colorScheme.onSurfaceVariant,
// // // // // // // //                                     ),
// // // // // // // //                                   ),
// // // // // // // //                                 ],
// // // // // // // //                               ),
// // // // // // // //                             ),
// // // // // // // //                           );
// // // // // // // //                         },
// // // // // // // //                       ),
// // // // // // // //                     ),
// // // // // // // //                   const SizedBox(height: 20),
// // // // // // // //                 ],

// // // // // // // //                 // ── Game settings ─────────────────────────────────────────────
// // // // // // // //                 _SliderRow(
// // // // // // // //                   label: l10n.gameSettingsTurnTimer,
// // // // // // // //                   value: s.turnTimerSeconds.toDouble(),
// // // // // // // //                   display: l10n.gameSettingsSeconds(s.turnTimerSeconds),
// // // // // // // //                   min: 15,
// // // // // // // //                   max: 120,
// // // // // // // //                   divisions: 21,
// // // // // // // //                   onChanged: (v) =>
// // // // // // // //                       room.updateSetting('turn_timer_secs', v.round()),
// // // // // // // //                 ),
// // // // // // // //                 _SliderRow(
// // // // // // // //                   label: l10n.gameSettingsMaxRounds,
// // // // // // // //                   value: s.maxRounds.toDouble(),
// // // // // // // //                   display: '${s.maxRounds}',
// // // // // // // //                   min: 3,
// // // // // // // //                   max: 30,
// // // // // // // //                   divisions: 27,
// // // // // // // //                   onChanged: (v) => room.updateSetting('max_rounds', v.round()),
// // // // // // // //                 ),
// // // // // // // //                 const SizedBox(height: 4),
// // // // // // // //                 _SwitchRow(
// // // // // // // //                   label: l10n.gameSettingsAllowSkip,
// // // // // // // //                   icon: Icons.skip_next_rounded,
// // // // // // // //                   value: s.allowSkip,
// // // // // // // //                   onChanged: (v) => room.updateSetting('allow_skip', v),
// // // // // // // //                 ),
// // // // // // // //                 _SwitchRow(
// // // // // // // //                   label: 'Chat',
// // // // // // // //                   icon: Icons.chat_bubble_outline_rounded,
// // // // // // // //                   value: s.chatEnabled,
// // // // // // // //                   onChanged: (v) => room.updateSetting('chat_enabled', v),
// // // // // // // //                 ),
// // // // // // // //                 _SwitchRow(
// // // // // // // //                   label: l10n.gameSettingsAllowSpectators,
// // // // // // // //                   icon: Icons.visibility_outlined,
// // // // // // // //                   value: s.allowSpectators,
// // // // // // // //                   onChanged: (v) => room.updateSetting('allow_spectators', v),
// // // // // // // //                 ),
// // // // // // // //                 _SwitchRow(
// // // // // // // //                   label: l10n.gameSettingsSpicy,
// // // // // // // //                   icon: Icons.local_fire_department_outlined,
// // // // // // // //                   value: s.allowSpicy,
// // // // // // // //                   onChanged: (v) => room.updateSetting('allow_spicy', v),
// // // // // // // //                 ),
// // // // // // // //                 _SwitchRow(
// // // // // // // //                   label: l10n.gameSettingsRequireApproval,
// // // // // // // //                   icon: Icons.lock_outline_rounded,
// // // // // // // //                   value: s.requiresApproval,
// // // // // // // //                   onChanged: (v) => room.updateSetting('requires_approval', v),
// // // // // // // //                 ),
// // // // // // // //               ],
// // // // // // // //             ),
// // // // // // // //           );
// // // // // // // //         },
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // // }

// // // // // // // // // ── Helpers ───────────────────────────────────────────────────────────────────

// // // // // // // // extension _PackX on PackEntity {
// // // // // // // //   String get coverEmoji {
// // // // // // // //     if (titleJson['en']?.toString().toLowerCase().contains('arabic') == true)
// // // // // // // //       return '🌙';
// // // // // // // //     if (titleJson['en']?.toString().toLowerCase().contains('party') == true)
// // // // // // // //       return '🎉';
// // // // // // // //     return '🎮';
// // // // // // // //   }
// // // // // // // // }

// // // // // // // // class _SliderRow extends StatelessWidget {
// // // // // // // //   const _SliderRow({
// // // // // // // //     required this.label,
// // // // // // // //     required this.value,
// // // // // // // //     required this.display,
// // // // // // // //     required this.min,
// // // // // // // //     required this.max,
// // // // // // // //     required this.divisions,
// // // // // // // //     required this.onChanged,
// // // // // // // //   });
// // // // // // // //   final String label;
// // // // // // // //   final double value;
// // // // // // // //   final String display;
// // // // // // // //   final double min, max;
// // // // // // // //   final int divisions;
// // // // // // // //   final void Function(double) onChanged;

// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     final theme = context.theme;
// // // // // // // //     return Padding(
// // // // // // // //       padding: const EdgeInsets.symmetric(vertical: 4),
// // // // // // // //       child: Row(
// // // // // // // //         children: [
// // // // // // // //           Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
// // // // // // // //           Text(
// // // // // // // //             display,
// // // // // // // //             style: theme.textTheme.labelMedium?.copyWith(
// // // // // // // //               color: theme.colorScheme.primary,
// // // // // // // //               fontWeight: FontWeight.w600,
// // // // // // // //             ),
// // // // // // // //           ),
// // // // // // // //           const SizedBox(width: 8),
// // // // // // // //           SizedBox(
// // // // // // // //             width: 120,
// // // // // // // //             child: Slider(
// // // // // // // //               value: value.clamp(min, max),
// // // // // // // //               min: min,
// // // // // // // //               max: max,
// // // // // // // //               divisions: divisions,
// // // // // // // //               onChanged: onChanged,
// // // // // // // //             ),
// // // // // // // //           ),
// // // // // // // //         ],
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // // }

// // // // // // // // class _SwitchRow extends StatelessWidget {
// // // // // // // //   const _SwitchRow({
// // // // // // // //     required this.label,
// // // // // // // //     required this.icon,
// // // // // // // //     required this.value,
// // // // // // // //     required this.onChanged,
// // // // // // // //   });
// // // // // // // //   final String label;
// // // // // // // //   final IconData icon;
// // // // // // // //   final bool value;
// // // // // // // //   final void Function(bool)? onChanged;

// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     final theme = context.theme;
// // // // // // // //     return Padding(
// // // // // // // //       padding: const EdgeInsets.symmetric(vertical: 2),
// // // // // // // //       child: Row(
// // // // // // // //         children: [
// // // // // // // //           Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
// // // // // // // //           const SizedBox(width: 12),
// // // // // // // //           Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
// // // // // // // //           Switch(value: value, onChanged: onChanged),
// // // // // // // //         ],
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // // }

// // // // // // // import 'package:flutter/material.dart';
// // // // // // // import 'package:provider/provider.dart';

// // // // // // // import '../../../../core/extensions/context_ext.dart';
// // // // // // // import '../../../../core/theme/app_colors.dart';
// // // // // // // import '../../../packs/data/pack_repository.dart';
// // // // // // // import '../../../packs/domain/pack_entity.dart';
// // // // // // // import '../../../packs/presentation/pack_provider.dart';
// // // // // // // import '../room_provider.dart';

// // // // // // // class GameSettingsSheet extends StatefulWidget {
// // // // // // //   const GameSettingsSheet({super.key});

// // // // // // //   @override
// // // // // // //   State<GameSettingsSheet> createState() => _GameSettingsSheetState();
// // // // // // // }

// // // // // // // class _GameSettingsSheetState extends State<GameSettingsSheet> {
// // // // // // //   List<PackEntity> _packs = [];
// // // // // // //   bool _loadingPacks = true;
// // // // // // //   String _langFilter = 'all'; // 'all' | 'en' | 'ar' | 'fr'

// // // // // // //   static const _langs = [
// // // // // // //     ('all', '🌐 All'),
// // // // // // //     ('en', '🇬🇧 EN'),
// // // // // // //     ('ar', '🇸🇦 AR'),
// // // // // // //     ('fr', '🇫🇷 FR'),
// // // // // // //   ];

// // // // // // //   @override
// // // // // // //   void initState() {
// // // // // // //     super.initState();
// // // // // // //     _loadPacks();
// // // // // // //   }

// // // // // // //   Future<void> _loadPacks() async {
// // // // // // //     try {
// // // // // // //       final packProvider = context.read<PackProvider>();
// // // // // // //       final owned = [
// // // // // // //         ...packProvider.purchasedPacks,
// // // // // // //         ...packProvider.localPacks,
// // // // // // //         ...packProvider.browsePacks.where((p) => p.isFree),
// // // // // // //       ];
// // // // // // //       final seen = <String>{};
// // // // // // //       final unique = owned.where((p) => seen.add(p.id)).toList();
// // // // // // //       if (mounted)
// // // // // // //         setState(() {
// // // // // // //           _packs = unique;
// // // // // // //           _loadingPacks = false;
// // // // // // //         });
// // // // // // //     } catch (e) {
// // // // // // //       if (mounted) setState(() => _loadingPacks = false);
// // // // // // //     }
// // // // // // //   }

// // // // // // //   List<PackEntity> get _filteredPacks {
// // // // // // //     if (_langFilter == 'all') return _packs;
// // // // // // //     return _packs
// // // // // // //         .where(
// // // // // // //           (p) =>
// // // // // // //               p.language == _langFilter ||
// // // // // // //               p.isMultilang ||
// // // // // // //               (p.titleJson[_langFilter] != null),
// // // // // // //         )
// // // // // // //         .toList();
// // // // // // //   }

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     final theme = context.theme;
// // // // // // //     final l10n = context.l10n;

// // // // // // //     return Container(
// // // // // // //       decoration: BoxDecoration(
// // // // // // //         color: theme.colorScheme.surface,
// // // // // // //         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
// // // // // // //       ),
// // // // // // //       padding: EdgeInsets.fromLTRB(
// // // // // // //         24,
// // // // // // //         12,
// // // // // // //         24,
// // // // // // //         MediaQuery.viewInsetsOf(context).bottom + 24,
// // // // // // //       ),
// // // // // // //       child: Consumer<RoomProvider>(
// // // // // // //         builder: (_, room, __) {
// // // // // // //           final s = room.settings;
// // // // // // //           return SingleChildScrollView(
// // // // // // //             child: Column(
// // // // // // //               mainAxisSize: MainAxisSize.min,
// // // // // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // //               children: [
// // // // // // //                 // Handle
// // // // // // //                 Center(
// // // // // // //                   child: Container(
// // // // // // //                     width: 36,
// // // // // // //                     height: 4,
// // // // // // //                     decoration: BoxDecoration(
// // // // // // //                       color: theme.colorScheme.outlineVariant,
// // // // // // //                       borderRadius: BorderRadius.circular(2),
// // // // // // //                     ),
// // // // // // //                   ),
// // // // // // //                 ),
// // // // // // //                 const SizedBox(height: 20),

// // // // // // //                 Text(
// // // // // // //                   l10n.gameSettings,
// // // // // // //                   style: theme.textTheme.titleLarge?.copyWith(
// // // // // // //                     fontWeight: FontWeight.w700,
// // // // // // //                   ),
// // // // // // //                 ),
// // // // // // //                 const SizedBox(height: 20),

// // // // // // //                 // ── Language filter ──────────────────────────────────────────
// // // // // // //                 Text(
// // // // // // //                   'Language',
// // // // // // //                   style: theme.textTheme.labelLarge?.copyWith(
// // // // // // //                     fontWeight: FontWeight.w600,
// // // // // // //                   ),
// // // // // // //                 ),
// // // // // // //                 const SizedBox(height: 8),
// // // // // // //                 SingleChildScrollView(
// // // // // // //                   scrollDirection: Axis.horizontal,
// // // // // // //                   child: Row(
// // // // // // //                     children: _langs.map((lang) {
// // // // // // //                       final selected = _langFilter == lang.$1;
// // // // // // //                       return Padding(
// // // // // // //                         padding: const EdgeInsets.only(right: 8),
// // // // // // //                         child: ChoiceChip(
// // // // // // //                           label: Text(lang.$2),
// // // // // // //                           selected: selected,
// // // // // // //                           onSelected: (_) =>
// // // // // // //                               setState(() => _langFilter = lang.$1),
// // // // // // //                         ),
// // // // // // //                       );
// // // // // // //                     }).toList(),
// // // // // // //                   ),
// // // // // // //                 ),
// // // // // // //                 const SizedBox(height: 20),

// // // // // // //                 // ── Pack picker ───────────────────────────────────────────────
// // // // // // //                 if (room.isOwner) ...[
// // // // // // //                   Text(
// // // // // // //                     'Select Pack',
// // // // // // //                     style: theme.textTheme.labelLarge?.copyWith(
// // // // // // //                       fontWeight: FontWeight.w600,
// // // // // // //                     ),
// // // // // // //                   ),
// // // // // // //                   const SizedBox(height: 8),
// // // // // // //                   if (_loadingPacks)
// // // // // // //                     const Padding(
// // // // // // //                       padding: EdgeInsets.symmetric(vertical: 16),
// // // // // // //                       child: Center(child: CircularProgressIndicator()),
// // // // // // //                     )
// // // // // // //                   else if (_packs.isEmpty)
// // // // // // //                     Container(
// // // // // // //                       padding: const EdgeInsets.all(16),
// // // // // // //                       decoration: BoxDecoration(
// // // // // // //                         color: theme.colorScheme.surfaceContainerHighest,
// // // // // // //                         borderRadius: BorderRadius.circular(12),
// // // // // // //                       ),
// // // // // // //                       child: Row(
// // // // // // //                         children: [
// // // // // // //                           Icon(
// // // // // // //                             Icons.info_outline,
// // // // // // //                             color: theme.colorScheme.onSurfaceVariant,
// // // // // // //                           ),
// // // // // // //                           const SizedBox(width: 12),
// // // // // // //                           Expanded(
// // // // // // //                             child: Text(
// // // // // // //                               'No packs available. Run the seed SQL in Supabase.',
// // // // // // //                               style: theme.textTheme.bodySmall,
// // // // // // //                             ),
// // // // // // //                           ),
// // // // // // //                         ],
// // // // // // //                       ),
// // // // // // //                     )
// // // // // // //                   else
// // // // // // //                     SizedBox(
// // // // // // //                       height: 110,
// // // // // // //                       child: ListView.separated(
// // // // // // //                         scrollDirection: Axis.horizontal,
// // // // // // //                         itemCount: _filteredPacks.length,
// // // // // // //                         separatorBuilder: (_, __) => const SizedBox(width: 10),
// // // // // // //                         itemBuilder: (ctx, i) {
// // // // // // //                           final pack = _filteredPacks[i];
// // // // // // //                           final selected = room.room?.packId == pack.id;
// // // // // // //                           return GestureDetector(
// // // // // // //                             onTap: () => room.setPackId(pack.id),
// // // // // // //                             child: AnimatedContainer(
// // // // // // //                               duration: const Duration(milliseconds: 180),
// // // // // // //                               width: 140,
// // // // // // //                               padding: const EdgeInsets.all(12),
// // // // // // //                               decoration: BoxDecoration(
// // // // // // //                                 color: selected
// // // // // // //                                     ? theme.colorScheme.primaryContainer
// // // // // // //                                     : theme.colorScheme.surfaceContainerHighest,
// // // // // // //                                 borderRadius: BorderRadius.circular(12),
// // // // // // //                                 border: Border.all(
// // // // // // //                                   color: selected
// // // // // // //                                       ? theme.colorScheme.primary
// // // // // // //                                       : Colors.transparent,
// // // // // // //                                   width: 2,
// // // // // // //                                 ),
// // // // // // //                               ),
// // // // // // //                               child: Column(
// // // // // // //                                 crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // //                                 children: [
// // // // // // //                                   Row(
// // // // // // //                                     children: [
// // // // // // //                                       Text(
// // // // // // //                                         pack.coverEmoji,
// // // // // // //                                         style: const TextStyle(fontSize: 20),
// // // // // // //                                       ),
// // // // // // //                                       const Spacer(),
// // // // // // //                                       if (selected)
// // // // // // //                                         Icon(
// // // // // // //                                           Icons.check_circle_rounded,
// // // // // // //                                           color: theme.colorScheme.primary,
// // // // // // //                                           size: 18,
// // // // // // //                                         ),
// // // // // // //                                     ],
// // // // // // //                                   ),
// // // // // // //                                   const SizedBox(height: 6),
// // // // // // //                                   Text(
// // // // // // //                                     pack.titleJson['en'] as String? ?? pack.id,
// // // // // // //                                     style: theme.textTheme.labelMedium
// // // // // // //                                         ?.copyWith(fontWeight: FontWeight.w600),
// // // // // // //                                     maxLines: 2,
// // // // // // //                                     overflow: TextOverflow.ellipsis,
// // // // // // //                                   ),
// // // // // // //                                   const SizedBox(height: 4),
// // // // // // //                                   Text(
// // // // // // //                                     '${pack.cardCount} cards',
// // // // // // //                                     style: theme.textTheme.labelSmall?.copyWith(
// // // // // // //                                       color: theme.colorScheme.onSurfaceVariant,
// // // // // // //                                     ),
// // // // // // //                                   ),
// // // // // // //                                 ],
// // // // // // //                               ),
// // // // // // //                             ),
// // // // // // //                           );
// // // // // // //                         },
// // // // // // //                       ),
// // // // // // //                     ),
// // // // // // //                   const SizedBox(height: 20),
// // // // // // //                 ],

// // // // // // //                 // ── Game settings ─────────────────────────────────────────────
// // // // // // //                 _SliderRow(
// // // // // // //                   label: l10n.gameSettingsTurnTimer,
// // // // // // //                   value: s.turnTimerSeconds.toDouble(),
// // // // // // //                   display: l10n.gameSettingsSeconds(s.turnTimerSeconds),
// // // // // // //                   min: 15,
// // // // // // //                   max: 120,
// // // // // // //                   divisions: 21,
// // // // // // //                   onChanged: (v) =>
// // // // // // //                       room.updateSetting('turn_timer_secs', v.round()),
// // // // // // //                 ),
// // // // // // //                 _SliderRow(
// // // // // // //                   label: l10n.gameSettingsMaxRounds,
// // // // // // //                   value: s.maxRounds.toDouble(),
// // // // // // //                   display: '${s.maxRounds}',
// // // // // // //                   min: 3,
// // // // // // //                   max: 30,
// // // // // // //                   divisions: 27,
// // // // // // //                   onChanged: (v) => room.updateSetting('max_rounds', v.round()),
// // // // // // //                 ),
// // // // // // //                 const SizedBox(height: 4),
// // // // // // //                 _SwitchRow(
// // // // // // //                   label: l10n.gameSettingsAllowSkip,
// // // // // // //                   icon: Icons.skip_next_rounded,
// // // // // // //                   value: s.allowSkip,
// // // // // // //                   onChanged: (v) => room.updateSetting('allow_skip', v),
// // // // // // //                 ),
// // // // // // //                 _SwitchRow(
// // // // // // //                   label: 'Chat',
// // // // // // //                   icon: Icons.chat_bubble_outline_rounded,
// // // // // // //                   value: s.chatEnabled,
// // // // // // //                   onChanged: (v) => room.updateSetting('chat_enabled', v),
// // // // // // //                 ),
// // // // // // //                 _SwitchRow(
// // // // // // //                   label: l10n.gameSettingsAllowSpectators,
// // // // // // //                   icon: Icons.visibility_outlined,
// // // // // // //                   value: s.allowSpectators,
// // // // // // //                   onChanged: (v) => room.updateSetting('allow_spectators', v),
// // // // // // //                 ),
// // // // // // //                 _SwitchRow(
// // // // // // //                   label: l10n.gameSettingsSpicy,
// // // // // // //                   icon: Icons.local_fire_department_outlined,
// // // // // // //                   value: s.allowSpicy,
// // // // // // //                   onChanged: (v) => room.updateSetting('allow_spicy', v),
// // // // // // //                 ),
// // // // // // //                 _SwitchRow(
// // // // // // //                   label: l10n.gameSettingsRequireApproval,
// // // // // // //                   icon: Icons.lock_outline_rounded,
// // // // // // //                   value: s.requiresApproval,
// // // // // // //                   onChanged: (v) => room.updateSetting('requires_approval', v),
// // // // // // //                 ),
// // // // // // //               ],
// // // // // // //             ),
// // // // // // //           );
// // // // // // //         },
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // // // ── Helpers ───────────────────────────────────────────────────────────────────

// // // // // // // extension _PackX on PackEntity {
// // // // // // //   String get coverEmoji {
// // // // // // //     if (titleJson['en']?.toString().toLowerCase().contains('arabic') == true)
// // // // // // //       return '🌙';
// // // // // // //     if (titleJson['en']?.toString().toLowerCase().contains('party') == true)
// // // // // // //       return '🎉';
// // // // // // //     return '🎮';
// // // // // // //   }
// // // // // // // }

// // // // // // // class _SliderRow extends StatelessWidget {
// // // // // // //   const _SliderRow({
// // // // // // //     required this.label,
// // // // // // //     required this.value,
// // // // // // //     required this.display,
// // // // // // //     required this.min,
// // // // // // //     required this.max,
// // // // // // //     required this.divisions,
// // // // // // //     required this.onChanged,
// // // // // // //   });
// // // // // // //   final String label;
// // // // // // //   final double value;
// // // // // // //   final String display;
// // // // // // //   final double min, max;
// // // // // // //   final int divisions;
// // // // // // //   final void Function(double) onChanged;

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     final theme = context.theme;
// // // // // // //     return Padding(
// // // // // // //       padding: const EdgeInsets.symmetric(vertical: 4),
// // // // // // //       child: Row(
// // // // // // //         children: [
// // // // // // //           Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
// // // // // // //           Text(
// // // // // // //             display,
// // // // // // //             style: theme.textTheme.labelMedium?.copyWith(
// // // // // // //               color: theme.colorScheme.primary,
// // // // // // //               fontWeight: FontWeight.w600,
// // // // // // //             ),
// // // // // // //           ),
// // // // // // //           const SizedBox(width: 8),
// // // // // // //           SizedBox(
// // // // // // //             width: 120,
// // // // // // //             child: Slider(
// // // // // // //               value: value.clamp(min, max),
// // // // // // //               min: min,
// // // // // // //               max: max,
// // // // // // //               divisions: divisions,
// // // // // // //               onChanged: onChanged,
// // // // // // //             ),
// // // // // // //           ),
// // // // // // //         ],
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // // class _SwitchRow extends StatelessWidget {
// // // // // // //   const _SwitchRow({
// // // // // // //     required this.label,
// // // // // // //     required this.icon,
// // // // // // //     required this.value,
// // // // // // //     required this.onChanged,
// // // // // // //   });
// // // // // // //   final String label;
// // // // // // //   final IconData icon;
// // // // // // //   final bool value;
// // // // // // //   final void Function(bool)? onChanged;

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     final theme = context.theme;
// // // // // // //     return Padding(
// // // // // // //       padding: const EdgeInsets.symmetric(vertical: 2),
// // // // // // //       child: Row(
// // // // // // //         children: [
// // // // // // //           Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
// // // // // // //           const SizedBox(width: 12),
// // // // // // //           Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
// // // // // // //           Switch(value: value, onChanged: onChanged),
// // // // // // //         ],
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:provider/provider.dart';

// // // // // // import '../../../../core/extensions/context_ext.dart';
// // // // // // import '../../../../core/theme/app_colors.dart';
// // // // // // import '../../../packs/data/pack_repository.dart';
// // // // // // import '../../../packs/domain/pack_entity.dart';
// // // // // // import '../../../packs/presentation/pack_provider.dart';
// // // // // // import '../room_provider.dart';

// // // // // // class GameSettingsSheet extends StatefulWidget {
// // // // // //   const GameSettingsSheet({super.key});

// // // // // //   @override
// // // // // //   State<GameSettingsSheet> createState() => _GameSettingsSheetState();
// // // // // // }

// // // // // // class _GameSettingsSheetState extends State<GameSettingsSheet> {
// // // // // //   List<PackEntity> _packs = [];
// // // // // //   bool _loadingPacks = true;
// // // // // //   String _langFilter = 'all'; // 'all' | 'en' | 'ar' | 'fr'

// // // // // //   static const _langs = [
// // // // // //     ('all', '🌐 All'),
// // // // // //     ('en', '🇬🇧 EN'),
// // // // // //     ('ar', '🇸🇦 AR'),
// // // // // //     ('fr', '🇫🇷 FR'),
// // // // // //   ];

// // // // // //   @override
// // // // // //   void initState() {
// // // // // //     super.initState();
// // // // // //     _loadPacks();
// // // // // //   }

// // // // // //   Future<void> _loadPacks() async {
// // // // // //     try {
// // // // // //       final packProvider = context.read<PackProvider>();
// // // // // //       final owned = [
// // // // // //         ...packProvider.purchasedPacks,
// // // // // //         ...packProvider.localPacks,
// // // // // //         ...packProvider.browsePacks.where((p) => p.isFree),
// // // // // //       ];
// // // // // //       final seen = <String>{};
// // // // // //       final unique = owned.where((p) => seen.add(p.id)).toList();
// // // // // //       if (mounted)
// // // // // //         setState(() {
// // // // // //           _packs = unique;
// // // // // //           _loadingPacks = false;
// // // // // //         });
// // // // // //     } catch (e) {
// // // // // //       if (mounted) setState(() => _loadingPacks = false);
// // // // // //     }
// // // // // //   }

// // // // // //   List<PackEntity> get _filteredPacks {
// // // // // //     if (_langFilter == 'all') return _packs;
// // // // // //     return _packs
// // // // // //         .where((p) => p.availableLanguages.contains(_langFilter))
// // // // // //         .toList();
// // // // // //   }

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     final theme = context.theme;
// // // // // //     final l10n = context.l10n;

// // // // // //     return Container(
// // // // // //       decoration: BoxDecoration(
// // // // // //         color: theme.colorScheme.surface,
// // // // // //         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
// // // // // //       ),
// // // // // //       padding: EdgeInsets.fromLTRB(
// // // // // //         24,
// // // // // //         12,
// // // // // //         24,
// // // // // //         MediaQuery.viewInsetsOf(context).bottom + 24,
// // // // // //       ),
// // // // // //       child: Consumer<RoomProvider>(
// // // // // //         builder: (_, room, __) {
// // // // // //           final s = room.settings;
// // // // // //           return SingleChildScrollView(
// // // // // //             child: Column(
// // // // // //               mainAxisSize: MainAxisSize.min,
// // // // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // // // //               children: [
// // // // // //                 // Handle
// // // // // //                 Center(
// // // // // //                   child: Container(
// // // // // //                     width: 36,
// // // // // //                     height: 4,
// // // // // //                     decoration: BoxDecoration(
// // // // // //                       color: theme.colorScheme.outlineVariant,
// // // // // //                       borderRadius: BorderRadius.circular(2),
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                 ),
// // // // // //                 const SizedBox(height: 20),

// // // // // //                 Text(
// // // // // //                   l10n.gameSettings,
// // // // // //                   style: theme.textTheme.titleLarge?.copyWith(
// // // // // //                     fontWeight: FontWeight.w700,
// // // // // //                   ),
// // // // // //                 ),
// // // // // //                 const SizedBox(height: 20),

// // // // // //                 // ── Language filter ──────────────────────────────────────────
// // // // // //                 Text(
// // // // // //                   'Language',
// // // // // //                   style: theme.textTheme.labelLarge?.copyWith(
// // // // // //                     fontWeight: FontWeight.w600,
// // // // // //                   ),
// // // // // //                 ),
// // // // // //                 const SizedBox(height: 8),
// // // // // //                 SingleChildScrollView(
// // // // // //                   scrollDirection: Axis.horizontal,
// // // // // //                   child: Row(
// // // // // //                     children: _langs.map((lang) {
// // // // // //                       final selected = _langFilter == lang.$1;
// // // // // //                       return Padding(
// // // // // //                         padding: const EdgeInsets.only(right: 8),
// // // // // //                         child: ChoiceChip(
// // // // // //                           label: Text(lang.$2),
// // // // // //                           selected: selected,
// // // // // //                           onSelected: (_) =>
// // // // // //                               setState(() => _langFilter = lang.$1),
// // // // // //                         ),
// // // // // //                       );
// // // // // //                     }).toList(),
// // // // // //                   ),
// // // // // //                 ),
// // // // // //                 const SizedBox(height: 20),

// // // // // //                 // ── Pack picker ───────────────────────────────────────────────
// // // // // //                 if (room.isOwner) ...[
// // // // // //                   Text(
// // // // // //                     'Select Pack',
// // // // // //                     style: theme.textTheme.labelLarge?.copyWith(
// // // // // //                       fontWeight: FontWeight.w600,
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                   const SizedBox(height: 8),
// // // // // //                   if (_loadingPacks)
// // // // // //                     const Padding(
// // // // // //                       padding: EdgeInsets.symmetric(vertical: 16),
// // // // // //                       child: Center(child: CircularProgressIndicator()),
// // // // // //                     )
// // // // // //                   else if (_packs.isEmpty)
// // // // // //                     Container(
// // // // // //                       padding: const EdgeInsets.all(16),
// // // // // //                       decoration: BoxDecoration(
// // // // // //                         color: theme.colorScheme.surfaceContainerHighest,
// // // // // //                         borderRadius: BorderRadius.circular(12),
// // // // // //                       ),
// // // // // //                       child: Row(
// // // // // //                         children: [
// // // // // //                           Icon(
// // // // // //                             Icons.info_outline,
// // // // // //                             color: theme.colorScheme.onSurfaceVariant,
// // // // // //                           ),
// // // // // //                           const SizedBox(width: 12),
// // // // // //                           Expanded(
// // // // // //                             child: Text(
// // // // // //                               'No packs available. Run the seed SQL in Supabase.',
// // // // // //                               style: theme.textTheme.bodySmall,
// // // // // //                             ),
// // // // // //                           ),
// // // // // //                         ],
// // // // // //                       ),
// // // // // //                     )
// // // // // //                   else
// // // // // //                     SizedBox(
// // // // // //                       height: 110,
// // // // // //                       child: ListView.separated(
// // // // // //                         scrollDirection: Axis.horizontal,
// // // // // //                         itemCount: _filteredPacks.length,
// // // // // //                         separatorBuilder: (_, __) => const SizedBox(width: 10),
// // // // // //                         itemBuilder: (ctx, i) {
// // // // // //                           final pack = _filteredPacks[i];
// // // // // //                           final selected = room.room?.packId == pack.id;
// // // // // //                           return GestureDetector(
// // // // // //                             onTap: () => room.setPackId(pack.id),
// // // // // //                             child: AnimatedContainer(
// // // // // //                               duration: const Duration(milliseconds: 180),
// // // // // //                               width: 140,
// // // // // //                               padding: const EdgeInsets.all(12),
// // // // // //                               decoration: BoxDecoration(
// // // // // //                                 color: selected
// // // // // //                                     ? theme.colorScheme.primaryContainer
// // // // // //                                     : theme.colorScheme.surfaceContainerHighest,
// // // // // //                                 borderRadius: BorderRadius.circular(12),
// // // // // //                                 border: Border.all(
// // // // // //                                   color: selected
// // // // // //                                       ? theme.colorScheme.primary
// // // // // //                                       : Colors.transparent,
// // // // // //                                   width: 2,
// // // // // //                                 ),
// // // // // //                               ),
// // // // // //                               child: Column(
// // // // // //                                 crossAxisAlignment: CrossAxisAlignment.start,
// // // // // //                                 children: [
// // // // // //                                   Row(
// // // // // //                                     children: [
// // // // // //                                       Text(
// // // // // //                                         pack.coverEmoji,
// // // // // //                                         style: const TextStyle(fontSize: 20),
// // // // // //                                       ),
// // // // // //                                       const Spacer(),
// // // // // //                                       if (selected)
// // // // // //                                         Icon(
// // // // // //                                           Icons.check_circle_rounded,
// // // // // //                                           color: theme.colorScheme.primary,
// // // // // //                                           size: 18,
// // // // // //                                         ),
// // // // // //                                     ],
// // // // // //                                   ),
// // // // // //                                   const SizedBox(height: 6),
// // // // // //                                   Text(
// // // // // //                                     pack.titleJson['en'] as String? ?? pack.id,
// // // // // //                                     style: theme.textTheme.labelMedium
// // // // // //                                         ?.copyWith(fontWeight: FontWeight.w600),
// // // // // //                                     maxLines: 2,
// // // // // //                                     overflow: TextOverflow.ellipsis,
// // // // // //                                   ),
// // // // // //                                   const SizedBox(height: 4),
// // // // // //                                   Text(
// // // // // //                                     '${pack.cardCount} cards',
// // // // // //                                     style: theme.textTheme.labelSmall?.copyWith(
// // // // // //                                       color: theme.colorScheme.onSurfaceVariant,
// // // // // //                                     ),
// // // // // //                                   ),
// // // // // //                                 ],
// // // // // //                               ),
// // // // // //                             ),
// // // // // //                           );
// // // // // //                         },
// // // // // //                       ),
// // // // // //                     ),
// // // // // //                   const SizedBox(height: 20),
// // // // // //                 ],

// // // // // //                 // ── Game settings ─────────────────────────────────────────────
// // // // // //                 _SliderRow(
// // // // // //                   label: l10n.gameSettingsTurnTimer,
// // // // // //                   value: s.turnTimerSeconds.toDouble(),
// // // // // //                   display: l10n.gameSettingsSeconds(s.turnTimerSeconds),
// // // // // //                   min: 15,
// // // // // //                   max: 120,
// // // // // //                   divisions: 21,
// // // // // //                   onChanged: (v) =>
// // // // // //                       room.updateSetting('turn_timer_secs', v.round()),
// // // // // //                 ),
// // // // // //                 _SliderRow(
// // // // // //                   label: l10n.gameSettingsMaxRounds,
// // // // // //                   value: s.maxRounds.toDouble(),
// // // // // //                   display: '${s.maxRounds}',
// // // // // //                   min: 3,
// // // // // //                   max: 30,
// // // // // //                   divisions: 27,
// // // // // //                   onChanged: (v) => room.updateSetting('max_rounds', v.round()),
// // // // // //                 ),
// // // // // //                 const SizedBox(height: 4),
// // // // // //                 _SwitchRow(
// // // // // //                   label: l10n.gameSettingsAllowSkip,
// // // // // //                   icon: Icons.skip_next_rounded,
// // // // // //                   value: s.allowSkip,
// // // // // //                   onChanged: (v) => room.updateSetting('allow_skip', v),
// // // // // //                 ),
// // // // // //                 _SwitchRow(
// // // // // //                   label: 'Chat',
// // // // // //                   icon: Icons.chat_bubble_outline_rounded,
// // // // // //                   value: s.chatEnabled,
// // // // // //                   onChanged: (v) => room.updateSetting('chat_enabled', v),
// // // // // //                 ),
// // // // // //                 _SwitchRow(
// // // // // //                   label: l10n.gameSettingsAllowSpectators,
// // // // // //                   icon: Icons.visibility_outlined,
// // // // // //                   value: s.allowSpectators,
// // // // // //                   onChanged: (v) => room.updateSetting('allow_spectators', v),
// // // // // //                 ),
// // // // // //                 _SwitchRow(
// // // // // //                   label: l10n.gameSettingsSpicy,
// // // // // //                   icon: Icons.local_fire_department_outlined,
// // // // // //                   value: s.allowSpicy,
// // // // // //                   onChanged: (v) => room.updateSetting('allow_spicy', v),
// // // // // //                 ),
// // // // // //                 _SwitchRow(
// // // // // //                   label: l10n.gameSettingsRequireApproval,
// // // // // //                   icon: Icons.lock_outline_rounded,
// // // // // //                   value: s.requiresApproval,
// // // // // //                   onChanged: (v) => room.updateSetting('requires_approval', v),
// // // // // //                 ),
// // // // // //               ],
// // // // // //             ),
// // // // // //           );
// // // // // //         },
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // // ── Helpers ───────────────────────────────────────────────────────────────────

// // // // // // extension _PackX on PackEntity {
// // // // // //   String get coverEmoji {
// // // // // //     if (titleJson['en']?.toString().toLowerCase().contains('arabic') == true)
// // // // // //       return '🌙';
// // // // // //     if (titleJson['en']?.toString().toLowerCase().contains('party') == true)
// // // // // //       return '🎉';
// // // // // //     return '🎮';
// // // // // //   }
// // // // // // }

// // // // // // class _SliderRow extends StatelessWidget {
// // // // // //   const _SliderRow({
// // // // // //     required this.label,
// // // // // //     required this.value,
// // // // // //     required this.display,
// // // // // //     required this.min,
// // // // // //     required this.max,
// // // // // //     required this.divisions,
// // // // // //     required this.onChanged,
// // // // // //   });
// // // // // //   final String label;
// // // // // //   final double value;
// // // // // //   final String display;
// // // // // //   final double min, max;
// // // // // //   final int divisions;
// // // // // //   final void Function(double) onChanged;

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     final theme = context.theme;
// // // // // //     return Padding(
// // // // // //       padding: const EdgeInsets.symmetric(vertical: 4),
// // // // // //       child: Row(
// // // // // //         children: [
// // // // // //           Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
// // // // // //           Text(
// // // // // //             display,
// // // // // //             style: theme.textTheme.labelMedium?.copyWith(
// // // // // //               color: theme.colorScheme.primary,
// // // // // //               fontWeight: FontWeight.w600,
// // // // // //             ),
// // // // // //           ),
// // // // // //           const SizedBox(width: 8),
// // // // // //           SizedBox(
// // // // // //             width: 120,
// // // // // //             child: Slider(
// // // // // //               value: value.clamp(min, max),
// // // // // //               min: min,
// // // // // //               max: max,
// // // // // //               divisions: divisions,
// // // // // //               onChanged: onChanged,
// // // // // //             ),
// // // // // //           ),
// // // // // //         ],
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // class _SwitchRow extends StatelessWidget {
// // // // // //   const _SwitchRow({
// // // // // //     required this.label,
// // // // // //     required this.icon,
// // // // // //     required this.value,
// // // // // //     required this.onChanged,
// // // // // //   });
// // // // // //   final String label;
// // // // // //   final IconData icon;
// // // // // //   final bool value;
// // // // // //   final void Function(bool)? onChanged;

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     final theme = context.theme;
// // // // // //     return Padding(
// // // // // //       padding: const EdgeInsets.symmetric(vertical: 2),
// // // // // //       child: Row(
// // // // // //         children: [
// // // // // //           Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
// // // // // //           const SizedBox(width: 12),
// // // // // //           Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
// // // // // //           Switch(value: value, onChanged: onChanged),
// // // // // //         ],
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:provider/provider.dart';

// // // // // import '../../../../core/extensions/context_ext.dart';
// // // // // import '../../../../core/theme/app_colors.dart';
// // // // // import '../../../packs/data/pack_repository.dart';
// // // // // import '../../../packs/domain/pack_entity.dart';
// // // // // import '../../../packs/presentation/pack_provider.dart';
// // // // // import '../room_provider.dart';

// // // // // class GameSettingsSheet extends StatefulWidget {
// // // // //   const GameSettingsSheet({super.key});

// // // // //   @override
// // // // //   State<GameSettingsSheet> createState() => _GameSettingsSheetState();
// // // // // }

// // // // // class _GameSettingsSheetState extends State<GameSettingsSheet> {
// // // // //   List<PackEntity> _packs = [];
// // // // //   bool _loadingPacks = true;
// // // // //   String _langFilter = 'all'; // 'all' | 'en' | 'ar' | 'fr'

// // // // //   static const _langs = [
// // // // //     ('all', '🌐 All'),
// // // // //     ('en', '🇬🇧 EN'),
// // // // //     ('ar', '🇸🇦 AR'),
// // // // //     ('fr', '🇫🇷 FR'),
// // // // //   ];

// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();
// // // // //     _loadPacks();
// // // // //   }

// // // // //   Future<void> _loadPacks() async {
// // // // //     try {
// // // // //       final packProvider = context.read<PackProvider>();
// // // // //       final owned = [
// // // // //         ...packProvider.purchasedPacks,
// // // // //         ...packProvider.localPacks,
// // // // //         ...packProvider.browsePacks.where((p) => p.isFree),
// // // // //       ];
// // // // //       final seen = <String>{};
// // // // //       final unique = owned.where((p) => seen.add(p.id)).toList();
// // // // //       if (mounted)
// // // // //         setState(() {
// // // // //           _packs = unique;
// // // // //           _loadingPacks = false;
// // // // //         });
// // // // //     } catch (e) {
// // // // //       if (mounted) setState(() => _loadingPacks = false);
// // // // //     }
// // // // //   }

// // // // //   List<PackEntity> get _filteredPacks {
// // // // //     if (_langFilter == 'all') return _packs;
// // // // //     return _packs.where((p) {
// // // // //       // Check availableLanguages array (from DB migration)
// // // // //       if (p.availableLanguages.isNotEmpty) {
// // // // //         return p.availableLanguages.contains(_langFilter);
// // // // //       }
// // // // //       // Fallback if column not yet migrated
// // // // //       return p.language == _langFilter ||
// // // // //           p.language == 'multi' ||
// // // // //           p.isMultilang;
// // // // //     }).toList();
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final theme = context.theme;
// // // // //     final l10n = context.l10n;

// // // // //     return Container(
// // // // //       decoration: BoxDecoration(
// // // // //         color: theme.colorScheme.surface,
// // // // //         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
// // // // //       ),
// // // // //       padding: EdgeInsets.fromLTRB(
// // // // //         24,
// // // // //         12,
// // // // //         24,
// // // // //         MediaQuery.viewInsetsOf(context).bottom + 24,
// // // // //       ),
// // // // //       child: Consumer<RoomProvider>(
// // // // //         builder: (_, room, __) {
// // // // //           final s = room.settings;
// // // // //           return SingleChildScrollView(
// // // // //             child: Column(
// // // // //               mainAxisSize: MainAxisSize.min,
// // // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // // //               children: [
// // // // //                 // Handle
// // // // //                 Center(
// // // // //                   child: Container(
// // // // //                     width: 36,
// // // // //                     height: 4,
// // // // //                     decoration: BoxDecoration(
// // // // //                       color: theme.colorScheme.outlineVariant,
// // // // //                       borderRadius: BorderRadius.circular(2),
// // // // //                     ),
// // // // //                   ),
// // // // //                 ),
// // // // //                 const SizedBox(height: 20),

// // // // //                 Text(
// // // // //                   l10n.gameSettings,
// // // // //                   style: theme.textTheme.titleLarge?.copyWith(
// // // // //                     fontWeight: FontWeight.w700,
// // // // //                   ),
// // // // //                 ),
// // // // //                 const SizedBox(height: 20),

// // // // //                 // ── Language filter ──────────────────────────────────────────
// // // // //                 Text(
// // // // //                   'Language',
// // // // //                   style: theme.textTheme.labelLarge?.copyWith(
// // // // //                     fontWeight: FontWeight.w600,
// // // // //                   ),
// // // // //                 ),
// // // // //                 const SizedBox(height: 8),
// // // // //                 SingleChildScrollView(
// // // // //                   scrollDirection: Axis.horizontal,
// // // // //                   child: Row(
// // // // //                     children: _langs.map((lang) {
// // // // //                       final selected = _langFilter == lang.$1;
// // // // //                       return Padding(
// // // // //                         padding: const EdgeInsets.only(right: 8),
// // // // //                         child: ChoiceChip(
// // // // //                           label: Text(lang.$2),
// // // // //                           selected: selected,
// // // // //                           onSelected: (_) =>
// // // // //                               setState(() => _langFilter = lang.$1),
// // // // //                         ),
// // // // //                       );
// // // // //                     }).toList(),
// // // // //                   ),
// // // // //                 ),
// // // // //                 const SizedBox(height: 20),

// // // // //                 // ── Pack picker ───────────────────────────────────────────────
// // // // //                 if (room.isOwner) ...[
// // // // //                   Text(
// // // // //                     'Select Pack',
// // // // //                     style: theme.textTheme.labelLarge?.copyWith(
// // // // //                       fontWeight: FontWeight.w600,
// // // // //                     ),
// // // // //                   ),
// // // // //                   const SizedBox(height: 8),
// // // // //                   if (_loadingPacks)
// // // // //                     const Padding(
// // // // //                       padding: EdgeInsets.symmetric(vertical: 16),
// // // // //                       child: Center(child: CircularProgressIndicator()),
// // // // //                     )
// // // // //                   else if (_packs.isEmpty)
// // // // //                     Container(
// // // // //                       padding: const EdgeInsets.all(16),
// // // // //                       decoration: BoxDecoration(
// // // // //                         color: theme.colorScheme.surfaceContainerHighest,
// // // // //                         borderRadius: BorderRadius.circular(12),
// // // // //                       ),
// // // // //                       child: Row(
// // // // //                         children: [
// // // // //                           Icon(
// // // // //                             Icons.info_outline,
// // // // //                             color: theme.colorScheme.onSurfaceVariant,
// // // // //                           ),
// // // // //                           const SizedBox(width: 12),
// // // // //                           Expanded(
// // // // //                             child: Text(
// // // // //                               'No packs available. Run the seed SQL in Supabase.',
// // // // //                               style: theme.textTheme.bodySmall,
// // // // //                             ),
// // // // //                           ),
// // // // //                         ],
// // // // //                       ),
// // // // //                     )
// // // // //                   else
// // // // //                     SizedBox(
// // // // //                       height: 110,
// // // // //                       child: ListView.separated(
// // // // //                         scrollDirection: Axis.horizontal,
// // // // //                         itemCount: _filteredPacks.length,
// // // // //                         separatorBuilder: (_, __) => const SizedBox(width: 10),
// // // // //                         itemBuilder: (ctx, i) {
// // // // //                           final pack = _filteredPacks[i];
// // // // //                           final selected = room.room?.packId == pack.id;
// // // // //                           return GestureDetector(
// // // // //                             onTap: () => room.setPackId(pack.id),
// // // // //                             child: AnimatedContainer(
// // // // //                               duration: const Duration(milliseconds: 180),
// // // // //                               width: 140,
// // // // //                               padding: const EdgeInsets.all(12),
// // // // //                               decoration: BoxDecoration(
// // // // //                                 color: selected
// // // // //                                     ? theme.colorScheme.primaryContainer
// // // // //                                     : theme.colorScheme.surfaceContainerHighest,
// // // // //                                 borderRadius: BorderRadius.circular(12),
// // // // //                                 border: Border.all(
// // // // //                                   color: selected
// // // // //                                       ? theme.colorScheme.primary
// // // // //                                       : Colors.transparent,
// // // // //                                   width: 2,
// // // // //                                 ),
// // // // //                               ),
// // // // //                               child: Column(
// // // // //                                 crossAxisAlignment: CrossAxisAlignment.start,
// // // // //                                 children: [
// // // // //                                   Row(
// // // // //                                     children: [
// // // // //                                       Text(
// // // // //                                         pack.coverEmoji,
// // // // //                                         style: const TextStyle(fontSize: 20),
// // // // //                                       ),
// // // // //                                       const Spacer(),
// // // // //                                       if (selected)
// // // // //                                         Icon(
// // // // //                                           Icons.check_circle_rounded,
// // // // //                                           color: theme.colorScheme.primary,
// // // // //                                           size: 18,
// // // // //                                         ),
// // // // //                                     ],
// // // // //                                   ),
// // // // //                                   const SizedBox(height: 6),
// // // // //                                   Text(
// // // // //                                     pack.titleJson['en'] as String? ?? pack.id,
// // // // //                                     style: theme.textTheme.labelMedium
// // // // //                                         ?.copyWith(fontWeight: FontWeight.w600),
// // // // //                                     maxLines: 2,
// // // // //                                     overflow: TextOverflow.ellipsis,
// // // // //                                   ),
// // // // //                                   const SizedBox(height: 4),
// // // // //                                   Text(
// // // // //                                     '${pack.cardCount} cards',
// // // // //                                     style: theme.textTheme.labelSmall?.copyWith(
// // // // //                                       color: theme.colorScheme.onSurfaceVariant,
// // // // //                                     ),
// // // // //                                   ),
// // // // //                                 ],
// // // // //                               ),
// // // // //                             ),
// // // // //                           );
// // // // //                         },
// // // // //                       ),
// // // // //                     ),
// // // // //                   const SizedBox(height: 20),
// // // // //                 ],

// // // // //                 // ── Game settings ─────────────────────────────────────────────
// // // // //                 _SliderRow(
// // // // //                   label: l10n.gameSettingsTurnTimer,
// // // // //                   value: s.turnTimerSeconds.toDouble(),
// // // // //                   display: l10n.gameSettingsSeconds(s.turnTimerSeconds),
// // // // //                   min: 15,
// // // // //                   max: 120,
// // // // //                   divisions: 21,
// // // // //                   onChanged: (v) =>
// // // // //                       room.updateSetting('turn_timer_secs', v.round()),
// // // // //                 ),
// // // // //                 _SliderRow(
// // // // //                   label: l10n.gameSettingsMaxRounds,
// // // // //                   value: s.maxRounds.toDouble(),
// // // // //                   display: '${s.maxRounds}',
// // // // //                   min: 3,
// // // // //                   max: 30,
// // // // //                   divisions: 27,
// // // // //                   onChanged: (v) => room.updateSetting('max_rounds', v.round()),
// // // // //                 ),
// // // // //                 const SizedBox(height: 4),
// // // // //                 _SwitchRow(
// // // // //                   label: l10n.gameSettingsAllowSkip,
// // // // //                   icon: Icons.skip_next_rounded,
// // // // //                   value: s.allowSkip,
// // // // //                   onChanged: (v) => room.updateSetting('allow_skip', v),
// // // // //                 ),
// // // // //                 _SwitchRow(
// // // // //                   label: 'Chat',
// // // // //                   icon: Icons.chat_bubble_outline_rounded,
// // // // //                   value: s.chatEnabled,
// // // // //                   onChanged: (v) => room.updateSetting('chat_enabled', v),
// // // // //                 ),
// // // // //                 _SwitchRow(
// // // // //                   label: l10n.gameSettingsAllowSpectators,
// // // // //                   icon: Icons.visibility_outlined,
// // // // //                   value: s.allowSpectators,
// // // // //                   onChanged: (v) => room.updateSetting('allow_spectators', v),
// // // // //                 ),
// // // // //                 _SwitchRow(
// // // // //                   label: l10n.gameSettingsSpicy,
// // // // //                   icon: Icons.local_fire_department_outlined,
// // // // //                   value: s.allowSpicy,
// // // // //                   onChanged: (v) => room.updateSetting('allow_spicy', v),
// // // // //                 ),
// // // // //                 _SwitchRow(
// // // // //                   label: l10n.gameSettingsRequireApproval,
// // // // //                   icon: Icons.lock_outline_rounded,
// // // // //                   value: s.requiresApproval,
// // // // //                   onChanged: (v) => room.updateSetting('requires_approval', v),
// // // // //                 ),
// // // // //               ],
// // // // //             ),
// // // // //           );
// // // // //         },
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // // ── Helpers ───────────────────────────────────────────────────────────────────

// // // // // extension _PackX on PackEntity {
// // // // //   String get coverEmoji {
// // // // //     if (titleJson['en']?.toString().toLowerCase().contains('arabic') == true)
// // // // //       return '🌙';
// // // // //     if (titleJson['en']?.toString().toLowerCase().contains('party') == true)
// // // // //       return '🎉';
// // // // //     return '🎮';
// // // // //   }
// // // // // }

// // // // // class _SliderRow extends StatelessWidget {
// // // // //   const _SliderRow({
// // // // //     required this.label,
// // // // //     required this.value,
// // // // //     required this.display,
// // // // //     required this.min,
// // // // //     required this.max,
// // // // //     required this.divisions,
// // // // //     required this.onChanged,
// // // // //   });
// // // // //   final String label;
// // // // //   final double value;
// // // // //   final String display;
// // // // //   final double min, max;
// // // // //   final int divisions;
// // // // //   final void Function(double) onChanged;

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final theme = context.theme;
// // // // //     return Padding(
// // // // //       padding: const EdgeInsets.symmetric(vertical: 4),
// // // // //       child: Row(
// // // // //         children: [
// // // // //           Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
// // // // //           Text(
// // // // //             display,
// // // // //             style: theme.textTheme.labelMedium?.copyWith(
// // // // //               color: theme.colorScheme.primary,
// // // // //               fontWeight: FontWeight.w600,
// // // // //             ),
// // // // //           ),
// // // // //           const SizedBox(width: 8),
// // // // //           SizedBox(
// // // // //             width: 120,
// // // // //             child: Slider(
// // // // //               value: value.clamp(min, max),
// // // // //               min: min,
// // // // //               max: max,
// // // // //               divisions: divisions,
// // // // //               onChanged: onChanged,
// // // // //             ),
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // class _SwitchRow extends StatelessWidget {
// // // // //   const _SwitchRow({
// // // // //     required this.label,
// // // // //     required this.icon,
// // // // //     required this.value,
// // // // //     required this.onChanged,
// // // // //   });
// // // // //   final String label;
// // // // //   final IconData icon;
// // // // //   final bool value;
// // // // //   final void Function(bool)? onChanged;

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final theme = context.theme;
// // // // //     return Padding(
// // // // //       padding: const EdgeInsets.symmetric(vertical: 2),
// // // // //       child: Row(
// // // // //         children: [
// // // // //           Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
// // // // //           const SizedBox(width: 12),
// // // // //           Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
// // // // //           Switch(value: value, onChanged: onChanged),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // import 'package:flutter/material.dart';
// // // // import 'package:provider/provider.dart';

// // // // import '../../../../core/extensions/context_ext.dart';
// // // // import '../../../../core/theme/app_colors.dart';
// // // // import '../../../packs/data/pack_repository.dart';
// // // // import '../../../packs/domain/pack_entity.dart';
// // // // import '../../../packs/presentation/pack_provider.dart';
// // // // import '../room_provider.dart';

// // // // class GameSettingsSheet extends StatefulWidget {
// // // //   const GameSettingsSheet({super.key});

// // // //   @override
// // // //   State<GameSettingsSheet> createState() => _GameSettingsSheetState();
// // // // }

// // // // class _GameSettingsSheetState extends State<GameSettingsSheet> {
// // // //   List<PackEntity> _packs = [];
// // // //   bool _loadingPacks = true;
// // // //   String _langFilter = 'all'; // 'all' | 'en' | 'ar' | 'fr'

// // // //   static const _langs = [
// // // //     ('all', '🌐 All'),
// // // //     ('en', '🇬🇧 EN'),
// // // //     ('ar', '🇸🇦 AR'),
// // // //     ('fr', '🇫🇷 FR'),
// // // //   ];

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     // Reflect the room's actual language so the sheet shows the real
// // // //     // current state instead of always opening on "All".
// // // //     _langFilter = context.read<RoomProvider>().room?.language ?? 'en';
// // // //     _loadPacks();
// // // //   }

// // // //   Future<void> _loadPacks() async {
// // // //     try {
// // // //       final packProvider = context.read<PackProvider>();
// // // //       final owned = [
// // // //         ...packProvider.purchasedPacks,
// // // //         ...packProvider.localPacks,
// // // //         ...packProvider.browsePacks.where((p) => p.isFree),
// // // //       ];
// // // //       final seen = <String>{};
// // // //       final unique = owned.where((p) => seen.add(p.id)).toList();
// // // //       if (mounted)
// // // //         setState(() {
// // // //           _packs = unique;
// // // //           _loadingPacks = false;
// // // //         });
// // // //     } catch (e) {
// // // //       if (mounted) setState(() => _loadingPacks = false);
// // // //     }
// // // //   }

// // // //   List<PackEntity> get _filteredPacks {
// // // //     if (_langFilter == 'all') return _packs;
// // // //     return _packs.where((p) {
// // // //       // Check availableLanguages array (from DB migration)
// // // //       if (p.availableLanguages.isNotEmpty) {
// // // //         return p.availableLanguages.contains(_langFilter);
// // // //       }
// // // //       // Fallback if column not yet migrated
// // // //       return p.language == _langFilter ||
// // // //           p.language == 'multi' ||
// // // //           p.isMultilang;
// // // //     }).toList();
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final theme = context.theme;
// // // //     final l10n = context.l10n;

// // // //     return Container(
// // // //       decoration: BoxDecoration(
// // // //         color: theme.colorScheme.surface,
// // // //         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
// // // //       ),
// // // //       padding: EdgeInsets.fromLTRB(
// // // //         24,
// // // //         12,
// // // //         24,
// // // //         MediaQuery.viewInsetsOf(context).bottom + 24,
// // // //       ),
// // // //       child: Consumer<RoomProvider>(
// // // //         builder: (_, room, __) {
// // // //           final s = room.settings;
// // // //           return SingleChildScrollView(
// // // //             child: Column(
// // // //               mainAxisSize: MainAxisSize.min,
// // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // //               children: [
// // // //                 // Handle
// // // //                 Center(
// // // //                   child: Container(
// // // //                     width: 36,
// // // //                     height: 4,
// // // //                     decoration: BoxDecoration(
// // // //                       color: theme.colorScheme.outlineVariant,
// // // //                       borderRadius: BorderRadius.circular(2),
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //                 const SizedBox(height: 20),

// // // //                 Text(
// // // //                   l10n.gameSettings,
// // // //                   style: theme.textTheme.titleLarge?.copyWith(
// // // //                     fontWeight: FontWeight.w700,
// // // //                   ),
// // // //                 ),
// // // //                 const SizedBox(height: 20),

// // // //                 // ── Language filter ──────────────────────────────────────────
// // // //                 Text(
// // // //                   'Language',
// // // //                   style: theme.textTheme.labelLarge?.copyWith(
// // // //                     fontWeight: FontWeight.w600,
// // // //                   ),
// // // //                 ),
// // // //                 const SizedBox(height: 8),
// // // //                 SingleChildScrollView(
// // // //                   scrollDirection: Axis.horizontal,
// // // //                   child: Row(
// // // //                     children: _langs.map((lang) {
// // // //                       final selected = _langFilter == lang.$1;
// // // //                       return Padding(
// // // //                         padding: const EdgeInsets.only(right: 8),
// // // //                         child: ChoiceChip(
// // // //                           label: Text(lang.$2),
// // // //                           selected: selected,
// // // //                           onSelected: (_) {
// // // //                             setState(() => _langFilter = lang.$1);
// // // //                             // "All" is a browse-only filter — only a real
// // // //                             // language should be persisted as the game's
// // // //                             // active language.
// // // //                             if (lang.$1 != 'all') {
// // // //                               room.setLanguage(lang.$1);
// // // //                             }
// // // //                           },
// // // //                         ),
// // // //                       );
// // // //                     }).toList(),
// // // //                   ),
// // // //                 ),
// // // //                 const SizedBox(height: 20),

// // // //                 // ── Pack picker ───────────────────────────────────────────────
// // // //                 if (room.isOwner) ...[
// // // //                   Text(
// // // //                     'Select Pack',
// // // //                     style: theme.textTheme.labelLarge?.copyWith(
// // // //                       fontWeight: FontWeight.w600,
// // // //                     ),
// // // //                   ),
// // // //                   const SizedBox(height: 8),
// // // //                   if (_loadingPacks)
// // // //                     const Padding(
// // // //                       padding: EdgeInsets.symmetric(vertical: 16),
// // // //                       child: Center(child: CircularProgressIndicator()),
// // // //                     )
// // // //                   else if (_packs.isEmpty)
// // // //                     Container(
// // // //                       padding: const EdgeInsets.all(16),
// // // //                       decoration: BoxDecoration(
// // // //                         color: theme.colorScheme.surfaceContainerHighest,
// // // //                         borderRadius: BorderRadius.circular(12),
// // // //                       ),
// // // //                       child: Row(
// // // //                         children: [
// // // //                           Icon(
// // // //                             Icons.info_outline,
// // // //                             color: theme.colorScheme.onSurfaceVariant,
// // // //                           ),
// // // //                           const SizedBox(width: 12),
// // // //                           Expanded(
// // // //                             child: Text(
// // // //                               'No packs available. Run the seed SQL in Supabase.',
// // // //                               style: theme.textTheme.bodySmall,
// // // //                             ),
// // // //                           ),
// // // //                         ],
// // // //                       ),
// // // //                     )
// // // //                   else
// // // //                     SizedBox(
// // // //                       height: 110,
// // // //                       child: ListView.separated(
// // // //                         scrollDirection: Axis.horizontal,
// // // //                         itemCount: _filteredPacks.length,
// // // //                         separatorBuilder: (_, __) => const SizedBox(width: 10),
// // // //                         itemBuilder: (ctx, i) {
// // // //                           final pack = _filteredPacks[i];
// // // //                           final selected = room.room?.packId == pack.id;
// // // //                           return GestureDetector(
// // // //                             onTap: () => room.setPackId(pack.id),
// // // //                             child: AnimatedContainer(
// // // //                               duration: const Duration(milliseconds: 180),
// // // //                               width: 140,
// // // //                               padding: const EdgeInsets.all(12),
// // // //                               decoration: BoxDecoration(
// // // //                                 color: selected
// // // //                                     ? theme.colorScheme.primaryContainer
// // // //                                     : theme.colorScheme.surfaceContainerHighest,
// // // //                                 borderRadius: BorderRadius.circular(12),
// // // //                                 border: Border.all(
// // // //                                   color: selected
// // // //                                       ? theme.colorScheme.primary
// // // //                                       : Colors.transparent,
// // // //                                   width: 2,
// // // //                                 ),
// // // //                               ),
// // // //                               child: Column(
// // // //                                 crossAxisAlignment: CrossAxisAlignment.start,
// // // //                                 children: [
// // // //                                   Row(
// // // //                                     children: [
// // // //                                       Text(
// // // //                                         pack.coverEmoji,
// // // //                                         style: const TextStyle(fontSize: 20),
// // // //                                       ),
// // // //                                       const Spacer(),
// // // //                                       if (selected)
// // // //                                         Icon(
// // // //                                           Icons.check_circle_rounded,
// // // //                                           color: theme.colorScheme.primary,
// // // //                                           size: 18,
// // // //                                         ),
// // // //                                     ],
// // // //                                   ),
// // // //                                   const SizedBox(height: 6),
// // // //                                   Text(
// // // //                                     pack.titleJson['en'] as String? ?? pack.id,
// // // //                                     style: theme.textTheme.labelMedium
// // // //                                         ?.copyWith(fontWeight: FontWeight.w600),
// // // //                                     maxLines: 2,
// // // //                                     overflow: TextOverflow.ellipsis,
// // // //                                   ),
// // // //                                   const SizedBox(height: 4),
// // // //                                   Text(
// // // //                                     '${pack.cardCount} cards',
// // // //                                     style: theme.textTheme.labelSmall?.copyWith(
// // // //                                       color: theme.colorScheme.onSurfaceVariant,
// // // //                                     ),
// // // //                                   ),
// // // //                                 ],
// // // //                               ),
// // // //                             ),
// // // //                           );
// // // //                         },
// // // //                       ),
// // // //                     ),
// // // //                   const SizedBox(height: 20),
// // // //                 ],

// // // //                 // ── Game settings ─────────────────────────────────────────────
// // // //                 _SliderRow(
// // // //                   label: l10n.gameSettingsTurnTimer,
// // // //                   value: s.turnTimerSeconds.toDouble(),
// // // //                   display: l10n.gameSettingsSeconds(s.turnTimerSeconds),
// // // //                   min: 15,
// // // //                   max: 120,
// // // //                   divisions: 21,
// // // //                   onChanged: (v) =>
// // // //                       room.updateSetting('turn_timer_secs', v.round()),
// // // //                 ),
// // // //                 _SliderRow(
// // // //                   label: l10n.gameSettingsMaxRounds,
// // // //                   value: s.maxRounds.toDouble(),
// // // //                   display: '${s.maxRounds}',
// // // //                   min: 3,
// // // //                   max: 30,
// // // //                   divisions: 27,
// // // //                   onChanged: (v) => room.updateSetting('max_rounds', v.round()),
// // // //                 ),
// // // //                 const SizedBox(height: 4),
// // // //                 _SwitchRow(
// // // //                   label: l10n.gameSettingsAllowSkip,
// // // //                   icon: Icons.skip_next_rounded,
// // // //                   value: s.allowSkip,
// // // //                   onChanged: (v) => room.updateSetting('allow_skip', v),
// // // //                 ),
// // // //                 _SwitchRow(
// // // //                   label: 'Chat',
// // // //                   icon: Icons.chat_bubble_outline_rounded,
// // // //                   value: s.chatEnabled,
// // // //                   onChanged: (v) => room.updateSetting('chat_enabled', v),
// // // //                 ),
// // // //                 _SwitchRow(
// // // //                   label: l10n.gameSettingsAllowSpectators,
// // // //                   icon: Icons.visibility_outlined,
// // // //                   value: s.allowSpectators,
// // // //                   onChanged: (v) => room.updateSetting('allow_spectators', v),
// // // //                 ),
// // // //                 _SwitchRow(
// // // //                   label: l10n.gameSettingsSpicy,
// // // //                   icon: Icons.local_fire_department_outlined,
// // // //                   value: s.allowSpicy,
// // // //                   onChanged: (v) => room.updateSetting('allow_spicy', v),
// // // //                 ),
// // // //                 _SwitchRow(
// // // //                   label: l10n.gameSettingsRequireApproval,
// // // //                   icon: Icons.lock_outline_rounded,
// // // //                   value: s.requiresApproval,
// // // //                   onChanged: (v) => room.updateSetting('requires_approval', v),
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           );
// // // //         },
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // // ── Helpers ───────────────────────────────────────────────────────────────────

// // // // extension _PackX on PackEntity {
// // // //   String get coverEmoji {
// // // //     if (titleJson['en']?.toString().toLowerCase().contains('arabic') == true)
// // // //       return '🌙';
// // // //     if (titleJson['en']?.toString().toLowerCase().contains('party') == true)
// // // //       return '🎉';
// // // //     return '🎮';
// // // //   }
// // // // }

// // // // class _SliderRow extends StatelessWidget {
// // // //   const _SliderRow({
// // // //     required this.label,
// // // //     required this.value,
// // // //     required this.display,
// // // //     required this.min,
// // // //     required this.max,
// // // //     required this.divisions,
// // // //     required this.onChanged,
// // // //   });
// // // //   final String label;
// // // //   final double value;
// // // //   final String display;
// // // //   final double min, max;
// // // //   final int divisions;
// // // //   final void Function(double) onChanged;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final theme = context.theme;
// // // //     return Padding(
// // // //       padding: const EdgeInsets.symmetric(vertical: 4),
// // // //       child: Row(
// // // //         children: [
// // // //           Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
// // // //           Text(
// // // //             display,
// // // //             style: theme.textTheme.labelMedium?.copyWith(
// // // //               color: theme.colorScheme.primary,
// // // //               fontWeight: FontWeight.w600,
// // // //             ),
// // // //           ),
// // // //           const SizedBox(width: 8),
// // // //           SizedBox(
// // // //             width: 120,
// // // //             child: Slider(
// // // //               value: value.clamp(min, max),
// // // //               min: min,
// // // //               max: max,
// // // //               divisions: divisions,
// // // //               onChanged: onChanged,
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class _SwitchRow extends StatelessWidget {
// // // //   const _SwitchRow({
// // // //     required this.label,
// // // //     required this.icon,
// // // //     required this.value,
// // // //     required this.onChanged,
// // // //   });
// // // //   final String label;
// // // //   final IconData icon;
// // // //   final bool value;
// // // //   final void Function(bool)? onChanged;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final theme = context.theme;
// // // //     return Padding(
// // // //       padding: const EdgeInsets.symmetric(vertical: 2),
// // // //       child: Row(
// // // //         children: [
// // // //           Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
// // // //           const SizedBox(width: 12),
// // // //           Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
// // // //           Switch(value: value, onChanged: onChanged),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // import 'package:flutter/material.dart';
// // // import 'package:provider/provider.dart';

// // // import '../../../../core/extensions/context_ext.dart';
// // // import '../../../../core/theme/app_colors.dart';
// // // import '../../../packs/data/pack_repository.dart';
// // // import '../../../packs/domain/pack_entity.dart';
// // // import '../../../packs/presentation/pack_provider.dart';
// // // import '../room_provider.dart';

// // // class GameSettingsSheet extends StatefulWidget {
// // //   const GameSettingsSheet({super.key});

// // //   @override
// // //   State<GameSettingsSheet> createState() => _GameSettingsSheetState();
// // // }

// // // class _GameSettingsSheetState extends State<GameSettingsSheet> {
// // //   List<PackEntity> _packs = [];
// // //   bool _loadingPacks = true;
// // //   String _langFilter = 'all'; // 'all' | 'en' | 'ar' | 'fr'

// // //   // packId → languages every active card actually has content for.
// // //   // Populated alongside _packs in _loadPacks(); used so the filter below
// // //   // can't be fooled by a pack whose metadata claims a language but whose
// // //   // cards were never actually translated.
// // //   Map<String, Set<String>> _cardLanguages = {};

// // //   static const _langs = [
// // //     ('all', '🌐 All'),
// // //     ('en', '🇬🇧 EN'),
// // //     ('ar', '🇸🇦 AR'),
// // //     ('fr', '🇫🇷 FR'),
// // //   ];

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     // Reflect the room's actual language so the sheet shows the real
// // //     // current state instead of always opening on "All".
// // //     _langFilter = context.read<RoomProvider>().room?.language ?? 'en';
// // //     _loadPacks();
// // //   }

// // //   Future<void> _loadPacks() async {
// // //     try {
// // //       final packProvider = context.read<PackProvider>();
// // //       final owned = [
// // //         ...packProvider.purchasedPacks,
// // //         ...packProvider.localPacks,
// // //         ...packProvider.browsePacks.where((p) => p.isFree),
// // //       ];
// // //       final seen = <String>{};
// // //       final unique = owned.where((p) => seen.add(p.id)).toList();

// // //       // Best-effort: if this lookup fails for any reason, fall back to
// // //       // trusting pack metadata alone rather than blocking the picker.
// // //       var coverage = <String, Set<String>>{};
// // //       try {
// // //         coverage = await PackRepository.instance.getCardLanguageCoverage(
// // //           unique.map((p) => p.id).toList(),
// // //         );
// // //       } catch (_) {}

// // //       if (mounted)
// // //         setState(() {
// // //           _packs = unique;
// // //           _cardLanguages = coverage;
// // //           _loadingPacks = false;
// // //         });
// // //     } catch (e) {
// // //       if (mounted) setState(() => _loadingPacks = false);
// // //     }
// // //   }

// // //   List<PackEntity> get _filteredPacks {
// // //     if (_langFilter == 'all') return _packs;
// // //     return _packs.where((p) {
// // //       // Title/metadata must claim the language...
// // //       final titleHasLang = p.titleJson.containsKey(_langFilter);
// // //       if (!titleHasLang) return false;

// // //       // ...and the actual cards must really have it too. If the coverage
// // //       // lookup didn't return anything for this pack (e.g. it failed, or
// // //       // the pack has zero cards), fall back to the metadata flags so a
// // //       // pack isn't hidden just because of a lookup hiccup.
// // //       final knownCoverage = _cardLanguages[p.id];
// // //       if (knownCoverage != null) {
// // //         return knownCoverage.contains(_langFilter);
// // //       }
// // //       if (p.availableLanguages.isNotEmpty) {
// // //         return p.availableLanguages.contains(_langFilter);
// // //       }
// // //       return p.language == _langFilter ||
// // //           p.language == 'multi' ||
// // //           p.isMultilang;
// // //     }).toList();
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = context.theme;
// // //     final l10n = context.l10n;

// // //     return Container(
// // //       decoration: BoxDecoration(
// // //         color: theme.colorScheme.surface,
// // //         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
// // //       ),
// // //       padding: EdgeInsets.fromLTRB(
// // //         24,
// // //         12,
// // //         24,
// // //         MediaQuery.viewInsetsOf(context).bottom + 24,
// // //       ),
// // //       child: Consumer<RoomProvider>(
// // //         builder: (_, room, __) {
// // //           final s = room.settings;
// // //           return SingleChildScrollView(
// // //             child: Column(
// // //               mainAxisSize: MainAxisSize.min,
// // //               crossAxisAlignment: CrossAxisAlignment.start,
// // //               children: [
// // //                 // Handle
// // //                 Center(
// // //                   child: Container(
// // //                     width: 36,
// // //                     height: 4,
// // //                     decoration: BoxDecoration(
// // //                       color: theme.colorScheme.outlineVariant,
// // //                       borderRadius: BorderRadius.circular(2),
// // //                     ),
// // //                   ),
// // //                 ),
// // //                 const SizedBox(height: 20),

// // //                 Text(
// // //                   l10n.gameSettings,
// // //                   style: theme.textTheme.titleLarge?.copyWith(
// // //                     fontWeight: FontWeight.w700,
// // //                   ),
// // //                 ),
// // //                 const SizedBox(height: 20),

// // //                 // ── Language filter ──────────────────────────────────────────
// // //                 Text(
// // //                   'Language',
// // //                   style: theme.textTheme.labelLarge?.copyWith(
// // //                     fontWeight: FontWeight.w600,
// // //                   ),
// // //                 ),
// // //                 const SizedBox(height: 8),
// // //                 SingleChildScrollView(
// // //                   scrollDirection: Axis.horizontal,
// // //                   child: Row(
// // //                     children: _langs.map((lang) {
// // //                       final selected = _langFilter == lang.$1;
// // //                       return Padding(
// // //                         padding: const EdgeInsets.only(right: 8),
// // //                         child: ChoiceChip(
// // //                           label: Text(lang.$2),
// // //                           selected: selected,
// // //                           onSelected: (_) {
// // //                             setState(() => _langFilter = lang.$1);
// // //                             // "All" is a browse-only filter — only a real
// // //                             // language should be persisted as the game's
// // //                             // active language.
// // //                             if (lang.$1 != 'all') {
// // //                               room.setLanguage(lang.$1);
// // //                             }
// // //                           },
// // //                         ),
// // //                       );
// // //                     }).toList(),
// // //                   ),
// // //                 ),
// // //                 const SizedBox(height: 20),

// // //                 // ── Pack picker ───────────────────────────────────────────────
// // //                 if (room.isOwner) ...[
// // //                   Text(
// // //                     'Select Pack',
// // //                     style: theme.textTheme.labelLarge?.copyWith(
// // //                       fontWeight: FontWeight.w600,
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 8),
// // //                   if (_loadingPacks)
// // //                     const Padding(
// // //                       padding: EdgeInsets.symmetric(vertical: 16),
// // //                       child: Center(child: CircularProgressIndicator()),
// // //                     )
// // //                   else if (_packs.isEmpty)
// // //                     Container(
// // //                       padding: const EdgeInsets.all(16),
// // //                       decoration: BoxDecoration(
// // //                         color: theme.colorScheme.surfaceContainerHighest,
// // //                         borderRadius: BorderRadius.circular(12),
// // //                       ),
// // //                       child: Row(
// // //                         children: [
// // //                           Icon(
// // //                             Icons.info_outline,
// // //                             color: theme.colorScheme.onSurfaceVariant,
// // //                           ),
// // //                           const SizedBox(width: 12),
// // //                           Expanded(
// // //                             child: Text(
// // //                               'No packs available. Run the seed SQL in Supabase.',
// // //                               style: theme.textTheme.bodySmall,
// // //                             ),
// // //                           ),
// // //                         ],
// // //                       ),
// // //                     )
// // //                   else
// // //                     SizedBox(
// // //                       height: 110,
// // //                       child: ListView.separated(
// // //                         scrollDirection: Axis.horizontal,
// // //                         itemCount: _filteredPacks.length,
// // //                         separatorBuilder: (_, __) => const SizedBox(width: 10),
// // //                         itemBuilder: (ctx, i) {
// // //                           final pack = _filteredPacks[i];
// // //                           final selected = room.room?.packId == pack.id;
// // //                           return GestureDetector(
// // //                             onTap: () => room.setPackId(pack.id),
// // //                             child: AnimatedContainer(
// // //                               duration: const Duration(milliseconds: 180),
// // //                               width: 140,
// // //                               padding: const EdgeInsets.all(12),
// // //                               decoration: BoxDecoration(
// // //                                 color: selected
// // //                                     ? theme.colorScheme.primaryContainer
// // //                                     : theme.colorScheme.surfaceContainerHighest,
// // //                                 borderRadius: BorderRadius.circular(12),
// // //                                 border: Border.all(
// // //                                   color: selected
// // //                                       ? theme.colorScheme.primary
// // //                                       : Colors.transparent,
// // //                                   width: 2,
// // //                                 ),
// // //                               ),
// // //                               child: Column(
// // //                                 crossAxisAlignment: CrossAxisAlignment.start,
// // //                                 children: [
// // //                                   Row(
// // //                                     children: [
// // //                                       Text(
// // //                                         pack.coverEmoji,
// // //                                         style: const TextStyle(fontSize: 20),
// // //                                       ),
// // //                                       const Spacer(),
// // //                                       if (selected)
// // //                                         Icon(
// // //                                           Icons.check_circle_rounded,
// // //                                           color: theme.colorScheme.primary,
// // //                                           size: 18,
// // //                                         ),
// // //                                     ],
// // //                                   ),
// // //                                   const SizedBox(height: 6),
// // //                                   Text(
// // //                                     pack.titleJson['en'] as String? ?? pack.id,
// // //                                     style: theme.textTheme.labelMedium
// // //                                         ?.copyWith(fontWeight: FontWeight.w600),
// // //                                     maxLines: 2,
// // //                                     overflow: TextOverflow.ellipsis,
// // //                                   ),
// // //                                   const SizedBox(height: 4),
// // //                                   Text(
// // //                                     '${pack.cardCount} cards',
// // //                                     style: theme.textTheme.labelSmall?.copyWith(
// // //                                       color: theme.colorScheme.onSurfaceVariant,
// // //                                     ),
// // //                                   ),
// // //                                 ],
// // //                               ),
// // //                             ),
// // //                           );
// // //                         },
// // //                       ),
// // //                     ),
// // //                   const SizedBox(height: 20),
// // //                 ],

// // //                 // ── Game settings ─────────────────────────────────────────────
// // //                 _SliderRow(
// // //                   label: l10n.gameSettingsTurnTimer,
// // //                   value: s.turnTimerSeconds.toDouble(),
// // //                   display: l10n.gameSettingsSeconds(s.turnTimerSeconds),
// // //                   min: 15,
// // //                   max: 120,
// // //                   divisions: 21,
// // //                   onChanged: (v) =>
// // //                       room.updateSetting('turn_timer_secs', v.round()),
// // //                 ),
// // //                 _SliderRow(
// // //                   label: l10n.gameSettingsMaxRounds,
// // //                   value: s.maxRounds.toDouble(),
// // //                   display: '${s.maxRounds}',
// // //                   min: 3,
// // //                   max: 30,
// // //                   divisions: 27,
// // //                   onChanged: (v) => room.updateSetting('max_rounds', v.round()),
// // //                 ),
// // //                 const SizedBox(height: 4),
// // //                 _SwitchRow(
// // //                   label: l10n.gameSettingsAllowSkip,
// // //                   icon: Icons.skip_next_rounded,
// // //                   value: s.allowSkip,
// // //                   onChanged: (v) => room.updateSetting('allow_skip', v),
// // //                 ),
// // //                 _SwitchRow(
// // //                   label: 'Chat',
// // //                   icon: Icons.chat_bubble_outline_rounded,
// // //                   value: s.chatEnabled,
// // //                   onChanged: (v) => room.updateSetting('chat_enabled', v),
// // //                 ),
// // //                 _SwitchRow(
// // //                   label: l10n.gameSettingsAllowSpectators,
// // //                   icon: Icons.visibility_outlined,
// // //                   value: s.allowSpectators,
// // //                   onChanged: (v) => room.updateSetting('allow_spectators', v),
// // //                 ),
// // //                 _SwitchRow(
// // //                   label: l10n.gameSettingsSpicy,
// // //                   icon: Icons.local_fire_department_outlined,
// // //                   value: s.allowSpicy,
// // //                   onChanged: (v) => room.updateSetting('allow_spicy', v),
// // //                 ),
// // //                 _SwitchRow(
// // //                   label: l10n.gameSettingsRequireApproval,
// // //                   icon: Icons.lock_outline_rounded,
// // //                   value: s.requiresApproval,
// // //                   onChanged: (v) => room.updateSetting('requires_approval', v),
// // //                 ),
// // //               ],
// // //             ),
// // //           );
// // //         },
// // //       ),
// // //     );
// // //   }
// // // }

// // // // ── Helpers ───────────────────────────────────────────────────────────────────

// // // extension _PackX on PackEntity {
// // //   String get coverEmoji {
// // //     if (titleJson['en']?.toString().toLowerCase().contains('arabic') == true)
// // //       return '🌙';
// // //     if (titleJson['en']?.toString().toLowerCase().contains('party') == true)
// // //       return '🎉';
// // //     return '🎮';
// // //   }
// // // }

// // // class _SliderRow extends StatelessWidget {
// // //   const _SliderRow({
// // //     required this.label,
// // //     required this.value,
// // //     required this.display,
// // //     required this.min,
// // //     required this.max,
// // //     required this.divisions,
// // //     required this.onChanged,
// // //   });
// // //   final String label;
// // //   final double value;
// // //   final String display;
// // //   final double min, max;
// // //   final int divisions;
// // //   final void Function(double) onChanged;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = context.theme;
// // //     return Padding(
// // //       padding: const EdgeInsets.symmetric(vertical: 4),
// // //       child: Row(
// // //         children: [
// // //           Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
// // //           Text(
// // //             display,
// // //             style: theme.textTheme.labelMedium?.copyWith(
// // //               color: theme.colorScheme.primary,
// // //               fontWeight: FontWeight.w600,
// // //             ),
// // //           ),
// // //           const SizedBox(width: 8),
// // //           SizedBox(
// // //             width: 120,
// // //             child: Slider(
// // //               value: value.clamp(min, max),
// // //               min: min,
// // //               max: max,
// // //               divisions: divisions,
// // //               onChanged: onChanged,
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _SwitchRow extends StatelessWidget {
// // //   const _SwitchRow({
// // //     required this.label,
// // //     required this.icon,
// // //     required this.value,
// // //     required this.onChanged,
// // //   });
// // //   final String label;
// // //   final IconData icon;
// // //   final bool value;
// // //   final void Function(bool)? onChanged;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = context.theme;
// // //     return Padding(
// // //       padding: const EdgeInsets.symmetric(vertical: 2),
// // //       child: Row(
// // //         children: [
// // //           Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
// // //           const SizedBox(width: 12),
// // //           Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
// // //           Switch(value: value, onChanged: onChanged),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';

// // import '../../../../core/extensions/context_ext.dart';
// // import '../../../../core/theme/app_colors.dart';
// // import '../../../packs/data/pack_repository.dart';
// // import '../../../packs/domain/pack_entity.dart';
// // import '../../../packs/presentation/pack_provider.dart';
// // import '../room_provider.dart';

// // class GameSettingsSheet extends StatefulWidget {
// //   const GameSettingsSheet({super.key});

// //   @override
// //   State<GameSettingsSheet> createState() => _GameSettingsSheetState();
// // }

// // class _GameSettingsSheetState extends State<GameSettingsSheet> {
// //   List<PackEntity> _packs = [];
// //   bool _loadingPacks = true;
// //   String _langFilter = 'all'; // 'all' | 'en' | 'ar' | 'fr'

// //   // packId → languages every active card actually has content for.
// //   // Populated alongside _packs in _loadPacks(); used so the filter below
// //   // can't be fooled by a pack whose metadata claims a language but whose
// //   // cards were never actually translated.
// //   Map<String, Set<String>> _cardLanguages = {};

// //   static const _langs = [
// //     ('all', '🌐 All'),
// //     ('en', '🇬🇧 EN'),
// //     ('ar', '🇸🇦 AR'),
// //     ('fr', '🇫🇷 FR'),
// //   ];

// //   @override
// //   void initState() {
// //     super.initState();
// //     // Reflect the room's actual language so the sheet shows the real
// //     // current state instead of always opening on "All".
// //     _langFilter = context.read<RoomProvider>().room?.language ?? 'en';
// //     _loadPacks();
// //   }

// //   Future<void> _loadPacks() async {
// //     try {
// //       final packProvider = context.read<PackProvider>();
// //       final owned = [
// //         ...packProvider.purchasedPacks,
// //         ...packProvider.localPacks,
// //         ...packProvider.browsePacks.where((p) => p.isFree),
// //       ];
// //       final seen = <String>{};
// //       final unique = owned.where((p) => seen.add(p.id)).toList();

// //       // Best-effort: if this lookup fails for any reason, fall back to
// //       // trusting pack metadata alone rather than blocking the picker.
// //       var coverage = <String, Set<String>>{};
// //       try {
// //         coverage = await PackRepository.instance.getCardLanguageCoverage(
// //           unique.map((p) => p.id).toList(),
// //         );
// //       } catch (_) {}

// //       if (mounted)
// //         setState(() {
// //           _packs = unique;
// //           _cardLanguages = coverage;
// //           _loadingPacks = false;
// //         });
// //     } catch (e) {
// //       if (mounted) setState(() => _loadingPacks = false);
// //     }
// //   }

// //   List<PackEntity> get _filteredPacks {
// //     if (_langFilter == 'all') return _packs;
// //     return _packs.where((p) {
// //       // Title/metadata must claim the language...
// //       final titleHasLang = p.titleJson.containsKey(_langFilter);
// //       if (!titleHasLang) return false;

// //       // ...and the actual cards must really have it too. If the coverage
// //       // lookup didn't return anything for this pack (e.g. it failed, or
// //       // the pack has zero cards), fall back to the metadata flags so a
// //       // pack isn't hidden just because of a lookup hiccup.
// //       final knownCoverage = _cardLanguages[p.id];
// //       if (knownCoverage != null) {
// //         return knownCoverage.contains(_langFilter);
// //       }
// //       if (p.availableLanguages.isNotEmpty) {
// //         return p.availableLanguages.contains(_langFilter);
// //       }
// //       return p.language == _langFilter ||
// //           p.language == 'multi' ||
// //           p.isMultilang;
// //     }).toList();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = context.theme;
// //     final l10n = context.l10n;

// //     return Container(
// //       decoration: BoxDecoration(
// //         color: theme.colorScheme.surface,
// //         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
// //       ),
// //       padding: EdgeInsets.fromLTRB(
// //         24,
// //         12,
// //         24,
// //         MediaQuery.viewInsetsOf(context).bottom + 24,
// //       ),
// //       child: Consumer<RoomProvider>(
// //         builder: (_, room, __) {
// //           final s = room.settings;
// //           return SingleChildScrollView(
// //             child: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 // Handle
// //                 Center(
// //                   child: Container(
// //                     width: 36,
// //                     height: 4,
// //                     decoration: BoxDecoration(
// //                       color: theme.colorScheme.outlineVariant,
// //                       borderRadius: BorderRadius.circular(2),
// //                     ),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 20),

// //                 Text(
// //                   l10n.gameSettings,
// //                   style: theme.textTheme.titleLarge?.copyWith(
// //                     fontWeight: FontWeight.w700,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 20),

// //                 // ── Language filter ──────────────────────────────────────────
// //                 Text(
// //                   'Language',
// //                   style: theme.textTheme.labelLarge?.copyWith(
// //                     fontWeight: FontWeight.w600,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 8),
// //                 SingleChildScrollView(
// //                   scrollDirection: Axis.horizontal,
// //                   child: Row(
// //                     children: _langs.map((lang) {
// //                       final selected = _langFilter == lang.$1;
// //                       return Padding(
// //                         padding: const EdgeInsets.only(right: 8),
// //                         child: ChoiceChip(
// //                           label: Text(lang.$2),
// //                           selected: selected,
// //                           onSelected: (_) {
// //                             setState(() => _langFilter = lang.$1);
// //                             // "All" is a browse-only filter — only a real
// //                             // language should be persisted as the game's
// //                             // active language.
// //                             if (lang.$1 != 'all') {
// //                               room.setLanguage(lang.$1);
// //                             }
// //                           },
// //                         ),
// //                       );
// //                     }).toList(),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 20),

// //                 // ── Pack picker ───────────────────────────────────────────────
// //                 if (room.isOwner) ...[
// //                   Text(
// //                     'Select Pack',
// //                     style: theme.textTheme.labelLarge?.copyWith(
// //                       fontWeight: FontWeight.w600,
// //                     ),
// //                   ),
// //                   const SizedBox(height: 8),
// //                   if (_loadingPacks)
// //                     const Padding(
// //                       padding: EdgeInsets.symmetric(vertical: 16),
// //                       child: Center(child: CircularProgressIndicator()),
// //                     )
// //                   else if (_packs.isEmpty)
// //                     Container(
// //                       padding: const EdgeInsets.all(16),
// //                       decoration: BoxDecoration(
// //                         color: theme.colorScheme.surfaceContainerHighest,
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                       child: Row(
// //                         children: [
// //                           Icon(
// //                             Icons.info_outline,
// //                             color: theme.colorScheme.onSurfaceVariant,
// //                           ),
// //                           const SizedBox(width: 12),
// //                           Expanded(
// //                             child: Text(
// //                               'No packs available. Run the seed SQL in Supabase.',
// //                               style: theme.textTheme.bodySmall,
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     )
// //                   else
// //                     SizedBox(
// //                       height: 110,
// //                       child: ListView.separated(
// //                         scrollDirection: Axis.horizontal,
// //                         itemCount: _filteredPacks.length,
// //                         separatorBuilder: (_, __) => const SizedBox(width: 10),
// //                         itemBuilder: (ctx, i) {
// //                           final pack = _filteredPacks[i];
// //                           final selected = room.room?.packId == pack.id;
// //                           return GestureDetector(
// //                             onTap: () => room.setPackId(pack.id),
// //                             child: AnimatedContainer(
// //                               duration: const Duration(milliseconds: 180),
// //                               width: 140,
// //                               padding: const EdgeInsets.all(12),
// //                               decoration: BoxDecoration(
// //                                 color: selected
// //                                     ? theme.colorScheme.primaryContainer
// //                                     : theme.colorScheme.surfaceContainerHighest,
// //                                 borderRadius: BorderRadius.circular(12),
// //                                 border: Border.all(
// //                                   color: selected
// //                                       ? theme.colorScheme.primary
// //                                       : Colors.transparent,
// //                                   width: 2,
// //                                 ),
// //                               ),
// //                               child: Column(
// //                                 crossAxisAlignment: CrossAxisAlignment.start,
// //                                 children: [
// //                                   Row(
// //                                     children: [
// //                                       Text(
// //                                         pack.coverEmoji,
// //                                         style: const TextStyle(fontSize: 20),
// //                                       ),
// //                                       const Spacer(),
// //                                       if (selected)
// //                                         Icon(
// //                                           Icons.check_circle_rounded,
// //                                           color: theme.colorScheme.primary,
// //                                           size: 18,
// //                                         ),
// //                                     ],
// //                                   ),
// //                                   const SizedBox(height: 6),
// //                                   Text(
// //                                     pack.titleJson['en'] as String? ?? pack.id,
// //                                     style: theme.textTheme.labelMedium
// //                                         ?.copyWith(fontWeight: FontWeight.w600),
// //                                     maxLines: 2,
// //                                     overflow: TextOverflow.ellipsis,
// //                                   ),
// //                                   const SizedBox(height: 4),
// //                                   Text(
// //                                     '${pack.cardCount} cards',
// //                                     style: theme.textTheme.labelSmall?.copyWith(
// //                                       color: theme.colorScheme.onSurfaceVariant,
// //                                     ),
// //                                   ),
// //                                 ],
// //                               ),
// //                             ),
// //                           );
// //                         },
// //                       ),
// //                     ),
// //                   const SizedBox(height: 20),
// //                 ],

// //                 // ── Game settings ─────────────────────────────────────────────
// //                 _SliderRow(
// //                   label: l10n.gameSettingsTurnTimer,
// //                   value: s.turnTimerSeconds.toDouble(),
// //                   display: l10n.gameSettingsSeconds(s.turnTimerSeconds),
// //                   min: 15,
// //                   max: 120,
// //                   divisions: 21,
// //                   onChanged: (v) =>
// //                       room.updateSetting('turn_timer_secs', v.round()),
// //                 ),
// //                 _SliderRow(
// //                   label: l10n.gameSettingsMaxRounds,
// //                   value: s.maxRounds.toDouble(),
// //                   display: '${s.maxRounds}',
// //                   min: 3,
// //                   max: 30,
// //                   divisions: 27,
// //                   onChanged: (v) => room.updateSetting('max_rounds', v.round()),
// //                 ),
// //                 const SizedBox(height: 4),
// //                 _SwitchRow(
// //                   label: l10n.gameSettingsAllowSkip,
// //                   icon: Icons.skip_next_rounded,
// //                   value: s.allowSkip,
// //                   onChanged: (v) => room.updateSetting('allow_skip', v),
// //                 ),
// //                 _SwitchRow(
// //                   label: 'Chat',
// //                   icon: Icons.chat_bubble_outline_rounded,
// //                   value: s.chatEnabled,
// //                   onChanged: (v) => room.updateSetting('chat_enabled', v),
// //                 ),
// //                 _SwitchRow(
// //                   label: l10n.gameSettingsAllowSpectators,
// //                   icon: Icons.visibility_outlined,
// //                   value: s.allowSpectators,
// //                   onChanged: (v) => room.updateSetting('allow_spectators', v),
// //                 ),
// //                 // Approval gate only makes sense when spectators are enabled
// //                 if (s.allowSpectators)
// //                   _SwitchRow(
// //                     label: 'Require approval to spectate',
// //                     icon: Icons.how_to_reg_outlined,
// //                     value: s.spectatorApprovalRequired,
// //                     onChanged: (v) =>
// //                         room.updateSetting('spectator_approval_required', v),
// //                   ),
// //                 _SwitchRow(
// //                   label: l10n.gameSettingsSpicy,
// //                   icon: Icons.local_fire_department_outlined,
// //                   value: s.allowSpicy,
// //                   onChanged: (v) => room.updateSetting('allow_spicy', v),
// //                 ),
// //                 _SwitchRow(
// //                   label: l10n.gameSettingsRequireApproval,
// //                   icon: Icons.lock_outline_rounded,
// //                   value: s.requiresApproval,
// //                   onChanged: (v) => room.updateSetting('requires_approval', v),
// //                 ),
// //               ],
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }

// // // ── Helpers ───────────────────────────────────────────────────────────────────

// // extension _PackX on PackEntity {
// //   String get coverEmoji {
// //     if (titleJson['en']?.toString().toLowerCase().contains('arabic') == true)
// //       return '🌙';
// //     if (titleJson['en']?.toString().toLowerCase().contains('party') == true)
// //       return '🎉';
// //     return '🎮';
// //   }
// // }

// // class _SliderRow extends StatelessWidget {
// //   const _SliderRow({
// //     required this.label,
// //     required this.value,
// //     required this.display,
// //     required this.min,
// //     required this.max,
// //     required this.divisions,
// //     required this.onChanged,
// //   });
// //   final String label;
// //   final double value;
// //   final String display;
// //   final double min, max;
// //   final int divisions;
// //   final void Function(double) onChanged;

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = context.theme;
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(vertical: 4),
// //       child: Row(
// //         children: [
// //           Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
// //           Text(
// //             display,
// //             style: theme.textTheme.labelMedium?.copyWith(
// //               color: theme.colorScheme.primary,
// //               fontWeight: FontWeight.w600,
// //             ),
// //           ),
// //           const SizedBox(width: 8),
// //           SizedBox(
// //             width: 120,
// //             child: Slider(
// //               value: value.clamp(min, max),
// //               min: min,
// //               max: max,
// //               divisions: divisions,
// //               onChanged: onChanged,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class _SwitchRow extends StatelessWidget {
// //   const _SwitchRow({
// //     required this.label,
// //     required this.icon,
// //     required this.value,
// //     required this.onChanged,
// //   });
// //   final String label;
// //   final IconData icon;
// //   final bool value;
// //   final void Function(bool)? onChanged;

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = context.theme;
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(vertical: 2),
// //       child: Row(
// //         children: [
// //           Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
// //           const SizedBox(width: 12),
// //           Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
// //           Switch(value: value, onChanged: onChanged),
// //         ],
// //       ),
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../../../../core/di/service_locator.dart';
// import '../../../../core/extensions/context_ext.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../packs/data/pack_repository.dart';
// import '../../../packs/domain/pack_entity.dart';
// import '../../../packs/presentation/pack_provider.dart';
// import '../room_provider.dart';

// class GameSettingsSheet extends StatefulWidget {
//   const GameSettingsSheet({super.key});

//   @override
//   State<GameSettingsSheet> createState() => _GameSettingsSheetState();
// }

// class _GameSettingsSheetState extends State<GameSettingsSheet> {
//   List<PackEntity> _packs = [];
//   bool _loadingPacks = true;
//   String _langFilter = 'all'; // 'all' | 'en' | 'ar' | 'fr'
//   Set<String> _playedPackIds = {}; // packs already used in this room

//   // packId → languages every active card actually has content for.
//   // Populated alongside _packs in _loadPacks(); used so the filter below
//   // can't be fooled by a pack whose metadata claims a language but whose
//   // cards were never actually translated.
//   Map<String, Set<String>> _cardLanguages = {};

//   static const _langs = [
//     ('all', '🌐 All'),
//     ('en', '🇬🇧 EN'),
//     ('ar', '🇸🇦 AR'),
//     ('fr', '🇫🇷 FR'),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     // Reflect the room's actual language so the sheet shows the real
//     // current state instead of always opening on "All".
//     _langFilter = context.read<RoomProvider>().room?.language ?? 'en';
//     _loadPacks();
//   }

//   Future<void> _loadPacks() async {
//     try {
//       final packProvider = context.read<PackProvider>();
//       final owned = [
//         ...packProvider.purchasedPacks,
//         ...packProvider.localPacks,
//         ...packProvider.browsePacks.where((p) => p.isFree),
//       ];
//       final seen = <String>{};
//       final unique = owned.where((p) => seen.add(p.id)).toList();

//       // Best-effort: if this lookup fails for any reason, fall back to
//       // trusting pack metadata alone rather than blocking the picker.
//       var coverage = <String, Set<String>>{};
//       try {
//         coverage = await PackRepository.instance.getCardLanguageCoverage(
//           unique.map((p) => p.id).toList(),
//         );
//       } catch (_) {}

//       // Load which packs have already been played in this room so we
//       // can grey them out in the picker (can't reuse a pack per room).
//       var playedIds = <String>{};
//       try {
//         final roomId = context.read<RoomProvider>().room?.id;
//         if (roomId != null) {
//           playedIds = await sl.roomRepository.getPlayedPackIds(roomId);
//         }
//       } catch (_) {}

//       if (mounted)
//         setState(() {
//           _packs = unique;
//           _cardLanguages = coverage;
//           _playedPackIds = playedIds;
//           _loadingPacks = false;
//         });
//     } catch (e) {
//       if (mounted) setState(() => _loadingPacks = false);
//     }
//   }

//   List<PackEntity> get _filteredPacks {
//     if (_langFilter == 'all') return _packs;
//     return _packs.where((p) {
//       // Title/metadata must claim the language...
//       final titleHasLang = p.titleJson.containsKey(_langFilter);
//       if (!titleHasLang) return false;

//       // ...and the actual cards must really have it too. If the coverage
//       // lookup didn't return anything for this pack (e.g. it failed, or
//       // the pack has zero cards), fall back to the metadata flags so a
//       // pack isn't hidden just because of a lookup hiccup.
//       final knownCoverage = _cardLanguages[p.id];
//       if (knownCoverage != null) {
//         return knownCoverage.contains(_langFilter);
//       }
//       if (p.availableLanguages.isNotEmpty) {
//         return p.availableLanguages.contains(_langFilter);
//       }
//       return p.language == _langFilter ||
//           p.language == 'multi' ||
//           p.isMultilang;
//     }).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     final l10n = context.l10n;

//     return Container(
//       decoration: BoxDecoration(
//         color: theme.colorScheme.surface,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       padding: EdgeInsets.fromLTRB(
//         24,
//         12,
//         24,
//         MediaQuery.viewInsetsOf(context).bottom + 24,
//       ),
//       child: Consumer<RoomProvider>(
//         builder: (_, room, __) {
//           final s = room.settings;
//           return SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Handle
//                 Center(
//                   child: Container(
//                     width: 36,
//                     height: 4,
//                     decoration: BoxDecoration(
//                       color: theme.colorScheme.outlineVariant,
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),

//                 Text(
//                   l10n.gameSettings,
//                   style: theme.textTheme.titleLarge?.copyWith(
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 const SizedBox(height: 20),

//                 // ── Language filter ──────────────────────────────────────────
//                 Text(
//                   'Language',
//                   style: theme.textTheme.labelLarge?.copyWith(
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: Row(
//                     children: _langs.map((lang) {
//                       final selected = _langFilter == lang.$1;
//                       return Padding(
//                         padding: const EdgeInsets.only(right: 8),
//                         child: ChoiceChip(
//                           label: Text(lang.$2),
//                           selected: selected,
//                           onSelected: (_) {
//                             setState(() => _langFilter = lang.$1);
//                             // "All" is a browse-only filter — only a real
//                             // language should be persisted as the game's
//                             // active language.
//                             if (lang.$1 != 'all') {
//                               room.setLanguage(lang.$1);
//                             }
//                           },
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                 ),
//                 const SizedBox(height: 20),

//                 // ── Pack picker ───────────────────────────────────────────────
//                 if (room.isOwner) ...[
//                   Text(
//                     'Select Pack',
//                     style: theme.textTheme.labelLarge?.copyWith(
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   if (_loadingPacks)
//                     const Padding(
//                       padding: EdgeInsets.symmetric(vertical: 16),
//                       child: Center(child: CircularProgressIndicator()),
//                     )
//                   else if (_packs.isEmpty)
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: theme.colorScheme.surfaceContainerHighest,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.info_outline,
//                             color: theme.colorScheme.onSurfaceVariant,
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Text(
//                               'No packs available. Run the seed SQL in Supabase.',
//                               style: theme.textTheme.bodySmall,
//                             ),
//                           ),
//                         ],
//                       ),
//                     )
//                   else
//                     SizedBox(
//                       height: 110,
//                       child: ListView.separated(
//                         scrollDirection: Axis.horizontal,
//                         itemCount: _filteredPacks.length,
//                         separatorBuilder: (_, __) => const SizedBox(width: 10),
//                         itemBuilder: (ctx, i) {
//                           final pack = _filteredPacks[i];
//                           final selected = room.room?.packId == pack.id;
//                           final alreadyUsed = _playedPackIds.contains(pack.id);
//                           return GestureDetector(
//                             onTap: alreadyUsed
//                                 ? null
//                                 : () => room.setPackId(pack.id),
//                             child: Opacity(
//                               opacity: alreadyUsed ? 0.45 : 1.0,
//                               child: AnimatedContainer(
//                                 duration: const Duration(milliseconds: 180),
//                                 width: 140,
//                                 padding: const EdgeInsets.all(12),
//                                 decoration: BoxDecoration(
//                                   color: selected
//                                       ? theme.colorScheme.primaryContainer
//                                       : theme
//                                             .colorScheme
//                                             .surfaceContainerHighest,
//                                   borderRadius: BorderRadius.circular(12),
//                                   border: Border.all(
//                                     color: selected
//                                         ? theme.colorScheme.primary
//                                         : alreadyUsed
//                                         ? Colors.grey.shade400
//                                         : Colors.transparent,
//                                     width: 2,
//                                   ),
//                                 ),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Row(
//                                       children: [
//                                         Text(
//                                           pack.coverEmoji,
//                                           style: const TextStyle(fontSize: 20),
//                                         ),
//                                         const Spacer(),
//                                         if (selected)
//                                           Icon(
//                                             Icons.check_circle_rounded,
//                                             color: theme.colorScheme.primary,
//                                             size: 18,
//                                           ),
//                                         if (alreadyUsed)
//                                           const Icon(
//                                             Icons.block_rounded,
//                                             color: Colors.grey,
//                                             size: 16,
//                                           ),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 6),
//                                     Text(
//                                       pack.titleJson['en'] as String? ??
//                                           pack.id,
//                                       style: theme.textTheme.labelMedium
//                                           ?.copyWith(
//                                             fontWeight: FontWeight.w600,
//                                           ),
//                                       maxLines: 2,
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Text(
//                                       '${pack.cardCount} cards',
//                                       style: theme.textTheme.labelSmall
//                                           ?.copyWith(
//                                             color: theme
//                                                 .colorScheme
//                                                 .onSurfaceVariant,
//                                           ),
//                                     ),
//                                     if (alreadyUsed)
//                                       Text(
//                                         'Already played',
//                                         style: theme.textTheme.labelSmall
//                                             ?.copyWith(
//                                               color: Colors.red.shade400,
//                                             ),
//                                       ),
//                                   ],
//                                 ),
//                               ), // AnimatedContainer
//                             ), // Opacity
//                           );
//                         },
//                       ),
//                     ),
//                   const SizedBox(height: 20),
//                 ],

//                 // ── Game settings ─────────────────────────────────────────────
//                 _SliderRow(
//                   label: l10n.gameSettingsTurnTimer,
//                   value: s.turnTimerSeconds.toDouble(),
//                   display: l10n.gameSettingsSeconds(s.turnTimerSeconds),
//                   min: 15,
//                   max: 120,
//                   divisions: 21,
//                   onChanged: (v) =>
//                       room.updateSetting('turn_timer_secs', v.round()),
//                 ),
//                 _SliderRow(
//                   label: l10n.gameSettingsMaxRounds,
//                   value: s.maxRounds.toDouble(),
//                   display: '${s.maxRounds}',
//                   min: 3,
//                   max: 30,
//                   divisions: 27,
//                   onChanged: (v) => room.updateSetting('max_rounds', v.round()),
//                 ),
//                 const SizedBox(height: 4),
//                 _SwitchRow(
//                   label: l10n.gameSettingsAllowSkip,
//                   icon: Icons.skip_next_rounded,
//                   value: s.allowSkip,
//                   onChanged: (v) => room.updateSetting('allow_skip', v),
//                 ),
//                 _SwitchRow(
//                   label: 'Chat',
//                   icon: Icons.chat_bubble_outline_rounded,
//                   value: s.chatEnabled,
//                   onChanged: (v) => room.updateSetting('chat_enabled', v),
//                 ),
//                 _SwitchRow(
//                   label: l10n.gameSettingsAllowSpectators,
//                   icon: Icons.visibility_outlined,
//                   value: s.allowSpectators,
//                   onChanged: (v) => room.updateSetting('allow_spectators', v),
//                 ),
//                 // Approval gate only makes sense when spectators are enabled
//                 if (s.allowSpectators)
//                   _SwitchRow(
//                     label: 'Require approval to spectate',
//                     icon: Icons.how_to_reg_outlined,
//                     value: s.spectatorApprovalRequired,
//                     onChanged: (v) =>
//                         room.updateSetting('spectator_approval_required', v),
//                   ),
//                 _SwitchRow(
//                   label: l10n.gameSettingsSpicy,
//                   icon: Icons.local_fire_department_outlined,
//                   value: s.allowSpicy,
//                   onChanged: (v) => room.updateSetting('allow_spicy', v),
//                 ),
//                 _SwitchRow(
//                   label: l10n.gameSettingsRequireApproval,
//                   icon: Icons.lock_outline_rounded,
//                   value: s.requiresApproval,
//                   onChanged: (v) => room.updateSetting('requires_approval', v),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// // ── Helpers ───────────────────────────────────────────────────────────────────

// extension _PackX on PackEntity {
//   String get coverEmoji {
//     if (titleJson['en']?.toString().toLowerCase().contains('arabic') == true)
//       return '🌙';
//     if (titleJson['en']?.toString().toLowerCase().contains('party') == true)
//       return '🎉';
//     return '🎮';
//   }
// }

// class _SliderRow extends StatelessWidget {
//   const _SliderRow({
//     required this.label,
//     required this.value,
//     required this.display,
//     required this.min,
//     required this.max,
//     required this.divisions,
//     required this.onChanged,
//   });
//   final String label;
//   final double value;
//   final String display;
//   final double min, max;
//   final int divisions;
//   final void Function(double) onChanged;

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
//           Text(
//             display,
//             style: theme.textTheme.labelMedium?.copyWith(
//               color: theme.colorScheme.primary,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(width: 8),
//           SizedBox(
//             width: 120,
//             child: Slider(
//               value: value.clamp(min, max),
//               min: min,
//               max: max,
//               divisions: divisions,
//               onChanged: onChanged,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _SwitchRow extends StatelessWidget {
//   const _SwitchRow({
//     required this.label,
//     required this.icon,
//     required this.value,
//     required this.onChanged,
//   });
//   final String label;
//   final IconData icon;
//   final bool value;
//   final void Function(bool)? onChanged;

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2),
//       child: Row(
//         children: [
//           Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
//           const SizedBox(width: 12),
//           Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
//           Switch(value: value, onChanged: onChanged),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../games/engine/base_game_engine.dart';
import '../../../packs/data/pack_repository.dart';
import '../../../packs/domain/pack_entity.dart';
import '../../../packs/presentation/pack_provider.dart';
import '../room_provider.dart';

class GameSettingsSheet extends StatefulWidget {
  const GameSettingsSheet({super.key, this.scrollController});

  /// Shares scroll position with an enclosing DraggableScrollableSheet so
  /// dragging the sheet handle and scrolling the content are the same
  /// gesture instead of two competing ones.
  final ScrollController? scrollController;

  @override
  State<GameSettingsSheet> createState() => _GameSettingsSheetState();
}

class _GameSettingsSheetState extends State<GameSettingsSheet> {
  List<PackEntity> _packs = [];
  bool _loadingPacks = true;
  String _langFilter = 'en';
  Set<String> _playedPackIds = {}; // packs already used in this room

  // packId → languages every active card actually has content for.
  // Populated alongside _packs in _loadPacks(); used so the filter below
  // can't be fooled by a pack whose metadata claims a language but whose
  // cards were never actually translated.
  Map<String, Set<String>> _cardLanguages = {};

  // Small display-only lookup, not a source of truth — the actual list of
  // *available* languages always comes from the pack_languages table via
  // _loadLanguages(). A code with no entry here just falls back to a
  // generic flag emoji, it's never excluded from the list.
  static const _flagEmoji = {
    'en': '🇬🇧',
    'ar': '🇸🇦',
    'fr': '🇫🇷',
    'es': '🇪🇸',
    'de': '🇩🇪',
    'pt': '🇵🇹',
    'tr': '🇹🇷',
    'ru': '🇷🇺',
  };

  List<(String, String)> _langs = [];

  @override
  void initState() {
    super.initState();
    // Reflect the room's actual language so the sheet shows the real
    // current state.
    _langFilter = context.read<RoomProvider>().room?.language ?? 'en';
    _loadPacks();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    try {
      final langs = await PackRepository.instance.getAvailableLanguages();
      if (!mounted) return;
      setState(() {
        _langs = [
          for (final l in langs)
            (
              l.code,
              '${_flagEmoji[l.code] ?? '🏳️'} ${l.code.toUpperCase()}',
            ),
        ];
      });
    } catch (_) {
      // Fall back to just the room's own current language — never block
      // the sheet on this, and never silently hardcode a fixed set.
      if (mounted) {
        setState(() => _langs = [(_langFilter, _langFilter.toUpperCase())]);
      }
    }
  }

  Future<void> _loadPacks() async {
    try {
      final packProvider = context.read<PackProvider>();
      final owned = [
        ...packProvider.purchasedPacks,
        ...packProvider.localPacks,
        ...packProvider.browsePacks.where((p) => p.isFree),
      ];
      final seen = <String>{};
      final unique = owned.where((p) => seen.add(p.id)).toList();

      // Best-effort: if this lookup fails for any reason, fall back to
      // trusting pack metadata alone rather than blocking the picker.
      var coverage = <String, Set<String>>{};
      try {
        coverage = await PackRepository.instance.getCardLanguageCoverage(
          unique.map((p) => p.id).toList(),
        );
      } catch (_) {}

      // Load which packs have already been played in this room so we
      // can grey them out in the picker (can't reuse a pack per room).
      var playedIds = <String>{};
      try {
        final roomId = context.read<RoomProvider>().room?.id;
        if (roomId != null) {
          playedIds = await sl.roomRepository.getPlayedPackIds(roomId);
        }
      } catch (_) {}

      if (mounted)
        setState(() {
          _packs = unique;
          _cardLanguages = coverage;
          _playedPackIds = playedIds;
          _loadingPacks = false;
        });
    } catch (e) {
      if (mounted) setState(() => _loadingPacks = false);
    }
  }

  List<PackEntity> get _filteredPacks {
    return _packs.where((p) {
      // Title/metadata must claim the language...
      final titleHasLang = p.titleJson.containsKey(_langFilter);
      if (!titleHasLang) return false;

      // ...and the actual cards must really have it too. If the coverage
      // lookup didn't return anything for this pack (e.g. it failed, or
      // the pack has zero cards), fall back to the metadata flags so a
      // pack isn't hidden just because of a lookup hiccup.
      final knownCoverage = _cardLanguages[p.id];
      if (knownCoverage != null) {
        return knownCoverage.contains(_langFilter);
      }
      if (p.availableLanguages.isNotEmpty) {
        return p.availableLanguages.contains(_langFilter);
      }
      return p.language == _langFilter ||
          p.language == 'multi' ||
          p.isMultilang;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Consumer<RoomProvider>(
        builder: (_, room, __) {
          final s = room.settings;
          return SingleChildScrollView(
            controller: widget.scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  l10n.gameSettings,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Language filter ──────────────────────────────────────────
                Text(
                  'Language',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _langs.map((lang) {
                      final selected = _langFilter == lang.$1;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(lang.$2),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _langFilter = lang.$1);
                            room.setLanguage(lang.$1);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Pack picker ───────────────────────────────────────────────
                if (room.isOwner) ...[
                  Text(
                    'Select Pack',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_loadingPacks)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_packs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No packs available. Run the seed SQL in Supabase.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Builder(
                      builder: (_) {
                        // A pack already played in this room is removed
                        // from selection entirely, immediately at game
                        // start — no exemption for the room's current
                        // session pack. Never wait for another pack to be
                        // selected before this one disappears.
                        final visiblePacks = _filteredPacks
                            .where((p) => !_playedPackIds.contains(p.id))
                            .toList();
                        return SizedBox(
                          height: 110,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: visiblePacks.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (ctx, i) {
                              final pack = visiblePacks[i];
                              final selected = room.room?.packId == pack.id;
                              return GestureDetector(
                                onTap: () => room.setPackId(pack.id),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 140,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? theme.colorScheme.primaryContainer
                                        : theme
                                              .colorScheme
                                              .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected
                                          ? theme.colorScheme.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            pack.coverEmoji,
                                            style: const TextStyle(
                                              fontSize: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Tooltip(
                                            message: switch (
                                                pack.genderRestriction) {
                                              'male' => 'Male only',
                                              'female' => 'Female only',
                                              _ => 'Everyone',
                                            },
                                            child: Text(
                                              switch (pack.genderRestriction) {
                                                'male' => '👨',
                                                'female' => '👩',
                                                _ => '👥',
                                              },
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          if (selected)
                                            Icon(
                                              Icons.check_circle_rounded,
                                              color: theme.colorScheme.primary,
                                              size: 18,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        pack.titleJson['en'] as String? ??
                                            pack.id,
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${pack.cardCount} cards',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 20),
                ],

                // ── Game settings ─────────────────────────────────────────────
                _SliderRow(
                  label: l10n.gameSettingsTurnTimer,
                  value: s.turnTimerSeconds.toDouble(),
                  display: l10n.gameSettingsSeconds(s.turnTimerSeconds),
                  min: 15,
                  max: 120,
                  divisions: 21,
                  onChanged: (v) =>
                      room.updateSetting('turn_timer_secs', v.round()),
                ),
                _SliderRow(
                  label: l10n.gameSettingsMaxRounds,
                  value: s.maxRounds.toDouble(),
                  display: '${s.maxRounds}',
                  min: 3,
                  max: 30,
                  divisions: 27,
                  onChanged: (v) => room.updateSetting('max_rounds', v.round()),
                ),
                const SizedBox(height: 4),
                _SwitchRow(
                  label: l10n.gameSettingsAllowSkip,
                  icon: Icons.skip_next_rounded,
                  value: s.allowSkip,
                  onChanged: (v) => room.updateSetting('allow_skip', v),
                ),
                _SwitchRow(
                  label: 'Chat',
                  icon: Icons.chat_bubble_outline_rounded,
                  value: s.chatEnabled,
                  onChanged: (v) => room.updateSetting('chat_enabled', v),
                ),
                _SwitchRow(
                  label: l10n.gameSettingsAllowSpectators,
                  icon: Icons.visibility_outlined,
                  value: s.allowSpectators,
                  onChanged: (v) => room.updateSetting('allow_spectators', v),
                ),
                // Approval gate only makes sense when spectators are enabled
                if (s.allowSpectators)
                  _SwitchRow(
                    label: 'Require approval to spectate',
                    icon: Icons.how_to_reg_outlined,
                    value: s.spectatorApprovalRequired,
                    onChanged: (v) =>
                        room.updateSetting('spectator_approval_required', v),
                  ),
                _SwitchRow(
                  label: l10n.gameSettingsSpicy,
                  icon: Icons.local_fire_department_outlined,
                  value: s.allowSpicy,
                  onChanged: (v) => room.updateSetting('allow_spicy', v),
                ),
                _SwitchRow(
                  label: l10n.gameSettingsRequireApproval,
                  icon: Icons.lock_outline_rounded,
                  value: s.requiresApproval,
                  onChanged: (v) => room.updateSetting('requires_approval', v),
                ),

                // ── Truth or Dare — punishment + proof settings ─────────
                if (room.room?.gameType == GameType.truthOrDare) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 4),
                  Text(
                    'Truth or Dare',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _SwitchRow(
                    label: 'Punishment mode',
                    icon: Icons.gavel_rounded,
                    value: s.enablePunishments,
                    onChanged: (v) =>
                        room.updateSetting('enable_punishments', v),
                  ),
                  if (s.enablePunishments) ...[
                    Builder(
                      builder: (context) {
                        final selectedPack = _packs
                            .where((p) => p.id == room.room?.packId)
                            .firstOrNull;
                        final hasPackPunishments =
                            (selectedPack?.suggestedPunishments.length ??
                                0) >=
                            10;
                        // Only offer the pack-sourced mode when the
                        // selected pack actually has a valid (>=10)
                        // authored list — otherwise silently behave as
                        // 'players', same as before this feature existed.
                        if (!hasPackPunishments) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              left: 32,
                              right: 8,
                              bottom: 8,
                            ),
                            child: Text(
                              'When a player skips, every other player '
                              'submits a punishment and the skipped player '
                              'picks one to do.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(
                            left: 32,
                            right: 8,
                            bottom: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'This pack includes its own punishments. '
                                'Choose who provides them when a player '
                                'skips.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'pack',
                                    label: Text('Pack punishments'),
                                  ),
                                  ButtonSegment(
                                    value: 'players',
                                    label: Text('Players submit'),
                                  ),
                                ],
                                selected: {s.punishmentSource},
                                onSelectionChanged: (v) => room.updateSetting(
                                  'punishment_source',
                                  v.first,
                                ),
                                style: const ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Proof visibility',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'everyone',
                        label: Text('Everyone'),
                      ),
                      ButtonSegment(
                        value: 'players_only',
                        label: Text('Players'),
                      ),
                      ButtonSegment(
                        value: 'spectators_only',
                        label: Text('Spectators'),
                      ),
                      ButtonSegment(
                        value: 'selected',
                        label: Text('Custom'),
                      ),
                    ],
                    selected: {s.proofVisibilityPolicy},
                    onSelectionChanged: (v) => room.updateSetting(
                      'proof_visibility_policy',
                      v.first,
                    ),
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  if (s.proofVisibilityPolicy == 'selected') ...[
                    const SizedBox(height: 8),
                    Text(
                      'Choose exactly who can see proof',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: room.members.map((m) {
                        final selected = s.proofVisibilitySelectedUserIds
                            .contains(m.userId);
                        return FilterChip(
                          label: Text(
                            '${m.displayName}${m.isSpectator ? ' (spec)' : ''}',
                          ),
                          selected: selected,
                          onSelected: (on) {
                            final ids = [
                              ...s.proofVisibilitySelectedUserIds,
                            ];
                            if (on) {
                              if (!ids.contains(m.userId)) ids.add(m.userId);
                            } else {
                              ids.remove(m.userId);
                            }
                            room.updateSetting(
                              'proof_visibility_selected_user_ids',
                              ids,
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _SwitchRow(
                    label: 'Unlimited duration (until next round)',
                    icon: Icons.all_inclusive_rounded,
                    value: s.proofViewSeconds == 0,
                    onChanged: (v) => room.updateSetting(
                      'proof_view_seconds',
                      v ? 0 : 5,
                    ),
                  ),
                  if (s.proofViewSeconds != 0)
                    _SliderRow(
                      label: 'Proof view duration (auto-closes after this)',
                      value: s.proofViewSeconds.toDouble(),
                      display: '${s.proofViewSeconds}s',
                      min: 2,
                      max: 30,
                      divisions: 28,
                      onChanged: (v) {
                        room.updateSetting('proof_view_seconds', v.round());
                        // A finite duration means the proof auto-closes —
                        // that's the 'timed' mode; the separate "allow
                        // replay" toggle below only applies once duration
                        // is set back to Unlimited.
                        room.updateSetting('proof_replay_mode', 'timed');
                      },
                    ),
                  if (s.proofViewSeconds == 0)
                    _SwitchRow(
                      label: 'Allow one replay',
                      icon: Icons.replay_rounded,
                      value: s.proofReplayMode == 'replay_once',
                      onChanged: (v) => room.updateSetting(
                        'proof_replay_mode',
                        v ? 'replay_once' : 'once',
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(left: 32, right: 8),
                    child: Text(
                      s.proofViewSeconds == 0
                          ? 'Premium viewers get one extra replay beyond this.'
                          : 'Proof auto-closes after ${s.proofViewSeconds}s — no replay while a duration is set.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

extension _PackX on PackEntity {
  String get coverEmoji {
    if (titleJson['en']?.toString().toLowerCase().contains('arabic') == true)
      return '🌙';
    if (titleJson['en']?.toString().toLowerCase().contains('party') == true)
      return '🎉';
    return '🎮';
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.display,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });
  final String label;
  final double value;
  final String display;
  final double min, max;
  final int divisions;
  final void Function(double) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            display,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final IconData icon;
  final bool value;
  final void Function(bool)? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
