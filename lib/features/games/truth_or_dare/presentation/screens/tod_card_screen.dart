// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:image_picker/image_picker.dart';

// import '../../../../../core/extensions/context_ext.dart';
// import '../../../../../core/theme/app_colors.dart';
// import '../../../../../shared/widgets/buttons/j_button.dart';
// import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
// import '../../domain/tod_models.dart';
// import '../../tod_game_provider.dart';
// import '../widgets/tod_player_banner.dart';
// import '../widgets/tod_timer_ring.dart';
// import '../widgets/tod_waiting_overlay.dart';

// /// Routes to the correct sub-view based on TodTurnPhase.
// class TodCardScreen extends StatelessWidget {
//   const TodCardScreen({
//     super.key,
//     required this.state,
//     required this.game,
//     required this.displayNames,
//   });

//   final TodState state;
//   final TodGameProvider game;
//   final Map<String, String> displayNames;

//   @override
//   Widget build(BuildContext context) {
//     return switch (state.phase) {
//       TodTurnPhase.choosingType => _ChoiceView(
//         state: state,
//         game: game,
//         displayNames: displayNames,
//       ),
//       TodTurnPhase.readingCard => _CardView(
//         state: state,
//         game: game,
//         displayNames: displayNames,
//       ),
//       TodTurnPhase.awaitingNextTurn => _AwaitingView(
//         state: state,
//         game: game,
//         displayNames: displayNames,
//       ),
//       TodTurnPhase.awaitingResult => _CardView(
//         state: state,
//         game: game,
//         displayNames: displayNames,
//       ),
//       _ => _ChoiceView(state: state, game: game, displayNames: displayNames),
//     };
//   }
// }

// // ── 1. Choice view ─────────────────────────────────────────────────────────────
// class _ChoiceView extends StatelessWidget {
//   const _ChoiceView({
//     required this.state,
//     required this.game,
//     required this.displayNames,
//   });
//   final TodState state;
//   final TodGameProvider game;
//   final Map<String, String> displayNames;

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     final isMyTurn = game.isMyTurn;
//     final playerName =
//         displayNames[state.currentPlayerId] ??
//         'Player ${state.currentPlayerId.substring(0, 4)}';

//     return Stack(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             children: [
//               TodPlayerBanner(
//                 playerId: state.currentPlayerId,
//                 playerName: playerName,
//                 playerOrder: state.playerOrder,
//                 isMyTurn: isMyTurn,
//               ),

//               const Spacer(),

//               Text(
//                 isMyTurn ? 'Choose your challenge' : '$playerName is choosing…',
//                 style: theme.textTheme.headlineSmall?.copyWith(
//                   fontWeight: FontWeight.w700,
//                 ),
//                 textAlign: TextAlign.center,
//               ).animate().fadeIn().slideY(begin: 0.08, end: 0),

//               const SizedBox(height: 40),

//               if (isMyTurn) ...[
//                 _ChoiceButton(
//                   label: 'Truth',
//                   emoji: '🤔',
//                   color: AppColors.truthColor,
//                   description: 'Answer a personal question honestly.',
//                   onTap: game.chooseTruth,
//                 ).animate(delay: 80.ms).fadeIn().slideX(begin: -0.08, end: 0),

//                 const SizedBox(height: 16),

//                 _ChoiceButton(
//                   label: 'Dare',
//                   emoji: '🔥',
//                   color: AppColors.dareColor,
//                   description: 'Complete a daring challenge.',
//                   onTap: game.chooseDare,
//                 ).animate(delay: 140.ms).fadeIn().slideX(begin: 0.08, end: 0),
//               ] else
//                 _ChoiceWaiting(playerName: playerName),

//               const Spacer(),
//             ],
//           ),
//         ),

//         if (!isMyTurn) const TodWaitingOverlay(),
//       ],
//     );
//   }
// }

// class _ChoiceWaiting extends StatelessWidget {
//   const _ChoiceWaiting({required this.playerName});
//   final String playerName;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         const SizedBox(
//           width: 48,
//           height: 48,
//           child: CircularProgressIndicator(strokeWidth: 3),
//         ),
//         const SizedBox(height: 16),
//         Text(
//           'Waiting for $playerName to decide…',
//           style: context.textTheme.bodyMedium?.copyWith(
//             color: context.colorScheme.onSurfaceVariant,
//           ),
//           textAlign: TextAlign.center,
//         ),
//       ],
//     );
//   }
// }

// class _ChoiceButton extends StatelessWidget {
//   const _ChoiceButton({
//     required this.label,
//     required this.emoji,
//     required this.color,
//     required this.description,
//     required this.onTap,
//   });

