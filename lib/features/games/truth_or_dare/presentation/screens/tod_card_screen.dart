
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:jma3a/Sticker.dart';

import '../../../../../core/extensions/context_ext.dart';
import '../../../../../core/providers/auth_provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/app_logger.dart';
import '../../../../../shared/widgets/buttons/j_button.dart';
import '../../../../../shared/widgets/cards/user_avatar.dart';
import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
import '../../../../avatar/presentation/avatar_creator_screen.dart';
import '../../../../../../core/services/image_cache_service.dart';
import '../../data/tod_repository.dart';
import '../../domain/tod_models.dart';
import '../../tod_game_provider.dart';
import '../widgets/tod_player_banner.dart';
import '../widgets/tod_timer_ring.dart';
import '../../../../rooms/domain/room_entity.dart';
import '../../../../../shared/widgets/game/dishonest_reasons_panel.dart';
import '../../../../../shared/widgets/game/honesty_vote_buttons.dart';
import '../../../../../shared/widgets/game/responsive_game_text.dart';

/// TEMPORARY DIAGNOSTIC SWITCH — DO NOT SHIP AS true.
///
/// Flip to `true` locally (never commit as `true`) to unmount every
/// honesty-related widget from the result/reveal screen (_HonestyVoteRow,
/// DishonestReasonsPanel) while leaving everything else — including the
/// response/proof rendering itself — completely unchanged. Used to
/// isolate whether the honesty layer is involved in the "remote player
/// sees a blank result screen" report:
///   - If the remote result STILL goes blank with this set to `true`,
///     the honesty UI is conclusively NOT the cause — look at state
///     delivery/routing instead (see TOD_STATE_APPLIED/TOD_AWAITING_VIEW
///     logs, AppLogger.debug).
///   - If the remote result renders correctly with this set to `true`,
///     re-enable it and reintroduce _HonestyVoteRow and
///     DishonestReasonsPanel ONE AT A TIME (comment one back in, test,
///     repeat) to find the exact offending widget, rather than guessing.
const bool kTodDisableHonestyUiForDiagnosis = false;

/// Looks up [userId]'s CURRENT room-member row from [game.roomProvider] —
/// the SAME single source of truth the lobby (MemberTile) reads for
/// honesty_points/general_score, kept fresh by RoomProvider's own
/// profiles-CDC extension (see RoomProvider._subscribeChannel). Not
/// reactive by itself — RoomProvider is passed into TodGameScreen as a
/// plain widget field (see TodGameScreen.roomProvider), not registered
/// via Provider/InheritedWidget in this route's tree, so `context.watch`
/// would risk a ProviderNotFoundException here. Callers that need to
/// react live to a RoomProvider-only change (e.g. a vote landing while
/// this screen is open) must wrap the call site in a ListenableBuilder
/// listening to game.roomProvider directly — see TodRoomMemberBanner.
RoomMemberEntity? todRoomMemberFor(TodGameProvider game, String userId) {
  final members = game.roomProvider?.members;
  if (members == null) return null;
  for (final m in members) {
    if (m.userId == userId) return m;
  }
  return null;
}

/// Wraps [TodPlayerBanner] so it rebuilds live whenever [game.roomProvider]
/// changes (e.g. RoomProvider's profiles-CDC-triggered member refresh
/// after an honesty vote) — via a direct Listenable subscription, not
/// Provider's context lookup, since RoomProvider isn't guaranteed to be
/// registered via ChangeNotifierProvider in this route's widget tree (it's
/// passed down as a plain field — see TodGameScreen.roomProvider). Falls
/// back to a static (non-live) banner if roomProvider isn't wired at all.
class TodRoomMemberBanner extends StatelessWidget {
  const TodRoomMemberBanner({
    super.key,
    required this.game,
    required this.playerId,
    required this.playerName,
    required this.playerOrder,
    required this.isMyTurn,
  });

  final TodGameProvider game;
  final String playerId;
  final String playerName;
  final List<String> playerOrder;
  final bool isMyTurn;

  TodPlayerBanner _banner() {
    final member = todRoomMemberFor(game, playerId);
    return TodPlayerBanner(
      playerId: playerId,
      playerName: playerName,
      playerOrder: playerOrder,
      isMyTurn: isMyTurn,
      honestyPoints: member?.honestyPoints,
      generalScore: member?.generalScore,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rp = game.roomProvider;
    if (rp == null) return _banner();
    return ListenableBuilder(listenable: rp, builder: (context, _) => _banner());
  }
}

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

class _ChoiceView extends StatelessWidget {
  const _ChoiceView({
    required this.state,
    required this.game,
    required this.displayNames,
  });
  final TodState state;
  final TodGameProvider game;
  final Map<String, String> displayNames;

  // Mirrors TruthOrDareEngine._onChoice's own Force Dare check exactly —
  // this is display-only (a stale/tampered client sending 'truth' anyway
  // still gets silently converted to a dare by the authoritative engine),
  // but the UI must still reflect it: "Truth hidden or disabled, only
  // Dare available" while a limit is in effect.
  bool _isForcedDare() {
    final forceDareMode = game.config?.forceDareMode ?? 'unlimited';
    final maxTruths = game.config?.maxTruths ?? 2;
    return switch (forceDareMode) {
      'per_player' =>
        (state.truthCountByPlayer[state.currentPlayerId] ?? 0) >= maxTruths,
      'per_turn' => state.globalTruthStreak >= maxTruths,
      _ => false,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isMyTurn = game.isMyTurn;
    final playerName =
        displayNames[state.currentPlayerId] ??
        'Player ${state.currentPlayerId.substring(0, 4)}';
    final forcedDare = _isForcedDare();

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              TodRoomMemberBanner(
                game: game,
                playerId: state.currentPlayerId,
                playerName: playerName,
                playerOrder: state.playerOrder,
                isMyTurn: isMyTurn,
              ),
              const Spacer(),
              Text(
                isMyTurn
                    ? context.l10n.todChooseYourChallenge
                    : context.l10n.todPlayerIsChoosing(playerName),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn().slideY(begin: 0.08, end: 0),
              if (isMyTurn && forcedDare) ...[
                const SizedBox(height: 10),
                // Styled as an intentional "locked" chip rather than a
                // greyed-out caption — the engine forced this, so the UI
                // should read as a deliberate twist, not a disabled state.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.dareColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.dareColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔒', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          context.l10n.todForcedDareHint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.dareColor,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
              ],
              const SizedBox(height: 40),
              if (isMyTurn) ...[
                if (!forcedDare) ...[
                  _ChoiceButton(
                    label: context.l10n.todTruth,
                    emoji: '🤔',
                    color: AppColors.truthColor,
                    description: context.l10n.todTruthChoiceDescription,
                    onTap: game.chooseTruth,
                  ).animate(delay: 80.ms).fadeIn().slideX(begin: -0.08, end: 0),
                  const SizedBox(height: 16),
                ],
                _ChoiceButton(
                  label: context.l10n.todDare,
                  emoji: '🔥',
                  color: AppColors.dareColor,
                  description: context.l10n.todDareChoiceDescription,
                  onTap: game.chooseDare,
                ).animate(delay: 140.ms).fadeIn().slideX(begin: 0.08, end: 0),
              ] else
                _ChoiceWaiting(
                  playerName: playerName,
                  packCoverUrl: game.packCoverUrl,
                ),
              const Spacer(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChoiceWaiting extends StatelessWidget {
  const _ChoiceWaiting({required this.playerName, this.packCoverUrl});
  final String playerName;
  final String? packCoverUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar-first: the waiting player's identity is the primary
        // visual, not the pack artwork — makes the wait feel social
        // rather than a generic loading state.
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: context.colorScheme.primary.withOpacity(0.25),
              width: 2,
            ),
          ),
          child: UserAvatar(size: 64, displayName: playerName),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
          begin: 1.0,
          end: 1.05,
          duration: 900.ms,
          curve: Curves.easeInOut,
        ),
        const SizedBox(height: 14),
        const _PulsingDots(),
        const SizedBox(height: 12),
        Text(
          context.l10n.todChoosingTruthOrDare(playerName),
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 84,
            height: 52,
            child: ImageCacheService.instance.packCover(
              url: packCoverUrl,
              width: 84,
              height: 52,
            ),
          ),
        ).animate(delay: 120.ms).fadeIn(),
        const SizedBox(height: 4),
        Text(
          context.l10n.appName,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant.withOpacity(0.5),
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PulsingDots extends StatelessWidget {
  const _PulsingDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: context.colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ).animate(onPlay: (c) => c.repeat(), delay: (i * 160).ms).scaleXY(
          begin: 0.6,
          end: 1.0,
          duration: 480.ms,
          curve: Curves.easeInOut,
        ).then().scaleXY(begin: 1.0, end: 0.6, duration: 480.ms);
      }),
    );
  }
}

