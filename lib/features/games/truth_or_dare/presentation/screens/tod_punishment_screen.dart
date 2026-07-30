// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';

// import '../../../../../core/extensions/context_ext.dart';
// import '../../../../../core/theme/app_colors.dart';
// import '../../../../../shared/widgets/buttons/j_button.dart';
// import '../../domain/tod_models.dart';
// import '../../tod_game_provider.dart';

// /// Punishment screen — shown when a player skips.
// ///
// /// Phase machine:
// ///   1. No punishment proposed yet      → owner/mod sees "Propose" form;
// ///                                         others see "Waiting for host…"
// ///   2. Punishment text set, voting open → all non-skipped players vote
// ///   3. Majority reached / mod overrides → outcome splash shown briefly
// class TodPunishmentScreen extends StatefulWidget {
//   const TodPunishmentScreen({
//     super.key,
//     required this.state,
//     required this.game,
//     required this.displayNames,
//   });

//   final TodState            state;
//   final TodGameProvider     game;
//   final Map<String, String> displayNames;

//   @override
//   State<TodPunishmentScreen> createState() => _TodPunishmentScreenState();
// }

// class _TodPunishmentScreenState extends State<TodPunishmentScreen> {
//   final _textCtrl = TextEditingController();

//   @override
//   void dispose() {
//     _textCtrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final state     = widget.state;
//     final game      = widget.game;
//     final voteState = state.currentPunishmentVote;
//     final theme     = context.theme;

//     final skipperName = widget.displayNames[state.currentPlayerId] ??
//         'Player ${state.currentPlayerId.substring(0, 4)}';

//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _PunishmentHeader(skipperName: skipperName),
//           const SizedBox(height: 16),

