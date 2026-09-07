
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jma3a/Sticker.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';
import '../../../../shared/widgets/overlays/confirm_dialog.dart';
import '../../../games/engine/base_game_engine.dart';
import '../../../games/never_have_i_ever/never_have_i_ever_engine.dart';
import '../../../games/meme_game/meme_game_engine.dart';
import '../../../games/truth_or_dare/domain/tod_models.dart';
import '../../../games/truth_or_dare/truth_or_dare_engine.dart';
import '../../data/offline_game_provider.dart';
import '../../domain/offline_session.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF0D1B2A);
const _kNavyLight = Color(0xFF1A2E45);
const _kYellow = Color(0xFFFFD60A);
const _kCoral = Color(0xFFFF6B6B);
const _kTeal = Color(0xFF4ECDC4);
const _kPurple = Color(0xFFA855F7);
const _kGreen = Color(0xFF4ADE80);
const _kOrange = Color(0xFFFB923C);

// ── Root screen ───────────────────────────────────────────────────────────────
class OfflinePlayScreen extends StatelessWidget {
  const OfflinePlayScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineGameProvider>(
      builder: (ctx, game, _) {
        if (game.isGameOver) return _GameOverScreen(game: game);
        if (game.loadState == OfflineLoadState.error)
          return _ErrorScreen(game: game);
        if (game.isLobby) return _LanLobbyScreen(game: game);
        final session = game.session;
        if (session == null || game.state == null)
          return _WaitingScreen(game: game);
        return WillPopScope(
          onWillPop: () async {
            final ok = await showConfirmDialog(
              context: ctx,
              title: 'Leave game?',
              message: 'Your progress will be saved.',
              confirmLabel: 'Leave',
            );
            return ok == true;
          },
          child: Scaffold(
            backgroundColor: _kNavy,
            appBar: _GameAppBar(game: game),
            body: _ActiveGameBody(game: game, session: session),
          ),
        );
      },
    );
  }
}

class _WaitingScreen extends StatelessWidget {
  const _WaitingScreen({required this.game});
  final OfflineGameProvider game;
  @override
  Widget build(BuildContext context) {
    final session = game.session;
    return Scaffold(
      backgroundColor: _kNavy,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(strokeWidth: 3, color: _kYellow),
            ).animate(onPlay: (c) => c.repeat()).rotate(duration: 1.5.seconds),
            const SizedBox(height: 24),
            Text(
              !game.isLanHost ? context.l10n.offlineWaitingForHostToStart : context.l10n.loading,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (session != null) ...[
              const SizedBox(height: 8),
              Text(
                context.l10n.offlineGameTypeAndPack(session.gameType.displayName, session.packName),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.game});
  final OfflineGameProvider game;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _kNavy,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('❌', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              game.error ?? context.l10n.error,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
              ),
              child: Text(context.l10n.exit),
            ),
          ],
        ),
      ),
    ),
  );
}

class _GameAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _GameAppBar({required this.game});
  final OfflineGameProvider game;
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: _kNavyLight,
    elevation: 0,
    foregroundColor: Colors.white,
    title: Row(
      children: [
        Text(
          game.session?.gameType.displayName ?? 'Game',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _kYellow.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kYellow.withOpacity(0.3)),
            ),
            child: Text(
              game.session?.packName ?? '',
              style: const TextStyle(
                color: _kYellow,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ],
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.history_rounded, color: Colors.white70),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _HistorySheet(game: game),
        ),
      ),
      if (game.mode == OfflineMode.lan) _ChatBadgeButton(game: game),
    ],
  );
}

class _ChatBadgeButton extends StatelessWidget {
  const _ChatBadgeButton({required this.game});
  final OfflineGameProvider game;
  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.topRight,
    children: [
      IconButton(
        icon: const Icon(
          Icons.chat_bubble_outline_rounded,
          color: Colors.white70,
        ),
        onPressed: () {
          game.clearUnreadChat();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _ChatSheet(game: game),
          );
        },
      ),
      if (game.unreadChatCount > 0)
        Positioned(
          top: 8,
          right: 8,
          child:
              Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: _kCoral,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${game.unreadChatCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.1, 1.1),
                    duration: 800.ms,
                  ),
        ),
    ],
  );
}

class _ActiveGameBody extends StatelessWidget {
  const _ActiveGameBody({required this.game, required this.session});
  final OfflineGameProvider game;
  final OfflineSession session;
  @override
  Widget build(BuildContext context) {
    final String myId = game.mode == OfflineMode.passAndPlay
        ? ''
        : game.isLanHost
        ? (session.players.firstOrNull?.id ?? '')
        : (game.clientPlayerId ?? '');
    final bool passAndPlay = game.mode == OfflineMode.passAndPlay;
    final displayNames = {for (final p in session.players) p.id: p.name};
    Widget child() => switch (session.gameType) {
      GameType.truthOrDare => _TodView(
        key: ValueKey('tod-${(game.state as TodState?)?.phase}'),
        game: game,
        session: session,
        myId: myId,
        passAndPlay: passAndPlay,
        displayNames: displayNames,
      ),
      GameType.neverHaveIEver => _NhieView(
        key: ValueKey('nhie-${(game.state as NhieState?)?.roundNumber}'),
        game: game,
        session: session,
        myId: myId,
        passAndPlay: passAndPlay,
      ),
      GameType.memeGame => _MemeView(
        key: ValueKey(
          'meme-${(game.state as MemeState?)?.phase}-${(game.state as MemeState?)?.roundNumber}',
        ),
        game: game,
        session: session,
        myId: myId,
        passAndPlay: passAndPlay,
      ),
    };
    return Column(
      children: [
        _PlayerTurnStrip(
          game: game,
          session: session,
          myId: myId,
          displayNames: displayNames,
        ),
        Expanded(
          child: AnimatedSwitcher(duration: 300.ms, child: child()),
        ),
      ],
    );
  }
}