class _ChoiceButton extends StatefulWidget {
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
  State<_ChoiceButton> createState() => _ChoiceButtonState();
}

class _ChoiceButtonState extends State<_ChoiceButton> {
  // Passive press-scale feedback. Listener (not a second GestureDetector)
  // so it never competes with InkWell's own gesture recognizer below — the
  // actual tap/onTap call is entirely untouched.
  double _scale = 1.0;

  void _setPressed(bool pressed) {
    if (!mounted) return;
    setState(() => _scale = pressed ? 0.96 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label;
    final emoji = widget.emoji;
    final color = widget.color;
    final description = widget.description;
    final onTap = widget.onTap;
    // Presentation redesign only — [onTap] (chooseTruth / chooseDare) is
    // unchanged, still the sole action.
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.36),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: Colors.white.withValues(alpha: 0.18),
          highlightColor: Colors.white.withValues(alpha: 0.06),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.78)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              child: Row(
                children: [
                  // Frosted circular emoji badge for a stronger, tactile
                  // party-game feel.
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 34)),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.25,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
        ),
      ),
    );
  }
}

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
      return Center(child: Text(context.l10n.todNoCardAvailable));
    }

    final isSpicy = card.difficulty == TodDifficulty.spicy;
    final isTruth = card.type == TodCardType.truth;
    final cardColor = isTruth ? AppColors.truthColor : AppColors.dareColor;
    final playerName =
        displayNames[state.currentPlayerId] ??
        context.l10n.todDefaultPlayerNumbered(state.currentPlayerId.substring(0, 4));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TodRoomMemberBanner(
            game: game,
            playerId: state.currentPlayerId,
            playerName: playerName,
            playerOrder: state.playerOrder,
            isMyTurn: isMyTurn,
          ),
          const SizedBox(height: 12),
          if (game.timerIsRunning || game.timerRemaining > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TodTimerRing(
                remaining: game.timerRemaining,
                total: game.state != null ? (80) : 60,
                color: cardColor,
              ).animate().fadeIn(),
            ),
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
          if (isMyTurn) ...[
            JButton(
              label: context.l10n.todDoneButton,
              onPressed: () =>
                  _showCompleteSheet(context, game, isTruth: isTruth),
            ),
            // Previously shown unconditionally — the room's "Allow Skip"
            // setting was persisted but never actually consulted anywhere.
            //
            // Real-device root-cause fix (player Skip regression): this
            // used to ALSO require enablePunishments, hiding Skip
            // entirely for any room with allowSkip=true but punishments
            // OFF (a normal, common configuration — plenty of rooms use
            // plain skip with no punishment consequence at all). The
            // engine's own authoritative gate (TruthOrDareEngine
            // ._onSkip: `if (!isTimeout && !_config.allowSkip) return
            // _state;`) has never depended on enablePunishments — only
            // this UI condition invented that extra requirement, so it
            // was silently hiding a button the engine would have
            // accepted. allowSkip alone is the complete, correct
            // condition, matching the engine exactly.
            if (game.config?.allowSkip ?? true) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => _confirmSkip(context),
                child: Text(
                  context.l10n.skip,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ] else
            _PeerActivityIndicator(
              playerName: playerName,
              activity: game.peerActivityLabel,
            ),
          if (game.canAdvanceTurnHere && !isMyTurn)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextButton.icon(
                // Gated on canAdvanceTurnHere (advance_turn/skip_turn
                // specifically), not the broader canModerate — a moderator
                // with neither permission previously still saw this button,
                // but tapping it was a silent no-op since the owner-side
                // check already required one of those two keys. Delegates
                // to the owner's client if the presser isn't the owner — a
                // direct game.ownerAdvanceTurn call here would silently
                // no-op for a non-owner moderator.
                onPressed: () => game.requestAdvanceTurn(force: true),
                icon: const Icon(Icons.skip_next_rounded, size: 16),
                label: Text(context.l10n.todSkipTurnMod),
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
    // Previously only enforced at final submit (_handleAction's
    // isGameMuted check) — a muted player could still open this sheet,
    // record voice/take a photo, and fill in a full proof before being
    // silently blocked at the very last step. Gating at the entry point
    // instead makes the mute immediately visible, matching every other
    // muted-channel gate in this app (chat input, reactions).
    if (game.roomProvider?.currentMember?.isGameMuted ?? false) {
      context.showSnackBar(context.l10n.chatMuted, isError: true);
      return;
    }
    final ctrl = TextEditingController();
    String? imgB64;
    bool attempted = false;

    // Proof visibility: chosen HERE, before the proof is ever submitted —
    // not configurable afterward. Defaults to the room's own
    // proofVisibilityPolicy setting (unchanged behavior for anyone who
    // doesn't touch it), but is now an explicit, per-submission choice.
    TodProofVisibility selectedVisibility = switch (game.config?.proofVisibilityPolicy) {
      'players_only' => TodProofVisibility.playersOnly,
      'spectators_only' => TodProofVisibility.spectatorsOnly,
      _ => TodProofVisibility.everyone,
    };
    final selectedUserIds = <String>{};
    bool visibilityAttempted = false;

    // Image proof viewing timer — ONLY relevant for image proof (item 4).
    // 'No limit' (the current default) maps to TodProofViewMode.once;
    // a chosen duration maps to TodProofViewMode.timed. Voice proof never
    // reads either of these (see _ProofViewer — the auto-close Timer only
    // ever exists inside its imageB64.isNotEmpty branch), and Truth has no
    // proof at all, so neither is ever shown/relevant there.
    TodProofViewMode selectedViewMode = TodProofViewMode.once;
    int selectedViewSeconds = 5;

    Uint8List? voiceBytes;
    bool isRecording = false;
    final recorder = AudioRecorder();
    bool recorderDisposed = false;
    void safeDisposeRecorder() {
      if (recorderDisposed) return;
      recorderDisposed = true;
      recorder.dispose().catchError((_) {});
    }

    Timer? recordingTimer;
    int recordingSeconds = 0;
    final isPremium =
        context.read<AuthProvider>().currentUser?.isPremiumActive ?? false;
    final maxRecordSeconds = isPremium ? 60 : 30;

    game.pauseTimer();
    game.broadcastActivity('answering');

    Future<void> stopRecording(StateSetter setS) async {
      recordingTimer?.cancel();
      final path = await recorder.stop();
      if (path == null) return;
      await Future.delayed(const Duration(milliseconds: 300));
      final file = File(path);
      if (!await file.exists()) return;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;
      setS(() {
        voiceBytes = bytes;
        isRecording = false;
        recordingSeconds = 0;
      });
    }

    Future<void> startRecording(StateSetter setS) async {
      if (!await recorder.hasPermission()) return;
      game.broadcastActivity('uploading_proof');
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/proof_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
        ),
        path: path,
      );
      recordingSeconds = 0;
      setS(() {
        isRecording = true;
        imgB64 = null;
      });
      recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        recordingSeconds++;
        setS(() {});
        if (recordingSeconds >= maxRecordSeconds) stopRecording(setS);
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          return PopScope(
            onPopInvoked: (_) {
              recordingTimer?.cancel();
              safeDisposeRecorder();
            },
            child: Padding(
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
                child: SingleChildScrollView(
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
                            isTruth ? ctx.l10n.todTypeTruth : ctx.l10n.todTypeDare,
                            style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                              color: isTruth
                                  ? AppColors.truthColor
                                  : AppColors.dareColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ctx.l10n.todCompleteTurn,
                            style: Theme.of(ctx).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: ctrl,
                        maxLines: 3,
                        maxLength: 300,
                        decoration: InputDecoration(
                          hintText: isTruth
                              ? ctx.l10n.todAnswerRequiredHint
                              : ctx.l10n.todAddDescriptionOptional,
                          border: const OutlineInputBorder(),
                          errorText:
                              isTruth && ctrl.text.trim().isEmpty && attempted
                              ? ctx.l10n.todTruthRequiresResponse
                              : (!isTruth &&
                                    attempted &&
                                    ctrl.text.trim().isEmpty &&
                                    imgB64 == null &&
                                    voiceBytes == null)
                              ? ctx.l10n.todDareRequiresResponseOrProof
                              : null,
                        ),
                        onChanged: (_) => setS(() {}),
                      ),
                      const SizedBox(height: 8),
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
                        else if (voiceBytes != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.purple.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.purple,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    ctx.l10n.todVoiceProofRecorded,
                                    style: const TextStyle(
                                      color: Colors.purple,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: ctx.l10n.preview,
                                  icon: const Icon(
                                    Icons.play_circle_outline,
                                    color: Colors.purple,
                                  ),
                                  onPressed: () => showModalBottomSheet(
                                    context: ctx,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => _VoicePlayerSheet(
                                      voiceB64: base64Encode(voiceBytes!),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  onPressed: () =>
                                      setS(() => voiceBytes = null),
                                ),
                              ],
                            ),
                          )
                        else if (isRecording)
                          _RecordingWidget(
                            seconds: recordingSeconds,
                            maxSeconds: maxRecordSeconds,
                            onStop: () => stopRecording(setS),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    try {
                                      game.broadcastActivity(
                                        'uploading_proof',
                                      );
                                      final picked = await ImagePicker()
                                          .pickImage(
                                            source: ImageSource.gallery,
                                            imageQuality: 40,
                                          );
                                      if (picked != null) {
                                        final bytes = await picked
                                            .readAsBytes();
                                        setS(
                                          () => imgB64 = base64Encode(bytes),
                                        );
                                      }
                                    } catch (_) {}
                                  },
                                  icon: const Icon(
                                    Icons.add_photo_alternate_outlined,
                                  ),
                                  label: Text(ctx.l10n.photo),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => startRecording(setS),
                                  icon: const Icon(Icons.mic_outlined),
                                  label: Text(
                                    ctx.l10n.todVoiceMaxSeconds(maxRecordSeconds),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),
                      ],
                      // Proof options — visibility + (image-only) viewing
                      // timer — are only relevant for a Dare; Truth has no
                      // proof at all (item 2).
                      if (!isTruth) ...[
                        const SizedBox(height: 12),
                        _ProofVisibilitySelector(
                          selected: selectedVisibility,
                          selectedUserIds: selectedUserIds,
                          members: game.roomProvider?.members ?? const [],
                          currentUserId: game.currentUserId,
                          showMissingSelectionError:
                              visibilityAttempted &&
                              selectedVisibility ==
                                  TodProofVisibility.selectedPlayers &&
                              selectedUserIds.isEmpty,
                          onVisibilityChanged: (v) => setS(() {
                            selectedVisibility = v;
                            visibilityAttempted = false;
                          }),
                          onToggleUser: (id) => setS(() {
                            if (!selectedUserIds.remove(id)) {
                              selectedUserIds.add(id);
                            }
                          }),
                        ),
                        if (imgB64 != null) ...[
                          const SizedBox(height: 12),
                          _ProofTimerSelector(
                            mode: selectedViewMode,
                            seconds: selectedViewSeconds,
                            onChanged: (mode, seconds) => setS(() {
                              selectedViewMode = mode;
                              selectedViewSeconds = seconds;
                            }),
                          ),
                        ],
                      ],
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          if (isTruth && ctrl.text.trim().isEmpty) {
                            setS(() => attempted = true);
                            return;
                          }
                          // A dare (including a resolved punishment) needs
                          // SOME meaningful content — a real response or
                          // proof attached — not neither, closing what was
                          // previously a fully-optional submission. The
                          // server-side engine enforces the identical rule
                          // (see TruthOrDareEngine._onComplete) so a
                          // modified client sending the broadcast directly
                          // can't bypass this UI-only check.
                          if (!isTruth &&
                              ctrl.text.trim().isEmpty &&
                              imgB64 == null &&
                              voiceBytes == null) {
                            setS(() => attempted = true);
                            return;
                          }
                          // If the group voted a specific proof type
                          // mandatory for this turn, it must be attached
                          // regardless of the response text.
                          final requiredProof =
                              game.state?.proofVoteState?.winner;
                          if (requiredProof == TodProofVoteOption.voiceProof &&
                              voiceBytes == null) {
                            context.showSnackBar(
                              ctx.l10n.todProofVoteRequiresVoice,
                              isError: true,
                            );
                            return;
                          }
                          if (requiredProof == TodProofVoteOption.imageProof &&
                              imgB64 == null) {
                            context.showSnackBar(
                              ctx.l10n.todProofVoteRequiresImage,
                              isError: true,
                            );
                            return;
                          }
                          if (!isTruth &&
                              selectedVisibility ==
                                  TodProofVisibility.selectedPlayers &&
                              selectedUserIds.isEmpty) {
                            setS(() => visibilityAttempted = true);
                            return;
                          }
                          final voiceB64 = voiceBytes != null
                              ? base64Encode(voiceBytes!)
                              : '';
                          // No proof at all for Truth, or a Dare with just
                          // voice/no attachment: no viewing timer applies —
                          // 'once' is the same "no auto-close" default the
                          // image-timer picker's own 'No limit' option maps
                          // to, so this is a no-op either way.
                          final viewMode = (!isTruth && imgB64 != null)
                              ? selectedViewMode
                              : TodProofViewMode.once;
                          final viewSeconds = (!isTruth && imgB64 != null)
                              ? selectedViewSeconds
                              : 5;
                          final visibility = isTruth
                              ? const TodProofVisibilitySettings()
                              : TodProofVisibilitySettings(
                                  visibility: selectedVisibility,
                                  visibleToIds: selectedUserIds.toList(),
                                );
                          recordingTimer?.cancel();
                          safeDisposeRecorder();
                          Navigator.of(ctx).pop();
                          // Purely visual, non-blocking reward moment — does
                          // not delay or gate the actual submission below.
                          _showSuccessBurst(context);
                          game.broadcastActivity('waiting_for_approval');
                          // Server-authoritative record of THIS turn's proof
                          // visibility + viewing rules — record_proof_view
                          // checks this (not the shared broadcast state, and
                          // not the old room-wide default) so a reconnecting
                          // viewer can't get a fresh/looser grant just by
                          // reconnecting. Fire-and-forget: a failure here
                          // only means record_proof_view falls back to the
                          // old room-level policy for this turn, it never
                          // blocks the actual submission below.
                          if (!isTruth && state.turnStartedAt != null) {
                            game
                                .saveProofMetadata(
                                  turnStartedAt: state.turnStartedAt!,
                                  visibility: visibility,
                                  viewMode: viewMode,
                                  viewSeconds: viewSeconds,
                                )
                                .ignore();
                          }
                          game.completeTurn(
                            response: ctrl.text.trim(),
                            proofImageB64: imgB64 ?? '',
                            proofVoiceB64: voiceB64,
                            proofViewSeconds: viewSeconds,
                            proofViewMode: viewMode,
                            proofVisibility: visibility,
                          );
                        },
                        child: Text(ctx.l10n.todSubmitCompleteTurn),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () {
                          recordingTimer?.cancel();
                          safeDisposeRecorder();
                          Navigator.of(ctx).pop();
                        },
                        child: Text(ctx.l10n.cancel),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ).then((_) {
      game.resumeTimer();
    });
  }

  Future<void> _confirmSkip(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: context.l10n.todSkipCardConfirmTitle,
      message: context.l10n.todSkipCardConfirmBody,
      confirmLabel: context.l10n.skip,
    );
    if (confirmed == true) game.skipTurn();
  }

  /// Brief, non-blocking "nice one!" flourish shown right after a turn is
  /// submitted — purely cosmetic (an [OverlayEntry] that removes itself),
  /// no effect on [game.completeTurn] or the turn/phase state machine.
  void _showSuccessBurst(BuildContext context) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: Center(
          child: Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.successGreen.withValues(alpha: 0.16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.successGreen.withValues(alpha: 0.35),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Text('✅', style: TextStyle(fontSize: 44)),
          )
              .animate()
              .scale(
                begin: const Offset(0.4, 0.4),
                end: const Offset(1, 1),
                duration: 320.ms,
                curve: Curves.elasticOut,
              )
              .then(delay: 400.ms)
              .fadeOut(duration: 260.ms),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 1000), entry.remove);
  }
}

