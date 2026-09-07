
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/extensions/context_ext.dart';
import '../../domain/tod_models.dart';
import '../../tod_game_provider.dart';

const _kNavy = Color(0xFF0D1B2A);
const _kNavyLight = Color(0xFF1A2E45);
const _kYellow = Color(0xFFFFD60A);
const _kCoral = Color(0xFFFF6B6B);
const _kGreen = Color(0xFF4ADE80);
const _kOrange = Color(0xFFFB923C);

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
                      context.l10n.todPlayerSkipped(playerName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.todTimeForPunishment,
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
                  context.l10n.todSubmittedCount(submittedCount, expectedCount),
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
                  child: Column(
                    children: [
                      const Text('😬', style: TextStyle(fontSize: 44)),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.todYouSkipped,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.todEveryoneElsePickingPunishment,
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
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
                  child: Column(
                    children: [
                      const Text('✅', style: TextStyle(fontSize: 36)),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.todSubmittedWaitingForOthers,
                        style: const TextStyle(
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
                  context.l10n.todSubmitPunishmentFor(playerName),
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
                  label: Text(
                    context.l10n.submit,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
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
                          context.l10n.todOnlyPlayerCanPick(playerName),
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
                  tooltip: context.l10n.todForcePunishmentTooltip,
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