//   final String label;
//   final String emoji;
//   final Color color;
//   final String description;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(24),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [color, color.withOpacity(0.8)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: color.withOpacity(0.3),
//               blurRadius: 16,
//               offset: const Offset(0, 6),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             Text(emoji, style: const TextStyle(fontSize: 40)),
//             const SizedBox(width: 20),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     label,
//                     style: const TextStyle(
//                       fontSize: 26,
//                       fontWeight: FontWeight.w800,
//                       color: Colors.white,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     description,
//                     style: TextStyle(
//                       fontSize: 13,
//                       color: Colors.white.withOpacity(0.85),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const Icon(
//               Icons.chevron_right_rounded,
//               color: Colors.white,
//               size: 28,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── 2. Card reading view ───────────────────────────────────────────────────────
// class _CardView extends StatelessWidget {
//   const _CardView({
//     required this.state,
//     required this.game,
//     required this.displayNames,
//   });
//   final TodState state;
//   final TodGameProvider game;
//   final Map<String, String> displayNames;

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     final card = state.currentCard;
//     final isMyTurn = game.isMyTurn;

//     if (card == null) {
//       return const Center(child: Text('No card available — all cards used!'));
//     }

//     final isSpicy = card.difficulty == TodDifficulty.spicy;
//     final isTruth = card.type == TodCardType.truth;
//     final cardColor = isTruth ? AppColors.truthColor : AppColors.dareColor;
//     final playerName =
//         displayNames[state.currentPlayerId] ??
//         'Player ${state.currentPlayerId.substring(0, 4)}';

//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         children: [
//           TodPlayerBanner(
//             playerId: state.currentPlayerId,
//             playerName: playerName,
//             playerOrder: state.playerOrder,
//             isMyTurn: isMyTurn,
//           ),

//           const SizedBox(height: 12),

//           // Timer ring — only when active
//           if (game.timerIsRunning || game.timerRemaining > 0)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 12),
//               child: TodTimerRing(
//                 remaining: game.timerRemaining,
//                 total: game.state != null
//                     ? (80) // default; actual from config
//                     : 60,
//                 color: cardColor,
//               ).animate().fadeIn(),
//             ),

//           // Card face
//           Expanded(
//             child: _CardFace(
//               card: card,
//               cardColor: cardColor,
//               isSpicy: isSpicy,
//               isTruth: isTruth,
//             ),
//           ),

//           const SizedBox(height: 20),

//           // Action buttons
//           if (isMyTurn) ...[
//             JButton(
//               label: 'Done! ✅',
//               onPressed: () =>
//                   _showCompleteSheet(context, game, isTruth: isTruth),
//             ),
//             const SizedBox(height: 10),
//             TextButton(
//               onPressed: () => _confirmSkip(context),
//               child: Text(
//                 'Skip',
//                 style: TextStyle(
//                   color: theme.colorScheme.onSurfaceVariant,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ] else
//             Text(
//               '$playerName is performing…',
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 color: theme.colorScheme.onSurfaceVariant,
//               ),
//             ),