/// Proof visibility picker shown INSIDE the complete-turn sheet, above the
/// Submit button — the choice is attached to the submission itself
/// (TodProofVisibilitySettings passed to completeTurn), never configurable
/// after the fact.
class _ProofVisibilitySelector extends StatelessWidget {
  const _ProofVisibilitySelector({
    required this.selected,
    required this.selectedUserIds,
    required this.members,
    required this.currentUserId,
    required this.showMissingSelectionError,
    required this.onVisibilityChanged,
    required this.onToggleUser,
  });

  final TodProofVisibility selected;
  final Set<String> selectedUserIds;
  final List<RoomMemberEntity> members;
  final String currentUserId;
  final bool showMissingSelectionError;
  final ValueChanged<TodProofVisibility> onVisibilityChanged;
  final ValueChanged<String> onToggleUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Only currently-present members can be picked — excludes the
    // submitter themself (nothing to choose there) and anyone
    // disconnected/gone (kicked/banned/left), matching every other
    // member-picker in this app (RoomMembersFab, moderation sheets).
    final eligibleMembers = members
        .where(
          (m) =>
              m.userId != currentUserId &&
              !m.isDisconnected &&
              !m.leftDefinitively,
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.todProofVisibilityLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _VisibilityChip(
              label: context.l10n.todProofVisibilityEveryone,
              icon: Icons.public_rounded,
              isSelected: selected == TodProofVisibility.everyone,
              onTap: () => onVisibilityChanged(TodProofVisibility.everyone),
            ),
            _VisibilityChip(
              label: context.l10n.todProofVisibilityPlayersOnly,
              icon: Icons.groups_rounded,
              isSelected: selected == TodProofVisibility.playersOnly,
              onTap: () =>
                  onVisibilityChanged(TodProofVisibility.playersOnly),
            ),
            _VisibilityChip(
              label: context.l10n.todProofVisibilitySpectatorsOnly,
              icon: Icons.visibility_rounded,
              isSelected: selected == TodProofVisibility.spectatorsOnly,
              onTap: () =>
                  onVisibilityChanged(TodProofVisibility.spectatorsOnly),
            ),
            _VisibilityChip(
              label: context.l10n.todProofVisibilityPersonalized,
              icon: Icons.person_search_rounded,
              isSelected: selected == TodProofVisibility.selectedPlayers,
              onTap: () =>
                  onVisibilityChanged(TodProofVisibility.selectedPlayers),
            ),
          ],
        ),
        if (selected == TodProofVisibility.selectedPlayers) ...[
          const SizedBox(height: 12),
          if (eligibleMembers.isEmpty)
            Text(
              context.l10n.todProofVisibilityNoOneElse,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: eligibleMembers
                  .map(
                    (m) => _MemberPickChip(
                      member: m,
                      isSelected: selectedUserIds.contains(m.userId),
                      onTap: () => onToggleUser(m.userId),
                    ),
                  )
                  .toList(),
            ),
          if (showMissingSelectionError) ...[
            const SizedBox(height: 6),
            Text(
              context.l10n.todProofVisibilityPickAtLeastOne,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _VisibilityChip extends StatelessWidget {
  const _VisibilityChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.14)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One selectable member in the Personalized picker — a checkmark badge
/// plus a colored border/fill make the selected state visually obvious at
/// a glance, not just a subtle tint.
class _MemberPickChip extends StatelessWidget {
  const _MemberPickChip({
    required this.member,
    required this.isSelected,
    required this.onTap,
  });

  final RoomMemberEntity member;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.16)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatar(
                  size: 26,
                  displayName: member.displayName,
                  avatarUrl: member.avatarUrl,
                  avatarConfig: member.avatarConfig,
                  isPremium: member.isPremium,
                ),
                if (isSelected)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 9,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              member.displayName,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
            if (member.isSpectator) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.visibility_outlined,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Image-proof-only viewing-duration picker (item 4) — chosen by the
/// submitter before pressing Done, attached to the submission itself.
/// Never shown for voice proof or Truth (see call site).
class _ProofTimerSelector extends StatelessWidget {
  const _ProofTimerSelector({
    required this.mode,
    required this.seconds,
    required this.onChanged,
  });

  final TodProofViewMode mode;
  final int seconds;
  final void Function(TodProofViewMode mode, int seconds) onChanged;

  static const _durations = [3, 5, 10, 15];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.todProofTimerLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _VisibilityChip(
              label: context.l10n.todProofTimerNoLimit,
              icon: Icons.all_inclusive_rounded,
              isSelected: mode == TodProofViewMode.once,
              onTap: () => onChanged(TodProofViewMode.once, seconds),
            ),
            for (final d in _durations)
              _VisibilityChip(
                label: '${d}s',
                icon: Icons.timer_outlined,
                isSelected: mode == TodProofViewMode.timed && seconds == d,
                onTap: () => onChanged(TodProofViewMode.timed, d),
              ),
          ],
        ),
      ],
    );
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
    final cardVisual = ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: cardColor.withOpacity(0.55), width: 1.5),
          boxShadow: [
            // Wide, soft ambient glow in the card's own color — the "premium
            // object under a spotlight" depth cue.
            BoxShadow(
              color: cardColor.withOpacity(0.30),
              blurRadius: 40,
              spreadRadius: -4,
              offset: const Offset(0, 14),
            ),
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
            Positioned.fill(child: CustomPaint(painter: _CardShimmerPainter())),
            // Glossy top highlight — a soft diagonal sheen suggesting a
            // lacquered/foil card surface rather than a flat colored panel.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.14),
                        Colors.white.withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.5],
                    ),
                  ),
                ),
              ),
            ),
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
    )
        // Reveal entrance: pop in, then a single light sweep across the
        // face — makes a fresh card feel like it was just dealt, without
        // looping into something distracting.
        .animate()
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          duration: 320.ms,
          curve: Curves.easeOutBack,
        )
        .shimmer(
          delay: 280.ms,
          duration: 900.ms,
          color: Colors.white.withOpacity(0.22),
        );

    if (!isSpicy) return cardVisual;

    // Spicy cards get a slow, low-amplitude glow pulse on top of the base
    // shadow — a small "this one's hotter" cue, not a new interaction.
    return cardVisual
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .boxShadow(
          begin: BoxShadow(
            color: AppColors.spicyColor.withOpacity(0.0),
            blurRadius: 0,
            spreadRadius: 0,
          ),
          end: BoxShadow(
            color: AppColors.spicyColor.withOpacity(0.45),
            blurRadius: 30,
            spreadRadius: 2,
          ),
          duration: 1400.ms,
          curve: Curves.easeInOut,
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
      child: Text(
        context.l10n.todSpicyBadge,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Renders the acting player's live activity ("Ahmed is answering…") when a
/// `tod_player_activity` broadcast has arrived for this turn, falling back
/// to the previous plain "is performing…" text when nothing has been
/// reported yet (e.g. right at turn start, before the first broadcast).
class _PeerActivityIndicator extends StatelessWidget {
  const _PeerActivityIndicator({required this.playerName, this.activity});
  final String playerName;
  final String? activity;

  String _label(BuildContext context) => switch (activity) {
    'answering' => context.l10n.todActivityAnswering(playerName),
    'uploading_proof' => context.l10n.todActivityUploadingProof(playerName),
    'waiting_for_approval' => context.l10n.todActivityFinishingUp(playerName),
    'choosing' => context.l10n.todActivityChoosing(playerName),
    _ => context.l10n.todActivityPerforming(playerName),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserAvatar(size: 24, displayName: playerName),
          const SizedBox(width: 8),
          Text(
            _label(context),
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (activity != null) ...[
            const SizedBox(width: 8),
            const _PulsingDots(),
          ],
        ],
      ),
    ).animate().fadeIn();
  }
}

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
        title: Text(context.l10n.todEndGameTitle),
        content: Text(context.l10n.todEndGameBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
            child: Text(context.l10n.todEndGame),
          ),
        ],
      ),
    );
    if (confirmed == true) game.requestEndGame();
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

    // Diagnostic instrumentation for the "remote player sees a blank
    // result screen" report — AppLogger.debug is compiled to a no-op
    // level in production (see AppLogger._logLevel), so this is safe to
    // leave in; it only ever prints in development builds. Logs no proof
    // CONTENT (image/voice bytes), only presence booleans and identity/
    // phase metadata, on every build of this view (both the owner's own
    // build, isOwner:true, and every other client's build, isOwner:
    // false) so the two can be diffed side by side across two real
    // devices to see whether the REMOTE client's state genuinely lacks
    // the response, or has it but fails to render it.
    AppLogger.debug(
      'TOD_AWAITING_VIEW isOwner=${game.isOwner} '
      'hasSyncedState=${game.hasSyncedState} '
      'localPlayerId=${game.currentUserId} '
      'currentTurnPlayerId=${state.currentPlayerId} isMyTurn=$isMyTurn '
      'round=${state.roundNumber} phase=${state.phase.name} '
      'snapshotAt=${state.snapshotAt} '
      'responseType=${state.currentCard?.type.name ?? 'none'} '
      'isPunishment=${state.currentCard?.id.startsWith('punishment_') ?? false} '
      'hasTurnResponse=${state.turnResponse.isNotEmpty} '
      'hasTurnProofImage=${state.turnProofImageB64.isNotEmpty} '
      'hasTurnProofVoice=${state.turnProofVoiceB64.isNotEmpty}',
    );

    final reactTally = <String, int>{};
    for (final r in state.currentReactions) {
      reactTally[r.emoji] = (reactTally[r.emoji] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.ownerBadge.withValues(alpha: 0.12),
                  theme.colorScheme.surfaceContainerHighest,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.ownerBadge.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 44))
                    .animate()
                    .scale(
                      begin: const Offset(0.3, 0.3),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: 8),
                Text(
                  _name(state.currentPlayerId),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  context.l10n.todCompletedTurn,
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
                    // Item 18.3 — the answer itself is the whole point of
                    // this reveal moment, so it gets large/expressive
                    // treatment (scaling down only if genuinely long)
                    // instead of the old muted bodyMedium italic.
                    child: ResponsiveGameText(
                      context.l10n.todQuotedResponse(state.turnResponse),
                      textAlign: TextAlign.center,
                      maxLines: 5,
                      style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                          ) ??
                          const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                ],
                if ((state.turnHasVoiceProof ||
                        state.turnProofImageB64.isNotEmpty) &&
                    state.turnProofVisibility.canView(
                      game.currentUserId,
                      game.roomProvider?.currentMember?.isSpectator ?? false,
                    )) ...[
                  const SizedBox(height: 12),
                  _ProofViewer(
                    imageB64: state.turnHasVoiceProof
                        ? ''
                        : state.turnProofImageB64,
                    voiceB64: state.turnHasVoiceProof
                        ? state.turnProofVoiceB64
                        : '',
                    myUserId: game.currentUserId,
                    viewedByMap: state.turnProofViewedBy,
                    onOpened: game.markProofViewed,
                    viewMode: state.turnProofViewMode,
                    viewSeconds: state.turnProofViewSeconds,
                    // Premium viewers get one extra replay beyond whatever
                    // the room's own setting allows.
                    isPremium:
                        context.read<AuthProvider>().currentUser?.isPremiumActive ??
                        false,
                    sessionId: game.sessionId,
                    turnStartedAt: state.turnStartedAt,
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final myAvatarConfig = context
                  .watch<AuthProvider>()
                  .currentUser
                  ?.avatarConfig;
              return EmojiReactionRow(
                reactionsByEmoji: reactTally,
                // The tally row (reactionsByEmoji) is always shown
                // regardless of who's viewing — only the "add a reaction"
                // picker is gated on not-already-reacted AND not the
                // player whose own turn this is (matches the previous
                // inline `!myReacted && !isMyTurn` gate exactly).
                alreadyReacted: myReacted || isMyTurn,
                onReact: game.reactToResponse,
                useAvatarMode:
                    context.watch<AuthProvider>().currentUser?.isPremiumActive ==
                    true,
                ownAvatarConfig: myAvatarConfig,
                avatarConfigByValue: {
                  for (final k in reactTally.keys)
                    if (AvatarConfig.isAvatarReaction(k)) k: myAvatarConfig,
                },
              );
            },
          ),
          if (reactTally.isNotEmpty || (!myReacted && !isMyTurn))
            const SizedBox(height: 8),
          if (!isMyTurn && state.turnResponse.isNotEmpty) ...[
            if (!myVoted)
              OutlinedButton.icon(
                onPressed: game.voteForResponse,
                icon: const Icon(Icons.thumb_up_outlined, size: 16),
                label: Text(
                  context.l10n.todLikedResponseVotes(state.currentVotes.length),
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
                  context.l10n.todVotedForResponseTotal(state.currentVotes.length),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.successGreen,
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
          if (!isMyTurn && !kTodDisableHonestyUiForDiagnosis)
            _HonestyVoteRow(
              game: game,
              targetUserId: state.currentPlayerId,
              roundNumber: state.roundNumber,
              participantIds: state.playerOrder,
            ),
          if (isMyTurn && !kTodDisableHonestyUiForDiagnosis)
            DishonestReasonsPanel(
              fetch: game.getMyDishonestReasons,
              // Keyed on the round (fresh fetch per turn) AND on the live
              // dishonest-reason generation counter (item: instant reveal)
              // — a 'dishonest_reason_added' realtime signal bumps the
              // generation, which changes this Key, which makes Flutter
              // recreate the panel's State and re-run its one-shot fetch.
              // No stream/poll inside the panel itself — see
              // TodGameProvider.onDishonestReasonAdded.
              key: ValueKey(
                'dishonest_reasons_${state.roundNumber}_'
                '${game.dishonestReasonGeneration('round:${state.roundNumber}')}',
              ),
            ),
          _ScoreSummary(state: state, displayNames: displayNames),
          const SizedBox(height: 20),
          if (game.isOwner || game.canAdvanceTurnHere) ...[
            if (game.canAdvanceTurnHere) ...[
              if (!game.allOthersReady) ...[
                Builder(
                  builder: (context) {
                    final waitingOn = state.playerOrder
                        .where(
                          (id) =>
                              id != game.currentUserId &&
                              !game.readyForNext.contains(id),
                        )
                        .map(_name)
                        .toList();
                    return Text(
                      context.l10n.todWaitingForToFinishReading(waitingOn.join(', ')),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
              JButton(
                label: context.l10n.todNextTurn,
                onPressed: game.allOthersReady
                    ? () => game.requestAdvanceTurn()
                    : null,
                icon: Icons.skip_next_rounded,
              ).animate(delay: 250.ms).fadeIn(),
              const SizedBox(height: 6),
            ],
            if (game.isOwner)
              Builder(
                builder: (ctx) {
                  final isPremium =
                      ctx.read<AuthProvider>().currentUser?.isPremium ?? false;
                  if (!isPremium) return const SizedBox.shrink();
                  return TextButton.icon(
                    onPressed: () => _showAddCustomCardSheet(ctx, game),
                    icon: const Icon(Icons.add_card_outlined, size: 16),
                    label: Text(ctx.l10n.todAddCustomCardButton),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  );
                },
              ),
            if (game.isOwner)
              TextButton(
                onPressed: () => _confirmEndGame(context),
                child: Text(context.l10n.todEndGame),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.errorRed,
                ),
              ),
          ] else if (!state.playerOrder.contains(game.currentUserId))
            Text(
              context.l10n.todSpectatingWaitingHost,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ).animate().fadeIn()
          else if (game.hasMarkedReady)
            Text(
              context.l10n.todReadyWaitingHost,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.successGreen,
              ),
            ).animate().fadeIn()
          else
            JButton(
              label: context.l10n.todReadyForNextTurn,
              onPressed: game.markReadyForNext,
              icon: Icons.check_circle_outline_rounded,
            ).animate().fadeIn(),
        ],
      ),
    );
  }

  void _showAddCustomCardSheet(BuildContext ctx, TodGameProvider game) {
    TodCardType selectedType = TodCardType.truth;
    TodDifficulty selectedDifficulty = TodDifficulty.mild;
    final ctrl = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(sheetCtx).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_card_outlined),
                    const SizedBox(width: 8),
                    Text(
                      sheetCtx.l10n.todAddCustomCardTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      sheetCtx.l10n.premiumBadge,
                      style: const TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  sheetCtx.l10n.todCustomCardSessionOnly,
                  style: Theme.of(sheetCtx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(sheetCtx).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<TodCardType>(
                  segments: [
                    ButtonSegment(
                      value: TodCardType.truth,
                      label: Text(sheetCtx.l10n.todTruth),
                      icon: const Icon(Icons.lightbulb_outline),
                    ),
                    ButtonSegment(
                      value: TodCardType.dare,
                      label: Text(sheetCtx.l10n.todDare),
                      icon: const Icon(Icons.local_fire_department_outlined),
                    ),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (v) => setS(() => selectedType = v.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  maxLength: 300,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: sheetCtx.l10n.todWriteCardPromptHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<TodDifficulty>(
                  value: selectedDifficulty,
                  decoration: InputDecoration(
                    labelText: sheetCtx.l10n.todDifficultyLabel,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: TodDifficulty.values.map((d) {
                    return DropdownMenuItem(
                      value: d,
                      child: Text(
                        d.name[0].toUpperCase() + d.name.substring(1),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setS(() => selectedDifficulty = v!),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          if (ctrl.text.trim().length < 5) return;
                          setS(() => submitting = true);
                          final result = await game.addCustomCard(
                            type: selectedType,
                            content: ctrl.text.trim(),
                            difficulty: selectedDifficulty,
                          );
                          if (sheetCtx.mounted) {
                            Navigator.of(sheetCtx).pop();
                            if (!result.success && ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(switch (result.error) {
                                    'game_not_started_yet' =>
                                      ctx.l10n.gameNotStartedYet,
                                    'game_not_ready' => ctx.l10n.gameNotReady,
                                    _ => result.error ?? ctx.l10n.failed,
                                  }),
                                ),
                              );
                            } else if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(ctx.l10n.todCustomCardAdded),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(sheetCtx.l10n.todAddCardToDeck),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Honest/Not-honest voting on the just-completed response — shared
/// mechanism (see HonestyVoteRepository) also used by NHIE and Meme Game.
/// Reduced to a no-op empty widget for anyone ineligible (self, spectator,
/// already voted) rather than showing disabled buttons — matches "no
/// exposed internal scoring mechanics": nobody sees point values here.
class _HonestyVoteRow extends StatelessWidget {
  const _HonestyVoteRow({
    required this.game,
    required this.targetUserId,
    required this.roundNumber,
    required this.participantIds,
  });
  final TodGameProvider game;
  final String targetUserId;
  final int roundNumber;
  final List<String> participantIds;

  @override
  Widget build(BuildContext context) {
    final responseKey = 'round:$roundNumber';
    return HonestyVoteRow(
      voterId: game.currentUserId,
      targetUserId: targetUserId,
      participantIds: participantIds,
      hasVoted: game.hasVotedHonesty(responseKey, targetUserId),
      onVote: ({required targetUserId, required isHonest, reason}) =>
          game.castHonestyVote(
            targetUserId: targetUserId,
            isHonest: isHonest,
            reason: reason,
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
            context.l10n.todDefaultPlayerNumbered(score.userId.substring(0, 4));
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(medal, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(child: Text(name, style: context.textTheme.bodyMedium)),
              Text(
                context.l10n.todPointsAbbrev(score.points),
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

/// Generic, type-agnostic proof indicator shown for a completed turn's
/// proof — whichever of [imageB64]/[voiceB64] is non-empty determines what
/// opening it does, but the pre-open appearance is identical either way so
/// nobody (sender included) can tell image vs. voice, or who has opened it,
/// before they open it themselves. Each user gets exactly one open, tracked
/// via [viewedByMap] (shared game state, so the "viewed" flag survives
/// rebuilds/reconnects instead of resetting like plain widget state would).
class _ProofViewer extends StatefulWidget {
  const _ProofViewer({
    required this.imageB64,
    required this.voiceB64,
    required this.myUserId,
    required this.viewedByMap,
    required this.onOpened,
    this.viewMode = TodProofViewMode.once,
    this.viewSeconds = 5,
    this.isPremium = false,
    this.sessionId,
    this.turnStartedAt,
  });
  final String imageB64;
  final String voiceB64;
  final String myUserId;
  final Map<String, int> viewedByMap;
  final VoidCallback onOpened;
  final TodProofViewMode viewMode;
  final int viewSeconds;
  final bool isPremium;
  final String? sessionId;
  final int? turnStartedAt;

  @override
  State<_ProofViewer> createState() => _ProofViewerState();
}

class _ProofViewerState extends State<_ProofViewer> {
  bool _isOpening = false; // mutex

  /// Item 2 — see todProofMaxViews (tod_models.dart) for the exact formula
  /// and rationale; kept as a single shared pure function so this display
  /// value and the documented server formula can never drift apart.
  int get _maxViews => todProofMaxViews(
    viewMode: widget.viewMode,
    isPremium: widget.isPremium,
  );

  bool get _alreadyViewed =>
      (widget.viewedByMap[widget.myUserId] ?? 0) >= _maxViews;

  Future<void> _open() async {
    if (_alreadyViewed || _isOpening) return;
    setState(() => _isOpening = true);

    // Real server-side gate — who's allowed to view and how many times is
    // enforced in Postgres now, not just derived from the shared broadcast
    // state a modified/different-owner client could disagree with.
    if (widget.sessionId != null && widget.turnStartedAt != null) {
      try {
        await TodRepository.instance.recordProofView(
          sessionId: widget.sessionId!,
          turnStartedAt: widget.turnStartedAt!,
        );
      } catch (e) {
        if (mounted) {
          setState(() => _isOpening = false);
          final message = e.toString().contains('view_limit_exceeded')
              ? 'No replays left for this proof.'
              : e.toString().contains('not_permitted')
              ? 'You are not allowed to view this proof.'
              : 'Could not open proof — please try again.';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
        return;
      }
    }

    // Mark viewed before showing content: the one-time grant is spent by
    // opening, not by finishing, and syncs immediately to every client.
    widget.onOpened();
    if (!mounted) return;
    if (widget.imageB64.isNotEmpty) {
      await showDialog(
        context: context,
        barrierColor: Colors.black,
        builder: (_) => _TimedImageProofDialog(
          imageB64: widget.imageB64,
          // Only TodProofViewMode.timed actually auto-closes — 'once' and
          // 'replay_once' show with no duration limit, same as before.
          viewSeconds:
              widget.viewMode == TodProofViewMode.timed ? widget.viewSeconds : null,
        ),
      );
    } else if (widget.voiceB64.isNotEmpty) {
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        builder: (_) => _VoicePlayerSheet(voiceB64: widget.voiceB64),
      );
    }
    if (mounted) setState(() => _isOpening = false);
  }

  @override
  Widget build(BuildContext context) {
    final viewed = _alreadyViewed;
    final timesViewed = widget.viewedByMap[widget.myUserId] ?? 0;
    final canReplay = !viewed && timesViewed > 0;
    // Item 2 — an honest, non-misleading count: how many opens this
    // specific viewer has left, per this specific proof (viewedByMap is
    // already per-viewer; _maxViews already reflects free vs premium).
    final replaysLeft = _maxViews - timesViewed;
    return GestureDetector(
      onTap: viewed ? null : _open,
      child: Container(
        width: double.infinity,
        height: 70,
        decoration: BoxDecoration(
          color: viewed ? Colors.grey.shade200 : Colors.deepPurple.shade900,
          borderRadius: BorderRadius.circular(12),
          border: viewed
              ? null
              : Border.all(color: Colors.deepPurple.shade400, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              viewed ? Icons.check_circle_outline : Icons.remove_red_eye_outlined,
              color: viewed ? Colors.grey : Colors.white,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              viewed
                  ? 'Proof viewed'
                  : canReplay
                  ? '👁 Replay ($replaysLeft left)'
                  : '🔒 Tap to view proof',
              style: TextStyle(
                color: viewed ? Colors.grey.shade600 : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen image proof viewer. When [viewSeconds] is set (item 4 —
/// TodProofViewMode.timed), shows a live, visibly-decreasing countdown and
/// closes itself the instant it reaches zero — the image is genuinely gone
/// from the screen, not just covered. [viewSeconds] null (once/replay_once)
/// shows with no duration limit, same as before this feature existed.
///
/// This countdown is presentation only — the authorization decision
/// (whether this viewer was allowed to open the image at all, and how many
/// times) already happened server-side in record_proof_view before this
/// widget is ever shown; see _ProofViewerState._open.
class _TimedImageProofDialog extends StatefulWidget {
  const _TimedImageProofDialog({required this.imageB64, this.viewSeconds});
  final String imageB64;
  final int? viewSeconds;

  @override
  State<_TimedImageProofDialog> createState() =>
      _TimedImageProofDialogState();
}

class _TimedImageProofDialogState extends State<_TimedImageProofDialog> {
  // ROOT CAUSE of the image flicker/reload (item 1): base64Decode was
  // previously called INLINE inside build(), which the countdown's own
  // setState re-ran every second — a fresh Uint8List each tick, so
  // Image.memory's MemoryImage (identity-keyed on the bytes object) saw a
  // "new" image every second and reloaded it. Decoded exactly ONCE here,
  // when the dialog first opens, and never touched again — the Image
  // subtree below is now completely stable across every countdown tick.
  late final Uint8List _imageBytes = base64Decode(widget.imageB64);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(child: Image.memory(_imageBytes)),
              ),
              if (widget.viewSeconds != null)
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: TodCountdownBadge(
                      seconds: widget.viewSeconds!,
                      onExpired: () {
                        if (mounted && Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Isolated countdown (item 1) — the ONLY thing that rebuilds once a
/// second. A completely separate subtree/State from the image above it in
/// _TimedImageProofDialog, so its setState can never touch (let alone
/// reload) the image. Owns its own fresh Timer for its own lifetime —
/// mounting a new instance (each replay opens a brand-new dialog, hence a
/// brand-new TodCountdownBadge) always starts exactly one new timer at the
/// full original duration.
class TodCountdownBadge extends StatefulWidget {
  const TodCountdownBadge({
    super.key,
    required this.seconds,
    required this.onExpired,
  });
  final int seconds;
  final VoidCallback onExpired;

  @override
  State<TodCountdownBadge> createState() => TodCountdownBadgeState();
}

class TodCountdownBadgeState extends State<TodCountdownBadge> {
  late int _remaining = widget.seconds;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining <= 1) {
        _ticker?.cancel();
        widget.onExpired();
        return;
      }
      setState(() => _remaining--);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urgent = _remaining <= 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: urgent ? AppColors.errorRed : Colors.white38,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 15,
            color: urgent ? AppColors.errorRed : Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            '$_remaining',
            style: TextStyle(
              color: urgent ? AppColors.errorRed : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingWidget extends StatefulWidget {
  const _RecordingWidget({
    required this.seconds,
    required this.maxSeconds,
    required this.onStop,
  });
  final int seconds;
  final int maxSeconds;
  final VoidCallback onStop;
  @override
  State<_RecordingWidget> createState() => _RecordingWidgetState();
}

class _RecordingWidgetState extends State<_RecordingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  String get _timeLabel {
    final remaining = widget.maxSeconds - widget.seconds;
    final m = remaining ~/ 60;
    final s = remaining % 60;
    return m > 0 ? '$m:${s.toString().padLeft(2, '0')}' : '${s}s left';
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.seconds / widget.maxSeconds;
    final isNearEnd = progress > 0.8;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              RepaintBoundary(
                child: SizedBox(
                  width: 40,
                  height: 28,
                  child: AnimatedBuilder(
                    animation: _wave,
                    builder: (_, __) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(5, (i) {
                        final phase = (_wave.value + i * 0.2) % 1.0;
                        final h = 6.0 + phase * 16.0;
                        return Container(
                          width: 4,
                          height: h,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.todRecording,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _timeLabel,
                style: TextStyle(
                  color: isNearEnd ? Colors.red : Colors.red.shade700,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.red.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(
                isNearEnd ? Colors.red : Colors.red.shade400,
              ),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: widget.onStop,
              icon: const Icon(Icons.stop_rounded),
              label: Text(context.l10n.todStopRecording),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoicePlayerSheet extends StatefulWidget {
  const _VoicePlayerSheet({required this.voiceB64});
  final String voiceB64;

  @override
  State<_VoicePlayerSheet> createState() => _VoicePlayerSheetState();
}

class _VoicePlayerSheetState extends State<_VoicePlayerSheet> {
  AudioPlayer? _player;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  bool _playing = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final bytes = base64Decode(widget.voiceB64);
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_proof_play_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await File(path).writeAsBytes(bytes);
      _player = AudioPlayer();
      await _player!.setFilePath(path);
      _total = _player!.duration ?? Duration.zero;
      _player!.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _player!.playerStateStream.listen((s) {
        if (mounted) setState(() => _playing = s.playing);
        if (s.processingState == ProcessingState.completed && mounted) {
          _player!.seek(Duration.zero);
          _player!.pause();
        }
      });
      if (mounted) setState(() => _loaded = true);
      await _player!.play();
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.purple.shade900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Icon(Icons.mic_rounded, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          Text(
            context.l10n.todVoiceProofTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (!_loaded)
            const CircularProgressIndicator(color: Colors.white)
          else ...[
            Slider(
              value: _position.inMilliseconds.toDouble().clamp(
                0,
                _total.inMilliseconds.toDouble(),
              ),
              max: _total.inMilliseconds.toDouble().clamp(1, double.infinity),
              activeColor: Colors.white,
              inactiveColor: Colors.white24,
              onChanged: (v) =>
                  _player?.seek(Duration(milliseconds: v.round())),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _fmt(_position),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  _fmt(_total),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            IconButton(
              iconSize: 56,
              icon: Icon(
                _playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: Colors.white,
                size: 56,
              ),
              onPressed: () => _playing ? _player?.pause() : _player?.play(),
            ),
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.done, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