//           Expanded(
//             child: voteState == null
//                 ? _ProposeView(
//                     game:       game,
//                     textCtrl:   _textCtrl,
//                     canPropose: game.canModerate,
//                   )
//                 : _VotingView(
//                     game:      game,
//                     state:     state,
//                     voteState: voteState,
//                     textCtrl:  _textCtrl,
//                     displayNames: widget.displayNames,
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── Header ─────────────────────────────────────────────────────────────────────
// class _PunishmentHeader extends StatelessWidget {
//   const _PunishmentHeader({required this.skipperName});
//   final String skipperName;

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     return Container(
//       width:   double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             AppColors.warningAmber.withOpacity(0.15),
//             AppColors.warningAmber.withOpacity(0.05),
//           ],
//           begin: Alignment.topLeft,
//           end:   Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppColors.warningAmber.withOpacity(0.3)),
//       ),
//       child: Row(
//         children: [
//           const Text('⏭', style: TextStyle(fontSize: 32)),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('$skipperName skipped!',
//                     style: theme.textTheme.titleMedium?.copyWith(
//                         fontWeight: FontWeight.w700)),
//                 Text('Time for the group to decide the punishment.',
//                     style: theme.textTheme.bodySmall?.copyWith(
//                         color: theme.colorScheme.onSurfaceVariant)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     ).animate().fadeIn().slideY(begin: -0.05, end: 0);
//   }
// }

// // ── Phase 1: Propose ───────────────────────────────────────────────────────────
// class _ProposeView extends StatelessWidget {
//   const _ProposeView({
//     required this.game,
//     required this.textCtrl,
//     required this.canPropose,
//   });

//   final TodGameProvider       game;
//   final TextEditingController textCtrl;
//   final bool                  canPropose;

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;

//     if (!canPropose) {
//       return Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const SizedBox(
//               width: 40, height: 40,
//               child: CircularProgressIndicator(strokeWidth: 2.5),
//             ),
//             const SizedBox(height: 16),
//             Text('Waiting for the host to\npropose a punishment…',
//                 style: theme.textTheme.bodyLarge?.copyWith(
//                     color: theme.colorScheme.onSurfaceVariant),
//                 textAlign: TextAlign.center),
//           ],
//         ).animate().fadeIn(),
//       );
//     }

//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Create a punishment:',
//               style: theme.textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.w700)),
//           const SizedBox(height: 12),

//           TextField(
//             controller: textCtrl,
//             maxLength:  200,
//             maxLines:   3,
//             decoration: const InputDecoration(
//               hintText:  'Describe the punishment…',
//               counterText: '',
//             ),
//           ),
//           const SizedBox(height: 16),

//           JButton(
//             label:     'Propose Punishment',
//             onPressed: () {
//               final text = textCtrl.text.trim();
//               if (text.isNotEmpty) {
//                 game.proposePunishment(text);
//                 textCtrl.clear();
//               }
//             },
//             icon: Icons.send_rounded,
//           ).animate(delay: 80.ms).fadeIn(),

//           const SizedBox(height: 24),

//           Text('Quick presets:',
//               style: theme.textTheme.labelLarge?.copyWith(
//                   color: theme.colorScheme.onSurfaceVariant)),
//           const SizedBox(height: 8),

//           _QuickPunishments(
//             onSelect: (text) {
//               textCtrl.text = text;
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _QuickPunishments extends StatelessWidget {
//   const _QuickPunishments({required this.onSelect});
//   final void Function(String) onSelect;

//   static const _presets = [
//     'Do 10 push-ups',
//     'Sing a song for 30 seconds',
//     'Do a silly dance move',
//     'Tell an embarrassing story',
//     'Do your best animal impression',
//     'Speak in an accent for 2 turns',
//     'Post a funny status',
//     'Call someone and say something weird',
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Wrap(
//       spacing: 8, runSpacing: 8,
//       children: _presets.map((p) => ActionChip(
//         label:    Text(p, style: const TextStyle(fontSize: 12)),
//         onPressed: () => onSelect(p),
//         avatar:   const Icon(Icons.add_rounded, size: 14),
//         visualDensity: VisualDensity.compact,
//       )).toList(),
//     );
//   }
// }

// // ── Phase 2: Voting ────────────────────────────────────────────────────────────
// class _VotingView extends StatelessWidget {
//   const _VotingView({
//     required this.game,
//     required this.state,
//     required this.voteState,
//     required this.textCtrl,
//     required this.displayNames,
//   });

//   final TodGameProvider         game;
//   final TodState                state;
//   final TodPunishmentVoteState  voteState;
//   final TextEditingController   textCtrl;
//   final Map<String, String>     displayNames;

//   @override
//   Widget build(BuildContext context) {
//     final theme    = context.theme;
//     final hasVoted = game.hasVotedOnPunishment;
//     final isSkipped = game.isMyTurn;     // the player who skipped
//     final resolved  = voteState.resolvedVote;

//     if (resolved != null) {
//       return _OutcomeView(vote: resolved, voteState: voteState);
//     }

//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Punishment card
//           Container(
//             width:   double.infinity,
//             padding: const EdgeInsets.all(18),
//             decoration: BoxDecoration(
//               color:        theme.colorScheme.surfaceContainerHighest,
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(
//                   color: AppColors.warningAmber.withOpacity(0.35)),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Punishment:',
//                     style: theme.textTheme.labelLarge?.copyWith(
//                         color: theme.colorScheme.onSurfaceVariant)),
//                 const SizedBox(height: 8),
//                 Text(voteState.punishment.text,
//                     style: theme.textTheme.titleMedium?.copyWith(
//                         fontWeight: FontWeight.w700)),
//               ],
//             ),
//           ).animate().fadeIn(),

//           const SizedBox(height: 20),

//           _VoteProgress(voteState: voteState),

//           const SizedBox(height: 24),

//           // Vote buttons (not for the player who skipped)
//           if (!isSkipped && !hasVoted) ...[
//             Text('Cast your vote:',
//                 style: theme.textTheme.titleSmall?.copyWith(
//                     fontWeight: FontWeight.w600)),
//             const SizedBox(height: 12),

//             Row(
//               children: [
//                 Expanded(
//                   child: _VoteButton(
//                     label:  'Do It! 💪',
//                     color:  AppColors.successGreen,
//                     onTap:  () => game.voteOnPunishment(
//                         TodPunishmentVote.doIt),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: _VoteButton(
//                     label:  'Pass 🙅',
//                     color:  AppColors.errorRed,
//                     onTap:  () => game.voteOnPunishment(
//                         TodPunishmentVote.dontDoIt),
//                   ),
//                 ),
//               ],
//             ).animate(delay: 80.ms).fadeIn(),

//             const SizedBox(height: 12),

//             OutlinedButton.icon(
//               onPressed: () =>
//                   game.voteOnPunishment(TodPunishmentVote.changePunishment),
//               icon:  const Icon(Icons.swap_horiz_rounded),
//               label: const Text('Change Punishment'),
//               style: OutlinedButton.styleFrom(
//                   minimumSize: const Size(double.infinity, 44)),
//             ).animate(delay: 120.ms).fadeIn(),

//           ] else if (isSkipped)
//             Container(
//               padding:     const EdgeInsets.all(16),
//               decoration:  BoxDecoration(
//                 color:        theme.colorScheme.surfaceContainerHighest,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text('😬', style: TextStyle(fontSize: 20)),
//                   SizedBox(width: 8),
//                   Text('Others are voting on your fate…',
//                       style: TextStyle(fontWeight: FontWeight.w600)),
//                 ],
//               ),
//             ).animate().fadeIn()

//           else if (hasVoted)
//             Container(
//               padding:     const EdgeInsets.all(16),
//               decoration:  BoxDecoration(
//                 color:        AppColors.successGreen.withOpacity(0.08),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.check_circle_rounded,
//                       color: AppColors.successGreen),
//                   SizedBox(width: 8),
//                   Text('Vote recorded!',
//                       style: TextStyle(
//                           color:      AppColors.successGreen,
//                           fontWeight: FontWeight.w600)),
//                 ],
//               ),
//             ).animate().fadeIn(),

//           const SizedBox(height: 24),

//           // Moderator panel
//           if (game.canModerate) ...[
//             Text('Moderator controls:',
//                 style: theme.textTheme.labelLarge?.copyWith(
//                     color: theme.colorScheme.onSurfaceVariant)),
//             const SizedBox(height: 8),
//             _ModeratorOverridePanel(game: game, textCtrl: textCtrl),
//           ],
//         ],
//       ),
//     );
//   }
// }

// class _VoteProgress extends StatelessWidget {
//   const _VoteProgress({required this.voteState});
//   final TodPunishmentVoteState voteState;

//   @override
//   Widget build(BuildContext context) {
//     final doIt     = voteState.votes.values
//         .where((v) => v == TodPunishmentVote.doIt).length;
//     final dontDoIt = voteState.votes.values
//         .where((v) => v == TodPunishmentVote.dontDoIt).length;
//     final change   = voteState.votes.values
//         .where((v) => v == TodPunishmentVote.changePunishment).length;
//     final total    = voteState.totalVoters;
//     final cast     = voteState.votes.length;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Text('Votes: $cast / $total',
//                 style: context.textTheme.labelLarge?.copyWith(
//                     color: context.colorScheme.onSurfaceVariant)),
//             const Spacer(),
//             if (voteState.moderatorOverride != null)
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 8, vertical: 3),
//                 decoration: BoxDecoration(
//                   color: AppColors.warningAmber.withOpacity(0.15),
//                   borderRadius: BorderRadius.circular(6),
//                 ),
//                 child: Text('Mod Override',
//                     style: TextStyle(
//                         fontSize: 11,
//                         fontWeight: FontWeight.w700,
//                         color: AppColors.warningAmber)),
//               ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         ClipRRect(
//           borderRadius: BorderRadius.circular(8),
//           child: SizedBox(
//             height: 36,
//             child: Row(
//               children: [
//                 if (doIt > 0)
//                   _VoteBar(flex: doIt,     color: AppColors.successGreen,
//                       label: 'Do It ($doIt)'),
//                 if (dontDoIt > 0)
//                   _VoteBar(flex: dontDoIt, color: AppColors.errorRed,
//                       label: "Pass ($dontDoIt)"),
//                 if (change > 0)
//                   _VoteBar(flex: change,   color: AppColors.warningAmber,
//                       label: "Change ($change)"),
//                 if (cast < total)
//                   Expanded(
//                     flex: total - cast,
//                     child: Container(
//                         color: context.colorScheme.surfaceContainerHighest),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _VoteBar extends StatelessWidget {
//   const _VoteBar({required this.flex, required this.color, required this.label});
//   final int    flex;
//   final Color  color;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       flex: flex,
//       child: Container(
//         color: color.withOpacity(0.75),
//         child: Center(
//           child: Text(label,
//               style: const TextStyle(
//                   fontSize: 11, fontWeight: FontWeight.w700,
//                   color: Colors.white)),
//         ),
//       ),
//     );
//   }
// }

// class _VoteButton extends StatelessWidget {
//   const _VoteButton({
//     required this.label,
//     required this.color,
//     required this.onTap,
//   });
//   final String      label;
//   final Color       color;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         height: 56,
//         decoration: BoxDecoration(
//           color:        color,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color:      color.withOpacity(0.3),
//               blurRadius: 8,
//               offset:     const Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Center(
//           child: Text(label,
//               style: const TextStyle(
//                   color:      Colors.white,
//                   fontWeight: FontWeight.w700,
//                   fontSize:   15)),
//         ),
//       ),
//     );
//   }
// }

// class _ModeratorOverridePanel extends StatelessWidget {
//   const _ModeratorOverridePanel({
//     required this.game,
//     required this.textCtrl,
//   });
//   final TodGameProvider       game;
//   final TextEditingController textCtrl;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding:    const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color:        AppColors.warningAmber.withOpacity(0.07),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//             color: AppColors.warningAmber.withOpacity(0.25)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: _OverrideButton(
//                   label:  'Force Do It',
//                   color:  AppColors.successGreen,
//                   onTap:  () => game.overridePunishment(
//                       TodPunishmentVote.doIt),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: _OverrideButton(
//                   label:  'Force Pass',
//                   color:  AppColors.errorRed,
//                   onTap:  () => game.overridePunishment(
//                       TodPunishmentVote.dontDoIt),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 10),
//           TextField(
//             controller: textCtrl,
//             decoration: const InputDecoration(
//               hintText: 'Replace punishment text…',
//               isDense:  true,
//             ),
//           ),
//           const SizedBox(height: 8),
//           OutlinedButton(
//             onPressed: () {
//               final text = textCtrl.text.trim();
//               game.overridePunishment(
//                 TodPunishmentVote.doIt,
//                 replacementText: text.isNotEmpty ? text : null,
//               );
//               textCtrl.clear();
//             },
//             style: OutlinedButton.styleFrom(
//               minimumSize:    const Size(double.infinity, 40),
//               foregroundColor: AppColors.warningAmber,
//               side: BorderSide(color: AppColors.warningAmber.withOpacity(0.5)),
//             ),
//             child: const Text('Replace & Force'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _OverrideButton extends StatelessWidget {
//   const _OverrideButton({
//     required this.label,
//     required this.color,
//     required this.onTap,
//   });
//   final String      label;
//   final Color       color;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return OutlinedButton(
//       onPressed: onTap,
//       style: OutlinedButton.styleFrom(
//         side:            BorderSide(color: color),
//         foregroundColor: color,
//         minimumSize:     const Size(double.infinity, 40),
//       ),
//       child: Text(label,
//           style: const TextStyle(
//               fontSize: 12, fontWeight: FontWeight.w700)),
//     );
//   }
// }

// // ── Outcome view ──────────────────────────────────────────────────────────────
// class _OutcomeView extends StatelessWidget {
//   const _OutcomeView({required this.vote, required this.voteState});
//   final TodPunishmentVote      vote;
//   final TodPunishmentVoteState voteState;

//   @override
//   Widget build(BuildContext context) {
//     final (emoji, label, color) = switch (vote) {
//       TodPunishmentVote.doIt     => ('💪', 'Punishment accepted!', AppColors.successGreen),
//       TodPunishmentVote.dontDoIt => ('🙅', 'Punishment rejected!', AppColors.errorRed),
//       TodPunishmentVote.changePunishment =>
//           ('🔄', 'Changing punishment…', AppColors.warningAmber),
//     };

//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(emoji, style: const TextStyle(fontSize: 72))
//               .animate()
//               .scale(
//                 begin: const Offset(0.3, 0.3),
//                 end:   const Offset(1, 1),
//                 duration: 550.ms,
//                 curve: Curves.elasticOut,
//               ),
//           const SizedBox(height: 20),
//           Text(label,
//               style: context.textTheme.headlineSmall?.copyWith(
//                   fontWeight: FontWeight.w700, color: color))
//               .animate(delay: 200.ms).fadeIn(),
//           if (vote == TodPunishmentVote.doIt) ...[
//             const SizedBox(height: 12),
//             Text(voteState.punishment.text,
//                 style: context.textTheme.bodyLarge,
//                 textAlign: TextAlign.center)
//                 .animate(delay: 300.ms).fadeIn(),
//           ],
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/tod_models.dart';
import '../../tod_game_provider.dart';

// ── Design tokens matching the rest of the game UI ───────────────────────────
const _kNavy = Color(0xFF0D1B2A);
const _kNavyLight = Color(0xFF1A2E45);
const _kYellow = Color(0xFFFFD60A);
const _kCoral = Color(0xFFFF6B6B);
const _kGreen = Color(0xFF4ADE80);
const _kOrange = Color(0xFFFB923C);

// /// Full-screen punishment flow shown to every player when a skip happens.
// ///
// /// Flow:
// ///  Phase A — [no punishment proposed yet]
// ///    • Admin/moderator: text field to type a punishment + send
// ///    • Others: "Waiting for admin to propose a punishment…"
// ///
// ///  Phase B — [punishment proposed, voting in progress]
// ///    • Current player: sees the punishment, can't vote on own punishment
// ///    • Everyone else: 3 vote buttons → Do It / Pass / Change It
// ///    • Live vote tally shown to all
// ///
// ///  Phase C — [outcome = doIt]
// ///    • Big punishment card + countdown timer (default 60s)
// ///    • Admin sees "Confirm done" button to advance
// ///    • Others see "Waiting for [player] to complete…"
// ///
// ///  Phase D — [outcome = dontDoIt / changePunishment]
// ///    • Goes back to Phase A (engine resets vote)
// class TodPunishmentScreen extends StatefulWidget {
//   const TodPunishmentScreen({
//     super.key,
//     required this.state,
//     required this.game,
//     required this.displayNames,
//   });
// 
//   final TodState state;
//   final TodGameProvider game;
//   final Map<String, String> displayNames;
// 
//   @override
//   State<TodPunishmentScreen> createState() => _TodPunishmentScreenState();
// }
// 
// class _TodPunishmentScreenState extends State<TodPunishmentScreen> {
//   final _ctrl = TextEditingController();
// 
//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }
// 
//   String _name(String id) =>
//       widget.displayNames[id] ?? id.substring(0, id.length.clamp(0, 6));
// 
//   @override
//   Widget build(BuildContext context) {
//     final state = widget.state;
//     final game = widget.game;
//     final voteState = state.currentPunishmentVote;
//     final myId = game.currentUserId;
//     final isAdmin = game.isOwner || game.canModerate;
//     final playerName = _name(state.currentPlayerId);
//     final isCurrentPlayer = myId == state.currentPlayerId;
// 
//     // ── Phase C: outcome reached → execution ────────────────────────────────
//     if (voteState != null && voteState.hasOutcome) {
//       final decision = voteState.resolvedVote;
//       if (decision == TodPunishmentVote.doIt) {
//         return _ExecutionPhase(
//           punishment: voteState.punishment,
//           playerName: playerName,
//           isAdmin: isAdmin,
//           onConfirm: () => game.ownerAdvanceTurn(),
//         );
//       }
//       // dontDoIt / changePunishment → engine will reset; show brief message
//       return _OutcomeMessage(decision: decision, playerName: playerName);
//     }
// 
//     // ── Phase B: punishment proposed, voting ────────────────────────────────
//     if (voteState != null) {
//       return _VotingPhase(
//         voteState: voteState,
//         state: state,
//         game: game,
//         myId: myId,
//         isAdmin: isAdmin,
//         isCurrentPlayer: isCurrentPlayer,
//         playerName: playerName,
//         displayNames: widget.displayNames,
//       );
//     }
// 
//     // ── Phase A: no punishment proposed yet ─────────────────────────────────
//     return _ProposePhase(
//       state: state,
//       game: game,
//       ctrl: _ctrl,
//       isAdmin: isAdmin,
//       isCurrentPlayer: isCurrentPlayer,
//       playerName: playerName,
//     );
//   }
// }
// 
// // ── Phase A: propose ──────────────────────────────────────────────────────────
// class _ProposePhase extends StatelessWidget {
//   const _ProposePhase({
//     required this.state,
//     required this.game,
//     required this.ctrl,
//     required this.isAdmin,
//     required this.isCurrentPlayer,
//     required this.playerName,
//   });
//   final TodState state;
//   final TodGameProvider game;
//   final TextEditingController ctrl;
//   final bool isAdmin, isCurrentPlayer;
//   final String playerName;
// 
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: _kNavy,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             children: [
//               // Header
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: _kCoral.withOpacity(0.15),
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(color: _kCoral.withOpacity(0.3)),
//                 ),
//                 child: Column(
//                   children: [
//                     const Text(
//                       '⚡',
//                       style: TextStyle(fontSize: 52),
//                     ).animate().scale(
//                       begin: const Offset(0, 0),
//                       end: const Offset(1, 1),
//                       duration: 400.ms,
//                       curve: Curves.elasticOut,
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       '$playerName skipped!',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 22,
//                         fontWeight: FontWeight.w800,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 4),
//                     const Text(
//                       'Time for a punishment…',
//                       style: TextStyle(color: Colors.white60, fontSize: 14),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ).animate().fadeIn().slideY(begin: -0.1, end: 0),
// 
//               const Spacer(),
// 
//               if (isAdmin && !isCurrentPlayer) ...[
//                 const Text(
//                   'Propose a punishment:',
//                   style: TextStyle(
//                     color: Colors.white70,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 TextField(
//                   controller: ctrl,
//                   maxLength: 200,
//                   style: const TextStyle(color: Colors.white),
//                   decoration: InputDecoration(
//                     hintText: 'e.g. "Do 10 push-ups" or "Sing a verse"',
//                     hintStyle: const TextStyle(color: Colors.white38),
//                     filled: true,
//                     fillColor: _kNavyLight,
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(14),
//                       borderSide: BorderSide(color: _kCoral.withOpacity(0.3)),
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(14),
//                       borderSide: BorderSide(color: _kCoral.withOpacity(0.3)),
//                     ),
//                     counterStyle: const TextStyle(color: Colors.white38),
//                   ),
//                   maxLines: 2,
//                 ),
//                 const SizedBox(height: 12),
//                 FilledButton.icon(
//                   onPressed: () {
//                     final txt = ctrl.text.trim();
//                     if (txt.isEmpty) return;
//                     game.proposePunishment(txt);
//                     ctrl.clear();
//                   },
//                   style: FilledButton.styleFrom(
//                     backgroundColor: _kCoral,
//                     foregroundColor: Colors.white,
//                     minimumSize: const Size(double.infinity, 52),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                   ),
//                   icon: const Icon(Icons.send_rounded),
//                   label: const Text(
//                     'Send Punishment',
//                     style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
//                   ),
//                 ),
//               ] else if (isCurrentPlayer) ...[
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: _kNavyLight,
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: const Column(
//                     children: [
//                       Text('😬', style: TextStyle(fontSize: 44)),
//                       SizedBox(height: 8),
//                       Text(
//                         'You skipped…',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                       SizedBox(height: 4),
//                       Text(
//                         'The group is deciding your fate.',
//                         style: TextStyle(color: Colors.white54, fontSize: 14),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//               ] else ...[
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: _kNavyLight,
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Column(
//                     children: [
//                       const SizedBox(
//                         width: 32,
//                         height: 32,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2.5,
//                           color: _kYellow,
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       Text(
//                         'Waiting for the admin to propose a punishment for $playerName…',
//                         style: const TextStyle(
//                           color: Colors.white60,
//                           fontSize: 14,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
// 
//               const Spacer(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
// 
// // ── Phase B: voting ───────────────────────────────────────────────────────────
// class _VotingPhase extends StatelessWidget {
//   const _VotingPhase({
//     required this.voteState,
//     required this.state,
//     required this.game,
//     required this.myId,
//     required this.isAdmin,
//     required this.isCurrentPlayer,
//     required this.playerName,
//     required this.displayNames,
//   });
// 
//   final TodPunishmentVoteState voteState;
//   final TodState state;
//   final TodGameProvider game;
//   final String myId;
//   final bool isAdmin, isCurrentPlayer;
//   final String playerName;
//   final Map<String, String> displayNames;
// 
//   bool get _hasVoted => voteState.votes.containsKey(myId);
// 
//   @override
//   Widget build(BuildContext context) {
//     final doItCount = voteState.votes.values
//         .where((v) => v == TodPunishmentVote.doIt)
//         .length;
//     final passCount = voteState.votes.values
//         .where((v) => v == TodPunishmentVote.dontDoIt)
//         .length;
//     final changeCount = voteState.votes.values
//         .where((v) => v == TodPunishmentVote.changePunishment)
//         .length;
//     final total = voteState.totalVoters;
//     final majority = (total / 2).ceil();
// 
//     return Scaffold(
//       backgroundColor: _kNavy,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Punishment card
//               Container(
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       _kOrange.withOpacity(0.3),
//                       _kCoral.withOpacity(0.2),
//                     ],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(24),
//                   border: Border.all(
//                     color: _kOrange.withOpacity(0.4),
//                     width: 1.5,
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     const Text(
//                       '⚡ PUNISHMENT',
//                       style: TextStyle(
//                         color: Colors.white54,
//                         fontSize: 11,
//                         fontWeight: FontWeight.w800,
//                         letterSpacing: 1.5,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       voteState.punishment.text,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 22,
//                         fontWeight: FontWeight.w800,
//                         height: 1.4,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       'For: $playerName',
//                       style: TextStyle(
//                         color: _kOrange.withOpacity(0.8),
//                         fontSize: 13,
//                       ),
//                     ),
//                   ],
//                 ),
//               ).animate().fadeIn().slideY(begin: -0.1, end: 0),
// 
//               const SizedBox(height: 20),
// 
//               // Vote tally
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _VotePill(
//                     emoji: '🔥',
//                     label: 'DO IT',
//                     count: doItCount,
//                     needed: majority,
//                     color: _kCoral,
//                   ),
//                   _VotePill(
//                     emoji: '🙅',
//                     label: 'PASS',
//                     count: passCount,
//                     needed: majority,
//                     color: Colors.white54,
//                   ),
//                   _VotePill(
//                     emoji: '🔄',
//                     label: 'CHANGE',
//                     count: changeCount,
//                     needed: majority,
//                     color: _kPurple,
//                   ),
//                 ],
//               ).animate().fadeIn(),
// 
//               const SizedBox(height: 8),
//               LinearProgressIndicator(
//                 value: voteState.votes.length / total.clamp(1, 999),
//                 backgroundColor: Colors.white.withOpacity(0.08),
//                 color: _kYellow,
//               ),
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 4),
//                 child: Text(
//                   '${voteState.votes.length} / $total voted',
//                   style: const TextStyle(color: Colors.white38, fontSize: 11),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
// 
//               const SizedBox(height: 20),
// 
//               // Vote buttons
//               if (isCurrentPlayer) ...[
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 12,
//                   ),
//                   decoration: BoxDecoration(
//                     color: _kNavyLight,
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   child: const Text(
//                     'You can\'t vote on your own punishment 😅',
//                     style: TextStyle(color: Colors.white54, fontSize: 13),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ] else if (_hasVoted) ...[
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 12,
//                   ),
//                   decoration: BoxDecoration(
//                     color: _kGreen.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(14),
//                     border: Border.all(color: _kGreen.withOpacity(0.3)),
//                   ),
//                   child: Text(
//                     '✅ You voted: ${_voteLabel(voteState.votes[myId]!)}',
//                     style: const TextStyle(
//                       color: _kGreen,
//                       fontWeight: FontWeight.w700,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ] else ...[
//                 const Text(
//                   'Cast your vote:',
//                   style: TextStyle(
//                     color: Colors.white70,
//                     fontSize: 14,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: _VoteButton(
//                         emoji: '🔥',
//                         label: 'DO IT',
//                         color: _kCoral,
//                         onTap: () =>
//                             game.voteOnPunishment(TodPunishmentVote.doIt),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: _VoteButton(
//                         emoji: '🙅',
//                         label: 'PASS',
//                         color: Colors.white54,
//                         onTap: () =>
//                             game.voteOnPunishment(TodPunishmentVote.dontDoIt),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: _VoteButton(
//                         emoji: '🔄',
//                         label: 'CHANGE',
//                         color: _kPurple,
//                         onTap: () => game.voteOnPunishment(
//                           TodPunishmentVote.changePunishment,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1, end: 0),
//               ],
// 
//               // Admin override
//               if (isAdmin) ...[
//                 const SizedBox(height: 20),
//                 const Divider(color: Colors.white12),
//                 const SizedBox(height: 8),
//                 const Text(
//                   'Admin override:',
//                   style: TextStyle(
//                     color: Colors.white38,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w700,
//                     letterSpacing: 1,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: () =>
//                             game.overridePunishment(TodPunishmentVote.doIt),
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: _kCoral,
//                           side: const BorderSide(color: _kCoral),
//                         ),
//                         child: const Text('Force DO IT'),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: () =>
//                             game.overridePunishment(TodPunishmentVote.dontDoIt),
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: Colors.white54,
//                           side: const BorderSide(color: Colors.white24),
//                         ),
//                         child: const Text('Skip'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// 
//   String _voteLabel(TodPunishmentVote v) => switch (v) {
//     TodPunishmentVote.doIt => '🔥 Do It',
//     TodPunishmentVote.dontDoIt => '🙅 Pass',
//     TodPunishmentVote.changePunishment => '🔄 Change It',
//   };
// }
// 
// // ── Phase C: execution ────────────────────────────────────────────────────────
// class _ExecutionPhase extends StatefulWidget {
//   const _ExecutionPhase({
//     required this.punishment,
//     required this.playerName,
//     required this.isAdmin,
//     required this.onConfirm,
//   });
//   final TodPunishment punishment;
//   final String playerName;
//   final bool isAdmin;
//   final VoidCallback onConfirm;
//   @override
//   State<_ExecutionPhase> createState() => _ExecutionPhaseState();
// }
// 
// class _ExecutionPhaseState extends State<_ExecutionPhase> {
//   static const _kDuration = 60;
//   int _remaining = _kDuration;
//   Timer? _t;
//   bool _canConfirm = false;
// 
//   @override
//   void initState() {
//     super.initState();
//     _t = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (!mounted) return;
//       setState(() {
//         if (_remaining > 0) _remaining--;
//         if (_remaining == 0) {
//           _canConfirm = true;
//           _t?.cancel();
//         }
//       });
//     });
//   }
// 
//   @override
//   void dispose() {
//     _t?.cancel();
//     super.dispose();
//   }
// 
//   @override
//   Widget build(BuildContext context) {
//     final pct = _remaining / _kDuration;
//     final timerColor = pct > 0.4
//         ? _kGreen
//         : pct > 0.2
//         ? _kOrange
//         : _kCoral;
// 
//     return Scaffold(
//       backgroundColor: _kNavy,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             children: [
//               // Timer
//               Container(
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     child: Column(
//                       children: [
//                         Text(
//                           '$_remaining',
//                           style: TextStyle(
//                             color: timerColor,
//                             fontSize: 72,
//                             fontWeight: FontWeight.w900,
//                           ),
//                         ),
//                         Text(
//                           'seconds remaining',
//                           style: TextStyle(
//                             color: timerColor.withOpacity(0.7),
//                             fontSize: 12,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(6),
//                           child: LinearProgressIndicator(
//                             value: pct,
//                             minHeight: 8,
//                             color: timerColor,
//                             backgroundColor: timerColor.withOpacity(0.15),
//                           ),
//                         ),
//                       ],
//                     ),
//                   )
//                   .animate(onPlay: (c) => c.repeat(reverse: true))
//                   .shimmer(
//                     duration: 2.seconds,
//                     color: timerColor.withOpacity(0.3),
//                   ),
// 
//               const SizedBox(height: 16),
// 
//               // Punishment card
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       _kCoral.withOpacity(0.4),
//                       _kOrange.withOpacity(0.25),
//                     ],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(24),
//                   border: Border.all(color: _kCoral.withOpacity(0.5), width: 2),
//                   boxShadow: [
//                     BoxShadow(color: _kCoral.withOpacity(0.3), blurRadius: 24),
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     const Text('⚡', style: TextStyle(fontSize: 48)),
//                     const SizedBox(height: 10),
//                     const Text(
//                       'PUNISHMENT',
//                       style: TextStyle(
//                         color: Colors.white54,
//                         fontSize: 11,
//                         fontWeight: FontWeight.w800,
//                         letterSpacing: 2,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       widget.punishment.text,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 24,
//                         fontWeight: FontWeight.w800,
//                         height: 1.4,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       '${widget.playerName} must complete this!',
//                       style: TextStyle(
//                         color: _kCoral.withOpacity(0.8),
//                         fontSize: 13,
//                       ),
//                     ),
//                   ],
//                 ),
//               ).animate().scale(
//                 begin: const Offset(0.92, 0.92),
//                 end: const Offset(1, 1),
//                 duration: 350.ms,
//                 curve: Curves.easeOutBack,
//               ),
// 
//               const Spacer(),
// 
//               if (widget.isAdmin) ...[
//                 FilledButton.icon(
//                   onPressed: _canConfirm
//                       ? widget.onConfirm
//                       : () {
//                           // Admin can force-confirm early
//                           widget.onConfirm();
//                         },
//                   style: FilledButton.styleFrom(
//                     backgroundColor: _canConfirm ? _kGreen : _kOrange,
//                     foregroundColor: _kNavy,
//                     minimumSize: const Size(double.infinity, 56),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                   ),
//                   icon: const Icon(Icons.check_circle_rounded),
//                   label: Text(
//                     _canConfirm
//                         ? '✅ Confirm Done — Next Turn'
//                         : '⏩ Skip Timer & Confirm',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w800,
//                       fontSize: 15,
//                     ),
//                   ),
//                 ).animate().fadeIn().slideY(begin: 0.2, end: 0),
//               ] else ...[
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: _kNavyLight,
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   child: Text(
//                     '${widget.playerName} is completing the punishment…\nWaiting for admin to confirm.',
//                     style: const TextStyle(color: Colors.white60, fontSize: 14),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ],
// 
//               const SizedBox(height: 16),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
// 
// // ── Outcome message (doNotDoIt / changePunishment) ────────────────────────────
// class _OutcomeMessage extends StatelessWidget {
//   const _OutcomeMessage({required this.decision, required this.playerName});
//   final TodPunishmentVote? decision;
//   final String playerName;
//   @override
//   Widget build(BuildContext context) {
//     final isDontDo = decision == TodPunishmentVote.dontDoIt;
//     return Scaffold(
//       backgroundColor: _kNavy,
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(32),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 isDontDo ? '🙅' : '🔄',
//                 style: const TextStyle(fontSize: 64),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 isDontDo
//                     ? 'Group voted to let $playerName off!\nMoving to next turn…'
//                     : 'Group wants a different punishment!\nAdmin will propose a new one…',
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 18,
//                   fontWeight: FontWeight.w700,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
// 
// // ── Helper widgets ─────────────────────────────────────────────────────────────
// class _VotePill extends StatelessWidget {
//   const _VotePill({
//     required this.emoji,
//     required this.label,
//     required this.count,
//     required this.needed,
//     required this.color,
//   });
//   final String emoji, label;
//   final int count, needed;
//   final Color color;
//   @override
//   Widget build(BuildContext context) => Column(
//     children: [
//       Text(emoji, style: const TextStyle(fontSize: 24)),
//       const SizedBox(height: 2),
//       Text(
//         '$count',
//         style: TextStyle(
//           color: color,
//           fontWeight: FontWeight.w900,
//           fontSize: 22,
//         ),
//       ),
//       Text(
//         label,
//         style: TextStyle(
//           color: color.withOpacity(0.7),
//           fontSize: 9,
//           fontWeight: FontWeight.w700,
//           letterSpacing: 0.8,
//         ),
//       ),
//       Text(
//         'need $needed',
//         style: const TextStyle(color: Colors.white24, fontSize: 9),
//       ),
//     ],
//   );
// }
// 
// class _VoteButton extends StatelessWidget {
//   const _VoteButton({
//     required this.emoji,
//     required this.label,
//     required this.color,
//     required this.onTap,
//   });
//   final String emoji, label;
//   final Color color;
//   final VoidCallback onTap;
//   @override
//   Widget build(BuildContext context) => GestureDetector(
//     onTap: onTap,
//     child: Container(
//       padding: const EdgeInsets.symmetric(vertical: 16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [color, color.withOpacity(0.75)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             color: color.withOpacity(0.35),
//             blurRadius: 14,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Text(emoji, style: const TextStyle(fontSize: 28)),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.w800,
//               fontSize: 11,
//               letterSpacing: 0.5,
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }

/// Full-screen punishment flow shown to every player when a skip happens.
///
/// Flow:
///  Phase A — [no options proposed yet]
///    • Admin/moderator: builds 3-5 punishment options, then starts the vote
///    • Others: "Waiting for admin to set up punishment options…"
///
///  Phase B — [options proposed, voting in progress]
///    • Current player: sees the options, can't vote on their own punishment
///    • Everyone else: votes for exactly one option
///    • Live vote tally shown to all
///
/// Once the vote resolves (every eligible player has voted, or the admin
/// force-resolves it), the engine transitions the turn straight into the
/// normal Dare execution flow (readingCard phase, TruthOrDareEngine.
/// _resolvePunishment) — this screen never renders an execution/outcome
/// step of its own. TodGameScreen's phase switch routes to TodCardScreen
/// once phase is no longer punishmentVoting, so punishment execution
/// (synced countdown timer, proof capture/viewing, completeTurn()/history)
/// is the exact same code path as any other Dare, not a separate one.
/// There is also no "don't do it"/"change it" outcome anymore — the vote
/// only decides *which* proposed option is performed, never whether one is;
/// punishment can never be skipped or bypassed.
class TodPunishmentScreen extends StatefulWidget {
  const TodPunishmentScreen({
    super.key,
    required this.state,
    required this.game,
    required this.displayNames,
  });

  final TodState state;
  final TodGameProvider game;
  final Map<String, String> displayNames;

  @override
  State<TodPunishmentScreen> createState() => _TodPunishmentScreenState();
}

class _TodPunishmentScreenState extends State<TodPunishmentScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _name(String id) =>
      widget.displayNames[id] ?? id.substring(0, id.length.clamp(0, 6));

  void _submit() {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty) return;
    widget.game.submitPunishment(txt);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final game = widget.game;
    final voteState = state.currentPunishmentVote;
    final myId = game.currentUserId;
    final isAdmin = game.isOwner || game.canModerate;
    final playerName = _name(state.currentPlayerId);
    final isCurrentPlayer = myId == state.currentPlayerId;

    // ── Phase B: every non-skipped player has submitted — the skipped
    // player (only) now picks one ─────────────────────────────────────────
    if (voteState != null && voteState.submissionsComplete) {
      return _VotingPhase(
        voteState: voteState,
        game: game,
        myId: myId,
        isAdmin: isAdmin,
        isCurrentPlayer: isCurrentPlayer,
        playerName: playerName,
      );
    }

    // ── Phase A: still collecting one submission per non-skipped player ────
    return _ProposePhase(
      ctrl: _ctrl,
      submittedCount: voteState?.options.length ?? 0,
      expectedCount:
          voteState?.expectedSubmissions ?? (state.playerOrder.length - 1),
      hasSubmitted: game.hasSubmittedPunishment,
      isCurrentPlayer: isCurrentPlayer,
      playerName: playerName,
      onSubmit: _submit,
    );
  }
}

// ── Phase A: every non-skipped player submits exactly one option ───────────────
class _ProposePhase extends StatelessWidget {
  const _ProposePhase({
    required this.ctrl,
    required this.submittedCount,
    required this.expectedCount,
    required this.hasSubmitted,
    required this.isCurrentPlayer,
    required this.playerName,
    required this.onSubmit,
  });
  final TextEditingController ctrl;
  final int submittedCount;
  final int expectedCount;
  final bool hasSubmitted;
  final bool isCurrentPlayer;
  final String playerName;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kNavy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kCoral.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kCoral.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      '⚡',
                      style: TextStyle(fontSize: 52),
                    ).animate().scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 400.ms,
                      curve: Curves.elasticOut,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$playerName skipped!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Time for a punishment…',
                      style: TextStyle(color: Colors.white60, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.1, end: 0),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '$submittedCount / $expectedCount submitted',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),

              if (isCurrentPlayer) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _kNavyLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Text('😬', style: TextStyle(fontSize: 44)),
                      SizedBox(height: 8),
                      Text(
                        'You skipped…',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Everyone else is picking a punishment for you.',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ] else if (hasSubmitted) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _kGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kGreen.withOpacity(0.3)),
                  ),
                  child: const Column(
                    children: [
                      Text('✅', style: TextStyle(fontSize: 36)),
                      SizedBox(height: 8),
                      Text(
                        'Submitted — waiting for everyone else…',
                        style: TextStyle(
                          color: _kGreen,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ] else ...[
                Text(
                  'Submit one punishment for $playerName:',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  maxLength: 200,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g. "Do 10 push-ups"',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: _kNavyLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: _kCoral.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: _kCoral.withOpacity(0.3)),
                    ),
                    counterStyle: const TextStyle(color: Colors.white38),
                  ),
                  maxLines: 2,
                  onSubmitted: (_) => onSubmit(),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  // Not gated on ctrl.text emptiness — this is a
                  // StatelessWidget so it wouldn't reactively re-enable on
                  // keystroke; onSubmit()'s own empty-text guard handles it.
                  onPressed: onSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kCoral,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _kCoral.withOpacity(0.3),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text(
                    'Submit',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Phase B: voting ───────────────────────────────────────────────────────────
class _VotingPhase extends StatelessWidget {
  const _VotingPhase({
    required this.voteState,
    required this.game,
    required this.myId,
    required this.isAdmin,
    required this.isCurrentPlayer,
    required this.playerName,
  });

  final TodPunishmentVoteState voteState;
  final TodGameProvider game;
  final String myId;
  final bool isAdmin, isCurrentPlayer;
  final String playerName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kCoral.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kCoral.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      isCurrentPlayer
                          ? '⚡ PICK YOUR PUNISHMENT'
                          : '⚡ ${_shortName(playerName)} IS CHOOSING…',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isCurrentPlayer
                          ? 'Everyone submitted one — pick which you\'ll do.'
                          : 'Waiting for $playerName to pick one.',
                      style: TextStyle(
                        color: _kOrange.withOpacity(0.8),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.1, end: 0),

              const SizedBox(height: 16),

              for (final option in voteState.options)
                _OptionCard(
                  option: option,
                  canPick: isCurrentPlayer,
                  onTap: () => game.voteOnPunishment(option.id),
                  onOverride: isAdmin && !isCurrentPlayer
                      ? () => game.overridePunishment(option.id)
                      : null,
                ),

              if (!isCurrentPlayer) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _kNavyLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _kYellow,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Only $playerName can pick — a moderator can force '
                          'one if they\'re unresponsive.',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _shortName(String name) =>
      name.length > 14 ? '${name.substring(0, 14)}…' : name;
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.canPick,
    required this.onTap,
    required this.onOverride,
  });
  final TodPunishment option;
  final bool canPick;
  final VoidCallback onTap;
  final VoidCallback? onOverride;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _kNavyLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: canPick ? _kCoral.withOpacity(0.4) : Colors.white12,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: canPick ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (canPick) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.white38,
                ),
              ],
              if (onOverride != null) ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(
                    Icons.bolt_rounded,
                    size: 18,
                    color: _kOrange,
                  ),
                  tooltip: 'Force this punishment',
                  onPressed: onOverride,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