//           // Moderator override row
//           if (game.canModerate && !isMyTurn)
//             Padding(
//               padding: const EdgeInsets.only(top: 6),
//               child: TextButton.icon(
//                 onPressed: game.ownerAdvanceTurn,
//                 icon: const Icon(Icons.skip_next_rounded, size: 16),
//                 label: const Text('Skip turn (mod)'),
//                 style: TextButton.styleFrom(
//                   foregroundColor: AppColors.warningAmber,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   void _showCompleteSheet(
//     BuildContext context,
//     TodGameProvider game, {
//     bool isTruth = false,
//   }) {
//     final ctrl = TextEditingController();
//     String? imgB64;
//     bool _attempted = false;

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (ctx) => StatefulBuilder(
//         builder: (ctx, setS) {
//           return Padding(
//             padding: EdgeInsets.only(
//               bottom: MediaQuery.of(ctx).viewInsets.bottom,
//             ),
//             child: Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Theme.of(ctx).colorScheme.surface,
//                 borderRadius: const BorderRadius.vertical(
//                   top: Radius.circular(20),
//                 ),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 36,
//                       height: 4,
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade300,
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     children: [
//                       Text(
//                         isTruth ? '🤔 Truth' : '🔥 Dare',
//                         style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
//                           color: isTruth
//                               ? AppColors.truthColor
//                               : AppColors.dareColor,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         'Complete Turn',
//                         style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   // Truth: response required. Dare: response optional.
//                   TextField(
//                     controller: ctrl,
//                     maxLines: 3,
//                     maxLength: 300,
//                     decoration: InputDecoration(
//                       hintText: isTruth
//                           ? 'Your answer is required…'
//                           : 'Add a description (optional)…',
//                       border: const OutlineInputBorder(),
//                       errorText:
//                           isTruth && ctrl.text.trim().isEmpty && _attempted
//                           ? 'Truth requires a response'
//                           : null,
//                     ),
//                     onChanged: (_) => setS(() {}),
//                   ),
//                   const SizedBox(height: 8),
//                   // Proof image — Dares only
//                   if (!isTruth) ...[
//                     if (imgB64 != null)
//                       Stack(
//                         children: [
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(8),
//                             child: Image.memory(
//                               base64Decode(imgB64!),
//                               height: 120,
//                               width: double.infinity,
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                           Positioned(
//                             top: 4,
//                             right: 4,
//                             child: GestureDetector(
//                               onTap: () => setS(() => imgB64 = null),
//                               child: const CircleAvatar(
//                                 radius: 12,
//                                 backgroundColor: Colors.black54,
//                                 child: Icon(
//                                   Icons.close,
//                                   size: 14,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       )
//                     else
//                       OutlinedButton.icon(
//                         onPressed: () async {
//                           try {
//                             final picked = await ImagePicker().pickImage(
//                               source: ImageSource.gallery,
//                               imageQuality: 40,
//                             );
//                             if (picked != null) {
//                               final bytes = await picked.readAsBytes();
//                               setS(() => imgB64 = base64Encode(bytes));
//                             }
//                           } catch (_) {}
//                         },
//                         icon: const Icon(Icons.add_photo_alternate_outlined),
//                         label: const Text('Add proof photo (view once)'),
//                       ),
//                     const SizedBox(height: 8),
//                   ],
//                   const SizedBox(height: 8),
//                   FilledButton(
//                     onPressed: () {
//                       // Truth: enforce non-empty response
//                       if (isTruth && ctrl.text.trim().isEmpty) {
//                         setS(() => _attempted = true);
//                         return;
//                       }
//                       Navigator.of(ctx).pop();
//                       game.completeTurn(
//                         response: ctrl.text.trim(),
//                         proofImageB64: imgB64 ?? '',
//                       );
//                     },
//                     child: const Text('Submit & Complete Turn ✅'),
//                   ),
//                   const SizedBox(height: 4),
//                   TextButton(
//                     onPressed: () => Navigator.of(ctx).pop(),
//                     child: const Text('Cancel'),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Future<void> _confirmSkip(BuildContext context) async {
//     final confirmed = await showConfirmDialog(
//       context: context,
//       title: 'Skip this card?',
//       message: 'Skipping may result in a group punishment vote.',
//       confirmLabel: 'Skip',
//     );
//     if (confirmed == true) game.skipTurn();
//   }
// }

// class _CardFace extends StatelessWidget {
//   const _CardFace({
//     required this.card,
//     required this.cardColor,
//     required this.isSpicy,
//     required this.isTruth,
//   });

//   final TodCard card;
//   final Color cardColor;
//   final bool isSpicy;
//   final bool isTruth;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(28),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [cardColor, cardColor.withOpacity(0.78)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [
//           BoxShadow(
//             color: cardColor.withOpacity(0.28),
//             blurRadius: 24,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Type + difficulty badges
//           Row(
//             children: [
//               _TypeBadge(label: isTruth ? '🤔  TRUTH' : '🔥  DARE'),
//               if (isSpicy) ...[const SizedBox(width: 8), _SpicyBadge()],
//             ],
//           ),
//           const Spacer(),
//           Text(
//             card.content,
//             style: const TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.w700,
//               color: Colors.white,
//               height: 1.45,
//             ),
//           ).animate().fadeIn(duration: 350.ms),
//           const Spacer(),
//         ],
//       ),
//     ).animate().scale(
//       begin: const Offset(0.92, 0.92),
//       end: const Offset(1, 1),
//       duration: 320.ms,
//       curve: Curves.easeOutBack,
//     );
//   }
// }

// class _TypeBadge extends StatelessWidget {
//   const _TypeBadge({required this.label});
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.2),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(
//         label,
//         style: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.w800,
//           fontSize: 13,
//           letterSpacing: 1,
//         ),
//       ),
//     );
//   }
// }

// class _SpicyBadge extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: AppColors.spicyColor.withOpacity(0.8),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: const Text(
//         '🌶 SPICY',
//         style: TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.w700,
//           fontSize: 12,
//         ),
//       ),
//     );
//   }
// }

// // ── 3. Awaiting next turn ──────────────────────────────────────────────────────
// class _AwaitingView extends StatelessWidget {
//   const _AwaitingView({
//     required this.state,
//     required this.game,
//     required this.displayNames,
//   });
//   final TodState state;
//   final TodGameProvider game;
//   final Map<String, String> displayNames;

//   Future<void> _confirmEndGame(BuildContext context) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('End Game?'),
//         content: const Text('This will end the game for all players.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           FilledButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
//             child: const Text('End Game'),
//           ),
//         ],
//       ),
//     );
//     if (confirmed == true) game.endGame();
//   }

//   String _name(String id) =>
//       displayNames[id] ?? id.substring(0, id.length.clamp(0, 6));

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     final myReacted = state.currentReactions.any(
//       (r) => r.userId == game.currentUserId,
//     );
//     final myVoted = state.currentVotes.any(
//       (v) => v.voterId == game.currentUserId,
//     );
//     final isMyTurn = state.currentPlayerId == game.currentUserId;

//     // Group reactions
//     final reactTally = <String, int>{};
//     for (final r in state.currentReactions) {
//       reactTally[r.emoji] = (reactTally[r.emoji] ?? 0) + 1;
//     }

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // ── Turn complete card ───────────────────────────────────────────────
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: theme.colorScheme.surfaceContainerHighest,
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Column(
//               children: [
//                 const Text('🎉', style: TextStyle(fontSize: 44)),
//                 const SizedBox(height: 8),
//                 Text(
//                   _name(state.currentPlayerId),
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 Text(
//                   'completed their turn!',
//                   style: theme.textTheme.bodySmall?.copyWith(
//                     color: theme.colorScheme.onSurfaceVariant,
//                   ),
//                 ),
//                 if (state.currentCard != null) ...[
//                   const SizedBox(height: 10),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 8,
//                     ),
//                     decoration: BoxDecoration(
//                       color: state.currentCard!.type == TodCardType.truth
//                           ? Colors.blue.withOpacity(0.1)
//                           : Colors.orange.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(
//                       state.currentCard!.content,
//                       textAlign: TextAlign.center,
//                       style: theme.textTheme.bodyMedium?.copyWith(
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ],
//                 // Response message
//                 if (state.turnResponse.isNotEmpty) ...[
//                   const SizedBox(height: 12),
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: theme.colorScheme.primaryContainer.withOpacity(
//                         0.4,
//                       ),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       '"${state.turnResponse}"',
//                       textAlign: TextAlign.center,
//                       style: theme.textTheme.bodyMedium?.copyWith(
//                         fontStyle: FontStyle.italic,
//                       ),
//                     ),
//                   ),
//                 ],
//                 // Proof image (view-once)
//                 if (state.turnProofImageB64.isNotEmpty) ...[
//                   const SizedBox(height: 12),
//                   _ViewOnceImage(b64: state.turnProofImageB64),
//                 ],
//               ],
//             ),
//           ).animate().fadeIn(),
//           const SizedBox(height: 16),

//           // ── Reactions ────────────────────────────────────────────────────────
//           if (reactTally.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 8),
//               child: Wrap(
//                 spacing: 8,
//                 runSpacing: 6,
//                 children: reactTally.entries
//                     .map(
//                       (e) => Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 10,
//                           vertical: 5,
//                         ),
//                         decoration: BoxDecoration(
//                           color: theme.colorScheme.surfaceContainerHighest,
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Text(
//                           '${e.key} ${e.value}',
//                           style: const TextStyle(fontSize: 14),
//                         ),
//                       ),
//                     )
//                     .toList(),
//               ),
//             ),
//           // Emoji picker
//           if (!myReacted && !isMyTurn) ...[
//             Text('React:', style: theme.textTheme.labelSmall),
//             const SizedBox(height: 4),
//             SizedBox(
//               height: 44,
//               child: ListView(
//                 scrollDirection: Axis.horizontal,
//                 children:
//                     [
//                           '😂',
//                           '🔥',
//                           '💀',
//                           '👏',
//                           '🤣',
//                           '😭',
//                           '🫡',
//                           '💯',
//                           '🤯',
//                           '👑',
//                           '😤',
//                           '🥹',
//                         ]
//                         .map(
//                           (s) => Padding(
//                             padding: const EdgeInsets.only(right: 6),
//                             child: InkWell(
//                               borderRadius: BorderRadius.circular(8),
//                               onTap: () => game.reactToResponse(s),
//                               child: Container(
//                                 width: 40,
//                                 height: 40,
//                                 alignment: Alignment.center,
//                                 decoration: BoxDecoration(
//                                   color:
//                                       theme.colorScheme.surfaceContainerHighest,
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 child: Text(
//                                   s,
//                                   style: const TextStyle(fontSize: 20),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         )
//                         .toList(),
//               ),
//             ),
//             const SizedBox(height: 8),
//           ],

//           // ── Vote for response ────────────────────────────────────────────────
//           if (!isMyTurn && state.turnResponse.isNotEmpty) ...[
//             if (!myVoted)
//               OutlinedButton.icon(
//                 onPressed: game.voteForResponse,
//                 icon: const Icon(Icons.thumb_up_outlined, size: 16),
//                 label: Text(
//                   '👍 Liked this response '
//                   '(${state.currentVotes.length} vote${state.currentVotes.length != 1 ? 's' : ''})',
//                 ),
//               )
//             else
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 8,
//                 ),
//                 decoration: BoxDecoration(
//                   color: AppColors.successGreen.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(
//                   '✓ You voted for this response '
//                   '(${state.currentVotes.length} total)',
//                   style: theme.textTheme.bodySmall?.copyWith(
//                     color: AppColors.successGreen,
//                   ),
//                 ),
//               ),
//             const SizedBox(height: 12),
//           ],

//           // ── Scores ───────────────────────────────────────────────────────────
//           _ScoreSummary(state: state, displayNames: displayNames),
//           const SizedBox(height: 20),

//           // ── Next turn controls ───────────────────────────────────────────────
//           if (game.isOwner) ...[
//             JButton(
//               label: 'Next Turn →',
//               onPressed: game.ownerAdvanceTurn,
//               icon: Icons.skip_next_rounded,
//             ).animate(delay: 250.ms).fadeIn(),
//             const SizedBox(height: 10),
//             TextButton(
//               onPressed: () => _confirmEndGame(context),
//               child: const Text('End Game'),
//               style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
//             ),
//           ] else
//             Text(
//               'Waiting for host to start next turn…',
//               textAlign: TextAlign.center,
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 color: theme.colorScheme.onSurfaceVariant,
//               ),
//             ).animate().fadeIn(),
//         ],
//       ),
//     );
//   }
// }

// class _ScoreSummary extends StatelessWidget {
//   const _ScoreSummary({required this.state, required this.displayNames});
//   final TodState state;
//   final Map<String, String> displayNames;

//   @override
//   Widget build(BuildContext context) {
//     final top = state.sortedScores.take(3).toList();
//     if (top.isEmpty) return const SizedBox.shrink();

//     return Column(
//       children: top.asMap().entries.map((e) {
//         final rank = e.key;
//         final score = e.value;
//         final medal = ['🥇', '🥈', '🥉'][rank.clamp(0, 2)];
//         final name =
//             displayNames[score.userId] ??
//             'Player ${score.userId.substring(0, 4)}';
//         return Padding(
//           padding: const EdgeInsets.symmetric(vertical: 2),
//           child: Row(
//             children: [
//               Text(medal, style: const TextStyle(fontSize: 16)),
//               const SizedBox(width: 8),
//               Expanded(child: Text(name, style: context.textTheme.bodyMedium)),
//               Text(
//                 '${score.points} pts',
//                 style: context.textTheme.titleSmall?.copyWith(
//                   fontWeight: FontWeight.w700,
//                   color: context.colorScheme.primary,
//                 ),
//               ),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }
// }

// // ── View-once proof image ─────────────────────────────────────────────────────

// class _ViewOnceImage extends StatefulWidget {
//   const _ViewOnceImage({required this.b64});
//   final String b64;
//   @override
//   State<_ViewOnceImage> createState() => _ViewOnceImageState();
// }

// class _ViewOnceImageState extends State<_ViewOnceImage> {
//   bool _revealed = false;
//   bool _viewed = false;

//   @override
//   Widget build(BuildContext context) {
//     if (_viewed) {
//       return Container(
//         height: 80,
//         alignment: Alignment.center,
//         decoration: BoxDecoration(
//           color: Colors.grey.shade200,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Text(
//           '📷 Proof viewed',
//           style: Theme.of(
//             context,
//           ).textTheme.bodySmall?.copyWith(color: Colors.grey),
//         ),
//       );
//     }
//     return GestureDetector(
//       onTap: () {
//         if (!_revealed) {
//           setState(() => _revealed = true);
//         } else {
//           setState(() => _viewed = true);
//         }
//       },
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(12),
//         child: Stack(
//           alignment: Alignment.center,
//           children: [
//             Image.memory(
//               base64Decode(widget.b64),
//               height: 180,
//               width: double.infinity,
//               fit: BoxFit.cover,
//             ),
//             if (!_revealed)
//               Container(
//                 height: 180,
//                 width: double.infinity,
//                 color: Colors.black87,
//                 alignment: Alignment.center,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(
//                       Icons.visibility_outlined,
//                       color: Colors.white,
//                       size: 32,
//                     ),
//                     const SizedBox(height: 6),
//                     Text(
//                       'Tap to reveal proof photo',
//                       style: const TextStyle(color: Colors.white, fontSize: 13),
//                     ),
//                   ],
//                 ),
//               ),
//             if (_revealed)
//               Positioned(
//                 bottom: 6,
//                 right: 6,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 10,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.black54,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: const Text(
//                     'Tap to dismiss',
//                     style: TextStyle(color: Colors.white, fontSize: 11),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/extensions/context_ext.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/buttons/j_button.dart';
import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
import '../../domain/tod_models.dart';
import '../../tod_game_provider.dart';
import '../widgets/tod_player_banner.dart';
import '../widgets/tod_timer_ring.dart';
import '../widgets/tod_waiting_overlay.dart';

/// Routes to the correct sub-view based on TodTurnPhase.
class TodCardScreen extends StatelessWidget {
  const TodCardScreen({
    super.key,
    required this.state,
    required this.game,
    required this.displayNames,
  });

  final TodState state;
  final TodGameProvider game;
  final Map<String, String> displayNames;

  @override
  Widget build(BuildContext context) {
    return switch (state.phase) {
      TodTurnPhase.choosingType => _ChoiceView(
        state: state,
        game: game,
        displayNames: displayNames,
      ),
      TodTurnPhase.readingCard => _CardView(
        state: state,
        game: game,
        displayNames: displayNames,
      ),
      TodTurnPhase.awaitingNextTurn => _AwaitingView(
        state: state,
        game: game,
        displayNames: displayNames,
      ),
      TodTurnPhase.awaitingResult => _CardView(
        state: state,
        game: game,
        displayNames: displayNames,
      ),
      _ => _ChoiceView(state: state, game: game, displayNames: displayNames),
    };
  }
}

// ── 1. Choice view ─────────────────────────────────────────────────────────────
class _ChoiceView extends StatelessWidget {
  const _ChoiceView({
    required this.state,
    required this.game,
    required this.displayNames,
  });
  final TodState state;
  final TodGameProvider game;
  final Map<String, String> displayNames;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isMyTurn = game.isMyTurn;
    final playerName =
        displayNames[state.currentPlayerId] ??
        'Player ${state.currentPlayerId.substring(0, 4)}';

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              TodPlayerBanner(
                playerId: state.currentPlayerId,
                playerName: playerName,
                playerOrder: state.playerOrder,
                isMyTurn: isMyTurn,
              ),

              const Spacer(),

              Text(
                isMyTurn ? 'Choose your challenge' : '$playerName is choosing…',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn().slideY(begin: 0.08, end: 0),

              const SizedBox(height: 40),

              if (isMyTurn) ...[
                _ChoiceButton(
                  label: 'Truth',
                  emoji: '🤔',
                  color: AppColors.truthColor,
                  description: 'Answer a personal question honestly.',
                  onTap: game.chooseTruth,
                ).animate(delay: 80.ms).fadeIn().slideX(begin: -0.08, end: 0),

                const SizedBox(height: 16),

                _ChoiceButton(
                  label: 'Dare',
                  emoji: '🔥',
                  color: AppColors.dareColor,
                  description: 'Complete a daring challenge.',
                  onTap: game.chooseDare,
                ).animate(delay: 140.ms).fadeIn().slideX(begin: 0.08, end: 0),
              ] else
                _ChoiceWaiting(playerName: playerName),

              const Spacer(),
            ],
          ),
        ),

        if (!isMyTurn) const TodWaitingOverlay(),
      ],
    );
  }
}

class _ChoiceWaiting extends StatelessWidget {
  const _ChoiceWaiting({required this.playerName});
  final String playerName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(height: 16),
        Text(
          'Waiting for $playerName to decide…',
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.emoji,
    required this.color,
    required this.description,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final Color color;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 2. Card reading view ───────────────────────────────────────────────────────
class _CardView extends StatelessWidget {
  const _CardView({
    required this.state,
    required this.game,
    required this.displayNames,
  });
  final TodState state;
  final TodGameProvider game;
  final Map<String, String> displayNames;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final card = state.currentCard;
    final isMyTurn = game.isMyTurn;

    if (card == null) {
      return const Center(child: Text('No card available — all cards used!'));
    }

    final isSpicy = card.difficulty == TodDifficulty.spicy;
    final isTruth = card.type == TodCardType.truth;
    final cardColor = isTruth ? AppColors.truthColor : AppColors.dareColor;
    final playerName =
        displayNames[state.currentPlayerId] ??
        'Player ${state.currentPlayerId.substring(0, 4)}';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TodPlayerBanner(
            playerId: state.currentPlayerId,
            playerName: playerName,
            playerOrder: state.playerOrder,
            isMyTurn: isMyTurn,
          ),

          const SizedBox(height: 12),

          // Timer ring — only when active
          if (game.timerIsRunning || game.timerRemaining > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TodTimerRing(
                remaining: game.timerRemaining,
                total: game.state != null
                    ? (80) // default; actual from config
                    : 60,
                color: cardColor,
              ).animate().fadeIn(),
            ),

          // Card face
          Expanded(
            child: _CardFace(
              card: card,
              cardColor: cardColor,
              isSpicy: isSpicy,
              isTruth: isTruth,
              coverUrl: game.packCoverUrl,
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          if (isMyTurn) ...[
            JButton(
              label: 'Done! ✅',
              onPressed: () =>
                  _showCompleteSheet(context, game, isTruth: isTruth),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => _confirmSkip(context),
              child: Text(
                'Skip',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else
            Text(
              '$playerName is performing…',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

          // Moderator override row
          if (game.canModerate && !isMyTurn)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextButton.icon(
                onPressed: game.ownerAdvanceTurn,
                icon: const Icon(Icons.skip_next_rounded, size: 16),
                label: const Text('Skip turn (mod)'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.warningAmber,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCompleteSheet(
    BuildContext context,
    TodGameProvider game, {
    bool isTruth = false,
  }) {
    final ctrl = TextEditingController();
    String? imgB64;
    bool _attempted = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        isTruth ? '🤔 Truth' : '🔥 Dare',
                        style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                          color: isTruth
                              ? AppColors.truthColor
                              : AppColors.dareColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Complete Turn',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Truth: response required. Dare: response optional.
                  TextField(
                    controller: ctrl,
                    maxLines: 3,
                    maxLength: 300,
                    decoration: InputDecoration(
                      hintText: isTruth
                          ? 'Your answer is required…'
                          : 'Add a description (optional)…',
                      border: const OutlineInputBorder(),
                      errorText:
                          isTruth && ctrl.text.trim().isEmpty && _attempted
                          ? 'Truth requires a response'
                          : null,
                    ),
                    onChanged: (_) => setS(() {}),
                  ),
                  const SizedBox(height: 8),
                  // Proof image — Dares only
                  if (!isTruth) ...[
                    if (imgB64 != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(imgB64!),
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setS(() => imgB64 = null),
                              child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.black54,
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            final picked = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 40,
                            );
                            if (picked != null) {
                              final bytes = await picked.readAsBytes();
                              setS(() => imgB64 = base64Encode(bytes));
                            }
                          } catch (_) {}
                        },
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Add proof photo (view once)'),
                      ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () {
                      // Truth: enforce non-empty response
                      if (isTruth && ctrl.text.trim().isEmpty) {
                        setS(() => _attempted = true);
                        return;
                      }
                      Navigator.of(ctx).pop();
                      game.completeTurn(
                        response: ctrl.text.trim(),
                        proofImageB64: imgB64 ?? '',
                      );
                    },
                    child: const Text('Submit & Complete Turn ✅'),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmSkip(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Skip this card?',
      message: 'Skipping may result in a group punishment vote.',
      confirmLabel: 'Skip',
    );
    if (confirmed == true) game.skipTurn();
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.card,
    required this.cardColor,
    required this.isSpicy,
    required this.isTruth,
    this.coverUrl,
  });

  final TodCard card;
  final Color cardColor;
  final bool isSpicy;
  final bool isTruth;
  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    final hasCover = coverUrl != null && coverUrl!.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        // height is provided by the parent Expanded — must be explicit for Positioned.fill to work
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cardColor.withOpacity(0.55), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.38),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background image or app default
            Positioned.fill(
              child: hasCover
                  ? Image.network(
                      coverUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/jma3a_card_background.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  : Image.asset(
                      'assets/images/jma3a_card_background.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [cardColor, cardColor.withOpacity(0.78)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
            ),
            // Colour tint
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cardColor.withOpacity(0.45),
                      const Color(0xFF0D1B2A).withOpacity(0.60),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Shimmer
            Positioned.fill(child: CustomPaint(painter: _CardShimmerPainter())),
            // Content
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TypeBadge(label: isTruth ? '🤔  TRUTH' : '🔥  DARE'),
                      if (isSpicy) ...[const SizedBox(width: 8), _SpicyBadge()],
                    ],
                  ),
                  const Spacer(),
                  Text(
                    card.content,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.45,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 350.ms),
                  const Spacer(),
                ],
              ),
            ),
            // Corner suit
            Positioned(
              top: 10,
              left: 12,
              child: Opacity(
                opacity: 0.18,
                child: Text(
                  isTruth ? '🤔' : '🔥',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              right: 12,
              child: Opacity(
                opacity: 0.18,
                child: RotatedBox(
                  quarterTurns: 2,
                  child: Text(
                    isTruth ? '🤔' : '🔥',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(
      begin: const Offset(0.92, 0.92),
      end: const Offset(1, 1),
      duration: 320.ms,
      curve: Curves.easeOutBack,
    );
  }
}

class _CardShimmerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;
    for (double x = -size.height; x < size.width * 2; x += 38)
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SpicyBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.spicyColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        '🌶 SPICY',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ── 3. Awaiting next turn ──────────────────────────────────────────────────────
class _AwaitingView extends StatelessWidget {
  const _AwaitingView({
    required this.state,
    required this.game,
    required this.displayNames,
  });
  final TodState state;
  final TodGameProvider game;
  final Map<String, String> displayNames;

  Future<void> _confirmEndGame(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('End Game?'),
        content: const Text('This will end the game for all players.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
            child: const Text('End Game'),
          ),
        ],
      ),
    );
    if (confirmed == true) game.endGame();
  }

  String _name(String id) =>
      displayNames[id] ?? id.substring(0, id.length.clamp(0, 6));

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final myReacted = state.currentReactions.any(
      (r) => r.userId == game.currentUserId,
    );
    final myVoted = state.currentVotes.any(
      (v) => v.voterId == game.currentUserId,
    );
    final isMyTurn = state.currentPlayerId == game.currentUserId;

    // Group reactions
    final reactTally = <String, int>{};
    for (final r in state.currentReactions) {
      reactTally[r.emoji] = (reactTally[r.emoji] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Turn complete card ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 8),
                Text(
                  _name(state.currentPlayerId),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'completed their turn!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (state.currentCard != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: state.currentCard!.type == TodCardType.truth
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      state.currentCard!.content,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                // Response message
                if (state.turnResponse.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(
                        0.4,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '"${state.turnResponse}"',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                // Proof image (view-once)
                if (state.turnProofImageB64.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ViewOnceImage(b64: state.turnProofImageB64),
                ],
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 16),

          // ── Reactions ────────────────────────────────────────────────────────
          if (reactTally.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: reactTally.entries
                    .map(
                      (e) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${e.key} ${e.value}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          // Emoji picker
          if (!myReacted && !isMyTurn) ...[
            Text('React:', style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children:
                    [
                          '😂',
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
                        ]
                        .map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => game.reactToResponse(s),
                              child: Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  s,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── Vote for response ────────────────────────────────────────────────
          if (!isMyTurn && state.turnResponse.isNotEmpty) ...[
            if (!myVoted)
              OutlinedButton.icon(
                onPressed: game.voteForResponse,
                icon: const Icon(Icons.thumb_up_outlined, size: 16),
                label: Text(
                  '👍 Liked this response '
                  '(${state.currentVotes.length} vote${state.currentVotes.length != 1 ? 's' : ''})',
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '✓ You voted for this response '
                  '(${state.currentVotes.length} total)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.successGreen,
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],

          // ── Scores ───────────────────────────────────────────────────────────
          _ScoreSummary(state: state, displayNames: displayNames),
          const SizedBox(height: 20),

          // ── Next turn controls ───────────────────────────────────────────────
          if (game.isOwner) ...[
            JButton(
              label: 'Next Turn →',
              onPressed: game.ownerAdvanceTurn,
              icon: Icons.skip_next_rounded,
            ).animate(delay: 250.ms).fadeIn(),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => _confirmEndGame(context),
              child: const Text('End Game'),
              style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            ),
          ] else
            Text(
              'Waiting for host to start next turn…',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ).animate().fadeIn(),
        ],
      ),
    );
  }
}

class _ScoreSummary extends StatelessWidget {
  const _ScoreSummary({required this.state, required this.displayNames});
  final TodState state;
  final Map<String, String> displayNames;

  @override
  Widget build(BuildContext context) {
    final top = state.sortedScores.take(3).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    return Column(
      children: top.asMap().entries.map((e) {
        final rank = e.key;
        final score = e.value;
        final medal = ['🥇', '🥈', '🥉'][rank.clamp(0, 2)];
        final name =
            displayNames[score.userId] ??
            'Player ${score.userId.substring(0, 4)}';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(medal, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(child: Text(name, style: context.textTheme.bodyMedium)),
              Text(
                '${score.points} pts',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colorScheme.primary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── View-once proof image ─────────────────────────────────────────────────────

class _ViewOnceImage extends StatefulWidget {
  const _ViewOnceImage({required this.b64});
  final String b64;
  @override
  State<_ViewOnceImage> createState() => _ViewOnceImageState();
}

class _ViewOnceImageState extends State<_ViewOnceImage> {
  bool _revealed = false;
  bool _viewed = false;

  @override
  Widget build(BuildContext context) {
    if (_viewed) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '📷 Proof viewed',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      );
    }
    return GestureDetector(
      onTap: () {
        if (!_revealed) {
          setState(() => _revealed = true);
        } else {
          setState(() => _viewed = true);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.memory(
              base64Decode(widget.b64),
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            if (!_revealed)
              Container(
                height: 180,
                width: double.infinity,
                color: Colors.black87,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap to reveal proof photo',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            if (_revealed)
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Tap to dismiss',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