class _PlayerTurnStrip extends StatelessWidget {
  const _PlayerTurnStrip({
    required this.game,
    required this.session,
    required this.myId,
    required this.displayNames,
  });
  final OfflineGameProvider game;
  final OfflineSession session;
  final String myId;
  final Map<String, String> displayNames;
  @override
  Widget build(BuildContext context) {
    final state = game.state;
    String? currentId;
    if (state is TodState)
      currentId = state.currentPlayerId;
    else if (state is NhieState)
      currentId = state.currentPlayerId;
    final isPassAndPlay = game.mode == OfflineMode.passAndPlay;
    return Container(
      color: _kNavyLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 54,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: session.players.map((p) {
            final isCurrent = p.id == currentId;
            final isMe = !isPassAndPlay && p.id == myId;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                        duration: 300.ms,
                        width: isCurrent ? 40 : 32,
                        height: isCurrent ? 40 : 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCurrent
                              ? _kYellow
                              : Colors.white.withOpacity(0.1),
                          border: isMe
                              ? Border.all(color: _kTeal, width: 2)
                              : null,
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: _kYellow.withOpacity(0.5),
                                    blurRadius: 12,
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          p.name[0].toUpperCase(),
                          style: TextStyle(
                            color: isCurrent
                                ? _kNavy
                                : Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w800,
                            fontSize: isCurrent ? 16 : 13,
                          ),
                        ),
                      )
                      .animate(target: isCurrent ? 1 : 0)
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.15, 1.15),
                      ),
                  const SizedBox(height: 2),
                  Text(
                    isMe ? '(you)' : p.name.split(' ').first,
                    style: TextStyle(
                      color: isCurrent ? _kYellow : Colors.white38,
                      fontSize: 9,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TodView extends StatelessWidget {
  const _TodView({
    super.key,
    required this.game,
    required this.session,
    required this.myId,
    required this.displayNames,
    this.passAndPlay = false,
  });
  final OfflineGameProvider game;
  final OfflineSession session;
  final String myId;
  final Map<String, String> displayNames;
  final bool passAndPlay;
  String _name(String id) =>
      displayNames[id] ?? id.substring(0, math.min(6, id.length));
  @override
  Widget build(BuildContext context) {
    final s = game.state as TodState?;
    if (s == null) return const SizedBox.shrink();
    final isMyTurn = passAndPlay || s.currentPlayerId == myId;
    final curName = _name(s.currentPlayerId);
    return switch (s.phase) {
      TodTurnPhase.choosingType => _TodChoicePhase(
        s: s,
        game: game,
        myId: myId,
        isMyTurn: isMyTurn,
        name: curName,
        config: session.config,
        passAndPlay: passAndPlay,
      ),
      TodTurnPhase.readingCard || TodTurnPhase.awaitingResult => _TodCardPhase(
        s: s,
        game: game,
        myId: myId,
        isMyTurn: isMyTurn,
        name: curName,
        config: session.config,
        passAndPlay: passAndPlay,
      ),
      TodTurnPhase.awaitingNextTurn => _TodResultPhase(
        s: s,
        game: game,
        myId: myId,
        isMyTurn: isMyTurn,
        name: curName,
        displayNames: displayNames,
        passAndPlay: passAndPlay,
      ),
      _ => _TodChoicePhase(
        s: s,
        game: game,
        myId: myId,
        isMyTurn: isMyTurn,
        name: curName,
        config: session.config,
        passAndPlay: passAndPlay,
      ),
    };
  }
}

class _TodChoicePhase extends StatelessWidget {
  const _TodChoicePhase({
    required this.s,
    required this.game,
    required this.myId,
    required this.isMyTurn,
    required this.name,
    required this.config,
    this.passAndPlay = false,
  });
  final TodState s;
  final OfflineGameProvider game;
  final String myId;
  final bool isMyTurn;
  final String name;
  final GameConfig config;
  final bool passAndPlay;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            isMyTurn ? '🎯 Your turn!' : '🎯 $name\'s turn',
            style: TextStyle(
              color: isMyTurn ? _kYellow : Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ).animate().fadeIn().slideY(begin: -0.2, end: 0),
        const SizedBox(height: 32),
        if (isMyTurn || passAndPlay) ...[
          Text(
            context.l10n.offlineChooseYourFate,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 28),
          _BigChoiceButton(
            emoji: '🤔',
            label: context.l10n.offlineTruthLabel,
            subtitle: context.l10n.offlineAnswerHonestly,
            color: _kCoral,
            onTap: () => _doAction(game, myId, {
              'action': 'tod_choice',
              'card_type': 'truth',
            }, passAndPlay: passAndPlay),
          ).animate(delay: 150.ms).fadeIn().slideX(begin: -0.06, end: 0),
          const SizedBox(height: 14),
          _BigChoiceButton(
            emoji: '🔥',
            label: context.l10n.offlineDareLabel,
            subtitle: context.l10n.offlineAcceptChallenge,
            color: _kOrange,
            onTap: () => _doAction(game, myId, {
              'action': 'tod_choice',
              'card_type': 'dare',
            }, passAndPlay: passAndPlay),
          ).animate(delay: 220.ms).fadeIn().slideX(begin: 0.06, end: 0),
        ] else ...[
          Text(
                context.l10n.offlineIsDeciding(name),
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: 900.ms),
          const SizedBox(height: 24),
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: _kYellow),
          ),
        ],
        const Spacer(),
      ],
    ),
  );
}

class _BigChoiceButton extends StatelessWidget {
  const _BigChoiceButton({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final String emoji, label, subtitle;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.maxFinite,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(width: 20),
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
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white54,
            size: 20,
          ),
        ],
      ),
    ),
  );
}

class _TodCardPhase extends StatefulWidget {
  const _TodCardPhase({
    required this.s,
    required this.game,
    required this.myId,
    required this.isMyTurn,
    required this.name,
    required this.config,
    this.passAndPlay = false,
  });
  final TodState s;
  final OfflineGameProvider game;
  final String myId;
  final bool isMyTurn;
  final String name;
  final GameConfig config;
  final bool passAndPlay;
  @override
  State<_TodCardPhase> createState() => _TodCardPhaseState();
}

