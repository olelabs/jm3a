import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jma3a/features/games/truth_or_dare/domain/tod_models.dart';
import 'package:jma3a/features/games/truth_or_dare/tod_game_provider.dart';

import '../../../../../../core/extensions/context_ext.dart';
import '../../../../../../core/theme/app_colors.dart';

/// Party-gold accent used across the ToD dark chrome (matches the in-game
/// chat sheet and punishment screen's own hardcoded accent) — kept as a
/// local const rather than a shared token since it's specific to this
/// deliberately-dark-branded game chrome, not the app's adaptive theme.
const _kPartyGold = Color(0xFFFFD60A);

/// Persistent HUD shown at the top of all gameplay screens.
/// Contains: round progress, round counter, timer badge, player count.
///
/// Deliberately dark-branded (purple → blue gradient) regardless of the
/// app's light/dark theme, matching [BrandedStatusView] and this game's own
/// punishment/chat screens — a consistent, immersive "party" chrome across
/// every ToD moment instead of flipping between light/dark per phase.
class TodHud extends StatelessWidget {
  const TodHud({
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
    final progress = state.maxRounds > 0
        ? state.roundNumber / state.maxRounds
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandPurpleDark, AppColors.brandBlueDark],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPurpleDark.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rounded progress pill instead of an edge-to-edge flat bar — a
          // small tactile touch that reads as "game" rather than "form".
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (_, value, __) => LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: Colors.white.withOpacity(0.16),
                  color: _kPartyGold,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                _RoundBadge(round: state.roundNumber, maxRound: state.maxRounds),

                // Real-device root-cause fix (missing punishment
                // indicator): reads the existing authoritative
                // GameConfig.enablePunishments the engine itself already
                // enforces (see TruthOrDareEngine._onSkip's own
                // enablePunishments branch) — this is display-only, it
                // never sets or controls anything, so there's no
                // separate punishment state to keep in sync and nothing
                // for a non-admin player to accidentally control. Placed
                // in this existing top HUD row (not a new floating
                // widget) so it survives every reconnect/next-game the
                // same way the round/timer/phase badges beside it
                // already do — all four are driven by the exact same
                // state/config the HUD already rebuilds from.
                if (game.config?.enablePunishments ?? false)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _PunishmentBadge(),
                  ),

                const Spacer(),

                if (game.timerIsRunning || game.timerRemaining > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _TimerBadge(
                      seconds: game.timerRemaining,
                    ).animate().fadeIn(),
                  ),

                _PhaseBadge(phase: state.phase),

                const SizedBox(width: 10),

                Row(
                  children: [
                    Icon(
                      Icons.people_alt_rounded,
                      size: 14,
                      color: Colors.white.withOpacity(0.75),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${state.playerOrder.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundBadge extends StatelessWidget {
  const _RoundBadge({required this.round, required this.maxRound});
  final int round;
  final int maxRound;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎲', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(
            context.l10n.todRoundBadge(round, maxRound),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only — reflects [GameConfig.enablePunishments]/[GameConfig
/// .punishmentSource] only, never sets them. The room owner changes
/// punishment settings through the existing pre-game/lobby settings flow
/// (TodPreGameConfigSheet / the lobby settings sheet), same as every
/// other GameConfig field — this badge is display-only for both admin
/// and normal players, matching the same "nothing here controls
/// anything" contract every other HUD badge (round/timer/phase/player
/// count) already follows.
class _PunishmentBadge extends StatelessWidget {
  const _PunishmentBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.warningAmber.withOpacity(0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warningAmber.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 13,
            color: AppColors.warningAmber,
          ),
          const SizedBox(width: 4),
          Text(
            context.l10n.todPunishmentModeOn,
            style: const TextStyle(
              color: AppColors.warningAmber,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseBadge extends StatelessWidget {
  const _PhaseBadge({required this.phase});
  final TodTurnPhase phase;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (phase) {
      TodTurnPhase.choosingType => (context.l10n.todPhaseChoosing, AppColors.infoBlue),
      TodTurnPhase.readingCard => (context.l10n.todPhaseInProgress, AppColors.successGreen),
      TodTurnPhase.awaitingResult => (context.l10n.todPhaseCompleting, AppColors.warningAmber),
      TodTurnPhase.punishmentVoting => (context.l10n.todPhaseVoting, AppColors.warningAmber),
      TodTurnPhase.awaitingNextTurn => (context.l10n.done, AppColors.successGreen),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _TimerBadge extends StatelessWidget {
  const _TimerBadge({required this.seconds});
  final int seconds;

  Color get _color {
    if (seconds > 30) return AppColors.successGreen;
    if (seconds > 10) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    final urgent = seconds <= 10;
    final badge = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_rounded, size: 13, color: _color),
          const SizedBox(width: 3),
          Text(
            context.l10n.gameSettingsSeconds(seconds),
            style: TextStyle(
              color: _color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    if (!urgent) return badge;

    return badge
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1.0, end: 1.08, duration: 500.ms, curve: Curves.easeInOut);
  }
}