class _TodCardPhaseState extends State<_TodCardPhase> {
  @override
  Widget build(BuildContext context) {
    final card = widget.s.currentCard;
    if (card == null) return const SizedBox.shrink();
    final isTruth = card.type == TodCardType.truth;
    final cardColor = isTruth ? _kCoral : _kOrange;
    final isSpicy = card.difficulty == TodDifficulty.spicy;
    final coverUrl = widget.game.session?.packCoverUrl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        children: [
          if (widget.s.timerStartedAt != null)
            _TurnTimer(
              startedAt: widget.s.timerStartedAt!,
              durationSeconds:
                  widget.game.session?.config.turnTimerSeconds ?? 60,
              onExpired: () {
                if (widget.isMyTurn)
                  _doAction(widget.game, widget.myId, {
                    'action': 'tod_skip',
                  }, passAndPlay: widget.passAndPlay);
              },
            ),
          const SizedBox(height: 10),
          Expanded(
            child: _GameCard(
              content: card.content,
              color: cardColor,
              coverUrl: coverUrl,
              badge: isTruth ? '🤔  TRUTH' : '🔥  DARE',
              isSpicy: isSpicy,
              playerInitial: widget.name[0].toUpperCase(),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.isMyTurn) ...[
            if (widget.passAndPlay)
              FilledButton.icon(
                onPressed: () => _doAction(
                  widget.game,
                  widget.myId,
                  {'action': 'tod_complete', 'response': '', 'proof_image': ''},
                  passAndPlay: true,
                  autoAdvance: true,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: _kNavy,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.skip_next_rounded, size: 20),
                label: Text(
                  context.l10n.todNextTurn,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.3, end: 0)
            else
              FilledButton.icon(
                onPressed: () => _showCompleteSheet(context),
                style: FilledButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: _kNavy,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(
                  context.l10n.todDoneButton,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.3, end: 0),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _doAction(widget.game, widget.myId, {
                'action': 'tod_skip',
              }, passAndPlay: widget.passAndPlay),
              style: TextButton.styleFrom(foregroundColor: Colors.white38),
              child: Text(context.l10n.skip),
            ),
          ] else
            Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    context.l10n.todActivityPerforming(widget.name),
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 1.seconds),
        ],
      ),
    );
  }

  void _showCompleteSheet(BuildContext ctx) {
    final ctrl = TextEditingController();
    final isTruth = widget.s.currentCard?.type == TodCardType.truth;
    String? imgB64;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (bCtx, setS) => Container(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(bCtx).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF1A2E45),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isTruth ? '🤔 Your answer' : '🔥 What did you do?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                maxLines: 3,
                maxLength: 300,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: isTruth ? 'Type your answer…' : 'What did you do?',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  counterStyle: const TextStyle(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 10),
              if (imgB64 != null) ...[
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        base64Decode(imgB64!),
                        height: 100,
                        width: double.maxFinite,
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
                ),
                const SizedBox(height: 10),
              ] else
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      // iOS fix: use explicit quality and max dimensions
                      final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 60,
                        maxWidth: 1200,
                        maxHeight: 1200,
                      );
                      if (picked != null) {
                        final bytes = await picked.readAsBytes();
                        setS(() => imgB64 = base64Encode(bytes));
                      }
                    } catch (e) {
                      if (bCtx.mounted)
                        ScaffoldMessenger.of(bCtx).showSnackBar(
                          SnackBar(content: Text(bCtx.l10n.offlineCouldNotPickImage(e.toString()))),
                        );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 16,
                  ),
                  label: Text(
                    bCtx.l10n.offlineAddProofPhoto,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  Navigator.pop(bCtx);
                  _doAction(widget.game, widget.myId, {
                    'action': 'tod_complete',
                    'response': ctrl.text.trim(),
                    'proof_image': imgB64 ?? '',
                  }, passAndPlay: widget.passAndPlay);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: _kNavy,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  bCtx.l10n.offlineCompleteTurnCheck,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodResultPhase extends StatelessWidget {
  const _TodResultPhase({
    required this.s,
    required this.game,
    required this.myId,
    required this.isMyTurn,
    required this.name,
    required this.displayNames,
    this.passAndPlay = false,
  });
  final TodState s;
  final OfflineGameProvider game;
  final String myId;
  final bool isMyTurn;
  final String name;
  final Map<String, String> displayNames;
  final bool passAndPlay;
  @override
  Widget build(BuildContext context) {
    final hasReacted =
        passAndPlay || s.currentReactions.any((r) => r.userId == myId);
    final hasVoted =
        passAndPlay || s.currentVotes.any((v) => v.voterId == myId);
    final reactTally = <String, int>{};
    for (final r in s.currentReactions)
      reactTally[r.emoji] = (reactTally[r.emoji] ?? 0) + 1;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_kGreen.withOpacity(0.2), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _kGreen.withOpacity(0.25)),
            ),
            child: Column(
              children: [
                const Text(
                  '🎉',
                  style: TextStyle(fontSize: 52),
                ).animate().scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.offlineCompletedName(name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (s.currentCard != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    s.currentCard!.content,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (s.turnResponse.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      context.l10n.todQuotedResponse(s.turnResponse),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                if (s.turnProofImageB64.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _ViewOnceImage(b64: s.turnProofImageB64),
                ],
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.1, end: 0),
          const SizedBox(height: 16),
          if (reactTally.isNotEmpty) ...[
            Wrap(
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
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${e.key} ${e.value}',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (!isMyTurn && !hasReacted) ...[
            Text(
              context.l10n.todReactLabel,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kEmojiReactions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (_, i) {
                  final emoji = kEmojiReactions[i];
                  return GestureDetector(
                    onTap: () => _doAction(game, myId, {
                      'action': 'tod_react',
                      'emoji': emoji,
                    }, passAndPlay: passAndPlay),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (!isMyTurn && s.turnResponse.isNotEmpty && !hasVoted) ...[
            OutlinedButton.icon(
              onPressed: () => _doAction(game, myId, {
                'action': 'tod_vote_response',
              }, passAndPlay: passAndPlay),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kYellow,
                side: const BorderSide(color: _kYellow, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.thumb_up_outlined, size: 16),
              label: Text(context.l10n.offlineGoodOneVotes(s.currentVotes.length)),
            ),
            const SizedBox(height: 12),
          ],
          _ScoreStrip(s: s, displayNames: displayNames),
          const SizedBox(height: 20),
          if (game.isLanHost || passAndPlay)
            FilledButton.icon(
              onPressed: () => _doAction(game, myId, {
                'action': 'advance',
              }, passAndPlay: passAndPlay),
              style: FilledButton.styleFrom(
                backgroundColor: _kYellow,
                foregroundColor: _kNavy,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.skip_next_rounded),
              label: Text(
                context.l10n.offlineNextTurnShort,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2, end: 0)
          else
            Center(
              child: Text(
                context.l10n.offlineWaitingForHost,
                style: const TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ),
          if (game.isLanHost || game.mode == OfflineMode.passAndPlay) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: game.endGame,
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
              child: Text(context.l10n.todEndGame),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreStrip extends StatelessWidget {
  const _ScoreStrip({required this.s, required this.displayNames});
  final TodState s;
  final Map<String, String> displayNames;
  @override
  Widget build(BuildContext context) {
    final sorted = s.sortedScores.take(3).toList();
    if (sorted.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: sorted.asMap().entries.map((e) {
          final medals = ['🥇', '🥈', '🥉'];
          final name = displayNames[e.value.userId] ?? context.l10n.roleLabelPlayer;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text(medals[e.key], style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${e.value.points}',
                  style: const TextStyle(
                    color: _kYellow,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  context.l10n.ptsSuffix,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// NEVER HAVE I EVER
// ══════════════════════════════════════════════════════════════════════════════
class _NhieView extends StatelessWidget {
  const _NhieView({
    super.key,
    required this.game,
    required this.session,
    required this.myId,
    this.passAndPlay = false,
  });
  final OfflineGameProvider game;
  final OfflineSession session;
  final String myId;
  final bool passAndPlay;
  @override
  Widget build(BuildContext context) {
    final s = game.state as NhieState?;
    if (s == null) return const SizedBox.shrink();
    if (s.isOver) return _NhieResultsView(state: s, session: session);
    final names = {for (final p in session.players) p.id: p.name};
    final myVote = s.voteEntries[passAndPlay ? _currentPlayerId(game) : myId];
    final hasVoted = myVote != null;
    final haveCount = s.voteEntries.values.where((v) => v.haveI).length;
    final neverCount = s.voteEntries.values.where((v) => !v.haveI).length;
    final allVoted = passAndPlay
        ? hasVoted
        : s.voteEntries.length >= session.players.length;
    final effectiveId = passAndPlay ? _currentPlayerId(game) : myId;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: _kTeal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kTeal.withOpacity(0.3)),
              ),
              child: Text(
                context.l10n.offlineRoundOf(s.roundNumber, s.maxRounds),
                style: const TextStyle(
                  color: _kTeal,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            width: double.maxFinite,
            child: _GameCard(
              content: s.currentCard?.content ?? '…',
              color: _kTeal,
              badge: context.l10n.offlineNeverHaveIEverBadge,
              coverUrl: game.session?.packCoverUrl,
              emoji: '🍹',
            ),
          ),
          const SizedBox(height: 20),
          if (hasVoted || s.voteEntries.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NhieTallyPill(
                  emoji: '🙋',
                  label: context.l10n.nhieIHave,
                  count: haveCount,
                  color: _kTeal,
                ),
                _NhieTallyPill(
                  emoji: '🙅',
                  label: context.l10n.nhieNever,
                  count: neverCount,
                  color: _kCoral,
                ),
              ],
            ).animate().fadeIn(),
            const SizedBox(height: 10),
          ],
          if (allVoted) ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: s.voteEntries.entries
                  .map(
                    (e) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: (e.value.haveI ? _kTeal : _kCoral).withOpacity(
                          0.12,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (e.value.haveI ? _kTeal : _kCoral).withOpacity(
                            0.3,
                          ),
                        ),
                      ),
                      child: Text(
                        '${names[e.key] ?? e.key} ${e.value.haveI ? "🙋" : "🙅"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
          ],
          if (!hasVoted) ...[
            Row(
              children: [
                Expanded(
                  child: _NhieVoteButton(
                    emoji: '🙋',
                    label: 'I HAVE',
                    color: _kTeal,
                    onTap: () => _doAction(
                      game,
                      effectiveId,
                      {'action': 'nhie_vote', 'have_i': true, 'message': ''},
                      passAndPlay: passAndPlay,
                      autoAdvance: passAndPlay,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NhieVoteButton(
                    emoji: '🙅',
                    label: 'NEVER',
                    color: _kCoral,
                    onTap: () => _doAction(
                      game,
                      effectiveId,
                      {'action': 'nhie_vote', 'have_i': false, 'message': ''},
                      passAndPlay: passAndPlay,
                      autoAdvance: passAndPlay,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (myVote.haveI ? _kTeal : _kCoral).withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (myVote.haveI ? _kTeal : _kCoral).withOpacity(0.3),
                ),
              ),
              child: Text(
                context.l10n.offlineMyVoteCount(
                  myVote.haveI ? '🙋 ${context.l10n.nhieIHave}' : '🙅 ${context.l10n.nhieNever}',
                  s.voteEntries.length,
                  session.players.length,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (!allVoted && !passAndPlay)
              LinearProgressIndicator(
                value: s.voteEntries.length / session.players.length,
                backgroundColor: Colors.white.withOpacity(0.08),
                color: _kTeal,
              ).animate().fadeIn(),
          ],
          const SizedBox(height: 20),
          if (game.isLanHost || passAndPlay) ...[
            FilledButton.icon(
              onPressed: (allVoted || passAndPlay)
                  ? () => _doAction(game, effectiveId, {
                      'action': 'advance',
                    }, passAndPlay: passAndPlay)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: (allVoted || passAndPlay)
                    ? _kYellow
                    : Colors.white.withOpacity(0.1),
                foregroundColor: (allVoted || passAndPlay)
                    ? _kNavy
                    : Colors.white38,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.skip_next_rounded),
              label: Text(
                (allVoted || passAndPlay)
                    ? context.l10n.nhieNextCard
                    : context.l10n.offlineWaitingForMore(session.players.length - s.voteEntries.length),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ] else
            Center(
              child: Text(
                context.l10n.offlineWaitingHostAdvance,
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          if (s.history.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
            Text(
              context.l10n.offlinePreviousCards,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            ...s.history.reversed.take(3).map((r) {
              final haveI = r.votes.entries
                  .where((e) => e.value.haveI)
                  .map((e) => names[e.key] ?? e.key)
                  .join(', ');
              final never = r.votes.entries
                  .where((e) => !e.value.haveI)
                  .map((e) => names[e.key] ?? e.key)
                  .join(', ');
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.card.content,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (haveI.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '🙋 $haveI',
                        style: const TextStyle(color: _kTeal, fontSize: 12),
                      ),
                    ],
                    if (never.isNotEmpty)
                      Text(
                        '🙅 $never',
                        style: const TextStyle(color: _kCoral, fontSize: 12),
                      ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _NhieTallyPill extends StatelessWidget {
  const _NhieTallyPill({
    required this.emoji,
    required this.label,
    required this.count,
    required this.color,
  });
  final String emoji, label;
  final int count;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 2),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 28,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
      ],
    ),
  );
}

class _NhieVoteButton extends StatelessWidget {
  const _NhieVoteButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String emoji, label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    ),
  );
}

class _NhieResultsView extends StatelessWidget {
  const _NhieResultsView({required this.state, required this.session});
  final NhieState state;
  final OfflineSession session;
  @override
  Widget build(BuildContext context) {
    final names = {for (final p in session.players) p.id: p.name};
    final scores = state.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🍹🏆🍹', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              context.l10n.todGameOverBang,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 24),
            ...scores.asMap().entries.map((e) {
              final medals = ['🥇', '🥈', '🥉'];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Text(
                      e.key < 3 ? medals[e.key] : '${e.key + 1}.',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        names[e.value.key] ?? e.value.key,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      context.l10n.nhieDrinksScore(e.value.value),
                      style: const TextStyle(
                        color: _kTeal,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MEME GAME
// ══════════════════════════════════════════════════════════════════════════════
class _MemeView extends StatefulWidget {
  const _MemeView({
    super.key,
    required this.game,
    required this.session,
    required this.myId,
    this.passAndPlay = false,
  });
  final OfflineGameProvider game;
  final OfflineSession session;
  final String myId;
  final bool passAndPlay;
  @override
  State<_MemeView> createState() => _MemeViewState();
}

class _MemeViewState extends State<_MemeView> {
  bool _submitting = true;
  String _sticker = '';
  final _captionCtrl = TextEditingController();
  final List<Map<String, String>> _subs = [];
  int _voterIdx = 0;
  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memeState = widget.game.state as MemeState?;
    final promptText = memeState?.currentPrompt?.caption ?? '…';
    final theme = context.theme;

    if (widget.passAndPlay) {
      if (_submitting) {
        final subIdx = _subs.length;
        final playerName = subIdx < widget.session.players.length
            ? widget.session.players[subIdx].name
            : context.l10n.roleLabelPlayer;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                context.l10n.offlineSubmissionTitle(playerName),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kPurple,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  promptText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_sticker.isNotEmpty) _stickerImg(_sticker, height: 80),
              const SizedBox(height: 4),
              Text(context.l10n.offlinePickReaction, style: theme.textTheme.labelMedium),
              Expanded(
                child: SingleChildScrollView(
                  child: StickerPicker(
                    selected: _sticker.isEmpty ? null : _sticker,
                    onSelect: (s) => setState(() => _sticker = s),
                  ),
                ),
              ),
              TextField(
                controller: _captionCtrl,
                decoration: InputDecoration(
                  hintText: context.l10n.offlineAddCaptionOptional,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _sticker.isNotEmpty
                      ? () {
                          setState(() {
                            _subs.add({
                              'sticker': _sticker,
                              'caption': _captionCtrl.text,
                            });
                            _captionCtrl.clear();
                            _sticker = '';
                            if (_subs.length >= widget.session.players.length)
                              _submitting = false;
                          });
                        }
                      : null,
                  child: Text(
                    context.l10n.offlineSubmitCount(_subs.length, widget.session.players.length),
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        if (_voterIdx < widget.session.players.length) {
          final voter = widget.session.players[_voterIdx];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  context.l10n.offlineVotesExclaim(voter.name),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(context.l10n.offlinePickFavourite, style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _subs.length,
                    itemBuilder: (_, i) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: _stickerImg(_subs[i]['sticker']!, height: 48),
                        title: Text(
                          _subs[i]['caption']!.isEmpty
                              ? '(no caption)'
                              : _subs[i]['caption']!,
                        ),
                        onTap: () => setState(() {
                          _voterIdx++;
                          if (_voterIdx >= widget.session.players.length) {
                            _doAction(widget.game, widget.myId, {
                              'action': 'advance',
                            }, passAndPlay: true);
                            _submitting = true;
                            _subs.clear();
                            _voterIdx = 0;
                          }
                        }),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      }
    }

    // LAN mode
    final s = widget.game.state as MemeState?;
    if (s == null) return const SizedBox.shrink();
    if (s.isOver) return _MemeResultsView(state: s, session: widget.session);
    final names = {for (final p in widget.session.players) p.id: p.name};
    return switch (s.phase) {
      MemePhase.submitting => _buildSubmit(s, names),
      MemePhase.voting => _buildVote(s, names),
      MemePhase.results => _buildResults(s, names),
    };
  }

  Widget _buildSubmit(MemeState s, Map<String, String> names) {
    final hasSubmitted = s.submissions.containsKey(widget.myId);
    final prompt = s.currentPrompt?.caption ?? '…';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: _kPurple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kPurple.withOpacity(0.3)),
              ),
              child: Text(
                context.l10n.offlineRoundOf(s.roundNumber, s.maxRounds),
                style: const TextStyle(
                  color: _kPurple,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 160,
            width: double.maxFinite,
            child: _GameCard(
              content: prompt,
              color: _kPurple,
              badge: context.l10n.offlineMemeBadge,
              coverUrl: widget.game.session?.packCoverUrl,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                context.l10n.memeSubmittedCount(s.submissions.length, widget.session.players.length),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (hasSubmitted) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kGreen.withOpacity(0.25)),
              ),
              child: Column(
                children: [
                  _stickerImg(
                    s.submissions[widget.myId]!.stickerChoice,
                    height: 72,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.offlineSubmittedWaitingCheck,
                    style: const TextStyle(
                      color: _kGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            LinearProgressIndicator(
              value: s.submissions.length / widget.session.players.length,
              backgroundColor: Colors.white.withOpacity(0.06),
              color: _kPurple,
            ).animate().fadeIn(),
          ] else ...[
            if (_sticker.isNotEmpty) ...[
              Center(child: _stickerImg(_sticker, height: 88)),
              const SizedBox(height: 8),
            ],
            Text(
              context.l10n.offlinePickReactionColon,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 200,
              child: SingleChildScrollView(
                child: StickerPicker(
                  selected: _sticker.isEmpty ? null : _sticker,
                  onSelect: (s) => setState(() => _sticker = s),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _captionCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: context.l10n.offlineAddCaptionOptional,
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.07),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _sticker.isNotEmpty
                  ? () {
                      _doAction(widget.game, widget.myId, {
                        'action': 'meme_submit',
                        'caption': _captionCtrl.text.trim(),
                        'sticker_choice': _sticker,
                      }, passAndPlay: false);
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: _kPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor: Colors.white.withOpacity(0.08),
              ),
              icon: const Icon(Icons.send_rounded),
              label: Text(
                context.l10n.offlineSubmitExclaim,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVote(MemeState s, Map<String, String> names) {
    final hasVoted = s.votes.containsKey(widget.myId);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🗳️', style: TextStyle(fontSize: 40)),
                Text(
                  context.l10n.offlineVoteForBestNoEmoji,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  context.l10n.memeVotesCount(s.votes.length, s.submissions.length),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 16),
          ...s.submissions.entries.where((e) => e.key != widget.myId).map((
            entry,
          ) {
            final sub = entry.value;
            final author = names[entry.key] ?? entry.key;
            final myPick = s.votes[widget.myId] == entry.key;
            final voteCount = s.votes.values
                .where((v) => v == entry.key)
                .length;
            return GestureDetector(
              onTap: hasVoted
                  ? null
                  : () => _doAction(widget.game, widget.myId, {
                      'action': 'meme_vote',
                      'target_user_id': entry.key,
                    }, passAndPlay: false),
              child:
                  AnimatedContainer(
                        duration: 200.ms,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: myPick
                              ? _kPurple.withOpacity(0.2)
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: myPick
                                ? _kPurple
                                : Colors.white.withOpacity(0.1),
                            width: myPick ? 2 : 1,
                          ),
                          boxShadow: myPick
                              ? [
                                  BoxShadow(
                                    color: _kPurple.withOpacity(0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _stickerImg(sub.stickerChoice, height: 60),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    author,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (sub.caption.isNotEmpty)
                                    Text(
                                      sub.caption,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (myPick)
                              const Text(
                                '✓',
                                style: TextStyle(
                                  color: _kPurple,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                            if (hasVoted && voteCount > 0)
                              Text(
                                context.l10n.offlineVoteCountBallot(voteCount),
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      )
                      .animate(
                        delay: Duration(
                          milliseconds:
                              s.submissions.entries.toList().indexWhere(
                                (e) => e.key == entry.key,
                              ) *
                              60,
                        ),
                      )
                      .fadeIn()
                      .slideX(begin: 0.06, end: 0),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildResults(MemeState s, Map<String, String> names) {
    final winnerId = s.roundWinnerId;
    final winnerName = names[winnerId] ?? winnerId ?? '?';
    final winnerSub = s.submissions[winnerId];
    final allVoted = s.votes.length >= s.submissions.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_kYellow.withOpacity(0.15), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _kYellow.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Text(
                  '🏆',
                  style: TextStyle(fontSize: 52),
                ).animate().scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.todWinnerWins(winnerName),
                  style: const TextStyle(
                    color: _kYellow,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (winnerSub != null) ...[
                  const SizedBox(height: 14),
                  _stickerImg(winnerSub.stickerChoice, height: 80),
                  if (winnerSub.caption.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.todQuotedResponse(winnerSub.caption),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...s.submissions.entries.map((e) {
            final vCount = s.votes.values.where((v) => v == e.key).length;
            final isWin = e.key == winnerId;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isWin
                    ? _kYellow.withOpacity(0.08)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _stickerImg(e.value.stickerChoice, height: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          names[e.key] ?? e.key,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                        if (e.value.caption.isNotEmpty)
                          Text(
                            e.value.caption,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    context.l10n.offlineVoteCountBallot(vCount),
                    style: TextStyle(
                      color: isWin ? _kYellow : Colors.white38,
                      fontWeight: isWin ? FontWeight.w800 : FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 20),
          if (widget.game.isLanHost)
            FilledButton.icon(
              onPressed: allVoted
                  ? () => _doAction(widget.game, widget.myId, {
                      'action': 'advance',
                    }, passAndPlay: false)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: allVoted
                    ? _kYellow
                    : Colors.white.withOpacity(0.1),
                foregroundColor: allVoted ? _kNavy : Colors.white38,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.skip_next_rounded),
              label: Text(
                allVoted
                    ? context.l10n.memeNextRound
                    : context.l10n.offlineWaitingForMore(s.submissions.length - s.votes.length),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            )
          else
            Center(
              child: Text(
                context.l10n.offlineWaitingForHost,
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

class _MemeResultsView extends StatelessWidget {
  const _MemeResultsView({required this.state, required this.session});
  final MemeState state;
  final OfflineSession session;
  @override
  Widget build(BuildContext context) {
    final names = {for (final p in session.players) p.id: p.name};
    final scores = state.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😂🏆😂', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              context.l10n.offlineMemeChampion,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 24),
            ...scores.asMap().entries.map((e) {
              final medals = ['🥇', '🥈', '🥉'];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Text(
                      e.key < 3 ? medals[e.key] : '${e.key + 1}.',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        names[e.value.key] ?? e.value.key,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      '${e.value.value} 🏆',
                      style: const TextStyle(
                        color: _kPurple,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED UTILITIES
// ══════════════════════════════════════════════════════════════════════════════
void _doAction(
  OfflineGameProvider game,
  String myId,
  Map<String, dynamic> action, {
  bool passAndPlay = false,
  bool autoAdvance = false,
}) {
  final actionType = action['action'] as String? ?? '';
  final isTurnAction = ![
    'tod_react',
    'tod_vote_response',
    'advance',
    'nhie_react',
    'meme_react',
  ].contains(actionType);
  final effectiveId = passAndPlay ? _currentPlayerId(game) : myId;
  if (isTurnAction && game.mode == OfflineMode.lan && !passAndPlay) {
    final state = game.state;
    if (state is TodState && state.currentPlayerId != effectiveId) return;
  }
  final fullAction = {
    ...action,
    'user_id': effectiveId,
    'ts': DateTime.now().millisecondsSinceEpoch,
  };
  if (game.isLanHost || passAndPlay) {
    if (actionType == 'advance') {
      game.advanceTurn();
    } else {
      final event = _parseEvent(fullAction);
      if (event != null) game.handleEvent(event);
    }
    if (autoAdvance && passAndPlay && actionType != 'advance')
      Future.delayed(100.ms, () => game.advanceTurn());
  } else {
    game.sendLanAction({'event': fullAction});
  }
}

String _currentPlayerId(OfflineGameProvider game) {
  final state = game.state;
  if (state is TodState) return state.currentPlayerId;
  if (state is NhieState) return state.currentPlayerId;
  return game.session?.players.firstOrNull?.id ?? '';
}

GameEngineEvent? _parseEvent(Map<String, dynamic> m) {
  final action = m['action'] as String? ?? m['type'] as String? ?? '';
  final userId = m['user_id'] as String? ?? '';
  final ts = m['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch;
  return switch (action) {
    'tod_choice' => TodChoiceEvent(
      userId: userId,
      ts: ts,
      cardType: m['card_type'] == 'dare' ? TodCardType.dare : TodCardType.truth,
    ),
    'tod_complete' => TodCompleteEvent(
      userId: userId,
      ts: ts,
      response: m['response'] as String? ?? '',
      proofImageB64: m['proof_image'] as String? ?? '',
    ),
    'tod_react' => TodReactEvent(
      userId: userId,
      ts: ts,
      emoji: m['emoji'] as String? ?? '👍',
    ),
    'tod_vote_response' => TodVoteResponseEvent(userId: userId, ts: ts),
    'tod_skip' => TodSkipEvent(userId: userId, ts: ts),
    'nhie_vote' => NhieVoteEvent(
      userId: userId,
      ts: ts,
      haveI: m['have_i'] as bool? ?? false,
      message: m['message'] as String? ?? '',
    ),
    'nhie_react' => NhieReactionEvent(
      userId: userId,
      ts: ts,
      sticker: m['sticker'] as String? ?? '',
    ),
    'meme_submit' => MemeSubmitEvent(
      userId: userId,
      ts: ts,
      caption: m['caption'] as String? ?? '',
      stickerChoice: m['sticker_choice'] as String? ?? '',
    ),
    'meme_vote' => MemeVoteEvent(
      userId: userId,
      ts: ts,
      targetUserId: m['target_user_id'] as String? ?? '',
    ),
    'meme_react' => MemeReactEvent(
      userId: userId,
      ts: ts,
      targetUserId: m['target_user_id'] as String? ?? '',
      emoji: m['emoji'] as String? ?? '👍',
    ),
    _ => null,
  };
}

Widget _stickerImg(String path, {double? height, BoxFit fit = BoxFit.contain}) {
  if (path.startsWith('http'))
    return Image.network(
      path,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) =>
          Text('🎭', style: TextStyle(fontSize: (height ?? 40) * 0.6)),
    );
  if (path.isEmpty)
    return Text('🎭', style: TextStyle(fontSize: (height ?? 40) * 0.6));
  return Image.asset(
    path,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) =>
        Text('🎭', style: TextStyle(fontSize: (height ?? 40) * 0.6)),
  );
}

// ── View-once proof image ──────────────────────────────────────────────────────
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
    if (_viewed)
      return Container(
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white38, size: 14),
            const SizedBox(width: 6),
            Text(
              context.l10n.offlineProofViewed,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      );
    // LayoutBuilder ensures bounded width — fixes iOS crash
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 40;
        return GestureDetector(
          onTap: () => setState(() {
            if (!_revealed)
              _revealed = true;
            else
              _viewed = true;
          }),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: w,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.memory(
                    base64Decode(widget.b64),
                    width: w,
                    height: 200,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                  if (!_revealed)
                    Container(
                      width: w,
                      height: 200,
                      color: Colors.black.withOpacity(0.85),
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
                            context.l10n.offlineTapToRevealProof,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.offlineTapAgainToDismiss,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_revealed)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _viewed = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            context.l10n.offlineTapToDismiss,
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Reusable game card ─────────────────────────────────────────────────────────
// ── Game Card ─────────────────────────────────────────────────────────────────
/// Physical playing-card style widget.
/// - Background: user cover image OR built-in decorative pattern
/// - Bottom strip: when cover exists, shows a blurred thumbnail strip
class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.content,
    required this.color,
    required this.badge,
    this.coverUrl,
    this.isSpicy = false,
    this.playerInitial,
    this.emoji,
    this.subTitle,
  });
  final String content;
  final Color color;
  final String badge;
  final String? coverUrl;
  final bool isSpicy;
  final String? playerInitial;
  final String? emoji;
  final String? subTitle;

  static const _r = 24.0;

  @override
  Widget build(BuildContext context) {
    final hasCover = coverUrl != null && coverUrl!.isNotEmpty;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 32;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          width: w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_r),
            border: Border.all(color: color.withOpacity(0.55), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.45),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_r - 1),
            child: Stack(
              children: [
                // ── Background ───────────────────────────────────────────────
                Positioned.fill(
                  child: hasCover
                      ? Image.network(
                          coverUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/backgrounds/jma3a_card_background.png',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      : Image.asset(
                          'assets/images/backgrounds/jma3a_card_background.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) =>
                              _AppPatternBg(color: color),
                        ),
                ),
                // ── Colour tint overlay — keep light so background image shows ──
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.30),
                          const Color(0xFF0D1B2A).withOpacity(0.45),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                // ── Shimmer lines ────────────────────────────────────────────
                Positioned.fill(
                  child: CustomPaint(painter: _CardShimmerPainter()),
                ),
                // ── Content ──────────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, hasCover ? 72 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Pill(
                            badge,
                            background: Colors.white.withOpacity(0.22),
                          ),
                          if (isSpicy) ...[
                            const SizedBox(width: 6),
                            _Pill(
                              '🌶 SPICY',
                              background: Colors.red.withOpacity(0.35),
                            ),
                          ],
                          const Spacer(),
                          if (playerInitial != null)
                            Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.35),
                                ),
                              ),
                              child: Text(
                                playerInitial!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      if (emoji != null)
                        Text(
                          emoji!,
                          style: const TextStyle(fontSize: 56),
                        ).animate().scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1, 1),
                          duration: 400.ms,
                          curve: Curves.elasticOut,
                        ),
                      if (subTitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          subTitle!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                            content,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.45,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 280.ms)
                          .slideY(begin: 0.06, end: 0),
                      const Spacer(),
                    ],
                  ),
                ),
                // ── Bottom cover strip ───────────────────────────────────────
                if (hasCover)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _CardBottomStrip(
                      coverUrl: coverUrl!,
                      accentColor: color,
                    ),
                  ),
                // ── Corner suit symbols ──────────────────────────────────────
                Positioned(
                  top: 10,
                  left: 12,
                  child: Opacity(
                    opacity: 0.18,
                    child: Text(
                      _suitFor(badge),
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  bottom: hasCover ? 62 : 10,
                  right: 12,
                  child: Opacity(
                    opacity: 0.18,
                    child: RotatedBox(
                      quarterTurns: 2,
                      child: Text(
                        _suitFor(badge),
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
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
      },
    );
  }

  static String _suitFor(String badge) {
    if (badge.contains('TRUTH')) return '🤔';
    if (badge.contains('DARE')) return '🔥';
    if (badge.contains('NEVER')) return '🍹';
    if (badge.contains('MEME')) return '😂';
    return '🎲';
  }
}

/// App's built-in decorative background — used when no pack cover is uploaded.
class _AppPatternBg extends StatelessWidget {
  const _AppPatternBg({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _PatternPainter(color: color),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0D1B2A),
            Color.lerp(const Color(0xFF0D1B2A), color, 0.40)!,
            const Color(0xFF0D1B2A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ),
  );
}

class _PatternPainter extends CustomPainter {
  const _PatternPainter({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final arc = Paint()
      ..color = color.withOpacity(0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    // Concentric arcs from two corners
    for (double r = 28; r < size.width * 1.7; r += 26)
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        0,
        1.57,
        false,
        arc,
      );
    for (double r = 28; r < size.width * 1.7; r += 26)
      canvas.drawArc(
        Rect.fromCircle(center: Offset(size.width, size.height), radius: r),
        3.14,
        1.57,
        false,
        arc,
      );
    // Dot grid
    final dot = Paint()
      ..color = color.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    for (double x = 20; x < size.width; x += 26)
      for (double y = 20; y < size.height; y += 26)
        canvas.drawCircle(Offset(x, y), 1.5, dot);
  }

  @override
  bool shouldRepaint(_PatternPainter old) => old.color != color;
}

class _CardShimmerPainter extends CustomPainter {
  const _CardShimmerPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.008)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    for (double x = -size.height; x < size.width * 2; x += 38)
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), p);
  }

  @override
  bool shouldRepaint(_CardShimmerPainter _) => false;
}

/// Bottom strip showing the pack cover as a blurred thumbnail banner.
class _CardBottomStrip extends StatelessWidget {
  const _CardBottomStrip({required this.coverUrl, required this.accentColor});
  final String coverUrl;
  final Color accentColor;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        children: [
          // Blurred / tinted cover
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                accentColor.withOpacity(0.50),
                BlendMode.srcOver,
              ),
              child: Image.network(
                coverUrl,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          // Scrim
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Top divider
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Divider(height: 1, color: accentColor.withOpacity(0.50)),
          ),
          // Thumbnail
          Positioned(
            left: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white.withOpacity(0.40)),
                  boxShadow: [
                    const BoxShadow(color: Colors.black38, blurRadius: 4),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
          // Label
          Positioned(
            left: 52,
            right: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                context.l10n.offlinePackCover,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, {required this.background});
  final String label;
  final Color background;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.15)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 11,
        letterSpacing: 1.0,
      ),
    ),
  );
}

class _TurnTimer extends StatefulWidget {
  const _TurnTimer({
    required this.startedAt,
    required this.durationSeconds,
    required this.onExpired,
  });
  final int startedAt, durationSeconds;
  final VoidCallback onExpired;
  @override
  State<_TurnTimer> createState() => _TurnTimerState();
}

class _TurnTimerState extends State<_TurnTimer> {
  Timer? _t;
  int _remaining = 0;
  bool _fired = false;
  @override
  void initState() {
    super.initState();
    _update();
    _t = Timer.periodic(1.seconds, (_) => _update());
  }

  void _update() {
    final elapsed =
        (DateTime.now().millisecondsSinceEpoch - widget.startedAt) ~/ 1000;
    final rem = (widget.durationSeconds - elapsed).clamp(
      0,
      widget.durationSeconds,
    );
    if (mounted) setState(() => _remaining = rem);
    if (rem == 0 && !_fired) {
      _fired = true;
      widget.onExpired();
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = widget.durationSeconds > 0
        ? _remaining / widget.durationSeconds
        : 0.0;
    final color = pct > 0.4
        ? _kGreen
        : pct > 0.2
        ? _kOrange
        : _kCoral;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              context.l10n.offlineTimerSeconds(_remaining),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            color: color,
            backgroundColor: color.withOpacity(0.15),
          ),
        ),
      ],
    );
  }
}

// ── In-game history sheet ──────────────────────────────────────────────────────
class _HistorySheet extends StatelessWidget {
  const _HistorySheet({required this.game});
  final OfflineGameProvider game;
  @override
  Widget build(BuildContext context) {
    final state = game.state;
    final session = game.session;
    final names = {
      for (final p in session?.players ?? <OfflinePlayer>[]) p.id: p.name,
    };
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.75,
      decoration: const BoxDecoration(
        color: _kNavyLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            context.l10n.offlineGameHistoryTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Divider(color: Colors.white12, height: 1),
          Expanded(child: _buildHistory(context, state, names)),
        ],
      ),
    );
  }

  Widget _buildHistory(BuildContext context, GameEngineState? state, Map<String, String> names) {
    if (state is TodState) {
      if (state.history.isEmpty)
        return Center(
          child: Text(
            context.l10n.offlineNoTurnsCompleted,
            style: const TextStyle(color: Colors.white38),
          ),
        );
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: state.history.length,
        itemBuilder: (_, i) {
          final r = state.history[state.history.length - 1 - i];
          final pName = names[r.playerId] ?? r.playerId;
          final isTruth = r.card?.type == TodCardType.truth;
          final color = isTruth ? _kCoral : _kOrange;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        isTruth ? '🤔' : '🔥',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: r.response.isNotEmpty
                              ? _kGreen.withOpacity(0.15)
                              : Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          r.response.isNotEmpty ? context.l10n.offlineDoneCheck : context.l10n.offlineSkippedCross,
                          style: TextStyle(
                            color: r.response.isNotEmpty ? _kGreen : _kCoral,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (r.card != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Text(
                      r.card!.content,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                if (r.response.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
                    child: Text(
                      context.l10n.todQuotedResponse(r.response),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    }
    if (state is NhieState) {
      if (state.history.isEmpty)
        return Center(
          child: Text(
            context.l10n.offlineNoRoundsCompleted,
            style: const TextStyle(color: Colors.white38),
          ),
        );
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: state.history.length,
        itemBuilder: (_, i) {
          final r = state.history[state.history.length - 1 - i];
          final haveI = r.votes.entries
              .where((e) => e.value.haveI)
              .map((e) => names[e.key] ?? e.key)
              .join(', ');
          final never = r.votes.entries
              .where((e) => !e.value.haveI)
              .map((e) => names[e.key] ?? e.key)
              .join(', ');
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kTeal.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🍹 ${r.card.content}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (haveI.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '🙋 $haveI',
                    style: const TextStyle(color: _kTeal, fontSize: 12),
                  ),
                ],
                if (never.isNotEmpty)
                  Text(
                    '🙅 $never',
                    style: const TextStyle(color: _kCoral, fontSize: 12),
                  ),
              ],
            ),
          );
        },
      );
    }
    if (state is MemeState) {
      if (state.history.isEmpty)
        return Center(
          child: Text(
            context.l10n.offlineNoRoundsCompleted,
            style: const TextStyle(color: Colors.white38),
          ),
        );
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: state.history.length,
        itemBuilder: (_, i) {
          final r = state.history[state.history.length - 1 - i];
          final winner = names[r.winnerId] ?? r.winnerId ?? '?';
          final winSub = r.submissions[r.winnerId];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kPurple.withOpacity(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.offlineRoundColonCaption(r.roundNumber, r.prompt.caption),
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text('🏆 '),
                    Text(
                      winner,
                      style: const TextStyle(
                        color: _kYellow,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (winSub != null) ...[
                      const SizedBox(width: 10),
                      _stickerImg(winSub.stickerChoice, height: 24),
                      if (winSub.caption.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            context.l10n.todQuotedResponse(winSub.caption),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      );
    }
    return Center(
      child: Text(
        context.l10n.offlineNoHistoryAvailable,
        style: const TextStyle(color: Colors.white38),
      ),
    );
  }
}

// ── LAN Lobby ──────────────────────────────────────────────────────────────────
class _LanLobbyScreen extends StatefulWidget {
  const _LanLobbyScreen({required this.game});
  final OfflineGameProvider game;
  @override
  State<_LanLobbyScreen> createState() => _LanLobbyScreenState();
}

class _LanLobbyScreenState extends State<_LanLobbyScreen> {
  final _chatCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  @override
  void dispose() {
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final t = _chatCtrl.text.trim();
    if (t.isEmpty) return;
    widget.game.sendChat(t);
    _chatCtrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() => Future.delayed(100.ms, () {
    if (_scrollCtrl.hasClients)
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: 200.ms,
        curve: Curves.easeOut,
      );
  });

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final session = game.session;
    final players = session?.players ?? [];
    return Scaffold(
      backgroundColor: _kNavy,
      appBar: AppBar(
        backgroundColor: _kNavyLight,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session?.gameType.displayName ?? 'Lobby',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              session?.packName ?? '',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _kYellow.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kYellow.withOpacity(0.3)),
                ),
                child: Text(
                  context.l10n.offlinePlayersCount(players.length),
                  style: const TextStyle(
                    color: _kYellow,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: _kNavyLight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.offlinePlayersInLobby,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: players.map((p) {
                      final isHost = p.seatOrder == 0;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isHost
                                        ? _kYellow.withOpacity(0.2)
                                        : _kTeal.withOpacity(0.15),
                                    border: Border.all(
                                      color: isHost ? _kYellow : _kTeal,
                                      width: 1.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    p.name[0].toUpperCase(),
                                    style: TextStyle(
                                      color: isHost ? _kYellow : _kTeal,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                if (isHost)
                                  const Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Text(
                                      '👑',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                if (!isHost && game.isLanHost)
                                  Positioned(
                                    bottom: -2,
                                    right: -2,
                                    child: GestureDetector(
                                      onTap: () => _confirmKick(context, p),
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: const BoxDecoration(
                                          color: _kCoral,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.name.split(' ').first,
                              style: TextStyle(
                                color: isHost ? _kYellow : Colors.white60,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: game,
              builder: (_, __) {
                final msgs = game.chatMessages;
                if (msgs.isNotEmpty)
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _scrollToBottom(),
                  );
                final myId = game.isLanHost
                    ? (session?.players.firstOrNull?.id ?? '')
                    : (game.clientPlayerId ?? '');
                return msgs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('💬', style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 8),
                            Text(
                              context.l10n.offlineSayHiToGroup,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        itemCount: msgs.length,
                        itemBuilder: (_, i) => _ChatBubble(
                          msg: msgs[i],
                          isMe: msgs[i].senderId == myId,
                        ),
                      );
              },
            ),
          ),
          if (!game.isLanHost)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _kYellow.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kYellow.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _kYellow,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.l10n.offlineWaitingForHostToStart,
                    style: const TextStyle(
                      color: _kYellow,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              MediaQuery.viewInsetsOf(context).bottom + 10,
            ),
            decoration: const BoxDecoration(color: _kNavyLight),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Chat…',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.07),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _send(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: _kYellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: _kNavy,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmKick(BuildContext context, OfflinePlayer p) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: _kNavyLight,
      title: Text(
        context.l10n.offlineKickConfirmTitle(p.name),
        style: const TextStyle(color: Colors.white),
      ),
      content: Text(
        context.l10n.offlineKickConfirmBody,
        style: const TextStyle(color: Colors.white60),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel, style: const TextStyle(color: Colors.white54)),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            widget.game.kickLanPlayer(p.id);
          },
          style: FilledButton.styleFrom(backgroundColor: _kCoral),
          child: Text(context.l10n.kick),
        ),
      ],
    ),
  );
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.msg, required this.isMe});
  final LanChatMessage msg;
  final bool isMe;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      bottom: 8,
      left: isMe ? 56 : 0,
      right: isMe ? 0 : 56,
    ),
    child: Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (!isMe)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 3),
            child: Text(
              msg.senderName,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? _kYellow : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(18).copyWith(
              bottomRight: isMe ? const Radius.circular(4) : null,
              bottomLeft: isMe ? null : const Radius.circular(4),
            ),
          ),
          child: Text(
            msg.text,
            style: TextStyle(
              color: isMe ? _kNavy : Colors.white,
              fontWeight: isMe ? FontWeight.w700 : FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ChatSheet extends StatefulWidget {
  const _ChatSheet({required this.game});
  final OfflineGameProvider game;
  @override
  State<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<_ChatSheet> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    widget.game.sendChat(t);
    _ctrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final myId = widget.game.isLanHost
        ? (widget.game.session?.players.firstOrNull?.id ?? '')
        : (widget.game.clientPlayerId ?? '');
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.65,
      decoration: const BoxDecoration(
        color: _kNavyLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            context.l10n.todChatTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.game,
              builder: (_, __) {
                final msgs = widget.game.chatMessages;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scroll.hasClients)
                    _scroll.animateTo(
                      _scroll.position.maxScrollExtent,
                      duration: 200.ms,
                      curve: Curves.easeOut,
                    );
                });
                return msgs.isEmpty
                    ? Center(
                        child: Text(
                          context.l10n.chatNoMessagesYet,
                          style: const TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(12),
                        itemCount: msgs.length,
                        itemBuilder: (_, i) => _ChatBubble(
                          msg: msgs[i],
                          isMe: msgs[i].senderId == myId,
                        ),
                      );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              MediaQuery.viewInsetsOf(context).bottom + 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message…',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.07),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _send(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: _kYellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: _kNavy,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Game over ─────────────────────────────────────────────────────────────────
class _GameOverScreen extends StatelessWidget {
  const _GameOverScreen({required this.game});
  final OfflineGameProvider game;
  @override
  Widget build(BuildContext context) {
    final state = game.state;
    final names = {
      for (final p in game.session?.players ?? <OfflinePlayer>[]) p.id: p.name,
    };
    return Scaffold(
      backgroundColor: _kNavy,
      appBar: AppBar(
        backgroundColor: _kNavyLight,
        foregroundColor: Colors.white,
        title: Text(
          context.l10n.offlineGameOverTrophy,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: _kNavyLight,
              child: TabBar(
                labelColor: _kYellow,
                unselectedLabelColor: Colors.white38,
                indicatorColor: _kYellow,
                tabs: [
                  Tab(text: context.l10n.offlineScoresTab),
                  Tab(text: context.l10n.offlineHistoryTab),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildScores(context, state, names),
                  _HistorySheet(game: game),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                style: FilledButton.styleFrom(
                  backgroundColor: _kYellow,
                  foregroundColor: _kNavy,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.home_rounded),
                label: Text(
                  context.l10n.offlineBackToMenu,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScores(BuildContext context, GameEngineState? state, Map<String, String> names) {
    List<MapEntry<String, int>> scores = [];
    if (state is TodState)
      scores =
          state.scores.entries
              .map((e) => MapEntry(e.key, e.value.points))
              .toList()
            ..sort((a, b) => b.value.compareTo(a.value));
    else if (state is NhieState)
      scores = state.scores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    else if (state is MemeState)
      scores = state.scores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: scores.length + 1,
      itemBuilder: (_, i) {
        if (i == 0)
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                const Text(
                  '🏆',
                  style: TextStyle(fontSize: 64),
                ).animate().scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.offlineFinalScores,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          );
        final e = scores[i - 1];
        final medals = ['🥇', '🥈', '🥉'];
        final isTop = i <= 3;
        return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: isTop
                    ? LinearGradient(
                        colors: [
                          _kYellow.withOpacity(i == 1 ? 0.15 : 0.08),
                          Colors.transparent,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                color: isTop ? null : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: isTop
                    ? Border.all(
                        color: _kYellow.withOpacity(i == 1 ? 0.3 : 0.1),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Text(
                    i <= 3 ? medals[i - 1] : '$i.',
                    style: const TextStyle(fontSize: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      names[e.key] ?? e.key,
                      style: TextStyle(
                        color: i == 1 ? _kYellow : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  Text(
                    '${e.value}',
                    style: TextStyle(
                      color: i == 1 ? _kYellow : Colors.white60,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'pts',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            )
            .animate(delay: Duration(milliseconds: i * 80))
            .fadeIn()
            .slideX(begin: 0.1, end: 0);
      },
    );
  }
}
